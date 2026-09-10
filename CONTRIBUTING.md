# Contributing to the A.S.A.P. Framework

Read [`CLAUDE.md`](CLAUDE.md) (coding rules, directory layout — authoritative),
[`ARCHITECTURE_SPEC.md`](ARCHITECTURE_SPEC.md) (design), and
[`STATE.md`](STATE.md) (current state + gotchas) first.

## Running the checks

Godot **4.7** headless (`STATE.md` has the binary path). From the repo root:

```bash
for t in test_utility test_event_bus test_theme_manager test_asset_id_scanner \
         test_node_pool test_impact_vfx test_world_environment test_camera_director \
         test_hud_polish test_sfx_player test_music_director test_audio_mixing; do
  godot --headless --script res://tests/$t.gd
done
godot --headless --editor --quit                    # import / global-class check
godot --headless --script res://scripts/run_asset_scan.gd   # regenerate the worklist
```

CI (`.github/workflows/test.yml`) runs all of this on every push and PR, and
fails if `exports/asset_worklist.md` drifts.

## The four pillars (never violate)

1. **Pure Logic** — logic scripts emit `EventBus.emit_semantic_event(id, context)`
   and touch **no** node / stream / shader / `Control`.
2. **Profile-Driven Translation** — presentation resolves assets by string id
   through `ThemeManager.resolve_<kind>`. No hardcoded `res://` asset paths, no
   `preload()` of art.
3. **Defensive Defaulting** — never assume a `resolve_*` is non-null except
   `resolve_sprite`; every asset lookup already falls back and logs.
4. **Telemetry-Gated Scoping** — every asset id a scene references is an
   `@export` named `*_<kind>_asset_id` or `*_event_id`.

## Adding a subsystem (the shape every one follows)

1. **Pure logic** → `scripts/<name>_translation.gd` (`class_name`, static, **no
   autoload references** — so it unit-tests under `godot --headless --script`).
   Anything table-shaped is a typed `Resource` (`scripts/<name>_<thing>.gd`).
2. **Manager** → `autoloads/<name>.gd`, `class_name <Name>Subsystem extends Node`,
   registered in `project.godot` as autoload `<Name>` (after `EventBus` /
   `ThemeManager`). Connects to `EventBus.semantic_event_emitted` in `_ready()`;
   dispatch method `handle_semantic_event_emitted(id, context)`.
3. **Pools / persistent child nodes** are created by the manager in `_ready()`
   (the `HudPolish` / `SfxPlayer` / `MusicDirector` pattern), not wired via
   `@export` (an autoload can't wire exports). Use `NodePool` for anything
   spawned per event.
4. **Opt-in components** (things an entity/HUD scene attaches) → `prefabs/`,
   `class_name`, `static get_packed_scene()`, exported `node_target` +
   `*_source_id`, listen on the bus directly.
5. **Assets** — a new kind needs: `ThemeProfile` (`<kind>_assets` export +
   `default_<kind>` + `resolve_<kind>_or_null` + `collect_<kind>_ids` +
   `update_from_<kind>_assets`), `ThemeManager` (`profile_fallback_<kind>` +
   two-line `resolve_<kind>` / `has_<kind>` via `resolve_with_ladder`),
   `AssetIdScanner` (`<KIND>_ID_SUFFIX` / `<KIND>_KIND` + a `classify_property`
   branch + an `is_reference_mapped` branch), and a stub method in
   `tests/test_asset_id_scanner.gd`.
6. **Event ids** — add `const`s to `scripts/event_ids.gd` and a row to the
   registry in `ARCHITECTURE_SPEC.md`. Reference `EventIds.X`, never a literal.
7. **Demo** → `scenes/demo_<name>.tscn` (+ `.gd`), added to the demo list in
   `.github/workflows` is not required, but list it in `README.md` / `STATE.md`.
8. **Test** → `tests/test_<name>.gd`, a `SceneTree` script with the
   `expect_*` / `quit(code)` harness (copy an existing one). Cover the
   translation logic; verify Node wiring with a throwaway smoke scene
   (`godot --headless res://scenes/_smoke_*.tscn`), then delete it.
9. **Docs** — spec §, `REMAINING_TASKS.md` (check the boxes, add a dated history
   entry + any follow-ups), `STATE.md`, `README.md`.

## Coding rules quick reference (full text: `CLAUDE.md`)

- Static typing everywhere. This project treats GDScript **warnings as errors** —
  explicitly type anything coming off `Dictionary` / `Array` / `load()` /
  `.new()` / `.get()`.
- No `_`-prefixed members. No `$` / `get_node()` — exported `node_`-prefixed
  refs, connected in `_ready()`. Signal handlers named `handle_*`.
- `.tscn` exported node refs **must** list `node_paths=PackedStringArray(...)` on
  the `[node]` line.
- Autoload scripts carry **no `class_name`** matching the autoload name.
- Reference-type property updates go through `update_from_<property>()`.
- Object validity: `Utility.is_object_valid(obj)`, never `obj == null` alone.
- Early returns over nested `if` / `else`.

## Commits

Branch off `main` (`framework/*`). Conventional-ish subject line; body explains
the *why* and any decisions. One subsystem (or one coherent step) per commit.
