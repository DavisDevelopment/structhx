package test;

import test.StructField;
import test.FieldType in Ftype;

using test.StructTools;

@:forward
abstract StructInfo (CStructInfo) from CStructInfo {
	/* Constructor Function */
	public inline function new(list : Array<StructField>):Void {
		this = new CStructInfo(list);
	}

/* === Type Casting === */

	/* from Array<StructField> */
	@:from
	public static inline function fromFields(list : Array<StructField>):StructInfo {
		return new StructInfo(list);
	}
}

class CStructInfo {
	/* Constructor Function */
	public function new(list : Array<StructField>):Void {
		fields = list;
		writer = new StructWriter(cast this);
		reader = new StructReader(cast this);
	}

/* === Instance Methods === */

	/**
	  * Iterate over [this] Data
	  */
	public function iterator():Iterator<StructField> {
		return (fields.iterator());
	}

	/**
	  * Get a Field by name
	  */
	public function field(name : String):Null<StructField> {
		for (f in this)
			if (f.name == name)
				return f;
		return null;
	}

	/**
	  * Get total size of [this] Struct
	  */
	public function size():Int {
		var s:Int = 0;
		for (f in this)
			s += f.ftype.sizeof();
		return s;
	}

/* === Instance Fields === */

	public var fields : Array<StructField>;
	public var writer : StructWriter;
	public var reader : StructReader;
}
