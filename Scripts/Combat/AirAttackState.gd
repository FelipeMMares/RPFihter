extends AttackState
class_name AirAttackState


@export var landing_state: StringName = &"Idle"

var _attack_animation_finished: bool = false


func _enter() -> void:
	_attack_animation_finished = false

	# Executa a configuração normal do AttackState:
	# inicia animação, desliga a HitBox inicialmente etc.
	super._enter()


func _physics_process(delta: float) -> void:
	var character := _get_character()

	if character == null:
		return

	# Quando tocar no chão, encerra o ataque aéreo.
	if (
		character.is_on_floor()
		and character.velocity.y >= 0.0
	):
		if hitbox != null:
			hitbox.disable()

		_hitbox_active = false

		transition_to.emit(landing_state)
		return

	# Enquanto a animação ainda estiver sendo executada,
	# mantém o controle normal dos frames ativos.
	if not _attack_animation_finished:
		super._physics_process(delta)
		return

	# Depois que a animação termina, permanece neste
	# estado, mas sem manter a HitBox ativa.
	if hitbox != null:
		hitbox.disable()

	_hitbox_active = false


func _animation_finished() -> void:
	# Não chama super._animation_finished(), porque
	# AttackState faria a transição para next_state.
	_attack_animation_finished = true

	if hitbox != null:
		hitbox.disable()

	_hitbox_active = false

	# Não troca de estado aqui.
	# O último frame da animação permanecerá visível
	# até o personagem tocar no chão.


func _exit() -> void:
	_attack_animation_finished = false

	super._exit()


func _get_character() -> CharacterBody2D:
	var current_node: Node = get_parent()

	while current_node != null:
		if current_node is CharacterBody2D:
			return current_node as CharacterBody2D

		current_node = current_node.get_parent()

	return null
