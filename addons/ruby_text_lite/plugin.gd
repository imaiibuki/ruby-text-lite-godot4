## Minimal EditorPlugin for Ruby Text Lite.
##
## RubyLabelLite/RubyParserLite/RBEffectLite are all usable without this
## plugin being enabled at all, because they declare `class_name` and Godot
## picks those up project-wide. This plugin exists mainly so the addon shows
## up in the Project Settings > Plugins list, and to register a custom icon
## for RubyLabelLite nodes in the "Create Node" dialog.
@tool
extends EditorPlugin

const RUBY_LABEL_ICON := "res://addons/ruby_text_lite/icon.svg"


func _enter_tree() -> void:
	# On the very first --import of a fresh project the .svg has no import
	# cache yet; load() would error, so fall back to null (default icon)
	# until the next editor start re-imports it.
	var icon: Texture2D = load(RUBY_LABEL_ICON) if ResourceLoader.exists(RUBY_LABEL_ICON) else null
	add_custom_type(
		"RubyLabelLite",
		"RichTextLabel",
		preload("ruby_label.gd"),
		icon
	)


func _exit_tree() -> void:
	remove_custom_type("RubyLabelLite")
