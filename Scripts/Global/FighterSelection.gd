extends Node


enum Fighter {
	CHUN_LI,
	ELENA
}


var selected_fighter: Fighter = Fighter.CHUN_LI


func select_chun_li() -> void:
	selected_fighter = Fighter.CHUN_LI


func select_elena() -> void:
	selected_fighter = Fighter.ELENA


func get_opponent() -> Fighter:
	if selected_fighter == Fighter.CHUN_LI:
		return Fighter.ELENA

	return Fighter.CHUN_LI
