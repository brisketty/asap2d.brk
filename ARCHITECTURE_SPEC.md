# A.S.A.P. Framework — Architecture Specification

> **A.S.A.P. — Automated Skeleton, Artist Pipeline.**
> Companion document: [`REMAINING_TASKS.md`](REMAINING_TASKS.md) tracks the
> phased implementation and its history.
>
> Scope of this document: the framework's *own* architecture (the foundation
> layer and the seven presentation subsystems built on it). The Brisklance
> addon's self-update design lives separately in
> [`addons/brisklance/manager/ARCHITECTURE_SPEC.md`](addons/brisklance/manager/ARCHITECTURE_SPEC.md).

## Problem

A 2D game accumulates dozens of "juice" systems — hit flashes, screen shake,
floating damage numbers, parallax, positional SFX, music crossfades. Written
naively, each one reaches directly into gameplay code (`player.gd` calls
`camera.add_trauma(0.4)`, `enemy.gd` instantiates a spark scene). The result:

- Gameplay logic cannot be unit-tested without a full scene tree of art.
- Re-theming (a new biome, a boss arena, a "hurt" post-processing state) means
  editing logic scripts.
- A missing texture or stream hard-crashes the running build.
- No tool can tell an artist *which* assets a scene actually needs, or which are
  still missing.

## Goal

Gameplay logic emits **abstract semantic events** (`&"impact.basic"` at a
position) and never references a node, stream, texture, or UI element.
Presentation subsystems listen on a **Global Event Bus**, translate each event
into concrete assets fetched **by string id** from a **Theme Manager**, and every
lookup **falls back to a default** rather than failing. Every asset id a scene
references is a scannable `@export`, so tooling can produce a **prioritized,
zero-waste artist worklist**.

## The four pillars

### 1. Pure Logic (Semantic Emission)

Core logic scripts (`/scripts`, gameplay `class_name` nodes) **must never**
reference visual nodes, `AudioStream`s, shaders, or `Control`s. They communicate
**only** by calling `EventBus.emit_semantic_event(p_event_id, p_context)`.

- `p_event_id: StringName` — a namespaced id from the registry below.
- `p_context: Dictionary` — abstract spatial/intensity data, shaped by
  `Utility.make_spatial_context`. Never carries object references to art.

A logic script may `await` nothing from presentation and must behave identically
whether or not any subsystem is connected.

### 2. Profile-Driven Translation

Presentation managers **never** hardcode `res://` asset paths or `preload()` art.
They call `ThemeManager.resolve_<kind>(p_asset_id)` and receive whatever the
**active `ThemeProfile`** maps that id to. Swapping the active profile
(`ThemeManager.set_active_profile_by_id(&"cave")`) re-themes every subsystem at
once, with no logic or presentation code change.

### 3. Defensive Defaulting

Every `ThemeManager.resolve_*` call returns a usable asset or the closest
fallback — **never `null`, never a crash**:

```
active profile mapping  →  active profile's default_<kind>  →  ThemeManager.<kind>_fallback
```

Each downgrade logs once via `printerr` with the missing id (this doubles as
telemetry). Subsystems may assume the returned asset is valid.

### 4. Telemetry-Gated Scoping

Every asset id a scene references is declared as an `@export var` whose name ends
in a known suffix (`_sprite_asset_id`, `_audio_asset_id`, `_particle_asset_id`,
…) or `_event_id`. `AssetIdScanner` statically walks the scene tree, collects
these, diffs them against the active `ThemeProfile`, and emits a worklist of
**only the unmapped ids**, ordered by how many scenes use each (most-used first).

## Directory layout

Per [`CLAUDE.md`](CLAUDE.md):

| Dir | Holds |
| --- | --- |
| `/scripts` | Standalone utilities that do **not** extend `Node` (`Utility`, `ThemeProfile`, `AssetIdScanner`, future presentation `Resource` profiles). |
| `/autoloads` | Global singletons (`EventBus`, `ThemeManager`, and one autoload per subsystem manager). |
| `/prefabs` | Reusable sub-scenes: each subsystem's in-scene nodes (pools, emitters, HUD widgets). |
| `/scenes` | Root game-loop scenes + the framework demo. |
| `/assets` | Raw art/audio + `ThemeProfile` `.tres` files. |
| `/tests` | Headless `SceneTree` test scripts. |

---

## Foundation layer (implemented)

### 1. `Utility` — `scripts/utility.gd`

`class_name Utility`, no `extends`. Pure static helpers.

Constants — the reserved `EventBus` context keys:

- `CONTEXT_POSITION_KEY := &"position"`
- `CONTEXT_DIRECTION_KEY := &"direction"`
- `CONTEXT_MAGNITUDE_KEY := &"magnitude"`
- `CONTEXT_SOURCE_ID_KEY := &"source_id"`

