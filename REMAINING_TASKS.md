# A.S.A.P. Framework — Remaining Tasks

Design: [`ARCHITECTURE_SPEC.md`](ARCHITECTURE_SPEC.md).

Status legend: `[x]` done · `[~]` in progress · `[ ]` not started.

Phase 1–7 subsystem managers follow the naming convention: script
`class_name <Name>Subsystem extends Node`, autoload registered as `<Name>`
(the name in each phase heading is the autoload name).

---

## Phase 0 — Foundation layer  ✅ complete

Delivered and verified against Godot 4.7 (`godot --headless`): 3 test suites,
24 checks, plus a clean editor import and a headless run of the demo scene.

- [x] `scripts/utility.gd` — `Utility.is_object_valid` (Node-guarded queued
  check), `make_spatial_context`, reserved context-key constants.
- [x] `autoloads/event_bus.gd` — `EventBus` autoload; `semantic_event_emitted`
  signal; `emit_semantic_event` with non-empty-id assert. No `class_name`.
- [x] `scripts/theme_profile.gd` — `ThemeProfile` resource; `sprite_assets` /
  `audio_assets` maps with `update_from_*` methods; per-profile defaults;
  `resolve_*_or_null`, `collect_*_ids`.
- [x] `autoloads/theme_manager.gd` — `ThemeManager` autoload; `profile_available`,
  `profile_fallback_sprite`/`_audio`; `active_profile` setter +
  `active_profile_changed`; `set_active_profile_by_id`; `resolve_sprite` /
  `resolve_audio` fallback ladder (never null, logs each downgrade);
  `has_sprite` / `has_audio`.
- [x] `scripts/asset_id_scanner.gd` — `@tool AssetIdScanner`; recursive `.tscn`
  walk; **instantiation-based** id collection (SceneState-only misses defaulted
  exports); `classify_property`; `build_task_list` (dedupe, reference count,
  drop-mapped, priority sort); `format_task_list`.
- [x] `prefabs/demo_impact_presenter.{gd,tscn}` — reference presenter;
  `get_packed_scene()`; bus-connect in `_ready()`; resolve + spawn + status label.
- [x] `scenes/foundation_demo.{gd,tscn}` — main scene; timer/click emit;
  profile-toggle button; pushes `profile_available` to `ThemeManager`.
- [x] `assets/theme_profile_complete.tres`, `assets/theme_profile_sparse.tres`.
- [x] `project.godot` — `EventBus` + `ThemeManager` autoloads; `run/main_scene`.
- [x] `README.md` — four pillars, context contract, fallback ladder, id
  convention, scanner usage.
- [x] `tests/test_event_bus.gd`, `tests/test_theme_manager.gd`,
  `tests/test_asset_id_scanner.gd`.

### Foundation follow-ups  ✅ complete

- [x] `scripts/event_ids.gd` — `EventIds` const `StringName`s per namespace; demo
  migrated (`FoundationDemo`, `DemoImpactPresenter` default).
- [x] `prefabs/node_pool.{gd,tscn}` — `NodePool` (`prewarm`/`acquire`/`release`/
  `clear_pool`, ceiling recycles oldest). `tests/test_node_pool.gd` (13 checks).
- [x] `ThemeProfile` particle support the simple way — `particle_assets`,
  `default_particle`, `resolve_particle_or_null`, `collect_particle_ids`,
  `update_from_particle_assets`. Generic `resolve(kind, id)` refactor **deferred
  to 5+ kinds** (see spec Cross-cutting).
- [x] `ThemeManager.resolve_particle` + `has_particle` + `profile_fallback_particle`;
  `AssetIdScanner` `PARTICLE_ID_SUFFIX` / `PARTICLE_KIND` + `is_reference_mapped`
  branch; `test_asset_id_scanner` covers it.
- [x] `tests/test_utility.gd` (11 checks) — null / live RefCounted / live Node /
  freed Node / queued Node / context shape + defaults. **`is_object_valid`
  param changed `Object` → `Variant`** so a dangling ref can be passed without
  tripping the runtime arg type check.
