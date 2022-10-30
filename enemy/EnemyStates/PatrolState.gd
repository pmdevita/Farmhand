extends "res://enemy/State.gd"

var destination = 0;
var increment_walk = 0.01;

# Called when the node enters the scene tree for the first time.
func enter():
	print("hello from patrol")
	destination = 1 + destination


# Called every frame. 'delta' is the elapsed time since the previous frame.
func update(delta):
	#use navmesh to go to a random point
	pass
