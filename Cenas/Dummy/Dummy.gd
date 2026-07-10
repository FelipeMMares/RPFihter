extends CharacterBody2D

@onready var state_machine = $StateMachine
@onready var hurt_box = $Hurtbox
@export var speed : float = 150

func _ready() -> void:
	hurt_box.hurt.connect(_on_hurt)

func _on_hurt(hit_data: HitData) -> void:
	state_machine.receive_hit(hit_data)

func move(direction: Vector2) -> void:
	velocity.x = direction.x * speed
