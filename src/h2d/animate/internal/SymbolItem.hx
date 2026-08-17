package h2d.animate.internal;

import h2d.animate.internal.elements.Element;
import h2d.animate.internal.elements.SymbolInstance;
import h2d.col.Matrix;
import h2d.col.Point;

class SymbolItem
{
	public var name:String;
	public var timeline:Timeline;

	public function new(timeline:Timeline)
	{
		this.timeline = timeline;
		this.timeline.libraryItem = this;
		this.name = timeline.name;
    }

	public function toString():String
	{
		return '{name: $name}';
	}

	public function dispose():Void
	{
		timeline = Utils.dispose(timeline);
	}

	/**
	 * Creates an instance of the symbol item object.
	 *
	 * @param type 	Optional, type of symbol instance to create (``GRAPHIC``, ``MOVIECLIP``, ``BUTTON``).
	 * @return		A new symbol instance of the library symbol item.
	 */
	@:access(animate.internal.elements.SymbolInstance)
	public function createInstance(?type:ElementType = GRAPHIC):Null<SymbolInstance>
	{
		var instance:SymbolInstance;
		switch (type)
		{
			case ElementType.GRAPHIC:
				instance = new SymbolInstance();
			// case ElementType.MOVIECLIP:
			// 	instance = new MovieClipInstance();
			// case ElementType.BUTTON:
			// 	instance = new ButtonInstance();
			default:
				// FlxG.log.warn('Invalid Symbol Instance type "$type".');
				return null;
		}

		instance.libraryItem = this;
		instance.matrix = new Matrix();
		instance.transformationPoint = new Point();
		instance.loopType = LOOP;
		instance.firstFrame = 0;
		instance.setColorTransform(1, 1, 1, 1, 0, 0, 0, 0);
		return instance;
	}
}