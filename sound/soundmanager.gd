extends Spatial

export var GuitarMusic: NodePath
export var GuitarTimerPath: NodePath
onready var GuitarTimer = get_node(GuitarTimerPath)

# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func play_ambience():
	print("starting ambience playback")
	var music: Array = $GuitarMusic.get_children()
	var songIndex = rand_range(0, music.size())
	var song = $GuitarMusic.get_child(songIndex)
	if not song.is_connected("finished", GuitarTimer, "start_timer"):
		print("not connected yet")
		song.connect("finished", GuitarTimer, "start_timer")
	song.play()
	
