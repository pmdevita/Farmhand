extends KinematicBody
# TODO: VISUAL/AUDIO cue for stamina? Make jump affect stamina?
#		- Specifically, STAMINA DELAY: disable or keep at 1?
#		  Player won't understand when they run out that it needs
#		  to recharge to a minimum value.
#		- Jump affecting stamina NOT implemented, if implemented
#		  it will need to be set in player settings.
# TODO: Fix StaminaBar scaling on fullscreen (currently using
#		ProjectSettings: Mode "2D" for Scale)
# TODO: Speed adjustments and any smoothing/bugfixes with sprint/sneak speeds
# TODO: Adjust camera FOV/allow player to with a slider? Same w sensitivity?
# TODO: Basic inventory system with mousewheel (pickup, equip); just shown in
#		player's first-person POV, nothing special. Maybe bobs with camera.
# TODO: Item use animations/abilities (attack, use, individual item scripts)
#		- Also add physical item pickups to player? Shown in camera FOV, animated
#		  identical to camera rotation with camera bob?
# TODO: Player Health/Death on enemy collision/attack
# TODO: Post Processing? Even just bare minimum?
# OPTIONAL: Camera bob animations (if added, affects currently held item as well)
# OPTIONAL: Footstep sounds (walk/run/sneak/land from midair? only difference is speed
#		of sounds played)
# OPTIONAL: Breathing sound effects (could serve as a caue to player when running out of
#		stamina or after a jump instead/in conjunction w/ stamina bar?)
# Anything else? Bugtesting/level playtesting. Add features as necessary

# Scrapped:


# Reference to player camera object used for rotations/Mouselook
onready var camera:Camera = $PlayerCamera
# How sensitive the first person camera is for Mouselook
export var mouseSensitivity = 0.5
# How high and low the player is able to look
export var lookLimitUp = 1
export var lookLimitDown = -1
# Is the mouse focused (only move camera when game is focused)
var mouseFocused = true

# Used for random footsteps
var rand = 1

# Audio Files for Footsteps
var fs1
var fs2
var fs3
var fs4
var fs5
var fs6
var footstep1 = "res://Player/SFX/grasssteps.11.ogg"
var footstep2 = "res://Player/SFX/grasssteps.13.ogg"
var footstep3 = "res://Player/SFX/grasssteps.15.ogg"
var footstep4 = "res://Player/SFX/grasssteps.17.ogg"
var footstep5 = "res://Player/SFX/grasssteps.19.ogg"
var footstep6 = "res://Player/SFX/grasssteps.21.ogg"

# Player's sneak speed (m/s)
export var sneakSpeed = 7.0
# Player's walk speed (m/s)
export var walkSpeed = 14.0
# Player's sprint speed (m/s)
export var sprintSpeed = 28.0
# Determines how fast the player can move between sprint/walk/sneak
export var changeStateSpeed = 0.01
# Holds the current player speed.
var currentSpeed = walkSpeed

# Reference to player stamina bar
onready var staminaBar:ProgressBar = $PlayerUI/StaminaBar

# Values FOV changes to based on sneak/sprint/normal
export var normalFOV = 70.0
export var sneakFOV = 50.0
export var sprintFOV = 90.0
export var fovChangeRate = 1.0

# If the player runs out of stamina, recharge to this level before sprinting again
export var staminaDelay = 30.0
var ranOutOfSprint = false
# Rate at which stamina is recovered while standing still
export var recoverStaminaIdle = 3.0
# Rate at which stamina is recovered while sneaking
export var recoverStaminaSneaking = 2.0
# Rate at which stamina is recovered while walking
export var recoverStaminaWalking = 1.5
# Rate at which stamina is lost while sprinting
export var loseStaminaSprint = 4.0
# How much stamina is lost from a jump
# export var loseStaminaJump = 25.0 <-- Not implemented; unnecessary?

# Player's remaining stamina
var stamina = 100.0
# Booleans for checking sneak/sprint/walk state; can only perform one at a time,
# sprinting midair allowed, sneaking only allowed if on ground
var sneaking = false
var sprinting = false
var moving = false

var stopFootSteps = true

# Used to determine if we started the jump delay timer or not.
var jumpTimerStarted = false

# Enables/disables player sneak/sprint
export var canSneak = true
export var canSprint = true

