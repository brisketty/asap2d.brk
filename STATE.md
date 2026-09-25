# STATE.md — working notes for agents

Orientation, gotchas and open work for anyone (human or agent) picking this repo
up. **Living document — update it when reality changes.**

- **Design**: [`ARCHITECTURE_SPEC.md`](ARCHITECTURE_SPEC.md)
- **Task backlog + dated history**: [`REMAINING_TASKS.md`](REMAINING_TASKS.md)
- **Asset ids a theme fills**: [`THEME_PROFILE_SLOTS.md`](THEME_PROFILE_SLOTS.md)
- **`ThemeProfile` fields, per-field example + visuals**: [`THEME_PROFILE_FIELDS.md`](THEME_PROFILE_FIELDS.md)
- **What each demo should look like**: [`DEMO_SMOKE_TESTS.md`](DEMO_SMOKE_TESTS.md)
- **Contributing / "add a subsystem" checklist**: [`CONTRIBUTING.md`](CONTRIBUTING.md)
- **Coding rules (authoritative, overrides everything)**: [`CLAUDE.md`](CLAUDE.md)
- **Brisklance addon** (`addons/brisklance/`) has its *own* spec/tasks — a
  plugin self-updater, unrelated to the game framework. Ignore it.

---

## Current state (2026-09-11)

- **Framework complete.** Foundation + all 7 subsystems + tooling, on `main`,
  pushed to `origin` (`github.com/brisketty/asap2d.brk`).
- **15 headless test suites**, all green on Godot 4.7. 9 demo
  scenes run headless with 0 script errors. `lint_conventions` clean.
  `run_asset_scan` + a per-subsystem runtime smoke each pass.
- **9 asset kinds live**: sprite, audio, particle, shader, post_fx, music,
  bus_profile, tileset, screen_tile.
- **2026-09-11 follow-up (Camera demo pass)**: `CameraRig.shake_intensity_scale`
  tuning knob + bigger Crit default; optional `screen_tile` border overlay
  (under/over the state grade, per `THEME_PROFILE_SLOTS.md`); `SfxRoute`
  variation pools (`route_audio_variation_ids`) + a new opt-in
  `SfxPlayer.state_sfx_table` (enter/loop/exit sounds for `state.*`). See
  gotcha **R10** below for the new `CanvasLayer.layer` convention this
  introduced.
- **2026-09-26 addition**: `TileMapDecorator` (`prefabs/tilemap_decorator.gd`)
  — an editor-time procedural TileMap decoration tool (6-layer mask & override
  workflow, `@export_tool_button` actions) + `demo_tilemap_decorator.tscn`
  (§9 in `DEMO_SMOKE_TESTS.md`). Outside the 7-subsystem framework: no
  autoload, no EventBus wiring, no ThemeProfile integration by design. See
  `REMAINING_TASKS.md` History for details.
- `state.*` (`hurt`/`lowhealth`/`paused`/`clear`) feeds Camera (post-FX grade),
  MusicDirector (intensity floor) and AudioMixing (transient bus grade).
