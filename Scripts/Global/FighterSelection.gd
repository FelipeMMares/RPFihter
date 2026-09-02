extends Node


enum Fighter {
	CHUN_LI,
	ELENA,
	MORRIGAN,
	ZANGIEF,
	POTEMKIN
}


const ENABLED_FIGHTERS: Array[Fighter] = [
	Fighter.CHUN_LI,
	Fighter.ELENA,
	Fighter.MORRIGAN,
	Fighter.ZANGIEF
]


var player_fighter: Fighter = Fighter.CHUN_LI
var opponent_fighter: Fighter = Fighter.ELENA


func select_player(
	fighter: Fighter
) -> void:
	if not is_fighter_enabled(fighter):
		printerr(
			"FighterSelection: tentativa de selecionar "
			+ "lutador bloqueado para Player: ",
			Fighter.keys()[fighter]
		)

		return

	player_fighter = fighter

	print(
		"FighterSelection | Player selecionado: ",
		Fighter.keys()[player_fighter]
	)


func select_opponent(
	fighter: Fighter
) -> void:
	if not is_fighter_enabled(fighter):
		printerr(
			"FighterSelection: tentativa de selecionar "
			+ "lutador bloqueado para CPU: ",
			Fighter.keys()[fighter]
		)

		return

	opponent_fighter = fighter

	print(
		"FighterSelection | Oponente selecionado: ",
		Fighter.keys()[opponent_fighter]
	)


func is_fighter_enabled(
	fighter: Fighter
) -> bool:
	return fighter in ENABLED_FIGHTERS


func get_enabled_fighters() -> Array[Fighter]:
	return ENABLED_FIGHTERS.duplicate()


func sanitize_selections() -> void:
	if not is_fighter_enabled(player_fighter):
		player_fighter = Fighter.CHUN_LI

	if not is_fighter_enabled(opponent_fighter):
		opponent_fighter = Fighter.ELENA


func is_mirror_match() -> bool:
	return player_fighter == opponent_fighter
