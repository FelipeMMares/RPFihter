extends Node2D
class_name ArenaVisual


@export_group("Animação da Arena")

@export var animation_name: StringName = &"ArenaLoop"

@export_group("Música da Arena")

@export var arena_music: AudioStream

@onready var arena_animated: AnimatedSprite2D = (
	$ArenaAnimated
)


func _ready() -> void:
	if arena_animated == null:
		printerr(
			name,
			": ArenaAnimated não encontrado."
		)
		return

	if arena_animated.sprite_frames == null:
		printerr(
			name,
			": SpriteFrames não configurado em ArenaAnimated."
		)
		return

	if not arena_animated.sprite_frames.has_animation(
		animation_name
	):
		printerr(
			name,
			": animação [",
			animation_name,
			"] não encontrada."
		)
		return

	arena_animated.play(
		animation_name
	)
