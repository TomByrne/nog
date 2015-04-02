package nog.lang;
import stringParser.core.IInterpretter;
import stringParser.core.StringParserIterator;

class LangInterpretter implements IInterpretter
{
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
	
	private var _result:Dynamic;
	private var _resultWas:Dynamic;
	private var _nogInterpretter:NogInterpretter;
	private var _langDef:LangDef;

	public function new(langDef:LangDef, inputString:String) {
		_langDef = langDef;
		_nogInterpretter = new NogInterpretter();
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
		
		_result = { fileExt:"hm", name:"hm", rootDefs:[] };
	}
	
}