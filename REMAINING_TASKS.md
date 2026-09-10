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

Spec: §Subsystems A. Depends on: `NodePool`, `resolve_particle`. **✅ complete**
(6 test suites / 62 checks green; editor import clean; demo + runtime smoke pass).

- [x] `autoloads/impact_vfx.gd` — `ImpactVfxSubsystem` / autoload `ImpactVfx`;
  dispatch on `impact.*` + `combat.hitstop`. (`combat.knockback` /
  `entity.destroyed` handled by the opt-in components / left for later, not the
  autoload.)
- [x] `scripts/impact_intensity.gd` (`ImpactIntensity` resource) +
  `scripts/impact_translation.gd` (`ImpactTranslation`, autoload-free static:
  `build_lookup`, `build_default_intensity_table`, `compute_hitstop_end`).
  `@export Array[ImpactIntensity]` on the subsystem; explicit table **replaces**
  defaults. Dropped `trauma_hint` — trauma is Camera's (§C).
- [x] `prefabs/particle_burst.tscn` (one-shot GPUParticles2D + built-in
  ParticleProcessMaterial) + `prefabs/particle_burst_pool.{gd,tscn}`
  (`ParticleBurstPool` wrapping a `NodePool`); `burst()` pulls material from
  `ThemeManager.resolve_particle`, falls through to the built-in on a miss.
- [x] `prefabs/hit_flash.{gd,tscn}` — `HitFlash` component; `modulate` pulse on
  matching `impact.*`. Shader flash deferred to Phase 2 (`resolve_shader`);
  `flash_shader_asset_id` export reserved.
- [x] Hit-stop owner — `request_hitstop`, `compute_hitstop_end` (max-of, clamp to
  `hitstop_max_seconds`), `Engine.time_scale = 0.0001`, real-time timer chain
  restores. Smoke-verified engage + release.
- [x] `prefabs/knockback_receiver.{gd,tscn}` — `KnockbackReceiver`; lurch + ease
  back on `combat.knockback`.
- [x] `prefabs/squash_stretch.{gd,tscn}` — `SquashStretch`; elastic squash on
  `impact.*` / `combat.knockback`.
- [x] `ImpactVfx` autoload registered (after `EventBus`, `ThemeManager`).
- [x] `scenes/demo_impact_vfx.{gd,tscn}` — dummy target + 3 components + 4 buttons.
- [x] `tests/test_impact_vfx.gd` (13 checks) — `ImpactTranslation` lookup +
  hit-stop bookkeeping. (Autoload wiring verified via demo/smoke, not `--script`
  — see history.)
- [x] Registry rows: `impact.*` / `combat.*` already covered.

### Phase 1 follow-ups

- [ ] `AssetIdScanner`: also walk exported `Resource` arrays / scan `.tres` under
  `res://assets` so intensity-table `*_asset_id`s become telemetry-visible.
- [ ] `HitFlash` shader path once `resolve_shader` lands (Phase 2).
- [ ] `combat.death` / `entity.destroyed` handling (death burst) — with the
  entity-lifecycle work.

---

## Phase 2 — World & Environment Subsystem (`WorldEnvironment2D`)

Spec: §B. Depends on: `resolve_particle`, `resolve_shader`. **✅ complete**
(7 suites / 78 checks green; editor import clean; demo + biome-switch smoke pass).

- [x] `ThemeManager.resolve_shader` + `has_shader` + `profile_fallback_shader`;
  `ThemeProfile.shader_assets` + `default_shader` + `resolve_shader_or_null` +
  `collect_shader_ids` (now via `collect_ids_of`); scanner `SHADER_ID_SUFFIX` /
  `SHADER_KIND` + branches; `ThemeManager.get_active_profile_id()`.
- [x] `autoloads/world_environment_2d.gd` — `WorldEnvironment2DSubsystem` /
  autoload `WorldEnvironment2D`; `biome.entered` → optional profile switch (via
  `WorldTranslation.should_switch_profile`) + rebuild; `biome.exited` → teardown;
  also rebuilds on `active_profile_changed` (`is_rebuilding` guard).
- [x] `scripts/world_translation.gd` (`WorldTranslation`, autoload-free static:
  `build_scroll_scales`, `resolve_layer_textures`, `should_switch_profile`).
