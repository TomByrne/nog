package nog.lang;
import nog.lang.LangDef.TokenPos;
import nog.Nog;
import nog.Nog.NogPos;
import stringParser.core.IInterpreter;
import stringParser.core.StringParserIterator;
import nog.lang.LangDef;

using nog.lang.LangUtils;
using nog.NogUtils;


class LangInterpreter<T> implements IInterpreter
{
	public function getResult() : T {
		checkResult();
		return _langReader.getResult();
	}
	public function getIterator():StringParserIterator{
		return _nogInterpretter.getIterator();
	}

	public var inputString(get, set):String;
	private function get_inputString():String{
		return _nogInterpretter.inputString;
	}
	private function set_inputString(value:String):String{
		_nogInterpretter.inputString = value;
		return value;
	}

	public var langDef(get, set):LangDef;
	private function get_langDef():LangDef{
		return _langDef;
	}
	private function set_langDef(value:LangDef):LangDef{
		_langDef = value;
		_resultWas = null;
		_langReader = null;
		return value;
	}

	public var currentFilePath(get, set):String;
	private function get_currentFilePath():String{
		return _nogInterpretter.currentFilePath;
	}
	private function set_currentFilePath(value:String):String{
		_nogInterpretter.currentFilePath = value;
		return value;
	}
	
	private var _resultWas:Array<NogPos>;
	private var _nogInterpretter:NogInterpreter;
	private var _langDef:LangDef;
	private var _langReader:ILangReader<T>;
	private var _queIndex:Int = 0;
	private var _tokenIndex:Int = 0;
	
	private var _queue:Array<QueOp>;
	private var _excessTokens:Array<TokenPos>;
	private var _lastNog:NogPos;
	private var _currentNogTrail:Array<NogPos>;
	private var _currentNameTrail:Array<String>;
	private var _currentIdentTrail:Array<Ident>;
	private var _preventErr:Bool;

	public function new(?langDef:LangDef, ?inputString:String) {
		_nogInterpretter = new NogInterpreter();
		this.langDef = langDef;
		this.inputString = inputString;
	}
	
	public function setInputString(string:String):Void {
		this.inputString = string;
	}
	
	private function checkResult():Void {
		var res = _nogInterpretter.getNog();
		if (res == _resultWas) return;
		_resultWas = res;
		
		if (_langReader == null) {
			_langReader = _langDef.getReader();
		}else {
			_langReader.reset();
		}
		
		if (res == null) {
			return;
		}
		
		_queue = [];
		_currentNogTrail = [];
		_currentNameTrail = [];
		_currentIdentTrail = [];
		_excessTokens = [];
		
		//_interpContext = new InterpContext();
		//_interpContext.remainingNogs = _resultWas.concat([]);
		addRoots(_resultWas, _langDef.rootDefs);
		
		while (_queue.length > 0) {
			process();
		}
	}
	
	function addRoots(nogs:Array<NogPos>, defTokens:Array<TokenPos>) 
	{
		for (nog in nogs) {
			que(nog, null, defTokens);
		}
	}
	
	function que(nog:NogPos, matchTokens:Array<TokenPos>=null, options:Array<TokenPos>=null, name:String=null, ident:Ident=null) 
	{
		var nogTrail = _currentNogTrail.concat([nog]);
		var nameTrail = ( name!=null ? _currentNameTrail.concat([name]) : _currentNameTrail);
		var identTrail = ( ident!=null ? _currentIdentTrail.concat([ident]) : _currentIdentTrail);
		_queue.insert( _queIndex, QueOp.PROCESS({ nog:nog, matchTokens:matchTokens, options:options, nogTrail:nogTrail, nameTrail:nameTrail, identTrail:identTrail }) );
		_queIndex++;
	}
	
	function queClear(toToken:TokenPos) 
	{
		_queue.insert( _queIndex, QueOp.CLEAR(toToken) );
		_queIndex++;
	}
	
	function process() 
	{
		var op:QueOp = _queue.shift();
		switch(op) {
			case QueOp.PROCESS(item):
				_queIndex = 0;
				_tokenIndex = 0;
				processNow(item.nog, item.matchTokens, item.options, item.nogTrail, item.nameTrail, item.identTrail);
				if (_queue.length == 0) {
					clearExcessTokens();
				}
			case QueOp.CLEAR(toToken):
				clearExcessTokens(toToken);
		}
	}
	
