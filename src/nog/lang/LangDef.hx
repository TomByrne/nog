package nog.lang;

import nog.Nog;

typedef LangDef =
{
	var name:String;
	var fileExt:String;
	var readerType:String;
	var metadata:Array<LangMeta>;
	var file:String;
	var rootDefs:Array<TokenPos>;
	var identifierTypes:Array<String>;
	var symbols:Array<Ref>;
}
enum LangMeta {
	SetProp(nogPos:NogPos, target:String, fields:Array<String>, value:Dynamic);
	CallMethod(nogPos:NogPos,target:String, fields:Array<String>, args:Array<Dynamic>);
}

#if (nogpos || macro)

typedef TokenPos =  {
	var min:Int;
	var max:Int;
	var line:Int;
	var file:String;
	var tokenRef:TokenDef;
}

#else

typedef TokenPos = TokenDef;

#end


enum TokenDef {
	Ident(type:String, partSeparator:String, ?next:TokenPos);
	Named(name:String, ?next:TokenPos);
	
	Ref(id:String, pointer:Pointer<TokenPos>, ?next:TokenPos);
	
	LiteralOp(op:String, ?next:TokenPos);
	LiteralLabel(label:String, ?next:TokenPos);
	LiteralStr(quote:String, str:String, ?next:TokenPos);
	LiteralBlock(bracket:String, children:Array<TokenPos>, ?next:TokenPos);
	
	Optional(def:TokenPos, ?next:TokenPos);
	Alternate(children:Array<TokenPos>, ?next:TokenPos);
	Multi(def:TokenPos, min:Int, max:Int, ?next:TokenPos);
	
	Int(?next:TokenPos);
	Float(?next:TokenPos);
	String(acceptSingle:Bool, acceptDouble:Bool, acceptBacktick:Bool, ?next:TokenPos);
}

enum CharSpec {
	Char(char:String);
	Range(from:String, to:String);
}

typedef Pointer<T> = {
	public var value:T;
}

typedef Ref = {
	public var name:String;
	public var value:TokenPos;
}

typedef Ident = {
	var type:String;
	var ident:String;
}