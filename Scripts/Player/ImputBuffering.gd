extends Node

class ActionTimeFrame:
	var Action_name: String
	var TimeFrame: int
	
func _init(p_action_name: String,
	p_timeFrame = Engine.get_physics_frames()) -> void:
		pass

@export var player_controls : PlayerControls

var actions = Array[String] = []

func _ready() -> void:
	pass # Replace with function body.
