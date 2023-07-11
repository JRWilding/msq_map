extends Node3D

const spawn_random = 5.0

func _ready():
	if not multiplayer.is_server():
		return
		
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(del_player)
	
	for id in multiplayer.get_peers():
		add_player(id)
		
	if not OS.has_feature("dedicated_server"):
		add_player(1)

func _exit_tree():
	if not multiplayer.is_server():
		return
		
	multiplayer.peer_connected.disconnect(add_player)
	multiplayer.peer_disconnected.disconnect(del_player)
	
func add_player(id: int):
	var player = preload("res://addons/msq_map/example/player.tscn").instantiate()
	player.player = id
	#var pos := Vector2.from_angle(randf() * 2 * PI)
	var spawn = $SpawnPoint
	player.position = spawn.position#Vector3(pos.x * spawn_random * randf(), 1, pos.y * spawn_random * randf())
	player.name = str(id)
	$Players.add_child(player, true)
	
func del_player(id: int):
	if not $Players.has_node(str(id)):
		return
	$Players.get_node(str(id)).queue_free()
