# test_controls.gd
# Coloque este script no seu personagem ou em um nó separado

extends Node

@export var player_controls: PlayerControls
@export var command_parser: CommandParser

func _ready():
	# Espera um pouco e testa
	await get_tree().create_timer(2.0).timeout
	print("\n=== 🎮 TESTE COM PLAYERCONTROLS ===")
	print("Pressione as teclas para testar:")
	print("  [← ou A] = left")
	print("  [→ ou D] = right")
	print("  [J ou Z] = light_punch")
	print("  [K ou X] = high_punch")
	print("  [1] = Teste automático: left, left, right")
	print("  [2] = Teste automático: down, right, light_punch")
	print("  [F3] = Mostrar buffer atual")
	print("================================")

# No script do personagem
func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				test_combo_with_prefix()
			KEY_2:
				test_manual_mode()
			KEY_F3:
				debug_buffer()

func test_combo_with_prefix():
	print("\n=== TESTE COM PREFIXO: left, left, right ===")
	
	var parser = $CommandParser
	if not parser:
		print("❌ CommandParser não encontrado!")
		return
	
	var prefix = parser.input_buffer.input_prefix
	print("🔍 Prefixo: '", prefix, "'")
	
	# Limpa o buffer
	parser.input_buffer.buffer.clear()
	
	# Adiciona inputs com o prefixo correto
	parser.input_buffer.add_input_direct(prefix + "left")
	parser.input_buffer.add_input_direct(prefix + "left")
	parser.input_buffer.add_input_direct(prefix + "right")
	
	parser.input_buffer.debug_buffer()
	
	var move = parser.get_current_special_move()
	if move != "":
		print("✅ COMANDO RECONHECIDO: ", move)
	else:
		print("❌ Nenhum comando reconhecido")

func test_combo_hadouken():
	var move = command_parser.get_current_special_move()

	if move != "":
		print("🔥 Movimento detectado:", move)

	match move:

		"teste_combo":
			print("Combo de teste!")

		"hadouken":
			print("HADOUKEN!")

		"shoryuken":
			print("SHORYUKEN!")

		"tatsumaki":
			print("TATSUMAKI!")

func _simulate_action(action_name: String):
	# Método para simular um input
	# Isso é útil para testes automatizados
	var input_buffer = command_parser.input_buffer
	if input_buffer:
		# Remove o prefixo se existir
		var raw_action = action_name
		if action_name.begins_with(input_buffer.input_prefix):
			raw_action = action_name.trim_prefix(input_buffer.input_prefix)
		
		input_buffer.add_input_direct(raw_action)

func test_manual_mode():
	print("\n=== 🎮 MODO MANUAL ===")
	print("Pressione as teclas configuradas no PlayerControls")
	print("O buffer vai capturar automaticamente!")
	print("Pressione F3 para ver o buffer atual")

func debug_buffer():
	if command_parser and command_parser.input_buffer:
		command_parser.input_buffer.debug_buffer()
	else:
		print("❌ Buffer não disponível!")

func debug_parser_status():
	print("\n=== 📊 STATUS DO PARSER ===")
	if command_parser:
		print("✅ CommandParser: OK")
		print("📦 Commands: ", command_parser.commands.size())
		if command_parser.input_buffer:
			print("✅ InputBuffer: OK")
			print("🔤 Prefix: '", command_parser.input_buffer.input_prefix, "'")
			print("📊 Buffer size: ", command_parser.input_buffer.buffer.size())
			print("🎮 Ações registradas: ", command_parser.input_buffer.actions)
		else:
			print("❌ InputBuffer: NULL")
	else:
		print("❌ CommandParser: NULL")
	
	if player_controls:
		print("\n🎮 PlayerControls:")
		print("  left: ", player_controls.left)
		print("  right: ", player_controls.right)
		print("  down: ", player_controls.down)
		print("  up: ", player_controls.up)
		print("  light_punch: ", player_controls.light_punch)
		print("  high_punch: ", player_controls.high_punch)
		print("  kick: ", player_controls.kick)
		print("  low_kick: ", player_controls.low_kick)
	else:
		print("❌ PlayerControls: NULL")
