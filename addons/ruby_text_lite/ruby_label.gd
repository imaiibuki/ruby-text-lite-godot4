## RubyLabelLite
##
## A drop-in RichTextLabel replacement that understands [ruby=よみ]漢字[/ruby]
## BBCode and renders small reading text centered above each base run. This is
## the free Lite version of RubyLabel (see https://ibuking289.itch.io/ruby-text-godot4
## for the full version, which also understands Aozora/narou-style
## ｜漢字《よみ》 notation, mono-ruby, emphasis dots (bouten), and adds a ruby
## outline).
##
## ---------------------------------------------------------------------------
## HOW RENDERING WORKS (read this before touching the drawing code)
## ---------------------------------------------------------------------------
## RichTextEffect (see rb_effect.gd) can only *modify how a glyph is drawn*
## (color/transform/visibility) -- it has no API to paint extra content like
## the reading text. So the actual ruby text has to be painted by someone
## else, after the base glyph positions for this frame are known.
##
## This implementation overrides _draw() directly on this RichTextLabel
## subclass and paints on top of the native text drawing. Verified
## empirically (same approach as the full Ruby Text addon) that for a
## Control-derived engine class, GDScript's `_draw()` virtual fires *in
## addition to* the engine's own native NOTIFICATION_DRAW drawing, in the
## same frame, right after the native text (and therefore after the "rbl"
## effect's _process_custom_fx calls for this frame) -- so there is no
## one-frame lag or flicker, and no extra node is needed.
##
## Because the custom effect is re-run every frame (RichTextLabel does this
## automatically whenever any custom effect is installed), ruby positions
## naturally follow [wave]/[shake]/etc. offsets applied to the base glyphs,
## and naturally respect visible_characters / visible_ratio (a glyph that
## wasn't drawn this frame is simply never recorded, so its ruby doesn't
## appear either).
@tool
extends RichTextLabel
class_name RubyLabelLite

## Explicit preload (rather than relying on global class_name resolution)
## so this works immediately even when the project's global script class
## cache hasn't been regenerated yet -- e.g. right after adding this new
## script, before the editor has ever opened the project.
const RubyLayoutLite = preload("res://addons/ruby_text_lite/ruby_layout.gd")

enum RubyReveal {
	FIRST_CHAR, ## show the reading as soon as the base's first character is visible
	ALL_CHARS,  ## only show the reading once every character of the base is visible
}

## Source text using ruby notation ([ruby=よみ]漢字[/ruby] BBCode only in
## Lite). Converted to BBCode and assigned to `text`.
@export_multiline var ruby_text: String = "":
	set(value):
		ruby_text = value
		_apply_ruby_text()

## Ruby font size, as a fraction of the base font size.
@export_range(0.1, 1.5, 0.01) var ruby_scale: float = 0.5:
	set(value):
		ruby_scale = value
		_update_auto_spacing()
		queue_redraw()

@export var ruby_color: Color = Color(1, 1, 1, 1):
	set(value):
		ruby_color = value
		queue_redraw()

## Extra gap, in pixels, between the bottom of the ruby text and the top of
## the base glyphs.
@export_range(-16, 32, 0.5) var ruby_offset: float = 2.0:
	set(value):
		ruby_offset = value
		queue_redraw()

## When true, automatically reserves vertical room (top margin + extra line
## separation) for the ruby text so it doesn't get clipped or overlap the
## previous line.
@export var auto_spacing: bool = true:
	set(value):
		auto_spacing = value
		_update_auto_spacing()

@export var ruby_reveal: RubyReveal = RubyReveal.FIRST_CHAR

var _readings: Array = []
var _base_lengths: Array = []
# _base_start_offsets[id] = the character offset, counting only the plain
# (non-BBCode-tag) characters of `text` -- i.e. the same unit
# `visible_characters`/`visible_ratio` count against -- where that id's base
# run starts. See the big comment on _compute_base_start_offsets() for why
# this is needed in addition to (not instead of) char_fx.visible.
var _base_start_offsets: Array = []
var _rb_effect: RBEffectLite
# auto_spacing bookkeeping (see _update_auto_spacing)
var _user_sb: StyleBox = null
var _own_sb: StyleBox = null
var _user_ls = null # int, or null = the user set no override
var _own_ls: int = -1
var _spacing_base_size: int = -1
var _spacing_busy: bool = false

# Glyph positions recorded by _rb_effect for the frame currently being drawn.
# id -> Array[{pos: Vector2, adv: float}]
var _glyphs_by_id: Dictionary = {}
var _glyphs_frame: int = -1


