extends CharacterBody2D


@onready var health: Health = $Health
@onready var state_machine: StateMachine = $StateMachine


# Confira se o nome na árvore é realmente "Hitboxers".
# Caso seja "Hitboxes", corrija o caminho.
@onready var light_punch_hitbox: HitBox = (
	$Hitboxers/LightPunch
)

@export var speed: float = 150.0
@export var jump_force: float = 700.0
@export var gravity: float = 1200.0


func _ready() -> void:
	if health == null:
		printerr("Player: componente Health não encontrado.")
		return

	if state_machine == null:
		printerr("Player: StateMachine não encontrada.")
		return



func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

	move_and_slide()


func jump() -> void:
	if is_on_floor():
		velocity.y = -jump_force


func move(direction: Vector2) -> void:
	velocity.x = direction.x * speed


func stop() -> void:
	velocity.x = 0.0
