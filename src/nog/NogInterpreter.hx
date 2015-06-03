package nog;

import nog.Nog;
import nog.NogInterpreter.NogInterpConfig;
import nog.NogInterpreter.NogPending;
import stringParser.core.AbstractInterpreter;
import stringParser.core.StringKeys;
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
	public static var CONFIG_A:NogInterpConfig = { whitespace:[" "], singleCommentStart:["//"], singleCommentEnd:["\n", "\r"], multiCommentStart:["/*"], multiCommentEnd:["*/"], blockBreaks:[";", "\n", "\r"], operators:["+", "-", "=", "*", "#", "$", ".", ",", "?", "!", "/", "\\", "@", "~", "|", "^", "%", "&", ":"], allowBrackets:[Bracket.Angle, Bracket.Curly, Bracket.Round, Bracket.Square] };
	
	public function getNog():Array<NogPos>{
		return _nogResult;
	}
	
	/*public var operatorParser(get, null):CharListParser;
	private function get_operatorParser():CharListParser{
		checkInit();
		return operatorParser;
	}
	public var labelParser(get, null):CharListParser;
	private function get_labelParser():CharListParser{
		checkInit();
		return labelParser;
	}
	public var numberParser(get, null):NumberParser;
	private function get_numberParser():NumberParser{
		checkInit();
		return numberParser;
	}
	public var hexParser(get, null):NumberParser;
	private function get_hexParser():NumberParser{
		checkInit();
		return hexParser;
	}
	public var stringSingleParser(get, null):QuotedStringParser;
	private function get_stringSingleParser():QuotedStringParser{
		checkInit();
		return stringSingleParser;
	}
	public var stringDoubleParser(get, null):QuotedStringParser;
	private function get_stringDoubleParser():QuotedStringParser{
		checkInit();
		return stringDoubleParser;
	}
	public var stringBacktickParser(get, null):QuotedStringParser;
	private function get_stringBacktickParser():QuotedStringParser{
		checkInit();
		return stringBacktickParser;
	}
	public var curlyBlockParser(get, null):BracketPairParser;
	private function get_curlyBlockParser():BracketPairParser{
		checkInit();
		return curlyBlockParser;
	}
	public var squareBlockParser(get, null):BracketPairParser;
	private function get_squareBlockParser():BracketPairParser{
		checkInit();
		return squareBlockParser;
	}
	public var angleBlockParser(get, null):BracketPairParser;
	private function get_angleBlockParser():BracketPairParser{
		checkInit();
		return angleBlockParser;
	}
	public var roundBlockParser(get, null):BracketPairParser;
	private function get_roundBlockParser():BracketPairParser{
		checkInit();
		return roundBlockParser;
	}
	public var commentSingleParser(get, null):QuotedStringParser;
	private function get_commentSingleParser():QuotedStringParser{
		checkInit();
		return commentSingleParser;
	}
	public var commentMultiParser(get, null):QuotedStringParser;
	private function get_commentMultiParser():QuotedStringParser{
		checkInit();
		return commentMultiParser;
	}
	public var lineEndingParser(get, null):CharListParser;
	private function get_lineEndingParser():CharListParser{
		checkInit();
		return lineEndingParser;
	}*/

	/*private static function getConfig(config:Null<NogInterpConfig>):Array<ICharacterParser> {
		if (config == null) config = CONFIG_A;
		var configKey = config.allowBrackets.join(" ") + "_" + config.blockBreaks.join(" ") + "_" + config.multiCommentEnd.join(" ") + "_" + config.multiCommentStart.join(" ") + "_" + config.operators.join(" ") + "_" + config.singleCommentEnd.join(" ") + "_" + config.singleCommentStart.join(" ") + "_" + config.whitespace.join(" ");
		var nogConfig = _nogConfigs.get(configKey);
		if(nogConfig==null){
			nogConfig = [];
			nogConfig.push(WhitespaceParser.instance);
			
			var spaceParser = new WhitespaceParser(config.whitespace);
			
			var childParsers:Array<ICharacterParser> = [spaceParser];
			
			var exprBreaks = config.blockBreaks;
			
			var hexParser = new NumberParser(true);
			nogConfig.push(hexParser);
			childParsers.push(hexParser);
			
			var numberParser = new NumberParser(false);
			nogConfig.push(numberParser);
			childParsers.push(numberParser);
			
			var commentMultiParser = new QuotedStringParser(config.multiCommentStart, config.multiCommentEnd);
			nogConfig.push(commentMultiParser);
			childParsers.push(commentMultiParser);
			
			var commentSingleParser = new QuotedStringParser(config.singleCommentStart, config.singleCommentEnd);
			nogConfig.push(commentSingleParser);
			childParsers.push(commentSingleParser);
			
			var operatorParser = new CharListParser(config.operators, 2, exprBreaks);
			//operatorParser.childParsers = [];
			//operatorParser.finishedParsers = [spaceParser];
			nogConfig.push(operatorParser);
			childParsers.push(operatorParser);
			//operatorParser.childParsers.push(hexParser);
			//operatorParser.childParsers.push(numberParser);
			//operatorParser.childParsers.push(operatorParser);
			//operatorParser.childParsers.push(commentMultiParser);
			//operatorParser.childParsers.push(commentSingleParser);
			
			var labelParser = new CharListParser(CharListParser.getCharRanges(true,true,true,["_"]), 2, exprBreaks);
			//labelParser.childParsers = [];
			//labelParser.finishedParsers = [spaceParser];
			nogConfig.push(labelParser);
			childParsers.push(labelParser);
			//operatorParser.childParsers.push(labelParser);
			//labelParser.childParsers.push(hexParser);
			//labelParser.childParsers.push(numberParser);
			//labelParser.childParsers.push(operatorParser);
			//labelParser.childParsers.push(labelParser); // labels can follow labels
			
			var stringSingleParser = new QuotedStringParser(["'"]);
			childParsers.push(stringSingleParser);
			//operatorParser.childParsers.push(stringSingleParser);
			
			var stringDoubleParser = new QuotedStringParser(['"']);
			childParsers.push(stringDoubleParser);
			//operatorParser.childParsers.push(stringDoubleParser);
			
			var stringBacktickParser = new QuotedStringParser(['`']);
			childParsers.push(stringBacktickParser);
			//operatorParser.childParsers.push(stringBacktickParser);
			
			if(config.allowBrackets.indexOf(Bracket.Curly)!=-1){
				var curlyBlockParser = new BracketPairParser("{","}",null, exprBreaks);
				nogConfig.push(curlyBlockParser);
				//operatorParser.childParsers.push(curlyBlockParser);
				//labelParser.childParsers.push(curlyBlockParser);
				childParsers.push(curlyBlockParser);
				curlyBlockParser.childParsers = childParsers;
				curlyBlockParser.nextTokenParsers = childParsers;
			}
			
			if(config.allowBrackets.indexOf(Bracket.Square)!=-1){
				var squareBlockParser = new BracketPairParser("[","]",null, exprBreaks);
				nogConfig.push(squareBlockParser);
				//operatorParser.childParsers.push(squareBlockParser);
				//labelParser.childParsers.push(squareBlockParser);
				childParsers.push(squareBlockParser);
				squareBlockParser.childParsers = childParsers;
				squareBlockParser.nextTokenParsers = childParsers;
			}
			
			if(config.allowBrackets.indexOf(Bracket.Angle)!=-1){
				var angleBlockParser = new BracketPairParser("<",">",null, exprBreaks);
				nogConfig.push(angleBlockParser);
				//operatorParser.childParsers.push(angleBlockParser);
				//labelParser.childParsers.push(angleBlockParser);
				childParsers.push(angleBlockParser);
				angleBlockParser.childParsers = childParsers;
				angleBlockParser.nextTokenParsers = childParsers;
			}
			
			if(config.allowBrackets.indexOf(Bracket.Round)!=-1){
				var roundBlockParser = new BracketPairParser("(",")",null, exprBreaks);
				nogConfig.push(roundBlockParser);
				//operatorParser.childParsers.push(roundBlockParser);
				//labelParser.childParsers.push(roundBlockParser);
				childParsers.push(roundBlockParser);
				roundBlockParser.childParsers = childParsers;
				roundBlockParser.nextTokenParsers = childParsers;
			}
			
			
			childParsers = childParsers.concat([spaceParser]);
			operatorParser.finishedParsers = childParsers;
			labelParser.finishedParsers = childParsers;
			numberParser.finishedParsers = childParsers;
			stringSingleParser.finishedParsers = childParsers;
			stringDoubleParser.finishedParsers = childParsers;
			stringBacktickParser.finishedParsers = childParsers;
			
			
			var lineEndingParser = new CharListParser(exprBreaks);
			nogConfig.push(lineEndingParser);
			_nogConfigs.set(configKey, nogConfig);
		}
		return nogConfig;
	}

	private static var _nogConfigs:Map<String, Array<ICharacterParser>>;
*/
	
	private var _pendingMap:Map<String, NogPending>;
	private var _pending:Array<NogPending>;
	private var _nogResult:Array<NogPos>;
	private var _nogConfig:Array<ICharacterParser>;
	
	var _hexParser:NumberParser;
	var _numberParser:NumberParser;
	var _operatorParser:CharListParser;
	var _labelParser:CharListParser;
	var _stringSingleParser:QuotedStringParser;
	var _stringDoubleParser:QuotedStringParser;
	var _stringBacktickParser:QuotedStringParser;
	var _curlyBlockParser:BracketPairParser;
	var _squareBlockParser:BracketPairParser;
	var _angleBlockParser:BracketPairParser;
	var _roundBlockParser:BracketPairParser;
	var _lineEndingParser:CharListParser;
	var _commentMultiParser:QuotedStringParser;
	var _commentSingleParser:QuotedStringParser;
	
	// Sets back-references in output objects (change the prop as you parse different sources)
	public var currentFilePath:String;


	public function new(inputString:String=null, config:NogInterpConfig=null){
		createConfig(config);
		super(inputString);
		_pendingMap = new Map<String, NogPending>();
	}
	
	function createConfig(config:NogInterpConfig) 
	{
		if (config == null) config = CONFIG_A;
		
		var nogConfig:Array<ICharacterParser> = [];
		nogConfig.push(WhitespaceParser.instance);
		
		var spaceParser = new WhitespaceParser(config.whitespace);
		
		var childParsers:Array<ICharacterParser> = [spaceParser];
		
		var exprBreaks = config.blockBreaks;
		
		_hexParser = new NumberParser(true);
		nogConfig.push(_hexParser);
		childParsers.push(_hexParser);
		
		_numberParser = new NumberParser(false);
		nogConfig.push(_numberParser);
		childParsers.push(_numberParser);
		
		_commentMultiParser = new QuotedStringParser(config.multiCommentStart, config.multiCommentEnd);
		nogConfig.push(_commentMultiParser);
		childParsers.push(_commentMultiParser);
		
		_commentSingleParser = new QuotedStringParser(config.singleCommentStart, config.singleCommentEnd);
		nogConfig.push(_commentSingleParser);
		childParsers.push(_commentSingleParser);
		
		_operatorParser = new CharListParser(config.operators, 2, exprBreaks);
		nogConfig.push(_operatorParser);
		childParsers.push(_operatorParser);
		
		_labelParser = new CharListParser(CharListParser.getCharRanges(true,true,true,["_"]), 2, exprBreaks);
		nogConfig.push(_labelParser);
		childParsers.push(_labelParser);
		
		_stringSingleParser = new QuotedStringParser(["'"]);
		childParsers.push(_stringSingleParser);
		
		_stringDoubleParser = new QuotedStringParser(['"']);
		childParsers.push(_stringDoubleParser);
		
		_stringBacktickParser = new QuotedStringParser(['`']);
		childParsers.push(_stringBacktickParser);
		
		if(config.allowBrackets.indexOf(Bracket.Curly)!=-1){
			_curlyBlockParser = new BracketPairParser("{","}",null, exprBreaks);
			nogConfig.push(_curlyBlockParser);
			childParsers.push(_curlyBlockParser);
			_curlyBlockParser.childParsers = childParsers;
			_curlyBlockParser.nextTokenParsers = childParsers;
		}
		
		if(config.allowBrackets.indexOf(Bracket.Square)!=-1){
			_squareBlockParser = new BracketPairParser("[","]",null, exprBreaks);
			nogConfig.push(_squareBlockParser);
			childParsers.push(_squareBlockParser);
			_squareBlockParser.childParsers = childParsers;
			_squareBlockParser.nextTokenParsers = childParsers;
		}
		
		if(config.allowBrackets.indexOf(Bracket.Angle)!=-1){
			_angleBlockParser = new BracketPairParser("<",">",null, exprBreaks);
			nogConfig.push(_angleBlockParser);
			childParsers.push(_angleBlockParser);
			_angleBlockParser.childParsers = childParsers;
			_angleBlockParser.nextTokenParsers = childParsers;
		}
		
		if(config.allowBrackets.indexOf(Bracket.Round)!=-1){
			_roundBlockParser = new BracketPairParser("(",")",null, exprBreaks);
			nogConfig.push(_roundBlockParser);
			childParsers.push(_roundBlockParser);
			_roundBlockParser.childParsers = childParsers;
			_roundBlockParser.nextTokenParsers = childParsers;
		}
		
		
		childParsers = childParsers.concat([spaceParser]);
		_operatorParser.finishedParsers = childParsers;
		_labelParser.finishedParsers = childParsers;
		_numberParser.finishedParsers = childParsers;
		_stringSingleParser.finishedParsers = childParsers;
		_stringDoubleParser.finishedParsers = childParsers;
		_stringBacktickParser.finishedParsers = childParsers;
		
		
		_lineEndingParser = new CharListParser(exprBreaks);
		nogConfig.push(_lineEndingParser);
		_nogConfig = nogConfig;
	}
	
	override private function getParserConfig():Array<ICharacterParser>{
		return _nogConfig;
	}
	
	override private function start():Void {
		_pending = [];
		_nogResult = [];
		_result = _nogResult;
	}

	override private function interpret(id:String, parentId:String, key:String, parser:ICharacterParser, strings:Dynamic):Void {
		if (parser == _lineEndingParser) return;
		
		var value:Dynamic = null;
		
		var pending:NogPending = NogPending.take(id, key, parser, strings);
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
		
		if (pending.parser == _operatorParser) {
			var str = (pending.strings!=null ? StringTools.trim(pending.strings) : null);
			nogObj = Nog.Op(str, getChild(pending));
			
		}else if (pending.parser == _numberParser) {
			var str:String = cast pending.strings;
			if(str.indexOf(".")==-1){
				nogObj = Nog.Int(Std.parseInt(str), false, getChild(pending));
			}else {
				nogObj = Nog.Float(Std.parseFloat(str), getChild(pending));
			}
			
		}else if (pending.parser == _hexParser) {
			var str:String = cast pending.strings;
			nogObj = Nog.Int(Std.parseInt(str), true, getChild(pending));
			
		}else if (pending.parser == _labelParser) {
			var str = (pending.strings!=null ? StringTools.trim(pending.strings) : null);
			nogObj = Nog.Label(str, getChild(pending));
			
		}else if (pending.parser == _stringSingleParser) {
			nogObj = Nog.Str(Quote.Single, pending.strings, getChild(pending));
			
		}else if (pending.parser == _stringDoubleParser) {
			nogObj = Nog.Str(Quote.Double, pending.strings, getChild(pending));
			
		}else if (pending.parser == _stringBacktickParser) {
			nogObj = Nog.Str(Quote.Backtick, pending.strings, getChild(pending));
			
		}else if (pending.parser == _commentSingleParser) {
			nogObj = Nog.Comment(pending.strings);
			
		}else if (pending.parser == _commentMultiParser) {
			nogObj = Nog.CommentMulti(pending.strings, getChild(pending));
			
		}else if (pending.parser == _curlyBlockParser) {
			var separator = getString(pending);
			if (separator == "\r\n") separator = BlockBreak.Newline;
			nogObj = Nog.Block(Bracket.Curly, getChildren(pending, StringKeys.CHILD), getChild(pending), separator);
			
		}else if (pending.parser == _squareBlockParser) {
			var separator = getString(pending);
			if (separator == "\r\n") separator = BlockBreak.Newline;
			nogObj = Nog.Block(Bracket.Square, getChildren(pending, StringKeys.CHILD), getChild(pending), separator);
			
		}else if (pending.parser == _roundBlockParser) {
			var separator = getString(pending);
			if (separator == "\r\n") separator = BlockBreak.Newline;
			nogObj = Nog.Block(Bracket.Round, getChildren(pending, StringKeys.CHILD), getChild(pending), separator);
			
		}else if (pending.parser == _angleBlockParser) {
			var separator = getString(pending);
			if (separator == "\r\n") separator = BlockBreak.Newline;
			nogObj = Nog.Block(Bracket.Angle, getChildren(pending, StringKeys.CHILD), getChild(pending), separator);
			
		}else {
			throw "Something went very wrong";
		}
		
		
		var nogPos = nogObj.pos(currentFilePath, pending.start, pending.end, pending.line);
		
		if (pending.parent==null) {
			_nogResult.unshift(nogPos);
		}else {
			//if (pending.parent.childrenNog == null) pending.parent.childrenNog = [];
			//pending.parent.childrenNog.push(nogPos);
			pending.parent.addChild(pending.key, nogPos);
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
	function getString(pending:NogPending):String {
		if (!pending.strings) {
			return null;
		}else if (Std.is(pending.strings, Array)) {
			return (pending.strings==0 ? null : pending.strings[0]);
		}else {
			return cast pending.strings;
		}
	}
	function getChild(pending:NogPending, ?key:String, index:Int = 0):NogPos {
		if (key == null) key = StringKeys.NEXT;
		if (pending.childMap == null) return null;
		var list = pending.childMap.get(key);
		return list == null || list.length<=index ? null : list[index];
		//return pending.childrenNog == null || pending.childrenNog.length<=index ? null : pending.childrenNog[index];
	}
	function getChildren(pending:NogPending, key:String):Array<NogPos> {
		if (pending.childMap == null) return [];
		var list = pending.childMap.get(key);
		return list == null ? [] : list;
	}
}
class NogPending {
	
	private static var _pool:Array<NogPending> = [];
	
	public static function take(id:String, key:String, parser:ICharacterParser, strings:Dynamic) {
		var ret:NogPending;
		if (_pool.length > 0) {
			ret = _pool.pop();
		}else {
			ret = new NogPending();
		}
		ret.id = id;
		ret.key = key;
		ret.parser = parser;
		ret.strings = strings;
		return ret;
	}
	
	public static function ret(nogPending:NogPending) {
		nogPending.parser = null;
		nogPending.strings = null;
		nogPending.childrenPending = null;
		nogPending.childMap = null;
		nogPending.parent = null;
		_pool.push(nogPending);
	}
	
	public var id:String;
	public var key:String;
	public var parser:ICharacterParser;
	public var strings:Dynamic;
	public var childrenPending:Array<NogPending>;
	//public var childrenNog:Array<NogPos>;
	public var childMap:Map<String, Array<NogPos>>;
	public var parent:NogPending;
	
	public var start:Int;
	public var end:Int;
	public var line:Int;
	
	public function new() {
		
	}
	
	public function addChild(key:String, child:NogPos) {
		if (childMap == null) childMap = new Map();
		var list:Array<NogPos> = childMap.get(key);
		if (list==null) {
			list = [];
			childMap.set(key, list);
		}
		list.push(child);
	}
	
}

typedef NogInterpConfig = {
	var whitespace:Array<String>;
	
	var blockBreaks:Array<String>;
	var operators:Array<String>;
	
	var singleCommentStart:Array<String>;
	var singleCommentEnd:Array<String>;
	
	var multiCommentStart:Array<String>;
	var multiCommentEnd:Array<String>;
	
	var allowBrackets:Array<String>;
}
