extends Node
class_name Health

# Emitido sempre que a vida mudar.
signal health_changed(current_health: int, max_health: int)

# Emitido quando a vida chega a zero.
signal defeated

@export var max_health: int = 1000

var current_health: int = 0


func _ready() -> void:
	current_health = max_health

	print(
		get_parent().name,
		" iniciou com ",
		current_health,
		" de vida."
	)

	health_changed.emit(current_health, max_health)


func take_damage(amount: int) -> void:
	if amount <= 0:
		return

	if current_health <= 0:
		return

	current_health = clampi(
		current_health - amount,
		0,
		max_health
	)

	print(
		get_parent().name,
		" recebeu ",
		amount,
		" de dano. Vida atual: ",
		current_health,
		"/",
		max_health
	)

	health_changed.emit(current_health, max_health)

	if current_health == 0:
		defeated.emit()


func heal(amount: int) -> void:
	if amount <= 0:
		return

	if current_health <= 0:
		return

	current_health = clampi(
		current_health + amount,
		0,
		max_health
	)

	health_changed.emit(current_health, max_health)


func reset_health() -> void:
	current_health = max_health

	health_changed.emit(current_health, max_health)


func is_defeated() -> bool:
	return current_health <= 0


func get_health_percentage() -> float:
	if max_health <= 0:
		return 0.0

	return float(current_health) / float(max_health)
