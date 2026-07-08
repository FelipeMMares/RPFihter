extends Node
class_name StateMachine

@export var jump_method := "jump"
@export var move_method : String = "move"
@export var initial_state : State
@export var animated_sprite : AnimatedSprite2D
@export var player_controls : PlayerControls
@export var command_parser : CommandParser
@export var on_ready : bool = false

var _started : bool = false
var _current_state : State = null
var _character : CharacterBody2D
var _anim_request_id : int = 0

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
		
		child.set_process(false)
		child.set_physics_process(false)
		
	if initial_state and on_ready:
		initial_state._enter()
		initial_state.set_process(true)
		initial_state.set_physics_process(true)
		
		_current_state = initial_state
		
		_started = true
		
func _transition_to(new_state: String, previous_state: String) -> void:
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
	
	print("TRANSIÇÃO:", previous_state, " -> ", new_state)
#func _physics_process(delta: float) -> void:
	#print("current_state: ", _current_state.name)

func start() -> void:

	if _started:
		return
		
	_started = true
	
	if initial_state:
		_current_state = initial_state
		_current_state._enter()
		_current_state.set_process(true)
		_current_state.set_physics_process(true)

func _on_request_move_direction(direction: Vector2) -> void:
	if _character and _character.has_method(move_method):
		_character.call(move_method, direction)

func _on_request_jump() -> void:
	print("STATE MACHINE PEDIU PULO")

	if _character.has_method(jump_method):
		_character.call(jump_method)

func _on_request_play_animation(anim_name: String,
								backwards: bool = false,
								state: State = null) -> void:
	print("TOCANDO:", anim_name)
	print(animated_sprite.sprite_frames.get_animation_names())

	if backwards:
		animated_sprite.play_backwards(anim_name)
	else:
		animated_sprite.play(anim_name)
	if not animated_sprite:
		return

	_anim_request_id += 1
	var request_id := _anim_request_id

	if backwards:
		animated_sprite.play_backwards(anim_name)
	else:
		animated_sprite.play(anim_name)

	await  animated_sprite.animation_finished
	if state and state.has_method("_animation_finished"):
		state._animation_finished()
