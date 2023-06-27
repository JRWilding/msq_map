@tool
class_name MarchingSquaresMapNode
extends StaticBody3D

@export var image: CompressedTexture2D:
	set(new_image):
		print("setting new image")
		image = new_image
		
		if get_tree() == null:
			return
		
		rebuild()
		toPoly()
		
@export var wallHeight: float = 2:
	set(new_wallHeight):
		wallHeight = new_wallHeight
		
		if get_tree() == null:
			return
		
		toPoly()

var cells: Array[Cell] = []
var shapes: Array[Shape] = []
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

const tl = Vector2(0, 0)
const tr = Vector2(1, 0)
const br = Vector2(1, 1)
const bl = Vector2(0, 1)
const t = Vector2(0.5, 0.0)
const r = Vector2(1.0, 0.5)
const b = Vector2(0.5, 1.0)
const l = Vector2(0.0, 0.5)

const center = Vector2(0.5,0.5)

func getChildrenOfType(type):
	var out = []
	for c in get_children():
		if is_instance_of(c, type):
			out.push_back(c)
	return out
	
func getMesh():
	return getChildrenOfType(MeshInstance3D)
		
func getColPoly():
	return getChildrenOfType(CollisionPolygon3D)
	
func getColShape():
	return getChildrenOfType(CollisionShape3D)
	