- `exports/asset_worklist.md` lists `[tileset] world.tiles` — legitimately
  unmapped (the `AnimatedTileDriver` default id; the demo injects tilesets in
  code, which the scanner can't see). Not a bug.
- Git: `main` is `2c3a1ef` (initial) → merge `a3f6d1b` (`--no-ff`, feature
  commits kept) → ~7 follow-up commits. `framework/foundation` branch still
  exists locally — merged, safe to delete (`git branch -d framework/foundation`).

**No framework work remains.** Everything open is optional polish — see
[TODO](#todo).

---

## Where things are

| What | Path | Notes |
| --- | --- | --- |
| Godot editor | `D:\Programs\Godot_v4.7\Godot_v4.7-stable_win64.exe` | **Not on PATH.** Godot **4.7** stable (despite `project.godot` `features` saying `4.6`). GL Compatibility renderer. |
| Foundation | `scripts/{utility,theme_profile,asset_id_scanner,event_ids}.gd`, `autoloads/{event_bus,theme_manager}.gd` | pillars: EventBus (semantic emission), ThemeManager (resolution + fallback), ThemeProfile, AssetIdScanner |
| Tuning | `scripts/tuning_profile.gd` (`TuningProfile`), `autoloads/tuning.gd` (`Tuning`) | central swappable numeric-constant profile (camera/audio/vfx/world/ui durations, colors, thresholds), mirrors ThemeProfile/ThemeManager but flat scalars - no resolve ladder, `active_profile` is guaranteed non-null after `_ready()`. Registered **first** in `project.godot` autoloads since `AudioMixing._ready()` reads it synchronously. |
| Object pool | `prefabs/node_pool.{gd,tscn}` | `NodePool` — generic; prewarm / acquire / release / ceiling-recycle |
| Tween recipes | `scripts/tweens.gd` | `Tweens` — static `pop` / `fade_out` / `rise_and_fade` / `shake` |
| Tools | `scripts/{run_asset_scan,lint_conventions,tone_stream}.gd` | SceneTree scripts (run headless); ToneStream = procedural WAV for demos/tests |
| Impact VFX (P1) | `autoloads/impact_vfx.gd` (`ImpactVfx`), `scripts/impact_{translation,intensity}.gd`, `prefabs/particle_burst*`, `prefabs/{hit_flash,knockback_receiver,squash_stretch}.{gd,tscn}` | |
| World & Env (P2) | `autoloads/world_environment_2d.gd` (`WorldEnvironment2D`), `scripts/world_translation.gd`, `prefabs/{parallax_rig,ambient_particle_layer,screen_shader_overlay,animated_tile_driver}.{gd,tscn}` | |
| Camera (P3) | `autoloads/camera_director.gd` (`CameraDirector`), `scripts/camera_{translation,trauma}.gd`, `prefabs/{camera_rig,camera_focus_region,screen_tile_border}.{gd,tscn}`, `scripts/screen_tile_{set,translation}.gd` | owns the `Camera2D`; `set_followed(node)`; optional tiled border under/over the state grade; `CameraFocusRegion` = opt-in "region of interest" trigger (zoom-to-fit on enter), a `Control` so its own `position`/`size` get native drag handles on the node itself (see F9), fit behavior per-region via `region_fit_mode` (`CameraTranslation.FocusFitMode`: `CENTERED` shows the whole region, may reveal area outside it; `COVERED` never shows outside the region, may crop part of it - CSS `contain`/`cover`) |
| HUD (P4) | `autoloads/hud_polish.gd` (`HudPolish`), `scripts/hud_translation.gd`, `prefabs/{floating_damage_text,catch_up_bar,hover_pop}.{gd,tscn}` | floating text is **world-space** |
| SFX (P5) | `autoloads/sfx_player.gd` (`SfxPlayer`), `scripts/{sfx_translation,sfx_route,state_sfx_set}.gd`, `prefabs/sfx_voice_pool.{gd,tscn}` + `sfx_voice_{2d,ui}.tscn` | pools under the autoload; `notify_scene_change()` cuts transients; `state_sfx_table` = opt-in enter/loop/exit sounds for `state.*` |
| BGM (P6) | `autoloads/music_director.gd` (`MusicDirector`), `scripts/music_translation.gd` | two-bank stem crossfade; players created in the autoload |
| Mixing (P7) | `autoloads/audio_mixing.gd` (`AudioMixing`), `scripts/{audio_mixing_translation,bus_profile}.gd`, `default_bus_layout.tres` | `Master / Music / Ambience / SFX / UI`; SFX reverb added at runtime |
| Shaders | `assets/shaders/{biome_tint,hurt_vignette}.gdshader` | |
| Theme profiles | `assets/theme_profile_{complete,sparse,forest,cave}.tres` — fields explained in [`THEME_PROFILE_FIELDS.md`](THEME_PROFILE_FIELDS.md) | |
| Demos | `scenes/foundation_demo.tscn` (main scene), `scenes/demo_{impact_vfx,world,camera,hud,sfx,music,mixing,tilemap_decorator}.tscn` | 9 total; per-demo click-through + expected result in [`DEMO_SMOKE_TESTS.md`](DEMO_SMOKE_TESTS.md) |
| TileMap Decorator (editor tool) | `prefabs/tilemap_decorator.{gd,tscn}` (`TileMapDecorator`), `scripts/tilemap_decorator_translation.gd`, `scenes/demo_tilemap_decorator.{gd,tscn}` | `@tool`; 19-layer mask & override workflow (expanded past the spec's 11 - Top/Bottom/Left/Right each get their own Gen_/Overrider pair since a TileMapLayer can only paint from one `tile_set`); 10 `tileset_*` exports (one per category + RegionDefinition) that "Prepare Layers" syncs onto their matching layer(s); 9 `sparseness_*` knobs (0..1, independent of tile weight) for how often a cell is left empty; `@export_tool_button` "Prepare Layers"/"Generate Decorations"; weighted picks read straight off each Gen_* layer's own `tile_set` (`TileData.probability`), no ruleset resource; **not** an EventBus subsystem — no autoload, no ThemeProfile integration |
| Tests | `tests/test_*.gd` (15), `tests/fixture_intensity.tres` | headless `SceneTree` scripts |
| CI | `.github/workflows/test.yml` | import → lint → suites → worklist-drift check, on every push/PR |
| Worklist | `exports/asset_worklist.md` | generated by `run_asset_scan`; git-tracked (`.gitignore` keeps just this file under `/exports`) |

Every autoload above is registered from a `.tscn` wrapper
(`autoloads/<name>.tscn` — one `Node` with the matching `.gd` script
attached), not the bare script — see R2. The table's `.gd` paths are still the
right place to read/edit logic; open the `.tscn` only to assign/save an
exported resource (`TuningProfile`, a route table, `ThemeManager.profile_fallback_*`, ...)
in the Inspector.

Autoload order in `project.godot`: `Tuning`, `EventBus`, `ThemeManager`, then
the 7 subsystems (each may reference any of the first three, so they must
come after).

---

## How to run

```bash
GODOT="/d/Programs/Godot_v4.7/Godot_v4.7-stable_win64.exe"

# the 15 headless test suites (each prints "All ... tests passed." + exits 0)
for t in test_utility test_event_bus test_theme_manager test_tuning test_asset_id_scanner \
		 test_node_pool test_impact_vfx test_world_environment test_camera_director \
		 test_hud_polish test_sfx_player test_music_director test_audio_mixing \
		 test_screen_tile test_tilemap_decorator; do
  "$GODOT" --headless --script res://tests/$t.gd
done

# lint + asset worklist (both also run in CI)
"$GODOT" --headless --script res://scripts/lint_conventions.gd
"$GODOT" --headless --script res://scripts/run_asset_scan.gd

# a demo scene, headless, for N frames
"$GODOT" --headless --quit-after 200 res://scenes/demo_camera.tscn

# import / global-class registration check (SEE GOTCHA H4 — dirties tracked files)
"$GODOT" --headless --editor --quit
```

**At-exit noise to ignore:** every headless run ends with `RID allocations ...
leaked`, `ObjectDB instances were leaked`, `Pages in use`, `Thread object is
being destroyed`, `NavMesh...`. These are Godot's normal teardown chatter, not
failures. Grep them out.

---

## Gotchas

### G — GDScript / typing (this project treats **warnings as errors**)

- **G1. `var x := <Variant>` won't compile.** Anything off `Dictionary`/`Array`
  subscript, `Node.get(name)`, `load(...)`, `.new()` on a loaded script,
  `SceneState.get_node_property_value`, `Object.call(...)` — type it explicitly.
  `var x: Variant = …` is the escape hatch; `as T` narrows it.
- **G2. `a == [x] as Array[T]` parses as `(a == [x]) as Array[T]`** → "Cannot
  convert bool to Array[T]". Wrap: `a == ([x] as Array[T])`. Hit this in three
  test files.
- **G3. Assigning an untyped array to a typed `Array[T]` property via a dynamic
  set fails at runtime** — `subsystem.some_typed_array = [x]` →
  "Invalid assignment … value of type 'Array'". Use a typed local:
  `var t: Array[T] = [x]; subsystem.some_typed_array = t`. **From a `.tscn`
  the opposite is true** — `prop = [ExtResource("1")]` coerces into a typed
  export fine.
- **G4. Godot virtuals are the only allowed `_`-prefixed methods** (`_ready`,
  `_process`, `_init`, `_initialize`/`_run` for SceneTree/EditorScript, …).
  `lint_conventions.gd` enforces this; its `ALLOWED_VIRTUALS` list is the source
  of truth.
- **G5. `Utility.is_object_valid(p_object)` takes `Variant`, not `Object` — on
  purpose.** Godot rejects a previously-freed instance at a typed `Object` param
  *before the body runs*. Variant sidesteps it. Internally: `is Object` →
  `is_instance_valid` → (`is Node` ? `not is_queued_for_deletion()` : ok);
  `is_queued_for_deletion()` doesn't exist on `Resource`/`RefCounted`. **Always
  use this, never `obj == null` alone** (CLAUDE.md §2B).
- **G6. `match` accepts constant patterns** including `EventIds.FOO` and
  comma-separated `EventIds.A, EventIds.B:`. Used in most subsystem dispatchers.
- **G7. A `const Array[Dictionary]` entry can't call `PackedStringArray([...])`
  as a value** — "Assigned value for constant ... isn't a constant
  expression," even though the same literal works fine as a plain `Array`
  value (`"key": ["a", "b"]`). Hit building `TileMapDecorator.TILESET_ASSIGNMENTS`.
  Use a plain array literal and cast at the read site (`as Array`) instead.

### R — Godot resources, scenes & tweens

- **R1. Exported node refs need `node_paths=PackedStringArray(...)` on the
  `[node]` line.** Hand-writing `node_foo = NodePath("Bar")` alone leaves
  `node_foo` **null** at runtime. When overriding an exported ref on an
  *instanced* child, put `node_paths=` on that child's `[node]` line too. Every
  `.tscn` in `scenes/`/`prefabs/` that wires a `node_*` export does this.
- **R2. Autoloads can't wire `@export` node refs.** Subsystem managers therefore
  **create their pools / persistent children in `_ready()`** and hold them in
  plain `var`s (the HudPolish / SfxPlayer / MusicDirector / CameraDirector
  pattern), not via `@export`. Node refs specifically still can't be assigned
  this way (no sibling nodes exist to point at in a one-node autoload scene).
  **A `@export` config var (route tables, `TuningProfile`, etc.) CAN now be set
  in the inspector**: every autoload is registered via a thin wrapper scene
  (`autoloads/<name>.tscn` — one `Node` with the script attached), not the bare
  `.gd`, specifically so the Inspector can save property overrides onto that
  scene's root node. Open the `.tscn`, assign the resource/array, save — it
  persists across editor/game restarts. Still keep a sensible code default
  (`build_default_*()`) for headless/test contexts where nothing wired the
  scene override (`--script` runs don't even load autoloads — see H1).
- **R3. Autoload name must not equal a `class_name`.** `EventBus` /
  `ThemeManager` / `Tuning` have **no `class_name`**. Subsystem managers use
  `class_name <Name>Subsystem` + autoload `<Name>` (distinct), or no
  `class_name`.
- **R4. Two tweens must never animate the same property on the same object.**
  The music crossfade first tried one tween for both stem banks; a following
  `set_intensity` fought it and pinned stems at the floor. Fix: each tween owns
  a disjoint set of targets (crossfade → outgoing bank only; intensity →
  active bank only).
- **R5. Tween shape**: `create_tween().set_parallel(true)` runs steps together;
  `.chain()` returns to sequential; a `tween_callback` after `.chain()` fires
  once, after every parallel step. Kill the previous tween
  (`if Utility.is_object_valid(t): t.kill()`) before re-tweening the same nodes.
- **R6. Pool auto-release uses `CONNECT_ONE_SHOT`.** `signal.connect(cb.bind(x),
  CONNECT_ONE_SHOT)` — a fresh bound callable each acquire, auto-disconnected on
  fire. `is_connected()` can't dedupe bound callables, so don't rely on it.
- **R7. Hit-stop / time-freeze**: `Engine.time_scale = 0.0001`, never `0.0` (a
  true zero freezes `_process` delta, so a delta-based restore never runs). Pair
  with `get_tree().create_timer(t, true, false, true)` — the 4th arg
  `ignore_time_scale = true` — so the restore timer ticks while frozen.
- **R8. `ScreenShaderOverlay` is shared** by the World atmosphere overlay and the
  Camera state-grade. `configure()` swaps instantly (resets `modulate.a`);
  `fade_to()` alpha-crossfades.
- **R9. A stray NUL byte broke a source file once** (`"%s\0%s"` →
  "Unterminated string", no line number). If you get an unexplained
  "Unterminated string": `file scripts/*.gd` (looks for `data` vs `ASCII text`),
  then `perl -0pi -e 's/\x00//g' <file>`.
- **R10. `CanvasLayer.layer` was implicit everywhere (default `0`) until
  `camera_rig.tscn`** — compositing among same-layer `CanvasLayer`s follows
  scene-tree/autoload add order, which is how World's atmosphere overlay ends
  up under Camera's state grade today (`WorldEnvironment2D` autoload registers
  before `CameraDirector`). `CameraRig` now sets explicit layers so its 3
  internal passes have a real order regardless of add-order: `TileUnder=5` <
  `ScreenShaderOverlay=6` < `TileOver=7`, all above World's still-implicit `0`
  so the existing "state grade over world atmosphere" behavior is preserved.
  If you add another full-screen `CanvasLayer` pass anywhere, give it an
  explicit `layer` rather than relying on add-order.
- **R11. GDScript default parameter values must be constant expressions** -
  they can't reference an autoload (`Tuning.active_profile.*`) directly. When a
  function's default needs to be centrally tunable, use a negative sentinel
  (`p_seconds: float = -1.0`) and resolve it in the function body
  (`var seconds := p_seconds if p_seconds >= 0.0 else Tuning.active_profile.foo`).
  Used throughout `scripts/tweens.gd`, `ScreenTileBorder.fade_to`,
  `ScreenShaderOverlay.fade_to`. Safe whenever the real value is always
  non-negative.
- **R12. `Camera2D.zoom` is a magnification factor, not a "see more world"
  factor.** `zoom = (2, 2)` **doubles apparent size** (zooms *in*, sees *less*
  world); `zoom = (0.5, 0.5)` zooms *out* and sees *more*. `zoom = 1` is
  neutral. Easy to get backwards (it reads like it should mean "zoom level =
  how much world is visible", the opposite). `CameraTranslation.compute_fit_zoom`
  had exactly this bug once — used `region_size / viewport_size` directly as
  the zoom value instead of `viewport_size / region_size` — which happened to
  *look* plausible in `CENTERED` mode (its `minf(..., 1.0)` clamp masked the
  inversion for small regions) but was flagrant in `COVERED` mode (zoomed
  *out* tremendously for a small region instead of zooming in to fill it).
  Fixed: the fit ratio is always `viewport_size / region_size`; `CENTERED`
  takes the `min` axis (clamped `<= 1.0`, never magnifies past native);
  `COVERED` takes the `max` axis (no upper clamp - small regions legitimately
  need large zoom-in to fill the screen).

### H — Headless / CLI / tooling

- **H1. `--script` runs do NOT load autoloads.** A `SceneTree` test that
  `preload`s a script naming `EventBus`/`ThemeManager`/any autoload as a bare
  identifier fails to *compile* ("Identifier not found") — which also disables
  its `static` methods. **Pattern:** each subsystem's pure logic lives in an
  autoload-free `scripts/<name>_translation.gd` (`class_name`, static, refs only
  other `class_name` globals + `*_route`/`*_intensity` resources) and is
  unit-tested there. Node wiring is verified by running a demo scene
  (`godot --headless res://scenes/<demo>.tscn`) or a throwaway smoke scene.
- **H2. EditorScripts can't be driven headless.**
  `--headless --editor --script <EditorScript>` hangs (editor stays open);
  `--script` alone runs it as a plain script, not `_run()`. Runnable tools
  (`run_asset_scan`, `lint_conventions`) are `extends SceneTree` with
  `_initialize()` + `quit(code)`.
- **H3. `godot --headless --import` hung once (~120 s+) inside a loop.** Prefer
  `--editor --quit`, or run `--import` alone with a generous timeout.
- **H4. `--headless --editor --quit` normalizes older resources** — rewrites
  `format=3` `.tres`/`.tscn`/`project.godot` to Godot 4.7's sub-format (uid in
  header, `load_steps` dropped, `uid=` on ext_resources, `ShaderMaterial`→
  `Material` type hints). Harmless & idempotent but **dirties tracked files**.
  `git checkout` those specific files before committing unrelated work, or commit
  the normalization alone. `--script` runs alone don't do this. **Do not
  `git checkout -- .` to clean it — that also nukes your own uncommitted edits**
  (learned the hard way). (`570d980` bundled such churn into a docs commit —
  left as-is, not worth force-pushing public history.)
- **H5. Smoke scenes** are throwaway `scenes/_smoke_*.{gd,tscn}` — run, then
  `rm` both files **and** any `_smoke_*.uid` the import generated (one slipped
  into an early commit). Never commit them.
- **H6. `bc` is not installed** in the Git Bash env; sum in the shell loop.

### F — Framework-specific

- **F1. `AssetIdScanner` instantiates scenes; it does not parse `SceneState`.**
  A `.tscn` only serialises *overridden* exports, so a state-only parse found
  **zero** ids. `scan_scene` → `packed.instantiate(GEN_EDIT_STATE_DISABLED)`,
  walks live nodes, `root.free()`. Never enters the tree (`_ready` never fires).
  **Keep framework prefab `_init` trivial.** It also walks `.tres`/`.res` and
  recurses into script-backed `Resource` values (arrays + dicts), gated on
  `PROPERTY_USAGE_SCRIPT_VARIABLE`, with a per-file instance-id cycle guard.
  `run_asset_scan` scans `res://scenes` + `res://prefabs` + `res://assets`.
  **Code-built defaults are invisible** (e.g. `build_default_intensity_table`) —
  you can't scan code.
- **F2. `resolve_sprite` never returns null** (`res://icon.svg` last resort).
  **Every other `resolve_<kind>` can return null** until the project sets
  `ThemeManager.profile_fallback_<kind>`. Each subsystem degrades gracefully on
  null — see the "missing →" column in `THEME_PROFILE_SLOTS.md`.
- **F3. `impact.spark` is used as two kinds**: a *particle* id (the framework
  default in `ImpactTranslation.build_default_intensity_table`) and a *sprite*
  id (`DemoImpactPresenter` in the foundation demo only). Not a conflict — they
  go in different `*_assets` dicts.
- **F4. Adding an asset kind** (currently 9 — `screen_tile` was the latest,
  added for the Camera border overlay): `ThemeProfile` gets
  `<kind>_assets` export + `default_<kind>` + `resolve_<kind>_or_null` +
  `collect_<kind>_ids` + `update_from_<kind>_assets`; `ThemeManager` gets
  `profile_fallback_<kind>` + 2-line `resolve_<kind>` / `has_<kind>` (via
  `resolve_with_ladder` / `profile_asset_or_null` / `profile_default_or_null`);
  `AssetIdScanner` gets `<KIND>_ID_SUFFIX` / `<KIND>_KIND` + a `classify_property`
  branch (more specific suffix first — `_post_fx_asset_id` before
  `_shader_asset_id`) + an `is_reference_mapped` branch; add a `has_<kind>` stub
  to `tests/test_asset_id_scanner.gd`'s `StubThemeManager`. **The
  dict-of-dicts `ThemeProfile` refactor was considered and rejected** (explicit
  typed exports read better in the inspector).
- **F5. No `ThemeProfile` inheritance.** A biome swap replaces the *whole* active
  profile. Shared slots (`sfx.*`, `state.*`) must be repeated in every biome
  profile, or the game must swap back to a base profile for non-biome moments.
  (Follow-up: per-biome sub-resources.)
- **F6. Test harness**: `extends SceneTree`, `func _initialize()`, `expect_int`/
  `expect_true`/`expect_str` returning 0/1, tally into `failure_count`,
  `push_error` + `quit(1)` on failure else `print("All ... passed.") ; quit(0)`.
  Copy an existing `tests/test_*.gd`.
- **F7. `AssetIdScanner` only classifies single-id properties, not collections.**
  `SfxRoute.route_audio_variation_ids` (`Array[StringName]`) is a real audio-id
  list but doesn't end in a scannable suffix on a scalar, so
  `recurse_into_value` walks into it (it's an `Array`) but finds `StringName`
  elements, not `Resource`/`Array`/`Dictionary`, and stops — invisible to
  `run_asset_scan`. List variation ids by hand until the scanner grows
  array-of-id support (see TODO).
- **F8. Two different "random unit" conventions coexist in `*_translation.gd`
  pure functions** — don't mix them up. `SfxTranslation.random_pitch_scale` /
  `random_volume_db` (and `CameraTranslation`'s noise sampling) take a unit in
  **-1..1** (an *offset* around a center). `SfxTranslation.pick_variation_id` /
  `ScreenTileTranslation.pick_variation_index` take a unit in **0..1** (an
  *index* into a list). Both clamp defensively, so a swapped range degrades
  rather than crashes, but picks the wrong end of the list / wrong pitch bias.
- **F9. Gizmo-editable extents without a real physics query**: `CameraFocusRegion`
  wants a draggable rectangle in the 2D editor but never wants an actual
  physics body. **Attempt 1 (superseded)**: a non-monitoring `Area2D` child
  holding a `CollisionShape2D` (`RectangleShape2D`), purely to piggyback
  Godot's shape-editor handles. Papercut: those handles only show when the
  *child* `CollisionShape2D` is selected — selecting `CameraFocusRegion`
  itself (the node you'd naturally click) shows nothing draggable. **Attempt 2
  (does not compile, do not retry)**: overriding `_edit_get_rect` /
  `_edit_use_rect` / `_edit_set_rect` on a `Node2D`. These exist in the engine
  but are **not exposed as GDScript-overridable virtuals in 4.7** — Godot
  errors "overrides a method from native class CanvasItem... won't be called
  by the engine" (warnings-as-errors fails the build). They're wired up in
  C++ for specific built-in nodes only (`GPUParticles2D`'s visibility rect,
  etc.), not a general scripting hook. **Current approach**:
  `CameraFocusRegion` extends `Control` instead of `Node2D` (like
  `ReferenceRect`) and uses the node's own native `position`/`size` as the
  region rect (top-left anchored, not centered). Selecting the node itself
  then gets Godot's built-in Control resize handles for free — no override
  code, no child node. A `Control` composes fine under a plain `Node2D`
  parent and still respects the active `Camera2D`'s transform (canvas
  transform applies to every `CanvasItem`, `Control` included), so it stays a
  correct world-space marker; set `mouse_filter = MOUSE_FILTER_IGNORE` so it
  never intercepts clicks meant for real UI. Detection stays a plain
  `CameraTranslation.is_point_in_region` position check either way, never an
  `Area2D`/physics signal or a `Control` input event. **Reuse this
  `Control`-as-world-space-rect-marker pattern** for any future "author an
  extent visually" prefab — not a raw `Vector2`/`Rect2` export, and not a
  collision-shape workaround.

---

## TODO

**Nothing is load-bearing.** The framework is done; these are refinements, in
rough priority order. Full context + per-phase lists in `REMAINING_TASKS.md`.

### Small, self-contained

- [ ] `HitFlash` shader path — use `flash_shader_asset_id` + `resolve_shader`
  (exists now); currently a `modulate` pulse.
- [ ] `combat.death` / `entity.destroyed` → a death particle burst in `ImpactVfx`.
- [ ] `ui.confirm` / `ui.cancel` widget feedback in `HudPolish` (only `ui.hover`
  is wired).
- [ ] Chromatic-aberration: a dedicated event/param (the grade shader exposes
  the uniform, nothing drives it).
- [ ] Voice stealing / priority in `SfxVoicePool` (at the ceiling `NodePool`
  recycles the oldest, which may cut an important sound).
- [ ] `MusicDirector` sample-lock is best-effort (all stems `play()` in one
  frame); `music_stem_count` is fixed after `_ready()`.
- [ ] Per-bus EQ in `BusProfile` / `AudioMixing` (only gain + reverb now).
- [ ] `SFX_Reverb` as a real send bus (currently a direct effect on `SFX`).
- [ ] `default_tileset` + real shipped tiles so `world.tiles` leaves the worklist.
- [ ] Delete the merged `framework/foundation` branch.
- [ ] `AssetIdScanner` doesn't scan `Array[StringName]` id properties (see F7) —
  `route_audio_variation_ids` and any future variation-pool field is invisible
  to `run_asset_scan`; needs a `recurse_into_value` branch that classifies
  string elements of a suffix-matching array property.
- [ ] `CameraRig` follow is a hard per-frame snap to the target, no smoothing —
  considered adding an optional lerp/deadzone follow mode while investigating
  "micro movement after a shake" (turned out to be the demo's own ambient
  wander, not a shake bug — see `DEMO_SMOKE_TESTS.md` § `demo_camera.tscn`),
  deferred since nothing needed it yet.
- [ ] `ScreenTileBorder` re-picks random tile variations on every
  `get_viewport().size_changed` rebuild (no stable per-position seed) — fine
  for a one-off resize, could look jarring if a game resizes its window
  frequently at runtime.
- [ ] `Tuning`/`TuningProfile` now covers every scalar timing/threshold/scale
  constant across the framework, including what were originally per-instance
  `@export` fields (`AudioMixing.spatial_*` -> `audio_spatial_*`,
  `MusicDirector.music_crossfade_seconds`/`music_stem_floor_db` -> `audio_music_*`,
  `CameraRig.shake_*` -> `camera_shake_*`, `KnockbackReceiver.knockback_strength`/
  `knockback_recover_seconds` -> `vfx_knockback_*`). Folding these in traded
  per-instance override for one global profile - deliberate, since the ask was
  a single centralized knob. What's left un-migrated is structural/identity/
  routing config, not tuning: `MusicDirector.music_stem_count` (array sizing),
  `music_bus`/`music_ambience_bus` (bus routing names), `music_state_tension`
  (a `state.* -> floor` Dictionary, same shape as `ThemeProfile`'s dicts),
  `KnockbackReceiver.knockback_source_id` (per-instance identity). All of these
  are already inspector-editable in place on their own autoload/prefab `.tscn`
  (see R2), so there's no R2 pressure pushing them into `Tuning` too.
- [ ] `SfxPlayer.state_sfx_table` only has room for one active loop
  (`state_loop_player`); two `state.*` events firing back-to-back without a
  `state.clear` between them just retargets the same player (last-wins), no
  crossfade.

### Larger / cross-cutting

- [ ] A `font` asset kind (10th) for `FloatingDamageText`; screen-space (vs
  world-space) floating-text option; `CatchUpBar` textured fills via
  `*_sprite_asset_id`.
- [ ] Per-biome `ThemeProfile` sub-resources (see F5).
- [ ] `Presentation` umbrella autoload owning the 7 subsystems as children — only
  if the 9 autoloads become awkward for load order / teardown / a single
  `notify_scene_change()` fan-out.
- [ ] Editor dock that runs `run_asset_scan` on demand (Brisklance-style).
- [ ] Real game content in `/scenes` + `/prefabs` (out of framework scope).

### Done — do not re-open

Convention-lint script · `AssetIdScanner` walking `.tres`/resource arrays · CI ·
`CONTRIBUTING.md` · `THEME_PROFILE_SLOTS.md` · `tileset` kind + `AnimatedTileDriver` ·
`state.*` → audio · `music`/`bus_profile` kinds · ThemeManager `resolve_with_ladder`
refactor · merge to `main` + push · `screen_tile` kind + `ScreenTileBorder` ·
`CameraRig.shake_intensity_scale` + bigger Crit shake default ·
`SfxRoute.route_audio_variation_ids` · `StateSfxSet` +
`SfxPlayer.state_sfx_table` enter/loop/exit lifecycle · `DEMO_SMOKE_TESTS.md` ·
`THEME_PROFILE_FIELDS.md` · `CameraRig.focus_on_region` (zoom-to-fit) +
`CameraFocusRegion` region-of-interest trigger prefab · `demo_camera.tscn`
checker backdrop · `Tuning`/`TuningProfile` knob (`scripts/tuning_profile.gd`,
`autoloads/tuning.gd`) centralizing scattered subsystem `const`s across
camera/audio/vfx/world/ui, replacing ~15 one-off consts and 2 duplicated
`0.35`-second fade defaults · every autoload registered via a `.tscn` wrapper
scene instead of a bare `.gd`, so `@export` config (route tables, fallback
assets, `TuningProfile`) is savable in the Inspector (updates R2) ·
`CameraRig.shake_*` (decay/max_offset/max_roll/noise_speed/intensity_scale)
migrated from per-instance `@export` into `TuningProfile.camera_shake_*` ·
`AudioMixing.spatial_*`, `MusicDirector.music_crossfade_seconds`/
`music_stem_floor_db`, and `KnockbackReceiver.knockback_strength`/
`knockback_recover_seconds` likewise migrated into `TuningProfile`
(`audio_spatial_*`, `audio_music_crossfade_seconds`, `audio_music_stem_floor_db`,
`vfx_knockback_strength`, `vfx_knockback_recover_seconds`) ·
`CameraTranslation.FocusFitMode` (`CENTERED`/`COVERED`) + `CameraFocusRegion.region_fit_mode`
so a region-of-interest focus can either always show the whole region
(`CENTERED`, may reveal area outside it) or never show outside the region
(`COVERED`, may crop part of it) - threaded through `camera.focus`'s context
(`Utility.CONTEXT_FIT_MODE_KEY`) into `CameraRig.focus_on_region`; a
**Focus Fit** button on `demo_camera.tscn` toggles it live ·
`CameraFocusRegion` now extends `Control` instead of `Node2D` (see F9) so its
own `position`/`size` get Godot's native drag handles directly on the node -
no more `Area2D`/`CollisionShape2D` indirection, and no more needing to
select a child node just to resize the region.

---

## Convention reminders (full text in CLAUDE.md — it overrides defaults)

- Static typing on every var / param / return.
- No `_`-prefixed privates (Godot virtuals excepted). No `$` / `get_node()` —
  exported `node_`-prefixed refs only, connected programmatically in `_ready()`.
- Signal handlers named `handle_<node>_<signal>()`.
- Reference-type (`Array`/`Dictionary`/`Object`) property mutation → call
  `update_from_<property>()` explicitly afterward.
- Standalone-scene root scripts implement `static get_packed_scene()`.
- Object validity: `Utility.is_object_valid(obj)`.
- Early returns over nested `if`/`else`.
- Files live only in the directories `CLAUDE.md §1` lists.
