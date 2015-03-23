package nog;

enum Nog
{
	Op(op:String, ?child:Nog);
	Label(label:String, ?child:Nog);
	Str(quote:String, string:String);
	Block(bracket:String, children:Array<Nog>);
	Comment(comment:String);
	CommentMulti(comment:String);
}