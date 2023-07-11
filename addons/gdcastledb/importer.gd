@tool
extends EditorImportPlugin

#
# CastleDB importer for Godot Engine 4.x by あるる（きのもと 結衣） @arlez80
#

# ------------------------------------------------------------------------------

func _get_resource_type( ) -> String:
	return "Script"

func _get_save_extension( ) -> String:
	return "gd"

func _get_recognized_extensions( ) -> PackedStringArray:
	return ["cdb"]

func _get_visible_name( ) -> String:
	return "CastleDB"

func _get_importer_name( ) -> String:
	return "CastleDBImporter"

func _get_preset_count( ) -> int:
	return 1

func _get_preset_name( preset:int ) -> String:
	return "Default"

func _get_import_options( path: String, preset_index: int ) -> Array[Dictionary]:
	return []

func _get_option_visibility( path: String, option_name: StringName, options: Dictionary ) -> bool:
	return true

func _get_import_order( ) -> int:
	return 0

func _get_priority( ) -> float:
	return 1.0

# ------------------------------------------------------------------------------

enum CDBType {
	CDB_ID,
	CDB_STRING,
	CDB_BOOL,
	CDB_INT,
	CDB_FLOAT,
	CDB_ENUM,
	CDB_REFERENCE,
	CDB_IMAGE,			# 未対応
	CDB_LIST,
	CDB_CUSTOM_TYPE,	# 未対応
	CDB_FLAGS,
	CDB_COLOR,
	CDB_LAYER,			# 未対応
	CDB_FILE,
	CDB_TILE,
	CDB_TILE_LAYER,		# 未対応
	CDB_DYNAMIC,		# 未対応
	CDB_PROPERTIES,		# 未対応
}

# ------------------------------------------------------------------------------

func _convert_sheet_name_to_inst_name( s:String ) -> String:
	#
	# シート名をインスタンス名に変換する
	# @param	s	元名前
	# @return	GDScript用名前
	#

	if s == s.to_lower( ):
		if s.replace( "@", "_" ).is_valid_identifier( ):
			# 変換不要
			return s.replace( "@", "_" )

	var next_cap:bool = false
	var d:String = ""
	for i in range( s.length( ) ):
		var c: = s[i]
		if c == "@":
			d += "_"
		else:
			if next_cap and c == c.to_upper( ):
				d += "_"
			next_cap = true
			d += c.to_lower( )

	return d

func _convert_sheet_name_to_class_name( s:String ) -> String:
	#
	# シート名をクラス名へ変換する
	# @param	s	元名前
	# @return	GDScript用名前
	#

	return s.capitalize( ).replace( " ", "" ).replace( "@", "_" )

func _convert_key_name( s:String ) -> String:
	#
	# キー名を変換する
	# @param	s	元名前
	# @return	GDScript用名前
	#

	return s.capitalize( ).strip_edges( ).replace( " ", "" )

func _convert_enum_name( s:String ) -> String:
	#
	# enumアイテム名を変換する
	# @param	s	元名前
	# @return	GDScript用名前
	#

	return s.capitalize( ).strip_edges( ).to_upper( ).replace( " ", "_" )

func _has_unique_id( columns:Array ) -> bool:
	#
	# ユニークIDを持っているか？
	# @param	columns	項目リスト
	# @return	あればTrueを返す
	#

	for column in columns:
		var type:PackedStringArray = column["typeStr"].split(":")
		match int( type[0] ):
			CDBType.CDB_ID:
				return true
			_:
				pass

	return false

func _generate_enum_and_flags( columns:Array ) -> String:
	#
	# EnumとFlagsを生成する
	# @param	columns	項目リスト
	# @return	GDScriptコード
	#

	var code:String = ""

	for column in columns:
		var type:PackedStringArray = column["typeStr"].split(":")
		match int( type[0] ):
			CDBType.CDB_ENUM:
				var items: = type[1].split(",")
				code += "\tenum %s {" % [self._convert_key_name( column["name"] )]
				for item in items:
					code += "%s," % item
				code += "}\n"
			CDBType.CDB_FLAGS:
				var id:int = 1
				var items: = type[1].split(",")
				code += "\tenum %s {" % [self._convert_key_name( column["name"] )]
				for item in items:
					code += "%s = %d," % [ item, id ]
					id <<= 1
				code += "}\n"
			_:
				pass

	return code

