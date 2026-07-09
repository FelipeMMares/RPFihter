extends State
class_name AttackState

@export var next_state := "Idle"

func _enter():

	play_animation.emit(name, false)

func _physics_process(delta):

	check_special_move()
	move.emit(Vector2.ZERO)
	# opcional:
	# permitir virar para o lado durante o ataque

func _animation_finished():

	transition_to.emit(next_state)
