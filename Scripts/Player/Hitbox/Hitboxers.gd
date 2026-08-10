extends Area2D
class_name HitBox

@export_group("Hit Spark")

@export_enum(
	"Light",
	"Heavy",
	"Special"
)
var hit_spark_type: int = 0

const HIT_SPARK_SCENE: PackedScene = preload(
	"res://Scripts/Combat/HitSpark.tscn"
)

@export_group("MP")

@export_range(0.0, 5.0, 0.05)
var mp_gain_multiplier: float = 1.0

signal hit_confirmed(target: Area2D)

@export var hit_data: HitData

var _owner_character: CharacterBody2D
var _already_hit: Array[Area2D] = []
var _enabled: bool = false


func _ready() -> void:
	_owner_character = _find_owner_character()

	# A HitBox não ocupa nenhuma camada.
	collision_layer = 0

	# Detecta exclusivamente a camada 2.
	collision_mask = 0
	set_collision_mask_value(2, true)

	monitoring = false
	monitorable = false

	# Deixe as formas permanentemente habilitadas.
	# Quem controla o golpe é a propriedade monitoring.
	for child in get_children():
		if child is CollisionShape2D:
			var collision_shape := child as CollisionShape2D

			if collision_shape.shape == null:
				printerr(
					"HitBox ",
					get_path(),
					": CollisionShape2D sem Shape."
				)
			else:
				collision_shape.disabled = false

	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)

	print(
		"HitBox pronta: ",
		get_path(),
		" | dono: ",
		_owner_character.name
			if _owner_character != null
			else "não encontrado",
		" | mask: ",
		collision_mask
	)


func enable() -> void:
	_enabled = true
	_already_hit.clear()

	set_deferred("monitoring", true)

	print(
		"HitBox ativada: ",
		get_path()
	)

	# Verifica também as áreas que já estavam sobrepostas
	# quando a HitBox foi ligada.
	call_deferred("_scan_current_overlaps")


func disable() -> void:
	_enabled = false
	set_deferred("monitoring", false)


func _scan_current_overlaps() -> void:
	# Aguarda o servidor de física atualizar as colisões.
	await get_tree().physics_frame

	if not _enabled:
		return

	var overlapping_areas: Array[Area2D] = (
		get_overlapping_areas()
	)

	print(
		"HitBox ",
		get_path(),
		" encontrou ",
		overlapping_areas.size(),
		" áreas sobrepostas."
	)

	for area in overlapping_areas:
		print("Área sobreposta: ", area.get_path())
		_try_hit(area)


func _on_area_entered(area: Area2D) -> void:
	if not _enabled:
		return

	print(
		"area_entered recebido: ",
		area.get_path()
	)

	_try_hit(area)


func _try_hit(area: Area2D) -> void:
	if area == null:
		return

	if not area.has_method("receive_hit"):
		return

	var target_character: CharacterBody2D = null

	if area.has_method("get_character"):
		target_character = (
			area.call("get_character")
			as CharacterBody2D
		)

	if target_character == null:
		return

	# Impede dano próprio.
	if (
		_owner_character != null
		and target_character == _owner_character
	):
		return

	if area in _already_hit:
		return

	if hit_data == null:
		printerr(
			"HitBox ",
			get_path(),
			": HitData não configurado."
		)
		return

	_already_hit.append(area)

	var hit_result: Variant = area.call(
		"receive_hit",
		hit_data,
		_owner_character
	)

	var caused_damage: bool = (
		typeof(hit_result) == TYPE_BOOL
		and hit_result == true
	)

	if caused_damage:
		_spawn_hit_spark(area)

		if (
			_owner_character != null
			and _owner_character.has_method(
				"gain_mp_from_successful_hit"
			)
		):
			_owner_character.call(
				"gain_mp_from_successful_hit",
				mp_gain_multiplier
			)

	hit_confirmed.emit(area)


func _find_owner_character() -> CharacterBody2D:
	var current_node: Node = get_parent()

	while current_node != null:
		if current_node is CharacterBody2D:
			return current_node as CharacterBody2D

		current_node = current_node.get_parent()

	return null

func set_owner_character(
	character: CharacterBody2D
) -> void:
	_owner_character = character


func _spawn_hit_spark(
	hurtbox: Area2D
) -> void:
	if hurtbox == null:
		return

	var spark := (
		HIT_SPARK_SCENE.instantiate()
		as HitSpark
	)

	if spark == null:
		printerr(
			"HitBox: não foi possível criar HitSpark."
		)
		return

	var scene := get_tree().current_scene

	if scene == null:
		spark.queue_free()
		return

	scene.add_child(
		spark
	)

	var impact_position: Vector2 = (
		global_position
		+ hurtbox.global_position
	) * 0.5

	spark.play_spark(
		hit_spark_type,
		impact_position
	)
