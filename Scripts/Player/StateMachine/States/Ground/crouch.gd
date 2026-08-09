extends State


@export var crouch_while_state: StringName = &"CrouchWhile"
@export var idle_state: StringName = &"Idle"

var _leaving_crouch: bool = false


func _enter() -> void:
	move.emit(Vector2.ZERO)
	if not player_input_enabled:
		return

	if player_controls == null:
		return

	# Se Down ainda está pressionado, o personagem
	# está começando a se agachar.
	if Input.is_action_pressed(player_controls.down):
		_leaving_crouch = false

		set_crouching_hurtbox(true)

		# Reproduz a animação normalmente.
		play_animation.emit(&"Crouch", false)

	# Se Down não está mais pressionado, o personagem
	# está se levantando.
	else:
		_leaving_crouch = true

		# Mantém a HurtBox reduzida enquanto a animação
		# de levantar ainda está acontecendo.
		set_crouching_hurtbox(true)

		# Reproduz a animação Crouch ao contrário.
		play_animation.emit(&"Crouch", true)


func _physics_process(_delta: float) -> void:
	move.emit(Vector2.ZERO)

	if not player_input_enabled:
		return

	if player_controls == null:
		return

func _animation_finished() -> void:
	if _leaving_crouch:
		# Somente após terminar de levantar a HurtBox
		# volta ao tamanho normal.
		set_crouching_hurtbox(false)

		transition_to.emit(idle_state)
	else:
		transition_to.emit(crouch_while_state)
