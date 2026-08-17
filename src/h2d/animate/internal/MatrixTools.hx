package h2d.animate.internal;

import h2d.col.Matrix;

class MatrixTools
{
    inline public static function transformX(m:Matrix, px:Float, py:Float):Float
    {
        return px * m.a + py * m.c + m.x;
    }

    inline public static function transformY(m:Matrix, px:Float, py:Float):Float
    {
        return px * m.b + py * m.d + m.y;
    }

    inline public static function copyFrom(m:Matrix, a:Matrix):Void
    {
        m.a = a.a;
        m.b = a.b;
        m.c = a.c;
        m.d = a.d;
        m.x = a.x;
        m.y = a.y;
    }
}