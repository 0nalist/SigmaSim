extends Panel
@onready var time_label = $TimeLabel

func _ready() -> void:
	time_label.text = TimeManager.get_formatted_time()
	TimeManager.minute_passed.connect(_on_minute_passed)
	TimeManager.day_passed.connect(_on_day_passed)

func _on_minute_passed(_minute: int) -> void:
	time_label.text = TimeManager.get_formatted_time()

func _on_day_passed(_day: int, _month: int, _year: int) -> void:
	time_label.text = TimeManager.get_formatted_time()
