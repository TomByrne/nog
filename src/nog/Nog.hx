package nog;
import nog.Nog.Pos;

enum Nog
{
	Op(op:String, ?child:NogPos);
	Label(label:String, ?child:NogPos);
	Str(quote:String, string:String);
	Block(bracket:String, children:Array<NogPos>);
	Comment(comment:String);
	CommentMulti(comment:String);
}

#if nogpos

typedef NogPos = {
	var start:Int;
	var end:Int;
	var nog:Nog;
}

#else

typedef NogPos = Nog;

#end