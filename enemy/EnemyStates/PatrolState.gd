extends "res://enemy/State.gd"

export var target_1 := NodePath()
export var target_2 := NodePath()

onready var next_target := get_node(target_2)

# Called when the node enters the scene tree for the first time.
func enter():
	print("hello from patrol")
	
	print(target_1, target_2)
	
	if next_target.name == "Pos-2":
		next_target = get_node(target_1)
	else:
		next_target = get_node(target_2)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func update(delta):
	#use navmesh to go to a random point
	print(next_target.get_global_transform().get_translation())
	pass
