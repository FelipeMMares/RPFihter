extends Node2D
class_name FightManager


@export_group("Rounds")

@export var rounds_to_win: int = 2
@export var next_round_delay: float = 3.0


@export_group("Morte súbita")

@export var timeout_draws_before_sudden_death: int = 2

# Qualquer golpe deve encerrar a morte súbita.
@export var sudden_death_health: int = 1


@export_group("Fim da luta")

# Tempo que a mensagem final fica visível
# antes de abrir o menu.
@export var final_victory_message_duration: float = 3.0

# Arraste o nó do menu de pausa para este campo.
@export var pause_menu: Control


@onready var player_1: CharacterBody2D = $Player1
@onready var player_2: CharacterBody2D = $Dummy

@onready var hud: FightHUD = $HUD
@onready var dummy_ai: DummyAI = $Dummy/DummyAI


@onready var player_facing: FacingController = (
	$Player1/FacingController
)

@onready var dummy_facing: FacingController = (
	$Dummy/FacingController
)


@onready var player_1_health: Health = (
	$Player1/Health
)

@onready var player_2_health: Health = (
	$Dummy/Health
)


@onready var player_1_state_machine: StateMachine = (
	$Player1/StateMachine
)

@onready var player_2_state_machine: StateMachine = (
	$Dummy/StateMachine
)


var player_1_start_position: Vector2
var player_2_start_position: Vector2


var player_1_wins: int = 0
var player_2_wins: int = 0


var round_finished: bool = false
var match_finished: bool = false

var consecutive_timeout_draws: int = 0
var sudden_death_active: bool = false


var _round_finish_in_progress: bool = false
var _match_finish_in_progress: bool = false


func _ready() -> void:
	player_1_start_position = player_1.global_position
	player_2_start_position = player_2.global_position

	if dummy_ai != null:
		dummy_ai.setup(player_1)
	else:
		printerr(
			"FightManager: DummyAI não encontrada."
		)

	if player_facing != null:
		player_facing.setup(player_2)
	else:
		printerr(
			"FightManager: FacingController do Player não encontrado."
		)

	if dummy_facing != null:
		dummy_facing.setup(player_1)
	else:
		printerr(
			"FightManager: FacingController do Dummy não encontrado."
		)

	player_1_health.defeated.connect(
		_on_player_1_health_depleted
	)

	player_2_health.defeated.connect(
		_on_player_2_health_depleted
	)

	hud.time_over.connect(
		_on_time_over
	)

	hud.setup(
		player_1_health,
		player_2_health
	)

	hud.set_timer_enabled(true)
	hud.set_sudden_death_mode(false)

	hud.start_round(
		player_1_wins,
		player_2_wins
	)

	# O menu precisa continuar processando
	# enquanto a árvore estiver pausada.
	if pause_menu != null:
		pause_menu.process_mode = (
			Node.PROCESS_MODE_ALWAYS
		)


func _on_player_1_health_depleted() -> void:
	if (
		round_finished
		or match_finished
		or _round_finish_in_progress
	):
		return

	# Player 2 venceu.
	await _finish_round_by_health(
		player_2,
		player_1,
		2
	)


func _on_player_2_health_depleted() -> void:
	if (
		round_finished
		or match_finished
		or _round_finish_in_progress
	):
		return

	# Player 1 venceu.
	await _finish_round_by_health(
		player_1,
		player_2,
		1
	)


func _finish_round_by_health(
	winner: CharacterBody2D,
	loser: CharacterBody2D,
	winner_number: int
) -> void:
	if (
		round_finished
		or match_finished
		or _round_finish_in_progress
	):
		return

	_round_finish_in_progress = true
	round_finished = true

	# É necessário guardar essa informação antes
	# de desativar a morte súbita.
	var round_was_sudden_death: bool = (
		sudden_death_active
	)

	consecutive_timeout_draws = 0
	sudden_death_active = false

	hud.set_timer_enabled(false)
	hud.set_sudden_death_mode(false)
	hud.show_ko()

	# Em derrota por HP, usamos FallDefeated.
	_lock_round_result(
		winner,
		loser,
		&"FallDefeated"
	)

	if winner_number == 1:
		player_1_wins += 1
	else:
		player_2_wins += 1

	hud.update_wins(
		player_1_wins,
		player_2_wins
	)

	await _continue_after_round(
		winner_number,
		round_was_sudden_death
	)


func _on_time_over() -> void:
	if (
		round_finished
		or match_finished
		or _round_finish_in_progress
	):
		return

	# O cronômetro não deve terminar durante
	# a morte súbita.
	if sudden_death_active:
		return

	_round_finish_in_progress = true
	round_finished = true

	hud.set_timer_enabled(false)

	var player_1_hp: int = (
		player_1_health.current_health
	)

	var player_2_hp: int = (
		player_2_health.current_health
	)

	var winner_number: int = 0

	if player_1_hp > player_2_hp:
		winner_number = 1
		consecutive_timeout_draws = 0
		player_1_wins += 1

		_lock_round_result(
			player_1,
			player_2,
			&"Defeated"
		)

		hud.show_round_message(
			"PLAYER 1 WINS"
		)

	elif player_2_hp > player_1_hp:
		winner_number = 2
		consecutive_timeout_draws = 0
		player_2_wins += 1

		_lock_round_result(
			player_2,
			player_1,
			&"Defeated"
		)

		hud.show_round_message(
			"PLAYER 2 WINS"
		)

	else:
		consecutive_timeout_draws += 1

		_lock_draw_result()

		hud.show_round_message(
			"DRAW"
		)

		print(
			"Empates consecutivos por timeout: ",
			consecutive_timeout_draws,
			"/",
			timeout_draws_before_sudden_death
		)

	hud.update_wins(
		player_1_wins,
		player_2_wins
	)

	await _continue_after_round(
		winner_number,
		false
	)


