@tool
class_name MarchingSquaresMapNode
extends Node

const P1Utils = preload("res://Addons/MarchingSquaresMap/p1_utils.gd")
const Generator = preload("res://Addons/MarchingSquaresMap/make_meshes.gd")


@export var instance: int:
	set(newInstance):
		instance = newInstance
		if get_tree() == null:
			return
		rebuild()
		toPoly()
		
@export var image: CompressedTexture2D:
	set(new_image):
		print("setting new image")
		image = new_image
		
		if get_tree() == null:
			return
		
		rebuild()
		toPoly()

@export var mapScale: float = 1:
	set(newMapScale):
		mapScale = newMapScale
		
		if get_tree() == null:
			return
			
		toPoly()
		
@export var wallHeight: float = 2:
	set(new_wallHeight):
		wallHeight = new_wallHeight
		
		if get_tree() == null:
			return
		
		toPoly()

var cellIsSolid: Array[int] = []
var cellMSq: Array[int] = []
var iw: int
var ih: int


const msNeighbour = [
	Vector2(0,0),
	Vector2(1,0),
	Vector2(1,1),
	Vector2(0,1)
]

const msConfig = [
	8, 4, 2, 1
]
	
func getGeneratedMeshes():
	return P1Utils.getChildrenOfType(self, MeshInstance3D)
			
func copyToTool(tool: SurfaceTool, verts: Array, offset: Vector3, scale: Vector3):
	for v in verts:
		tool.add_vertex((v + offset) * scale)
			
func toPoly():
	
	var oldNodes = getGeneratedMeshes()
	for on in oldNodes:
		remove_child(on)
		
	if image == null:
		return
	
	if false:
		print("  | 00 01 02 03 04 05 06 07 08")
		print("------------------------------")
		for y in range(ih):
			var row = (str(y) if y >= 10 else ("0" + str(y))) + "| "
			for x in range(iw):
				var c = cellMSq[cell(x,y)]
				row += (str(c) if c >= 10 else ("0" + str(c))) + " "
			print(row)
			
		print ("=======")
		
	var vMapScaleWithHeight = Vector3(mapScale,wallHeight,mapScale)
			
	var floorTool = P1Utils.makeTool()
	var wallTool = P1Utils.makeTool()
	var ceilingTool = P1Utils.makeTool()
	
	var meshes = []
	for i in range(16):
		meshes.push_back(Generator.generateMesh(i))
	
	for y in range(ih):
		for x in range(iw):
			var c = cellMSq[cell(x,y)]
			var offset = Vector3(x, 0, y)
			var cellMesh = meshes[c]
			copyToTool(floorTool, cellMesh[0], offset, vMapScaleWithHeight)
			copyToTool(wallTool, cellMesh[1], offset, vMapScaleWithHeight)
			copyToTool(ceilingTool, cellMesh[2], offset, vMapScaleWithHeight)
			
	var ceiling = MeshInstance3D.new()
	P1Utils.addEditorChild(self, ceiling, "Ceiling")
	ceiling.mesh = ceilingTool.commit()
	ceiling.create_trimesh_collision()
	
	var wall = MeshInstance3D.new()
	P1Utils.addEditorChild(self, wall, "Wall")
	wall.mesh = wallTool.commit()
	wall.create_trimesh_collision()
	
	var floor = MeshInstance3D.new()
	P1Utils.addEditorChild(self, floor, "Floor")
	floor.mesh = floorTool.commit()
	floor.create_trimesh_collision()
	
func rebuild():
	print("rebuilding")
	
	cellIsSolid = []
	cellMSq = []
	iw = 0
	ih = 0
	
	if image == null:
		return
			
	iw = image.get_width()
	ih = image.get_height()
	var img = image.get_image()
	var numSolids = 0
	
	for y in range(ih):
		for x in range(iw):
			var isSolid = 1 if img.get_pixel(x, y).r > 0 else 0
			numSolids += isSolid
			cellIsSolid.push_back(isSolid)
			
	print("cells size: ", cellIsSolid.size(), " solids: ", numSolids)
		
	for y in range(ih):
		for x in range(iw):
			marchingSquare(x, y)
			
func marchingSquare(x, y):
	var config = 0
	for corner in range(4):
		var p = msNeighbour[corner]
		var nx = x + p.x
		var ny = y + p.y
		if (nx <= 0 || ny <= 0 || nx >= iw || ny >= ih):
			config += msConfig[corner]
			continue
			
		var d2 = cellIsSolid[cell(nx,ny)]
		config += msConfig[corner] if d2 == 1 else 0
		
	cellMSq.push_back(config)

func cell(x: int, y: int):
	assert(x >= 0 && x < iw)
	assert(y >= 0 && y < ih)
	return y * iw + x
