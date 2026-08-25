extends Node
class_name AnimationVisualController


@export_group("Configuração")

@export var enabled: bool = true

@export var force_every_frame: bool = true

@export var animated_sprite: AnimatedSprite2D

@export var visual_profile: AnimationVisualProfile

@export var debug_visual: bool = false

@export var mirror_offset_when_flipped: bool = true

var _default_offset: Vector2 = Vector2.ZERO
var _default_scale: Vector2 = Vector2.ONE

var _adjustment_map: Dictionary = {}

var _initialized: bool = false

var _last_debug_animation: StringName = &""
var _last_debug_frame: int = -1


func _ready() -> void:
	process_priority = 1000

	if animated_sprite == null:
		printerr(
			"AnimationVisualController: "
			+ "AnimatedSprite2D não configurado."
		)
		return

	_default_offset = animated_sprite.offset
	_default_scale = animated_sprite.scale

	_build_adjustment_map()

	_initialized = true

	if not animated_sprite.animation_changed.is_connected(
		_on_animation_changed
	):
		animated_sprite.animation_changed.connect(
			_on_animation_changed
		)

	if not animated_sprite.frame_changed.is_connected(
		_on_frame_changed
	):
		animated_sprite.frame_changed.connect(
			_on_frame_changed
		)

	# ALTERADO
	call_deferred("_apply_current_visual")


func _process(
	_delta: float
) -> void:
	if not _initialized:
		return

	if not enabled:
		return

	if not force_every_frame:
		return

	# Força a configuração correta mesmo que
	# outro código tenha alterado offset/scale.
	_apply_current_visual()


func _build_adjustment_map() -> void:
	_adjustment_map.clear()

	if visual_profile == null:
		return

	for adjustment in visual_profile.animation_adjustments:
		if adjustment == null:
			continue

		if adjustment.animation_name.is_empty():
			continue

		_adjustment_map[
			adjustment.animation_name
		] = adjustment


func _on_animation_changed() -> void:
	# Faz novamente de forma deferred para garantir
	# que a troca de animação terminou antes do ajuste.
	call_deferred(
		"_apply_current_visual"
	)


func _on_frame_changed() -> void:
	call_deferred(
		"_apply_current_visual"
	)


func _apply_current_visual() -> void:
	if animated_sprite == null:
		return

	if not enabled:
		_restore_default_visual()
		return

	var animation_name := StringName(
		animated_sprite.animation
	)

	var final_offset: Vector2 = (
		_default_offset
	)

	var final_scale: Vector2 = (
		_default_scale
	)

	if _adjustment_map.has(
		animation_name
	):
		var adjustment := (
			_adjustment_map[
				animation_name
			]
			as AnimationVisualAdjustment
		)

		if adjustment != null:
			# ------------------------------
			# CONFIGURAÇÃO DA ANIMAÇÃO
			# ------------------------------

			if adjustment.override_offset:
				final_offset = (
					adjustment.offset
				)

			if adjustment.override_scale:
				final_scale = (
					adjustment.scale
				)

			# ------------------------------
			# CONFIGURAÇÃO DO FRAME
			# ------------------------------

			var frame_adjustment := (
				adjustment.get_frame_adjustment(
					animated_sprite.frame
				)
			)

			if frame_adjustment != null:
				if frame_adjustment.override_offset:
					final_offset = (
						frame_adjustment.offset
					)

				if frame_adjustment.override_scale:
					final_scale = (
						frame_adjustment.scale
					)


	# ============================================
	# NOVO: ESPELHA O OFFSET JUNTO COM O SPRITE
	# ============================================

	if (
		mirror_offset_when_flipped
		and animated_sprite.flip_h
	):
		final_offset.x = -final_offset.x


	animated_sprite.offset = (
		final_offset
	)

	animated_sprite.scale = (
		final_scale
	)

	_debug_current_visual(
		animation_name,
		final_offset,
		final_scale
	)


func _restore_default_visual() -> void:
	if animated_sprite == null:
		return

	animated_sprite.offset = (
		_default_offset
	)

	animated_sprite.scale = (
		_default_scale
	)


func set_visual_profile(
	new_profile: AnimationVisualProfile
) -> void:
	visual_profile = new_profile

	_build_adjustment_map()

	if enabled:
		call_deferred(
			"_apply_current_visual"
		)


func set_enabled(
	value: bool
) -> void:
	enabled = value

	if not enabled:
		_restore_default_visual()
		return

	call_deferred(
		"_apply_current_visual"
	)


func _debug_current_visual(
	animation_name: StringName,
	final_offset: Vector2,
	final_scale: Vector2
) -> void:
	if not debug_visual:
		return

	if (
		animation_name == _last_debug_animation
		and animated_sprite.frame == _last_debug_frame
	):
		return

	_last_debug_animation = animation_name
	_last_debug_frame = animated_sprite.frame

	print(
		"VISUAL FORÇADO | ",
		animated_sprite.get_path(),
		" | animação: ",
		animation_name,
		" | frame: ",
		animated_sprite.frame,
		" | flip_h: ",
		animated_sprite.flip_h,
		" | offset: ",
		final_offset,
		" | scale: ",
		final_scale
	)
