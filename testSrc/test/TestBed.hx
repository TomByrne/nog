package test;

import flash.display.Sprite;
import flash.events.Event;
import flash.events.TimerEvent;
import flash.utils.ByteArray;
import flash.utils.Timer;
import nog.Nog;
import nog.NogInterpreter;
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
		var tester:FileStringParserTester<Array<NogPos>> = new FileStringParserTester("NOG", new NogInterpreter());
		tester.addTest(new CommentSingle1().toString(), test.bind([p(0,9,0, Nog.Comment(" comment"))], _, _), false);
		tester.addTest(new CommentMulti1().toString(), test.bind([p(0,22,0,Nog.CommentMulti(" comment\r\nmulti \r\n"))], _, _), false);
		tester.addTest(new SimpleOp1().toString(), test.bind([p(0,1,0,Nog.Op("+", p(1,7,0,Nog.Label("plusOp"))))], _, _), false);
		tester.addTest(new SimpleOp2().toString(), test.bind([p(0,1,0,Nog.Op(".", p(1,7,0,Nog.Label("dotOp", p(7,10,0,Nog.Op("+=", p(10,11,0,Nog.Op("*", p(11,17,0,Nog.Label("starOp"))))))))))], _, _), false);
		tester.addTest(new SimpleBlock1().toString(), test.bind([p(0,23,0,Nog.Block(Bracket.Curly, [p(4,9,0,Nog.Label("label", p(9,11,0,Nog.Op(":", p(11,19,0,Nog.Str(Quote.Double, "String"))))))]))], _, _), false);
		tester.addTest(new SimpleBlock2().toString(), test.bind([p(0,29,0,Nog.Block(Bracket.Angle, [p(4,10,0,Nog.Str(Quote.Double,"Str1")), p(11,20,0,Nog.Str(Quote.Single,"Str2")), p(20,29,0,Nog.Str(Quote.Backtick,"Str3"))]))], _, _), false);
		tester.addTest(new SimpleBlock3().toString(), test.bind([Nog.Block(Bracket.Curly, [Nog.Op('$',Nog.Label("Int")), Nog.Op('$',Nog.Label("Float")), Nog.Op('$',Nog.Label("String"))])], _, _), false);
		tester.addTest(new MultipleExpr1().toString(), test.bind([p(0,6,0,Nog.Label("label", p(6,8,0,Nog.Op("=", p(8,18,0,Nog.Str(Quote.Double, "String")))))), p(18,19,0,Nog.Op("!", p(19,23,0,Nog.Label("bang", p(23,24,0,Nog.Op(":", p(24,29,0,Nog.Label("colon"))))))))], _, _), false);
		tester.addTest(new MultipleExpr2().toString(), test.bind([Nog.Comment(" single line comment +-=:;"), Nog.Op("+", Nog.Label("plusOp", Nog.Op("=", Nog.Str(Quote.Double, "String")))), Nog.Op("-", Nog.Label("minusOp", Nog.Block(Bracket.Curly, [Nog.Op("!", Nog.Label("bangOp"))])))], _, _), false);
		tester.addTest(new ExprIfStatement().toString(), test.bind([Nog.Label("if", Nog.Block(Bracket.Round, [Nog.Label("expr1")]), Nog.Block(Bracket.Curly, [Nog.Label("expr2")]))], _, _), false);
		tester.addTest(new Literals1().toString(), test.bind([Nog.Int(12, false), Nog.Float(12.5), Nog.Int(-12, false), Nog.Float(-12.5), Nog.Int(16, true)], _, _), false);
		tester.running = true;
	}
	
	function p(min:Int, max:Int, line:Int, nog:Nog) {
		#if nogpos
		return { file:null, min:min, max:max, line:line, nogRef:nog };
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
@:file("../testDocs/literals1.txt") class Literals1 extends ByteArray{}