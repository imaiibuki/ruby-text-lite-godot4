## RubyParserLite
##
## Pure-function parser that converts ruby notation into BBCode consumable by
## RichTextLabel + the "rbl" custom RichTextEffect (see rb_effect.gd).
##
## Lite supports exactly ONE input notation (the full "Ruby Text" addon also
## understands Aozora/narou notation `｜漢字《よみ》`, mono-ruby, and Kakuyomu
## emphasis dots `《《...》》` -- see
## https://ibuking289.itch.io/ruby-text-godot4):
##
##   BBCode:            [ruby=よみ]漢字[/ruby]
##
## Anything that looks like the full version's other notations (｜, 《...》,
## mono-ruby `・` splitting, `《《...》》` emphasis dots) is simply NOT
## recognized here and is left in the output exactly as typed -- plain
## literal text, no ruby, no error.
##
## Output: BBCode where every ruby base is wrapped as [rbl id=N]base[/rbl] and
## the readings are returned as a separate array indexed by N (so the reading
## text itself never has to round-trip through BBCode escaping).
##
## This script has no dependency on scene nodes; every function is static so
## it can be unit-tested headlessly (see tests/test_parser.gd).
extends RefCounted
class_name RubyParserLite


## Wraps `base` as a single-group ruby (no mono-ruby splitting -- that is a
## full-version-only feature).
static func _make_rb_group(base: String, yomi: String, readings: Array, base_lengths: Array) -> String:
	if base.is_empty():
		return ""
	var id := readings.size()
	readings.append(yomi)
	base_lengths.append(base.length())
	return "[rbl id=%d]%s[/rbl]" % [id, base]


## Converts `source` (raw ruby_text, possibly containing other BBCode tags
## which are left untouched) into:
##   { "bbcode": String, "readings": Array[String], "base_lengths": Array[int] }
## `base_lengths[id]` is the number of base characters belonging to rbl id N
## (used by RubyLabelLite's ALL_CHARS reveal mode).
static func parse(source: String) -> Dictionary:
	var out := ""
	var readings: Array = []
	var base_lengths: Array = []
	var n := source.length()
	var i := 0
	while i < n:
		var c := source[i]
		if c == "[" and source.substr(i, 6) == "[ruby=":
			var close_bracket := source.find("]", i)
			if close_bracket != -1:
				var end_tag := source.find("[/ruby]", close_bracket + 1)
				if end_tag != -1:
					var yomi := source.substr(i + 6, close_bracket - (i + 6))
					var base := source.substr(close_bracket + 1, end_tag - (close_bracket + 1))
					out += _make_rb_group(base, yomi, readings, base_lengths)
					i = end_tag + 7
					continue
			# malformed tag; fall through and copy the bracket literally
			out += c
			i += 1
			continue
		else:
			out += c
			i += 1
	return {"bbcode": out, "readings": readings, "base_lengths": base_lengths}


## Convenience: returns just the plain visible text (base characters only, no
## readings, no BBCode tags of any kind). Useful for copy-to-clipboard,
## accessibility, or search indexing.
static func strip_ruby(source: String) -> String:
	var parsed := parse(source)
	var bbcode: String = parsed["bbcode"]
	var out := ""
	var n := bbcode.length()
	var i := 0
	while i < n:
		var c := bbcode[i]
		if c == "[":
			var end := bbcode.find("]", i)
			if end == -1:
				out += bbcode.substr(i)
				break
			i = end + 1
			continue
		out += c
		i += 1
	return out
