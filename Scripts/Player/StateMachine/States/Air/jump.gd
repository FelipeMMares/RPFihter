extends State


@export var landing_state: StringName = &"Idle"


func _enter() -> void:
	play_animation.emit("Jump", false)


func _physics_process(_delta: float) -> void:
	var character := get_parent().get_parent() as CharacterBody2D

	if character == null:
		return

	# Somente o Player lê teclado/controle durante o pulo.
	if player_controls != null:
		_process_player_air_movement()

	# O Dummy não possui player_controls.
	# Ele simplesmente mantém o movimento já aplicado pela IA.

	if character.is_on_floor() and character.velocity.y >= 0.0:
		transition_to.emit(landing_state)


func _process_player_air_movement() -> void:
	if not player_controls.is_walking():
		return

	var direction: float = Input.get_axis(
		player_controls.left,
		player_controls.right
	)

	move.emit(Vector2(direction, 0.0))