func toPoly():
	
	print("  | 00 01 02 03 04 05 06 07 08")
	print("------------------------------")
	for y in range(ih):
		var row = (str(y) if y >= 10 else ("0" + str(y))) + "| "
		for x in range(iw):
			var c = cells[cell(x,y)].msq
			row += (str(c) if c >= 10 else ("0" + str(c))) + " "
		print(row)
		
	print ("=======")
	
	print("  | 00 01 02 03 04 05 06 07 08")
	print("------------------------------")
	for y in range(ih):
		var row = (str(y) if y >= 10 else ("0" + str(y))) + "| "
		for x in range(iw):
			var c = cells[cell(x,y)].shape
			row += (str(c) if c >= 10 || c < 0 else ("0" + str(c))) + " "
		print(row)
		
	var oldNodes = getMesh()
	oldNodes.append_array(getColPoly())
	oldNodes.append_array(getColShape())
	for on in oldNodes:
		remove_child(on)
		
	if image == null:
		return
		
	if shapes.is_empty():
		return
	
	var floorcol = CollisionShape3D.new()
	floorcol.name = "CollisionObject3D#Floor"
	floorcol.shape = BoxShape3D.new()
	floorcol.position = Vector3(iw/2, -0.5, ih/2)
	floorcol.shape.size = Vector3(iw, 1, ih)
	
	add_child(floorcol)
	floorcol.set_owner(get_tree().get_edited_scene_root())
	
	var floor = MeshInstance3D.new()
	floor.mesh = PlaneMesh.new()
	floor.mesh.center_offset = Vector3(iw/2, 0, ih/2)
	floor.mesh.size = Vector2(iw, ih)
	var material = floor.mesh.material
	material = material if material != null else StandardMaterial3D.new()
	material.albedo_color = Color(0, 0, 0)
	floor.mesh.material = material
	
	floor.name = "MeshInstance3D#Floor"
	add_child(floor)
	floor.set_owner(get_tree().get_edited_scene_root())
	
	var scount = 0
	for shape in shapes:
		if shape.list.size() < 1:
			continue
		var firstCell
		var debug = scount == 18
	
		for c in shape.list:
			if not c.isEdge || c.msq == 15:
				continue
			firstCell = c
			break

		if firstCell == null:
			continue
			
		var poly = CollisionPolygon3D.new()
		poly.depth = wallHeight
		
		var wall = MeshInstance3D.new()
		var ceiling = MeshInstance3D.new()
		
		var st = SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		st.set_color(Color(1, 0, 0))
		st.set_uv(Vector2(0, 0))
		
		var stc = SurfaceTool.new()
		stc.begin(Mesh.PRIMITIVE_TRIANGLES)
		stc.set_color(Color(1,1,0))
		stc.set_uv(Vector2(0,0))
		
		wall.name = "MeshInstance3D#Wall" + str(scount)
		add_child(wall)
		wall.set_owner(get_tree().get_edited_scene_root())
		
		ceiling.name = "MeshInstance3D#Ceiling" + str(scount)
		add_child(ceiling)
		ceiling.set_owner(get_tree().get_edited_scene_root())
		
		add_child(poly)
		poly.set_owner(get_tree().get_edited_scene_root())
		poly.name = "CollisionPolygon3D#" + str(scount)
		poly.rotate_x(deg_to_rad(90))
		poly.translate(Vector3(0,0,-wallHeight/2))
				
		var polyg = poly.polygon
		polyg.clear()
		
		var c = firstCell
		var count = 0
		var lastConfig: int = -1
		var prev = Vector2(-1,-1)
		var prevVec: Vector2
		
		while (count < shape.numEdges + 50):
			var line = c.lineB if c.lineB != null && c.lineB.get_point_position(0) == prev else c.lineA
			var start = line.get_point_position(0)
			var end = line.get_point_position(1)
			prev = end
			
			var collinear = false
			var vec = (end - start).normalized()
			if prevVec != null:
				collinear = prevVec.is_equal_approx(vec)
				
			prevVec = vec
						
			match c.msq:
				1:
					c = move(c, 0, 1)
				2:
					c = move(c, 1, 0)
				3:
					c = move(c, 1, 0)
				4:
					c = move(c, 0, -1)
				5:
					c = move(c, 0, 1) if line == c.lineB else move(c, 0, -1)
				6:
					c = move(c, 0, -1)
				7:
					c = move(c, 0, -1)
				8:
					c = move(c, -1, 0)
				9:
					c = move(c, 0, 1)
				10:
					c = move(c, -1, 0) if line == c.lineB else move(c, 1, 0)
				11:
					c = move(c, 1, 0)
				12:
					c = move(c, -1, 0)
				13:
					c = move(c, 0, 1)
				14:
					c = move(c, -1, 0)
			
			if not straight(c.msq, lastConfig):
				if debug:
					print("appending ", end)
				polyg.append(end)
				
				
			lastConfig = c.msq
			
			if c == firstCell:
				# close?
				break

			count += 1
			
		if polyg.size() < 1:
			continue
			
		var wh = wallHeight
		for p in range(0, polyg.size() -1):
			var s = polyg[p]
			var e = polyg[p+1]
			st.add_vertex(Vector3(s.x, 0, s.y))
			st.add_vertex(Vector3(e.x, 0, e.y))
			st.add_vertex(Vector3(s.x, wh, s.y))
			
			st.add_vertex(Vector3(e.x, wh, e.y))
			st.add_vertex(Vector3(s.x, wh, s.y))
			st.add_vertex(Vector3(e.x, 0, e.y))
			
			if debug:
				print("mesh ", s, " to ", e)
		
		# close
		var s = polyg[polyg.size() -1]
		var e = polyg[0]
		st.add_vertex(Vector3(s.x, 0, s.y))
		st.add_vertex(Vector3(e.x, 0, e.y))
		st.add_vertex(Vector3(s.x, wh, s.y))
		
		st.add_vertex(Vector3(e.x, wh, e.y))
		st.add_vertex(Vector3(s.x, wh, s.y))
		st.add_vertex(Vector3(e.x, 0, e.y))
		if debug:
			print("close ", s, " to ", e)
		
		for vert in shape.verts:
			stc.add_vertex(vert)
			if debug:
				print("ceiling: ", vert)
			
		poly.polygon = polyg
		
		wall.mesh = st.commit()
		ceiling.mesh = stc.commit()
		
		scount += 1

func straight(a: int, b: int):
	match a:
		b: return true
		1: return b == 11
		2: return b == 7
		3: return b == 12
		4: return b == 14
		6: return b == 9
		7: return b == 2
		8: return b == 13
		9: return b == 6
		11: return b == 1
		12: return b == 3
		13: return b == 8
		14: return b == 4
	
func move(c: Cell, x: int, y: int) -> Cell:
	var nx = c.x + x
	var ny = c.y + y
	if nx >= 0 && nx < iw && ny >= 0 && ny < ih:
		return cells[cell(nx,ny)]
	return c
	
