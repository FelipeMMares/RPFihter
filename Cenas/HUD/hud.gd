extends CanvasLayer
class_name FightHUD

@onready var player_1_hp: ProgressBar = %Player1HP
@onready var player_2_hp: ProgressBar = %Player2HP

@export var empty_win_texture: Texture2D
@export var filled_win_texture: Texture2D

@onready var player_1_win_icons: Array[TextureRect] = [
	%Player1Win1,
	%Player1Win2
]

@onready var player_2_win_icons: Array[TextureRect] = [
	%Player2Win2,
	%Player2Win2
]

@onready var timer_label: Label = %Timer
@export var hp_animation_speed: float = 800.0

signal time_over

var player_health: Health
var dummy_health: Health

var round_time: float = 90.0
var remaining_time: float = 90.0
var round_running: bool = false

var wins_player_1: int = 0
var wins_player_2: int = 0

var target_player_1_hp: float
var target_player_2_hp: float

func _ready() -> void:
	print("Player1HP: ", player_1_hp)
	print("Player2HP: ", player_2_hp)

	if player_1_hp == null:
		printerr("HUD: Player1HP não foi encontrado.")
		return

	if player_2_hp == null:
		printerr("HUD: Player2HP não foi encontrado.")
		return

func setup(
	player_health_reference: Health,
	dummy_health_reference: Health
) -> void:
	player_health = player_health_reference
	dummy_health = dummy_health_reference

	player_health.health_changed.connect(_on_player_health_changed)
	dummy_health.health_changed.connect(_on_dummy_health_changed)

	player_health.defeated.connect(_on_player_defeated)
	dummy_health.defeated.connect(_on_dummy_defeated)

	_setup_bars()
	start_round()


func _process(delta: float) -> void:
	# Mantém a animação suave das barras, caso você esteja usando.
	player_1_hp.value = move_toward(
		player_1_hp.value,
		target_player_1_hp,
		hp_animation_speed * delta
	)

	player_2_hp.value = move_toward(
		player_2_hp.value,
		target_player_2_hp,
		hp_animation_speed * delta
	)

	if not round_running:
		return

	remaining_time = maxf(
		remaining_time - delta,
		0.0
	)

	timer_label.text = str(ceili(remaining_time))

	if remaining_time <= 0.0:
		round_running = false
		timer_label.text = "TIME"
		time_over.emit()

func _setup_bars() -> void:
	if player_1_hp == null:
		printerr("HUD: Player1HP não foi encontrado.")
		return

	if player_2_hp == null:
		printerr("HUD: Player2HP não foi encontrado.")
		return

	if player_health == null:
		printerr("HUD: Health do Player não foi configurado.")
		return

	if dummy_health == null:
		printerr("HUD: Health do Dummy não foi configurado.")
		return

	player_1_hp.min_value = 0
	player_1_hp.max_value = player_health.max_health
	player_1_hp.value = player_health.current_health

	player_2_hp.min_value = 0
	player_2_hp.max_value = dummy_health.max_health
	player_2_hp.value = dummy_health.current_health

	target_player_1_hp = player_health.current_health
	target_player_2_hp = dummy_health.current_health


func start_round() -> void:
	remaining_time = round_time
	round_running = true

	player_health.reset_health()
	dummy_health.reset_health()

	timer_label.text = str(ceili(remaining_time))



func _on_player_health_changed(
	current_health: int,
	max_health: int
) -> void:
	player_1_hp.max_value = max_health
	target_player_1_hp = current_health
	player_1_hp.value = current_health


func _on_dummy_health_changed(
	current_health: int,
	max_health: int
) -> void:
	if player_2_hp == null:
		printerr("HUD: Player2HP está nulo ao atualizar a vida.")
		return

	player_2_hp.max_value = max_health
	target_player_2_hp = current_health
	player_2_hp.value = current_health

func _on_player_defeated() -> void:
	if not round_running:
		return

	wins_player_2 += 1
	round_running = false



func _on_dummy_defeated() -> void:
	if not round_running:
		return

	wins_player_1 += 1
	round_running = false



func _finish_round_by_time() -> void:
	round_running = false

	if player_health.current_health > dummy_health.current_health:
		wins_player_1 += 1
	elif dummy_health.current_health > player_health.current_health:
		wins_player_2 += 1



func stop_round_timer() -> void:
	round_running = false


func show_round_message(message: String) -> void:
	timer_label.text = message


func update_wins(
	player_1_victories: int,
	player_2_victories: int
) -> void:
	_update_win_icons(
		player_1_win_icons,
		player_1_victories
	)

	_update_win_icons(
		player_2_win_icons,
		player_2_victories
	)


func _update_win_icons(
	icons: Array[TextureRect],
	victories: int
) -> void:
	for i in range(icons.size()):
		if i < victories:
			icons[i].texture = filled_win_texture
		else:
			icons[i].texture = empty_win_texture
