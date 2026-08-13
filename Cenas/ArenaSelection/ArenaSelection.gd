extends Control


@export_group("Panoramas")

@export var arena_01_preview: Texture2D
@export var arena_02_preview: Texture2D
@export var arena_03_preview: Texture2D
@export var arena_04_preview: Texture2D
@export var arena_05_preview: Texture2D
@export var arena_06_preview: Texture2D


@export_group("Nomes")

@export var arena_01_name: String = "Arena 01"
@export var arena_02_name: String = "Arena 02"
@export var arena_03_name: String = "Arena 03"
@export var arena_04_name: String = "Arena 04"
@export var arena_05_name: String = "Arena 05"
@export var arena_06_name: String = "Arena 06"


@export_group("Cenas")

@export_file("*.tscn")
var fight_scene_path: String


@onready var arena_preview: TextureRect = (
	$MainMargin/MainRow/PreviewPanel/
	PreviewColumn/PreviewBox/ArenaPreview
)

@onready var arena_name: Label = (
	$MainMargin/MainRow/PreviewPanel/
	PreviewColumn/ArenaName
)


@onready var arena_01_button: Button = (
	$MainMargin/MainRow/SelectionPanel/
	SelectionColumn/ArenaGrid/Arena01Button
)

@onready var arena_02_button: Button = (
	$MainMargin/MainRow/SelectionPanel/
	SelectionColumn/ArenaGrid/Arena02Button
)

@onready var arena_03_button: Button = (
	$MainMargin/MainRow/SelectionPanel/
	SelectionColumn/ArenaGrid/Arena03Button
)

@onready var arena_04_button: Button = (
	$MainMargin/MainRow/SelectionPanel/
	SelectionColumn/ArenaGrid/Arena04Button
)

@onready var arena_05_button: Button = (
	$MainMargin/MainRow/SelectionPanel/
	SelectionColumn/ArenaGrid/Arena05Button
)

@onready var arena_06_button: Button = (
	$MainMargin/MainRow/SelectionPanel/
	SelectionColumn/ArenaGrid/Arena06Button
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

	_preview_arena(
		ArenaSelection.Arena.ARENA_01
	)

	arena_01_button.grab_focus()

func _connect_arena_button(
	button: Button,
	arena: ArenaSelection.Arena
) -> void:
	button.mouse_entered.connect(
		_preview_arena.bind(arena)
	)

	button.focus_entered.connect(
		_preview_arena.bind(arena)
	)

	button.pressed.connect(
		_select_arena.bind(arena)
	)

func _preview_arena(
	arena: ArenaSelection.Arena
) -> void:
	arena_preview.texture = (
		_get_arena_preview(arena)
	)

	arena_name.text = (
		_get_arena_name(arena)
	)

func _get_arena_preview(
	arena: ArenaSelection.Arena
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
	arena: ArenaSelection.Arena
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

	return ""

func _select_arena(
	arena: ArenaSelection.Arena
) -> void:
	ArenaSelection.select_arena(
		arena
	)

	print(
		"ARENA SELECIONADA: ",
		arena
	)

	if fight_scene_path.is_empty():
		printerr(
			"ArenaSelect: Fight Scene Path vazio."
		)
		return

	get_tree().change_scene_to_file(
		fight_scene_path
	)
