class_name EventIds
## Canonical semantic event ids for the Global Event Bus. Emitters and consumers
## agree by symbol, not by typed literal, so a rename is a compile-time concern
## and a typo is impossible. Namespaced `domain.event`.
##
## A subsystem PR that introduces an id adds a constant here and a row in
## ARCHITECTURE_SPEC.md's "Event id namespace registry".

# impact.* - a hit landed. Consumers: Impact VFX, Camera, SFX, UI damage text.
const IMPACT_BASIC := &"impact.basic"
const IMPACT_HEAVY := &"impact.heavy"
const IMPACT_CRIT := &"impact.crit"
const IMPACT_BLOCK := &"impact.block"

# combat.* - combat flow beats. Consumers: Impact VFX, Camera.
const COMBAT_HITSTOP := &"combat.hitstop"
const COMBAT_KNOCKBACK := &"combat.knockback"
const COMBAT_DEATH := &"combat.death"

# damage.* - a health/resource delta. Consumers: UI/HUD, SFX.
const DAMAGE_DEALT := &"damage.dealt"
const DAMAGE_HEALED := &"damage.healed"

# entity.* - lifecycle. Consumers: Impact VFX, SFX.
const ENTITY_SPAWNED := &"entity.spawned"
const ENTITY_DESTROYED := &"entity.destroyed"

# biome.* - environment change. Consumers: World, BGM, Camera, Audio Bus.
const BIOME_ENTERED := &"biome.entered"
const BIOME_EXITED := &"biome.exited"

# camera.* - explicit camera direction. Consumer: Camera.
const CAMERA_FOCUS := &"camera.focus"
const CAMERA_ZOOM := &"camera.zoom"
const CAMERA_SHAKE := &"camera.shake"

# ui.* - UI interaction feedback. Consumers: UI/HUD, SFX (dry bus).
const UI_HOVER := &"ui.hover"
const UI_CONFIRM := &"ui.confirm"
const UI_CANCEL := &"ui.cancel"
const UI_NOTIFY := &"ui.notify"

# music.* - score direction. Consumer: BGM.
const MUSIC_THEME := &"music.theme"
const MUSIC_STINGER := &"music.stinger"
const MUSIC_TENSION := &"music.tension"

# state.* - persistent game/character state. Consumers: Camera post-FX, Audio Bus, BGM.
const STATE_HURT := &"state.hurt"
const STATE_LOWHEALTH := &"state.lowhealth"
const STATE_PAUSED := &"state.paused"