Methods:

- `static is_object_valid(p_object: Object) -> bool` — `CLAUDE.md` §2B. Returns
  `false` for `null`, non-`is_instance_valid`, or a `Node` that
  `is_queued_for_deletion()`. Works for `Resource`/`RefCounted` (the queued check
  is guarded by a `Node` cast).
- `static make_spatial_context(p_position: Vector2, p_direction := Vector2.ZERO, p_magnitude := 0.0, p_source_id := &"") -> Dictionary` —
  the canonical context shape `{ position, direction, magnitude, source_id }`.

### 2. `EventBus` — `autoloads/event_bus.gd`

`extends Node`. **No `class_name`** (would collide with the `EventBus` autoload
identifier). Registered as autoload `EventBus`.

- `signal semantic_event_emitted(p_event_id: StringName, p_context: Dictionary)`
- `emit_semantic_event(p_event_id: StringName, p_context := {}) -> void` —
  `assert(p_event_id != &"")`, then emits. Synchronous fan-out.

**Context contract.** Consumers must tolerate missing keys
(`p_context.get(Utility.CONTEXT_POSITION_KEY, Vector2.ZERO)`). Subsystems may
read extra keys they define, but the four reserved keys always mean the same
thing.

### 3. `ThemeProfile` — `scripts/theme_profile.gd`

`class_name ThemeProfile`, `extends Resource`. A swappable presentation profile
(biome / mood / arena state).

- `@export var profile_id: StringName`
- `@export var sprite_assets: Dictionary` (`StringName -> Texture2D`), setter →
  `update_from_sprite_assets()` (`CLAUDE.md` §2E).
- `@export var audio_assets: Dictionary` (`StringName -> AudioStream`), setter →
  `update_from_audio_assets()`.
- `@export var particle_assets: Dictionary` (`StringName -> Resource`:
  `ParticleProcessMaterial` or `PackedScene`), setter →
  `update_from_particle_assets()`.
- `@export var shader_assets` (`-> ShaderMaterial`, world atmosphere),
  `post_fx_assets` (`-> ShaderMaterial`, state grades), `music_assets`
  (`-> AudioStream`, looped), each with its `update_from_*` setter.
- `@export var default_{sprite,audio,particle,shader,post_fx,music}` (typed).
- `resolve_{…}_or_null(p_asset_id)` — raw lookup, **no fallback**.
- `collect_{…}_ids() -> PackedStringArray` — thin wrappers over
  `collect_ids_of(Dictionary)`, for tooling.

**Growth (see Cross-cutting).** Each new asset kind adds a parallel
`<kind>_assets: Dictionary`, `default_<kind>`, `resolve_<kind>_or_null`,
`collect_<kind>_ids`. When the count justifies it this collapses into a single
`Dictionary` of `Dictionary` keyed by kind + a generic `resolve_or_null(p_kind, p_asset_id)`.

### 4. `ThemeManager` — `autoloads/theme_manager.gd`

`extends Node`. **No `class_name`**. Registered as autoload `ThemeManager`. The
single choke point for every asset lookup in the framework.

- `@export_group("Profiles", "profile_")`
  - `@export var profile_available: Array[ThemeProfile]`
  - `@export var profile_fallback_sprite: Texture2D = preload("res://icon.svg")`
  - `@export var profile_fallback_audio: AudioStream`
  - `@export var profile_fallback_{particle,shader,post_fx,music}` (typed)
- `signal active_profile_changed(p_profile_id: StringName)`
- `var active_profile: ThemeProfile` — setter → `update_from_active_profile()`
  which emits `active_profile_changed` with the new `profile_id` (or `&""`).
- `_ready()` — if `active_profile` unset and `profile_available` non-empty, adopts
  element 0.
- `get_active_profile_id() -> StringName` — `&""` when no valid profile.
- `set_active_profile_by_id(p_profile_id: StringName) -> void` — early-return on
  no match (`printerr`).
- `resolve_sprite(p_asset_id: StringName) -> Texture2D` — **never null**. Ladder:
  active-profile mapping → active-profile `default_sprite` →
  `profile_fallback_sprite`. `printerr` on each downgrade.
- `resolve_{audio,particle,shader,post_fx,music}` — same ladder as
  `resolve_sprite` (all built on `resolve_with_ladder` + `profile_asset_or_null`
  + `profile_default_or_null`); the final fallback may be `null` when the project
  never configures that `profile_fallback_*`.
- `has_{sprite,audio,particle,shader,post_fx,music}(p_asset_id) -> bool` —
  non-logging existence check against the active profile, for `AssetIdScanner`.

