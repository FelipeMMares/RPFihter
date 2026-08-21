extends CharacterBody2D


# ============================================================
# REFERÊNCIAS
# ============================================================

@onready var animated_sprite: AnimatedSprite2D = (
	$AnimatedSprite2D
)

@onready var state_machine: StateMachine = (
	$StateMachine
)

@onready var hurt_box: HurtBox = (
	$Hurtbox
)


# ============================================================
# MOVIMENTO
# ============================================================

@export_group("Movimento")

@export var speed: float = 150.0
@export var jump_force: float = 700.0
@export var gravity: float = 1200.0


# ============================================================
# AJUSTE VISUAL DAS ANIMAÇÕES
# ============================================================

# A Idle será nossa referência.
#
# O ideal é deixar:
#
# Idle
# scale = (1, 1)
# offset = (0, 0)
#
# e corrigir as demais em relação a ela.


var animation_visuals: Dictionary = {

	# --------------------------------------------------------
	# BASE
	# --------------------------------------------------------

	&"Idle": {
		"scale": Vector2(1.956, 1.921),
		"offset": Vector2(0.0, 0.0)
	},

	&"Walk": {
		"scale": Vector2(1.956, 1.921),
		"offset": Vector2(0.0, -1.0)
	},
# --------------------------------------------------------
# AGACHAMENTO
# --------------------------------------------------------

&"CrouchStart": {
	"scale": Vector2(1.956, 1.921),
	"offset": Vector2(-25.0, 0.0)
},

&"CrouchWhile": {
	"scale": Vector2(1.956, 1.921),
	"offset": Vector2(-25.0, 0.0)
},

&"CrouchEnd": {
	"scale": Vector2(1.956, 1.921),
	"offset": Vector2(-25.0, 0.0)
},

	# --------------------------------------------------------
	# PULO
	# --------------------------------------------------------

	&"StartJump": {
		"scale": Vector2(2.0, 2.0),
		"offset": Vector2(-10.0, -100.0)
	},

	&"Jump": {
		"scale": Vector2(1.0, 1.0),
		"offset": Vector2(0.0, 0.0)
	},

	# --------------------------------------------------------
	# ATAQUES NORMAIS
	# --------------------------------------------------------

	&"LightPunch": {
		"scale": Vector2(1.0, 1.0),
		"offset": Vector2(0.0, 0.0)
	},

	&"HighPunch": {
		"scale": Vector2(1.0, 1.0),
		"offset": Vector2(0.0, 0.0)
	},

	&"Kick": {
		"scale": Vector2(1.0, 1.0),
		"offset": Vector2(0.0, 0.0)
	},

	&"LowKick": {
		"scale": Vector2(1.0, 1.0),
		"offset": Vector2(0.0, 0.0)
	},

	# --------------------------------------------------------
	# ATAQUES AGACHADOS
	# --------------------------------------------------------

	&"CrouchLightPunch": {
		"scale": Vector2(1.0, 1.0),
		"offset": Vector2(0.0, 0.0)
	},

	&"CrouchHighPunch": {
		"scale": Vector2(1.0, 1.0),
		"offset": Vector2(0.0, 0.0)
	},

	&"CrouchKick": {
		"scale": Vector2(1.0, 1.0),
		"offset": Vector2(0.0, 0.0)
	},

	&"CrouchLowKick": {
		"scale": Vector2(1.0, 1.0),
		"offset": Vector2(0.0, 0.0)
	},

	# --------------------------------------------------------
	# ATAQUES AÉREOS
	# --------------------------------------------------------

	&"AirLightPunch": {
		"scale": Vector2(1.0, 1.0),
		"offset": Vector2(0.0, 0.0)
	},

	&"AirHighPunch": {
		"scale": Vector2(1.0, 1.0),
		"offset": Vector2(0.0, 0.0)
	},

	&"AirKick": {
		"scale": Vector2(1.0, 1.0),
		"offset": Vector2(0.0, 0.0)
	},

	&"AirLowKick": {
		"scale": Vector2(1.0, 1.0),
		"offset": Vector2(0.0, 0.0)
	},

	# --------------------------------------------------------
	# ESPECIAIS
	# --------------------------------------------------------

	&"SoulFist": {
		"scale": Vector2(1.0, 1.0),
		"offset": Vector2(0.0, 0.0)
	},

	&"AirSoulFist": {
		"scale": Vector2(1.0, 1.0),
		"offset": Vector2(0.0, 0.0)
	},

	&"ShadowBlade": {
		"scale": Vector2(1.0, 1.0),
		"offset": Vector2(0.0, 0.0)
	},

	&"ShellKick": {
		"scale": Vector2(1.0, 1.0),
		"offset": Vector2(0.0, 0.0)
	},

	# --------------------------------------------------------
	# DANO / RESULTADO
	# --------------------------------------------------------

	&"Hurt": {
		"scale": Vector2(1.0, 1.0),
		"offset": Vector2(0.0, 0.0)
	},

	&"Fall": {
		"scale": Vector2(1.0, 1.0),
		"offset": Vector2(0.0, 0.0)
	},

	&"Victory": {
		"scale": Vector2(1.0, 1.0),
		"offset": Vector2(0.0, 0.0)
	},

	&"Defeated": {
		"scale": Vector2(1.0, 1.0),
		"offset": Vector2(0.0, 0.0)
	},

	&"FallDefeated": {
		"scale": Vector2(1.0, 1.0),
		"offset": Vector2(0.0, 0.0)
	}
}


