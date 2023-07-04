@tool
class_name MarchingSquaresGenerator extends Node

@export var instance := 0:
	set(value):
		if get_tree() == null:
			return
		instance = value
		generateAll()

@export var material : Material:
	set(value):
		material = value
		generateAll()
		
const dtl = Vector3(0, 0, 0)
const dtr = Vector3(1, 0, 0)
const dbr = Vector3(1, 0, 1)
const dbl = Vector3(0, 0, 1)
const dt = Vector3(0.5, 0, 0.0)
const dr = Vector3(1.0, 0, 0.5)
const db = Vector3(0.5, 0, 1.0)
const dl = Vector3(0.0, 0, 0.5)
const dc = Vector3(0.5, 0, 0.5)

const utl = Vector3(0, 1, 0)
const utr = Vector3(1, 1, 0)
const ubr = Vector3(1, 1, 1)
const ubl = Vector3(0, 1, 1)
const ut = Vector3(0.5, 1, 0.0)
const ur = Vector3(1.0, 1, 0.5)
const ub = Vector3(0.5, 1, 1.0)
const ul = Vector3(0.0, 1, 0.5)
const uc = Vector3(0.5, 1, 0.5)

const uvtl = Vector2(0, 0)
const uvtr = Vector2(1, 0)
const uvbr = Vector2(1, 1)
const uvbl = Vector2(0, 1)
const uvt = Vector2(0.5, 0.0)
const uvr = Vector2(1.0, 0.5)
const uvb = Vector2(0.5, 1.0)
const uvl = Vector2(0.0, 0.5)

const e = Color.WHITE

const w = Color.BLACK
const wc = 0.9
const qwc = 0.1#1 - sqrt(pow(wc /2.0, 2) + pow(wc /2.0, 2))
const qw = Color(qwc, qwc, qwc, 1)
const hwc = 0.1#1 - (wc /2.0)
const hw = Color(hwc, hwc, hwc, 1)
const hywc = 0#1 - sqrt(pow(wc,2) + pow(wc/2, 2))
const hyw = Color(hywc, hywc, hywc, 1)

static func writeToTool(arr: Array, tool: SurfaceTool):
	for v in arr:
		tool.set_uv(Vector2(v.x, v.z))
		tool.add_vertex(v)

static func writeToToolUV(verts: Array, uvs: Array, cols: Array, tool: SurfaceTool):
	var i = 0
	for v in verts:
		tool.set_uv(uvs[i])
		tool.set_color(cols[i])
		i += 1
		tool.add_vertex(v)
			
static func finishTool(tool: SurfaceTool):	
	tool.index()
	tool.generate_normals()
	tool.generate_tangents()
	
