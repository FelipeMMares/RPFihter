extends Control
class_name DefeatScreen


@export_group("Cenas")

@export_file("*.tscn")
var fight_scene_path: String = (
	"res://Cenas/Cenarios/CenaDaLuta.tscn"
)

@export_file("*.tscn")
var character_select_scene_path: String

@export_file("*.tscn")
var arena_select_scene_path: String

@export_file("*.tscn")
var main_menu_scene_path: String = (
	"res://Cenas/MainMenu/MainMenu.tscn"
)


@export_group("Contagem")

@export_range(1, 60, 1)
var countdown_start: int = 10

@export_range(1, 60, 1)
var game_over_countdown: int = 10


@export_group("Animação")

@export_range(0.1, 1.0, 0.05)
var defeated_speed_scale: float = 0.5


@export_group("Sprites de derrota")

@export var chun_li_defeat_icon: Texture2D
@export var elena_defeat_icon: Texture2D


@onready var character_display: Node2D = (
	$CharacterDisplay
)

@onready var defeated_animated: AnimatedSprite2D = (
	$CharacterDisplay/DefeatedAnimated
)

@onready var defeat_icon: Sprite2D = (
	$CharacterDisplay/DefeatIcon
)


@onready var center_container: CenterContainer = (
	$CenterContainer
)


@onready var defeat_title: Label = (
	$CenterContainer/ResultPanel/ResultMargin/VBoxContainer/DefeatTitle
)

@onready var question_label: Label = (
	$CenterContainer/ResultPanel/ResultMargin/VBoxContainer/QuestionLabel
)

@onready var countdown_label: Label = (
	$CenterContainer/ResultPanel/ResultMargin/VBoxContainer/CountdownLabel
)


@onready var retry_button: Button = (
	$CenterContainer/ResultPanel/ResultMargin/VBoxContainer/VBoxContainer/RetryButton
)

@onready var character_select_button: Button = (
	$CenterContainer/ResultPanel/ResultMargin/VBoxContainer/VBoxContainer/CharacterSelectButton
)

@onready var arena_select_button: Button = (
	$CenterContainer/ResultPanel/ResultMargin/VBoxContainer/VBoxContainer/ArenaSelectButton
)

@onready var main_menu_button: Button = (
	$CenterContainer/ResultPanel/ResultMargin/VBoxContainer/VBoxContainer/MainMenuButton
)


@onready var countdown_timer: Timer = (
	$CountdownTimer
)

@onready var game_over_timer: Timer = (
	$GameOverTimer
)


var _remaining_time: int = 10

var _screen_resolved: bool = false
var _game_over_active: bool = false

var _defeated_animation: StringName
var _fall_defeated_animation: StringName

var _selected_defeat_icon: Texture2D


func _ready() -> void:
	get_tree().paused = false

	_remaining_time = countdown_start

	_screen_resolved = false
	_game_over_active = false

	_configure_selected_character()
	_configure_interface()
	_connect_buttons()
	_configure_timers()

	await _play_defeated_animation()

	if _screen_resolved:
		return

	_start_choice_phase()

func _configure_selected_character() -> void:
	match FighterSelection.player_fighter:
		FighterSelection.Fighter.CHUN_LI:
			_defeated_animation = (
				&"ChunLiDefeated"
			)

			_fall_defeated_animation = (
				&"ChunLiFallDefeated"
			)

			_selected_defeat_icon = (
				chun_li_defeat_icon
			)


		FighterSelection.Fighter.ELENA:
			_defeated_animation = (
				&"ElenaDefeated"
			)

			_fall_defeated_animation = (
				&"ElenaFallDefeated"
			)

			_selected_defeat_icon = (
				elena_defeat_icon
			)

func _configure_interface() -> void:
	if center_container != null:
		center_container.visible = false

	if defeat_icon != null:
		defeat_icon.visible = false

	if defeat_title != null:
		defeat_title.text = "DERROTA"

	if question_label != null:
		question_label.text = (
			"TENTAR DE NOVO?"
		)

	if countdown_label != null:
		countdown_label.visible = true

	if retry_button != null:
		retry_button.visible = true

	if character_select_button != null:
		character_select_button.visible = true

	if arena_select_button != null:
		arena_select_button.visible = true

	if main_menu_button != null:
		main_menu_button.visible = true

func _connect_buttons() -> void:
	if retry_button != null:
		retry_button.pressed.connect(
			_on_retry_button_pressed
		)

	if character_select_button != null:
		character_select_button.pressed.connect(
			_on_character_select_button_pressed
		)

	if arena_select_button != null:
		arena_select_button.pressed.connect(
			_on_arena_select_button_pressed
		)

	if main_menu_button != null:
		main_menu_button.pressed.connect(
			_on_main_menu_button_pressed
		)

func _configure_timers() -> void:
	if countdown_timer == null:
		printerr(
			"DefeatScreen: CountdownTimer não encontrado."
		)
	else:
		countdown_timer.wait_time = 1.0
		countdown_timer.one_shot = false

		countdown_timer.timeout.connect(
			_on_countdown_timer_timeout
		)


	if game_over_timer == null:
		printerr(
			"DefeatScreen: GameOverTimer não encontrado."
		)
	else:
		game_over_timer.wait_time = float(
			game_over_countdown
		)

		game_over_timer.one_shot = true

		game_over_timer.timeout.connect(
			_on_game_over_timer_timeout
		)

