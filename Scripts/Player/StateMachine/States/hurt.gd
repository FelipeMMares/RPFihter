extends State


var hit_data: HitData

var hitstun_timer: int = 0

var _hurt_animation_finished: bool = false


func set_hit_data(
	data: HitData
) -> void:
	if data == null:
		return

	hit_data = data

	# Um segundo golpe não deve diminuir
	# o hitstun que ainda resta.
	hitstun_timer = maxi(
		hitstun_timer,
		data.hitstun
	)

	print(
		"Hurt recebeu HitData"
	)

	print(
		"Animação solicitada: ",
		data.hurt_animation
	)

	print(
		"Hitstun: ",
		data.hitstun
	)


func _enter() -> void:
	_hurt_animation_finished = false

	move.emit(
		Vector2.ZERO
	)

	print(
		"ENTROU NO ESTADO HURT"
	)

	if hit_data == null:
		printerr(
			"Hurt: hit_data está null"
		)

		play_animation.emit(
			name,
			false
		)

		return

	print(
		"Tocando animação Hurt: ",
		hit_data.hurt_animation
	)

	play_animation.emit(
		String(hit_data.hurt_animation),
		false
	)


func _physics_process(
	_delta: float
) -> void:
	move.emit(
		Vector2.ZERO
	)

	if hitstun_timer > 0:
		hitstun_timer -= 1

	_try_finish_hurt()


func _animation_finished() -> void:
	_hurt_animation_finished = true

	_try_finish_hurt()


func _try_finish_hurt() -> void:
	if not _hurt_animation_finished:
		return

	if hitstun_timer > 0:
		return

	transition_to.emit(
		&"Idle"
	)
