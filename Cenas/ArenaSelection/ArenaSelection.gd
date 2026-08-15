extends Control


@export_group("Panoramas")

@export var arena_01_preview: Texture2D
@export var arena_02_preview: Texture2D
@export var arena_03_preview: Texture2D
@export var arena_04_preview: Texture2D
@export var arena_05_preview: Texture2D
@export var arena_06_preview: Texture2D


@export_group("Nomes")

@export var arena_01_name: String = "Vila da Preguiça"
@export var arena_02_name: String = "Floresta dos Sussurros"
@export var arena_03_name: String = "Deserto dos Exilados"
@export var arena_04_name: String = "Convés Interno do Nau"
@export var arena_05_name: String = "Vale de Lava"
@export var arena_06_name: String = "Ruínas do Rei Demônio"


@export_group("Cenas")

@export var fight_scene: PackedScene
@export var opponent_select_scene: PackedScene


@onready var arena_preview: TextureRect = (
	%ArenaPreview
)

@onready var arena_name: Label = (
	%ArenaName
)

@onready var arena_01_button: TextureButton = (
	%Arena01Button
)

@onready var arena_02_button: TextureButton = (
	%Arena02Button
)

@onready var arena_03_button: TextureButton = (
	%Arena03Button
)

@onready var arena_04_button: TextureButton = (
	%Arena04Button
)

@onready var arena_05_button: TextureButton = (
	%Arena05Button
)

@onready var arena_06_button: TextureButton = (
	%Arena06Button
)


func _ready() -> void:
	_connect_arena_button(
		arena_01_button,
		ArenaSelection.Arena.ARENA_01
	)

	_connect_arena_button(
		arena_02_button,
		ArenaSelection.Arena.ARENA_02
	)

	_connect_arena_button(
		arena_03_button,
		ArenaSelection.Arena.ARENA_03
	)

	_connect_arena_button(
		arena_04_button,
		ArenaSelection.Arena.ARENA_04
	)

	_connect_arena_button(
		arena_05_button,
		ArenaSelection.Arena.ARENA_05
	)

	_connect_arena_button(
		arena_06_button,
		ArenaSelection.Arena.ARENA_06
	)

	_focus_current_arena()

func _connect_arena_button(
	button: TextureButton,
	arena: int
) -> void:
	if button == null:
		return

	# Garante navegação por teclado e controle.
	button.focus_mode = Control.FOCUS_ALL

	button.focus_entered.connect(
		_preview_arena.bind(arena)
	)

	button.mouse_entered.connect(
		_focus_button.bind(button)
	)

	button.pressed.connect(
		_select_arena.bind(arena)
	)

func _focus_button(
	button: TextureButton
) -> void:
	if button == null:
		return

	button.grab_focus()

func _preview_arena(
	arena: int
) -> void:
	var preview: Texture2D = (
		_get_arena_preview(arena)
	)

	var display_name: String = (
		_get_arena_name(arena)
	)

	if preview != null:
		arena_preview.texture = preview

	arena_name.text = display_name

	print(
		"PREVIEW DA ARENA: ",
		display_name
	)

func _get_arena_preview(
	arena: int
) -> Texture2D:
	match arena:
		ArenaSelection.Arena.ARENA_01:
			return arena_01_preview

		ArenaSelection.Arena.ARENA_02:
			return arena_02_preview

		ArenaSelection.Arena.ARENA_03:
			return arena_03_preview

		ArenaSelection.Arena.ARENA_04:
			return arena_04_preview

		ArenaSelection.Arena.ARENA_05:
			return arena_05_preview

		ArenaSelection.Arena.ARENA_06:
			return arena_06_preview

	return null

func _get_arena_name(
	arena: int
) -> String:
	match arena:
		ArenaSelection.Arena.ARENA_01:
			return arena_01_name

		ArenaSelection.Arena.ARENA_02:
			return arena_02_name

		ArenaSelection.Arena.ARENA_03:
			return arena_03_name

		ArenaSelection.Arena.ARENA_04:
			return arena_04_name

		ArenaSelection.Arena.ARENA_05:
			return arena_05_name

		ArenaSelection.Arena.ARENA_06:
			return arena_06_name

	return "Arena"

func _select_arena(
	arena: int
) -> void:
	ArenaSelection.select_arena(
		arena
	)

	print(
		"CONFIRMOU ARENA: ",
		_get_arena_name(arena)
	)

	if fight_scene == null:
		printerr(
			"ArenaSelect: Fight Scene não configurada."
		)
		return

	get_tree().change_scene_to_packed(
		fight_scene
	)

func _focus_current_arena() -> void:
	var button: TextureButton = (
		_get_arena_button(
			ArenaSelection.selected_arena
		)
	)

	if button == null:
		button = arena_01_button

	if button == null:
		return

	button.grab_focus()

	_preview_arena(
		ArenaSelection.selected_arena
	)

func _get_arena_button(
	arena: int
) -> TextureButton:
	match arena:
		ArenaSelection.Arena.ARENA_01:
			return arena_01_button

		ArenaSelection.Arena.ARENA_02:
			return arena_02_button

		ArenaSelection.Arena.ARENA_03:
			return arena_03_button

		ArenaSelection.Arena.ARENA_04:
			return arena_04_button

		ArenaSelection.Arena.ARENA_05:
			return arena_05_button

		ArenaSelection.Arena.ARENA_06:
			return arena_06_button

	return arena_01_button

func _unhandled_input(
	event: InputEvent
) -> void:
	if event.is_action_pressed(
		&"ui_cancel"
	):
		_go_back()
	

func _go_back() -> void:
	if opponent_select_scene == null:
		printerr(
			"ArenaSelect: Opponent Select Scene não configurada."
		)
		return

	get_tree().change_scene_to_packed(
		opponent_select_scene
	)
