@tool
extends EditorPlugin
class_name AsapFrameworkPlugin

const AUTOLOADS: Array[Dictionary] = [
	{"name": "Tuning", "path": "res://addons/brisklance/self/autoloads/tuning.tscn"},
	{"name": "EventBus", "path": "res://addons/brisklance/self/autoloads/event_bus.tscn"},
	{"name": "ThemeManager", "path": "res://addons/brisklance/self/autoloads/theme_manager.tscn"},
	{"name": "ImpactVfx", "path": "res://addons/brisklance/self/autoloads/impact_vfx.tscn"},
	{"name": "WorldEnvironment2D", "path": "res://addons/brisklance/self/autoloads/world_environment_2d.tscn"},
	{"name": "CameraDirector", "path": "res://addons/brisklance/self/autoloads/camera_director.tscn"},
	{"name": "HudPolish", "path": "res://addons/brisklance/self/autoloads/hud_polish.tscn"},
	{"name": "SfxPlayer", "path": "res://addons/brisklance/self/autoloads/sfx_player.tscn"},
	{"name": "MusicDirector", "path": "res://addons/brisklance/self/autoloads/music_director.tscn"},
	{"name": "AudioMixing", "path": "res://addons/brisklance/self/autoloads/audio_mixing.tscn"},
]


func _enter_tree() -> void:
	# Re-registering on every load (not just on enable) keeps a fresh checkout
	# working without ever having to toggle the plugin off/on in the editor.
	# _enter_tree fires on ordinary quit too, unlike _disable_plugin, so removal
	# stays out of here - it belongs only to an explicit disable.
	for entry: Dictionary in AUTOLOADS:
		add_autoload_singleton(entry.name as String, entry.path as String)


func _disable_plugin() -> void:
	for entry: Dictionary in AUTOLOADS:
		remove_autoload_singleton(entry.name as String)
