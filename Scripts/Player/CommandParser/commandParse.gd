extends Node
class_name CommandParser


@export var commands: Array[CommandSequence] = []
@export var input_buffer: InputBuffer

var root := CommandNode.new()


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

		root.add_sequence(
			command.inputs,
			command.name
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
	return move_name in [
		"hadouken",
		"shoryuken",
		"tatsumaki"
	]


func is_combo(
	move_name: String
) -> bool:
	return not is_special_move(move_name)
