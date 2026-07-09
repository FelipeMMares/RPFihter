extends Area2D
class_name HitBox

@export var damage := 10
@export var hitstun := 12
@export var pushback := 25.0

func _ready():
	disable()

func enable():
	monitoring = true
	monitorable = true

func disable():
	monitoring = false
	monitorable = false
