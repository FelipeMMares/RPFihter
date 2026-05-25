extends Node
class_name InputBuffer

@export var buffer_window : int = 15
@export var player_controls : PlayerControls
@export var input_prefix : String

class ActionTimeFrame:
	var action_name: String
	var timeframe: int
	
	func _init(p_action_name: String,
		p_timeFrame = Engine.get_physics_frames()) -> void:
		action_name = p_action_name
		timeframe = p_timeFrame

	func _to_string() -> String:
		return "action: %s\ttimeframe: %d" % [action_name, timeframe]

var actions : Array[String] = []
var buffer : Array[ActionTimeFrame] = []

func _ready() -> void:
	
	for input in InputMap.get_actions():
		if input.begins_with(input_prefix):
			actions.append(input)
	print("Ações encontradas: ", actions)
	print("Input Prefix: ", input_prefix)

func _physics_process(delta: float) -> void:
	_clean_input()
	_capture_input()
	print(buffer)
		
func _capture_input() -> void:
	var current_frame : int = Engine.get_physics_frames()
	
	for action : String in actions:
		# CORRIGIDO: Armazenar o valor em uma variável para debug
		var action_key = player_controls.get(action)
		
		# DEBUG: Verificar o valor retornado
		if action_key == null:
			print("ERRO: player_controls.get('", action, "') retornou null")
			print("player_controls: ", player_controls)
			continue
		
		print("action: ", action, " -> key: ", action_key)
		
		if Input.is_action_just_pressed(action_key):
			var resource_action = _input_to_resource_action(action)
			var p_action_frame = ActionTimeFrame.new(resource_action, current_frame)
			buffer.append(p_action_frame)


func _input_to_resource_action(action: String) -> String:
	# CORRIGIDO: Verificar se a string tem tamanho suficiente
	if action.length() > input_prefix.length():
		return action.right(-input_prefix.length())
	return action  # Retorna a própria ação se não houver prefixo

func _clean_input() -> void:
	var current_frame : int = Engine.get_physics_frames()
	buffer.filter(
		func (a: ActionTimeFrame) -> bool:
			return current_frame - a.timeframe <= buffer_window
	)
	
