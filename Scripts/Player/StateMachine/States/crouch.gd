extends State

var waiting_for_animation := false

func _enter() -> void:
	if animated_sprite:
		animated_sprite.play("Crouch")  # Use "Crouch" em vez de name
		waiting_for_animation = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if not waiting_for_animation and Input.is_action_just_released(player_controls.down):
		waiting_for_animation = true
		
		# Desconectar antes de conectar para evitar duplicatas
		if animated_sprite.animation_finished.is_connected(_animation_finished):
			animated_sprite.animation_finished.disconnect(_animation_finished)
		
		animated_sprite.animation_finished.connect(_animation_finished, CONNECT_ONE_SHOT)
		animated_sprite.play("Crouch")

func _animation_finished() -> void:
	waiting_for_animation = false
	transition_to.emit("Idle")

func _exit() -> void:
	# Limpar conexão ao sair do estado
	if animated_sprite and animated_sprite.animation_finished.is_connected(_animation_finished):
		animated_sprite.animation_finished.disconnect(_animation_finished)
