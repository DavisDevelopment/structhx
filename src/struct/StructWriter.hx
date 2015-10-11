package test;

import tannus.io.Buffer;
import haxe.io.Bytes;

import test.FieldType in Ftype;
import test.StructField in Field;
import test.StructInfo;
import test.Struct;

import Reflect.getProperty in attr;

using test.StructTools;
using StringTools;
using Lambda;

class StructWriter {
	/* Constructor Function */
	public function new(data : StructInfo):Void {
		info = data;
	}

/* === Instance Methods === */

	/**
	  * get the total size of [this] Struct
	  */
	private function size():Int {
		return (info.size());
	}

	/**
	  * Write an instance of the Struct in question to a Buffer
	  */
	public function write_to(item:Struct, b:Buffer):Void {
		if (b.length < size())
			throw 'Error: provided Buffer is of insufficient size to store this struct';

		var get = attr.bind(item, _);
		for (f in info) {
			var type = f.ftype;
			var v = get(f.name);
			write_value(v, type, b);
		}
	}

	/**
	  * Create a new Buffer, write [item] to it, and return the Buffer
	  */
	public function write(item : Struct):Buffer {
		var buffr:Buffer = Buffer.alloc(size());

		write_to(item, buffr);

		return buffr;
	}

	/**
	  * Write the given value of the given type to the given Buffer
	  */
	private function write_value(val:Dynamic, type:Ftype, b:Buffer):Void {
		switch (type) {
			case TBool:
				b.writeBool(cast val);

			case TFloat:
				b.writeDouble(cast val);

			case TInt:
				b.writeInt(cast val);

			case TString( len ):
				b.writeString(Std.string(val).rpad(String.fromCharCode(0), len));

			case TArray(atype, len):
				var items:Array<Dynamic> = cast val;
				for (iv in items)
					write_value(iv, atype, b);

			case TStruct( info ):
				for (f in info) {
					type = f.ftype;
					var v = attr(val, f.name);
					write_value(v, type, b);
				}
		}
	}

/* === Instance Fields === */

	/* the fields of the Struct being written */
	public var info : StructInfo;

	/* the class of the Struct type in question */
	// public var struct : Class<T>;
}
