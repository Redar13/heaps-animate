package h2d.animate;

import h2d.animate.Animate.Animation;
import h2d.animate.AnimateJson;
import h2d.animate.internal.Color;
import h2d.animate.internal.Frame;
import h2d.animate.internal.Layer;
import h2d.animate.internal.SymbolItem;
import h2d.animate.internal.Timeline;
import h2d.animate.internal.Utils;
import h2d.animate.internal.elements.AtlasInstance;
import h2d.col.IBounds;
import h2d.col.Matrix;
import haxe.Json;
import haxe.ds.Vector;
import haxe.io.Path;
import hxd.Res;
import hxd.res.Any;
import hxd.res.Resource;
using StringTools;

/**
 * Settings used when first loading a texture atlas.
 *
 * @param swfMode 			Used if the movieclips of the symbol should render similarly to SWF files. Disabled by default.
 * 							See ``h2d.animate.internal.elements.MovieClipInstance`` for more.
 *
 * @param cacheOnLoad		If to cache all necessary filters and masks when the texture atlas is first loaded. Disabled by default.
 *							This setting may be useful for reducing lag on filter heavy atlases. But take into account that
 *							it can also heavily increase loading times.
 *
 * @param filterQuality		Level of compression used to render filters. Set to ``MEDIUM`` by default.
 *							``HIGH`` 	-> Will render filters at their full quality, with no resolution loss.
 *							``MEDIUM`` 	-> Will apply some lossless compression to the filter, most recommended option.
 *							``LOW`` 	-> Will use heavy and easily noticeable compression, use with precausion.
 *							``RUDY``	-> Having your eyes closed probably has better graphics than this.
 *
 * @param onSymbolCreate	An optional callback that gets called when a ``SymbolItem`` is created and added to the library.
 * 							This setting can be used as a intermeddiate point in the Texture Atlas loading process to add
 * 							any custom changes that may want to be applied before any baking is applied to the Texture Atlas.
 */
typedef AnimateSettings =
{
	?swfMode:Bool,
	?cacheOnLoad:Bool,
	?filterQuality:FilterQuality,
	?onSymbolCreate:SymbolItem->Void
}

@:allow(h2d.animate.Animate)
class AnimateLibrary {
	// TODO:
	// public var instance:SymbolInstance;
	// public var stageInstance:SymbolInstanceJson;

	/**
	 * The main ``Timeline`` that the Texture Atlas was exported from.
	 */
	public var timeline:Timeline;

	/**
	 * Rectangle with the resolution of the Animate stage background.
	 * Defaults to 1280x720 if the Texture Atlas wasnt exported using BetterTA.
	 */
	public var stageRect:IBounds;

	/**
	 * Color of the Animate stage background.
	 * Defaults to WHITE if the Texture Atlas wasnt exported using BetterTA.
	 */
	public var stageColor:Int;

	/**
	 * Matrix of the Texture Atlas on the Animate stage.
	 * Defaults to an empty matrix if not exported from an instanced symbol.
	 */
	public var matrix:Matrix; // TODO: to be replaced with library.instance

	/**
	 * Default frame rate that the Texture Atlas was exported from.
	 */
	public var frameRate:Float;

	var dictionary:Map<String, SymbolItem>;
	var _symbolDictionary:Null<Vector<SymbolJson>>;
	var path:String;
	var addedCollections:Array<AnimateLibrary>;
	var _isInlined:Bool;
	var _libraryList:Array<String>;
	var _settings:Null<AnimateSettings>;
	var _tiles:Map<String, {t: h2d.Tile, rotated:Bool}>;


	public function new()
	{
		this.dictionary = [];
		this.addedCollections = [];
		this._tiles = [];
	}

	/**
	 * The collection of extra main timelines merged to the Texture Atlas.
	 * @return An array of ``Timeline`` object, empty if the sprite isn't loaded with a Texture Atlas.
	 */
	inline public function getCollectionTimelines():Array<Timeline>
		return [for (collection in addedCollections) collection.timeline];

