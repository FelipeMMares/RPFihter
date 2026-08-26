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

@export_group("Anti-Stack dos lutadores")

# Quanto o triângulo passa para fora da caixa
# principal em cada lado.
@export_range(0.0, 100.0, 1.0)
var anti_stack_side_extension: float = 25.0

# Altura do pico do triângulo acima da caixa.
@export_range(1.0, 100.0, 1.0)
var anti_stack_height: float = 45.0

# Velocidade usada para "escorrer" rapidamente
# para o lado quando um lutador fica sobre outro.
@export_range(100.0, 1500.0, 10.0)
var anti_stack_slide_speed: float = 650.0

@onready var hurt_box: HurtBox = $Hurtbox
@onready var state_machine: StateMachine = $StateMachine
@onready var health: Health = $Health

@onready var animated_sprite: AnimatedSprite2D = (
	$AnimatedSprite2D
)

@onready var voice_player: CharacterVoicePlayer = (
	$VoicePlayer
)

@export var speed: float = 150.0
@export var jump_force: float = 700.0
@export var gravity: float = 1200.0

@export var body_collision: CollisionShape2D

@export var anti_stack_collision: CollisionShape2D

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

# Vítima presa durante o Throw.
var throw_locked: bool = false
var throw_sequence_active: bool = false
var throw_attacker: CharacterBody2D = null
var pending_throw_damage: int = 0

# Esta era a variável que estava faltando.
var _throw_victim_locked_position: Vector2 = Vector2.ZERO

# Atacante parado durante a animação Throw.
var throw_attacker_locked: bool = false
var _throw_attacker_locked_position: Vector2 = Vector2.ZERO

# Dados enviados do TryGrab para o Throw.
var pending_grab_target: CharacterBody2D = null
var pending_throw_direction: float = 0.0

var grab_attempt_active: bool = false
var grab_attempt_started_msec: int = -1

var _resolving_grab_counter: bool = false

func _ready() -> void:
	_configure_anti_stack_triangle()

func _physics_process(delta: float) -> void:
	if throw_attacker_locked:
		velocity = Vector2.ZERO
		global_position = _throw_attacker_locked_position
		return

	if throw_locked:
		velocity = Vector2.ZERO
		global_position = _throw_victim_locked_position
		return

	if not is_on_floor():
		velocity.y += gravity * delta

	move_and_slide()

	_resolve_fighter_stacking()

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

	velocity = launch_velocity

	print(
		name,
		" entrou em HurtFall | velocidade: ",
		velocity
	)

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


func _set_body_collision_enabled(
	enabled: bool
) -> void:
	if body_collision != null:
		body_collision.set_deferred(
			"disabled",
			not enabled
		)

	if anti_stack_collision != null:
		anti_stack_collision.set_deferred(
			"disabled",
			not enabled
		)


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

func queue_grab_target(
	target: CharacterBody2D
) -> void:
	pending_grab_target = target


func consume_grab_target() -> CharacterBody2D:
	var target := pending_grab_target
	pending_grab_target = null

	return target

func queue_throw_direction(direction: float) -> void:
	pending_throw_direction = signf(direction)


func consume_throw_direction() -> float:
	var direction := pending_throw_direction
	pending_throw_direction = 0.0

	return direction

func begin_throw_attacker_lock() -> void:
	throw_attacker_locked = true
	_throw_attacker_locked_position = global_position
	velocity = Vector2.ZERO


func end_throw_attacker_lock() -> void:
	throw_attacker_locked = false
	velocity = Vector2.ZERO

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

	# Remove uma reserva incompleta.
	if (
		throw_role == ThrowRole.ATTACKER
		and not throw_attacker_locked
	):
		throw_role = ThrowRole.NONE


func is_trying_grab() -> bool:
	return grab_attempt_active


func get_grab_attempt_started_msec() -> int:
	return grab_attempt_started_msec

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
	if blocked_guard_hits < maximum_guard_hits:
		blocked_guard_hits += 1

		print(
			name,
			" bloqueou | defesa: ",
			blocked_guard_hits,
			"/",
			maximum_guard_hits
		)

		guard_changed.emit(
			blocked_guard_hits,
			maximum_guard_hits
		)

		return

	_break_guard()

