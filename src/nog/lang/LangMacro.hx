package nog.lang;

#if macro
import sys.io.File;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import nog.lang.ClassReader;
#end

class LangMacro
{

	static private var extMap:Map<String, LangDef> = new Map();
	
	#if nogpos
	macro static public function getLang(url:String, add:Bool=false) : Expr 
	{
		var langDefStr = File.getContent( url );
		var langDef = genLangDefNow(langDefStr, url, false);
		if (add) {
			addLangDef(langDef);
		}
		return macro $v{langDef};
	}
	#end

	macro static public function addLang(url:String) : Expr 
	{
		var langDefStr = File.getContent( url );
		var langDef = genLangDefNow(langDefStr, url, true);
		addLangDef(langDef);
		return macro null;
	}
	
	macro static public function addCodeFile(url:Expr, ?forceFileExt:Expr) 
	{
		var urlStr = getString(url);
		var codeStr = File.getContent( urlStr );
		var forceExtStr = getString( forceFileExt, true );
		var fileExt = (forceExtStr == null ? haxe.io.Path.extension(urlStr) : forceExtStr);
		if (!extMap.exists(fileExt)) {
			Context.error("Language couldn't be detected. Use file extensions or explicitly specify.", url.pos );
			
		}else if (!extMap.exists(fileExt)) {
			var p:Position = ( forceFileExt == null ? forceFileExt.pos : url.pos);
			Context.error("Language hasn't been defined, '"+fileExt+"'", p );
		}
		var langDef = extMap.get(fileExt);
		genCodeModules(langDef, codeStr, urlStr);
		return macro null;
	}
	
	#if macro
	
	static public function getString(strExpr:Expr, optional:Bool=false) : String 
	{
		switch(strExpr.expr) {
			case EConst(c):
				switch(c){
					case CString(strExpr): return strExpr;
					case CIdent(ident):
						if(optional && ident=="null")return null;
					default:
				}
			default:
		}
		Context.error("Value should be a string.", strExpr.pos );
		return null;
	}
	
	#else
	
	#end
	
	static public function addLangDef(langDef:LangDef) : Void 
	{
		extMap.set(langDef.fileExt, langDef);
		trace("Registering Language: '"+langDef.name+"' (file ext ."+langDef.fileExt+")");
	}
	
	
	static public function genLangDefNow(langDef:String, ?langDefUrl:String, resolveRefs:Bool=true) : LangDef 
	{
		var langDefInterp = new LangDefInterpreter(langDef, resolveRefs);
		langDefInterp.currentFilePath = langDefUrl;
		var iterator = langDefInterp.getIterator();
		iterator.iterateSynchronous();
		return langDefInterp.getLangDef();
	}
	
	
	static public function genCodeModules<T>(langDef:LangDef, code:String, ?codeUrl:String) : T
	{
		var langInterp = new LangInterpreter(langDef, code);
		langInterp.currentFilePath = codeUrl;
		var iterator = langInterp.getIterator();
		iterator.iterateSynchronous();
		return langInterp.getResult();
	}
}