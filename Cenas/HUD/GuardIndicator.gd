extends Control
class_name GuardIndicator


@onready var ring_progress: TextureProgressBar = (
	$RingProgress
)

@onready var shield: AnimatedSprite2D = (
	$Shield
)


func _ready() -> void:
	reset_guard()


func update_guard(
	current_value: float,
	max_value: float
) -> void:
	if max_value <= 0.0:
		return

	var ratio: float = clampf(
		current_value / max_value,
		0.0,
		1.0
	)

	# Aqui estamos tratando a barra como "pressão":
	# defesa cheia = barra vazia
	# defesa acabando = barra cheia
	ring_progress.value = (
		1.0 - ratio
	) * 100.0

	_update_shield_frame(
		ratio
	)


func break_guard() -> void:
	ring_progress.value = 100.0

	if shield.sprite_frames == null:
		return

	var frame_count: int = (
		shield.sprite_frames.get_frame_count(
			shield.animation
		)
	)

	if frame_count > 0:
		shield.frame = frame_count - 1


func reset_guard() -> void:
	if ring_progress != null:
		ring_progress.value = 0.0

	if shield != null:
		shield.frame = 0


func _update_shield_frame(
	guard_ratio: float
) -> void:
	if shield.sprite_frames == null:
		return

	var frame_count: int = (
		shield.sprite_frames.get_frame_count(
			shield.animation
		)
	)

	if frame_count <= 1:
		return

	var last_frame: int = frame_count - 1

	var damage_ratio: float = (
		1.0 - guard_ratio
	)

	var target_frame: int = int(
		floor(
			damage_ratio
			* float(last_frame)
		)
	)

	# O último frame fica reservado
	# exclusivamente para Guard Break.
	target_frame = clampi(
		target_frame,
		0,
		maxi(0, last_frame - 1)
	)

	shield.frame = target_frame
