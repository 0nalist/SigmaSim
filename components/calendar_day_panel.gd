extends Panel
class_name CalendarDayPanel

@onready var day_label: Label = %DayLabel
@onready var icon_row: HBoxContainer = %IconRow

var day: int = 0
var is_past: bool = false

# Colors by bill type
var bill_colors := {
	"Rent": Color.RED,
	"Medical Insurance": Color.BLUE,
	"Student Loan": Color.GREEN,
	"Credit Card": Color.PURPLE
}

func set_day(day_number: int, is_in_past: bool, bills: Array):
	day = day_number
	is_past = is_in_past
	day_label.text = str(day)

	# Grey out or X out past days
	if is_past:
		modulate = Color(0.6, 0.6, 0.6)
		day_label.text += " X"
	else:
		modulate = Color(1, 1, 1)

	# Clear previous icons
	for child in icon_row.get_children():
		child.queue_free()

	# Add a color circle for each bill
	for bill_type in bills:
		var circle = ColorRect.new()
		circle.color = bill_colors.get(bill_type, Color.GRAY)
		circle.custom_minimum_size = Vector2(10, 10)
		icon_row.add_child(circle)


func set_empty() -> void:
	day_label.text = ""
	modulate = Color(0.45, 0.45, 0.45, 1.0) 
