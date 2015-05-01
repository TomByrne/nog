package nog;

import haxe.PosInfos;
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
			return stringifyNogObj(nog.nogRef, pretty, leadingWhite, true);
			//return "{" + STRINGIFY_SPACE+"start:" +nog.min + "," + STRINGIFY_SPACE+"end:" + nog.max + "," + STRINGIFY_SPACE+"nog:" + stringifyNogObj(nog.nogRef, pretty, leadingWhite) + STRINGIFY_SPACE+"}";
		}else {
			return "{start:" +nog.min + ",end:" + nog.max + ",nog:" + stringifyNogObj(nog.nogRef, pretty, leadingWhite, true) + "}";
		}
	}
	public static function toString( nog:NogPos ):String
	{
		return stringifyNogObj(nog.nogRef, false, "", false);
	}
	
	public static function nog(nogPos:NogPos):Nog {
		return nogPos.nogRef;
	}
	public static function pos(nog:Nog, file:String, min:Int, max:Int, line:Int):NogPos {
		return { nogRef:nog, file:file, min:min, max:max, line:line };
	}
	
	#else
	
	public static function stringify( nog:Nog, pretty:Bool=true ):String
	{
		return stringifyNogObj(nog, pretty, "", true);
	}
	private static function stringifyNog( nog:Nog, pretty:Bool, leadingWhite:String ):String
	{
		return stringifyNogObj(nog, pretty, leadingWhite, true);
	}
	
	public static function toString( nog:Nog ):String
	{
		return stringifyNogObj(nog, false, "", false);
	}
	
	public static function nog(nogPos:NogPos):Nog {
		return nogPos;
	}
	public static function pos(nog:Nog, file:String, min:Int, max:Int, line:Int):NogPos {
		return nog;
	}
	
	#end
	
	
	public static function isOp( nogPos:NogPos ):Bool
	{
		switch(nog(nogPos)) {
			case Nog.Op(_, _, _): return true;
			default: return false;
		}
	}
	
	
	public static function getOp( nogPos:NogPos ):Null<String>
	{
		switch(nog(nogPos)) {
			case Nog.Op(op, _, _): return op;
			default: return null;
		}
	}
	
	
	public static function isLabel( nogPos:NogPos ):Bool
	{
		switch(nog(nogPos)) {
			case Nog.Label(_, _, _): return true;
			default: return false;
		}
	}
	
	
	public static function getLabel( nogPos:NogPos ):Null<String>
	{
		switch(nog(nogPos)) {
			case Nog.Label(label, _, _): return label;
			default: return null;
		}
	}
	
	
	public static function isStr( nogPos:NogPos ):Bool
	{
		switch(nog(nogPos)) {
			case Nog.Str(_, _): return true;
			default: return false;
		}
	}
	
	
	public static function isBlock( nogPos:NogPos ):Bool
	{
		switch(nog(nogPos)) {
			case Nog.Block(_, _): return true;
			default: return false;
		}
	}
	
	
	public static function getForeBracket( bracket:String ):String
	{
		switch(bracket) {
			case Bracket.Square: return "[";
			case Bracket.Curly: return "{";
			case Bracket.Angle: return "<";
			case Bracket.Round: return "(";
		}
		throw "Unrecognised bracket";
	}
	public static function getAftBracket( bracket:String ):String
	{
		switch(bracket) {
			case Bracket.Square: return "]";
			case Bracket.Curly: return "}";
			case Bracket.Angle: return ">";
			case Bracket.Round: return ")";
		}
		throw "Unrecognised bracket";
	}
	
	
	public static function getForeQuote( quote:String ):String
	{
		switch(quote) {
			case Quote.Single: return "'";
			case Quote.Double: return '"';
			case Quote.Backtick: return "`";
		}
		throw "Unrecognised quote";
	}
	public static function getAftQuote( quote:String ):String
	{
		return getForeQuote(quote);
	}
	
	
	private static function stringifyNogObj( nog:Nog, pretty:Bool, leadingWhite:String, deep:Bool ):String
	{
		switch(nog) {
			case Nog.Block(bracket, children):
				var ret = getForeBracket(bracket);
				
				if(deep){
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
				}
				ret += getAftBracket(bracket);
				
				return ret;
				
			case Nog.Comment(comment):
				return "#"+comment;
				
			case Nog.CommentMulti(comment):
				return "##"+comment+"##";
				
			case Nog.Label(label, child1, child2):
				var ret = label;
				if(deep){
					if (child1 != null) {
						if (pretty) ret += STRINGIFY_SPACE;
						ret += stringifyNog(child1, pretty, leadingWhite);
					}
					if (child2 != null) {
						if (pretty) ret += STRINGIFY_SPACE;
						ret += stringifyNog(child2, pretty, leadingWhite);
					}
				}
				return ret;
				
			case Nog.Op(op, child1, child2):
				var ret = op;
				if(deep){
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
				}
				return ret;
				
			case Nog.Str(quote, string):
				return getForeQuote(quote) + string + getAftQuote(quote);
				
			case Nog.Int(value, hex):
				if (hex) {
					return "0x"+StringTools.hex(value);
				}else {
					return "" + value;
				}
				
			case Nog.Float(value):
				return "" + value;
				
		}
	}
	
	static public function error(nogPos:Nog.NogPos, str:String, ?pos2:PosInfos) {
		#if macro
			haxe.macro.Context.error(str, haxe.macro.Context.makePosition( { file:nogPos.file, min:nogPos.min, max:nogPos.max } ) );
			
		#elseif nogpos 
			//throw str;
			var pos:PosInfos = { methodName:"", lineNumber:nogPos.line, fileName:nogPos.file, customParams:null, className:"" };
			haxe.Log.trace(str, pos);
		#else
			//throw str;
			haxe.Log.trace(str, pos2);
		#end
	}
	
	static private function containsBlock(nogPos:NogPos) : Bool
	{
		switch(NogUtils.nog(nogPos)) {
			case Nog.CommentMulti(_) | Nog.Comment(_):
				return true;
				
			case Nog.Str(_, _) | Nog.Int(_) | Nog.Float(_):
				return false;
				
			case Nog.Block(_, children):
				return children.length > 0;
				
			case Nog.Op(_, child1, child2) | Nog.Label(_, child1, child2):
				return (child1 != null && containsBlock(child1)) || (child2 != null && containsBlock(child2));
		}
	}
}