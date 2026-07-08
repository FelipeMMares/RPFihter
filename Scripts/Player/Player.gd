extends CharacterBody2D

@export var speed : float = 150
@export var jump_force : float = 450.0
@export var gravity : float = 1200.0

func _physics_process(delta):

	if not is_on_floor():
		velocity.y += gravity * delta

	move_and_slide()

func jump():
	print("PLAYER PULOU")
	
	if is_on_floor():
		velocity.y = -jump_force

func move(direction: Vector2) -> void:
	
	velocity = direction * speed
	move_and_slide()
	
#func _input(event):
	#if event is InputEventKey and event.pressed:
		#match event.keycode:
			#KEY_1:
				## Teste automático: left, left, right
				#test_combo_left_left_right()
			#KEY_2:
				## Teste manual: você digita os inputs
				#print("Modo manual: use as teclas para testar")
			#KEY_F3:
				## Debug do buffer
				#debug_buffer()
#
##func test_combo_left_left_right():
##
	##print()
##
	##print("==========================")
	##print("TESTANDO COMBO")
	##print("==========================")
#
	#var parser = $CommandParser
#
	#parser.clear_buffer()
#
	#parser.input_buffer.add_test_sequence([
		#"left",
		#"left",
		#"right"
	#])
#
	#var move = parser.get_current_special_move()
#
	#print()
#
	#print("Resultado:")
#
	#if move == "":
		#print("Nenhum comando encontrado.")
	#else:
		#print(move)
#
	#print("==========================")
#
#func debug_buffer():
	#var parser = $CommandParser
	#if parser and parser.input_buffer:
		#parser.input_buffer.debug_buffer()
