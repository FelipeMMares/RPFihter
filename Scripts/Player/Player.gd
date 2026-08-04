extends CharacterBody2D

enum ThrowRole {
	NONE,
	ATTACKER,
	VICTIM
}


var throw_role: int = ThrowRole.NONE

# Esta era a variável que estava faltando.
var _throw_victim_locked_position: Vector2 = Vector2.ZERO


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

signal guard_hits_changed(
	current_hits: int,
	maximum_hits: int
)


@export_group("Defesa")

# Quantos golpes podem ser bloqueados antes
# da defesa quebrar.
@export var maximum_guard_hits: int = 5

# Força aplicada ao atacante quando sofre Parry.
@export var parry_knockback_force: float = 600.0


var blocked_guard_hits: int = 0


var guard_active: bool = false

var _parry_window_end_msec: int = -1
var _guard_release_requested: bool = false

var _pending_parry_recoil_velocity: float = 0.0

@export var body_collision: CollisionShape2D

var pending_grab_target: CharacterBody2D = null
var grab_attempt_active: bool = false
var grab_attempt_started_msec: int = -1

var _resolving_grab_counter: bool = false

# Vítima presa durante o Throw.
var throw_locked: bool = false
var throw_sequence_active: bool = false
var throw_attacker: CharacterBody2D = null
var pending_throw_damage: int = 0

# Atacante parado durante a animação Throw.
var throw_attacker_locked: bool = false
var _throw_attacker_locked_position: Vector2 = Vector2.ZERO


var pending_throw_direction: float = 0.0



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
	_anchor: Node2D = null
) -> bool:
	if throw_role != ThrowRole.NONE:
		return false

	if not can_be_thrown():
		return false

	# Garante que uma defesa anterior não permaneça
	# ativa durante Thrown.
	end_guard()

	throw_role = ThrowRole.VICTIM

	throw_locked = true
	throw_sequence_active = true
	throw_attacker = attacker

	# Guarda exatamente onde a vítima estava.
	_throw_victim_locked_position = global_position

	pending_throw_damage = 0
	velocity = Vector2.ZERO

	if hurt_box != null:
		hurt_box.set_crouching(false)

	_set_body_collision_enabled(false)

	state_machine.force_transition(&"Thrown")

	return true

func update_throw_capture() -> void:
	if not throw_locked:
		return

	velocity = Vector2.ZERO

	# Mantém a vítima exatamente na posição
	# em que foi agarrada.
	global_position = _throw_victim_locked_position

func release_from_throw(
	damage: int,
	launch_velocity: Vector2
) -> void:
	if not throw_sequence_active:
		return

	reset_throw_visual_rotation()

	throw_locked = false

	pending_throw_damage = maxi(
		damage,
		0
	)

	_set_body_collision_enabled(true)

	# O movimento da vítima começa somente aqui.
	velocity = launch_velocity

	state_machine.force_transition(&"HurtFall")


func cancel_throw_capture() -> void:
	reset_throw_visual_rotation()

	throw_locked = false
	throw_sequence_active = false
	throw_attacker = null

	pending_throw_damage = 0
	velocity = Vector2.ZERO

	throw_role = ThrowRole.NONE

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
	throw_attacker = null

	pending_throw_damage = 0

	if throw_role == ThrowRole.VICTIM:
		throw_role = ThrowRole.NONE


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


func queue_throw_direction(direction: float) -> void:
	pending_throw_direction = signf(direction)


func consume_throw_direction() -> float:
	var direction := pending_throw_direction
	pending_throw_direction = 0.0

	return direction

func begin_grab_attempt() -> void:
	grab_attempt_active = true
	grab_attempt_started_msec = Time.get_ticks_msec()


func end_grab_attempt() -> void:
	grab_attempt_active = false
	grab_attempt_started_msec = -1


func cancel_grab_attempt() -> void:
	grab_attempt_active = false
	grab_attempt_started_msec = -1

	pending_grab_target = null
	pending_throw_direction = 0.0

	if (
		throw_role == ThrowRole.ATTACKER
		and not throw_attacker_locked
	):
		throw_role = ThrowRole.NONE


func is_trying_grab() -> bool:
	return grab_attempt_active


func get_grab_attempt_started_msec() -> int:
	return grab_attempt_started_msec


func queue_grab_target(
	target: CharacterBody2D
) -> void:
	pending_grab_target = target


func consume_grab_target() -> CharacterBody2D:
	var target := pending_grab_target
	pending_grab_target = null

	return target

func resolve_grab_counter_with(
	other_character: CharacterBody2D
) -> void:
	if _resolving_grab_counter:
		return

	_resolving_grab_counter = true

	cancel_grab_attempt()
	velocity.x = 0.0

	if (
		is_instance_valid(other_character)
		and other_character.has_method(
			"receive_grab_counter_cancel"
		)
	):
		other_character.call(
			"receive_grab_counter_cancel"
		)

	if state_machine != null:
		state_machine.force_transition(&"Idle")

	_resolving_grab_counter = false


