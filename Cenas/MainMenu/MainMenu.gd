extends Control
class_name MainMenu


@export_file("*.tscn")
var character_select_scene_path: String = (
	"res://Cenas/CharacterSelect/CharacterSelect.tscn"
)


@export_group("Intro")

@export var intro_animation: StringName = (
	&"Logo_intro"
)

@export var allow_skip: bool = true

@export_range(0.0, 2.0, 0.05)
var skip_delay: float = 0.20


@export_group("Start Button")

@export_range(0.1, 2.0, 0.05)
var blink_duration: float = 0.55

@export_range(0.0, 1.0, 0.05)
var blink_min_alpha: float = 0.20


@onready var start_button: Button = (
	$Background/CenterContainer/VBoxContainer/StartButton
)

@onready var animation_player: AnimationPlayer = (
	$AnimationPlayer
)

@onready var flash: AnimatedSprite2D = (
	$Background/LogoRoot/Flash
)


var _intro_finished: bool = false
var _can_skip: bool = false
var _changing_scene: bool = false

var _blink_tween: Tween


func _ready() -> void:
	get_tree().paused = false

	start_button.disabled = true
	start_button.modulate.a = 0.0

	flash.visible = false

	start_button.pressed.connect(
		_on_start_button_pressed
	)

	animation_player.animation_finished.connect(
		_on_animation_finished
	)

	flash.animation_finished.connect(
		_on_flash_animation_finished
	)

	animation_player.play(
		intro_animation
	)

	await get_tree().create_timer(
		skip_delay
	).timeout

	if _intro_finished:
		return

	_can_skip = true


func _unhandled_input(
	event: InputEvent
) -> void:
	if _intro_finished:
		return

	if not allow_skip:
		return

	if not _can_skip:
		return

	if (
		event is InputEventKey
		and event.pressed
		and not event.echo
	):
		_skip_intro()
		get_viewport().set_input_as_handled()
		return

	if (
		event is InputEventJoypadButton
		and event.pressed
	):
		_skip_intro()
		get_viewport().set_input_as_handled()
		return

	if (
		event is InputEventMouseButton
		and event.pressed
	):
		_skip_intro()
		get_viewport().set_input_as_handled()


func _skip_intro() -> void:
	if _intro_finished:
		return

	_can_skip = false

	var animation := (
		animation_player.get_animation(
			intro_animation
		)
	)

	if animation != null:
		animation_player.seek(
			animation.length,
			true
		)

	animation_player.stop()

	_finish_intro()


func _on_animation_finished(
	animation_name: StringName
) -> void:
	if animation_name != intro_animation:
		return

	_finish_intro()


func _finish_intro() -> void:
	if _intro_finished:
		return

	_intro_finished = true
	_can_skip = false

	flash.stop()
	flash.visible = false

	start_button.disabled = false
	start_button.modulate.a = 1.0

	start_button.grab_focus()

	_start_button_blink()


func _start_button_blink() -> void:
	if _blink_tween != null:
		_blink_tween.kill()

	start_button.modulate.a = 1.0

	_blink_tween = create_tween()

	_blink_tween.set_loops()

	_blink_tween.set_trans(
		Tween.TRANS_SINE
	)

	_blink_tween.set_ease(
		Tween.EASE_IN_OUT
	)

	_blink_tween.tween_property(
		start_button,
		"modulate:a",
		blink_min_alpha,
		blink_duration
	)

	_blink_tween.tween_property(
		start_button,
		"modulate:a",
		1.0,
		blink_duration
	)


func _play_logo_impact() -> void:
	print("=== TESTE HITSPARK ===")

	if flash == null:
		printerr("Flash é NULL")
		return

	if flash.sprite_frames == null:
		printerr("Flash não possui SpriteFrames")
		return

	if not flash.sprite_frames.has_animation(&"hitSpark"):
		printerr(
			"Animação hitSpark não existe. Animações: ",
			flash.sprite_frames.get_animation_names()
		)
		return

	print(
		"Frames do hitSpark: ",
		flash.sprite_frames.get_frame_count(&"hitSpark")
	)

	flash.stop()

	# Força todas as propriedades visuais para teste.
	flash.visible = true
	flash.modulate = Color.WHITE
	flash.self_modulate = Color.WHITE
	flash.z_index = 100

	flash.animation = &"hitSpark"
	flash.frame = 0
	flash.speed_scale = 1.0

	flash.play()

	print("Visible: ", flash.visible)
	print("Playing: ", flash.is_playing())
	print("Animation: ", flash.animation)
	print("Frame: ", flash.frame)
	print("Position: ", flash.position)
	print("Scale: ", flash.scale)
	print("=====================")

func _on_flash_animation_finished() -> void:
	if flash.animation != &"hitSpark":
		return

	flash.stop()
	flash.visible = false


func _on_start_button_pressed() -> void:
	if not _intro_finished:
		return

	if _changing_scene:
		return

	if _blink_tween != null:
		_blink_tween.kill()

	_change_scene(
		character_select_scene_path
	)


func _change_scene(
	scene_path: String
) -> void:
	if _changing_scene:
		return

	if scene_path.is_empty():
		printerr(
			"MainMenu: caminho da cena não configurado."
		)
		return

	if not ResourceLoader.exists(
		scene_path
	):
		printerr(
			"MainMenu: cena não encontrada: ",
			scene_path
		)
		return

	_changing_scene = true

	get_tree().paused = false

	var change_error: Error = (
		get_tree().change_scene_to_file(
			scene_path
		)
	)

	if change_error != OK:
		_changing_scene = false

		printerr(
			"MainMenu: erro ao abrir a cena: ",
			change_error
		)
