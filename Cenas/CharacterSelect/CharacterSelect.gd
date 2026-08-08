extends Control
class_name CharacterSelect


@export_group("Cena de luta")

@export_file("*.tscn")
var fight_scene_path: String = (
	"res://Cenas/Cenarios/CenaDaLuta.tscn"
)


@export_group("Preview dos personagens")

@export var chun_li_frames: SpriteFrames
@export var elena_frames: SpriteFrames

@export_range(0.5, 10.0, 0.1)
var idle_before_taunt_time: float = 3.0


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


@onready var locked_buttons: Array[Button] = [
	$MainMargin/MainRow/SelectionPanel/SelectionColumn/CharacterGrid/LockedButton,
	$MainMargin/MainRow/SelectionPanel/SelectionColumn/CharacterGrid/LockedButton2,
	$MainMargin/MainRow/SelectionPanel/SelectionColumn/CharacterGrid/LockedButton3,
	$MainMargin/MainRow/SelectionPanel/SelectionColumn/CharacterGrid/LockedButton4
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


func _ready() -> void:
	get_tree().paused = false

	update_message.visible = false

	_configure_timers()
	_connect_buttons()

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

	# Mouse em cima do personagem troca o preview.
	chun_li_button.mouse_entered.connect(
		_preview_chun_li
	)

	elena_button.mouse_entered.connect(
		_preview_elena
	)

	# Também funciona com teclado/controle.
	chun_li_button.focus_entered.connect(
		_preview_chun_li
	)

	elena_button.focus_entered.connect(
		_preview_elena
	)

	for button in locked_buttons:
		button.pressed.connect(
			_on_locked_character_pressed
		)


func _preview_chun_li() -> void:
	if _character_confirmed:
		return

	_show_fighter_preview(
		chun_li_frames,
		"CHUN-LI"
	)


func _preview_elena() -> void:
	if _character_confirmed:
		return

	_show_fighter_preview(
		elena_frames,
		"ELENA"
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

	# Garante que Chun-Li esteja aparecendo,
	# mesmo se o mouse/foco ainda estava em outro botão.
	_preview_chun_li()

	FighterSelection.select_chun_li()

	await _confirm_selection()


func _on_elena_pressed() -> void:
	if _character_confirmed:
		return

	_preview_elena()

	FighterSelection.select_elena()

	await _confirm_selection()


func _confirm_selection() -> void:
	_character_confirmed = true

	preview_timer.stop()
	message_timer.stop()

	update_message.visible = false

	# Impede o jogador de trocar de personagem
	# durante a animação Victory.
	chun_li_button.disabled = true
	elena_button.disabled = true

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
		# Caso ainda não tenha Victory configurada.
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
			"CharacterSelect: caminho da luta vazio."
		)
		return

	if not ResourceLoader.exists(
		fight_scene_path
	):
		printerr(
			"CharacterSelect: cena não encontrada: ",
			fight_scene_path
		)
		return

	var change_error: Error = (
		get_tree().change_scene_to_file(
			fight_scene_path
		)
	)

	if change_error != OK:
		printerr(
			"CharacterSelect: erro ao abrir luta: ",
			change_error
		)
