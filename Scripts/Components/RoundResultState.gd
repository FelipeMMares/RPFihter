extends State
class_name RoundResultState


@export var animation_name: StringName = &""
@export var allow_fall_until_floor: bool = false


@onready var character: CharacterBody2D = (
	get_parent().get_parent()
	as CharacterBody2D
)


func _enter() -> void:
	if character == null:
		return

	character.velocity.x = 0.0

	if not allow_fall_until_floor:
		character.velocity.y = 0.0

	if character.has_method("end_guard"):
		character.call("end_guard")

	var selected_animation: StringName = (
		animation_name
		if animation_name != &""
		else StringName(name)
	)

	play_animation.emit(
		String(selected_animation),
		false
	)


func _physics_process(_delta: float) -> void:
	if character == null:
		return

	character.velocity.x = 0.0

	if allow_fall_until_floor:
		if character.is_on_floor():
			character.velocity = Vector2.ZERO
	else:
		character.velocity.y = 0.0


func _animation_finished() -> void:
	# Não realiza transição.
	# O personagem permanece no último frame.
	pass
