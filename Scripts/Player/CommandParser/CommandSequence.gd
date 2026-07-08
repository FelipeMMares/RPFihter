#extends Resource
#class_name  CommandSequence
#
#@export var name : String = ""
#@export var inputs : Array[String] = []
#
#func is_valid() -> bool:
	#return not name.is_empty() and not inputs.is_empty()

# command_sequence.gd (Atualizado)
extends Resource
class_name CommandSequence

@export var name : String = ""
@export var inputs : Array[String] = []
@export var is_special : bool = false  # Marca se é golpe especial ou combo

func is_valid() -> bool:
	return not name.is_empty() and not inputs.is_empty()

# Função para inverter a sequência (usada no CommandParser)
func get_reversed_sequence() -> Array[String]:
	var reversed_seq = inputs.duplicate()
	reversed_seq.reverse()
	return reversed_seq
