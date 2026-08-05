extends Node2D


@export var animation_name: StringName = &"AnimatedBackground"


@onready var animated_sprite: AnimatedSprite2D = (
	$AnimatedSprite2D
)


func _ready() -> void:
	if animated_sprite == null:
		printerr(
			"PropsAnimated: AnimatedSprite2D não encontrado."
		)
		return

	if animated_sprite.sprite_frames == null:
		printerr(
			"PropsAnimated: SpriteFrames não configurado."
		)
		return

	if not animated_sprite.sprite_frames.has_animation(
		animation_name
	):
		printerr(
			"PropsAnimated: animação [",
			animation_name,
			"] não encontrada."
		)
		return

	animated_sprite.play(animation_name)
