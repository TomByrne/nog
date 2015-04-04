package nog.lang;
import haxe.macro.Context;
import nog.lang.LangDef.Pointer;
import nog.lang.LangDef.TokenDef;
import nog.lang.LangDef.TokenPos;
import nog.Nog;
import nog.NogInterpreter;
import stringParser.core.IInterpreter;
import stringParser.core.StringParser;
import stringParser.core.StringParserIterator;

using nog.NogUtils;
using nog.lang.LangUtils;

class LangDefInterpreter implements IInterpreter
{
	public function getLangDef():LangDef{
		checkResult();
		return _result;
	}
	public function getResult():Dynamic {
		checkResult();
		return _result;
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

	public var currentFilePath(get, set):String;
	private function get_currentFilePath():String{
		return _nogInterpretter.currentFilePath;
	}
	private function set_currentFilePath(value:String):String{
		_nogInterpretter.currentFilePath = value;
		return value;
	}
	
	private var _result:LangDef;
	private var _resultWas:Dynamic;
	private var _nogInterpretter:NogInterpreter;

	public function new(inputString:String) {
		_nogInterpretter = new NogInterpreter();
		this.inputString = inputString;
	}
	
	public function setInputString(string:String):Void {
		this.inputString = string;
	}
	
	private function checkResult():Void {
		var res = _nogInterpretter.getNog();
		if (res == _resultWas) return;
		_resultWas = res;
		
		if (res == null) {
			_result = null;
			return;
		}
		
		var fileExt:String = null;
		var name:String = null;
		var rootDef:TokenPos = null;
		var refs:Map<String, TokenPos> = new Map();
		var lookups:Array<TokenPos> = [];
		var identifierTypes:Array<String> = [];
		for (nogPos in res) {
			trace(nogPos.stringify());
			switch(nogPos.nog()) {
				case Nog.Op(op, child1, child2):
					if (child2 != null) {
						doErr(child2, "Unrecognised token");
					}
					if (op == "@") {
						// metadata
						var pair = getNameValue(child1);
						switch( pair.name ) {
							case "name" : name = pair.value;
							case "fileExt" : fileExt = pair.value;
						}
						
					}else if (op == "!") {
						// definition
						switch(child1.nog()) {
							case Nog.Label(label, child1, child2):
								// Define new symbol
								refs.set(label, interpNogRoot(child1, lookups, identifierTypes));
								
								if (child2 != null) {
									doErr(child2, "Unrecognised token");
								}
							default:
								doErr(child1, "Should specify a symbol label here");
								
						}
						
					}else if (op == "-") {
						// root item/s
						if (rootDef != null) {
							doErr(child1, "Root token already defined");
						}
						rootDef = interpNogRoot(child1, lookups, identifierTypes);
					}
				
				case Nog.Comment(_) | Nog.CommentMulti(_):
					// ignore
					
				default:
					doErr(nogPos, "Unrecognised token at language def root");
			}
		}
		
		for (tokenPos in lookups) {
			switch(tokenPos.token()) {
				case TokenDef.Ref(id, ref, next):
					if (ref.value != null) continue;
					
					var resolved = refs.get(id);
					if (resolved==null) {
						doTokenErr(tokenPos, "Unrecognised reference token");
						continue;
					}
					ref.value = resolved;
				default:
						doTokenErr(tokenPos, "An unknown error occured, Non-reference token found in lookups listing");
			}
		}
		trace("identifierTypes: "+identifierTypes);
		_result = { fileExt:fileExt, name:name, rootDef:rootDef, identifierTypes:identifierTypes };
	}
	
	function interpNogRoot(nogPos:NogPos, lookups:Array<TokenPos>, identifierTypes:Array<String>) : TokenPos{
		return interpNog(nogPos, lookups, identifierTypes);
	}
	
	function interpNog(nogPos:NogPos, lookups:Array<TokenPos>, identifierTypes:Array<String>) : Null<TokenPos> {
		if (nogPos == null) return null;
		
		var nog = nogPos.nog();
		switch(nog) {
			case Nog.Op(op, child1, child2):
				
				if ( op.length>1 && op.charAt(0) == "\\" ) {
					return toTokenPos(TokenDef.LiteralOp(op.substr(1), interpNog(child1, lookups, identifierTypes)), nogPos);
				}
				
				if(op == "+"){
					if (child2 != null) doErr(child2, "Unrecognised token");
					return toTokenPos(TokenDef.Multi(interpNog(child1, lookups, identifierTypes)), nogPos);
					
				}else if (op == "|") {
					return toTokenPos(TokenDef.Alternate(interpNogList(child1, lookups, identifierTypes, "["), interpNog(child2, lookups, identifierTypes)), nogPos);
					
				}else if (op == ":") {
					if (child2 != null) doErr(child2, "Unrecognised token");
					switch(child1.nog()) {
						case Nog.Label(label, child1, child2):
							if (child2 != null) doErr(child2, "Unrecognised token");
							if (identifierTypes.indexOf(label) == -1) identifierTypes.push(label);
							return toTokenPos(TokenDef.Ident(label, interpNog(child1, lookups, identifierTypes)), nogPos);
						default:
							doErr(child1, "Identifier type operator should be followed by a label");
							return null;
					}
					
				}else if (op == "!") {
					if (child2 != null) doErr(child2, "Unrecognised token");
					switch(child1.nog()) {
						case Nog.Label(label, child1, child2):
							if (child2 != null) doErr(child2, "Unrecognised token");
							var ret = toTokenPos(TokenDef.Ref(label, {value:null}, interpNog(child1, lookups, identifierTypes)), nogPos);
							lookups.push(ret);
							return ret;
						default:
							doErr(nogPos, "Should be simple label here");
							return null;
					}
					
				}else if (op == "$") {
					if (child2 != null) doErr(child2, "Unrecognised token");
					switch(child1.nog()) {
						case Nog.Label(label, child11, child12):
							if (child12 != null) doErr(child12, "Unrecognised token");
							switch(label) {
								case "Int":
									return toTokenPos(TokenDef.Int, nogPos);
								case "Float":
									return toTokenPos(TokenDef.Float, nogPos);
								case "String":
									return interpStringType(child11);
								default:
									doErr(child11, "Unknown core type used");
									return null;
							}
						default:
							doErr(child1, "Core type operator should be followed by a type name (e.g. Int)");
							return null;
					}
					
				}else if (op == "?") {
					var children;
					if (isNogList(child1, "[")) {
						children = interpNogList(child1, lookups, identifierTypes, "[");
					}else {
						children = [interpNog(child1, lookups, identifierTypes)];
					}
					if(children.length==1){
						var next = interpNog(child2, lookups, identifierTypes);
						return toTokenPos(TokenDef.Optional(children[0], next), nogPos);
					}else if (children.length == 0) {
						doErr(child1, "Optional should have exactly one child expression");
						return null;
					}else {
						doErr(child1, "Optional operator should only have one child expression");
						return null;
					}
					
				}else {
					doErr(child1, "Unrecognised operator");
					return null;
				}
				
			case Nog.Block(bracket, children):
				return toTokenPos(TokenDef.LiteralBlock(bracket, interpNogArray(children, lookups, identifierTypes)), nogPos);
				
			case Nog.Str(quote, str):
				return toTokenPos(TokenDef.LiteralStr(quote, str), nogPos);
				
			case Nog.Comment(_) | Nog.CommentMulti(_) | Label(_):
				return null;
		}
	}
	
	function toTokenPos(token:TokenDef, nogPos:NogPos) : TokenPos
	{
		#if (nogpos || macro)
		return { min:nogPos.min, max:nogPos.max, file:nogPos.file, tokenRef:token };
		#else
		return token;
		#end
	}
	
	function interpStringType(nogPos:NogPos) : TokenPos{
		var nog = nogPos.nog();
		var bracket = "(";
		switch(nog) {
			case Nog.Block(bracket, children):
				var allowSingle = false;
				var allowDouble = false;
				var allowBacktick = false;
				for (i in 0...children.length) {
					var child = children[i];
					var val = getLabel(child) == "true";
					     if (i == 0) allowSingle = val;
					else if (i == 1) allowDouble = val;
					else if (i == 2) allowBacktick = val;
				}
				return toTokenPos(TokenDef.String(allowSingle, allowDouble, allowBacktick), nogPos);
			default:
				doErr(nogPos, "Should be a list of arguments surrounded in round brackets");
				return null;
		}
	}
	
	function getLabel(nogPos:NogPos):String{
		var nog = nogPos.nog();
		switch(nog) {
			case Nog.Label(label, child1, child2):
				if (child2 != null) doErr(child2, "Child tokens are not accepted here");
				if (child1 != null) doErr(child1, "Child tokens are not accepted here");
				return label;
			default:
				doErr(nogPos, "Should be simple label here");
				return null;
		}
	}
	
	function isNogList(nogPos:NogPos, bracket:String) : Bool {
		var nog = nogPos.nog();
		switch(nog) {
			case Nog.Block(bracket, children):
				return true;
			default:
		}
		return false;
	}
	
	function interpNogList(nogPos:NogPos, lookups:Array<TokenPos>, identifierTypes:Array<String>, bracket:String) : Null<Array<TokenPos>> {
		var nog = nogPos.nog();
		switch(nog) {
			case Nog.Block(bracket, children):
				return interpNogArray(children, lookups, identifierTypes);
			default:
				doErr(nogPos, "Should be a list of tokens surrounded in brackets like "+bracket);
				return null;
		}
	}
	
	function interpNogArray(children:Array<NogPos>, lookups:Array<TokenPos>, identifierTypes:Array<String>) : Null<Array<TokenPos>> {
		var ret = [];
		for (child in children) {
			ret.push(interpNog(child, lookups, identifierTypes));
		}
		return ret;
	}
	
	function getNameValue(nogPos:NogPos) :Null<NameVal>
	{
		var nog:Nog = nogPos.nog();
		
		switch(nog) {
			case Nog.Label(label, child1, child2):
				if( child2 != null) {
					doErr(child2, "Unrecognised token");
					return null;
				}
				if (label != "name" && label != "fileExt") {
					doErr(child1, "Unrecognised metadata name");
					return null;
				}
				switch(child1.nog()) {
					case Nog.Op("=", child11, child12):
						switch(child11.nog()) {
							case Nog.Str(quote, str):
								return { name:label, value:str };
							default:
								doErr(child11, "Should be a string value");
								return null;
						}
					default:
						doErr(child1, "Should be an equals operator");
						return null;
				}
			default:
				doErr(nogPos, "Should be a label for metadata");
				return null;
		}
		
	}
	
	function doErr(nogPos:Nog.NogPos, str:String) {
		#if macro
			Context.error(str, Context.makePosition({ file:nogPos.file, min:nogPos.min, max:nogPos.max }) );
		#else
			throw str;
		#end
	}
	
	function doTokenErr(tokenPos:TokenPos, str:String) {
		#if macro
			Context.error(str, Context.makePosition({ file:tokenPos.file, min:tokenPos.min, max:tokenPos.max }) );
		#else
			throw str;
		#end
	}
	
}
typedef NameVal = {
	var name:String;
	var value:Dynamic;
}
typedef RefInfo = {
	var parentEnum:Null<EnumValue>;
	var parentArray:Null<Array<TokenDef>>;
	var index:Int;
	var ref:String;
}