Subsystems that cache a resolved asset must re-pull on `active_profile_changed`.

### 5. `AssetIdScanner` — `scripts/asset_id_scanner.gd`

`@tool class_name AssetIdScanner`, `extends RefCounted`. Pure static methods
(same shape as `BrisklanceSelfUpdater`).

Constants: `{SPRITE,AUDIO,PARTICLE,SHADER,POST_FX,MUSIC}_ID_SUFFIX`
(`"_<kind>_asset_id"`), `EVENT_ID_SUFFIX := "_event_id"`,
`SCENE_EXTENSION := ".tscn"`; matching `*_KIND` constants.
`classify_property` checks the more specific `_post_fx_asset_id` /
`_music_asset_id` before `_shader_asset_id` / `_audio_asset_id`.

- `scan_directory(p_root_path: String) -> Array[Dictionary]` — recurse for
  `.tscn`, scan each.
- `collect_scene_paths(p_root_path) -> PackedStringArray` — recursive `.tscn`
  walk.
- `scan_scene(p_scene_path) -> Array[Dictionary]` — **instantiates** the scene
  with `PackedScene.GEN_EDIT_STATE_DISABLED` (never entered into the tree, so
  `_ready` never runs) and walks live nodes. A `.tscn` `SceneState` only stores
  *overridden* export values, so a static state-only parse misses ids left at
  their script default — instantiation is required.
- `collect_ids_from_node(p_node, p_root, p_scene_path, r_results)` — for each
  property in `get_property_list()` whose name `classify_property`s to a kind,
  append `{ scene_path, node_path, property, asset_id, kind }`; recurse children.
- `classify_property(p_property_name) -> StringName` — suffix match → kind or
  `&""`.
- `build_task_list(p_references, p_theme_manager) -> Array[Dictionary]` — drops
  `EVENT_KIND` and empty ids; dedupes by `(kind, asset_id)`; `reference_count` =
  distinct scenes; drops ids already mapped
  (`p_theme_manager.has_<kind>`); sorts by `reference_count` desc.
  `p_theme_manager` is duck-typed (any object with the `has_<kind>` methods), so
  tests can pass a stub.
- `format_task_list(p_tasks) -> String` — plain-text report.

Adding an asset kind = add a suffix constant, a kind constant, a
`classify_property` branch, and a `has_<kind>` branch in `is_reference_mapped`.

### 6. Demo — `scenes/foundation_demo.tscn`

Project main scene. `FoundationDemo` (`class_name`, `extends Node2D`):

- `@export_group("Profiles", "profile_")` → `profile_available: Array[ThemeProfile]`
  (both demo `.tres`), pushed to `ThemeManager.profile_available` in `_ready()`.
- `@export_group("Nodes", "node_")` → `node_emit_timer`, `node_profile_button`,
  `node_presenter` (exported node refs; `.tscn` uses
  `node_paths=PackedStringArray(...)`).
- Timer timeout / mouse click →
  `EventBus.emit_semantic_event(EventIds.IMPACT_BASIC, Utility.make_spatial_context(get_global_mouse_position()))`.
- Button toggles `ThemeManager.set_active_profile_by_id` between `&"complete"`
  and `&"sparse"`.

`DemoImpactPresenter` (`/prefabs`, `class_name`, `extends Node2D`) — the
reference presenter: `@export`ed `asset_spark_sprite_asset_id` and
`event_impact_event_id`; connects to the bus in `_ready()`; on a matching event
resolves the sprite via `ThemeManager`, spawns a short-lived `Sprite2D` at
`context.position`, updates a status `Label`. `static get_packed_scene()` per
`CLAUDE.md` §2F.

Demo profiles: `assets/theme_profile_complete.tres` (maps `impact.spark`) and
`assets/theme_profile_sparse.tres` (empty maps, `default_sprite` only → exercises
the fallback ladder live).

### 7. `EventIds` — `scripts/event_ids.gd`

`class_name EventIds`, no `extends`. `const StringName`s for every semantic event
id, grouped by namespace and mirroring the registry table below. Emitters and
consumers reference `EventIds.IMPACT_BASIC`, never a typed literal — a rename is
a compile concern, a typo is impossible. A subsystem PR adding an id adds a
constant here **and** a registry row.

### 8. `NodePool` — `prefabs/node_pool.{gd,tscn}`

`class_name NodePool`, `extends Node`. Generic object pool for anything spawned
per-event.

- `@export_group("Pool", "pool_")` → `pool_scene: PackedScene`,
  `pool_prewarm_count: int`, `pool_max_count: int` (hard ceiling).
