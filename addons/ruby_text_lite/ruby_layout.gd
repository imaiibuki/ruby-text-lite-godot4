## RubyLayoutLite
##
## Pure, stateless layout math for ruby text, kept separate from
## RubyLabelLite so it can be unit-tested headlessly without a font/Control
## (see tests/test_layout.gd) -- same pattern as RubyParserLite.
extends RefCounted
class_name RubyLayoutLite


## Collision-resolution pass for ruby readings that land on the same visual
## line. `ranges` is an Array of `[left, right]` pairs (each already centered
## over its base and individually edge-clamped into `[line_left, line_right]`
## by the caller), **sorted by `left` ascending**. `min_gap` is the minimum
## horizontal gap to keep between two adjacent readings. Returns an Array of
## adjusted `left` values, same order/length as `ranges`; widths never change.
##
## Algorithm (matches normal ruby/furigana collision handling):
##   1. Left-to-right pass: if a reading starts closer than `min_gap` to the
##      (possibly already-pushed) right edge of the previous reading, push it
##      right just enough to clear the gap. This can chain through several
##      readings in a row.
##   2. If that chain pushes the last reading's right edge past `line_right`,
##      a right-to-left pass pulls readings back so the rightmost one ends
##      exactly at `line_right`, shifting earlier readings left as needed to
##      keep `min_gap`.
##   3. If there still isn't enough total room (the sum of widths + gaps
##      exceeds the line), the leftmost reading is clamped to `line_left` and
##      a small residual overlap with its neighbor is allowed rather than
##      shrinking/clipping any text -- see README "Limitations".
##
## When no reading actually violates `min_gap`, every step is a no-op and the
## original `left` values are returned unchanged.
static func resolve_overlaps(ranges: Array, line_left: float, line_right: float, min_gap: float) -> Array:
	var n := ranges.size()
	var lefts: Array = []
	var rights: Array = []
	for r in ranges:
		lefts.append(float(r[0]))
		rights.append(float(r[1]))
	if n == 0:
		return lefts

	# 1) push right to resolve forward overlaps/gap violations.
	for i in range(1, n):
		var width: float = rights[i] - lefts[i]
		var min_left: float = rights[i - 1] + min_gap
		if lefts[i] < min_left:
			lefts[i] = min_left
			rights[i] = lefts[i] + width

	# 2) if that pushed the last reading past the line's right edge, pull
	# back from the right, shifting earlier readings left as needed.
	if rights[n - 1] > line_right:
		var width_last: float = rights[n - 1] - lefts[n - 1]
		rights[n - 1] = line_right
		lefts[n - 1] = rights[n - 1] - width_last
		for i in range(n - 2, -1, -1):
			var width_i: float = rights[i] - lefts[i]
			var max_right: float = lefts[i + 1] - min_gap
			if rights[i] > max_right:
				rights[i] = max_right
				lefts[i] = rights[i] - width_i

	# 3) not enough room even for that -- clamp the leftmost to the line's
	# left edge and allow a small residual overlap (documented limitation).
	if lefts[0] < line_left:
		var width0: float = rights[0] - lefts[0]
		lefts[0] = line_left
		rights[0] = lefts[0] + width0

	return lefts
