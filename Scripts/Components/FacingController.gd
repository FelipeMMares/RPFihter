extends Node
class_name FacingController


@export_group("Referências")
@export var character: CharacterBody2D
@export var animated_sprite: AnimatedSprite2D
@export var hitboxes_root: Node2D

@export_group("Orientação")
# Ative se os sprites originais foram desenhados olhando
# para a direita.
@export var sprite_originally_faces_right: bool = true

# Evita os personagens ficarem alternando rapidamente
# quando estiverem praticamente na mesma posição horizontal.
@export var horizontal_deadzone: float = 2.0


var opponent: CharacterBody2D

var _facing_right: bool = true
var _facing_was_applied: bool = false
var _base_hitboxes_scale_x: float = 1.0


func _ready() -> void:
	if character == null:
		character = get_parent() as CharacterBody2D

	if character == null:
		printerr(
			"FacingController: o nó pai precisa ser CharacterBody2D."
		)
		set_physics_process(false)
		return

	if animated_sprite == null:
		animated_sprite = character.get_node_or_null(
			"AnimatedSprite2D"
		) as AnimatedSprite2D

	if animated_sprite == null:
		printerr(
			"FacingController: AnimatedSprite2D não encontrado em ",
			character.name
		)

	if hitboxes_root == null:
		hitboxes_root = character.get_node_or_null(
			"Hitboxes"
		) as Node2D

	if hitboxes_root != null:
		_base_hitboxes_scale_x = absf(
			hitboxes_root.scale.x
		)

		if is_zero_approx(_base_hitboxes_scale_x):
			_base_hitboxes_scale_x = 1.0

	# Só começa a processar depois de receber um oponente.
	set_physics_process(opponent != null)


func setup(new_opponent: CharacterBody2D) -> void:
	opponent = new_opponent

	if opponent == null:
		printerr(
			"FacingController: oponente não configurado para ",
			character.name
		)
		set_physics_process(false)
		return

	set_physics_process(true)
	_update_facing(true)

	print(
		"FacingController: ",
		character.name,
		" está encarando ",
		opponent.name
	)


func _physics_process(_delta: float) -> void:
	_update_facing()


func _update_facing(force_update: bool = false) -> void:
	if character == null or opponent == null:
		return

	var horizontal_difference: float = (
		opponent.global_position.x
		- character.global_position.x
	)

	# Quando os dois estão praticamente no mesmo X,
	# mantém a última direção para evitar tremedeira.
	if (
		not force_update
		and absf(horizontal_difference) <= horizontal_deadzone
	):
		return

	if is_zero_approx(horizontal_difference):
		return

	var should_face_right: bool = (
		horizontal_difference > 0.0
	)

	_apply_facing(should_face_right)


func _apply_facing(face_right: bool) -> void:
	if (
		_facing_was_applied
		and _facing_right == face_right
	):
		return

	_facing_was_applied = true
	_facing_right = face_right

	# Determina se precisa inverter em relação à orientação
	# original do sprite.
	var should_flip: bool = (
		face_right != sprite_originally_faces_right
	)

	if animated_sprite != null:
		animated_sprite.flip_h = should_flip

	# Espelha também as hitboxes para que os ataques
	# continuem aparecendo na frente do personagem.
	if hitboxes_root != null:
		var new_scale := hitboxes_root.scale

		new_scale.x = (
			-_base_hitboxes_scale_x
			if should_flip
			else _base_hitboxes_scale_x
		)

		hitboxes_root.scale = new_scale

	print(
		character.name,
		" agora olha para ",
		"direita" if face_right else "esquerda"
	)


func is_facing_right() -> bool:
	return _facing_right
