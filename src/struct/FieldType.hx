package test;

import test.StructInfo;

enum FieldType {
	TBool;
	TFloat;
	TInt;
	TString(size : Int);
	TArray(type:FieldType, sizes:Int);
	TStruct(info : StructInfo);
}
