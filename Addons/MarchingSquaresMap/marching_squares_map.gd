@tool
extends EditorPlugin


func _enter_tree():
	add_custom_type("MarchingSquaresMap", "Node", preload("res://Addons/MarchingSquaresMap/marching_squares_map_node.gd"), preload("res://icon.svg"))
	


func _exit_tree():
	remove_custom_type("MarchingSquaresMap")