- [x] `scripts/run_asset_scan.gd` — **`SceneTree` script, not `EditorScript`**
  (an EditorScript can't be driven headless / hangs with `--editor`); runs with
  `godot --headless --script`, writes `exports/asset_worklist.md`. `.gitignore`
  keeps that one file, ignores the rest of `/exports`.
- [x] Subsystem-manager naming settled: `class_name <Name>Subsystem` +
  autoload `<Name>`. Recorded in spec "Conventions for subsystem authors" §1.

---

## Phase 1 — Impact & Combat VFX Subsystem (`ImpactVfx`)

Spec: §Planned subsystems A. Depends on: `NodePool`, `resolve_particle`.

- [ ] `autoloads/impact_vfx.gd` — `class_name ImpactVfxSubsystem`, autoload
  `ImpactVfx`; connect `EventBus.semantic_event_emitted` in `_ready()`;
  `handle_semantic_event_emitted` dispatch on `impact.*`, `combat.hitstop`,
  `combat.knockback`, `entity.destroyed`.
- [ ] `@export` intensity table: `event sub-id → { particle_asset_id, count,
  trauma_hint, hitstop_seconds }` (designer-tunable).
- [ ] `prefabs/particle_burst_pool.{gd,tscn}` — `GPUParticles2D` `NodePool`;
  `burst(p_position, p_particle_asset_id, p_amount)`; material from
  `ThemeManager.resolve_particle`.
- [ ] Hit-flash: `prefabs/hit_flash.gd` shader-material component;
  `register_flashable(p_id, p_canvas_item)` / `unregister_flashable(p_id)`;
  `flash(p_id)` on event; missing shader → no-op.
- [ ] Hit-stop owner: single `Engine.time_scale` pulse; overlapping requests take
  the max; always restores; `@export` max-duration clamp.
- [ ] Knockback: publish resolved `combat.knockback` vector in context **and**
  optional `prefabs/knockback_receiver.{gd,tscn}` opt-in component.
- [ ] Squash & stretch: `prefabs/squash_stretch.gd` component driven by
  `combat.knockback` / `impact.*`.
- [ ] Register autoload in `project.godot`.
- [ ] `scenes/demo_impact_vfx.tscn` — dummy target + emit buttons.
- [ ] `tests/test_impact_vfx.gd` — event → (particle id, count, hitstop seconds)
  translation with a stub `ThemeManager`; hit-stop max/restore logic.
- [ ] Spec registry rows for any new `impact.*` / `combat.*` ids.

---

## Phase 2 — World & Environment Subsystem (`WorldEnvironment2D`)

Spec: §B. Depends on: `resolve_particle`, `resolve_shader`.

- [ ] `ThemeManager.resolve_shader` + `has_shader`; scanner `SHADER_ID_SUFFIX`.
- [ ] `autoloads/world_environment_2d.gd` — listen `biome.entered` /
  `biome.exited`; on enter, prefer
  `ThemeManager.set_active_profile_by_id(context.source_id)` then rebuild own
  layers.
- [ ] `prefabs/parallax_rig.{gd,tscn}` — `ParallaxBackground` +
  configurable-count `ParallaxLayer`s; textures via `*_sprite_asset_id`; scroll
  scales via `@export`.
- [ ] `prefabs/ambient_particle_layer.{gd,tscn}` — looped `GPUParticles2D` on a
  `CanvasLayer`; material via `*_particle_asset_id`.
- [ ] `prefabs/screen_shader_overlay.{gd,tscn}` — full-screen `ColorRect` +
  `ShaderMaterial` for god rays / heat haze; material via `*_shader_asset_id`;
  intensity `@export`; missing shader → hidden.
- [ ] Animated-tile helper: `prefabs/animated_tile_driver.gd` (advances
  `TileMapLayer` animation or swaps `TileSet` via `*_tileset_asset_id`).
- [ ] `biome_profile` schema note in spec (which ids a biome profile must carry).
- [ ] Register autoload; `scenes/demo_world.tscn`; `tests/test_world_environment.gd`
  (biome id → resolved layer/particle/shader id set).

---

## Phase 3 — Camera & Post-Processing Subsystem (`CameraDirector`)

Spec: §C. Depends on: `resolve_post_fx`.

- [ ] `ThemeManager.resolve_post_fx` + `has_post_fx`; scanner `POST_FX_ID_SUFFIX`.
- [ ] `autoloads/camera_director.gd` — `set_followed(p_node)` registration;
  listen `camera.*`, `combat.hitstop`, `impact.heavy`/`impact.crit`, `state.*`.
- [ ] Trauma model: `add_trauma(p_amount)` accumulator, `trauma^2` → noise-driven
  offset/rotation, per-frame decay; `@export` decay rate, max offset, max roll.
- [ ] `@export` event→trauma table (no per-call-site constants).
- [ ] Dynamic zoom/FOV: `focus(p_rect)` / `zoom_to(p_factor, p_seconds)` via
  `Tween`; restore on `camera.focus` clear.
- [ ] `prefabs/camera_rig.{gd,tscn}` — `Camera2D` + shake driver +
  post-FX `CanvasLayer`/`ColorRect`.
- [ ] Post-FX profiles: cross-fade `Environment`/`ShaderMaterial` from
  `resolve_post_fx(state_id)` on `state.hurt`/`state.lowhealth`/`state.paused`;
  chromatic aberration as a shader param.
- [ ] Register autoload; `scenes/demo_camera.tscn`;
  `tests/test_camera_director.gd` (trauma accumulation/decay/clamp; event→trauma
  mapping; state→post-fx id resolution).

---

## Phase 4 — UI & HUD Polish Subsystem (`HudPolish`)

Spec: §D. Depends on: `NodePool`, a camera for world→screen projection.

- [ ] `prefabs/tween/` component library — `PopTween`, `ShakeTween`, `FadeTween`
  (standalone, reusable). Headless test for each easing.
- [ ] `autoloads/hud_polish.gd` — listen `damage.dealt`/`damage.healed`,
  `ui.hover`/`ui.confirm`/`ui.cancel`.
- [ ] `prefabs/floating_damage_text.{gd,tscn}` — pooled `Label`; spawn at
  `context.position` projected to screen; number/colour from `context.magnitude`
  + `impact.*` sub-id; animated by `PopTween` + `FadeTween`.
- [ ] `prefabs/catch_up_bar.{gd,tscn}` — instant + trailing `TextureProgressBar`;
  `set_ratio(p_value)` push API; `@export` catch-up speed; fills via
  `*_sprite_asset_id`.
- [ ] Registration map: `damage.*` source id → target `CatchUpBar`.
- [ ] Hover-effect component `prefabs/hover_pop.gd` for arbitrary `Control`s.
- [ ] Font handling decision (dedicated `font` kind vs sprite-analogue).
- [ ] Register autoload; `scenes/demo_hud.tscn`; `tests/test_hud_polish.gd`
  (magnitude→text/colour mapping; bar catch-up lerp math).

---

## Phase 5 — Polyphonic Audio Subsystem / SFX (`SfxPlayer`)

Spec: §E. Depends on: `NodePool`, Phase 7 bus layout (soft — can start on
default buses).

- [ ] `autoloads/sfx_player.gd` — `@export` route table:
  `event_id → { audio_asset_id, spatialized: bool, pitch_semitones: float,
  volume_db_range: float, stop_on_scene_change: bool }`.
- [ ] `prefabs/sfx_player_2d_pool.{gd,tscn}` — `AudioStreamPlayer2D` `NodePool`
  (positional).
- [ ] `prefabs/sfx_player_ui_pool.{gd,tscn}` — `AudioStreamPlayer` `NodePool`
  (dry / UI bus).
- [ ] Play path: acquire → stream from `ThemeManager.resolve_audio` → randomise
  `pitch_scale` / `volume_db` from route → play → auto-release on `finished`.
- [ ] Orphan safety: pools parented under the autoload; on `SceneTree`
  node-removed / scene change, in-flight players finish (reparented) or force
  release per `stop_on_scene_change`.
- [ ] Register autoload; `scenes/demo_sfx.tscn`; `tests/test_sfx_player.gd`
  (route lookup; pitch/volume randomisation bounds; orphan-release decision).

---

## Phase 6 — BGM & Ambience Subsystem (`MusicDirector`)

Spec: §F. Depends on: `resolve_music`, Phase 7 (soft).

- [ ] `ThemeManager.resolve_music` + `has_music`; scanner `MUSIC_ID_SUFFIX`.
- [ ] `autoloads/music_director.gd` — listen `music.theme`/`music.tension`/
  `music.stinger`, `biome.entered`, `state.*`.
- [ ] `prefabs/stem_player.{gd,tscn}` — N sample-locked `AudioStreamPlayer`s;
  per-stem target `volume_db` from an intensity value; blend without restart.
- [ ] Crossfade: `Tween` old theme down / new up over `@export` seconds; stream
  set from `resolve_music`.
- [ ] `prefabs/ambience_loop.{gd,tscn}` — looped player on the ambience bus;
  swap on `biome.entered`.
- [ ] Stinger: one-shot over the running theme (no duck unless `@export`ed).
- [ ] Register autoload; `scenes/demo_music.tscn`; `tests/test_music_director.gd`
  (intensity→stem volume curve; theme-change crossfade state machine).

---

## Phase 7 — Audio Bus / Mixing Subsystem (`AudioMixing`)

Spec: §G. Best done alongside Phase 5/6 (they consume its buses).

- [ ] `ThemeManager.resolve_bus_profile` + `has_bus_profile`; scanner
  `BUS_PROFILE_ID_SUFFIX`.
- [ ] `default_bus_layout.tres` — `Master → Music, Ambience, SFX (→ SFX_Reverb
  send), UI (dry)`; document in spec.
- [ ] `scripts/bus_profile.gd` — `BusProfile` resource: per-bus reverb room/wet,
  EQ, gain overrides.
- [ ] `autoloads/audio_mixing.gd` — listen `biome.entered` / `state.*`; apply a
  `BusProfile` via effect-parameter `Tween`s (no hard swaps).
- [ ] Guarantee `ui.*` SFX stay on the dry `UI` bus regardless of active profile.
- [ ] Central spatialisation config (`max_distance`, attenuation curve, panning
  strength) that `SfxPlayer` reads.
- [ ] Register autoload; `scenes/demo_mixing.tscn`; `tests/test_audio_mixing.gd`
  (profile → per-bus parameter targets; dry-UI invariant).

---

## Cross-cutting / later

- [ ] `Presentation` umbrella autoload owning the 7 subsystems as children, if
  autoload count / load order / teardown becomes awkward.
- [ ] `ThemeProfile` generic `resolve(kind, id)` refactor (trigger: 5+ asset
  kinds live; at 3 now — sprite/audio/particle).
- [ ] Per-biome `ThemeProfile` sub-resources to keep single profiles small.
- [ ] CI: run all `/tests/*.gd` headless on push; diff `exports/asset_worklist.md`.
- [ ] `CONTRIBUTING.md` — subsystem author checklist (mirrors spec §Conventions).
- [ ] Convention-lint script (`$`, `get_node(`, `func _`, untyped decls).
- [ ] Populate `/scenes` / `/prefabs` real game content (out of framework scope).

---

## History

### 2026-09-10 — Phase 0 follow-ups landed

`EventIds`, `NodePool` (+ test), `ThemeProfile`/`ThemeManager`/`AssetIdScanner`
particle support, `test_utility`, `run_asset_scan`, subsystem naming decision.
5 test suites / 49 checks green; editor import clean; demo + scan run headless.

- `is_object_valid`'s parameter is now `Variant`, not `Object`. Godot's runtime
  rejects a previously-freed instance passed to a typed `Object` param *before*
  the function body runs ("not a subclass of the expected argument class"), so
  the CLAUDE.md contract (handle freed objects) was impossible to honour with
  the typed signature.
- `run_asset_scan` is a `SceneTree` script, **not** an `EditorScript`.
  `godot --headless --editor --script <EditorScript>` hangs (editor stays open)
  and `--script` alone runs it as a plain script, not `_run()`. A `SceneTree`
  script runs cleanly headless and in CI.
- `/exports` is build output (usually untracked), but `exports/asset_worklist.md`
  is a tracked artifact CI diffs — `.gitignore` has `/exports/*` +
  `!/exports/asset_worklist.md`.
- Subsystem manager naming: `class_name <Name>Subsystem` + autoload `<Name>`.

### 2026-09-10 — Phase 0 foundation landed

Built the four-pillar foundation (`Utility`, `EventBus`, `ThemeManager`,
`ThemeProfile`, `AssetIdScanner`) + demo scene + 3 headless test suites.

Notable decisions / fixes during implementation:

- `EventBus` / `ThemeManager` carry **no `class_name`** — an autoload whose name
  equals a global class is an error in Godot 4. Subsystem managers must resolve
  the same way (distinct `class_name`, or none).
- `AssetIdScanner.scan_scene` **instantiates** each scene rather than reading
  `SceneState` — a `.tscn` only serialises *overridden* exports, so a
  state-only parse found zero ids. Instantiation uses
  `GEN_EDIT_STATE_DISABLED` and never enters the tree (`_ready` never runs).
- Exported node references in framework `.tscn`s require
  `node_paths=PackedStringArray(...)` on the `[node]` line (the pattern
  `addons/brisklance/manager/interface/brisklance/brisklance.tscn` uses) — without
  it the `node_*` vars resolve to `null`.
- This project treats GDScript warnings as errors: every `:=` off a `Variant`
  (`SceneState.get_node_property_value`, `load().new()`) must be explicitly typed.
- `ThemeManager.resolve_audio`'s final fallback may be an unset `AudioStream`
  until a project configures `profile_fallback_audio`; sprite resolution always
  yields a texture (`res://icon.svg` default).
