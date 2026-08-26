extends Control
class_name OpponentSelect


@export_group("Cena de luta")

@export_file("*.tscn")
var fight_scene_path: String = (
	"res://Cenas/ArenaSelection/ArenaSelection.tscn"
)


@export_group("Preview dos personagens")

@export var chun_li_frames: SpriteFrames
@export var elena_frames: SpriteFrames
@export var morrigan_frames: SpriteFrames
@export var zangief_frames: SpriteFrames

@export_range(0.5, 10.0, 0.1)
var idle_before_taunt_time: float = 3.0

@export_group("Ajustes visuais")

@export var morrigan_visual_profile: AnimationVisualProfile

@export var mirror_cpu_color: Color = Color(
	0.65,
	0.80,
	1.0,
	1.0
)

@export_group("Visual dos botões")

@export var button_hover_scale: float = 1.08
@export var button_animation_time: float = 0.12

@export var hover_border_color: Color = Color("#FFD84A")

@export var selected_background_color: Color = Color("#F2C94C")
@export var selected_border_color: Color = Color("#9A6B00")

@export var selected_name_color: Color = Color("#2A1B00")

@export var normal_name_color: Color = Color.WHITE

@onready var fighter_preview: AnimatedSprite2D = (
	$MainMargin/MainRow/PreviewPanel/PreviewBox/FighterPreview
)

@onready var fighter_name: Label = (
	$MainMargin/MainRow/PreviewPanel/FighterName
)


@onready var chun_li_button: Button = (
	$MainMargin/MainRow/SelectionPanel/SelectionColumn/CharacterGrid/ChunLiButton
)

@onready var elena_button: Button = (
	$MainMargin/MainRow/SelectionPanel/SelectionColumn/CharacterGrid/ElenaButton
)

@onready var morrigan_button: Button = (
	$MainMargin/MainRow/SelectionPanel/SelectionColumn/CharacterGrid/MorriganButton
)

@onready var zangief_button: Button = (
	$MainMargin/MainRow/SelectionPanel/SelectionColumn/CharacterGrid/ZangiefButton
)

@onready var preview_visual_controller: AnimationVisualController = (
	$MainMargin/MainRow/PreviewPanel/PreviewBox/AnimationVisualController
)

@onready var locked_buttons: Array[Button] = [
	$MainMargin/MainRow/SelectionPanel/SelectionColumn/CharacterGrid/LockedButton2,
	$MainMargin/MainRow/SelectionPanel/SelectionColumn/CharacterGrid/LockedButton3
]


@onready var update_message: Label = (
	$MainMargin/MainRow/SelectionPanel/SelectionColumn/UpdateMessage
)


@onready var preview_timer: Timer = (
	$PreviewTimer
)

@onready var message_timer: Timer = (
	$MessageTimer
)


var _character_confirmed: bool = false
var _selected_button: Button = null

func _ready() -> void:
	get_tree().paused = false

	update_message.visible = false

	_configure_timers()
	_connect_buttons()

	call_deferred("_setup_character_buttons")

	# Começa com Chun-Li destacada.
	_preview_chun_li()

	chun_li_button.grab_focus()


func _configure_timers() -> void:
	preview_timer.one_shot = true
	preview_timer.wait_time = idle_before_taunt_time

	message_timer.one_shot = true
	message_timer.wait_time = 2.0

	preview_timer.timeout.connect(
		_on_preview_timer_timeout
	)

	message_timer.timeout.connect(
		_on_message_timer_timeout
	)

	fighter_preview.animation_finished.connect(
		_on_preview_animation_finished
	)


func _connect_buttons() -> void:
	chun_li_button.pressed.connect(
		_on_chun_li_pressed
	)

	elena_button.pressed.connect(
		_on_elena_pressed
	)

	morrigan_button.pressed.connect(
		_on_morrigan_pressed
	)

	zangief_button.pressed.connect(
		_on_zangief_pressed
	)

	# Mouse em cima do personagem troca o preview.
	chun_li_button.mouse_entered.connect(
		_preview_chun_li
	)

	elena_button.mouse_entered.connect(
		_preview_elena
	)

	morrigan_button.mouse_entered.connect(
		_preview_morrigan
	)

	zangief_button.mouse_entered.connect(
		_preview_zangief
	)

	# Também funciona com teclado/controle.
	chun_li_button.focus_entered.connect(
		_preview_chun_li
	)

	elena_button.focus_entered.connect(
		_preview_elena
	)

	morrigan_button.focus_entered.connect(
		_preview_morrigan
	)

	zangief_button.focus_entered.connect(
		_preview_zangief
	)

	for button in locked_buttons:
		button.pressed.connect(
			_on_locked_character_pressed
		)


