package nog.lang.read;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Expr.TypeDefinition;
import nog.Nog;
import nog.lang.LangDef;

using Reflect;
using nog.NogUtils;

class ClassReader implements ILangReader<Module>
{
	
	public static var IDENT_MODULE:String = "module";
	public static var IDENT_TYPENAME:String = "typeName";
	public static var IDENT_EXTENDS:String = "extendsType";
	public static var IDENT_IMPLEMENTS:String = "implType";
	public static var IDENT_EXPR_IDENT:String = "exprIdent";
	public static var IDENT_METADATA_NAME:String = "metadataName";
	public static var IDENT_MEMBER_NAME:String = "memberName";
	public static var IDENT_MEMBER_TYPE:String = "memberType";
	public static var IDENT_ARG_NAME:String = "argName";
	public static var IDENT_ARG_TYPE:String = "argType";
	
	public static var NAME_INTERFACE:String = "interface";
	public static var NAME_CLASS:String = "class";
	public static var NAME_GETTER:String = "getter";
	public static var NAME_SETTER:String = "setter";
	public static var NAME_FUNCTION:String = "func";
	public static var NAME_ARG_DEFAULT:String = "argDefault";
	public static var NAME_STATIC_BLOCK:String = "staticBlock";
	public static var NAME_METADATA:String = "metadata";
	public static var NAME_VAR:String = "var";
	

	@:isVar public var typeSwap(default, set):Dynamic;
	public function set_typeSwap(value: Dynamic):Dynamic {
		this.typeSwap = value;
		var fields = value.fields();
		_typeSwap = new Map();
		for (n in fields){
			var cleanName = (n.charAt(0)=="_" ? n.substr(1) : n); // Some targets prepend an underscore in the case of keywords
			_typeSwap.set(cleanName, value.field(n));
		}
		return value;
	}

	public function getResult() : Module {
		return _result;
	}
	
	private var _result:Module;
	private var _moduleName:String;
	private var _types:Array<TypeDefinition>;
	private var _typeSwap:Map<String, String>;
	private var _usings:Array<TypePath>;
	private var _lastModule:String;
	private var _currentType:TypeDefinition;
	private var _nogPos:NogPos;
	private var _lastIsInterface:Bool;
	private var _lastInterfaces:Array<TypePath>;
	private var _lastSuperClass:TypePath;
	private var _currentFields:Array<Field>;
	private var _currentFieldMap:Map<String, Field>;
	
	private var _currentField:Field;
	private var _currentFieldType:ComplexType;
	private var _currentExprLists:Array<Array<Expr>>;
	private var _currentFieldContext:ExprContext;
	private var _currentFieldArgs:Array<FunctionArg>;
	
	private var _stack:Array<NogPos>;

	public function new() 
	{
		reset();
	}
	
	public function reset():Void {
		_types = [];
		_usings = [];
		_stack = [];
		resetType();
	}
	
	function resetType(){
		_currentType = null;
		_lastSuperClass = null;
		_lastIsInterface = false;
		_lastInterfaces = [];
		_currentFieldMap = new Map();
		resetField();
	}
	
	function resetField() 
	{
		_currentField = null;
		_currentFieldContext = null;
		_currentExprLists = [];
		_currentFieldArgs = [];
	}
	
	public function finish():Void {
		_result = { moduleName:_moduleName, types:_types, usings:_usings };
	}
	
	
	public function read(nogPos:NogPos, nogTrail:Array<NogPos>, nameTrail:Array<String>, identTrail:Array<Ident>):Void {
		
	}
	
	/*public function openNog(nogPos:NogPos):Void {
		_nogPos = nogPos;
	}
	public function closeNog(nogPos:NogPos):Void {
		if(_currentFieldContext!=null){
		}
	}*/
	
