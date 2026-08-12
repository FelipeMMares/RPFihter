extends CanvasLayer
class_name FightHUD

signal time_over
signal guard_changed(
	current_value: float,
	max_value: float
)

signal guard_broken
signal guard_reset

@onready var player_1_hp: ProgressBar = %Player1HP
@onready var player_2_hp: ProgressBar = %Player2HP
@onready var timer_label: Label = %Timer
@onready var sudden_death_label: Label = $__/_/SuddenDeathLabel



@onready var player_1_win_icons: Array[TextureRect] = [
	%Player1Win1,
	%Player1Win2
]

@onready var player_2_win_icons: Array[TextureRect] = [
	%Player2Win1,
	%Player2Win2
]

@onready var player_guard_indicator: GuardIndicator = (
	$PlayerGuardIndicator
)

@onready var dummy_guard_indicator: GuardIndicator = (
	$DummyGuardIndicator
)

@export var hp_animation_speed: float = 800.0
@export var round_time: float = 90.0

@onready var round_message_label: Label = %RoundMessage

@onready var round_transition_overlay: ColorRect = (
	%RoundTransitionOverlay
)

@onready var player_1_mp: ProgressBar = %Player1MP
@onready var player_2_mp: ProgressBar = %Player2MP

var player_health: Health
var dummy_health: Health

var remaining_time: float = 0.0
var round_running: bool = false

var target_player_1_hp: float = 0.0
var target_player_2_hp: float = 0.0
var timer_enabled: bool = true
var _round_transition_tween: Tween

var player_magic_points: MagicPoints
var dummy_magic_points: MagicPoints

var target_player_1_mp: float = 0.0
var target_player_2_mp: float = 0.0

var max_guard: float = 100.0
var current_guard: float = 100.0

@export var mp_animation_speed: float = 3.0

func _ready() -> void:
	update_wins(0, 0)

	if sudden_death_label != null:
		sudden_death_label.visible = false

	if player_1_hp == null:
		printerr("HUD: Player1HP não foi encontrado.")

	if player_2_hp == null:
		printerr("HUD: Player2HP não foi encontrado.")

	if timer_label == null:
		printerr("HUD: Timer não foi encontrado.")

	if round_message_label != null:
		round_message_label.visible = false

	if round_transition_overlay != null:
		round_transition_overlay.visible = false
		round_transition_overlay.color = Color.BLACK
		round_transition_overlay.modulate = Color(
			1.0,
			1.0,
			1.0,
			0.0
		)
	else:
		printerr(
			"HUD: RoundTransitionOverlay não encontrado."
		)

func setup(
	player_health_reference: Health,
	dummy_health_reference: Health,
	player_mp_reference: MagicPoints,
	dummy_mp_reference: MagicPoints
) -> void:
	player_health = player_health_reference
	dummy_health = dummy_health_reference

	player_magic_points = player_mp_reference
	dummy_magic_points = dummy_mp_reference

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

	if (
		player_magic_points != null
		and not player_magic_points.mp_changed.is_connected(
			_on_player_mp_changed
		)
	):
		player_magic_points.mp_changed.connect(
			_on_player_mp_changed
		)

	if (
		dummy_magic_points != null
		and not dummy_magic_points.mp_changed.is_connected(
			_on_dummy_mp_changed
		)
	):
		dummy_magic_points.mp_changed.connect(
			_on_dummy_mp_changed
		)

	_setup_bars()
	_setup_mp_bars()


func _process(delta: float) -> void:
	# As barras de vida devem continuar sendo atualizadas
	# mesmo quando o cronômetro estiver desativado.
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

	player_1_mp.value = move_toward(
		player_1_mp.value,
		target_player_1_mp,
		mp_animation_speed * delta
	)

	player_2_mp.value = move_toward(
		player_2_mp.value,
		target_player_2_mp,
		mp_animation_speed * delta
	)

	# Se o round terminou, não conta o tempo.
	if not round_running:
		return

	# Durante a morte súbita, o round continua ativo,
	# mas o tempo não diminui.
	if not timer_enabled:
		return

	remaining_time = maxf(
		remaining_time - delta,
		0.0
	)

	timer_label.text = str(
		ceili(remaining_time)
	)

	if remaining_time <= 0.0:
		round_running = false
		timer_label.text = "TIME"
		time_over.emit()

func show_ko() -> void:
	round_running = false

	if round_message_label == null:
		return

	round_message_label.text = "KO"
	round_message_label.visible = true

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

	# O round continua ativo mesmo durante a morte súbita.
	# Apenas o cronômetro fica desativado.
	round_running = true

	if timer_label != null:
		timer_label.visible = true

		if timer_enabled:
			timer_label.text = str(
				ceili(remaining_time)
			)
		else:
			timer_label.text = "∞"

	target_player_1_hp = player_health.current_health
	target_player_2_hp = dummy_health.current_health

	player_1_hp.value = player_health.current_health
	player_2_hp.value = dummy_health.current_health

	update_wins(
		player_1_victories,
		player_2_victories
	)

	if timer_enabled:
		print(
			"HUD: round iniciado com ",
			remaining_time,
			" segundos."
		)
	else:
		print("HUD: round de morte súbita iniciado sem tempo.")

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


func show_round_message(
	message: String
) -> void:
	round_running = false

	if round_message_label == null:
		printerr(
			"HUD: RoundMessage não encontrado."
		)
		return

	round_message_label.text = message
	round_message_label.visible = true


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

