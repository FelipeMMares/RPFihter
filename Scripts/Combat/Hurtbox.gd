extends Area2D
class_name HurtBox

signal hurt(hit_data: HitData)

func _ready() -> void:
	monitoring = true
	monitorable = true

	collision_layer = 2
	collision_mask = 0

	print(
		"HurtBox pronta: ",
		name,
		" layer: ",
		collision_layer,
		" mask: ",
		collision_mask
	)

func receive_hit(hit_data: HitData) -> void:
	print("HurtBox recebeu hit: ", hit_data)
	hurt.emit(hit_data)