	function clearExcessTokens(toToken:Null<TokenPos>=null) 
	{
		while (_excessTokens.length > 0) {
			var token = _excessTokens[0];
			if (token == toToken) break;
			interpNog(null, token, true, _lastNog);
			_excessTokens.shift();
		}
	}
	
	function processNow(nog:NogPos, matchTokens:Array<TokenPos>, options:Array<TokenPos>, nogTrail:Array<NogPos>, nameTrail:Array<String>, identTrail:Array<Ident>) : InterpResp
	{
		var nameTrailWas = _currentNameTrail;
		var nogTrailWas = _currentNogTrail;
		var identTrailWas = _currentIdentTrail;
		
		_currentNameTrail = nameTrail;
		_currentNogTrail = nogTrail;
		_currentIdentTrail = identTrail;
		
		var found = false;
		var eagerMode = (options==null);
		var opts = ( eagerMode ? _excessTokens : options);
		var throwErr = ( eagerMode || opts.length <= 1 ) && !_preventErr;
		var i:Int = 0;
		if (eagerMode)_tokenIndex = 0;
		while (i < opts.length) {
			if (eagerMode)_tokenIndex++;
			var res = interpNog(nog, opts[i], throwErr, _lastNog);
			if (res == InterpResp.Match) {
				found = true;
				
				if (eagerMode) {
					_excessTokens.shift();
				}
				else i++;
				
				if (matchTokens != null)insertTokenList(matchTokens);
				
				break;
			}else if (res == InterpResp.IgnoreToken) {
				if (eagerMode) {
					_excessTokens.shift();
				}
				else i++;
			}else {
				++i;
			}
		}
		if (!found) {
			if (throwErr && nog != null && opts.length == 0) {
				nog.error("Unrecognised token: "+nog.toString());
			}
		}else{
			_lastNog = nog;
		}
		
		_currentNogTrail = nogTrailWas;
		_currentNameTrail = nameTrailWas;
		_currentIdentTrail = identTrailWas;
		
		return found ? InterpResp.Match : InterpResp.NoMatch;
	}
	function interpNog(nogPos:Null<NogPos>, defToken:TokenPos, throwError:Bool, lastParsed:Null<NogPos>):InterpResp 
	{
		var ret = InterpResp.NoMatch;
		switch(defToken.token()) {
			case TokenDef.Optional(def, next):
				ret = interpOptional(def, next, nogPos, lastParsed, throwError);
				
			case TokenDef.Alternate(children, next):
				ret = interpAlternate(defToken, children, next, nogPos, lastParsed, throwError);
				
			case TokenDef.Multi(def, min, max, next):
				ret = interpMulti(def, min, max, next, nogPos, lastParsed, throwError);
			
			case TokenDef.Ident(type, next1, next2):
				ret = interpIdent(type, next1, next2, nogPos, lastParsed, throwError);
				
			case TokenDef.LiteralLabel(label, tokenChild1, tokenChild2):
				ret = interpLitLabel(defToken, label, tokenChild1, tokenChild2, nogPos, lastParsed, throwError);
				
			case TokenDef.LiteralOp(op, next1, next2):
				ret = interpLitOp(op, next1, next2, nogPos, lastParsed, throwError);
				
			case TokenDef.LiteralStr(quote, str):
				ret = interpLitStr(quote, str, nogPos, lastParsed, throwError);
				
			case TokenDef.LiteralBlock(bracket, children):
				ret = interpLitBlock(bracket, children, nogPos, lastParsed, throwError);
				
			case TokenDef.Ref(id, pointer, next):
				ret = interpRef(defToken, id, pointer, next, nogPos, lastParsed, throwError);
				
			case TokenDef.Named(name, next):
				ret = interpNamed(name, next, nogPos, lastParsed, throwError);
				
			case  TokenDef.String(acceptSingle, acceptDouble, acceptBacktick):
				ret = interpStr(acceptSingle, acceptDouble, acceptBacktick, nogPos, lastParsed, throwError);
				
				
			default:
				if (throwError) {
					defToken.doErr("Unrecognised lang token: "+defToken.toString());
				}
		}
		return ret;
	}
	
