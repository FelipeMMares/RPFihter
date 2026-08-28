extends Node2D
class_name FightManager

@onready var arena_holder: Node2D = (
	$ArenaHolder
)

@onready var arena_music_player: AudioStreamPlayer = (
	$ArenaMusicPlayer
)

@onready var player_guard_indicator: GuardIndicator = (
	$HUD/PlayerGuardIndicator
)

@onready var dummy_guard_indicator: GuardIndicator = (
	$HUD/DummyGuardIndicator
)

@export_group("Personagens")

@export var chun_li_scene: PackedScene
@export var elena_scene: PackedScene
@export var morrigan_scene: PackedScene
@export var zangief_scene: PackedScene
@export var potemkin_scene: PackedScene

@export_group("Mirror Match")

@export var mirror_cpu_color: Color = Color(
	0.65,
	0.80,
	1.0,
	1.0
)

@export_group("Arenas")

@export var arena_01_scene: PackedScene
@export var arena_02_scene: PackedScene
@export var arena_03_scene: PackedScene
@export var arena_04_scene: PackedScene
@export var arena_05_scene: PackedScene
@export var arena_06_scene: PackedScene

@export_group("Introdução do round")

@export_range(1, 10, 1)
var round_countdown_start: int = 3

@export_range(0.1, 3.0, 0.1)
var countdown_step_duration: float = 1.0

@export_range(0.1, 3.0, 0.1)
var fight_message_duration: float = 0.75

@export_group("Rounds")

@export var rounds_to_win: int = 2
@export var next_round_delay: float = 3.0

@export_group("Transição entre rounds")

@export_range(0.0, 3.0, 0.05)
var fade_to_black_duration: float = 0.4

@export_range(0.0, 2.0, 0.05)
var black_screen_hold_duration: float = 0.15

@export_range(0.0, 3.0, 0.05)
var fade_from_black_duration: float = 0.4

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

@export_group("MP")

# Ligado: cada round começa com Starting MP.
# Desligado: o MP passa de um round para o outro.
@export var reset_mp_each_round: bool = true


@onready var hud: FightHUD = $HUD

@export_group("Telas")

@export_file("*.tscn")
var player_defeat_scene_path: String = (
	"res://Cenas/DefeatScreen/DefeatScreen.tscn"
)

@onready var chun_li_entry_spawn: Marker2D = (
	$ChunLiEntrySpawn
)

@onready var player_spawn: Marker2D = (
	$PlayerSpawn
)

@onready var dummy_spawn: Marker2D = (
	$DummySpawn
)

var player_1: CharacterBody2D
var player_2: CharacterBody2D

var dummy_ai: DummyAI
var player_ai: DummyAI

var player_facing: FacingController
var dummy_facing: FacingController

var player_1_health: Health
var player_2_health: Health

var player_1_mp: MagicPoints
var player_2_mp: MagicPoints

var player_1_state_machine: StateMachine
var player_2_state_machine: StateMachine

var current_round_number: int = 1

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

var _round_intro_in_progress: bool = false



