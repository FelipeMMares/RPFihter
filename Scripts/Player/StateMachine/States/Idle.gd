extends State


func _enter():
	# Toca a animação idle diretamente no AnimatedSprite2D
	if animated_sprite:
		animated_sprite.play("Idle")
		print("Idle animation started")
	else:
		print("Erro: animated_sprite é null em Idle")

func _exit():
	# Opcional: fazer algo ao sair do estado
	pass
