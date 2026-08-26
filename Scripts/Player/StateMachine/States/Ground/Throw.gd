extends State
class_name ThrowState

@export_group("Animação")

@export var throw_animation: StringName = &"Throw"

@export_group("Movimento visual da vítima")

# Ative apenas no Throw do Dummy.
@export var move_victim_during_throw: bool = false

# Cada elemento é um deslocamento relativo à posição
# em que a vítima foi capturada.
@export var victim_path_by_frame: Array[Vector2] = []

# Rotação visual da vítima em cada frame.
@export var target_rotation_by_frame: Array[float] = []


@export_group("Direção")

# Ativado somente no Throw da Chun-Li.
@export var allow_direction_choice: bool = false

# Ativado somente no Throw do Dummy.
# Faz a vítima ser lançada atrás do Dummy.
@export var launch_opposite_to_target_side: bool = false


@export_group("Arremesso")

@export var throw_damage: int = 150

# Valor configurado no Inspector.
@export var throw_velocity: Vector2 = Vector2(
	100.0,
	-80.0
)

@export_range(1.0, 30.0, 0.5)
var horizontal_throw_multiplier: float = 10.0

@export var return_state: StringName = &"Idle"

@export_group("Impacto")

@export var release_frame: int = -1

@onready var animated_sprite: AnimatedSprite2D = (
	get_parent()
	.get_parent()
	.get_node_or_null("AnimatedSprite2D")
	as AnimatedSprite2D
)


var _grabbed_target: CharacterBody2D = null

# Direção em que a vítima será lançada.
var _selected_direction: float = 0.0

# Lado em que a vítima estava em relação ao atacante.
#  1 = vítima estava à direita
# -1 = vítima estava à esquerda
var _target_side_direction: float = 0.0

var _victim_start_position: Vector2 = Vector2.ZERO

var _throw_completed: bool = false
var _attacker_locked: bool = false

var _victim_released: bool = false

func _enter() -> void:
	_victim_released = false
	_grabbed_target = null

	_selected_direction = 0.0
	_target_side_direction = 0.0

	_throw_completed = false
	_attacker_locked = false

	move.emit(Vector2.ZERO)

	var attacker := _get_character()

	if attacker == null:
		transition_to.emit(return_state)
		return

	if not attacker.has_method("is_throw_attacker"):
		transition_to.emit(return_state)
		return

	if not bool(attacker.call("is_throw_attacker")):
		printerr(
			"ThrowState: personagem não está "
			+ "reservado como atacante: ",
			attacker.name
		)

		transition_to.emit(return_state)
		return

	# Recebe a vítima confirmada pelo TryGrab.
	if attacker.has_method("consume_grab_target"):
		_grabbed_target = (
			attacker.call("consume_grab_target")
			as CharacterBody2D
		)

	if not is_instance_valid(_grabbed_target):
		printerr(
			"ThrowState: alvo confirmado não encontrado."
		)

		_grabbed_target = null
		transition_to.emit(return_state)
		return

	if (
		not _grabbed_target.has_method("is_throw_victim")
		or not bool(
			_grabbed_target.call("is_throw_victim")
		)
	):
		printerr(
			"ThrowState: alvo não está reservado "
			+ "como vítima: ",
			_grabbed_target.name
		)

		_grabbed_target = null
		transition_to.emit(return_state)
		return

	_victim_start_position = (
		_grabbed_target.global_position
	)

	# Lado em que a vítima estava quando o Throw começou.
	_target_side_direction = signf(
		_grabbed_target.global_position.x
		- attacker.global_position.x
	)

	if is_zero_approx(_target_side_direction):
		_target_side_direction = 1.0

	# Trava a posição do atacante.
	if attacker.has_method("begin_throw_attacker_lock"):
		attacker.call("begin_throw_attacker_lock")
		_attacker_locked = true

	# Chun-Li: usa a direção escolhida pelo jogador.
	if allow_direction_choice:
		if attacker.has_method(
			"consume_throw_direction"
		):
			_selected_direction = float(
				attacker.call(
					"consume_throw_direction"
				)
			)

	# Dummy: lança para o lado oposto ao Player.
	elif launch_opposite_to_target_side:
		_selected_direction = (
			-_target_side_direction
		)

	# Comportamento padrão: lança para o lado
	# em que a vítima estava.
	else:
		_selected_direction = (
			_target_side_direction
		)

	if is_zero_approx(_selected_direction):
		_selected_direction = (
			_target_side_direction
		)

	print(
		"Throw iniciado | atacante: ",
		attacker.name,
		" | vítima: ",
		_grabbed_target.name,
		" | lado inicial: ",
		_target_side_direction,
		" | direção do lançamento: ",
		_selected_direction
	)

	play_animation.emit(
		throw_animation,
		false
	)


