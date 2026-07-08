extends State

func _enter():

	#print("ENTROU NO JUMPSTART")

	play_animation.emit(name, false)

func _animation_finished():

	#print("JUMPSTART TERMINOU")

	transition_to.emit("Jump")
