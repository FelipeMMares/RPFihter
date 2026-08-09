extends Node2D
class_name FightManager

@export_group("Personagens")

@export var chun_li_scene: PackedScene
@export var elena_scene: PackedScene

@export_group("Mirror Match")

@export var mirror_cpu_color: Color = Color(
	0.65,
	0.80,
	1.0,
	1.0
)

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

@onready var player_1: CharacterBody2D = $Player1
@onready var player_2: CharacterBody2D = $Dummy

@onready var hud: FightHUD = $HUD
@onready var player_ai: DummyAI = (
	$Player1.get_node_or_null("DummyAI")
	as DummyAI
)

@onready var dummy_ai: DummyAI = (
	$Dummy.get_node_or_null("DummyAI")
	as DummyAI
)


@export_group("Telas")

@export_file("*.tscn")
var player_defeat_scene_path: String = (
	"res://Cenas/DefeatScreen/DefeatScreen.tscn"
)

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

@onready var player_1_mp: MagicPoints = (
	$Player1/MagicPoints
)

@onready var player_2_mp: MagicPoints = (
	$Dummy/MagicPoints
)

@onready var player_1_state_machine: StateMachine = (
	$Player1/StateMachine
)

@onready var player_2_state_machine: StateMachine = (
	$Dummy/StateMachine
)

@onready var player_1_entry_spawn: Marker2D = (
	$Player1EntrySpawn
)

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
	player_1_start_position = player_1.global_position
	player_2_start_position = player_2.global_position

	if player_1_state_machine != null:
		player_1_state_machine.set_player_input_enabled(
			true
		)

	if player_2_state_machine != null:
		player_2_state_machine.set_player_input_enabled(
			false
		)


	if player_ai != null:
		player_ai.active = false
		player_ai.process_mode = (
			Node.PROCESS_MODE_DISABLED
		)


	if dummy_ai != null:
		dummy_ai.active = true
		dummy_ai.process_mode = (
			Node.PROCESS_MODE_INHERIT
		)

	dummy_ai.setup(player_1)

	_set_mp_regeneration_enabled(false)

	# O personagem escolhido pelo jogador nunca
	# deve ser controlado pela IA.
	if player_ai != null:
		player_ai.active = false
		player_ai.process_mode = (
			Node.PROCESS_MODE_DISABLED
		)

	# O personagem do lado Dummy é sempre a CPU.
	if dummy_ai != null:
		dummy_ai.active = true
		dummy_ai.process_mode = (
			Node.PROCESS_MODE_INHERIT
		)

		dummy_ai.setup(player_1)
	else:
		printerr(
			"FightManager: DummyAI não encontrada na CPU."
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

	hud.set_timer_enabled(true)
	hud.set_sudden_death_mode(false)


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
	_set_mp_regeneration_enabled(false)
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

	hud.stop_round_timer()
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

	# Somente no primeiro round tentamos usar Entry.
	if current_round_number == 1:
		if (
			player_1_state_machine != null
			and player_1_state_machine.has_state(&"Entry")
		):
			player_intro_state = &"Entry"

			# Alguns personagens podem possuir uma
			# entrada com deslocamento, como Chun-Li.
			if (
				player_1_entry_spawn != null
				and player_1.has_method(
					"start_entry_motion"
				)
			):
				player_1.call(
					"start_entry_motion",
					player_1_entry_spawn.global_position,
					player_1_start_position,
					0,
					19
				)

	# O jogador usa Entry, quando disponível.
	_set_character_intro_state(
		player_1_state_machine,
		player_intro_state,
		"Player 1"
	)

	# A CPU aguarda parada.
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
	if (
		current_round_number == 1
		and player_1.has_method("finish_entry_motion")
	):
		player_1.call("finish_entry_motion")

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

func _enter_tree() -> void:
	_spawn_selected_fighters()

func _spawn_selected_fighters() -> void:
	var player_scene: PackedScene = _get_fighter_scene(
		FighterSelection.player_fighter
	)

	var cpu_scene: PackedScene = _get_fighter_scene(
		FighterSelection.opponent_fighter
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

	var player_spawn := (
		get_node_or_null("PlayerSpawn")
		as Marker2D
	)

	var dummy_spawn := (
		get_node_or_null("DummySpawn")
		as Marker2D
	)

	if player_spawn != null:
		player_instance.global_position = (
			player_spawn.global_position
		)

	if dummy_spawn != null:
		cpu_instance.global_position = (
			dummy_spawn.global_position
		)

	_apply_mirror_match_color(
		player_instance,
		cpu_instance
	)

func _get_fighter_scene(
	fighter: FighterSelection.Fighter
) -> PackedScene:
	match fighter:
		FighterSelection.Fighter.CHUN_LI:
			return chun_li_scene

		FighterSelection.Fighter.ELENA:
			return elena_scene

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