# Used to allow player to even jump at all, or when delaying jumps
export var canJump = true
# Whether or not the player can mini-jump while sneaking
export var canSneakJump = true
# Whether or not the player can spam-jump
export var canBunnyhop = false
# How long in seconds the player must wait before jumping
export var jumpDelay = 1.5;
# Reference to timer for jump-delays
onready var timer:Timer = $JumpTimer

# Reference to timer for footstep sounds
onready var footstepTimer:Timer = $FootstepTimer

# How high the player jumps normally
export var normalJumpStrength = 20
# How high the player jumps while sneaking
export var sneakJumpStrength = 10
# Player's falling speed (m/s)
export var playerGravity = 75
# Player's Y velocity (for jumping/falling)
var playerVelocityY = 0

# Stores player velocity to use on next take
var previousYVelocity

# Runs on script initial launch
func _ready():
	# Lock mouse cursor on start
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Get reference to jump delay timer
	timer = get_node("JumpTimer")
	
	# Initialize camera FOV
	camera.fov = normalFOV
	
	# Load footstep sounds
	fs1 = load(footstep1)
	fs2 = load(footstep2)
	fs3 = load(footstep3)
	fs4 = load(footstep4)
	fs5 = load(footstep5)
	fs6 = load(footstep6)
	fs1.set_loop(false)
	fs2.set_loop(false)
	fs3.set_loop(false)
	fs4.set_loop(false)
	fs5.set_loop(false)
	fs6.set_loop(false)
	randomize()

