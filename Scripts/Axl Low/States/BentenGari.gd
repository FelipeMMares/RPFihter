extends State

@export_group("Voice")

@export var special_voices: Array[AudioStream] = []


@export_group("Animação")

@export var animation_name: StringName = &"BentenGari"


@export_group("Hitbox")

@export var hitbox: Area2D

@export_range(0, 60, 1)
var active_start_frame: int = 4

@export_range(0, 60, 1)
var active_end_frame: int = 10


@export_group("Efeito opcional")

@export var effect_sprite: AnimatedSprite2D

@export var effect_animation_name: StringName = &"BentenGari"

@export_range(0, 60, 1)
var effect_start_frame: int = 3

@export_range(0, 60, 1)
var effect_end_frame: int = 11

@export var sync_effect_to_body_frame: bool = true


@export_group("Estado")

@export var return_state: StringName = &"Idle"


var _hitbox_active: bool = false
var _direction: float = 1.0
var _effect_original_position: Vector2 = Vector2.ZERO


func _enter() -> void:
	_set_hitbox_enabled(false)

	var character := _get_character()

	if character == null:
		transition_to.emit(return_state)
		return

	_direction = _get_facing_direction()

	character.velocity.x = 0.0

	_prepare_effect()

	_play_special_voice(character)

	play_animation.emit(
		String(animation_name),
		false
	)


func _physics_process(
	_delta: float
) -> void:
	var character := _get_character()

	if character == null:
		return

	# Benten Gari fica parado no eixo X.
	character.velocity.x = 0.0

	var state_machine := (
		get_parent() as StateMachine
	)

	if state_machine == null:
		return

	var sprite := state_machine.animated_sprite

	if sprite == null:
		return

	if (
		StringName(sprite.animation)
		!= animation_name
	):
		return

	var current_frame: int = sprite.frame

	var should_be_active := (
		current_frame >= active_start_frame
		and current_frame <= active_end_frame
	)

	if should_be_active != _hitbox_active:
		_set_hitbox_enabled(
			should_be_active
		)

	_update_effect(
		current_frame
	)


func _animation_finished() -> void:
	_set_hitbox_enabled(false)
	_hide_effect()

	var character := _get_character()

	if character != null:
		character.velocity.x = 0.0

	transition_to.emit(
		return_state
	)


func _exit() -> void:
	_set_hitbox_enabled(false)
	_hide_effect()

	var character := _get_character()

	if character != null:
		character.velocity.x = 0.0


func _prepare_effect() -> void:
	if effect_sprite == null:
		return

	_effect_original_position = (
		effect_sprite.position
	)

	effect_sprite.visible = false
	effect_sprite.stop()

	# Mantém o efeito coerente com o lado para o qual
	# o Axl está olhando.
	effect_sprite.flip_h = (
		_direction < 0.0
	)

	effect_sprite.position.x = (
		absf(_effect_original_position.x)
		* _direction
	)


func _update_effect(
	body_frame: int
) -> void:
	if effect_sprite == null:
		return

	if (
		body_frame < effect_start_frame
		or body_frame > effect_end_frame
	):
		effect_sprite.visible = false
		return

	if effect_sprite.sprite_frames == null:
		return

	if not effect_sprite.sprite_frames.has_animation(
		effect_animation_name
	):
		return

	effect_sprite.visible = true

	if not sync_effect_to_body_frame:
		if (
			StringName(effect_sprite.animation)
			!= effect_animation_name
			or not effect_sprite.is_playing()
		):
			effect_sprite.play(
				effect_animation_name
			)
		return

	# Sincroniza o frame do efeito com o frame corporal.
	effect_sprite.animation = (
		effect_animation_name
	)

	var effect_frame_count := (
		effect_sprite.sprite_frames.get_frame_count(
			effect_animation_name
		)
	)

	if effect_frame_count <= 0:
		return

	var effect_frame := clampi(
		body_frame - effect_start_frame,
		0,
		effect_frame_count - 1
	)

	effect_sprite.frame = effect_frame


func _hide_effect() -> void:
	if effect_sprite == null:
		return

	effect_sprite.stop()
	effect_sprite.visible = false

	# Evita acumular espelhamentos/deslocamentos
	# entre execuções.
	effect_sprite.position = (
		_effect_original_position
	)


func _set_hitbox_enabled(
	active: bool
) -> void:
	_hitbox_active = active

	if hitbox == null:
		return

	# Usa a API do HitBox atual do projeto quando disponível.
	if active:
		if hitbox.has_method("enable"):
			hitbox.call("enable")
		else:
			hitbox.set_deferred(
				"monitoring",
				true
			)
	else:
		if hitbox.has_method("disable"):
			hitbox.call("disable")
		else:
			hitbox.set_deferred(
				"monitoring",
				false
			)


func _get_facing_direction() -> float:
	var character := _get_character()

	if character == null:
		return 1.0

	var facing_controller := (
		character.get_node_or_null(
			"FacingController"
		) as FacingController
	)

	if facing_controller != null:
		if facing_controller.is_facing_right():
			return 1.0

		return -1.0

	# Fallback.
	var state_machine := (
		get_parent() as StateMachine
	)

	if (
		state_machine != null
		and state_machine.animated_sprite != null
		and state_machine.animated_sprite.flip_h
	):
		return -1.0

	return 1.0


func _get_character() -> CharacterBody2D:
	return (
		get_parent().get_parent()
		as CharacterBody2D
	)


func _play_special_voice(
	character: CharacterBody2D
) -> void:
	if special_voices.is_empty():
		return

	if character == null:
		return

	if character.has_method(
		"play_random_voice"
	):
		character.call(
			"play_random_voice",
			special_voices,
			true
		)
