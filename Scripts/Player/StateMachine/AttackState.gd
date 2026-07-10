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
	var sprite := get_parent().get_parent().get_node("AnimatedSprite2D") as AnimatedSprite2D

	if sprite == null or hitbox == null:
		return

	var current_frame := sprite.frame

	if current_frame >= active_start_frame and current_frame <= active_end_frame:
		if not _hitbox_active:
			_hitbox_active = true
			print("ATIVANDO HITBOX NO FRAME: ", current_frame)
			hitbox.enable()
	else:
		if _hitbox_active:
			_hitbox_active = false
			print("DESATIVANDO HITBOX NO FRAME: ", current_frame)
			hitbox.disable()

func _exit() -> void:
	_hitbox_active = false

	if hitbox:
		hitbox.disable()

func _animation_finished() -> void:
	if hitbox:
		hitbox.disable()

	transition_to.emit(next_state)
