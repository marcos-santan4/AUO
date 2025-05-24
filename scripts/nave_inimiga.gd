extends Area2D

@export var speed = 250
@export var fire_rate = 0.4
@export var bullets_scene = preload("res://scenes/laser_inimigo.tscn")
@export var shoot_offset = Vector2(-10, 5)
@onready var sprite: AnimatedSprite2D = $Sprite

var hp = 150
var tempo_para_atirar = 0.0
var player_reff = null
var direction_y = 1
var direction_x = -1
var wave_amplitude := 5
var wave_frequency := 1.5
var vertical_speed := 180.0
var time := 0.0

const SCREEN_TOP = 0
const SCREEN_BOTTOM = 1152
const SCREEN_LEFT = 0
const SCREEN_RIGHT = 648
const MARGIN = 32

func _ready() -> void:
	add_to_group("inimigo")
	player_reff = get_tree().get_first_node_in_group('player')


func _process(delta: float) -> void:
	time += delta

	# Movimento dinâmico com curva senoidal + y aleatório
	var target_y = sin(time * wave_frequency) * wave_amplitude
	position.y += vertical_speed * delta * sign(target_y)

	# Movimento em X (avanço suave com oscilação para simular evasão)
	position.x += cos(time * wave_frequency * 0.8) * speed * delta * 0.5

	# Evita sair da tela
	position.y = clamp(position.y, SCREEN_TOP + MARGIN, SCREEN_BOTTOM - MARGIN)
	position.x = clamp(position.x, SCREEN_LEFT + MARGIN, SCREEN_RIGHT - MARGIN)

	# Desvio básico de tiros (foge horizontalmente se algum tiro estiver perto)
	var lasers = get_tree().get_nodes_in_group("laser")
	for laser in lasers:
		if global_position.distance_to(laser.global_position) < 100:
			position.x += randf_range(-1, 1) * 80 * delta  # movimento evasivo rápido

	# Disparo
	if player_reff:
		tempo_para_atirar -= delta
		if tempo_para_atirar <= 0:
			atirar()
			tempo_para_atirar = fire_rate


func atirar():
	sprite.play("shoot")
	
	var bullet = bullets_scene.instantiate()
	bullet.position = global_position + shoot_offset
	
	var direcao = (player_reff.global_position - global_position).normalized()
	if bullet.has_method("set_direcao"):
		bullet.set_direcao(direcao)
	get_parent().add_child(bullet)
	
	await get_tree().create_timer(0.2).timeout
	sprite.play("moving")

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("laser"):
		tomar_dano()
		area.queue_free()
		
func _on_body_entered(body) -> void:
	if body.is_in_group("player"):
		body.remover_hp()
		tomar_dano()

func tomar_dano():
	hp -= 10
	if hp == 0:
		morrer()
	else:
		sprite.play("hit")
		await get_tree().create_timer(0.2).timeout
	
func morrer():
	sprite.play("death")
	await sprite.animation_finished
	queue_free()
