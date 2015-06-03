package nog;

import haxe.macro.Context;
import haxe.macro.Expr.Position;
import haxe.PosInfos;
import nog.Nog;

class NogUtils
{
	public static var STRINGIFY_TAB:String = "\t";
	public static var STRINGIFY_NEWLINE:String = "\n";
	public static var STRINGIFY_SPACE:String = " ";
	public static var STRINGIFY_LINEEND:String = ";";
	
	public static function position(nogPos:NogPos):Position {
		#if macro
			return haxe.macro.Context.makePosition( { file:nogPos.file, min:nogPos.min, max:nogPos.max } );
		#else
			return { file:nogPos.file, min:nogPos.min, max:nogPos.max };
		#end
	}
	
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
			case Nog.Op(_, _): return true;
			default: return false;
		}
	}
	
	
	public static function getOp( nogPos:NogPos ):Null<String>
	{
		switch(nog(nogPos)) {
			case Nog.Op(op, _): return op;
			default: return null;
		}
	}
	
	
	public static function isLabel( nogPos:NogPos ):Bool
	{
		switch(nog(nogPos)) {
			case Nog.Label(_, _): return true;
			default: return false;
		}
	}
	
	
	public static function getLabel( nogPos:NogPos ):Null<String>
	{
		switch(nog(nogPos)) {
			case Nog.Label(label, _): return label;
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
			case Nog.Block(bracket, children, next, blockBreak):
				var ret = getForeBracket(bracket);
				
				if(deep){
					var childWhite = (pretty ? leadingWhite + STRINGIFY_TAB : leadingWhite );
					var breakChar;
					var prePostChar = "";
					var childStrs = [];
					var addNewline = false;
					var searchChildren = (blockBreak == null && pretty);
					for (child in children) {
						var childStr = stringifyNog(child, pretty, childWhite);
						childStrs.push(childStr);
						if (searchChildren && (childStr.indexOf(STRINGIFY_NEWLINE) != -1 || containsBlock(child))){
							addNewline = true;
							searchChildren = false;
						}
					}
					if (blockBreak == null) {
						if(pretty && addNewline){
							breakChar = STRINGIFY_NEWLINE;
							prePostChar = STRINGIFY_NEWLINE;
						}else {
							breakChar = STRINGIFY_LINEEND;
							childWhite = "";
						}
					}else {
						if (blockBreak == BlockBreak.SemiColon) {
							childWhite = "";
						}else {
							prePostChar = blockBreak;
						}
						breakChar = blockBreak;
					}
					/*var newLine = (pretty ? STRINGIFY_NEWLINE : "");
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
					}*/
					ret += prePostChar;
					for (i in 0...childStrs.length) {
						var childStr = childStrs[i];
						ret += childWhite + childStr;
						if (childStrs.length > 1 && i<childStrs.length-1) {
							ret += breakChar;
						}
					}
					ret += prePostChar;
				}
				ret += getAftBracket(bracket);
				
				if (deep && next != null) {
					ret += stringifyNog( next, pretty, leadingWhite );
				}
				
				return ret;
				
			case Nog.Comment(comment):
				return "//"+comment;
				
			case Nog.CommentMulti(comment, next):
				var ret = "/*"+comment+"*/";
				if (deep && next != null) {
					ret += stringifyNog( next, pretty, leadingWhite );
				}
				return ret;
				
			case Nog.Label(label, next):
				var ret = label;
				if(deep){
					if (next != null) {
						switch(NogUtils.nog(next)) {
							case Nog.Label(_, _):
								if (pretty) ret += STRINGIFY_SPACE;
							default:
						}
						ret += stringifyNog(next, pretty, leadingWhite);
					}
				}
				return ret;
				
			case Nog.Op(op, next):
				var ret = op;
				if(deep){
					if (next != null) {
						if (pretty) {
							switch(NogUtils.nog(next)) {
								case Nog.Op(_, _) | Nog.Str(_):
									ret += STRINGIFY_SPACE;
								default:
							}
						}
						ret += stringifyNog(next, pretty, leadingWhite);
					}
				}
				return ret;
				
			case Nog.Str(quote, string, next):
				var ret = getForeQuote(quote) + string + getAftQuote(quote);
				if (deep && next != null) {
					ret += stringifyNog( next, pretty, leadingWhite );
				}
				return ret;
				
			case Nog.Int(value, hex, next):
				var ret;
				if (hex) {
					ret = "0x"+StringTools.hex(value);
				}else {
					ret = "" + value;
				}
				if (deep && next != null) {
					ret += stringifyNog( next, pretty, leadingWhite );
				}
				return ret;
				
			case Nog.Float(value, next):
				var ret = "" + value;
				if (deep && next != null) {
					ret += stringifyNog( next, pretty, leadingWhite );
				}
				return ret;
				
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
			case Nog.CommentMulti(_, _) | Nog.Comment(_):
				return true;
				
			case Nog.Block(_, children, next, blockBreak):
				if ((children.length > 1 && blockBreak != BlockBreak.SemiColon) || (next != null && containsBlock(next))) {
					return true;
				}else {
					for (child in children) {
						if (containsBlock(child)) {
							return true;
						}
					}
					return false;
				}
				
			case Nog.Str(_, _, next) | Nog.Int(_, _, next) | Nog.Float(_, next) | Nog.Op(_, next) | Nog.Label(_, next):
				return (next != null && containsBlock(next));
		}
	}
	
	public static function followPropPath(nogPos:NogPos, separator:String=".") : FieldPath
	{
		
		var ret = { fields:[], next:nogPos };
		
		while(true){
			switch(NogUtils.nog(nogPos)) {
				case Nog.Label(label, next):
					ret.fields.push(label);
					ret.next = next;
					if (next==null) return ret;
					
					switch(NogUtils.nog(next)) {
						case Nog.Op(sep, next2):
							if (sep != separator) {
								return ret;
							}
							if (next2 == null) {
								NogUtils.error(nogPos, "Should be a label following");
								return null;
							}
							// all ok
							nogPos = next2;
						default:
							return ret;
					}
				default:
					NogUtils.error(nogPos, "Should be a label");
					return null;
			}
		}
	}
}
typedef FieldPath = {
	var fields:Array<String>;
	var next:NogPos;
}