func rebuild():
	print("rebuilding")
	
	cells = []
	shapes = []
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
			var isSolid = img.get_pixel(x, y).r > 0
			if isSolid:
				numSolids += 1
			cells.push_back(Cell.new(cell(x,y), x, y, isSolid))
			
	print("cells size: ", cells.size(), " solids: ", numSolids)
	
	for y in range(ih):
		for x in range(iw):
			var d = cells[cell(x,y)]
			if d.isSolid && d.shape == -1:
				var shape = shapes.size()
				shapes.push_back(Shape.new(shape))
				fill(x,y,shape)
				
	for y in range(ih):
		for x in range(iw):
			var d = cells[cell(x,y)]			
			marchingSquare(d)
			wallDistance(d)
			

func marchingSquare(c: Cell):
	var config = 0
	for corner in range(4):
		var p = msNeighbour[corner]
		var nx = c.x + p.x
		var ny = c.y + p.y
		if (nx <= 0 || ny <= 0 || nx >= iw || ny >= ih):
			config += msConfig[corner]
			continue
			
		var d2 = cells[cell(nx,ny)]
		config += msConfig[corner] if d2.isSolid else 0
		
	c.msq = config
	
	if c.shape != -1:
		print(c.shape, " marching ", c.msq, " at ", c.x, ",", c.y)
		
	match c.msq:
		1:
			addToMesh(c, [add(c,l), add(c,b), add(c,bl)])
			c.lineA = Line2D.new()
			c.lineA.add_point(add(c,l))
			c.lineA.add_point(add(c,b))
		2:
			addToMesh(c, [add(c,br), add(c,b), add(c,r)])
			c.lineA = Line2D.new()
			c.lineA.add_point(add(c,b))
			c.lineA.add_point(add(c,r))
		4:
			addToMesh(c, [add(c,tr), add(c,r), add(c,t)])
			c.lineA = Line2D.new()
			c.lineA.add_point(add(c,r))
			c.lineA.add_point(add(c,t))
		8:
			addToMesh(c, [add(c,tl), add(c,t), add(c,l)])
			c.lineA = Line2D.new()
			c.lineA.add_point(add(c,t))
			c.lineA.add_point(add(c,l))

		3:
			addToMesh(c, [add(c,r), add(c,br), add(c,bl), add(c,l)])
			c.lineA = Line2D.new()
			c.lineA.add_point(add(c,l))
			c.lineA.add_point(add(c,r))
			
		6:
			addToMesh(c, [add(c,t), add(c,tr), add(c,br), add(c,b)])
			c.lineA = Line2D.new()
			c.lineA.add_point(add(c,b))
			c.lineA.add_point(add(c,t))
			
		9:
			addToMesh(c, [add(c,tl), add(c,t), add(c,b), add(c,bl)])
			c.lineA = Line2D.new()
			c.lineA.add_point(add(c,t))
			c.lineA.add_point(add(c,b))

		12:
			addToMesh(c, [add(c,tl), add(c,tr), add(c,r), add(c,l)])
			c.lineA = Line2D.new()
			c.lineA.add_point(add(c,r))
			c.lineA.add_point(add(c,l))

		5:
			addToMesh(c, [add(c,t), add(c,tr), add(c,r), add(c,b), add(c,bl), add(c,l)])
			c.lineA = Line2D.new()
			c.lineA.add_point(add(c,l))
			c.lineA.add_point(add(c,t))
			c.lineB = Line2D.new()
			c.lineB.add_point(add(c,r))
			c.lineB.add_point(add(c,b))

		10:
			addToMesh(c, [add(c, tl), add(c, t), add(c, r), add(c, br), add(c, b), add(c, l)])
			c.lineA = Line2D.new()
			c.lineA.add_point(add(c,t))
			c.lineA.add_point(add(c,r))
			c.lineB = Line2D.new()
			c.lineB.add_point(add(c,b))
			c.lineB.add_point(add(c,l))


		7:
			addToMesh(c, [add(c,t), add(c,tr), add(c,br), add(c,bl), add(c,l)])
			c.lineA = Line2D.new()
			c.lineA.add_point(add(c,l))
			c.lineA.add_point(add(c,t))

		11:
			addToMesh(c, [add(c,tl), add(c,t), add(c,r), add(c,br), add(c,bl)])
			c.lineA = Line2D.new()
			c.lineA.add_point(add(c,t))
			c.lineA.add_point(add(c,r))

		13:
			addToMesh(c, [add(c,tl), add(c,tr), add(c,r), add(c,b), add(c,bl)])
			c.lineA = Line2D.new()
			c.lineA.add_point(add(c,r))
			c.lineA.add_point(add(c,b))

		14:
			addToMesh(c, [add(c,tl), add(c,tr), add(c,br), add(c,b), add(c,l)])
			c.lineA = Line2D.new()
			c.lineA.add_point(add(c,b))
			c.lineA.add_point(add(c,l))


		15:
			var size = 1
			var done = true
			while not done && c.x + size + 1 < iw && c.y + size + 1 < ih:
				for x in range(c.x, c.x + size + 2):
					var d = cells[cell(x, c.y + size)]
					if d.msq != 15 || d.shape != c.shape || d.meshed:
						done = true
						break
				for y in range(c.y, c.y + size + 2):
					var d = cells[cell(c.x + size, y)]
					if d.msq != 15 || d.shape != c.shape || d.meshed:
						done = true
						break
				size += 1
			
			var tr2 = add(c,tr,size-1)
			var br2 = add(c,br,size-1,size-1)
			var bl2 = add(c,bl,0,size-1)
			
			addToMesh(c, [add(c,tl),tr2,br2,bl2])
			
			for y in range(c.y, c.y + size):
				for x in range(c.x, c.x + size):
					var d = cells[cell(x,y)]
					#d.meshed = true

