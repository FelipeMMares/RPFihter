extends CharacterBody2D

@onready var state_machine : StateMachine = $StateMachine
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	# Registra o sprite em um grupo para fácil acesso
	animated_sprite.add_to_group("Idle")
	
	# Inicia a máquina de estados
	state_machine.start()
	
