extends Node


const PREPARATION_SCENE_PATH: String = (
	"res://Cenas/PreparationScreen/PreparationScreen.tscn"
)


var active: bool = false

var current_fight_index: int = 0


var opponent_order: Array[int] = []

var arena_order: Array[int] = []


func start_campaign() -> void:
	reset_campaign()

	active = true

	_build_opponent_order()
	_build_arena_order()

	if opponent_order.is_empty():
		printerr(
			"CampaignManager: nenhum oponente disponível."
		)

		active = false
		return

	if arena_order.size() < opponent_order.size():
		printerr(
			"CampaignManager: arenas insuficientes."
		)

		active = false
		return

	_apply_current_fight()

	print(
		"=== CAMPANHA INICIADA ==="
	)

	print(
		"Player: ",
		FighterSelection.Fighter.keys()[
			FighterSelection.player_fighter
		]
	)

	print_campaign()


func _build_opponent_order() -> void:
	opponent_order.clear()

	# Somente os quatro personagens liberados.
	opponent_order = [
		FighterSelection.Fighter.CHUN_LI,
		FighterSelection.Fighter.ELENA,
		FighterSelection.Fighter.MORRIGAN,
		FighterSelection.Fighter.ZANGIEF
	]

	# Impede mirror match na campanha.
	opponent_order.erase(
		FighterSelection.player_fighter
	)

	# Sorteia a ordem.
	opponent_order.shuffle()


func _build_arena_order() -> void:
	arena_order.clear()

	arena_order = [
		ArenaSelection.Arena.ARENA_01,
		ArenaSelection.Arena.ARENA_02,
		ArenaSelection.Arena.ARENA_03,
		ArenaSelection.Arena.ARENA_04,
		ArenaSelection.Arena.ARENA_05,
		ArenaSelection.Arena.ARENA_06
	]

	# Sorteia uma única vez.
	# Como cada posição será usada uma vez,
	# não teremos arenas repetidas.
	arena_order.shuffle()


func _apply_current_fight() -> void:
	if not active:
		return

	if (
		current_fight_index < 0
		or current_fight_index
		>= opponent_order.size()
	):
		return

	FighterSelection.select_opponent(
		opponent_order[
			current_fight_index
		]
	)

	ArenaSelection.select_arena(
		arena_order[
			current_fight_index
		]
	)

	print(
		"CAMPAIGN | Luta ",
		current_fight_index + 1,
		"/",
		opponent_order.size(),
		" | Oponente: ",
		FighterSelection.Fighter.keys()[
			opponent_order[
				current_fight_index
			]
		],
		" | Arena: ",
		ArenaSelection.Arena.keys()[
			arena_order[
				current_fight_index
			]
		]
	)


func open_current_fight() -> void:
	if not active:
		printerr(
			"CampaignManager: campanha não está ativa."
		)
		return

	if (
		current_fight_index < 0
		or current_fight_index
		>= opponent_order.size()
	):
		printerr(
			"CampaignManager: índice de luta inválido."
		)
		return

	_apply_current_fight()

	if not ResourceLoader.exists(
		PREPARATION_SCENE_PATH
	):
		printerr(
			"CampaignManager: PreparationScreen não encontrada."
		)
		return

	get_tree().paused = false

	var error: Error = (
		get_tree().change_scene_to_file(
			PREPARATION_SCENE_PATH
		)
	)

	if error != OK:
		printerr(
			"CampaignManager: erro ao abrir PreparationScreen: ",
			error
		)


func has_next_fight() -> bool:
	if not active:
		return false

	return (
		current_fight_index + 1
		< opponent_order.size()
	)


func advance_after_victory() -> bool:
	if not active:
		return false

	if not has_next_fight():
		return false

	current_fight_index += 1

	_apply_current_fight()

	return true


func get_current_fight_number() -> int:
	return current_fight_index + 1


func get_total_fights() -> int:
	return opponent_order.size()


func get_current_opponent() -> int:
	if opponent_order.is_empty():
		return FighterSelection.Fighter.CHUN_LI

	return opponent_order[
		current_fight_index
	]


func get_current_arena() -> int:
	if arena_order.is_empty():
		return ArenaSelection.Arena.ARENA_01

	return arena_order[
		current_fight_index
	]


func complete_campaign() -> void:
	print(
		"CAMPAIGN | CAMPANHA CONCLUÍDA!"
	)

	active = false


func fail_campaign() -> void:
	print(
		"CAMPAIGN | CAMPANHA ENCERRADA POR DERROTA."
	)

	active = false


func reset_campaign() -> void:
	active = false

	current_fight_index = 0

	opponent_order.clear()
	arena_order.clear()


func print_campaign() -> void:
	print(
		"========== CAMPANHA =========="
	)

	print(
		"Player: ",
		FighterSelection.Fighter.keys()[
			FighterSelection.player_fighter
		]
	)

	for index in range(
		opponent_order.size()
	):
		print(
			"Luta ",
			index + 1,
			" | ",
			FighterSelection.Fighter.keys()[
				opponent_order[index]
			],
			" | ",
			ArenaSelection.Arena.keys()[
				arena_order[index]
			]
		)

	print(
		"=============================="
	)
