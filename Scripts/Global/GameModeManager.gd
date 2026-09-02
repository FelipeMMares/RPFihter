extends Node


enum GameMode {
	NONE,
	VERSUS,
	CAMPAIGN
}


var current_mode: GameMode = GameMode.NONE


func set_mode(
	mode: GameMode
) -> void:
	current_mode = mode


func is_versus() -> bool:
	return current_mode == GameMode.VERSUS


func is_campaign() -> bool:
	return current_mode == GameMode.CAMPAIGN