- [x] `prefabs/parallax_rig.{gd,tscn}` — `ParallaxRig extends ParallaxBackground`;
  `configure(textures, scroll_scales)` rebuilds `ParallaxLayer` + tiling
  `Sprite2D` per texture; ids `world.parallax.{far,mid,near}`.
- [x] `prefabs/ambient_particle_layer.{gd,tscn}` — `AmbientParticleLayer`;
  `configure(material)`; id `world.ambient`; null → emission stops.
- [x] `prefabs/screen_shader_overlay.{gd,tscn}` — `ScreenShaderOverlay`;
  `configure(shader_material)`; id `world.overlay`; null → `ColorRect` hidden.
- [x] Register autoload; `scenes/demo_world.{gd,tscn}` (forest/cave/exit + panning
  camera + two biome profiles + `biome_tint.gdshader`);
  `tests/test_world_environment.gd` (15 checks).

### Phase 2 follow-ups

- [x] Animated tiles — `tileset` asset kind (8th) end to end
  (`ThemeProfile.tileset_assets` / `resolve_tileset` / `has_tileset` / scanner
  `TILESET_ID_SUFFIX` / `TILESET_KIND`); `prefabs/animated_tile_driver.{gd,tscn}`
  (`AnimatedTileDriver` — swaps `TileMapLayer.tile_set` on `active_profile_changed`,
  keeps the current one on a null resolve). Per-tile animation is left to the
  `TileSet` / engine. Demo: a `Ground` layer + driver in `demo_world` with
  code-built per-biome tilesets. **`world.tiles` shows in the worklist** — it has
  no shipped mapping (the demo injects tilesets at runtime).
