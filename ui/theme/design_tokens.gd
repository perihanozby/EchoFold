class_name DesignTokens
extends RefCounted
const BG = Color("0b1322")
const SURFACE = Color("19293b")
const TEXT = Color("f2f6fa")
const SECONDARY = Color("b8c9d6")
const ACCENT = Color("72d6d0")
const WARM = Color("f0b98d")

static func box(color: Color, border: Color = Color("284356"), radius: int = 14) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 13
	style.content_margin_bottom = 13
	return style

static func theme() -> Theme:
	var t = Theme.new()
	var font = load("res://assets/fonts/NotoSans-Regular.ttf") as FontFile
	font.fallbacks = [load("res://assets/fonts/NotoSansArabic-Regular.ttf"), load("res://assets/fonts/NotoSansDevanagari-Regular.ttf"), load("res://assets/fonts/NotoSansThai-Regular.ttf"), load("res://assets/fonts/NotoSansCJKsc-Regular.otf")]
	t.default_font = font
	t.default_font_size = 16
	t.set_color("font_color", "Label", TEXT)
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", ACCENT)
	t.set_color("font_disabled_color", "Button", Color("526c7d"))
	t.set_stylebox("normal", "Button", box(SURFACE))
	t.set_stylebox("hover", "Button", box(Color("24364b"), ACCENT))
	t.set_stylebox("pressed", "Button", box(Color("284356"), ACCENT))
	t.set_stylebox("focus", "Button", box(Color(0, 0, 0, 0), Color("c6e7f2")))
	t.set_stylebox("disabled", "Button", box(Color("111e30")))
	t.set_constant("separation", "VBoxContainer", 12)
	t.set_constant("separation", "HBoxContainer", 10)
	t.set_stylebox("panel", "PanelContainer", box(SURFACE))
	return t
