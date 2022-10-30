extends "res://enemy/State.gd"

@export var patrol_timer = 3;

var destination = 0;
var increment_walk = 0.01;

# Called when the node enters the scene tree for the first time.
func enter():
	print("hello")
	destination = 1 + destination
	
	if owner.position.x >= 1 || owner.position.x <= -1:
		increment_walk = -increment_walk


# Called every frame. 'delta' is the elapsed time since the previous frame.
func update(delta):
	#use navmesh to go to a random point
	owner.position.x += increment_walk
	
	if owner.position.x >= destination || owner.position.x <= -destination:
		state_machine.transition_function("IdleState")
