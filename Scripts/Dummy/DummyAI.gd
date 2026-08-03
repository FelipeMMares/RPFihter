extends Node
class_name DummyAI


enum AIAction {
	NONE,
	APPROACH,
	RETREAT,
	WAIT,
	CROUCH
}


@export_group("Referências")
@export var state_machine: StateMachine
@export var target: CharacterBody2D
@export var active: bool = true


@export_group("Estados")
@export var idle_state: StringName = &"Idle"
@export var walk_state: StringName = &"Walk"
@export var jump_state: StringName = &"StartJump"
@export_group("Estados de agachamento")
@export var crouch_start_state: StringName = &"CrouchStart"
@export var crouch_while_state: StringName = &"CrouchWhile"
@export var crouch_end_state: StringName = &"CrouchEnd"

@export_group("Duração do agachamento")

# Este tempo começa somente depois que a animação
# CrouchStart terminar e CrouchWhile começar.
@export var minimum_crouch_duration: float = 0.40
@export var maximum_crouch_duration: float = 1.40

@export var attack_states: Array[StringName] = [
	&"LightPunch",
	&"HighPunch",
	&"Kick",
	&"LowKick"
]

@export_group("Ataques agachados")

@export var crouch_attack_states: Array[StringName] = [
	&"CrouchLightPunch",
	&"CrouchHighPunch",
	&"CrouchKick",
	&"CrouchLowKick"
]

@export_range(0.0, 1.0, 0.05)
var crouch_attack_chance: float = 0.65

@export var crouch_attack_delay_min: float = 0.25
@export var crouch_attack_delay_max: float = 0.75

@export_group("Salto")

@export_range(0.0, 1.0, 0.05)
var diagonal_jump_chance: float = 0.75

@export_range(0.0, 1.0, 0.05)
var jump_toward_target_chance: float = 0.75

@export_group("Ataques aéreos")

# Estado em que o personagem já está no ar.
# Não é StartJump.
@export var airborne_state: StringName = &"Jump"

@export var air_attack_states: Array[StringName] = [
	&"AirLightPunch",
	&"AirHighPunch",
	&"AirKick",
	&"AirLowKick"
]

@export_range(0.0, 1.0, 0.05)
var air_attack_chance: float = 0.65

@export var air_attack_delay_min: float = 0.10
@export var air_attack_delay_max: float = 0.40

@export_group("Agarrão")

@export var try_grab_state: StringName = &"TryGrab"
@export var throw_range: float = 12.0
@export var close_throw_weight: int = 15

@export_group("Distância")
@export var attack_range: float = 25.0


@export_group("Duração das ações")
@export var minimum_approach_duration: float = 0.20
@export var maximum_approach_duration: float = 0.60

@export var minimum_retreat_duration: float = 0.25
@export var maximum_retreat_duration: float = 0.70

@export var minimum_wait_duration: float = 0.20
@export var maximum_wait_duration: float = 0.80

@export var minimum_decision_delay: float = 0.10
@export var maximum_decision_delay: float = 0.30


@export_group("Pesos quando está perto")
@export var close_attack_weight: int = 55
@export var close_retreat_weight: int = 20
@export var close_jump_weight: int = 10
@export var close_wait_weight: int = 15
@export var close_crouch_weight: int = 15


@export_group("Pesos quando está longe")
@export var far_approach_weight: int = 65
@export var far_retreat_weight: int = 5
@export var far_jump_weight: int = 10
@export var far_wait_weight: int = 20
@export var far_crouch_weight: int = 10


@onready var character: CharacterBody2D = (
	get_parent() as CharacterBody2D
)


var _rng := RandomNumberGenerator.new()

var _current_action: int = AIAction.NONE
var _action_time_left: float = 0.0
var _decision_delay: float = 0.0

var _character_body_shape: CollisionShape2D
var _target_body_shape: CollisionShape2D

var _crouch_hold_started: bool = false
var _crouch_release_requested: bool = false

var _crouch_attack_timer: float = 0.0
var _crouch_attack_attempted: bool = false

var _air_attack_timer: float = 0.0
var _air_attack_attempted: bool = false

