package
{
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import org.flixel.FlxG;
	
	public class Leaf
	{
		
		public var y:int, x:int, width:int, height:int;		// the position and size of this leaf
		
		public var leftChild:Leaf;				// the leaf's left child leaf
		public var rightChild:Leaf;				// the leaf's right child leaf
		public var room:Rectangle;				// the room that is inside this leaf
		public var halls:Vector.<Rectangle>;	// hallways to connect this leaf to other leafs
		
		public function Leaf(X:int, Y:int, Width:int, Height:int)
		{
			// initialize our leaf
			x = X;
			y = Y;
			width = Width;
			height = Height;
		}
		
		public function split():Boolean
		{
			// begin splitting the leaf into 2 children
			
			if (leftChild != null || rightChild != null)
				return false; // we're already split! Abort!
			
			// determine direction of split
			// if the width is >25% larger than height, we split vertically
			// if the height is >25% larger than the width, we split horizontally
			// otherwise we split randomly
			
			var splitH:Boolean = FlxG.random() > 0.5;
			
			if (width > height && height / width >= 0.05)
				splitH = false;
			else if (height > width && width / height >= 0.05)
				splitH = true;
			
			var max:int = (splitH ? height : width) - Registry.MIN_LEAF_SIZE; // determine the maximum height or width
			if (max <= Registry.MIN_LEAF_SIZE)
				return false; // the area is too small to split any more...
			
			var split:int = Registry.randomNumber(Registry.MIN_LEAF_SIZE, max); // determine where we're going to split
			
			// create our left and right children based on the direction of the split
			if (splitH)
			{
				leftChild = new Leaf(x, y, width, split);
				rightChild = new Leaf(x, y + split, width, height - split);
			}
			else
			{
				leftChild = new Leaf(x, y, split, height);
				rightChild = new Leaf(x + split, y, width - split, height);
			}
			return true; // split successful!
		}
		
		public function getRoom():Rectangle
		{
			// iterate all the way down these leafs to find a room, if one exists.
			if (room != null)
				return room;
			else
			{
				var lRoom:Rectangle;
				var rRoom:Rectangle;
				if (leftChild != null)
				{
					lRoom = leftChild.getRoom();
				}
				if (rightChild != null)
				{
					rRoom = rightChild.getRoom();
				}
				if (lRoom == null && rRoom == null)
					return null;
				else if (rRoom == null)
					return lRoom;
				else if (lRoom == null)
					return rRoom;
				else if (FlxG.random() > .5)
					return lRoom;
				else
					return rRoom;
			}
		}
		
		public function createRooms():void
		{
			// this function generates all the rooms and hallways for this leaf and all it's children.
			if (leftChild != null || rightChild != null)
			{
				// this leaf has been split, so go into the children leafs
				if (leftChild != null)
				{
					leftChild.createRooms();
				}
				if (rightChild != null)
				{
					rightChild.createRooms();
				}
				
				// if there are both left and right children in this leaf, create a hallway between them
				if (leftChild != null && rightChild != null)
				{
					createHall(leftChild.getRoom(), rightChild.getRoom());
				}
				
			}
			else
			{
				// this leaf is the ready to make a room
				var roomSize:Point;
				var roomPos:Point;
				// the room can be between 3 x 3 tiles to the size of the leaf - 2.
				roomSize = new Point(Registry.randomNumber(3, width - 2), Registry.randomNumber(3, height - 2)); 
				// place the room within the leaf don't put it right against the side of the leaf (that would merge rooms together)
				roomPos = new Point(Registry.randomNumber(1, width - roomSize.x - 1), Registry.randomNumber(1, height - roomSize.y - 1));
				room = new Rectangle(x + roomPos.x, y + roomPos.y, roomSize.x, roomSize.y);
			}
		}
		
		public function createHall(l:Rectangle, r:Rectangle):void
		{
			// now we connect these 2 rooms together with hallways.
			// this looks pretty complicated, but it's just trying to figure out which  point is where and then either draw a straight line, or a pair of lines to make a right-angle to connect them.
			// you could do some extra logic to make your halls more bendy, or do some more advanced things if you wanted.
			
			halls = new Vector.<Rectangle>;
			
			var point1:Point = new Point(Registry.randomNumber(l.left + 1, l.right - 2), Registry.randomNumber(l.top + 1, l.bottom - 2));
			var point2:Point = new Point(Registry.randomNumber(r.left + 1, r.right - 2), Registry.randomNumber(r.top + 1, r.bottom - 2));
			
			var w:Number = point2.x - point1.x;
			var h:Number = point2.y - point1.y;
			
			if (w < 0)
			{
				if (h < 0)
				{
					if (FlxG.random() * 0.5)
					{
						halls.push(new Rectangle(point2.x, point1.y, Math.abs(w), 1));
						halls.push(new Rectangle(point2.x, point2.y, 1, Math.abs(h)));
					}
					else
					{
						halls.push(new Rectangle(point2.x, point2.y, Math.abs(w), 1));
						halls.push(new Rectangle(point1.x, point2.y, 1, Math.abs(h)));
					}
				}
				else if (h > 0)
				{
					
					if (FlxG.random() * 0.5)
					{
						halls.push(new Rectangle(point2.x, point1.y, Math.abs(w), 1));
						halls.push(new Rectangle(point2.x, point1.y, 1, Math.abs(h)));
					}
					else
					{
						halls.push(new Rectangle(point2.x, point2.y, Math.abs(w), 1));
						halls.push(new Rectangle(point1.x, point1.y, 1, Math.abs(h)));
					}
				}
				else // if (h == 0)
				{
					halls.push(new Rectangle(point2.x, point2.y, Math.abs(w), 1));
				}
			}
			else if (w > 0)
			{
				if (h < 0)
				{
					if (FlxG.random() * 0.5)
					{
						halls.push(new Rectangle(point1.x, point2.y, Math.abs(w), 1));
						halls.push(new Rectangle(point1.x, point2.y, 1, Math.abs(h)));
					}
					else
					{
						halls.push(new Rectangle(point1.x, point1.y, Math.abs(w), 1));
						halls.push(new Rectangle(point2.x, point2.y, 1, Math.abs(h)));
					}
				}
				else if (h > 0)
				{
					if (FlxG.random() * 0.5)
					{
						halls.push(new Rectangle(point1.x, point1.y, Math.abs(w), 1));
						halls.push(new Rectangle(point2.x, point1.y, 1, Math.abs(h)));
					}
					else
					{
						halls.push(new Rectangle(point1.x, point2.y, Math.abs(w), 1));
						halls.push(new Rectangle(point1.x, point1.y, 1, Math.abs(h)));
					}
				}
				else // if (h == 0)
				{
					halls.push(new Rectangle(point1.x, point1.y, Math.abs(w), 1));
				}
			}
			else // if (w == 0)
			{
				if (h < 0)
				{
					halls.push(new Rectangle(point2.x, point2.y, 1, Math.abs(h)));
				}
				else if (h > 0)
				{
					halls.push(new Rectangle(point1.x, point1.y, 1, Math.abs(h)));
				}
			}
		
		}
	}

}