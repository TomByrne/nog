package test;

import flash.display.Sprite;
import flash.events.Event;
import flash.events.TimerEvent;
import flash.utils.Timer;
import nog.lang.LangDef;
import nog.lang.LangDefInterpretter;
import nog.lang.LangInterpretter;
import nog.lang.LangMacro;
import nog.NogInterpretter;
import stringParser.core.StringParser;
import stringParser.core.StringParserIterator;
import flash.utils.ByteArray;
import nog.Nog;
import stringParser.test.*;

using nog.NogUtils;

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
		//var langDef:LangDef = LangMacro.getLangDef("../examples/LanguageDef.nog");
		
		var langDefInterp = new LangDefInterpretter(new LanguageDef().toString());
		langDefInterp.currentFilePath = "../examples/LanguageDef.nog";
		var iterator = langDefInterp.getIterator();
		iterator.iterateSynchronous();
		var langDef:LangDef = langDefInterp.getLangDef();
		var testlangDef = langDef;
		
	}
}

@:file("../examples/LanguageDef.nog") class LanguageDef extends ByteArray{}
@:file("../examples/ComposureDef.nog") class ComposureDef extends ByteArray{}