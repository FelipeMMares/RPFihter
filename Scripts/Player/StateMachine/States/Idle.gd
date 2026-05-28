extends State


func _enter():
	# Toca a animação idle diretamente no AnimatedSprite2D
	if animated_sprite:
		animated_sprite.play("Idle")
		print("Idle animation started")
	else:
		print("Erro: animated_sprite é null em Idle")
	if character:
		character.velocity.x = 0
		
func _physics_process(delta: float) -> void:
	
	if player_controls.is_walking():
		transition_to.emit("Walk")

func _exit():
	# Opcional: fazer algo ao sair do estado
	pass
