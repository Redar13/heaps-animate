import hxd.Key;
import h2d.Object;
import h2d.animate.internal.elements.DrawableInstance;
import h2d.col.Bounds;
import h2d.Bitmap;
import h2d.animate.AnimateLibrary;
import hxd.Res;
import hxd.App;
import h2d.animate.Animate;
import h2d.Anim;

class Main extends App
{
	var parent:Object;
	var atlas:Animate = null;
	var atlasHitbox:Bitmap = null;
	var curAtlasHitbox:Bitmap = null;
	var dummyObject:Object = null;

	override function init()
	{
		Res.initLocal();

		var bg = new Bitmap(h2d.Tile.fromColor(0x555555), s2d);
		bg.width = 2000000;
		bg.height = bg.width;
		bg.x = -bg.width / 2;
		bg.y = -bg.height / 2;

		atlasHitbox = new Bitmap(h2d.Tile.fromColor(0xEC0000), s2d);
		atlasHitbox.alpha = 0.2;
		curAtlasHitbox = new Bitmap(h2d.Tile.fromColor(0x00EC00), s2d);
		curAtlasHitbox.alpha = 0.2;

		s2d.defaultSmooth = true;

		// parent = new Object(s2d);
		// parent.setScale(0.5);
		// parent.rotate(45);
		parent = s2d;

		var lib = AnimateLibrary.fromAnimate("./atlas");
		var animate = new Animate(parent);
		animate.library = lib;
		if (animate.addAnimByTimeline("main", lib.timeline, true) != null)
		{
			animate.play("main");

			var resourse = Res.green;
			var drawable = new Bitmap(resourse.toTile());
			drawable.smooth = false;
			drawable.scale(3.0);
			var element = new DrawableInstance(drawable);
			// var layer:h2d.animate.internal.Layer = animate.curAnim.timeline.getLayer(0);
			var layer:h2d.animate.internal.Layer = animate.curAnim.timeline.parent.getSymbol("SYMBOLS/tail")?.timeline.getLayer(0);
			if (layer != null)
			{
				dummyObject = drawable;
				// var layerBounds = layer.getBounds(0);
				// drawable.x += layerBounds.width - drawable.tile.width / drawable.scaleX / 2;
				drawable.x -= 130;
				element.matrix.scaleX(-1);
				layer.forEachFrame(i -> {
					i.insert(0, element);
				});
			}
		}
		else
		{
			trace("Failed to load animation");
		}
		this.atlas = animate;
		this.atlas.applyStageMatrix = true;
		// this.atlas.rotate(45);
		// this.atlas.scaleX = 0.5;

		var window = hxd.Window.getInstance();
		var prevX = window.mouseX, prevY = window.mouseY;
		var isPressed = false;
		window.addEventTarget(e -> {
			switch e.kind
			{
				case EWheel:
					var delta = -e.wheelDelta / 10 * s2d.scaleX;
					s2d.scaleX += delta;
					s2d.scaleY = s2d.scaleX;
					var matrix = s2d.getAbsPos();
					s2d.x += (matrix.x - window.mouseX) / matrix.a * delta;
					s2d.y += (matrix.y - window.mouseY) / matrix.d * delta;
				case ERelease:
					switch e.button
					{
						case hxd.Key.MOUSE_LEFT:
							isPressed = false;
					}
				case EPush:
					switch e.button
					{
						case hxd.Key.MOUSE_LEFT:
							prevX = window.mouseX;
							prevY = window.mouseY;
							isPressed = true;
					}
				case EMove:
					if (isPressed)
					{
						var deltaX = window.mouseX - prevX;
						var deltaY = window.mouseY - prevY;
						if (Key.isDown(Key.CTRL))
						{
							if (Key.isDown(Key.S))
							{
								var e = atlas.getSize();
								if (atlas.scaleX != 0)
									e.width /= Math.abs(atlas.scaleX) * 2;
								if (atlas.scaleY != 0)
									e.height /= Math.abs(atlas.scaleY) * 2;
								var delta = new h2d.col.Point(deltaX / e.width, deltaY / e.height);
								delta.rotate(-atlas.rotation);
								atlas.scaleX += delta.x;
								atlas.scaleY += delta.y;
							}
							else if (Key.isDown(Key.R))
							{
								atlas.rotate(-deltaX / 100);
							}
							else
							{
								atlas.x += deltaX;
								atlas.y += deltaY;
							}
						}
						else
						{
							s2d.x += deltaX;
							s2d.y += deltaY;
						}
						prevX = window.mouseX;
						prevY = window.mouseY;
					}
				default:
			}
		});
	}

	override function update(dt:Float)
	{
		super.update(dt);
		if (atlas != null)
		{
			var size = atlas.getSize();
			size.offset(atlas.x, atlas.y);
			boundsToDrawable(atlasHitbox, size, 3);
			boundsToDrawable(curAtlasHitbox, atlas.getBounds(atlas.parent), 0);
		}
		dummyObject?.rotate(dt / 2);
	}

	function boundsToDrawable(drawable:Bitmap, bounds:Bounds, pad:Int = 3)
	{
		bounds.xMin -= pad;
		bounds.yMin -= pad;
		bounds.xMax += pad;
		bounds.yMax += pad;
		drawable.x = bounds.x;
		drawable.y = bounds.y;
		drawable.width = bounds.width;
		drawable.height = bounds.height;
	}

	private static function main()
	{
		new Main();
	}
}
