package nog.lang;
import nog.lang.LangDef.TokenPos;
import nog.lang.read.ILangReader;
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
	private var _queIndex:Int;
	private var _tokenIndex:Int;
	
	private var _queue:Array<QueOp>;
	private var _excessTokens:Array<TokenPos>;
	private var _lastNog:NogPos;
	private var _preventErr:Bool;

	public function new(?langDef:LangDef, ?inputString:String) {
		_nogInterpretter = new NogInterpreter();
		this.langDef = langDef;
		this.inputString = inputString;
		_queIndex = 0;
		_tokenIndex = 0;
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
		
		
		for (meta in _langDef.metadata) {
			switch(meta) {
				case SetProp(nogPos, target, fields, value):
					if (target != "reader") {
						nogPos.error("Unrecognised metadata");
						continue;
					}
					setProp(nogPos, _langReader, fields, value);
					
				case CallMethod(nogPos, target, fields, args):
					if (target != "reader") {
						nogPos.error("Unrecognised metadata");
						continue;
					}
					callMeth(nogPos, _langReader, fields, args);
					
			}
		}
		
		if (res == null) {
			return;
		}
		
		_queue = [];
		_excessTokens = [];
		
		//_interpContext = new InterpContext();
		//_interpContext.remainingNogs = _resultWas.concat([]);
		addRoots(_resultWas, _langDef.rootDefs);
		
		while (_queue.length > 0) {
			process();
		}
	}
	
	function setProp(nogPos:NogPos, obj:Dynamic, fields:Array<String>, value:Dynamic) 
	{
		var subject:Dynamic = obj;
		var i = 0;
		while (i < fields.length) {
			var prop = fields[i];
			if (i < fields.length - 1) {
				try {
					subject = Reflect.getProperty(subject, prop);
				}catch (e:Dynamic) {
					nogPos.error("Couldn't get property " + prop + " on object " + subject+": "+e);
					return;
				}
			}else {
				try {
					Reflect.setProperty(subject, prop, value);
				}catch (e:Dynamic) {
					nogPos.error("Couldn't set property " + prop + " on object " + subject+": "+e);
					return;
				}
			}
			i++;
		}
	}
	
	function callMeth(nogPos:NogPos, obj:Dynamic, fields:Array<String>, args:Array<Dynamic>) 
	{
		var subject = obj;
		var i = 0;
		while (i < fields.length) {
			var prop = fields[i];
			if (i < fields.length - 1) {
				try {
					subject = Reflect.getProperty(subject, prop);
				}catch (e:Dynamic) {
					nogPos.error("Couldn't get property " + prop + " on object " + subject+": "+e);
					return;
				}
			}else {
				try {
					Reflect.callMethod(subject, Reflect.getProperty(subject, prop), args);
				}catch (e:Dynamic) {
					nogPos.error("Couldn't call method " + prop + " on object " + subject+": "+e);
					return;
				}
			}
			i++;
		}
	}
	
	function addRoots(nogs:Array<NogPos>, defTokens:Array<TokenPos>) 
	{
		for (nog in nogs) {
			que(nog, null, defTokens);
		}
	}
	
	function que(nog:NogPos, matchTokens:Array<TokenPos>=null, options:Array<TokenPos>=null) 
	{
		queInsert(QueOp.PROCESS({ nog:nog, matchTokens:matchTokens, options:options }));
	}
	
	function queClear(toToken:TokenPos) 
	{
		queInsert(QueOp.CLEAR(toToken));
	}
	
	function queInsert(op:QueOp){
		_queue.insert( _queIndex, op );
		_queIndex++;
	}
	
	function process() 
	{
		var op:QueOp = _queue.shift();
		switch(op) {
			case QueOp.PROCESS(item):
				_queIndex = 0;
				_tokenIndex = 0;
				var throwErr = item.options == null || item.options.length == 1;
				processNow(item.nog, throwErr, item.matchTokens, item.options);
				if (_queue.length == 0) {
					clearExcessTokens();
				}
			case QueOp.CLEAR(toToken):
				clearExcessTokens(toToken);
				
			case QueOp.OPEN_IDENT(nogPos, type, ident):
				_langReader.openIdent(nogPos, type, ident);
			case QueOp.CLOSE_IDENT(nogPos, type, ident):
				_langReader.closeIdent(nogPos, type, ident);
				
			case QueOp.OPEN_NAME(nogPos, name):
				_langReader.openName(nogPos, name);
			case QueOp.CLOSE_NAME(nogPos, name):
				_langReader.closeName(nogPos, name);
				
			case QueOp.OPEN_OP(nogPos, op):
				_langReader.openOp(nogPos, op);
			case QueOp.CLOSE_OP(nogPos, op):
				_langReader.closeOp(nogPos, op);
				
			case QueOp.OPEN_BLOCK(nogPos, bracket):
				_langReader.openBlock(nogPos, bracket);
			case QueOp.BLOCK_SEPARATOR(nogPos):
				_langReader.blockSeparator(nogPos);
			case QueOp.CLOSE_BLOCK(nogPos, bracket):
				_langReader.closeBlock(nogPos, bracket);
				
			case QueOp.OPEN_LABEL(nogPos, label):
				_langReader.openLabel(nogPos, label);
			case QueOp.CLOSE_LABEL(nogPos, label):
				_langReader.closeLabel(nogPos, label);
				
			case QueOp.OPEN_STR(nogPos, str):
				_langReader.openStr(nogPos, str);
			case QueOp.CLOSE_STR(nogPos, str):
				_langReader.closeStr(nogPos, str);
				
			case QueOp.OPEN_INT(nogPos, int, hex):
				_langReader.openInt(nogPos, int, hex);
			case QueOp.CLOSE_INT(nogPos, int, hex):
				_langReader.closeInt(nogPos, int, hex);
				
			case QueOp.OPEN_FLOAT(nogPos, float):
				_langReader.openFloat(nogPos, float);
			case QueOp.CLOSE_FLOAT(nogPos, float):
				_langReader.closeFloat(nogPos, float);
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
	
	function processNow(nog:NogPos, throwErr:Bool, matchTokens:Array<TokenPos>, options:Array<TokenPos>) : InterpResp
	{
		var found = false;
		var eagerMode = (options==null);
		var opts = ( eagerMode ? _excessTokens : options);
		//var throwErr = ( eagerMode || opts.length <= 1 ) && !_preventErr;
		var i:Int = 0;
		while (i < opts.length) {
			if (eagerMode)_tokenIndex = i+1;
			var res = interpNog(nog, opts[i], throwErr, _lastNog);
			if (res == InterpResp.Match) {
				found = true;
				
				if (eagerMode) {
					_excessTokens.splice(i, 1);
					_tokenIndex--;
				}
				else i++;
				
				if (matchTokens != null)insertTokenList(matchTokens);
				
				break;
			}else if (res == InterpResp.IgnoreToken) {
				if (eagerMode) {
					_excessTokens.splice(i, 1);
					_tokenIndex--;
				}
				else i++;
			}else {
				++i;
			}
		}
		if (!found) {
			if (throwErr && nog != null && i >= opts.length) {
				switch(nog.nog()) {
					case Comment(_) | CommentMulti(_, _):
					default:
						nog.error("Unrecognised token: "+nog.toString());
				}
			}
		}else{
			_lastNog = nog;
		}
		
		return found ? InterpResp.Match : InterpResp.NoMatch;
	}
	
	function interpNog(nogPos:Null<NogPos>, defToken:TokenPos, throwError:Bool, lastParsed:Null<NogPos>):InterpResp 
	{
		if(nogPos!=null){
			switch(nogPos.nog()) {
				case Nog.Comment(_):
					return InterpResp.NoMatch;
				case Nog.CommentMulti(_, next):
					if (next != null) {
						nogPos = next;
					}else{
						return InterpResp.NoMatch;
					}
				default:
			}
		}
		if(nogPos!=null && nogPos.toString() == "if"){
			//trace("interpNog: " + nogPos.toString()+" "+Type.enumIndex(defToken.token()));
		}
		var ret = InterpResp.NoMatch;
		switch(defToken.token()) {
			case TokenDef.Optional(def, next):
				ret = interpOptional(def, next, nogPos, lastParsed, throwError);
				
			case TokenDef.Alternate(children, next):
				ret = interpAlternate(defToken, children, next, nogPos, lastParsed, throwError);
				
			case TokenDef.Multi(def, min, max, next):
				ret = interpMulti(def, min, max, next, nogPos, lastParsed, throwError);
			
			case TokenDef.Ident(type, sep, next):
				ret = interpIdent(type, sep, next, nogPos, lastParsed, throwError);
				
			case TokenDef.LiteralLabel(label, next):
				ret = interpLitLabel(defToken, label, next, nogPos, lastParsed, throwError);
				
			case TokenDef.LiteralOp(op, next):
				ret = interpLitOp(op, next, nogPos, lastParsed, throwError);
				
			case TokenDef.LiteralStr(quote, str, next):
				ret = interpLitStr(quote, str, next, nogPos, lastParsed, throwError);
				
			case TokenDef.LiteralBlock(bracket, children, next):
				ret = interpLitBlock(bracket, children, next, nogPos, lastParsed, throwError);
				
			case TokenDef.Ref(id, pointer, next):
				ret = interpRef(defToken, id, pointer, next, nogPos, lastParsed, throwError);
				
			case TokenDef.Named(name, next):
				ret = interpNamed(name, next, nogPos, lastParsed, throwError);
				
			case  TokenDef.String(acceptSingle, acceptDouble, acceptBacktick, next):
				ret = interpStr(acceptSingle, acceptDouble, acceptBacktick, next, nogPos, lastParsed, throwError);
				
			case  TokenDef.Int:
				ret = interpInt(nogPos, lastParsed, throwError);
				
			case  TokenDef.Float:
				ret = interpFloat(nogPos, lastParsed, throwError);
		}
		return ret;
	}
	
	function interpStr(acceptSingle:Bool, acceptDouble:Bool, acceptBacktick:Bool, next:TokenPos, nogPos:Null<NogPos>, lastParsed:Null<NogPos>, throwError:Bool)  : InterpResp
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
			case Nog.Str(quote2, str2, next2):
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
				queInsert(QueOp.OPEN_STR(nogPos, str2));
				insertTokens(next);
				queInsert(QueOp.CLOSE_STR(nogPos, str2));
				if (next2 != null) que(next2);
				
				//read(nogPos);
				return InterpResp.Match;
				
			default:
				addInterpError(nogPos, lastParsed, throwError, err);
				return InterpResp.NoMatch;
		}
	}
	
	function interpInt(nogPos:Null<NogPos>, lastParsed:Null<NogPos>, throwError:Bool)  : InterpResp
	{
		switch(nogPos.nog()) {
			case Nog.Int(value, hex, next2): 
				queInsert(QueOp.OPEN_INT(nogPos, value, hex));
				if (next2 != null) que(next2);
				queInsert(QueOp.CLOSE_INT(nogPos, value, hex));
				//read(nogPos);
				return InterpResp.Match;
				
			default:
				addInterpError(nogPos, lastParsed, throwError, "Expected an Int here");
				return InterpResp.NoMatch;
		}
	}
	
	function interpFloat(nogPos:Null<NogPos>, lastParsed:Null<NogPos>, throwError:Bool)  : InterpResp
	{
		switch(nogPos.nog()) {
			case Nog.Float(value, next2):
				queInsert(QueOp.OPEN_FLOAT(nogPos, value));
				if (next2 != null) que(next2);
				queInsert(QueOp.CLOSE_FLOAT(nogPos, value));
				//read(nogPos);
				return InterpResp.Match;
				
			default:
				addInterpError(nogPos, lastParsed, throwError, "Expected a Float here");
				return InterpResp.NoMatch;
		}
	}
	
	function interpNamed(name:String, next:Null<TokenPos>, nogPos:Null<NogPos>, lastParsed:Null<NogPos>, throwError:Bool)  : InterpResp
	{
		if (nogPos != null) {
			queInsert( QueOp.OPEN_NAME(nogPos, name));
			var ret = processNow(nogPos, throwError, null, [next]);
			queInsert( QueOp.CLOSE_NAME(nogPos, name));
			return ret;
		}
		return InterpResp.IgnoreToken;
	}
	
	function interpRef(token:TokenPos, id:String, pointer:Pointer<TokenPos>, next:Null<TokenPos>, nogPos:Null<NogPos>, lastParsed:Null<NogPos>, throwError:Bool)  : InterpResp
	{
		if (pointer.value == null) {
			token.doErr("LangDef References should all be resolved before interpretting language: "+id);
			return InterpResp.NoMatch;
		}
		var ret = processNow(nogPos, throwError, tokenArr(next), [pointer.value]);
		
		return ret;
	}
	
	function interpOptional(def:TokenPos, next:Null<TokenPos>, nogPos:Null<NogPos>, lastParsed:Null<NogPos>, throwError:Bool) : InterpResp
	{
		var ret = InterpResp.IgnoreToken;
		if (nogPos != null) {
			var prevWas = _preventErr;
			_preventErr = true;
			ret = processNow(nogPos, false, null, [def]);
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
		var ret = processNow(nogPos, false, tokenArr(next), children);
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
						
					default:
						if (queOp!=null) {
							_queue.unshift(queOp);
						}
						break;
						
				}
			}
			first = false;
			
			var res = processNow(nextNog, throwError, null, [def]);
			
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
	
	function interpIdent(type:String, partSeparator:String, next:TokenPos, nogPos:Null<NogPos>, lastParsed:Null<NogPos>, throwError:Bool)  : InterpResp
	{
		var err = "Should be " + type + " identifier";
		if (nogPos == null) {
			addInterpError(nogPos, lastParsed, throwError, err);
			return InterpResp.NoMatch;
		}
		
		var fieldPath = NogUtils.followPropPath(nogPos, partSeparator);
		if (fieldPath.fields.length > 0) {
			var ident = { type:type, ident:fieldPath.fields.join(partSeparator) };
			queInsert( QueOp.OPEN_IDENT(nogPos, type, ident.ident));
			insertTokens(next);
			if (fieldPath.next != null) que(fieldPath.next, null, null);
			queInsert( QueOp.CLOSE_IDENT(nogPos, type, ident.ident));
			//read(nogPos);
			return InterpResp.Match;
		}else{
			addInterpError(nogPos, lastParsed, throwError, err);
			return InterpResp.NoMatch;
		}
		
		/*switch(nogPos.nog()) {
			case Nog.Label(label, next2):
				
				var ident = { type:type, ident:label };
				insertTokens(next);
				if (next2 != null) que(next2, null, null, null, ident);
				return InterpResp.Match;
				
			default:
				addInterpError(nogPos, lastParsed, throwError, err);
				return InterpResp.NoMatch;
		}*/
	}
	
	function interpLitStr(quote:String, str:String, next:TokenPos, nogPos:Null<NogPos>, lastParsed:Null<NogPos>, throwError:Bool)  : InterpResp
	{
		var err = "Should be string " + quote.getForeQuote() + str + quote.getAftQuote();
		if (nogPos == null) {
			addInterpError(nogPos, lastParsed, throwError, err);
			return InterpResp.NoMatch;
		}
		
		switch(nogPos.nog()) {
			case Nog.Str(quote2, str2, next2):
				if (quote != quote2) {
					if (throwError) nogPos.error("Quotes should be " + quote);
					return InterpResp.NoMatch;
					
				}else if (str != str2) {
					if(throwError)nogPos.error("String should be "+str);
					return InterpResp.NoMatch;
				}
				insertTokens(next);
				if (next2 != null) que(next2);
				
				//read(nogPos);
				return InterpResp.Match;
				
			default:
				addInterpError(nogPos, lastParsed, throwError, err);
				return InterpResp.NoMatch;
		}
	}
	
	function interpLitOp(op:String, next:Null<TokenPos>, nogPos:Null<NogPos>, lastParsed:Null<NogPos>, throwError:Bool)  : InterpResp
	{
		var err = "Should be " + op + " operator";
		if (nogPos == null) {
			addInterpError(nogPos, lastParsed, throwError, err);
			return InterpResp.NoMatch;
		}
		
		switch(nogPos.nog()) {
			case Nog.Op(op2, next2):
				if (op != op2) {
					if(throwError)nogPos.error(op2+" operator should be "+op);
					return InterpResp.NoMatch;
				}
				
				insertTokens(next);
				queInsert(QueOp.OPEN_OP(nogPos, op2));
				if (next2 != null) que(next2);
				queInsert(QueOp.CLOSE_OP(nogPos, op2));
				
				//read(nogPos);
				return InterpResp.Match;
				
			default:
				addInterpError(nogPos, lastParsed, throwError, err);
				return InterpResp.NoMatch;
		}
	}
	
	function interpLitLabel(token:TokenPos, label:String, next:TokenPos, nogPos:Null<NogPos>, lastParsed:Null<NogPos>, throwError:Bool)  : InterpResp
	{
		var err = "Should be " + label + " label";
		if (nogPos == null) {
			addInterpError(nogPos, lastParsed, throwError, err);
			return InterpResp.NoMatch;
		}
		
		switch(nogPos.nog()) {
			case Nog.Label(label2, next2):
				if (label != label2) {
					if (throwError) {
						nogPos.error("Label should be "+label);
					}
					return InterpResp.NoMatch;
				}
				
				queInsert(QueOp.OPEN_LABEL(nogPos, label));
				insertTokens(next);
				if (next2 != null) que(next2);
				queInsert(QueOp.CLOSE_LABEL(nogPos, label));
				
				//read(nogPos);
				return InterpResp.Match;
				
			default:
				addInterpError(nogPos, lastParsed, throwError, err);
				return InterpResp.NoMatch;
		}
	}
	
	function interpLitBlock(bracket:String, children:Array<TokenPos>, next:TokenPos, nogPos:Null<NogPos>, lastParsed:Null<NogPos>, throwError:Bool)  : InterpResp
	{
		var err = "Should be a " + bracket.getForeBracket() + bracket.getAftBracket() + " block";
		if (nogPos == null) {
			addInterpError(nogPos, lastParsed, throwError, err);
			return InterpResp.NoMatch;
		}
		
		switch(nogPos.nog()) {
			case Nog.Block(bracket2, children2, next2, blockBreak):
				if (bracket != bracket2) {
					if (throwError) nogPos.error("Brackets should be " + bracket);
					return InterpResp.NoMatch;
				}
				
				queInsert(QueOp.OPEN_BLOCK(nogPos, bracket));
				//insertTokenList(children);
				for (childNog in children2) {
					que(childNog, null, children);
					queInsert(QueOp.BLOCK_SEPARATOR(nogPos));
				}
				var tokenIndex = _tokenIndex;
				insertTokens(next);
				queClear(_excessTokens.length > tokenIndex ? _excessTokens[tokenIndex] : null);
				
				if (next2 != null) que(next2);
				queInsert(QueOp.CLOSE_BLOCK(nogPos, bracket));
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
			if (throwError) {
				nogPos.error(msg);
			}
		}
	}
	
	/*function read(nogPos:NogPos) 
	{
		_langReader.read(nogPos);
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
	
	OPEN_IDENT(nogPos:NogPos, type:String, ident:String);
	CLOSE_IDENT(nogPos:NogPos, type:String, ident:String);
	
	OPEN_NAME(nogPos:NogPos, name:String);
	CLOSE_NAME(nogPos:NogPos, name:String);
	
	OPEN_OP(nogPos:NogPos, op:String);
	CLOSE_OP(nogPos:NogPos, op:String);
	
	OPEN_BLOCK(nogPos:NogPos, bracket:String);
	BLOCK_SEPARATOR(nogPos:NogPos);
	CLOSE_BLOCK(nogPos:NogPos, bracket:String);
	
	OPEN_LABEL(nogPos:NogPos, label:String);
	CLOSE_LABEL(nogPos:NogPos, label:String);
	
	OPEN_STR(nogPos:NogPos, str:String);
	CLOSE_STR(nogPos:NogPos, str:String);
	
	OPEN_INT(nogPos:NogPos, int:Int, hex:Bool);
	CLOSE_INT(nogPos:NogPos, int:Int, hex:Bool);
	
	OPEN_FLOAT(nogPos:NogPos, float:Float);
	CLOSE_FLOAT(nogPos:NogPos, float:Float);
}
typedef ProcessItem = {
	var nog:NogPos;
	var options:Null<Array<TokenPos>>;
	var matchTokens:Array<TokenPos>;
}
enum InterpResp {
	Match;
	NoMatch;
	IgnoreToken;
}