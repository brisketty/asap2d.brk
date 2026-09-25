# ThemeProfile slots — visual & audio reference

Every A.S.A.P. subsystem fetches its assets by **abstract string id** through
`ThemeManager.resolve_<kind>(id)`, which looks the id up in the **active
`ThemeProfile`**. This document lists every id the shipped framework resolves —
the "slots" an artist / designer fills in per theme.

- A `ThemeProfile` is one `.tres` per theme / biome / mood. `biome.entered` with
  `context.source_id = "forest"` makes `WorldEnvironment2D` switch the active
  profile to the one whose `profile_id` is `&"forest"`, so **every** subsystem
  re-themes at once.
- Fill a slot by adding a `StringName -> asset` entry to the matching
  `<kind>_assets` dictionary on the profile (`sprite_assets`, `audio_assets`,
  `particle_assets`, `shader_assets`, `post_fx_assets`, `music_assets`,
  `bus_profile_assets`, `tileset_assets`).
- **Unfilled slots don't crash.** `resolve_sprite` always returns a texture
  (`default_sprite` → `res://icon.svg`); every other `resolve_*` returns `null`
  and the subsystem degrades gracefully (see the *Missing* column).
- Per-profile `default_<kind>` catches any id the profile doesn't map
  explicitly; `ThemeManager.profile_fallback_<kind>` is the last resort.

For the `ThemeProfile` **fields themselves** (each `<kind>_assets` dict +
`default_<kind>`), with a per-field example and a slot for sample visuals, see
[`THEME_PROFILE_FIELDS.md`](THEME_PROFILE_FIELDS.md).

Run `godot --headless --script res://addons/brisklance/self/scripts/run_asset_scan.gd` to get a
prioritized list of ids referenced by scenes/prefabs but not yet mapped in the
active profile (written to `exports/asset_worklist.md`).

---

## Fixed slots

Ids the framework resolves under a constant name. Fill these in a profile that
is active whenever the relevant event fires.

### Visual

| id | kind | resolved by | purpose | missing → |
| --- | --- | --- | --- | --- |
| `world.parallax.far` | sprite | `WorldEnvironment2D` → `ParallaxRig` | farthest parallax layer texture (tiled) | `icon.svg` |
| `world.parallax.mid` | sprite | `WorldEnvironment2D` → `ParallaxRig` | middle parallax layer | `icon.svg` |
| `world.parallax.near` | sprite | `WorldEnvironment2D` → `ParallaxRig` | nearest parallax layer (scrolls ~1:1) | `icon.svg` |
| `world.ambient` | particle | `WorldEnvironment2D` → `AmbientParticleLayer` | looping screen-space ambience (dust, snow, embers) — a `ParticleProcessMaterial` | emission stays off |
| `world.overlay` | shader | `WorldEnvironment2D` → `ScreenShaderOverlay` | full-screen atmosphere pass (god rays, heat haze, colour wash) — a `ShaderMaterial` on a `ColorRect` | overlay hidden |
| `world.tiles` | tileset | `AnimatedTileDriver` | ground / wall `TileSet` for a `TileMapLayer` (per-tile animation defined in the `TileSet` itself) | current tiles kept |
| `impact.spark` | particle | `ImpactVfx` → `ParticleBurstPool` | the burst material for `impact.*` hits (the default intensity table points every impact at this one id — override the table for per-hit particles) | prefab's built-in burst material |
| `state.hurt` | post_fx | `CameraDirector` → `ScreenShaderOverlay` | full-screen grade while hurt (vignette, desaturate, chromatic aberration) — a `ShaderMaterial` | no grade |
| `state.lowhealth` | post_fx | `CameraDirector` | grade while at low health | no grade |
| `state.paused` | post_fx | `CameraDirector` | grade while paused (blur, dim) | no grade |
| `state.hurt` | screen_tile | `CameraDirector` → `ScreenTileBorder` (under the grade) | optional tiled border art around the screen edges — a `ScreenTileSet` (one tile texture + variations, auto-tiled) | no border |
| `state.hurt.over` | screen_tile | `CameraDirector` → `ScreenTileBorder` (over the grade) | same, drawn above the shader grade instead of below | no border |
| `state.lowhealth` / `state.lowhealth.over` | screen_tile | ″ | same pair for low health | no border |
| `state.paused` / `state.paused.over` | screen_tile | ″ | same pair for paused | no border |

