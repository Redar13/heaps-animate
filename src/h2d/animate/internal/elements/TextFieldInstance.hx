package h2d.animate.internal.elements;

// import h2d.animate.AnimateJson.TextFieldInstanceJson;

// class TextFieldInstance extends AtlasInstance
// {
// 	/**
// 	 * The currently displayed text of the textfield.
// 	 * Requires a redraw when changed.
// 	 */
// 	public var text(get, set):String;

//     var field:Text;
//     var format:Font;
// 	var _dirty:Bool = false;


// 	public function new(data:TextFieldInstanceJson, parent:AnimateLibrary, ?frame:Frame)
// 	{
// 		super(null, null, frame);

// 		this.elementType = TEXT;
// 		this.matrix = data.MX.toMatrix();

// 		var atr = data.ATR[0];
// 		if (atr != null)
// 		{
//             format = new Font(atr.F, atr.SZ);
// 			format.letterSpacing = atr.CSP;
// 			format.bold = atr.BL;
// 			format.italic = atr.IT;
// 			format.align = switch (atr.ALN)
// 			{
// 				case "left": TextFormatAlign.LEFT;
// 				case "right": TextFormatAlign.RIGHT;
// 				case "justify": TextFormatAlign.JUSTIFY;
// 				case _: TextFormatAlign.LEFT;
// 			}
// 			format.color = FlxColor.fromString(atr.C);
// 		}
//         else
//         {
//             format = new Font("dummy", 14);
//         }

// 		if (data.BRD)
// 		{
// 			// format.borderSize = data.ALTHK;
// 		}
// 		field = new Text(format);

// 		field.text = data.TXT;

// 		redraw();
// 	}

// 	inline function get_text():String
// 	{
// 		return field.text;
// 	}

// 	inline function set_text(text:String):String
// 	{
// 		if (text != field.text)
// 		{
// 			field.text = text;
// 			_dirty = true;
// 		}

// 		return text;
// 	}
// }