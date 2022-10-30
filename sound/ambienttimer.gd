extends Timer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

export var minSeconds: int

export var maxSeconds: int


# Called when the node enters the scene tree for the first time.
func _ready():
	start_timer()
	
func start_timer():
	print("starting sound timer")
	start(rand_range(minSeconds, maxSeconds))


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
