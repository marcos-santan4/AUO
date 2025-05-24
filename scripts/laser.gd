extends Area2D

@export var speed = 5

func _ready() -> void:
	add_to_group("laser")

func _process(delta: float) -> void:
	speed += delta * 2
	position.y -= speed