func _ready() -> void:
	_rng.randomize()

	if character == null:
		printerr(
			"DummyAI: o nó pai não é um CharacterBody2D."
		)
		set_physics_process(false)
		return

	_character_body_shape = _find_body_collision(
		character
	)

	if target != null:
		_target_body_shape = _find_body_collision(
			target
		)


func setup(new_target: CharacterBody2D) -> void:
	target = new_target

	if target == null:
		printerr("DummyAI: alvo recebido é nulo.")
		return

	_target_body_shape = _find_body_collision(target)

	print(
		"DummyAI configurada | alvo: ",
		target.name
	)


func _physics_process(delta: float) -> void:
	if not active:
		return
	
	if character == null:
		return

	if target == null:
		return

	if state_machine == null:
		return

	if _decision_delay > 0.0:
		_decision_delay = maxf(
			_decision_delay - delta,
			0.0
		)

	var current_state: StringName = (
		state_machine.get_current_state_name()
	)
	# Durante toda a sequência de agarrão, a StateMachine
# e a física do Dummy controlam o personagem.
#
# Principalmente em HurtFall, não podemos chamar
# _stop_character(), pois isso apagaria velocity.x.
	if current_state == &"Thrown":
		return

	if current_state == &"HurtFall":
		return

	if current_state == &"Fall":
		_stop_character()
		return

	if current_state == &"GetUp":
		_stop_character()
		return

	if _current_action == AIAction.CROUCH:
		_process_crouch_action(
			delta,
			current_state
		)
		return

	# Enquanto está no estado Jump, pode decidir
	# realizar um ataque aéreo.
	if current_state == airborne_state:
		_process_air_attack(delta)
		return

	# Durante um ataque aéreo, a própria State controla
	# o retorno para Idle ao tocar no chão.
	if _is_air_attack_state(current_state):
		return

	# Depois vêm as verificações gerais de ataques,
	# Hurt, Jump e outros estados.
	# Durante ataques, Hurt, pulo e outras animações,
	# não toma uma nova decisão.
	if (
		current_state != idle_state
		and current_state != walk_state
	):
		_stop_character()
		return

	if _action_time_left > 0.0:
		_action_time_left -= delta
		_process_current_action()

		if _action_time_left <= 0.0:
			_finish_current_action()

		return

	if _decision_delay > 0.0:
		_ensure_idle()
		_stop_character()
		return



	_choose_next_action()


func _choose_next_action() -> void:
	var distance: float = (
		_get_horizontal_attack_distance()
	)

	if distance <= attack_range:
		_choose_close_action()
	else:
		_choose_far_action()


func _choose_close_action() -> void:
	var weights: Array[int] = [
		close_attack_weight,
		close_throw_weight,
		close_retreat_weight,
		close_jump_weight,
		close_crouch_weight,
		close_wait_weight
	]

	var selected_action: int = _weighted_index(weights)

	match selected_action:
		0:
			_perform_random_attack()

		1:
			_perform_throw()

		2:
			_start_retreat()

		3:
			_perform_jump()

		4:
			_start_crouch()

		5:
			_start_wait()


func _choose_far_action() -> void:
	var weights: Array[int] = [
		far_approach_weight,
		far_retreat_weight,
		far_jump_weight,
		far_crouch_weight,
		far_wait_weight
	]

	var selected_action: int = _weighted_index(weights)

	match selected_action:
		0:
			_start_approach()

		1:
			_start_retreat()

		2:
			_perform_jump()

		3:
			_start_crouch()

		4:
			_start_wait()


func _weighted_index(weights: Array[int]) -> int:
	var total_weight: int = 0

	for weight in weights:
		total_weight += maxi(weight, 0)

	if total_weight <= 0:
		return weights.size() - 1

	var roll: int = _rng.randi_range(
		1,
		total_weight
	)

	var accumulated_weight: int = 0

	for index in range(weights.size()):
		accumulated_weight += maxi(
			weights[index],
			0
		)

		if roll <= accumulated_weight:
			return index

	return weights.size() - 1


func _start_approach() -> void:
	_current_action = AIAction.APPROACH

	_action_time_left = _rng.randf_range(
		minimum_approach_duration,
		maximum_approach_duration
	)

	print(
		"DummyAI decidiu avançar por ",
		_action_time_left,
		" segundos."
	)


