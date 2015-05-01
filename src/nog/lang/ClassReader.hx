package nog.lang;
import nog.lang.LangDef;
import nog.Nog;
import haxe.macro.Expr;

class ClassReader implements ILangReader<Module>
{
	public function getResult() : Module {
		return _result;
	}
	
	private var _result:Module;
	private var _moduleName:String;
	private var _types:Array<TypeDefinition>;

	public function new() 
	{
		reset();
	}
	
	public function reset():Void {
		_types = [];
	}
	
	public function finish():Void {
		_result = { moduleName:_moduleName, types:_types };
	}
	
	public function read(nogPos:NogPos, langToken:TokenPos, withinNogs:Array<NogPos>, withinTokens:Array<TokenPos>):Void {
		trace("langToken: "+langToken+" - "+nogPos);
	}
}


typedef Module = {
	public var moduleName:String;
	public var types:Array<TypeDefinition>;
}