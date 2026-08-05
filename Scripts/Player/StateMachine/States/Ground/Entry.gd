extends State
class_name EntryState


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
