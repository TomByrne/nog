package test;

import flash.display.Sprite;
import flash.events.Event;
import flash.events.TimerEvent;
import flash.utils.ByteArray;
import flash.utils.Timer;
import nog.lang.LangDef;
import nog.lang.LangDefInterpreter;
import nog.lang.LangInterpreter;
import nog.lang.LangMacro;
import stringParser.test.*;
import haxe.macro.Expr;

using nog.NogUtils;
using nog.lang.LangUtils;

class TestLangParse extends Sprite
{
	
	public static function main():Void {
		new TestLangParse();
	}
	
	public function new()
	{
		super();
		
		// This helps with issues with the FD debugger
		var timer = new Timer(500, 1);
		timer.addEventListener(TimerEvent.TIMER, onTimer);
		timer.start();
	}
	function onTimer(e:Event):Void {
		//var langDef:LangDef = LangMacro.getLang("../examples/LanguageDef.nog");
		//LangMacro.addLang("../examples/LanguageDef.nog");
		//LangMacro.addCodeFile("../examples/ComposureDef.nld");
		
		/*var langStr = new LanguageDef().toString();
		var langDefInterp = new LangDefInterpreter(langStr);
		langDefInterp.currentFilePath = "../examples/LanguageDef.nld";
		var iterator = langDefInterp.getIterator();
		iterator.iterateSynchronous();
		var langDef:LangDef = langDefInterp.getLangDef();*/
		
		/*var langInterp = new LangInterpreter(langDef, new ComposureDef().toString());
		langInterp.currentFilePath = "../examples/ComposureDef.cel";
		var iterator = langInterp.getIterator();
		iterator.iterateSynchronous();
		var modules = langInterp.getModules();
		modules;*/
		
		//  --- AS3 ---
		
		/*var langStr = new As3Def().toString();
		var langDefInterp = new LangDefInterpreter(langStr);
		langDefInterp.currentFilePath = "../testDocs/lang/AS3.nld";
		var iterator = langDefInterp.getIterator();
		iterator.iterateSynchronous();
		var langDef:LangDef = langDefInterp.getLangDef();*/
		
		var langDef:LangDef = LangMacro.getLang("../testDocs/lang/AS3.nld");
		langDef.resolveRefs();
		var langInterp = new LangInterpreter<Array<TypeDefinition>>(langDef, new AS3Lang().toString());
		langInterp.currentFilePath = "../testDocs/lang/AS3.as";
		var iterator = langInterp.getIterator();
		iterator.iterateSynchronous();
		var modules = langInterp.getResult();
		
		/*LangMacro.addLang("../testDocs/lang/AS3.nld");
		LangMacro.addCodeFile("../testDocs/lang/AS3.as");*/
	}
}

@:file("../examples/LanguageDef.nld") class LanguageDef extends ByteArray{}
@:file("../examples/ComposureDef.cel") class ComposureDef extends ByteArray{}

@:file("../testDocs/lang/AS3.nld") class As3Def extends ByteArray{}
@:file("../testDocs/lang/AS3.as") class AS3Lang extends ByteArray{}