func _init() -> void:
	bbcode_enabled = true
	_rb_effect = RBEffectLite.new()
	_rb_effect.owner_label = weakref(self)
	install_effect(_rb_effect)


func _ready() -> void:
	_update_auto_spacing()


## Called by RBEffectLite._process_custom_fx for every visible glyph that
## belongs to an [rbl id=N] block.
func _rb_record_glyph(id: int, pos: Vector2, advance: float) -> void:
	var frame := Engine.get_frames_drawn()
	if frame != _glyphs_frame:
		_glyphs_by_id.clear()
		_glyphs_frame = frame
	if not _glyphs_by_id.has(id):
		_glyphs_by_id[id] = []
	_glyphs_by_id[id].append({"pos": pos, "adv": advance})


func _apply_ruby_text() -> void:
	var parsed := RubyParserLite.parse(ruby_text)
	_readings = parsed["readings"]
	_base_lengths = parsed["base_lengths"]
	text = parsed["bbcode"]
	_base_start_offsets = _compute_base_start_offsets(text, _readings.size())
	_update_auto_spacing()


## Computes, for every "[rbl id=N]" group in `bbcode`, the plain-character
## offset (skipping every "[...]" tag, which is exactly what RichTextLabel's
## own visible_characters/visible_ratio count against) where that group's
## base run starts.
##
## Why this exists: _draw() cannot rely on "did _rb_record_glyph get called
## for this id with char_fx.visible == true this frame" alone to decide
## whether a reading should be painted. The custom effect's per-frame
## "visible" signal can lag behind a visible_ratio/visible_characters change
## for a handful of frames, so comparing each id's own fixed start offset
## against the live (unlagged) `visible_characters` value every frame in
## _draw() sidesteps that engine-level lag entirely.
static func _compute_base_start_offsets(bbcode: String, id_count: int) -> Array:
	var offsets: Array = []
	for i in range(id_count):
		offsets.append(0)
	var plain_count := 0
	var n := bbcode.length()
	var i := 0
	while i < n:
		var c := bbcode[i]
		if c == "[":
			var close := bbcode.find("]", i)
			if close == -1:
				plain_count += 1
				i += 1
				continue
			var tag := bbcode.substr(i + 1, close - (i + 1))
			if tag.begins_with("rbl id="):
				var id := int(tag.substr(7))
				if id >= 0 and id < offsets.size():
					offsets[id] = plain_count
			i = close + 1
			continue
		plain_count += 1
		i += 1
	return offsets


## Returns true if `id`'s reading should be considered for drawing *this*
## frame, given the live `visible_characters` value. This is the
## authoritative gate (see _compute_base_start_offsets() for why it exists
## instead of trusting char_fx.visible alone) -- pulled out into its own
## method, rather than inlined in _draw(), so it has a single
## implementation that both _draw() and tests (tests/test_reveal.gd) can
## call directly without needing to rasterize a frame.
func _is_reading_revealed(id: int) -> bool:
	var vis_chars: int = visible_characters
	if vis_chars < 0:
		return true # RichTextLabel's own "no limit" sentinel (ratio == 1.0).
	var start_off: int = _base_start_offsets[id] if id < _base_start_offsets.size() else 0
	if ruby_reveal == RubyReveal.FIRST_CHAR:
		return start_off < vis_chars
	var base_len: int = _base_lengths[id] if id < _base_lengths.size() else 1
	return start_off + base_len <= vis_chars


## auto_spacing works on top of the user's own "normal" stylebox and
## "line_separation" overrides (background, padding...): they are remembered,
## extended by the ruby room, and put back when auto_spacing is turned off.
func _update_auto_spacing() -> void:
	if _spacing_busy:
		return
	_spacing_busy = true
	# Any override that is not the one we set last time belongs to the user.
	if has_theme_stylebox_override("normal"):
		var cur_sb := get_theme_stylebox("normal")
		if cur_sb != _own_sb:
			_user_sb = cur_sb
	else:
		_user_sb = null
	if has_theme_constant_override("line_separation"):
		var cur_ls := get_theme_constant("line_separation")
		if cur_ls != _own_ls:
			_user_ls = cur_ls
	else:
		_user_ls = null
	_own_sb = null
	_own_ls = -1
	if _user_sb != null:
		add_theme_stylebox_override("normal", _user_sb)
	else:
		remove_theme_stylebox_override("normal")
	if _user_ls != null:
		add_theme_constant_override("line_separation", _user_ls)
	else:
		remove_theme_constant_override("line_separation")
	_spacing_base_size = _get_base_font_size()
	if auto_spacing:
		var rsize := _get_ruby_font_size(_spacing_base_size)
		var extra := rsize + int(ceil(max(ruby_offset, 0.0))) + 2
		var base_sb := get_theme_stylebox("normal")
		var sb: StyleBox = base_sb.duplicate() if base_sb != null else StyleBoxEmpty.new()
		sb.content_margin_top = (base_sb.get_margin(SIDE_TOP) if base_sb != null else 0.0) + extra
		_own_sb = sb
		_own_ls = get_theme_constant("line_separation") + extra
		add_theme_stylebox_override("normal", _own_sb)
		add_theme_constant_override("line_separation", _own_ls)
	queue_redraw()
	_spacing_busy = false


