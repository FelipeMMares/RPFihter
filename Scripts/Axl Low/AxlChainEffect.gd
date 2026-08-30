extends Node2D
class_name AxlChainEffect


enum ExtensionAxis {
	HORIZONTAL,
	VERTICAL_UP,
	VERTICAL_DOWN
}


@export_group("Referências")

@export var chain_sprite: Sprite2D

@export var hitbox: HitBox

@export var collision_shape: CollisionShape2D


@export_group("Sprites")

@export var textures: Array[Texture2D] = []

@export var stage_lengths: PackedFloat32Array = (
	PackedFloat32Array()
)


@export_group("Hitbox")

@export var extension_axis: ExtensionAxis = (
	ExtensionAxis.HORIZONTAL
)

@export var hitbox_thickness: float = 28.0

@export var hitbox_start_padding: float = 20.0


var _hitbox_active: bool = false

var _base_scale_x: float = 1.0


func _ready() -> void:
	_base_scale_x = absf(scale.x)

	finish()


func begin(
	owner_character: CharacterBody2D,
	facing: float
) -> void:
	visible = true

	scale.x = (
		_base_scale_x
		* (
			1.0
			if facing >= 0.0
			else -1.0
		)
	)

	if hitbox != null:
		hitbox.set_owner_character(
			owner_character
		)

	set_hitbox_active(false)


func set_stage(
	stage_index: int
) -> void:
	if chain_sprite == null:
		return

	if textures.is_empty():
		return

	if (
		stage_index < 0
		or stage_index >= textures.size()
	):
		visible = false
		set_hitbox_active(false)
		return

	visible = true

	var texture := textures[stage_index]

	if texture == null:
		return

	chain_sprite.texture = texture
	chain_sprite.centered = false

	var length := _get_stage_length(
		stage_index,
		texture
	)

	_update_visual(
		texture
	)

	_update_collision(
		length
	)


func _get_stage_length(
	stage_index: int,
	texture: Texture2D
) -> float:
	if stage_index < stage_lengths.size():
		return stage_lengths[stage_index]

	match extension_axis:
		ExtensionAxis.HORIZONTAL:
			return float(
				texture.get_width()
			)

		ExtensionAxis.VERTICAL_UP, \
		ExtensionAxis.VERTICAL_DOWN:
			return float(
				texture.get_height()
			)

	return 1.0


func _update_visual(
	texture: Texture2D
) -> void:
	var width := float(
		texture.get_width()
	)

	var height := float(
		texture.get_height()
	)

	match extension_axis:
		ExtensionAxis.HORIZONTAL:
			chain_sprite.position = Vector2(
				0.0,
				-height * 0.5
			)

		ExtensionAxis.VERTICAL_DOWN:
			chain_sprite.position = Vector2(
				-width * 0.5,
				0.0
			)

		ExtensionAxis.VERTICAL_UP:
			chain_sprite.position = Vector2(
				-width * 0.5,
				-height
			)


func _update_collision(
	total_length: float
) -> void:
	if collision_shape == null:
		return

	var rectangle := (
		collision_shape.shape
		as RectangleShape2D
	)

	if rectangle == null:
		return

	var usable_length := maxf(
		total_length - hitbox_start_padding,
		1.0
	)

	match extension_axis:
		ExtensionAxis.HORIZONTAL:
			rectangle.size = Vector2(
				usable_length,
				hitbox_thickness
			)

			collision_shape.position = Vector2(
				hitbox_start_padding
				+ usable_length * 0.5,
				0.0
			)

		ExtensionAxis.VERTICAL_DOWN:
			rectangle.size = Vector2(
				hitbox_thickness,
				usable_length
			)

			collision_shape.position = Vector2(
				0.0,
				hitbox_start_padding
				+ usable_length * 0.5
			)

		ExtensionAxis.VERTICAL_UP:
			rectangle.size = Vector2(
				hitbox_thickness,
				usable_length
			)

			collision_shape.position = Vector2(
				0.0,
				-hitbox_start_padding
				- usable_length * 0.5
			)


func set_hitbox_active(
	active: bool
) -> void:
	if hitbox == null:
		return

	if active == _hitbox_active:
		return

	_hitbox_active = active

	if active:
		hitbox.enable()
	else:
		hitbox.disable()


func finish() -> void:
	set_hitbox_active(false)

	visible = false
