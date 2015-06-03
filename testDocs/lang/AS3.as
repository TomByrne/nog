package org.tbyrne.test {
	
	public class PubClass extends String implements int{

		{
			// Static block
			trace("YAY");
		}

		/*[Inject]
		public function func1(arg1:Int, arg2:Int=0):String{
			prop1 = "hello";
			arg1 = arg1 * arg1 = hello - "String";
			arg1 *= arg1;
			arg1 += arg1;
			arg1 -= arg1;
			arg1 /= arg1;
			arg1 ^= arg1;
			arg1 != arg1;
			arg1 %= arg1;
			arg1 |= arg1;

			arg1 * arg1;
			arg1 + arg1;
			arg1 - arg1;
			arg1 / arg1;
			arg1 ^ arg1;
			arg1 ! arg1;
			arg1 % arg1;
			arg1 | arg1;

			if(arg1 != arg2 ){
				arg1 %= arg1;
			}
			for(arg1 != arg2; arg1 != arg2; arg1 != arg2 ){
				arg1 != arg2;
			}
		}

		[Inject("Test")]
		private var bool:Boolean = true;

		[Inject(test="Test")]
		private var integer:int = 0x33;

		//[Inject(test="Test", "Hi")]
		private var float:Number = -1.9;

		private var string:String = "Hello";*/

	}
}