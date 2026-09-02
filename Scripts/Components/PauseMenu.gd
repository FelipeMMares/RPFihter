extends Control


const CHARACTER_SELECT_SCENE_PATH: String = (
	"res://Cenas/CharacterSelect/CharacterSelect.tscn"
)

const ARENA_SELECT_SCENE_PATH: String = (
	"res://Cenas/ArenaSelection/ArenaSelection.tscn"
)


@export var pause_action: StringName = &"pause"


@onready var title: Label = (
	$Background/MenuPosition/Title
)

@onready var continue_button: Button = (
	$Background/MenuPosition/VBoxContainer/ContinueButton
)

@onready var character_select_button: Button = (
	$Background/MenuPosition/VBoxContainer/CharacterSelectButton
)

@onready var arena_select_button: Button = (
	$Background/MenuPosition/VBoxContainer/ArenaSelectButton
)

@onready var restart_button: Button = (
	$Background/MenuPosition/VBoxContainer/RestartButton
)


var _match_end_mode: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	visible = false

	character_select_button.visible = false
	arena_select_button.visible = false

	continue_button.pressed.connect(
		_resume_game
	)

	restart_button.pressed.connect(
		_restart_fight
	)

	character_select_button.pressed.connect(
		_go_to_character_select
	)

	arena_select_button.pressed.connect(
		_go_to_arena_select
	)


func _unhandled_input(
	event: InputEvent
) -> void:
	if not event.is_action_pressed(
		pause_action
	):
		return

	# Depois do fim da luta não pode fechar
	# o menu apertando Pause novamente.
	if _match_end_mode:
		get_viewport().set_input_as_handled()
		return

	if get_tree().paused:
		_resume_game()
	else:
		_pause_game()

	get_viewport().set_input_as_handled()


func _pause_game() -> void:
	_match_end_mode = false

	title.text = "PAUSADO"

	continue_button.visible = true
	character_select_button.visible = false
	arena_select_button.visible = false
	restart_button.visible = true

	visible = true

	get_tree().paused = true

	continue_button.grab_focus()


func _resume_game() -> void:
	if _match_end_mode:
		return

	get_tree().paused = false

	visible = false


func _restart_fight() -> void:
	get_tree().paused = false

	get_tree().reload_current_scene()


func open_for_match_end() -> void:
	_match_end_mode = true

	title.text = "VITÓRIA"

	# Depois da vitória não existe mais
	# a opção de continuar a luta.
	continue_button.visible = false

	character_select_button.visible = true
	arena_select_button.visible = true

	restart_button.visible = true

	visible = true

	get_tree().paused = true

	character_select_button.grab_focus()


func _go_to_character_select() -> void:
	get_tree().paused = false

	if not ResourceLoader.exists(
		CHARACTER_SELECT_SCENE_PATH
	):
		printerr(
			"PauseMenu: CharacterSelect não encontrada."
		)
		return

	var error: Error = (
		get_tree().change_scene_to_file(
			CHARACTER_SELECT_SCENE_PATH
		)
	)

	if error != OK:
		printerr(
			"PauseMenu: erro ao abrir CharacterSelect: ",
			error
		)


func _go_to_arena_select() -> void:
	get_tree().paused = false

	if not ResourceLoader.exists(
		ARENA_SELECT_SCENE_PATH
	):
		printerr(
			"PauseMenu: ArenaSelection não encontrada."
		)
		return

	var error: Error = (
		get_tree().change_scene_to_file(
			ARENA_SELECT_SCENE_PATH
		)
	)

	if error != OK:
		printerr(
			"PauseMenu: erro ao abrir ArenaSelection: ",
			error
		)


func _exit_tree() -> void:
	if get_tree() != null:
		get_tree().paused = false