func _generate_row_class( name:String, columns:Array ) -> String:
	#
	# 行用クラスを生成する
	# @param	name	シート名
	# @param	column	項目リスト
	# @return	GDScriptコード
	#

	var members:Array = []
	var init_arg:Array = []
	var init_code:Array = []
	var ref_code:Array = []

	for column in columns:
		var column_name:String = column["name"]
		var type:PackedStringArray = column["typeStr"].split(":")
		match int( type[0] ):
			CDBType.CDB_ID:
				members.append( "%s := \"\"" % column_name )
				init_code.append( "self._unique_id_name = _%s" % [column_name] )

				members.append( "_unique_id_name := \"\"" )
				init_arg.append( "_%s:String" % column_name )
				init_code.append( "self.%s = _%s" % [column_name, column_name] )
			CDBType.CDB_STRING, CDBType.CDB_FILE:
				members.append( "%s := \"\"" % column_name )
				init_arg.append( "_%s:String" % column_name )
				init_code.append( "self.%s = _%s" % [column_name, column_name] )
			CDBType.CDB_BOOL:
				members.append( "%s := false" % column_name )
				init_arg.append( "_%s:bool" % column_name )
				init_code.append( "self.%s = _%s" % [column_name, column_name] )
			CDBType.CDB_INT, CDBType.CDB_ENUM, CDBType.CDB_FLAGS:
				members.append( "%s := 0" % column_name )
				init_arg.append( "_%s:int" % column_name )
				init_code.append( "self.%s = _%s" % [column_name, column_name] )
			CDBType.CDB_FLOAT:
				members.append( "%s := 0.0" % column_name )
				init_arg.append( "_%s:float" % column_name )
				init_code.append( "self.%s = _%s" % [column_name, column_name] )
			CDBType.CDB_LIST:
				members.append( "%s := []" % column_name )
				init_arg.append( "_%s:Array" % column_name )
				init_code.append( "self.%s = _%s" % [column_name, column_name] )
				ref_code.append( "for t in self.%s: t._delay_set_reference( import_src )" % [column_name] )
			CDBType.CDB_COLOR:
				members.append( "%s := Color( )" % column_name )
				init_arg.append( "_%s:Color" % column_name )
				init_code.append( "self.%s = _%s" % [column_name, column_name] )
			CDBType.CDB_TILE:
				members.append( "%s := CastleDB.Tile.new( )" % column_name )
				init_arg.append( "_%s:CastleDB.Tile" % column_name )
				init_code.append( "self.%s = _%s" % [column_name, column_name] )
			CDBType.CDB_REFERENCE:
				var sheet_inst_name: = self._convert_sheet_name_to_inst_name( type[1] )
				var sheet_class_name: = self._convert_sheet_name_to_class_name( type[1] )
				members.append( "%s:%s.Row = null" % [column_name, sheet_class_name] )
				# init_argでは与えない。遅延で後から対応付け
				# init_codeでは初期化しない

				# 参照キーIDだけ持っておく
				members.append( "_%s_ref_id:String = \"\"" % column_name )
				init_arg.append( "__%s_ref_id:String" % column_name )
				init_code.append( "self._%s_ref_id = __%s_ref_id" % [column_name, column_name] )

				# 参照解決コード
				ref_code.append( "self.%s = import_src.table_%s.get_value(self._%s_ref_id)" % [column_name, sheet_inst_name, column_name] )
			_:
				# 未対応
				pass

	var code:String = "\tclass Row:\n"
	for member in members:
		code += "\t\tvar %s\n" % member
	code += "\t\tfunc _init(%s):\n" % ",".join( init_arg )
	for t in init_code:
		code += "\t\t\t%s\n" % t

	code += "\t\tfunc _delay_set_reference( import_src ):\n"
	if 0 < ref_code.size( ):
		for t in ref_code:
			code += "\t\t\t%s\n" % t
	else:
		code += "\t\t\tpass"

	return code

