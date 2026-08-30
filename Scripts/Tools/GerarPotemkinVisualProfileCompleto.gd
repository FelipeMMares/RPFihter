@tool
extends EditorScript

# ================================================================
# RPFighters - Potemkin Visual Profile Auto-Balance COMPLETO
#
# Gera um NOVO perfil e não sobrescreve o original.
#
# Objetivo:
# - Idle = referência visual principal.
# - Base segura para TODAS as animações:
#       Offset = (0, 0)
#       Scale  = (1.1, 1.1)
# - Genéricas/cinemáticas recebem offsets explícitos calibrados.
# - TODOS os ataques recebem scale uniforme 1.1.
# - Offsets dos ataques são capturados do perfil original antes
#   da normalização, evitando perder deslocamentos intencionais.
# - Frames sem offset explícito deixam de herdar o (40,60) da cena.
# - PNG repetido recebe a mesma âncora.
# - PNG usado por genérica e ataque herda a âncora canônica genérica.
#
# IMPORTANTE:
# AnimationVisualProfile.gd
# AnimationVisualAdjustment.gd
# FrameVisualAdjustment.gd
# precisam começar com @tool.
# ================================================================


const PROFILE_PATH := (
	"res://Cenas/Potenkim/PotemkinVisualProfile.tres"
)

const FRAMES_PATH := (
	"res://Cenas/Potenkim/Potemkin_frames.tres"
)

const OUTPUT_PATH := (
	"res://Cenas/Potenkim/"
	+ "PotemkinVisualProfile_COMPLETO.tres"
)


const BASE_OFFSET := Vector2.ZERO
const BASE_SCALE := Vector2(1.1, 1.1)


# ================================================================
# ANIMAÇÕES DE ATAQUE
#
# Os offsets destas animações são lidos do perfil ORIGINAL.
# O gerador não depende de números duplicados aqui.
# ================================================================

const ATTACK_ANIMATIONS := [
	&"LightPunch",
	&"HighPunch",
	&"Kick",
	&"LowKick",

	&"CrouchLightPunch",
	&"CrouchHighPunch",
	&"CrouchKick",
	&"CrouchLowKick",

	&"AirLightPunch",
	&"AirHighPunch",
	&"AirKick",
	&"AirLowKick",

	&"MegaFist",
	&"SlideHead",

	&"PotenkimBusterTry",
	&"PotenkimBuster",

	&"TryGrab",
	&"Throw",
]


# ================================================================
# OFFSETS GENÉRICOS / CINEMÁTICOS
#
# Idle estável é a referência.
# Scale individual é DESLIGADO em todos estes frames.
# ================================================================