func _play_defeated_animation() -> void:
	if defeated_animated == null:
		printerr(
			"DefeatScreen: DefeatedAnimated não encontrado."
		)
		return

	if defeated_animated.sprite_frames == null:
		printerr(
			"DefeatScreen: SpriteFrames não configurado."
		)
		return

	if not defeated_animated.sprite_frames.has_animation(
		_defeated_animation
	):
		printerr(
			"DefeatScreen: animação ",
			_defeated_animation,
			" não encontrada."
		)
		return

	defeated_animated.speed_scale = (
		defeated_speed_scale
	)

	defeated_animated.play(
		_defeated_animation
	)

	await defeated_animated.animation_finished

	defeated_animated.speed_scale = 1.0

func _start_choice_phase() -> void:
	_remaining_time = countdown_start

	if center_container != null:
		center_container.visible = true

	if defeat_title != null:
		defeat_title.text = "DERROTA"

	if question_label != null:
		question_label.visible = true
		question_label.text = "TENTAR DE NOVO?"

	if countdown_label != null:
		countdown_label.visible = true

	if retry_button != null:
		retry_button.visible = true
		retry_button.disabled = false

	if character_select_button != null:
		character_select_button.disabled = false

	if arena_select_button != null:
		arena_select_button.disabled = false

	if main_menu_button != null:
		main_menu_button.disabled = false

	_update_countdown_label()

	if countdown_timer != null:
		countdown_timer.start()

	if retry_button != null:
		retry_button.grab_focus()

func _on_countdown_timer_timeout() -> void:
	if _screen_resolved:
		return

	if _game_over_active:
		return

	_remaining_time -= 1

	if _remaining_time <= 0:
		_remaining_time = 0

		_update_countdown_label()

		_enter_game_over_phase()
		return

	_update_countdown_label()

func _update_countdown_label() -> void:
	if countdown_label == null:
		return

	countdown_label.text = str(
		_remaining_time
	)

func _enter_game_over_phase() -> void:
	if _screen_resolved:
		return

	if _game_over_active:
		return

	_game_over_active = true

	_stop_first_countdown()

	if defeat_title != null:
		defeat_title.text = "GAME OVER"

	if question_label != null:
		question_label.visible = false

	if countdown_label != null:
		countdown_label.visible = false

	if retry_button != null:
		retry_button.visible = false

	_play_fall_defeated()

	_show_defeat_icon()

	if game_over_timer != null:
		game_over_timer.start()

	if character_select_button != null:
		character_select_button.grab_focus()

func _play_fall_defeated() -> void:
	if defeated_animated == null:
		return

	if defeated_animated.sprite_frames == null:
		return

	if not defeated_animated.sprite_frames.has_animation(
		_fall_defeated_animation
	):
		printerr(
			"DefeatScreen: animação ",
			_fall_defeated_animation,
			" não encontrada."
		)
		return

	defeated_animated.speed_scale = 1.0

	defeated_animated.play(
		_fall_defeated_animation
	)

func _show_defeat_icon() -> void:
	if defeat_icon == null:
		return

	if _selected_defeat_icon == null:
		printerr(
			"DefeatScreen: ícone de derrota não configurado."
		)
		return

	defeat_icon.texture = (
		_selected_defeat_icon
	)

	defeat_icon.visible = true

func _on_game_over_timer_timeout() -> void:
	if _screen_resolved:
		return

	_screen_resolved = true

	_change_scene(
		main_menu_scene_path
	)

func _on_retry_button_pressed() -> void:
	if _screen_resolved:
		return

	if _game_over_active:
		return

	_screen_resolved = true

	_stop_all_timers()

	_change_scene(
		fight_scene_path
	)

func _on_character_select_button_pressed() -> void:
	if _screen_resolved:
		return

	_screen_resolved = true

	_stop_all_timers()

	_change_scene(
		character_select_scene_path
	)

func _on_arena_select_button_pressed() -> void:
	if _screen_resolved:
		return

	_screen_resolved = true

	_stop_all_timers()

	_change_scene(
		arena_select_scene_path
	)

func _on_main_menu_button_pressed() -> void:
	if _screen_resolved:
		return

	_screen_resolved = true

	_stop_all_timers()

	_change_scene(
		main_menu_scene_path
	)

func _stop_first_countdown() -> void:
	if (
		countdown_timer != null
		and not countdown_timer.is_stopped()
	):
		countdown_timer.stop()


func _stop_all_timers() -> void:
	_stop_first_countdown()

	if (
		game_over_timer != null
		and not game_over_timer.is_stopped()
	):
		game_over_timer.stop()

func _change_scene(
	scene_path: String
) -> void:
	if scene_path.is_empty():
		printerr(
			"DefeatScreen: caminho de cena vazio."
		)
		return

	if not ResourceLoader.exists(
		scene_path
	):
		printerr(
			"DefeatScreen: cena não encontrada: ",
			scene_path
		)
		return

	get_tree().paused = false

	var change_error: Error = (
		get_tree().change_scene_to_file(
			scene_path
		)
	)

	if change_error != OK:
		printerr(
			"DefeatScreen: erro ao trocar de cena: ",
			change_error
		)
