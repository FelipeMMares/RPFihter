extends Resource
class_name PlayerControls

@export var up : String
@export var down : String
@export var left : String
@export var right : String
@export var light_punch : String
@export var high_punch : String
@export var kick : String
@export var low_kick : String


func is_walking() -> bool:
	return Input.is_action_just_pressed(right) or\
			Input.is_action_just_pressed(left)

func is_jumping() -> bool:
	return Input.is_action_just_pressed(up)
	
func is_crounching() -> bool:
	return Input.is_action_just_pressed(down)
