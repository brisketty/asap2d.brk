# ASAP Framework

The **A.S.A.P. Framework** (Automated Skeleton, Artist Pipeline) dictates the
structural engineering of all game systems to decouple gameplay logic from
sensory presentation.

## The four pillars

1. **Pure Logic (Semantic Emission).** Core logic scripts never reference visual
   nodes, audio streams, or UI. They communicate only by broadcasting abstract
   string ids plus spatial data over the Global Event Bus.
2. **Profile-Driven Translation.** Presentation managers fetch assets from the
   centralized Theme Manager using string ids. No hardcoded asset paths.
3. **Defensive Defaulting.** Every asset lookup falls back to a default asset.
   Lookups never return `null` and never crash the engine on missing art.
4. **Telemetry-Gated Scoping.** Asset ids are exposed as scannable `@export`
   vars so tooling can statically parse scenes and emit a prioritized,
   zero-waste worklist for artists.

## Foundation layer

| Piece | Path | Role |
| --- | --- | --- |
| `Utility` | `scripts/utility.gd` | `is_object_valid`, `make_spatial_context` |
| `EventBus` (autoload) | `autoloads/event_bus.gd` | `emit_semantic_event(id, context)` / `semantic_event_emitted` |
| `ThemeManager` (autoload) | `autoloads/theme_manager.gd` | `resolve_{sprite,audio,particle,shader}` with fallback ladder |
| `ThemeProfile` | `scripts/theme_profile.gd` | id → asset maps + per-profile defaults |
| `AssetIdScanner` | `scripts/asset_id_scanner.gd` | scene scan → artist worklist |

### EventBus context contract

`emit_semantic_event(p_event_id, p_context)` — `p_event_id` is a namespaced
`StringName` such as `&"impact.basic"`. `p_context` follows
`Utility.make_spatial_context`:

| key | type | meaning |
| --- | --- | --- |
| `position` | `Vector2` | where it happened (global space) |
| `direction` | `Vector2` | unit direction (knockback / facing) |
| `magnitude` | `float` | abstract intensity (damage, force) |
| `source_id` | `StringName` | abstract id of the emitter |

Consumers must tolerate missing keys.

### ThemeManager fallback ladder

`resolve_sprite(id)` returns, in order: the active profile's mapped texture →
the active profile's `default_sprite` → `ThemeManager.profile_fallback_sprite`.
Each downgrade logs once via `printerr`. `resolve_audio(id)` mirrors this.

### Scannable id convention

Presentation scripts expose ids as `@export` vars with these suffixes:

- `*_sprite_asset_id` / `*_audio_asset_id` / `*_particle_asset_id` /
  `*_shader_asset_id` — resolved through `ThemeManager.resolve_<kind>`
- `*_event_id` — an `EventBus` semantic event id (use an `EventIds` constant)

### Generating the artist worklist

```gdscript
var refs := AssetIdScanner.scan_directory("res://scenes")
print(AssetIdScanner.format_task_list(AssetIdScanner.build_task_list(refs, ThemeManager)))
```

Lists only ids not yet mapped in the active `ThemeProfile`, most-referenced
first.

## Demo

`scenes/foundation_demo.tscn` (the project's main scene) emits `&"impact.basic"`
on a timer and on click. `DemoImpactPresenter` translates it into a spark sprite
via `ThemeManager`. The on-screen button swaps between `theme_profile_complete`
and `theme_profile_sparse` to show the fallback ladder take over live.

## Tests

Headless `SceneTree` scripts under `tests/`, one per foundation piece:

```
godot --headless --script res://tests/test_event_bus.gd
godot --headless --script res://tests/test_theme_manager.gd
godot --headless --script res://tests/test_asset_id_scanner.gd
```

Each prints `All ... tests passed.` and exits `0`.

## Subsystems

Built on this foundation, each an autoload manager (`<Name>Subsystem` class,
`<Name>` autoload) plus `prefabs/` components:

- **Impact & Combat VFX** (`ImpactVfx`) — ✅ pooled particle bursts, hit-stop,
  `HitFlash` / `KnockbackReceiver` / `SquashStretch` components.
  Demo: `scenes/demo_impact_vfx.tscn`.
- **World & Environment** (`WorldEnvironment2D`) — ✅ biome-driven parallax rig,
  ambient particle layer, full-screen shader overlay; switches the active
  `ThemeProfile` per biome. Demo: `scenes/demo_world.tscn`.
- **Camera & Post-Processing** (`CameraDirector`) — ✅ trauma-based screen shake,
  zoom/focus tweens, state-driven post-FX grades (hurt vignette). Owns the
  `Camera2D`; gameplay calls `set_followed(node)`. Demo: `scenes/demo_camera.tscn`.
- **UI & HUD Polish** (`HudPolish`) — ✅ pooled floating damage/heal numbers,
  `CatchUpBar` (trailing-fill health bar), `HoverPop`, a `Tweens` recipe library.
  Demo: `scenes/demo_hud.tscn`.
- **Polyphonic Audio / SFX** (`SfxPlayer`) — ✅ route table, pooled positional +
  dry voices, per-voice pitch/volume randomisation, orphan-clip safety on scene
  change. Demo: `scenes/demo_sfx.tscn`.
- **BGM & Ambience** (`MusicDirector`) — ✅ two-bank stem crossfade, intensity
  layering (`music.tension`), per-biome ambience loop, stingers.
  Demo: `scenes/demo_music.tscn`.
- Audio Bus / Mixing — planned (see `REMAINING_TASKS.md`).