# returns an Array[ArrayArray[] for 1 cell with the given marching square config
# Arrays are the triangles for floor, wall, ceiling, in order
# (the outer array will be size=3)
# mid array is mesh, uvs, edges, in order
# (the middle array will be size=3)
# inner array is the data (either vec3 for verts or vec2 for uvs)
static func generateVerts(config: int) -> Array[Array]:
	var fl = [[],[],[]]
	var wa = [[],[],[]]
	var ce = [[],[],[]]
		
	var verts: Array[Vector3]
	var uvs: Array[Vector2]
	var cols: Array[Color]
	match config:
		0:
			verts = [
				dtl, dtr, dbr, 
				dbr, dbl, dtl
			]
			uvs = [
				uvtl, uvtr, uvbr, 
				uvbr, uvbl, uvtl
			]
			cols = [
				w, w, w,
				w, w, w
			]
		1:
			verts = [
				dtl, dtr, dl,
				dl, dtr, db,
				db, dtr, dbr,
				db, ub, ul,
				ul, dl, db,
				ul, ub, ubl
			]
			uvs = [
				uvtl, uvtr, uvl,
				uvl, uvtr, uvb,
				uvb, uvtr, uvbr,
				uvbl, uvtl, uvtr,
				uvtr, uvbr, uvbl,
				uvl, uvb, uvbl
			]
			cols = [
				w, w, e,
				e, w, e,
				e, w, w,
				e, e, e,
				e, e, e,
				e, e, hw
			]
		2:
			verts = [
				dbl, dtl, db,
				db, dtl, dr,
				dr, dtl, dtr,
				dr, ur, ub,
				ub, db, dr,
				ub, ur, ubr
			]
			uvs = [
				uvbl, uvtl, uvb,
				uvb, uvtl, uvr,
				uvr, uvtl, uvtr,
				uvbl, uvtl, uvtr,
				uvtr, uvbr, uvbl,
				uvb, uvr, uvbr
			]
			cols = [
				w, w, e,
				e, w, e,
				e, w, w,
				e, e, e,
				e, e, e,
				e, e, hw
			]
		3:
			verts = [
				dtl, dtr, dl,
				dl, dtr, dr,
				dr, ur, ul,
				ul, dl, dr,
				ubl, ul, ub,
				ul, ur, ub,
				ur, ubr, ub
			]
			uvs = [
				uvtl, uvtr, uvl,
				uvl, uvtr, uvr,
				uvbl, uvtl, uvtr,
				uvtr, uvbr, uvbl,
				uvbl, uvl, uvb,
				uvl, uvr, uvb,
				uvr, uvbr, uvb
			]
			cols = [
				w, w, e,
				e, w, e,
				e, e, e,
				e, e, e,
				hw, e, qw,
				e, e, qw,
				e, hw, qw
			]
		4:
			verts = [
				dtl, dt, dbl,
				dbl, dt, dr,
				dr, dbr, dbl,
				dt, ut, ur,
				ur, dr, dt,
				ut, utr, ur
			]
			uvs = [
				uvtl, uvt, uvbl,
				uvbl, uvt, uvr,
				uvr, uvbr, uvbl,
				uvbl, uvtl, uvtr,
				uvtr, uvbr, uvbl,
				uvt, uvtr, uvr
			]
			cols = [
				w, e, w,
				w, e, e,
				e, w, w,
				e, e, e,
				e, e, e,
				e, hw, e,
			]
		5:
			verts = [
				dtl, dt, dl,
				dt, ut, ul,
				ul, dl, dt,
				
				ut, utr, ubl,
				ut, ubl, ul,
				utr, ub, ubl,
				utr, ur, ub,
				
				ub, ur, dr,
				dr, db, ub,
				dr, dbr, db
			]
			uvs = [
				uvtl, uvt, uvl,
				uvbl, uvtl, uvtr,
				uvtr, uvbr, uvbl,
				
				uvt, uvtr, uvbl,
				uvt, uvbl, uvl,
				uvtr, uvb, uvbl,
				uvtr, uvr, uvb,
				
				uvtl, uvtr, uvbr,
				uvbr, uvbl, uvtl,
				uvr, uvbr, uvb
			]
			cols = [
				w, e, e,
				e, e, e,
				e, e, e,
				
				e, qw, hyw,
				e, hyw, e,
				hyw, e, qw, 
				qw, e, e,
				
				e, e, e,
				e, e, e, 
				e, w, e
			]
		6:
			verts = [
				dtl, dt, dbl,
				dbl, dt, db,
				db, dt, ut,
				ut, ub, db,
				ut, utr, ur,
				ut, ur, ub,
				ur, ubr, ub,
			]
			uvs = [
				uvtl, uvt, uvbl,
				uvbl, uvt, uvb,
				uvbr, uvbl, uvtl,
				uvtl, uvtr, uvbr,
				uvt, uvtr, uvr,
				uvt, uvr, uvb,
				uvr, uvbr, uvb,
			]
			cols = [
				w, e, w,
				w, e, e,
				e, e, e,
				e, e, e,
				e, hw, qw,
				e, qw, e,
				qw, hw, e				
			]
		7:
			verts = [
				dtl, dt, dl,
				dl, dt, ut,
				ut, ul, dl,
				ut, utr, ubr,
				ubr, ul, ut,
				ubr, ubl, ul
			]
			uvs = [
				uvtl, uvt, uvl,
				uvbr, uvbl, uvtl,
				uvtl, uvtr, uvbr,
				uvt, uvtr, uvbr,
				uvbr, uvl, uvt,
				uvbr, uvbl, uvl
			]
			cols = [
				w, e, e,
				e, e, e,
				e, e, e,
				e, qw, hyw,
				hyw, e, e,
				hyw, qw, e
			]
		8:
			verts = [
				dt, dtr, dbr,
				dbr, dl, dt,
				dbr, dbl, dl,
				dl, ul, ut,
				ut, dt, dl,
				utl, ut, ul
			]
			uvs = [
				uvt, uvtr, uvbr,
				uvbr, uvl, uvt,
				uvbr, uvbl, uvl,
				uvbl, uvtl, uvtr,
				uvtr, uvbr, uvbl,
				uvtl, uvt, uvl
			]
			cols = [
				e, w, w,
				w, e, e,
				w, w, e,
				e, e, e,
				e, e, e,
				hw, e, e
			]
		9:
			verts = [
				utl, ut, ul,
				ut, ub, ul,
				ubl, ul, ub,
				ut, dt, db,
				db, ub, ut,
				dt, dtr, dbr,
				dbr, db, dt
			]
			uvs = [
				uvtl, uvt, uvl,
				uvt, uvb, uvl,
				uvbl, uvl, uvb,
				uvtr, uvbr, uvbl,
				uvbl, uvtl, uvtr,
				uvt, uvtr, uvbr,
				uvbr, uvb, uvt
			]
			cols = [
				hw, e, qw,
				e, e, qw,
				hw, qw, e,
				e, e, e,
				e, e, e,
				e, w, w, 
				w, e, e
			]
		10:
			verts = [
				utl, ut, ubr,
				ut, ur, ubr,
				ubr, ub, utl,
				ub, ul, utl,
				ul, ub, db,
				db, dl, ul,
				dl, db, dbl,
				dt, dtr, dr,
				dr, ur, ut,
				ut, dt, dr
			]
			uvs = [
				uvtl, uvt, uvbr,
				uvt, uvr, uvbr,
				uvbr, uvb, uvtl,
				uvb, uvl, uvtl,
				uvtl, uvtr, uvbr,
				uvbr, uvbl, uvtl,
				uvl, uvb, uvbl,
				uvt, uvtr, uvr,
				uvbl, uvtl, uvtr,
				uvtr, uvbr, uvbl
			]
			cols = [
				qw, e, hyw, 
				e, e, qw, 
				qw, e, hyw,
				e, e, hyw, 
				e, e, e, 
				e, e, e,
				e, e, w,
				e, w, e,
				e, e, e,
				e, e, e
			]
		11:
			verts = [
				utl, ut, ubl,
				ubl, ut, ur,
				ur, ubr, ubl,
				ur, ut, dt,
				dt, dr, ur,
				dt, dtr, dr
			]
			uvs = [
				uvtl, uvt, uvbl,
				uvbl, uvt, uvr,
				uvr, uvbr, uvbl,
				uvtl, uvtr, uvbr,
				uvbr, uvbl, uvtl,
				uvt, uvtr, uvr
			]
			cols = [
				qw, e, hyw,
				hyw, e, e,
				e, qw, hyw, 
				e, e, e, 
				e, e, e, 
				e, w, e
			]
		12:
			verts = [
				utl, ut, ul,
				ut, ur, ul,
				ut, utr, ur,
				ur, dr, dl,
				dl, ul, ur,
				dbl, dl, dr,
				dr, dbr, dbl
			]
			uvs = [
				uvtl, uvt, uvl,
				uvt, uvr, uvl,
				uvt, uvtr, uvr,
				uvtr, uvbr, uvbl,
				uvbl, uvtl, uvtr,
				uvbl, uvl, uvr,
				uvr, uvbr, uvbl
			]
			cols = [
				hw, qw, e,
				qw, e, e,
				qw, hw, e,				
				w, w, w,
				w, w, w,
				w, e, e,
				e, w, w
			]
		13:
			verts = [
				utl, utr, ur,
				ur, ub, utl,
				utl, ub, ubl,
				ub, ur, dr,
				dr, db, ub,
				db, dr, dbr
			]
			uvs = [
				uvtl, uvtr, uvr,
				uvr, uvb, uvtl,
				uvtl, uvb, uvbl,
				uvtl, uvtr, uvbr,
				uvbr, uvbl, uvtl,
				uvb, uvr, uvbr
			]
			cols = [
				hyw, hw, e,
				e, e, hyw, 
				hyw, e, hw,
				e, e, e, 
				e, e, e, 
				e, e, qw 
			]
		14:
			verts = [
				utl, utr, ul,
				ul, utr, ub,
				ub, utr, ubr,
				ul, ub, db,
				db, dl, ul,
				dl, db, dbl
			]
			uvs = [
				uvtl, uvtr, uvl,
				uvl, uvtr, uvb,
				uvb, uvtr, uvbr,
				uvtl, uvtr, uvbr,
				uvbr, uvbl, uvtl,
				uvl, uvb, uvbl
			]
			cols = [
				hw, hyw, e, 
				e, hyw, e, 
				e, hyw, hw, 
				w, w, w, 
				w, w, w, 
				e, e, w
			]
		15:
			verts = [
				utl, utr, ubl,
				ubl, utr, ubr
			]
			uvs = [
				uvtl, uvtr, uvbl,
				uvbl, uvtr, uvbr
			]
			cols = [
				w, w, w,
				w, w, w
			]
	
	for i in range(0, verts.size(), 3):
		var v1 = verts[i]
		var v2 = verts[i+1]
		var v3 = verts[i+2]
		var uv1 = uvs[i]
		var uv2 = uvs[i+1]
		var uv3 = uvs[i+2]
		var col1 = cols[i]
		var col2 = cols[i+1]
		var col3 = cols[i+2]
		
		var y = v1.y + v2.y + v3.y
		var arr = fl if y == 0 else ce if y == 3 else wa

		arr[0].push_back(v2)
		arr[0].push_back(v3)
		arr[0].push_back(v1)
		arr[1].push_back(uv2)
		arr[1].push_back(uv3)
		arr[1].push_back(uv1)
		arr[2].push_back(col2)
		arr[2].push_back(col3)
		arr[2].push_back(col1)
	
	return [fl, wa, ce]
	
