package nog.lang.read;
import nog.lang.LangDef.TokenPos;
import nog.Nog.NogPos;
import nog.lang.LangDef;

interface ILangReader <T>
{
	function getResult():T;
	function reset():Void;
	function finish():Void;
	
	
	//function read(nogPos:NogPos, nogTrail:Array<NogPos>, nameTrail:Array<String>, identTrail:Array<Ident>):Void;
	
	/*function openNog(nogPos:NogPos):Void;
	function closeNog(nogPos:NogPos):Void;*/
	
	function openName(nogPos:NogPos, name:String):Void;
	function closeName(nogPos:NogPos, name:String):Void;
	
	function openIdent(nogPos:NogPos, type:String, ident:String):Void;
	function closeIdent(nogPos:NogPos, type:String, ident:String):Void;
	
	function openOp(nogPos:NogPos, op:String):Void;
	function closeOp(nogPos:NogPos, op:String):Void;
	
	function openBlock(nogPos:NogPos, bracket:String):Void;
	function blockSeparator(nogPos:NogPos):Void;
	function closeBlock(nogPos:NogPos, bracket:String):Void;
	
	function openLabel(nogPos:NogPos, label:String):Void;
	function closeLabel(nogPos:NogPos, label:String):Void;
	
	function openStr(nogPos:NogPos, str:String):Void;
	function closeStr(nogPos:NogPos, str:String):Void;
	
	function openInt(nogPos:NogPos, int:Int, hex:Bool):Void;
	function closeInt(nogPos:NogPos, int:Int, hex:Bool):Void;
	
	function openFloat(nogPos:NogPos, float:Float):Void;
	function closeFloat(nogPos:NogPos, float:Float):Void;
}