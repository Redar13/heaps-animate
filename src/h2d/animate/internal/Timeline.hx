package h2d.animate.internal;

import h2d.animate.AnimateJson;
import h2d.animate.internal.elements.Element;
import h2d.col.Bounds;
import h2d.col.Matrix;
import h2d.col.Point;

class Timeline {
	public var libraryItem:SymbolItem;
	public var layers:Array<Layer>;
	public var name:String;
	public var currentFrame:Int;
	public var frameCount:Int;
	public var parent(default, null):AnimateLibrary;

	var _layerMap:Map<String, Layer>;
	var _bounds:Bounds;

	public function new(?timeline:TimelineJson, parent:AnimateLibrary, ?name:String)
	{
		this.name = name ?? "";
		this.layers = [];
		this.currentFrame = 0;
		this.parent = parent;

		_layerMap = [];
		_bounds = new Bounds();

		if (timeline != null)
			_loadJson(timeline);
	}

	/**
	 * Returns a layer based on name or index.
	 *
	 * @param layer Index ``Int`` or name ``String`` of the layer.
	 * @return		The ``Layer`` found with that name or index, null if not found.
	 */
	public function getLayer(name:OneOfTwo<Int, String>):Null<Layer>
	{
		return (name is String) ? _layerMap.get(name) : layers[name];
	}

	/**
	 * Applies a function to all the layers of the timeline.
	 *
	 * @param callback The ``Layer->Void`` function to call for all the existing layers.
	 */
	public function forEachLayer(callback:Layer->Void):Void
	{
		for (layer in layers)
			callback(layer);
	}

	/**
	 * Returns the frames through all the layers of a timeline at a specific frame index.
	 *
	 * @param index Frame index ``Int`` to get the frames objects from.
	 * @return		An array of all the ``Frame`` objects at a specific frame index.
	 */
	public function getFramesAtIndex(index:Int):Array<Frame>
	{
		var frames:Array<Frame> = [];
		for (layer in layers)
		{
			var frame = layer.getFrameAtIndex(index);
			if (frame != null)
				frames.push(frame);
		}
		return frames;
	}

	/**
	 * Returns the elements through all the layers of a timeline at a specific frame index.
	 *
	 * @param index Frame index ``Int`` to get the element objects from.
	 * @return		An array of all the ``Element`` objects at a specific frame index.
	 */
	public function getElementsAtIndex(index:Int):Array<Element>
	{
		var elements:Array<Element> = [];
		for (layer in layers)
		{
			var frame = layer.getFrameAtIndex(index);
			if (frame != null)
			{
				for (element in frame.elements)
					elements.push(element);
			}
		}
		return elements;
	}

	/**
	 * Returns an array of all the elements at the current frame displayed on the timeline.
	 * May be innacurate if theres more than one ``FlxAnimate`` object playing the same timeline.
	 *
	 * For accuracy of your specific needs, I recommend using ``getElementsAtIndex`` more.
	 *
	 * @return An array of all the ``Element`` objects at the current frame.
	 */
	public function getCurrentElements():Array<Element>
	{
		return getElementsAtIndex(currentFrame);
	}

	/**
	 * Returns the first frame label in the timeline at a specific frame index.
	 *
	 * @param index Frame index ``Int`` to get the element objects from.
	 * @return		Label ``String`` of the specific frame index, an empty string if not found.
	 */
	public function getFrameLabelAtIndex(index:Int):String
	{
		for (layer in layers)
		{
			var frame = layer.getFrameAtIndex(index);
			if (frame != null && frame.name.length > 0)
				return frame.name;
		}
		return "";
	}

	/**
	 * Gets the list of indices of a frame label to be found from a timeline.
	 *
	 * @param label Frame label tag to find the indices of.
	 * @return Array of ``Int`` indices of the frame label, empty if none were found.
	 */
	public function findFrameLabelIndices(label:String):Array<Int>
	{
		var foundFrames:Array<Int> = [];
		var hasFoundLabel:Bool = false;

		for (layer in layers)
		{
			for (frame in layer.frames)
			{
				if (StringTools.rtrim(frame.name) == label)
				{
					hasFoundLabel = true;

					for (i in 0...frame.duration)
						foundFrames.push(frame.index + i);
				}
			}

			if (hasFoundLabel)
				break;
		}

		return foundFrames;
	}

	inline public function iterator()
	{
		return layers.iterator();
	}

	inline public function keyValueIterator()
	{
		return layers.keyValueIterator();
	}

	// @:allow(animate.FlxAnimateController)
	private function signalFrameChange(frameIndex:Int, animation):Void
	{
		for (layer in layers)
		{
			final frame:Null<Frame> = layer.getFrameAtIndex(frameIndex);
			if (frame != null)
				frame.signalFrameChange(frameIndex, animation);
		}
	}

	function _loadJson(timeline:TimelineJson)
	{
		var layersJson = timeline.L;

		for (layerJson in layersJson)
		{
			var layer = new Layer(this);
			layer.name = layerJson.LN;
			layers.push(layer);
			_layerMap.set(layer.name, layer);
		}

		for (i in 0...layersJson.length)
		{
			var layer = layers[i];
			layer._loadJson(layersJson[i], parent, i, layers);

			if (layer.frameCount > frameCount)
				frameCount = layer.frameCount;
		}

		_bounds = getWholeBounds(false, _bounds);
	}

