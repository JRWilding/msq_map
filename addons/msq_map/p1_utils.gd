@tool
class_name P1Utils
extends Object

static func addEditorChild(parent: Node, node: Node, name: String):
	node.name = name
	parent.add_child(node)
	node.set_owner(parent.get_tree().get_edited_scene_root())

static func makeTool(color: Color = Color.WHITE) -> SurfaceTool:
	var tool = SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	tool.set_color(color)
	tool.set_uv(Vector2(0,0))

	return tool

static func getChildrenOfType(parent: Node, type) -> Array:
	var out = []
	for c in parent.get_children():
		if is_instance_of(c, type):
			out.push_back(c)
	return out