func _start_retreat() -> void:
	_current_action = AIAction.RETREAT

	_action_time_left = _rng.randf_range(
		minimum_retreat_duration,
		maximum_retreat_duration
	)

	print(
		"DummyAI decidiu recuar por ",
		_action_time_left,
		" segundos."
	)


func _start_wait() -> void:
	_current_action = AIAction.WAIT

	_action_time_left = _rng.randf_range(
		minimum_wait_duration,
		maximum_wait_duration
	)

	_ensure_idle()
	_stop_character()

	print(
		"DummyAI decidiu esperar por ",
		_action_time_left,
		" segundos."
	)


func _process_current_action() -> void:
	var horizontal_difference: float = (
		target.global_position.x
		- character.global_position.x
	)

	match _current_action:
		AIAction.APPROACH:
			if (
				_get_horizontal_attack_distance()
				<= attack_range
			):
				_action_time_left = 0.0
				return

			_ensure_walk()

			_move_character(
				Vector2(
					signf(horizontal_difference),
					0.0
				)
			)

		AIAction.RETREAT:
			_ensure_walk()

			_move_character(
				Vector2(
					-signf(horizontal_difference),
					0.0
				)
			)

		AIAction.WAIT:
			_ensure_idle()
			_stop_character()


func _finish_current_action() -> void:
	_current_action = AIAction.NONE
	_action_time_left = 0.0

	_stop_character()
	_ensure_idle()

	_decision_delay = _rng.randf_range(
		minimum_decision_delay,
		maximum_decision_delay
	)


func _perform_random_attack() -> void:
	var valid_attacks: Array[StringName] = []

	for attack_state in attack_states:
		if state_machine.has_state(attack_state):
			valid_attacks.append(attack_state)
		else:
			printerr(
				"DummyAI: estado de ataque não encontrado: ",
				attack_state
			)

	if valid_attacks.is_empty():
		_start_wait()
		return

	var selected_index: int = _rng.randi_range(
		0,
		valid_attacks.size() - 1
	)

	var selected_attack: StringName = (
		valid_attacks[selected_index]
	)

	_stop_character()

	print(
		"DummyAI escolheu o ataque: ",
		selected_attack
	)

	state_machine.force_transition(
		selected_attack
	)

	_decision_delay = _rng.randf_range(
		minimum_decision_delay,
		maximum_decision_delay
	)


func _perform_jump() -> void:
	if not state_machine.has_state(jump_state):
		printerr(
			"DummyAI: estado de pulo não encontrado: ",
			jump_state
		)

		_start_wait()
		return

	var jump_direction: float = 0.0

	if _rng.randf() <= diagonal_jump_chance:
		var direction_to_target: float = signf(
			target.global_position.x
			- character.global_position.x
		)

		if _rng.randf() <= jump_toward_target_chance:
			# Salta na direção do adversário.
			jump_direction = direction_to_target
		else:
			# Salta para longe do adversário.
			jump_direction = -direction_to_target

	_move_character(
		Vector2(
			jump_direction,
			0.0
		)
	)

	_air_attack_attempted = false

	_air_attack_timer = _rng.randf_range(
		air_attack_delay_min,
		air_attack_delay_max
	)

	print(
		"DummyAI decidiu pular | direção: ",
		jump_direction
	)

	state_machine.force_transition(jump_state)

	_decision_delay = _rng.randf_range(
		minimum_decision_delay,
		maximum_decision_delay
	)


func _move_character(direction: Vector2) -> void:
	state_machine.request_move(direction)


func _stop_character() -> void:
	state_machine.request_move(Vector2.ZERO)


func _ensure_walk() -> void:
	if (
		state_machine.get_current_state_name()
		!= walk_state
	):
		state_machine.force_transition(
			walk_state
		)


func _ensure_idle() -> void:
	if (
		state_machine.get_current_state_name()
		== walk_state
	):
		state_machine.force_transition(
			idle_state
		)


func _find_body_collision(
	body: CharacterBody2D
) -> CollisionShape2D:
	if body == null:
		return null

	for child in body.get_children():
		if child is CollisionShape2D:
			return child as CollisionShape2D

	return null


