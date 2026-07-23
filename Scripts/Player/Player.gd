extends CharacterBody2D

@export var speed : float = 150
@export var jump_force : float = 700.0
@export var gravity : float = 1200.0
@onready var light_punch_hitbox: HitBox = $Hitboxers/LightPunch

func _physics_process(delta):

	if not is_on_floor():
		velocity.y += gravity * delta

	move_and_slide()

func jump():
	#print("PLAYER PULOU")
	
	if is_on_floor():
		velocity.y = -jump_force

func move(direction: Vector2) -> void:
	
	velocity.x = direction.x * speed

func stop():

	velocity.x = 0
