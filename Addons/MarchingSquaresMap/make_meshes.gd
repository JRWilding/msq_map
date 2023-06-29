@tool
class_name MarchingSquaresGenerator extends Node

@export var instance: int:
	set(newInstance):
		print("set instance")
		if get_tree() == null:
			return
		instance = newInstance
		generateAll()

const P1Utils = preload("res://Addons/MarchingSquaresMap/p1_utils.gd")

const dtl = Vector3(0, 0, 0)
const dtr = Vector3(1, 0, 0)
const dbr = Vector3(1, 0, 1)
const dbl = Vector3(0, 0, 1)
const dt = Vector3(0.5, 0, 0.0)
const dr = Vector3(1.0, 0, 0.5)
const db = Vector3(0.5, 0, 1.0)
const dl = Vector3(0.0, 0, 0.5)

const utl = Vector3(0, 1, 0)
const utr = Vector3(1, 1, 0)
const ubr = Vector3(1, 1, 1)
const ubl = Vector3(0, 1, 1)
const ut = Vector3(0.5, 1, 0.0)
const ur = Vector3(1.0, 1, 0.5)
const ub = Vector3(0.5, 1, 1.0)
const ul = Vector3(0.0, 1, 0.5)
	
# returns an Array[Array[Vector3]] for 1 cell with the given marching square config
# Arrays are the triangles for floor, wall, ceiling, in order
# (the outer array will be size=3)
static func generateVerts(config: int) -> Array[Array]:
	var fl = []
	var wa = []
	var ce = []
		
	var verts: Array[Vector3]
	match config:
		0:
			verts = [
				dtl, dtr, dbr, 
				dbr, dbl, dtl
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
		2:
			verts = [
				dbl, dtl, db,
				db, dtl, dr,
				dr, dtl, dtr,
				dr, ur, ub,
				ub, db, dr,
				ub, ur, ubr
			]
		3:
			verts = [
				dtl, dtr, dl,
				dl, dtr, dr,
				dr, ur, ul,
				ul, dl, dr,
				ul, ur, ubl,
				ubl, ur, ubr
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
		5:
			verts = [
				dtl, dt, dl,
				dt, ut, ul,
				ul, dl, dt,
				ut, utr, ur,
				ur, ul, ut,
				ur, ub, ul,
				ul, ub, ubl,
				ub, ur, dr,
				dr, db, ub,
				dr, dbr, db
			]
		6:
			verts = [
				dtl, dt, dbl,
				dbl, dt, db,
				db, dt, ut,
				ut, ub, db,
				ut, utr, ub,
				ub, utr, ubr
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
		8:
			verts = [
				dt, dtr, dbr,
				dbr, dl, dt,
				dbr, dbl, dl,
				dl, ul, ut,
				ut, dt, dl,
				utl, ut, ul
			]
		9:
			verts = [
				utl, ut, ub,
				ub, ubl, utl,
				ut, dt, db,
				db, ub, ut,
				dt, dtr, dbr,
				dbr, db, dt
			]
		10:
			verts = [
				utl, ut, ul,
				ul, ut, ur,
				ur, ubr, ub,
				ub, ul, ur,
				ul, ub, db,
				db, dl, ul,
				dl, db, dbl,
				dt, dtr, dr,
				dr, ur, ut,
				ut, dt, dr
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
		12:
			verts = [
				utl, utr, ul,
				ul, utr, ur,
				ur, dr, dl,
				dl, ul, ur,
				dbl, dl, dr,
				dr, dbr, dbl
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
		14:
			verts = [
				utl, utr, ul,
				ul, utr, ub,
				ub, utr, ubr,
				ul, ub, db,
				db, dl, ul,
				dl, db, dbl
			]
		15:
			verts = [
				utl, utr, ubl,
				ubl, utr, ubr
			]
	
	for i in range(0, verts.size(), 3):
		var v1 = verts[i]
		var v2 = verts[i+1]
		var v3 = verts[i+2]
		var y = v1.y + v2.y + v3.y
		var arr = fl if y == 0 else ce if y == 3 else wa
		arr.push_back(v2)
		arr.push_back(v3)
		arr.push_back(v1)
	
	return [fl, wa, ce]
	
func generateNode(config: int) -> MeshInstance3D:
	var meshNode = MeshInstance3D.new()
	P1Utils.addEditorChild(self, meshNode, "mesh" + str(config))
	var arr = MarchingSquaresGenerator.generateVerts(config)
	var fTool = P1Utils.makeTool()
	var wTool = P1Utils.makeTool()
	var cTool = P1Utils.makeTool()
	
	for v in arr[0]:
		fTool.add_vertex(v)
	for v in arr[1]:
		wTool.add_vertex(v)
	for v in arr[2]:
		cTool.add_vertex(v)
		
	fTool.index()
	fTool.generate_normals()
	var mesh = fTool.commit()
	
	var navMesh = NavigationMesh.new()
	navMesh.create_from_mesh(mesh)
	var navRegion = NavigationRegion3D.new()
	navRegion.navigation_mesh = navMesh
	P1Utils.addEditorChild(meshNode, navRegion, "nav" + str(config))
	
	wTool.index()
	wTool.generate_normals()
	mesh = wTool.commit(mesh)
	
	cTool.index()
	cTool.generate_normals()
	mesh = cTool.commit(mesh)
	
	meshNode.mesh = mesh
	meshNode.translate(Vector3(config % 4 * 2, 0, config / 4 * 2))
	meshNode.create_trimesh_collision()
		
	return meshNode
	
func generateAll():
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
	
	
