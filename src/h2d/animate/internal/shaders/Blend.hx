package h2d.animate.internal.shaders;

import h2d.animate.AnimateJson.AnimateBlendMode;
import h3d.pass.ScreenFx;
import h3d.shader.ScreenShader;

class BlendShader extends ScreenShader {

	static var SRC = {

		@param var texture:Sampler2D;
		@param var blendMode:Int;

		function screen(a:Float, b:Float):Float {
			return 1.0 - (1.0 - a) * (1.0 - b);
		}

		function hardlight(a:Float, b:Float):Float {
			return (b > 0.5) ? (1.0 - (1.0 - a) * (1.0 - 2.0 * (b - 0.5))) : (a * (2.0 * b));
		}

		function overlay(a:Float, b:Float):Float {
			return (a < 0.5) ? (2.0 * a * b) : (1.0 - 2.0 * (1.0 - a) * (1.0 - b));
		}

		function applyBlend(a:Vec4, b:Vec4, mode:Int):Vec4
		{
			if (mode == -1) return a; // NORMAL/LAYER/SHADER
			if (a.a == 0.0) return a;

			var result:Vec4 = a;

			switch (mode) {
				case 0: // ADD
					result.rgb = a.rgb + b.rgb;
				case 1: // ALPHA
					result.a = b.a;
				case 2: // DARKEN
					result.rgb = min(a.rgb, b.rgb);
				case 3: // DIFFERENCE
					result.rgb = abs(a.rgb - b.rgb);
				case 4: // ERASE
					result.a = a.a * (1.0 - b.a);
					result.rgb = a.rgb;
				case 5: // HARDLIGHT
					result.r = hardlight(a.r, b.r);
					result.g = hardlight(a.g, b.g);
					result.b = hardlight(a.b, b.b);
				case 6: // INVERT
					result.rgb = vec3(1.0) - a.rgb;
				case 8: // LIGHTEN
					result.rgb = max(a.rgb, b.rgb);
				case 9: // MULTIPLY
					result.rgb = a.rgb * b.rgb;
				case 11: // OVERLAY
					result.r = overlay(a.r, b.r);
					result.g = overlay(a.g, b.g);
					result.b = overlay(a.b, b.b);
				case 12: // SCREEN
					result.r = screen(a.r, b.r);
					result.g = screen(a.g, b.g);
					result.b = screen(a.b, b.b);
				case 14: // SUBTRACT
					result.rgb = a.rgb - b.rgb;
			}

			result.rgb = mix(a.rgb, result.rgb, b.a);
			return result;
		}

		function fragment() {
			var base:Vec4 = texture.get(calculatedUV);
			output.color = applyBlend(base, output.color, blendMode);
		}
	};
}

class Blend extends ScreenFx<BlendShader>
{
	public function new() {
		super(new BlendShader());
	}

	public function apply(texture : h3d.mat.Texture, blendMode:AnimateBlendMode) {
		shader.texture = texture;
		shader.blendMode = cast blendMode;
		render();
	}
}