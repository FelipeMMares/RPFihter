extends Control


@export_file("*.tscn")
var fight_scene_path: String = (
	"res://Cenas/Cenarios/CenaDaLuta.tscn"
)


@onready var chun_li_button: Button = (
	$HBoxContainer/ChunLiButton
)

@onready var elena_button: Button = (
	$HBoxContainer/ElenaButton
)


func _ready() -> void:
	get_tree().paused = false

	chun_li_button.pressed.connect(
		_on_chun_li_pressed
	)

	elena_button.pressed.connect(
		_on_elena_pressed
	)

	chun_li_button.grab_focus()


func _on_chun_li_pressed() -> void:
	FighterSelection.select_chun_li()

	_start_fight()


func _on_elena_pressed() -> void:
	FighterSelection.select_elena()

	_start_fight()


func _start_fight() -> void:
	var error := get_tree().change_scene_to_file(
		fight_scene_path
	)

	if error != OK:
		printerr(
			"CharacterSelect: erro ao abrir luta: ",
			error
		)
