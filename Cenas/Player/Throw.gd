extends State
class_name ThrowState


@export_group("Referências")

@export var throw_box: ThrowBox
@export var throw_anchor: Marker2D


@export_group("Frames de captura")

@export var grab_start_frame: int = 2
@export var grab_end_frame: int = 4


@export_group("Trajetória")

# Uma posição local para cada frame da animação.
# A trajetória deve ser criada considerando
# um arremesso para a direita.
@export var target_path: Array[Vector2] = []

# Rotação visual da vítima em cada frame.
@export var target_rotation_by_frame: Array[float] = []


@export_group("Direção")

# Ative somente no Throw da Chun-Li.
@export var allow_direction_choice: bool = false

# Caso nenhuma direção seja pressionada,
# arremessa para a frente.
@export var use_forward_as_default: bool = true


@export_group("Arremesso")

@export var throw_damage: int = 150

# X será multiplicado pela direção escolhida.
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

# -1 = esquerda
#  1 = direita
var _selected_direction: float = 0.0

var _original_anchor_position: Vector2


func _ready() -> void:
	if throw_anchor != null:
		_original_anchor_position = (
			throw_anchor.position
		)

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
	_selected_direction = 0.0

	move.emit(Vector2.ZERO)

	if throw_box != null:
		throw_box.disable()

	if throw_anchor != null:
		throw_anchor.position = (
			_original_anchor_position
		)

	_read_player_throw_direction()

	play_animation.emit(name, false)


func _physics_process(_delta: float) -> void:
	move.emit(Vector2.ZERO)

	if animated_sprite == null:
		return

	var current_frame: int = animated_sprite.frame

	# Se já capturou, movimenta a vítima de acordo
	# com a trajetória configurada.
	if _grabbed_target != null:
		_apply_throw_pose(current_frame)
		return

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


func _read_player_throw_direction() -> void:
	if not allow_direction_choice:
		return

	if player_controls == null:
		return

	var input_direction: float = Input.get_axis(
		player_controls.left,
		player_controls.right
	)

	if not is_zero_approx(input_direction):
		_selected_direction = signf(
			input_direction
		)


func _on_target_found(
	hurtbox_area: Area2D
) -> void:
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

	if not target.has_method(
		"begin_throw_capture"
	):
		return

	var attacker := _get_character()

	if attacker == null:
		return

	# Se o Player não selecionou uma direção,
	# ou se for o Dummy, usa a direção do alvo.
	if is_zero_approx(_selected_direction):
		_selected_direction = signf(
			target.global_position.x
			- attacker.global_position.x
		)

	if is_zero_approx(_selected_direction):
		_selected_direction = 1.0

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

	_apply_throw_pose(
		animated_sprite.frame
	)

	print(
		"Throw conectou | alvo: ",
		target.name,
		" | direção: ",
		_selected_direction
	)


func _apply_throw_pose(
	current_frame: int
) -> void:
	if throw_anchor == null:
		return

	if not target_path.is_empty():
		var path_index := clampi(
			current_frame,
			0,
			target_path.size() - 1
		)

		var path_position: Vector2 = (
			target_path[path_index]
		)

		# A trajetória é desenhada para a direita.
		# Ao arremessar para a esquerda, o eixo X
		# é invertido.
		throw_anchor.position = Vector2(
			path_position.x * _selected_direction,
			path_position.y
		)

	if (
		_grabbed_target != null
		and not target_rotation_by_frame.is_empty()
		and _grabbed_target.has_method(
			"set_throw_visual_rotation"
		)
	):
		var rotation_index := clampi(
			current_frame,
			0,
			target_rotation_by_frame.size() - 1
		)

		var rotation_value: float = (
			target_rotation_by_frame[
				rotation_index
			]
		)

		_grabbed_target.call(
			"set_throw_visual_rotation",
			rotation_value
			* _selected_direction
		)


func _animation_finished() -> void:
	if throw_box != null:
		throw_box.disable()

	if _grabbed_target != null:
		if _grabbed_target.has_method(
			"reset_throw_visual_rotation"
		):
			_grabbed_target.call(
				"reset_throw_visual_rotation"
			)

		var final_velocity := Vector2(
			absf(throw_velocity.x)
			* _selected_direction,
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

	if throw_anchor != null:
		throw_anchor.position = (
			_original_anchor_position
		)

	if _grabbed_target != null:
		if _grabbed_target.has_method(
			"reset_throw_visual_rotation"
		):
			_grabbed_target.call(
				"reset_throw_visual_rotation"
			)

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
