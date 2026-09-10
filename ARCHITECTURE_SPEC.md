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
- `@export var default_sprite: Texture2D`, `default_audio: AudioStream`,
  `default_particle: Resource`
- `resolve_sprite_or_null` / `resolve_audio_or_null` / `resolve_particle_or_null`
  `(p_asset_id)` — raw lookup, **no fallback** (the manager applies and logs the
  fallback so it happens once, centrally).
- `collect_sprite_ids()` / `collect_audio_ids()` / `collect_particle_ids()`
  `-> PackedStringArray` — for tooling.

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
  - `@export var profile_fallback_particle: Resource`
- `signal active_profile_changed(p_profile_id: StringName)`
- `var active_profile: ThemeProfile` — setter → `update_from_active_profile()`
  which emits `active_profile_changed` with the new `profile_id` (or `&""`).
- `_ready()` — if `active_profile` unset and `profile_available` non-empty, adopts
  element 0.
- `set_active_profile_by_id(p_profile_id: StringName) -> void` — early-return on
  no match (`printerr`).
- `resolve_sprite(p_asset_id: StringName) -> Texture2D` — **never null**. Ladder:
  active-profile mapping → active-profile `default_sprite` →
  `profile_fallback_sprite`. `printerr` on each downgrade.
- `resolve_audio(p_asset_id: StringName) -> AudioStream` /
  `resolve_particle(p_asset_id: StringName) -> Resource` — same ladder; the final
  fallback may be `null` if the project never configures
  `profile_fallback_audio` / `profile_fallback_particle`.
- `has_sprite` / `has_audio` / `has_particle` `(p_asset_id) -> bool` —
  non-logging existence check against the active profile, for `AssetIdScanner`.

Subsystems that cache a resolved asset must re-pull on `active_profile_changed`.

### 5. `AssetIdScanner` — `scripts/asset_id_scanner.gd`

`@tool class_name AssetIdScanner`, `extends RefCounted`. Pure static methods
(same shape as `BrisklanceSelfUpdater`).

Constants: `SPRITE_ID_SUFFIX`/`AUDIO_ID_SUFFIX`/`PARTICLE_ID_SUFFIX`
(`"_<kind>_asset_id"`), `EVENT_ID_SUFFIX := "_event_id"`,
`SCENE_EXTENSION := ".tscn"`; kinds `SPRITE_KIND`/`AUDIO_KIND`/`PARTICLE_KIND`/
`EVENT_KIND`.

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
| `state.*` | `state.hurt`, `state.lowhealth`, `state.paused` | Camera (post-FX), Audio Bus, BGM |

A subsystem PR that introduces an id adds a row here.

### `ThemeProfile` schema per asset kind

| Kind | Suffix | `ThemeProfile` field | `ThemeManager.resolve_*` returns | Status |
| --- | --- | --- | --- | --- |
| sprite | `_sprite_asset_id` | `sprite_assets` | `Texture2D` | live |
| audio | `_audio_asset_id` | `audio_assets` | `AudioStream` | live |
| particle | `_particle_asset_id` | `particle_assets` | `ParticleProcessMaterial` / `PackedScene` (typed `Resource`) | live |
| shader | `_shader_asset_id` | `shader_assets` | `ShaderMaterial` | planned (Phase 2) |
| tileset | `_tileset_asset_id` | `tileset_assets` | `TileSet` | planned (Phase 2) |
| post_fx | `_post_fx_asset_id` | `post_fx_assets` | `Environment` / `Material` | planned (Phase 3) |
| music | `_music_asset_id` | `music_assets` | `AudioStream` (looped) | planned (Phase 6) |
| bus_profile | `_bus_profile_asset_id` | `bus_profile_assets` | bus-effect config `Resource` | planned (Phase 7) |

`resolve_sprite` always returns a texture (the `res://icon.svg` engine default).
`resolve_audio` / `resolve_particle` may return `null` until the project sets
`profile_fallback_audio` / `profile_fallback_particle`.

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

### B. World & Environment Subsystem — `WorldEnvironment2D`

Biome-specific parallax layers, ambient particle loops, animated tiles, god rays,
heat haze.