func set_timer_enabled(enabled: bool) -> void:
	timer_enabled = enabled

	if timer_label == null:
		return

	timer_label.visible = true

	if timer_enabled:
		if round_running:
			timer_label.text = str(
				ceili(remaining_time)
			)

		print("HUD: cronômetro ativado.")
	else:
		# Não coloca "∞" aqui.
		# O cronômetro também é desativado em KO,
		# timeout e no fim da luta.
		print("HUD: cronômetro desativado.")

func set_sudden_death_mode(active: bool) -> void:
	if sudden_death_label == null:
		printerr(
			"HUD: SuddenDeathLabel não encontrado."
		)
		return

	sudden_death_label.visible = active

	if active:
		timer_enabled = false

		if timer_label != null:
			timer_label.visible = true
			timer_label.text = "∞"

		sudden_death_label.text = (
			"MORTE SÚBITA\n"
			+ "PRIMEIRO GOLPE VENCE"
		)

		print(
			"HUD: modo de morte súbita ativado."
		)
	else:
		print(
			"HUD: modo de morte súbita desativado."
		)

func prepare_round_intro() -> void:
	# O cronômetro ainda não está correndo.
	round_running = false
	remaining_time = round_time

	if timer_label != null:
		timer_label.visible = true

		if timer_enabled:
			timer_label.text = str(
				ceili(remaining_time)
			)
		else:
			timer_label.text = "∞"

	hide_round_message()


func show_countdown(
	countdown_value: int
) -> void:
	round_running = false

	if round_message_label == null:
		return

	round_message_label.text = (
		"READY?\n"
		+ str(countdown_value)
	)

	round_message_label.visible = true


func show_fight_message() -> void:
	if round_message_label == null:
		return

	round_message_label.text = "LUTEM!"
	round_message_label.visible = true


func hide_round_message() -> void:
	if round_message_label == null:
		return

	round_message_label.visible = false
	round_message_label.text = ""

func fade_to_black(
	duration: float
) -> void:
	if round_transition_overlay == null:
		return

	_stop_round_transition_tween()

	round_transition_overlay.visible = true
	round_transition_overlay.modulate = Color(
		1.0,
		1.0,
		1.0,
		0.0
	)

	if duration <= 0.0:
		round_transition_overlay.modulate = Color.WHITE
		return

	_round_transition_tween = create_tween()

	_round_transition_tween.tween_property(
		round_transition_overlay,
		"modulate:a",
		1.0,
		duration
	)

	await _round_transition_tween.finished


func fade_from_black(
	duration: float
) -> void:
	if round_transition_overlay == null:
		return

	_stop_round_transition_tween()

	round_transition_overlay.visible = true
	round_transition_overlay.modulate = Color.WHITE

	if duration <= 0.0:
		round_transition_overlay.modulate = Color(
			1.0,
			1.0,
			1.0,
			0.0
		)

		round_transition_overlay.visible = false
		return

	_round_transition_tween = create_tween()

	_round_transition_tween.tween_property(
		round_transition_overlay,
		"modulate:a",
		0.0,
		duration
	)

	await _round_transition_tween.finished

	round_transition_overlay.visible = false


func set_round_transition_black() -> void:
	if round_transition_overlay == null:
		return

	_stop_round_transition_tween()

	round_transition_overlay.visible = true
	round_transition_overlay.modulate = Color.WHITE


func _stop_round_transition_tween() -> void:
	if (
		_round_transition_tween != null
		and _round_transition_tween.is_valid()
	):
		_round_transition_tween.kill()

	_round_transition_tween = null

func _setup_mp_bars() -> void:
	if (
		player_1_mp == null
		or player_2_mp == null
	):
		printerr(
			"HUD: barras de MP não encontradas."
		)
		return

	if (
		player_magic_points == null
		or dummy_magic_points == null
	):
		printerr(
			"HUD: MagicPoints não configurados."
		)
		return

	player_1_mp.min_value = 0.0
	player_1_mp.max_value = (
		player_magic_points.max_mp
	)
	player_1_mp.value = (
		player_magic_points.current_mp
	)

	player_2_mp.min_value = 0.0
	player_2_mp.max_value = (
		dummy_magic_points.max_mp
	)
	player_2_mp.value = (
		dummy_magic_points.current_mp
	)

	target_player_1_mp = (
		player_magic_points.current_mp
	)

	target_player_2_mp = (
		dummy_magic_points.current_mp
	)

func _on_player_mp_changed(
	current_mp: float,
	maximum_mp: float
) -> void:
	if player_1_mp == null:
		return

	player_1_mp.max_value = maximum_mp
	target_player_1_mp = current_mp


func _on_dummy_mp_changed(
	current_mp: float,
	maximum_mp: float
) -> void:
	if player_2_mp == null:
		return

	player_2_mp.max_value = maximum_mp
	target_player_2_mp = current_mp

func apply_guard_damage(
	amount: float
) -> void:
	current_guard = maxf(
		current_guard - amount,
		0.0
	)

	guard_changed.emit(
		current_guard,
		max_guard
	)

	if current_guard <= 0.0:
		guard_broken.emit()

func update_player_guard(
	current_hits: int,
	max_hits: int
) -> void:
	player_guard_indicator.update_guard(
		current_hits,
		max_hits
	)


func update_dummy_guard(
	current_hits: int,
	max_hits: int
) -> void:
	dummy_guard_indicator.update_guard(
		current_hits,
		max_hits
	)


func break_player_guard() -> void:
	player_guard_indicator.break_guard()


func break_dummy_guard() -> void:
	dummy_guard_indicator.break_guard()


func reset_player_guard() -> void:
	player_guard_indicator.reset_guard()


func reset_dummy_guard() -> void:
	dummy_guard_indicator.reset_guard()
