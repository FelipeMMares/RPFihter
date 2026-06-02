extends CharacterBody2D

@export var speed : float = 150

func move(direction: Vector2) -> void:
	
	velocity = direction * speed
	move_and_slide()
	
