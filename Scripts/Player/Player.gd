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


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

	move_and_slide()


func move(direction: Vector2) -> void:
	# Nunca altere velocity.y aqui.
	velocity.x = direction.x * speed


func stop() -> void:
	# Nunca use velocity = Vector2.ZERO.
	velocity.x = 0.0


func jump() -> void:
	print(
		name,
		" tentou pular | chão: ",
		is_on_floor(),
		" | velocidade antes: ",
		velocity
	)

	if not is_on_floor():
		return

	velocity.y = -jump_force

	print(
		name,
		" pulou | velocidade depois: ",
		velocity
	)
