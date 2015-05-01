package nog;

import nog.Nog;
import nog.NogInterpreter.NogPending;
import stringParser.core.AbstractInterpreter;
import stringParser.core.StringParser;
import stringParser.core.StringParserIterator;
import stringParser.parsers.BracketPairParser;
import stringParser.parsers.ICharacterParser;
import stringParser.parsers.NameValuePairParser;
import stringParser.parsers.QuotedStringParser;
import stringParser.parsers.CharListParser;
import stringParser.parsers.WhitespaceParser;
import stringParser.parsers.NumberParser;

using nog.NogUtils;
using StringTools;

class NogInterpreter extends AbstractInterpreter
{
	public function getNog():Array<NogPos>{
		return _nogResult;
	}
	
	
	public static var nogConfig(get, null):Array<ICharacterParser>;
	private static function get_nogConfig():Array<ICharacterParser>{
		checkInit();
		return _nogConfig;
	}
	
	public static var operatorParser(get, null):CharListParser;
	private static function get_operatorParser():CharListParser{
		checkInit();
		return operatorParser;
	}
	public static var labelParser(get, null):CharListParser;
	private static function get_labelParser():CharListParser{
		checkInit();
		return labelParser;
	}
	public static var numberParser(get, null):NumberParser;
	private static function get_numberParser():NumberParser{
		checkInit();
		return numberParser;
	}
	public static var hexParser(get, null):NumberParser;
	private static function get_hexParser():NumberParser{
		checkInit();
		return hexParser;
	}
	public static var stringSingleParser(get, null):QuotedStringParser;
	private static function get_stringSingleParser():QuotedStringParser{
		checkInit();
		return stringSingleParser;
	}
	public static var stringDoubleParser(get, null):QuotedStringParser;
	private static function get_stringDoubleParser():QuotedStringParser{
		checkInit();
		return stringDoubleParser;
	}
	public static var stringBacktickParser(get, null):QuotedStringParser;
	private static function get_stringBacktickParser():QuotedStringParser{
		checkInit();
		return stringBacktickParser;
	}
	public static var curlyBlockParser(get, null):BracketPairParser;
	private static function get_curlyBlockParser():BracketPairParser{
		checkInit();
		return curlyBlockParser;
	}
	public static var squareBlockParser(get, null):BracketPairParser;
	private static function get_squareBlockParser():BracketPairParser{
		checkInit();
		return squareBlockParser;
	}
	public static var angleBlockParser(get, null):BracketPairParser;
	private static function get_angleBlockParser():BracketPairParser{
		checkInit();
		return angleBlockParser;
	}
	public static var roundBlockParser(get, null):BracketPairParser;
	private static function get_roundBlockParser():BracketPairParser{
		checkInit();
		return roundBlockParser;
	}
	public static var commentSingleParser(get, null):QuotedStringParser;
	private static function get_commentSingleParser():QuotedStringParser{
		checkInit();
		return commentSingleParser;
	}
	public static var commentMultiParser(get, null):QuotedStringParser;
	private static function get_commentMultiParser():QuotedStringParser{
		checkInit();
		return commentMultiParser;
	}
	public static var lineEndingParser(get, null):CharListParser;
	private static function get_lineEndingParser():CharListParser{
		checkInit();
		return lineEndingParser;
	}