	function interpStr(acceptSingle:Bool, acceptDouble:Bool, acceptBacktick:Bool, nogPos:Null<NogPos>, lastParsed:Null<NogPos>, throwError:Bool)  : InterpResp
	{
		var quotes = "";
		if (acceptSingle) {
			quotes += "'";
		}
		if (acceptDouble) {
			quotes += ( quotes.length>0 ? (acceptBacktick ? ', "' : ' or "') : '"');
		}
		if (acceptBacktick) {
			quotes += ( quotes.length>0 ? ' or `' : '`');
		}
		var err = "Should be string with " + quotes + " quotes";
		if (nogPos == null) {
			addInterpError(nogPos, lastParsed, throwError, err);
			return InterpResp.NoMatch;
		}
		
		switch(nogPos.nog()) {
			case Nog.Str(quote2, str2):
				if (quote2 == Quote.Single) {
					if (!acceptSingle) {
						if (throwError) nogPos.error("Can't use single quotes here. "+err);
						return InterpResp.NoMatch;
					}
				}else if (quote2 == Quote.Double) {
					if (!acceptDouble) {
						if (throwError) nogPos.error("Can't use double quotes here. "+err);
						return InterpResp.NoMatch;
					}
				}else if (quote2 == Quote.Backtick) {
					if (!acceptBacktick) {
						if (throwError) nogPos.error("Can't use backtick quotes here. "+err);
						return InterpResp.NoMatch;
					}
				}
				
				//read(nogPos, defToken);
				return InterpResp.Match;
				
			default:
				addInterpError(nogPos, lastParsed, throwError, err);
				return InterpResp.NoMatch;
		}
	}
	
	function interpNamed(name:String, next:Null<TokenPos>, nogPos:Null<NogPos>, lastParsed:Null<NogPos>, throwError:Bool)  : InterpResp
	{
		if (nogPos != null)return processNow(nogPos, null, [next], _currentNogTrail, _currentNameTrail, _currentIdentTrail);
		return InterpResp.IgnoreToken;
	}
	
	function interpRef(token:TokenPos, id:String, pointer:Pointer<TokenPos>, next:Null<TokenPos>, nogPos:Null<NogPos>, lastParsed:Null<NogPos>, throwError:Bool)  : InterpResp
	{
		if (pointer.value == null) {
			token.doErr("LangDef References should all be resolved before interpretting language: "+id);
			return InterpResp.NoMatch;
		}
		var ret = processNow(nogPos, tokenArr(next), [pointer.value], _currentNogTrail, _currentNameTrail, _currentIdentTrail);
		
		return ret;
	}
	
	function interpOptional(def:TokenPos, next:Null<TokenPos>, nogPos:Null<NogPos>, lastParsed:Null<NogPos>, throwError:Bool) : InterpResp
	{
		var ret = InterpResp.IgnoreToken;
		if (nogPos != null) {
			var prevWas = _preventErr;
			_preventErr = true;
			ret = processNow(nogPos, null, [def], _currentNogTrail, _currentNameTrail, _currentIdentTrail);
			_preventErr = prevWas;
			insertTokens(next);
			if (ret == InterpResp.NoMatch) {
				ret = InterpResp.IgnoreToken;
			}
		}
		
		return ret;
	}
	
	function interpAlternate(def:TokenPos, children:Array<TokenPos>, next:Null<TokenPos>, nogPos:Null<NogPos>, lastParsed:Null<NogPos>, throwError:Bool)  : InterpResp
	{
		var prevWas = _preventErr;
		_preventErr = children.length > 1;
		var ret = processNow(nogPos, tokenArr(next), children, _currentNogTrail.concat([nogPos]), _currentNameTrail, _currentIdentTrail);
		_preventErr = prevWas;
		if (ret == InterpResp.NoMatch && throwError && children.length > 1) {
			var errNog = (nogPos==null ? lastParsed : nogPos);
			errNog.error("Expected one of the following tokens: "+def.toString());
		}
		return ret;
	}
	
