package h2d.animate.internal;

import h2d.animate.AnimateJson;
import h2d.animate.internal.Timeline;
import h2d.animate.internal.elements.*;
import h2d.animate.internal.elements.Element;
import h2d.animate.internal.elements.SymbolInstance;
import h2d.col.Bounds;
import h2d.col.Matrix;
import haxe.ds.Vector;
import hxd.res.Sound;
import hxd.snd.Channel;

@:access(h2d.animate.AnimateLibrary)
@:allow(h2d.animate.internal.Layer)
class Frame {
	public var layer(default, null):Null<Layer>;
	public var elements(default, null):Array<Element>;
	public var index:Int;
	public var duration:Int;
	public var name:String;

	public var sound:Null<Channel>;
	public var soundSync:String; // "event", "play", "stop", "stream"

	var _soundData:Null<Sound>;

	public var blend:BlendMode;

	public function new(?layer:Layer)
	{
		this.elements = [];
		this.name = "";
		this.layer = layer;
		this.duration = 1;
		this.index = 0;
	}

	/**
	 * Adds an ``Element`` object to the elements list of the frame.
	 * If the frame is masked it will require a redraw.
	 *
	 * @param element Element object to add to the frame. It won't be added if its already part of the list.
	 */
	public function add(element:Element):Void
	{
		if (elements.indexOf(element) != -1)
			return;

		element.parentFrame = this;
		elements.push(element);
		setDirty();
	}

	/**
	 * Insert an ``Element`` object to an index of the elements list of the frame.
	 * If the frame is masked it will require a redraw.
	 *
	 * @param index		Index where to add the element to.
	 * @param element 	Element object to add to the frame. It won't be added if its already part of the list.
	 */
	public function insert(index:Int, element:Element)
	{
		if (elements.indexOf(element) != -1)
			return;

		element.parentFrame = this;
		elements.insert(index, element);
		setDirty();
	}

	public function draw(ctx:RenderContext, animateContext:AnimateRenderContext)
	{
		_drawElements(ctx, animateContext);
	}

	// @:allow(animate.internal.FilterRenderer)
	inline public function _drawElements(ctx:RenderContext, animateContext:AnimateRenderContext)
	{
		if (elements.length != 0)
		{
			// animateContext = animateContext.clone();
			animateContext.frameIndex = this.index;
			for (element in elements)
			{
				if (element.visible)
					element.draw(ctx, animateContext);
			}
			// animateContext.put();
		}
	}

	/**
	 * Clears up the memory from the previously baked frames and
	 * sets the frame ready for a new rebake of masks/filters.
	 */
	public function setDirty()
	{
		if (_requireBake)
		{
			_dirty = true;
		}

		if (_bakedFrames != null)
		{
			// _bakedFrames.dispose();
			_bakedFrames = null;
			_bakedIndices = null;
		}

		if (layer != null && layer.timeline != null)
			layer.timeline.parent.setSymbolDirty(layer.timeline.name);
	}

	/**
	 *	Packs and replaces the selected elements from the frame into a new symbol item and instance.
	 *	NOTE: Doesn't include the new symbol item into the texture atlas library/dictionary.
	 *
	 * @param fromIndex Index where to start converting elements from.
	 * @param toIndex 	Index where to stop converting elements from.
	 * @param type 		Optional, type of symbol instance to create (``GRAPHIC``, ``MOVIECLIP``, ``BUTTON``).
	 * @return 			An new symbol instance containing the selected elements.
	 */
	@:access(h2d.animate.internal.Layer)
	public function convertToSymbol(fromIndex:Int, toIndex:Int, ?type:ElementType = GRAPHIC):SymbolInstance
	{
		var elements = this.elements.splice(fromIndex, toIndex - fromIndex);

		var timeline = new Timeline(null, layer.timeline.parent, "tempSymbol");
		var layer = new Layer(timeline);

		var frame = new Frame(layer);
		for (element in elements)
			frame.add(element);

		layer.frames.push(frame);
		layer.frameIndices.push(0);

		timeline.layers.push(layer);
		timeline.frameCount = layer.frameCount;

		var item = new SymbolItem(timeline);
		var instance = item.createInstance(type);
		insert(fromIndex, instance);

		return instance;
	}

	/**
	 * Applies a function to all the elements of the frame.
	 *
	 * @param callback The ``Element->Void`` function to call for all the existing elements.
	 */
	public function forEachElement(callback:Element->Void):Void
	{
		for (element in this.elements)
			callback(element);
	}

	/**
	 * Returns the bounds of the keyframe at a specific index.
	 *
	 * @param frameIndex			The frame index where to calculate the bounds from.
	 * @param bounds					Optional, the rectangle used to input the final calculated values.
	 * @param matrix				Optional, the matrix to apply to the bounds calculation.
	 * @param includeFilters		Optional, if to include filtered bounds in the calculation or use the unfilitered ones (true to Flash's bounds).
	 * @return						A ``Bounds`` with the complete frames's bounds at an index, empty if no elements were found.
	 */
	public function getBounds(frameIndex:Int, ?bounds:Bounds, ?matrix:Matrix, ?includeFilters:Bool = true, ?useCachedBounds:Bool = false):Bounds
	{
		bounds ??= new Bounds();
		bounds.set(0, 0, 0, 0);

		// Returns empty bounds if theres no elements in the frame
		if (elements.length <= 0)
		{
			if (matrix != null)
				bounds.set(matrix.x, matrix.y, 0, 0);
			return bounds;
		}

		var tmpRect = new Bounds();

		// Loop through the bounds of each element
		bounds = elements[0].getBounds(frameIndex, bounds, matrix, includeFilters, useCachedBounds);
		for (i in 1...elements.length)
		{
			elements[i].getBounds(frameIndex, tmpRect, matrix, includeFilters, useCachedBounds);
			bounds.addBounds(tmpRect);
		}

		// Calculate masked bounds of the frame
		if (this.layer.layerType == CLIPPED && this.layer.parentLayer != null)
		{
			// tmpRect.set(0, 0, 0, 0);
			// var maskerBounds = this.layer.parentLayer.getBounds(frameIndex + this.index, tmpRect, matrix, includeFilters, useCachedBounds);
			// Timeline.maskBounds(bounds, maskerBounds);
		}

		return bounds;
	}

