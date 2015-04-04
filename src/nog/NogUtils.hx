package nog;

import nog.Nog;

class NogUtils
{
	public static var STRINGIFY_TAB:String = "\t";
	public static var STRINGIFY_NEWLINE:String = "\n";
	public static var STRINGIFY_SPACE:String = " ";
	public static var STRINGIFY_LINEEND:String = ";";
	
	#if (nogpos || macro)
	public static function stringify( nog:NogPos, pretty:Bool=true ):String
	{
		return stringifyNog(nog, pretty, "");
	}
	private static function stringifyNog( nog:NogPos, pretty:Bool, leadingWhite:String ):String
	{
		if (pretty) {
			return stringifyNogObj(nog.nogRef, pretty, leadingWhite);
			//return "{" + STRINGIFY_SPACE+"start:" +nog.min + "," + STRINGIFY_SPACE+"end:" + nog.max + "," + STRINGIFY_SPACE+"nog:" + stringifyNogObj(nog.nogRef, pretty, leadingWhite) + STRINGIFY_SPACE+"}";
		}else {
			return "{start:" +nog.min + ",end:" + nog.max + ",nog:" + stringifyNogObj(nog.nogRef, pretty, leadingWhite) + "}";
		}
	}
	
	public static function nog(nogPos:NogPos):Nog {
		return nogPos.nogRef;
	}
	public static function pos(nog:Nog, min:Int, max:Int, file:String):NogPos {
		return { nogRef:nog, min:min, max:max, file:file };
	}
	
	#else
	
	public static function stringify( nog:Nog, pretty:Bool=true ):String
	{
		return stringifyNogObj(nog, pretty, "");
	}
	private static function stringifyNog( nog:Nog, pretty:Bool, leadingWhite:String ):String
	{
		return stringifyNogObj(nog, pretty, leadingWhite);
	}
	
	public static function nog(nogPos:NogPos):Nog {
		return nogPos;
	}
	public static function pos(nog:Nog, min:Int, max:Int, file:String):NogPos {
		return nog;
	}
	
	#end
	
	
	private static function stringifyNogObj( nog:Nog, pretty:Bool, leadingWhite:String ):String
	{
		switch(nog) {
			case Nog.Block(bracket, children):
				var ret = bracket;
				
				var childWhite = (pretty ? leadingWhite + STRINGIFY_TAB : leadingWhite );
				var addNewline = false;
				var childStrs = [];
				for (child in children) {
					var childStr = stringifyNog(child, pretty, childWhite);
					childStrs.push(childStr);
					if (pretty && !addNewline && (childStr.indexOf(STRINGIFY_NEWLINE) != -1 || containsBlock(child))){
						addNewline = true;
					}
				}
				var newLine = (pretty ? STRINGIFY_NEWLINE : "");
				if (addNewline) {
					for (childStr in childStrs) {
						ret += newLine + childWhite + childStr;
					}
					ret += STRINGIFY_NEWLINE + leadingWhite;
				}else{
					for (i in 0...childStrs.length) {
						var childStr = childStrs[i];
						ret += childStr;
						if (childStrs.length > 1 && i<childStrs.length-1) {
							ret += STRINGIFY_LINEEND;
						}
					}
				}
				
				switch(bracket) {
					case "<": ret += ">";
					case "{": ret += "}";
					case "[": ret += "]";
					case "(": ret += ")";
				}
				return ret;
				
			case Nog.Comment(comment):
				return "#"+comment;
				
			case Nog.CommentMulti(comment):
				return "##"+comment+"##";
				
			case Nog.Label(label, child1, child2):
				var ret = label;
				if (child1 != null) {
					if (pretty) ret += STRINGIFY_SPACE;
					ret += stringifyNog(child1, pretty, leadingWhite);
				}
				if (child2 != null) {
					if (pretty) ret += STRINGIFY_SPACE;
					ret += stringifyNog(child2, pretty, leadingWhite);
				}
				return ret;
				
			case Nog.Op(op, child1, child2):
				var ret = op;
				if (child1 != null) {
					if (pretty) {
						switch(NogUtils.nog(child1)) {
							case Nog.Op(_, _) | Nog.Str(_):
								ret += STRINGIFY_SPACE;
							default:
						}
					}
					ret += stringifyNog(child1, pretty, leadingWhite);
				}
				if (child2 != null) {
					if (pretty) {
						switch(NogUtils.nog(child2)) {
							case Nog.Op(_, _) | Nog.Str(_):
								ret += STRINGIFY_SPACE;
							default:
						}
					}
					ret += stringifyNog(child2, pretty, leadingWhite);
				}
				return ret;
				
			case Nog.Str(quote, string):
				return quote + string + quote;
				
		}
	}
	
	static private function containsBlock(nogPos:NogPos) : Bool
	{
		switch(NogUtils.nog(nogPos)) {
			case Nog.Comment(_) | Nog.CommentMulti(_) | Nog.Str(_, _):
				return false;
				
			case Nog.Block(_, children):
				return children.length > 0;
				
			case Nog.Op(_, child1, child2) | Nog.Label(_, child1, child2):
				return (child1 != null && containsBlock(child1)) || (child2 != null && containsBlock(child2));
		}
	}
}