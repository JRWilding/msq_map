# GDCastleDB for Godot Engine 4.0 and later

A [CastleDB](http://castledb.org/) loader for Godot Engine 4.0 and later.

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/E1E44AWTA)

## for Godot Engine 3.0

[See this repository](https://bitbucket.org/arlez80/gdcastledb3/)

## Example

1. Install this addon to your project
2. Add \*.cdb to autoload in the project setting

```
func f( ):
	var row: = TestDB.table_test_sheet.get("ID_TEST")
	print( row.text )
	print( row.integer )
	print( row.floating )
	print( row.color )
```

## TODO

See [repository issues](https://bitbucket.org/arlez80/gdcastledb4/issues?status=new&status=open)

## License

MIT License

## Author

あるる / きのもと 結衣 @arlez80
