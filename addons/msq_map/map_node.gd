@tool
class_name MarchingSquaresMapNode
extends Node3D

@export var reinit: int = 0:
	set(value):
		reinit = value
		rebuild()
		toPoly()
		
@export var image: CompressedTexture2D:
	set(value):
		image = value
		rebuild()
		toPoly()

@export var mapScale := 1.0:
	set(value):
		mapScale = value
		toPoly()
		
@export var wallHeight := 2.0:
	set(value):
		wallHeight = value
		toPoly()

@export var chunkSize := 16.0:
	set(value):
		chunkSize = value
		toPoly()

@export var useGridMap := false:
	set(value):
		useGridMap = value
		toPoly()

@export var floorMaterial: Material:
	set(value):
		floorMaterial = value
		toPoly()
		
@export var wallMaterial: Material:
	set(value):
		wallMaterial = value
		toPoly()
		
@export var ceilingMaterial: Material:
	set(value):
		ceilingMaterial = value
		toPoly()
		
@export var wallPlaneSubdivision := 8:
	set(value):
		wallPlaneSubdivision = value
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
				
func copyToTool(tool: SurfaceTool, genMesh: Array, offset: Vector3, sc: Vector3) -> bool:
	if genMesh[0].is_empty():
		return false
		
	if genMesh[0].size() != genMesh[1].size():
		return false
			
	var verts = genMesh[0]
	var tVerts = []
	var uvs = genMesh[1]
	var tUvs = []
	var edges = genMesh[2] if genMesh.size() > 2 else null
	var map = Vector2(iw / chunkSize, ih / chunkSize) * Vector2(sc.x, sc.z)

	var isWall = false
	var isFloor = false
	if verts.size() >= 3:
		var v1 = verts[0]
		var v2 = verts[1]
		var v3 = verts[2]
		var y = v1.y + v2.y + v3.y
		isWall = y > 0 && y < 3
		isFloor = y == 0
		
	for i in range(verts.size()):
		var v2 = (verts[i] + offset) * sc
		tVerts.push_back(v2)
		if isWall:
			tUvs.push_back(uvs[i])
		else:
			tUvs.push_back(Vector2(v2.x, v2.z) / map)

	MarchingSquaresGenerator.writeToToolUV(tVerts, tUvs, edges, tool)
	
	return true
	
func addMeshToWorld(parent: Node, colLayer: int, mesh: Mesh, nodeName: String, mat: Material) -> MeshInstance3D:
	var meshNode = MeshInstance3D.new()
	P1Utils.addEditorChild(parent, meshNode, nodeName)
	meshNode.mesh = mesh
	meshNode.material_override = mat
	meshNode.create_trimesh_collision()
	var col: StaticBody3D = meshNode.get_child(0)
	col.collision_layer = colLayer
	return meshNode
	
	
func addToolToWorld(parent: Node, colLayer: int, tool: SurfaceTool, nodeName: String, mat: Material) -> MeshInstance3D:
	MarchingSquaresGenerator.finishTool(tool)
	var mesh = tool.commit()
	return addMeshToWorld(parent, colLayer, mesh, nodeName, mat)

func populateGridMap():
	var grid: GridMap = GridMap.new()
	P1Utils.addEditorChild(self, grid, "GridMap")
		
	grid.mesh_library = load("res://addons/msq_map/meshlib.tres")
		
	grid.cell_center_x = false
	grid.cell_center_y = false
	grid.cell_center_z = false
	
	grid.bake_navigation = true
	grid.cell_size = Vector3(mapScale,1,mapScale)
	grid.cell_scale = mapScale
	grid.scale = Vector3(1,wallHeight,1)
	
	grid.rotation = Vector3(0,deg_to_rad(-90),0)

	for y in range(ih):
		for x in range(iw):
			grid.set_cell_item(Vector3(x,0,y), cellMSq[cell(x,y)], 0)
				
