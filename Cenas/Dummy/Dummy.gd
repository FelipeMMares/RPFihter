extends CharacterBody2D

@onready var state_machine = $StateMachine
@onready var hurt_box = $Hurtbox
@export var speed : float = 150
@onready var health: Health = $Health

func _ready() -> void:
	hurt_box.hurt.connect(_on_hurt)

func _on_hurt(hit_data: HitData) -> void:
	if hit_data == null:
		printerr("Dummy recebeu HitData nulo.")
		return

	health.take_damage(hit_data.damage)

	state_machine.receive_hit(hit_data)

func move(direction: Vector2) -> void:
	velocity.x = direction.x * speed
