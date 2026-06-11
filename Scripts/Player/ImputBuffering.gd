extends Node
class_name InputBuffer

@export var buffer_window : int = 15
@export var input_prefix : String

class ActionTimeFrame:
	var action_name: String
	var timeframe: int
	
	func _init(p_action_name: String,
		p_timeFrame : int) -> void:
		action_name = p_action_name
		timeframe = p_timeFrame

	func _to_string() -> String:
		return "action: %s\t | timeframe: %d" % [action_name, timeframe]

var actions : Array[String] = []
var buffer : Array[ActionTimeFrame] = []

func _ready() -> void:
	
	for input in InputMap.get_actions():
		if input.begins_with(input_prefix):
			actions.append(input)
	#print("Ações encontradas: ", actions)
	#print("Input Prefix: ", input_prefix)

func _physics_process(delta: float) -> void:
	_clean_input()
	_capture_input()
	#print("buffer:", buffer)
		
func _capture_input() -> void:
	var current_frame : int = Engine.get_physics_frames()
	
	for action : String in actions:
		if Input.is_action_just_pressed(action):
			var raw_action : String = _input_to_resource_action(action)
			#print("raw_action: ", raw_action)
			var p_action_frame = \
			ActionTimeFrame.new(raw_action, current_frame)
			buffer.append(p_action_frame)


func _input_to_resource_action(action: String) -> String:
	# CORRIGIDO: Verificar se a string tem tamanho suficiente
	if action.length() > input_prefix.length():
		return action.trim_prefix(input_prefix)
	return action  # Retorna a própria ação se não houver prefixo

func _clean_input() -> void:
	var current_frame : int = Engine.get_physics_frames()
	for action in buffer:
		if current_frame - action.timeframe >= buffer_window:
			buffer.erase(action)

func get_input_at(i: int) -> ActionTimeFrame:
	
	if i < 0 or i >= buffer.size():
		return null
	
	return buffer[i]
