package nog.lang;
import haxe.macro.Context;
import nog.lang.LangDef.Pointer;
import nog.lang.LangDef.Ref;
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
	
	public var resolveRefs:Bool;

	public function new(inputString:String, resolveRefs:Bool=true) {
		_nogInterpretter = new NogInterpreter();
		this.inputString = inputString;
		this.resolveRefs = resolveRefs;
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
		var reader:String = null;
		var name:String = null;
		var rootDefs:Array<TokenPos> = [];
		var refs:Map<String, TokenPos> = new Map();
		var refList:Array<Ref> = [];
		var lookups:Array<TokenPos> = [];
		var identifierTypes:Array<String> = [];
		for (nogPos in res) {
			switch(nogPos.nog()) {
				case Nog.Op(op, child1, child2):
					if (child2 != null) {
						child2.error( "Unrecognised token: "+child2.toString());
					}
					if (op == "@") {
						// metadata
						var pair = getNameValue(child1);
						switch( pair.name ) {
							case "name" : name = pair.value;
							case "fileExt" : fileExt = pair.value;
							case "reader" : reader = pair.value;
						}
						
					}else if (op == "!") {
						// definition
						switch(child1.nog()) {
							case Nog.Label(label, child1, child2):
								// Define new symbol
								var token = interpNogRoot(child1, lookups, identifierTypes);
								refs.set(label, token);
								refList.push({name:label, value:token});
								
								if (child2 != null) {
									child2.error( "Unrecognised token: "+child2.toString());
								}
							default:
								child1.error("Should specify a symbol label here");
								
						}
						
					}else if (op == "-") {
						// root item/s
						rootDefs.push(interpNogRoot(child1, lookups, identifierTypes));
					}
				
				case Nog.Comment(_) | Nog.CommentMulti(_):
					// ignore
					
				default:
					nogPos.error( "Unrecognised token at language def root: "+nogPos.toString());
			}
		}
		
		if(resolveRefs){
			for (tokenPos in lookups) {
				switch(tokenPos.token()) {
					case TokenDef.Ref(id, ref, next):
						if (ref.value != null) continue;
						
						var resolved = refs.get(id);
						if (resolved==null) {
							tokenPos.doErr("Unrecognised reference token: "+id);
							continue;
						}
						ref.value = resolved;
					default:
							tokenPos.doErr("An unknown error occured, Non-reference token found in lookups listing");
				}
			}
		}
		var readerType = null;
		if (reader==null) {
			error("Reader must be specified in language definition with @reader tag");
		}
		#if macro
		// force reader class to be included in output
		Context.getModule(reader);
		#end
		
		_result = { fileExt:fileExt, name:name, rootDefs:rootDefs, identifierTypes:identifierTypes, symbols:refList, readerType:reader, file:currentFilePath };
	}
	
	inline private function error(str:String) {
		#if macro
			haxe.macro.Context.error(currentFilePath, haxe.macro.Context.makePosition({ file:currentFilePath, min:0, max:inputString.length }) );
		#else
			throw str;
		#end
	}
	
	function interpNogRoot(nogPos:NogPos, lookups:Array<TokenPos>, identifierTypes:Array<String>) : TokenPos{
		return interpNog(nogPos, lookups, identifierTypes);
	}
	
	function interpNog(nogPos:NogPos, lookups:Array<TokenPos>, identifierTypes:Array<String>, allowBlockEncap:Bool=false, childOverflow:Null<Pointer<NogPos>>=null) : Null<TokenPos> {
		if (nogPos == null) return null;
		
		var nog = nogPos.nog();
		switch(nog) {
			case Nog.Op(op, child1, child2):
				
				if ( op.charAt(0) == "\\" ) {
					if(op.length>1){
						if (child2 != null) errorOrOverflow(child2, childOverflow, "Unrecognised token: "+child2.toString());
						return TokenDef.LiteralOp(op.substr(1), interpNog(child1, lookups, identifierTypes)).nogPos(nogPos);
					}else {
						return makeLiteral(nogPos, child1, child2, lookups, identifierTypes, childOverflow).nogPos(nogPos);
					}
				}
				
				if(op == "+"){
					//if (child2 != null) child2.error( "Unrecognised token: "+child2.toString());
					return TokenDef.Multi(interpNog(child1, lookups, identifierTypes, true), 1, -1, interpNog(child2, lookups, identifierTypes)).nogPos(nogPos);
					
				}else if (op == "|") {
					return TokenDef.Alternate(interpNogList(child1, lookups, identifierTypes, "["), interpNog(child2, lookups, identifierTypes)).nogPos(nogPos);
					
				}else if (op == ":") {
					switch(child1.nog()) {
						case Nog.Label(label, child11, child12):
							if (identifierTypes.indexOf(label) == -1) identifierTypes.push(label);
							
							var c1;
							var c2 = null;
							var excess = null;
							if (child11 == null) {
								if (child12 == null) {
									c1 = child2;
								}else {
									c1 = child12;
									c2 = child2;
								}
							}else {
								c1 = child11;
								if (child12 == null) {
									c2 = child2;
								}else {
									c2 = child12;
									excess = child2;
								}
							}
							if ( excess!=null ) {
								errorOrOverflow(excess, childOverflow, "Unrecognised token: "+excess.toString());
							}
							var lookup = (c2 == null ? {value:null} : childOverflow);
							var c1Token = interpNog(child11, lookups, identifierTypes, false, lookup);
							if (c2 == null) c2 = lookup.value;
							var token = TokenDef.Ident(label, c1Token, interpNog(c2, lookups, identifierTypes, false, childOverflow));
							return token.nogPos(nogPos);
						default:
							child1.error( "Identifier type operator should be followed by a label");
							return null;
					}
					
				}else if (op == "^") {
					if (child2 != null)errorOrOverflow(child2, childOverflow, "Unrecognised token: "+child2.toString());
					switch(child1.nog()) {
						case Nog.Label(label, child11, child12):
							if (child12 != null)errorOrOverflow(child12, childOverflow, "Unrecognised token: "+child12.toString());
							if (identifierTypes.indexOf(label) == -1) identifierTypes.push(label);
							var c1Token = interpNog(child11, lookups, identifierTypes, false, childOverflow);
							var token = TokenDef.Named(label, interpNog(child11, lookups, identifierTypes, false, childOverflow));
							return token.nogPos(nogPos);
						default:
							child1.error( "Name type operator should be followed by a label");
							return null;
					}
					
				}else if (op == "!") {
					if (child2 != null) errorOrOverflow(child2, childOverflow, "Unrecognised token: "+child2.toString());
					switch(child1.nog()) {
						case Nog.Label(label, child11, child12):
							if (child12 != null) errorOrOverflow(child12, childOverflow, "Unrecognised token: "+child12.toString());
							var ret = TokenDef.Ref(label, {value:null}, interpNog(child11, lookups, identifierTypes)).nogPos(nogPos);
							lookups.push(ret);
							return ret;
						default:
							nogPos.error( "Should be simple label here");
							return null;
					}
					
				}else if (op == "$") {
					if (child2 != null) errorOrOverflow(child2, childOverflow, "Unrecognised token: "+child2.toString());
					switch(child1.nog()) {
						case Nog.Label(label, child11, child12):
							if (child12 != null) errorOrOverflow(child12, childOverflow, "Unrecognised token: "+child12.toString());
							switch(label) {
								case "Int":
									return TokenDef.Int.nogPos(nogPos);
								case "Float":
									return TokenDef.Float.nogPos(nogPos);
								case "String":
									return interpStringType(child11);
								default:
									child11.error("Unknown core type used");
									return null;
							}
						default:
							child1.error("Core type operator should be followed by a type name (e.g. Int)");
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
						return TokenDef.Optional(children[0], next).nogPos(nogPos);
					}else if (children.length == 0) {
						child1.error("Optional should have exactly one child expression");
						return null;
					}else {
						child1.error("Optional operator should only have one child expression");
						return null;
					}
					
				}else {
					child1.error( "Unrecognised operator");
					return null;
				}
				
			case Nog.Block(bracket, children):
				if (allowBlockEncap) {
					if (children.length == 1) {
						return interpNog(children[0], lookups, identifierTypes);
					}else{
						nogPos.error("This type of block can only have one child");
					}
				}else {
					nogPos.error("Unrecognised block");
				}
				return null;
				
			case Nog.Str(quote, str):
				return TokenDef.LiteralStr(quote, str).nogPos(nogPos);
				
			case Label(label, child1, child2):
				nogPos.error("Unrecognised label");
				return null;
				
			case Nog.Comment(_) | Nog.CommentMulti(_):
				return null;
				
			case Nog.Int(_, _) | Nog.Float(_):
				nogPos.error("Numbers have no meaning here");
				return null;
		}
	}
	
	function makeLiteral(parent:NogPos, nogPos1:NogPos, nogPos2:NogPos, lookups:Array<TokenPos>, identifierTypes:Array<String>, childOverflow:Null<Pointer<NogPos>>) : Null<TokenDef> 
	{
		if (nogPos1 == null) {
			parent.error( "Literal operator should be following by at least one token");
			return null;
		}
		switch( nogPos1.nog() ) {
			case Nog.Str(quote, string):
				return TokenDef.LiteralStr(quote, string);
				
			case Nog.Op(op, child1, child2):
				var c1;
				var c2 = null;
				var excess = null;
				if (child1 == null) {
					if (child2 == null) {
						c1 = nogPos2;
					}else {
						c1 = child2;
						c2 = nogPos2;
					}
				}else {
					c1 = child1;
					if (child2 == null) {
						c2 = nogPos2;
					}else {
						c2 = child2;
						excess = nogPos2;
					}
				}
				if ( excess!=null ) {
					errorOrOverflow(excess, childOverflow, "Unrecognised token: "+excess.toString());
				}
				return TokenDef.LiteralOp(op, interpNog(c1, lookups, identifierTypes), interpNog(c2, lookups, identifierTypes));
				
			case Nog.Label(label, child1, child2):
				if ( child1!=null && child2!=null && nogPos2!=null ) {
					parent.error( "Too many tokens in under literal operator");
					return null;
				}
				var c1;
				var c2 = null;
				var excess = null;
				if (child1 == null) {
					if (child2 == null) {
						c1 = nogPos2;
					}else {
						c1 = child2;
						c2 = nogPos2;
					}
				}else {
					c1 = child1;
					if (child2 == null) {
						c2 = nogPos2;
					}else {
						c2 = child2;
						excess = nogPos2;
					}
				}
				if ( excess!=null ) {
					errorOrOverflow(excess, childOverflow, "Unrecognised token: "+excess.toString());
				}
				var lookup = (c2 == null ? {value:null} : null);
				var c1Token = interpNog(c1, lookups, identifierTypes, false, lookup);
				if (c2 == null) c2 = lookup.value;
				
				return TokenDef.LiteralLabel(label, c1Token, interpNog(c2, lookups, identifierTypes));
				
			case Nog.Block(bracket, children):
				if ( nogPos2!=null ) {
					errorOrOverflow(nogPos2, childOverflow, "Unrecognised token: "+nogPos2.toString());
				}
				var children2:Array<TokenPos> = [];
				for (child in children) {
					var childToken = interpNog(child, lookups, identifierTypes);
					if(childToken!=null)children2.push(childToken);
				}
				return TokenDef.LiteralBlock(bracket, children2);
				
			case Nog.Comment(_) | Nog.CommentMulti(_):
				parent.error( "Literal Comments not supported");
				return null;
				
			case Nog.Int(_, _) | Nog.Float(_):
				parent.error( "Literal Numbers not supported");
				return null;
		}
	}
	
	function errorOrOverflow(nogPos:NogPos, overflow:Null<Pointer<NogPos>>, err:String) 
	{
		if (nogPos != null) {
			if (overflow != null && overflow.value==null) {
				overflow.value = nogPos;
			}else {
				nogPos.error(err);
			}
		}
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
				return TokenDef.String(allowSingle, allowDouble, allowBacktick).nogPos(nogPos);
			default:
				nogPos.error( "Should be a list of arguments surrounded in round brackets");
				return null;
		}
	}
	
	function getLabel(nogPos:NogPos):String{
		var nog = nogPos.nog();
		switch(nog) {
			case Nog.Label(label, child1, child2):
				if (child1 != null) child1.error("Child tokens are not accepted here");
				if (child2 != null) child2.error("Child tokens are not accepted here");
				return label;
			default:
				nogPos.error("Should be simple label here");
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
				nogPos.error( "Should be a list of tokens surrounded in brackets like "+bracket);
				return null;
		}
	}
	
	function interpNogArray(children:Array<NogPos>, lookups:Array<TokenPos>, identifierTypes:Array<String>) : Null<Array<TokenPos>> {
		var ret = [];
		for (child in children) {
			var ch = interpNog(child, lookups, identifierTypes);
			if(ch!=null)ret.push(ch);
		}
		return ret;
	}
	
	function getNameValue(nogPos:NogPos) :Null<NameVal>
	{
		var nog:Nog = nogPos.nog();
		
		switch(nog) {
			case Nog.Label(label, child1, child2):
				if( child2 != null) {
					child2.error( "Unrecognised token: "+child2.toString());
					return null;
				}
				if (label != "name" && label != "fileExt" && label != "reader") {
					child1.error( "Unrecognised metadata name");
					return null;
				}
				switch(child1.nog()) {
					case Nog.Op("=", child11, child12):
						switch(child11.nog()) {
							case Nog.Str(quote, str):
								return { name:label, value:str };
							default:
								child11.error("Should be a string value");
								return null;
						}
					default:
						child1.error( "Should be an equals operator");
						return null;
				}
			default:
				nogPos.error("Should be a label for metadata");
				return null;
		}
		
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