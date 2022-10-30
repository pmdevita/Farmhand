extends KinematicBody
# TODO: Sneak adjusts camera and player collider height
# TODO: Stamina BAR or VISUAL/AUDIO cue? Make jump affect stamina?
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

# Reference to player camera object used for rotations/Mouselook
onready var camera:Camera = $PlayerCamera
# How sensitive the first person camera is for Mouselook
export var mouseSensitivity = 0.5
# How high and low the player is able to look
export var lookLimitUp = 1
export var lookLimitDown = -1

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
# @export var loseStaminaJump = 25.0 <-- Not implemented; unnecessary?

# Player's remaining stamina
var stamina = 100.0
# Booleans for checking sneak/sprint/walk state; can only perform one at a time,
# sprinting midair allowed, sneaking only allowed if on ground
var sneaking = false
var sprinting = false
var moving = false

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

# How high the player jumps normally
export var normalJumpStrength = 20
# How high the player jumps while sneaking
export var sneakJumpStrength = 10
# Player's falling speed (m/s)
export var playerGravity = 75
# Player's Y velocity (for jumping/falling)
var playerVelocityY = 0

# Runs on script initial launch
func _ready():
	# Lock mouse cursor on start
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Get reference to jump delay timer
	timer = get_node("JumpTimer")

# Updates player physics movement every frame using kinematic body
func _physics_process(delta):
	# Player input will be stored in groundVelocity; starts at idle
	var groundVelocity = Vector3.ZERO
	
	# Store the player speed we will lerp to, for speed smoothing between states
	var newSpeed
	# Store the jump strength to use depending on sneaking or normally-moving
	var jumpStrength
	
	# Collect player movement input
	groundVelocity = Input.get_vector("Left", "Right", "Forward", "Backward")
	
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
		if (is_on_floor()):
			if (sneaking):
				sneaking = false
				if (canJump):
					canJump = false
					jumpTimerStarted = true
					timer.start(jumpDelay)
			else:
				sprinting = false
				sneaking = true
		else:
			if (sneaking):
				sneaking = false
				if (canJump):
					canJump = false
					jumpTimerStarted = true
					timer.start(jumpDelay)
	
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
	
	# If the velocity is not zero, we know the player is moving.
	if (velocity != Vector3.ZERO):
		moving = true
	else:
		moving = false
	
	# Call the function to actually move the player
	move_and_slide(velocity)

	# Lock mouse cursor if user clicks on screen
	if Input.is_action_just_pressed("mouse 1"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Unlock cursor if user presses escape
	if Input.is_action_just_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
# Handles camera movement/rotation input on cursor move
func _input(event):
	# If the mouse moved; get how much it has moved since the prev. frame
	# x is how much it's moved left/right, y is forward/backward
	if (event is InputEventMouseMotion):
		# Moving the mouse left or right rotates the player AND camera on y-axis
		rotate_y(-event.relative.x * mouseSensitivity)
		# Moving the mouse forward or back rotates ONLY the camera up/down
		camera.rotate_x(-event.relative.y * mouseSensitivity)
		
		# Clamp camera's rotation when looking up/down; min and max use PI
		camera.rotation.x = clamp(camera.rotation.x, lookLimitDown, lookLimitUp)

func _process(delta):
	# Lose stamina if sprinting, else recover amount based on movement state
	# Set stamina manually to 0 or 100 if it exceeds these values
	if (sprinting and moving):
		if (stamina > 0):
			stamina -= loseStaminaSprint
		else:
			stamina = 0
	elif (sneaking):
		if (stamina < 100):
			stamina += recoverStaminaSneaking
		else:
			stamina = 100
	elif (moving):
		if (stamina < 100):
			stamina += recoverStaminaWalking
		else:
			stamina = 100
	else:
		if (stamina < 100):
			stamina += recoverStaminaIdle
		else:
			stamina = 100
	
	# DEBUG; remove onec stamina bar/visual or audio cue implemented.
	print("Stamina: ", stamina)
