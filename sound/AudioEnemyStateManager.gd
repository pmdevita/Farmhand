extends Spatial

const State = preload("res://sound/AudioState.gd")

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

export var initial_state = NodePath()
onready var state: State = get_node(initial_state)


var alert_enemies: Array = []
var attack_enemies: Array = []

# Called when the node enters the scene tree for the first time.
func _ready():
	for child in get_children():
		child.state_machine = self
		
	state.enter()
	
func change_state(new_state: State):
	if state == new_state:
		return
	state.exit()
	state = new_state
	state.enter()

func is_playing():
	return state.is_playing()
	
func calculate_state():
	if attack_enemies.size() > 0:
		change_state($AttackState)
	elif alert_enemies.size() > 0:
		change_state($AlertState)
	else:
		change_state($Normal)

func enemy_alert(node: Node):
	alert_enemies.append(node)
	attack_enemies.erase(node)
	
func enemy_attack(node: Node):
	attack_enemies.append(node)
	alert_enemies.erase(node)
	
func enemy_normal(node: Node):
	alert_enemies.erase(node)
	attack_enemies.erase(node)
	
	




# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
