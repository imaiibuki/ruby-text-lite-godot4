## Demo: typewriter reveal using RubyLabelLite with [ruby=...] BBCode.
## Click / press any key to advance to the next sample.
extends Control

const FONT_PATH := "res://demo/font/NotoSansJP-Regular.ttf"

var samples: Array = [
	{
		"title": "基本: [ruby=よみ]漢字[/ruby] BBCode",
		"text": "[ruby=とうきょう]東京[/ruby]は[ruby=にほん]日本[/ruby]の[ruby=しゅと]首都[/ruby]です。",
	},
	{
		"title": "長い読み (reading longer than the base)",
		"text": "[ruby=なぞめいたふしぎなことば]謎[/ruby]の意味がようやく分かった。",
	},
	{
		"title": "BBCode 色 + wave との併用",
		"text": "[wave amp=24 freq=4][color=gold][ruby=まほう]魔法[/ruby][/color][/wave]の力で[ruby=とびら]扉[/ruby]が開く。",
	},
	{
		"title": "ピンイン (Chinese pinyin via [ruby=])",
		"text": "[ruby=nǐ hǎo]你好[/ruby]，[ruby=shì jiè]世界[/ruby]！",
	},
]

var label: RubyLabelLite
var title_label: Label
var current_index := -1
var reveal_timer := 0.0
const REVEAL_SECONDS := 2.2


func _ready() -> void:
	var font: Font = load(FONT_PATH)
	# The bundled Noto Sans JP is a variable font whose default instance is
	# Thin (wght 100); pin it to Regular. The key must be the integer tag.
	var font_variation := FontVariation.new()
	font_variation.base_font = font
	font_variation.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): 400}
	font = font_variation

	# Real padding around the whole demo (a Container's "margin_*" theme
	# constants only apply on a MarginContainer -- a VBoxContainer ignores
	# them, which is why text used to sit flush against the window edge).
	var outer_margin := MarginContainer.new()
	outer_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	outer_margin.add_theme_constant_override("margin_left", 28)
	outer_margin.add_theme_constant_override("margin_top", 24)
	outer_margin.add_theme_constant_override("margin_right", 28)
	outer_margin.add_theme_constant_override("margin_bottom", 24)
	add_child(outer_margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	outer_margin.add_child(vbox)

	title_label = Label.new()
	title_label.add_theme_font_override("font", font)
	title_label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(title_label)

	var panel := PanelContainer.new()
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.1, 0.13)
	panel_style.content_margin_left = 20
	panel_style.content_margin_top = 18
	panel_style.content_margin_right = 20
	panel_style.content_margin_bottom = 18
	panel.add_theme_stylebox_override("panel", panel_style)
	panel.custom_minimum_size = Vector2(560, 200)
	vbox.add_child(panel)

	label = RubyLabelLite.new()
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	label.bbcode_enabled = true
	label.add_theme_font_override("normal_font", font)
	label.add_theme_font_size_override("normal_font_size", 30)
	label.add_theme_color_override("default_color", Color.WHITE)
	label.ruby_color = Color(1, 1, 1)
	label.scroll_active = false
	panel.add_child(label)

	var hint := Label.new()
	hint.add_theme_font_override("font", font)
	hint.add_theme_font_size_override("font_size", 14)
	hint.text = "クリックまたは何かキーを押すと次の例へ / click or press a key for the next sample"
	vbox.add_child(hint)

	_show_sample(0)


func _show_sample(i: int) -> void:
	current_index = i
	var sample: Dictionary = samples[i]
	title_label.text = "%d/%d  %s" % [i + 1, samples.size(), sample["title"]]
	label.ruby_text = sample["text"]
	label.visible_ratio = 0.0
	reveal_timer = 0.0


func _process(delta: float) -> void:
	if current_index < 0:
		return
	if label.visible_ratio < 1.0:
		reveal_timer += delta
		label.visible_ratio = clamp(reveal_timer / REVEAL_SECONDS, 0.0, 1.0)


func _unhandled_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton and event.pressed) or (event is InputEventKey and event.pressed):
		if label.visible_ratio < 1.0:
			label.visible_ratio = 1.0
		else:
			_show_sample((current_index + 1) % samples.size())
