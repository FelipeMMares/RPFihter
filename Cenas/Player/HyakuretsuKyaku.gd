extends State
class_name HyakuretsuKyakuState


enum AttackPhase {
	START,
	LOOP,
	END
}


@export_group("Animações")

@export var start_animation: StringName = (
	&"HyakuretsuKyakuStart"
)

@export var loop_animation: StringName = (
	&"HyakuretsuKyakuLoop"
)

@export var end_animation: StringName = (
	&"HyakuretsuKyakuEnd"
)


@export_group("Repetição")

# Ação completa do InputMap.
# Exemplo: Player1_kick
#
# Se ficar vazia, será usado player_controls.kick.
@export var mash_action: StringName = &""

# Quantas vezes a parte de chutes pode se repetir.
@export_range(1, 30, 1)
var maximum_loops: int = 10


@export_group("HitBox")

@export var hitbox: HitBox

# Frames ativos dentro da animação Loop.
@export var active_start_frame: int = 1
@export var active_end_frame: int = 2


@export_group("Transição")

@export var return_state: StringName = &"Idle"


@onready var character: CharacterBody2D = (
	get_parent().get_parent()
	as CharacterBody2D
)

@onready var animated_sprite: AnimatedSprite2D = (
	character.get_node_or_null("AnimatedSprite2D")
	as AnimatedSprite2D
)


var _phase: AttackPhase = AttackPhase.START

# Quantos loops ainda estão enfileirados.
var _loops_remaining: int = 1

# Total já autorizado pelo jogador.
var _total_loops: int = 1

var _hitbox_active: bool = false
var _entry_physics_frame: int = 0


func _enter() -> void:
	_phase = AttackPhase.START

	_loops_remaining = 1
	_total_loops = 1

	_hitbox_active = false
	_entry_physics_frame = Engine.get_physics_frames()

	move.emit(Vector2.ZERO)

	if hitbox != null:
		hitbox.disable()

	play_animation.emit(
		start_animation,
		false
	)


func _physics_process(_delta: float) -> void:
	move.emit(Vector2.ZERO)

	_read_additional_kick_input()

	if _phase == AttackPhase.LOOP:
		_update_loop_hitbox()
	else:
		_disable_hitbox()


func _read_additional_kick_input() -> void:
	if _phase == AttackPhase.END:
		return

	# Evita contar novamente o botão que ativou
	# o comando original no mesmo frame.
	if (
		Engine.get_physics_frames()
		<= _entry_physics_frame
	):
		return

	var selected_action: StringName = mash_action

	if (
		selected_action == &""
		and player_controls != null
	):
		selected_action = player_controls.kick

	if selected_action == &"":
		return

	if not Input.is_action_just_pressed(
		selected_action
	):
		return

	if _total_loops >= maximum_loops:
		return

	_total_loops += 1
	_loops_remaining += 1

	print(
		"Hyakuretsu Kyaku ampliado | loops: ",
		_total_loops,
		"/",
		maximum_loops
	)


func _update_loop_hitbox() -> void:
	if animated_sprite == null:
		return

	var current_frame: int = animated_sprite.frame

	var should_be_active: bool = (
		current_frame >= active_start_frame
		and current_frame <= active_end_frame
	)

	if should_be_active and not _hitbox_active:
		_hitbox_active = true

		if hitbox != null:
			hitbox.enable()

	elif not should_be_active and _hitbox_active:
		_disable_hitbox()


func _disable_hitbox() -> void:
	if not _hitbox_active:
		return

	_hitbox_active = false

	if hitbox != null:
		hitbox.disable()


func _animation_finished() -> void:
	_disable_hitbox()

	match _phase:
		AttackPhase.START:
			_play_loop()

		AttackPhase.LOOP:
			_loops_remaining -= 1

			if _loops_remaining > 0:
				_play_loop()
			else:
				_play_end()

		AttackPhase.END:
			transition_to.emit(return_state)


func _play_loop() -> void:
	_phase = AttackPhase.LOOP
	_hitbox_active = false

	if hitbox != null:
		hitbox.disable()

	play_animation.emit(
		loop_animation,
		false
	)


func _play_end() -> void:
	_phase = AttackPhase.END
	_hitbox_active = false

	if hitbox != null:
		hitbox.disable()

	play_animation.emit(
		end_animation,
		false
	)


func _exit() -> void:
	_disable_hitbox()

	if hitbox != null:
		hitbox.disable()

	if character != null:
		character.velocity.x = 0.0
