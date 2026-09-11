# ThemeProfile — field-by-field reference

Every exported field on `ThemeProfile` (`scripts/theme_profile.gd`), what it
holds, and a concrete example. Drop a screenshot under each **Sample visual**
line as you build real themes — that's what this doc is here to collect.
Keep the image files under `assets/docs/theme/` (their editable originals go in
`/external/`, per `CLAUDE.md §1`).

- A `ThemeProfile` is **one `.tres` per theme / biome / mood**
  (`assets/theme_profile_*.tres`). `biome.entered` with
  `context.source_id = "forest"` makes the active profile the one whose
  `profile_id` is `&"forest"`, and every subsystem re-themes at once.
- Assets are looked up by **abstract StringName id** through
  `ThemeManager.resolve_<kind>(id)`. The **id catalogue** — every slot the
  shipped framework resolves — is [`THEME_PROFILE_SLOTS.md`](THEME_PROFILE_SLOTS.md).
  This doc is about the *container fields*, not the ids.
- **Resolution ladder** (`autoloads/theme_manager.gd` → `resolve_with_ladder`):
  `<kind>_assets[id]` → `default_<kind>` → `ThemeManager.profile_fallback_<kind>`.
  Each downgrade logs once with `printerr`. `resolve_sprite` never returns null
  (`profile_fallback_sprite` is `res://icon.svg`); every other kind can be null
  until the project sets its `profile_fallback_*`, and each subsystem degrades
  gracefully (the *missing →* column in `THEME_PROFILE_SLOTS.md`).
- The 9 `<kind>_assets` fields are `Dictionary` (reference type). Their setters
  auto-call `update_from_<kind>_assets()`, but **mutating one in place**
  (`profile.sprite_assets[id] = tex`) does **not** — reassign the whole dict, or
  call the `update_from_*` method yourself (CLAUDE.md §2E). See
  `scenes/demo_world.gd` `inject_demo_parallax()` for the reassign pattern.

| Field | Type | Holds |
| --- | --- | --- |
| `profile_id` | `StringName` | the id this profile answers to |
| `sprite_assets` / `default_sprite` | `Dictionary` `StringName → Texture2D` / `Texture2D` | textures (parallax layers, spark sprite) |
| `audio_assets` / `default_audio` | `StringName → AudioStream` / `AudioStream` | one-shot SFX streams |
| `particle_assets` / `default_particle` | `StringName → ParticleProcessMaterial\|PackedScene` (`Resource`) / `Resource` | ambient + impact particle materials |
| `shader_assets` / `default_shader` | `StringName → ShaderMaterial` / `ShaderMaterial` | full-screen **atmosphere** passes |
| `post_fx_assets` / `default_post_fx` | `StringName → ShaderMaterial` / `ShaderMaterial` | full-screen **state / damage** grades |
| `music_assets` / `default_music` | `StringName → AudioStream` (looped) / `AudioStream` | theme stems, ambience beds, stingers |
| `bus_profile_assets` / `default_bus_profile` | `StringName → BusProfile` / `BusProfile` | per-biome / per-state mixing state |
| `tileset_assets` / `default_tileset` | `StringName → TileSet` / `TileSet` | ground / wall tiles for a `TileMapLayer` |
| `screen_tile_assets` / `default_screen_tile` | `StringName → ScreenTileSet` / `ScreenTileSet` | optional tiled border art around the screen edges |

---

## `profile_id`

**Type** `StringName` · **Purpose** the value the framework matches when it
switches themes. `ThemeManager.set_active_profile_by_id(&"forest")` picks the
registered profile whose `profile_id == &"forest"`; `WorldEnvironment2D` calls
that with `biome.entered`'s `context.source_id`. Also the `<biome>` bus-profile
id and the `<theme>` stem prefix (`forest.0`, `forest.1`, …).

```gdscript
profile_id = &"forest"
```

> **Sample visual:** _(embed the biome this profile represents)_

---

## `sprite_assets` / `default_sprite`

**Type** `Dictionary` `StringName → Texture2D` / `Texture2D` · **Resolved by**
`ThemeManager.resolve_sprite(id)` · **Fixed ids** `world.parallax.far` /
`world.parallax.mid` / `world.parallax.near` (tiled `ParallaxRig` layers, far →
near), `impact.spark` (sprite variant, foundation demo only). **Missing →**
`res://icon.svg` (this kind never returns null).

```gdscript
sprite_assets = {
    &"world.parallax.far":  preload("res://assets/forest/sky.png"),
    &"world.parallax.mid":  preload("res://assets/forest/trees_back.png"),
    &"world.parallax.near": preload("res://assets/forest/trees_front.png"),
}
default_sprite = preload("res://assets/forest/trees_back.png")
```

