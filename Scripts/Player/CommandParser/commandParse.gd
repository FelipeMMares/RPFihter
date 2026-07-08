#extends Node
#class_name CommandParser
#
#@export var commands : Array[CommandSequence] = []
#@export var input_buffer : InputBuffer
#
#var root := CommandNode.new()
#
#func _ready() -> void:
	#
	#for command in commands:
		#if command and command.is_valid():
			#root.add_sequence(command.inputs, command.name)
	#print("Filhos do root:")
	#print(root.children.keys())
#
#func get_current_special_move() -> String:
	#var current_node = root
	#var current_frame = Engine.get_physics_frames()
	#
	#for i in range(input_buffer.buffer.size()-1, -1, -1):
		#var input = input_buffer.get_input_at(i)
		#print("Lendo:", input.action_name)
		#
		#if current_node.children.has(input.action_name):
			#print("Encontrou nó:", input.action_name)
			#current_node = current_node.children[input.action_name]
			#
			#if current_node.resulting_move != "":
				#print("Move encontrado:", current_node.resulting_move)
				#printerr("funfou!")
				#input_buffer.buffer.clear()
				#return current_node.resulting_move
		#
		#else:
			#print("Falhou em:", input.action_name)
			#break
	#
	#return ""

# command_parser.gd
extends Node
class_name CommandParser

@export var commands : Array[CommandSequence] = []
@export var input_buffer : InputBuffer

# Raiz da Trie
var root := CommandNode.new()

func _ready() -> void:

	if input_buffer == null:
		printerr("CommandParser: InputBuffer não definido.")
		return

	_build_tree()

	print("\n==============================")
	print("ÁRVORE DE COMANDOS")
	print("==============================")

	print_command_tree(root,0)

	print("==============================\n")

func _build_tree():

	root = CommandNode.new()

	for command in commands:

		if command == null:
			continue

		if not command.is_valid():
			continue

		root.add_sequence(command.inputs, command.name)

		print(
			"Comando carregado:",
			command.name,
			" -> ",
			command.inputs
		)

func print_command_tree(node: CommandNode, depth:int):

	var indent = "   ".repeat(depth)

	for action in node.children.keys():

		var child = node.children[action]

		if child.resulting_move != "":
			print(indent,action," => ",child.resulting_move)
		else:
			print(indent,action)

		print_command_tree(child,depth+1)

func get_current_special_move() -> String:

	if input_buffer == null:
		return ""

	input_buffer.cleanup()

	if input_buffer.buffer.is_empty():
		return ""

		# ==========================
	# DEBUG DO BUFFER
	# ==========================
	print("\n===== BUFFER =====")
	for input in input_buffer.buffer:
		print(input.action_name)
	print("==================")

	var current_node := root

	# Apenas para debug
	var matched := []

	# Começa do input mais recente
	for i in range(input_buffer.buffer.size()-1,-1,-1):

		var input = input_buffer.buffer[i]
		var action = input.action_name

		print("--------------------------------")
		print("Lendo:",action)
		print("Nós disponíveis:",current_node.children.keys())

		if current_node.children.has(action):

			current_node = current_node.children[action]

			matched.append(action)

			print("Passou.")

			if current_node.resulting_move != "":

				print()

				print("================================")
				print("MOVIMENTO ENCONTRADO")
				print(current_node.resulting_move)
				print("Sequência:",matched)
				print("================================")

				input_buffer.buffer.clear()

				return current_node.resulting_move

		else:

			print("Falhou em:",action)

			# --------------------------------------------------
			# ALTERAÇÃO IMPORTANTE
			#
			# Reinicia a busca na raiz.
			#
			# Isso permite ignorar inputs antigos
			# que não fazem parte do comando.
			# --------------------------------------------------

			current_node = root
			matched.clear()
	
	return ""

func clear_buffer():

	if input_buffer:
		input_buffer.buffer.clear()

func is_special_move(move_name:String)->bool:

	return move_name in [
		"hadouken",
		"shoryuken",
		"tatsumaki"
	]

func is_combo(move_name:String)->bool:

	return not is_special_move(move_name)
