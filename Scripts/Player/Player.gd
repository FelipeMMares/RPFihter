extends CharacterBody2D

enum ThrowRole {
	NONE,
	ATTACKER,
	VICTIM
}

signal guard_changed(
	current_hits: int,
	max_hits: int
)

signal guard_broken
signal guard_reset

var throw_role: int = ThrowRole.NONE

# Esta era a variável que estava faltando.
var _throw_victim_locked_position: Vector2 = Vector2.ZERO

@export_group("Separação entre lutadores")

# Distância aplicada imediatamente quando
# um personagem está sobre o outro.
@export_range(1.0, 20.0, 1.0)
var stack_separation_distance: float = 5.0

# Velocidade lateral aplicada junto com a separação.
@export var stack_knockback_speed: float = 260.0

# Define o quanto a colisão precisa ser vertical.
# Valores próximos de 1 exigem uma colisão mais
# claramente vinda de cima ou de baixo.
@export_range(0.1, 1.0, 0.05)
var stack_vertical_normal_threshold: float = 0.65

# Evita aplicar a separação muitas vezes seguidas.
@export_range(0.0, 0.5, 0.01)
var stack_push_cooldown: float = 0.06


var _stack_push_cooldown_left: float = 0.0

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

@export_group("Movimento de entrada")

@export var entry_animation_name: StringName = &"Entry"


@onready var entry_animated_sprite: AnimatedSprite2D = (
	$AnimatedSprite2D
)


var _entry_motion_active: bool = false

var _entry_spawn_position: Vector2 = Vector2.ZERO
var _entry_target_position: Vector2 = Vector2.ZERO

var _entry_motion_start_frame: int = 0
var _entry_motion_end_frame: int = 19

@export_group("Defesa")

# Quantos golpes podem ser bloqueados antes
# da defesa quebrar.
@export var maximum_guard_hits: int = 5

# Força aplicada ao atacante quando sofre Parry.
@export var parry_knockback_force: float = 600.0

@export_group("Ataques especiais")

@export_range(0.0, 10.0, 0.1)
var default_special_mp_cost: float = 1.0


@onready var magic_points: MagicPoints = (
	$MagicPoints
)

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
	_stack_push_cooldown_left = maxf(
		_stack_push_cooldown_left - delta,
		0.0
	)

	if throw_attacker_locked:
		velocity = Vector2.ZERO
		global_position = (
			_throw_attacker_locked_position
		)
		return

	if throw_locked:
		velocity = Vector2.ZERO
		global_position = (
			_throw_victim_locked_position
		)
		return

	# Movimento cinematográfico da apresentação.
	if _update_entry_motion():
		return

	if not is_on_floor():
		velocity.y += gravity * delta

	move_and_slide()

	_resolve_fighter_stacking()

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
) -> bool:
	if hit_data == null:
		return false

	if state_machine == null:
		return false

	if state_machine.is_round_result_locked():
		return false

	var current_state: StringName = (
		state_machine.get_current_state_name()
	)

	var is_in_guard_state: bool = (
		current_state == &"Guard"
		or current_state == &"GuardWhile"
	)

	if is_in_guard_state and guard_active:
		if is_parry_window_active():
			_perform_parry(attacker)
		else:
			_block_attack()

		# Bloqueio e Parry não causaram dano.
		return false

	if health == null:
		return false

	health.take_damage(
		hit_data.damage
	)

	state_machine.receive_hit(
		hit_data
	)

	# O golpe realmente causou dano.
	return true

func _block_attack() -> void:
	# Os primeiros cinco ataques são bloqueados.
	if blocked_guard_hits < maximum_guard_hits:
		blocked_guard_hits += 1

		print(
			name,
			" bloqueou | defesa: ",
			blocked_guard_hits,
			"/",
			maximum_guard_hits
		)

		# Avisa a HUD que a defesa avançou.
		guard_changed.emit(
			blocked_guard_hits,
			maximum_guard_hits
		)

		return

	# O próximo ataque excede o limite.
	_break_guard()

func _break_guard() -> void:
	end_guard()

	print(
		name,
		" teve a defesa quebrada."
	)

	# Faz a HUD mostrar o último frame.
	guard_broken.emit()

	state_machine.force_transition(
		&"Stun"
	)

