package h2d.animate;

import h2d.Drawable;
import h2d.animate.internal.AnimateRenderContext;
import h2d.animate.internal.FlashTileLayerContent;
import h2d.animate.internal.Timeline;
import h2d.animate.internal.shaders.ColorAdd;

class Animate extends Drawable
{
	public var curAnim(default, null):Null<Animation> = null;
	public var curAnimName(default, null):Null<String> = null;
	public var library(default, set):AnimateLibrary;
	public var applyStageMatrix(default, set):Bool = false;

	var _animations:Map<String, Animation> = [];
	var _tileBatcher = new FlashTileLayerContent();
	var _animateRendererContext = new AnimateRenderContext();
	var _offsetColor:ColorAdd;

	public function new(parent : h2d.Object, ?library:AnimateLibrary)
	{
		super(parent);
		_offsetColor = this.addShader(new h2d.animate.internal.shaders.ColorAdd());
		this.library = library;
	}

	inline public function addAnimByFramelabel(animName:String, labelName:String, speed:Float = 1.0, indices:Null<Array<Int>> = null, looped:Bool = false):Bool
	{
		return addAnim(animName, library?.getAnimByFramelabel(labelName, speed, indices, looped));
	}

	inline public function addAnimBySymbol(animName:String, symbolName:String, speed:Float = 1.0, indices:Null<Array<Int>> = null, looped:Bool = false):Bool
	{
		return addAnim(animName, library?.getAnimBySymbol(symbolName, speed, indices, looped));
	}

	inline public function addAnimByTimeline(animName:String, timeline:Timeline, speed:Float = 1.0, indices:Null<Array<Int>> = null, looped:Bool = false):Bool
	{
		return addAnim(animName, AnimateLibrary.getAnimByTimeline(timeline, speed, indices, looped));
	}

	public function addAnim(animName:String, anim:Null<Animation>):Bool
	{
		if (anim == null) return false;
		_animations.set(animName, anim);
		return true;
	}

	inline public function animExists(name:String):Bool
	{
		return _animations.exists(name);
	}

	public function play(name:String, ?atFrame:Null<Float>):Bool
	{
		if (atFrame == null && curAnimName == name) return curAnimName != null;
		if (curAnimName != name)
		{
			curAnim = _animations.get(name);
			curAnimName = name;
		}
		if (curAnim != null)
			curAnim.play(atFrame ?? curAnim.curFrame);
		else
			curAnimName = null;

		return curAnimName != null;
	}

	public function pause():Bool
	{
		if (curAnim == null) return false;
		curAnim.pause();
		return true;
	}

	public function stop():Bool
	{
		if (curAnim != null)
		{
			curAnimName = null;
			curAnim.stop();
			curAnim = null;
			return true;
		}
		return false;
	}

	inline public function clearAnimations()
	{
		_animations.clear();
		stop();
	}

	public function getAnimation(name:String):Null<Animation>
	{
		return _animations.get(name);
	}

	inline public function anims():Map<String, Animation>
	{
		return _animations.copy();
	}

	inline public function animsList():Array<Animation>
	{
		return [for (i in _animations.iterator()) i];
	}

	inline public function animNames():Array<String>
	{
		return [for (i in _animations.keys()) i];
	}

	override function getBoundsRec( relativeTo : Object, out : h2d.col.Bounds, forSize : Bool ) {
		super.getBoundsRec(relativeTo, out, forSize);
		if (curAnim?.timeline != null)
		{
			final timeline = curAnim.timeline;
			var b = forSize ? timeline.getWholeBounds() : timeline.getBounds(timeline.currentFrame);
			addBounds(relativeTo, out, b.x, b.y, b.width, b.height);
		}
	}

	override function draw(ctx:RenderContext)
	{
		if (curAnim == null) return;
		if (!ctx.beginDrawBatchState(this)) return;
		var timeline = curAnim.timeline;
		prepareAnimateContext(false);
		timeline.draw(ctx, _animateRendererContext);
		_tileBatcher.popRender(ctx);
	}

	override function sync(ctx:RenderContext) {
		if (curAnim != null)
			curAnim.sync(ctx);

		super.sync(ctx);
	}

	override function onRemove() // clean up a object memory, i guess
	{
		_tileBatcher.dispose();
		clearAnimations();
		this.removeShader(_offsetColor);
		super.onRemove();
	}

