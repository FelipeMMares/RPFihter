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
@export var active: bool = false

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

@export_group("Resposta à defesa")

@export var grab_state: StringName = &"TryGrab"

@export var target_guard_states: Array[StringName] = [
	&"Guard",
	&"GuardWhile"
]

@export_range(0.0, 1.0, 0.05)
var grab_guarding_target_chance: float = 0.75

@export_group("Distância")
@export var attack_range: float = 25.0

@export_group("Ataques especiais")

@export var special_attack_states: Array[StringName] = [
	&"ScratchWheel",
	&"RhinoHorn",
	&"LynxTail"
]

@export_range(0.0, 1.0, 0.05)
var normal_special_chance: float = 0.25

@export_range(0.0, 1.0, 0.05)
var desperation_special_chance: float = 0.55

@export_range(0.0, 1.0, 0.05)
var finisher_special_chance: float = 0.70

@export var special_max_distance: float = 180.0

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

@export_group("Instinto de combate")

@export_range(0, 100, 1)
var aggression: int = 80

@export_range(0, 100, 1)
var survival_instinct: int = 70

# Abaixo desta porcentagem, Elena entra
# no modo de sobrevivência.
@export_range(0.05, 0.90, 0.05)
var low_health_threshold: float = 0.35

# Abaixo desta porcentagem de vida da Chun-Li,
# Elena tenta finalizar a luta.
@export_range(0.05, 0.90, 0.05)
var target_finisher_threshold: float = 0.25

@export_range(0, 200, 5)
var desperation_attack_bonus: int = 45

@export_range(0, 200, 5)
var finisher_attack_bonus: int = 70

@export_range(0, 100, 5)
var survival_retreat_bonus: int = 15

@export_range(0, 100, 5)
var survival_crouch_bonus: int = 20

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

var _character_health: Health
var _target_health: Health
var _target_state_machine: StateMachine

func _ready() -> void:
	_rng.randomize()

	_character_health = (
		character.get_node_or_null("Health")
		as Health
	)

	if target != null:
		_cache_target_components()

	_character_body_shape = _find_body_collision(
		character
	)

	if target != null:
		_target_body_shape = _find_body_collision(
			target
		)


func setup(
	new_target: CharacterBody2D
) -> void:
	target = new_target

	if target == null:
		printerr(
			"DummyAI: alvo recebido é nulo."
		)
		return

	_target_body_shape = _find_body_collision(
		target
	)

	_cache_target_components()

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


	if state_machine.is_round_result_locked():
		return
	
	var current_state: StringName = (
		state_machine.get_current_state_name()
	)

	if _current_action == AIAction.CROUCH:
		_process_crouch_action(
			delta,
			current_state
		)
		return
	# Os próprios estados especiais controlam a velocidade.
	if _is_special_attack_state(current_state):
		return
	# Durante toda a sequência de agarrão, a StateMachine
# e a física do Dummy controlam o personagem.
#
	if current_state == &"Thrown":
		return

	if current_state == &"HurtFall":
		return

	if current_state == &"ParryRecoil":
		return

	if current_state == jump_state:
		return

	if current_state == airborne_state:
		_process_air_attack(delta)
		return

	if _is_air_attack_state(current_state):
		return

	if current_state == &"Fall":
		_stop_character()
		return

	if current_state == &"GetUp":
		_stop_character()
		return

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

# Só conta o delay quando a IA está
# realmente livre para decidir.
	if _decision_delay > 0.0:
		_decision_delay = maxf(
			_decision_delay - delta,
			0.0
		)
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
	# Se a Chun-Li estiver defendendo, tenta agarrar.
	if _try_grab_guarding_target():
		return

	var attack_weight: int = (
		close_attack_weight
		+ int(float(aggression) * 0.25)
	)

	var retreat_weight: int = close_retreat_weight
	var jump_weight: int = close_jump_weight
	var crouch_weight: int = close_crouch_weight
	var wait_weight: int = close_wait_weight

	# Com pouca vida, Elena fica mais desesperada:
	# ataca mais, espera menos e usa movimentos
	# defensivos com um pouco mais de frequência.
	if _is_character_low_health():
		attack_weight += desperation_attack_bonus

		retreat_weight += int(
			float(survival_instinct) * 0.20
		)

		crouch_weight += survival_crouch_bonus

		wait_weight = 0

	# Se Chun-Li estiver quase derrotada,
	# Elena abandona a passividade.
	if _is_target_low_health():
		attack_weight += finisher_attack_bonus
		retreat_weight = 0
		wait_weight = 0

	var weights: Array[int] = [
		attack_weight,
		retreat_weight,
		jump_weight,
		crouch_weight,
		wait_weight
	]

	var selected_action: int = (
		_weighted_index(weights)
	)

	match selected_action:
		0:
			_perform_random_attack()

		1:
			_start_retreat()

		2:
			_perform_jump()

		3:
			_start_crouch()

		4:
			_start_wait()