func generateNode(config: int) -> MeshInstance3D:
	var n = "mesh" + str(config)
	if has_node(n):
		return setNode(get_node(n), config)
	else:
		var meshNode = MeshInstance3D.new()
		P1Utils.addEditorChild(self, meshNode, n)
		meshNode.translate(Vector3(config % 4 * 2, 0, config / 4 * 2))
		meshNode = setNode(meshNode, config)
		meshNode.create_trimesh_collision()
		return meshNode
	

func setNode(meshNode: MeshInstance3D, config: int) -> MeshInstance3D:
	var genMesh = MarchingSquaresGenerator.generateVerts(config)
	var fTool = P1Utils.makeTool()
	var wTool = P1Utils.makeTool()
	var cTool = P1Utils.makeTool()
	
	MarchingSquaresGenerator.writeToToolUV(genMesh[0][0], genMesh[0][1], genMesh[0][2], fTool)
	MarchingSquaresGenerator.writeToToolUV(genMesh[1][0], genMesh[1][1], genMesh[1][2], wTool)
	MarchingSquaresGenerator.writeToToolUV(genMesh[2][0], genMesh[2][1], genMesh[2][2], cTool)
			
	MarchingSquaresGenerator.finishTool(fTool)
	var mesh = fTool.commit()
	var navMesh = NavigationMesh.new()
	navMesh.create_from_mesh(mesh)

	var navRegion = NavigationRegion3D.new()
	navRegion.navigation_mesh = navMesh
	P1Utils.addEditorChild(meshNode, navRegion, "nav" + str(config))
	
	MarchingSquaresGenerator.finishTool(wTool)
	mesh = wTool.commit(mesh)
	MarchingSquaresGenerator.finishTool(cTool)
	mesh = cTool.commit(mesh)
	
	meshNode.mesh = mesh
	meshNode.material_override = material
			
	return meshNode
	
