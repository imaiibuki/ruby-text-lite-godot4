## RBEffectLite
##
## Custom RichTextEffect for the "rbl" BBCode tag ([rbl id=N]base[/rbl])
## produced by RubyParserLite. It does not change how the base glyph is drawn
## (no color/transform change) -- its only job is to *observe* where each
## base glyph ends up this frame and report that back to the owning
## RubyLabelLite, which then draws the actual ruby (furigana) text on top in
## its own _draw().
##
## The tag is "rbl" (not "rb") and the class is "RBEffectLite" (not
## "RBEffect") so this Lite addon can be installed in the same project as the
## paid Ruby Text addon without any class_name collision.
##
## RichTextEffect has no drawing API of its own (it can only tweak how the
## engine draws the existing glyph), so it cannot paint the ruby text itself;
## that is why RubyLabelLite needs a second drawing pass. See ruby_label.gd
## for details on how that pass is wired up to avoid a one-frame lag.
extends RichTextEffect
class_name RBEffectLite

var bbcode := "rbl"

## Set by RubyLabelLite right after instancing this effect.
var owner_label: WeakRef


func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	if owner_label == null:
		return true
	var label: Object = owner_label.get_ref()
	if label == null:
		return true
	var id: int = int(char_fx.env.get("id", -1))
	if id < 0:
		return true
	if not char_fx.visible:
		# Respect visible_characters/visible_ratio: if the base glyph itself
		# is not being drawn, don't record it (so the ruby won't show either).
		return true
	var ts := TextServerManager.get_primary_interface()
	var font_size: int = label.get_theme_font_size("normal_font_size")
	var advance: float = font_size * 0.6 # fallback guess
	if char_fx.font.is_valid():
		advance = ts.font_get_glyph_advance(char_fx.font, font_size, char_fx.glyph_index).x
	var pos: Vector2 = char_fx.transform.origin + char_fx.offset
	label._rb_record_glyph(id, pos, advance)
	return true
