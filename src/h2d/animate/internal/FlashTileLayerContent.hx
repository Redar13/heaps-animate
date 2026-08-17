package h2d.animate.internal;

import h2d.TileGroup.TileLayerContent;
import h2d.col.Matrix;
import h2d.impl.BatchDrawState;
import hxd.BufferFormat;
using h2d.animate.internal.MatrixTools;

/**
 * Special class for draw a tile quads
 */
class FlashTileLayerContent extends h3d.prim.Primitive
{
	var tmp : hxd.FloatBuffer;
	/**
		Content bounds left edge.
	**/
	public var xMin : Float;
	/**
		Content bounds top edge.
	**/
	public var yMin : Float;
	/**
		Content bounds right edge.
	**/
	public var xMax : Float;
	/**
		Content bounds bottom edge.
	**/
	public var yMax : Float;

	public var useAllocatorLimit = 1024;

	var state : BatchDrawState;

	public function new() {
		state = new BatchDrawState();
		clear();
	}

	public function isEmpty() {
		return triCount() == 0;
	}

    inline public function popRender(ctx:RenderContext)
    {
		if (!isEmpty())
		{
			this.doRender(ctx, 0, -1);
			this.clear();
		}
		else
			trace("huh");
    }

	public function add(matrix:Matrix, colorTransform:ColorTransform, t : h2d.Tile)
    {
		var hx = t.width, hy = t.height;

		inline function updateBounds( x, y ) {
			if (x < xMin) xMin = x;
			if (y < yMin) yMin = y;
			if (x > xMax) xMax = x;
			if (y > yMax) yMax = y;
		}

		var dx = t.dx;
		var dy = t.dy;
		var px = matrix.transformX(dx, dy);
		var py = matrix.transformY(dx, dy);

		tmp.push(px);
		tmp.push(py);
		tmp.push(t.u);
		tmp.push(t.v);

		insertColorTransform(colorTransform);
		updateBounds(px, py);

		dx = (t.dx + hx);
		dy = t.dy;
		px = matrix.transformX(dx, dy);
		py = matrix.transformY(dx, dy);

		tmp.push(px);
		tmp.push(py);
		tmp.push(t.u2);
		tmp.push(t.v);

		insertColorTransform(colorTransform);
		updateBounds(px, py);

		dx = t.dx;
		dy = (t.dy + hy);
		px = matrix.transformX(dx, dy);
		py = matrix.transformY(dx, dy);

		tmp.push(px);
		tmp.push(py);
		tmp.push(t.u);
		tmp.push(t.v2);

		insertColorTransform(colorTransform);
		updateBounds(px, py);

		dx = (t.dx + hx);
		dy = (t.dy + hy);
		px = matrix.transformX(dx, dy);
		py = matrix.transformY(dx, dy);

		tmp.push(px);
		tmp.push(py);
		tmp.push(t.u2);
		tmp.push(t.v2);

		insertColorTransform(colorTransform);
		updateBounds(px, py);

		state.setTile(t);
		state.add(4);
	}

	inline function insertColorTransform(ct:ColorTransform)
	{
		tmp.push(ct.redMultiplier);
		tmp.push(ct.greenMultiplier);
		tmp.push(ct.blueMultiplier);
		tmp.push(ct.alphaMultiplier);

		tmp.push(ct.redOffset);
		tmp.push(ct.greenOffset);
		tmp.push(ct.blueOffset);
		tmp.push(ct.alphaOffset);
	}

	override public function triCount() {
		return if (buffer == null) Std.int(tmp.length / 24) else buffer.vertices >> 1;
	}

	public function clear() {
		tmp = new hxd.FloatBuffer();
		if (buffer != null) {
			if (buffer.vertices * 12 < useAllocatorLimit) hxd.impl.Allocator.get().disposeBuffer(buffer);
			else buffer.dispose();
		}
		buffer = null;
		xMin = hxd.Math.POSITIVE_INFINITY;
		yMin = hxd.Math.POSITIVE_INFINITY;
		xMax = hxd.Math.NEGATIVE_INFINITY;
		yMax = hxd.Math.NEGATIVE_INFINITY;
		state.clear();
	}

	public static var XY_UV_CT(get,null) : BufferFormat;
	static function get_XY_UV_CT() {
		if (XY_UV_CT == null) XY_UV_CT = BufferFormat.make([
			{ name : "position", type : DVec2 },
			{ name : "uv", type : DVec2 },
			{ name : "color", type : DVec4 },
			{ name : "offsetColor", type : DVec4 }
		]);
		return XY_UV_CT;
	}

	override public function alloc(engine:h3d.Engine) {
		if (tmp == null) clear();
		if (tmp.length > 0) {
			buffer = tmp.length < useAllocatorLimit
				? hxd.impl.Allocator.get().ofFloats(tmp, XY_UV_CT)
				: h3d.Buffer.ofFloats(tmp, XY_UV_CT);
		}
	}

	override function dispose() {
		if (buffer != null) {
			if (buffer.vertices * 12 < useAllocatorLimit) hxd.impl.Allocator.get().disposeBuffer(buffer);
			else buffer.dispose();
			buffer = null;
		}
		super.dispose();
	}

	/**
		Flushes added quads to the rendering buffer.
		Only flushes if rendering buffer is disposed, and to ensure new data is added, call `dispose()` first.
	**/
	inline public function flush() {
		if (buffer == null || buffer.isDisposed()) alloc(h3d.Engine.getCurrent());
	}

	/**
		Renders the Content quads.
		@param min Initial triangle offset of buffer to draw.
		@param len Amount of triangle to draw. (`-1` to render until the end of buffer)
	**/
	inline public function doRender(ctx : RenderContext, min, len) {
		flush();
		state.drawQuads(ctx, buffer, min, len);
	}
}