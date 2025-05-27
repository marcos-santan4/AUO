extends Node2D

# Referências dos nós
@onready var player = $Nave  # Ajuste o caminho conforme sua estrutura
@onready var wave_manager = $WaveManager
@onready var ui_layer = $UILayer  # Para interface do usuário
@onready var wave_label = $UILayer/WaveLabel  # Label para mostrar onda atual

# Variáveis de controle da fase
var phase_completed = false

func _ready() -> void:
	# Conecta sinais do Wave Manager
	if wave_manager:
		wave_manager.wave_started.connect(_on_wave_started)
		wave_manager.wave_completed.connect(_on_wave_completed)
		wave_manager.all_waves_completed.connect(_on_all_waves_completed)
		wave_manager.enemy_spawned.connect(_on_enemy_spawned)
	
	# Conecta sinais do player
	if player:
		if player.has_signal("player_died"):
			player.player_died.connect(_on_player_died)
		if player.has_signal("hp_changed"):
			player.hp_changed.connect(_on_player_hp_changed)
	
	print("Fase 1 iniciada!")

func _on_wave_started(wave_number: int) -> void:
	print("Interface: Onda ", wave_number, " iniciada!")
	
	# Atualizar UI
	if wave_label:
		wave_label.text = "ONDA " + str(wave_number)
		_animate_wave_label()
	
	# Aqui você pode adicionar efeitos visuais, sons, etc.
	_play_wave_start_sound()

func _on_wave_completed(wave_number: int) -> void:
	print("Interface: Onda ", wave_number, " completa!")
	
	# Feedback visual
	_show_wave_complete_message(wave_number)
	
	# Aqui você pode dar recompensas, power-ups, etc.
	_maybe_give_powerup()

func _on_all_waves_completed() -> void:
	phase_completed = true
	print("FASE 1 COMPLETA!")
	
	# Mostrar tela de vitória ou ir para próxima fase
	_show_victory_screen()

func _on_enemy_spawned(enemy: Node) -> void:
	print("Novo inimigo spawnado: ", enemy.name)
	
	# Aqui você pode adicionar efeitos de spawn
	_create_spawn_effect(enemy.position)

func _on_player_died() -> void:
	print("Game Over!")
	
	# Mostrar tela de game over
	_show_game_over_screen()

func _on_player_hp_changed(new_hp: int) -> void:
	# Atualizar barra de HP na interface
	_update_hp_display(new_hp)

# Funções de interface e efeitos visuais

func _animate_wave_label() -> void:
	if not wave_label:
		return
		
	# Animação simples da label de onda
	var tween = create_tween()
	wave_label.modulate.a = 0
	wave_label.scale = Vector2(2, 2)
	
	tween.parallel().tween_property(wave_label, "modulate:a", 1.0, 0.5)
	tween.parallel().tween_property(wave_label, "scale", Vector2(1, 1), 0.5)
	
	# Esconde após alguns segundos
	await tween.finished
	await get_tree().create_timer(2.0).timeout
	
	var fade_tween = create_tween()
	fade_tween.tween_property(wave_label, "modulate:a", 0.0, 1.0)

func _show_wave_complete_message(wave_number: int) -> void:
	# Criar mensagem temporária
	var message = Label.new()
	message.text = "ONDA " + str(wave_number) + " COMPLETA!"
	message.add_theme_font_size_override("font_size", 32)
	message.position = Vector2(324 - 150, 576)  # Centro da tela
	
	add_child(message)
	
	# Animar e remover
	var tween = create_tween()
	message.modulate.a = 0
	tween.tween_property(message, "modulate:a", 1.0, 0.5)
	await tween.finished
	
	await get_tree().create_timer(1.5).timeout
	
	tween = create_tween()
	tween.tween_property(message, "modulate:a", 0.0, 0.5)
	await tween.finished
	
	message.queue_free()

func _create_spawn_effect(position: Vector2) -> void:
	# Efeito visual simples de spawn
	# Você pode criar um particle system ou animação aqui
	print("Efeito de spawn em: ", position)

func _play_wave_start_sound() -> void:
	# Tocar som de início de onda
	# Exemplo: $AudioStreamPlayer.play()
	pass

func _maybe_give_powerup() -> void:
	# Chance de dar power-up entre ondas
	if randf() < 0.3:  # 30% de chance
		print("Power-up seria dado aqui!")
		# Criar power-up, curar player, etc.

func _show_victory_screen() -> void:
	print("Mostrar tela de vitória")
	# Aqui você mudaria para uma cena de vitória ou próxima fase
	# get_tree().change_scene_to_file("res://scenes/victory.tscn")

func _show_game_over_screen() -> void:
	print("Mostrar tela de game over")
	# get_tree().change_scene_to_file("res://scenes/game_over.tscn")

func _update_hp_display(hp: int) -> void:
	# Atualizar interface de HP
	print("HP do player: ", hp)

# Funções de debug - REMOVIDO O CÓDIGO PROBLEMÁTICO

func _input(event: InputEvent) -> void:
	# Atalhos para debug - usando uma tecla específica que não conflita
	if event.is_action_pressed("ui_cancel"):  # ESC para debug
		if Input.is_key_pressed(KEY_CTRL):  # Ctrl+ESC para confirmar
			if wave_manager:
				print("DEBUG: Pulando para próxima onda")
				# Mata todos os inimigos para forçar próxima onda
				var enemies = get_tree().get_nodes_in_group("inimigo")
				for enemy in enemies:
					enemy.queue_free()

# Função para pausar/despausar o jogo
func _pause_game() -> void:
	get_tree().paused = true

func _resume_game() -> void:
	get_tree().paused = false
