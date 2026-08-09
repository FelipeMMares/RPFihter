extends Node
class_name StateMachine

@export var jump_method := "jump"
@export var move_method : String = "move"
@export var initial_state : State
@export var animated_sprite : AnimatedSprite2D
@export var player_controls : PlayerControls
@export var command_parser : CommandParser
@export var on_ready : bool = false

@export_group("Controle")

@export var player_input_enabled: bool = true

@export_group("Especial de carga")

@export var charge_special_enabled: bool = false

@export var charge_special_state: StringName = &""

@export var charge_special_button: String = (
	"lightPunch"
)

@export var charge_frames: int = 45

@export var charge_input_window: int = 8

@export var charge_release_window: int = 12

@export var charge_allowed_states: Array[StringName] = [
	&"Idle",
	&"Walk",
	&"Crouch",
	&"IdleCrouched",
	&"LightPunch"
]

@export_group("Agarrões")

@export var throwable_states: Array[StringName] = [
	&"Idle",
	&"Walk",
	&"Crouch",
	&"CrouchWhile",
	&"TryGrab"
]

var _started : bool = false
var _current_state : State = null
var _character : CharacterBody2D
var _anim_request_id : int = 0
var _round_result_locked: bool = false
var _round_result_state: StringName = &""
var _player_input_enabled: bool = true

func _ready() -> void:
	
	_character = get_parent()
	
	if _character is not CharacterBody2D:
		printerr("Character is not CharacterBody2D")
	
	if not _character.has_method(move_method):
		printerr("Character doesnt have \"%s\" method" % [move_method])
	
	for child in get_children():
		if child is not State:
			printerr("Removed %s because is not a State node!", child)
			remove_child(child)
	
	for child: State in get_children():
		
		var state_name : String = child.name
		
		child.transition_to.connect(_transition_to.bind(state_name))
		child.move.connect(_on_request_move_direction)
		child.jump.connect(_on_request_jump)
		child.play_animation.connect(_on_request_play_animation.bind(child))
		
		child.command_parser = command_parser
		child.player_controls = player_controls
		child.player_input_enabled = player_input_enabled
		
		child.set_process(false)
		child.set_physics_process(false)
		
	if initial_state and on_ready:
		initial_state._enter()
		initial_state.set_process(true)
		initial_state.set_physics_process(true)
		
		_current_state = initial_state
		
		_started = true
		
func _transition_to(new_state: String, previous_state: String) -> void:
	if _round_result_locked:
		return
	print("TRANSIÇÃO:", previous_state, " -> ", new_state)
	var new_state_node : State = get_node_or_null(new_state)
	
	var previous_state_node : State = get_node_or_null(previous_state)
	
	if not new_state_node or not previous_state_node:
		print("❌ Estado", new_state, "não encontrado!")
		printerr("%s or %s is null" % [new_state, previous_state])
		return
		
	previous_state_node.set_physics_process(false)
	previous_state_node.set_process(false)
	
	previous_state_node._exit()
	new_state_node._enter()
	
	new_state_node.set_physics_process(true)
	new_state_node.set_process(true)
	
	_current_state = new_state_node
	


func start() -> void:

	if _started:
		return
		
	_started = true
	
	if initial_state:
		_current_state = initial_state
		_current_state._enter()
		_current_state.set_process(true)
		_current_state.set_physics_process(true)

func _physics_process(
	_delta: float
) -> void:
	if not _started:
		return

	# CPU não interpreta comandos do jogador.
	if not player_input_enabled:
		return

	if _current_state == null:
		return

	if command_parser == null:
		return

	if animated_sprite == null:
		return

	if not charge_special_enabled:
		return

	if charge_special_state == &"":
		return

	if (
		StringName(_current_state.name)
		not in charge_allowed_states
	):
		return

	_try_detect_charge_special()

func _try_detect_charge_special() -> void:
	var back_action: String = "left"
	var forward_action: String = "right"

	# Determina frente/trás conforme o personagem
	# estiver olhando.
	if animated_sprite.flip_h:
		back_action = "right"
		forward_action = "left"

	var special_detected: bool = (
		command_parser.consume_charge_command(
			back_action,
			forward_action,
			charge_special_button,
			charge_frames,
			charge_input_window,
			charge_release_window
		)
	)

	if not special_detected:
		return

	if not has_state(charge_special_state):
		printerr(
			"StateMachine: especial de carga [",
			charge_special_state,
			"] não encontrado."
		)
		return

	print(
		"StateMachine: especial de carga detectado | ",
		back_action,
		" carregado → ",
		forward_action,
		" + ",
		charge_special_button,
		" | estado: ",
		charge_special_state
	)

	force_transition(
		charge_special_state
	)

func _on_request_move_direction(direction: Vector2) -> void:
	if _character and _character.has_method(move_method):
		_character.call(move_method, direction)

func _on_request_jump() -> void:
	#print("STATE MACHINE PEDIU PULO")

	if _character.has_method(jump_method):
		_character.call(jump_method)

func _on_request_play_animation(
	anim_name: String,
	backwards: bool = false,
	state: State = null
) -> void:
	if not animated_sprite:
		printerr("AnimatedSprite2D não configurado")
		return

	#print("StateMachine recebeu animação: ", anim_name)

	if not animated_sprite.sprite_frames.has_animation(anim_name):
		printerr("Animação não encontrada: ", anim_name)
		return

	if backwards:
		animated_sprite.play_backwards(anim_name)
	else:
		animated_sprite.play(anim_name)

	await animated_sprite.animation_finished

	if state and state.has_method("_animation_finished"):
		state._animation_finished()

func receive_hit(hit_data: HitData) -> void:
	var hurt_state = get_node_or_null("Hurt")

	if hurt_state == null:
		printerr("StateMachine: estado Hurt não encontrado.")
		return

	if hurt_state.has_method("set_hit_data"):
		hurt_state.set_hit_data(hit_data)

	if _current_state:
		_transition_to("Hurt", _current_state.name)

func force_transition(new_state: StringName) -> void:
	if _current_state == null:
		printerr("StateMachine: estado atual é nulo.")
		return

	var new_state_node := get_node_or_null(NodePath(new_state)) as State

	if new_state_node == null:
		printerr(
			"StateMachine: estado ",
			new_state,
			" não encontrado."
		)
		return

	if _current_state == new_state_node:
		return

	_transition_to(
		String(new_state),
		String(_current_state.name)
	)

func get_current_state_name() -> StringName:
	if _current_state == null:
		return &""

	return StringName(_current_state.name)


func has_state(state_name: StringName) -> bool:
	return (
		get_node_or_null(NodePath(state_name))
		is State
	)

func request_move(direction: Vector2) -> void:
	_on_request_move_direction(direction)

func can_be_thrown() -> bool:
	if _current_state == null:
		return false

	var current_state_name := StringName(
		_current_state.name
	)

	return current_state_name in throwable_states

func is_round_result_locked() -> bool:
	return _round_result_locked


func lock_round_result(
	state_name: StringName
) -> void:
	# Primeiro permite a transição para o resultado.
	_round_result_locked = false
	_round_result_state = state_name

	force_transition(state_name)

	# Depois bloqueia qualquer nova transição.
	_round_result_locked = true


func unlock_round_result() -> void:
	_round_result_locked = false
	_round_result_state = &""

func set_player_input_enabled(
	enabled: bool
) -> void:
	player_input_enabled = enabled

	for child in get_children():
		if child is not State:
			continue

		var state := child as State

		state.player_input_enabled = enabled