func _ready() -> void:
	var selected_arena: ArenaVisual = (
		_spawn_selected_arena()
	)

	_play_arena_music(
		selected_arena
	)
	_spawn_selected_fighters()

	if player_1 == null or player_2 == null:
		printerr(
			"FightManager: não foi possível criar os lutadores."
		)
		return

	_connect_guard_indicators()

	player_1_start_position = (
		player_1.global_position
	)

	player_2_start_position = (
		player_2.global_position
	)

	# Player1 recebe input humano.
	if player_1_state_machine != null:
		player_1_state_machine.set_player_input_enabled(
			true
		)

	# Dummy nunca recebe input humano.
	if player_2_state_machine != null:
		player_2_state_machine.set_player_input_enabled(
			false
		)

	# Somente o personagem escolhido como CPU
	# precisa ter a IA ativa.
	if dummy_ai != null:
		dummy_ai.active = true

		dummy_ai.process_mode = (
			Node.PROCESS_MODE_INHERIT
		)

		dummy_ai.setup(
			player_1
		)
	else:
		printerr(
			"FightManager: personagem CPU não possui DummyAI."
		)

	_configure_fighter_ai()

	_set_mp_regeneration_enabled(
		false
	)

	if player_facing != null:
		player_facing.setup(
			player_2
		)
	else:
		printerr(
			"FightManager: FacingController do Player não encontrado."
		)

	if dummy_facing != null:
		dummy_facing.setup(
			player_1
		)
	else:
		printerr(
			"FightManager: FacingController do Dummy não encontrado."
		)

	call_deferred(
		"_start_round_intro"
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
		player_2_health,
		player_1_mp,
		player_2_mp
	)

	hud.set_timer_enabled(
		true
	)

	hud.set_sudden_death_mode(
		false
	)

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
	_set_mp_regeneration_enabled(
		false
	)

	if (
		round_finished
		or match_finished
		or _round_finish_in_progress
	):
		return

	_round_finish_in_progress = true
	round_finished = true

	# Guarda antes de desligar a morte súbita.
	var round_was_sudden_death: bool = (
		sudden_death_active
	)

	consecutive_timeout_draws = 0
	sudden_death_active = false

	hud.stop_round_timer()
	hud.set_sudden_death_mode(
		false
	)

	hud.show_ko()


	# Primeiro registra a vitória.
	if winner_number == 1:
		player_1_wins += 1
	else:
		player_2_wins += 1


	hud.update_wins(
		player_1_wins,
		player_2_wins
	)


	# Agora já podemos saber se este
	# round encerrou a luta.
	var match_was_won: bool = false

	if round_was_sudden_death:
		match_was_won = true

	elif (
		winner_number == 1
		and player_1_wins >= rounds_to_win
	):
		match_was_won = true

	elif (
		winner_number == 2
		and player_2_wins >= rounds_to_win
	):
		match_was_won = true


	# Limpa buffers, desliga HitBoxes
	# e interrompe a IA.
	_freeze_combat_after_round_end()


	if match_was_won:
		# Vitória FINAL da luta.
		#
		# Vencedor:
		# Victory e permanece nela.
		#
		# Perdedor:
		# FallDefeated e permanece
		# no último frame.
		_lock_round_result(
			winner,
			loser,
			&"FallDefeated"
		)

	else:
		# Round intermediário.
		#
		# Vencedor apenas espera em Idle.
		#
		# Perdedor fica em FallDefeated
		# até o próximo round.
		_lock_health_round_result(
			winner,
			loser
		)


	await _continue_after_round(
		winner_number,
		round_was_sudden_death
	)


func _on_time_over() -> void:
	_set_mp_regeneration_enabled(false)
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

	hud.stop_round_timer()

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
	# Mantém KO, vitória por tempo ou DRAW
	# visível durante três segundos.
	await get_tree().create_timer(
		next_round_delay
	).timeout

	# Uma vitória durante morte súbita
	# encerra toda a luta.
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

	# Só rounds intermediários passam
	# pela tela preta e são resetados.
	await _transition_to_next_round()


func _reset_next_round_behind_black() -> void:
	# Permite sair de Victory,
	# Defeated e FallDefeated.
	_unlock_fighters_for_next_round()

	if (
		player_1 != null
		and player_1.has_method(
			"reset_for_new_round"
		)
	):
		player_1.call(
			"reset_for_new_round"
		)


	if (
		player_2 != null
		and player_2.has_method(
			"reset_for_new_round"
		)
	):
		player_2.call(
			"reset_for_new_round"
		)


	if player_ai != null:
		player_ai.reset_for_round_transition()


	if dummy_ai != null:
		dummy_ai.reset_for_round_transition()

	current_round_number += 1

	print(
		"Preparando round ",
		current_round_number
	)

	round_finished = false
	_round_finish_in_progress = false

	sudden_death_active = (
		consecutive_timeout_draws
		>= timeout_draws_before_sudden_death
	)

	# Reposiciona enquanto a tela está preta.
	player_1.global_position = (
		player_1_start_position
	)

	player_2.global_position = (
		player_2_start_position
	)

	player_1.velocity = Vector2.ZERO
	player_2.velocity = Vector2.ZERO

