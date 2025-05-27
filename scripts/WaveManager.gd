extends Node

# Referência da cena do inimigo
@export var enemy_scene: PackedScene = preload("res://scenes/nave_inimiga.tscn")
@export var spawn_delay = 1.0  # Tempo entre spawns na mesma onda
@export var wave_start_delay = 2.0  # Tempo entre ondas

# Configuração das ondas
var wave_configs = [
	{"enemies": 2, "spawn_pattern": "sequential"},  # Onda 1: 2 inimigos
	{"enemies": 2, "spawn_pattern": "sequential"},  # Onda 2: 2 inimigos  
	{"enemies": 3, "spawn_pattern": "sequential"},  # Onda 3: 3 inimigos
	{"enemies": 3, "spawn_pattern": "mixed"}, # Onda 4: 3 inimigos juntos
	{"enemies": 4, "spawn_pattern": "sequential"},  # Onda 5: 4 inimigos
	{"enemies": 4, "spawn_pattern": "simultaneous"}, # Onda 6: 4 inimigos juntos
	{"enemies": 5, "spawn_pattern": "mixed"},       # Onda 7: 5 inimigos - padrão misto
]

# Posições de spawn (você pode ajustar conforme sua tela)
var spawn_positions = [
	Vector2(160, -50),   # Esquerda
	Vector2(324, -50),   # Centro  
	Vector2(488, -50),   # Direita
	Vector2(100, -50),   # Mais à esquerda
	Vector2(548, -50),   # Mais à direita
]

# Variáveis de controle
var current_wave = 0
var enemies_alive = 0
var enemies_spawned_this_wave = 0
var wave_active = false
var game_completed = false
var spawned_enemies = []  # Array para rastrear inimigos ativos

# Referências
var player_ref = null
var main_scene_ref = null

# Sinais
signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)  
signal all_waves_completed
signal enemy_spawned(enemy: Node)

func _ready() -> void:
	# Encontra referências importantes
	player_ref = get_tree().get_first_node_in_group("player")
	main_scene_ref = get_parent()  # Assume que este script está na cena principal
	
	# Conecta sinal de morte do player se existir
	if player_ref and player_ref.has_signal("player_died"):
		player_ref.player_died.connect(_on_player_died)
	
	print("Wave Manager iniciado - Total de ondas: ", wave_configs.size())
	
	# Inicia primeira onda após um delay
	await get_tree().create_timer(2.0).timeout
	start_next_wave()

func start_next_wave() -> void:
	if game_completed:
		return
		
	if current_wave >= wave_configs.size():
		_complete_all_waves()
		return
	
	wave_active = true
	enemies_spawned_this_wave = 0
	spawned_enemies.clear()  # Limpa a lista de inimigos
	
	var wave_config = wave_configs[current_wave]
	print("=== INICIANDO ONDA ", current_wave + 1, " ===")
	print("Inimigos nesta onda: ", wave_config.enemies)
	print("Padrão de spawn: ", wave_config.spawn_pattern)
	
	# Emite sinal de onda iniciada
	wave_started.emit(current_wave + 1)
	
	# Spawnar inimigos baseado no padrão
	match wave_config.spawn_pattern:
		"sequential":
			_spawn_sequential(wave_config.enemies)
		"simultaneous":
			_spawn_simultaneous(wave_config.enemies)
		"mixed":
			_spawn_mixed(wave_config.enemies)

func _spawn_sequential(enemy_count: int) -> void:
	for i in range(enemy_count):
		_spawn_enemy(i)
		if i < enemy_count - 1:  # Não espera no último
			await get_tree().create_timer(spawn_delay).timeout

func _spawn_simultaneous(enemy_count: int) -> void:
	for i in range(enemy_count):
		_spawn_enemy(i)

func _spawn_mixed(enemy_count: int) -> void:
	# Spawna metade simultânea, depois o resto sequencial
	var simultaneous_count = enemy_count / 2
	var sequential_count = enemy_count - simultaneous_count
	
	# Primeiro grupo simultâneo
	for i in range(simultaneous_count):
		_spawn_enemy(i)
	
	# Aguarda um pouco
	await get_tree().create_timer(spawn_delay * 2).timeout
	
	# Segundo grupo sequencial
	for i in range(sequential_count):
		_spawn_enemy(simultaneous_count + i)
		if i < sequential_count - 1:
			await get_tree().create_timer(spawn_delay).timeout

