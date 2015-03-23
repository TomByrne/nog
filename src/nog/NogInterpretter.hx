package nog;

import flash.errors.Error;
import nog.NogInterpretter.NogPending;
import stringParser.core.AbstractInterpretter;
import stringParser.core.StringParser;
import stringParser.core.StringParserIterator;
import stringParser.parsers.BracketPairParser;
import stringParser.parsers.ICharacterParser;
import stringParser.parsers.NameValuePairParser;
import stringParser.parsers.QuotedStringParser;
import stringParser.parsers.CharListParser;

class NogInterpretter extends AbstractInterpretter
{
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

	private static function checkInit():Void{
		if(_nogConfig==null){
			_nogConfig = [];
			var blockChildParsers:Array<ICharacterParser> = [];
			
			operatorParser = new CharListParser(["+", "-", "=", "*", "$", "*", ".", ",", "?", "!", "/", "\\", "@", "~", "|", "^", "%", "&", ":"]);
			operatorParser.childParsers = [];
			_nogConfig.push(operatorParser);
			blockChildParsers.push(operatorParser);
			
			labelParser = new CharListParser(CharListParser.getCharRanges(true,true,true,["_", "."]));
			labelParser.childParsers = [];
			_nogConfig.push(labelParser);
			blockChildParsers.push(labelParser);
			operatorParser.childParsers.push(labelParser);
			labelParser.childParsers.push(operatorParser);
			
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
			
			squareBlockParser = new BracketPairParser("[","]",null,[";", "\n", "\r"]);
			_nogConfig.push(squareBlockParser);
			operatorParser.childParsers.push(squareBlockParser);
			labelParser.childParsers.push(squareBlockParser);
			
			angleBlockParser = new BracketPairParser("<",">",null,[";", "\n", "\r"]);
			_nogConfig.push(angleBlockParser);
			operatorParser.childParsers.push(angleBlockParser);
			labelParser.childParsers.push(angleBlockParser);
			
			roundBlockParser = new BracketPairParser("(",")",null,[";", "\n", "\r"]);
			_nogConfig.push(roundBlockParser);
			operatorParser.childParsers.push(roundBlockParser);
			labelParser.childParsers.push(roundBlockParser);
			
			curlyBlockParser.childParsers = blockChildParsers;
			squareBlockParser.childParsers = blockChildParsers;
			angleBlockParser.childParsers = blockChildParsers;
			roundBlockParser.childParsers = blockChildParsers;
		}
	}


	private static var _nogConfig:Array<ICharacterParser>;
	
	private var _pendingMap:Map<String, NogPending>;
	private var _pending:Array<NogPending> = [];


	public function new(inputString:String=null){
		super(inputString);
		_pendingMap = new Map<String, NogPending>();
	}
	override private function getParserConfig():Array<ICharacterParser>{
		return nogConfig;
	}
	
	override private function start():Void{
		_result = [];
	}

	override private function interpret(id:String, parentId:String, parser:ICharacterParser, strings:Dynamic):Void{
		var value:Dynamic = null;
		
		var pending:NogPending = NogPending.take(id, parser, strings);
		_pendingMap.set(id, pending);
		
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
		var nogObj:Nog;
		
		if (pending.parser == operatorParser) {
			var str = (pending.strings ? StringTools.trim(pending.strings) : null);
			nogObj = Nog.Op(str, getChild(pending));
			
		}else if (pending.parser == labelParser) {
			var str = (pending.strings ? StringTools.trim(pending.strings) : null);
			nogObj = Nog.Label(str, getChild(pending));
			
		}else if (pending.parser == stringSingleParser) {
			nogObj = Nog.Str("'", pending.strings);
			
		}else if (pending.parser == stringDoubleParser) {
			nogObj = Nog.Str('"', pending.strings);
			
		}else if (pending.parser == stringBacktickParser) {
			nogObj = Nog.Str("`", pending.strings);
			
		}else if (pending.parser == commentSingleParser) {
			nogObj = Nog.Comment(pending.strings);
			
		}else if (pending.parser == commentMultiParser) {
			nogObj = Nog.CommentMulti(pending.strings);
			
		}else if (pending.parser == curlyBlockParser) {
			nogObj = Nog.Block("{", pending.childrenNog);
			
		}else if (pending.parser == squareBlockParser) {
			nogObj = Nog.Block("[", pending.childrenNog);
			
		}else if (pending.parser == roundBlockParser) {
			nogObj = Nog.Block("(", pending.childrenNog);
			
		}else if (pending.parser == angleBlockParser) {
			nogObj = Nog.Block("<", pending.childrenNog);
			
		}else {
			throw new Error("Something went very wrong");
		}
		if (pending.parent==null) {
			_result.unshift(nogObj);
		}else {
			if (pending.parent.childrenNog == null) pending.parent.childrenNog = [];
			pending.parent.childrenNog.push(nogObj);
		}
		_pendingMap.remove(pending.id);
		NogPending.ret(pending);
	}
	
	@:inline
	function getChild(pending:NogPending):Nog{
		return pending.childrenNog == null ? null : pending.childrenNog[0];
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
	public var childrenNog:Array<Nog>;
	public var parent:NogPending;
	
	public function new() {
		
	}
	
}