func _generate_all( name:String, columns:Array, rows:Array, sheets:Array ) -> String:
	#
	# allを生成する
	# @param	name	シート名
	# @param	columns	項目リスト
	# @param	rows	内容リスト
	# @param	sheets	全シートデータ
	# @return	コード化したテーブル内容
	#

	# all
	var all_code:Array[String] = []
	for row in rows:
		var row_code:Array[String] = []
		for column in columns:
			var key_name:String = column["name"]

			if not row.has( key_name ):
				match int( column["typeStr"].split(":")[0] ):
					CDBType.CDB_ID, CDBType.CDB_STRING, CDBType.CDB_FILE, CDBType.CDB_REFERENCE:
						row_code.append( var_to_str( "" ) )
					CDBType.CDB_BOOL:
						row_code.append( var_to_str( false ) )
					CDBType.CDB_FLOAT:
						row_code.append( var_to_str( 0.0 ) )
					CDBType.CDB_INT, CDBType.CDB_ENUM, CDBType.CDB_FLAGS:
						row_code.append( "0" )
					CDBType.CDB_COLOR:
						row_code.append( "Color8() ")
					CDBType.CDB_TILE:
						row_code.append( "null" )
					CDBType.CDB_LIST:
						row_code.append( "[]" )
					_:
						# 未対応
						pass
			else:
				match int( column["typeStr"].split(":")[0] ):
					CDBType.CDB_ID, CDBType.CDB_STRING, CDBType.CDB_FILE, CDBType.CDB_BOOL, CDBType.CDB_FLOAT, CDBType.CDB_REFERENCE:
						row_code.append( var_to_str( row[key_name] ) )
					CDBType.CDB_INT, CDBType.CDB_ENUM, CDBType.CDB_FLAGS:
						# XXX: var2strにすると浮動小数点になるため分離
						row_code.append( str( row[key_name] ) )
					CDBType.CDB_COLOR:
						var c:int = row[key_name]
						var r:int = ( c >> 16 ) & 255
						var g:int = ( c >> 8 ) & 255
						var b:int = c & 255
						row_code.append( "Color8(%d,%d,%d)" % [r,g,b] )
					CDBType.CDB_TILE:
						var args:Array[String] = []
						for tile_key in ["file", "size", "x", "y", "stride"]:
							if row[key_name].has( tile_key ):
								if tile_key == "file":
									args.append( var_to_str( row[key_name][tile_key] ) )
								else:
									# XXX: var2strだとfloatになってしまう
									args.append( str( row[key_name][tile_key] ) )
						row_code.append( "CastleDB.Tile.new(%s)" % ",".join( args ) )
					CDBType.CDB_LIST:
						var list_name: = self._convert_sheet_name_to_class_name( "%s@%s" % [name, key_name] )
						for sheet in sheets:
							if self._convert_sheet_name_to_class_name( sheet["name"] ) == list_name:
								row_code.append( self._generate_all( list_name, sheet["columns"], row[key_name], sheets ) )
								break
					_:
						# 未対応
						pass

		all_code.append( "%s.Row.new(%s)" % [ name, ",".join( row_code ) ] )

	return "[%s]" % [ ",".join( all_code ) ]

# ------------------------------------------------------------------------------

func _import( source_file:String, save_path:String, options:Dictionary, platform_variants:Array, gen_files:Array ) -> Error:
	var file: = FileAccess.open( source_file, FileAccess.READ )
	if file.get_error() != OK:
		return file.get_error()

	var json: = JSON.new()
	var json_error: = json.parse( file.get_as_text( ) )
	file.close( )
	if json_error != OK:
		return json_error

	var data:Dictionary = json.data
	var code:String = "extends Node\n"
	code += "\n"
	code += "# this file is auto generated by GDCastledb @arlez80\n"
	code += "# DO NOT EDIT BY MANUAL\n"
	code += "\n"

	if data.has("sheets"):
		var sheets:Array = data["sheets"]
		var class_code:String = ""
		var var_code:String = ""
		var init_code:String = ""

		for sheet in sheets:
			# TODO: Godotでの予約済み識別子を与えられたときにエラーぐらい返したほうがいいんじゃないかな
			var sheet_inst_name:String = self._convert_sheet_name_to_inst_name( sheet["name"] )
			var sheet_class_name:String = self._convert_sheet_name_to_class_name( sheet["name"] )

			# クラス宣言
			class_code += "\n".join([
				"class %s extends CastleDB:" % sheet_class_name
			,	self._generate_enum_and_flags( sheet["columns"] )
			,	self._generate_row_class( sheet_class_name, sheet["columns"] )
			,	""
			,	"\tfunc _init( ):"
			,	"\t\tself.all = %s" % self._generate_all( sheet_class_name, sheet["columns"], sheet["lines"], sheets )
			,	"\t\tself._generate_keys( )\n" if self._has_unique_id( sheet["columns"] ) else ""
			,	"\tfunc get_value( id:String ) -> %s.Row:" % [ sheet_class_name ]
			,	"\t\tif self.keys.has( id ):"
			,	"\t\t\treturn self.all[self.keys[id]]"
			,	"\t\treturn null"
			,	""
			,	"\tfunc get_index( id:String ) -> int:"
			,	"\t\tif self.keys.has( id ):"
			,	"\t\t\treturn self.keys[id]"
			,	"\t\treturn -1"
			,	""
			])

			if 0 < sheet["lines"].size( ):
				# 変数
				var_code += "var table_%s: = %s.new( )\n" % [ sheet_inst_name, sheet_class_name ]

				# 初期化
				init_code += "\tself.table_%s._delay_set_reference( self )\n" % [ sheet_inst_name ]

		code += class_code
		code += "\n"
		code += var_code
		code += "\n"
		code += "func _init( ):\n"
		code += init_code

	var converted_source: = GDScript.new( )
	converted_source.set_source_code( code )
	return ResourceSaver.save( converted_source, "%s.%s" % [ save_path, self._get_save_extension( ) ] )