	/**
	 * Returns the top-left position of the timeline, based on it's bounds.
	 * Useful as an offset value when migrating from a legacy bounds based project.
	 *
	 * @param result 			Optional, point where to store the origin data.
	 * @param applyStageMatrix	Optional, if to apply the stage matrix scaling to the result bounds (needed to replicate legacy bounds).
	 * @return 					A ``Point`` containing the origin point of the bounds top-left position.
	 */
	public function getBoundsOrigin(?result:Point, ?applyStageMatrix:Bool = false):Point
	{
		result ??= new Point();
		result.set(_bounds.xMin, _bounds.yMin);

		if (applyStageMatrix && parent?.matrix != null)
		{
			result.x *= parent.matrix.a;
			result.y *= parent.matrix.d;
		}

		return result;
	}

	var _cachedBounds:Map<Int, Bounds> = [];

	/**
	 * Returns the bounds of the timeline at a specific frame index.
	 *
	 * @param frameIndex			The frame index where to calculate the bounds from.
	 * @param includeHiddenLayers	If to include in the calculation layers currently invisible.
	 * @param bounds					Optional, the rectangle used to input the final calculated values.
	 * @param matrix				Optional, the matrix to apply to the bounds calculation.
	 * @param includeFilters		Optional, if to include filtered bounds in the calculation or use the unfilitered ones (true to Flash's bounds).
	 * @param useCachedBounds		Optional, if to use previously cached bounds. Greatly improves the performance of the function, but wont work
	 * 								if something from the Texture Atlas was manually changed by the user in code (i.e. frames, matrices, etc)
	 * @return						A ``Bounds`` with the timeline's bounds at an index, empty if no elements were found.
	 */
	public function getBounds(frameIndex:Int, ?includeHiddenLayers:Bool = false, ?bounds:Bounds, ?matrix:Matrix, ?includeFilters:Bool = true,
			?useCachedBounds:Bool = false):Bounds
	{
		if (bounds == null)
			bounds = new Bounds();

		bounds.set(0, 0, 0, 0);

		if (useCachedBounds)
		{
			if (_cachedBounds.exists(frameIndex))
			{
				bounds.load(_cachedBounds.get(frameIndex));
				return Utils.applyMatrixToBounds(bounds, matrix);
			}
		}

		var first:Bool = true;
		var tmpRect:Bounds = new Bounds();

		for (layer in layers)
		{
			if (!layer.visible && !includeHiddenLayers)
				continue;

			// Get frame at the bounds index
			var frame = layer.getFrameAtIndex(frameIndex);
			if (frame == null || frame.elements.length <= 0)
				continue;

			// Get the bounds of the frame at the index
			var frameBounds = frame.getBounds((frameIndex - frame.index), tmpRect, null, includeFilters, useCachedBounds);
			if (frameBounds.isEmpty())
				continue;

			if (first)
			{
				first = false;
				bounds.load(frameBounds);
			}
			else
				bounds.addBounds(frameBounds);
		}

		Utils.applyMatrixToBounds(bounds, matrix);

		if (useCachedBounds)
		{
			var cached = new Bounds();
			cached.load(bounds);
			_cachedBounds.set(frameIndex, cached);
		}

		return bounds;
	}

	/**
	 * Use this function to clear the currently cached timeline bounds.
	 *
	 * Some functions like ``getWholeBounds`` require the use of cached bounds to greatly save on performance.
	 * However, if the user changed something about the Texture Atlas, a recache of those bounds may be neccesary.
	 */
	public function clearBoundsCache():Void
	{
		_cachedBounds.clear();
	}

	/**
	 * Returns the complete bounds of the timeline throught all the frames.
	 *
	 * @param includeHiddenLayers	If to include in the calculation layers currently invisible.
	 * @param bounds					Optional, the rectangle used to input the final calculated values.
	 * @param matrix				Optional, the matrix to apply to the bounds calculation.
	 * @param includeFilters		Optional, if to include filtered bounds in the calculation or use the unfilitered ones (true to Flash's bounds).
	 *								But, in case the user changed something from the Texture Atlas, a recache may be needed.
	 * @return						A ``Bounds`` with the complete timeline's bounds, empty if no elements were found.
	 */
	public function getWholeBounds(?includeHiddenLayers:Bool = false, ?bounds:Bounds, ?matrix:Matrix, ?includeFilters:Bool = true):Bounds
	{
		var tmpRect:Bounds = new Bounds();
		bounds ??= new Bounds();
		bounds.set(0, 0, 0, 0);

		for (i in 0...this.frameCount)
		{
			var frameBounds = getBounds(i, includeHiddenLayers, tmpRect, null, includeFilters, true);
			if (frameBounds.isEmpty())
				continue;

			bounds.addBounds(frameBounds);
		}

		Utils.applyMatrixToBounds(bounds, matrix);
		return bounds;
	}

	public function draw(ctx:RenderContext, animateContext:AnimateRenderContext)
	{
		animateContext.index = currentFrame;
		var i = layers.length - 1;
		while (i >= 0)
		{
			var layer = layers[i--];
			if (!layer.visible)
				continue;

			var frame = layer.getFrameAtIndex(currentFrame);
			if (frame == null)
				continue;

			// animateContext = animateContext.clone();
			// animateContext.index = currentFrame;
			frame.draw(ctx, animateContext);
			// animateContext.put();
		}
	}

	public function dispose():Void
	{
		parent = null;
		libraryItem = null;
		layers = Utils.disposeArray(layers);
		_bounds = null;
		_layerMap = null;

		if (_cachedBounds != null)
		{
			clearBoundsCache();
			_cachedBounds = null;
		}
	}
}