extends Node2D
class_name HitSpark


enum SparkType {
	LIGHT,
	HEAVY,
	SPECIAL
}


@onready var animated_sprite: AnimatedSprite2D = (
	$AnimatedSprite2D
)


func _ready() -> void:
	animated_sprite.animation_finished.connect(
		_on_animation_finished
	)


func play_spark(
	spark_type: int,
	world_position: Vector2
) -> void:
	global_position = world_position

	match spark_type:
		SparkType.LIGHT:
			animated_sprite.play(
				&"LightHit"
			)

		SparkType.HEAVY:
			animated_sprite.play(
				&"HeavyHit"
			)

		SparkType.SPECIAL:
			animated_sprite.play(
				&"SpecialHit"
			)


func _on_animation_finished() -> void:
	queue_free()
