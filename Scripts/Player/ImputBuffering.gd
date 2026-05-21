extends Node
class_name InputBuffer

@export var player_controls : PlayerControls
@export var input_prefix : String

class ActionTimeFrame:
	var Action_name: String
	var TimeFrame: int
	
func _init(p_action_name: String,
	p_timeFrame = Engine.get_physics_frames()) -> void:
		pass


var actions : Array[String] = []
var buffer : Array[ActionTimeFrame] = []

func _ready() -> void:
	
	for input in InputMap.get_actions():
		if input_prefix in input:
			actions.append(input)
		

func _physics_process(delta: float) -> void:
	_capture_input()
		
func _capture_input() -> void:
	var current_frame : int = Engine.get_physics_frames()
	
	for action : String in actions:
		var action_Key = player_controls.get(action)
		if Input.is_action_just_pressed(player_controls.get(action)):
			var p_action_frame = \
			 ActionTimeFrame.new(action_Key, current_frame)
			buffer.append(p_action_frame)
