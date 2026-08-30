@tool
extends EditorScript

# ================================================================
# RPFighters - Potemkin Visual Profile Auto-Balance
#
# O script NÃO sobrescreve o arquivo original.
# Ele lê o perfil atual do projeto, aplica uma base visual estável
# e grava:
#
# res://Cenas/Potenkim/PotemkinVisualProfile_BALANCEADO.tres
#
# Estratégia:
# 1. Todas as animações recebem baseline Offset=(0,0), Scale=(1.1,1.1).
#    Isso impede que o AnimatedSprite2D da cena injete (40,60)/(1.2,1.2)
#    em frames sem override.
# 2. Animações genéricas usam os offsets já calibrados a partir do Idle.
# 3. Scale por frame das animações genéricas é desligado para evitar
#    "respiração"/pulsação de tamanho.
# 4. Nos ataques, offsets e scales específicos existentes são preservados.
#    Apenas o baseline passa a ser seguro (0,0 / 1.1).
# 5. Se a MESMA textura aparecer mais de uma vez dentro de uma animação,
#    o mesmo offset/scale é reaplicado nas repetições. Isso elimina tremor
#    em sequências que vão e voltam usando o mesmo PNG.
# ================================================================

const PROFILE_PATH := "res://Cenas/Potenkim/PotemkinVisualProfile.tres"
const FRAMES_PATH := "res://Cenas/Potenkim/Potemkin_frames.tres"
const OUTPUT_PATH := "res://Cenas/Potenkim/PotemkinVisualProfile_BALANCEADO.tres"

const BASE_OFFSET := Vector2.ZERO
const BASE_SCALE := Vector2(1.1, 1.1)

