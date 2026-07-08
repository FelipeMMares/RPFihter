extends Node
class_name InputBuffer

@export var buffer_window : int = 60
@export var input_prefix : String
@export var player_controls : PlayerControls  # ← NOVO: Referência ao PlayerControls

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
	if player_controls == null:
		printerr("InputBuffer: PlayerControls não definido.")
		return

	actions.clear()

	var control_actions = [
		player_controls.left,
		player_controls.right,
		player_controls.up,
		player_controls.down,
		player_controls.light_punch,
		player_controls.high_punch,
		player_controls.kick,
		player_controls.low_kick
	]

	for action in control_actions:

		if action == "":
			continue

		if action not in actions:
			actions.append(action)

	#print("\n===== INPUTS REGISTRADOS =====")

	#for action in actions:
		#print(action)

	#print("==============================")

	for input in InputMap.get_actions():
		if input.begins_with(input_prefix):
			actions.append(input)
	#print("Ações encontradas: ", actions)
	#print("Input Prefix: ", input_prefix)

func _physics_process(delta: float) -> void:
	_clean_input()
	_capture_input()

func _capture_input() -> void:
	var current_frame := Engine.get_physics_frames()

	for action in actions:
		if Input.is_action_just_pressed(action):

			var raw_action := _input_to_resource_action(action)

			buffer.append(ActionTimeFrame.new(raw_action, current_frame))

			#print("--------------------------------")
			#print("INPUT:", raw_action)
			#print("BUFFER SIZE:", buffer.size())

			for item in buffer:
				print(" -> ", item.action_name)

func _input_to_resource_action(action:String)->String:

	#print("Prefixo atual:", input_prefix)
	#print("Action recebida:", action)

	if action.begins_with(input_prefix):

		var converted = action.trim_prefix(input_prefix)

		#print("Convertido:", converted)

		return converted

	return action

func _clean_input():

	var current_frame = Engine.get_physics_frames()

	for i in range(buffer.size()-1,-1,-1):

		if current_frame-buffer[i].timeframe>=buffer_window:

			buffer.remove_at(i)

func get_input_at(i: int) -> ActionTimeFrame:
	
	if i < 0 or i >= buffer.size():
		return null
	
	return buffer[i]

# input_buffer.gd (Adicione isso no FINAL do arquivo)

# ========== NOVOS MÉTODOS PARA INTEGRAÇÃO ==========

# Retorna os últimos N inputs (útil para verificar sequências de combo)
func get_recent_inputs(count: int) -> Array[ActionTimeFrame]:
	var start = max(0, buffer.size() - count)
	return buffer.slice(start, buffer.size())

# Verifica se o buffer está "velho" demais
func is_buffer_stale(timeout_frames: int = 30) -> bool:
	if buffer.is_empty():
		return true
	var last = buffer[-1]
	var current_frame = Engine.get_physics_frames()
	return (current_frame - last.timeframe) > timeout_frames

# Verifica se um input específico está no buffer
func has_input(action_name: String, within_frames: int = -1) -> bool:
	for i in range(buffer.size() - 1, -1, -1):
		if buffer[i].action_name == action_name:
			if within_frames == -1:
				return true
			var current_frame = Engine.get_physics_frames()
			if (current_frame - buffer[i].timeframe) <= within_frames:
				return true
	return false

# Retorna o último input de um tipo específico
func get_last_input_of_type(action_name: String) -> ActionTimeFrame:
	for i in range(buffer.size() - 1, -1, -1):
		if buffer[i].action_name == action_name:
			return buffer[i]
	return null

# Verifica se o buffer contém uma sequência específica (do mais recente para o mais antigo)
func has_sequence(sequence: Array[String], max_gap: int = 5) -> bool:
	if sequence.is_empty() or buffer.size() < sequence.size():
		return false
	
	var seq_index = 0
	var last_frame = -1
	
	# Percorre do mais recente para o mais antigo
	for i in range(buffer.size() - 1, -1, -1):
		if buffer[i].action_name == sequence[seq_index]:
			# Verifica se está dentro do gap permitido
			if last_frame == -1 or (last_frame - buffer[i].timeframe) <= max_gap:
				seq_index += 1
				last_frame = buffer[i].timeframe
				
				if seq_index >= sequence.size():
					return true
			else:
				# Reset se o gap for muito grande
				seq_index = 0
				last_frame = -1
				# Tenta começar de novo com este input
				if buffer[i].action_name == sequence[0]:
					seq_index = 1
					last_frame = buffer[i].timeframe
	
	return false

#func debug_actions():
#
	#print()
#
	#print("===== ACTIONS =====")
#
	#for action in actions:
		#print(action)
#
	#print("===================")
#
#func debug_buffer():
#
	#print()
#
	#print("=========== BUFFER ===========")
#
	#for i in range(buffer.size()-1,-1,-1):
#
		#var data = buffer[i]
#
		#print(
			#"#",
			#i,
			#" | ",
			#data.action_name,
			#" | frame ",
			#data.timeframe
		#)
#
	#print("==============================")

func cleanup(timeout_frames: int = -1):
	var current_frame = Engine.get_physics_frames()
	var max_time = timeout_frames if timeout_frames > 0 else buffer_window
	var i = 0
	while i < buffer.size():
		if (current_frame - buffer[i].timeframe) > max_time:
			buffer.remove_at(i)
		else:
			i += 1

func add_input_direct(action_name: String) -> void:
	var current_frame := Engine.get_physics_frames()

	var input := ActionTimeFrame.new(
		action_name,
		current_frame
	)

	buffer.append(input)

	#print("➕ Input manual:", action_name)

#func add_test_sequence(sequence:Array[String]):
#
	#buffer.clear()
#
	#for action in sequence:
#
		#add_input_direct(action)
#
	#debug_buffer()