	public function openName(nogPos:NogPos, name:String):Void {
		_nogPos = nogPos;
		trace("openName: "+name);
		
		switch(name) {
			case ClassReader.NAME_CLASS:
				_lastIsInterface = false;
				recompileSuperClass();
				
			case ClassReader.NAME_INTERFACE:
				_lastIsInterface = true;
				recompileSuperClass();
				
			case ClassReader.NAME_STATIC_BLOCK:
				var field = getCurrentField("__init__");
				field.access.push(APublic);
				field.access.push(AStatic);
				_currentFieldContext = ExprContext.Func;
				recompileFieldKind();
		}
	}
	public function closeName(nogPos:NogPos, name:String):Void {
		_nogPos = nogPos;
		trace("closeName: "+name);
		
		switch(name) {
			case ClassReader.NAME_STATIC_BLOCK | ClassReader.NAME_FUNCTION | ClassReader.NAME_GETTER | ClassReader.NAME_SETTER:
				resetField();
		}
	}
	
	public function openIdent(nogPos:NogPos, type:String, ident:String):Void {
		_nogPos = nogPos;
		trace("openIdent: " + type+" " + ident);
		
		switch(type) {
			case ClassReader.IDENT_MODULE:
				_lastModule = ident;
				if (_currentType != null && _currentType.pack==null) {
					_currentType.pack = _lastModule.split(".");
				}
				
			case ClassReader.IDENT_TYPENAME:
				getCurrentType().name = ident;
				
			case ClassReader.IDENT_EXTENDS:
				_lastSuperClass = makeTypePath(ident);
				recompileSuperClass();
				
			case ClassReader.IDENT_IMPLEMENTS:
				_lastInterfaces.push(makeTypePath(ident));
				recompileSuperClass();
				
			case ClassReader.IDENT_EXPR_IDENT:
				getCurrentField();
				recompileFieldKind();
		}
	}
	
	public function closeIdent(nogPos:NogPos, type:String, ident:String):Void {
		_nogPos = nogPos;
		trace("closeIdent: "+type+" "+ident);
		
		switch(type) {
			case ClassReader.IDENT_TYPENAME:
				resetType();
		}
	}
	
	public function openOp(nogPos:NogPos, op:String):Void {
		if (_currentFieldContext != null) {
			_stack.push(nogPos);
		}
		trace("openOp: "+op);
	}
	public function closeOp(nogPos:NogPos, op:String):Void {
		if (_currentFieldContext != null) {
			clearStackTo(nogPos);
		}
		trace("closeOp: "+op);
	}
	
	public function openBlock(nogPos:NogPos, bracket:String):Void {
		if (_currentFieldContext != null) {
			_stack.push(nogPos);
		}
		trace("openBlock: "+bracket);
	}
	public function blockSeparator(nogPos:NogPos):Void {
		if (_currentFieldContext != null) {
			clearStackTo(nogPos, false);
		}
		trace("blockSeparator: ");
	}
	public function closeBlock(nogPos:NogPos, bracket:String):Void {
		if (_currentFieldContext != null) {
			clearStackTo(nogPos);
		}
		trace("closeBlock: "+bracket);
	}
	
	public function openLabel(nogPos:NogPos, label:String):Void {
		if (_currentFieldContext != null) {
			_stack.push(nogPos);
		}
		trace("openLabel: "+label);
	}
	public function closeLabel(nogPos:NogPos, label:String):Void {
		if (_currentFieldContext != null) {
			clearStackTo(nogPos);
		}
		trace("closeLabel: "+label);
	}
	
	public function openStr(nogPos:NogPos, str:String):Void {
		if (_currentFieldContext != null) {
			_stack.push(nogPos);
		}
		trace("openStr: "+str);
	}
	public function closeStr(nogPos:NogPos, str:String):Void {
		if (_currentFieldContext != null) {
			clearStackTo(nogPos);
		}
		trace("closeStr: "+str);
	}
	
	public function openInt(nogPos:NogPos, int:Int, hex:Bool):Void {
		if (_currentFieldContext != null) {
			_stack.push(nogPos);
		}
		trace("openInt: "+int);
	}
	public function closeInt(nogPos:NogPos, int:Int, hex:Bool):Void {
		if (_currentFieldContext != null) {
			clearStackTo(nogPos);
		}
		trace("closeInt: "+int);
	}
	
