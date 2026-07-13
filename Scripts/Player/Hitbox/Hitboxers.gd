extends Area2D
class_name HitBox

signal hit_confirmed(target: Area2D)

@export var hit_data: HitData

@onready var collision_shape: CollisionShape2D = $HitColision

var _already_hit: Array[Area2D] = []

func _ready() -> void:
	monitoring = false
	monitorable = true

	collision_layer = 0
	collision_mask = 2

	collision_shape.disabled = true

	area_entered.connect(_on_area_entered)

	print("HitBox pronta: ", name, " hit_data: ", hit_data)

func enable() -> void:
	print("HitBox ligada: ", name)

	_already_hit.clear()

	collision_shape.set_deferred("disabled", false)
	set_deferred("monitoring", true)

func disable() -> void:
	print("HitBox desligada: ", name)

	set_deferred("monitoring", false)
	collision_shape.set_deferred("disabled", true)

func _on_area_entered(area: Area2D) -> void:
	print("Área detectada: ", area.name)

	if not area is HurtBox:
		return

	if area in _already_hit:
		return

	_already_hit.append(area)

	print("HitBox acertou HurtBox")
	area.receive_hit(hit_data)

	# Avisa que o ataque acertou.
	hit_confirmed.emit(area)

func begin_attack(new_hit_data: HitData) -> void:
	hit_data = new_hit_data

	# Limpa os personagens já atingidos na ativação anterior.
	_already_hit.clear()

	set_deferred("monitoring", true)

	for child in get_children():
		if child is CollisionShape2D:
			child.set_deferred("disabled", false)


func end_attack() -> void:
	set_deferred("monitoring", false)

	for child in get_children():
		if child is CollisionShape2D:
			child.set_deferred("disabled", true)
