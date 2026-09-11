class_name StateSfxSet
extends Resource
## One row of `SfxPlayer.state_sfx_table`: the enter / sustained-loop / exit
## sounds for a `state.*` event (hurt / lowhealth / paused). Each stage picks
## randomly among its variation ids (empty -> silent) with its own pitch jitter.
## `loop_audio_variation_ids` streams should have their loop point set - they
## play for as long as the state is active and are stopped on `state.clear`.

@export var state_event_id: StringName = &"state.hurt"

@export_group("Enter", "enter_")
@export var enter_audio_variation_ids: Array[StringName] = []
@export var enter_pitch_semitones: float = 0.0

@export_group("Loop", "loop_")
@export var loop_audio_variation_ids: Array[StringName] = []
@export var loop_pitch_semitones: float = 0.0

@export_group("Exit", "exit_")
@export var exit_audio_variation_ids: Array[StringName] = []
@export var exit_pitch_semitones: float = 0.0
