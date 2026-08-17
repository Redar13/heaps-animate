package h2d.animate.internal;

import h2d.col.Matrix;

class AnimateRenderContext
{
	public var matrix:Matrix = new Matrix();
	public var colorTransform:ColorTransform = new ColorTransform();

	/**
	 * Index of the timeline to render.
	 */
	public var frameIndex:Int = 0;

	/**
	 * Relative frame index of the current keyframe the symbol instance is stored at.
	 */
	public var index:Int = 0;

	public var drawableTarget:Null<Drawable> = null;
	public var tileBatcher:Null<FlashTileLayerContent> = null;

	static var _freePool:Int = 0;
	static var _pool:Array<AnimateRenderContext> = [];

	public static function get():AnimateRenderContext {
		if (_freePool > 0)
			return _pool[--_freePool].identity();
		return new AnimateRenderContext();
	}

	inline public function put():Void
	{
		if (_pool.indexOf(this) == -1)
			unsafePut();
	}

	public function unsafePut():Void
	{
		_pool[_freePool] = this;
		_freePool++;
	}

	public function new() {}

	inline public function identity():AnimateRenderContext
	{
		matrix.identity();
		colorTransform.identity();
		frameIndex = 0;
		index = 0;
		drawableTarget = null;
		tileBatcher = null;
		return this;
	}

	public function clone():AnimateRenderContext
	{
		if (_freePool > 0 )
			return _pool[--_freePool].copyFrom(this);
		return new AnimateRenderContext().copyFrom(this);
	}

	inline public function copyFrom(context:AnimateRenderContext):AnimateRenderContext
	{
		MatrixTools.copyFrom(matrix, context.matrix);
		colorTransform.copyFrom(context.colorTransform);
		frameIndex = context.frameIndex;
		index = context.index;
		drawableTarget = context.drawableTarget;
		tileBatcher = context.tileBatcher;
		return this;
	}
}