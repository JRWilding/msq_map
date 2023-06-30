@tool
extends EditorPlugin


func _enter_tree():
	add_custom_type("MarchingSquaresMap", "Node3D", preload("res://addons/msq_map/map_node.gd"), preload("res://icon.svg"))
	add_custom_type("MarchingSquaresGenerator", "Node", preload("res://addons/msq_map/make_meshes.gd"), preload("res://icon.svg"))
	


func _exit_tree():
	remove_custom_type("MarchingSquaresMap")
	remove_custom_type("MarchingSquaresGenerator")