Real reference: `scenes/demo_world.gd` builds three tinted `GradientTexture2D`
blobs at runtime (far = large/faint, near = small/bright) because the framework
ships no parallax art.

> **Sample visual:** _(the three parallax layers, and the composite in motion)_

---

## `audio_assets` / `default_audio`

**Type** `StringName → AudioStream` / `AudioStream` · **Resolved by**
`ThemeManager.resolve_audio(id)` · **Fixed ids** `sfx.impact.light` /
`sfx.impact.heavy` / `sfx.impact.crit` / `sfx.ui.hover` / `sfx.ui.confirm` /
`sfx.ui.cancel` (the default `SfxPlayer.route_table`). **Missing →** silent.
One-shots — not looped.

```gdscript
audio_assets = {
    &"sfx.impact.light": preload("res://sfx/hit_light.ogg"),
    &"sfx.impact.heavy": preload("res://sfx/hit_heavy.ogg"),
    &"sfx.ui.hover":     preload("res://sfx/ui_hover.ogg"),
}
```

Real reference: `scenes/demo_sfx.gd` `build_tone_profile()` fills these with
`ToneStream.make(freq, seconds)` procedural tones.

> **Sample visual:** _(waveform / spectrogram of each hit tier, or a routing diagram)_

---

## `particle_assets` / `default_particle`

**Type** `StringName → ParticleProcessMaterial | PackedScene` (stored as
`Resource` so an id can map to either) / `Resource` · **Resolved by**
`ThemeManager.resolve_particle(id)` · **Fixed ids** `world.ambient` (looping
screen-space `AmbientParticleLayer` — dust / snow / embers), `impact.spark` (the
burst material every `impact.*` hit uses by default). **Missing →** `world.ambient`
emission stays off; `impact.spark` falls back to the burst prefab's built-in
material.

```gdscript
particle_assets = {
    &"world.ambient": preload("res://assets/forest/pollen.tres"),   # ParticleProcessMaterial
    &"impact.spark":  preload("res://assets/vfx/leaf_burst.tres"),
}
```

Real reference: `assets/particle_cave_ambient.tres` (mapped to `world.ambient`
in `theme_profile_cave.tres`; `theme_profile_forest.tres` maps none — the demo's
"no particles in forest" is intentional).

> **Sample visual:** _(the ambient emitter running; the impact burst on a hit)_

---

## `shader_assets` / `default_shader`

**Type** `StringName → ShaderMaterial` / `ShaderMaterial` · **Resolved by**
`ThemeManager.resolve_shader(id)` · **Fixed id** `world.overlay` — a full-screen
**atmosphere** pass on a `ColorRect` (god rays, heat haze, colour wash), driven
by `WorldEnvironment2D` → `ScreenShaderOverlay`. **Missing →** overlay hidden.
Kept separate from `post_fx_assets` so tooling can tell "biome atmosphere" art
from "damage feedback" art.

```gdscript
shader_assets = {
    &"world.overlay": preload("res://assets/shader_forest_tint.tres"),
}
```

Real reference: `assets/shader_forest_tint.tres` / `assets/shader_cave_tint.tres`
(both `ShaderMaterial`s over `assets/shaders/biome_tint.gdshader`).

> **Sample visual:** _(scene with the overlay on vs off)_

---

## `post_fx_assets` / `default_post_fx`

**Type** `StringName → ShaderMaterial` / `ShaderMaterial` · **Resolved by**
`ThemeManager.resolve_post_fx(id)` · **Fixed ids** `state.hurt` /
`state.lowhealth` / `state.paused` — full-screen **state grades** driven by
`CameraDirector` (vignette, desaturate, blur, chromatic aberration).
`state.clear` fades whatever is active back out. **Missing →** no grade.

```gdscript
post_fx_assets = {
    &"state.hurt":      preload("res://assets/post_fx_hurt_vignette.tres"),
    &"state.lowhealth": preload("res://assets/grade/lowhealth_pulse.tres"),
    &"state.paused":    preload("res://assets/grade/pause_blur.tres"),
}
```

Real reference: `assets/post_fx_hurt_vignette.tres` (over
`assets/shaders/hurt_vignette.gdshader`; mapped in `theme_profile_complete.tres`).
These are biome-independent — repeat them in every biome profile (see
`THEME_PROFILE_SLOTS.md` § "Shared vs per-biome slots").

> **Sample visual:** _(the hurt grade at full strength; the low-health pulse)_

---

## `music_assets` / `default_music`

**Type** `StringName → AudioStream` (loop points set) / `AudioStream` ·
**Resolved by** `ThemeManager.resolve_music(id)` · **Id patterns** (built from
event data, not fixed):

