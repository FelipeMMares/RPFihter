extends Control
class_name PreparationScreen


const FIGHT_SCENE_PATH: String = (
	"res://Cenas/Cenarios/CenaDaLuta.tscn"
)


@export_group("Ícones")

@export var chun_li_icon: Texture2D
@export var elena_icon: Texture2D
@export var morrigan_icon: Texture2D
@export var zangief_icon: Texture2D


@export_group("Tempo")

@export_range(0.5, 10.0, 0.1)
var preparation_time: float = 2.5


@onready var player_icon: TextureRect = (
	$MainContainer/FightersRow/PlayerBox/PlayerIcon
)

@onready var opponent_icon: TextureRect = (
	$MainContainer/FightersRow/OpponentBox/OpponentIcon
)

@onready var player_name: Label = (
	$MainContainer/FightersRow/PlayerBox/PlayerName
)

@onready var opponent_name: Label = (
	$MainContainer/FightersRow/OpponentBox/OpponentName
)

@onready var preparation_timer: Timer = (
	$PreparationTimer
)


func _ready() -> void:
	get_tree().paused = false

	_setup_fighter_previews()

	preparation_timer.one_shot = true
	preparation_timer.wait_time = preparation_time

	preparation_timer.timeout.connect(
		_open_fight
	)

	preparation_timer.start()


func _setup_fighter_previews() -> void:
	var player: int = (
		FighterSelection.player_fighter
	)

	var opponent: int = (
		FighterSelection.opponent_fighter
	)

	player_icon.texture = (
		_get_fighter_icon(player)
	)

	opponent_icon.texture = (
		_get_fighter_icon(opponent)
	)

	player_name.text = (
		_get_fighter_name(player)
	)

	opponent_name.text = (
		_get_fighter_name(opponent)
	)


func _get_fighter_icon(
	fighter: int
) -> Texture2D:
	match fighter:
		FighterSelection.Fighter.CHUN_LI:
			return chun_li_icon

		FighterSelection.Fighter.ELENA:
			return elena_icon

		FighterSelection.Fighter.MORRIGAN:
			return morrigan_icon

		FighterSelection.Fighter.ZANGIEF:
			return zangief_icon

	return null


func _get_fighter_name(
	fighter: int
) -> String:
	match fighter:
		FighterSelection.Fighter.CHUN_LI:
			return "CHUN-LI"

		FighterSelection.Fighter.ELENA:
			return "ELENA"

		FighterSelection.Fighter.MORRIGAN:
			return "MORRIGAN"

		FighterSelection.Fighter.ZANGIEF:
			return "ZANGIEF"

	return "UNKNOWN"


func _open_fight() -> void:
	if not ResourceLoader.exists(
		FIGHT_SCENE_PATH
	):
		printerr(
			"PreparationScreen: cena de luta não encontrada."
		)
		return

	var error: Error = (
		get_tree().change_scene_to_file(
			FIGHT_SCENE_PATH
		)
	)

	if error != OK:
		printerr(
			"PreparationScreen: erro ao abrir luta: ",
			error
		)
