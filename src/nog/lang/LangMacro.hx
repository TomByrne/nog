package nog.lang;
import haxe.macro.Expr;

#if macro
import sys.io.File;
#end

class LangMacro
{

	/*macro public function read(code:String, langDef:String) : Lang 
	{
		
	}*/

	macro static public function getLangDef(url:String) : Expr 
	{
		var langDefStr = File.getContent( url );
		var langDef = genLangDefNow(langDefStr, url);
		return macro $v{langDef};
	}
	
	#if macro
	
	#else
	
	#end
	
	
	
	static public function genLangDefNow(langDef:String, ?langDefUrl:String) : LangDef 
	{
		var langDefInterp = new LangDefInterpreter(langDef);
		langDefInterp.currentFilePath = langDefUrl;
		var iterator = langDefInterp.getIterator();
		iterator.iterateSynchronous();
		return langDefInterp.getLangDef();
	}
}