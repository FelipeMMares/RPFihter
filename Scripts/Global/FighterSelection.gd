extends Node


enum Fighter {
	CHUN_LI,
	ELENA
}


var player_fighter: Fighter = Fighter.CHUN_LI
var opponent_fighter: Fighter = Fighter.ELENA


func select_player(
	fighter: Fighter
) -> void:
	player_fighter = fighter

	print(
		"FighterSelection | Player selecionado: ",
		player_fighter
	)


func select_opponent(
	fighter: Fighter
) -> void:
	opponent_fighter = fighter

	print(
		"FighterSelection | Oponente selecionado: ",
		opponent_fighter
	)


func is_mirror_match() -> bool:
	return player_fighter == opponent_fighter