	public function openFloat(nogPos:NogPos, float:Float):Void {
		if (_currentFieldContext != null) {
			_stack.push(nogPos);
		}
		trace("openFloat: "+float);
	}
	public function closeFloat(nogPos:NogPos, float:Float):Void {
		if (_currentFieldContext != null) {
			clearStackTo(nogPos);
		}
		trace("closeFloat: "+float);
	}
	
	
	function makeTypePath(ident:String):TypePath {
		ident = swapType(ident);
		var lastDot = ident.lastIndexOf(".");
		if (lastDot == -1) {
			return { pack:[], name:ident, sub:null, params:null};
		}else {
			var pack = ident.substr(0, lastDot).split(".");
			ident = ident.substr(lastDot + 1);
			return { pack:pack, name:ident, sub:null, params:null};
		}
	}
	
	function swapType(type:String) 
	{
		if (_typeSwap.exists(type)) {
			return _typeSwap.get(type);
		}else {
			return type;
		}
	}
	
	private function getCurrentType():TypeDefinition {
		if (_currentType == null) {
			_currentFields = [];
			var pack = (_lastModule!=null ? _lastModule.split(".") : null);
			_currentType = { pos:_nogPos.position(), params:[], pack:pack, name:null, meta:null, kind:null, fields:_currentFields };
			_types.push(_currentType);
		}
		return _currentType;
	}
	
	private function recompileSuperClass():Void {
		getCurrentType().kind = TDClass(_lastSuperClass, _lastInterfaces, _lastIsInterface );
	}
	
	private function getCurrentField(?name:String):Field {
		getCurrentType();
		if (name != null) {
			if (_currentField!=null && _currentField.name == null) {
				_currentField.name = name;
				return _currentField;
			}
			var ret = _currentFieldMap.get(name);
			if (ret != null) {
				resetField();
				_currentField = ret;
				return ret;
			}
		}
		if (name != null || _currentField == null) {
			resetField();
			_currentField = { pos:_nogPos.position(), name:name, meta:null, kind:null, doc:null, access:[] };
			_currentFields.push(_currentField);
			if(name != null)_currentFieldMap.set(name, _currentField);
		}
		return _currentField;
	}
	
	private function recompileFieldKind():Void {
		switch(_currentFieldContext) {
			case ExprContext.Var:
				getCurrentField().kind = FVar (_currentFieldType, getCurrentExpr(true));
				
			/*case ExprContext.Getter:
				getCurrentField().kind = FVar (_currentFieldType, _currentExprs[0]);
				
			case ExprContext.Setter:
				getCurrentField().kind = FVar (_currentFieldType, _currentExprs[0]);*/
				
			case ExprContext.Func:
				getCurrentField().kind = FFun ({ret:_currentFieldType, params:[], args:_currentFieldArgs, expr:getCurrentExpr()});
		}
		trace(">> "+getCurrentField().kind);
	}
	
	function getCurrentExpr(limitToOne:Bool=false) :Expr
	{
		var list = _currentExprLists[0];
		if (list == null) return null;
		if (list.length > 1) {
			if (limitToOne) {
				_nogPos.error("Only accepts one expression here");
			}
			return { pos:_currentField.pos, expr:EBlock(list) };
		}else if(list.length == 1) {
			return list[0];
		}else {
			return null;
		}
	}
	
