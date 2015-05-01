package nog;

enum Nog
{
	Op(op:String, ?child1:NogPos, ?child2:NogPos);
	Label(label:String, ?child1:NogPos, ?child2:NogPos);
	Block(bracket:String, children:Array<NogPos>);
	Comment(comment:String);
	CommentMulti(comment:String);
	
	Str(quote:String, string:String);
	Int(value:Int, hex:Bool);
	Float(value:Float);
}

abstract Bracket(String) {
	public static var Round = "(";
	public static var Square = "[";
	public static var Curly = "{";
	public static var Angle = "<";
}

abstract Quote(String) {
	public static var Single = "'";
	public static var Double = '"';
	public static var Backtick = "`";
}

#if (nogpos || macro)

typedef NogPos = {
	var min:Int;
	var max:Int;
	var line:Int;
	var file:String;
	var nogRef:Nog;
}

#else

typedef NogPos = Nog;

#end