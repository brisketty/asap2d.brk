# DEMO_SMOKE_TESTS.md — manual walkthrough of every demo scene

Each subsystem ships a demo scene under `scenes/`. This is the **human**
checklist: what to click and what you should see / hear. It complements the
headless run in [`STATE.md`](STATE.md#how-to-run) — that only proves *0 script
errors*, not that anything actually looks right.

## Before you start

- **Editor**: `D:\Programs\Godot_v4.7\Godot_v4.7-stable_win64.exe` (Godot 4.7,
  GL Compatibility renderer). Not on `PATH`.
- **Run a demo**: open its `.tscn` in the editor → **Run Current Scene** (`F6`).
  `foundation_demo.tscn` is the project main scene (`F5` runs it).
- **Headless error check only** (no visuals, no audio device):
  ```
  GODOT="/d/Programs/Godot_v4.7/Godot_v4.7-stable_win64.exe"
  "$GODOT" --headless --quit-after 200 res://scenes/demo_world.tscn
  ```
- **All art is placeholder.** The framework ships no textures — every unmapped
  sprite/tile id resolves to `res://icon.svg` via the ThemeManager fallback
  ladder (that is the point of the fallback; see `STATE.md` gotcha F2). Demos
  that need to *show* something distinct build throwaway textures/tilesets in
  code (`demo_world`), or the look is just tinted Godot icons.
- **All demo audio is procedural.** `demo_sfx` / `demo_music` / `demo_mixing`
  synthesise tones with `ToneStream` (`scripts/tone_stream.gd`) — beeps and
  drones, not real sound design.
- **`ThemeManager: <kind> '<id>' missing, using engine fallback.`** in the
  Output panel is normal for ids a profile deliberately doesn't map.
- **At-exit noise** (`… leaked`, `resources still in use at exit`,
  `Pages in use`, …) is Godot teardown chatter, not a failure.

Section shape: **Scene · Exercises · Controls · Expected · Notes**.

---

## 1. `foundation_demo.tscn` — A.S.A.P. foundation

- **Exercises**: EventBus semantic emission + ThemeManager fallback ladder via
  `DemoImpactPresenter`.
- **Controls**: none required — `impact.basic` auto-emits on a timer and on every
  mouse click (at the cursor). One button: **Profile: complete** ⇄
  **Profile: sparse**.
- **Expected**: a spark sprite appears at the click / cursor point each emission.
  With the **complete** profile the spark uses that profile's mapped texture;
  switch to **sparse** and the same event falls through to the default / engine
  fallback art — the presenter keeps working, the look degrades. Output panel
  logs one `missing, using engine fallback` line per downgrade.
- **Notes**: placeholder spark = a small Godot icon.

## 2. `demo_impact_vfx.tscn` — Impact & Combat VFX (`ImpactVfx`)

- **Exercises**: pooled particle bursts, hit-stop, and the opt-in `HitFlash` /
  `SquashStretch` / `KnockbackReceiver` components on a dummy target.
- **Controls**: **Basic** / **Heavy** / **Crit** / **Knockback** buttons — each
  emits its event at the dummy with a random direction.
- **Expected**:
  - Basic → small particle burst at the dummy + brief hit-flash.
  - Heavy → bigger burst, stronger squash/stretch.
  - Crit → largest burst + a noticeable **hit-stop** (everything freezes for a
    beat, then resumes).
  - Knockback → the dummy is shoved along the random direction and eases back.
- **Notes**: particles are the framework default material; the dummy is a plain
  placeholder sprite.

## 3. `demo_world.tscn` — World & Environment (`WorldEnvironment2D`)

- **Exercises**: biome-driven ThemeProfile swap → rebuilt parallax rig + ambient
  particle layer + full-screen tint shader, plus `AnimatedTileDriver` swapping
  the ground `TileSet`. Camera auto-pans right so parallax is visible.
- **Controls**: **biome.entered: forest** / **biome.entered: cave** /
  **biome.exited**. On-screen `StatusLabel` shows the active biome; the
  `ExpectationLabel` restates what to watch for.
- **Expected**:
  - **On load** the demo is already in **forest**: three translucent radial-blob
    parallax layers (far = large/faint green, near = small/bright canopy),
    scrolling at *visibly different* speeds as the camera drifts right; a floor
    row of tiles; a green full-screen tint. `Biome: forest`.
  - **cave** → layer hues shift to blue/slate, the floor tiles change, the tint
    changes, and drifting **ambient particles** appear.
  - **forest** again → back to green, particles stop (forest maps no
    `world.ambient` — intentional, per `THEME_PROFILE_SLOTS.md`).
  - **biome.exited** → parallax layers, particles, tint and floor all clear.
    `Biome: (none)`.
- **Notes**: the distinct parallax textures and both floor tilesets are built in
  `demo_world.gd` (`inject_demo_parallax()` / `inject_demo_tilesets()`) — the
  shipped framework has none, so without the demo's injection all three layers
  would be the identical Godot icon (this is the confusion this doc exists to
  resolve). `ThemeManager: tileset 'world.tiles' missing` logs once at boot
  before the injection lands — expected.

## 4. `demo_camera.tscn` — Camera & Post-Processing (`CameraDirector`)

- **Exercises**: trauma shake, zoom tweens, state-driven post-FX grade, the
  optional tiled screen-border overlay, per-state / per-effect sound hooks, and
  a region-of-interest zoom-to-fit focus. A player marker auto-wanders in a
  circle over a checker backdrop and is registered as the camera target.
- **Controls**: **Crit** / **Shake** / **Hurt** / **Clear** / **Zoom In** /
  **Zoom Out**.
- **Expected**:
  - The view follows the wandering marker against the checker backdrop, making
    the follow/shake/zoom motion easy to read.
  - An orange/blue-bordered box (`BossRegion`, a `CameraFocusRegion`) sits
    beside the marker's wander loop. When the marker wanders inside it, the
    border turns orange and the camera tweens to pan + zoom out just enough to
    frame the whole box; leaving it releases the camera back to following the
    marker and tweens the zoom back to normal. No button drives this — it's a
    plain position check against the marker every frame
    (`CameraTranslation.is_point_in_region`), the same pattern a boss-arena
    trigger would use.
  - Shake / Crit → trauma-based screen shake that decays, plus a one-shot tone
    (pitch varies a little each press). Crit should read as a **visibly bigger**
    shake than a bare Shake press — both scale by `CameraRig.shake_intensity_scale`
    (default `1.0`; raise it in the Inspector for an even punchier feel).
  - Hurt → a red vignette grade **and** a tiled red border (two colour
    variations, one layer under the vignette, one over it) that stay until
    **Clear**; an enter blip plays once, then a low sustained tone loops for as
    long as Hurt is active.
  - Clear → the vignette, border and loop all stop together; an exit blip plays.
  - Zoom In / Zoom Out → the camera zoom tweens to the new level, each with its
    own one-shot tone (no sustained "zooming" sound — the tween is sub-second,
    so an enter/exit lifecycle isn't worth it here, unlike Hurt).
- **Notes**: grade is the `hurt_vignette` shader; border tiles and every tone
  are code-built placeholders (`demo_camera.gd` `inject_demo_screen_tiles()` /
  `inject_demo_sounds()`) — the framework ships neither border art nor audio.
  **The camera has no follow-smoothing** — it hard-snaps to the wandering
  marker every frame. Any drift you notice once a shake has fully decayed is
  that ambient wander continuing, not shake residue:
  `CameraTranslation.decay_trauma` floors to an exact `0.0`, and
  `shake_amount(0)` is exactly `0` too, so the shake math itself leaves nothing
  behind.

## 5. `demo_hud.tscn` — UI & HUD Polish (`HudPolish`)

- **Exercises**: pooled world-space floating damage/heal text, `CatchUpBar`
  trailing-fill bar, `HoverPop`.
- **Controls**: **Hit** (8) / **Crit** (33) / **Heal** (12) spawn floating
  numbers near the focus with random jitter; **Bar -** / **Bar +** push the
  CatchUpBar ratio down / up.
- **Expected**:
  - Each damage/heal press → a floating number rises and fades near the focus
    point (heal visually distinct from damage). Spam to see the pool reused.
  - Bar buttons → the bar's main fill jumps and a secondary "catch-up" fill
    trails toward it.
  - The **Crit** button itself does a small pop on hover / press (`HoverPop`).
- **Notes**: floating text is **world-space** (`STATE.md`), so it sits in the
  scene, not pinned to the screen.

## 6. `demo_sfx.tscn` — Polyphonic Audio (`SfxPlayer`)

- **Exercises**: the SFX route table + pooled voices with per-voice pitch /
  volume randomisation, from a code-built profile of procedural tones.
- **Controls**: **Light** / **Heavy** / **Hover** / **Burst**.
- **Expected**: a tone per press (Light = high/short, Heavy = low/longer, Hover =
  soft click). **Burst** fires 8 at once — you hear the voice pool go
  polyphonic, each voice slightly detuned / re-leveled. Rapid manual presses do
  the same.
- **Notes**: silent under `--headless` (no audio device) but no error.

## 7. `demo_music.tscn` — BGM & Ambience (`MusicDirector`)

- **Exercises**: two-bank stem crossfade, intensity layering, per-biome ambience
  bed, stingers — all procedural drones.
- **Controls**: **forest** / **cave** theme buttons, **Tension** slider,
  **Stinger**, **Forest Ambience**, **Stop Ambience**, **Low-health**,
  **State Clear**.
- **Expected**:
  - A theme button starts a looping stacked-tone chord; switching themes
    crossfades from the old bank to the new one (no hard cut).
  - Tension slider up → upper stems fade in (denser); down → back to the base
    stem.
  - Stinger → a one-shot tone over the top, music continues.
  - Forest Ambience → a low bed loop under the music; Stop Ambience ends it.
  - Low-health → intensity is pinned to a floor (can't go below) until
    **State Clear**.
- **Notes**: `music_stem_count` is fixed after `_ready()` (`STATE.md` TODO).

## 8. `demo_mixing.tscn` — Audio Bus / Mixing (`AudioMixing`)

- **Exercises**: per-biome bus gain + SFX reverb tweened toward a `BusProfile`;
  the structural dry `UI` bus.
- **Controls**: **Play SFX (loop)** toggle, **Cave** / **Hall** / **Dry**,
  **Hurt** / **State Clear**.
- **Expected**:
  - Play SFX → a repeating tone on the `SFX` bus.
  - **Cave** / **Hall** → that tone gains an audible reverb tail (Hall wetter /
    longer than Cave), tweened in, not snapped. **Dry** removes it.
  - **Hurt** → a transient duck / grade on the bus that recovers on
    **State Clear**.
  - The button clicks themselves stay dry (they're on `UI`, not `SFX`).
- **Notes**: `SFX_Reverb` is currently a direct effect on `SFX`, not a real send
  (`STATE.md` TODO). Silent headless, no error.

---

## Cross-cutting

- Run each demo from the editor with the **Output** and **Debugger** panels
  visible — a red entry in Debugger is a real failure; `printerr` "using engine
  fallback" lines in Output are not.
- CI (`.github/workflows/test.yml`) runs every demo headless for a few hundred
  frames purely to catch script errors — it can't see any of the above.
