extends "res://enemy/State.gd"

var target_point := Node

# Called when the node enters the scene tree for the first time.
func enter():
	print("hello from patrol")
	
	#for i in targets_array.size():
	#	print(targets_array[i])


# Called every frame. 'delta' is the elapsed time since the previous frame.
func update(delta):
	#use navmesh to go to a random point
	 
	pass