func _choose_far_action() -> void:
	# Pode usar Rhino Horn ou outro especial
	# para encurtar a distância.
	if _try_special_attack():
		return

	var approach_weight: int = (
		far_approach_weight
		+ int(float(aggression) * 0.30)
	)

	var retreat_weight: int = far_retreat_weight
	var jump_weight: int = far_jump_weight
	var crouch_weight: int = far_crouch_weight
	var wait_weight: int = far_wait_weight

	if _is_character_low_health():
		# Não fica parada esperando ser derrotada.
		approach_weight += int(
			float(desperation_attack_bonus) * 0.50
		)

		crouch_weight += int(
			float(survival_instinct) * 0.15
		)

		wait_weight = 0

	if _is_target_low_health():
		# Persegue a Chun-Li para finalizar.
		approach_weight += finisher_attack_bonus
		retreat_weight = 0
		wait_weight = 0

	var weights: Array[int] = [
		approach_weight,
		retreat_weight,
		jump_weight,
		crouch_weight,
		wait_weight
	]

	var selected_action: int = (
		_weighted_index(weights)
	)

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

	_set_next_decision_delay()


func _perform_random_attack() -> void:
	if _try_special_attack():
		return
	
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

	var transitioned: bool = (
		state_machine.request_ai_transition(
			selected_attack
		)
	)

	if not transitioned:
		return

	_set_next_decision_delay()


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

	var transitioned: bool = (
		state_machine.request_ai_transition(
			jump_state
		)
	)

	if not transitioned:
		return

	_set_next_decision_delay()


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

	_prepare_ai_crouch_state(
		crouch_start_state,
		false
	)

	state_machine.request_ai_transition(
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

func _prepare_ai_crouch_state(
	state_name: StringName,
	leaving: bool
) -> void:
	if state_machine == null:
		return

	var crouch_state: State = (
		state_machine.get_node_or_null(
			NodePath(state_name)
		) as State
	)

	if crouch_state == null:
		return

	if crouch_state.has_method(
		"prepare_ai_crouch"
	):
		crouch_state.call(
			"prepare_ai_crouch",
			leaving
		)

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

	_prepare_ai_crouch_state(
		crouch_end_state,
		true
	)

	state_machine.request_ai_transition(
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

	_set_next_decision_delay()


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
	_set_next_decision_delay()


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

	return state_machine.request_ai_transition(
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

	return state_machine.request_ai_transition(
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

		var can_throw_result: Variant = (
			target.call("can_be_thrown")
		)

		var can_throw: bool = (
			typeof(can_throw_result) == TYPE_BOOL
			and can_throw_result == true
		)

		if not can_throw:
			_perform_random_attack()
			return

	_stop_character()

	print("DummyAI decidiu tentar um Throw.")

	state_machine.force_transition(
		try_grab_state
	)
	
	_set_next_decision_delay()

func _start_random_special_attack() -> bool:
	var valid_specials: Array[StringName] = []

	for special_state in special_attack_states:
		if state_machine.has_state(special_state):
			valid_specials.append(special_state)
		else:
			printerr(
				"DummyAI: especial não encontrado: ",
				special_state
			)

	if valid_specials.is_empty():
		return false

	var selected_index: int = _rng.randi_range(
		0,
		valid_specials.size() - 1
	)

	var selected_special: StringName = (
		valid_specials[selected_index]
	)

	_stop_character()

	print(
		"DummyAI escolheu especial: ",
		selected_special
	)

	if not character.has_method(
		"request_special_attack"
	):
		return false

	var result: Variant = character.call(
		"request_special_attack",
		selected_special
	)

	var special_started: bool = (
		typeof(result) == TYPE_BOOL
		and result == true
	)

	if not special_started:
		print(
			"DummyAI: MP insuficiente para ",
			selected_special
		)

		return false

	return true

	_set_next_decision_delay()

	return true


func _is_special_attack_state(
	state_name: StringName
) -> bool:
	for special_state in special_attack_states:
		if state_name == special_state:
			return true

	return false

func _cache_target_components() -> void:
	if target == null:
		return

	_target_health = (
		target.get_node_or_null("Health")
		as Health
	)

	_target_state_machine = (
		target.get_node_or_null("StateMachine")
		as StateMachine
	)


func _get_health_ratio(
	health_component: Health
) -> float:
	if health_component == null:
		return 1.0

	if health_component.max_health <= 0:
		return 0.0

	return clampf(
		float(health_component.current_health)
		/ float(health_component.max_health),
		0.0,
		1.0
	)


func _is_character_low_health() -> bool:
	return (
		_get_health_ratio(_character_health)
		<= low_health_threshold
	)


func _is_target_low_health() -> bool:
	return (
		_get_health_ratio(_target_health)
		<= target_finisher_threshold
	)

func _try_special_attack() -> bool:
	if character == null:
		return false

	if state_machine == null:
		return false

	# Não permite que um especial da IA
	# interrompa uma ação em andamento.
	if not state_machine.can_ai_change_state():
		return false

	if not character.has_method(
		"request_special_attack"
	):
		return false

	if (
		_get_horizontal_attack_distance()
		> special_max_distance
	):
		return false

	var selected_chance: float = (
		normal_special_chance
	)

	if _is_character_low_health():
		selected_chance = maxf(
			selected_chance,
			desperation_special_chance
		)

	if _is_target_low_health():
		selected_chance = maxf(
			selected_chance,
			finisher_special_chance
		)

	if _rng.randf() > selected_chance:
		return false

	var valid_specials: Array[StringName] = []

	for special_state in special_attack_states:
		if state_machine.has_state(special_state):
			valid_specials.append(
				special_state
			)

	if valid_specials.is_empty():
		return false

	# Tenta mais de um especial caso o primeiro
	# não possa começar.
	valid_specials.shuffle()

	for special_state in valid_specials:
		var result: Variant = character.call(
			"request_special_attack",
			special_state
		)

		var special_started: bool = (
			typeof(result) == TYPE_BOOL
			and result == true
		)

		if not special_started:
			continue

		_stop_character()
		_set_next_decision_delay()

		print(
			"DummyAI usou especial: ",
			special_state
		)

		return true

	# Sem MP ou nenhum especial disponível:
	# volta para o golpe normal.
	return false

func _try_grab_guarding_target() -> bool:
	if _target_state_machine == null:
		return false

	if not state_machine.has_state(grab_state):
		return false

	var target_state: StringName = (
		_target_state_machine
		.get_current_state_name()
	)

	if not target_guard_states.has(
		target_state
	):
		return false

	if (
		_get_horizontal_attack_distance()
		> attack_range
	):
		return false

	if (
		_rng.randf()
		> grab_guarding_target_chance
	):
		return false

	_stop_character()

	var transitioned: bool = (
		state_machine.request_ai_transition(
		grab_state
		)
	)

	if not transitioned:
		return false

	_set_next_decision_delay()

	print(
		"DummyAI tentou agarrar a Chun-Li em defesa."
	)

	return true

func _set_next_decision_delay() -> void:
	var delay_multiplier: float = 1.0

	if _is_target_low_health():
		delay_multiplier = 0.40
	elif _is_character_low_health():
		delay_multiplier = 0.55

	_decision_delay = (
		_rng.randf_range(
			minimum_decision_delay,
			maximum_decision_delay
		)
		* delay_multiplier
	)

func reset_for_round_transition() -> void:
	_current_action = AIAction.NONE
	_action_time_left = 0.0

	_crouch_hold_started = false
	_crouch_release_requested = false

	_crouch_attack_timer = 0.0
	_crouch_attack_attempted = false

	_air_attack_timer = 0.0
	_air_attack_attempted = false

	_stop_character()

	# Evita uma decisão exatamente no
	# primeiro frame em que a IA for liberada.
	_set_next_decision_delay()
