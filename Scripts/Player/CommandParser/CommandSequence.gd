extends Resource
class_name  CommandSequence

@export var name : String = ""
@export var inputs : Array[String] = []

func is_valid() -> bool:
	return not name.is_empty() and not inputs.is_empty()
