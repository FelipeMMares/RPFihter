extends Control
class_name DefeatScreen


@export_group("Cenas")

@export_file("*.tscn")
var fight_scene_path: String = (
	"res://Cenas/Cenarios/CenaDaLuta.tscn"
)

@export_file("*.tscn")
var main_menu_scene_path: String = (
	"res://Cenas/MainMenu/MainMenu.tscn"
)


@export_group("Contagem")

@export_range(1, 60, 1)
var countdown_start: int = 10

@export_range(0.1, 5.0, 0.1)
var game_over_duration: float = 1.5


@onready var defeat_title: Label = (
	$CenterContainer/VBoxContainer/DefeatTitle
)

@onready var question_label: Label = (
	$CenterContainer/VBoxContainer/QuestionLabel
)

@onready var countdown_label: Label = (
	$CenterContainer/VBoxContainer/CountdownLabel
)

@onready var retry_button: Button = (
	$CenterContainer/VBoxContainer/VBoxContainer/RetryButton
)

@onready var main_menu_button: Button = (
	$CenterContainer/VBoxContainer/VBoxContainer/MainMenuButton
)

@onready var countdown_timer: Timer = (
	$CountdownTimer
)


var _remaining_time: int = 10
var _screen_resolved: bool = false


func _ready() -> void:
	get_tree().paused = false

	_remaining_time = countdown_start
	_screen_resolved = false

	if defeat_title != null:
		defeat_title.text = "DERROTA"

	if question_label != null:
		question_label.text = (
			"VOCÊ VAI TENTAR DE NOVO?"
		)

	_update_countdown_label()

	if retry_button != null:
		retry_button.pressed.connect(
			_on_retry_button_pressed
		)

		retry_button.grab_focus()

	if main_menu_button != null:
		main_menu_button.pressed.connect(
			_on_main_menu_button_pressed
		)

	if countdown_timer == null:
		printerr(
			"DefeatScreen: CountdownTimer não encontrado."
		)
		return

	countdown_timer.wait_time = 1.0
	countdown_timer.one_shot = false

	countdown_timer.timeout.connect(
		_on_countdown_timer_timeout
	)

	countdown_timer.start()


func _on_countdown_timer_timeout() -> void:
	if _screen_resolved:
		return

	_remaining_time -= 1

	if _remaining_time <= 0:
		_remaining_time = 0
		_update_countdown_label()

		await _show_game_over()
		return

	_update_countdown_label()


func _update_countdown_label() -> void:
	if countdown_label == null:
		return

	countdown_label.text = str(
		_remaining_time
	)


func _on_retry_button_pressed() -> void:
	if _screen_resolved:
		return

	_screen_resolved = true
	_stop_countdown()

	_change_scene(
		fight_scene_path
	)


func _on_main_menu_button_pressed() -> void:
	if _screen_resolved:
		return

	_screen_resolved = true
	_stop_countdown()

	_change_scene(
		main_menu_scene_path
	)


func _show_game_over() -> void:
	if _screen_resolved:
		return

	_screen_resolved = true
	_stop_countdown()

	if defeat_title != null:
		defeat_title.text = "GAME OVER"

	if question_label != null:
		question_label.visible = false

	if countdown_label != null:
		countdown_label.visible = false

	if retry_button != null:
		retry_button.disabled = true

	if main_menu_button != null:
		main_menu_button.disabled = true

	await get_tree().create_timer(
		game_over_duration
	).timeout

	_change_scene(
		main_menu_scene_path
	)


func _stop_countdown() -> void:
	if (
		countdown_timer != null
		and not countdown_timer.is_stopped()
	):
		countdown_timer.stop()


func _change_scene(scene_path: String) -> void:
	if scene_path.is_empty():
		printerr(
			"DefeatScreen: caminho de cena vazio."
		)
		return

	if not ResourceLoader.exists(scene_path):
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
