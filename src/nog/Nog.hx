package nog;

enum Nog
{
	Op(op:String, ?next:NogPos);
	Label(label:String, ?next:NogPos);
	Block(bracket:String, children:Array<NogPos>, ?next:NogPos, ?blockBreak:String);
	Comment(comment:String);
	CommentMulti(comment:String, ?next:NogPos);
	
	Str(quote:String, string:String, ?next:NogPos);
	Int(value:Int, hex:Bool, ?next:NogPos);
	Float(value:Float, ?next:NogPos);
}

abstract Bracket(String) {
	public static var Round = "(";
	public static var Square = "[";
	public static var Curly = "{";
	public static var Angle = "<";
}

abstract BlockBreak(String) {
	//public static var Comma = ",";
	public static var SemiColon = ";";
	public static var Newline = "\n";
	public static var Return = "\r";
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