extends Area2D

var direcao = Vector2.ZERO
@export var speed = 300

func _process(delta: float) -> void:
	position += direcao * speed * delta

func set_direcao(dir: Vector2):
	direcao = dir

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.remover_hp()
		queue_free()
