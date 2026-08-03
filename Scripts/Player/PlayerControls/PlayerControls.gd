extends Resource
class_name PlayerControls

@export var up : String
@export var down : String
@export var left : StringName
@export var right : StringName
@export var light_punch : String
@export var high_punch : String
@export var kick : String
@export var low_kick : String
@export var throw: StringName
@export var guard: StringName


func is_walking() -> bool:
	return Input.is_action_pressed(right) or\
			Input.is_action_pressed(left)

func is_jumping() -> bool:
	return Input.is_action_just_pressed(up)
	
func just_crouched() -> bool:
	return Input.is_action_just_pressed(down)

func just_light_punch() -> bool:
	return Input.is_action_just_pressed(light_punch)

func get_throw_direction() -> float:
	var left_pressed := Input.is_action_pressed(left)
	var right_pressed := Input.is_action_pressed(right)

	# Impede o agarrão caso esquerda e direita
	# estejam pressionadas simultaneamente.
	if left_pressed and right_pressed:
		return 0.0

	# O botão Throw acabou de ser pressionado
	# enquanto uma direção já estava segurada.
	if Input.is_action_just_pressed(throw):
		if left_pressed:
			return -1.0

		if right_pressed:
			return 1.0

	# Permite pressionar a direção imediatamente
	# depois do botão Throw.
	if Input.is_action_pressed(throw):
		if Input.is_action_just_pressed(left):
			return -1.0

		if Input.is_action_just_pressed(right):
			return 1.0

	return 0.0