- `available: Array[Node]`, `in_use: Array[Node]`.
- `prewarm()` — tops `available` up to `pool_prewarm_count`, never past it
  (idempotent). Called from `_ready()`.
- `acquire() -> Node` — reuse from `available` → else instantiate (under the
  ceiling) → else **recycle the oldest `in_use` node**. Returns the node
  reparented under the pool; caller positions it. `null` only if `pool_scene`
  unset.
- `release(p_node)` — moves it back to `available`, detached from the pool tree.
  Double-release is a no-op.
- `clear_pool()` — frees everything, for teardown.
- `static get_packed_scene()` per `CLAUDE.md` §2F.

Never `queue_free` a pooled node in an event handler.

### 9. `run_asset_scan` — `scripts/run_asset_scan.gd`

`extends SceneTree` (not an `EditorScript` — so CI can run it headless:
`godot --headless --script res://scripts/run_asset_scan.gd`). Scans
`res://scenes` + `res://prefabs`, builds a throwaway `ThemeManager` from every
`ThemeProfile` in `res://assets` (basis = the first one), runs
`AssetIdScanner.build_task_list`, prints the worklist and writes
`exports/asset_worklist.md` (git-tracked; CI diffs it — see `.gitignore`).

---

## Conventions for subsystem authors

Every subsystem follows the same shape:

1. **One manager**, `extends Node`, registered as an autoload. **Naming decision
   (settled):** the manager script carries a distinct `class_name` ending in
   `Subsystem` (`ImpactVfxSubsystem`, `CameraDirectorSubsystem`, …) and the
   autoload is registered under the short name without that suffix (`ImpactVfx`,
   `CameraDirector`, …). This keeps a referenceable type for `is`/typed params
   while call sites stay terse, and the autoload name never collides with the
   `class_name`. (`EventBus`/`ThemeManager` predate this rule and simply drop
   `class_name`; new subsystems follow the `…Subsystem` convention.) The manager
   connects to `EventBus.semantic_event_emitted` in `_ready()`.
2. **Handler**: `handle_semantic_event_emitted(p_event_id, p_context)` — a
   `match`/early-return dispatch on `p_event_id` against ids the subsystem owns.
   Unknown id → return.
3. **Asset access only through `ThemeManager`**. Cache resolved assets, refresh on
   `active_profile_changed`.
4. **Scannable ids**: any id the subsystem's prefabs reference is an `@export`
   with the right suffix. Ids the subsystem hardcodes internally are `const`
   `StringName`s registered below.
5. **Object pooling** for anything spawned per-event (particles, audio players,
   damage labels): a `NodePool` prefab, pre-warmed, `acquire()`/`release()`,
   never `queue_free` in the hot path.
6. **No `_` privates, no `$`/`get_node`, full static typing, early returns**
   (`CLAUDE.md` §2).
7. **Headless test** for the pure translation logic (id → asset-kind + count),
   plus a manual in-scene check for the visual result.

### Event id namespace registry

Namespaced `domain.event`, `StringName`. Owned by the emitting *concept*, not the
subsystem. Consumed by any number of subsystems.

| Namespace | Example ids | Typical consumers |
| --- | --- | --- |
| `impact.*` | `impact.basic`, `impact.heavy`, `impact.crit`, `impact.block` | Impact VFX, Camera, SFX, UI (damage text) |
| `combat.*` | `combat.hitstop`, `combat.knockback`, `combat.death` | Impact VFX, Camera |
| `damage.*` | `damage.dealt`, `damage.healed` | UI/HUD, SFX |
| `entity.*` | `entity.spawned`, `entity.destroyed` | Impact VFX, SFX |
| `biome.*` | `biome.entered`, `biome.exited` | World, BGM, Camera, Audio Bus |
| `camera.*` | `camera.focus`, `camera.zoom`, `camera.shake` | Camera |
| `ui.*` | `ui.hover`, `ui.confirm`, `ui.cancel`, `ui.notify` | UI/HUD, SFX (dry bus) |
| `music.*` | `music.theme`, `music.stinger`, `music.tension` | BGM |
| `state.*` | `state.hurt`, `state.lowhealth`, `state.paused`, `state.clear` | Camera (post-FX), Audio Bus, BGM |

A subsystem PR that introduces an id adds a row here.

### `ThemeProfile` schema per asset kind

