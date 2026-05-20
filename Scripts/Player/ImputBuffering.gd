extends Node

class ActionTimeFrame:
	var Action_name: String
	var TimeFrame: int
	
func _init(p_action_name: String,
	p_timeFrame = Engine.get_physics_frames()) -> void:
		pass

@export var player_controls : PlayerControls
@export var input_prefix : String

var actions : Array[String] = []

func _ready() -> void:
	
	for input in InputMap.get_actions():
		printt("input= ", input)