`CameraDirector` resolves `resolve_post_fx(<state event id>)` and
`resolve_screen_tile(<state event id>)` / `resolve_screen_tile(<state event id>
+ ".over")`, so the ids are literally `state.hurt` / `state.lowhealth` /
`state.paused` (+ `.over`); `state.clear` fades the grade and clears both tile
layers back out. Both `screen_tile` ids are independently optional — fill 0, 1,
or 2 per state.

### Audio

| id | kind | resolved by | purpose | missing → |
| --- | --- | --- | --- | --- |
| `sfx.impact.light` | audio | `SfxPlayer` (route for `impact.basic`) | positional one-shot for a light hit | silent |
| `sfx.impact.heavy` | audio | `SfxPlayer` (route for `impact.heavy`) | positional one-shot for a heavy hit | silent |
| `sfx.impact.crit` | audio | `SfxPlayer` (route for `impact.crit`) | positional one-shot for a crit | silent |
| `sfx.ui.hover` | audio | `SfxPlayer` (route for `ui.hover`) | dry UI-bus one-shot on hover | silent |
| `sfx.ui.confirm` | audio | `SfxPlayer` (route for `ui.confirm`) | dry UI-bus confirm blip | silent |
| `sfx.ui.cancel` | audio | `SfxPlayer` (route for `ui.cancel`) | dry UI-bus cancel blip | silent |
| `sfx.camera.shake` | audio | `SfxPlayer` (route for `camera.shake`) | dry one-shot on any screen shake trigger | silent |
| `sfx.camera.zoom` | audio | `SfxPlayer` (route for `camera.zoom`) | dry one-shot on any zoom trigger (one id covers in and out — pitch/variation add the difference) | silent |
| `state.hurt` | bus_profile | `AudioMixing` | transient mix while hurt — a `BusProfile` (per-bus dB trims + SFX reverb) applied over the biome mix | flat / dry (neutral) |
| `state.lowhealth` | bus_profile | `AudioMixing` | transient mix at low health | neutral |
| `state.paused` | bus_profile | `AudioMixing` | transient mix while paused (duck music, muffle SFX) | neutral |

The `sfx.*` ids are the **default route table**. `SfxPlayer.route_table` is an
`@export Array[SfxRoute]`, so a project can rename them, add routes for any other
event, and tune per-route pitch / volume randomisation and spatialisation. Every
route can also list `route_audio_variation_ids` (`Array[StringName]`) — one is
picked at random per play, on top of the pitch/volume jitter; empty falls back
to the singular `route_audio_asset_id`. **Not scanned** by `AssetIdScanner`
today (it only classifies single-id properties, not arrays) — list variation
ids by hand.

---

## Dynamic slots (id patterns)

Ids the framework builds from event data. Fill **one entry per game concept**
(per theme, per biome, per stinger).

| pattern | kind | resolved by | filled from | example ids |
| --- | --- | --- | --- | --- |
| `<theme>.<n>` for `n` in `0 … music_stem_count-1` | music | `MusicDirector` stem players | `music.theme` `context.source_id` = `<theme>`; `music_stem_count` (default **3**) | `music.theme` → `"forest"` needs `forest.0`, `forest.1`, `forest.2` |
| `ambience.<biome>` | music | `MusicDirector` ambience loop | `biome.entered` `context.source_id` = `<biome>` | `ambience.forest`, `ambience.cave` |
| `stinger.<id>` | music | `MusicDirector` stinger player | `music.stinger` `context.source_id` = `<id>` | `stinger.boss_reveal`, `stinger.item_get` |
| `<biome>` | bus_profile | `AudioMixing` | `biome.entered` `context.source_id` = `<biome>` | `forest`, `cave` (the biome id *is* the bus-profile id) |

