extends State
class_name ThrowState


@export_group("Referências")

@export var throw_box: ThrowBox
@export var throw_anchor: Marker2D


@export_group("Frames do agarrão")

@export var grab_start_frame: int = 2
@export var grab_end_frame: int = 4


@export_group("Arremesso")

@export var throw_damage: int = 150

# X é a força horizontal.
# Y negativo arremessa para cima.
@export var throw_velocity: Vector2 = Vector2(
	300.0,
	-450.0
)

@export var return_state: StringName = &"Idle"


@onready var animated_sprite: AnimatedSprite2D = (
	get_parent()
	.get_parent()
	.get_node_or_null("AnimatedSprite2D")
	as AnimatedSprite2D
)


var _grabbed_target: CharacterBody2D
var _throw_box_active: bool = false
var _state_active: bool = false


func _ready() -> void:
	if throw_box == null:
		return

	if not throw_box.target_found.is_connected(
		_on_target_found
	):
		throw_box.target_found.connect(
			_on_target_found
		)


func _enter() -> void:
	_state_active = true
	_grabbed_target = null
	_throw_box_active = false

	move.emit(Vector2.ZERO)

	if throw_box != null:
		throw_box.disable()

	play_animation.emit(name, false)


func _physics_process(_delta: float) -> void:
	move.emit(Vector2.ZERO)

	if _grabbed_target != null:
		return

	if animated_sprite == null:
		return

	var current_frame := animated_sprite.frame

	var should_be_active := (
		current_frame >= grab_start_frame
		and current_frame <= grab_end_frame
	)

	if should_be_active and not _throw_box_active:
		_throw_box_active = true

		if throw_box != null:
			throw_box.enable()

	elif not should_be_active and _throw_box_active:
		_throw_box_active = false

		if throw_box != null:
			throw_box.disable()


func _on_target_found(hurtbox_area: Area2D) -> void:
	if not _state_active:
		return

	if _grabbed_target != null:
		return

	if hurtbox_area == null:
		return

	if not hurtbox_area.has_method("get_character"):
		return

	var target := (
		hurtbox_area.call("get_character")
		as CharacterBody2D
	)

	if target == null:
		return

	if not target.has_method("begin_throw_capture"):
		return

	var attacker := _get_character()

	var captured := bool(
		target.call(
			"begin_throw_capture",
			attacker,
			throw_anchor
		)
	)

	if not captured:
		return

	_grabbed_target = target

	_throw_box_active = false

	if throw_box != null:
		throw_box.disable()

	print(
		"Throw conectou | alvo: ",
		target.name
	)


func _animation_finished() -> void:
	if throw_box != null:
		throw_box.disable()

	if _grabbed_target != null:
		var attacker := _get_character()

		var direction: float = 1.0

		if attacker != null and throw_anchor != null:
			direction = signf(
				throw_anchor.global_position.x
				- attacker.global_position.x
			)

		if is_zero_approx(direction):
			direction = 1.0

		var final_velocity := Vector2(
			absf(throw_velocity.x) * direction,
			throw_velocity.y
		)

		_grabbed_target.call(
			"release_from_throw",
			throw_damage,
			final_velocity
		)

		_grabbed_target = null

	transition_to.emit(return_state)


func _exit() -> void:
	_state_active = false
	_throw_box_active = false

	if throw_box != null:
		throw_box.disable()

	# Proteção caso o Throw seja interrompido antes
	# do fim da animação.
	if _grabbed_target != null:
		if _grabbed_target.has_method(
			"cancel_throw_capture"
		):
			_grabbed_target.call(
				"cancel_throw_capture"
			)

		_grabbed_target = null


func _get_character() -> CharacterBody2D:
	var current_node: Node = get_parent()

	while current_node != null:
		if current_node is CharacterBody2D:
			return current_node as CharacterBody2D

		current_node = current_node.get_parent()

	return null