| Kind | Suffix | `ThemeProfile` field | `ThemeManager.resolve_*` returns | Status |
| --- | --- | --- | --- | --- |
| sprite | `_sprite_asset_id` | `sprite_assets` | `Texture2D` | live |
| audio | `_audio_asset_id` | `audio_assets` | `AudioStream` | live |
| particle | `_particle_asset_id` | `particle_assets` | `ParticleProcessMaterial` / `PackedScene` (typed `Resource`) | live |
| shader | `_shader_asset_id` | `shader_assets` | `ShaderMaterial` (world atmosphere) | live |
| post_fx | `_post_fx_asset_id` | `post_fx_assets` | `ShaderMaterial` (state grade) | live |
| music | `_music_asset_id` | `music_assets` | `AudioStream` (looped) | live |
| tileset | `_tileset_asset_id` | `tileset_assets` | `TileSet` | planned (Phase 2 follow-up) |
| bus_profile | `_bus_profile_asset_id` | `bus_profile_assets` | bus-effect config `Resource` | planned (Phase 7) |

`resolve_sprite` always returns a texture (the `res://icon.svg` engine default).
`resolve_audio` / `resolve_particle` / `resolve_shader` / `resolve_post_fx` may
return `null` until the project sets the matching `profile_fallback_*`.

---

## Subsystems

Each is a phase in [`REMAINING_TASKS.md`](REMAINING_TASKS.md).

### A. Impact & Combat VFX Subsystem — `ImpactVfx`  ✅ implemented (Phase 1)

Autoload `ImpactVfx`, `class_name ImpactVfxSubsystem` (`autoloads/impact_vfx.gd`).

- **Listens:** `impact.*` (burst + optional hit-stop from the intensity row),
  `combat.hitstop` (`context.magnitude` seconds).
- **`ImpactTranslation`** (`scripts/impact_translation.gd`, autoload-free, static)
  — intensity-table lookup + `compute_hitstop_end` bookkeeping. Unit-tested
  headless; the Node is just the wiring.
- **Intensity table:** `@export Array[ImpactIntensity]` (`intensity_event_id`,
  `intensity_particle_asset_id`, `intensity_particle_count`,
  `intensity_hitstop_seconds`). Empty → `build_default_intensity_table()`
  (basic/heavy/crit/block). An explicit table **replaces** the defaults, it does
  not merge.
