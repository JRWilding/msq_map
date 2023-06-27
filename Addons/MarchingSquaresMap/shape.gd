class_name Shape
extends Object

var id: int
var bounds: AABB
var list: Array[Cell] = []
var numEdges: int = 0
var verts: Array[Vector3] = []
var uvs = []
var indices = []

func _init(id: int):
	self.id = id
