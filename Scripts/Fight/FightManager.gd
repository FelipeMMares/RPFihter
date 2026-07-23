extends Node2D
class_name FightManager

@export var rounds_to_win: int = 2
@export var next_round_delay: float = 3.0

@onready var player_1: CharacterBody2D = $Player1
@onready var player_2: CharacterBody2D = $Dummy
@onready var hud: FightHUD = $HUD
@onready var dummy_ai: DummyAI = $Dummy/DummyAI

@onready var player_1_health: Health = $Player1/Health
@onready var player_2_health: Health = $Dummy/Health

@onready var player_1_state_machine: StateMachine = \
	$Player1/StateMachine

@onready var player_2_state_machine: StateMachine = \
	$Dummy/StateMachine

var player_1_start_position: Vector2
var player_2_start_position: Vector2

var player_1_wins: int = 0
var player_2_wins: int = 0

var round_finished: bool = false
var match_finished: bool = false


func _ready() -> void:

	if dummy_ai != null:
		dummy_ai.setup(player_1)
	else:
		printerr(
			"CenaDaLuta: DummyAI não encontrada."
		)

	player_1_start_position = player_1.global_position
	player_2_start_position = player_2.global_position

	player_1_health.defeated.connect(
		_on_player_1_health_depleted
	)

	player_2_health.defeated.connect(
		_on_player_2_health_depleted
	)

	hud.time_over.connect(_on_time_over)

	# Primeiro configura as referências da HUD.
	hud.setup(
		player_1_health,
		player_2_health
	)

	# Depois inicia imediatamente o primeiro round.
	hud.start_round(
		player_1_wins,
		player_2_wins
	)

func _on_player_1_health_depleted() -> void:
	if round_finished or match_finished:
		return

	# Player 1 perdeu por ficar sem HP.
	_finish_round_by_health(
		player_2_state_machine,
		player_1_state_machine,
		2
	)


func _on_player_2_health_depleted() -> void:
	if round_finished or match_finished:
		return

	# Player 2 perdeu por ficar sem HP.
	_finish_round_by_health(
		player_1_state_machine,
		player_2_state_machine,
		1
	)


func _finish_round_by_health(
	winner_state_machine: StateMachine,
	loser_state_machine: StateMachine,
	winner_number: int
) -> void:
	if round_finished:
		return

	round_finished = true

	# KO aparece apenas quando alguém perdeu todo o HP.
	hud.show_ko()

	winner_state_machine.force_transition(&"Victory")
	loser_state_machine.force_transition(&"FallDefeated")

	if winner_number == 1:
		player_1_wins += 1
	else:
		player_2_wins += 1

	hud.update_wins(
		player_1_wins,
		player_2_wins
	)

	await _continue_after_round()

func _on_time_over() -> void:
	if round_finished or match_finished:
		return

	round_finished = true

	var player_1_hp := player_1_health.current_health
	var player_2_hp := player_2_health.current_health

	if player_1_hp > player_2_hp:
		player_1_wins += 1

		player_1_state_machine.force_transition(&"Victory")
		player_2_state_machine.force_transition(&"Defeated")

		hud.show_round_message("PLAYER 1 WINS")

	elif player_2_hp > player_1_hp:
		player_2_wins += 1

		player_2_state_machine.force_transition(&"Victory")
		player_1_state_machine.force_transition(&"Defeated")

		hud.show_round_message("PLAYER 2 WINS")

	else:
		# Empate no tempo.
		player_1_state_machine.force_transition(&"Defeated")
		player_2_state_machine.force_transition(&"Defeated")

		hud.show_round_message("DRAW")

	hud.update_wins(
		player_1_wins,
		player_2_wins
	)

	await _continue_after_round()

func _continue_after_round() -> void:
	await get_tree().create_timer(
		next_round_delay
	).timeout

	if player_1_wins >= rounds_to_win:
		match_finished = true
		hud.show_round_message("PLAYER 1 WINS THE MATCH")
		return

	if player_2_wins >= rounds_to_win:
		match_finished = true
		hud.show_round_message("PLAYER 2 WINS THE MATCH")
		return

	_start_next_round()

func _start_next_round() -> void:
	round_finished = false

	# Reposiciona os personagens.
	player_1.global_position = player_1_start_position
	player_2.global_position = player_2_start_position

	player_1.velocity = Vector2.ZERO
	player_2.velocity = Vector2.ZERO

	# Recupera toda a vida.
	player_1_health.reset_health()
	player_2_health.reset_health()

	# Retorna ambos ao estado inicial.
	player_1_state_machine.force_transition(&"Idle")
	player_2_state_machine.force_transition(&"Idle")

	hud.start_round(
		player_1_wins,
		player_2_wins
	)
