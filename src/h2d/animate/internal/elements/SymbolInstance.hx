package h2d.animate.internal.elements;

import h2d.animate.AnimateJson;
import h2d.animate.internal.elements.Element;
import h2d.col.Bounds;
import h2d.col.Matrix;
import h2d.col.Point;
import hxd.Math;

class SymbolInstance extends AnimateElement<SymbolInstanceJson>
{
	public var libraryItem:SymbolItem;
	public var blend:AnimateBlendMode;
	public var firstFrame:Int;
	public var lastFrame:Int;
	public var loopType:LoopType;
	public var symbolName(get, never):String;
	public var transformationPoint:Point;

	var isColored:Bool;
	var transform:ColorTransform;
	var _transform:ColorTransform;

	public function new(?data:SymbolInstanceJson, ?parent:AnimateLibrary, ?frame:Frame)
	{
		super(data, parent, frame);
		this.elementType = GRAPHIC;

		if (data == null)
			return;

		this.libraryItem = parent.getSymbol(data.SN, data.BM);
		this.matrix = data.MX.toMatrix();
		this.firstFrame = data.FF;
		this.lastFrame = data.LF;
		this.isColored = false;

		this.loopType = switch (data.LP)
		{
			case "PO" | "playonce": LoopType.PLAY_ONCE;
			case "SF" | "singleframe": LoopType.SINGLE_FRAME;
			default: LoopType.LOOP;
		}

		final trp:Null<PointJson> = data.TRP;
		this.transformationPoint = new Point(trp?.x ?? 0.0, trp?.y ?? 0.0);

		if (libraryItem == null)
			visible = false;

		var color = data.C;
		if (color != null)
		{
			switch (color.M)
			{
				case "AD" | "Advanced":
					setColorTransform(color.RM, color.GM, color.BM, color.AM, color.RO, color.GO, color.BO, color.AO);
				case "CA" | "Alpha":
					setColorTransform(1.0, 1.0, 1.0, color.AM, 0.0, 0.0, 0.0, 0.0);
				case "CBRT" | "Brightness":
					var brightness = color.BRT;
					var colorMult = 1.0 - Math.abs(brightness);
					var colorOff = brightness >= 0.0 ? brightness * 255.0 : 0.0;
					setColorTransform(colorMult, colorMult, colorMult, 1.0, colorOff, colorOff, colorOff, 0.0);
				case "T" | "Tint":
					var tint:Color = Color.fromString(color.TC);
					var tintMult:Float = color.TM;
					var mult:Float = 1.0 - tintMult;
					setColorTransform(mult, mult, mult, 1.0, tint.red * tintMult, tint.green * tintMult, tint.blue * tintMult, 0.0);
			}
		}
	}

	overload extern inline public function setColorTransform(rMult:Float = 1, gMult:Float = 1, bMult:Float = 1, aMult:Float = 1, rOffset:Float = 0,
			gOffset:Float = 0, bOffset:Float = 0, aOffset:Float = 0):Void
	{
		_setColorTransform(rMult, gMult, bMult, aMult, rOffset, gOffset, bOffset, aOffset);
	}

	overload extern inline public function setColorTransform(color:Color):Void
	{
		_setColorTransform(color.redFloat, color.greenFloat, color.blueFloat, 1, 0, 0, 0, 0);
	}

	/**
	 * Returns the timeline frame index needed to be rendered at a specific frame, while taking loop types into consideration.
	 * @param index 		Index of the timeline to render.
	 * @param frameIndex 	Optional, relative frame index of the current keyframe the symbol instance is stored at.
	 * @return				Found frame index for rendering at a specific frame.
	 */
	public function getFrameIndex(index:Int, frameIndex:Int = 0):Int
	{
		frameIndex = firstFrame + (index - frameIndex);

		final lastIndex:Int = libraryItem.timeline.frameCount - 1;
		final hasLastFrame:Bool = (lastFrame > -1);
		final doWrap:Bool = hasLastFrame && (lastFrame < firstFrame);

		final length:Int = (doWrap ? lastIndex : (hasLastFrame ? Math.imin(lastFrame, lastIndex) : lastIndex)) - firstFrame + 1;
		final totalLength:Int = doWrap ? length + (lastFrame + 1) : length;

		switch (loopType)
		{
			case LoopType.LOOP:
				if (doWrap)
				{
					frameIndex = ((frameIndex - firstFrame) % totalLength + totalLength) % totalLength;
				}
				else
				{
					if (hasLastFrame)
						return Utils.wrap(frameIndex, firstFrame, Math.imin(lastFrame, lastIndex));

					return Utils.wrap(frameIndex, 0, lastIndex);
				}

			case LoopType.PLAY_ONCE:
				frameIndex = Math.imin((frameIndex - firstFrame), totalLength - 1);

			case LoopType.SINGLE_FRAME:
				return firstFrame;
		}

		if (frameIndex < length)
			return firstFrame + frameIndex;

		if (doWrap)
			return (frameIndex - length);

		return -1 + (frameIndex - length);
	}

