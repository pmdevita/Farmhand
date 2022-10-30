# Virtual base class for all states to derive from
extends Node

var state_machine = null

# Will be called when new state is entered
func enter() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func update(_delta) -> void:
	pass

# not sure the difference between update and physics update
func physics_update(_delta) -> void:
	pass

# Will be called when previous state is left, but before running the new state's enter()
func exit() -> void:
	pass
