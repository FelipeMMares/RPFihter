extends State
class_name RoundResultState


@export var animation_name: StringName

# Ative somente no FallDefeated.
# Permite que o personagem continue caindo
# até encostar no chão.
@export var allow_fall_until_floor: bool = false


@onready var character: CharacterBody2D = (
	get_parent().get_parent()
	as CharacterBody2D
)


func _enter() -> void:
	set_crouching_hurtbox(false)

	if character != null:
		character.velocity.x = 0.0

		if not allow_fall_until_floor:
			character.velocity.y = 0.0

		if character.has_method("end_guard"):
			character.call("end_guard")

	play_animation.emit(
		animation_name,
		false
	)


func _physics_process(_delta: float) -> void:
	if character == null:
		return

	character.velocity.x = 0.0

	if not allow_fall_until_floor:
		character.velocity.y = 0.0
	elif character.is_on_floor():
		character.velocity = Vector2.ZERO


func _animation_finished() -> void:
	# Não troca de estado.
	# Permanece no último frame da animação.
	pass
