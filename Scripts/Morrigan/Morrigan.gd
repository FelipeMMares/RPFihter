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
	"offset": Vector2(-26.0, 0.0)
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

		# EXEMPLOS.
		# Troque pelos valores reais depois.
		0: {
			"offset": Vector2(0.0, -108.0),
			"scale": Vector2(2.0, 2.0)
		},

		1: {
			"offset": Vector2(-26.0, -70.0),
			"scale": Vector2(2.0, 2.0)
		},

		2: {
			"offset": Vector2(-26.0, -4.0),
			"scale": Vector2(2.0, 2.0)
		},

		3: {
			"offset": Vector2(-26.0, 41.0),
			"scale": Vector2(2.0, 2.0)
		},

		4: {
			"offset": Vector2(-26.0, 62.0),
			"scale": Vector2(2.0, 2.0)
		},

		5: {
			"offset": Vector2(-26.0, 62.0),
			"scale": Vector2(2.0, 2.0)
		},

		6: {
			"offset": Vector2(-26.0, 97.0),
			"scale": Vector2(2.0, 2.0)
		},

		7: {
			"offset": Vector2(-26.0, 97.0),
			"scale": Vector2(2.0, 2.0)
		},

		8: {
			"offset": Vector2(-26.0, 97.0),
			"scale": Vector2(2.0, 2.0)
		},

		9: {
			"offset": Vector2(-26.0, 97.0),
			"scale": Vector2(2.0, 2.0)
		},

		10: {
			"offset": Vector2(-26.0, 97.0),
			"scale": Vector2(2.0, 2.0)
		},

		11: {
			"offset": Vector2(-10.0, 97.0),
			"scale": Vector2(2.0, 2.0)
		},

		12: {
			"offset": Vector2(-10.0, 65.0),
			"scale": Vector2(2.0, 2.0)
		},

		13: {
			"offset": Vector2(-26.0, 48.0),
			"scale": Vector2(2.0, 2.0)
		},

		14: {
			"offset": Vector2(-26.0, 6.0),
			"scale": Vector2(2.0, 2.0)
		},

		15: {
			"offset": Vector2(-26.0, -28.0),
			"scale": Vector2(2.0, 2.0)
		},

		16: {
			"offset": Vector2(-26.0, -63.0),
			"scale": Vector2(2.0, 2.0)
		}
	},

	# --------------------------------------------------------
	# ATAQUES NORMAIS
	# --------------------------------------------------------

	&"LightPunch": {
		"scale": Vector2(1.956, 1.921),
		"offset": Vector2(45.0, -10.0)
	},

	&"HighPunch": {
		"scale": Vector2(1.956, 1.921),
		"offset": Vector2(45.0, -10.00)
	},

	&"Kick": {
		"scale": Vector2(1.956, 1.921),
		"offset": Vector2(45.0, -10.0)
	},

	&"LowKick": {
		"scale": Vector2(1.956, 1.921),
		"offset": Vector2(45.0, -10.0)
	},

	# --------------------------------------------------------
	# ATAQUES AGACHADOS
	# --------------------------------------------------------

	&"CrouchLightPunch": {
		"scale": Vector2(1.910, 1.910),
		"offset": Vector2(15.0, 0.0)
	},

	&"CrouchHighPunch": {
		"scale": Vector2(1.910, 1.910),
		"offset": Vector2(15.0, 0.0)
	},

	&"CrouchKick": {
		"scale": Vector2(1.910, 1.910),
		"offset": Vector2(15.0, 0.0)
	},

	&"CrouchLowKick": {
		"scale": Vector2(1.910, 1.910),
		"offset": Vector2(15.0, 0.0)
	},

	# --------------------------------------------------------
	# ATAQUES AÉREOS
	# --------------------------------------------------------

	&"AirLightPunch": {
		# EXEMPLOS.
		# Troque pelos valores reais depois.
		0: {
			"offset": Vector2(10.0, -2.0),
			"scale": Vector2(2.0, 2.0)
		},

		1: {
			"offset": Vector2(10.0, -2.0),
			"scale": Vector2(2.0, 2.0)
		},

		2: {
			"offset": Vector2(10.0, 5.0),
			"scale": Vector2(2.0, 2.0)
		},

		3: {
			"offset": Vector2(10.0, 24.0),
			"scale": Vector2(2.0, 2.0)
		},

		4: {
			"offset": Vector2(10.0, 28.0),
			"scale": Vector2(2.0, 2.0)
		},

		5: {
			"offset": Vector2(10.0, 39.0),
			"scale": Vector2(2.0, 2.0)
		},

		6: {
			"offset": Vector2(10.0, 48.0),
			"scale": Vector2(2.0, 2.0)
		},

		7: {
			"offset": Vector2(10.0, 50.0),
			"scale": Vector2(2.0, 2.0)
		},

		8: {
			"offset": Vector2(10.0, 55.0),
			"scale": Vector2(2.0, 2.0)
		},

		9: {
			"offset": Vector2(10.0, 55.0),
			"scale": Vector2(2.0, 2.0)
		},

		10: {
			"offset": Vector2(10.0, 50.0),
			"scale": Vector2(2.0, 2.0)
		},

		11: {
			"offset": Vector2(10.0, 46.0),
			"scale": Vector2(2.0, 2.0)
		}
	},

	&"AirHighPunch": {
		# EXEMPLOS.
		# Troque pelos valores reais depois.
		0: {
			"offset": Vector2(10.0, -40.0),
			"scale": Vector2(2.0, 2.0)
		},

		1: {
			"offset": Vector2(10.0, -16.0),
			"scale": Vector2(2.0, 2.0)
		},

		2: {
			"offset": Vector2(10.0, 2.0),
			"scale": Vector2(2.0, 2.0)
		},

		3: {
			"offset": Vector2(10.0, 22.0),
			"scale": Vector2(2.0, 2.0)
		},

		4: {
			"offset": Vector2(10.0, 34.0),
			"scale": Vector2(2.0, 2.0)
		},

		5: {
			"offset": Vector2(10.0, 40.0),
			"scale": Vector2(2.0, 2.0)
		},

		6: {
			"offset": Vector2(10.0, 50.0),
			"scale": Vector2(2.0, 2.0)
		},

		7: {
			"offset": Vector2(10.0, 56.0),
			"scale": Vector2(2.0, 2.0)
		},

		8: {
			"offset": Vector2(10.0, 64.0),
			"scale": Vector2(2.0, 2.0)
		},

		9: {
			"offset": Vector2(10.0, 66.0),
			"scale": Vector2(2.0, 2.0)
		},

		10: {
			"offset": Vector2(10.0, 68.0),
			"scale": Vector2(2.0, 2.0)
		},

		11: {
			"offset": Vector2(10.0, 45.0),
			"scale": Vector2(2.0, 2.0)
		}
	},

	&"AirKick": {
		# EXEMPLOS.
		# Troque pelos valores reais depois.
		0: {
			"offset": Vector2(10.0, 22.0),
			"scale": Vector2(2.0, 2.0)
		},

		1: {
			"offset": Vector2(10.0, 22.0),
			"scale": Vector2(2.0, 2.0)
		},

		2: {
			"offset": Vector2(10.0, 36.0),
			"scale": Vector2(2.0, 2.0)
		},

		3: {
			"offset": Vector2(10.0, 45.0),
			"scale": Vector2(2.0, 2.0)
		},

		4: {
			"offset": Vector2(10.0, 52.0),
			"scale": Vector2(2.0, 2.0)
		},

		5: {
			"offset": Vector2(10.0, 56.0),
			"scale": Vector2(2.0, 2.0)
		},

		6: {
			"offset": Vector2(10.0, 56.0),
			"scale": Vector2(2.0, 2.0)
		},

		7: {
			"offset": Vector2(10.0, 50.0),
			"scale": Vector2(2.0, 2.0)
		},

		8: {
			"offset": Vector2(10.0, 40.0),
			"scale": Vector2(2.0, 2.0)
		},

		9: {
			"offset": Vector2(10.0, 40.0),
			"scale": Vector2(2.0, 2.0)
		},

		10: {
			"offset": Vector2(10.0, 25.0),
			"scale": Vector2(2.0, 2.0)
		}
	},

	&"AirLowKick": {
		# EXEMPLOS.
		# Troque pelos valores reais depois.
		0: {
			"offset": Vector2(10.0, -5.0),
			"scale": Vector2(2.0, 2.0)
		},

		1: {
			"offset": Vector2(10.0, -4.0),
			"scale": Vector2(2.0, 2.0)
		},

		2: {
			"offset": Vector2(10.0, 25.0),
			"scale": Vector2(2.0, 2.0)
		},

		3: {
			"offset": Vector2(10.0, 30.0),
			"scale": Vector2(2.0, 2.0)
		},

		4: {
			"offset": Vector2(10.0, 40.0),
			"scale": Vector2(2.0, 2.0)
		},

		5: {
			"offset": Vector2(10.0, 44.0),
			"scale": Vector2(2.0, 2.0)
		},

		6: {
			"offset": Vector2(10.0, 52.0),
			"scale": Vector2(2.0, 2.0)
		},

		7: {
			"offset": Vector2(10.0, 58.0),
			"scale": Vector2(2.0, 2.0)
		},

		8: {
			"offset": Vector2(10.0, 58.0),
			"scale": Vector2(2.0, 2.0)
		},

		9: {
			"offset": Vector2(10.0, 58.0),
			"scale": Vector2(2.0, 2.0)
		},

		10: {
			"offset": Vector2(10.0, 40.0),
			"scale": Vector2(2.0, 2.0)
		}
	},

	# --------------------------------------------------------
	# AGARRÕES
	# --------------------------------------------------------

	&"Throw": {
		"scale": Vector2(1.956, 1.956),
		"offset": Vector2(40.0, 0.0)
	},

	&"TryGrab": {
		"scale": Vector2(1.956, 1.956),
		"offset": Vector2(40.0, 0.0)
	},

	# --------------------------------------------------------
	# ESPECIAIS
	# --------------------------------------------------------

	&"SoulFist": {
		"scale": Vector2(1.960, 1.1960),
		"offset": Vector2(80.0, -10.0)
	},

	&"AirSoulFist": {
		"scale": Vector2(1.1960, 1.960),
		"offset": Vector2(75.0, 25.0)
	},

	&"ShadowBlade": {
		0: {
			"offset": Vector2(18.0, -28.0),
			"scale": Vector2(1.956, 1.956)
		},

		1: {
			"offset": Vector2(18.0, -28.0),
			"scale": Vector2(1.956, 1.956)
		},

		2: {
			"offset": Vector2(18.0, -28.0),
			"scale": Vector2(1.956, 1.956)
		},

		3: {
			"offset": Vector2(18.0, -28.0),
			"scale": Vector2(1.956, 1.956)
		},

		4: {
			"offset": Vector2(2.0, -28.0),
			"scale": Vector2(1.956, 1.956)
		},

		5: {
			"offset": Vector2(-28, -5.0),
			"scale": Vector2(1.956, 1.956)
		},

		6: {
			"offset": Vector2(-35.0, 5.0),
			"scale": Vector2(1.956, 1.956)
		},

		7: {
			"offset": Vector2(-52.0, 15.0),
			"scale": Vector2(1.956, 1.956)
		},

		8: {
			"offset": Vector2(-56.0, 20.0),
			"scale": Vector2(1.956, 1.956)
		},

		9: {
			"offset": Vector2(-30.0, 15.0),
			"scale": Vector2(1.956, 1.956)
		},

		10: {
			"offset": Vector2(-30.0, 0.0),
			"scale": Vector2(1.956, 1.956)
		},

		11: {
			"offset": Vector2(-30.0, -20.0),
			"scale": Vector2(1.956, 1.956)
		},

		12: {
			"offset": Vector2(-30.0, -30.0),
			"scale": Vector2(1.956, 1.956)
		},

		13: {
			"offset": Vector2(-30.0, -30.0),
			"scale": Vector2(1.956, 1.956)
		},

		14: {
			"offset": Vector2(-30.0, -30.0),
			"scale": Vector2(1.956, 1.956)
		},

		15: {
			"offset": Vector2(-30.0, -30.0),
			"scale": Vector2(1.956, 1.956)
		},

		16: {
			"offset": Vector2(-30.0, -30.0),
			"scale": Vector2(1.956, 1.956)
		},
		17: {
			"offset": Vector2(-30.0, -30.0),
			"scale": Vector2(1.956, 1.956)
		},

		18: {
			"offset": Vector2(-30.0, -30.0),
			"scale": Vector2(1.956, 1.956)
		},

		19: {
			"offset": Vector2(-30.0, -30.0),
			"scale": Vector2(1.956, 1.956)
		},

		20: {
			"offset": Vector2(-30.0, -30.0),
			"scale": Vector2(1.94, 1.94)
		},

		21: {
			"offset": Vector2(-30.0, -30.0),
			"scale": Vector2(1.94, 1.94)
		},

		22: {
			"offset": Vector2(-30.0, -30.0),
			"scale": Vector2(1.94, 1.94)
		},

		23: {
			"offset": Vector2(-30.0, -30.0),
			"scale": Vector2(1.94, 1.94)
		},

		24: {
			"offset": Vector2(-30.0, -30.0),
			"scale": Vector2(1.94, 1.94)
		},

		25: {
			"offset": Vector2(-30.0, -30.0),
			"scale": Vector2(1.94, 1.94)
		},

		26: {
			"offset": Vector2(-30.0, -30.0),
			"scale": Vector2(1.94, 1.94)
		},


		27: {
			"offset": Vector2(-30.0, -30.0),
			"scale": Vector2(1.94, 1.94)
		},

		28: {
			"offset": Vector2(-30.0, -30.0),
			"scale": Vector2(1.94, 1.94)
		},

		29: {
			"offset": Vector2(-30.0, -30.0),
			"scale": Vector2(1.94, 1.94)
		},

		30: {
			"offset": Vector2(-30.0, -30.0),
			"scale": Vector2(1.94, 1.94)
		},

		31: {
			"offset": Vector2(-30.0, -30.0),
			"scale": Vector2(1.94, 1.94)
		},

		32: {
			"offset": Vector2(-30.0, -30.0),
			"scale": Vector2(1.94, 1.94)
		}
	},