- **Listens:** `biome.entered` / `biome.exited`.
- On `biome.entered` with `context.source_id` = biome id, resolves a
  `biome_profile` (parallax layer textures via `*_sprite_asset_id`, ambient
  particle via `*_particle_asset_id`, god-ray / heat-haze via `*_shader_asset_id`)
  and reconfigures a persistent `ParallaxBackground` + overlay `CanvasLayer`.
- Prefer switching the **active `ThemeProfile`** to the biome, so every other
  subsystem re-themes too; this subsystem then only rebuilds its own layer nodes.
- **Prefabs:** `parallax_rig`, `ambient_particle_layer`, `screen_shader_overlay`.

### C. Camera & Post-Processing Subsystem — `CameraDirector`

Trauma-based shake, dynamic FOV/zoom, chromatic aberration, state-driven
post-processing profiles.

- **Listens:** `camera.*`, `combat.hitstop`, `impact.heavy`/`impact.crit`
  (auto-trauma), `state.hurt`/`state.lowhealth`/`state.paused` (post-FX profile).
- **Trauma model:** `add_trauma(p_amount)` accumulator, `trauma^2` → offset/rotation
  via noise, decays per frame. Events map to trauma amounts through a small
  `@export` table (designer-tunable, not hardcoded per call site).
- **Post-FX:** a `WorldEnvironment` (or full-screen `ColorRect` + `ShaderMaterial`)
  whose `Environment`/material is `ThemeManager.resolve_post_fx(&"state.hurt")`.
  Cross-faded on state change.
- **Camera target:** registered by the gameplay camera holder
  (`set_followed(p_node)`), not discovered.
- **Prefabs:** `camera_rig` (Camera2D + shake driver + post-FX rect).

### D. UI & HUD Polish Subsystem — `HudPolish`

Modular tweening components, catch-up health/mana bars, hover effects, floating
damage text.

- **Listens:** `damage.dealt` / `damage.healed` (floating text + bar catch-up),
  `ui.hover` / `ui.confirm` / `ui.cancel` (widget feedback).
- **Floating damage text:** pooled `Label` prefab, spawned at
  `context.position` projected to screen space via the current camera, animated
  by a reusable `Tweener` component; number/colour driven by `context.magnitude`
  and an `impact.*` sub-id.
- **Catch-up bars:** `CatchUpBar` prefab — two `TextureProgressBar`s (instant +
  lerped trailing), driven by a value the HUD *pushes* (`bar.set_ratio(x)`); the
  subsystem wires `damage.*` → the right bar via a registration map.
- **Tweening:** `/prefabs/tween` component library (`PopTween`, `ShakeTween`,
  `FadeTween`) usable standalone by any UI scene.
- **Assets:** bar fill/underlay `*_sprite_asset_id`, font via a `*_sprite_asset_id`
  analogue or a dedicated `font` kind.

### E. Polyphonic Audio Subsystem (SFX) — `SfxPlayer`

Positional, pooled one-shots with automatic pitch/volume randomisation, orphan
safety across scene swaps.

- **Listens:** every gameplay/`ui.*` event that has an `*_audio_asset_id` mapping.
  A small `@export` route table maps `event_id → audio_asset_id + spatialization`.
- **Pool:** `AudioStreamPlayer2D` pool (positional) + `AudioStreamPlayer` pool
  (dry / UI). `acquire`, set stream from `ThemeManager.resolve_audio`, randomise
  `pitch_scale` (±semitones) and `volume_db` (±range) from per-route `@export`s,
  play, auto-`release` on `finished`.
- **Orphan safety:** the pool lives under the subsystem autoload (never freed on
  scene change); on `SceneTree` change, in-flight players either finish
  (`reparent` to the pool) or are force-released — configurable per route
  (`stop_on_scene_change`).
- **Assets:** `*_audio_asset_id`.

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

Live at 3 kinds (sprite/audio/particle) as parallel dictionaries. At ~5+,
refactor to `@export var asset_tables: Dictionary` (`StringName kind ->
Dictionary`) + `@export var default_assets: Dictionary` and a generic
`ThemeManager.resolve(p_kind, p_asset_id) -> Resource`; `resolve_sprite` /
`resolve_audio` / `resolve_particle` become thin typed wrappers. Its own task,
not folded into a subsystem.

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
