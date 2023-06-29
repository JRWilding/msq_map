@tool
extends EditorPlugin


func _enter_tree():
	add_custom_type("MarchingSquaresMap", "Node", preload("res://Addons/MarchingSquaresMap/map_node.gd"), preload("res://icon.svg"))
	add_custom_type("MarchingSquaresGenerator", "Node", preload("res://Addons/MarchingSquaresMap/make_meshes.gd"), preload("res://icon.svg"))
	


func _exit_tree():
	remove_custom_type("MarchingSquaresMap")
	remove_custom_type("MarchingSquaresGenerator")
