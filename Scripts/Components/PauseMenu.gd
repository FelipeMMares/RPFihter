extends Control


@export var pause_action: StringName = &"pause"

@onready var continue_button: Button = (
	$Background/MenuPosition/VBoxContainer/ContinueButton
)

@onready var restart_button: Button = (
	$Background/MenuPosition/VBoxContainer/RestartButton
)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	continue_button.pressed.connect(_resume_game)
	restart_button.pressed.connect(_restart_fight)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(pause_action):
		return

	if get_tree().paused:
		_resume_game()
	else:
		_pause_game()

	get_viewport().set_input_as_handled()


func _pause_game() -> void:
	visible = true
	get_tree().paused = true

	continue_button.grab_focus()


func _resume_game() -> void:
	get_tree().paused = false
	visible = false


func _restart_fight() -> void:
	# É importante despausar antes de recarregar.
	get_tree().paused = false
	get_tree().reload_current_scene()


func _exit_tree() -> void:
	# Evita que outra cena fique pausada caso esta
	# seja removida enquanto o menu está aberto.
	if get_tree() != null:
		get_tree().paused = false
