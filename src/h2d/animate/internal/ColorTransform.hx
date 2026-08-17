package h2d.animate.internal;

class ColorTransform {

	/**
		A decimal value that is multiplied with the alpha transparency channel
		value.

		If you set the alpha transparency value of a display object directly by
		using the `alpha` property of the DisplayObject instance, it
		affects the value of the `alphaMultiplier` property of that
		display object's `transform.colorTransform` property.
	**/
	public var alphaMultiplier:Float;

	/**
		A number from -255 to 255 that is added to the alpha transparency channel
		value after it has been multiplied by the `alphaMultiplier`
		value.
	**/
	public var alphaOffset:Float;

	/**
		A decimal value that is multiplied with the blue channel value.
	**/
	public var blueMultiplier:Float;

	/**
		A number from -255 to 255 that is added to the blue channel value after it
		has been multiplied by the `blueMultiplier` value.
	**/
	public var blueOffset:Float;

	/**
		The RGB color value for a ColorTransform object.

		When you set this property, it changes the three color offset values
		(`redOffset`, `greenOffset`, and
		`blueOffset`) accordingly, and it sets the three color
		multiplier values(`redMultiplier`,
		`greenMultiplier`, and `blueMultiplier`) to 0. The
		alpha transparency multiplier and offset values do not change.

		When you pass a value for this property, use the format
		0x_RRGGBB_. _RR_, _GG_, and _BB_ each consist of two
		hexadecimal digits that specify the offset of each color component. The 0x
		tells the Haxe compiler that the number is a hexadecimal
		value.
	**/
	public var color(get, set):Int;

	/**
		A decimal value that is multiplied with the green channel value.
	**/
	public var greenMultiplier:Float;

	/**
		A number from -255 to 255 that is added to the green channel value after
		it has been multiplied by the `greenMultiplier` value.
	**/
	public var greenOffset:Float;

	/**
		A decimal value that is multiplied with the red channel value.
	**/
	public var redMultiplier:Float;

	/**
		A number from -255 to 255 that is added to the red channel value after it
		has been multiplied by the `redMultiplier` value.
	**/
	public var redOffset:Float;

	/**
		Creates a ColorTransform object for a display object with the specified
		color channel values and alpha values.

		@param redMultiplier   The value for the red multiplier, in the range from
							   0 to 1.
		@param greenMultiplier The value for the green multiplier, in the range
							   from 0 to 1.
		@param blueMultiplier  The value for the blue multiplier, in the range
							   from 0 to 1.
		@param alphaMultiplier The value for the alpha transparency multiplier, in
							   the range from 0 to 1.
		@param redOffset       The offset value for the red color channel, in the
							   range from -255 to 255.
		@param greenOffset     The offset value for the green color channel, in
							   the range from -255 to 255.
		@param blueOffset      The offset for the blue color channel value, in the
							   range from -255 to 255.
		@param alphaOffset     The offset for alpha transparency channel value, in
							   the range from -255 to 255.
	**/
	public function new(redMultiplier:Float = 1, greenMultiplier:Float = 1, blueMultiplier:Float = 1, alphaMultiplier:Float = 1, redOffset:Float = 0,
			greenOffset:Float = 0, blueOffset:Float = 0, alphaOffset:Float = 0):Void
	{
		this.redMultiplier = redMultiplier;
		this.greenMultiplier = greenMultiplier;
		this.blueMultiplier = blueMultiplier;
		this.alphaMultiplier = alphaMultiplier;
		this.redOffset = redOffset;
		this.greenOffset = greenOffset;
		this.blueOffset = blueOffset;
		this.alphaOffset = alphaOffset;
	}

	/**
		Concatenates the ColorTranform object specified by the `second`
		parameter with the current ColorTransform object and sets the current
		object as the result, which is an additive combination of the two color
		transformations. When you apply the concatenated ColorTransform object,
		the effect is the same as applying the `second` color
		transformation after the _original_ color transformation.

		@param second The ColorTransform object to be combined with the current
					  ColorTransform object.
	**/
	public function concat(second:ColorTransform):Void
	{
		redOffset = second.redOffset * redMultiplier + redOffset;
		greenOffset = second.greenOffset * greenMultiplier + greenOffset;
		blueOffset = second.blueOffset * blueMultiplier + blueOffset;
		alphaOffset = second.alphaOffset * alphaMultiplier + alphaOffset;

		redMultiplier *= second.redMultiplier;
		greenMultiplier *= second.greenMultiplier;
		blueMultiplier *= second.blueMultiplier;
		alphaMultiplier *= second.alphaMultiplier;
	}

