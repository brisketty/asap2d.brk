class_name CameraTrauma
extends Resource
## One row of the Camera subsystem's event -> trauma table: how much shake trauma
## a semantic event adds. Designer-tunable as a typed array on CameraDirector.

@export var trauma_event_id: StringName = &"impact.heavy"
## Added to the trauma accumulator (which is clamped to 0..1).
@export var trauma_amount: float = 0.4