func generateAll():
	
	print ("wc: ", wc)
	print ("hwc: ", hwc)
	print ("qwc: ", qwc)
	print ("hywc: ", hywc)
	
	for i in range(get_child_count()):
		var c = get_child(0)
		remove_child(c)
		
	var _mesh0 = generateNode(0)
	var _mesh1 = generateNode(1)
	var _mesh2 = generateNode(2)
	var _mesh3 = generateNode(3)
	var _mesh4 = generateNode(4)
	var _mesh5 = generateNode(5)
	var _mesh6 = generateNode(6)
	var _mesh7 = generateNode(7)
	var _mesh8 = generateNode(8)
	var _mesh9 = generateNode(9)
	var _mesh10 = generateNode(10)
	var _mesh11 = generateNode(11)
	var _mesh12 = generateNode(12)
	var _mesh13 = generateNode(13)
	var _mesh14 = generateNode(14)
	var _mesh15 = generateNode(15)
		
	#dupe(_mesh13, Vector3(-3, 0, 0))
	#dupe(_mesh8, Vector3(-2, 0, 0))
	#dupe(_mesh9, Vector3(-3, 0, 1))
	#dupe(_mesh8, Vector3(-3, 0, 2))
	
func dupe(node: Node, pos: Vector3):
	var new = node.duplicate() as Node3D
	new.position = pos
	P1Utils.addEditorChild(get_node("test"), new, node.name)
	
