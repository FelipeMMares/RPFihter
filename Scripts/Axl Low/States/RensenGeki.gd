extends State


@export_group("Animação")

@export var animation_name: StringName = (
	&"RensenGeki"
)


@export_group("Efeito")

@export_node_path("Node2D")
var chain_effect_path: NodePath


# Para cada frame da animação do Axl,
# informa qual estágio da corrente usar.
#
# -1 = corrente escondida
# 0  = curta
# 4  = máxima
#
@export var stage_by_frame: PackedInt32Array = (
	PackedInt32Array([
		-1,
		-1,
		0,
		1,
		2,
		3,
		4,
		4,
		3,
		2,
		1,
		0,
		-1
	])
)


@export_group("Frames ativos")

@export_range(0, 60, 1)
var active_start_frame: int = 2

@export_range(0, 60, 1)
var active_end_frame: int = 11


@export_group("Estado")

@export var return_state: StringName = &"Idle"


var _chain_effect: AxlChainEffect = null


func _enter() -> void:
	move.emit(
		Vector2.ZERO
	)

	var character := _get_character()

	if character != null:
		_chain_effect = (
			character.get_node_or_null(
				chain_effect_path
			) as AxlChainEffect
		)

	if _chain_effect != null:
		_chain_effect.begin(
			character,
			_get_facing_direction()
		)

	play_animation.emit(
		String(animation_name),
		false
	)


func _physics_process(
	_delta: float
) -> void:
	# Axl não anda enquanto executa o Rensen.
	move.emit(
		Vector2.ZERO
	)

	var state_machine := (
		get_parent() as StateMachine
	)

	if state_machine == null:
		return

	var sprite := (
		state_machine.animated_sprite
	)

	if sprite == null:
		return

	if (
		StringName(sprite.animation)
		!= animation_name
	):
		return

	var current_frame := sprite.frame

	_update_chain_stage(
		current_frame
	)

	_update_hitbox(
		current_frame
	)


func _update_chain_stage(
	current_frame: int
) -> void:
	if _chain_effect == null:
		return

	var stage := -1

	if (
		current_frame >= 0
		and current_frame
		< stage_by_frame.size()
	):
		stage = (
			stage_by_frame[
				current_frame
			]
		)

	_chain_effect.set_stage(
		stage
	)


func _update_hitbox(
	current_frame: int
) -> void:
	if _chain_effect == null:
		return

	var active := (
		current_frame
		>= active_start_frame
		and current_frame
		<= active_end_frame
	)

	_chain_effect.set_hitbox_active(
		active
	)


func _exit() -> void:
	if _chain_effect != null:
		_chain_effect.finish()

	_chain_effect = null


func _animation_finished() -> void:
	if _chain_effect != null:
		_chain_effect.finish()

	transition_to.emit(
		return_state
	)


func _get_character() -> CharacterBody2D:
	return (
		get_parent().get_parent()
		as CharacterBody2D
	)


func _get_facing_direction() -> float:
	var state_machine := (
		get_parent() as StateMachine
	)

	if state_machine == null:
		return 1.0

	if state_machine.animated_sprite == null:
		return 1.0

	if state_machine.animated_sprite.flip_h:
		return -1.0

	return 1.0
