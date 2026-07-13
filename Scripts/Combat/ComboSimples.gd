extends State
class_name LightPunchComboState

@export_group("Animação")
@export var animation_name: StringName = &"LightPunch"

@export_group("Hitbox")
@export var hitbox: HitBox
@export var hit_data: HitData
@export var active_frame_start: int = 2
@export var active_frame_end: int = 3

@export_group("Continuação do combo")
@export var next_combo_state: StringName = &""
@export var input_window_start: int = 2
@export var input_window_end: int = 5
@export var transition_frame: int = 5

@export_group("Retorno")
@export var return_state: StringName = &"Idle"

var _is_active: bool = false
var _next_attack_buffered: bool = false
var _transition_requested: bool = false
var _hitbox_enabled: bool = false

var _entry_physics_frame: int = 0

@onready var state_machine: StateMachine = get_parent() as StateMachine
@onready var animated_sprite: AnimatedSprite2D = state_machine.animated_sprite


func _enter() -> void:
	_is_active = true
	_next_attack_buffered = false
	_transition_requested = false
	_hitbox_enabled = false

	_entry_physics_frame = Engine.get_physics_frames()

	move.emit(Vector2.ZERO)

	if hitbox != null:
		hitbox.end_attack()

	play_animation.emit(
		String(animation_name),
		false
	)


func _exit() -> void:
	_is_active = false
	_next_attack_buffered = false
	_transition_requested = false

	_disable_hitbox()


func _physics_process(_delta: float) -> void:
	if not _is_active:
		return

	if animated_sprite == null:
		return

	if animated_sprite.animation != animation_name:
		return

	var current_frame: int = animated_sprite.frame

	_update_hitbox(current_frame)
	_capture_next_input(current_frame)
	_try_continue_combo(current_frame)


func _capture_next_input(current_frame: int) -> void:
	if next_combo_state.is_empty():
		return

	if player_controls == null:
		return

	# Impede que o input que iniciou o golpe também seja
	# interpretado como o segundo golpe.
	if Engine.get_physics_frames() <= _entry_physics_frame:
		return

	if current_frame < input_window_start:
		return

	if current_frame > input_window_end:
		return

	if player_controls.just_light_punch():
		_next_attack_buffered = true

		print(
			animation_name,
			": próximo LightPunch armazenado no frame ",
			current_frame
		)


func _try_continue_combo(current_frame: int) -> void:
	if not _next_attack_buffered:
		return

	if _transition_requested:
		return

	if current_frame < transition_frame:
		return

	_go_to_next_combo_state()


func _go_to_next_combo_state() -> void:
	if next_combo_state.is_empty():
		return

	_transition_requested = true
	_disable_hitbox()

	print(
		animation_name,
		" → ",
		next_combo_state
	)

	transition_to.emit(
		String(next_combo_state)
	)


func _update_hitbox(current_frame: int) -> void:
	var should_be_enabled := (
		current_frame >= active_frame_start
		and current_frame <= active_frame_end
	)

	if should_be_enabled and not _hitbox_enabled:
		_enable_hitbox()
	elif not should_be_enabled and _hitbox_enabled:
		_disable_hitbox()


func _enable_hitbox() -> void:
	if hitbox == null:
		return

	if hit_data == null:
		printerr(
			name,
			": nenhum HitData configurado."
		)
		return

	_hitbox_enabled = true
	hitbox.begin_attack(hit_data)


func _disable_hitbox() -> void:
	if not _hitbox_enabled:
		return

	_hitbox_enabled = false

	if hitbox != null:
		hitbox.end_attack()


func _animation_finished() -> void:
	if not _is_active:
		return

	if _transition_requested:
		return

	_disable_hitbox()

	# Caso o input tenha sido armazenado perto do final da animação.
	if _next_attack_buffered and not next_combo_state.is_empty():
		_go_to_next_combo_state()
		return

	_transition_requested = true
	transition_to.emit(
		String(return_state)
	)
