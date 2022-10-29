extends RigidBody3D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _physics_process(delta):
	var velocity = Vector3()
	if Input.is_action_pressed("Forward"):
		velocity.z = -0.1
	if Input.is_action_pressed("Backward"):
		velocity.z = 0.1
	if Input.is_action_pressed("Left"):
		velocity.x = -0.1
	if Input.is_action_pressed("Right"):
		velocity.x = 0.1
		
	add_constant_force(velocity)
	
