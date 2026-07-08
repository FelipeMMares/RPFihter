extends RefCounted
class_name CommandNode

# Cada filho representa o próximo input possível.
# Exemplo:
#
# root
# └── right
#      └── left
#           └── left
#                resulting_move = "teste_combo"

var children : Dictionary[String, CommandNode] = {}

# Nome do golpe encontrado ao chegar neste nó.
var resulting_move : String = ""


func add_sequence(sequence: Array[String], move_name: String) -> void:

	# -----------------------------------------------------------------
	# ALTERAÇÃO
	#
	# Não usamos reverse() diretamente.
	#
	# reverse() altera o array original.
	#
	# duplicate() cria uma cópia.
	# -----------------------------------------------------------------

	var reversed_sequence := sequence.duplicate()
	reversed_sequence.reverse()

	var current_node : CommandNode = self

	for action in reversed_sequence:

		if not current_node.children.has(action):
			current_node.children[action] = CommandNode.new()

		current_node = current_node.children[action]

	current_node.resulting_move = move_name