# Os estados de resultado já cumpriram seu papel.
# Como a tela ainda está preta, podemos colocar
# os dois lutadores em Idle sem que o jogador
# veja a troca de animação.

	if player_1_state_machine != null:
		if player_1_state_machine.has_state(
			&"Idle"
		):
			player_1_state_machine.force_transition(
				&"Idle"
			)


	if player_2_state_machine != null:
		if player_2_state_machine.has_state(
			&"Idle"
		):
			player_2_state_machine.force_transition(
				&"Idle"
			)

	# Reseta a vida enquanto a tela está preta.
	if sudden_death_active:
		var selected_health: int = maxi(
			sudden_death_health,
			1
		)

		player_1_health.set_health(
			selected_health
		)

		player_2_health.set_health(
			selected_health
		)

		print(
			"MORTE SÚBITA | HP: ",
			selected_health
		)
	else:
		player_1_health.reset_health()
		player_2_health.reset_health()


	# O reset de MP é independente do reset de HP.
	if reset_mp_each_round:
		player_1_mp.reset_mp()
		player_2_mp.reset_mp()


	print(
		"RESET DO ROUND | Chun-Li HP: ",
		player_1_health.current_health,
		"/",
		player_1_health.max_health,
		" | Dummy HP: ",
		player_2_health.current_health,
		"/",
		player_2_health.max_health,
		" | Chun-Li MP: ",
		player_1_mp.current_mp,
		"/",
		player_1_mp.max_mp,
		" | Dummy MP: ",
		player_2_mp.current_mp,
		"/",
		player_2_mp.max_mp
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
	_set_mp_regeneration_enabled(false)
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

	# Player 2 venceu, portanto Chun-Li perdeu.
	if winner_number == 2:
		_open_player_defeat_screen()
		return

	# Mantém o comportamento atual quando
	# Chun-Li vence a luta.
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

func _start_round_intro() -> void:
	_set_mp_regeneration_enabled(false)
	if _round_intro_in_progress:
		return

	if match_finished:
		return

	_round_intro_in_progress = true

	# Primeiro escolhe Entry ou Idle.
	# Isso precisa acontecer antes de desativar
	# o processamento das StateMachines.
	_prepare_round_intro_states()

	player_1.velocity = Vector2.ZERO
	player_2.velocity = Vector2.ZERO

	# Agora trava os estados, a IA e os inputs.
	_set_round_intro_locked(true)

	hud.prepare_round_intro()

	for countdown_value in range(
		round_countdown_start,
		0,
		-1
	):
		hud.show_countdown(
			countdown_value
		)

		await get_tree().create_timer(
			countdown_step_duration,
			false
		).timeout

	# Descarta comandos pressionados durante
	# READY? 3, 2 e 1.
	_clear_character_input_buffer(
		player_1
	)

	_clear_character_input_buffer(
		player_2
	)

	# Exibe LUTEM! antes de liberar os personagens.
	hud.show_fight_message()

	# Garante pelo menos um frame com LUTEM!
	# visível antes da liberação.
	await get_tree().process_frame

	# No primeiro round:
	# Entry → Idle.
	#
	# Nos outros:
	# permanece em Idle.
	_release_round_intro_states()

	# Libera StateMachines, DummyAI e InputBuffers.
	_set_round_intro_locked(false)

	_set_mp_regeneration_enabled(true)

	# O cronômetro só começa depois de LUTEM!
	hud.start_round(
		player_1_wins,
		player_2_wins
	)

	await get_tree().create_timer(
		fight_message_duration,
		false
	).timeout

	hud.hide_round_message()

	_round_intro_in_progress = false

func _set_round_intro_locked(
	locked: bool
) -> void:
	var selected_process_mode: ProcessMode

	if locked:
		selected_process_mode = (
			Node.PROCESS_MODE_DISABLED
		)
	else:
		selected_process_mode = (
			Node.PROCESS_MODE_INHERIT
		)

	if player_1_state_machine != null:
		player_1_state_machine.process_mode = (
			selected_process_mode
		)

	if player_2_state_machine != null:
		player_2_state_machine.process_mode = (
			selected_process_mode
		)

	if dummy_ai != null:
		dummy_ai.process_mode = (
			selected_process_mode
		)

	# O jogador pode receber inputs quando
	# a introdução terminar.
	# Player humano:
	# bloqueado durante a intro,
	# liberado quando a luta começa.
	_set_character_input_buffer_locked(
		player_1,
		locked
	)

	# CPU nunca deve ler inputs humanos.
	_set_character_input_buffer_locked(
		player_2,
		true
	)

func _set_character_input_buffer_locked(
	character: CharacterBody2D,
	locked: bool
) -> void:
	if character == null:
		return

	var input_buffer := (
		character.find_child(
			"InputBuffer",
			true,
			false
		)
		as InputBuffer
	)

	if input_buffer == null:
		return

	input_buffer.clear_buffer()

	if locked:
		input_buffer.process_mode = (
			Node.PROCESS_MODE_DISABLED
		)
	else:
		input_buffer.process_mode = (
			Node.PROCESS_MODE_INHERIT
		)

func _clear_character_input_buffer(
	character: CharacterBody2D
) -> void:
	if character == null:
		return

	var input_buffer := (
		character.find_child(
			"InputBuffer",
			true,
			false
		)
		as InputBuffer
	)

	if input_buffer != null:
		input_buffer.clear_buffer()

func _transition_to_next_round() -> void:
	if hud == null:
		printerr(
			"FightManager: HUD não encontrada."
		)
		return

	# Escurece enquanto os lutadores continuam
	# presos nos estados finais do round.
	await hud.fade_to_black(
		fade_to_black_duration
	)

	# A partir deste ponto, tudo está oculto.
	hud.hide_round_message()

	_reset_next_round_behind_black()

	if black_screen_hold_duration > 0.0:
		await get_tree().create_timer(
			black_screen_hold_duration
		).timeout

	# Revela os personagens já resetados.
	await hud.fade_from_black(
		fade_from_black_duration
	)

	# A contagem começa somente depois
	# que a tela voltou.
	await _start_round_intro()

func _prepare_round_intro_states() -> void:
	var player_intro_state: StringName = &"Idle"
	var cpu_intro_state: StringName = &"Idle"

	if current_round_number == 1:
		# ==========================================
		# ENTRY PADRÃO DE TODOS OS PERSONAGENS
		# ==========================================

		if (
			player_1_state_machine != null
			and player_1_state_machine.has_state(
				&"Entry"
			)
		):
			player_intro_state = &"Entry"

		if (
			player_2_state_machine != null
			and player_2_state_machine.has_state(
				&"Entry"
			)
		):
			cpu_intro_state = &"Entry"


		# ==========================================
		# CHUN-LI
		# Possui preparação especial de posição
		# antes da animação Entry.
		# ==========================================

		# PLAYER É CHUN-LI
		if (
			FighterSelection.player_fighter
			== FighterSelection.Fighter.CHUN_LI
		):
			player_intro_state = (
				_prepare_chun_li_entry(
					player_1,
					player_1_state_machine,
					player_1_start_position,
					false
				)
			)

		# CPU É CHUN-LI
		if (
			FighterSelection.opponent_fighter
			== FighterSelection.Fighter.CHUN_LI
		):
			cpu_intro_state = (
				_prepare_chun_li_entry(
					player_2,
					player_2_state_machine,
					player_2_start_position,
					true
				)
			)


	# ==========================================
	# APLICA OS ESTADOS
	# ==========================================

	_set_character_intro_state(
		player_1_state_machine,
		player_intro_state,
		"Player 1"
	)

	_set_character_intro_state(
		player_2_state_machine,
		cpu_intro_state,
		"Player 2"
	)

func _set_character_intro_state(
	state_machine: StateMachine,
	intro_state: StringName,
	character_name: String
) -> void:
	if state_machine == null:
		printerr(
			"FightManager: StateMachine não encontrada para ",
			character_name
		)
		return

	if not state_machine.has_state(intro_state):
		printerr(
			"FightManager: estado [",
			intro_state,
			"] não encontrado em ",
			character_name
		)
		return

	state_machine.force_transition(
		intro_state
	)

	print(
		character_name,
		" aguardando início do round no estado ",
		intro_state
	)

func _release_round_intro_states() -> void:
	# Garante que a Chun-Li esteja exatamente na
	# start position, mesmo que a animação não tenha
	# alcançado o frame 19 por alguma razão.
	if current_round_number == 1:
		if (
			FighterSelection.player_fighter
			== FighterSelection.Fighter.CHUN_LI
			and player_1 != null
			and player_1.has_method(
				"finish_entry_motion"
			)
		):
			player_1.call(
				"finish_entry_motion"
			)

		if (
			FighterSelection.opponent_fighter
			== FighterSelection.Fighter.CHUN_LI
			and player_2 != null
			and player_2.has_method(
				"finish_entry_motion"
			)
		):
			player_2.call(
				"finish_entry_motion"
			)

	_release_character_intro_state(
		player_1_state_machine,
		"Player 1"
	)

	_release_character_intro_state(
		player_2_state_machine,
		"Player 2"
	)


func _release_character_intro_state(
	state_machine: StateMachine,
	character_name: String
) -> void:
	if state_machine == null:
		return

	var current_state: StringName = (
		state_machine.get_current_state_name()
	)

	# No primeiro round, sai de Entry.
	# Nos rounds seguintes, já estará em Idle.
	if current_state == &"Entry":
		if not state_machine.has_state(&"Idle"):
			printerr(
				"FightManager: Idle não encontrado em ",
				character_name
			)
			return

		state_machine.force_transition(
			&"Idle"
		)

func _set_mp_regeneration_enabled(
	enabled: bool
) -> void:
	if player_1_mp != null:
		player_1_mp.set_regeneration_enabled(
			enabled
		)

	if player_2_mp != null:
		player_2_mp.set_regeneration_enabled(
			enabled
		)

func _open_player_defeat_screen() -> void:
	if player_defeat_scene_path.is_empty():
		printerr(
			"FightManager: caminho da tela de derrota vazio."
		)
		return

	if not ResourceLoader.exists(
		player_defeat_scene_path
	):
		printerr(
			"FightManager: tela de derrota não encontrada: ",
			player_defeat_scene_path
		)
		return

	# Evita carregar a nova cena ainda pausada.
	get_tree().paused = false

	var change_error: Error = (
		get_tree().change_scene_to_file(
			player_defeat_scene_path
		)
	)

	if change_error != OK:
		printerr(
			"FightManager: erro ao abrir tela de derrota: ",
			change_error
		)



func _spawn_selected_fighters() -> void:
	var player_scene: PackedScene = (
		_get_fighter_scene(
			FighterSelection.player_fighter
		)
	)

	var cpu_scene: PackedScene = (
		_get_fighter_scene(
			FighterSelection.opponent_fighter
		)
	)

	print(
		"SELEÇÃO DA LUTA | Player: ",
		FighterSelection.player_fighter,
		" | CPU: ",
		FighterSelection.opponent_fighter
	)

	if player_scene == null:
		printerr(
			"FightManager: cena do Player não configurada."
		)
		return

	if cpu_scene == null:
		printerr(
			"FightManager: cena da CPU não configurada."
		)
		return

	var player_instance := (
		player_scene.instantiate()
		as CharacterBody2D
	)

	var cpu_instance := (
		cpu_scene.instantiate()
		as CharacterBody2D
	)

	if player_instance == null:
		printerr(
			"FightManager: Player não é CharacterBody2D."
		)
		return

	if cpu_instance == null:
		printerr(
			"FightManager: CPU não é CharacterBody2D."
		)

		player_instance.queue_free()
		return

	player_instance.name = "Player1"
	cpu_instance.name = "Dummy"

	add_child(player_instance)
	add_child(cpu_instance)

	# Agora guardamos diretamente as instâncias.
	player_1 = player_instance
	player_2 = cpu_instance

	# Busca StateMachine, Health, MP, DummyAI etc.
	_cache_fighter_components()

	var player_spawn := (
		get_node_or_null(
			"PlayerSpawn"
		)
		as Marker2D
	)

	var dummy_spawn := (
		get_node_or_null(
			"DummySpawn"
		)
		as Marker2D
	)

	if player_spawn != null:
		player_1.global_position = (
			player_spawn.global_position
		)

	if dummy_spawn != null:
		player_2.global_position = (
			dummy_spawn.global_position
		)

	_apply_mirror_match_color(
		player_1,
		player_2
	)

	print(
		"PLAYER INSTANCIADO: ",
		player_scene.resource_path
	)

	print(
		"CPU INSTANCIADA: ",
		cpu_scene.resource_path
	)

func _get_fighter_scene(
	fighter: FighterSelection.Fighter
) -> PackedScene:
	match fighter:
		FighterSelection.Fighter.CHUN_LI:
			return chun_li_scene

		FighterSelection.Fighter.ELENA:
			return elena_scene

		FighterSelection.Fighter.MORRIGAN:
			return morrigan_scene

		FighterSelection.Fighter.ZANGIEF:
			return zangief_scene

		FighterSelection.Fighter.POTEMKIN:
			return potemkin_scene

	return null

func _apply_mirror_match_color(
	player: CharacterBody2D,
	cpu: CharacterBody2D
) -> void:
	if player == null or cpu == null:
		return

	# Personagens diferentes.
	if not FighterSelection.is_mirror_match():
		cpu.modulate = Color.WHITE
		return

	# Mesmo personagem.
	cpu.modulate = mirror_cpu_color

func _cache_fighter_components() -> void:
	if player_1 == null:
		printerr(
			"FightManager: Player1 é nulo."
		)
		return

	if player_2 == null:
		printerr(
			"FightManager: Dummy é nulo."
		)
		return

	player_facing = (
		player_1.get_node_or_null(
			"FacingController"
		)
		as FacingController
	)

	dummy_facing = (
		player_2.get_node_or_null(
			"FacingController"
		)
		as FacingController
	)

	player_1_health = (
		player_1.get_node_or_null(
			"Health"
		)
		as Health
	)

	player_2_health = (
		player_2.get_node_or_null(
			"Health"
		)
		as Health
	)

	player_1_mp = (
		player_1.get_node_or_null(
			"MagicPoints"
		)
		as MagicPoints
	)

	player_2_mp = (
		player_2.get_node_or_null(
			"MagicPoints"
		)
		as MagicPoints
	)

	player_1_state_machine = (
		player_1.get_node_or_null(
			"StateMachine"
		)
		as StateMachine
	)

	player_2_state_machine = (
		player_2.get_node_or_null(
			"StateMachine"
		)
		as StateMachine
	)

	player_ai = (
		player_1.find_child(
			"DummyAI",
			true,
			false
		) as DummyAI
	)

	dummy_ai = (
		player_2.find_child(
			"DummyAI",
			true,
			false
		)
		as DummyAI
	)

	print(
		"FightManager: componentes carregados."
	)

	print(
		"Player1: ",
		player_1.name
	)

	print(
		"Dummy: ",
		player_2.name
	)

	print(
		"DummyAI encontrada: ",
		dummy_ai != null
	)


func _get_chun_li_entry_position(
	as_dummy: bool
) -> Vector2:
	if chun_li_entry_spawn == null:
		return Vector2.ZERO

	if not as_dummy:
		return chun_li_entry_spawn.global_position

	if (
		player_spawn == null
		or dummy_spawn == null
	):
		return chun_li_entry_spawn.global_position

	var arena_center_x: float = (
		player_spawn.global_position.x
		+ dummy_spawn.global_position.x
	) * 0.5

	var original_position: Vector2 = (
		chun_li_entry_spawn.global_position
	)

	var mirrored_position := Vector2(
		(2.0 * arena_center_x)
		- original_position.x,
		original_position.y
	)

	return mirrored_position

func _prepare_chun_li_entry(
	character: CharacterBody2D,
	state_machine: StateMachine,
	final_position: Vector2,
	as_dummy: bool
) -> StringName:
	if character == null:
		return &"Idle"

	if state_machine == null:
		return &"Idle"

	if not state_machine.has_state(&"Entry"):
		return &"Idle"

	if not character.has_method(
		"start_entry_motion"
	):
		return &"Idle"

	var entry_position: Vector2 = (
		_get_chun_li_entry_position(
			as_dummy
		)
	)

	character.call(
		"start_entry_motion",
		entry_position,
		final_position,
		0,
		19
	)

	print(
		"Entrada Chun-Li | ",
		"Dummy" if as_dummy else "Player",
		" | início: ",
		entry_position,
		" | destino: ",
		final_position
	)

	return &"Entry"

func _configure_fighter_ai() -> void:
	# O personagem escolhido no CharacterSelect
	# é sempre controlado pelo jogador.
	if player_ai != null:
		player_ai.active = false

		player_ai.process_mode = (
			Node.PROCESS_MODE_DISABLED
		)

	# O personagem escolhido no OpponentSelect
	# é sempre controlado pela CPU.
	if dummy_ai != null:
		dummy_ai.active = true

		dummy_ai.process_mode = (
			Node.PROCESS_MODE_INHERIT
		)

		dummy_ai.setup(
			player_1
		)

		print(
			"DummyAI ativada no oponente: ",
			player_2.name
		)
	else:
		printerr(
			"FightManager: personagem escolhido no "
			+ "OpponentSelect não possui DummyAI."
		)

func _connect_guard_ui() -> void:
	if player_1 != null:
		var player_changed := Callable(
			hud,
			"update_player_guard"
		)

		var player_broken := Callable(
			hud,
			"break_player_guard"
		)

		if player_1.has_signal(
			"guard_changed"
		):
			if not player_1.is_connected(
				"guard_changed",
				player_changed
			):
				player_1.connect(
					"guard_changed",
					player_changed
				)

		if player_1.has_signal(
			"guard_broken"
		):
			if not player_1.is_connected(
				"guard_broken",
				player_broken
			):
				player_1.connect(
					"guard_broken",
					player_broken
				)


	if player_2 != null:
		var dummy_changed := Callable(
			hud,
			"update_dummy_guard"
		)

		var dummy_broken := Callable(
			hud,
			"break_dummy_guard"
		)

		if player_2.has_signal(
			"guard_changed"
		):
			if not player_2.is_connected(
				"guard_changed",
				dummy_changed
			):
				player_2.connect(
					"guard_changed",
					dummy_changed
				)

		if player_2.has_signal(
			"guard_broken"
		):
			if not player_2.is_connected(
				"guard_broken",
				dummy_broken
			):
				player_2.connect(
					"guard_broken",
					dummy_broken
				)

func _connect_guard_indicators() -> void:
	if player_1 == null:
		printerr(
			"FightManager: Player1 nulo ao conectar Guard UI."
		)
	else:
		if player_1.has_signal(
			&"guard_changed"
		):
			player_1.connect(
				&"guard_changed",
				Callable(
					player_guard_indicator,
					"update_guard"
				)
			)

			print(
				"Guard UI conectada ao Player1."
			)
		else:
			printerr(
				"Player1 não possui signal guard_changed."
			)

		if player_1.has_signal(
			&"guard_broken"
		):
			player_1.connect(
				&"guard_broken",
				Callable(
					player_guard_indicator,
					"break_guard"
				)
			)

		if player_1.has_signal(
			&"guard_reset"
		):
			player_1.connect(
				&"guard_reset",
				Callable(
					player_guard_indicator,
					"reset_guard"
				)
			)


	if player_2 == null:
		printerr(
			"FightManager: Dummy nulo ao conectar Guard UI."
		)
	else:
		if player_2.has_signal(
			&"guard_changed"
		):
			player_2.connect(
				&"guard_changed",
				Callable(
					dummy_guard_indicator,
					"update_guard"
				)
			)

			print(
				"Guard UI conectada ao Dummy."
			)
		else:
			printerr(
				"Dummy não possui signal guard_changed."
			)

		if player_2.has_signal(
			&"guard_broken"
		):
			player_2.connect(
				&"guard_broken",
				Callable(
					dummy_guard_indicator,
					"break_guard"
				)
			)

		if player_2.has_signal(
			&"guard_reset"
		):
			player_2.connect(
				&"guard_reset",
				Callable(
					dummy_guard_indicator,
					"reset_guard"
				)
			)

func _spawn_selected_arena() -> ArenaVisual:
	var arena_scene: PackedScene = (
		_get_arena_scene(
			ArenaSelection.selected_arena
		)
	)

	if arena_scene == null:
		printerr(
			"FightManager: arena selecionada não configurada."
		)
		return null

	var arena_instance := (
		arena_scene.instantiate()
		as ArenaVisual
	)

	if arena_instance == null:
		printerr(
			"FightManager: a cena da arena não usa ArenaVisual.gd."
		)
		return null

	arena_holder.add_child(
		arena_instance
	)

	print(
		"ARENA INSTANCIADA: ",
		arena_instance.name
	)

	return arena_instance

func _get_arena_scene(
	arena: int
) -> PackedScene:
	match arena:
		ArenaSelection.Arena.ARENA_01:
			return arena_01_scene

		ArenaSelection.Arena.ARENA_02:
			return arena_02_scene

		ArenaSelection.Arena.ARENA_03:
			return arena_03_scene

		ArenaSelection.Arena.ARENA_04:
			return arena_04_scene

		ArenaSelection.Arena.ARENA_05:
			return arena_05_scene

		ArenaSelection.Arena.ARENA_06:
			return arena_06_scene

	return null

func _play_arena_music(
	arena: ArenaVisual
) -> void:
	if arena_music_player == null:
		printerr(
			"FightManager: ArenaMusicPlayer não encontrado."
		)
		return

	if arena == null:
		return

	if arena.arena_music == null:
		printerr(
			"FightManager: arena ",
			arena.name,
			" não possui música configurada."
		)
		return

	arena_music_player.stop()

	arena_music_player.stream = (
		arena.arena_music
	)

	arena_music_player.play()

	print(
		"MÚSICA DA ARENA: ",
		arena.arena_music.resource_path
	)

func _lock_health_round_result(
	winner: CharacterBody2D,
	loser: CharacterBody2D
) -> void:
	# Vencedor apenas permanece parado em Idle.
	_lock_character_result(
		winner,
		&"Idle"
	)

	# Perdedor permanece em FallDefeated.
	_lock_character_result(
		loser,
		&"FallDefeated"
	)

func _freeze_combat_after_round_end() -> void:
	# Limpa os comandos e impede novos inputs
	# durante a tela de resultado.
	_set_character_input_buffer_locked(
		player_1,
		true
	)

	_set_character_input_buffer_locked(
		player_2,
		true
	)

	_disable_character_hitboxes(
		player_1
	)

	_disable_character_hitboxes(
		player_2
	)

	if dummy_ai != null:
		dummy_ai.reset_for_round_transition()

	if player_ai != null:
		player_ai.reset_for_round_transition()

func _disable_character_hitboxes(
	character: CharacterBody2D
) -> void:
	if character == null:
		return

	var hitboxers := (
		character.get_node_or_null(
			"Hitboxers"
		)
	)

	if hitboxers == null:
		return

	_disable_hitboxes_recursive(
		hitboxers
	)


func _disable_hitboxes_recursive(
	node: Node
) -> void:
	if node is HitBox:
		var hitbox := node as HitBox

		hitbox.disable()

	for child in node.get_children():
		_disable_hitboxes_recursive(
			child
		)
