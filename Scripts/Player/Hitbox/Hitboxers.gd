extends Area2D
class_name HitBox

enum ImpactSoundType {
	HIT,
	STRIKE
}

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

@export_group("SFX de impacto")

@export_enum(
	"Hit",
	"Strike"
)
var impact_sound_type: int = (
	ImpactSoundType.HIT
)

@export var hit_sound: AudioStream
@export var guard_sound: AudioStream
@export var strike_sound: AudioStream

@export_range(
	-12.0,
	6.0,
	0.5
)
var impact_volume_db: float = 0.0

@export_range(
	0.0,
	0.20,
	0.01
)
var pitch_variation: float = 0.04

@export_group("MP")

@export_range(0.0, 5.0, 0.05)
var mp_gain_multiplier: float = 1.0

signal hit_confirmed(target: Area2D)

signal hit_resolved(
	target: Area2D,
	result: int
)

@export var hit_data: HitData

var _owner_character: CharacterBody2D
var _already_hit: Array[Area2D] = []
var _enabled: bool = false

const IMPACT_AUDIO_POOL_SIZE: int = 4

var _impact_audio_pool: Array[AudioStreamPlayer2D] = []
var _impact_audio_index: int = 0

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

	_create_impact_audio_pool()

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

	if typeof(hit_result) != TYPE_INT:
		printerr(
			"HitBox: receive_hit retornou valor inválido: ",
			hit_result
		)
		return

	var combat_result: int = int(
		hit_result
	)

	var impact_position: Vector2 = (
		_get_impact_position(
			area
		)
	)


	match combat_result:
		CombatHitResult.Type.HIT:
			_spawn_hit_spark(
				area,
				hit_spark_type
			)

			_play_successful_hit_sound(
				impact_position
			)

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


		CombatHitResult.Type.GUARD:
			_spawn_hit_spark(
				area,
				HitSpark.SparkType.GUARD
			)

			_play_impact_sound(
				guard_sound,
				impact_position
			)


		CombatHitResult.Type.IGNORED:
			pass

	hit_resolved.emit(
		area,
		combat_result
	)

	# Mantemos o sinal antigo para não quebrar
	# nenhuma lógica que já dependa dele.
	hit_confirmed.emit(
		area
	)

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
	hurtbox: Area2D,
	spark_type: int
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
		spark_type,
		impact_position
	)

func _play_impact_sound(
	stream: AudioStream,
	impact_position: Vector2
) -> void:
	if stream == null:
		return

	if _impact_audio_pool.is_empty():
		return

	var audio_player: AudioStreamPlayer2D = (
		_impact_audio_pool[
			_impact_audio_index
		]
	)

	_impact_audio_index = (
		_impact_audio_index + 1
	) % _impact_audio_pool.size()

	audio_player.stop()

	audio_player.stream = stream

	audio_player.global_position = (
		impact_position
	)

	audio_player.volume_db = (
		impact_volume_db
	)

	if pitch_variation > 0.0:
		audio_player.pitch_scale = randf_range(
			1.0 - pitch_variation,
			1.0 + pitch_variation
		)
	else:
		audio_player.pitch_scale = 1.0

	audio_player.play()

func _get_impact_position(
	hurtbox: Area2D
) -> Vector2:
	if hurtbox == null:
		return global_position

	return (
		global_position
		+ hurtbox.global_position
	) * 0.5

func _play_successful_hit_sound(
	impact_position: Vector2
) -> void:
	match impact_sound_type:
		ImpactSoundType.HIT:
			_play_impact_sound(
				hit_sound,
				impact_position
			)

		ImpactSoundType.STRIKE:
			_play_impact_sound(
				strike_sound,
				impact_position
			)

func _create_impact_audio_pool() -> void:
	for index in range(
		IMPACT_AUDIO_POOL_SIZE
	):
		var audio_player := (
			AudioStreamPlayer2D.new()
		)

		audio_player.name = (
			"ImpactAudio_%d" % index
		)

		audio_player.volume_db = (
			impact_volume_db
		)

		add_child(
			audio_player
		)

		_impact_audio_pool.append(
			audio_player
		)
