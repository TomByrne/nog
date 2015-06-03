package nog.lang;
import haxe.macro.Context;
import nog.lang.LangDef.LangMeta;
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
		var name:String = null;
		var readerType:String = null;
		var meta:Array<LangMeta> = [];
		
		var rootDefs:Array<TokenPos> = [];
		var refs:Map<String, TokenPos> = new Map();
		var refList:Array<Ref> = [];
		var lookups:Array<TokenPos> = [];
		var identifierTypes:Array<String> = [];
		for (nogPos in res) {
			switch(nogPos.nog()) {
				case Nog.Op(op, next):
					if (op == "@") {
						// metadata
						var metaObj = getMetaOperation(next);
						if (metaObj != null) {
							switch(metaObj) {
								case SetProp(nogPos, target, fields, value):
									if (target != "reader" || fields.length == 0) {
										
										if (fields.length > 0) {
											nogPos.error("Cannot set child property on this metadata");
											
										}else if (Type.getClassName(Type.getClass(value)) != "String") { // For some reason Std.is isn't working here
											nogPos.error("This metadata must be set to a String: ");
											
										}else if(target == "fileExt"){
											fileExt = value;
										}else if(target == "name"){
											name = value;
										}else if(target == "reader"){
											readerType = value;
										}
									}else{
										meta.push(metaObj);
									}
									
								case CallMethod(nogPos, target, fields, args):
									if (target != "reader") {
										nogPos.error("Cannot call method on this metadata");
									}else{
										meta.push(metaObj);
									}
							}
						}
						
					}else if (op == "!") {
						// definition
						switch(next.nog()) {
							case Nog.Label(label, next2):
								// Define new symbol
								var token = interpNogRoot(next2, lookups, identifierTypes);
								refs.set(label, token);
								refList.push({name:label, value:token});
							default:
								next.error("Should specify a symbol label here");
								
						}
						
					}else if (op == "-") {
						// root item/s
						rootDefs.push(interpNogRoot(next, lookups, identifierTypes));
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
		if (readerType==null) {
			error("Reader must be specified in language definition with @reader tag");
		}
		#if macro
		// force reader class to be included in output
		Context.getModule(readerType);
		#end
		
		_result = { fileExt:fileExt, name:name, rootDefs:rootDefs, identifierTypes:identifierTypes, symbols:refList, readerType:readerType, file:currentFilePath, metadata:meta };
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
	
	function interpNog(nogPos:NogPos, lookups:Array<TokenPos>, identifierTypes:Array<String>, allowBlockEncap:Bool=false) : Null<TokenPos> {
		if (nogPos == null) return null;
		
		var nog = nogPos.nog();
		switch(nog) {
			case Nog.Op(op, next):
				
				if ( op.charAt(0) == "\\" ) {
					if(op.length>1){
						return TokenDef.LiteralOp(op.substr(1), interpNog(next, lookups, identifierTypes)).nogPos(nogPos);
					}else {
						return makeLiteral(nogPos, next, lookups, identifierTypes).nogPos(nogPos);
					}
				}
				
				if (op == "|") {
					var listRes = interpNogList(next, lookups, identifierTypes, "[");
					if (listRes == null) {
						next.error( "Alternatve operator should be followed by tokens");
						return null;
					}else{
						return TokenDef.Alternate(listRes.list, listRes.next).nogPos(nogPos);
					}
					
				}else if (op == ":") {
					if (next==null) {
						next.error( "Identifier type operator should be followed by a label");
						return null;
					}
					switch(next.nog()) {
						case Nog.Label(label, next2):
							if (identifierTypes.indexOf(label) == -1) identifierTypes.push(label);
							var c1Token = interpNog(next2, lookups, identifierTypes, false);
							var token = TokenDef.Ident(label, null, c1Token);
							return token.nogPos(nogPos);
							
						case Nog.Block(Bracket.Square, children, next2, blockBreak):
							if (children.length > 1) {
								next.error( "Identifier array should not contain any line breaks or semi-colons");
								return null;
							}else if (children.length == 0) {
								next.error( "Identifier array should contain a label and separator");
								return null;
							}
							var labelNog = children[0];
							switch(labelNog.nog()) {
								case Nog.Label(label, next3):
									if (next3 == null) {
										labelNog.error( "Identifier array label should be followed by separator");
										return null;
									}
									switch(next3.nog()) {
										case Nog.Op(op, next4):
											if (next4 != null) {
												next4.error( "Identifier array separator should not be followed");
												return null;
											}
											if (identifierTypes.indexOf(label) == -1) identifierTypes.push(label);
											var c1Token = interpNog(next2, lookups, identifierTypes, false);
											var token = TokenDef.Ident(label, op, c1Token);
											return token.nogPos(nogPos);
										default:
											labelNog.error( "Identifier array label should be followed by separator");
											return null;
									}
									
								default:
									next.error( "Should be label token here");
									return null;
							}
							
							
						default:
							next.error( "Identifier type operator should be followed by a label");
							return null;
					}
					
				}else if (op == "^") {
					if (next==null) {
						next.error( "Name type operator should be followed by a label");
						return null;
					}
					switch(next.nog()) {
						case Nog.Label(label, next2):
							if (identifierTypes.indexOf(label) == -1) identifierTypes.push(label);
							var token = TokenDef.Named(label, interpNog(next2, lookups, identifierTypes, false));
							return token.nogPos(nogPos);
						default:
							next.error( "Name type operator should be followed by a label");
							return null;
					}
					
				}else if (op == "!") {
					if (next==null) {
						next.error( "Should be simple label here");
						return null;
					}
					switch(next.nog()) {
						case Nog.Label(label, next2):
							var ret = TokenDef.Ref(label, {value:null}, interpNog(next2, lookups, identifierTypes)).nogPos(nogPos);
							lookups.push(ret);
							return ret;
						default:
							next.error( "Should be simple label here");
							return null;
					}
					
				}else if (op == "$") {
					if (next==null) {
						next.error("Core type operator should be followed by a type name (e.g. Int)");
						return null;
					}
					switch(next.nog()) {
						case Nog.Label(label, next2):
							switch(label) {
								case "Int":
									return TokenDef.Int(interpNog(next2, lookups, identifierTypes)).nogPos(nogPos);
								case "Float":
									return TokenDef.Float(interpNog(next2, lookups, identifierTypes)).nogPos(nogPos);
								case "String":
									return interpStringType(next2, lookups, identifierTypes);
								default:
									next.error("Unknown core type used");
									return null;
							}
						default:
							next.error("Core type operator should be followed by a type name (e.g. Int)");
							return null;
					}
					
				}else if (op == "?") {
					var children = null;
					var next2 = null;
					if (isNogList(next, "[")) {
						var listRes = interpNogList(next, lookups, identifierTypes, "[");
						if (listRes != null) {
							children = listRes.list;
							next2 = listRes.next;
						}
					}else {
						children = [interpNog(next, lookups, identifierTypes)];
					}
					if(children!=null && children.length==1){
						//var next = interpNog(child2, lookups, identifierTypes);
						return TokenDef.Optional(children[0], next2).nogPos(nogPos);
					}else if (children==null || children.length == 0) {
						next.error("Optional operator should have exactly one child expression");
						return null;
					}else {
						next.error("Optional operator should only have one child expression");
						return null;
					}
					
				}else if(op == "+"){
					var children = null;
					var next2 = null;
					if (isNogList(next, "[")) {
						var listRes = interpNogList(next, lookups, identifierTypes, "[");
						if (listRes != null) {
							children = listRes.list;
							next2 = listRes.next;
						}
					}else {
						children = [interpNog(next, lookups, identifierTypes)];
					}
					if(children!=null && children.length==1){
						//var next = interpNog(child2, lookups, identifierTypes);
						return TokenDef.Multi(children[0], 1, -1, next2).nogPos(nogPos);
					}else if (children==null || children.length == 0) {
						next.error("Multi operator should have exactly one child expression");
						return null;
					}else {
						next.error("Multi operator should only have one child expression");
						return null;
					}
					
				}else {
					next.error( "Unrecognised operator");
					return null;
				}
				
			case Nog.Block(bracket, children, next2, blockBreak):
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
				
			case Nog.Str(quote, str, next2):
				return TokenDef.LiteralStr(quote, str, interpNog(next2, lookups, identifierTypes)).nogPos(nogPos);
				
			case Label(label, next2):
				nogPos.error("Unrecognised label");
				return null;
				
			case Nog.Comment(_):
				return null;
				
			case Nog.CommentMulti(_, next2):
				return next2==null ? null : interpNog(next2, lookups, identifierTypes);
				
			case Nog.Int(_, _, next2) | Nog.Float(_, next2):
				nogPos.error("Numbers have no meaning here");
				return null;
		}
	}
	
	function makeLiteral(parent:NogPos, nogPos1:NogPos, lookups:Array<TokenPos>, identifierTypes:Array<String>) : Null<TokenDef> 
	{
		if (nogPos1 == null) {
			parent.error( "Literal operator should be following by at least one token");
			return null;
		}
		switch( nogPos1.nog() ) {
			case Nog.Str(quote, string, next):
				return TokenDef.LiteralStr(quote, string, interpNog(next, lookups, identifierTypes));
				
			case Nog.Op(op, next):
				return TokenDef.LiteralOp(op, interpNog(next, lookups, identifierTypes));
				
			case Nog.Label(label, next):
				var c1Token = interpNog(next, lookups, identifierTypes, false);
				return TokenDef.LiteralLabel(label, c1Token);
				
			case Nog.Block(bracket, children, next, blockBreak):
				var children2:Array<TokenPos> = [];
				for (child in children) {
					var childToken = interpNog(child, lookups, identifierTypes);
					if(childToken!=null)children2.push(childToken);
				}
				return TokenDef.LiteralBlock(bracket, children2, interpNog(next, lookups, identifierTypes));
				
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
	
	function interpStringType(nogPos:NogPos, lookups:Array<TokenPos>, identifierTypes:Array<String>) : TokenPos{
		var nog = nogPos.nog();
		var bracket = "(";
		switch(nog) {
			case Nog.Block(bracket, children, next2, blockBreak):
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
				return TokenDef.String(allowSingle, allowDouble, allowBacktick, interpNog(next2, lookups, identifierTypes)).nogPos(nogPos);
			default:
				nogPos.error( "Should be a list of arguments surrounded in round brackets");
				return null;
		}
	}
	
	function getLabel(nogPos:NogPos):String{
		var nog = nogPos.nog();
		switch(nog) {
			case Nog.Label(label, next):
				if (next != null) next.error("Child tokens are not accepted here");
				return label;
			default:
				nogPos.error("Should be simple label here");
				return null;
		}
	}
	
	function isNogList(nogPos:NogPos, bracket:String) : Bool {
		var nog = nogPos.nog();
		switch(nog) {
			case Nog.Block(bracket, children, next, blockBreak):
				return true;
			default:
		}
		return false;
	}
	
	function interpNogList(nogPos:NogPos, lookups:Array<TokenPos>, identifierTypes:Array<String>, bracket:String) : Null<ListRes> {
		var nog = nogPos.nog();
		switch(nog) {
			case Nog.Block(bracket, children, next, blockBreak):
				return {list:interpNogArray(children, lookups, identifierTypes), next:interpNog(next, lookups, identifierTypes)};
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
	
	function getMetaOperation(nogPos:NogPos) : LangMeta
	{
		var topNog = nogPos;
		var nog:Nog = nogPos.nog();
		
		var fieldPath = NogUtils.followPropPath(nogPos);
		var target = fieldPath.fields.shift();
		
		if (target != "name" && target != "fileExt" && target != "reader") {
			fieldPath.next.error( "Unrecognised metadata name: "+target);
			return null;
		}
		
		switch(fieldPath.next.nog()) {
			case Nog.Op("=", next2):
				switch(next2.nog()) {
					case Nog.Str(_, value, next3):
						if (next3 != null) {
							next3.error("Unrecognised token here");
						}
						return SetProp(topNog, target, fieldPath.fields, value);
						
					case Nog.Int(value, _, next3):
						if (next3 != null) {
							next3.error("Unrecognised token here");
						}
						return SetProp(topNog, target, fieldPath.fields, value);
						
					case Nog.Float(value, next3):
						if (next3 != null) {
							next3.error("Unrecognised token here");
						}
						return SetProp(topNog, target, fieldPath.fields, value);
						
					case Nog.Block(Bracket.Curly, children, next3, blockBreak):
						if (next3 != null) {
							next3.error("Unrecognised token here");
						}
						return SetProp(topNog, target, fieldPath.fields, NogJson.jsonNogToObject(next2));
						
					case Nog.Block(Bracket.Square, children, next3, blockBreak):
						if (next3 != null) {
							next3.error("Unrecognised token here");
						}
						return SetProp(topNog, target, fieldPath.fields, NogJson.jsonNogToObject(next2));
						
					default:
						next2.error( "Should be a value following");
						return null;
				}
			case Nog.Op(Bracket.Round, next2):
				return CallMethod(topNog, target, fieldPath.fields, NogJson.listToArray(next2, true));
				
			default:
				fieldPath.next.error( "Should be an equals operator: "+fieldPath.next);
				return null;
		}
		
	}
	
}
typedef RefInfo = {
	var parentEnum:Null<EnumValue>;
	var parentArray:Null<Array<TokenDef>>;
	var index:Int;
	var ref:String;
}

typedef ListRes = {
	var next:Null<TokenPos>;
	var list:Array<TokenPos>;
}