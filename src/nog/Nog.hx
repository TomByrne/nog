package nog;
import nog.Nog.Pos;

enum Nog
{
	Op(op:String, ?child1:NogPos, ?child2:NogPos);
	Label(label:String, ?child1:NogPos, ?child2:NogPos);
	Str(quote:String, string:String);
	Block(bracket:String, children:Array<NogPos>);
	Comment(comment:String);
	CommentMulti(comment:String);
}

#if (nogpos || macro)

typedef NogPos = {
	var min:Int;
	var max:Int;
	var file:String;
	var nogRef:Nog;
}

#else

typedef NogPos = Nog;

#end