- [ ] `biome_profile` still uses fixed constant ids in the subsystem, not
  `@export`s (autoload can't wire exports) — same limitation as the impact
  intensity table; the "scan `.tres`/`Resource` arrays" follow-up covers making
  them telemetry-visible.

---

## Phase 3 — Camera & Post-Processing Subsystem (`CameraDirector`)

Spec: §C. Depends on: `resolve_post_fx`. **✅ complete** (8 suites / 94 checks
green; editor import clean; demo + camera runtime smoke pass).

- [x] `post_fx` asset kind end to end — `ThemeProfile.post_fx_assets` +
  `default_post_fx` + `resolve_post_fx_or_null` + `collect_post_fx_ids`;
  `ThemeManager.resolve_post_fx` / `has_post_fx` / `profile_fallback_post_fx`;
  scanner `POST_FX_ID_SUFFIX` / `POST_FX_KIND` (checked before `shader`).
- [x] `autoloads/camera_director.gd` — `CameraDirectorSubsystem` / autoload
  `CameraDirector`; `set_followed(node)`; dispatch trauma table + `camera.shake`
  / `camera.zoom` / `camera.focus` + `state.{hurt,lowhealth,paused,clear}`.
  `EventIds.STATE_CLEAR` added.
- [x] `scripts/camera_trauma.gd` (`CameraTrauma` resource) +
  `scripts/camera_translation.gd` (`CameraTranslation`, autoload-free static:
  trauma math + event→trauma table, default table).
- [x] `prefabs/camera_rig.{gd,tscn}` — `CameraRig extends Node2D`: `Camera2D` +
  `FastNoiseLite` shake in `_process` + zoom `Tween` + focus `Tween` + child
  `ScreenShaderOverlay`. Follows registered node unless focused.
- [x] `ScreenShaderOverlay.fade_to(material, seconds)` — alpha crossfade for the
  state grade (World overlay also benefits).
- [x] Register autoload; `scenes/demo_camera.{gd,tscn}` (wandering player,
  crit/shake/hurt/clear/zoom buttons, `hurt_vignette.gdshader` in the `complete`
  profile); `tests/test_camera_director.gd` (15 checks).

### Phase 3 follow-ups

- [ ] Chromatic aberration — the grade shader exposes it as a uniform but there
  is no dedicated event/parameter driving it yet.
- [ ] `camera.focus` currently pans to a point; a `focus(rect)` that also frames
  (zoom-to-fit) is unimplemented.

---

## Phase 4 — UI & HUD Polish Subsystem (`HudPolish`)

Spec: §D. Depends on: `NodePool`, `CameraDirector`. **✅ complete** (10 suites /
109 checks green; editor import clean; demo + HUD runtime smoke pass).

- [x] `scripts/tweens.gd` (`Tweens`, static recipes: `pop`, `fade_out`,
  `rise_and_fade`, `shake`). Kept as a static utility rather than Node
  components - equally reusable, no scene overhead.
- [x] `autoloads/hud_polish.gd` — `HudPolishSubsystem` / autoload `HudPolish`;
  `damage.dealt`/`damage.healed` → pooled floating number + optional bar push;
  `register_bar` / `unregister_bar` / `push_bar_ratio`.
- [x] `scripts/hud_translation.gd` (`HudTranslation`, autoload-free static:
  `damage_text`, `damage_color`, `catch_up_step`, `is_heal`).
- [x] `prefabs/floating_damage_text.{gd,tscn}` — **world-space** `Node2D` + Label
  (no screen projection needed - the camera renders it), pooled, rise+fade via
  `Tweens.rise_and_fade`, `finished` → pool release (`CONNECT_ONE_SHOT`).
- [x] `prefabs/catch_up_bar.{gd,tscn}` — front `ProgressBar` (snap) over trailing
  `ProgressBar` (eased); `set_ratio()` push API; `@export catch_up_speed`;
  snaps forward on heal.
- [x] Registration map (`bars_by_id`) + `push_bar_ratio(id, ratio)`.
- [x] `prefabs/hover_pop.{gd,tscn}` — `HoverPop` for any `Control`; pops +
  optional `ui.hover` emit.
- [x] Register autoload; `scenes/demo_hud.{gd,tscn}`; `tests/test_hud_polish.gd`
  (15 checks).

### Phase 4 follow-ups

- [ ] Dedicated `font` asset kind (floating text uses the project theme font).
- [ ] `ui.confirm` / `ui.cancel` widget feedback (only `ui.hover` wired).
- [ ] Screen-space floating-text option (current is world-space, so it shakes /
  zooms with the camera).
- [ ] Bar fills via `*_sprite_asset_id` (`ProgressBar` is untextured for now).

---

## Phase 5 — Polyphonic Audio Subsystem / SFX (`SfxPlayer`)

Spec: §E. Depends on: `NodePool`. **✅ complete** (11 suites / 124 checks green;
editor import clean; demo + SFX runtime smoke pass).

- [x] `autoloads/sfx_player.gd` — `SfxPlayerSubsystem` / autoload `SfxPlayer`;
  `@export Array[SfxRoute]` (empty → `build_default_route_table`); dispatches to
  the positional or UI pool by `route_spatialized`; per-instance `RNG`.
- [x] `scripts/sfx_route.gd` (`SfxRoute` resource) +
  `scripts/sfx_translation.gd` (`SfxTranslation`, autoload-free static:
  lookup, default table, `random_pitch_scale` = `2^(unit·semitones/12)`,
  `random_volume_db`, `should_keep_on_scene_change`).
- [x] `prefabs/sfx_voice_pool.{gd,tscn}` — one `SfxVoicePool` script, two voice
  scenes: `sfx_voice_2d.tscn` (`AudioStreamPlayer2D`, bus `SFX`) and
  `sfx_voice_ui.tscn` (`AudioStreamPlayer`, bus `UI`). (Merged the two prefabs
  from the task list — one script, `.set()`-based config serves both classes.)
- [x] Play path: null-stream guard → acquire → configure → play → auto-release
  on `finished` (`CONNECT_ONE_SHOT`).
- [x] Orphan safety: pools under the autoload (voices survive scene changes);
  `SfxPlayer.notify_scene_change()` → `stop_transient()` cuts only
  `route_stop_on_scene_change` voices (tagged via `set_meta`).
- [x] `default_bus_layout.tres` — `Master / Music / Ambience / SFX / UI`.
- [x] Register autoload; `scenes/demo_sfx.{gd,tscn}` (+ `scripts/tone_stream.gd`
  procedural-tone helper); `tests/test_sfx_player.gd` (15 checks).

### Phase 5 follow-ups

- [ ] Automatic scene-change detection (currently the game must call
  `notify_scene_change()`).
- [ ] Voice stealing / priority when a pool hits `pool_max_count` (currently
  `NodePool` recycles the oldest, which may cut an important sound).

---

## Phase 6 — BGM & Ambience Subsystem (`MusicDirector`)

Spec: §F. Depends on: `resolve_music` (done). **✅ complete** (12 suites / 149
checks green; editor import clean; demo + music runtime smoke pass).

- [x] `resolve_music` / `has_music` / scanner `MUSIC_ID_SUFFIX` — done in the
  kind-6 refactor step.
- [x] `autoloads/music_director.gd` — `MusicDirectorSubsystem` / autoload
  `MusicDirector`; `music.theme` / `music.tension` / `music.stinger` /
  `biome.entered` / `biome.exited`.
- [x] `scripts/music_translation.gd` (`MusicTranslation`, autoload-free static:
  `stem_asset_id`, `stem_activation`, `stem_volume_db`, `crossfade_volumes`,
  `resolve_stem_streams`).
- [x] Stems: **two banks** of N `AudioStreamPlayer`s created in the autoload
  (not a prefab - matches the HudPolish/SfxPlayer "autoload owns its pool"
  pattern). `set_intensity` retweens the active bank; theme change fades incoming
  up / outgoing down on separate tweens (no same-player conflict).
- [x] Crossfade over `@export music_crossfade_seconds`; streams from
  `MusicTranslation.resolve_stem_streams`.
- [x] Ambience: one looping player on bus `Ambience`, swapped on `biome.entered`.
- [x] Stinger: one player on bus `Music`, fired over the theme, no duck.
- [x] Register autoload; `scenes/demo_music.{gd,tscn}` (+ `ToneStream` looping
  support); `tests/test_music_director.gd` (15 checks).

### Phase 6 follow-ups

- [x] `state.*` → intensity floor — `music_state_tension` (default hurt 0.5 /
  lowhealth 0.85); `MusicTranslation.effective_intensity` = max(requested,
  state); `state.clear` releases it.
- [ ] Tighter sample-lock (currently all stems `play()` in one frame - fine at
  60 fps, may drift on a hitch).
- [ ] `music_stem_count` is fixed after `_ready()`; changing it needs a restart.

---

## Phase 7 — Audio Bus / Mixing Subsystem (`AudioMixing`)

Spec: §G. **✅ complete** (12 suites / 160 checks green; editor import clean;
demo + mixing runtime smoke pass). **Last subsystem — the framework is done.**

- [x] `bus_profile` asset kind (7th): `ThemeProfile.bus_profile_assets` +
  `default_bus_profile` + `resolve_bus_profile_or_null` + `collect_bus_profile_ids`;
  `ThemeManager.resolve_bus_profile` / `has_bus_profile` / `profile_fallback_bus_profile`;
  scanner `BUS_PROFILE_ID_SUFFIX` / `BUS_PROFILE_KIND` + branches.
- [x] `default_bus_layout.tres` kept minimal (`Master ← Music, Ambience, SFX, UI`);
  the SFX reverb is **added at runtime** by `AudioMixing._ready()` (subsystem owns
  its effect, `.tres` stays editable) rather than baked in.
- [x] `scripts/bus_profile.gd` (`BusProfile` resource: per-bus dB trims + reverb
  wet/room) + `scripts/audio_mixing_translation.gd` (`AudioMixingTranslation`,
  autoload-free static: `neutral_profile`, `make_profile`, `bus_targets` (never
  `UI`), `is_dry_bus`, `reverb_{wet,room_size}_for`).
- [x] `autoloads/audio_mixing.gd` — `AudioMixingSubsystem` / autoload
  `AudioMixing`; `biome.entered` → `resolve_bus_profile` → `apply_bus_profile`
  tweens bus gains (`set_bus_volume_db` via `tween_method`) + reverb wet/room;
  `biome.exited` → neutral.
- [x] Dry-UI guarantee: `bus_targets` never lists `UI`, reverb only on `SFX`;
  `is_ui_bus_dry()` asserts it.
- [x] `@export spatial_{max_distance,attenuation,panning_strength}` +
  `apply_spatialisation(voice)`, called by `SfxPlayer` after acquiring a
  positional voice.
- [x] Register autoload; `scenes/demo_mixing.{gd,tscn}`;
  `tests/test_audio_mixing.gd` (13 checks).

### Phase 7 follow-ups

- [x] `state.*` bus overrides — `state.hurt`/`lowhealth`/`paused` apply a
  transient `resolve_bus_profile(state_id)` over the stored `biome_profile`;
  `state.clear` restores the biome.
- [ ] Per-bus EQ (only gain + reverb now).
- [ ] `SFX_Reverb` as a real send bus (currently a direct effect on `SFX`).

---

## Cross-cutting / later

- [ ] `Presentation` umbrella autoload owning the 7 subsystems as children, if
  autoload count / load order / teardown becomes awkward.
- [x] ~~`ThemeProfile` generic `resolve(kind, id)` refactor~~ — **decided against**
  at kind 6. `ThemeProfile` keeps explicit typed exports (inspector-friendly);
  the `ThemeManager` duplication was removed via `resolve_with_ladder` +
  `profile_asset_or_null` instead. See spec "`ThemeProfile` scaling".
- [ ] Per-biome `ThemeProfile` sub-resources to keep single profiles small.
- [x] CI — `.github/workflows/test.yml` runs the 12 headless suites + editor
  import on every push/PR and fails on `asset_worklist.md` drift.
- [x] `CONTRIBUTING.md` — pillars + the "adding a subsystem" checklist + coding
  quick reference.
- [x] Convention-lint script — `scripts/lint_conventions.gd` flags `$`,
  `get_node(`/`get_node_or_null(`, and non-virtual `_`-prefixed methods across
  `scripts`/`autoloads`/`prefabs`/`scenes`. Wired into CI. (Untyped-decl checking
  left to warnings-as-errors.)
- [x] `AssetIdScanner` walks `.tres` / `.res` and nested script-backed
  `Resource`s (arrays + dictionaries included) — `scan_resource`,
  `collect_ids_from_object` / `recurse_into_value`, `PROPERTY_USAGE_SCRIPT_VARIABLE`
  filter, instance-id cycle guard. `run_asset_scan` now also scans `res://assets`.
  Code-built defaults (e.g. `ImpactTranslation.build_default_intensity_table`)
  are still invisible — you can't scan code.
- [ ] Populate `/scenes` / `/prefabs` real game content (out of framework scope).

---

## History

### 2026-09-10 — `tileset` asset kind + AnimatedTileDriver (Phase 2 follow-up)

8th asset kind, closes out World & Environment. `AnimatedTileDriver` is an
opt-in `TileMapLayer` sibling that re-resolves `world.tiles` on
`active_profile_changed`. `demo_world` grew a `Ground` layer with code-built
per-biome `TileSet`s (forest atlas tile (0,0), cave (1,1)) so the swap is
visible. Smoke: forest → 24 floor cells at tile (0,0); cave → tileset swapped
to a different object, repainted at (1,1). 12 suites / 171 checks.

`exports/asset_worklist.md` now lists `[tileset] world.tiles` — legitimately
unmapped (no shipped tiles; the demo injects tilesets in code, which the scanner
can't see). First non-empty worklist.

### 2026-09-10 — `state.*` wired into audio (post-merge polish)

- `MusicDirector` — `state.hurt`/`lowhealth`/`paused` impose an intensity *floor*
  (`music_state_tension`, default 0.5 / 0.85); `MusicTranslation.effective_intensity`
  takes `max(requested, state_floor)`; `set_intensity` / `set_state_intensity`
  both feed `apply_intensity`. `state.clear` releases the floor.
- `AudioMixing` — the same `state.*` events apply a transient
  `resolve_bus_profile(state_id)` grade *over* the remembered `biome_profile`
  (not overwriting it); `state.clear` re-applies the biome.
- Demo buttons added to `demo_music` / `demo_mixing`. Camera already reacted to
  `state.*`; now all three of the state-aware subsystems do.
- 12 suites / 170 checks; smoke verified `state.lowhealth` lifting stems and
  `state.clear` restoring both music tension and the biome bus profile.

### 2026-09-10 — Scanner deepening + convention lint

- `AssetIdScanner` now walks `.tres`/`.res` and recurses into script-backed
  `Resource` values (and arrays/dictionaries of them), not just scene nodes.
  Property walk is gated on `PROPERTY_USAGE_SCRIPT_VARIABLE`; a per-file
  instance-id set guards shared-resource cycles. `run_asset_scan` scans
  `res://assets` too. `tests/fixture_intensity.tres` covers it (5 new checks;
  165 total).
- `scripts/lint_conventions.gd` — `$` / `get_node` / non-virtual `_`-method
  lint, clean across the framework, wired into `.github/workflows/test.yml`
  after the import step.

### 2026-09-10 — CI + CONTRIBUTING

`.github/workflows/test.yml` (setup-godot 4.7 → import → 12 suites → worklist
drift check). `CONTRIBUTING.md` — the four pillars and the 9-step "adding a
subsystem" checklist distilled from doing it seven times.

### 2026-09-10 — Phase 7: Audio Bus / Mixing — framework complete

`AudioMixing` autoload + `AudioMixingTranslation` (pure) + `BusProfile`;
`bus_profile` asset kind (7th); runtime SFX reverb install; per-bus gain +
reverb tweens on `biome.entered`; central spatialisation config applied by
`SfxPlayer`; `demo_mixing`; `test_audio_mixing` (13). 12 suites / 160 checks.
Smoke: `biome.entered cave` → music bus to -3 dB, reverb wet 0 → 0.5, UI bus
untouched and still effect-free; `biome.exited` → neutral.

**All 7 subsystems are now implemented.** Foundation + 7 subsystems + the
kind-6 refactor = 9 commits on `framework/foundation`; 13 headless test suites
(160 checks), 8 demo scenes, all green on Godot 4.7.

- SFX reverb is added to the `SFX` bus at runtime, not baked into
  `default_bus_layout.tres` — keeps the layout file editable and the effect
  owned by the subsystem.
- The dry-UI guarantee is structural: `bus_targets` never yields `UI` and the
  reverb lives only on `SFX`, so nothing the subsystem does can colour interface
  sound.

### 2026-09-10 — Phase 6: BGM & Ambience

`MusicDirector` autoload + `MusicTranslation` (pure); two-bank stem crossfade;
looping ambience + stinger players; `demo_music` (tension slider) + looping
`ToneStream`; `test_music_director` (15). 12 suites / 149 checks green.
Smoke: theme forest → tension 1.0 lifts all 3 stems to 0 dB → tension 0.2 drops
stem 2 to the floor → theme cave crossfades banks (new up, old down, old stops).

- **Bug found + fixed in the smoke:** the first design had one tween per
  crossfade animating *both* banks' `volume_db`; a following `set_intensity`
  fought it on the incoming stems (pinned at the floor for the whole 2 s).
  Fix: crossfade animates only the *outgoing* bank; the incoming bank fades up
  through `set_intensity` — different players, no conflict.
- Stems are created in the autoload, not a `stem_player` prefab — consistent
  with HudPolish/SfxPlayer owning their pools inline.

### 2026-09-10 — ThemeManager resolution refactor + `music` kind (kind 6)

Standalone step before Phase 6. Added the `music` asset kind
(`ThemeProfile.music_assets` / `resolve_music` / `has_music` / scanner
`MUSIC_ID_SUFFIX`). **Decided against** the dictionary-of-dictionaries
`ThemeProfile` refactor — explicit typed `@export` dictionaries read better in
the inspector. Instead collapsed the `ThemeManager` duplication into
`resolve_with_ladder(kind, id, profile_asset, profile_default, engine_fallback)`
+ `profile_asset_or_null(method, id)` + `profile_default_or_null(property)`; each
`resolve_<kind>` / `has_<kind>` is now 1–2 lines. `theme_manager.gd` 160 → 150
lines but adding a kind is ~half the diff. 10 suites / 134 checks green.

### 2026-09-10 — Phase 5: Polyphonic Audio / SFX

`SfxPlayer` autoload + `SfxTranslation` (pure) + `SfxRoute`; `SfxVoicePool`
(one script, 2D + UI voice scenes); `default_bus_layout.tres` (5 buses);
`ToneStream` helper; `demo_sfx`; `test_sfx_player` (15). 11 suites / 124 checks.
Smoke: 3 positional + 1 UI voice acquired → `notify_scene_change()` cuts only
the transient one → the rest play out and auto-release.

- Merged the task list's two pool prefabs into one `SfxVoicePool` — `.set()` /
  `.call()` on the voice `Node` serves both `AudioStreamPlayer2D` and
  `AudioStreamPlayer` from one code path.
- Orphan safety is mostly free: the pools live under the autoload, so voices
  aren't in the scene that changes. Only the explicit "cut this on scene change"
  case needs code (`stop_transient` + a `keep_on_scene_change` meta tag).
- `default_bus_layout.tres` created here (Phase 7's territory) as a stub so
  `SFX` / `UI` buses exist; Phase 7 adds effects and sends.

### 2026-09-10 — Phase 4: UI & HUD Polish

`HudPolish` autoload + `HudTranslation` (pure) + `Tweens` recipes;
`FloatingDamageText` (pooled, world-space), `CatchUpBar`, `HoverPop` prefabs;
`demo_hud`; `test_hud_polish` (15). 9 suites / 109 checks green. Smoke:
`damage.dealt` acquires a pooled number → releases after its lifetime;
`set_ratio(0.4)` snaps the front bar, trail eases down and catches up.

- Floating text is **world-space** (`Node2D`), not screen-projected — simplest,
  and the CameraDirector camera already renders it. Trade-off: it shakes/zooms
  with the camera; a screen-space option is a follow-up.
- `Tweens` shipped as a static recipe utility (`scripts/`), not Node components —
  callable from anywhere, `p_node.create_tween()` needs only that the node is in
  the tree.
- `font` asset kind deferred; no 6th kind yet, so the generic
  `ThemeManager.resolve(kind,id)` refactor is still pending its trigger.

### 2026-09-10 — Phase 3: Camera & Post-Processing

`CameraDirector` autoload + `CameraTranslation` (pure trauma math + table) +
`CameraTrauma`; `CameraRig` prefab (shake / zoom / focus / post-FX overlay);
`post_fx` asset kind; `ScreenShaderOverlay.fade_to`; `demo_camera` +
`hurt_vignette.gdshader`; `test_camera_director` (15). 8 suites / 94 checks.
Smoke: follow → crit/shake trauma → hurt grade fades in → zoom tween → clear
fades out → trauma decays to 0.

- `post_fx` is a distinct kind from `shader` (own suffix, own namespace) so the
  artist worklist separates biome atmosphere from damage-state art. 5 kinds now;
  the 6th triggers the generic `resolve(kind, id)` refactor.
- `CameraRig` is created by the autoload and owns the `Camera2D`; gameplay
  registers the follow target via `set_followed`, matching the "no node
  discovery" rule.

### 2026-09-10 — Phase 2: World & Environment

`WorldEnvironment2D` autoload + `WorldTranslation` (pure); `ParallaxRig` /
`AmbientParticleLayer` / `ScreenShaderOverlay` prefabs; `shader` asset kind
across `ThemeProfile` / `ThemeManager` / `AssetIdScanner`; `demo_world` with
forest/cave profiles + `biome_tint.gdshader`; `test_world_environment` (15).
7 suites / 78 checks green. Smoke: forest→cave→exit rebuilds/tears down layers,
ambient particles, and the overlay; forest's missing `world.ambient` mapping
falls back cleanly (no emission, no error).

- Subsystem resolves a **fixed** id set (`world.parallax.*`, `world.ambient`,
  `world.overlay`) — the active `ThemeProfile` maps those per biome. `biome.entered`
  switches the profile so all subsystems re-theme, not just this one.
- `collect_*_ids` deduped into `collect_ids_of(Dictionary)` while adding the 4th
  kind. Generic `resolve(kind, id)` refactor trigger bumped to 6+ kinds.
- Animated tiles + `tileset` kind deferred (Phase 2 follow-up).

### 2026-09-10 — Phase 1: Impact & Combat VFX

`ImpactVfx` autoload + `ImpactTranslation` (pure) + `ImpactIntensity`;
`ParticleBurstPool` (over `NodePool`); `HitFlash` / `KnockbackReceiver` /
`SquashStretch` opt-in components; `demo_impact_vfx`; `test_impact_vfx` (13).
6 suites / 62 checks green.

- **Autoload-referencing scripts can't be `preload`ed in a `--script` run.**
  A headless `godot --headless --script <SceneTree>` does **not** load autoloads,
  and a script that names `EventBus` / `ThemeManager` as a bare identifier fails
  to *compile* there ("Identifier not found: EventBus") — which also kills its
  static methods. Fix / pattern: keep each subsystem's pure logic in an
  autoload-free `*_translation.gd` (`class_name`, static) and unit-test that;
  verify the Node wiring via a scene run / smoke instead.
- Hit-stop uses `Engine.time_scale = 0.0001` (not `0.0` — a true zero freezes
  `_process` delta so a delta-based restore never fires) + real-time
  `create_timer(t, true, false, true)` whose 4th arg `ignore_time_scale` makes
  it tick while frozen.
- Trauma dropped from the intensity table — `impact.heavy`/`crit` auto-trauma is
  Camera's (§C), consumed directly off the bus.

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