func toPoly():
	
	if not Engine.is_editor_hint() || not is_inside_tree():
		return
		
	
	var oldNodes = [
		get_node("Chunks") if has_node("Chunks") else null,
		get_node("NavigationRegion3D") if has_node("NavigationRegion3D") else null,
		get_node("GridMap") if has_node("GridMap") else null,
	]
	for on in oldNodes:
		if on != null:
			remove_child(on)
		
	if image == null:
		return
	
	if useGridMap:
		populateGridMap()
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
			
	var meshes = []
	for i in range(16):
		meshes.push_back(MarchingSquaresGenerator.generateVerts(i))
	
	var navRegion = NavigationRegion3D.new()
	P1Utils.addEditorChild(self, navRegion, "NavigationRegion3D")
	var chunks = Node3D.new()
	P1Utils.addEditorChild(self, chunks, "Chunks")
	
	var cache = []
	cache.resize(16)
	var chunk = 0
	for sy in range(0, ih, chunkSize):
		for sx in range(0, iw, chunkSize):
			
			var chunkNode = Node3D.new()
			var chunkNum = str(chunk)
			chunk += 1
			P1Utils.addEditorChild(chunks, chunkNode, "Chunk" + chunkNum)
			var hasFloor = false
			var floorTool = P1Utils.makeTool(Color.DARK_GRAY)
			var hasWall = false
			var wallTool = P1Utils.makeTool(Color.DARK_SLATE_GRAY)
			var wallPlanes = [] # [[tl, br],[uv-tl, uv-br]]
			var hasCeiling = false
			var ceilingTool = P1Utils.makeTool(Color.DIM_GRAY)
	
			for y in range(sy, sy + chunkSize):
				for x in range(sx, sx + chunkSize):
					
					if (x >= iw || y >= ih):
						continue
						
					var c = cellMSq[cell(x,y)]
					var offset = Vector3(x, 0, y)
					var cellMesh = meshes[c]
					hasFloor = copyToTool(floorTool, cellMesh[0], offset, vMapScaleWithHeight) || hasFloor
					
					if cache[c] == null:
						cache[c] = MarchingSquaresGenerator.wallPlane(cellMesh[3][0], wallPlaneSubdivision)
					var wallPlane = cache[c]
					if wallPlane.is_empty():
						hasWall = copyToTool(wallTool, cellMesh[1], offset, vMapScaleWithHeight) || hasWall
						#wallPlanes.push_back([
						#	[cellMesh[1][0][0], cellMesh[1][0][cellMesh[1][0].size() - 1]],
						#[cellMesh[1][1][0], cellMesh[1][1][cellMesh[1][1].size() - 1]]
						#])
						#hasWall = true
					else:
						hasWall = copyToTool(wallTool, wallPlane, offset, vMapScaleWithHeight) || hasWall
					
					hasCeiling = copyToTool(ceilingTool, cellMesh[2], offset, vMapScaleWithHeight) || hasCeiling
			
			if hasCeiling:
				addToolToWorld(chunkNode, 3, ceilingTool, "Ceiling" + chunkNum, ceilingMaterial)
			if hasWall:
				if not wallPlanes.is_empty():
					for w in wallPlanes:
						var sp = PlaneMesh.new()
						var s = (w[0][1] - w[0][0]) / 2
						sp.center_offset = Vector3(0,1,0)#w[0][0] + (s)
						sp.size = Vector2(s.x, s.z)
						sp.orientation = PlaneMesh.FACE_Z
						sp.subdivide_width = 16
						sp.subdivide_depth = 16
						addMeshToWorld(chunkNode, 2, wallPlanes, "Wall" + chunkNum, wallMaterial)
				else:
					addToolToWorld(chunkNode, 2, wallTool, "Wall" + chunkNum, wallMaterial)
			if hasFloor:
				var floorNode = addToolToWorld(chunkNode, 1, floorTool, "Floor" + chunkNum, floorMaterial)
				floorNode.add_to_group("msq_map_nav_floor")
			
	var floorNav = NavigationMesh.new()
	floorNav.agent_radius = 0.5
	floorNav.agent_max_climb = 0.2
	floorNav.cell_size = 0.05
	floorNav.cell_height = 0.1
	floorNav.geometry_source_group_name = "msq_map_nav_floor"
	floorNav.geometry_source_geometry_mode = NavigationMesh.SOURCE_GEOMETRY_GROUPS_EXPLICIT
	
	navRegion.navigation_mesh = floorNav
	
	navRegion.bake_navigation_mesh(true)
	
	var offset = Vector3(-iw, 0, -ih) * vMapScaleWithHeight * 0.5
	navRegion.translate(offset)
	chunks.translate(offset)
			
func rebuild():
	
	if not Engine.is_editor_hint() || not is_inside_tree():
		return
		
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