func _continue_after_round(
	winner_number: int,
	round_was_sudden_death: bool
) -> void:
	# Um vencedor em morte súbita encerra
	# imediatamente toda a luta.
	if (
		round_was_sudden_death
		and winner_number != 0
	):
		await _finish_match(
			winner_number
		)
		return

	if player_1_wins >= rounds_to_win:
		await _finish_match(1)
		return

	if player_2_wins >= rounds_to_win:
		await _finish_match(2)
		return

	# Apenas rounds intermediários usam
	# o intervalo comum.
	await get_tree().create_timer(
		next_round_delay
	).timeout

	_start_next_round()


func _start_next_round() -> void:
	# Primeiro destrava as StateMachines.
	_unlock_fighters_for_next_round()

	round_finished = false
	_round_finish_in_progress = false

	sudden_death_active = (
		consecutive_timeout_draws
		>= timeout_draws_before_sudden_death
	)

	player_1.global_position = (
		player_1_start_position
	)

	player_2.global_position = (
		player_2_start_position
	)

	player_1.velocity = Vector2.ZERO
	player_2.velocity = Vector2.ZERO

	if sudden_death_active:
		player_1_health.set_health(
			sudden_death_health
		)

		player_2_health.set_health(
			sudden_death_health
		)

		print(
			"MORTE SÚBITA | HP: ",
			sudden_death_health
		)

	else:
		player_1_health.reset_health()
		player_2_health.reset_health()

	player_1_state_machine.force_transition(
		&"Idle"
	)

	player_2_state_machine.force_transition(
		&"Idle"
	)

	hud.set_timer_enabled(
		not sudden_death_active
	)

	hud.set_sudden_death_mode(
		sudden_death_active
	)

	hud.start_round(
		player_1_wins,
		player_2_wins
	)


func _lock_round_result(
	winner: CharacterBody2D,
	loser: CharacterBody2D,
	loser_result_state: StringName
) -> void:
	_lock_character_result(
		winner,
		&"Victory"
	)

	_lock_character_result(
		loser,
		loser_result_state
	)


func _lock_draw_result() -> void:
	_lock_character_result(
		player_1,
		&"Defeated"
	)

	_lock_character_result(
		player_2,
		&"Defeated"
	)


func _lock_character_result(
	character: CharacterBody2D,
	result_state: StringName
) -> void:
	if character == null:
		return

	var state_machine := (
		_get_character_state_machine(character)
	)

	if state_machine == null:
		printerr(
			"FightManager: StateMachine não encontrada em ",
			character.name
		)
		return

	# Interrompe movimento horizontal.
	# FallDefeated ainda pode continuar caindo
	# pela gravidade do personagem.
	character.velocity.x = 0.0

	if result_state != &"FallDefeated":
		character.velocity.y = 0.0

	state_machine.lock_round_result(
		result_state
	)


func _unlock_fighters_for_next_round() -> void:
	player_1_state_machine.unlock_round_result()
	player_2_state_machine.unlock_round_result()


func _get_character_state_machine(
	character: CharacterBody2D
) -> StateMachine:
	if character == player_1:
		return player_1_state_machine

	if character == player_2:
		return player_2_state_machine

	return (
		character.get_node_or_null("StateMachine")
		as StateMachine
	)


func _finish_match(
	winner_number: int
) -> void:
	if _match_finish_in_progress:
		return

	_match_finish_in_progress = true
	match_finished = true
	round_finished = true

	hud.set_timer_enabled(false)
	hud.set_sudden_death_mode(false)

	var victory_message: String

	if winner_number == 1:
		victory_message = (
			"PLAYER 1 WINS THE MATCH"
		)
	else:
		victory_message = (
			"PLAYER 2 WINS THE MATCH"
		)

	# Usa a função que já existe na sua HUD.
	hud.show_round_message(
		victory_message
	)

	# Os lutadores continuam presos em
	# Victory e Defeated/FallDefeated.
	await get_tree().create_timer(
		final_victory_message_duration
	).timeout

	_open_match_end_menu()


func _open_match_end_menu() -> void:
	if pause_menu == null:
		printerr(
			"FightManager: Pause Menu não configurado."
		)

		# Ainda pausa a luta para impedir que ela continue.
		get_tree().paused = true
		return

	# Usa o método especial caso ele exista.
	if pause_menu.has_method(
		"open_for_match_end"
	):
		pause_menu.call(
			"open_for_match_end"
		)
	else:
		# Compatibilidade com um menu simples.
		pause_menu.show()

	get_tree().paused = true
