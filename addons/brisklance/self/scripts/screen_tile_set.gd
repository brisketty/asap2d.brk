class_name ScreenTileSet
extends Resource
## A tileable border decoration: an artist draws one tile texture (plus a few
## variations), and `ScreenTileBorder` auto-tiles them around the four screen
## edges. An `AnimatedTexture` entry animates for free - the layer itself has
## no animation logic. Resolved through `ThemeManager.resolve_screen_tile`.

@export var tile_variations: Array[Texture2D] = []
@export var tile_size: Vector2i = Vector2i(64, 64)
@export var border_thickness_tiles: int = 1