	/**
	 * Returns a ``SymbolItem`` object contained inside the texture atlas dictionary/library.
	 *
	 * @param name Name of the symbol item to return.
	 * @return ``SymbolItem`` found with the given name, null if not found.
	 */
	public function getSymbol(name:String, ?atlasInstance:AtlasInstanceJson):Null<SymbolItem>
	{
		if (dictionary.exists(name))
		{
			return dictionary.get(name);
		}
		else
		{
			if (name.contains("/")) // Look for the shortcut name if the symbol is contained in a folder
			{
				final shortcut:String = name.split("/").pop();
				if (dictionary.exists(shortcut))
					return dictionary.get(shortcut);
			}
		}

		if (_isInlined)
		{
			var sd = _symbolDictionary;
			if (sd != null)
			{
				for (i in 0...sd.length)
				{
					var data = sd[i];
					if (data.SN == name)
					{
						var timeline = new Timeline(data.TL, this, name);
						return setSymbol(null, new SymbolItem(timeline));
					}
				}
			}
		}
		else
		{
			if (_libraryList.contains(name))
			{
				var data:TimelineJson = Json.parse(getTextFromPath(path + "/LIBRARY/" + name + ".json"));
				var timeline = new Timeline(data, this, name);
				return setSymbol(null, new SymbolItem(timeline));
			}
		}

		for (collection in addedCollections)
		{
			if (collection.dictionary.exists(name))
				return collection.dictionary.get(name);
		}

		// Legacy check for Animate 2018 Texture Atlas
		if (atlasInstance != null)
		{
			var timeline = new Timeline(null, this, name);
			var layer = new Layer(timeline);
			var frame = new Frame(layer);
			frame.elements.push(new AtlasInstance(atlasInstance, this, frame));

			layer.frames.push(frame);
			@:privateAccess layer.frameIndices.push(0);
			timeline.layers.push(layer);
			timeline.frameCount = 1;

			// @:privateAccess
			// timeline._bounds = timeline.getWholeBounds(false, timeline._bounds);

			return setSymbol(name, new SymbolItem(timeline));
		}

		// FlxG.log.warn("SymbolItem with name " + '"$name"' + " doesn't exist.");
		return null;
	}

	static function getTextFromPath(path:String):String
	{
        return fixBom(Res.load(path).toText());
	}

	inline static function fixBom(src:String):String
	{
        return src.replace(String.fromCharCode(0xFEFF), "");
	}

	/**
	 * Returns if a ``SymbolItem`` object is contained inside the texture atlas dictionary/library.
	 *
	 * @param name Name of the symbol item to check for.
	 * @return Whether the symbol exists in the dictionary or not.
	 */
	public function existsSymbol(name:String):Bool
	{
		final existsBasic:Bool = dictionary.exists(name);
		if (existsBasic)
			return true;

		if (name.contains("/")) // Look for the shortcut name if the symbol is contained in a folder
		{
			final shortcut:String = name.split("/").pop();
			return dictionary.exists(shortcut);
		}

		return false;
	}

	/**
	 * Adds a ``SymbolItem`` object to the texture atlas dictionary/library.
	 *
	 * @param name 			Name of the symbol item to add, uses the timeline name if null.
	 * @param symbolItem 	``SymbolItem`` object to add.
	 * @return ``SymbolItem`` object that has been added, for chaining.
	 */
	public function setSymbol(?name:String, symbolItem:SymbolItem):SymbolItem
	{
		final id:String = name ?? symbolItem.timeline.name;
		dictionary.set(id, symbolItem);
		return symbolItem;
	}

