package h2d.animate.internal;


/**
 * Class representing a color, based on Int. Provides a variety of methods for creating and converting colors.
 *
 * Colors can be written as Ints. This means you can pass a hex value such as
 * 0xFF123456 to a function expecting a Color, and it will automatically become a Color "object".
 * Similarly, Colors may be treated as Ints.
 *
 * Note that when using properties of a Color other than ARGB, the values are ultimately stored as
 * ARGB values, so repeatedly manipulating HSB/HSL/CMYK values may result in a gradual loss of precision.
 *
 * @author Joe Williamson (JoeCreates)
 */
@:forward.variance
abstract Color(Int) from Int from UInt to Int to UInt
{
	inline public static var TRANSPARENT:Color = 0x00000000;
	inline public static var WHITE:Color = 0xFFFFFFFF;
	inline public static var GRAY:Color = 0xFF808080;
	inline public static var BLACK:Color = 0xFF000000;

	inline public static var GREEN:Color = 0xFF008000;
	inline public static var LIME:Color = 0xFF00FF00;
	inline public static var YELLOW:Color = 0xFFFFFF00;
	inline public static var ORANGE:Color = 0xFFFFA500;
	inline public static var RED:Color = 0xFFFF0000;
	inline public static var PURPLE:Color = 0xFF800080;
	inline public static var BLUE:Color = 0xFF0000FF;
	inline public static var BROWN:Color = 0xFF8B4513;
	inline public static var PINK:Color = 0xFFFFC0CB;
	inline public static var MAGENTA:Color = 0xFFFF00FF;
	inline public static var CYAN:Color = 0xFF00FFFF;

	/**
	 * A `Map<String, Int>` whose values are the static colors of `Color`.
	 * You can add more colors for `Color.fromString(String)` if you need.
	 */
	public static final colorLookup:Map<String, Int> = [
	    "TRANSPARENT" => 0x00000000,
	    "WHITE" => 0xFFFFFFFF,
	    "GRAY" => 0xFF808080,
	    "BLACK" => 0xFF000000,

	    "GREEN" => 0xFF008000,
	    "LIME" => 0xFF00FF00,
	    "YELLOW" => 0xFFFFFF00,
	    "ORANGE" => 0xFFFFA500,
	    "RED" => 0xFFFF0000,
	    "PURPLE" => 0xFF800080,
	    "BLUE" => 0xFF0000FF,
	    "BROWN" => 0xFF8B4513,
	    "PINK" => 0xFFFFC0CB,
	    "MAGENTA" => 0xFFFF00FF,
	    "CYAN" => 0xFF00FFFF,
    ];

	public var red(get, set):Int;
	public var blue(get, set):Int;
	public var green(get, set):Int;
	public var alpha(get, set):Int;

	public var redFloat(get, set):Float;
	public var blueFloat(get, set):Float;
	public var greenFloat(get, set):Float;
	public var alphaFloat(get, set):Float;

	public var cyan(get, set):Float;
	public var magenta(get, set):Float;
	public var yellow(get, set):Float;
	public var black(get, set):Float;

	/**
	 * The red, green and blue channels of this color as a 24 bit integer (from 0 to 0xFFFFFF)
	 */
	public var rgb(get, set):Color;

	/**
	 * The hue of the color in degrees (from 0 to 359)
	 */
	public var hue(get, set):Float;

	/**
	 * The saturation of the color (from 0 to 1)
	 */
	public var saturation(get, set):Float;

	/**
	 * The brightness (aka value) of the color (from 0 to 1)
	 */
	public var brightness(get, set):Float;

	/**
	 * The lightness of the color (from 0 to 1)
	 */
	public var lightness(get, set):Float;

	/**
	 * The luminance, or "percieved brightness" of a color (from 0 to 1)
	 * RGB -> Luma calculation from https://www.w3.org/TR/AERT/#color-contrast
	 */
	public var luminance(get, never):Float;

	static var COLOR_REGEX = ~/^(0x|#)(([A-F0-9]{2}){3,4})$/i;

	/**
	 * Create a color from the least significant four bytes of an Int
	 *
	 * @param	Value And Int with bytes in the format 0xAARRGGBB
	 * @return	The color as a Color
	 */
	inline public static function fromInt(Value:Int):Color
	{
		return new Color(Value);
	}

	/**
	 * Generate a color from integer RGB values (0 to 255)
	 *
	 * @param Red	The red value of the color from 0 to 255
	 * @param Green	The green value of the color from 0 to 255
	 * @param Blue	The green value of the color from 0 to 255
	 * @param Alpha	How opaque the color should be, from 0 to 255
	 * @return The color as a Color
	 */
	inline public static function fromRGB(Red:Int, Green:Int, Blue:Int, Alpha:Int = 255):Color
	{
		var color = new Color();
		return color.setRGB(Red, Green, Blue, Alpha);
	}

	/**
	 * Generate a color from float RGB values (0 to 1)
	 *
	 * @param Red	The red value of the color from 0 to 1
	 * @param Green	The green value of the color from 0 to 1
	 * @param Blue	The green value of the color from 0 to 1
	 * @param Alpha	How opaque the color should be, from 0 to 1
	 * @return The color as a Color
	 */
	inline public static function fromRGBFloat(Red:Float, Green:Float, Blue:Float, Alpha:Float = 1):Color
	{
		var color = new Color();
		return color.setRGBFloat(Red, Green, Blue, Alpha);
	}

	/**
	 * Generate a color from CMYK values (0 to 1)
	 *
	 * @param Cyan		The cyan value of the color from 0 to 1
	 * @param Magenta	The magenta value of the color from 0 to 1
	 * @param Yellow	The yellow value of the color from 0 to 1
	 * @param Black		The black value of the color from 0 to 1
	 * @param Alpha		How opaque the color should be, from 0 to 1
	 * @return The color as a Color
	 */
	inline public static function fromCMYK(Cyan:Float, Magenta:Float, Yellow:Float, Black:Float, Alpha:Float = 1):Color
	{
		var color = new Color();
		return color.setCMYK(Cyan, Magenta, Yellow, Black, Alpha);
	}

	/**
	 * Generate a color from HSB (aka HSV) components.
	 *
	 * @param	Hue			A number between 0 and 360, indicating position on a color strip or wheel.
	 * @param	Saturation	A number between 0 and 1, indicating how colorful or gray the color should be.  0 is gray, 1 is vibrant.
	 * @param	Brightness	(aka Value) A number between 0 and 1, indicating how bright the color should be.  0 is black, 1 is full bright.
	 * @param	Alpha		How opaque the color should be, either between 0 and 1 or 0 and 255.
	 * @return	The color as a Color
	 */
	public static function fromHSB(Hue:Float, Saturation:Float, Brightness:Float, Alpha:Float = 1):Color
	{
		var color = new Color();
		return color.setHSB(Hue, Saturation, Brightness, Alpha);
	}

	/**
	 * Generate a color from HSL components.
	 *
	 * @param	Hue			A number between 0 and 360, indicating position on a color strip or wheel.
	 * @param	Saturation	A number between 0 and 1, indicating how colorful or gray the color should be.  0 is gray, 1 is vibrant.
	 * @param	Lightness	A number between 0 and 1, indicating the lightness of the color
	 * @param	Alpha		How opaque the color should be, either between 0 and 1 or 0 and 255.
	 * @return	The color as a Color
	 */
	inline public static function fromHSL(Hue:Float, Saturation:Float, Lightness:Float, Alpha:Float = 1):Color
	{
		var color = new Color();
		return color.setHSL(Hue, Saturation, Lightness, Alpha);
	}

	/**
	 * Parses a `String` and returns a `Color` or `null` if the `String` couldn't be parsed.
	 *
	 * Examples (input -> output in hex):
	 *
	 * - `0x00FF00`    -> `0xFF00FF00`
	 * - `0xAA4578C2`  -> `0xAA4578C2`
	 * - `#0000FF`     -> `0xFF0000FF`
	 * - `#3F000011`   -> `0x3F000011`
	 * - `GRAY`        -> `0xFF808080`
	 * - `blue`        -> `0xFF0000FF`
	 *
	 * @param	str 	The string to be parsed
	 * @return	A `Color` or `null` if the `String` couldn't be parsed
	 */
	public static function fromString(str:String):Null<Color>
	{
		var result:Null<Color> = null;
		str = StringTools.trim(str);

		if (COLOR_REGEX.match(str))
		{
			var hexColor:String = "0x" + COLOR_REGEX.matched(2);
			result = new Color(Std.parseInt(hexColor));
			if (hexColor.length == 8)
			{
				result.alphaFloat = 1;
			}
		}
		else
		{
			str = str.toUpperCase();
			// if (colorLookup.exists(str))
				result = colorLookup.get(str);
		}

		return result;
	}

	/**
	 * Get HSB color wheel values in an array which will be 360 elements in size
	 *
	 * @param	Alpha Alpha value for each color of the color wheel, between 0 (transparent) and 255 (opaque)
	 * @return	HSB color wheel as Array of Colors
	 */
	public static function getHSBColorWheel(Alpha:Int = 255):Array<Color>
	{
		return [for (c in 0...360) fromHSB(c, 1.0, 1.0, Alpha)];
	}

	/**
	 * Get an interpolated color based on two diFFerent colors.
	 *
	 * @param 	Color1 The first color
	 * @param 	Color2 The second color
	 * @param 	Factor Value from 0 to 1 representing how much to shift Color1 toward Color2
	 * @return	The interpolated color
	 */
	inline public static function interpolate(Color1:Color, Color2:Color, Factor:Float = 0.5):Color
	{
		var r:Int = Std.int((Color2.red - Color1.red) * Factor + Color1.red);
		var g:Int = Std.int((Color2.green - Color1.green) * Factor + Color1.green);
		var b:Int = Std.int((Color2.blue - Color1.blue) * Factor + Color1.blue);
		var a:Int = Std.int((Color2.alpha - Color1.alpha) * Factor + Color1.alpha);

		return fromRGB(r, g, b, a);
	}

	/**
	 * Multiply the RGB channels of two Colors
	 */
	@:op(A * B)
	inline public static function multiply(lhs:Color, rhs:Color):Color
	{
		return Color.fromRGBFloat(lhs.redFloat * rhs.redFloat, lhs.greenFloat * rhs.greenFloat, lhs.blueFloat * rhs.blueFloat);
	}

	/**
	 * Add the RGB channels of two Colors
	 */
	@:op(A + B)
	inline public static function add(lhs:Color, rhs:Color):Color
	{
		return Color.fromRGB(lhs.red + rhs.red, lhs.green + rhs.green, lhs.blue + rhs.blue);
	}

	/**
	 * Subtract the RGB channels of one Color from another
	 */
	@:op(A - B)
	inline public static function subtract(lhs:Color, rhs:Color):Color
	{
		return Color.fromRGB(lhs.red - rhs.red, lhs.green - rhs.green, lhs.blue - rhs.blue);
	}

	/**
	 * Returns the sum of the absolute diFFerences of each channel between this and the specified color.
	 * For instance `Color.RED.getDistance(0xFFf80080)` is `135`, or `(0xFF - 0xf8) + (0x80 - 0x00)`
	 *
	 * @since 6.2.0
	 */
	public function getDistance(color:Color)
	{
		inline function abs(n:Int):Int
		{
			return n < 0 ? -n : n;
		}

		return abs(color.red - red)
			+ abs(color.green - green)
			+ abs(color.blue - blue)
			+ abs(color.alpha - alpha);
	}

	/**
	 * Searches the list of colors and returns the one whos rgba components are closets to this color.
	 * If colors is empty, the result is `null`
	 *
	 * @since 6.2.0
	 */
	overload extern inline public function nearest(colors:Array<Color>):Null<Color>
	{
		return getNearest(this, colors.iterator());
	}

	/**
	 * Searches the list of colors and returns the one whos rgba components are closets to this color.
	 * If colors is empty, the result is `null`
	 *
	 * @since 6.2.0
	 */
	overload extern inline public function nearest(colors:Iterator<Color>):Null<Color>
	{
		return getNearest(this, colors);
	}

	static function getNearest(target:Color, colors:Iterator<Color>):Null<Color>
	{
		var closest:Null<Color> = null;
		var closestDiFF = -1;

		for (color in colors)
		{
			if (color == target)
			{
				closest = target;
				break;
			}

			final diFF = color.getDistance(target);
			if (closest == null || diFF < closestDiFF)
			{
				closest = color;
				closestDiFF = diFF;
			}
		}

		return closest;
	}

	/**
	 * Returns a Complementary Color Harmony of this color.
	 * A complementary hue is one directly opposite the color given on the color wheel
	 *
	 * @return	The complimentary color
	 */
	inline public function getComplementHarmony():Color
	{
		return fromHSB(Utils.wrap(Std.int(hue) + 180, 0, 350), brightness, saturation, alphaFloat);
	}

	/**
	 * Return a String representation of the color in the format
	 *
	 * @param   alpha   Whether to include the alpha value in the hex string
	 * @param   usePrefix  Whether to include "0x" prefix at start of string
	 * @return	A string of length 10 in the format 0xAARRGGBB
	 */
	overload extern inline public function toHexString(alpha:Bool, usePrefix:Bool):String
	{
		return toHexString(usePrefix ? "0x" : "", alpha);
	}

	/**
	 * Return a String representation of the color in the format
	 *
	 * @param   includeAlpha  Whether to include the alpha value in the hex string
	 * @param   prefix        Optional color prefix
	 * @since 6.2.0
	 */
	overload extern inline public function toHexString(prefix:String = "0x", includeAlpha = true):String
	{
		inline function hex(n) return StringTools.hex(n, 2);
		return prefix + (includeAlpha ? hex(alpha) : "") + hex(red) + hex(green) + hex(blue);
	}

	/**
	 * Return a String representation of the color in the format #RRGGBB
	 *
	 * @return	A string of length 7 in the format #RRGGBB
	 */
	inline public function toWebString():String
	{
		return "#" + toHexString(false, false);
	}

	/**
	 * Get a string of color information about this color
	 *
	 * @return A string containing information about this color
	 */
	public function getColorInfo():String
	{
		// Hex format
		var result:String = toHexString() + "\n";
		// RGB format
		result += "Alpha: " + alpha + " Red: " + red + " Green: " + green + " Blue: " + blue + "\n";
		// HSB/HSL info
		result += "Hue: " + hxd.Math.fmt(hue) + " Saturation: " + hxd.Math.fmt(saturation) + " Brightness: "
			+ hxd.Math.fmt(brightness) + " Lightness: " + hxd.Math.fmt(lightness);

		return result;
	}

	/**
	 * Get a darkened version of this color
	 *
	 * @param	Factor Value from 0 to 1 of how much to progress toward black.
	 * @return 	A darkened version of this color
	 */
	public function getDarkened(Factor:Float = 0.2):Color
	{
		Factor = hxd.Math.clamp(Factor, 0, 1);
		var output:Color = this;
		output.lightness = output.lightness * (1 - Factor);
		return output;
	}

	/**
	 * Get a lightened version of this color
	 *
	 * @param	Factor Value from 0 to 1 of how much to progress toward white.
	 * @return 	A lightened version of this color
	 */
	inline public function getLightened(Factor:Float = 0.2):Color
	{
		Factor = hxd.Math.clamp(Factor, 0, 1);
		var output:Color = this;
		output.lightness = output.lightness + (1 - lightness) * Factor;
		return output;
	}

	/**
	 * Get the inversion of this color
	 *
	 * @return The inversion of this color
	 */
	inline public function getInverted():Color
	{
		var oldAlpha = alpha;
		var output:Color = Color.WHITE - this;
		output.alpha = oldAlpha;
		return output;
	}

	/**
	 * Set RGB values as integers (0 to 255)
	 *
	 * @param Red	The red value of the color from 0 to 255
	 * @param Green	The green value of the color from 0 to 255
	 * @param Blue	The green value of the color from 0 to 255
	 * @param Alpha	How opaque the color should be, from 0 to 255
	 * @return This color
	 */
	inline public function setRGB(Red:Int, Green:Int, Blue:Int, Alpha:Int = 255):Color
	{
		red = Red;
		green = Green;
		blue = Blue;
		alpha = Alpha;
		return this;
	}

	/**
	 * Set RGB values as floats (0 to 1)
	 *
	 * @param Red	The red value of the color from 0 to 1
	 * @param Green	The green value of the color from 0 to 1
	 * @param Blue	The green value of the color from 0 to 1
	 * @param Alpha	How opaque the color should be, from 0 to 1
	 * @return This color
	 */
	inline public function setRGBFloat(Red:Float, Green:Float, Blue:Float, Alpha:Float = 1):Color
	{
		redFloat = Red;
		greenFloat = Green;
		blueFloat = Blue;
		alphaFloat = Alpha;
		return this;
	}

	/**
	 * Set CMYK values as floats (0 to 1)
	 *
	 * @param Cyan		The cyan value of the color from 0 to 1
	 * @param Magenta	The magenta value of the color from 0 to 1
	 * @param Yellow	The yellow value of the color from 0 to 1
	 * @param Black		The black value of the color from 0 to 1
	 * @param Alpha		How opaque the color should be, from 0 to 1
	 * @return This color
	 */
	inline public function setCMYK(Cyan:Float, Magenta:Float, Yellow:Float, Black:Float, Alpha:Float = 1):Color
	{
		redFloat = (1 - Cyan) * (1 - Black);
		greenFloat = (1 - Magenta) * (1 - Black);
		blueFloat = (1 - Yellow) * (1 - Black);
		alphaFloat = Alpha;
		return this;
	}

	/**
	 * Set HSB (aka HSV) components
	 *
	 * @param	Hue			A number between 0 and 360, indicating position on a color strip or wheel.
	 * @param	Saturation	A number between 0 and 1, indicating how colorful or gray the color should be.  0 is gray, 1 is vibrant.
	 * @param	Brightness	(aka Value) A number between 0 and 1, indicating how bright the color should be.  0 is black, 1 is full bright.
	 * @param	Alpha		How opaque the color should be, either between 0 and 1 or 0 and 255.
	 * @return	This color
	 */
	inline public function setHSB(Hue:Float, Saturation:Float, Brightness:Float, Alpha = 1.0):Color
	{
		var chroma = Brightness * Saturation;
		var match = Brightness - chroma;
		return setHueChromaMatch(Hue, chroma, match, Alpha);
	}

	/**
	 * Set HSL components.
	 *
	 * @param	Hue			A number between 0 and 360, indicating position on a color strip or wheel.
	 * @param	Saturation	A number between 0 and 1, indicating how colorful or gray the color should be.  0 is gray, 1 is vibrant.
	 * @param	Lightness	A number between 0 and 1, indicating the lightness of the color
	 * @param	Alpha		How opaque the color should be, either between 0 and 1 or 0 and 255
	 * @return	This color
	 */
	inline public function setHSL(Hue:Float, Saturation:Float, Lightness:Float, Alpha = 1.0):Color
	{
		var chroma = (1 - Math.abs(2 * Lightness - 1)) * Saturation;
		var match = Lightness - chroma / 2;
		return setHueChromaMatch(Hue, chroma, match, Alpha);
	}

	/**
	 * Private utility function to perform common operations between setHSB and setHSL
	 */
	inline function setHueChromaMatch(Hue:Float, Chroma:Float, Match:Float, Alpha:Float):Color
	{
		Hue = Utils.mod(Hue, 360);
		var hueD = Hue / 60;
		var mid = Chroma * (1 - Math.abs(hueD % 2 - 1)) + Match;
		Chroma += Match;

		switch (Std.int(hueD))
		{
			case 0:
				setRGBFloat(Chroma, mid, Match, Alpha);
			case 1:
				setRGBFloat(mid, Chroma, Match, Alpha);
			case 2:
				setRGBFloat(Match, Chroma, mid, Alpha);
			case 3:
				setRGBFloat(Match, mid, Chroma, Alpha);
			case 4:
				setRGBFloat(mid, Match, Chroma, Alpha);
			case 5:
				setRGBFloat(Chroma, Match, mid, Alpha);
		}

		return this;
	}

	inline public function new(Value:Int = 0)
	{
		this = Value;
	}

	inline function getThis():Int
	{
		return this;
	}

	inline function get_red():Int
	{
		return (getThis() >> 16) & 0xFF;
	}

	inline function get_green():Int
	{
		return (getThis() >> 8) & 0xFF;
	}

	inline function get_blue():Int
	{
		return getThis() & 0xFF;
	}

	inline function get_alpha():Int
	{
		return (getThis() >> 24) & 0xFF;
	}

	inline function get_redFloat():Float
	{
		return red / 255;
	}

	inline function get_greenFloat():Float
	{
		return green / 255;
	}

	inline function get_blueFloat():Float
	{
		return blue / 255;
	}

	inline function get_alphaFloat():Float
	{
		return alpha / 255;
	}

	inline function set_red(Value:Int):Int
	{
		this &= 0xFF00FFFF;
		this |= boundChannel(Value) << 16;
		return Value;
	}

	inline function set_green(Value:Int):Int
	{
		this &= 0xFFFF00FF;
		this |= boundChannel(Value) << 8;
		return Value;
	}

	inline function set_blue(Value:Int):Int
	{
		this &= 0xFFFFFF00;
		this |= boundChannel(Value);
		return Value;
	}

	inline function set_alpha(Value:Int):Int
	{
		this &= 0x00FFFFFF;
		this |= boundChannel(Value) << 24;
		return Value;
	}

	inline function set_redFloat(Value:Float):Float
	{
		red = Math.round(Value * 255);
		return Value;
	}

	inline function set_greenFloat(Value:Float):Float
	{
		green = Math.round(Value * 255);
		return Value;
	}

	inline function set_blueFloat(Value:Float):Float
	{
		blue = Math.round(Value * 255);
		return Value;
	}

	inline function set_alphaFloat(Value:Float):Float
	{
		alpha = Math.round(Value * 255);
		return Value;
	}

	inline function get_cyan():Float
	{
		return (1 - redFloat - black) / brightness;
	}

	inline function get_magenta():Float
	{
		return (1 - greenFloat - black) / brightness;
	}

	inline function get_yellow():Float
	{
		return (1 - blueFloat - black) / brightness;
	}

	inline function get_black():Float
	{
		return 1 - brightness;
	}

	inline function set_cyan(Value:Float):Float
	{
		setCMYK(Value, magenta, yellow, black, alphaFloat);
		return Value;
	}

	inline function set_magenta(Value:Float):Float
	{
		setCMYK(cyan, Value, yellow, black, alphaFloat);
		return Value;
	}

	inline function set_yellow(Value:Float):Float
	{
		setCMYK(cyan, magenta, Value, black, alphaFloat);
		return Value;
	}

	inline function set_black(Value:Float):Float
	{
		setCMYK(cyan, magenta, yellow, Value, alphaFloat);
		return Value;
	}

	function get_hue():Float
	{
		var hueRad = Math.atan2(Math.sqrt(3) * (greenFloat - blueFloat), 2 * redFloat - greenFloat - blueFloat);
		var hue:Float = 0;
		if (hueRad != 0)
		{
			hue = 180 / Math.PI * hueRad;
		}

		return hue < 0 ? hue + 360 : hue;
	}

	inline function get_brightness():Float
	{
		return maxColor();
	}

	inline function get_luminance():Float
	{
		return (redFloat * 299 + greenFloat * 587 + blueFloat * 114) / 1000;
	}

	inline function get_saturation():Float
	{
		return (maxColor() - minColor()) / brightness;
	}

	inline function get_lightness():Float
	{
		return (maxColor() + minColor()) / 2;
	}

	inline function set_hue(Value:Float):Float
	{
		setHSB(Value, saturation, brightness, alphaFloat);
		return Value;
	}

	inline function set_saturation(Value:Float):Float
	{
		setHSB(hue, Value, brightness, alphaFloat);
		return Value;
	}

	inline function set_brightness(Value:Float):Float
	{
		setHSB(hue, saturation, Value, alphaFloat);
		return Value;
	}

	inline function set_lightness(Value:Float):Float
	{
		setHSL(hue, saturation, Value, alphaFloat);
		return Value;
	}

	inline function set_rgb(value:Color):Color
	{
		this = (this & 0xFF000000) | (value & 0x00FFFFFF);
		return value;
	}

	inline function get_rgb():Color
	{
		return this & 0x00FFFFFF;
	}

	inline function maxColor():Float
	{
		return Math.max(redFloat, Math.max(greenFloat, blueFloat));
	}

	inline function minColor():Float
	{
		return Math.min(redFloat, Math.min(greenFloat, blueFloat));
	}

	inline function boundChannel(Value:Int):Int
	{
		return Value > 0xFF ? 0xFF : Value < 0 ? 0 : Value;
	}
}
