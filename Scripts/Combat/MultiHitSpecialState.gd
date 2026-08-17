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

@export_group("Frustração por defesa")

@export var frustrate_on_first_guard: bool = true

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

var _expected_animation: StringName = &""
var _entry_physics_frame: int = -1

var _first_contact_resolved: bool = false
var _frustrated: bool = false

func _enter() -> void:
	_first_contact_resolved = false
	_frustrated = false

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

	_expected_animation = (
		animation_name
		if animation_name != &""
		else StringName(name)
	)

	_entry_physics_frame = Engine.get_physics_frames()

	if animated_sprite == null:
		printerr(
			name,
			": AnimatedSprite2D não encontrado."
		)
		transition_to.emit(return_state)
		return

	if animated_sprite.sprite_frames == null:
		printerr(
			name,
			": SpriteFrames não configurado."
		)
		transition_to.emit(return_state)
		return

	if not animated_sprite.sprite_frames.has_animation(
		_expected_animation
	):
		printerr(
			name,
			": animação não encontrada: ",
			_expected_animation
		)
		transition_to.emit(return_state)
		return

	print(
		"ENTROU NO ESTADO ",
		name,
		" | tocando animação: ",
		_expected_animation
	)

	play_animation.emit(
		String(_expected_animation),
		false
	)

func _ready() -> void:
	for hitbox in hitboxes:
		if hitbox == null:
			continue

		if not hitbox.hit_resolved.is_connected(
			_on_hitbox_resolved
		):
			hitbox.hit_resolved.connect(
				_on_hitbox_resolved
			)

func _physics_process(_delta: float) -> void:
	if _frustrated:
		_disable_all_hitboxes()

		if character != null:
			character.velocity.x = 0.0

		return

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
	if _frustrated:
		return
	# Evita que o término da animação anterior
	# encerre o especial no mesmo frame em que ele entrou.
	if (
		Engine.get_physics_frames()
		<= _entry_physics_frame
	):
		print(
			name,
			": animation_finished anterior ignorado."
		)
		return

	if animated_sprite == null:
		return

	# Só encerra quando a animação realmente executada
	# pelo especial terminar.
	if (
		StringName(animated_sprite.animation)
		!= _expected_animation
	):
		print(
			name,
			": término de outra animação ignorado: ",
			animated_sprite.animation
		)
		return

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

	transition_to.emit(return_state)

func _exit() -> void:
	_disable_all_hitboxes()

	_first_contact_resolved = false
	_frustrated = false

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

func _is_multi_activation_special() -> bool:
	var valid_hitbox_count: int = 0

	for hitbox in hitboxes:
		if hitbox != null:
			valid_hitbox_count += 1

	# Mais de uma HitBox diferente.
	if valid_hitbox_count > 1:
		return true


	var activation_count: int = 0

	for step in hitbox_steps:
		if step == null:
			continue

		if step.hitbox_indices.is_empty():
			continue

		activation_count += 1

	# Uma mesma HitBox ativada em mais
	# de uma janela também é multi-hit.
	return activation_count > 1

func _on_hitbox_resolved(
	_target: Area2D,
	combat_result: int
) -> void:
	if _frustrated:
		return

	if _first_contact_resolved:
		return

	# IGNORED não conta como primeiro impacto.
	if (
		combat_result
		== CombatHitResult.Type.IGNORED
	):
		return


	# A partir daqui o primeiro impacto
	# realmente foi resolvido.
	_first_contact_resolved = true


	# Se acertou normalmente, o especial
	# continua e nunca mais verifica esta regra.
	if (
		combat_result
		== CombatHitResult.Type.HIT
	):
		return


	if (
		combat_result
		!= CombatHitResult.Type.GUARD
	):
		return


	if not frustrate_on_first_guard:
		return


	if not _is_multi_activation_special():
		return


	_frustrate_special()

func _frustrate_special() -> void:
	if _frustrated:
		return

	_frustrated = true

	print(
		name,
		": especial frustrado pela defesa "
		+ "do primeiro impacto."
	)

	_disable_all_hitboxes()

	_current_step_index = -2

	if character != null:
		character.velocity.x = 0.0

	call_deferred(
		"_finish_frustrated_special"
	)

func _finish_frustrated_special() -> void:
	if not _frustrated:
		return

	var state_machine := (
		get_parent()
		as StateMachine
	)

	if state_machine == null:
		return

	# O personagem pode ter sido interrompido
	# por Hurt/FallDefeated nesse meio-tempo.
	if (
		state_machine.get_current_state_name()
		!= StringName(name)
	):
		return

	transition_to.emit(
		return_state
	)
