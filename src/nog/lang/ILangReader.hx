package nog.lang;
import nog.lang.LangDef.TokenPos;
import nog.Nog.NogPos;


interface ILangReader <T>
{
	function getResult():T;
	function reset():Void;
	function read(nogPos:NogPos, langToken:TokenPos, withinNogs:Array<NogPos>, withinTokens:Array<TokenPos>):Void;
	function finish():Void;
}