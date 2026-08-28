extends State


@export_group("Voice")

@export var hurt_voices: Array[AudioStream] = []

@export_range(
	0.0,
	1.0,
	0.05
)
var hurt_voice_chance: float = 0.75


var hit_data: HitData

var hitstun_timer: int = 0

var _hurt_animation_finished: bool = false

var _launch_active: bool = false
var _has_left_ground: bool = false


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


	# ==================================================
	# LANÇAMENTO
	# ==================================================

	if not data.launch.is_zero_approx():
		_launch_active = true
		_has_left_ground = false


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

	print(
		"Launch ativo: ",
		_launch_active
	)


func _enter() -> void:
	_hurt_animation_finished = false

	move.emit(
		Vector2.ZERO
	)

	_play_hurt_voice()

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

	# Golpes normais continuam zerando movimento.
	#
	# Golpes com launch precisam preservar
	# a velocidade recebida.
	if not _launch_active:
		move.emit(
			Vector2.ZERO
		)

	else:
		var character := (
			get_parent().get_parent()
			as CharacterBody2D
		)

		# Confirma que realmente saiu do chão
		# antes de considerar uma futura aterrissagem.
		if (
			character != null
			and not character.is_on_floor()
		):
			_has_left_ground = true


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


	# ==================================================
	# ESPERA O PERSONAGEM ATERRISSAR
	# ==================================================

	if _launch_active:
		var character := (
			get_parent().get_parent()
			as CharacterBody2D
		)

		if character == null:
			return

		# Ainda não saiu realmente do chão.
		if not _has_left_ground:
			return

		# Saiu do chão, mas ainda está no ar.
		if not character.is_on_floor():
			return

		_launch_active = false
		_has_left_ground = false


	transition_to.emit(
		&"Idle"
	)


func _play_hurt_voice() -> void:

	if hurt_voices.is_empty():
		return

	if randf() > hurt_voice_chance:
		return

	var character := (
		get_parent().get_parent()
		as CharacterBody2D
	)

	if character == null:
		return

	if character.has_method(
		"play_random_voice"
	):
		character.call(
			"play_random_voice",
			hurt_voices,
			false
		)


func _exit() -> void:
	_launch_active = false
	_has_left_ground = false
