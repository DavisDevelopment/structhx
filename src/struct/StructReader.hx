package test;

import haxe.macro.Expr;
import haxe.macro.Context;

import test.*;
import test.StructInfo in Info;
import test.StructField in Field;
import test.FieldType in Ftype;

import tannus.io.Buffer;

using test.StructTools;

class StructReader {
	/* Constructor Function */
	public function new(data : Info):Void {
		info = data;
	}

/* === Instance Methods === */

	/**
	  * Read a Struct from the given Buffer
	  */
	public macro function read_from<T:Struct>(self:ExprOf<StructReader>, b:ExprOf<Buffer>, more:Array<Expr>):ExprOf<T> {
		var type = Context.getExpectedType();
		var name:ExprOf<Class<Struct>> = macro $p{type.fullName().split('.')};
		var offset:Null<ExprOf<Int>> = cast more.shift();

		if (offset == null) {
			return macro ($self.read_struct_from($name, $b));
		}
		else {
			return macro ($self.read_struct_from($name, $b, $offset));
		}
	}

	/**
	  * Read a Struct from the given Buffer
	  */
	public function read_struct_from<T:Struct>(cl:Class<T>, buf:Buffer, ?offset:Int=0):T {
		var i:T = cast Type.createEmptyInstance( cl );
		buf.goto(offset);

		for (field in info) {
			read_field_to(i, field, buf);
		}

		return i;
	}

	/**
	  * Read a given Field from the given Buffer onto the given Struct
	  */
	private function read_field_to<T:Struct>(item:T, field:Field, buffer:Buffer):Void {
		var value:Dynamic = read_field(field, buffer);
		Reflect.setField(item, field.name, value);
	}

	/**
	  * Read the value of a given Field from the given Buffer
	  */
	private function read_field(f:Field, b:Buffer):Dynamic {
		return read_value(f.ftype, b);
	}

	/**
	  * Read a value of the given type from the given Buffer
	  */
	private function read_value(type:Ftype, b:Buffer):Dynamic {
		switch ( type ) {
			case TBool:
				return b.readBool();

			case TInt:
				return b.readInt();

			case TFloat:
				return b.readDouble();

			case TString(len):
				return b.readString(len);

			case TArray(atype, count):
				var list:Array<Dynamic> = new Array();
				for (i in 0...count) {
					list.push(read_value(atype, b));
				}
				return list;

			case TStruct( info ):
				throw 'Error: Cannot read fields with Struct types yet!';
				return null;
		}
	}

/* === Instance Fields === */

	/* the struct-info attached to [this] Reader */
	public var info : Info;
}
