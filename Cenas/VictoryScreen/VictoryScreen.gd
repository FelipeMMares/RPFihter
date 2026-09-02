extends Control
class_name VictoryScreen


const MAIN_MENU_PATH: String = (
	"res://Cenas/MainMenu/MainMenu.tscn"
)


@export_group("Personagens")

@export var chun_li_frames: SpriteFrames
@export var elena_frames: SpriteFrames
@export var morrigan_frames: SpriteFrames
@export var zangief_frames: SpriteFrames


@export_group("Ajuste visual")

@export var morrigan_visual_profile: AnimationVisualProfile


@export_group("Input")

@export_range(0.0, 5.0, 0.1)
var input_delay: float = 1.0


@onready var fighter_preview: AnimatedSprite2D = (
	$FighterPreview
)

@onready var visual_controller: AnimationVisualController = (
	$AnimationVisualController
)


var _can_continue: bool = false


func _ready() -> void:
	get_tree().paused = false

	_setup_victory_fighter()

	await get_tree().create_timer(
		input_delay
	).timeout

	_can_continue = true


func _setup_victory_fighter() -> void:
	var fighter: int = (
		FighterSelection.player_fighter
	)

	visual_controller.set_enabled(
		false
	)

	match fighter:
		FighterSelection.Fighter.CHUN_LI:
			fighter_preview.sprite_frames = (
				chun_li_frames
			)

		FighterSelection.Fighter.ELENA:
			fighter_preview.sprite_frames = (
				elena_frames
			)

		FighterSelection.Fighter.MORRIGAN:
			fighter_preview.sprite_frames = (
				morrigan_frames
			)

			if morrigan_visual_profile != null:
				visual_controller.set_visual_profile(
					morrigan_visual_profile
				)

				visual_controller.set_enabled(
					true
				)

		FighterSelection.Fighter.ZANGIEF:
			fighter_preview.sprite_frames = (
				zangief_frames
			)

	if fighter_preview.sprite_frames == null:
		printerr(
			"VictoryScreen: SpriteFrames não configurado."
		)
		return

	if fighter_preview.sprite_frames.has_animation(
		&"Victory"
	):
		fighter_preview.play(
			&"Victory"
		)
	else:
		printerr(
			"VictoryScreen: animação Victory não encontrada."
		)


func _unhandled_input(
	event: InputEvent
) -> void:
	if not _can_continue:
		return

	var pressed: bool = false

	if (
		event is InputEventKey
		and event.pressed
		and not event.echo
	):
		pressed = true

	elif (
		event is InputEventJoypadButton
		and event.pressed
	):
		pressed = true

	elif (
		event is InputEventMouseButton
		and event.pressed
	):
		pressed = true

	if not pressed:
		return

	_return_to_main_menu()

	get_viewport().set_input_as_handled()


func _return_to_main_menu() -> void:
	CampaignManager.reset_campaign()
	GameModeManager.reset()

	get_tree().paused = false

	get_tree().change_scene_to_file(
		MAIN_MENU_PATH
	)