var GENERIC_OFFSETS: Dictionary = {
	&"Idle": [
		Vector2(0, 0),
		Vector2(0, 0),
		Vector2(4, 0),
		Vector2(4, 0),
		Vector2(4, 0),
		Vector2(4, -8),
		Vector2(4, 0),
		Vector2(4, 0),
		Vector2(4, 0),
		Vector2(0, 0),
		Vector2(0, 0),
	],

	&"Walk": [
		Vector2(0, 0),
		Vector2(4, 8),
		Vector2(14, 12),
		Vector2(-2, -4),
		Vector2(-12, -8),
		Vector2(0, -8),
		Vector2(10, 0),
		Vector2(16, 8),
		Vector2(2, -8),
		Vector2(-14, -4),
		Vector2(-6, -4),
	],

	&"CrouchStart": [
		Vector2(-4, 0),
		Vector2(4, 24),
		Vector2(4, 16),
	],

	&"CrouchEnd": [
		Vector2(4, 16),
		Vector2(4, 24),
		Vector2(-4, 0),
	],

	&"CrouchWhile": [
		Vector2(4, 24),
		Vector2(4, 16),
		Vector2(4, 16),
		Vector2(4, 16),
		Vector2(0, 16),
		Vector2(0, 16),
		Vector2(0, 16),
		Vector2(0, 16),
		Vector2(0, 16),
		Vector2(4, 16),
		Vector2(4, 16),
		Vector2(4, 16),
		Vector2(4, 24),
	],

	&"StartJump": [
		Vector2(-4, 0),
		Vector2(4, 24),
		Vector2(4, 16),
		Vector2(4, 16),
		Vector2(4, 16),
		Vector2(0, 16),
		Vector2(0, 16),
		Vector2(0, 16),
	],

	&"Jump": [
		Vector2(22, 0),
		Vector2(26, -40),
		Vector2(30, -32),
		Vector2(16, -24),
		Vector2(18, -56),
		Vector2(14, -72),
		Vector2(8, -84),
	],

	&"Guard": [
		Vector2(16, 8),
		Vector2(4, 0),
		Vector2(-2, 0),
	],

	&"GuardWhile": [
		Vector2(-2, 0),
	],

	&"Parry": [
		Vector2(0, 0),
		Vector2(0, 0),
		Vector2(0, 0),
	],

	&"ParryRecoil": [
		Vector2(-2, 4),
		Vector2(4, 4),
		Vector2(6, 4),
		Vector2(14, 24),
		Vector2(20, 28),
		Vector2(26, 12),
	],

	&"Hurt": [
		Vector2(6, -12),
		Vector2(4, -12),
		Vector2(6, 0),
		Vector2(10, 0),
		Vector2(14, 4),
		Vector2(20, -8),
		Vector2(14, 4),
		Vector2(10, 0),
		Vector2(6, 0),
		Vector2(4, -12),
		Vector2(6, -12),
	],

	&"HurtFall": [
		Vector2(6, -8),
		Vector2(8, 16),
		Vector2(16, 16),
		Vector2(18, 22),
		Vector2(22, 20),
		Vector2(24, 20),
		Vector2(28, 4),
		Vector2(28, 8),
		Vector2(24, 0),
		Vector2(12, 0),
		Vector2(22, 0),
		Vector2(24, 28),
		Vector2(26, 44),
		Vector2(34, 56),
	],

	&"Fall": [
		Vector2(34, 56),
	],

	&"FallDefeated": [
		Vector2(6, -8),
		Vector2(8, 16),
		Vector2(16, 16),
		Vector2(18, 22),
		Vector2(22, 20),
		Vector2(24, 20),
		Vector2(28, 4),
		Vector2(28, 8),
		Vector2(24, 0),
		Vector2(12, 0),
		Vector2(22, 0),
		Vector2(24, 28),
		Vector2(26, 44),
		Vector2(34, 56),
		Vector2(50, 56),
	],

	&"GetUp": [
		Vector2(26, 28),
		Vector2(18, 12),
		Vector2(10, 0),
		Vector2(18, 0),
		Vector2(-2, -12),
	],

	&"Defeated": [
		Vector2(4, 0),
		Vector2(8, 0),
	],

	&"Stun": [
		Vector2(-6, 4),
		Vector2(-6, 4),
		Vector2(-6, 4),
		Vector2(-6, 4),
		Vector2(-6, 4),
		Vector2(-6, 4),
		Vector2(-6, 4),
		Vector2(-6, 4),
	],

	&"Thrown": [
		Vector2(26, -24),
		Vector2(24, -8),
	],

	&"Entry": [
		Vector2(12, -32),
		Vector2(0, -36),
		Vector2(6, -36),
		Vector2(10, -36),
		Vector2(16, -40),
		Vector2(8, -72),
		Vector2(0, -84),
		Vector2(-6, -88),
		Vector2(2, -56),
		Vector2(6, -36),
		Vector2(14, -8),
		Vector2(8, 0),
		Vector2(2, -4),
	],

	&"Victory": [
		Vector2(0, -8),
		Vector2(2, -8),
		Vector2(0, -8),
		Vector2(12, -28),
		Vector2(12, -36),
		Vector2(14, -56),
		Vector2(14, -80),
		Vector2(40, -108),
		Vector2(20, -61),
		Vector2(20, -61),
		Vector2(10, -45),
		Vector2(14, -96),
		Vector2(16, -92),
		Vector2(14, -96),
	],

	# Taunt é propositalmente explícita.
	# F21..F33 correspondem à sequência da Entry.
	&"Taunt": [
		Vector2(20, -32),
		Vector2(8, -12),
		Vector2(14, -20),
		Vector2(26, -24),
		Vector2(42, -36),
		Vector2(40, -28),
		Vector2(50, -32),
		Vector2(54, -32),
		Vector2(60, -44),
		Vector2(56, -92),
		Vector2(56, -80),
		Vector2(52, -84),
		Vector2(52, -112),
		Vector2(38, -32),
		Vector2(36, -28),
		Vector2(36, -32),
		Vector2(38, -28),
		Vector2(36, -28),
		Vector2(36, -28),
		Vector2(38, -28),
		Vector2(40, -32),

		Vector2(12, -32),
		Vector2(0, -36),
		Vector2(6, -36),
		Vector2(10, -36),
		Vector2(16, -40),
		Vector2(8, -72),
		Vector2(0, -84),
		Vector2(-6, -88),
		Vector2(2, -56),
		Vector2(6, -36),
		Vector2(14, -8),
		Vector2(8, 0),
		Vector2(2, -4),
	],
}


