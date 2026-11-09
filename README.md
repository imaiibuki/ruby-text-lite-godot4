# Ruby Text Lite for Godot 4

Free Lite version of [Ruby Text for Godot 4](https://ibuking289.itch.io/ruby-text-godot4) ($4) -- try the full version in your browser: [free web demo](https://ibuking289.itch.io/japanese-text-godot-demo).

![Ruby Text Lite: furigana and pinyin above RichTextLabel text with [ruby=...] BBCode](docs/screenshot.png)

Furigana / ruby / pinyin annotations for `RichTextLabel`. Use
`[ruby=よみ]漢字[/ruby]` BBCode and it renders small reading text centered
above the base characters -- combinable with Godot's existing BBCode effects
(color, wave, shake, ...) and with the typewriter `visible_characters` /
`visible_ratio` workflow.

> **This addon's code was written with the help of AI (Claude).**

## What it does (Lite)

- Drop-in: add a `RubyLabelLite` node and assign `ruby_text` instead of
  `text`.
- `[ruby=よみ]漢字[/ruby]` BBCode notation -- that is the only input notation
  Lite understands (see the table below for what the full version adds).
- Works together with other BBCode tags (`[color]`, `[wave]`, `[shake]`,
  ...) -- ruby text itself is drawn with its own `ruby_color`, independent of
  the base's BBCode color.
- Typewriter-friendly: a base's reading only appears once the base glyph(s)
  are actually visible, so it works with `visible_characters` /
  `visible_ratio` out of the box.
- Ruby for a base that wraps across two lines is drawn once per line segment
  so it never overlaps the text.
- Adjacent readings never overlap each other: when two neighboring ruby
  groups on the same line are wide enough to collide, the later one is
  nudged right -- or earlier ones nudged left, if it would otherwise run off
  the line -- just enough to keep a small minimum gap.
- Automatic vertical spacing (`auto_spacing`) so the ruby doesn't get clipped
  against the previous line or the top of the label.

## Install

1. Copy `addons/ruby_text_lite/` into your project's `addons/` folder.
2. Project Settings > Plugins > enable "Ruby Text Lite" (optional --
   `RubyLabelLite` works immediately via `class_name` even with the plugin
   disabled; enabling it just adds a `RubyLabelLite` icon/shortcut to the
   "Create Node" dialog).
3. Add a `RubyLabelLite` node (or change an existing `RichTextLabel` node's
   type to `RubyLabelLite` in the Scene dock), assign a font via the usual
   `normal_font` theme override, and set `ruby_text`.

Lite's classes (`RubyLabelLite`, `RubyParserLite`, `RubyLayoutLite`,
`RBEffectLite`) are all renamed from the full version's, so Lite and the
full "Ruby Text" addon can both be installed in the same project without any
`class_name` conflict.

## Properties (RubyLabelLite)

| Property | Type | Default | Description |
|---|---|---|---|
| `ruby_text` | String (multiline) | `""` | Source text using `[ruby=よみ]漢字[/ruby]` BBCode. Setting it converts to BBCode and assigns `RichTextLabel.text`. |
| `ruby_scale` | float | `0.5` | Ruby font size as a fraction of the label's `normal_font_size`. |
| `ruby_color` | Color | white | Fill color for the ruby text. |
| `ruby_offset` | float | `2.0` | Extra gap, in pixels, between the ruby text and the top of the base glyphs. |
| `auto_spacing` | bool | `true` | Automatically reserves vertical room so ruby isn't clipped. |
| `ruby_reveal` | enum | `FIRST_CHAR` | `FIRST_CHAR`: show the reading as soon as the base's first character is visible. `ALL_CHARS`: wait until every character of the base is visible. |

## Lite vs full Ruby Text ($4)

| Feature | Lite (free) | Full ($4) |
|---|---|---|
| `[ruby=よみ]漢字[/ruby]` BBCode | Yes | Yes |
| Aozora/narou notation `｜漢字《よみ》`, `漢字《よみ》` | No (left as literal text) | Yes |
| Mono-ruby `｜東京《とう・きょう》` | No | Yes |
| Emphasis dots / bouten `《《強調》》` | No | Yes |
| Ruby outline (`ruby_outline_size`/`ruby_outline_color`) | No | Yes |
| `ruby_scale`, `ruby_color`, `ruby_offset`, `auto_spacing` | Yes | Yes |
| Typewriter reveal (`visible_characters`/`visible_ratio`, `ruby_reveal`) | Yes | Yes |
| Adjacent-reading overlap avoidance | Yes | Yes |
| Wrapped-base line handling | Yes | Yes |

Full version: <https://ibuking289.itch.io/ruby-text-godot4>

## Limitations (Lite, honest list)

- Only `[ruby=よみ]漢字[/ruby]` BBCode is recognized. Any `｜`/`《`/`》`
  characters, or a `・`-separated reading, are left in the output exactly as
  typed -- plain literal text, no ruby, no error.
- No ruby outline option.
- Same rendering limitations as the full version otherwise (vertical text
  not supported, reading wider than its base overhangs centered and is
  edge-clamped, wrapped-base reading is split proportionally rather than
  linguistically "smart"). See the full version's README for details.

## Japanese line breaking

When the text language is Japanese (`label.language = "ja"`, or on Godot
4.6+ inherited from the app locale, e.g. a Japanese OS), Godot's default
settings can start a line with small kana (っ, ゃ, ...) or ー. Godot 4.5+:
set **Project Settings > Internationalization > Locale > Line Breaking
Strictness** to **Strict**. In our test with `RubyLabelLite` on 4.7.2
(`language = "ja"`, Noto Sans JP 20 px, 46 widths) this took the count of
such line starts from 48 to 0.
Godot 4.3/4.4 have no such setting.

## Tested versions

- **Godot 4.7.2-stable** and **Godot 4.3-stable**, Windows x64, headless:
  unit tests (`tests/`, not included in the distributed zip) all passing,
  plus a packaged-zip install check (fresh project, every script in the
  addon loading with no parse errors).
- **Godot 4.4.1, 4.5.2 and 4.6.3-stable**, Windows x64, headless: unit
  tests all passing (the packaged-zip install check was run on 4.3 and
  4.7.2 only).
- No rendered-screenshot/visual check and no other Godot 4.x version,
  renderer, OS, or export template (mobile/web) has been verified for Lite.

## License

MIT (see `LICENSE`). The addon needs no font -- assign your own Japanese
font (e.g. Noto Sans JP) via `normal_font`. The demo bundles Noto Sans JP
(SIL OFL 1.1) only so it displays out of the box; see `NOTICE.md`. The full version (Ruby Text for Godot 4) is sold separately
under its own license.
