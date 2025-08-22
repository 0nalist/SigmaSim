extends Control

@export var min_score: int = 300
@export var max_score: int = 850
@export var step: int = 50

var current_score: int = min_score

func _ready() -> void:
	PortfolioManager.credit_updated.connect(_on_credit_changed)
	_on_credit_changed(0.0, 0.0)

func _on_credit_changed(_used: float, _limit: float) -> void:
	current_score = PortfolioManager.get_credit_score()
	queue_redraw()
func _draw() -> void:
	var rect: Rect2 = Rect2(Vector2.ZERO, size)

	# background with rounded edges
	var bg_box := StyleBoxFlat.new()
	bg_box.bg_color = Color(0.2, 0.2, 0.2)
	bg_box.corner_radius_top_left = 8
	bg_box.corner_radius_top_right = 8
	bg_box.corner_radius_bottom_left = 8
	bg_box.corner_radius_bottom_right = 8
	draw_style_box(bg_box, rect)

	var ratio: float = float(current_score - min_score) / float(max_score - min_score)
	ratio = clamp(ratio, 0.0, 1.0)

	var fill_height: float = rect.size.y * ratio
	var fill_rect: Rect2 = Rect2(rect.position + Vector2(0, rect.size.y - fill_height), Vector2(rect.size.x, fill_height))

	# build vertical gradient from red → yellow → green
	var grad := Gradient.new()
	grad.colors = [Color.RED, Color.YELLOW, Color.GREEN]
	grad.offsets = [0.0, 0.5, 1.0]

	var grad_tex := GradientTexture2D.new()
	grad_tex.gradient = grad
	grad_tex.width = 1
	grad_tex.height = int(fill_height)
	grad_tex.fill_from = Vector2(0, 1)  # bottom to top
	grad_tex.fill_to = Vector2(0, 0)

	# draw gradient into the filled portion
	draw_texture_rect(grad_tex, fill_rect, true)

	# font
	var font: Font = ThemeDB.fallback_font
	var font_size: int = 12

	# Draw each score section
	for score in range(min_score, max_score + 1, step):
		var t: float = float(score - min_score) / float(max_score - min_score)
		var y: float = rect.size.y * (1.0 - t)

		# section color (gradient red->yellow->green)
		var section_color: Color
		if t < 0.5:
			section_color = Color.RED.lerp(Color.YELLOW, t / 0.5)
		else:
			section_color = Color.YELLOW.lerp(Color.GREEN, (t - 0.5) / 0.5)

		# draw horizontal line in black
		draw_line(Vector2(0, y), Vector2(rect.size.x, y), Color.BLACK)

		# left label = credit score
		var score_text: String = str(score)
		var score_size: Vector2 = font.get_string_size(score_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		draw_string(font, Vector2(-score_size.x - 6.0, y + score_size.y / 2.0),
			score_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, section_color)

		# right label = unlocks (if any)
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