func _spawn_enemy(index: int) -> void:
	if not enemy_scene:
		print("ERRO: Cena do inimigo não encontrada!")
		return
	
	var enemy = enemy_scene.instantiate()
	
	# Escolhe posição de spawn
	var spawn_pos = spawn_positions[index % spawn_positions.size()]
	
	# Adiciona alguma variação aleatória na posição X
	spawn_pos.x += randf_range(-30, 30)
	
	enemy.position = spawn_pos
	
	# Adiciona o inimigo ao grupo para identificação
	enemy.add_to_group("inimigo")
	
	# Conecta apenas UM sinal de morte - prioriza enemy_died
	if enemy.has_signal("enemy_died"):
		enemy.enemy_died.connect(_on_enemy_died.bind(enemy))
		print("Conectado sinal enemy_died para inimigo")
	else:
		print("Sinal enemy_died não encontrado, usando tree_exited")
		enemy.tree_exited.connect(_on_enemy_removed.bind(enemy))
	
	# Adiciona à cena
	main_scene_ref.add_child(enemy)
	
	# Adiciona à lista de inimigos rastreados
	spawned_enemies.append(enemy)
	enemies_alive += 1
	enemies_spawned_this_wave += 1
	
	print("✅ Inimigo spawnado: ", enemy.name, " - Vivos: ", enemies_alive, " | Total na lista: ", spawned_enemies.size())
	
	# Emite sinal
	enemy_spawned.emit(enemy)

func _on_enemy_died(enemy: Node) -> void:
	print("🎯 SINAL enemy_died recebido para: ", enemy.name if enemy else "NULO")
	_remove_enemy_from_tracking(enemy)

func _on_enemy_removed(enemy: Node) -> void:
	print("🚪 SINAL tree_exited recebido para: ", enemy.name if enemy else "NULO")
	_remove_enemy_from_tracking(enemy)

func _remove_enemy_from_tracking(enemy: Node) -> void:
	# Remove da lista apenas se ainda estiver lá
	if enemy in spawned_enemies:
		spawned_enemies.erase(enemy)
		enemies_alive -= 1
		print("🔴 INIMIGO MORREU: ", enemy.name if enemy else "NULO", " - Restam: ", enemies_alive)
		
		# Verifica se a onda acabou
		if enemies_alive <= 0 and wave_active:
			print("⚠️  TODOS OS INIMIGOS MORRERAM - PULANDO PARA PRÓXIMA ONDA!")
			_complete_current_wave()
	else:
		print("⚠️  Tentativa de remover inimigo que não estava sendo rastreado: ", enemy.name if enemy else "NULO")

# Função para verificar inimigos válidos (para debug)
func _process(delta: float) -> void:
	if wave_active:
		# Remove inimigos inválidos da lista (que foram destruídos externamente)
		var valid_enemies = []
		for enemy in spawned_enemies:
			if is_instance_valid(enemy) and enemy.get_parent() != null:
				valid_enemies.append(enemy)
		
		if valid_enemies.size() != spawned_enemies.size():
			print("Inimigos inválidos detectados. Ajustando contagem...")
			spawned_enemies = valid_enemies
			enemies_alive = spawned_enemies.size()
			
			if enemies_alive <= 0 and wave_active:
				_complete_current_wave()

func _complete_current_wave() -> void:
	wave_active = false
	current_wave += 1
	
	print("=== ONDA ", current_wave, " COMPLETA! ===")
	
	# Emite sinal de onda completa
	wave_completed.emit(current_wave)
	
	# Aguarda antes da próxima onda
	await get_tree().create_timer(wave_start_delay).timeout
	
	start_next_wave()

func _complete_all_waves() -> void:
	game_completed = true
	print("=== TODAS AS ONDAS COMPLETADAS! PARABÉNS! ===")
	
	all_waves_completed.emit()

func _on_player_died() -> void:
	wave_active = false
	game_completed = true
	print("Player morreu - Wave Manager pausado")

# Funções utilitárias
func get_current_wave() -> int:
	return current_wave + 1

func get_total_waves() -> int:
	return wave_configs.size()

func get_enemies_alive() -> int:
	return enemies_alive

func is_wave_active() -> bool:
	return wave_active

func add_custom_wave(enemy_count: int, pattern: String = "sequential") -> void:
	wave_configs.append({"enemies": enemy_count, "spawn_pattern": pattern})

func skip_to_wave(wave_number: int) -> void:
	if wave_number <= 0 or wave_number > wave_configs.size():
		return
		
	current_wave = wave_number - 1
	enemies_alive = 0
	wave_active = false
	spawned_enemies.clear()
	
	# Remove inimigos existentes
	var existing_enemies = get_tree().get_nodes_in_group("inimigo")
	for enemy in existing_enemies:
		enemy.queue_free()
	
	start_next_wave()
