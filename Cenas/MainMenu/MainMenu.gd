extends Control
class_name MainMenu


@export_file("*.tscn")
var fight_scene_path: String = (
	"res://Cenas/Cenarios/CenaDaLuta.tscn"
)


@onready var start_button: Button = (
	$Background/CenterContainer/VBoxContainer/StartButton
)

@export_file("*.tscn")
var character_select_scene_path: String = (
	"res://Cenas/CharacterSelect/CharacterSelect.tscn"
)

func _ready() -> void:
	# Garante que o jogo não continue pausado ao
	# retornar do menu final da luta.
	get_tree().paused = false

	if start_button == null:
		printerr(
			"MainMenu: StartButton não encontrado."
		)
		return

	start_button.pressed.connect(
		_on_start_button_pressed
	)

	start_button.grab_focus()


func _on_start_button_pressed() -> void:
	_change_scene(character_select_scene_path)


func _change_scene(scene_path: String) -> void:
	if scene_path.is_empty():
		printerr(
			"MainMenu: caminho da luta não configurado."
		)
		return

	if not ResourceLoader.exists(scene_path):
		printerr(
			"MainMenu: cena não encontrada: ",
			scene_path
		)
		return

	get_tree().paused = false

	var change_error: Error = (
		get_tree().change_scene_to_file(
			scene_path
		)
	)

	if change_error != OK:
		printerr(
			"MainMenu: erro ao abrir a cena: ",
			change_error
		)
