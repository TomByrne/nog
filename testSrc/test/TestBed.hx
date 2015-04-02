package test;

import flash.display.Sprite;
import flash.events.Event;
import flash.events.TimerEvent;
import flash.utils.Timer;
import nog.NogInterpretter;
import stringParser.core.StringParser;
import stringParser.core.StringParserIterator;
import flash.utils.ByteArray;
import nog.Nog;
import stringParser.test.*;

using nog.NogUtils;

class TestBed extends Sprite
{
	
	public static function main():Void {
		new TestBed();
	}
	
	public function new()
	{
		super();
		
		// This helps with issues with the FD debugger
		var timer = new Timer(500, 1);
		timer.addEventListener(TimerEvent.TIMER, onTimer);
		timer.start();
	}
	function onTimer(e:Event):Void{
		var tester:FileStringParserTester<Array<NogPos>> = new FileStringParserTester("NOG", new NogInterpretter());
		tester.addTest(new CommentSingle1().toString(), test.bind([p(0,9,Nog.Comment(" comment"))], _, _), false);
		tester.addTest(new CommentMulti1().toString(), test.bind([p(0,22,Nog.CommentMulti(" comment\r\nmulti \r\n"))], _, _), false);
		tester.addTest(new SimpleOp1().toString(), test.bind([p(0,1,Nog.Op("+", p(1,7,Nog.Label("plusOp"))))], _, _), false);
		tester.addTest(new SimpleOp2().toString(), test.bind([p(0,1,Nog.Op(".", p(1,7,Nog.Label("dotOp", p(7,10,Nog.Op("+=", p(10,11,Nog.Op("*", p(11,17,Nog.Label("starOp"))))))))))], _, _), false);
		tester.addTest(new SimpleBlock1().toString(), test.bind([p(0,23,Nog.Block("{", [p(4,9,Nog.Label("label", p(9,11,Nog.Op(":", p(11,19,Nog.Str('"', "String"))))))]))], _, _), false);
		tester.addTest(new SimpleBlock2().toString(), test.bind([p(0,29,Nog.Block("<", [p(4,10,Nog.Str('"',"Str1")), p(11,20,Nog.Str("'","Str2")), p(20,29,Nog.Str('`',"Str3"))]))], _, _), false);
		tester.addTest(new SimpleBlock3().toString(), test.bind([Nog.Block("{", [Nog.Op('$',Nog.Label("Int")), Nog.Op('$',Nog.Label("Float")), Nog.Op('$',Nog.Label("String"))])], _, _), false);
		tester.addTest(new MultipleExpr1().toString(), test.bind([p(0,6,Nog.Label("label", p(6,8,Nog.Op("=", p(8,18,Nog.Str('"', "String")))))), p(18,19,Nog.Op("!", p(19,23,Nog.Label("bang", p(23,24,Nog.Op(":", p(24,29,Nog.Label("colon"))))))))], _, _), false);
		tester.addTest(new MultipleExpr2().toString(), test.bind([Nog.Comment(" single line comment +-=:;"), Nog.Op("+", Nog.Label("plusOp", Nog.Op("=", Nog.Str('"', "String")))), Nog.Op("-", Nog.Label("minusOp", Nog.Block("{", [Nog.Op("!", Nog.Label("bangOp"))])))], _, _), false);
		tester.addTest(new ExprIfStatement().toString(), test.bind([Nog.Label("if", Nog.Block("(", [Nog.Label("expr1")])), Nog.Block("{", [Nog.Label("expr2")])], _, _), false);
		tester.running = true;
	}
	
	function p(start:Int, end:Int, nog:Nog) {
		#if nogpos
		return { start:start, end:end, nog:nog };
		#else
		return nog;
		#end
	}
	
	private function test(match:Array<NogPos>, result:Array<NogPos>, string:String):Bool {
		if (!ObjectsEqual.equal(result, match)) {
			var debug = "\rExpected: ";
			for (nPos in match) {
				debug += "\r"+nPos.stringify();
			}
			debug += "\rGot: ";
			for (nPos in result) {
				debug += "\r"+nPos.stringify();
			}
			trace(debug);
			return false;
		}
		return true;
	}
}

@:file("../testDocs/commentSingle1.txt") class CommentSingle1 extends ByteArray{}
@:file("../testDocs/commentMulti1.txt") class CommentMulti1 extends ByteArray{}
@:file("../testDocs/simpleOp1.txt") class SimpleOp1 extends ByteArray{}
@:file("../testDocs/simpleOp2.txt") class SimpleOp2 extends ByteArray{}
@:file("../testDocs/simpleBlock1.txt") class SimpleBlock1 extends ByteArray{}
@:file("../testDocs/simpleBlock2.txt") class SimpleBlock2 extends ByteArray{}
@:file("../testDocs/simpleBlock3.txt") class SimpleBlock3 extends ByteArray{}
@:file("../testDocs/multipleExpr1.txt") class MultipleExpr1 extends ByteArray { }
@:file("../testDocs/multipleExpr2.txt") class MultipleExpr2 extends ByteArray{}
@:file("../testDocs/exprIfStatement.txt") class ExprIfStatement extends ByteArray{}