func _get_horizontal_attack_distance() -> float:
	if character == null or target == null:
		return INF

	var center_distance: float = absf(
		target.global_position.x
		- character.global_position.x
	)

	var character_half_width: float = (
		_get_shape_half_width(
			_character_body_shape
		)
	)

	var target_half_width: float = (
		_get_shape_half_width(
			_target_body_shape
		)
	)

	return maxf(
		center_distance
		- character_half_width
		- target_half_width,
		0.0
	)


func _get_shape_half_width(
	collision_shape: CollisionShape2D
) -> float:
	if collision_shape == null:
		return 0.0

	if collision_shape.shape == null:
		return 0.0

	var scale_x: float = absf(
		collision_shape.global_scale.x
	)

	var shape: Shape2D = collision_shape.shape

	if shape is RectangleShape2D:
		var rectangle := shape as RectangleShape2D

		return (
			rectangle.size.x
			* 0.5
			* scale_x
		)

	if shape is CapsuleShape2D:
		var capsule := shape as CapsuleShape2D

		return capsule.radius * scale_x

	if shape is CircleShape2D:
		var circle := shape as CircleShape2D

		return circle.radius * scale_x

	return 0.0

func _start_crouch() -> void:
	if not state_machine.has_state(crouch_start_state):
		printerr(
			"DummyAI: estado não encontrado: ",
			crouch_start_state
		)
		_start_wait()
		return

	if not state_machine.has_state(crouch_while_state):
		printerr(
			"DummyAI: estado não encontrado: ",
			crouch_while_state
		)
		_start_wait()
		return

	if not state_machine.has_state(crouch_end_state):
		printerr(
			"DummyAI: estado não encontrado: ",
			crouch_end_state
		)
		_start_wait()
		return

	_current_action = AIAction.CROUCH

	# Essa duração será descontada somente quando
	# o Dummy estiver efetivamente em CrouchWhile.
	_action_time_left = _rng.randf_range(
		minimum_crouch_duration,
		maximum_crouch_duration
	)

	_crouch_hold_started = false
	_crouch_release_requested = false

	_crouch_attack_attempted = false

	_crouch_attack_timer = _rng.randf_range(
		crouch_attack_delay_min,
		crouch_attack_delay_max
	)

	_stop_character()

	print(
		"DummyAI decidiu agachar por ",
		_action_time_left,
		" segundos."
	)

	state_machine.force_transition(
		crouch_start_state
	)


func _process_crouch_action(
	delta: float,
	current_state: StringName
) -> void:
	_stop_character()

	# Espera a animação inicial de agachamento terminar.
	if current_state == crouch_start_state:
		return

	# Enquanto estiver executando um ataque agachado,
	# não diminui a duração e não solicita outra transição.
	if _is_crouch_attack_state(current_state):
		return

	if current_state == crouch_while_state:
		if not _crouch_hold_started:
			_crouch_hold_started = true

			print(
				"DummyAI entrou em ",
				crouch_while_state
			)

		# Tenta realizar no máximo um ataque durante
		# esta ação de agachamento.
		if not _crouch_attack_attempted:
			_crouch_attack_timer = maxf(
				_crouch_attack_timer - delta,
				0.0
			)

			if _crouch_attack_timer <= 0.0:
				_crouch_attack_attempted = true

				if (
					_rng.randf()
					<= crouch_attack_chance
				):
					if _start_random_crouch_attack():
						return

		# Usa a variável que já existe no seu script.
		_action_time_left = maxf(
			_action_time_left - delta,
			0.0
		)

		if _action_time_left <= 0.0:
			_release_crouch()

		return

	# Espera a animação de levantar terminar.
	if current_state == crouch_end_state:
		return

	# Após CrouchEnd, o estado deve retornar para Idle.
	if current_state == idle_state:
		_finish_crouch_action()
		return

	# Hurt, derrota, pulo ou qualquer interrupção externa.
	_cancel_crouch_action()


func _is_crouch_attack_state(
	state_name: StringName
) -> bool:
	for attack_state in crouch_attack_states:
		if state_name == attack_state:
			return true

	return false


func _release_crouch() -> void:
	if _crouch_release_requested:
		return

	_crouch_release_requested = true

	_stop_character()

	print(
		"DummyAI decidiu soltar o agachamento."
	)

	state_machine.force_transition(
		crouch_end_state
	)


