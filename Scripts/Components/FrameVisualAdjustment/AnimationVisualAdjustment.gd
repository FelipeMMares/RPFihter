@tool
extends Resource
class_name AnimationVisualAdjustment


@export var animation_name: StringName = &""


@export_group("Offset padrão")

@export var override_offset: bool = false

@export var offset: Vector2 = Vector2.ZERO


@export_group("Scale padrão")

@export var override_scale: bool = false

@export var scale: Vector2 = Vector2.ONE


@export_group("Ajustes por frame")

@export var frame_adjustments: Array[FrameVisualAdjustment] = []


func get_frame_adjustment(
	frame_index: int
) -> FrameVisualAdjustment:
	for adjustment in frame_adjustments:
		if adjustment == null:
			continue

		if adjustment.frame == frame_index:
			return adjustment

	return null