- **`ParticleBurstPool`** (`prefabs/particle_burst_pool.{gd,tscn}`) — a `NodePool`
  of one-shot `GPUParticles2D` (`particle_burst.tscn`); `burst(pos, asset_id,
  count)` pulls a `ParticleProcessMaterial` via `ThemeManager.resolve_particle`
  (falls through to the prefab's built-in material on a miss), emits, releases
  after `lifetime`.
- **Hit-stop:** single owner. `request_hitstop(seconds)` → `hitstop_end_msec` =
  `ImpactTranslation.compute_hitstop_end(...)` (max-of, clamped to
  `hitstop_max_seconds`); `Engine.time_scale = 0.0001`; a chain of real-time
  `SceneTreeTimer`s (`ignore_time_scale = true`) re-checks the absolute end and
  restores `time_scale = 1.0` once.
- **Opt-in components** (added to an entity scene, `node_target` + a
  `*_source_id`, listen on the bus directly — the subsystem never touches
  entities):
  - `HitFlash` — `modulate` pulse on any `impact.*` matching `flash_source_id`.
    (A shader flash via `flash_shader_asset_id` + `resolve_shader` is a Phase 2
    upgrade; kept as a no-op fallback for now.)
  - `KnockbackReceiver` — lurch `node_target.position` along
    `context.direction * context.magnitude` on `combat.knockback`, ease back.
  - `SquashStretch` — squash `node_target.scale` on `impact.*` /
    `combat.knockback`, spring back (elastic).
- **Not here:** auto-trauma from `impact.heavy`/`crit` is **Camera's** concern
  (§C has its own event→trauma table); the subsystem does not emit `camera.*`.
- **Demo:** `scenes/demo_impact_vfx.tscn` — dummy target with all three
  components + four emit buttons.
- **Known gap:** intensity-table `*_asset_id`s live on a `.tres`/autoload, not a
  scene node, so `AssetIdScanner` does not see them (it walks scenes only). A
  "scan exported `Resource` arrays" follow-up is in `REMAINING_TASKS.md`.

### B. World & Environment Subsystem — `WorldEnvironment2D`  ✅ implemented (Phase 2)

Autoload `WorldEnvironment2D`, `class_name WorldEnvironment2DSubsystem`
(`autoloads/world_environment_2d.gd`).

- **Listens:** `biome.entered` (`context.source_id` = biome id) and
  `biome.exited`. Also re-themes on `ThemeManager.active_profile_changed` while a
  biome is active (`is_rebuilding` guards the resulting re-entrancy).
- On `biome.entered`: if `WorldTranslation.should_switch_profile(...)`, calls
  `ThemeManager.set_active_profile_by_id(biome_id)` — so **every** subsystem
  re-themes — then rebuilds its own three persistent children by resolving a
  **fixed** set of abstract ids through the now-active profile:
  - `PARALLAX_LAYER_IDS` = `world.parallax.{far,mid,near}` →
    `ThemeManager.resolve_sprite` → `ParallaxRig.configure(textures, scroll_scales)`
    (scales from `WorldTranslation.build_scroll_scales`, far=0.15 → near=1.0).
  - `world.ambient` → `resolve_particle` → `AmbientParticleLayer.configure(...)`
    (null → emission simply stops).
  - `world.overlay` → `resolve_shader` → `ScreenShaderOverlay.configure(...)`
    (null → the full-screen `ColorRect` hides).
- On `biome.exited`: all three `configure`d empty/null.
- **`WorldTranslation`** (`scripts/world_translation.gd`, autoload-free, static):
  `build_scroll_scales`, `resolve_layer_textures`, `should_switch_profile`.
  Unit-tested headless.
- **Prefabs:** `parallax_rig` (`ParallaxBackground` subclass, rebuildable layer
  stack with `motion_mirroring` tiling), `ambient_particle_layer` (`CanvasLayer`
  + looping `GPUParticles2D`), `screen_shader_overlay` (`CanvasLayer` +
  full-rect `ColorRect`).
- **Demo:** `scenes/demo_world.tscn` — forest / cave / exit buttons, a panning
  camera, two biome `ThemeProfile`s (`assets/theme_profile_{forest,cave}.tres`;
  forest deliberately omits `world.ambient` to show the null-fallback).
- **Deferred:** animated tiles / `AnimatedTileDriver` + a `tileset` asset kind —
  a Phase 2 follow-up in `REMAINING_TASKS.md`.

### C. Camera & Post-Processing Subsystem — `CameraDirector`

Autoload `CameraDirector`, `class_name CameraDirectorSubsystem`
(`autoloads/camera_director.gd`).  ✅ implemented (Phase 3)

- **Camera target:** `CameraDirector.set_followed(node)` — gameplay registers it;
  the rig never discovers it. `set_followed(valid)` also `make_current()`s the
  rig's `Camera2D`.
- **Listens:**
  - trauma table (`@export Array[CameraTrauma]`, empty → defaults for
    `impact.heavy`/`impact.crit`/`combat.hitstop`/`combat.death`) — matched event
    → `camera_rig.add_trauma(amount)`.
  - `camera.shake` — `context.magnitude` added as trauma.
  - `camera.zoom` — `context.magnitude` = zoom factor, tweened.
  - `camera.focus` — `context.position` present → pan there and hold
    (`is_focused`); absent → release back to the followed target.
  - `state.hurt`/`state.lowhealth`/`state.paused` →
    `camera_rig.set_post_fx(ThemeManager.resolve_post_fx(event_id), …)`;
    `state.clear` → fade the grade out.
- **`CameraTranslation`** (`scripts/camera_translation.gd`, autoload-free static):
  trauma math (`add_trauma` clamp 0–1, `decay_trauma` floor 0,
  `shake_amount` = trauma², `compute_offset`/`compute_rotation` from noise) +
  the event→trauma table (`build_lookup`, `build_default_trauma_table`,
  `resolve_trauma`). Unit-tested headless.
- **`CameraRig`** (`prefabs/camera_rig.{gd,tscn}`, `extends Node2D`) — a
  `Camera2D` + `FastNoiseLite`-driven shake in `_process` + a zoom `Tween` +
  focus `Tween` + a child `ScreenShaderOverlay` for the state grade. Follows the
  registered node unless focused.
- **`ScreenShaderOverlay`** gained `fade_to(material, seconds)` (alpha
  crossfade) alongside the instant `configure()`; both the Camera grade and the
  World overlay use it.
- **Post-FX asset kind** (`_post_fx_asset_id`, `post_fx_assets`,
  `resolve_post_fx`) — separate from `shader` so tooling distinguishes "biome
  atmosphere" from "damage feedback" art.
- **Demo:** `scenes/demo_camera.tscn` — wandering player + crit/shake/hurt/clear/
  zoom buttons; `assets/shaders/hurt_vignette.gdshader` mapped to `state.hurt` in
  the `complete` profile.
- **Deferred:** chromatic aberration is available as a shader parameter on the
  grade material but has no dedicated event yet.

### D. UI & HUD Polish Subsystem — `HudPolish`  ✅ implemented (Phase 4)

Autoload `HudPolish`, `class_name HudPolishSubsystem`
(`autoloads/hud_polish.gd`).

- **Listens:** `damage.dealt` / `damage.healed` → spawn a pooled floating number
  at `context.position`; if `context.source_id` names a registered bar and
  `context.ratio` is present, also push that ratio.
- **`HudTranslation`** (`scripts/hud_translation.gd`, autoload-free static):
  `damage_text(magnitude, event_id)` (`"12"` / `"+5"`), `damage_color(...)`
  (heal green; magnitude tiers light/heavy/severe), `catch_up_step(...)` (the
  lerp). Unit-tested headless.
- **`FloatingDamageText`** (`prefabs/floating_damage_text.{gd,tscn}`,
  `extends Node2D`) — **world-space** (rendered by the CameraDirector camera, no
  screen projection), pooled via `NodePool`, `play(text, color)` rises and
  fades, then `finished` → the pool reclaims it (`CONNECT_ONE_SHOT`).
- **`CatchUpBar`** (`prefabs/catch_up_bar.{gd,tscn}`, `extends Control`) —
  standalone: a front `ProgressBar` that snaps to the pushed `set_ratio(x)` over
  a trailing bar that eases via `HudTranslation.catch_up_step` (snaps forward on
  a heal so it never lags growth). `HudPolish.register_bar(id, bar)` /
  `push_bar_ratio(id, ratio)` route to it by id.
- **`HoverPop`** (`prefabs/hover_pop.{gd,tscn}`) — attach to a `Control`; pops it
  on `mouse_entered` and optionally emits `ui.hover`.
- **`Tweens`** (`scripts/tweens.gd`, `class_name Tweens`, static) — reusable
  recipes (`pop`, `fade_out`, `rise_and_fade`, `shake`) any scene can call.
- **Demo:** `scenes/demo_hud.tscn` — damage/heal buttons, bar ±ratio buttons, a
  `HoverPop` on the crit button.
- **Deferred:** a dedicated `font` asset kind (floating text uses the project
  theme font); `ui.confirm`/`ui.cancel` widget feedback; screen-space (vs
  world-space) floating text option.

### E. Polyphonic Audio Subsystem (SFX) — `SfxPlayer`

Autoload `SfxPlayer`, `class_name SfxPlayerSubsystem` (`autoloads/sfx_player.gd`).
✅ implemented (Phase 5)

- **Route table:** `@export Array[SfxRoute]` (`route_event_id`,
  `route_audio_asset_id`, `route_spatialized`, `route_pitch_semitones`,
  `route_volume_db_range`, `route_stop_on_scene_change`). Empty → defaults
  (`impact.*` positional, `ui.*` dry). An explicit table **replaces** the
  defaults.
- **`SfxTranslation`** (`scripts/sfx_translation.gd`, autoload-free static):
  `build_lookup`, `build_default_route_table`, `resolve_route`,
  `random_pitch_scale(semitones, unit)` (`2^(unit·semitones/12)`),
  `random_volume_db(range, unit)`, `should_keep_on_scene_change`. Unit-tested.
- **`SfxVoicePool`** (`prefabs/sfx_voice_pool.{gd,tscn}`) — wraps a `NodePool` of
  a voice scene (`sfx_voice_2d.tscn` = `AudioStreamPlayer2D` on bus `SFX`, or
  `sfx_voice_ui.tscn` = `AudioStreamPlayer` on bus `UI`). `play(stream, pitch,
  volume_db, position, keep)` acquires, configures (via `.set()` so one code
  path serves both voice classes), plays, auto-releases on `finished`
  (`CONNECT_ONE_SHOT`). A null stream (missing asset, no fallback) → no-op.
- **Subsystem:** on a routed event, `ThemeManager.resolve_audio(route id)`,
  randomise pitch/volume with a per-instance `RandomNumberGenerator`, dispatch to
  the positional or UI pool by `route_spatialized`.
- **Orphan safety:** both pools live under the autoload, so voices survive scene
  changes automatically. `SfxPlayer.notify_scene_change()` (call before
  `change_scene`) → `pool.stop_transient()` cuts only voices whose route set
  `route_stop_on_scene_change` (tagged via `set_meta`); the rest play out.
- **Bus layout:** `default_bus_layout.tres` now defines `Master / Music /
  Ambience / SFX / UI` (Phase 7 adds effects + sends).
- **Demo:** `scenes/demo_sfx.tscn` — light/heavy/hover/burst buttons over a
  code-built `ThemeProfile` of procedural tones (`ToneStream`, a demo/test
  helper).

### F. BGM & Ambience Subsystem — `MusicDirector`

Stem blending, theme crossfades, ambient loops.

- **Listens:** `music.theme` / `music.tension` / `music.stinger`, `biome.entered`,
  `state.*`.
- **Stems:** N synced `AudioStreamPlayer`s (same length, sample-locked), per-stem
  target `volume_db` driven by an intensity value (`context.magnitude` or a
  `state.*` id) — blend, don't restart.
- **Crossfade:** on `music.theme` change, `Tween` old bus volume down / new up
  over an `@export` duration; resolve the new stream set via
  `ThemeManager.resolve_music`.
- **Ambience:** looped `AudioStreamPlayer` on the ambience bus, swapped on
  `biome.entered`.

### G. Audio Bus / Mixing Subsystem — `AudioMixing`

Spatialisation config, dry unattenuated UI listener, theme-specific bus effect
overrides (reverb, EQ).

- **Owns** the project audio bus layout doc (`Master → Music, Ambience, SFX
  (→ SFX_Reverb send), UI (dry)`).
- **Listens:** `biome.entered` / `state.*` → apply a `bus_profile` resource
  (`ThemeManager.resolve_bus_profile`) that sets reverb room size, wet mix, EQ
  per bus. Cross-faded via effect parameter tweens, not hard swaps.
- **UI listener:** ensures `ui.*` SFX route through the dry `UI` bus with no
  attenuation/reverb even when a heavy `bus_profile` is active.
- **Spatialisation:** central config (max distance, attenuation curve, panning
  strength) that `SfxPlayer` reads rather than each route re-specifying.

---

## Cross-cutting concerns

### Object pooling — `NodePool` ✅ implemented

See Foundation §8. Used by Impact VFX, SFX, UI floating text. Subsystems that
need a per-node reset on reuse should give `pool_scene`'s root a
`reset_for_pool()` method and call it in their own `acquire`/`release` wrapper —
`NodePool` itself stays generic and does not reset state.

### `ThemeProfile` scaling

**Decision (settled at kind 6, `music`).** `ThemeProfile` keeps an **explicit
typed `@export var <kind>_assets: Dictionary` + `default_<kind>` per kind** — it
reads far better in the inspector and in hand-edited `.tres` than an opaque
`Dictionary` of `Dictionary`. The duplication that mattered was on the
`ThemeManager` side, and that was removed instead: `resolve_with_ladder(...)` +
`profile_asset_or_null(method, id)` + `profile_default_or_null(property)` make
every `resolve_<kind>` / `has_<kind>` a one-or-two-liner. Adding a kind is now:
one `ThemeProfile` export trio + `resolve_/collect_/update_from_`, one
`ThemeManager` fallback export + `resolve_`/`has_` pair, one scanner
`SUFFIX`/`KIND` + two branches. No further refactor planned.

### Event id constants — `EventIds` ✅ implemented

See Foundation §7. The demo emits via `EventIds.IMPACT_BASIC`. Every subsystem
consuming or emitting an id references a constant, never a literal.

### Scanner tooling — `run_asset_scan` ✅ implemented

See Foundation §9. Future nicety (planned): a Brisklance-style dock panel that
runs it on demand and shows the worklist in the editor.

---

## Testing strategy

- **Pure logic** (`Utility`, `EventBus` fan-out, `ThemeManager` fallback ladder,
  `AssetIdScanner` dedupe/priority/mapping, each subsystem's `event_id → asset
  kind + count` translation): headless `SceneTree` scripts under `/tests`,
  `godot --headless --script res://tests/<file>.gd`, `expect`/`quit(code)`
  harness (mirrors `tests/test_self_updater.gd`).
- **Fallback behaviour**: assert `resolve_*` never returns `null` and logs on
  downgrade; drive it with a deliberately sparse `ThemeProfile`.
- **Scanner**: build a temp scene dir, assert instantiation-based collection,
  reference counting, and that mapped ids drop out.
- **Visual result**: manual, in the demo scene and per-subsystem demo scenes —
  documented as a checklist in each phase.
- **Convention lint**: grep new files for `$`, `get_node(`, `func _` (excluding
  Godot virtuals), untyped `var`/params.

## Risks

- **`Engine.time_scale` hit-stop** interacts with every time-based system
  (tweens, timers, physics). One owner, always restores, `@export` max clamp.
- **Autoload count** grows to ~9 (2 foundation + 7 subsystems). Acceptable; each
  is cheap and idle until an event arrives. Consider a single `Presentation`
  autoload that owns the subsystems as children if load order or teardown gets
  fiddly.
- **`ThemeProfile` as one big resource** can bloat. The scaling refactor and
  per-biome sub-resources mitigate it.
- **Scanner instantiates every scene** — a scene with heavy `_init` work or
  external deps slows the scan. Mitigation: scan `/prefabs` + `/scenes` only,
  never `res://` root; `_init` in framework prefabs stays trivial.
- **Event id typos** — a mis-typed `StringName` silently no-ops. Mitigated by the
  `EventIds` constant registry and the namespace table above.