func _preview_chun_li() -> void:
	if _character_confirmed:
		return

	preview_visual_controller.set_enabled(
		false
	)

	_show_fighter_preview(
		chun_li_frames,
		"CHUN-LI"
	)

	if (
		FighterSelection.player_fighter
		== FighterSelection.Fighter.CHUN_LI
	):
		fighter_preview.modulate = mirror_cpu_color
	else:
		fighter_preview.modulate = Color.WHITE


func _preview_elena() -> void:
	if _character_confirmed:
		return

	preview_visual_controller.set_enabled(
		false
	)

	_show_fighter_preview(
		elena_frames,
		"ELENA"
	)

	if (
		FighterSelection.player_fighter
		== FighterSelection.Fighter.ELENA
	):
		fighter_preview.modulate = mirror_cpu_color
	else:
		fighter_preview.modulate = Color.WHITE

func _preview_morrigan() -> void:
	if _character_confirmed:
		return

	_show_fighter_preview(
		morrigan_frames,
		"MORRIGAN"
	)

	preview_visual_controller.set_visual_profile(
		morrigan_visual_profile
	)

	preview_visual_controller.set_enabled(
		true
	)

	if (
		FighterSelection.player_fighter
		== FighterSelection.Fighter.MORRIGAN
	):
		fighter_preview.modulate = (
			mirror_cpu_color
		)
	else:
		fighter_preview.modulate = Color.WHITE

func _preview_zangief() -> void:
	if _character_confirmed:
		return

	preview_visual_controller.set_enabled(
		false
	)

	_show_fighter_preview(
		zangief_frames,
		"ZANGIEF"
	)

	if (
		FighterSelection.player_fighter
		== FighterSelection.Fighter.ZANGIEF
	):
		fighter_preview.modulate = (
			mirror_cpu_color
		)
	else:
		fighter_preview.modulate = (
			Color.WHITE
		)

func _show_fighter_preview(
	frames: SpriteFrames,
	display_name: String
) -> void:
	if frames == null:
		printerr(
			"CharacterSelect: SpriteFrames não configurado para ",
			display_name
		)
		return

	preview_timer.stop()

	fighter_preview.stop()

	fighter_preview.sprite_frames = frames

	fighter_name.text = display_name

	_play_idle()


func _play_idle() -> void:
	if _character_confirmed:
		return

	if fighter_preview.sprite_frames == null:
		return

	if not fighter_preview.sprite_frames.has_animation(
		&"Idle"
	):
		printerr(
			"CharacterSelect: animação Idle não encontrada."
		)
		return

	fighter_preview.play(
		&"Idle"
	)

	preview_timer.start(
		idle_before_taunt_time
	)


func _on_preview_timer_timeout() -> void:
	if _character_confirmed:
		return

	if fighter_preview.sprite_frames == null:
		return

	if not fighter_preview.sprite_frames.has_animation(
		&"Taunt"
	):
		# Se esse personagem não tiver Taunt,
		# simplesmente continua Idle.
		_play_idle()
		return

	fighter_preview.play(
		&"Taunt"
	)


func _on_preview_animation_finished() -> void:
	if _character_confirmed:
		return

	# Depois do Taunt volta para Idle.
	if fighter_preview.animation == &"Taunt":
		_play_idle()


func _on_chun_li_pressed() -> void:
	if _character_confirmed:
		return

	_preview_chun_li()

	_select_character_button(
		chun_li_button
	)

	FighterSelection.select_opponent(
		FighterSelection.Fighter.CHUN_LI
	)

	await _confirm_selection()


func _on_elena_pressed() -> void:
	if _character_confirmed:
		return

	_preview_elena()

	_select_character_button(
		elena_button
	)

	FighterSelection.select_opponent(
		FighterSelection.Fighter.ELENA
	)

	await _confirm_selection()

func _on_morrigan_pressed() -> void:
	if _character_confirmed:
		return

	_preview_morrigan()

	_select_character_button(
		morrigan_button
	)

	FighterSelection.select_opponent(
		FighterSelection.Fighter.MORRIGAN
	)

	await _confirm_selection()

func _on_zangief_pressed() -> void:
	if _character_confirmed:
		return

	_preview_zangief()

	_select_character_button(
		zangief_button
	)

	FighterSelection.select_opponent(
		FighterSelection.Fighter.ZANGIEF
	)

	await _confirm_selection()

func _confirm_selection() -> void:
	_character_confirmed = true

	preview_timer.stop()
	message_timer.stop()

	update_message.visible = false

	chun_li_button.disabled = true
	elena_button.disabled = true
	morrigan_button.disabled = true
	zangief_button.disabled = true

	for button in locked_buttons:
		button.disabled = true

	if (
		fighter_preview.sprite_frames != null
		and fighter_preview.sprite_frames.has_animation(
			&"Victory"
		)
	):
		fighter_preview.play(
			&"Victory"
		)

		await fighter_preview.animation_finished

	else:
		await get_tree().create_timer(
			0.8
		).timeout

	_start_fight()


