extends Resource
class_name FrameVisualAdjustment


@export_range(0, 999, 1)
var frame: int = 0


@export_group("Offset")

@export var override_offset: bool = false

@export var offset: Vector2 = Vector2.ZERO


@export_group("Scale")

@export var override_scale: bool = false

@export var scale: Vector2 = Vector2.ONE
