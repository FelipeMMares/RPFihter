extends Resource
class_name CommandSequence


@export var name: String = ""

# Sequência normal.
# Exemplo:
# ["down", "left"]
@export var inputs: Array[String] = []

# Botões que precisam finalizar o comando juntos.
# Exemplo:
# ["lightPunch", "highPunch"]
@export var simultaneous_inputs: Array[String] = []

# 0 = precisam cair exatamente no mesmo physics frame.
@export_range(0, 5, 1)
var simultaneous_window_frames: int = 0

# Máximo de frames entre cada parte do movimento.
@export_range(1, 60, 1)
var max_gap_frames: int = 12

@export var is_special: bool = false


func is_valid() -> bool:
	return (
		not name.is_empty()
		and (
			not inputs.is_empty()
			or not simultaneous_inputs.is_empty()
		)
	)


func get_reversed_sequence() -> Array[String]:
	var reversed_seq: Array[String] = (
		inputs.duplicate()
	)

	reversed_seq.reverse()

	return reversed_seq
