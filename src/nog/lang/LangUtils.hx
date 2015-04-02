package nog.lang;
import nog.lang.LangDef.TokenDef;
import nog.lang.LangDef.TokenPos;

class LangUtils
{

	#if (nogpos || macro)
	
	public static function token(tokenPos:TokenPos):TokenDef {
		return tokenPos.tokenRef;
	}
	public static function pos(token:TokenDef, min:Int, max:Int, file:String):TokenPos {
		return { tokenRef:token, min:min, max:max, file:file };
	}
	
	#else
	
	public static function token(tokenPos:TokenPos):TokenDef {
		return tokenPos;
	}
	public static function pos(token:TokenDef, min:Int, max:Int, file:String):TokenPos {
		return token;
	}
	
	#end
}