# ================================================================
# EXECUÇÃO
# ================================================================

func _run() -> void:
	var original := (
		ResourceLoader.load(PROFILE_PATH)
		as AnimationVisualProfile
	)

	if original == null:
		push_error(
			"Potemkin Auto-Balance COMPLETO: "
			+ "não foi possível carregar: "
			+ PROFILE_PATH
		)
		return

	var sprite_frames := (
		ResourceLoader.load(FRAMES_PATH)
		as SpriteFrames
	)

	if sprite_frames == null:
		push_error(
			"Potemkin Auto-Balance COMPLETO: "
			+ "não foi possível carregar: "
			+ FRAMES_PATH
		)
		return

	# ------------------------------------------------------------
	# 0) Captura os offsets dos ataques ANTES de alterar o perfil.
	#
	# Se um frame não tinha override:
	# - usa o offset padrão da animação, se houver;
	# - caso contrário usa (0,0).
	#
	# Nunca usa o (40,60) do AnimatedSprite2D da cena.
	# ------------------------------------------------------------

	var captured_attack_offsets := (
		_capture_attack_offsets(
			original,
			sprite_frames
		)
	)

	# Deep duplicate: original permanece intacto.
	var profile := (
		original.duplicate(true)
		as AnimationVisualProfile
	)

	if profile == null:
		push_error(
			"Potemkin Auto-Balance COMPLETO: "
			+ "falha ao duplicar o perfil."
		)
		return

	print("")
	print("================================================")
	print("POTEMKIN VISUAL PROFILE - AUTO BALANCE COMPLETO")
	print("Origem: ", PROFILE_PATH)
	print("Saída : ", OUTPUT_PATH)
	print("Scale : ", BASE_SCALE)
	print("================================================")

	# ------------------------------------------------------------
	# 1) BASELINE SEGURO PARA TODAS AS ANIMAÇÕES
	# ------------------------------------------------------------

	for animation_name in sprite_frames.get_animation_names():
		var anim_adjustment := (
			_get_or_create_animation_adjustment(
				profile,
				animation_name
			)
		)

		if anim_adjustment == null:
			continue

		anim_adjustment.override_offset = true
		anim_adjustment.offset = BASE_OFFSET

		anim_adjustment.override_scale = true
		anim_adjustment.scale = BASE_SCALE

		# Remove TODA variação antiga de scale por frame.
		for frame_adjustment in anim_adjustment.frame_adjustments:
			if frame_adjustment == null:
				continue

			frame_adjustment.override_scale = false
			frame_adjustment.scale = BASE_SCALE

	# ------------------------------------------------------------
	# 2) GENÉRICAS / CINEMÁTICAS
	# ------------------------------------------------------------

	_apply_explicit_generic_offsets(
		profile,
		sprite_frames
	)

	# ------------------------------------------------------------
	# 3) ATAQUES
	#
	# Reaplica os offsets capturados do perfil original,
	# mas todos agora usam scale 1.1.
	# Todo frame passa a possuir offset explícito.
	# ------------------------------------------------------------

	_apply_captured_attack_offsets(
		profile,
		sprite_frames,
		captured_attack_offsets
	)

	# ------------------------------------------------------------
	# 4) ÂNCORAS CANÔNICAS POR TEXTURA
	#
	# Se um ataque reutiliza um PNG conhecido de Idle/Crouch/
	# Entry/etc, ele recebe exatamente a mesma âncora.
	# ------------------------------------------------------------

	_apply_generic_texture_anchors(
		profile,
		sprite_frames
	)

	# ------------------------------------------------------------
	# 5) MESMA TEXTURA = MESMO AJUSTE
	#
	# Corrige animações de ida/volta e repetições.
	# ------------------------------------------------------------

	for animation_name in sprite_frames.get_animation_names():
		var animation_adjustment := (
			_find_animation_adjustment(
				profile,
				animation_name
			)
		)

		if animation_adjustment == null:
			continue

		_synchronize_repeated_textures(
			sprite_frames,
			animation_name,
			animation_adjustment
		)

	# ------------------------------------------------------------
	# 6) GARANTIA FINAL
	#
	# Nenhum frame do perfil final pode voltar a alterar scale.
	# ------------------------------------------------------------

	_force_uniform_scale_everywhere(
		profile
	)

	# ------------------------------------------------------------
	# 7) SALVAR
	# ------------------------------------------------------------

	var error := ResourceSaver.save(
		profile,
		OUTPUT_PATH
	)

	if error != OK:
		push_error(
			"Potemkin Auto-Balance COMPLETO: "
			+ "erro ao salvar (%s): %s"
			% [
				error,
				OUTPUT_PATH,
			]
		)
		return

	get_editor_interface().get_resource_filesystem().scan()

	print("")
	print("✅ Perfil COMPLETO gerado com sucesso:")
	print(OUTPUT_PATH)
	print("")
	print("O ORIGINAL NÃO foi alterado.")
	print("")
	print("O novo perfil:")
	print("  • usa 1.1 em TODAS as animações")
	print("  • corrige genéricas/cinemáticas")
	print("  • corrige Taunt explicitamente")
	print("  • normaliza TODOS os ataques")
	print("  • impede herança do offset (40,60)")
	print("  • sincroniza PNGs repetidos")
	print("")
	print("Teste nesta ordem:")
	print(
		"Idle -> Walk -> Hurt -> Taunt -> "
		+ "LightPunch -> HighPunch -> MegaFist -> "
		+ "SlideHead -> PotenkimBuster"
	)
	print("================================================")
	print("")


