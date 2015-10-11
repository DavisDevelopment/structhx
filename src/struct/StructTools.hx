package test;

import haxe.Serializer;

import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.Context;
import haxe.macro.Type.ClassField;

import test.StructField;
import test.FieldType in Ftype;

using haxe.macro.ExprTools;
using haxe.macro.TypeTools;

using Lambda;
using StringTools;
using tannus.ds.StringUtils;

class StructTools {

	/**
	  * Get the struct-data
	  */
	public static macro function getData<T : Struct>(cl : ExprOf<Class<T>>):ExprOf<test.StructInfo> {
		var t:Type = Context.typeof(cl);
		t = getClassType(t);
		var info_class = infoClass( t );
		var result = macro ($info_class.get());
		return result;
	}

	/**
	  * Obtain a writer for a given Struct
	  */
	public static macro function writer<T : Struct>(cl : ExprOf<Class<T>>):ExprOf<StructWriter> {
		/*
		var t:Type = getClassType(Context.typeof( cl ));
		var fields:Array<StructField> = data( t );
		*/

		return macro (new test.StructWriter($cl, $cl.getData()));
	}

	/* obtain the Bytes-encoded version of the given Struct */
	public static macro function write<T : Struct>(s : ExprOf<T>):ExprOf<tannus.io.Buffer> {
		var t = Context.typeof(s);
		var info:StructInfo = data(t);
		var infoe = infoExpr(info);
		
		var writer:Expr = macro new test.StructWriter(cast Type.getClass($s), $infoe);

		return macro ($writer.write( $s ));
	}

	/**
	  * Get FieldType value from Type name
	  */
	public static function fieldTypeFromName(name : String):StructField -> Ftype {
		switch ( name ) {
			case 'Bool':
				return (function(sf) return TBool);

			case 'Float':
				return (function(sf) return TFloat);

			case 'Int':
				return (function(sf) return TInt);

			case 'String':
				return function( sf ) {
					var len:Null<Int> = sf.get('size');
					if (len == null) {
						throw 'Error: Size of $name field must be declared!';
					}
					else {
						return TString( len );
					}
				};

			/* Arrays */
			case (_.strip('Array').strip('<').strip('>') => atype) if (name.startsWith('Array')):
				var _tparam = fieldTypeFromName(atype);
				return function( sf ) {
					return TArray(_tparam(sf), sf.get('size'));
				};

			default:
				throw 'Error: $name is not a struct-file type';
		}
	}

	/**
	  * Get the length (in bytes) of the given type
	  */
	public static function sizeof(ft : Ftype):Int {
		return (switch (ft) {
			/* Boolean */
			case TBool: 1;
			
			/* Integer */
			case TInt: 1;

			/* Double */
			case TFloat: 8;

			/* String */
			case TString(len): (len+1);

			/* Array */
			case TArray(type, size): (sizeof(type) * size);

			/* Other Struct */
			case TStruct( info ): (info.size());
		});
	}

#if macro
	/**
	  * Get the Type [T] from Type Class<T>
	  */
	private static function getClassType(t : Type):Null<Type> {
		var s:String = t.toString();
		var pat:tannus.io.RegEx = ~/^Class<([A-Z0-9.]+)>$/i;
		s = pat.extract(s)[1];
		return Context.getType(s);
	}

	/**
	  * Get a Map of all fields and types
	  */
	public static function data(type : Type):Array<StructField> {
		if (isStruct( type )) {
			var klass = type.getClass();
			var fields = klass.fields.get();
			var sfields:Array<StructField> = new Array();

			for (f in fields) {
				switch (f.kind) {
					case FVar(_, _):
						var data = fieldData( f );
						if (data.exists('field')) {
							var ftype:Type = getBaseType( f.type );
							sfields.push(new StructField(f.name, ftype.toString(), data));
						}

					default:
						continue;
				}
			}

			return sfields;
		}
		else {
			throw 'Error: $type is not a struct';
			return [];
		}
	}
	/**
	  * Check if the given type is a Struct
	  */
	public static function isStruct(t : Type):Bool {
		switch ( t ) {
			/* Class Type */
			case TInst(_.get() => klass, params):
				var ints = klass.interfaces;
				var names = ints.map(function(i) {
					var ct = i.t.get();
					return (ct.pack.concat([ct.name]).join('.'));
				});
				return names.has('test.Struct');

			default:
				return false;
		}
	}

	/**
	  * Get the most basic form of type [t]
	  */
	public static function getBaseType(t : Type):Type {
		switch ( t ) {
			case TInst(_, _):
				return t;

			case TAbstract(_.get() => ab, _):
				if (ab.type.toString() != t.toString())
					return getBaseType(ab.type);
				else
					return t;

			case TMono(_.get() => _t):
				if (_t != null) {
					return getBaseType( _t );
				} else return t;

			default:
				return t;
		}
	}

	/* get the full name of a type */
	public static function fullName(t : Type):String {
		switch ( t ) {
			case TInst(_.get() => klass, _):
				return (klass.pack.concat([klass.name]).join('.'));

			case TEnum(_.get() => en, _):
				return (en.pack.concat([en.name]).join('.'));

			case TAbstract(_.get() => en, _):
				return (en.pack.concat([en.name]).join('.'));
			
			default:
				return '';
		}
	}

	/**
	  * Creates an expression from a StructInfo instance
	  */
	public static function infoExpr(info : StructInfo):ExprOf<StructInfo> {
		var block:Array<Expr> = [];

		for (f in info) {
			var metaMaker:Expr = (function() {
				var bl:Array<Expr> = [];
				var data = f.meta;
				for (k in data.keys()) {
					var v:String = Serializer.run(data.get(k));
					bl.push(macro met.set($v{k}, haxe.Unserializer.run($v{v})));
				}
				return macro (function() {
					var met:Map<String, Array<Dynamic>> = new Map();
					$b{ bl };
					return met;
				}());
			}());

			block.push(macro {
				var sf:test.StructField = new test.StructField($v{f.name}, $v{f.type}, $metaMaker);
				var li:Int = results.push( sf );
				if (sf.index == null)
					sf.index = li;
			});
		}

		return macro (function() {
			var results:Array<test.StructField> = new Array();

			$b{block};

			return results;
		}());
	}

	/* extract the relevant data from a Field's metadata */
	public static function fieldData(f : ClassField) {
		var meta = f.meta;
		var data:Map<String, Array<Dynamic>> = new Map();

		for (e in meta.get()) {
			data[e.name] = [for (p in e.params) p.getValue()];
		}

		return data;
	}

	/**
	  * Define a new *_Info class
	  */
	public static function infoClass(t : Type):Expr {
		var fname:String = fullName(t);
		var info_name:String = '${fname}_Info'.split('.').map(function(s) return s.capitalize()).join('_');
		var info_ref:Expr = Context.parse(info_name, Context.currentPos());

		try {
			var infoClass = Context.getType(info_name).getClass();
			return macro $i{info_name};
		}
		catch (err : Dynamic) {
			var infoClassDef = macro class $info_name {
				public static function get():test.StructInfo {
					return ${infoExpr(data(t))};
				}
				/*
				public static var info:test.StructInfo;
				public static function __init__():Void {
					info = ${infoExpr(data(t))};
				}
				*/
			}
			Context.defineType( infoClassDef );
			return infoClass(t);
		}
	}
#end
}
