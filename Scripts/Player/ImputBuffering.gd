extends Node
class_name InputBuffer


@export var buffer_window: int = 60
@export var input_prefix: String = ""
@export var player_controls: PlayerControls


class ActionTimeFrame:
	var action_name: String
	var timeframe: int

	func _init(
		p_action_name: String,
		p_timeframe: int
	) -> void:
		action_name = p_action_name
		timeframe = p_timeframe

	func _to_string() -> String:
		return "action: %s\t | timeframe: %d" % [
			action_name,
			timeframe
		]


var actions: Array[String] = []
var buffer: Array[ActionTimeFrame] = []

# Frame em que cada botão começou a ser segurado.
var _hold_start_frames: Dictionary = {}

# Duração do último botão que foi solto.
var _last_hold_duration: Dictionary = {}

# Frame em que o botão foi solto.
var _last_release_frame: Dictionary = {}

func _ready() -> void:
	if player_controls == null:
		printerr("InputBuffer: PlayerControls não definido.")
		return

	actions.clear()

	var control_actions := [
		player_controls.left,
		player_controls.right,
		player_controls.up,
		player_controls.down,
		player_controls.light_punch,
		player_controls.high_punch,
		player_controls.kick,
		player_controls.low_kick
	]

	for action_value in control_actions:
		var action_name := String(action_value)
		_register_action(action_name)

	# Só procura ações pelo prefixo quando existe um prefixo.
	# Isso evita adicionar todas as ações do projeto quando
	# input_prefix estiver vazio.
	if not input_prefix.is_empty():
		for input_value in InputMap.get_actions():
			var input_name := String(input_value)

			if input_name.begins_with(input_prefix):
				_register_action(input_name)

	print("InputBuffer: ações registradas: ", actions)
	print("InputBuffer: prefixo: ", input_prefix)


func _register_action(action_name: String) -> void:
	if action_name.is_empty():
		return

	# Evita que uma ação seja registrada duas vezes.
	# Sem isso, um único clique poderia gerar dois inputs.
	if action_name in actions:
		return

	actions.append(action_name)


func _physics_process(_delta: float) -> void:
	_clean_input()
	_update_hold_tracking()
	_capture_input()


func _capture_input() -> void:
	var current_frame := Engine.get_physics_frames()

	for action in actions:
		if not Input.is_action_just_pressed(action):
			continue

		var raw_action := _input_to_resource_action(action)

		buffer.append(
			ActionTimeFrame.new(
				raw_action,
				current_frame
			)
		)

		print(
			"InputBuffer: ",
			raw_action,
			" registrado no frame ",
			current_frame
		)

		# Debug opcional:
		# debug_buffer()


func _input_to_resource_action(action: String) -> String:
	if (
		not input_prefix.is_empty()
		and action.begins_with(input_prefix)
	):
		return action.trim_prefix(input_prefix)

	return action


func _clean_input() -> void:
	var current_frame := Engine.get_physics_frames()

	for i in range(buffer.size() - 1, -1, -1):
		var input_age := (
			current_frame - buffer[i].timeframe
		)

		if input_age >= buffer_window:
			buffer.remove_at(i)


func get_input_at(i: int) -> ActionTimeFrame:
	if i < 0 or i >= buffer.size():
		return null

	return buffer[i]


func get_action_name_at(i: int) -> String:
	var input := get_input_at(i)

	if input == null:
		return ""

	return input.action_name


func get_recent_inputs(
	count: int
) -> Array[ActionTimeFrame]:
	var start := maxi(
		0,
		buffer.size() - count
	)

	return buffer.slice(
		start,
		buffer.size()
	)


func is_buffer_stale(
	timeout_frames: int = 30
) -> bool:
	if buffer.is_empty():
		return true

	var last_input := buffer[-1]
	var current_frame := Engine.get_physics_frames()

	return (
		current_frame - last_input.timeframe
	) > timeout_frames


func has_input(
	action_name: String,
	within_frames: int = -1
) -> bool:
	var current_frame := Engine.get_physics_frames()

	for i in range(buffer.size() - 1, -1, -1):
		var input := buffer[i]

		if input.action_name != action_name:
			continue

		if within_frames == -1:
			return true

		if (
			current_frame - input.timeframe
			<= within_frames
		):
			return true

	return false