# ================================================================
# CAPTURA DOS ATAQUES
# ================================================================

func _capture_attack_offsets(
	profile: AnimationVisualProfile,
	sprite_frames: SpriteFrames
) -> Dictionary:
	var result: Dictionary = {}

	for attack_variant in ATTACK_ANIMATIONS:
		var animation_name := StringName(
			attack_variant
		)

		if not sprite_frames.has_animation(
			animation_name
		):
			print(
				"[aviso] ataque ausente no SpriteFrames: ",
				animation_name
			)
			continue

		var animation_adjustment := (
			_find_animation_adjustment(
				profile,
				animation_name
			)
		)

		var offsets: Array[Vector2] = []

		var frame_count := (
			sprite_frames.get_frame_count(
				animation_name
			)
		)

		for frame_index in range(
			frame_count
		):
			var effective_offset := (
				_get_effective_original_offset(
					animation_adjustment,
					frame_index
				)
			)

			offsets.append(
				effective_offset
			)

		result[animation_name] = offsets

	return result


func _get_effective_original_offset(
	animation_adjustment: AnimationVisualAdjustment,
	frame_index: int
) -> Vector2:
	if animation_adjustment == null:
		return BASE_OFFSET

	var frame_adjustment := (
		_find_frame_adjustment(
			animation_adjustment,
			frame_index
		)
	)

	if (
		frame_adjustment != null
		and frame_adjustment.override_offset
	):
		return frame_adjustment.offset

	if animation_adjustment.override_offset:
		return animation_adjustment.offset

	# Muito importante:
	# não herda o offset da cena.
	return BASE_OFFSET


