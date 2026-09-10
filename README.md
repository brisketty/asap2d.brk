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
| `ThemeManager` (autoload) | `autoloads/theme_manager.gd` | `resolve_sprite` / `resolve_audio` with fallback ladder |
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

- `*_sprite_asset_id` — resolved through `ThemeManager.resolve_sprite`
- `*_audio_asset_id` — resolved through `ThemeManager.resolve_audio`
- `*_event_id` — an `EventBus` semantic event id

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

## Planned subsystems

Built on this foundation, each as its own `class_name` manager under `prefabs/`:
Impact & Combat VFX · World & Environment · Camera & Post-Processing ·
UI & HUD Polish · Polyphonic Audio (SFX) · BGM & Ambience · Audio Bus / Mixing.
