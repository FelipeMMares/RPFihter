extends State
class_name MultiHitSpecialState


@export_group("Animação")

# Se estiver vazio, usa o nome do nó do estado.
@export var animation_name: StringName = &""

@export_group("Ajuste visual")

# Desloca apenas o desenho da animação.
# Não altera a posição global do personagem.
@export var animation_sprite_offset: Vector2 = Vector2.ZERO

# Faz o deslocamento horizontal acompanhar
# a direção para a qual o personagem está olhando.
@export var mirror_offset_x: bool = true

@export_group("HitBoxes")

# Todas as HitBoxes que esse especial pode utilizar.
@export var hitboxes: Array[HitBox] = []

# Sequência de ativação das HitBoxes.
@export var hitbox_steps: Array[FrameHitboxStep] = []


@export_group("Movimento")

@export var horizontal_velocity: float = 0.0

# Valor negativo lança para cima.
@export var vertical_velocity_on_enter: float = 0.0

@export var stop_horizontal_on_exit: bool = true


@export_group("Transição")

@export var return_state: StringName = &"Idle"

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

# -2 representa que a sequência ainda
# não foi processada.
var _current_step_index: int = -2

var _original_sprite_offset: Vector2 = Vector2.ZERO
var _sprite_offset_applied: bool = false

func _enter() -> void:
	_current_step_index = -2

	if animated_sprite != null:
		_original_sprite_offset = animated_sprite.offset

		var final_offset: Vector2 = (
			animation_sprite_offset
		)

		if mirror_offset_x:
			final_offset.x *= _facing_direction

		animated_sprite.offset = (
			_original_sprite_offset
			+ final_offset
		)

		_sprite_offset_applied = true

	_disable_all_hitboxes()

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

	character.velocity.x = (
		horizontal_velocity
		* _facing_direction
	)

	_update_frame_hitboxes()


func _update_frame_hitboxes() -> void:
	if animated_sprite == null:
		_disable_all_hitboxes()
		return

	var new_step_index: int = (
		_find_step_for_frame(
			animated_sprite.frame
		)
	)

	# Permanece na mesma etapa.
	# Não chama enable() novamente.
	if new_step_index == _current_step_index:
		return

	_disable_all_hitboxes()

	_current_step_index = new_step_index

	# Nenhuma etapa configurada para esse frame.
	if _current_step_index < 0:
		return

	var step: FrameHitboxStep = (
		hitbox_steps[
			_current_step_index
		]
	)

	if step == null:
		return

	for hitbox_index in step.hitbox_indices:
		_enable_hitbox_by_index(
			hitbox_index
		)


func _find_step_for_frame(
	current_frame: int
) -> int:
	for index in range(
		hitbox_steps.size()
	):
		var step: FrameHitboxStep = (
			hitbox_steps[index]
		)

		if step == null:
			continue

		var first_frame: int = mini(
			step.start_frame,
			step.end_frame
		)

		var last_frame: int = maxi(
			step.start_frame,
			step.end_frame
		)

		if (
			current_frame >= first_frame
			and current_frame <= last_frame
		):
			return index

	return -1


func _enable_hitbox_by_index(
	hitbox_index: int
) -> void:
	if hitbox_index < 0:
		return

	if hitbox_index >= hitboxes.size():
		printerr(
			name,
			": índice de HitBox inválido: ",
			hitbox_index
		)
		return

	var selected_hitbox: HitBox = (
		hitboxes[hitbox_index]
	)

	if selected_hitbox == null:
		printerr(
			name,
			": HitBox ",
			hitbox_index,
			" não configurada."
		)
		return

	selected_hitbox.enable()


func _disable_all_hitboxes() -> void:
	for hitbox in hitboxes:
		if hitbox != null:
			hitbox.disable()


func _animation_finished() -> void:
	_disable_all_hitboxes()

	_current_step_index = -2

	if (
		return_to_jump_if_airborne
		and character != null
		and not character.is_on_floor()
	):
		transition_to.emit(
			airborne_return_state
		)
		return

	transition_to.emit(
		return_state
	)


func _exit() -> void:
	_disable_all_hitboxes()

	_current_step_index = -2
	if (
		_sprite_offset_applied
		and animated_sprite != null
	):
		animated_sprite.offset = (
			_original_sprite_offset
		)

		_sprite_offset_applied = false
	
	if (
		stop_horizontal_on_exit
		and character != null
	):
		character.velocity.x = 0.0
