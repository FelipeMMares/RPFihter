extends AttackState

var _character : CharacterBody2D
@onready var hitbox : HitBox = _character.light_punch_hitbox

func _enter():

	super._enter()

	hitbox.monitoring = true

	print("Soco leve")

	_character.light_punch_hitbox.enable()
