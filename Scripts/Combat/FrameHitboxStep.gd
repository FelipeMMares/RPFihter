extends Resource
class_name FrameHitboxStep


# Primeiro e último frame em que esta etapa estará ativa.
@export var start_frame: int = 0
@export var end_frame: int = 0


# Índices das HitBoxes que serão ativadas.
#
# Os índices correspondem ao array "hitboxes"
# configurado no estado do golpe.
@export var hitbox_indices: Array[int] = []