	function interpMulti(def:TokenPos, min:Int, max:Int, next:TokenPos, nogPos:Null<NogPos>, lastParsed:Null<NogPos>, throwError:Bool)  : InterpResp
	{
		
		var count = 0;
		var matched = false;
		if (min < 0) min = 0;
		var first = true;
		var nextNog:NogPos;
		var queOp:QueOp = null;
		var maxTakeFromQue:Int = _queue.length;
		var taken = 0;
		var queWas = _queue.concat([]);
		var prevWas = _preventErr;
		_preventErr = true;
		do {
			if (first) {
				nextNog = nogPos;
			}else {
				queOp = _queue.shift();
				taken++;
				switch(queOp) {
					case QueOp.PROCESS(item):
						nextNog = item.nog;
						
					case QueOp.CLEAR:
						if (queOp!=null) {
							_queue.unshift(queOp);
						}
						break;
						
				}
			}
			first = false;
			
			var res = processNow(nextNog, null, [def], _currentNogTrail.concat([nextNog]), _currentNameTrail, _currentIdentTrail);
			
			if (res == InterpResp.Match) count++;
			else if (res == InterpResp.NoMatch) {
				if (queOp!=null) {
					_queue.unshift(queOp);
				}
				break;
			}
			
		}while (matched && (max == -1 || count < max) && taken < maxTakeFromQue);
		_preventErr = prevWas;
		
		var ret = ( count >= min && (max == -1 || count <= max) );
		if (!ret) {
			_queue = queWas;
		}
		insertTokens(next);
		
		return ret ? InterpResp.Match : InterpResp.NoMatch;
	}
	
	function interpIdent(type:String, next1:TokenPos, next2:TokenPos, nogPos:Null<NogPos>, lastParsed:Null<NogPos>, throwError:Bool)  : InterpResp
	{
		var err = "Should be " + type + " identifier";
		if (nogPos == null) {
			addInterpError(nogPos, lastParsed, throwError, err);
			return InterpResp.NoMatch;
		}
		
		switch(nogPos.nog()) {
			case Nog.Label(label, nogChild1, nogChild2):
				
				var ident = { type:type, ident:label };
				insertTokens(next1, next2);
				if (nogChild1 != null) que(nogChild1, null, null, null, ident);
				if (nogChild2 != null) que(nogChild2, null, null, null, ident);
				return InterpResp.Match;
				
			default:
				addInterpError(nogPos, lastParsed, throwError, err);
				return InterpResp.NoMatch;
		}
	}
	
	function interpLitStr(quote:String, str:String, nogPos:Null<NogPos>, lastParsed:Null<NogPos>, throwError:Bool)  : InterpResp
	{
		var err = "Should be string " + quote.getForeQuote() + str + quote.getAftQuote();
		if (nogPos == null) {
			addInterpError(nogPos, lastParsed, throwError, err);
			return InterpResp.NoMatch;
		}
		
		switch(nogPos.nog()) {
			case Nog.Str(quote2, str2):
				if (quote != quote2) {
					if (throwError) nogPos.error("Quotes should be " + quote);
					return InterpResp.NoMatch;
					
				}else if (str != str2) {
					if(throwError)nogPos.error("String should be "+str);
					return InterpResp.NoMatch;
				}
				
				//read(nogPos, defToken);
				return InterpResp.Match;
				
			default:
				addInterpError(nogPos, lastParsed, throwError, err);
				return InterpResp.NoMatch;
		}
	}
	
	function interpLitOp(op:String, tokenChild1:Null<TokenPos>, tokenChild2:Null<TokenPos>, nogPos:Null<NogPos>, lastParsed:Null<NogPos>, throwError:Bool)  : InterpResp
	{
		var err = "Should be " + op + " operator";
		if (nogPos == null) {
			addInterpError(nogPos, lastParsed, throwError, err);
			return InterpResp.NoMatch;
		}
		
		switch(nogPos.nog()) {
			case Nog.Op(op2, nogChild1, nogChild2):
				if (op != op2) {
					if(throwError)nogPos.error(op2+" operator should be "+op);
					return InterpResp.NoMatch;
				}
				
				insertTokens(tokenChild1, tokenChild2);
				if (nogChild1 != null) que(nogChild1);
				if (nogChild2 != null) que(nogChild2);
				
				//read(nogPos, defToken);
				
				return InterpResp.Match;
				
			default:
				addInterpError(nogPos, lastParsed, throwError, err);
				return InterpResp.NoMatch;
		}
	}
	