# Valores consolidados usando o Idle estável como referência.
# Cada Array corresponde aos frames 0..N da animação.
var GENERIC_OFFSETS: Dictionary = {
	&"Idle": [
		Vector2(0, 0), Vector2(0, 0), Vector2(4, 0),
		Vector2(4, 0), Vector2(4, 0), Vector2(4, -8),
		Vector2(4, 0), Vector2(4, 0), Vector2(4, 0),
		Vector2(0, 0), Vector2(0, 0),
	],

	&"Walk": [
		Vector2(0, 0), Vector2(4, 8), Vector2(14, 12),
		Vector2(-2, -4), Vector2(-12, -8), Vector2(0, -8),
		Vector2(10, 0), Vector2(16, 8), Vector2(2, -8),
		Vector2(-14, -4), Vector2(-6, -4),
	],

	&"CrouchStart": [
		Vector2(-4, 0), Vector2(4, 24), Vector2(4, 16),
	],

	&"CrouchEnd": [
		Vector2(4, 16), Vector2(4, 24), Vector2(-4, 0),
	],

	&"CrouchWhile": [
		Vector2(4, 24), Vector2(4, 16), Vector2(4, 16),
		Vector2(4, 16), Vector2(0, 16), Vector2(0, 16),
		Vector2(0, 16), Vector2(0, 16), Vector2(0, 16),
		Vector2(4, 16), Vector2(4, 16), Vector2(4, 16),
		Vector2(4, 24),
	],

	&"StartJump": [
		Vector2(-4, 0), Vector2(4, 24), Vector2(4, 16),
		Vector2(4, 16), Vector2(4, 16), Vector2(0, 16),
		Vector2(0, 16), Vector2(0, 16),
	],

	&"Jump": [
		Vector2(22, 0), Vector2(26, -40), Vector2(30, -32),
		Vector2(16, -24), Vector2(18, -56), Vector2(14, -72),
		Vector2(8, -84),
	],

	&"Guard": [
		Vector2(16, 8), Vector2(4, 0), Vector2(-2, 0),
	],

	&"GuardWhile": [
		Vector2(-2, 0),
	],

	# Parry ainda não tinha ajuste próprio no perfil antigo.
	# Mantém o corpo na mesma referência do Idle.
	&"Parry": [
		Vector2(0, 0), Vector2(0, 0), Vector2(0, 0),
	],

	&"ParryRecoil": [
		Vector2(-2, 4), Vector2(4, 4), Vector2(6, 4),
		Vector2(14, 24), Vector2(20, 28), Vector2(26, 12),
	],

	&"Hurt": [
		Vector2(6, -12), Vector2(4, -12), Vector2(6, 0),
		Vector2(10, 0), Vector2(14, 4), Vector2(20, -8),
		Vector2(14, 4), Vector2(10, 0), Vector2(6, 0),
		Vector2(4, -12), Vector2(6, -12),
	],

	&"HurtFall": [
		Vector2(6, -8), Vector2(8, 16), Vector2(16, 16),
		Vector2(18, 22), Vector2(22, 20), Vector2(24, 20),
		Vector2(28, 4), Vector2(28, 8), Vector2(24, 0),
		Vector2(12, 0), Vector2(22, 0), Vector2(24, 28),
		Vector2(26, 44), Vector2(34, 56),
	],

	&"Fall": [
		Vector2(34, 56),
	],

	&"FallDefeated": [
		Vector2(6, -8), Vector2(8, 16), Vector2(16, 16),
		Vector2(18, 22), Vector2(22, 20), Vector2(24, 20),
		Vector2(28, 4), Vector2(28, 8), Vector2(24, 0),
		Vector2(12, 0), Vector2(22, 0), Vector2(24, 28),
		Vector2(26, 44), Vector2(34, 56), Vector2(50, 56),
	],

	&"GetUp": [
		Vector2(26, 28), Vector2(18, 12), Vector2(10, 0),
		Vector2(18, 0), Vector2(-2, -12),
	],

	&"Defeated": [
		Vector2(4, 0), Vector2(8, 0),
	],

	&"Stun": [
		Vector2(-6, 4), Vector2(-6, 4), Vector2(-6, 4),
		Vector2(-6, 4), Vector2(-6, 4), Vector2(-6, 4),
		Vector2(-6, 4), Vector2(-6, 4),
	],

	&"Thrown": [
		Vector2(26, -24), Vector2(24, -8),
	],

	&"Entry": [
		Vector2(12, -32), Vector2(0, -36), Vector2(6, -36),
		Vector2(10, -36), Vector2(16, -40), Vector2(8, -72),
		Vector2(0, -84), Vector2(-6, -88), Vector2(2, -56),
		Vector2(6, -36), Vector2(14, -8), Vector2(8, 0),
		Vector2(2, -4),
	],

	&"Victory": [
		Vector2(0, -8), Vector2(2, -8), Vector2(0, -8),
		Vector2(12, -28), Vector2(12, -36), Vector2(14, -56),
		Vector2(14, -80), Vector2(40, -108), Vector2(20, -61),
		Vector2(20, -61), Vector2(10, -45), Vector2(14, -96),
		Vector2(16, -92), Vector2(14, -96),
	],

	&"Taunt": [
		Vector2(20, -32), Vector2(8, -12), Vector2(14, -20),
		Vector2(26, -24), Vector2(42, -36), Vector2(40, -28),
		Vector2(50, -32), Vector2(54, -32), Vector2(60, -44),
		Vector2(56, -92), Vector2(56, -80), Vector2(52, -84),
		Vector2(52, -112), Vector2(38, -32), Vector2(36, -28),
		Vector2(36, -32), Vector2(38, -28), Vector2(36, -28),
		Vector2(36, -28), Vector2(38, -28), Vector2(40, -32),
		# A partir daqui a Taunt reutiliza a Entry.
		Vector2(12, -32), Vector2(0, -36), Vector2(6, -36),
		Vector2(10, -36), Vector2(16, -40), Vector2(8, -72),
		Vector2(0, -84), Vector2(-6, -88), Vector2(2, -56),
		Vector2(6, -36), Vector2(14, -8), Vector2(8, 0),
		Vector2(2, -4),
	],
}


