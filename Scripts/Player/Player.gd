extends CharacterBody2D


@onready var health: Health = $Health
@onready var state_machine: StateMachine = $StateMachine
@onready var hurt_box: HurtBox = $Hurtbox

@onready var animated_sprite: AnimatedSprite2D = (
	$AnimatedSprite2D
)

# Confira se o nome na árvore é realmente "Hitboxers".
# Caso seja "Hitboxes", corrija o caminho.
@onready var light_punch_hitbox: HitBox = (
	$Hitboxers/LightPunch
)

@export var body_collision: CollisionShape2D

var throw_locked: bool = false
var throw_sequence_active: bool = false

var throw_anchor: Node2D
var throw_attacker: CharacterBody2D

var pending_throw_damage: int = 0

@export var speed: float = 150.0
@export var jump_force: float = 700.0
@export var gravity: float = 1200.0


func _physics_process(delta: float) -> void:
	if throw_locked:
		velocity = Vector2.ZERO
		return
	
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

func set_crouching(active: bool) -> void:
	if hurt_box == null:
		printerr(
			name,
			": HurtBox não encontrada."
		)
		return

	hurt_box.set_crouching(active)

func can_be_thrown() -> bool:
	if throw_sequence_active:
		return false

	if not is_on_floor():
		return false

	if hurt_box != null and hurt_box.is_invulnerable():
		return false

	if state_machine == null:
		return false

	return state_machine.can_be_thrown()


func begin_throw_capture(
	attacker: CharacterBody2D,
	anchor: Node2D
) -> bool:
	if not can_be_thrown():
		return false

	if anchor == null:
		return false

	throw_locked = true
	throw_sequence_active = true

	throw_attacker = attacker
	throw_anchor = anchor

	pending_throw_damage = 0
	velocity = Vector2.ZERO

	# Caso tenha sido agarrado agachado.
	if hurt_box != null:
		hurt_box.set_crouching(false)

	_set_body_collision_enabled(false)

	state_machine.force_transition(&"Thrown")

	return true


func update_throw_capture() -> void:
	if not throw_locked:
		return

	if not is_instance_valid(throw_anchor):
		cancel_throw_capture()
		return

	velocity = Vector2.ZERO
	global_position = throw_anchor.global_position


func release_from_throw(
	damage: int,
	launch_velocity: Vector2
) -> void:
	if not throw_sequence_active:
		return

	reset_throw_visual_rotation()

	throw_locked = false
	throw_anchor = null

	pending_throw_damage = maxi(damage, 0)

	_set_body_collision_enabled(true)

	velocity = launch_velocity

	state_machine.force_transition(&"HurtFall")


func cancel_throw_capture() -> void:
	reset_throw_visual_rotation()

	throw_locked = false
	throw_sequence_active = false

	throw_anchor = null
	throw_attacker = null

	pending_throw_damage = 0
	velocity = Vector2.ZERO

	_set_body_collision_enabled(true)

	if state_machine != null:
		state_machine.force_transition(&"Idle")


func apply_pending_throw_damage() -> bool:
	if pending_throw_damage <= 0:
		return health.is_defeated()

	var damage := pending_throw_damage
	pending_throw_damage = 0

	health.take_damage(damage)

	return health.is_defeated()


func finish_throw_sequence() -> void:
	throw_locked = false
	throw_sequence_active = false

	throw_anchor = null
	throw_attacker = null
	pending_throw_damage = 0


func set_throw_invulnerable(active: bool) -> void:
	if hurt_box != null:
		hurt_box.set_invulnerable(active)


func _set_body_collision_enabled(enabled: bool) -> void:
	if body_collision == null:
		return

	body_collision.set_deferred(
		"disabled",
		not enabled
	)

func set_throw_visual_rotation(
	rotation_in_degrees: float
) -> void:
	if animated_sprite == null:
		return

	animated_sprite.rotation_degrees = (
		rotation_in_degrees
	)


func reset_throw_visual_rotation() -> void:
	if animated_sprite == null:
		return

	animated_sprite.rotation_degrees = 0.0
