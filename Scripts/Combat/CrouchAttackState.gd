extends AttackState
class_name CrouchAttackState


@export var crouch_return_state: String = "CrouchWhile"


func _enter() -> void:
	# Garante que a HurtBox continue reduzida
	# durante todo o ataque.
	set_crouching_hurtbox(true)

	# O personagem não anda durante o ataque.
	move.emit(Vector2.ZERO)

	# Ao terminar a animação, AttackState fará
	# a transição para este estado.
	next_state = crouch_return_state

	super._enter()