	private static function checkInit():Void{
		if(_nogConfig==null){
			_nogConfig = [];
			_nogConfig.push(WhitespaceParser.instance);
			
			var spaceParser = new WhitespaceParser([" "]);
			
			var blockChildParsers:Array<ICharacterParser> = [];
			
			hexParser = new NumberParser(true);
			blockChildParsers.push(hexParser);
			_nogConfig.push(hexParser);
			
			numberParser = new NumberParser(false);
			blockChildParsers.push(numberParser);
			_nogConfig.push(numberParser);
			
			operatorParser = new CharListParser(["+", "-", "=", "*", "$", "*", ".", ",", "?", "!", "/", "\\", "@", "~", "|", "^", "%", "&", ":"], 2, [";", "\n", "\r"]);
			operatorParser.childParsers = [];
			operatorParser.finishedParsers = [spaceParser];
			_nogConfig.push(operatorParser);
			blockChildParsers.push(operatorParser);
			operatorParser.childParsers.push(hexParser);
			operatorParser.childParsers.push(numberParser);
			operatorParser.childParsers.push(operatorParser);
			
			labelParser = new CharListParser(CharListParser.getCharRanges(true,true,true,["_", "."]), 2, [";", "\n", "\r"]);
			labelParser.childParsers = [];
			labelParser.finishedParsers = [spaceParser];
			_nogConfig.push(labelParser);
			blockChildParsers.push(labelParser);
			operatorParser.childParsers.push(labelParser);
			labelParser.childParsers.push(hexParser);
			labelParser.childParsers.push(numberParser);
			labelParser.childParsers.push(operatorParser);
			labelParser.childParsers.push(labelParser); // labels can follow labels
			
			stringSingleParser = new QuotedStringParser(["'"]);
			blockChildParsers.push(stringSingleParser);
			operatorParser.childParsers.push(stringSingleParser);
			
			stringDoubleParser = new QuotedStringParser(['"']);
			blockChildParsers.push(stringDoubleParser);
			operatorParser.childParsers.push(stringDoubleParser);
			
			stringBacktickParser = new QuotedStringParser(['`']);
			blockChildParsers.push(stringBacktickParser);
			operatorParser.childParsers.push(stringBacktickParser);
			
			commentMultiParser = new QuotedStringParser(['##']);
			_nogConfig.push(commentMultiParser);
			blockChildParsers.push(commentMultiParser);
			operatorParser.childParsers.push(commentMultiParser);
			
			commentSingleParser = new QuotedStringParser(['#'], ["\n", "\r"]);
			_nogConfig.push(commentSingleParser);
			blockChildParsers.push(commentSingleParser);
			operatorParser.childParsers.push(commentSingleParser);
			
			curlyBlockParser = new BracketPairParser("{","}",null,[";", "\n", "\r"]);
			_nogConfig.push(curlyBlockParser);
			operatorParser.childParsers.push(curlyBlockParser);
			labelParser.childParsers.push(curlyBlockParser);
			blockChildParsers.push(curlyBlockParser);
			
			squareBlockParser = new BracketPairParser("[","]",null,[";", "\n", "\r"]);
			_nogConfig.push(squareBlockParser);
			operatorParser.childParsers.push(squareBlockParser);
			labelParser.childParsers.push(squareBlockParser);
			blockChildParsers.push(squareBlockParser);
			
			angleBlockParser = new BracketPairParser("<",">",null,[";", "\n", "\r"]);
			_nogConfig.push(angleBlockParser);
			operatorParser.childParsers.push(angleBlockParser);
			labelParser.childParsers.push(angleBlockParser);
			blockChildParsers.push(angleBlockParser);
			
			roundBlockParser = new BracketPairParser("(",")",null,[";", "\n", "\r"]);
			_nogConfig.push(roundBlockParser);
			operatorParser.childParsers.push(roundBlockParser);
			labelParser.childParsers.push(roundBlockParser);
			blockChildParsers.push(roundBlockParser);
			
			curlyBlockParser.childParsers = blockChildParsers;
			squareBlockParser.childParsers = blockChildParsers;
			angleBlockParser.childParsers = blockChildParsers;
			roundBlockParser.childParsers = blockChildParsers;
			
			
			lineEndingParser = new CharListParser([";"]);
			_nogConfig.push(lineEndingParser);
		}
	}


	private static var _nogConfig:Array<ICharacterParser>;
	
	private var _pendingMap:Map<String, NogPending>;
	private var _pending:Array<NogPending>;
	private var _nogResult:Array<NogPos>;
	
	// Sets back-references in output objects (change the prop as you parse different sources)
	public var currentFilePath:String;


	public function new(inputString:String=null){
		super(inputString);
		_pendingMap = new Map<String, NogPending>();
	}
	
	override private function getParserConfig():Array<ICharacterParser>{
		return nogConfig;
	}
	
	override private function start():Void {
		_pending = [];
		_nogResult = [];
		_result = _nogResult;
	}

	override private function interpret(id:String, parentId:String, parser:ICharacterParser, strings:Dynamic):Void {
		if (parser == lineEndingParser) return;
		
		var value:Dynamic = null;
		
		var pending:NogPending = NogPending.take(id, parser, strings);
		_pendingMap.set(id, pending);
		
		pending.start = _stringParser.getStartIndex(id);
		pending.end = _stringParser.getEndIndex(id);
		pending.line = _stringParser.getLineIndex(id);
		
		if(parentId!=null){
			var parent:NogPending = _pendingMap.get(parentId);
			if (parent.childrenPending==null) parent.childrenPending = [];
			parent.childrenPending.push(pending);
			pending.parent = parent;
			
			while (!ancestorTest(parent, _pending[_pending.length-1])) {
				convertPending(_pending.pop());
			}
		}
		_pending.push(pending);
	}


