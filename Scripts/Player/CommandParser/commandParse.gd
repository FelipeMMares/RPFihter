extends Node
class_name CommandParser


@export var commands: Array[CommandSequence] = []
@export var input_buffer: InputBuffer

var root := CommandNode.new()

var _last_charge_command_frame: int = -1

func _ready() -> void:
	if input_buffer == null:
		printerr(
			"CommandParser: InputBuffer não definido."
		)
		return

	_build_tree()

	print("")
	print("==============================")
	print("ÁRVORE DE COMANDOS")
	print("==============================")

	print_command_tree(root, 0)

	print("==============================")
	print("")


func _build_tree() -> void:
	root = CommandNode.new()

	for command in commands:
		if command == null:
			continue

		if not command.is_valid():
			printerr(
				"CommandParser: comando inválido ignorado."
			)
			continue

		var normalized_command_name: String = (
			command.name.strip_edges()
		)

		# Comandos terminados com botões simultâneos
		# são reconhecidos separadamente.
		if not command.simultaneous_inputs.is_empty():
			print(
				"Comando simultâneo carregado: ",
				command.name,
				" | sequência: ",
				command.inputs,
				" | final: ",
				command.simultaneous_inputs
			)

			continue

		root.add_sequence(
			command.inputs,
			normalized_command_name
		)

		print(
			"Comando carregado: ",
			command.name,
			" -> ",
			command.inputs
		)


func print_command_tree(
	node: CommandNode,
	depth: int
) -> void:
	var indent := "   ".repeat(depth)

	for action in node.children.keys():
		var child: CommandNode = (
			node.children[action]
		)

		if not child.resulting_move.is_empty():
			print(
				indent,
				action,
				" => ",
				child.resulting_move
			)
		else:
			print(
				indent,
				action
			)

		print_command_tree(
			child,
			depth + 1
		)


# --------------------------------------------------
# MÉTODO NORMAL
#
# Reconhece o comando e limpa o buffer.
#
# Use para Hadouken, Shoryuken e outros comandos
# que devem ser consumidos imediatamente.
# --------------------------------------------------
func get_current_special_move() -> String:
	if input_buffer == null:
		return ""

	input_buffer.cleanup()

	if input_buffer.buffer.is_empty():
		return ""

	var simultaneous_move: String = (
		_get_simultaneous_special_move()
	)

	if not simultaneous_move.is_empty():
		print(
			"CommandParser: movimento encontrado: ",
			simultaneous_move,
			" | comando simultâneo"
		)

		input_buffer.clear_buffer()

		return simultaneous_move

	var current_node := root
	var matched: Array[String] = []

	for i in range(
		input_buffer.buffer.size() - 1,
		-1,
		-1
	):
		var input := input_buffer.buffer[i]
		var action := input.action_name

		if current_node.children.has(action):
			current_node = (
				current_node.children[action]
				as CommandNode
			)

			matched.append(action)

			if not current_node.resulting_move.is_empty():
				var move_name := (
					current_node.resulting_move
				)

				print(
					"CommandParser: movimento encontrado: ",
					move_name,
					" | sequência: ",
					matched
				)

				input_buffer.clear_buffer()

				return move_name
		else:
			current_node = root
			matched.clear()

	return ""


# --------------------------------------------------
# MÉTODO NOVO PARA COMBOS
#
# Reconhece o comando sem limpar o buffer.
#
# Continua examinando a árvore para encontrar a
# sequência mais longa.
#
# Exemplo:
#
# 2 LightPunch:
# retorna "light_punch_2"
#
# 3 LightPunch:
# continua lendo e retorna "light_punch_3"
# --------------------------------------------------
func peek_current_move(
	max_gap_frames: int = -1
) -> String:
	if input_buffer == null:
		return ""

	input_buffer.cleanup()

	if input_buffer.buffer.is_empty():
		return ""

	var current_node := root
	var best_move := ""

	var last_matched_frame := -1

	for i in range(
		input_buffer.buffer.size() - 1,
		-1,
		-1
	):
		var input := input_buffer.buffer[i]
		var action := input.action_name

		if (
			last_matched_frame != -1
			and max_gap_frames > 0
		):
			var gap := (
				last_matched_frame
				- input.timeframe
			)

			if gap > max_gap_frames:
				break

		if not current_node.children.has(action):
			break

		current_node = (
			current_node.children[action]
				as CommandNode
		)

		last_matched_frame = input.timeframe

		# Não retorna imediatamente.
		# Guarda o resultado e continua procurando
		# uma sequência maior.
		if not current_node.resulting_move.is_empty():
			best_move = current_node.resulting_move

	if not best_move.is_empty():
		print(
			"CommandParser PEEK encontrou: ",
			best_move
		)

	return best_move


