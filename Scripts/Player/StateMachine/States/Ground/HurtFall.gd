extends State

@export_group("Voice")

@export var voices: Array[AudioStream] = []

@export var fall_state: StringName = &"Fall"

var _has_left_ground: bool = false


func _enter() -> void:
	_has_left_ground = false

	play_animation.emit(&"HurtFall", false)

	_play_result_voice()

func _physics_process(_delta: float) -> void:
	var character := _get_character()

	if character == null:
		return

	if not character.is_on_floor():
		_has_left_ground = true

	if (
		_has_left_ground
		and character.is_on_floor()
		and character.velocity.y >= 0.0
	):
		character.velocity = Vector2.ZERO

		var defeated := bool(
			character.call(
				"apply_pending_throw_damage"
			)
		)

		# Se o dano derrotou o personagem,
		# o FightManager tratará FallDefeated.
		if defeated:
			return

		transition_to.emit(fall_state)


# A animação pode acabar antes de tocar no chão.
# Permanece no último frame até aterrissar.
func _animation_finished() -> void:
	pass


func _get_character() -> CharacterBody2D:
	return get_parent().get_parent() as CharacterBody2D

func _play_result_voice() -> void:
	if voices.is_empty():
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
			voices,
			true
		)
