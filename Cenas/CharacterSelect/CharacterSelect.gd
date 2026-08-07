extends Control


@export_file("*.tscn")
var fight_scene_path: String = (
	"res://Cenas/Cenarios/CenaDaLuta.tscn"
)


@onready var chun_li_button: Button = (
	$CenterContainer/VBoxContainer/CharacterGrid/ChunLiButton
)

@onready var elena_button: Button = (
	$CenterContainer/VBoxContainer/CharacterGrid/ElenaButton
)

@onready var locked_button_1: Button = (
	$CenterContainer/VBoxContainer/CharacterGrid/LockedButton1
)

@onready var locked_button_2: Button = (
	$CenterContainer/VBoxContainer/CharacterGrid/LockedButton2
)

@onready var locked_button_3: Button = (
	$CenterContainer/VBoxContainer/CharacterGrid/LockedButton3
)

@onready var locked_button_4: Button = (
	$CenterContainer/VBoxContainer/CharacterGrid/LockedButton4
)

@onready var locked_button_5: Button = (
	$CenterContainer/VBoxContainer/CharacterGrid/LockedButton5
)

@onready var locked_button_6: Button = (
	$CenterContainer/VBoxContainer/CharacterGrid/LockedButton6
)

@onready var update_message: Label = (
	$CenterContainer/VBoxContainer/UpdateMessage
)

@onready var message_timer: Timer = (
	$MessageTimer
)


func _ready() -> void:
	get_tree().paused = false

	update_message.visible = false

	chun_li_button.pressed.connect(
		_on_chun_li_pressed
	)

	elena_button.pressed.connect(
		_on_elena_pressed
	)

	locked_button_1.pressed.connect(
		_on_locked_character_pressed
	)

	locked_button_2.pressed.connect(
		_on_locked_character_pressed
	)

	locked_button_3.pressed.connect(
		_on_locked_character_pressed
	)

	locked_button_4.pressed.connect(
		_on_locked_character_pressed
	)

	locked_button_5.pressed.connect(
		_on_locked_character_pressed
	)

	locked_button_6.pressed.connect(
		_on_locked_character_pressed
	)

	message_timer.timeout.connect(
		_on_message_timer_timeout
	)

	chun_li_button.grab_focus()


func _on_chun_li_pressed() -> void:
	FighterSelection.select_chun_li()

	_start_fight()


func _on_elena_pressed() -> void:
	FighterSelection.select_elena()

	_start_fight()


func _on_locked_character_pressed() -> void:
	update_message.text = (
		"AGUARDE A ATUALIZAÇÃO"
	)

	update_message.visible = true

	message_timer.start()


func _on_message_timer_timeout() -> void:
	update_message.visible = false


func _start_fight() -> void:
	var error: Error = (
		get_tree().change_scene_to_file(
			fight_scene_path
		)
	)

	if error != OK:
		printerr(
			"CharacterSelect: erro ao abrir luta: ",
			error
		)
