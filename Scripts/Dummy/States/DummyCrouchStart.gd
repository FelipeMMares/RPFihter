extends State


@export var crouch_state: StringName = &"CrouchWhile"
@export var cancel_state: StringName = &"Idle"


func _enter() -> void:
	move.emit(
		Vector2.ZERO
	)

	# Não ativa ainda a HurtBox agachada.
	# O agachamento só será confirmado
	# no final da animação.
	set_crouching_hurtbox(
		false
	)

	play_animation.emit(
		&"CrouchStart",
		false
	)


func _physics_process(
	_delta: float
) -> void:
	move.emit(
		Vector2.ZERO
	)

	# CPU não usa Input diretamente.
	if not player_input_enabled:
		return

	if player_controls == null:
		return

	# Enquanto CrouchStart acontece,
	# ainda podemos completar um especial.
	if check_special_move():
		return


func _animation_finished() -> void:
	# CPU não precisa fisicamente segurar ↓.
	# Quando a IA pede CrouchStart, ela quer
	# realmente entrar em CrouchWhile.
	if not player_input_enabled:
		transition_to.emit(
			crouch_state
		)
		return

	if player_controls == null:
		transition_to.emit(
			cancel_state
		)
		return

	# Só confirma o agachamento se ↓
	# continuou pressionado durante toda
	# a animação CrouchStart.
	if player_controls.is_crouch_held():
		transition_to.emit(
			crouch_state
		)
		return

	# Foi apenas um toque em ↓.
	set_crouching_hurtbox(
		false
	)

	transition_to.emit(
		cancel_state
	)