func _run() -> void:
	var original := ResourceLoader.load(PROFILE_PATH) as AnimationVisualProfile
	if original == null:
		push_error("Potemkin Auto-Balance: não foi possível carregar: " + PROFILE_PATH)
		return

	var sprite_frames := ResourceLoader.load(FRAMES_PATH) as SpriteFrames
	if sprite_frames == null:
		push_error("Potemkin Auto-Balance: não foi possível carregar: " + FRAMES_PATH)
		return

	# Deep duplicate: o arquivo original permanece intacto.
	var profile := original.duplicate(true) as AnimationVisualProfile
	if profile == null:
		push_error("Potemkin Auto-Balance: falha ao duplicar o perfil.")
		return

	print("================================================")
	print("POTEMKIN VISUAL PROFILE - AUTO BALANCE")
	print("Origem: ", PROFILE_PATH)
	print("Saída : ", OUTPUT_PATH)
	print("================================================")

	# 1) Baseline seguro para TODAS as animações do SpriteFrames.
	# Isso impede que qualquer animação/frame sem override volte ao
	# offset/scale salvos no AnimatedSprite2D da cena.
	for animation_name in sprite_frames.get_animation_names():
		var anim_adjustment := _get_or_create_animation_adjustment(
			profile,
			animation_name
		)

		anim_adjustment.override_offset = true
		anim_adjustment.offset = BASE_OFFSET

		anim_adjustment.override_scale = true
		anim_adjustment.scale = BASE_SCALE

	# 2) Cria/aplica os ajustes genéricos consolidados.
	for animation_variant in GENERIC_OFFSETS.keys():
		var animation_name := StringName(animation_variant)

		if not sprite_frames.has_animation(animation_name):
			print("[aviso] SpriteFrames não possui animação: ", animation_name)
			continue

		var animation_adjustment := _get_or_create_animation_adjustment(
			profile,
			animation_name
		)

		animation_adjustment.override_offset = true
		animation_adjustment.offset = BASE_OFFSET
		animation_adjustment.override_scale = true
		animation_adjustment.scale = BASE_SCALE

		var offsets: Array = GENERIC_OFFSETS[animation_name]
		var actual_frame_count := sprite_frames.get_frame_count(animation_name)
		var count := mini(offsets.size(), actual_frame_count)

		for frame_index in range(count):
			var frame_adjustment := _get_or_create_frame_adjustment(
				animation_adjustment,
				frame_index
			)

			frame_adjustment.override_offset = true
			frame_adjustment.offset = offsets[frame_index]

			# Escala fixa da animação: elimina pulsação visual.
			frame_adjustment.override_scale = false
			frame_adjustment.scale = BASE_SCALE

		# Mesmo nos frames extras não previstos, não permita scale individual
		# em animações genéricas. Eles herdam 1.1 da animação.
		for frame_adjustment in animation_adjustment.frame_adjustments:
			if frame_adjustment == null:
				continue
			frame_adjustment.override_scale = false
			frame_adjustment.scale = BASE_SCALE

	# 3) Se um ataque/recovery reutiliza exatamente um PNG já calibrado
	# em uma animação genérica, reaplica a mesma âncora. Isso evita
	# saltos na transição para Idle/Entry/Crouch etc.
	_apply_generic_texture_anchors(
		profile,
		sprite_frames
	)

	# 4) Corrige repetições da MESMA textura dentro de cada animação.
	# Usa preferencialmente um frame que já tenha offset explícito.
	for animation_name in sprite_frames.get_animation_names():
		var animation_adjustment := _find_animation_adjustment(
			profile,
			animation_name
		)

		if animation_adjustment == null:
			continue

		_synchronize_repeated_textures(
			sprite_frames,
			animation_name,
			animation_adjustment
		)

	# 5) Salva como arquivo novo.
	var error := ResourceSaver.save(profile, OUTPUT_PATH)
	if error != OK:
		push_error(
			"Potemkin Auto-Balance: erro ao salvar (%s): %s" % [
				error,
				OUTPUT_PATH,
			]
		)
		return

	get_editor_interface().get_resource_filesystem().scan()

	print("")
	print("✅ Perfil balanceado gerado com sucesso:")
	print(OUTPUT_PATH)
	print("")
	print("O arquivo ORIGINAL NÃO foi alterado.")
	print("Troque o VisualProfile do Potemkin pelo arquivo *_BALANCEADO.tres")
	print("e teste primeiro Idle -> Walk -> Hurt -> Jump.")
	print("================================================")


func _find_animation_adjustment(
	profile: AnimationVisualProfile,
	animation_name: StringName
) -> AnimationVisualAdjustment:
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
	var existing := _find_animation_adjustment(
		profile,
		animation_name
	)

	if existing != null:
		return existing

	var created := AnimationVisualAdjustment.new()
	created.animation_name = animation_name
	created.override_offset = true
	created.offset = BASE_OFFSET
	created.override_scale = true
	created.scale = BASE_SCALE

	profile.animation_adjustments.append(created)
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
	var existing := _find_frame_adjustment(
		animation_adjustment,
		frame_index
	)

	if existing != null:
		return existing

	var created := FrameVisualAdjustment.new()
	created.frame = frame_index

	animation_adjustment.frame_adjustments.append(
		created
	)

	return created


func _texture_key(texture: Texture2D) -> String:
	if texture == null:
		return ""

	var key := texture.resource_path
	if key.is_empty():
		key = "instance:%s" % texture.get_instance_id()

	return key


