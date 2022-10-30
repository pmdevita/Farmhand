class_name EnemyState
extends "res://State.gd"

var enemy: Enemy

# Called when the node enters the scene tree for the first time.
func _ready():
	await enemy
	enemy = owner as Enemy
	assert(enemy != null)