func _on_locked_character_pressed() -> void:
	if _character_confirmed:
		return

	update_message.text = (
		"AGUARDE A ATUALIZAÇÃO"
	)

	update_message.visible = true

	message_timer.start()


func _on_message_timer_timeout() -> void:
	update_message.visible = false


func _start_fight() -> void:
	if fight_scene_path.is_empty():
		printerr(
			"OpponentSelect: caminho da luta vazio."
		)
		return

	if not ResourceLoader.exists(
		fight_scene_path
	):
		printerr(
			"OpponentSelect: cena da luta não encontrada: ",
			fight_scene_path
		)
		return

	var error: Error = (
		get_tree().change_scene_to_file(
			fight_scene_path
		)
	)

	if error != OK:
		printerr(
			"OpponentSelect: erro ao abrir luta: ",
			error
		)

func _setup_character_buttons() -> void:
	var buttons: Array[Button] = [
		chun_li_button,
		elena_button,
		morrigan_button,
		zangief_button
	]

	for locked_button in locked_buttons:
		buttons.append(locked_button)

	for button in buttons:
		_setup_character_button(button)
		

func _setup_character_button(
	button: Button
) -> void:
	if button == null:
		return

	# Faz o botão crescer a partir do centro.
	button.pivot_offset = button.size / 2.0

	button.mouse_entered.connect(
		_on_character_button_mouse_entered.bind(button)
	)

	button.mouse_exited.connect(
		_on_character_button_mouse_exited.bind(button)
	)

func _on_character_button_mouse_entered(
	button: Button
) -> void:
	if _character_confirmed:
		return

	_animate_button_scale(
		button,
		Vector2.ONE * button_hover_scale
	)

	if button != _selected_button:
		_apply_hover_style(button)

func _on_character_button_mouse_exited(
	button: Button
) -> void:
	if button == null:
		return

	_animate_button_scale(
		button,
		Vector2.ONE
	)

	if button == _selected_button:
		_apply_selected_style(button)
	else:
		_remove_custom_button_style(button)

func _animate_button_scale(
	button: Button,
	target_scale: Vector2
) -> void:
	var tween := create_tween()

	tween.set_trans(
		Tween.TRANS_QUAD
	)

	tween.set_ease(
		Tween.EASE_OUT
	)

	tween.tween_property(
		button,
		"scale",
		target_scale,
		button_animation_time
	)

func _apply_hover_style(
	button: Button
) -> void:
	var style := StyleBoxFlat.new()

	style.bg_color = Color(
		0.10,
		0.10,
		0.10,
		0.90
	)

	style.border_color = hover_border_color

	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3

	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4

	button.add_theme_stylebox_override(
		"normal",
		style
	)

	button.add_theme_stylebox_override(
		"hover",
		style
	)

func _apply_selected_style(
	button: Button
) -> void:
	var style := StyleBoxFlat.new()

	style.bg_color = selected_background_color

	style.border_color = selected_border_color

	style.border_width_left = 4
	style.border_width_top = 4
	style.border_width_right = 4
	style.border_width_bottom = 4

	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4

	button.add_theme_stylebox_override(
		"normal",
		style
	)

	button.add_theme_stylebox_override(
		"hover",
		style
	)

	button.add_theme_stylebox_override(
		"pressed",
		style
	)

	# Importante para manter o amarelo caso
	# o botão seja desativado após a escolha.
	button.add_theme_stylebox_override(
		"disabled",
		style
	)

	var name_label := _get_button_name_label(
		button
	)

	if name_label != null:
		name_label.add_theme_color_override(
			"font_color",
			selected_name_color
		)

func _get_button_name_label(
	button: Button
) -> Label:
	if button == null:
		return null

	return button.find_child(
		"NameLabel",
		true,
		false
	) as Label

func _remove_custom_button_style(
	button: Button
) -> void:
	button.remove_theme_stylebox_override(
		"normal"
	)

	button.remove_theme_stylebox_override(
		"hover"
	)

	button.remove_theme_stylebox_override(
		"pressed"
	)

	button.remove_theme_stylebox_override(
		"disabled"
	)

	var name_label := _get_button_name_label(
		button
	)

	if name_label != null:
		name_label.add_theme_color_override(
			"font_color",
			normal_name_color
		)

func _select_character_button(
	button: Button
) -> void:
	if button == null:
		return

	# Se já havia outro escolhido,
	# devolve ao estado normal.
	if (
		_selected_button != null
		and _selected_button != button
	):
		_remove_custom_button_style(
			_selected_button
		)

		_animate_button_scale(
			_selected_button,
			Vector2.ONE
		)

	_selected_button = button

	_apply_selected_style(
		button
	)

	_animate_button_scale(
		button,
		Vector2.ONE * button_hover_scale
	)
