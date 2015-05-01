package nog.lang;
import haxe.PosInfos;
import nog.lang.LangDef.TokenDef;
import nog.lang.LangDef.TokenPos;
import nog.Nog;

class LangUtils
{

	#if (nogpos || macro)
	
	public static function token(tokenPos:TokenPos):TokenDef {
		return tokenPos.tokenRef;
	}
	/*public static function pos(token:TokenDef, file:String, min:Int, max:Int, line:Int):TokenPos {
		return { tokenRef:token, file:file, min:min, max:max, line:line };
	}*/
	public static function nogPos(token:TokenDef, nog:NogPos):TokenPos {
		return { tokenRef:token, file:nog.file, min:nog.min, max:nog.max, line:nog.line };
	}
	
	#else
	
	public static function token(tokenPos:TokenPos):TokenDef {
		return tokenPos;
	}
	public static function pos(token:TokenDef, min:Int, max:Int, file:String):TokenPos {
		return token;
	}
	public static function nogPos(token:TokenDef, nog:NogPos):TokenPos {
		return token;
	}
	
	#end
	
	public static function getReader<T>(langDef:LangDef):ILangReader<T> {
		var readerType = Type.resolveClass(langDef.readerType);
		if (readerType == null) {
			err(langDef, "Couldn't find reader class");
		}
		return cast Type.createInstance(readerType, []);
	}
	
	public static function resolveRefs(langDef:LangDef):Void {
		var map:Map<String, TokenPos> = new Map();
		for (ref in langDef.symbols) {
			map.set(ref.name, ref.value);
		}
		for (tokenPos in langDef.rootDefs) {
			resolveRef(tokenPos, map);
		}
		for (ref in langDef.symbols) {
			resolveRef(ref.value, map);
		}
	}
	
	static function resolveRef(tokenPos:TokenPos, map:Map<String, TokenPos>) 
	{
		switch(LangUtils.token(tokenPos)) {
			case TokenDef.Ref(id, pointer, next):
				if (pointer.value == null) {
					if (!map.exists(id)) {
						doErr(tokenPos, "Unrecognised reference token: "+id);
					}else{
						pointer.value = map.get(id);
					}
				}
				if (next != null) resolveRef(next, map);
				
			case LiteralBlock(_, children):
				for (child in children) {
					resolveRef(child, map);
				}
				
			case TokenDef.Alternate(children, next):
				for (child in children) {
					resolveRef(child, map);
				}
				if (next != null) resolveRef(next, map);
				
			case Named(_, next):
				if (next != null) resolveRef(next, map);
				
			case TokenDef.Ident(_, child1, child2) | LiteralOp(_, child1, child2) | LiteralLabel(_, child1, child2) | Optional(child1, child2) | Multi(child1, _, _, child2):
				if (child1 != null) resolveRef(child1, map);
				if (child2 != null) resolveRef(child2, map);
				
			case LiteralStr(_, _) | Int | Float | String(_, _, _):
				// ignore
		}
	}
	
	public static function toString( tokenPos:TokenPos ):String
	{
		switch(LangUtils.token(tokenPos)) {
			case Ref(id, pointer, next):
				if (pointer.value == null) {
					return "Ref:" + id;
				}else {
					return toString(pointer.value);
				}
				
			case LiteralBlock(bracket, children):
				return NogUtils.getForeBracket(bracket) + NogUtils.getAftBracket(bracket);
				
			case Alternate(children, next):
				var tokens = "";
				for (i in 0...children.length) {
					var child = children[i];
					if (i != 0) {
						if (i < children.length - 1) tokens += ", ";
						else tokens += " or ";
					}
					tokens += toString(child);
				}
				return tokens;
				
			case Ident(ident, next1, next2):
				return ident+" identifier";
				
			case Named(name, next):
				return name+" token";
				
			case LiteralOp(op, next1, next2) :
				return op;
				
			case LiteralLabel(label, next1, next2) :
				return label;
				
			case LiteralStr(quote, str):
				return quote + str + quote;
			
			case Int:
				return "an Int";
			
			case Float:
				return "a Float";
			
			case TokenDef.String(acceptSingle, acceptDouble, acceptBacktick):
				return "a String";
				
			case Optional(child1, child2):
				return "an optional " + toString(child1);
				
			case Multi(child1, min, max, child2):
				if (min > 0) {
					if (max > 0) {
						return "Between "+min+" and "+max+" " + toString(child1);
					}else {
						return "At least "+min+" " + toString(child1);
					}
				}else if (max > 0) {
					return "At most "+max+" " + toString(child1);
				}else {
					return "Multiple " + toString(child1);
				}
		}
	}
	
	static function doErr(tokenPos:TokenPos, str:String, ?pos2:PosInfos) {
		#if macro
			haxe.macro.Context.error(str, haxe.macro.Context.makePosition({ file:tokenPos.file, min:tokenPos.min, max:tokenPos.max }) );
		#elseif nogpos
			var pos:PosInfos = { methodName:"", lineNumber:tokenPos.line, fileName:tokenPos.file, customParams:null, className:"" };
			haxe.Log.trace(str, pos);
		#else
			haxe.Log.trace(str, pos2);
		#end
	}
	
	static function err(langDef:LangDef, str:String) {
		#if macro
			haxe.macro.Context.error(str, haxe.macro.Context.makePosition({ file:langDef.file, min:0, max:1 }) );
		#else
			var pos:PosInfos = { methodName:"", lineNumber:0, fileName:langDef.file, customParams:null, className:"" };
			haxe.Log.trace(str, pos);
		#end
	}
}