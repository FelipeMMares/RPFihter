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

# Pode ficar vazio para usar player_controls.kick.
@export var mash_action: StringName = &""

@export_range(1, 30, 1)
var maximum_loops: int = 10


@export_group("HitBoxes do loop")

# Ordem sugerida:
# 0 = cabeça
# 1 = torso
# 2 = pés
@export var loop_hitboxes: Array[HitBox] = []


# Cada posição corresponde a um frame da animação.
#
# -1 = nenhuma HitBox
#  0 = loop_hitboxes[0]
#  1 = loop_hitboxes[1]
#  2 = loop_hitboxes[2]
#
# Exemplo:
# [0, -1, 1, -1, 2, -1]
#
# Frame 0: cabeça
# Frame 1: desligada
# Frame 2: torso
# Frame 3: desligada
# Frame 4: pés
# Frame 5: desligada
@export var frame_hitbox_pattern: Array[int] = [
	0,
	-1,
	1,
	-1,
	2,
	-1
]


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

var _loops_remaining: int = 1
var _total_loops: int = 1

var _entry_physics_frame: int = 0

# Evita chamar enable() várias vezes enquanto
# o AnimatedSprite continua no mesmo frame.
var _last_processed_animation_frame: int = -1

var _first_contact_resolved: bool = false
var _frustrated: bool = false

func _enter() -> void:
	_first_contact_resolved = false
	_frustrated = false

	_phase = AttackPhase.START

	_loops_remaining = 1
	_total_loops = 3

	_entry_physics_frame = (
		Engine.get_physics_frames()
	)

	_last_processed_animation_frame = -1

	move.emit(Vector2.ZERO)

	_disable_all_hitboxes()

	play_animation.emit(
		start_animation,
		false
	)

func _ready() -> void:
	for hitbox in loop_hitboxes:
		if hitbox == null:
			continue

		if not hitbox.hit_resolved.is_connected(
			_on_hitbox_resolved
		):
			hitbox.hit_resolved.connect(
				_on_hitbox_resolved
			)

func _physics_process(_delta: float) -> void:
	move.emit(Vector2.ZERO)

	_read_additional_kick_input()

	if _phase == AttackPhase.LOOP:
		_update_loop_hitboxes()
	else:
		_disable_all_hitboxes()


func _read_additional_kick_input() -> void:
	if _frustrated:
		return

	if _phase == AttackPhase.END:
		return

	# Não conta novamente o botão responsável
	# por iniciar o comando.
	if (
		Engine.get_physics_frames()
		<= _entry_physics_frame
	):
		return

	var selected_action: StringName = (
		mash_action
	)

	if (
		selected_action == &""
		and player_controls != null
	):
		selected_action = (
			player_controls.kick
		)

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
		"Hyakuretsu Kyaku ampliado | repetições: ",
		_total_loops,
		"/",
		maximum_loops
	)


func _update_loop_hitboxes() -> void:
	if _frustrated:
		_disable_all_hitboxes()
		return

	if animated_sprite == null:
		_disable_all_hitboxes()
		return

	if animated_sprite.animation != loop_animation:
		_disable_all_hitboxes()
		return

	var current_frame: int = (
		animated_sprite.frame
	)

	# O mesmo frame pode durar vários ciclos de física.
	# Só altera as HitBoxes quando o frame muda.
	if (
		current_frame
		== _last_processed_animation_frame
	):
		return

	_last_processed_animation_frame = (
		current_frame
	)

	# Todo novo frame começa desligando
	# as HitBoxes do frame anterior.
	_disable_all_hitboxes()

	if frame_hitbox_pattern.is_empty():
		return

	var pattern_position: int = (
		current_frame
		% frame_hitbox_pattern.size()
	)

	var hitbox_index: int = (
		frame_hitbox_pattern[
			pattern_position
		]
	)

	# -1 representa um frame sem impacto.
	if hitbox_index < 0:
		return

	if hitbox_index >= loop_hitboxes.size():
		printerr(
			"Hyakuretsu Kyaku: índice de HitBox inválido: ",
			hitbox_index
		)
		return

	var selected_hitbox: HitBox = (
		loop_hitboxes[hitbox_index]
	)

	if selected_hitbox == null:
		printerr(
			"Hyakuretsu Kyaku: HitBox ",
			hitbox_index,
			" não configurada."
		)
		return

	# enable() limpa _already_hit.
	# Portanto, cada frame ativo pode gerar
	# um novo golpe no combo.
	selected_hitbox.enable()


func _disable_all_hitboxes() -> void:
	for hitbox in loop_hitboxes:
		if hitbox != null:
			hitbox.disable()


func _animation_finished() -> void:
	if _frustrated:
		return

	_disable_all_hitboxes()

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
			transition_to.emit(
				return_state
			)


func _play_loop() -> void:
	_phase = AttackPhase.LOOP

	_last_processed_animation_frame = -1

	_disable_all_hitboxes()

	play_animation.emit(
		loop_animation,
		false
	)


func _play_end() -> void:
	_phase = AttackPhase.END

	_last_processed_animation_frame = -1

	_disable_all_hitboxes()

	play_animation.emit(
		end_animation,
		false
	)


func _exit() -> void:
	_first_contact_resolved = false
	_frustrated = false

	_disable_all_hitboxes()

	_last_processed_animation_frame = -1

	if character != null:
		character.velocity.x = 0.0

func _on_hitbox_resolved(
	_target: Area2D,
	combat_result: int
) -> void:
	if _frustrated:
		return

	if _first_contact_resolved:
		return

	if (
		combat_result
		== CombatHitResult.Type.IGNORED
	):
		return


	_first_contact_resolved = true


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


	_frustrated = true

	# Mesmo que o jogador já tenha apertado Kick
	# várias vezes durante START, perde todas
	# as repetições extras.
	_loops_remaining = 0
	_total_loops = 1

	_disable_all_hitboxes()

	move.emit(
		Vector2.ZERO
	)

	print(
		"Hyakuretsu Kyaku frustrado: "
		+ "primeiro impacto defendido."
	)

	call_deferred(
		"_finish_frustrated_hyakuretsu"
	)

func _finish_frustrated_hyakuretsu() -> void:
	if not _frustrated:
		return

	var state_machine := (
		get_parent()
		as StateMachine
	)

	if state_machine == null:
		return

	if (
		state_machine.get_current_state_name()
		!= StringName(name)
	):
		return

	transition_to.emit(
		return_state
	)