func _notification(what: int) -> void:
	# A theme / font size change outside our setters: re-reserve the ruby room.
	if what == NOTIFICATION_THEME_CHANGED and not _spacing_busy:
		if _get_base_font_size() != _spacing_base_size:
			_update_auto_spacing()


func _get_base_font_size() -> int:
	var s := get_theme_font_size("normal_font_size")
	if s <= 0:
		s = 16
	return s


func _get_ruby_font_size(base_size: int) -> int:
	return max(1, int(round(base_size * ruby_scale)))


func _get_ruby_font() -> Font:
	var f := get_theme_font("normal_font")
	return f


## Splits `reading` into `counts.size()` parts, one per wrapped-line segment
## of a base run, proportionally to how many base glyphs landed in each
## segment. Guarantees: order preserved (segment i gets a contiguous slice,
## in order), every char of `reading` is used exactly once across all parts,
## and every segment gets at least 1 character if there are at least as many
## reading characters as segments. Used so a base that wraps across lines
## doesn't repeat (and overflow) the full reading on every line -- see
## README "Limitations".
static func _distribute_reading(reading: String, counts: Array) -> Array:
	var n := counts.size()
	if n <= 1:
		return [reading]
	var total_chars := reading.length()
	var total_base := 0
	for c in counts:
		total_base += int(c)
	if total_base <= 0:
		total_base = n
	var shares: Array = []
	for i in range(n):
		shares.append(0)
	if total_chars >= n:
		for i in range(n):
			shares[i] = 1
		var remaining := total_chars - n
		if remaining > 0:
			var raw: Array = []
			var floors: Array = []
			var floor_sum := 0
			for i in range(n):
				var w: float = float(counts[i]) / float(total_base) * remaining
				raw.append(w)
				var f := int(floor(w))
				floors.append(f)
				floor_sum += f
			var left := remaining - floor_sum
			var order: Array = []
			for i in range(n):
				order.append(i)
			order.sort_custom(func(a, b):
				var fa: float = raw[a] - floors[a]
				var fb: float = raw[b] - floors[b]
				if fa == fb:
					return a < b
				return fa > fb
			)
			for k in range(left):
				floors[order[k]] += 1
			for i in range(n):
				shares[i] += floors[i]
	else:
		# Fewer reading characters than line segments: give 1 char each to
		# the segments with the most base glyphs (ties broken by original
		# order), 0 to the rest.
		var order2: Array = []
		for i in range(n):
			order2.append(i)
		order2.sort_custom(func(a, b):
			if counts[a] == counts[b]:
				return a < b
			return counts[a] > counts[b]
		)
		for k in range(total_chars):
			shares[order2[k]] = 1
	var parts: Array = []
	var pos := 0
	for i in range(n):
		parts.append(reading.substr(pos, shares[i]))
		pos += shares[i]
	return parts


## Minimum horizontal gap enforced between two ruby readings that land on the
## same visual line (see RubyLayoutLite.resolve_overlaps). There is no
## letter-spacing/shrink API for BitmapFont-drawn strings, so collision
## resolution is purely a *position* nudge, never a size change.
const RUBY_MIN_GAP_RATIO := 0.05
const RUBY_MIN_GAP_PX := 1.0


