extends Node
class_name MagicPoints


signal mp_changed(
	current_mp: float,
	maximum_mp: float
)


@export_group("Capacidade")

# Quantos especiais podem ser armazenados.
@export_range(1.0, 10.0, 1.0)
var max_mp: float = 3.0

# MP disponível no começo da luta ou após reset.
@export_range(0.0, 10.0, 0.1)
var starting_mp: float = 1.0


@export_group("Recuperação")

# Recuperação gradual por segundo.
@export_range(0.0, 5.0, 0.01)
var passive_regeneration_per_second: float = 0.08

# Recuperação concedida por golpe que causar dano.
@export_range(0.0, 5.0, 0.05)
var mp_gain_per_successful_hit: float = 0.25


var current_mp: float = 0.0
var regeneration_enabled: bool = false


func _ready() -> void:
	current_mp = clampf(
		starting_mp,
		0.0,
		max_mp
	)

	mp_changed.emit(
		current_mp,
		max_mp
	)


func _physics_process(delta: float) -> void:
	if not regeneration_enabled:
		return

	if current_mp >= max_mp:
		return

	add_mp(
		passive_regeneration_per_second
		* delta
	)


func can_spend(
	amount: float = 1.0
) -> bool:
	if amount <= 0.0:
		return true

	return current_mp >= amount


func try_spend(
	amount: float = 1.0
) -> bool:
	if not can_spend(amount):
		return false

	set_mp(
		current_mp - amount
	)

	return true


func add_mp(amount: float) -> void:
	if amount <= 0.0:
		return

	set_mp(
		current_mp + amount
	)


func gain_from_successful_hit(
	multiplier: float = 1.0
) -> void:
	add_mp(
		mp_gain_per_successful_hit
		* maxf(multiplier, 0.0)
	)


func set_mp(new_value: float) -> void:
	var clamped_value := clampf(
		new_value,
		0.0,
		max_mp
	)

	if is_equal_approx(
		clamped_value,
		current_mp
	):
		return

	current_mp = clamped_value

	mp_changed.emit(
		current_mp,
		max_mp
	)


func reset_mp() -> void:
	set_mp(max_mp)


func fill_mp() -> void:
	set_mp(max_mp)


func set_regeneration_enabled(
	enabled: bool
) -> void:
	regeneration_enabled = enabled
