package  
{
	import org.flixel.FlxGame;
	
	[SWF(width="640",height="480",backgroundColor="#333333")]
	[Frame(factoryClass = "Preloader")]
	
	public class BSPTut extends FlxGame 
	{
		
		public function BSPTut() 
		{
			super(640, 480, TestState, 1, 60, 60);
		}
		
	}

}