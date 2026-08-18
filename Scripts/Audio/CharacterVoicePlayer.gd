extends Node
class_name CharacterVoicePlayer


@export_group("Configuração")

@export_range(
	-20.0,
	6.0,
	0.5
)
var volume_db: float = 0.0

@export_range(
	0.0,
	0.10,
	0.01
)
var pitch_variation: float = 0.02


@onready var audio_player: AudioStreamPlayer = (
	$AudioStreamPlayer
)


func play_voice(
	voice: AudioStream,
	interrupt_current: bool = true
) -> void:
	if voice == null:
		return

	if audio_player == null:
		return

	if (
		audio_player.playing
		and not interrupt_current
	):
		return

	audio_player.stop()

	audio_player.stream = voice
	audio_player.volume_db = volume_db

	if pitch_variation > 0.0:
		audio_player.pitch_scale = randf_range(
			1.0 - pitch_variation,
			1.0 + pitch_variation
		)
	else:
		audio_player.pitch_scale = 1.0

	audio_player.play()


func play_random_voice(
	voices: Array[AudioStream],
	interrupt_current: bool = true
) -> void:
	if voices.is_empty():
		return

	var valid_voices: Array[AudioStream] = []

	for voice in voices:
		if voice != null:
			valid_voices.append(
				voice
			)

	if valid_voices.is_empty():
		return

	var selected_voice: AudioStream = (
		valid_voices.pick_random()
	)

	play_voice(
		selected_voice,
		interrupt_current
	)


func stop_voice() -> void:
	if audio_player == null:
		return

	audio_player.stop()