	override private function finish():Void{
		while (_pending.length > 0) {
			convertPending(_pending.pop());
		}
		_pending = [];
	}
	
	function ancestorTest(parent:NogPending, ancestor:NogPending) 
	{
		while (parent!=null) {
			if (parent == ancestor) return true;
			parent = parent.parent;
		}
		return false;
	}
	
	function convertPending(pending:NogPending) {
		var nogObj:Nog = null;
		
		if (pending.parser == operatorParser) {
			var str = (pending.strings!=null ? StringTools.trim(pending.strings) : null);
			nogObj = Nog.Op(str, getChild(pending), getChild(pending, 1));
			
		}else if (pending.parser == numberParser) {
			var str:String = cast pending.strings;
			if(str.indexOf(".")==-1){
				nogObj = Nog.Int(Std.parseInt(str), false);
			}else {
				nogObj = Nog.Float(Std.parseFloat(str));
			}
			
		}else if (pending.parser == hexParser) {
			var str:String = cast pending.strings;
			nogObj = Nog.Int(Std.parseInt(str), true);
			
		}else if (pending.parser == labelParser) {
			var str = (pending.strings!=null ? StringTools.trim(pending.strings) : null);
			nogObj = Nog.Label(str, getChild(pending), getChild(pending, 1));
			
		}else if (pending.parser == stringSingleParser) {
			nogObj = Nog.Str(Quote.Single, pending.strings);
			
		}else if (pending.parser == stringDoubleParser) {
			nogObj = Nog.Str(Quote.Double, pending.strings);
			
		}else if (pending.parser == stringBacktickParser) {
			nogObj = Nog.Str(Quote.Backtick, pending.strings);
			
		}else if (pending.parser == commentSingleParser) {
			nogObj = Nog.Comment(pending.strings);
			
		}else if (pending.parser == commentMultiParser) {
			nogObj = Nog.CommentMulti(pending.strings);
			
		}else if (pending.parser == curlyBlockParser) {
			nogObj = Nog.Block(Bracket.Curly, pending.childrenNog!=null ? pending.childrenNog : [] );
			
		}else if (pending.parser == squareBlockParser) {
			nogObj = Nog.Block(Bracket.Square,  pending.childrenNog!=null ? pending.childrenNog : []);
			
		}else if (pending.parser == roundBlockParser) {
			nogObj = Nog.Block(Bracket.Round,  pending.childrenNog!=null ? pending.childrenNog : []);
			
		}else if (pending.parser == angleBlockParser) {
			nogObj = Nog.Block(Bracket.Angle,  pending.childrenNog!=null ? pending.childrenNog : []);
			
		}else {
			throw "Something went very wrong";
		}
		
		
		var nogPos = nogObj.pos(currentFilePath, pending.start, pending.end, pending.line);
		
		if (pending.parent==null) {
			_nogResult.unshift(nogPos);
		}else {
			if (pending.parent.childrenNog == null) pending.parent.childrenNog = [];
			pending.parent.childrenNog.push(nogPos);
		}
		_pendingMap.remove(pending.id);
		NogPending.ret(pending);
	}
	
	function charList(str:String, chars:Array<String>) :Bool
	{
		var char = 0;
		var l = str.length;
		if(l==0)return false;
		while (char < l) {
			if (chars.indexOf(str.charAt(char) ) == -1) return false;
			char++;
		}
		return true;
	}
	inline function getChild(pending:NogPending, index:Int=0):NogPos{
		return pending.childrenNog == null || pending.childrenNog.length<=index ? null : pending.childrenNog[index];
	}
}
class NogPending {
	
	private static var _pool:Array<NogPending> = [];
	
	public static function take(id:String, parser:ICharacterParser, strings:Dynamic) {
		var ret:NogPending;
		if (_pool.length > 0) {
			ret = _pool.pop();
		}else {
			ret = new NogPending();
		}
		ret.id = id;
		ret.parser = parser;
		ret.strings = strings;
		return ret;
	}
	
	public static function ret(nogPending:NogPending) {
		nogPending.parser = null;
		nogPending.strings = null;
		nogPending.childrenPending = null;
		nogPending.childrenNog = null;
		nogPending.parent = null;
		_pool.push(nogPending);
	}
	
	public var id:String;
	public var parser:ICharacterParser;
	public var strings:Dynamic;
	public var childrenPending:Array<NogPending>;
	public var childrenNog:Array<NogPos>;
	public var parent:NogPending;
	
	public var start:Int;
	public var end:Int;
	public var line:Int;
	
	public function new() {
		
	}
	
}