func _finish_crouch_action() -> void:
	print("DummyAI terminou o agachamento.")

	_current_action = AIAction.NONE
	_action_time_left = 0.0

	_crouch_hold_started = false
	_crouch_release_requested = false

	_crouch_attack_timer = 0.0
	_crouch_attack_attempted = false

	_stop_character()

	_decision_delay = _rng.randf_range(
		minimum_decision_delay,
		maximum_decision_delay
	)


func _cancel_crouch_action() -> void:
	print(
		"DummyAI: agachamento interrompido no estado ",
		state_machine.get_current_state_name()
	)

	_current_action = AIAction.NONE
	_action_time_left = 0.0

	_crouch_hold_started = false
	_crouch_release_requested = false

	_crouch_attack_timer = 0.0
	_crouch_attack_attempted = false

	_stop_character()

	# Evita que a IA tome uma nova decisão
	# imediatamente após uma interrupção.
	_decision_delay = _rng.randf_range(
		minimum_decision_delay,
		maximum_decision_delay
	)


func _start_random_crouch_attack() -> bool:
	var valid_attacks: Array[StringName] = []

	for attack_state in crouch_attack_states:
		if state_machine.has_state(attack_state):
			valid_attacks.append(attack_state)
		else:
			printerr(
				"DummyAI: estado de ataque agachado "
				+ "não encontrado: ",
				attack_state
			)

	if valid_attacks.is_empty():
		printerr(
			"DummyAI: nenhum ataque agachado válido."
		)
		return false

	var selected_index: int = _rng.randi_range(
		0,
		valid_attacks.size() - 1
	)

	var selected_attack: StringName = (
		valid_attacks[selected_index]
	)

	_stop_character()

	print(
		"DummyAI: ataque agachado escolhido: ",
		selected_attack
	)

	state_machine.force_transition(
		selected_attack
	)

	return true

func _process_air_attack(delta: float) -> void:
	if _air_attack_attempted:
		return

	if character == null:
		return

	# Evita iniciar um ataque quando já estiver
	# tocando o chão.
	if character.is_on_floor():
		return

	_air_attack_timer = maxf(
		_air_attack_timer - delta,
		0.0
	)

	if _air_attack_timer > 0.0:
		return

	# Faz somente uma tentativa por salto.
	_air_attack_attempted = true

	if _rng.randf() > air_attack_chance:
		return

	_start_random_air_attack()


func _start_random_air_attack() -> bool:
	var valid_attacks: Array[StringName] = []

	for attack_state in air_attack_states:
		if state_machine.has_state(attack_state):
			valid_attacks.append(attack_state)
		else:
			printerr(
				"DummyAI: estado de ataque aéreo "
				+ "não encontrado: ",
				attack_state
			)

	if valid_attacks.is_empty():
		printerr(
			"DummyAI: nenhum ataque aéreo válido."
		)
		return false

	var selected_index: int = _rng.randi_range(
		0,
		valid_attacks.size() - 1
	)

	var selected_attack: StringName = (
		valid_attacks[selected_index]
	)

	print(
		"DummyAI escolheu ataque aéreo: ",
		selected_attack
	)

	state_machine.force_transition(
		selected_attack
	)

	return true


func _is_air_attack_state(
	state_name: StringName
) -> bool:
	for attack_state in air_attack_states:
		if state_name == attack_state:
			return true

	return false

func _perform_throw() -> void:
	if not state_machine.has_state(try_grab_state):
		printerr(
			"DummyAI: estado TryGrab não encontrado: ",
			try_grab_state
		)

		_start_wait()
		return

	if (
		_get_horizontal_attack_distance()
		> throw_range
	):
		_perform_random_attack()
		return

	if not target.has_method("can_be_thrown"):
		_perform_random_attack()
		return

	if not bool(target.call("can_be_thrown")):
		_perform_random_attack()
		return

	_stop_character()

	print("DummyAI decidiu tentar um Throw.")

	state_machine.force_transition(
		try_grab_state
	)

	_decision_delay = _rng.randf_range(
		minimum_decision_delay,
		maximum_decision_delay
	)
