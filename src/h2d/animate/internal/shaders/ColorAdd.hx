package h2d.animate.internal.shaders;

class ColorAdd extends hxsl.Shader {

	static var SRC = {
		var pixelColor : Vec4;

		@input var input : {
			var offsetColor : Vec4;
		};

		function fragment() {
			pixelColor += input.offsetColor / 255;
		}

	};

}