func _apply_captured_attack_offsets(
	profile: AnimationVisualProfile,
	sprite_frames: SpriteFrames,
	captured_offsets: Dictionary
) -> void:
	for attack_variant in ATTACK_ANIMATIONS:
		var animation_name := StringName(
			attack_variant
		)

		if not sprite_frames.has_animation(
			animation_name
		):
			continue

		var animation_adjustment := (
			_get_or_create_animation_adjustment(
				profile,
				animation_name
			)
		)

		if animation_adjustment == null:
			continue

		animation_adjustment.override_offset = true
		animation_adjustment.offset = BASE_OFFSET

		animation_adjustment.override_scale = true
		animation_adjustment.scale = BASE_SCALE

		var offsets: Array = []

		if captured_offsets.has(
			animation_name
		):
			offsets = captured_offsets[
				animation_name
			]

		var frame_count := (
			sprite_frames.get_frame_count(
				animation_name
			)
		)

		for frame_index in range(
			frame_count
		):
			var adjustment := (
				_get_or_create_frame_adjustment(
					animation_adjustment,
					frame_index
				)
			)

			if adjustment == null:
				continue

			var attack_offset := BASE_OFFSET

			if frame_index < offsets.size():
				attack_offset = offsets[
					frame_index
				]

			adjustment.override_offset = true
			adjustment.offset = attack_offset

			adjustment.override_scale = false
			adjustment.scale = BASE_SCALE


# ================================================================
# GENÉRICAS
# ================================================================

func _apply_explicit_generic_offsets(
	profile: AnimationVisualProfile,
	sprite_frames: SpriteFrames
) -> void:
	for animation_variant in GENERIC_OFFSETS.keys():
		var animation_name := StringName(
			animation_variant
		)

		if not sprite_frames.has_animation(
			animation_name
		):
			print(
				"[aviso] SpriteFrames não possui animação: ",
				animation_name
			)
			continue

		var animation_adjustment := (
			_get_or_create_animation_adjustment(
				profile,
				animation_name
			)
		)

		if animation_adjustment == null:
			continue

		animation_adjustment.override_offset = true
		animation_adjustment.offset = BASE_OFFSET

		animation_adjustment.override_scale = true
		animation_adjustment.scale = BASE_SCALE

		var offsets: Array = (
			GENERIC_OFFSETS[
				animation_name
			]
		)

		var actual_frame_count := (
			sprite_frames.get_frame_count(
				animation_name
			)
		)

		var count := mini(
			offsets.size(),
			actual_frame_count
		)

		for frame_index in range(
			count
		):
			var frame_adjustment := (
				_get_or_create_frame_adjustment(
					animation_adjustment,
					frame_index
				)
			)

			if frame_adjustment == null:
				continue

			frame_adjustment.override_offset = true
			frame_adjustment.offset = offsets[
				frame_index
			]

			frame_adjustment.override_scale = false
			frame_adjustment.scale = BASE_SCALE

		# Frames extras não previstos:
		# criamos explicitamente com offset base.
		for frame_index in range(
			count,
			actual_frame_count
		):
			var frame_adjustment := (
				_get_or_create_frame_adjustment(
					animation_adjustment,
					frame_index
				)
			)

			if frame_adjustment == null:
				continue

			if not frame_adjustment.override_offset:
				frame_adjustment.override_offset = true
				frame_adjustment.offset = BASE_OFFSET

			frame_adjustment.override_scale = false
			frame_adjustment.scale = BASE_SCALE