	public function getAnimByFramelabel(label:String, speed:Float = 1.0, indices:Null<Array<Int>> = null, looped:Bool = false, timeline:Null<Timeline> = null):Animation {

		var usedTimeline = timeline ?? this.timeline;
		var foundFrames:Array<Int> = usedTimeline.findFrameLabelIndices(label);
		var useableFrames:Array<Int> = [];

		if (foundFrames.length == 0)
		{
			var collectionTimelines = getCollectionTimelines();
			if (collectionTimelines.length != 0)
			{
				for (timeline in collectionTimelines)
				{
					var newFrames = timeline.findFrameLabelIndices(label);
					if (newFrames.length != 0)
					{
						trace('Found frame label "${label}" in timeline "${timeline.name}" from texture atlas "${timeline.parent.path}".');
						foundFrames = newFrames;
						usedTimeline = timeline;
						break;
					}
				}
			}
		}

		if (indices != null && indices.length != 0)
		{
			for (index in indices)
			{
				var frameIndex:Null<Int> = foundFrames[index];
				if (frameIndex != null)
					useableFrames.push(frameIndex);
			}
		}
		else
		{
			useableFrames = foundFrames;
		}

		if (useableFrames.length == 0)
		{
			trace('No frames useable with label "$label" and indices $indices in timeline "${usedTimeline.name}".');
			return null;
		}

		return getAnimByTimeline(usedTimeline, speed, foundFrames, looped);
	}

	public function getAnimBySymbol(symbolName:String, speed:Float = 1.0, indices:Null<Array<Int>> = null, looped:Bool = false):Animation {
		var symbol = getSymbol(symbolName);
		if (symbol == null)
		{
			trace('Symbol not found with name "$symbolName"');
			return null;
		}

		return getAnimByTimeline(symbol.timeline, speed, indices, looped);
	}

	inline public static function getAnimByTimeline(timeline:Timeline, speed:Float = 1.0, indices:Null<Array<Int>> = null, looped:Bool = false):Animation
	{
		var anim = new Animation(timeline, indices);
		anim.loop = looped;
		anim.speed = speed;
		return anim;
	}

	/**
	 * Parsing method for Adobe Animate texture atlases
	 *
	 * @param   animate  	The texture atlas folder path or Animation.json contents string.
	 * @param   spritemaps	Optional, array of the spritemaps to load for the texture atlas
	 * @param   metadata	Optional, string of the metadata.json contents string.
	 * @param   key			Optional, force the cache to use a specific Key to index the texture atlas.
	 * @param   unique  	Optional, ensures that the texture atlas uses a new slot in the cache.
	 * @return  Newly created `AnimateLibrary` collection.
	 */
	public static function fromAnimate(animate:String, ?spritemaps:Array<String>, ?metadata:String, ?key:String, ?unique:Bool = false,
			?settings:AnimateSettings):AnimateLibrary
	{
		var key:String = key ?? animate;

		/*
		if (!unique && _cachedAtlases.exists(key))
		{
			var cachedAtlas = _cachedAtlases.get(key);
			var isAtlasDestroyed = false;

			// Check if the atlas is complete
			// For most cases this shouldnt be an issue but theres a ton of people who make their
			// own flixel caching systems that dont work nice with this.
			// For anyone out there listening, if theres a better option, PLEASE help, this is crap
			// - maru
			for (spritemap in cast(cachedAtlas.parent, FlxAnimateSpritemapCollection).spritemaps)
			{
				if (#if (flixel >= "5.6.0") spritemap.isDestroyed #else spritemap.shader == null #end)
				{
					isAtlasDestroyed = true;
					break;
				}
			}

			// Another check for individual frames (may have combined frames from a Sparrow)
			if (!isAtlasDestroyed)
			{
				for (frame in cachedAtlas.frames)
				{
					if (frame == null || frame.parent == null || frame.frame == null)
					{
						isAtlasDestroyed = true;
						break;
					}
				}
			}

			// Destroy previously cached atlas if incomplete, and create a new instance
			if (isAtlasDestroyed)
			{
				FlxG.log.warn('Texture Atlas with the key "$key" was previously cached, but incomplete. Was it incorrectly destroyed?');
				cachedAtlas.destroy();
				_cachedAtlases.remove(key);
			}
			else
			{
				return cachedAtlas;
			}
		}
		*/

		if (Res.loader.exists(animate + "/Animation.json"))
			return _fromAnimatePath(animate, key, settings);

		return _fromAnimateInput(animate, spritemaps, metadata, key, settings);
	}

