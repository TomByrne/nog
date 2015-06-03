package nog;
import nog.Nog;

using nog.NogUtils;

/**
 * A utility class to convert JSON formatted nog object literals into objects
 */
class NogJson
{

	
	static public function jsonNogToObject(nogPos:NogPos):Dynamic
	{
		return NogJson._jsonNogToObject(nogPos);
	}
	
	static private function _jsonNogToObject(nogPos:NogPos, ?nextRef:Pointer<NogPos>):Dynamic
	{
		var next = null;
		var ret:Dynamic = null;
		switch(NogUtils.nog(nogPos)) {
			case Block(Bracket.Curly, children, n, blockBreak):
				next = n;
				if (children.length > 1) {
					NogUtils.error(nogPos, "Literal object shouldn't contain line breaks or semi-colons");
				}else if (children.length == 0) {
					ret = {};
				}else{
					ret = {};
					populateJsonObj(children[0], ret);
				}
				
			case Block(Bracket.Square, children, n, blockBreak):
				next = n;
				if (children.length > 1) {
					NogUtils.error(nogPos, "Literal array shouldn't contain line breaks or semi-colons");
				}else if (children.length == 0) {
					ret = [];
				}else{
					ret = listToArray(children[0], true);
				}
				
			case Str(quote, val, n):
				next = n;
				ret = val;
				
			case Nog.Int(val, _, n):
				next = n;
				ret = val;
				
			case Float(val, n):
				next = n;
				ret = val;
				
			default:
				NogUtils.error(nogPos, "Unrecognised token");
		}
		if (next != null) {
			if(nextRef==null){
				NogUtils.error(next, "Unrecognised token");
			}else {
				nextRef.value = next;
			}
		}
		return ret;
	}
	
	static private function populateJsonObj(nogPos:NogPos, obj:Dynamic, separator:String = ","):Void
	{
		var nextProp = nogPos;
		while (nextProp!=null) {
			var colon = null;
			var prop = null;
			switch(nextProp.nog()) {
				case Str(_, val, next):
					prop = val;
					colon = next;
					
				default:
					NogUtils.error(nextProp, "Unrecognised token here");
					break;
			}
			nextProp = null;
			var valueNog = null;
			if (colon != null) {
				switch(NogUtils.nog(colon)) {
					case Op(":", next):
						valueNog = next;
						
					default:
						NogUtils.error(colon, "Unrecognised token here");
				}
			}else {
				break;
			}
			var comma:NogPos = null;
			if (valueNog != null) {
				var nextRef = { value:null };
				var value = _jsonNogToObject(valueNog, nextRef);
				Reflect.setProperty(obj, prop, value);
				comma = nextRef.value;
			}else {
				break;
			}
			if (comma != null) {
				switch(NogUtils.nog(comma)) {
					case Op(sep, next):
						if (sep != separator) {
							NogUtils.error(comma, "Unrecognised token here");
							break;
						}
						nextProp = next;
						
					default:
						NogUtils.error(comma, "Unrecognised token here");
				}
			}else {
				break;
			}
		}
	}
	
	static public function listToArray(nogPos:NogPos, asJson:Bool, separator:String = ","):Array<Dynamic>
	{
		var ret:Array<Dynamic> = [];
		var subject = nogPos;
		while (subject!=null) {
			var comma = null;
			switch(NogUtils.nog(subject)) {
				case Str(_, val, next):
					ret.push(val);
					comma = next;
					
				case Int(val, _, next):
					ret.push(val);
					comma = next;
					
				case Float(val, next):
					ret.push(val);
					comma = next;
					
				case Block(Bracket.Curly | Bracket.Square, children, next, blockBreak):
					if (!asJson) {
						NogUtils.error(subject, "Unrecognised token here");
						break;
					}
					var val = jsonNogToObject(subject);
					if (val != null) {
						ret.push(val);
					}
					
					comma = next;
					
				default:
					NogUtils.error(subject, "Unrecognised token here");
					break;
			}
			subject = null;
			if (comma != null) {
				switch(NogUtils.nog(comma)) {
					case Op(sep, next):
						if (sep != separator) {
							NogUtils.error(comma, "Unrecognised token here");
							break;
						}
						subject = next;
						
					default:
						NogUtils.error(comma, "Unrecognised token here");
				}
			}else {
				break;
			}
		}
		return ret;
	}
	
}
typedef Pointer<T> = {
	public var value:T;
}