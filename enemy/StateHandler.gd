extends Node3D

const State = preload("res://enemy/State.gd")

signal transitioned(state_name)

@export var initial_state := NodePath()

@onready var state := get_node(initial_state)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("ajfdsakfhbasdj")
	if not state:
		print("Is Empty")
	
	#print(initial_state)
	#state = get_node(initial_state)
	print(state)
	
	await owner
	
	for child in get_children():
		child.state_machine = self
	
	state.enter()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta) -> void:
	state.update(_delta)

func _physics_process(_delta) -> void:
	state.physics_update(_delta)

func transition_function(new_state_name: String) -> void:
	print("Trying to transition")
	if not has_node(new_state_name):
		print("Trying to transition")
		return
	
	state.exit()
	state = get_node(new_state_name)
	state.enter()
	emit_signal("transitioned", state.name)
