class_name Cell
extends Object

var id: int
var x : int
var y : int
var c: int
var p: Vector2
var isSolid: bool
var shape: int = -1
var isEdge: bool
var msq: int
var meshed: int
var wallDistance: int

var lineA: Line2D
var lineB: Line2D

func _init(
	id: int = 0,
	x: int = 0,
	y: int = 0, 
	isSolid: bool = false
):
	self.id = id
	self.x = x
	self.y = y
	self.isSolid = isSolid
	self.p = Vector2(x,y)
	self.wallDistance = 0 if isSolid else -1
	self.shape = -1