func _apply_generic_texture_anchors(
	profile: AnimationVisualProfile,
	sprite_frames: SpriteFrames
) -> void:
	# PNG -> offset de referência conhecido.
	var canonical_offsets: Dictionary = {}

	for animation_variant in GENERIC_OFFSETS.keys():
		var animation_name := StringName(animation_variant)
		if not sprite_frames.has_animation(animation_name):
			continue

		var offsets: Array = GENERIC_OFFSETS[animation_name]
		var count := mini(
			offsets.size(),
			sprite_frames.get_frame_count(animation_name)
		)

		for frame_index in range(count):
			var texture := sprite_frames.get_frame_texture(
				animation_name,
				frame_index
			)
			var key := _texture_key(texture)
			if key.is_empty():
				continue

			# A primeira ocorrência genérica calibrada vira a referência.
			if not canonical_offsets.has(key):
				canonical_offsets[key] = offsets[frame_index]

	for animation_name in sprite_frames.get_animation_names():
		var animation_adjustment := _get_or_create_animation_adjustment(
			profile,
			animation_name
		)

		var frame_count := sprite_frames.get_frame_count(animation_name)
		for frame_index in range(frame_count):
			var texture := sprite_frames.get_frame_texture(
				animation_name,
				frame_index
			)
			var key := _texture_key(texture)
			if not canonical_offsets.has(key):
				continue

			var adjustment := _get_or_create_frame_adjustment(
				animation_adjustment,
				frame_index
			)

			adjustment.override_offset = true
			adjustment.offset = canonical_offsets[key]

			# Mesmo PNG = mesmo tamanho visual de referência.
			adjustment.override_scale = false
			adjustment.scale = BASE_SCALE


func _synchronize_repeated_textures(
	sprite_frames: SpriteFrames,
	animation_name: StringName,
	animation_adjustment: AnimationVisualAdjustment
) -> void:
	var frame_count := sprite_frames.get_frame_count(animation_name)
	if frame_count <= 1:
		return

	# texture_key -> Array[int] dos frames que usam o mesmo PNG.
	var occurrences: Dictionary = {}

	for frame_index in range(frame_count):
		var texture := sprite_frames.get_frame_texture(
			animation_name,
			frame_index
		)

		if texture == null:
			continue

		var key := _texture_key(texture)

		if not occurrences.has(key):
			occurrences[key] = []

		occurrences[key].append(frame_index)

	for key in occurrences.keys():
		var frames: Array = occurrences[key]
		if frames.size() < 2:
			continue

		# Procura o melhor frame canônico:
		# primeiro um frame com override explícito; senão o primeiro.
		var canonical_frame: int = int(frames[0])
		var canonical_adjustment: FrameVisualAdjustment = null

		for frame_variant in frames:
			var frame_index := int(frame_variant)
			var candidate := _find_frame_adjustment(
				animation_adjustment,
				frame_index
			)

			if candidate == null:
				continue

			if candidate.override_offset or candidate.override_scale:
				canonical_frame = frame_index
				canonical_adjustment = candidate
				break

		if canonical_adjustment == null:
			canonical_adjustment = _find_frame_adjustment(
				animation_adjustment,
				canonical_frame
			)

		# Se nenhum frame tinha ajuste, todos já herdam o mesmo baseline.
		if canonical_adjustment == null:
			continue

		# Offset efetivo do frame canônico.
		var canonical_offset := animation_adjustment.offset
		if canonical_adjustment.override_offset:
			canonical_offset = canonical_adjustment.offset

		# Scale efetivo do frame canônico.
		var canonical_scale := animation_adjustment.scale
		var canonical_has_frame_scale := canonical_adjustment.override_scale
		if canonical_has_frame_scale:
			canonical_scale = canonical_adjustment.scale

		for frame_variant in frames:
			var frame_index := int(frame_variant)
			if frame_index == canonical_frame:
				continue

			var target := _get_or_create_frame_adjustment(
				animation_adjustment,
				frame_index
			)

			target.override_offset = true
			target.offset = canonical_offset

			# Para genéricos, scale por frame já foi desligado.
			# Para ataques, preservamos a necessidade de scale específico
			# apenas quando a textura canônica realmente tinha esse override.
			if not GENERIC_OFFSETS.has(animation_name):
				target.override_scale = canonical_has_frame_scale
				target.scale = canonical_scale
