@tool
class_name MarchingSquaresMapNode
extends Node3D

const P1Utils = preload("res://Addons/MarchingSquaresMap/p1_utils.gd")
const Generator = preload("res://Addons/MarchingSquaresMap/make_meshes.gd")


@export var reinit: int:
	set(newReinit):
		reinit = newReinit
		rebuild()
		toPoly()
		
@export var image: CompressedTexture2D:
	set(newImage):
		image = newImage
		rebuild()
		toPoly()

@export var mapScale: float = 1:
	set(newMapScale):
		mapScale = newMapScale
		toPoly()
		
@export var wallHeight: float = 2:
	set(newWallHeight):
		wallHeight = newWallHeight
		toPoly()

@export var chunkSize: float = 16:
	set(newChunkSize):
		chunkSize = newChunkSize
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
	
func getGeneratedMeshes() -> Array:
	return P1Utils.getChildrenOfType(self, MeshInstance3D)

func getGeneratedNav() -> Array:
	return P1Utils.getChildrenOfType(self, NavigationRegion3D)
			
func copyToTool(tool: SurfaceTool, verts: Array, offset: Vector3, sc: Vector3):
	for v in verts:
		tool.add_vertex((v + offset) * sc)
	
func addToWorld(parent: Node, tool: SurfaceTool, nodeName: String, color: Color) -> MeshInstance3D:
	var meshNode = MeshInstance3D.new()
	P1Utils.addEditorChild(parent, meshNode, nodeName)
	tool.index()
	tool.generate_normals()
	meshNode.mesh = tool.commit()
	meshNode.material_overlay = StandardMaterial3D.new()
	meshNode.material_overlay.albedo_color = color
	meshNode.create_trimesh_collision()
	return meshNode

func populateGridMap():
	var grid: GridMap = get_node("GridMap")
	
	if grid.mesh_library == null:
		grid.mesh_library = load("res://Addons/MarchingSquaresMap/meshlib.tres")
		
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
	
	if not Engine.is_editor_hint() || get_tree() == null:
		return
	var oldNodes = P1Utils.getChildrenOfType(self, Node3D)
	oldNodes.append_array(getGeneratedNav())
	for on in oldNodes:
		remove_child(on)
		
	if image == null:
		return
	
	#populateGridMap()
	
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
		meshes.push_back(Generator.generateVerts(i))
	
	var region = NavigationRegion3D.new()
	P1Utils.addEditorChild(self, region, "NavigationRegion3D")
	var chunks = Node3D.new()
	P1Utils.addEditorChild(self, chunks, "Chunks")
	
	var chunk = 0
	for sy in range(0, ih, chunkSize):
		for sx in range(0, iw, chunkSize):
			
			var floorTool = P1Utils.makeTool(Color.DARK_GRAY)
			var wallTool = P1Utils.makeTool(Color.DARK_SLATE_GRAY)
			var ceilingTool = P1Utils.makeTool(Color.DIM_GRAY)
	
			for y in range(sy, sy + chunkSize):
				for x in range(sx, sx + chunkSize):
					
					if (x >= iw || y >= ih):
						continue
						
					var c = cellMSq[cell(x,y)]
					var offset = Vector3(x, 0, y)
					var cellMesh = meshes[c]
					copyToTool(floorTool, cellMesh[0], offset, vMapScaleWithHeight)
					copyToTool(wallTool, cellMesh[1], offset, vMapScaleWithHeight)
					copyToTool(ceilingTool, cellMesh[2], offset, vMapScaleWithHeight)
			
			print("chunk ", chunk)
			var c = str(chunk)
			chunk += 1
			addToWorld(chunks, ceilingTool, "Ceiling" + c, Color.DARK_GRAY)
			addToWorld(chunks, wallTool, "Wall" + c, Color.DARK_SLATE_GRAY)
			var floorNode = addToWorld(chunks, floorTool, "Floor" + c, Color.DIM_GRAY)
			floorNode.add_to_group("msq_nav_floor")
			
	var floorNav = NavigationMesh.new()
	floorNav.agent_radius = 0.5
	floorNav.agent_max_climb = 0.2
	floorNav.cell_size = 0.05
	floorNav.cell_height = 0.1
	floorNav.geometry_source_group_name = "msq_nav_floor"
	floorNav.geometry_source_geometry_mode = NavigationMesh.SOURCE_GEOMETRY_GROUPS_EXPLICIT
	
	region.navigation_mesh = floorNav
	
	region.bake_navigation_mesh(true)
			
func rebuild():
	
	if not Engine.is_editor_hint() || get_tree() == null:
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
