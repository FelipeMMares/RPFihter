extends Node
class_name DummyAI


@export_group("Referências")
@export var state_machine: StateMachine
@export var target: CharacterBody2D
@export var animated_sprite: AnimatedSprite2D


@export_group("Comportamento")
@export var active: bool = true

# Distância em que o Dummy para de andar e tenta atacar.
@export var attack_range: float = 100.0


@export_group("Tempo de reação")
@export var minimum_reaction_time: float = 0.15
@export var maximum_reaction_time: float = 0.35


@export_group("Intervalo entre ataques")
@export var minimum_attack_cooldown: float = 0.75
@export var maximum_attack_cooldown: float = 1.25


@export_group("Orientação do sprite")

# Deixe true se o sprite original olha para a direita.
@export var sprite_faces_right: bool = true


@export_group("Estados")
@export var idle_state: StringName = &"Idle"
@export var walk_state: StringName = &"Walk"
@export var attack_state: StringName = &"LightPunch"


@onready var character: CharacterBody2D = (
	get_parent() as CharacterBody2D
)


var _reaction_time_left: float = -1.0
var _cooldown_time_left: float = 0.0

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()

	if character == null:
		printerr(
			"DummyAI: o nó pai precisa ser um CharacterBody2D."
		)

		set_physics_process(false)
		return

	if state_machine == null:
		state_machine = character.get_node_or_null(
			"StateMachine"
		) as StateMachine

	if animated_sprite == null:
		animated_sprite = character.get_node_or_null(
			"AnimatedSprite2D"
		) as AnimatedSprite2D

	if state_machine == null:
		printerr(
			"DummyAI: StateMachine não encontrada."
		)

		set_physics_process(false)
		return

	if not character.has_method(state_machine.move_method):
		printerr(
			"DummyAI: o Dummy não possui o método de movimento: ",
			state_machine.move_method
		)

		set_physics_process(false)
		return

	if not state_machine.has_state(idle_state):
		printerr(
			"DummyAI: estado não encontrado: ",
			idle_state
		)

	if not state_machine.has_state(walk_state):
		printerr(
			"DummyAI: estado não encontrado: ",
			walk_state
		)

	if not state_machine.has_state(attack_state):
		printerr(
			"DummyAI: estado não encontrado: ",
			attack_state
		)


func setup(new_target: CharacterBody2D) -> void:
	target = new_target

	print(
		"DummyAI configurada. Alvo: ",
		target.name if target != null else "nulo"
	)


func _physics_process(delta: float) -> void:
	if not active:
		_stop_character()
		return

	if character == null:
		return

	if target == null:
		return

	if state_machine == null:
		return

	_cooldown_time_left = maxf(
		_cooldown_time_left - delta,
		0.0
	)

	var current_state: StringName = (
		state_machine.get_current_state_name()
	)

	# Durante ataque, dano, derrota e outros estados,
	# a IA não pode tomar uma nova decisão.
	if (
		current_state != idle_state
		and current_state != walk_state
	):
		_stop_character()
		return

	var horizontal_difference: float = (
		target.global_position.x
		- character.global_position.x
	)

	var horizontal_distance: float = absf(
		horizontal_difference
	)

	_face_target(horizontal_difference)

	# A IA já decidiu atacar e está aguardando
	# o tempo de reação.
	if _reaction_time_left >= 0.0:
		_stop_character()

		_reaction_time_left -= delta

		# O jogador saiu do alcance durante a espera.
		if horizontal_distance > attack_range:
			_reaction_time_left = -1.0
			return

		if _reaction_time_left <= 0.0:
			_reaction_time_left = -1.0
			_perform_attack()

		return

	# Fora do alcance: aproxima-se do jogador.
	if horizontal_distance > attack_range:
		_move_toward_target(horizontal_difference)
		return

	# Dentro do alcance: para de andar.
	_stop_character()

	if current_state == walk_state:
		state_machine.force_transition(idle_state)

	# Ainda está no intervalo entre ataques.
	if _cooldown_time_left > 0.0:
		return

	_schedule_attack()
	

func _move_toward_target(
	horizontal_difference: float
) -> void:
	var direction_x: float = signf(
		horizontal_difference
	)

	if direction_x == 0.0:
		_stop_character()
		return

	var current_state: StringName = (
		state_machine.get_current_state_name()
	)

	if current_state != walk_state:
		state_machine.force_transition(walk_state)

	_move_character(
		Vector2(direction_x, 0.0)
	)


func _stop_character() -> void:
	if character == null:
		return

	if state_machine == null:
		return

	_move_character(Vector2.ZERO)


func _move_character(direction: Vector2) -> void:
	if not character.has_method(
		state_machine.move_method
	):
		return

	character.call(
		state_machine.move_method,
		direction
	)


func _schedule_attack() -> void:
	if _reaction_time_left >= 0.0:
		return

	_reaction_time_left = _rng.randf_range(
		minimum_reaction_time,
		maximum_reaction_time
	)

	print(
		"DummyAI: ataque preparado em ",
		_reaction_time_left,
		" segundos."
	)


func _perform_attack() -> void:
	if target == null:
		return

	var horizontal_distance: float = absf(
		target.global_position.x
		- character.global_position.x
	)

	# Confere novamente porque o Player pode ter
	# se afastado durante o tempo de reação.
	if horizontal_distance > attack_range:
		return

	if (
		state_machine.get_current_state_name()
		!= idle_state
	):
		return

	if not state_machine.has_state(attack_state):
		printerr(
			"DummyAI: ataque não encontrado: ",
			attack_state
		)
		return

	_stop_character()

	print(
		"DummyAI: executando ",
		attack_state
	)

	state_machine.force_transition(
		attack_state
	)

	_cooldown_time_left = _rng.randf_range(
		minimum_attack_cooldown,
		maximum_attack_cooldown
	)


func _face_target(
	horizontal_difference: float
) -> void:
	if animated_sprite == null:
		return

	if horizontal_difference == 0.0:
		return

	var target_is_left: bool = (
		horizontal_difference < 0.0
	)

	if sprite_faces_right:
		animated_sprite.flip_h = target_is_left
	else:
		animated_sprite.flip_h = not target_is_left