# ================================================================
# BUSCAS / CRIAÇÃO SEGURA
#
# Não chamamos get_frame_adjustment() da Resource.
# Isso também evita o problema de placeholder que ocorreu antes.
# ================================================================

func _find_animation_adjustment(
	profile: AnimationVisualProfile,
	animation_name: StringName
) -> AnimationVisualAdjustment:
	if profile == null:
		return null

	for adjustment in profile.animation_adjustments:
		if adjustment == null:
			continue

		if adjustment.animation_name == animation_name:
			return adjustment

	return null


func _get_or_create_animation_adjustment(
	profile: AnimationVisualProfile,
	animation_name: StringName
) -> AnimationVisualAdjustment:
	var existing := (
		_find_animation_adjustment(
			profile,
			animation_name
		)
	)

	if existing != null:
		return existing

	var created := (
		AnimationVisualAdjustment.new()
	)

	if created == null:
		push_error(
			"Falha ao criar AnimationVisualAdjustment: "
			+ String(animation_name)
		)
		return null

	created.animation_name = animation_name
	created.override_offset = true
	created.offset = BASE_OFFSET
	created.override_scale = true
	created.scale = BASE_SCALE

	profile.animation_adjustments.append(
		created
	)

	return created


func _find_frame_adjustment(
	animation_adjustment: AnimationVisualAdjustment,
	frame_index: int
) -> FrameVisualAdjustment:
	if animation_adjustment == null:
		return null

	for adjustment in animation_adjustment.frame_adjustments:
		if adjustment == null:
			continue

		if adjustment.frame == frame_index:
			return adjustment

	return null


func _get_or_create_frame_adjustment(
	animation_adjustment: AnimationVisualAdjustment,
	frame_index: int
) -> FrameVisualAdjustment:
	if animation_adjustment == null:
		return null

	var existing := (
		_find_frame_adjustment(
			animation_adjustment,
			frame_index
		)
	)

	if existing != null:
		return existing

	var created := (
		FrameVisualAdjustment.new()
	)

	if created == null:
		push_error(
			"Falha ao criar FrameVisualAdjustment: frame "
			+ str(frame_index)
		)
		return null

	created.frame = frame_index

	animation_adjustment.frame_adjustments.append(
		created
	)

	return created


# ================================================================
# ÂNCORAS DE TEXTURA
# ================================================================

func _texture_key(
	texture: Texture2D
) -> String:
	if texture == null:
		return ""

	var key := texture.resource_path

	if key.is_empty():
		key = (
			"instance:%s"
			% texture.get_instance_id()
		)

	return key


