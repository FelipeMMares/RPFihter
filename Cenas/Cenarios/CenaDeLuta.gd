extends Node2D

@onready var player: CharacterBody2D = $Player1
@onready var dummy: CharacterBody2D = $Dummy
@onready var hud: FightHUD = $HUD


func _ready() -> void:
	hud.setup(
		player.get_node("Health"),
		dummy.get_node("Health")
	)
