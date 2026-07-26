extends State
class_name AttackState
@export var next_state: String = "Idle"
@export var hitbox: HitBox
@export var active_start_frame: int = 1
@export var active_end_frame: int = 3

var _hitbox_active: bool = false

func _enter() -> void:
	_hitbox_active = false

	if hitbox:
		hitbox.disable()

	print("AttackState entrou: ", name)
	print("Hitbox referenciada: ", hitbox)

	play_animation.emit(name, false)

func _physics_process(_delta: float) -> void:
	var sprite := get_parent().get_parent().get_node_or_null(
		"AnimatedSprite2D"
	) as AnimatedSprite2D

	if sprite == null:
		printerr(name, ": AnimatedSprite2D não encontrado.")
		return

	if hitbox == null:
		printerr(name, ": HitBox não configurada.")
		return

	var current_frame: int = sprite.frame

	var should_be_active: bool = (
		current_frame >= active_start_frame
		and current_frame <= active_end_frame
	)

	if should_be_active:
		if not _hitbox_active:
			_hitbox_active = true

			print(
				"ATIVANDO HITBOX | personagem: ",
				get_parent().get_parent().name,
				" | estado: ",
				name,
				" | frame: ",
				current_frame,
				" | hitbox: ",
				hitbox.name
			)

			hitbox.enable()
	else:
		if _hitbox_active:
			_hitbox_active = false

			print(
				"DESATIVANDO HITBOX | frame: ",
				current_frame
			)

			hitbox.disable()

func _exit() -> void:
	_hitbox_active = false

	if hitbox:
		hitbox.disable()

func _animation_finished() -> void:
	if hitbox:
		hitbox.disable()

	transition_to.emit(next_state)
