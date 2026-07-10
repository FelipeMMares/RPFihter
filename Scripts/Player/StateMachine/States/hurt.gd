extends State

var hit_data: HitData
var hitstun_timer: int = 0

func set_hit_data(data: HitData) -> void:
	hit_data = data
	hitstun_timer = data.hitstun

	print("Hurt recebeu HitData")
	print("Animação solicitada: ", data.hurt_animation)
	print("Hitstun: ", data.hitstun)

func _enter() -> void:
	print("ENTROU NO ESTADO HURT")

	if hit_data == null:
		printerr("Hurt: hit_data está null")
		play_animation.emit(name, false)
		return

	print("Tocando animação Hurt: ", hit_data.hurt_animation)
	play_animation.emit(String(hit_data.hurt_animation), false)

func _physics_process(_delta: float) -> void:
	hitstun_timer -= 1

	if hitstun_timer <= 0:
		transition_to.emit("Idle")
