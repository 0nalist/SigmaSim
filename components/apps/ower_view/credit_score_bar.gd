extends Control

@export var min_score: int = 300
@export var max_score: int = 850
@export var step: int = 50

var current_score: int = min_score
var gradient_tex: ImageTexture = null

func _ready() -> void:
	PortfolioManager.credit_updated.connect(_on_credit_changed)
	_on_credit_changed(0.0, 0.0)
	_generate_gradient_texture()

func _on_credit_changed(_used: float, _limit: float) -> void:
	current_score = PortfolioManager.get_credit_score()
	queue_redraw()

func _generate_gradient_texture() -> void:
	var h: int = int(size.y)
	if h <= 0:
		return

	# Create a vertical gradient 1px wide and full bar height
	var img := Image.create(1, h, false, Image.FORMAT_RGBA8)

	for y in range(h):
		var t: float = 1.0 - (float(y) / float(h))  # bottom=0, top=1
		var col: Color
		if t < 0.5:
			col = Color.RED.lerp(Color.YELLOW, t / 0.5)
		else:
			col = Color.YELLOW.lerp(Color.GREEN, (t - 0.5) / 0.5)
		img.set_pixel(0, y, col)

	# Convert to texture
	gradient_tex = ImageTexture.create_from_image(img)
func _draw() -> void:
	var rect: Rect2 = Rect2(Vector2.ZERO, size)

	# --- Background with rounded corners
	var bg_box := StyleBoxFlat.new()
	bg_box.bg_color = Color(0.2, 0.2, 0.2)
	bg_box.corner_radius_top_left = 8
	bg_box.corner_radius_top_right = 8
	bg_box.corner_radius_bottom_left = 8
	bg_box.corner_radius_bottom_right = 8
	draw_style_box(bg_box, rect)

	# --- Filled Gradient (no corner radius here)
	if gradient_tex != null:
		var ratio: float = float(current_score - min_score) / float(max_score - min_score)
		ratio = clamp(ratio, 0.0, 1.0)

		var fill_height: float = rect.size.y * ratio
		if fill_height > 0.0:
			var fill_rect := Rect2(rect.position + Vector2(0, rect.size.y - fill_height), Vector2(rect.size.x, fill_height))
			draw_texture_rect(gradient_tex, fill_rect, true)

	# --- Labels and Lines ---
	var font: Font = ThemeDB.fallback_font
	var font_size: int = 12

	for score in range(min_score, max_score + 1, step):
		var t: float = float(score - min_score) / float(max_score - min_score)
		var y: float = rect.size.y * (1.0 - t)

		# section color
		var section_color: Color
		if t < 0.5:
			section_color = Color.RED.lerp(Color.YELLOW, t / 0.5)
		else:
			section_color = Color.YELLOW.lerp(Color.GREEN, (t - 0.5) / 0.5)

		draw_line(Vector2(0, y), Vector2(rect.size.x, y), Color.BLACK)

		var score_text: String = str(score)
		var score_size: Vector2 = font.get_string_size(score_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		draw_string(font, Vector2(-score_size.x - 6.0, y + score_size.y / 2.0),
			score_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, section_color)

		var unlocks: String = _get_label_for_score(score)
		if unlocks != "":
			var unlock_size: Vector2 = font.get_string_size(unlocks, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
			draw_string(font, Vector2(rect.size.x + 4.0, y + unlock_size.y / 2.0),
				unlocks, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)

func _get_label_for_score(score: int) -> String:
	var unlocked_here: Array[String] = []
	for purchase in PortfolioManager.CREDIT_REQUIREMENTS.keys():
		if PortfolioManager.CREDIT_REQUIREMENTS[purchase] == score:
			unlocked_here.append(String(purchase))
	unlocked_here.sort()
	return ", ".join(unlocked_here)

func _notification(what: int) -> void:
	# Regenerate gradient when control is resized
	if what == NOTIFICATION_RESIZED:
		_generate_gradient_texture()