# Updates player physics movement every frame using kinematic body
func _physics_process(delta):
	# Player input will be stored in groundVelocity; starts at idle
	var groundVelocity = Vector3.ZERO

	# Store the jump strength to use depending on sneaking or normally-moving
	var jumpStrength
	
	# Collect player movement input
	groundVelocity = Input.get_vector("Left", "Right", "Forward", "Backward")
	# print(groundVelocity)
	
	# Player has regained enough stamina and may sprint again
	if (stamina > staminaDelay):
		ranOutOfSprint = false
	
	# Decide whether to begin or stop sprinting if player provides input
	if (Input.is_action_pressed("Sprint") and canSprint and !ranOutOfSprint):
		if (!sneaking):
			if (stamina > 0):
				sprinting = true
			else:
				ranOutOfSprint = true
				sprinting = false
	else:
		sprinting = false
	
	# Decide whether to toggle sneaking on/off if player provides input
	if (Input.is_action_just_pressed("Sneak") and canSneak):
		if (sneaking):
			sneaking = false
			if (canJump):
				canJump = false
				jumpTimerStarted = true
				timer.start(jumpDelay)
		else:
			sprinting = false
			sneaking = true
	
	# Adjust player speed to match the current state their character is in.
	if (sprinting):
		currentSpeed = lerp(currentSpeed, sprintSpeed, changeStateSpeed)
	elif (sneaking):
		currentSpeed = lerp(currentSpeed, sneakSpeed, changeStateSpeed)
	else:
		currentSpeed = lerp(currentSpeed, walkSpeed, changeStateSpeed)
	
	# Normalize velocity in case multiple keys pressed, apply movement speed
	groundVelocity = groundVelocity.normalized() * currentSpeed
	
	# Update player velocity on ground based on current direction
	var velocity = groundVelocity.x * global_transform.basis.x + groundVelocity.y * global_transform.basis.z
	
	# Decide whether to apply gravity or a jump to player
	if is_on_floor():
		playerVelocityY = 0
		if Input.is_action_pressed("Jump"):
			if (sneaking and canSneakJump):
				jumpStrength = sneakJumpStrength
			else:
				jumpStrength = normalJumpStrength
			
			# Allow the player to jump if the delay has ended.
			if (timer.is_stopped() and jumpTimerStarted):
				jumpTimerStarted = false
				canJump = true
			
			# If the player can't bunnyhop, set a timer until they can jump again
			if (!canBunnyhop and canJump):
				if (sneaking and !canSneakJump):
					pass
				else:
					# Apply the jump force
					playerVelocityY += jumpStrength
					# Start the delay timer before jumping again
					canJump = false
					timer.start(jumpDelay)
					jumpTimerStarted = true
			elif (canBunnyhop and canJump):
				if (sneaking and !canSneakJump):
					pass
				else:
					# Apply the jump force
					playerVelocityY += jumpStrength
	else:
		playerVelocityY -= playerGravity * delta
	
	# Update player's Y velocity
	velocity.y = playerVelocityY
	
	if ((Input.is_action_pressed("Forward")) or (Input.is_action_pressed("Backward")) or (Input.is_action_pressed("Left")) or (Input.is_action_pressed("Right"))):
		moving = true
	else:
		moving = false
	
	previousYVelocity = velocity.y
	
	# Call the function to actually move the player
	move_and_slide(velocity, Vector3.UP)

	# Lock mouse cursor if user clicks on screen
	if Input.is_action_just_pressed("mouse 1"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		mouseFocused = true
	
	# Unlock cursor if user presses escape
	if Input.is_action_just_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		mouseFocused = false
	
# Handles camera movement/rotation input on cursor move
func _input(event):
	# If the mouse moved; get how much it has moved since the prev. frame
	# x is how much it's moved left/right, y is forward/backward
	if (event is InputEventMouseMotion):
		if (mouseFocused):
			# Moving the mouse left or right rotates the player AND camera on y-axis
			rotate_y(-event.relative.x * mouseSensitivity)
			# Moving the mouse forward or back rotates ONLY the camera up/down
			camera.rotate_x(-event.relative.y * mouseSensitivity)
			
			# Clamp camera's rotation when looking up/down; min and max use PI
			camera.rotation.x = clamp(camera.rotation.x, lookLimitDown, lookLimitUp)

func _process(delta):
	# Lose stamina if sprinting, else recover amount based on movement state
	# Set stamina manually to 0 or 100 if it exceeds these values
	
	# Switch sound effect
	rand = randi() % 6 + 1
	
	if (footstepTimer.is_stopped()):
		if (rand == 1):
			$AudioStreamPlayer3D.stream = fs1
		elif (rand == 2):
			$AudioStreamPlayer3D.stream = fs2
		elif (rand == 3):
			$AudioStreamPlayer3D.stream = fs3
		elif (rand == 4):
			$AudioStreamPlayer3D.stream = fs4
		elif (rand == 5):
			$AudioStreamPlayer3D.stream = fs5
		else:
			$AudioStreamPlayer3D.stream = fs6
	
	if (sprinting and moving):
		stopFootSteps = false
		camera.fov = lerp(camera.fov, sprintFOV, fovChangeRate)
		if footstepTimer.time_left <= 0:
			
			$AudioStreamPlayer3D.pitch_scale = rand_range(0.8, 1.2)
			$AudioStreamPlayer3D.play()
			footstepTimer.start(0.2 * (sprintSpeed / 15))
			
		if (stamina > 0):
			stamina -= loseStaminaSprint
		else:
			stamina = 0
	elif (sneaking):
		stopFootSteps = false
		camera.fov = lerp(camera.fov, sneakFOV, fovChangeRate)
		if footstepTimer.time_left <= 0:
			$AudioStreamPlayer3D.pitch_scale = rand_range(0.8, 1.2)
			$AudioStreamPlayer3D.play()
			footstepTimer.start(0.75 * (sneakSpeed / 15))
		if (stamina < 100):
			stamina += recoverStaminaSneaking
		else:
			stamina = 100
	elif (moving):
		stopFootSteps = false
		camera.fov = lerp(camera.fov, normalFOV, fovChangeRate)
		if footstepTimer.time_left <= 0:
			$AudioStreamPlayer3D.pitch_scale = rand_range(0.8, 1.2)
			$AudioStreamPlayer3D.play()
			footstepTimer.start(0.5 * (walkSpeed / 20))
		if (stamina < 100):
			stamina += recoverStaminaWalking
		else:
			stamina = 100
	else:
		footstepTimer.stop()
		stopFootSteps = true
		camera.fov = lerp(camera.fov, normalFOV, fovChangeRate)
		if (stamina < 100):
			stamina += recoverStaminaIdle
		else:
			stamina = 100
	
	# Update stamina bar value
	staminaBar.value = stamina
	
	if (footstepTimer.is_stopped() and stopFootSteps):
		$AudioStreamPlayer3D.stop()
	
	# DEBUG; remove onec stamina bar/visual or audio cue implemented.
	#print("Moving? ", moving)
