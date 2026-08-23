extends State
class_name SoulEraserState

@export_group("Voice")

@export var special_voices: Array[AudioStream] = []

@export_group("Animação")

@export var animation_name: StringName = &"SoulEraser"


@export_group("HitBoxes")

# Hitbox principal da rajada.
@export var tick_hitbox: HitBox

# Hitbox usada no impacto final.
@export var final_hitbox: HitBox


@export_group("Frames da rajada")

@export var beam_start_frame: int = 5

@export var beam_end_frame: int = 18

@export var final_hit_frame: int = 19

@export_range(1, 30, 1)
var tick_every_frames: int = 3


@export_group("Limites")

@export_range(1, 20, 1)
var maximum_ticks: int = 5


@export_group("Transição")

@export var return_state: StringName = &"Idle"

# Estado usado apenas como proteção caso,
# por algum motivo, SoulEraser seja chamado no ar.
@export var airborne_state: StringName = &"Jump"


@onready var character: CharacterBody2D = (
	get_parent().get_parent()
	as CharacterBody2D
)

@onready var animated_sprite: AnimatedSprite2D = (
	character.get_node_or_null("AnimatedSprite2D")
	as AnimatedSprite2D
)


var _last_frame: int = -1
var _last_tick_frame: int = -999

var _current_ticks: int = 0

var _final_hit_used: bool = false


# ============================================================
# ENTRADA
# ============================================================

func _enter() -> void:

	_disable_hitboxes()

	_last_frame = -1
	_last_tick_frame = -999

	_current_ticks = 0
	_final_hit_used = false


	if character == null:
		printerr(
			"SoulEraser: personagem não encontrado."
		)

		transition_to.emit(
			return_state
		)

		return


	# ========================================================
	# SOUL ERASER É EXCLUSIVAMENTE TERRESTRE
	# ========================================================

	if not character.is_on_floor():

		print(
			"SoulEraser cancelado: Morrigan está no ar."
		)

		transition_to.emit(
			airborne_state
		)

		return


	# Morrigan fica parada durante o especial.
	character.velocity.x = 0.0


	if animated_sprite == null:

		printerr(
			"SoulEraser: AnimatedSprite2D não encontrado."
		)

		transition_to.emit(
			return_state
		)

		return


	if animated_sprite.sprite_frames == null:

		printerr(
			"SoulEraser: SpriteFrames não configurado."
		)

		transition_to.emit(
			return_state
		)

		return


	if not animated_sprite.sprite_frames.has_animation(
		animation_name
	):

		printerr(
			"SoulEraser: animação não encontrada: ",
			animation_name
		)

		transition_to.emit(
			return_state
		)

		return


	play_animation.emit(
		String(animation_name),
		false
	)

	_play_special_voice()
# ============================================================
# PROCESSAMENTO
# ============================================================

func _physics_process(
	_delta: float
) -> void:

	if character == null:
		return


	# SoulEraser não permite deslocamento horizontal.
	character.velocity.x = 0.0


	# Segurança adicional.
	#
	# Se alguma outra força fizer Morrigan sair do chão
	# durante o especial, encerra o ataque.
	if not character.is_on_floor():

		_disable_hitboxes()

		transition_to.emit(
			airborne_state
		)

		return


	if animated_sprite == null:
		return


	var current_frame: int = (
		animated_sprite.frame
	)


	# Evita processar várias vezes o mesmo
	# frame da animação.
	if current_frame == _last_frame:
		return


	_last_frame = current_frame


	_process_beam_frame(
		current_frame
	)


# ============================================================
# PROCESSAMENTO DA RAJADA
# ============================================================

func _process_beam_frame(
	current_frame: int
) -> void:


	# ========================================================
	# PEQUENOS HITS
	# ========================================================

	if (
		current_frame >= beam_start_frame
		and current_frame <= beam_end_frame
	):

		if _current_ticks >= maximum_ticks:
			return


		var frames_since_tick: int = (
			current_frame
			- _last_tick_frame
		)


		if frames_since_tick >= tick_every_frames:

			_apply_tick(
				current_frame
			)


		return


	# ========================================================
	# HIT FINAL
	# ========================================================

	if (
		current_frame >= final_hit_frame
		and not _final_hit_used
	):

		_apply_final_hit()


# ============================================================
# PEQUENO HIT
# ============================================================

func _apply_tick(
	current_frame: int
) -> void:

	if tick_hitbox == null:
		return


	_last_tick_frame = current_frame

	_current_ticks += 1


	# Reativa a mesma HitBox.
	#
	# enable() limpa _already_hit,
	# permitindo atingir novamente
	# o mesmo oponente.
	tick_hitbox.disable()

	tick_hitbox.enable()


	print(
		"SoulEraser tick ",
		_current_ticks,
		"/",
		maximum_ticks
	)


# ============================================================
# HIT FINAL
# ============================================================

func _apply_final_hit() -> void:

	_final_hit_used = true


	if tick_hitbox != null:

		tick_hitbox.disable()


	if final_hitbox == null:
		return


	final_hitbox.enable()


	print(
		"SoulEraser: HIT FINAL"
	)


# ============================================================
# FIM DA ANIMAÇÃO
# ============================================================

func _animation_finished() -> void:

	_disable_hitboxes()


	if character != null:
		character.velocity.x = 0.0


	transition_to.emit(
		return_state
	)


# ============================================================
# SAÍDA
# ============================================================

func _exit() -> void:

	_disable_hitboxes()


	_current_ticks = 0

	_final_hit_used = false

	_last_frame = -1

	_last_tick_frame = -999


	if character != null:
		character.velocity.x = 0.0


# ============================================================
# DESATIVA AS HITBOXES
# ============================================================

func _disable_hitboxes() -> void:

	if tick_hitbox != null:
		tick_hitbox.disable()


	if final_hitbox != null:
		final_hitbox.disable()

func _play_special_voice() -> void:
	if special_voices.is_empty():
		return

	if character == null:
		return

	if not character.has_method(
		"play_random_voice"
	):
		return

	character.call(
		"play_random_voice",
		special_voices,
		true
	)