&"SoulEraser": {
		"scale": Vector2(1.0, 1.0),
		"offset": Vector2(0.0, 0.0)
},

	# --------------------------------------------------------
	# DANO / RESULTADO
	# --------------------------------------------------------

	&"Hurt": {
		"scale": Vector2(1.956, 1.956),
		"offset": Vector2(-158.0, 6.0)
	},

	&"Fall": {
		"scale": Vector2(1.956, 1.956),
		"offset": Vector2(0.0, 0.0)
	},

	&"Victory": {
		"scale": Vector2(1.96, 1.96),
		"offset": Vector2(-82.0, -20.0)
	},

	&"Defeated": {
		"scale": Vector2(1.956, 1.956),
		"offset": Vector2(-8.0, -2.0)
	},

	&"FallDefeated": {
		0: {
			"offset": Vector2(-160.0, -10.0),
			"scale": Vector2(1.956, 1.956)
		},

		1: {
			"offset": Vector2(-160.0, -10.0),
			"scale": Vector2(1.956, 1.956)
		},

		2: {
			"offset": Vector2(-160.0, -10.0),
			"scale": Vector2(1.956, 1.956)
		},

		3: {
			"offset": Vector2(-160.0, -10.0),
			"scale": Vector2(1.956, 1.956)
		},

		4: {
			"offset": Vector2(-160.0, -10.0),
			"scale": Vector2(1.956, 1.956)
		},

		5: {
			"offset": Vector2(-160.0, -10.0),
			"scale": Vector2(1.956, 1.956)
		},

		6: {
			"offset": Vector2(-160.0, -10.0),
			"scale": Vector2(1.956, 1.956)
		},

		8: {
			"offset": Vector2(-160.0, -10.0),
			"scale": Vector2(1.956, 1.956)
		},

		9: {
			"offset": Vector2(-160.0, -10.0),
			"scale": Vector2(1.956, 1.956)
		},

		10: {
			"offset": Vector2(-120.0, -2.0),
			"scale": Vector2(1.956, 1.956)
		},

		11: {
			"offset": Vector2(-80.0, 14.0),
			"scale": Vector2(1.956, 1.956)
		},

		12: {
			"offset": Vector2(-50.0, 22.0),
			"scale": Vector2(1.956, 1.956)
		},

		13: {
			"offset": Vector2(-20.0, 27.0),
			"scale": Vector2(1.956, 1.956)
		},

		14: {
			"offset": Vector2(24.0, 29.0),
			"scale": Vector2(1.956, 1.956)
		},

		15: {
			"offset": Vector2(60.0, 22.0),
			"scale": Vector2(1.956, 1.956)
		},

		16: {
			"offset": Vector2(88.0, 18.0),
			"scale": Vector2(1.956, 1.956)
		},
		17: {
			"offset": Vector2(120.0, 10.0),
			"scale": Vector2(1.956, 1.956)
		},

		18: {
			"offset": Vector2(180.0, 0.0),
			"scale": Vector2(1.956, 1.956)
		},

		19: {
			"offset": Vector2(180.0, -15.0),
			"scale": Vector2(1.956, 1.956)
		},

		20: {
			"offset": Vector2(0.0, 0.0),
			"scale": Vector2(1.94, 1.94)
		},

		21: {
			"offset": Vector2(0.0, 0.0),
			"scale": Vector2(1.94, 1.94)
		},

		22: {
			"offset": Vector2(0.0, 0.0),
			"scale": Vector2(1.94, 1.94)
		},

		23: {
			"offset": Vector2(0.0, 0.0),
			"scale": Vector2(1.94, 1.94)
		},

		24: {
			"offset": Vector2(0.0, 0.0),
			"scale": Vector2(1.94, 1.94)
		},

		25: {
			"offset": Vector2(0.0, 0.0),
			"scale": Vector2(1.94, 1.94)
		},

		26: {
			"offset": Vector2(0.0, 0.0),
			"scale": Vector2(1.94, 1.94)
		}
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
