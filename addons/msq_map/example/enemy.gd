class_name Enemy
extends RigidBody3D

@export var speed: float = 4.0
@onready var navAgent: NavigationAgent3D = get_node("NavigationAgent3D")

func _ready():
	navAgent.velocity_computed.connect(Callable(_on_velocity_computed))
	
	var target = get_node("Target")
	if target != null:
		call_deferred("setMoveTarget", target.position)
		
func setMoveTarget(target: Vector3):
	navAgent.set_target_position(target)
	
func _physics_process(_delta):
	if navAgent == null || navAgent.is_navigation_finished():
		return
		
	var nextPathPos: Vector3 = navAgent.get_next_path_position()
	var curAgentPos: Vector3 = position
	var newVel: Vector3 = (nextPathPos - curAgentPos).normalized() * speed
	
	if navAgent.avoidance_enabled:
		navAgent.set_velocity(newVel)
	else:
		_on_velocity_computed(newVel)
		
func _on_velocity_computed(vel: Vector3):
	linear_velocity = vel
	
