package nog;

import nog.Nog;

class NogUtils
{
	public static var STRINGIFY_TAB:String = "\t";
	public static var STRINGIFY_NEWLINE:String = "\n";
	public static var STRINGIFY_SPACE:String = " ";
	
	#if nogpos
	public static function stringify( nog:NogPos, pretty:Bool=true ):String
	{
		return stringifyNog(nog, pretty, "");
	}
	private static function stringifyNog( nog:NogPos, pretty:Bool, leadingWhite:String ):String
	{
		if(pretty){
			return "{" + STRINGIFY_SPACE+"start:" +nog.start + "," + STRINGIFY_SPACE+"end:" + nog.end + "," + STRINGIFY_SPACE+"nog:" + stringifyNogObj(nog.nog, pretty, leadingWhite) + STRINGIFY_SPACE+"}";
		}else {
			return "{start:" +nog.start + ",end:" + nog.end + ",nog:" + stringifyNogObj(nog.nog, pretty, leadingWhite) + "}";
		}
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
	
	#end
	
	
	private static function stringifyNogObj( nog:Nog, pretty:Bool, leadingWhite:String ):String
	{
		switch(nog) {
			case Nog.Block(bracket, children):
				var ret = bracket + STRINGIFY_NEWLINE;
				var childWhite = leadingWhite;
				if (pretty) childWhite += STRINGIFY_TAB;
				for (child in children) {
					ret += childWhite + stringifyNog(child, pretty, childWhite) + STRINGIFY_NEWLINE;
				}
				ret += leadingWhite;
				switch(bracket) {
					case "<": ret += ">";
					case "{": ret += "}";
					case "[": ret += "]";
					case "(": ret += ")";
				}
				return ret + STRINGIFY_NEWLINE + leadingWhite;
				
			case Nog.Comment(comment):
				return "#"+comment;
				
			case Nog.CommentMulti(comment):
				return "##"+comment+"##";
				
			case Nog.Label(label, child):
				var ret = label;
				if (child != null) {
					if (pretty) ret += STRINGIFY_SPACE;
					ret += stringifyNog(child, pretty, leadingWhite);
				}
				return ret;
				
			case Nog.Op(op, child):
				var ret = op;
				if (child != null) {
					if (pretty) ret += STRINGIFY_SPACE;
					ret += stringifyNog(child, pretty, leadingWhite);
				}
				return ret;
				
			case Nog.Str(quote, string):
				return quote + string + quote;
				
		}
	}
}