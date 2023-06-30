extends MultiplayerSynchronizer

@export var jumping := false
@export var direction := Vector2()

func _ready():
	set_process(get_multiplayer_authority() == multiplayer.get_unique_id())
	
@rpc("call_local")
func jump():
	jumping = true
	
func _process(delta):
	direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if Input.is_action_just_pressed("ui_accept"):
		jump.rpc()