	function clearStackTo(nogPos:NogPos, remove:Bool=true) 
	{
		var i = _stack.length - 1;
		var lastExpr:Expr = null;
		var otherExpr:Expr = null;
		var pendingOp:String = null;
		while (i > 0) {
			var nog = _stack[i];
			var match = (nogPos == nog);
			var exprDef = null;
			
			if (!match || remove) {
				switch(nog.nog()) {
					case Nog.Float(value, _):
						exprDef = ExprDef.EConst(Constant.CFloat(Std.string(value)));
					case Nog.Int(value, _):
						exprDef = ExprDef.EConst(Constant.CInt(Std.string(value)));
					case Nog.Str(_, value, _):
						exprDef = ExprDef.EConst(Constant.CString(value));
					case Nog.Label(label, _):
						if (lastExpr != null) {
							exprDef = ExprDef.EField(lastExpr, label);
						}else {
							exprDef = ExprDef.EConst(Constant.CIdent(label));
						}
					case Nog.Block(bracket, _, _, _):
						// lookup nested expr group
						if (bracket == Bracket.Round) {
							// method call
						}else if (bracket == Bracket.Curly)  {
							// nested parenthesis group
						}else if (bracket == Bracket.Square)  {
							// array access
						}
					case Nog.Op(op, _):
						pendingOp = op;
					case Nog.Comment(_) | Nog.CommentMulti(_, _):
						// ignore
				}
				if (exprDef != null) {
					lastExpr = { expr:exprDef, pos:nog.position()};
				}else {
					lastExpr = null;
				}
				if (pendingOp!=null) {
					if(otherExpr!=null){
						switch(pendingOp) {
							case "=":
								exprDef = ExprDef.EBinop(Binop.OpAssign, lastExpr, otherExpr);
							case "+":
								exprDef = ExprDef.EBinop(Binop.OpAdd, lastExpr, otherExpr);
							case "-":
								exprDef = ExprDef.EBinop(Binop.OpSub, lastExpr, otherExpr);
							case "*":
								exprDef = ExprDef.EBinop(Binop.OpMult, lastExpr, otherExpr);
							case "/":
								exprDef = ExprDef.EBinop(Binop.OpDiv, lastExpr, otherExpr);
							case "||":
								exprDef = ExprDef.EBinop(Binop.OpOr, lastExpr, otherExpr);
							case ">":
								exprDef = ExprDef.EBinop(Binop.OpGt, lastExpr, otherExpr);
							case "<":
								exprDef = ExprDef.EBinop(Binop.OpLt, lastExpr, otherExpr);
							case "<<":
								exprDef = ExprDef.EBinop(Binop.OpShl, lastExpr, otherExpr);
							case ">>":
								exprDef = ExprDef.EBinop(Binop.OpShr, lastExpr, otherExpr);
							case "|":
								exprDef = ExprDef.EBinop(Binop.OpBoolOr, lastExpr, otherExpr);
							case "&":
								exprDef = ExprDef.EBinop(Binop.OpBoolAnd, lastExpr, otherExpr);
							case "+=":
								exprDef = ExprDef.EBinop(Binop.OpAssignOp(Binop.OpAdd), lastExpr, otherExpr);
							case "-=":
								exprDef = ExprDef.EBinop(Binop.OpAssignOp(Binop.OpSub), lastExpr, otherExpr);
							case "*=":
								exprDef = ExprDef.EBinop(Binop.OpAssignOp(Binop.OpMult), lastExpr, otherExpr);
							case "/=":
								exprDef = ExprDef.EBinop(Binop.OpAssignOp(Binop.OpDiv), lastExpr, otherExpr);
							case "|=":
								exprDef = ExprDef.EBinop(Binop.OpAssignOp(Binop.OpBoolOr), lastExpr, otherExpr);
							case "&=":
								exprDef = ExprDef.EBinop(Binop.OpAssignOp(Binop.OpBoolAnd), lastExpr, otherExpr);
							case "||=":
								exprDef = ExprDef.EBinop(Binop.OpAssignOp(Binop.OpOr), lastExpr, otherExpr);
							case "!=":
								exprDef = ExprDef.EBinop(Binop.OpNotEq, lastExpr, otherExpr);
							case ">=":
								exprDef = ExprDef.EBinop(Binop.OpGte, lastExpr, otherExpr);
							case "<=":
								exprDef = ExprDef.EBinop(Binop.OpLte, lastExpr, otherExpr);
							default:
								nog.error("Unsupported operator: " + pendingOp);
						}
						if (exprDef != null) {
							lastExpr = { expr:exprDef, pos:nog.position()};
						}else {
							lastExpr = null;
						}
						pendingOp = null;
						otherExpr = null;
					}else {
						otherExpr = lastExpr;
					}
				}
				
				_stack.pop();
			}
			if (match) break;
			
			i--;
		}
		var list = _currentExprLists[0];
		if (list==null) {
			list = [];
			_currentExprLists.push(list);
		}
		list.push(lastExpr);
	}
}


typedef Module = {
	public var moduleName:String;
	public var types:Array<TypeDefinition>;
	//public var imports:Array<ImportExpr>;
	public var usings:Array<TypePath>;
}

enum ExprContext {
	Var;
	//Getter;
	//Setter;
	Func;
}