extends Node

const PORT = 4433

func _ready():
	multiplayer.server_relay = false
	
	print("ready")
	if DisplayServer.get_name() == "headless":
		_on_host_pressed.call_deferred()
		
func _on_host_pressed():
	print("hosting")
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(PORT)
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		OS.alert("failed")
		return
	multiplayer.multiplayer_peer = peer
	start_game()
	
func _on_connect_pressed():
	var txt: String = $UI/Net/Options/Remote.text
	if txt == "":
		OS.alert("enter ip:port")
		return
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(txt, PORT)
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		OS.alert("failed")
		return
	multiplayer.multiplayer_peer = peer
	start_game()

func start_game():
	$UI.hide()
	
	if multiplayer.is_server():
		change_level.call_deferred(load("res://addons/msq_map/example/level.tscn"))
		
func change_level(scene: PackedScene):
	var level = $World
	for c in level.get_children():
		level.remove_child(c)
		c.queue_free()
		
	level.add_child(scene.instantiate())

func _input(event):
	if not multiplayer.is_server():
		return
	if event.is_action("ui_home") and Input.is_action_just_pressed("ui_home"):
		change_level.call_deferred(load("res://addons/msq_map/example/level.tscn"))
