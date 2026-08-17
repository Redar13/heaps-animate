package h2d.animate.internal.elements;

import h2d.animate.AnimateJson;
import h2d.animate.internal.elements.Element;
import h2d.col.Bounds;
import h2d.col.Matrix;
import h2d.col.Point;
import h2d.filter.ColorMatrix;

@:access(h2d.animate.AnimateLibrary)
class AtlasInstance extends AnimateElement<AtlasInstanceJson>
{
	public var tile:Null<Tile>;

	var tileMatrix:Matrix;
	var sourceTile:Tile;
	var rotated:Bool = false;

	public function new(?data:AtlasInstanceJson, ?parent:AnimateLibrary, ?frame:Frame)
	{
		super(data, parent, frame);
		this.tileMatrix = new Matrix();
		this.elementType = ATLAS;

		if (data != null)
		{
			var tileData = parent._tiles.get(data.N);
			this.tile = tileData.t;
			this.rotated = tileData.rotated;
			rotateTileMatrix();
			this.sourceTile = this.tile;
			this.matrix = data.MX.toMatrix();
		}
	}


	override public function draw(ctx:RenderContext, animateContext:AnimateRenderContext)
	{
		animateContext = animateContext.clone();
		animateContext.matrix.multiply(this.matrix, animateContext.matrix);
		animateContext.matrix.multiply(this.tileMatrix, animateContext.matrix);
		emitTileByAnimateContext(ctx, tile, animateContext);
		animateContext.put();
	}

	override function getBounds(frameIndex:Int, ?bounds:Bounds, ?matrix:Matrix, ?includeFilters:Bool = true, ?useCachedBounds:Bool = false):Bounds
	{
		bounds ??= new Bounds();

		if (tile != null)
			bounds.set(tile.dx, tile.dy, tile.width, tile.height);

		Utils.applyMatrixToBounds(bounds, this.matrix);
		Utils.applyMatrixToBounds(bounds, tileMatrix);
		Utils.applyMatrixToBounds(bounds, matrix);

		return bounds;
	}

	/**
	 * Replaces the tile used to render the atlas instance.
	 *
	 * @param tile 			New ``Tile`` to replace the existing one.
	 * 						Set to ``null`` to go back to the original tile.
	 * @param adjustScale 	If to rescale the new tile to fit the dimensions of the old one.
	 */
	public function replaceTile(?tile:Null<Tile>, adjustScale:Bool = true):Void
	{
		var copyTile:Tile = (tile ?? this.sourceTile).clone();

		// TODO: account for frame rotations
		// Scale adjustment
		if (adjustScale)
		{
			tileMatrix.identity();
			tileMatrix.a = sourceTile.width / copyTile.width;
			tileMatrix.d = sourceTile.height / copyTile.height;
			rotateTileMatrix();
		}

		this.tile = copyTile;

		if (this.parentFrame != null)
			this.parentFrame.setDirty();
	}

	function rotateTileMatrix()
	{
		if (this.rotated)
		{
			var a = tileMatrix.a, b = tileMatrix.b;
			var c = tileMatrix.c, d = tileMatrix.d;
			var x = tileMatrix.x, y = tileMatrix.y;
			tileMatrix.a = b;
			tileMatrix.b = -a;
			tileMatrix.c = d;
			tileMatrix.d = -c;
			tileMatrix.x = y;
			tileMatrix.y = -x;
			tileMatrix.y += tile.width;
		}
	}

	public function toString():String
	{
		return '{tile: ${tile?.getTexture()?.name ?? Std.string(tile)}, matrix: $matrix}';
	}

	override function dispose():Void
	{
		super.dispose();
		tile = null;
		sourceTile = null;
	}
}