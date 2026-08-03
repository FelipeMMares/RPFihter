extends State


func _enter() -> void:
	move.emit(Vector2.ZERO)

	set_crouching_hurtbox(false)

	# Mantém o alvo usando o sprite de dano.
	play_animation.emit(&"Hurt", false)


func _physics_process(_delta: float) -> void:
	var character := _get_character()

	if character == null:
		return

	if character.has_method("update_throw_capture"):
		character.call("update_throw_capture")


# Não sai quando a animação Hurt termina.
# O atacante decide quando o personagem será solto.
func _animation_finished() -> void:
	pass


func _get_character() -> CharacterBody2D:
	return get_parent().get_parent() as CharacterBody2D