func _break_guard() -> void:
	end_guard()

	print(
		name,
		" teve a defesa quebrada."
	)

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
	# Durante Throw é permitido existir
	# sobreposição proposital.
	if throw_locked or throw_attacker_locked:
		return

	if (
		state_machine != null
		and state_machine.is_round_result_locked()
	):
		return

	for collision_index in range(
		get_slide_collision_count()
	):
		var collision: KinematicCollision2D = (
			get_slide_collision(
				collision_index
			)
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

		# Só empurramos quem está POR CIMA.
		var self_is_above: bool = (
			global_position.y
			< other_character.global_position.y
		)

		if not self_is_above:
			continue

		var collision_normal: Vector2 = (
			collision.get_normal()
		)

		var slide_direction: float = 0.0

		# Primeiro tenta aproveitar a própria
		# inclinação do triângulo.
		if absf(collision_normal.x) > 0.05:
			slide_direction = signf(
				collision_normal.x
			)

		# Caso esteja exatamente sobre o pico
		# do triângulo, usamos a posição relativa.
		if is_zero_approx(slide_direction):
			slide_direction = signf(
				global_position.x
				- other_character.global_position.x
			)

		# Caso estejam perfeitamente alinhados,
		# escolhe um lado determinístico.
		if is_zero_approx(slide_direction):
			slide_direction = (
				-1.0
				if get_instance_id()
				< other_character.get_instance_id()
				else 1.0
			)

		_slide_off_character(
			slide_direction
		)

		break

func _slide_off_character(
	direction: float
) -> void:
	var slide_direction := signf(
		direction
	)

	if is_zero_approx(slide_direction):
		slide_direction = 1.0

	var delta := get_physics_process_delta_time()

	# Movimento lateral imediato.
	var slide_motion := Vector2(
		slide_direction
		* anti_stack_slide_speed
		* delta,
		0.0
	)

	move_and_collide(
		slide_motion
	)

	# Também mantém velocidade lateral alta,
	# para o movimento não parecer um teleporte.
	velocity.x = (
		slide_direction
		* anti_stack_slide_speed
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

func play_voice(
	voice: AudioStream,
	interrupt_current: bool = true
) -> void:
	if voice_player == null:
		return

	voice_player.play_voice(
		voice,
		interrupt_current
	)


func play_random_voice(
	voices: Array[AudioStream],
	interrupt_current: bool = true
) -> void:
	if voice_player == null:
		return

	voice_player.play_random_voice(
		voices,
		interrupt_current
	)


func stop_voice() -> void:
	if voice_player == null:
		return

	voice_player.stop_voice()

func _configure_anti_stack_triangle() -> void:
	if anti_stack_collision == null:
		printerr(
			name,
			": AntiStackCollision não configurado."
		)
		return

	if body_collision == null:
		printerr(
			name,
			": Body Collision não configurado."
		)
		return

	var rectangle := (
		body_collision.shape
		as RectangleShape2D
	)

	if rectangle == null:
		printerr(
			name,
			": o CollisionShape2D principal precisa usar RectangleShape2D."
		)
		return

	var half_width: float = (
		rectangle.size.x * 0.5
	)

	var half_height: float = (
		rectangle.size.y * 0.5
	)

	# As pontas inferiores ficam PARA FORA
	# da caixa principal.
	var triangle_half_width: float = (
		half_width
		+ anti_stack_side_extension
	)

	var triangle := ConvexPolygonShape2D.new()

	triangle.points = PackedVector2Array([
		# Canto esquerdo.
		Vector2(
			-triangle_half_width,
			0.0
		),

		# Canto direito.
		Vector2(
			triangle_half_width,
			0.0
		),

		# Pico acima da cabeça.
		Vector2(
			0.0,
			-anti_stack_height
		)
	])

	anti_stack_collision.shape = triangle

	# Coloca a base do triângulo exatamente
	# na parte superior da caixa principal.
	anti_stack_collision.position = Vector2(
		body_collision.position.x,
		body_collision.position.y - half_height
	)

func try_parry_grab(
	attacker: CharacterBody2D
) -> bool:
	if state_machine == null:
		return false

	var current_state: StringName = (
		state_machine.get_current_state_name()
	)

	var is_defending: bool = (
		current_state == &"Guard"
		or current_state == &"GuardWhile"
	)

	if not is_defending:
		return false

	if not guard_active:
		return false

	if not is_parry_window_active():
		return false

	print(
		name,
		" realizou Parry contra Grab de ",
		attacker.name if attacker != null else "null"
	)

	# Cancela explicitamente a tentativa antes
	# de aplicar a reação de Parry.
	if (
		is_instance_valid(attacker)
		and attacker.has_method(
			"cancel_grab_attempt"
		)
	):
		attacker.call(
			"cancel_grab_attempt"
		)

	# Reutiliza exatamente o Parry que já existe
	# contra ataques normais.
	_perform_parry(attacker)

	return true
