extends Area2D


# Called when the node enters the scene tree for the first time.
func _ready():
	$AnimatedSprite2D.play("fly")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	position.x -= get_parent().speed / 2
