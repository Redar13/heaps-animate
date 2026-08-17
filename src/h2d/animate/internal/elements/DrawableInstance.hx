package h2d.animate.internal.elements;

import h2d.Drawable;
import h2d.Object;
import h2d.col.Bounds;
import h2d.col.Matrix;

typedef DrawableInstance = TypedObjectElement<Drawable>;
typedef ObjectElement = TypedObjectElement<Object>;

@:access(h2d.Object)
@:access(h2d.RenderContext)
class TypedObjectElement<T:Object> extends Element
{
	public var obj:T;
	public function new(?obj:T)
	{
		super(null, null, null);
		this.matrix = new Matrix();
		this.obj = obj;
	}

	var ctxMatrix = new Matrix();
	override function draw(ctx:RenderContext, animateContext:AnimateRenderContext)
	{
		if (obj == null) return;

		animateContext.tileBatcher?.popRender(ctx); // flush last tiles
		animateContext.drawableTarget.getMatrix(ctxMatrix);
		// ctxMatrix.a = ctx.baseShader.absoluteMatrixA.x;
		// ctxMatrix.b = ctx.baseShader.absoluteMatrixB.x;
		// ctxMatrix.c = ctx.baseShader.absoluteMatrixA.y;
		// ctxMatrix.d = ctx.baseShader.absoluteMatrixB.y;
		// ctxMatrix.x = ctx.baseShader.absoluteMatrixA.z;
		// ctxMatrix.y = ctx.baseShader.absoluteMatrixB.z;
		ctxMatrix.multiply(animateContext.matrix, ctxMatrix);
		ctxMatrix.multiply(this.matrix, ctxMatrix);

		// if (obj.parent != null)
		// {
		// 	obj.parent.removeChild(obj);
		// 	// obj.parent = animateContext.drawableTarget;
		// }

		// todo: don't change pos every draw time
		obj.posChanged = true;
		obj.syncPos();
		{
			obj.getMatrix(_mat);
			_mat.multiply(_mat, ctxMatrix);
			obj.matA = _mat.a;
			obj.matB = _mat.b;
			obj.matC = _mat.c;
			obj.matD = _mat.d;
			obj.absX = _mat.x;
			obj.absY = _mat.y;
		}
		obj.drawContent(ctx);
	}
	/*
	// todo
	override function getBounds(frameIndex:Int, ?rect:Bounds, ?matrix:Matrix, ?includeFilters:Bool = true, ?useCachedBounds:Bool = false):Bounds
	{
		var bounds = super.getBounds(frameIndex, rect, matrix, includeFilters);

		if (basic != null)
			bounds = getObjectBounds(bounds);

		Utils.applyMatrixToBounds(bounds, matrix);

		return bounds;
	}

	function getObjectBounds(?result:Bounds):Bounds
	{
		return result;
	}
	*/

	override function dispose()
	{
		super.dispose();
		obj = null;
	}
}