func get_last_input_of_type(
	action_name: String
) -> ActionTimeFrame:
	for i in range(buffer.size() - 1, -1, -1):
		if buffer[i].action_name == action_name:
			return buffer[i]

	return null


# A sequência deve ser fornecida do input mais recente
# para o mais antigo.
#
# Exemplo:
# ["light_punch", "light_punch"]
func has_sequence(
	sequence: Array[String],
	max_gap: int = 5
) -> bool:
	if sequence.is_empty():
		return false

	if buffer.size() < sequence.size():
		return false

	var sequence_index := 0
	var last_frame := -1

	for i in range(buffer.size() - 1, -1, -1):
		var input := buffer[i]

		if input.action_name != sequence[sequence_index]:
			continue

		if (
			last_frame == -1
			or last_frame - input.timeframe <= max_gap
		):
			sequence_index += 1
			last_frame = input.timeframe

			if sequence_index >= sequence.size():
				return true
		else:
			sequence_index = 0
			last_frame = -1

			if input.action_name == sequence[0]:
				sequence_index = 1
				last_frame = input.timeframe

	return false


func cleanup(
	timeout_frames: int = -1
) -> void:
	var current_frame := Engine.get_physics_frames()

	var max_time := (
		timeout_frames
		if timeout_frames > 0
		else buffer_window
	)

	var i := 0

	while i < buffer.size():
		var input_age := (
			current_frame - buffer[i].timeframe
		)

		if input_age >= max_time:
			buffer.remove_at(i)
		else:
			i += 1


func add_input_direct(
	action_name: String
) -> void:
	if action_name.is_empty():
		return

	var current_frame := Engine.get_physics_frames()

	buffer.append(
		ActionTimeFrame.new(
			action_name,
			current_frame
		)
	)


func clear_buffer() -> void:
	buffer.clear()


func debug_buffer() -> void:
	print("")
	print("=========== INPUT BUFFER ===========")

	for i in range(buffer.size() - 1, -1, -1):
		var input := buffer[i]

		print(
			"#",
			i,
			" | ",
			input.action_name,
			" | frame ",
			input.timeframe
		)

	print("====================================")

func _update_hold_tracking() -> void:
	var current_frame := Engine.get_physics_frames()

	for action in actions:
		var raw_action := _input_to_resource_action(action)

		if Input.is_action_just_pressed(action):
			_hold_start_frames[raw_action] = current_frame

		elif (
			Input.is_action_pressed(action)
			and not _hold_start_frames.has(raw_action)
		):
			_hold_start_frames[raw_action] = current_frame

		if Input.is_action_just_released(action):
			if _hold_start_frames.has(raw_action):
				var start_frame: int = int(
					_hold_start_frames[raw_action]
				)

				_last_hold_duration[raw_action] = (
					current_frame - start_frame
				)

				_last_release_frame[raw_action] = current_frame

			_hold_start_frames.erase(raw_action)


func get_current_hold_frames(action_name: String) -> int:
	if not _hold_start_frames.has(action_name):
		return 0

	var current_frame := Engine.get_physics_frames()
	var start_frame: int = int(
		_hold_start_frames[action_name]
	)

	return current_frame - start_frame


func get_last_release_frame(action_name: String) -> int:
	if not _last_release_frame.has(action_name):
		return -1

	return int(_last_release_frame[action_name])


func had_recent_charge(
	action_name: String,
	minimum_frames: int,
	release_window: int = 12
) -> bool:
	# Ainda está segurando o botão.
	if get_current_hold_frames(action_name) >= minimum_frames:
		return true

	if not _last_hold_duration.has(action_name):
		return false

	if not _last_release_frame.has(action_name):
		return false

	var held_frames: int = int(
		_last_hold_duration[action_name]
	)

	var released_at: int = int(
		_last_release_frame[action_name]
	)

	var current_frame := Engine.get_physics_frames()

	return (
		held_frames >= minimum_frames
		and current_frame - released_at <= release_window
	)