func _physics_process(_delta: float) -> void:
	move.emit(Vector2.ZERO)

	if _victim_released:
		return

	if not is_instance_valid(_grabbed_target):
		return

	if animated_sprite == null:
		return

	var current_frame := animated_sprite.frame

	_apply_throw_pose(current_frame)

	if (
		release_frame >= 0
		and current_frame >= release_frame
	):
		_release_victim()


func _apply_throw_pose(
	current_frame: int
) -> void:
	if not is_instance_valid(_grabbed_target):
		return

	_apply_victim_path(current_frame)
	_apply_victim_rotation(current_frame)


func _apply_victim_path(
	current_frame: int
) -> void:
	if not move_victim_during_throw:
		return

	if victim_path_by_frame.is_empty():
		return

	if not _grabbed_target.has_method(
		"set_throw_capture_position"
	):
		return

	var path_index := clampi(
		current_frame,
		0,
		victim_path_by_frame.size() - 1
	)

	var path_offset: Vector2 = (
		victim_path_by_frame[path_index]
	)

	var path_direction: float = (
		_selected_direction
		if allow_direction_choice
		else _target_side_direction
	)

	var mirrored_offset := Vector2(
		path_offset.x * path_direction,
		path_offset.y
	)

	var new_position := (
		_victim_start_position
		+ mirrored_offset
	)

	_grabbed_target.call(
		"set_throw_capture_position",
		new_position
	)


func _apply_victim_rotation(
	current_frame: int
) -> void:
	if target_rotation_by_frame.is_empty():
		return

	if not _grabbed_target.has_method(
		"set_throw_visual_rotation"
	):
		return

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

	# No Throw do Dummy, a rotação acompanha o lado
	# em que a vítima começou.
	#
	# No Throw da Chun-Li, acompanha a direção escolhida.
	var rotation_direction: float = (
		_selected_direction
		if allow_direction_choice
		else _target_side_direction
	)

	_grabbed_target.call(
		"set_throw_visual_rotation",
		rotation_value * rotation_direction
	)


func _animation_finished() -> void:
	if not is_instance_valid(_grabbed_target):
		transition_to.emit(return_state)
		return

	_throw_completed = true

	if _grabbed_target.has_method(
		"reset_throw_visual_rotation"
	):
		_grabbed_target.call(
			"reset_throw_visual_rotation"
		)

	var final_horizontal_velocity: float = (
		absf(throw_velocity.x)
		* horizontal_throw_multiplier
	)

	var final_velocity := Vector2(
		final_horizontal_velocity
		* _selected_direction,
		throw_velocity.y
	)

	var attacker := _get_character()

	print(
		"Throw terminou | atacante: ",
		attacker.name if attacker != null else "null",
		" | vítima: ",
		_grabbed_target.name,
		" | velocidade: ",
		final_velocity
	)

	# Somente a vítima recebe a velocidade.
	_grabbed_target.call(
		"release_from_throw",
		throw_damage,
		final_velocity
	)

	_grabbed_target = null

	transition_to.emit(return_state)


func _exit() -> void:
	var attacker := _get_character()

	if (
		_attacker_locked
		and attacker != null
		and attacker.has_method(
			"end_throw_attacker_lock"
		)
	):
		attacker.call("end_throw_attacker_lock")

	_attacker_locked = false

	if (
		attacker != null
		and attacker.has_method(
			"release_throw_attacker_reservation"
		)
	):
		attacker.call(
			"release_throw_attacker_reservation"
		)

	# Se o Throw for interrompido antes de terminar,
	# libera a vítima.
	if (
		not _throw_completed
		and is_instance_valid(_grabbed_target)
		and _grabbed_target.has_method(
			"cancel_throw_capture"
		)
	):
		_grabbed_target.call(
			"cancel_throw_capture"
		)

	_grabbed_target = null


func _get_character() -> CharacterBody2D:
	return (
		get_parent().get_parent()
		as CharacterBody2D
	)

func _release_victim() -> void:
	if _victim_released:
		return

	if not is_instance_valid(_grabbed_target):
		return

	_victim_released = true

	if _grabbed_target.has_method(
		"reset_throw_visual_rotation"
	):
		_grabbed_target.call(
			"reset_throw_visual_rotation"
		)

	var final_horizontal_velocity: float = (
		absf(throw_velocity.x)
		* horizontal_throw_multiplier
	)

	var final_velocity := Vector2(
		final_horizontal_velocity
		* _selected_direction,
		throw_velocity.y
	)

	_grabbed_target.call(
		"release_from_throw",
		throw_damage,
		final_velocity
	)

	_grabbed_target = null
