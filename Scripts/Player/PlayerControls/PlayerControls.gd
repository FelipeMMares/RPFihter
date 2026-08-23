extends Resource
class_name PlayerControls


@export var up: StringName
@export var down: StringName
@export var left: StringName
@export var right: StringName

@export var light_punch: StringName
@export var high_punch: StringName
@export var kick: StringName
@export var low_kick: StringName

@export var throw: StringName
@export var guard: StringName


func is_walking() -> bool:
	return (
		_is_pressed(right)
		or _is_pressed(left)
	)


func is_jumping() -> bool:
	return _is_just_pressed(
		up
	)

func is_jump_held() -> bool:
	return _is_pressed(
		up
	)


func is_crouch_held() -> bool:
	return _is_pressed(
		down
	)

func just_crouched() -> bool:
	return _is_just_pressed(
		down
	)


func just_light_punch() -> bool:
	return _is_just_pressed(
		light_punch
	)


func get_throw_direction() -> float:
	var left_pressed: bool = (
		_is_pressed(left)
	)

	var right_pressed: bool = (
		_is_pressed(right)
	)

	if left_pressed and right_pressed:
		return 0.0

	if _is_just_pressed(throw):
		if left_pressed:
			return -1.0

		if right_pressed:
			return 1.0

	if _is_pressed(throw):
		if _is_just_pressed(left):
			return -1.0

		if _is_just_pressed(right):
			return 1.0

	return 0.0


func _is_pressed(
	action: StringName
) -> bool:
	if action.is_empty():
		return false

	if not InputMap.has_action(action):
		printerr(
			"PlayerControls: ação não existe: ",
			action
		)
		return false

	return Input.is_action_pressed(
		action
	)


func _is_just_pressed(
	action: StringName
) -> bool:
	if action.is_empty():
		return false

	if not InputMap.has_action(action):
		printerr(
			"PlayerControls: ação não existe: ",
			action
		)
		return false

	return Input.is_action_just_pressed(
		action
	)