func reset_guard_durability() -> void:
	blocked_guard_hits = 0

	guard_reset.emit()

	guard_changed.emit(
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

func _resolve_fighter_stacking() -> void:
	if _stack_push_cooldown_left > 0.0:
		return

	# Durante o Throw, os personagens podem ficar
	# propositalmente sobrepostos.
	if throw_locked or throw_attacker_locked:
		return

	# Não altera a posição durante Victory,
	# Defeated ou FallDefeated.
	if (
		state_machine != null
		and state_machine.is_round_result_locked()
	):
		return

	for collision_index in range(
		get_slide_collision_count()
	):
		var collision: KinematicCollision2D = (
			get_slide_collision(collision_index)
		)

		if collision == null:
			continue

		var other_character := (
			collision.get_collider()
			as CharacterBody2D
		)

		if other_character == null:
			continue

		if other_character == self:
			continue

		if not other_character.is_in_group(
			&"fighters"
		):
			continue

		var collision_normal: Vector2 = (
			collision.get_normal()
		)

		# Ignora colisões predominantemente laterais.
		# Queremos apenas o caso em que um personagem
		# está sobre o outro.
		if (
			absf(collision_normal.y)
			< stack_vertical_normal_threshold
		):
			continue

		# No Godot, um Y menor significa que o nó
		# está visualmente mais alto.
		var self_is_above: bool = (
			global_position.y
			< other_character.global_position.y
		)

		if not self_is_above:
			continue

		var push_direction: float = signf(
			global_position.x
			- other_character.global_position.x
		)

		# Caso estejam exatamente no mesmo X,
		# escolhe uma direção determinística.
		if is_zero_approx(push_direction):
			push_direction = (
				-1.0
				if get_instance_id()
				< other_character.get_instance_id()
				else 1.0
			)

		_apply_stack_side_push(
			push_direction
		)

		_stack_push_cooldown_left = (
			stack_push_cooldown
		)

		# Uma colisão válida já é suficiente.
		break

func _apply_stack_side_push(
	push_direction: float
) -> void:
	var normalized_direction: float = signf(
		push_direction
	)

	if is_zero_approx(normalized_direction):
		normalized_direction = 1.0

	var separation_motion := Vector2(
		normalized_direction
		* stack_separation_distance,
		0.0
	)

	move_and_collide(
		separation_motion
	)

func reset_for_new_round() -> void:
	velocity = Vector2.ZERO

	end_guard()

	# Reseta a resistência da defesa
	# e também avisa a interface.
	reset_guard_durability()

	throw_locked = false
	throw_attacker_locked = false
	throw_sequence_active = false
	throw_role = ThrowRole.NONE

	if has_method("set_crouching"):
		set_crouching(false)

	var input_buffer := find_child(
		"InputBuffer",
		true,
		false
	) as InputBuffer

	if input_buffer != null:
		input_buffer.clear_buffer()
		

func start_entry_motion(
	spawn_position: Vector2,
	target_position: Vector2,
	start_frame: int = 0,
	end_frame: int = 19
) -> void:
	_entry_spawn_position = spawn_position
	_entry_target_position = target_position

	_entry_motion_start_frame = maxi(
		start_frame,
		0
	)

	_entry_motion_end_frame = maxi(
		end_frame,
		_entry_motion_start_frame + 1
	)

	_entry_motion_active = true

	velocity = Vector2.ZERO
	global_position = _entry_spawn_position

	print(
		"Chun-Li iniciando Entry | início: ",
		_entry_spawn_position,
		" | destino: ",
		_entry_target_position,
		" | frames: ",
		_entry_motion_start_frame,
		"-",
		_entry_motion_end_frame
	)

func _update_entry_motion() -> bool:
	if not _entry_motion_active:
		return false

	# Enquanto a entrada estiver ativa, nenhum outro
	# movimento ou gravidade deve alterar a posição.
	velocity = Vector2.ZERO

	if entry_animated_sprite == null:
		printerr(
			"Player: AnimatedSprite2D não encontrado para Entry."
		)

		finish_entry_motion()
		return true

	# Aguarda a animação Entry realmente começar.
	if (
		StringName(entry_animated_sprite.animation)
		!= entry_animation_name
	):
		global_position = _entry_spawn_position
		return true

	var current_animation_frame: int = (
		entry_animated_sprite.frame
	)

	var total_movement_frames: int = maxi(
		_entry_motion_end_frame
		- _entry_motion_start_frame,
		1
	)

	var entry_progress: float = clampf(
		float(
			current_animation_frame
			- _entry_motion_start_frame
		)
		/ float(total_movement_frames),
		0.0,
		1.0
	)

	# Interpola tanto X quanto Y. Como os marcadores
	# normalmente terão o mesmo Y, o movimento será lateral.
	global_position = _entry_spawn_position.lerp(
		_entry_target_position,
		entry_progress
	)

	if current_animation_frame >= _entry_motion_end_frame:
		finish_entry_motion()

	return true

func finish_entry_motion() -> void:
	if not _entry_motion_active:
		return

	_entry_motion_active = false

	global_position = _entry_target_position
	velocity = Vector2.ZERO

	print(
		"Chun-Li terminou Entry em: ",
		global_position
	)

func request_special_attack(
	special_state: StringName,
	cost: float = -1.0
) -> bool:
	if state_machine == null:
		return false

	if state_machine.is_round_result_locked():
		return false

	if not state_machine.has_state(
		special_state
	):
		printerr(
			name,
			": estado especial não encontrado: ",
			special_state
		)
		return false

	if magic_points == null:
		printerr(
			name,
			": componente MagicPoints não encontrado."
		)
		return false

	var final_cost: float = cost

	if final_cost < 0.0:
		final_cost = default_special_mp_cost

	if not magic_points.try_spend(
		final_cost
	):
		print(
			name,
			": MP insuficiente para ",
			special_state,
			" | MP atual: ",
			magic_points.current_mp,
			" | custo: ",
			final_cost
		)

		return false

	state_machine.force_transition(
		special_state
	)

	print(
		name,
		" executou ",
		special_state,
		" | MP restante: ",
		magic_points.current_mp
	)

	return true


func gain_mp_from_successful_hit(
	multiplier: float = 1.0
) -> void:
	if magic_points == null:
		return

	magic_points.gain_from_successful_hit(
		multiplier
	)


func set_mp_regeneration_enabled(
	enabled: bool
) -> void:
	if magic_points != null:
		magic_points.set_regeneration_enabled(
			enabled
		)


func reset_mp() -> void:
	if magic_points != null:
		magic_points.reset_mp()