# ============================================================
# CORREÇÃO OPCIONAL POR FRAME
# ============================================================

# Use somente quando uma animação está alinhada no geral,
# mas alguns frames específicos "pulam".
#
# Estrutura:
#
# animação:
#     frame: Vector2(offset adicional)
#
#
# Exemplo:
#
# &"Kick": {
#     2: Vector2(-3, 0),
#     3: Vector2(-5, -2)
# }


var frame_visual_offsets: Dictionary = {
}


# Offset principal da animação atual.
#
# Guardamos separadamente porque o ajuste de frame
# deve ser SOMADO ao ajuste da animação.
var _current_animation_offset: Vector2 = Vector2.ZERO


# ============================================================
# READY
# ============================================================

func _ready() -> void:
	if animated_sprite == null:
		printerr(
			"Morrigan: AnimatedSprite2D não encontrado."
		)
		return

	if not animated_sprite.frame_changed.is_connected(
		_on_animation_frame_changed
	):
		animated_sprite.frame_changed.connect(
			_on_animation_frame_changed
		)

	# Garante que o primeiro estado visual também
	# comece corretamente.
	apply_animation_visual(
		StringName(
			animated_sprite.animation
		)
	)


# ============================================================
# FÍSICA
# ============================================================

func _physics_process(
	delta: float
) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

	move_and_slide()


# ============================================================
# MOVIMENTO SOLICITADO PELA STATE MACHINE
# ============================================================

func move(
	direction: Vector2
) -> void:
	# Apenas horizontal.
	#
	# Não zeramos Y porque isso destruiria
	# a velocidade do salto.
	velocity.x = direction.x * speed


func stop() -> void:
	velocity.x = 0.0


func jump() -> void:
	if not is_on_floor():
		return

	velocity.y = -jump_force


# ============================================================
# CROUCH / HURTBOX
# ============================================================

func set_crouching(
	active: bool
) -> void:
	if hurt_box == null:
		return

	hurt_box.set_crouching(
		active
	)


# ============================================================
# AJUSTE VISUAL POR ANIMAÇÃO
# ============================================================

func apply_animation_visual(
	animation_name: StringName
) -> void:
	if animated_sprite == null:
		return


	# --------------------------------------------------------
	# SEMPRE RESTAURA O PADRÃO
	# --------------------------------------------------------

	animated_sprite.scale = Vector2.ONE

	_current_animation_offset = (
		Vector2.ZERO
	)

	animated_sprite.offset = (
		Vector2.ZERO
	)


	# --------------------------------------------------------
	# PROCURA CONFIGURAÇÃO
	# --------------------------------------------------------

	if not animation_visuals.has(
		animation_name
	):
		return


	var data: Dictionary = (
		animation_visuals[
			animation_name
		]
	)


	# --------------------------------------------------------
	# SCALE
	# --------------------------------------------------------

	var visual_scale: Vector2 = (
		data.get(
			"scale",
			Vector2.ONE
		)
	)

	animated_sprite.scale = (
		visual_scale
	)


	# --------------------------------------------------------
	# OFFSET
	# --------------------------------------------------------

	var visual_offset: Vector2 = (
		data.get(
			"offset",
			Vector2.ZERO
		)
	)

	_current_animation_offset = (
		visual_offset
	)

	animated_sprite.offset = (
		visual_offset
	)


	# --------------------------------------------------------
	# CASO O PRIMEIRO FRAME TENHA CORREÇÃO
	# --------------------------------------------------------

	_apply_current_frame_offset()


# ============================================================
# FRAME CHANGED
# ============================================================

func _on_animation_frame_changed() -> void:
	_apply_current_frame_offset()


# ============================================================
# CORREÇÃO INDIVIDUAL DO FRAME
# ============================================================

func _apply_current_frame_offset() -> void:
	if animated_sprite == null:
		return


	var animation_name: StringName = (
		StringName(
			animated_sprite.animation
		)
	)

	var final_offset: Vector2 = (
		_current_animation_offset
	)


	# Se essa animação não possui correções
	# individuais, mantém somente o offset geral.
	if not frame_visual_offsets.has(
		animation_name
	):
		animated_sprite.offset = (
			final_offset
		)

		return


	var animation_frames: Dictionary = (
		frame_visual_offsets[
			animation_name
		]
	)


	var current_frame: int = (
		animated_sprite.frame
	)


	if animation_frames.has(
		current_frame
	):
		var frame_offset: Vector2 = (
			animation_frames[
				current_frame
			]
		)

		final_offset += frame_offset


	animated_sprite.offset = (
		final_offset
	)