	/**
		Formats and returns a string that describes all of the properties of
		the ColorTransform object.

		@return A string that lists all of the properties of the
				ColorTransform object.
	**/
	public function toString():String
	{
		return
			'(redMultiplier=$redMultiplier, greenMultiplier=$greenMultiplier, blueMultiplier=$blueMultiplier, alphaMultiplier=$alphaMultiplier, redOffset=$redOffset, greenOffset=$greenOffset, blueOffset=$blueOffset, alphaOffset=$alphaOffset)';
	}

	public function clone():ColorTransform
	{
		return new ColorTransform(redMultiplier, greenMultiplier, blueMultiplier, alphaMultiplier, redOffset, greenOffset, blueOffset, alphaOffset);
	}

	public function copyFrom(ct:ColorTransform):Void
	{
		redMultiplier = ct.redMultiplier;
		greenMultiplier = ct.greenMultiplier;
		blueMultiplier = ct.blueMultiplier;
		alphaMultiplier = ct.alphaMultiplier;

		redOffset = ct.redOffset;
		greenOffset = ct.greenOffset;
		blueOffset = ct.blueOffset;
		alphaOffset = ct.alphaOffset;
	}

	public function combine(ct:ColorTransform):Void
	{
		redMultiplier *= ct.redMultiplier;
		greenMultiplier *= ct.greenMultiplier;
		blueMultiplier *= ct.blueMultiplier;
		alphaMultiplier *= ct.alphaMultiplier;

		redOffset += ct.redOffset;
		greenOffset += ct.greenOffset;
		blueOffset += ct.blueOffset;
		alphaOffset += ct.alphaOffset;
	}

	inline public function identity():Void
	{
		redMultiplier = 1;
		greenMultiplier = 1;
		blueMultiplier = 1;
		alphaMultiplier = 1;
		redOffset = 0;
		greenOffset = 0;
		blueOffset = 0;
		alphaOffset = 0;
	}

	public function invert():Void
	{
		redMultiplier = redMultiplier == 0 ? 1 : 1 / redMultiplier;
		greenMultiplier = greenMultiplier == 0 ? 1 : 1 / greenMultiplier;
		blueMultiplier = blueMultiplier == 0 ? 1 : 1 / blueMultiplier;
		alphaMultiplier = alphaMultiplier == 0 ? 1 : 1 / alphaMultiplier;
		redOffset = -redOffset;
		greenOffset = -greenOffset;
		blueOffset = -blueOffset;
		alphaOffset = -alphaOffset;
	}

	public function equals(ct:ColorTransform, ignoreAlphaMultiplier:Bool):Bool
	{
		return (ct != null
			&& redMultiplier == ct.redMultiplier
			&& greenMultiplier == ct.greenMultiplier
			&& blueMultiplier == ct.blueMultiplier
			&& (ignoreAlphaMultiplier || alphaMultiplier == ct.alphaMultiplier)
			&& redOffset == ct.redOffset
			&& greenOffset == ct.greenOffset
			&& blueOffset == ct.blueOffset
			&& alphaOffset == ct.alphaOffset);
	}

	inline public function isDefault():Bool
	{
		return (hasRGBAMultipliers() || hasRGBAOffsets());
	}

	/**
	 * Returns whether red, green, or blue multipliers are set to anything other than 1.
	 */
	inline public function hasRGBMultipliers():Bool
	{
		return this.redMultiplier != 1 || this.greenMultiplier != 1 || this.blueMultiplier != 1;
	}

	/**
	 * Returns whether red, green, blue, or alpha multipliers are set to anything other than 1.
	 */
	inline public function hasRGBAMultipliers():Bool
	{
		return hasRGBMultipliers() || this.alphaMultiplier != 1;
	}

	/**
	 * Returns whether red, green, or blue offsets are set to anything other than 0.
	 */
	inline public function hasRGBOffsets():Bool
	{
		return this.redOffset != 0 || this.greenOffset != 0 || this.blueOffset != 0;
	}

	/**
	 * Returns whether red, green, blue, or alpha offsets are set to anything other than 0.
	 */
	inline public function hasRGBAOffsets():Bool
	{
		return hasRGBOffsets() || this.alphaOffset != 0;
	}

	// Getters & Setters
	function get_color():Int
	{
		return ((Std.int(redOffset) << 16) | (Std.int(greenOffset) << 8) | Std.int(blueOffset));
	}

	function set_color(value:Int):Int
	{
		redOffset = (value >> 16) & 0xFF;
		greenOffset = (value >> 8) & 0xFF;
		blueOffset = value & 0xFF;

		redMultiplier = 0;
		greenMultiplier = 0;
		blueMultiplier = 0;

		return color;
	}

}