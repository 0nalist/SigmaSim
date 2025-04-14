extends Panel
@onready var time_label = $TimeLabel

func _ready() -> void:
	time_label.text = TimeManager.get_formatted_time()
	TimeManager.minute_passed.connect(_on_minute_passed)

func _on_minute_passed(_minute: int) -> void:
	time_label.text = TimeManager.get_formatted_time()
