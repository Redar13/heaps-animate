package h2d.animate.internal;

import h2d.col.Bounds;
import h2d.col.Matrix;

typedef Disposable = {function dispose():Void;};

class Utils
{

	/**
	 * Performs a modulo operation to calculate the remainder of `a` divided by `b`.
	 *
	 * The definition of "remainder" varies by implementation;
	 * this one is similar to GLSL or Python in that it uses Euclidean division, which always returns positive,
	 * while Haxe's `%` operator uses signed truncated division.
	 *
	 * For example, `-5 % 3` returns `-2` while `FlxMath.mod(-5, 3)` returns `1`.
	 *
	 * @param a The dividend.
	 * @param b The divisor.
	 * @return `a mod b`.
	 */
	inline public static function mod(a:Float, b:Float):Float
	{
		if (b < 0)
			b = -b;
		return a - b * Math.ffloor(a / b);
	}

	/**
	 * Makes sure that value always stays between min and max,
	 * by wrapping the value around.
	 *
	 * @param 	value 	The value to wrap around
	 * @param 	min		The minimum the value is allowed to be
	 * @param 	max 	The maximum the value is allowed to be
	 * @return The wrapped value
	 */
	public static function wrap(value:Int, min:Int, max:Int):Int
	{
		final range:Int = max - min + 1;

		if (value < min)
			value += range * Std.int((min - value) / range + 1);

		return min + (value - min) % range;
	}

	public static function applyMatrixToBounds(bounds:Bounds, m:Null<Matrix>):Bounds
	{
		if (m == null)
			return bounds;

		if (bounds.isEmpty())
		{
			bounds.set(bounds.xMin + m.x, bounds.yMin + m.y, 0, 0);
			return bounds;
		}

		var xMin = m.a * bounds.xMin + m.c * bounds.yMin;
		var yMin = m.b * bounds.xMin + m.d * bounds.yMin;
		var xMax = xMin;
		var yMax = yMin;

		inline function inflate(x:Float, y:Float)
		{
			var tx = m.a * x + m.c * y;
			var ty = m.b * x + m.d * y;
			if (tx < xMin) xMin = tx;
			if (tx > xMax) xMax = tx;
			if (ty < yMin) yMin = ty;
			if (ty > yMax) yMax = ty;
		}

		inflate(bounds.xMax, bounds.yMin);
		inflate(bounds.xMax, bounds.yMax);
		inflate(bounds.xMin, bounds.yMax);

		bounds.set(xMin + m.x, yMin + m.y, xMax - xMin, yMax - yMin);
		return bounds;
	}

	extern inline public static function dispose<T:Disposable>(t:T):Null<T>
	{
		if (t != null)
			t.dispose();
		return null;
	}

	extern inline public static function disposeArray<T:Disposable>(arr:Array<T>):Null<Array<T>>
	{
		if (arr != null)
		{
			for (i in arr)
				if (i != null)
					i.dispose();
			arr.resize(0);
		}
		return null;
	}
}