func _apply_generic_texture_anchors(
	profile: AnimationVisualProfile,
	sprite_frames: SpriteFrames
) -> void:
	# PNG -> offset canônico.
	var canonical_offsets: Dictionary = {}

	# Primeiro, somente animações calibradas explicitamente
	# podem definir a referência global.
	for animation_variant in GENERIC_OFFSETS.keys():
		var animation_name := StringName(
			animation_variant
		)

		if not sprite_frames.has_animation(
			animation_name
		):
			continue

		var offsets: Array = (
			GENERIC_OFFSETS[
				animation_name
			]
		)

		var count := mini(
			offsets.size(),
			sprite_frames.get_frame_count(
				animation_name
			)
		)

		for frame_index in range(
			count
		):
			var texture := (
				sprite_frames.get_frame_texture(
					animation_name,
					frame_index
				)
			)

			var key := _texture_key(
				texture
			)

			if key.is_empty():
				continue

			if not canonical_offsets.has(
				key
			):
				canonical_offsets[key] = (
					offsets[
						frame_index
					]
				)

	# Depois aplica a referência a QUALQUER animação,
	# inclusive ataques.
	for animation_name in sprite_frames.get_animation_names():
		var animation_adjustment := (
			_get_or_create_animation_adjustment(
				profile,
				animation_name
			)
		)

		if animation_adjustment == null:
			continue

		var frame_count := (
			sprite_frames.get_frame_count(
				animation_name
			)
		)

		for frame_index in range(
			frame_count
		):
			var texture := (
				sprite_frames.get_frame_texture(
					animation_name,
					frame_index
				)
			)

			var key := _texture_key(
				texture
			)

			if not canonical_offsets.has(
				key
			):
				continue

			var adjustment := (
				_get_or_create_frame_adjustment(
					animation_adjustment,
					frame_index
				)
			)

			if adjustment == null:
				continue

			adjustment.override_offset = true
			adjustment.offset = (
				canonical_offsets[
					key
				]
			)

			adjustment.override_scale = false
			adjustment.scale = BASE_SCALE


# ================================================================
# SINCRONIZAÇÃO DE PNG REPETIDO
# ================================================================

func _synchronize_repeated_textures(
	sprite_frames: SpriteFrames,
	animation_name: StringName,
	animation_adjustment: AnimationVisualAdjustment
) -> void:
	var frame_count := (
		sprite_frames.get_frame_count(
			animation_name
		)
	)

	if frame_count <= 1:
		return

	# texture_key -> Array[int]
	var occurrences: Dictionary = {}

	for frame_index in range(
		frame_count
	):
		var texture := (
			sprite_frames.get_frame_texture(
				animation_name,
				frame_index
			)
		)

		if texture == null:
			continue

		var key := _texture_key(
			texture
		)

		if not occurrences.has(
			key
		):
			occurrences[key] = []

		occurrences[key].append(
			frame_index
		)

	for key in occurrences.keys():
		var frames: Array = occurrences[
			key
		]

		if frames.size() < 2:
			continue

		var canonical_frame := int(
			frames[0]
		)

		var canonical_adjustment := (
			_find_frame_adjustment(
				animation_adjustment,
				canonical_frame
			)
		)

		# Prefere o primeiro frame com offset explícito.
		for frame_variant in frames:
			var frame_index := int(
				frame_variant
			)

			var candidate := (
				_find_frame_adjustment(
					animation_adjustment,
					frame_index
				)
			)

			if candidate == null:
				continue

			if candidate.override_offset:
				canonical_frame = frame_index
				canonical_adjustment = candidate
				break

		if canonical_adjustment == null:
			continue

		var canonical_offset := (
			animation_adjustment.offset
		)

		if canonical_adjustment.override_offset:
			canonical_offset = (
				canonical_adjustment.offset
			)

		for frame_variant in frames:
			var frame_index := int(
				frame_variant
			)

			var target := (
				_get_or_create_frame_adjustment(
					animation_adjustment,
					frame_index
				)
			)

			if target == null:
				continue

			target.override_offset = true
			target.offset = canonical_offset

			target.override_scale = false
			target.scale = BASE_SCALE


# ================================================================
# GARANTIA FINAL DE SCALE
# ================================================================

func _force_uniform_scale_everywhere(
	profile: AnimationVisualProfile
) -> void:
	if profile == null:
		return

	for animation_adjustment in profile.animation_adjustments:
		if animation_adjustment == null:
			continue

		animation_adjustment.override_scale = true
		animation_adjustment.scale = BASE_SCALE

		# Baseline de offset também fica sempre seguro.
		animation_adjustment.override_offset = true

		for frame_adjustment in animation_adjustment.frame_adjustments:
			if frame_adjustment == null:
				continue

			frame_adjustment.override_scale = false
			frame_adjustment.scale = BASE_SCALE
