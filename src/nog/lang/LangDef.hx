package nog.lang;

typedef LangDef =
{
	var name:String;
	var fileExt:String;
	var rootDef:TokenPos;
	var identifierTypes:Array<String>;
}

#if (nogpos || macro)

typedef TokenPos =  {
	var min:Int;
	var max:Int;
	var file:String;
	var tokenRef:TokenDef;
}

#else

typedef TokenPos = TokenDef;

#end


enum TokenDef {
	Ident(type:String, ?next:TokenPos);
	
	Ref(id:String, pointer:Pointer<TokenPos>, ?next:TokenPos);
	
	LiteralOp(op:String, def:TokenPos);
	LiteralLabel(label:String, def:TokenPos);
	LiteralStr(quote:String, str:String);
	LiteralBlock(bracket:String, children:Array<TokenPos>);
	
	Optional(def:TokenPos);
	Alternate(children:Array<TokenPos>);
	Multi(def:TokenPos, ?min:Int, ?max:Int);
	
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

/*class Pointer<T> {
	
	private static var LAST_ID :Int = 0;
	
	public var value:T;
	public var id:Int;
	private var isPrinting:Bool;
	
	public function new(?value:T) {
		this.value = value;
		this.id = LAST_ID++;
	}
	
	public function toString():String {
		var ret:String;
		if(!isPrinting){
			isPrinting = true;
			var ret =  "*{"+id+"}" + value;
			isPrinting = false;
			return ret;
		}else {
			return "*{" + id + "}";
		}
	}
}*/