`SfxPlayer.state_sfx_table` (`@export Array[StateSfxSet]`, one row per
`state.*` id) is a separate, opt-in enter/loop/exit sound lifecycle for
hurt/lowhealth/paused — unlike `camera.shake` / `camera.zoom` above (momentary
effects), these states can last indefinitely: `enter_audio_variation_ids` plays
once on `state.hurt` (etc.), `loop_audio_variation_ids` starts a sustained loop
that keeps playing until `state.clear`, which stops the loop and plays
`exit_audio_variation_ids`. Each stage has its own pitch-jitter range and its
own id array — name the ids however you like (e.g. `sfx.state.hurt.enter` /
`.loop` / `.exit`); nothing in the framework hardcodes them. All three stages
default empty (silent) — sound design is too game-specific to default.

**Stems** must be the same length and are started together (sample-locked). They
layer in as intensity rises: stem 0 first, then 1, then 2 … `music.tension`
(0–1) and a floor from `state.*` (`music_state_tension`, default hurt 0.5 /
lowhealth 0.85) drive it.

**`music` assets** should have their loop points set (`AudioStreamWAV.loop_mode`
/ an imported `.ogg` set to loop).

---

## Shared vs per-biome slots

`biome.entered` swaps the **whole** active profile, and there is no profile
inheritance yet. So a slot that must work regardless of biome —

- the six `sfx.*` one-shots,
- the three `state.*` post-fx grades,
- the three `state.*` bus profiles,
- `stinger.*`,

— has to be present in **every** biome profile (copy them), *or* the game must
`set_active_profile_by_id` back to a "base" profile for non-biome moments.
Per-biome `ThemeProfile` sub-resources are a tracked follow-up
(`REMAINING_TASKS.md`).

---

## Worked example — a `forest` ThemeProfile

```
profile_id = &"forest"

sprite_assets = {
    &"world.parallax.far":  res://art/forest/sky.png
    &"world.parallax.mid":  res://art/forest/trees_back.png
    &"world.parallax.near": res://art/forest/trees_front.png
}
particle_assets = {
    &"world.ambient":  res://art/forest/pollen.tres      # ParticleProcessMaterial
    &"impact.spark":   res://art/vfx/leaf_burst.tres
}
shader_assets = {
    &"world.overlay":  res://art/forest/godrays.tres     # ShaderMaterial
}
post_fx_assets = {
    &"state.hurt":      res://art/grade/hurt_vignette.tres
    &"state.lowhealth": res://art/grade/lowhealth_pulse.tres
    &"state.paused":    res://art/grade/pause_blur.tres
}
tileset_assets = {
    &"world.tiles":    res://art/forest/ground.tres      # TileSet
}
audio_assets = {
    &"sfx.impact.light":  res://sfx/hit_light.ogg
    &"sfx.impact.heavy":  res://sfx/hit_heavy.ogg
    &"sfx.impact.crit":   res://sfx/hit_crit.ogg
    &"sfx.ui.hover":      res://sfx/ui_hover.ogg
    &"sfx.ui.confirm":    res://sfx/ui_confirm.ogg
    &"sfx.ui.cancel":     res://sfx/ui_cancel.ogg
}
music_assets = {
    &"forest.0":          res://music/forest_drums.ogg    # looped
    &"forest.1":          res://music/forest_strings.ogg
    &"forest.2":          res://music/forest_lead.ogg
    &"ambience.forest":   res://music/forest_birds.ogg
    &"stinger.item_get":  res://music/stinger_item.ogg
}
bus_profile_assets = {
    &"forest":            res://mix/forest_bus.tres       # gentle reverb
    &"state.hurt":        res://mix/hurt_bus.tres          # duck music, boost SFX
    &"state.lowhealth":   res://mix/lowhealth_bus.tres
    &"state.paused":      res://mix/paused_bus.tres
}

default_sprite = res://art/forest/trees_back.png   # covers any unmapped sprite id
```

The game then emits, on entering the forest:

```gdscript
EventBus.emit_semantic_event(EventIds.BIOME_ENTERED,
    Utility.make_spatial_context(Vector2.ZERO, Vector2.ZERO, 0.0, &"forest"))
EventBus.emit_semantic_event(EventIds.MUSIC_THEME,
    Utility.make_spatial_context(Vector2.ZERO, Vector2.ZERO, 0.0, &"forest"))
```

`biome.entered` swaps the profile and rebuilds parallax / ambient / overlay /
tiles / bus mix; `music.theme` crossfades the stems in.
