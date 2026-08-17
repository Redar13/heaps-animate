package h2d.animate.internal.elements;

import h2d.col.Bounds;
import h2d.col.Matrix;

typedef Element = AnimateElement<Dynamic>;

@:access(h2d.Drawable)
@:access(h2d.Object)
@:access(h2d.RenderContext)
class AnimateElement<T>
{
	public var matrix:Matrix;
	public var visible:Bool;
	public var elementType(default, null):ElementType;
	public var parentFrame:Frame;
	var _mat:Matrix;

	public function new(?data:T, ?parent:AnimateLibrary, ?frame:Frame)
	{
		_mat = new Matrix();
		parentFrame = frame;
		visible = true;
	}

	/**
	 * Returns the bounds of the element at a specific frame index.
	 *
	 * @param frameIndex			The frame index where to calculate the bounds from.
	 * @param bounds					Optional, the rectangle used to input the final calculated values.
	 * @param matrix				Optional, the matrix to apply to the bounds calculation.
	 * @param includeFilters		Optional, if to include filtered bounds in the calculation or use the unfilitered ones (true to Flash's bounds).
	 * @return						A ``Bounds`` with the complete frames's bounds at an index, empty if no elements were found.
	 */
	public function getBounds(frameIndex:Int, ?bounds:Bounds, ?matrix:Matrix, ?includeFilters:Bool = true, ?useCachedBounds:Bool = false):Bounds
	{
		return bounds ?? new Bounds();
	}

	public function draw(ctx:RenderContext, animateContext:AnimateRenderContext)
	{
		animateContext = animateContext.clone();
		if (this.matrix != null)
			animateContext.matrix.multiply(this.matrix, animateContext.matrix);
		emitTileByAnimateContext(ctx, null, animateContext); // drawing temp graphic
		animateContext.put();
	}

	function emitTileByAnimateContext(ctx:RenderContext, tile:Null<Tile>, animateContext:AnimateRenderContext)
	{
		if (animateContext.tileBatcher != null)
		{
			if (ctx.currentObj != animateContext.drawableTarget)
				ctx.beginDrawBatchState(animateContext.drawableTarget);
			animateContext.tileBatcher.add(animateContext.matrix, animateContext.colorTransform, tile);
		}
	}

	inline public function toSymbolInstance():SymbolInstance
		return cast this;

	inline public function toMovieClipInstance():MovieClipInstance
		return cast this;

	inline public function toAtlasInstance():AtlasInstance
		return cast this;

	// inline public function toButtonInstance():ButtonInstance
	// 	return cast this;

	// inline public function toTextFieldInstance():TextFieldInstance
	// 	return cast this;

	public function dispose()
	{
		_mat = null;
		matrix = null;
		parentFrame = null;
	}
}

enum abstract ElementType(String) to String
{
	var ATLAS = "atlas";
	var GRAPHIC = "graphic";
	var MOVIECLIP = "movieclip";
	var BUTTON = "button";
	var TEXT = "text";
}