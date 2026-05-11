extends Node

const State = preload("res://Scripts/Player/State.gd")

@export var current_state : State

var states : Dictionary [String, State] = {}

func _ready() -> void:
	
	for child in get_children():
		
		if child is not State:
			continue
			
		var state_name : String = child.name.to_lower()
		states[state_name] = child
		child.transition_to.connect(_transition_to.bind(state_name))
		child.set_process(false)
		child.set_physics_process(false)
		
	if current_state :
		current_state._enter()
		
func _transition_to(new_state: String, previous_state: String) -> void:
	pass
	
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
