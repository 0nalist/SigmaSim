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
    draw_rect(rect, Color(0.2, 0.2, 0.2))
    var ratio: float = float(current_score - min_score) / float(max_score - min_score)
    ratio = clamp(ratio, 0.0, 1.0)
    var fill_height: float = rect.size.y * ratio
    var fill_rect: Rect2 = Rect2(rect.position + Vector2(0, rect.size.y - fill_height), Vector2(rect.size.x, fill_height))
    draw_rect(fill_rect, Color(0.3, 0.8, 0.3))
    for score in range(min_score, max_score + 1, step):
        var y: float = rect.size.y * (1.0 - float(score - min_score) / float(max_score - min_score))
        draw_line(Vector2(0, y), Vector2(rect.size.x, y), Color.WHITE)