- `<theme>.<n>` for `n` in `0 … music_stem_count-1` (default 3) — the stem set a
  `music.theme` event layers in as intensity rises. Stems must be equal length,
  started sample-locked.
- `ambience.<biome>` — the bed loop under `biome.entered`.
- `stinger.<id>` — a one-shot over the top from `music.stinger`.

**Missing →** silent.

```gdscript
music_assets = {
    &"forest.0":         preload("res://music/forest_pad.ogg"),     # looped
    &"forest.1":         preload("res://music/forest_strings.ogg"),
    &"forest.2":         preload("res://music/forest_lead.ogg"),
    &"ambience.forest":  preload("res://music/forest_birds.ogg"),
    &"stinger.reveal":   preload("res://music/stinger_reveal.ogg"),
}
```

Real reference: `scenes/demo_music.gd` `build_score_profile()` —
`ToneStream.make(freq, 2.0, gain, true)` looped drones, one per stem.

> **Sample visual:** _(stem stack diagram — which layers play at tension 0 / 0.5 / 1)_

---

## `bus_profile_assets` / `default_bus_profile`

**Type** `StringName → BusProfile` / `BusProfile` · **Resolved by**
`ThemeManager.resolve_bus_profile(id)` · **Ids** `<biome>` (the biome id *is* the
bus-profile id — `forest`, `cave`), plus the biome-independent `state.hurt` /
`state.lowhealth` / `state.paused` transient mixes. A `BusProfile` is per-bus dB
trims + an SFX reverb amount; `AudioMixing` tweens toward it. **Missing →**
neutral / dry.

```gdscript
bus_profile_assets = {
    &"forest":      preload("res://mix/forest_bus.tres"),      # gentle reverb
    &"state.hurt":  preload("res://mix/hurt_bus.tres"),        # duck music, boost SFX
}
```

Real reference: `scenes/demo_mixing.gd` `build_profile()` —
`AudioMixingTranslation.make_profile(id, music_db, ambience_db, sfx_db, reverb_room, reverb_wet)`.

> **Sample visual:** _(bar chart of per-bus gain for each profile; reverb settings)_

---

## `tileset_assets` / `default_tileset`

**Type** `StringName → TileSet` / `TileSet` · **Resolved by**
`ThemeManager.resolve_tileset(id)` · **Fixed id** `world.tiles` — the ground /
wall `TileSet` an `AnimatedTileDriver` swaps onto its `TileMapLayer` when the
biome changes (the painted cells stay, the look changes; per-tile animation is
defined inside the `TileSet`). **Missing →** the current `TileSet` is kept (the
map is never wiped).

```gdscript
tileset_assets = {
    &"world.tiles": preload("res://assets/forest/ground.tres"),   # TileSet
}
```

Real reference: `scenes/demo_world.gd` `build_tileset()` builds a one-tile
`TileSetAtlasSource` over `res://icon.svg` per biome at runtime — the framework
ships no tiles, which is why `world.tiles` sits on the asset worklist.

> **Sample visual:** _(the forest floor vs the cave floor, same painted cells)_

---

## `screen_tile_assets` / `default_screen_tile`

**Type** `StringName → ScreenTileSet` / `ScreenTileSet` · **Resolved by**
`ThemeManager.resolve_screen_tile(id)` · **Ids** `state.hurt` / `state.lowhealth`
/ `state.paused` (drawn *under* the post-fx grade) and their `.over` variants
(drawn *over* it) — see `THEME_PROFILE_SLOTS.md`. A `ScreenTileSet` is one tile
texture + a few variations (`tile_variations: Array[Texture2D]`, an
`AnimatedTexture` entry animates for free), a `tile_size`, and how many tiles
deep the border runs (`border_thickness_tiles`) — `ScreenTileBorder` auto-tiles
them around the four screen edges, so an artist only ever draws one tile.
**Missing →** no border (both layers are fully optional, independently).

```gdscript
screen_tile_assets = {
    &"state.hurt":      preload("res://assets/hurt_border_under.tres"),  # ScreenTileSet
    &"state.hurt.over": preload("res://assets/hurt_border_over.tres"),
}
```

Real reference: `scenes/demo_camera.gd` `inject_demo_screen_tiles()` builds two
solid-colour `ScreenTileSet`s at runtime (same spirit as `demo_world.gd`'s
tileset/parallax injection) since the framework ships no border art.

> **Sample visual:** _(the hurt border under the vignette, and again with the over layer added)_

---

## Worked full example

See `assets/theme_profile_forest.tres` / `theme_profile_cave.tres` for compact
real profiles, and `THEME_PROFILE_SLOTS.md` § "Worked example" for a fully
populated `forest` profile written out.
