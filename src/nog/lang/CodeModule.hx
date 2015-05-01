package nog.lang;

import nog.lang.CodeModule.Token;
import nog.Nog.NogPos;
import haxe.macro.Expr;
import haxe.macro.Type;

typedef CodeModule = 
{
	var module:String;
	var exprs:Map<String, TokenInfo<Expr>>;
	var types:Map<String, TokenInfo<Type>>;
	
}

typedef TokenInfo<T> =
{
	// lang def token from language definition object
	var langDef:LangDef;
	
	// nog token/position in code file
	var nog:NogPos;
	
	// value object
	var token:T;
}