func clear_buffer() -> void:
	if input_buffer != null:
		input_buffer.clear_buffer()


func is_special_move(
	move_name: String
) -> bool:
	var normalized_name: String = (
		move_name.strip_edges()
	)

	for command in commands:
		if command == null:
			continue

		if (
			command.name.strip_edges()
			!= normalized_name
		):
			continue

		return command.is_special

	return false


func is_combo(
	move_name: String
) -> bool:
	return not is_special_move(move_name)

func consume_charge_command(
	back_action: String,
	forward_action: String,
	attack_action: String,
	minimum_charge_frames: int = 45,
	input_window: int = 8,
	release_window: int = 12
) -> bool:
	if input_buffer == null:
		return false

	input_buffer.cleanup()

	var forward_input := input_buffer.get_last_input_of_type(
		forward_action
	)

	var attack_input := input_buffer.get_last_input_of_type(
		attack_action
	)

	if forward_input == null or attack_input == null:
		return false

	var first_command_frame: int = mini(
		forward_input.timeframe,
		attack_input.timeframe
	)

	var last_command_frame: int = maxi(
		forward_input.timeframe,
		attack_input.timeframe
	)

	# Frente e soco precisam acontecer próximos.
	if (
		last_command_frame - first_command_frame
		> input_window
	):
		return false

	var release_frame: int = (
		input_buffer.get_last_release_frame(back_action)
	)

	if release_frame < 0:
		return false

	# O botão "para trás" precisa ter sido solto
	# antes de frente + soco.
	if first_command_frame < release_frame:
		return false

	# Frente + soco precisam acontecer logo após soltar.
	if (
		first_command_frame - release_frame
		> release_window
	):
		return false

	if not input_buffer.had_recent_charge(
		back_action,
		minimum_charge_frames,
		release_window
	):
		return false

	# Impede reconhecer o mesmo comando várias vezes.
	if last_command_frame == _last_charge_command_frame:
		return false

	_last_charge_command_frame = last_command_frame

	print(
		"KIKOKEN RECONHECIDO | carga: ",
		minimum_charge_frames,
		" frames | ",
		back_action,
		" → ",
		forward_action,
		" + ",
		attack_action
	)

	input_buffer.clear_buffer()

	return true

func _get_simultaneous_special_move() -> String:
	if input_buffer == null:
		return ""

	for command in commands:
		if command == null:
			continue

		if command.simultaneous_inputs.is_empty():
			continue

		if not command.is_special:
			continue

		if _matches_simultaneous_command(
			command
		):
			var move_name: String = (
				command.name.strip_edges()
			)

			print(
				"CommandParser: comando simultâneo encontrado: ",
				move_name
			)

			return move_name

	return ""


func _matches_simultaneous_command(
	command: CommandSequence
) -> bool:
	if input_buffer == null:
		return false

	if command == null:
		return false

	if command.simultaneous_inputs.is_empty():
		return false

	# ---------------------------------------
	# 1. Verifica os botões finais.
	# ---------------------------------------

	var chord_first_frame: int = 2147483647
	var chord_last_frame: int = -1

	for action_name in command.simultaneous_inputs:
		var input := (
			input_buffer.get_last_input_of_type(
				action_name
			)
		)

		if input == null:
			return false

		chord_first_frame = mini(
			chord_first_frame,
			input.timeframe
		)

		chord_last_frame = maxi(
			chord_last_frame,
			input.timeframe
		)

	# Todos os botões precisam acontecer juntos.
	if (
		chord_last_frame
		- chord_first_frame
		> command.simultaneous_window_frames
	):
		return false

	# Se não existir movimento antes do acorde,
	# o acorde sozinho é suficiente.
	if command.inputs.is_empty():
		return true

	# ---------------------------------------
	# 2. Procura a sequência anterior.
	#
	# command.inputs:
	# ["down", "left"]
	#
	# Procuramos de trás para frente:
	# left -> down
	# ---------------------------------------

	var sequence_index: int = (
		command.inputs.size() - 1
	)

	var last_matched_frame: int = (
		chord_first_frame
	)

	for i in range(
		input_buffer.buffer.size() - 1,
		-1,
		-1
	):
		var input := (
			input_buffer.buffer[i]
		)

		# O movimento precisa acontecer ANTES
		# dos botões finais.
		if input.timeframe >= chord_first_frame:
			continue

		var expected_action: String = (
			command.inputs[sequence_index]
		)

		if input.action_name != expected_action:
			continue

		var frame_gap: int = (
			last_matched_frame
			- input.timeframe
		)

		if frame_gap > command.max_gap_frames:
			return false

		last_matched_frame = input.timeframe

		sequence_index -= 1

		if sequence_index < 0:
			return true

	return false
