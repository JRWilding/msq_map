@tool
extends EditorPlugin

#
# CastleDB importer for Godot Engine 3.x by あるる（きのもと 結衣） @arlez80
#

var importer = null

# ------------------------------------------------------------------------------

func _enter_tree():
	self.importer = preload("importer.gd").new( )
	self.add_import_plugin( self.importer )

func _exit_tree():
	self.remove_import_plugin( self.importer )
	self.importer = null

# ------------------------------------------------------------------------------

func get_name( ) -> StringName:
	return "CastleDB Import Addon"
