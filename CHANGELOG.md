# Changelog

All notable changes to this addon are documented here.

## 1.0.0 -- 2026-11-05

Initial release (free Lite version of Ruby Text for Godot 4).

- `RubyLabelLite` (`extends RichTextLabel`, `@tool`): drop-in replacement
  that renders furigana/ruby/pinyin above text.
- `ruby_text` property that accepts `[ruby=よみ]漢字[/ruby]` BBCode only
  (Aozora/narou notation, mono-ruby, and emphasis dots/bouten are full-
  version-only features; Lite leaves that input as literal text).
- Exported properties: `ruby_scale`, `ruby_color`, `ruby_offset`,
  `auto_spacing`, `ruby_reveal` (`FIRST_CHAR` / `ALL_CHARS`).
- Ruby follows `visible_characters` / `visible_ratio` (typewriter effect) and
  is drawn per wrapped-line segment when a base run wraps across lines.
- Collision resolution between adjacent readings on the same visual line
  (`RubyLayoutLite.resolve_overlaps`, unit-tested in `tests/test_layout.gd`).
- `RubyParserLite.strip_ruby()` helper for plain-text extraction.
- Classes renamed from the full version's (`RubyLabelLite`,
  `RubyParserLite`, `RubyLayoutLite`, `RBEffectLite`) so Lite can be
  installed alongside the full "Ruby Text" addon without a `class_name`
  conflict.
- Demo scene (`demo/demo.tscn`) with a small typewriter-style demo.
- Headless unit tests (`tests/test_parser.gd`, `tests/test_layout.gd`,
  `tests/test_reveal.gd`).
- Tested on Godot 4.3-stable and 4.7.2-stable (Windows, headless).
