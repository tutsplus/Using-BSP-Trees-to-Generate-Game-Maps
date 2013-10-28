package
{
	import org.flixel.FlxG;
	
	public class Registry
	{
		
		static public const MIN_LEAF_SIZE:int = 6;	// minimum size for a leaf
		static public const MAX_LEAF_SIZE:int = 20;	// maximum size for a leaf
		
		// function to easily generate a random number between a range
		static public function randomNumber(min:Number, max:Number, Absolute:Boolean = false):Number
		{
			if (!Absolute)
			{
				return Math.floor(FlxG.random() * (1 + max - min) + min);
			}
			else
			{
				return Math.abs(Math.floor(FlxG.random() * (1 + max - min) + min));
			}
		}
	
	}

}