	inline public function iterator()
	{
		return elements.iterator();
	}

	inline public function keyValueIterator()
	{
		return elements.keyValueIterator();
	}

	@:allow(h2d.animate.internal.Layer)
	function _loadJson(frame:FrameJson, parent:AnimateLibrary):Void
	{
		this.index = frame.I;
		this.duration = frame.DU;
		this.name = frame.N ?? "";
		// this.blend = frame.B;
		this.blend = Add;

		var e = frame.E;
		if (e != null)
		{
			for (element in e)
			{
				var si = element.SI;
				if (si != null)
				{
					this.elements.push(switch (si.ST)
					{
						// case "B" | "button":
						// 	new ButtonInstance(si, parent, this);
						// case "MC" | "movieclip":
						// 	new MovieClipInstance(si, parent, this);
						default:
							new SymbolInstance(si, parent, this);
					});
				}
				else
				{
					var asi = element.ASI;
					if (asi != null)
					{
						this.elements.push(new AtlasInstance(asi, parent, this));
					}
					// else
					// {
					// 	var tfi = element.TFI;
					// 	if (tfi != null)
					// 	{
					// 		this.elements.push(new TextFieldInstance(tfi, parent, this));
					// 	}
					// }
				}
			}
		}

		/*
		#if FLX_SOUND_SYSTEM
		var snd = frame.SND;
		if (snd != null)
		{
			soundSync = snd.SNC;

			final soundPath:String = parent.path + '/LIBRARY/' + snd.N;
			if (FlxAnimateAssets.exists(soundPath, SOUND))
			{
				sound = FlxG.sound.create(_soundData).setup();
			}
		}
		#end
		*/
	}

	@:allow(h2d.animate.internal.Layer)
	var _dirty:Bool = false;

	@:allow(h2d.animate.internal.Layer)
	var _requireBake:Bool = false;

	var _bakedFrames:Vector<Frame>;
	var _bakedIndices:Array<Int>;

	function _bakeFrame(frameIndex:Int):Void
	{
        /*
		if (layer.parentLayer == null)
		{
			_dirty = false;
			return;
		}

		// Prepare vector to store masks
		if (_bakedFrames == null)
			_bakedFrames = new BakedFramesVector(duration);

		// Prepare indices vector
		// This is used as a way to save on the necessary bitmaps to render a mask
		if (_bakedIndices == null)
		{
			var isSimpleRender:Bool = true;
			for (element in elements)
			{
				if (element is AtlasInstance)
					continue;

				if (!element.toSymbolInstance().isSimpleSymbol())
				{
					isSimpleRender = false;
					break;
				}
			}

			_bakedIndices = isSimpleRender ? [for (i in 0...duration) 0] : [for (i in 0...duration) i];
		}

		frameIndex = _bakedIndices[frameIndex];
		if (_bakedFrames[frameIndex] != null)
			return;

		var bakedFrame:Null<AtlasInstance> = FilterRenderer.maskFrame(this, frameIndex + this.index, layer);
		if (bakedFrame == null)
			return;

		bakedFrame.parentFrame = this;
		_bakedFrames[frameIndex] = bakedFrame;

		if (bakedFrame.frame == null || bakedFrame.frame.frame.isEmpty)
			bakedFrame.visible = false;

		// All frames have been baked
		if (_dirty && _bakedFrames.isFull())
			_dirty = false;
        */
	}

	public function dispose():Void
	{
		elements = Utils.disposeArray(elements);
		// sound = Utils.dispose(sound);
		_soundData = null;
		layer = null;

		// if (_bakedFrames != null)
		// {
		// 	_bakedFrames.dispose();
		// 	_bakedFrames = null;
		// }
	}

	@:allow(h2d.animate.internal.Timeline)
	private function signalFrameChange(frameIndex:Int, animation):Void
	{
		final isKeyFrame:Bool = (index == frameIndex);

		// if (isKeyFrame)
		// {
		// 	if (name.length > 0)
		// 		animation.onFrameLabel.dispatch(name);
		// }

        /*
		if (sound != null)
		{
			// if (animation.curAnim != null && animation.curAnim.paused) {
			// pause the sound too maybe?
			// }

			switch (soundSync)
			{
				case "event":
					if (isKeyFrame)
						FlxG.sound.play(_soundData);

				case "stop":
					sound.stop();
				case "start":
					if (isKeyFrame)
						sound.play(true);
				case "stream":
					if (isKeyFrame)
						sound.play(true);

					var streamTime = (frameIndex - index) * (1 / animation.curAnim.frameRate) * 1000;
					var streamDiff = Math.abs(streamTime - sound.time);
					if (streamDiff >= 50)
						sound.time = streamTime;
			}
		}
        */
	}

}
