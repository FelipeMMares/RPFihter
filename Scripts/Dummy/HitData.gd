extends Resource
class_name HitData

# ============================
# DANO
# ============================

@export var damage: int = 100

# ============================
# HITSTUN
# Quantos frames o oponente fica
# travado após ser atingido.
# ============================

@export var hitstun: int = 12

# ============================
# EMPURRÃO
# Intensidade do knockback.
# ============================

@export var pushback: float = 80.0

# ============================
# LANÇAMENTO
# Para golpes que levantam
# o oponente do chão.
# (Não usaremos ainda.)
# ============================

@export var launch: Vector2 = Vector2.ZERO

# ============================
# ANIMAÇÃO
# Nome da animação que será
# executada no oponente.
# ============================

@export var hurt_animation: StringName = &"Hurt"

# ============================
# DURAÇÃO DA HITBOX
# Quantos frames a hitbox
# permanece ativa.
# (Usaremos nos ataques.)
# ============================

@export var active_frames: int = 3
