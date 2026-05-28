extends Node
class_name StateMachine

@export var initial_state : State
@export var animated_sprite : AnimatedSprite2D
@export var player_controls : PlayerControls
@export var on_ready : bool = false


var _states : Dictionary [String, State] = {}
var _started : bool = false
var _current_state : State = null
var _character : CharacterBody2D

func _ready() -> void:
	
	_character = get_parent()
	
	var animated_sprite = get_node("../AnimatedSprite2D")
	if not animated_sprite:
		animated_sprite = get_tree().get_first_node_in_group("Idle")
	
	for child in get_children():
		
		if child is not State:
			continue
			
		var state_name : String = child.name
		_states[state_name] = child
		child.transition_to.connect(_transition_to.bind(state_name))
		child.animated_sprite = animated_sprite
		child.player_controls = player_controls
		child.character = _character
		
		child.set_process(false)
		child.set_physics_process(false)
		
	if initial_state and on_ready:
		initial_state._enter()
		initial_state.set_process(true)
		initial_state.set_physics_process(true)
		
		_current_state = initial_state
		
		_started = true
		
func _transition_to(new_state: String, previous_state: String) -> void:
	
	var new_state_node : State = get_node_or_null(new_state)
	var previous_state_node : State = get_node_or_null(previous_state)
	
	if not new_state_node or not previous_state:
		printerr("%s or %s is null" % [new_state, previous_state])
		return
		
	previous_state_node.set_physics_process(false)
	previous_state_node.set_process(false)
	
	previous_state_node._exit()
	new_state_node._enter()
	
	new_state_node.set_physics_process(true)
	new_state_node.set_process(true)
	
	_current_state = new_state_node
	
func _physics_process(delta: float) -> void:
	print("current_state: ", _current_state.name)

func start() -> void:

	if _started:
		return
		
	_started = true
	
	if initial_state:
		_current_state = initial_state
		_current_state._enter()
	
