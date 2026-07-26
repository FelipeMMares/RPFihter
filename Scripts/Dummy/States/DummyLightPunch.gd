extends AttackState


func _enter() -> void:
	active_start_frame = 12
	active_end_frame = 14

	super._enter()

	print(
		"Dummy LightPunch: hitbox ativa do frame ",
		active_start_frame,
		" ao ",
		active_end_frame
	)
