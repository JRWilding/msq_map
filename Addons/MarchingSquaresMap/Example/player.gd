extends CharacterBody3D

const speed = 5
const jump_pow = 4.5

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@export var player := 1:
	set(id):
		player = id
		$PlayerInput.set_multiplayer_authority(id)
		
@export var exp_velocity := Vector3(0,0,0):
	set(v):
		if velocity != v:
			velocity = v
		exp_velocity = v

@onready var input = $PlayerInput

func _ready():
	if player == multiplayer.get_unique_id():
		$Camera3D.current = true
		
func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta
		
	if input.jumping and is_on_floor():
		velocity.y = jump_pow
		
	input.jumping = false
	
	var direction = (transform.basis * Vector3(input.direction.x, 0, input.direction.y)).normalized()
	
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
	
	#exp_velocity = velocity
	move_and_slide()
	