func receive_grab_counter_cancel() -> void:
	cancel_grab_attempt()
	velocity.x = 0.0

	if state_machine != null:
		state_machine.force_transition(&"Idle")

func reserve_as_throw_attacker() -> bool:
	if throw_role != ThrowRole.NONE:
		return false

	if throw_locked or throw_sequence_active:
		return false

	throw_role = ThrowRole.ATTACKER
	return true


func release_throw_attacker_reservation() -> void:
	if throw_role == ThrowRole.ATTACKER:
		throw_role = ThrowRole.NONE


func is_throw_attacker() -> bool:
	return throw_role == ThrowRole.ATTACKER


func is_throw_victim() -> bool:
	return throw_role == ThrowRole.VICTIM

func begin_throw_attacker_lock() -> void:
	throw_attacker_locked = true
	_throw_attacker_locked_position = global_position
	velocity = Vector2.ZERO


func end_throw_attacker_lock() -> void:
	throw_attacker_locked = false
	velocity = Vector2.ZERO

func set_throw_capture_position(
	new_global_position: Vector2
) -> void:
	if not throw_locked:
		return

	_throw_victim_locked_position = new_global_position
	velocity = Vector2.ZERO
	global_position = _throw_victim_locked_position

func begin_guard(
	parry_window_seconds: float
) -> void:
	guard_active = true
	_guard_release_requested = false

	var window_msec: int = roundi(
		maxf(parry_window_seconds, 0.0)
		* 1000.0
	)

	_parry_window_end_msec = (
		Time.get_ticks_msec()
		+ window_msec
	)


func end_guard() -> void:
	guard_active = false
	_parry_window_end_msec = -1


func is_guard_active() -> bool:
	return guard_active


func is_parry_window_active() -> bool:
	if not guard_active:
		return false

	if _parry_window_end_msec < 0:
		return false

	return (
		Time.get_ticks_msec()
		<= _parry_window_end_msec
	)

func receive_combat_hit(
	hit_data: HitData,
	attacker: CharacterBody2D = null
) -> void:
	if (
		state_machine != null
		and state_machine.is_round_result_locked()
	):
		return
	if hit_data == null:
		printerr(name, ": recebeu HitData nulo.")
		return

	if state_machine == null:
		printerr(name, ": StateMachine não encontrada.")
		return

	var current_state: StringName = (
		state_machine.get_current_state_name()
	)

	var is_in_guard_state: bool = (
		current_state == &"Guard"
		or current_state == &"GuardWhile"
	)

	# Defesa e Parry negam completamente o dano,
	# mas somente enquanto guard_active estiver ativo.
	if is_in_guard_state and guard_active:
		if is_parry_window_active():
			_perform_parry(attacker)
		else:
			_block_attack()

		return

	# Fora da defesa, o golpe causa dano normalmente.
	if health != null:
		health.take_damage(
			hit_data.damage
		)
	else:
		printerr(
			name,
			": componente Health não encontrado."
		)

	# Depois de aplicar o dano, entra em Hurt
	# e processa os demais dados do golpe.
	state_machine.receive_hit(hit_data)

func _block_attack() -> void:
	# Os primeiros cinco ataques são bloqueados.
	if blocked_guard_hits < maximum_guard_hits:
		blocked_guard_hits += 1

		guard_hits_changed.emit(
			blocked_guard_hits,
			maximum_guard_hits
		)

		print(
			name,
			" bloqueou | defesa: ",
			blocked_guard_hits,
			"/",
			maximum_guard_hits
		)

		return

	# O próximo ataque excede o limite.
	_break_guard()

func _break_guard() -> void:
	end_guard()

	print(name, " teve a defesa quebrada.")

	state_machine.force_transition(&"Stun")

func reset_guard_durability() -> void:
	blocked_guard_hits = 0

	guard_hits_changed.emit(
		blocked_guard_hits,
		maximum_guard_hits
	)

func _perform_parry(
	attacker: CharacterBody2D
) -> void:
	end_guard()

	print(
		name,
		" realizou Parry em ",
		attacker.name if attacker != null else "null"
	)

	state_machine.force_transition(&"Parry")

	if (
		is_instance_valid(attacker)
		and attacker.has_method(
			"receive_parry_knockback"
		)
	):
		attacker.call(
			"receive_parry_knockback",
			self,
			parry_knockback_force
		)

func receive_parry_knockback(
	defender: CharacterBody2D,
	knockback_force: float
) -> void:
	if defender == null:
		return

	var recoil_direction: float = signf(
		global_position.x
		- defender.global_position.x
	)

	if is_zero_approx(recoil_direction):
		recoil_direction = 1.0

	_pending_parry_recoil_velocity = (
		absf(knockback_force)
		* recoil_direction
	)

	state_machine.force_transition(&"ParryRecoil")


func consume_parry_recoil_velocity() -> float:
	var recoil_velocity := (
		_pending_parry_recoil_velocity
	)

	_pending_parry_recoil_velocity = 0.0

	return recoil_velocity

func request_guard_release() -> void:
	_guard_release_requested = true


func consume_guard_release_request() -> bool:
	var requested := _guard_release_requested

	_guard_release_requested = false

	return requested
