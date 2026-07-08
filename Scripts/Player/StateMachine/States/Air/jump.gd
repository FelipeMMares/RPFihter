extends State

var left_ground := false

func _enter():

	left_ground = false

	# Aplica o impulso
	jump.emit()

	# Toca a animação de pulo
	play_animation.emit(name, false)

func _physics_process(delta):

	check_special_move()

	var player = get_parent().get_parent()

	# Movimento horizontal no ar
	if player_controls.is_walking():

		var direction = Input.get_axis(
			player_controls.left,
			player_controls.right
		)

		move.emit(Vector2(direction,0))

	# Detecta quando realmente saiu do chão
	if !player.is_on_floor():
		left_ground = true

	# Quando pousar, volta para Idle
	if left_ground and player.is_on_floor():
		transition_to.emit("Idle")