	function interpLitLabel(token:TokenPos, label:String, tokenChild1:TokenPos, tokenChild2:TokenPos, nogPos:Null<NogPos>, lastParsed:Null<NogPos>, throwError:Bool)  : InterpResp
	{
		var err = "Should be " + label + " label";
		if (nogPos == null) {
			addInterpError(nogPos, lastParsed, throwError, err);
			return InterpResp.NoMatch;
		}
		
		switch(nogPos.nog()) {
			case Nog.Label(label2, nogChild1, nogChild2):
				if (label != label2) {
					if(throwError)nogPos.error("Label should be "+label);
					return InterpResp.NoMatch;
				}
				
				insertTokens(tokenChild1, tokenChild2);
				if (nogChild1 != null) que(nogChild1);
				if (nogChild2 != null) que(nogChild2);
				
				//read(nogPos, defToken);
				
				return InterpResp.Match;
				
			default:
				addInterpError(nogPos, lastParsed, throwError, err);
				return InterpResp.NoMatch;
		}
	}
	
	function interpLitBlock(bracket:String, children:Array<TokenPos>, nogPos:Null<NogPos>, lastParsed:Null<NogPos>, throwError:Bool)  : InterpResp
	{
		var err = "Should be a " + bracket.getForeBracket() + bracket.getAftBracket() + " block";
		if (nogPos == null) {
			addInterpError(nogPos, lastParsed, throwError, err);
			return InterpResp.NoMatch;
		}
		
		switch(nogPos.nog()) {
			case Nog.Block(bracket2, children2):
				if (bracket != bracket2) {
					if (throwError) nogPos.error("Brackets should be " + bracket);
					return InterpResp.NoMatch;
				}
				
				
				//insertTokenList(children);
				for (childNog in children2) {
					que(childNog, null, children);
				}
				queClear(_excessTokens.length > _tokenIndex ? _excessTokens[_tokenIndex] : null);
				
				return InterpResp.Match;
				
			default:
				addInterpError(nogPos, lastParsed, throwError, err);
				return InterpResp.NoMatch;
		}
	}
	
	function addInterpError(nogPos:Null<NogPos>, lastParsed:Null<NogPos>, throwError:Bool, msg:String) 
	{
		if (lastParsed != null) msg += " following "+lastParsed.toString();
		else msg += "here";
		
		if (nogPos == null) {
			if (throwError) {
				if (lastParsed != null) lastParsed.error( msg );
				else error(msg);
			}
		}else {
			if (throwError) nogPos.error(msg);
		}
	}
	
	/*function read(nogPos:NogPos, defToken:TokenPos) 
	{
		_langReader.read(nogPos, defToken, _interpContext.openNogs, _interpContext.openTokens);
	}*/
	
	
	function insertTokens(tokenChild1:Null<TokenPos>, tokenChild2:Null<TokenPos>=null) 
	{
		if (tokenChild1 != null) {
			_excessTokens.insert(_tokenIndex, tokenChild1);
			_tokenIndex++;
		}
		if (tokenChild2 != null) {
			_excessTokens.insert(_tokenIndex, tokenChild2);
			_tokenIndex++;
		}
	}
	
	
	function insertTokenList(tokens:Null<Array<TokenPos>>) 
	{
		if (tokens != null) {
			_excessTokens = _excessTokens.slice(0, _tokenIndex).concat(tokens).concat(_excessTokens.slice(_tokenIndex));
			_tokenIndex += tokens.length;
		}
	}
	
	function tokenArr(next1:TokenPos=null, next2:TokenPos=null) : Null<Array<TokenPos>>
	{
		if (next1 != null) {
			if (next2 != null) {
				return [next1, next2];
			}else {
				return [next1];
			}
		}else if (next2 != null) {
			return [next2];
		}else {
			return null;
		}
	}
	
	inline private function error(str:String) {
		#if macro
			haxe.macro.Context.error(currentFilePath, haxe.macro.Context.makePosition({ file:currentFilePath, min:0, max:inputString.length }) );
		#else
			throw str;
		#end
	}
}

enum QueOp {
	PROCESS(item:ProcessItem);
	CLEAR(toToken:Null<TokenPos>);
}
typedef ProcessItem = {
	var nog:NogPos;
	var options:Null<Array<TokenPos>>;
	var matchTokens:Array<TokenPos>;
	var nogTrail:Array<NogPos>;
	var nameTrail:Array<String>;
	var identTrail:Array<Ident>;
}
typedef Ident = {
	var type:String;
	var ident:String;
}
enum InterpResp {
	Match;
	NoMatch;
	IgnoreToken;
}