	static function listWithFilter(path:String, filter:Resource->Bool, includeSubDirectories:Bool = false)
	{
		// var list = FlxAnimateAssets.list(path, null, path.substring(0, path.indexOf(':')), includeSubDirectories);
		// return list.filter(filter);
		var list = Res.loader.dir(path);
		if (includeSubDirectories)
		{
			function checkSubDirectory(file:Resource)
			{
				if (file.entry.isDirectory)
					for (i in Res.loader.dir(file.entry.path))
					{
						checkSubDirectory(i);
						list.push(i);
					}
			}
			for (i in list.copy())
				checkSubDirectory(i);
		}
		return list.filter(filter);
	}

	static function _fromAnimatePath(path:String, ?key:String, ?settings:AnimateSettings)
	{
		// if (!Res.loader.exists(path + "/Animation.json"))
		// {
		// 	trace('No Animation.json file was found for path "$path".');
		// 	return null;
		// }

		var animation = getTextFromPath(path + "/Animation.json");
		var isInlined = !Res.loader.exists(path + "/metadata.json");
		var libraryList:Null<Array<String>> = null;
		var spritemaps:Array<String> = [];
		var metadata:Null<String> = isInlined ? null : getTextFromPath(path + "/metadata.json");

		if (!isInlined)
		{
			var list = listWithFilter(path + "/LIBRARY", (file) -> file.entry.extension == "json", true);
			libraryList = list.map((res) ->
			{
				var str = res.entry.directory.split("/LIBRARY/").pop();
				return Path.withoutExtension(str);
			});
		}

		// Load all spritemaps
		var spritemapList = listWithFilter(path, (file) -> file.name.startsWith("spritemap"), false);
		var jsonList = spritemapList.filter((file) -> file.entry.extension == "json");

		for (sm in jsonList)
		{
			var id = sm.name.split("spritemap")[1].split(".")[0];
			var imageFile = spritemapList.filter((file) -> file.name.startsWith('spritemap$id') && file.entry.extension != "json")[0];

			spritemaps.push(Path.withoutExtension(imageFile.entry.path));
		}

		if (spritemaps.length <= 0)
		{
			trace('No spritemaps were found for key "$path". Is the texture atlas incomplete?');
			return null;
		}

		return _fromAnimateInput(animation, spritemaps, metadata, key ?? path, isInlined, libraryList, settings);
	}

