#nave_inimiga.gd
extends Area2D
signal enemy_died
@export var speed = 250
@export var fire_rate = 0.4
@export var dano = 20 
@export var bullets_scene = preload("res://scenes/laser_inimigo.tscn")
@export var shoot_offset = Vector2(-10, 5)
@export var initial_descent_speed = 200.0
@export var descent_target_y = 150.0  # Posição Y onde para de descer e começa comportamento normal

@onready var sprite: AnimatedSprite2D = $Sprite
var hp = 30
var tempo_para_atirar = 0.0
var player_reff = null
var direction_y = 1
var direction_x = -1
var wave_amplitude := 5
var wave_frequency := 1.5
var vertical_speed := 180.0
var time := 0.0
var is_dead = false  # Flag para controlar se o inimigo já morreu
var is_shooting = false  # Flag para controlar animação de tiro

# Estados do inimigo
enum EnemyState {
	DESCENDING,    # Descendo pelo meio
	ACTIVE         # Comportamento normal (atirar e se mover)
}
var current_state = EnemyState.DESCENDING

const SCREEN_TOP = 0
const SCREEN_BOTTOM_LIMIT = 380
const SCREEN_LEFT = 0
const SCREEN_RIGHT = 648
const MARGIN = 10

func _ready() -> void:
	add_to_group("inimigo")
	player_reff = get_tree().get_first_node_in_group('player')
	
	# Conecta o sinal de animação finalizada
	if sprite:
		sprite.animation_finished.connect(_on_animation_finished)
	
	# Posiciona no meio da tela horizontalmente e no topo
	position.x = SCREEN_RIGHT / 2
	position.y = SCREEN_TOP - 50  # Começa um pouco acima da tela
	
	# Inicia com animação de movimento
	sprite.play("moving")

func _process(delta: float) -> void:
	# Se está morto, não processa mais nada
	if is_dead:
		return
	
	match current_state:
		EnemyState.DESCENDING:
			_handle_descent(delta)
		EnemyState.ACTIVE:
			_handle_active_behavior(delta)

func _handle_descent(delta: float) -> void:
	# Desce pelo meio da tela
	position.y += initial_descent_speed * delta
	
	# Verifica se chegou na posição alvo
	if position.y >= descent_target_y:
		current_state = EnemyState.ACTIVE
		time = 0.0  # Reseta o tempo para o comportamento ativo
		print("Inimigo ativo - começando a atirar e se mover")

func _handle_active_behavior(delta: float) -> void:
	time += delta
	
	# Movimento dinâmico com curva senoidal + y aleatório
	var target_y = sin(time * wave_frequency) * wave_amplitude
	position.y += vertical_speed * delta * sign(target_y)
	
	# Movimento em X (avanço suave com oscilação para simular evasão)
	position.x += cos(time * wave_frequency * 0.8) * speed * delta * 0.5
	
	# Evita sair da tela, mas agora limitado à metade superior
	position.y = clamp(position.y, SCREEN_TOP + MARGIN, SCREEN_BOTTOM_LIMIT - MARGIN)
	position.x = clamp(position.x, SCREEN_LEFT + MARGIN, SCREEN_RIGHT - MARGIN)
	
	# Desvio básico de tiros (foge horizontalmente se algum tiro estiver perto)
	var lasers = get_tree().get_nodes_in_group("laser")
	for laser in lasers:
		if global_position.distance_to(laser.global_position) < 100:
			position.x += randf_range(-1, 1) * 80 * delta  # movimento evasivo rápido
	
	# Disparo - só atira quando está no estado ativo
	if player_reff and not is_shooting:
		tempo_para_atirar -= delta
		if tempo_para_atirar <= 0:
			atirar()
			tempo_para_atirar = fire_rate

func atirar():
	if is_dead:
		return
		
	is_shooting = true
	sprite.play("shoot")
	
	var bullet = bullets_scene.instantiate()
	bullet.position = global_position + shoot_offset
	var direcao = (player_reff.global_position - global_position).normalized()
	
	if bullet.has_method("set_direcao"):
		bullet.set_direcao(direcao)
	
	get_parent().add_child(bullet)
	
	# Usa um Timer ao invés de await para não bloquear
	get_tree().create_timer(0.2).timeout.connect(_on_shoot_timer_timeout)

func _on_shoot_timer_timeout():
	if not is_dead and sprite:
		is_shooting = false
		sprite.play("moving")

func _on_area_entered(area: Area2D) -> void:
	if is_dead:
		return
		
	if area.is_in_group("laser"):
		tomar_dano()
		area.queue_free()

func _on_body_entered(body) -> void:
	if is_dead:
		return
		
	if body.is_in_group("player"):
		body.remover_hp()
		tomar_dano()

func tomar_dano():
	if is_dead:
		return
		
	hp -= 10
	print("HP do inimigo: ", hp)  # Debug para verificar o HP
	
	if hp <= 0:
		morrer()
	else:
		sprite.play("hit")
		# Usa Timer ao invés de await
		get_tree().create_timer(0.2).timeout.connect(_on_hit_timer_timeout)

func _on_hit_timer_timeout():
	if not is_dead and sprite and not is_shooting:
		sprite.play("moving")

func morrer():
	if is_dead:  # Evita chamar morrer() múltiplas vezes
		return
	
	enemy_died.emit()
		
	print("Inimigo morrendo...")  # Debug
	is_dead = true
	set_process(false)  # Para de processar lógica
	remove_from_group("inimigo")  # Remove do grupo
	
	# Desativa colisões imediatamente
	set_collision_layer(0)
	set_collision_mask(0)
	
	if has_node("CollisionShape2D"):
		$CollisionShape2D.set_deferred("disabled", true)
	
	# Toca animação de morte
	if sprite:
		sprite.play("death")
	else:
		# Se não tem sprite, remove imediatamente
		queue_free()

func _on_animation_finished():
	# Quando a animação de morte terminar, remove o objeto
	if is_dead and sprite and sprite.animation == "death":
		queue_free()
