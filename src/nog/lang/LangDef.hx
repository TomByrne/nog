package nog.lang;

import nog.Nog;

typedef LangDef =
{
	var name:String;
	var fileExt:String;
	var readerType:String;
	var file:String;
	var rootDefs:Array<TokenPos>;
	var identifierTypes:Array<String>;
	var symbols:Array<Ref>;
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
	Ident(type:String, ?next1:TokenPos, ?next2:TokenPos);
	Named(name:String, ?next:TokenPos);
	
	Ref(id:String, pointer:Pointer<TokenPos>, ?next:TokenPos);
	
	LiteralOp(op:String, ?next1:TokenPos, ?next2:TokenPos);
	LiteralLabel(label:String, ?next1:TokenPos, ?next2:TokenPos);
	LiteralStr(quote:String, str:String);
	LiteralBlock(bracket:String, children:Array<TokenPos>);
	
	Optional(def:TokenPos, ?next:TokenPos);
	Alternate(children:Array<TokenPos>, ?next:TokenPos);
	Multi(def:TokenPos, min:Int, max:Int, ?next:TokenPos);
	
	Int();
	Float();
	String(acceptSingle:Bool, acceptDouble:Bool, acceptBacktick:Bool);
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