	static function _fromAnimateInput(rawAnimation:String, spritemaps:Array<String>, metadata:Null<String>, path:Null<String>, isInlined:Bool = true,
			?libraryList:Array<String>, ?settings:AnimateSettings):AnimateLibrary
	{
		var animData:AnimationJson = null;
		try
		{
			animData = Json.parse(rawAnimation);
		}
		catch (e)
		{
			trace('Couldnt load Animation.json with input "$rawAnimation". Is the texture atlas missing?');
			return null;
		}

		if (path.length != 0)
			path = Path.addTrailingSlash(path);

		if (spritemaps == null || spritemaps.length == 0)
		{
			trace('No spritemaps were added for key "$path".');
			return null;
		}

		var library = new AnimateLibrary();
		library.path = path;

		// Load all spritemaps
		for (path in spritemaps)
		{
			var graphic = Res.loader.load(path + ".png").toTile();
			if (graphic == null)
			{
				trace('Failed to load image "$path.png"');
				continue;
			}

			var jsonResourse = Res.loader.load(path + ".json");
			if (jsonResourse == null)
			{
				trace('Failed to load spritemap data "$path.json"');
				continue;
			}

			var spritemap:SpritemapJson;
			try
			{
				spritemap = Json.parse(fixBom(jsonResourse.toText()));
			}
			catch (e)
			{
				trace('Couldnt load ${path + ".json"}.');
				return null;
			}

			for (sprite in spritemap.ATLAS.SPRITES)
			{
				var sprite = sprite.SPRITE;
				var tileW = hxd.Math.ceil(sprite.w);
				var tileH = hxd.Math.ceil(sprite.h);
				var t:Tile = graphic.sub(sprite.x, sprite.y, tileW, tileH);
				library._tiles.set(sprite.name, {t: t, rotated: sprite.rotated});
			}
		}

		library._symbolDictionary = animData.SD;
		library._isInlined = isInlined;
		library._libraryList = libraryList;
		library._settings = settings;

		var metadata:MetadataJson = (metadata == null) ? animData.MD : Json.parse(metadata);

		library.frameRate = metadata.FRT;
		library.timeline = new Timeline(animData.AN.TL, library, animData.AN.SN);
		library.dictionary.set(library.timeline.name, new SymbolItem(library.timeline)); // Add main symbol to the library too

		// stage background color
		var w = metadata.W;
		var h = metadata.H;
		library.stageRect = new IBounds();
		if (w > 0 && h > 0)
			library.stageRect.set(0, 0, w, h);
		else
			library.stageRect.set(0, 0, 1280, 720);
		library.stageColor = Color.fromString(metadata.BGC);

		// stage instance of the main symbol
		var stageInstance:Null<SymbolInstanceJson> = animData.AN.STI;
		library.matrix = (stageInstance != null) ? stageInstance.MX.toMatrix() : new Matrix();

		// clear the temp data crap
		library._symbolDictionary = null;
		library._libraryList = [];
		library._settings = null;

		// _cachedAtlases.set(path, library);

		return library;
	}

	var checkedDirtySymbols:Array<String> = [];

	function setSymbolDirty(targetSymbol:String)
	{
		// Doing this so in a batch of setSymbolDirty, symbols dont get double checked
		if (checkedDirtySymbols.contains(targetSymbol))
			return;

		var checkForSymbol:Timeline->Void;
		checkForSymbol = (timeline:Timeline) ->
		{
			if (timeline == null || timeline.name.length <= 0)
				return;

			checkedDirtySymbols.push(timeline.name);

			/*
			for (layer in timeline)
			{
				for (frame in layer)
				{
					@:privateAccess
					if (!frame._requireBake)
						continue;

					var wasFrameSetDirty:Bool = false;
					for (element in frame)
					{
						switch (element.elementType)
						{
							case GRAPHIC | MOVIECLIP | BUTTON:
								var foundSymbol = element.toSymbolInstance().libraryItem;
								if (foundSymbol.name == targetSymbol)
								{
									if (!wasFrameSetDirty)
										frame.setDirty();
									wasFrameSetDirty = true;
								}
								else
								{
									checkForSymbol(foundSymbol.timeline);
								}
							default:
						}
					}
				}
			}
			*/
		}

		checkForSymbol(timeline);
		checkedDirtySymbols.resize(0);
	}

	public function dispose():Void
	{
		// if (_cachedAtlases.exists(path))
		// 	_cachedAtlases.remove(path);

		if (dictionary != null)
		{
			for (symbol in dictionary.iterator())
				symbol.dispose();
		}

		stageRect = null;
		timeline = Utils.dispose(timeline);
		checkedDirtySymbols = null;
		dictionary = null;
		_tiles = null;
		matrix = null;
	}
}

enum abstract FilterQuality(Int) to Int
{
	var HIGH = 0;
	var MEDIUM = 1;
	var LOW = 2;
	var RUDY = 3;

	inline public function getQualityFactor():Float
	{
		return switch (this)
		{
			case FilterQuality.MEDIUM: 1.75;
			case FilterQuality.LOW: 2.0;
			case FilterQuality.RUDY: 2.25;
			default: 1.0;
		}
	}

	inline public function getPixelFactor():Float
	{
		return switch (this)
		{
			case FilterQuality.MEDIUM: 16.0;
			case FilterQuality.LOW: 12.0;
			case FilterQuality.RUDY: 8.0;
			default: 1.0;
		}
	}
}
