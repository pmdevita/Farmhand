extends "res://enemy/State.gd"

@export var idle_timer = 4;

@onready var timer:Timer = $IdleTimer

# Called when the node enters the scene tree for the first time.
func enter() -> void:
	print("Hello from the IdleState")
	
	owner.velocity = Vector3(0, 0, 0)
	timer.start(idle_timer)
	# play some animation or something

# Called every frame. 'delta' is the elapsed time since the previous frame.
func update(_delta):
		
	if timer.is_stopped():
		#transition to patrol state
		print("Timer is up, now Patrol")
		state_machine.transition_function("PatrolState")

func exit() -> void:
	pass