	/**
	 * Method used internally to check if a symbol has simple rendering (one frame).
	 * @return If the symbol has simple rendering or not.
	 */
	public function isSimpleSymbol():Bool
	{
		var timeline = libraryItem.timeline;

		if (timeline.frameCount == 1)
			return true;

		if (loopType == SINGLE_FRAME)
			return true;

		// TODO: more indepth check through layers

		return false;
	}

	var _tmpMatrix:Matrix = new Matrix();

	override function getBounds(frameIndex:Int, ?bounds:Bounds, ?matrix:Matrix, ?includeFilters:Bool = true, ?useCachedBounds:Bool = false):Bounds
	{
		// TODO: look into this
		// Patch-on fix for a really weird fucking bug
		if (libraryItem != null && libraryItem.timeline.parent.existsSymbol(symbolName))
			libraryItem = libraryItem.timeline.parent.getSymbol(symbolName);

		// Prepare the bounds matrix
		var targetMatrix:Matrix;
		if (matrix != null)
		{
			_tmpMatrix.a = this.matrix.a;
			_tmpMatrix.b = this.matrix.b;
			_tmpMatrix.c = this.matrix.c;
			_tmpMatrix.d = this.matrix.d;
			_tmpMatrix.x = this.matrix.x;
			_tmpMatrix.y = this.matrix.y;
			_tmpMatrix.multiply(_tmpMatrix, matrix);

			targetMatrix = _tmpMatrix;
		}
		else
		{
			targetMatrix = this.matrix;
		}

		// Get the bounds of the symbol item timeline
		return libraryItem.timeline.getBounds(getFrameIndex(frameIndex, 0), null, bounds, targetMatrix, includeFilters, useCachedBounds);
	}

	override function draw(ctx:RenderContext, animateContext:AnimateRenderContext)
	{
		if (isColored) // Concat symbol's color to the current color transform
		{
			_transform.copyFrom(this.transform);
			_transform.concat(animateContext.colorTransform);

			if (_transform.alphaMultiplier <= 0 || _transform.alphaOffset <= -255)
			{
				return;
			}
			animateContext = animateContext.clone();
			animateContext.colorTransform.copyFrom(_transform);
		}
		else
		{
			animateContext = animateContext.clone();
		}
		_drawTimeline(ctx, animateContext);
		animateContext.put();
	}

	function _drawTimeline(ctx:RenderContext, animateContext:AnimateRenderContext)
	{
		animateContext.matrix.multiply(this.matrix, animateContext.matrix);
		libraryItem.timeline.currentFrame = getFrameIndex(animateContext.index, animateContext.frameIndex);
		libraryItem.timeline.draw(ctx, animateContext);
	}

	function _setColorTransform(rMult:Float, gMult:Float, bMult:Float, aMult:Float, rOffset:Float, gOffset:Float, bOffset:Float, aOffset:Float)
	{
		if (transform == null)
			transform = new ColorTransform();
		if (_transform == null)
			_transform = new ColorTransform();

		transform.redMultiplier = rMult;
		transform.greenMultiplier = gMult;
		transform.blueMultiplier = bMult;
		transform.alphaMultiplier = aMult;

		transform.redOffset = rOffset;
		transform.greenOffset = gOffset;
		transform.blueOffset = bOffset;
		transform.alphaOffset = aOffset;

		isColored = (!transform.isDefault());
	}

	inline function get_symbolName():String
	{
		return libraryItem?.name;
	}
	public function toString():String
	{
		return '{name: ${libraryItem?.name}, matrix: $matrix}';
	}
}