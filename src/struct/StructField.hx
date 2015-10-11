package test;

import haxe.macro.Expr;
import haxe.macro.Type;

import tannus.ds.Object;
import test.FieldType in Ftype;

using haxe.macro.TypeTools;
using test.StructTools;

@:forward
abstract StructField (SField) from SField {
	/* Constructor Function */
	public inline function new(n:String, t:String, m:Map<String, Array<Dynamic>>):Void {
		this = new SField(n, t, m);
	}
}

private class SField {
	/* Constructor Function */
	public function new(n:String, t:String, m:SFMeta):Void {
		name = n;
		type = t;
		meta = m;
		ftype = StructTools.fieldTypeFromName(type)(cast this);
		index = get('field');
		size = ftype.sizeof();
	}

/* === Instance Methods === */

	/**
	  * Get a piece of metadata
	  */
	public function get<T>(key:String, ?i:Int=0):Null<T> {
		return (untyped meta.get(key)[i]);
	}

	/**
	  * Get a chunk of metadata
	  */
	public function getall<T>(key : String):Array<T> {
		return (untyped meta.get(key));
	}

/* === Instance Fields === */

	public var name : String;
	public var type : String;
	public var meta : SFMeta;

	public var ftype : Ftype;
	public var index : Int;
	public var size : Int;
}

private typedef SFMeta = Map<String, Array<Dynamic>>;
