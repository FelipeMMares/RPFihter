extends Node


enum Arena {
	ARENA_01,
	ARENA_02,
	ARENA_03,
	ARENA_04,
	ARENA_05,
	ARENA_06
}


var selected_arena: Arena = Arena.ARENA_01


func select_arena(
	arena: Arena
) -> void:
	selected_arena = arena
