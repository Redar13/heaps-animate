# HEAPS-ANIMATE

This library is a port of the [flixel-animate](https://github.com/MaybeMaru/flixel-animate) to the Heaps engine.

> [!WARNING]
> It's still in development and some things may change.

## Usage

It works similarly to a regular flixel-animate.

### Load atlas

```haxe
import h2d.animate.Animate;
import h2d.animate.AnimateLibrary;

...

var animate = new Animate(parentObj);
animate.library = AnimateLibrary.fromAnimate("path/to/atlas");
```

### Animations

```haxe
animate.addAnimBySymbol("symbolAnim", "symbolName", true);
animate.addAnimByFrameLabel("labelAnim", "labelName", true);
animate.addAnimByTimeline("timelineAnim", someTimelineObject, true);

var customAnimObj = new h2d.animate.Animate.Animation(animate.library.timeline);
customAnimObj.loop = (Math.random() > 0.5);
animate.addAnim("customAnim", customAnimObj);

animate.play("customAnim");
```

### Load Settings

```haxe
var library = AnimateLibrary.fromAnimate("path/to/atlas", {
   swfMode: false,                  // If to render like in a SWF file, rather than the Animate editor.
   cacheOnLoad: false,              // If to precache all animation filters and masks at once, rather than at runtime.
   filterQuality: MEDIUM            // Level of quality used to render filters. (HIGH, MEDIUM, LOW, RUDY)
   onSymbolCreate: SymbolItem->Void // Function called when a symbol item is created, useful for hardcoded modifications.
});
```
