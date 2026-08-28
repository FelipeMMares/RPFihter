extends State


@export_group("Terremoto")

@export var quake_hitbox: Area2D

@export_range(0, 30, 1)
var impact_frame: int = 4


@export_group("Estado")

@export var return_state: StringName = &"Idle"


var _quake_active: bool = false
var _impact_triggered: bool = false


func _enter() -> void:
	_impact_triggered = false

	_set_quake_enabled(false)

	var character := _get_character()

	if character == null:
		transition_to.emit(
			return_state
		)
		return

	# Slide Head não desloca Potemkin.
	character.velocity.x = 0.0

	play_animation.emit(
		&"SlideHead",
		false
	)


func _physics_process(
	_delta: float
) -> void:
	var character := _get_character()

	if character == null:
		return

	character.velocity.x = 0.0

	var state_machine := (
		get_parent() as StateMachine
	)

	if state_machine == null:
		return

	var sprite := (
		state_machine.animated_sprite
	)

	if sprite == null:
		return

	if (
		StringName(sprite.animation)
		!= &"SlideHead"
	):
		return

	var current_frame: int = sprite.frame


	# ==================================================
	# TERREMOTO
	# ==================================================

	var should_be_active: bool = (
		current_frame == impact_frame
	)

	if should_be_active != _quake_active:
		_set_quake_enabled(
			should_be_active
		)


	# Executa efeitos visuais/sonoros
	# uma única vez.
	if (
		current_frame >= impact_frame
		and not _impact_triggered
	):
		_impact_triggered = true

		_on_ground_impact()


func _on_ground_impact() -> void:
	print("POTEMKIN | SLIDE HEAD IMPACT")

	# Depois podemos chamar aqui:
	#
	# câmera tremer
	# poeira
	# partículas
	# som do terremoto


func _animation_finished() -> void:
	_set_quake_enabled(false)

	var character := _get_character()

	if character != null:
		character.velocity.x = 0.0

	transition_to.emit(
		return_state
	)


func _exit() -> void:
	_set_quake_enabled(false)

	var character := _get_character()

	if character != null:
		character.velocity.x = 0.0


func _set_quake_enabled(
	active: bool
) -> void:
	_quake_active = active

	if quake_hitbox == null:
		return

	quake_hitbox.monitoring = active
	quake_hitbox.monitorable = active

	for child in quake_hitbox.get_children():
		if child is CollisionShape2D:
			child.set_deferred(
				"disabled",
				not active
			)


func _get_character() -> CharacterBody2D:
	return (
		get_parent().get_parent()
		as CharacterBody2D
	)
