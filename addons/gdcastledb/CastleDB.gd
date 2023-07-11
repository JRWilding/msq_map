extends RefCounted

class_name CastleDB

#
# CastleDB importer for Godot Engine 4.x by あるる（きのもと 結衣） @arlez80
#

# ------------------------------------------------------------------------------

class Tile:
	var file:String = ""
	var size:int = 0
	var x:int = 0
	var y:int = 0
	var stride:int = 0
	
	func _init(_file:String = "",_size:int = 0,_x:int = 0,_y:int = 0,_stride:int = 0):
		self.file = _file
		self.size = _size
		self.x = _x
		self.y = _y
		self.stride = _stride

# ------------------------------------------------------------------------------

var all:Array = []
var keys:Dictionary = {}

# ------------------------------------------------------------------------------

func _generate_keys( ) -> void:
	#
	# キーから検索できるように対応表を作る
	#

	var index:int = 0
	for row in all:
		self.keys[row._unique_id_name] = index
		index += 1

func _delay_set_reference( import_src ) -> void:
	#
	# 参照を遅延で解決する
	#

	for row in self.all:
		row._delay_set_reference( import_src )

func _query( q:String ):
	#
	# SQL風実行
	# @param	q	クエリ
	# @return	結果
	# TODO: Haxe版にあるのでやる気がでたら実装する
	#

	pass