func _draw() -> void:
	# NOTE: this draws *in addition to* this Control's own native text
	# rendering -- see the big comment at the top of this file.
	if _readings.is_empty():
		return
	var font := _get_ruby_font()
	if font == null:
		return
	var base_size := _get_base_font_size()
	var rsize := _get_ruby_font_size(base_size)
	var ascent := font.get_ascent(base_size)
	var ci := get_canvas_item()

	# Drawable content area, in this Control's local coordinates. Ruby lines
	# are clamped into this rect instead of being allowed to overhang past
	# the label's own edges when the base sits at the very start/end of a
	# line -- matching normal Japanese typesetting.
	var sb := get_theme_stylebox("normal")
	var margin_l := 0.0
	var margin_r := 0.0
	if sb:
		margin_l = sb.get_margin(SIDE_LEFT)
		margin_r = sb.get_margin(SIDE_RIGHT)
	var content_l := margin_l
	var content_r := size.x - margin_r

	# Pass 1: compute each reading-segment's centered + edge-clamped draw box,
	# grouped by visual line (rounded base-glyph Y). Two *different* ruby
	# groups ([rbl id=]s) can land on the same visual line -- that's exactly
	# the case that can overlap -- so collision resolution (pass 2) needs to
	# see a whole line's readings together, not one ruby group at a time.
	var lines_boxes: Dictionary = {}  # line_key(int) -> Array[{part, draw_x, draw_y, text_width}]
	var line_order: Array = []        # first-seen order of line_key, for stable iteration

	for id_variant in _glyphs_by_id.keys():
		var id: int = id_variant
		if id < 0 or id >= _readings.size():
			continue
		var reading: String = _readings[id]
		if reading.is_empty():
			continue
		if not _is_reading_revealed(id):
			continue
		var glyphs: Array = _glyphs_by_id[id]
		# Group glyphs by (rounded) line Y so a base that wraps across lines
		# gets one reading drawn per line segment instead of one giant
		# overlapping blob. `count` = how many base glyphs landed on that
		# line, used below to split the reading proportionally.
		var segments: Dictionary = {}
		for g in glyphs:
			var gy: float = g["pos"].y
			var key := int(round(gy))
			if not segments.has(key):
				segments[key] = {"min_x": g["pos"].x, "max_x": g["pos"].x + g["adv"], "y": gy, "count": 1}
			else:
				var seg = segments[key]
				seg["min_x"] = min(seg["min_x"], g["pos"].x)
				seg["max_x"] = max(seg["max_x"], g["pos"].x + g["adv"])
				seg["count"] += 1
		var keys := segments.keys()
		keys.sort()

		var counts: Array = []
		for key in keys:
			counts.append(segments[key]["count"])
		var reading_parts: Array = _distribute_reading(reading, counts)

		for idx in range(keys.size()):
			var line_key: int = keys[idx]
			var seg = segments[line_key]
			var part: String = reading_parts[idx]
			if part.is_empty():
				continue
			var center_x: float = (seg["min_x"] + seg["max_x"]) * 0.5
			var text_width: float = font.get_string_size(part, HORIZONTAL_ALIGNMENT_LEFT, -1, rsize).x
			# Clamp into [content_l, content_r - text_width]; if the text is
			# wider than the whole content area, left-align at content_l
			# rather than clipping (both edges are covered by clamp()
			# degrading to content_l when max_x < min_x).
			var min_x := content_l
			var max_x := content_r - text_width
			var draw_x: float
			if max_x < min_x:
				draw_x = min_x
			else:
				draw_x = clamp(center_x - text_width * 0.5, min_x, max_x)
			var base_top: float = seg["y"] - ascent
			var draw_y: float = base_top - ruby_offset
			if not lines_boxes.has(line_key):
				lines_boxes[line_key] = []
				line_order.append(line_key)
			lines_boxes[line_key].append({"part": part, "draw_x": draw_x, "draw_y": draw_y, "text_width": text_width})

	# Pass 2: resolve left-right collisions between readings that share a
	# visual line -- RubyLayoutLite.resolve_overlaps is the pure, unit-tested
	# function (see tests/test_layout.gd) -- then draw. When nothing on a
	# line actually overlaps, resolve_overlaps is a no-op and every box is
	# drawn at exactly the same draw_x as before this change.
	var min_gap: float = max(RUBY_MIN_GAP_PX, rsize * RUBY_MIN_GAP_RATIO)
	for line_key in line_order:
		var boxes: Array = lines_boxes[line_key]
		boxes.sort_custom(func(a, b): return a["draw_x"] < b["draw_x"])
		var ranges: Array = []
		for b in boxes:
			ranges.append([b["draw_x"], b["draw_x"] + b["text_width"]])
		var adjusted_lefts: Array = RubyLayoutLite.resolve_overlaps(ranges, content_l, content_r, min_gap)

		for i in range(boxes.size()):
			var b = boxes[i]
			var draw_x: float = adjusted_lefts[i]
			font.draw_string(ci, Vector2(draw_x, b["draw_y"]), b["part"], HORIZONTAL_ALIGNMENT_LEFT, -1, rsize, ruby_color)
