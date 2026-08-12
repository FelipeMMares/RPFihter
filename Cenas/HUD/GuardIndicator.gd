extends Control
class_name GuardIndicator

signal guard_changed(
	current_hits: int,
	max_hits: int
)

signal guard_broken
signal guard_reset

@onready var ring_progress: AnimatedSprite2D = (
	$RingProgress
)

@onready var shield: AnimatedSprite2D = (
	$Shield
)


func _ready() -> void:
	ring_progress.pause()
	shield.pause()

	reset_guard()


func update_guard(
	current_hits: int,
	max_hits: int
) -> void:
	if max_hits <= 0:
		return

	var progress: float = clampf(
		float(current_hits) / float(max_hits),
		0.0,
		1.0
	)

	print(
		"GUARD UI | ",
		current_hits,
		"/",
		max_hits,
		" | progresso: ",
		progress
	)

	_update_ring_frame(
		progress
	)

	_update_shield_frame(
		progress
	)


func _update_ring_frame(
	progress: float
) -> void:
	if ring_progress.sprite_frames == null:
		return

	var frame_count: int = (
		ring_progress.sprite_frames.get_frame_count(
			ring_progress.animation
		)
	)

	if frame_count <= 0:
		return

	var last_frame: int = (
		frame_count - 1
	)

	var target_frame: int = roundi(
		progress * float(last_frame)
	)

	target_frame = clampi(
		target_frame,
		0,
		last_frame
	)

	ring_progress.frame = target_frame
	ring_progress.pause()

	print(
		"RING FRAME: ",
		target_frame
	)


func _update_shield_frame(
	progress: float
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

	var last_frame: int = (
		frame_count - 1
	)

	# Último frame fica reservado
	# exclusivamente para Guard Break.
	var last_normal_frame: int = (
		last_frame - 1
	)

	var target_frame: int = roundi(
		progress
		* float(last_normal_frame)
	)

	target_frame = clampi(
		target_frame,
		0,
		last_normal_frame
	)

	shield.frame = target_frame
	shield.pause()

	print(
		"SHIELD FRAME: ",
		target_frame
	)


func break_guard() -> void:
	print("GUARD UI: QUEBROU")

	_set_last_frame(
		ring_progress
	)

	_set_last_frame(
		shield
	)


func reset_guard() -> void:
	if ring_progress != null:
		ring_progress.frame = 0
		ring_progress.pause()

	if shield != null:
		shield.frame = 0
		shield.pause()


func _set_last_frame(
	sprite: AnimatedSprite2D
) -> void:
	if sprite == null:
		return

	if sprite.sprite_frames == null:
		return

	var frame_count: int = (
		sprite.sprite_frames.get_frame_count(
			sprite.animation
		)
	)

	if frame_count <= 0:
		return

	sprite.frame = frame_count - 1
	sprite.pause()
