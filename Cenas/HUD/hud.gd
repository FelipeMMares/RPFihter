extends CanvasLayer
class_name FightHUD

signal time_over

@onready var player_1_hp: ProgressBar = %Player1HP
@onready var player_2_hp: ProgressBar = %Player2HP
@onready var timer_label: Label = %Timer

@onready var player_1_win_icons: Array[TextureRect] = [
	%Player1Win1,
	%Player1Win2
]

@onready var player_2_win_icons: Array[TextureRect] = [
	%Player2Win1,
	%Player2Win2
]

@export var hp_animation_speed: float = 800.0
@export var round_time: float = 90.0

var player_health: Health
var dummy_health: Health

var remaining_time: float = 0.0
var round_running: bool = false

var target_player_1_hp: float = 0.0
var target_player_2_hp: float = 0.0


func _ready() -> void:
	update_wins(0, 0)

	if player_1_hp == null:
		printerr("HUD: Player1HP não foi encontrado.")

	if player_2_hp == null:
		printerr("HUD: Player2HP não foi encontrado.")

	if timer_label == null:
		printerr("HUD: Timer não foi encontrado.")


func setup(
	player_health_reference: Health,
	dummy_health_reference: Health
) -> void:
	player_health = player_health_reference
	dummy_health = dummy_health_reference

	if not player_health.health_changed.is_connected(
		_on_player_health_changed
	):
		player_health.health_changed.connect(
			_on_player_health_changed
		)

	if not dummy_health.health_changed.is_connected(
		_on_dummy_health_changed
	):
		dummy_health.health_changed.connect(
			_on_dummy_health_changed
		)

	_setup_bars()

	# ALTERAÇÃO:
	# Não chama start_round() aqui.
	# O FightManager decide quando o round começa.


func _process(delta: float) -> void:
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

func show_ko() -> void:
	round_running = false
	timer_label.text = "KO"

func _setup_bars() -> void:
	if player_1_hp == null or player_2_hp == null:
		printerr("HUD: barras de HP não encontradas.")
		return

	if player_health == null or dummy_health == null:
		printerr("HUD: componentes Health não configurados.")
		return

	player_1_hp.min_value = 0
	player_1_hp.max_value = player_health.max_health
	player_1_hp.value = player_health.current_health

	player_2_hp.min_value = 0
	player_2_hp.max_value = dummy_health.max_health
	player_2_hp.value = dummy_health.current_health

	target_player_1_hp = player_health.current_health
	target_player_2_hp = dummy_health.current_health


func start_round(
	player_1_victories: int,
	player_2_victories: int
) -> void:
	if player_health == null or dummy_health == null:
		printerr("HUD: setup() precisa ser chamado antes.")
		return

	remaining_time = round_time
	round_running = true

	timer_label.text = str(ceili(remaining_time))

	target_player_1_hp = player_health.current_health
	target_player_2_hp = dummy_health.current_health

	player_1_hp.value = player_health.current_health
	player_2_hp.value = dummy_health.current_health

	update_wins(
		player_1_victories,
		player_2_victories
	)

	print("HUD: round iniciado com ", remaining_time, " segundos")

func _on_player_health_changed(
	current_health: int,
	max_health: int
) -> void:
	if player_1_hp == null:
		return

	player_1_hp.max_value = max_health
	target_player_1_hp = current_health


func _on_dummy_health_changed(
	current_health: int,
	max_health: int
) -> void:
	if player_2_hp == null:
		return

	player_2_hp.max_value = max_health
	target_player_2_hp = current_health


func stop_round_timer() -> void:
	round_running = false


func show_round_message(message: String) -> void:
	timer_label.text = message


func update_wins(
	player_1_victories: int,
	player_2_victories: int
) -> void:
	print(
		"HUD atualizando vitórias: Player 1 = ",
		player_1_victories,
		" | Player 2 = ",
		player_2_victories
	)

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
		if icons[i] == null:
			printerr("HUD: ícone de vitória no índice ", i, " está nulo.")
			continue

		icons[i].visible = i < victories
