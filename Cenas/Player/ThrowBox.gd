extends Area2D
class_name ThrowBox


signal target_found(hurtbox: Area2D)


var _enabled: bool = false
var _target_already_found: bool = false
var _owner_character: CharacterBody2D


func _ready() -> void:
	_owner_character = _find_character()

	collision_layer = 0
	collision_mask = 0
	set_collision_mask_value(2, true)

	monitoring = false
	monitorable = false

	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)


func enable() -> void:
	_enabled = true
	_target_already_found = false

	set_deferred("monitoring", true)
	call_deferred("_scan_current_overlaps")


func disable() -> void:
	_enabled = false
	set_deferred("monitoring", false)


func _on_area_entered(area: Area2D) -> void:
	_try_target(area)


func _scan_current_overlaps() -> void:
	await get_tree().physics_frame

	if not _enabled:
		return

	for area in get_overlapping_areas():
		_try_target(area)

		if _target_already_found:
			return


func _try_target(area: Area2D) -> void:
	if not _enabled:
		return

	if _target_already_found:
		return

	if area == null:
		return

	if not area.has_method("get_character"):
		return

	var target := area.call("get_character") as CharacterBody2D

	if target == null:
		return

	if target == _owner_character:
		return

	if not target.has_method("can_be_thrown"):
		return

	if not bool(target.call("can_be_thrown")):
		return

	_target_already_found = true
	target_found.emit(area)


func _find_character() -> CharacterBody2D:
	var current_node: Node = get_parent()

	while current_node != null:
		if current_node is CharacterBody2D:
			return current_node as CharacterBody2D

		current_node = current_node.get_parent()

	return null
