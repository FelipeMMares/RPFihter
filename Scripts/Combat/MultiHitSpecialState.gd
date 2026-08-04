extends State
class_name MultiHitSpecialState


@export_group("Animação")

# Se ficar vazio, será usado o nome do nó do estado.
@export var animation_name: StringName = &""


@export_group("HitBox")

@export var hitbox: HitBox

# Cada Vector2i representa:
# X = primeiro frame ativo
# Y = último frame ativo
#
# Exemplo:
# [(3, 4), (7, 8)]
# produz dois impactos separados.
@export var active_windows: Array[Vector2i] = []


@export_group("Movimento")

# Velocidade horizontal real em pixels por segundo.
@export var horizontal_velocity: float = 0.0

# Valor negativo impulsiona para cima.
# Zero não altera a velocidade vertical.
@export var vertical_velocity_on_enter: float = 0.0

@export var stop_horizontal_on_exit: bool = true


@export_group("Transição")

@export var return_state: StringName = &"Idle"

# Use em golpes que podem terminar ainda no ar,
# como Scratch Wheel.
@export var return_to_jump_if_airborne: bool = false

@export var airborne_return_state: StringName = &"Jump"


@onready var character: CharacterBody2D = (
	get_parent().get_parent()
	as CharacterBody2D
)

@onready var animated_sprite: AnimatedSprite2D = (
	character.get_node_or_null("AnimatedSprite2D")
	as AnimatedSprite2D
)


var _facing_direction: float = 1.0
var _active_window_index: int = -1


func _enter() -> void:
	_active_window_index = -1

	if hitbox != null:
		hitbox.disable()

	if animated_sprite != null:
		_facing_direction = (
			-1.0
			if animated_sprite.flip_h
			else 1.0
		)

	if character != null:
		character.velocity.x = (
			horizontal_velocity
			* _facing_direction
		)

		if not is_zero_approx(
			vertical_velocity_on_enter
		):
			character.velocity.y = (
				vertical_velocity_on_enter
			)

	var selected_animation: StringName = (
		animation_name
		if animation_name != &""
		else StringName(name)
	)

	play_animation.emit(
		selected_animation,
		false
	)


func _physics_process(_delta: float) -> void:
	if character == null:
		return

	# Mantém a velocidade horizontal especial
	# enquanto a animação estiver em execução.
	character.velocity.x = (
		horizontal_velocity
		* _facing_direction
	)

	if animated_sprite == null:
		return

	var new_window_index: int = (
		_get_active_window_index(
			animated_sprite.frame
		)
	)

	if new_window_index == _active_window_index:
		return

	# Saiu da janela anterior.
	if hitbox != null:
		hitbox.disable()

	_active_window_index = new_window_index

	# Entrou em uma nova janela.
	# enable() limpa _already_hit, permitindo que
	# o próximo impacto acerte o mesmo alvo novamente.
	if (
		_active_window_index >= 0
		and hitbox != null
	):
		hitbox.enable()


func _get_active_window_index(
	current_frame: int
) -> int:
	for index in range(active_windows.size()):
		var window: Vector2i = active_windows[index]

		var start_frame: int = mini(
			window.x,
			window.y
		)

		var end_frame: int = maxi(
			window.x,
			window.y
		)

		if (
			current_frame >= start_frame
			and current_frame <= end_frame
		):
			return index

	return -1


func _animation_finished() -> void:
	if hitbox != null:
		hitbox.disable()

	_active_window_index = -1

	if (
		return_to_jump_if_airborne
		and character != null
		and not character.is_on_floor()
	):
		transition_to.emit(
			airborne_return_state
		)
		return

	transition_to.emit(return_state)


func _exit() -> void:
	if hitbox != null:
		hitbox.disable()

	_active_window_index = -1

	if (
		stop_horizontal_on_exit
		and character != null
	):
		character.velocity.x = 0.0
