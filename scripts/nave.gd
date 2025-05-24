extends CharacterBody2D

@export var speed = 300
@export var laser = preload("res://scenes/laser.tscn")
@export var fire_rate = 0.3

var can_shoot = true
var can_take_damage = true
var hp = 100
@onready var sprite: AnimatedSprite2D = $Sprite

func _ready() -> void:
	add_to_group("player")

const SCREEN_WIDTH = 648
const SCREEN_HEIGHT = 1152
const MARGIN = 50

func _process(_delta: float) -> void:
	$Label.text = str(hp)

	if Input.is_action_pressed("right"):
		velocity.x = speed
	elif Input.is_action_pressed("left"):
		velocity.x = -speed
	else:
		velocity.x = 0

	if Input.is_action_pressed("up"):
		velocity.y = -speed
	elif Input.is_action_pressed("down"):
		velocity.y = speed
	else:
		velocity.y = 0

	move_and_slide()

	# Restringe a nave dentro dos limites
	position.x = clamp(position.x, MARGIN, SCREEN_WIDTH - MARGIN)
	position.y = clamp(position.y, MARGIN, SCREEN_HEIGHT - MARGIN)

	if Input.is_action_pressed("tiro") and can_shoot:
		tiro()

	$Label.text = str(hp)

	# Movimento horizontal
	if Input.is_action_pressed("right"):
		velocity.x = speed
	elif Input.is_action_pressed("left"):
		velocity.x = -speed
	else:
		velocity.x = 0

	# Movimento vertical
	if Input.is_action_pressed("up"):
		velocity.y = -speed
	elif Input.is_action_pressed("down"):
		velocity.y = speed
	else:
		velocity.y = 0

	move_and_slide()

	# Disparo
	if Input.is_action_pressed("tiro") and can_shoot:
		tiro()

# Função de disparo
func tiro():
	can_shoot = false
	var lazer = laser.instantiate()
	lazer.position = global_position + Vector2(0, -10)
	get_parent().add_child(lazer)

	await get_tree().create_timer(fire_rate).timeout
	can_shoot = true

# Remover vida ao tomar dano
func remover_hp():
	if can_take_damage:
		hp -= 10
		take_damage()

	if hp <= 0:
		morrer()

# Aplicar dano com animação de hit
func take_damage():
	can_take_damage = false
	animate()
	await get_tree().create_timer(1.0).timeout
	can_take_damage = true

# Tocar animação de hit
func animate():
	sprite.play("hit")

# Morrer com animação e ir para tela de Game Over
func morrer():
	sprite.play("death")
	await sprite.animation_finished
	queue_free()
