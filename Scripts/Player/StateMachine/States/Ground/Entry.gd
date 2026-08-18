extends State
class_name EntryState

@export_group("Voice")

@export var special_voices: Array[AudioStream] = []

@export var animation_name: StringName = &"Entry"


@onready var character: CharacterBody2D = (
	get_parent().get_parent()
	as CharacterBody2D
)


func _enter() -> void:
	if character != null:
		character.velocity = Vector2.ZERO

		if character.has_method("end_guard"):
			character.call("end_guard")

	play_animation.emit(
		String(animation_name),
		false
	)

	_play_special_voice()

func _physics_process(_delta: float) -> void:
	if character != null:
		character.velocity = Vector2.ZERO


func _animation_finished() -> void:
	# Não vai para Idle automaticamente.
	# O FightManager fará essa transição quando
	# a mensagem "LUTEM!" aparecer.
	pass


func _exit() -> void:
	if character != null:
		character.velocity = Vector2.ZERO

func _play_special_voice() -> void:
	if special_voices.is_empty():
		return

	var character := (
		get_parent().get_parent()
		as CharacterBody2D
	)

	if character == null:
		return

	if not character.has_method(
		"play_random_voice"
	):
		return

	character.call(
		"play_random_voice",
		special_voices,
		true
	)
