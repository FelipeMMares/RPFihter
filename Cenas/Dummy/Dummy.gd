extends CharacterBody2D

@onready var hurt_box: HurtBox = $Hurtbox

@export var speed: float = 150.0
@export var jump_force: float = 700.0
@export var gravity: float = 1200.0


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

	move_and_slide()


func move(direction: Vector2) -> void:
	# Altera apenas o movimento horizontal.
	# Não apaga a velocidade vertical do salto.
	velocity.x = direction.x * speed


func stop() -> void:
	# Também interrompe apenas o movimento horizontal.
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

func set_crouching(active: bool) -> void:
	if hurt_box == null:
		printerr(
			name,
			": HurtBox não encontrada."
		)
		return

	hurt_box.set_crouching(active)