	function prepareAnimateContext(includeHidenLayers:Bool = false) {
		_animateRendererContext.drawableTarget = this;
		_animateRendererContext.tileBatcher = _tileBatcher;
		// _animateRendererContext.includeHidenLayers = includeHidenLayers; // todo?
	}
	override function calcAbsPos() {
		if (this.applyStageMatrix && curAnim != null)
		{
			var timeline = curAnim.timeline;
			var timelineBounds = timeline.getWholeBounds();
			var stageMatrix = timeline.parent.matrix;
			matA = stageMatrix.a;
			matB = stageMatrix.b;
			matC = stageMatrix.c;
			matD = stageMatrix.d;
			absX = stageMatrix.x - timelineBounds.x;
			absY = stageMatrix.y - timelineBounds.y;
		}
		else
		{
			matA = 1.0;
			matB = matC = 0;
			matD = 1.0;
			absX = absY = 0;
		}
		if (parent == null) {
			var cr, sr;
			if (rotation == 0) {
				cr = 1.; sr = 0.;
				matA *= scaleX;
				matD *= scaleY;
			} else {
				cr = Math.cos(rotation);
				sr = Math.sin(rotation);
				matA *= scaleX * cr;
				matB *= scaleX * sr;
				matC *= scaleY * -sr;
				matD *= scaleY * cr;
			}
			absX += x;
			absY += y;
		} else {
			var tmpA = matA;
			var tmpB = matB;
			var tmpC = matC;
			var tmpD = matD;
			matA = tmpA * parent.matA + tmpB * parent.matC;
			matB = tmpA * parent.matB + tmpB * parent.matD;
			matC = tmpC * parent.matA + tmpD * parent.matC;
			matD = tmpC * parent.matB + tmpD * parent.matD;
			absX = absX * parent.matA + absY * parent.matC + parent.absX;
			absY = absX * parent.matB + absY * parent.matD + parent.absY;
		}
	}

	inline function set_applyStageMatrix(v:Bool):Bool
	{
		if (applyStageMatrix != v)
		{
			this.applyStageMatrix = v;
			posChanged = true;
		}
		return v;
	}

	function set_library(v)
	{
		if (library != v)
		{
			for (k => i in _animations)
			{
				if (i.library == library)
				{
					if (curAnim == i)
						stop();
					_animations.remove(k);
				}
			}
			library = v;
			clearAnimations();
		}
		return library;
	}
}

@:allow(h2d.animate.Animate)
class Animation
{
	public var speed:Float = 1.0;
	public var loop:Bool = false;
	public var isPaused(default, null):Bool = true;
	public var currentFrame(get,set) : Float;
	public var frames:Array<Int>;
	public var timeline:Timeline;
	public var library(get, never):AnimateLibrary;

	var curFrame:Float = 0;

	public function new(timeline:Timeline, ?frames:Array<Int>)
	{
		this.timeline = timeline;
		this.frames = (frames ?? [for (i in 0...timeline.frameCount) i]);
	}

	public function play(atFrame = 0.) {
		currentFrame = atFrame;
		isPaused = false;
	}

	public function pause() {
		isPaused = true;
	}

	public function stop() {
		currentFrame = 0;
		isPaused = true;
	}

	public dynamic function onAnimEnd() {
	}

	inline function get_currentFrame() {
		return curFrame;
	}

	function set_currentFrame( frame : Float ) {
		curFrame = frames.length == 0 ? 0 : frame % frames.length;
		if (curFrame < 0) curFrame += frames.length;
		flushToTimeline();
		return curFrame;
	}

	function flushToTimeline() {
		timeline.currentFrame = frames[hxd.Math.floor(curFrame)];
		// timeline.signalFrameChange(frame, this);
	}

	function sync(ctx:RenderContext)
	{
		var prev = curFrame;
		if (!isPaused)
			curFrame += speed * ctx.elapsedTime * timeline.parent.frameRate;
		if (curFrame < frames.length)
		{
			flushToTimeline();
			return;
		}
		if (loop) {
			if (frames.length == 0)
				curFrame = 0;
			else
				curFrame %= frames.length;
			flushToTimeline();
			onAnimEnd();
		} else if (curFrame >= frames.length) {
			curFrame = frames.length;
			flushToTimeline();
			if (curFrame != prev) onAnimEnd();
		}
	}

	inline function get_library()
	{
		return timeline.parent;
	}
}