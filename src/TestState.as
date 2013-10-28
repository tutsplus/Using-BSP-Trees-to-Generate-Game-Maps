package
{
	import flash.display.BitmapData;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import org.flixel.FlxButton;
	import org.flixel.FlxG;
	import org.flixel.FlxGroup;
	import org.flixel.FlxSprite;
	import org.flixel.FlxState;
	import org.flixel.FlxTilemap;
	
	public class TestState extends FlxState
	{
		// embed our graphics
		[Embed(source="tiles.png")]
		private var ImgTiles:Class;
		[Embed(source="guy.png")]
		private var ImgGuy:Class;
		
		private var _mapData:BitmapData;		// our map Data - we draw our map here to be turned into a tilemap later
		private var _rooms:Vector.<Rectangle>;	// a Vector that holds all our rooms
		private var _halls:Vector.<Rectangle>;	// a Vector that holds all our halls
		private var _leafs:Vector.<Leaf>;		// a Vector that holds all our leafs
		private var _grpGraphicMap:FlxGroup;	// group for holding the map sprite, so it stays behind the UI elements
		private var _grpTestMap:FlxGroup;		// group for holding the tilemap for testing, so it stays behind the UI and player 
		private var _grpUI:FlxGroup;			// group for the UI to be in front of everything
		private var _button:FlxButton;			// button to make a new map
		private var _buttonPlaymap:FlxButton;	// button to switch to play mode
		private var _sprMap:FlxSprite;			// sprite to hold a scaled version of our map to show on the screen
		private var _map:FlxTilemap;			// the tilemap for testing out the map
		private var _player:FlxSprite;			// the player sprite that you can move around
		
		override public function create():void
		{
			add(_grpGraphicMap = new FlxGroup());
			add(_grpTestMap = new FlxGroup());			
			
			// We need to create a sprite to display our Map - it will be scaled up to fill the screen.
			// our map Sprite will be the size of or finished tileMap/tilesize.
			_sprMap = new FlxSprite(FlxG.width / 2 - FlxG.width / 32, FlxG.height / 2 - FlxG.height / 32).makeGraphic(FlxG.width / 16, FlxG.height / 16, 0x0);
			_sprMap.scale.x = 16;
			_sprMap.scale.y = 16;
			
			_grpGraphicMap.add(_sprMap);
			_grpTestMap.visible = false;
			
			// add player sprite.
			add(_player = new FlxSprite(0, 0, ImgGuy));
			_player.visible = false;
			_player.width = 12;
			_player.height = 12;
			_player.offset.x = 1;
			_player.offset.y = 1;
			
			// setup UI
			add(_grpUI = new FlxGroup());
			_button = new FlxButton(10, 10, "Generate", GenerateMap);
			_buttonPlaymap = new FlxButton(_button.x + _button.width + 10, 10, "Play", PlayMap);
			_grpUI.add(_button);
			_grpUI.add(_buttonPlaymap)
			
			_buttonPlaymap.visible = false;
			
			FlxG.mouse.show();
			
			GenerateMap();
		}
		
		private function PlayMap():void
		{
			// switch to 'play' mode
			_grpTestMap.visible = true;
			_grpGraphicMap.visible = false;
			_buttonPlaymap.visible = false;
			_player.visible = true;
			
			// turn our map Data into CSV, and make a new Tilemap out of it
			var newMap:FlxTilemap = new FlxTilemap().loadMap(FlxTilemap.bitmapToCSV(_mapData), ImgTiles, 16, 16, FlxTilemap.OFF, 0, 0, 1);
			if (_map != null)
			{
				// if an old map exists, replace it with our new map
				var oldMap:FlxTilemap = _map;
				_grpTestMap.replace(oldMap, newMap);
				oldMap.kill();
				oldMap.destroy();
			}
			else
			{
				// if no old map exists (first time we hit 'play'), add the new map to the group
				_grpTestMap.add(newMap);
			}
			_map = newMap;
		
		}
		
		private function GenerateMap():void
		{
			// reset our mapData
			_mapData = new BitmapData(_sprMap.width, _sprMap.height, false, 0xff000000);
			
			// setup the screen/UI
			_grpTestMap.visible = false;
			_grpGraphicMap.visible = true;
			_player.visible = false;
			
			// reset our Vectors 
			_rooms = new Vector.<Rectangle>;
			_halls = new Vector.<Rectangle>;
			_leafs = new Vector.<Leaf>;
			
			var l:Leaf; // helper leaf
			
			// first, create a leaf to be the 'root' of all leaves.
			var root:Leaf = new Leaf(0, 0, _sprMap.width, _sprMap.height);
			_leafs.push(root);
			
			var did_split:Boolean = true;
			// we loop through every leaf in our Vector over and over again, until no more leafs can be split.
			while (did_split)
			{
				did_split = false;
				for each (l in _leafs)
				{
					if (l.leftChild == null && l.rightChild == null) // if this leaf is not already split...
					{
						// if this leaf is too big, or 75% chance...
						if (l.width > Registry.MAX_LEAF_SIZE || l.height > Registry.MAX_LEAF_SIZE || FlxG.random() > 0.25)
						{
							if (l.split()) // split the leaf!
							{
								// if we did split, push the child leafs to the Vector so we can loop into them next
								_leafs.push(l.leftChild);
								_leafs.push(l.rightChild);
								did_split = true;
							}
						}
					}
				}
			}
			
			// next, iterate through each leaf and create a room in each one.
			root.createRooms();
			
			for each (l in _leafs)
			{
				// then we draw the room and hallway if it exists
				if (l.room != null)
				{
					drawRoom(l.room);
				}
				
				if (l.halls != null && l.halls.length > 0)
				{
					drawHalls(l.halls);
				}
			}
			
			// randomly pick one of the rooms for the player to start in...
			var startRoom:Rectangle = _rooms[Registry.randomNumber(0, _rooms.length - 1)];
			// and pick a random tile in that room for them to start on.
			var _playerStart:Point = new Point(Registry.randomNumber(startRoom.x, startRoom.x + startRoom.width - 1), Registry.randomNumber(startRoom.y, startRoom.y + startRoom.height - 1));
			
			// move the player sprite to the starting location (to get ready for the user to hit 'play')
			_player.x = _playerStart.x * 16 + 1;
			_player.y = _playerStart.y * 16 + 1;
			
			// make our map Sprite's pixels a copy of our map Data BitmapData. Tell flixel the sprite is 'dirty' (so it flushes the cache for that sprite)
			_sprMap.pixels = _mapData.clone();
			_sprMap.dirty = true;
			
			_buttonPlaymap.visible = true;
		
		}
		
		private function drawHalls(h:Vector.<Rectangle>):void
		{
			// add each hall to the hall vector, and draw the hall onto our mapData
			for each (var r:Rectangle in h)
			{
				_halls.push(r);
				_mapData.fillRect(r, FlxG.WHITE);
				
			}
		}
		
		private function drawRoom(r:Rectangle):void
		{
			// add this room to the room vector, and draw the room onto our mapData
			_rooms.push(r);
			_mapData.fillRect(r, FlxG.WHITE);
		
		}
		
		override public function update():void
		{
			super.update();
			
			if (_grpTestMap.visible)
			{
				
				// if we're in 'play' mode, arrow keys move the player
				
				if (FlxG.keys.LEFT)
				{
					_player.velocity.x = -100;
				}
				else if (FlxG.keys.RIGHT)
				{
					_player.velocity.x = 100;
				}
				else
				{
					_player.velocity.x = 0;
				}
				
				if (FlxG.keys.UP)
				{
					_player.velocity.y = -100;
				}
				else if (FlxG.keys.DOWN)
				{
					_player.velocity.y = 100;
				}
				else
				{
					_player.velocity.y = 0;
				}
				
				// check collison with the wall tiles in the map
				FlxG.collide(_player, _map);
			}
		}
	
	}

}