func addToMesh2(c: Cell, p0: Vector2, p1: Vector2, p2: Vector2):
	if c.shape == -1:
		return
	var s = shapes[c.shape]
	
	s.verts.push_back(Vector3(p0.x, wallHeight, p0.y))
	s.verts.push_back(Vector3(p1.x, wallHeight, p1.y))
	s.verts.push_back(Vector3(p2.x, wallHeight, p2.y))
	
	var indices = s.indices
	indices.push_back(indices.size())
	indices.push_back(indices.size())
	indices.push_back(indices.size())
	
	for i in range(6):
		s.uvs.push_back(0)
  
func addToMesh(c: Cell, p: Array):
	if c.meshed || c.shape == -1:
		return
	#c.meshed = true
		
	print(c.shape, " adding ", c.msq, " to ", c.x, ",", c.y, " = ", p)
	if (p.size() >= 3):
		addToMesh2(c, p[0], p[1], p[2])
	
	if (p.size() >= 4):
		addToMesh2(c, p[0], p[2], p[3])
	
	if (p.size() >= 5):
		addToMesh2(c, p[0], p[3], p[4])
	
	if (p.size() >= 6):
		addToMesh2(c, p[0], p[4], p[5])
	
func add(c: Cell, p: Vector2, x: int = 0, y: int = 0):
	return c.p + p + Vector2(x,y)

func wallDistance(_c: Cell):
	return 1
	
func fill(sx: int, sy: int, shape: int):
	var neighs = []
	var startCell = cells[cell(sx,sy)]
	neighs.push_back(startCell)
	
	while not neighs.is_empty():
		var c = neighs.pop_front()
		var x = c.x
		var y = c.y
		
		shapes[shape].bounds.expand(Vector3(x,0,y))
		shapes[shape].list.push_back(c)
		
		for y2 in range(-1, 2):
			for x2 in range(-1, 2):
				if x == 0 && y == 0:
					continue
				var nx = x + x2
				var ny = y + y2
				if nx < 0 || ny < 0 || nx >= iw || ny >= ih:
					continue
					
				var d = cells[cell(nx,ny)]
				if d.shape != -1:
					continue
					
				if d.msq != 0:
					d.shape = shape
					
				if not d.isSolid:
					d.isEdge = true
					c.isEdge = true
					shapes[shape].numEdges += 1
					continue
				neighs.push_back(d)
	
func cell(x: int, y: int):
	assert(x >= 0 && x < iw)
	assert(y >= 0 && y < ih)
	return y * iw + x
