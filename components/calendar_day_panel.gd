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

	if is_past:
		modulate = Color(0.6, 0.6, 0.6)
		day_label.text += " X"
	else:
		modulate = Color(1, 1, 1)

	# Clear old icons
	for child in icon_row.get_children():
		child.queue_free()

	# Add colored dots for each bill
	for bill_type in bills:
		var circle = ColorRect.new()
		circle.color = bill_colors.get(bill_type, Color.GRAY)
		circle.custom_minimum_size = Vector2(10, 10)
		icon_row.add_child(circle)

	set_tooltip(bills)


func set_tooltip(bills: Array) -> void:
	if bills.is_empty():
		set_tooltip_text("")
		return

	var tooltip_text := "Bill Due:\n"
	for bill_type in bills:
		var amount = BillManager.get_bill_amount(bill_type)
		tooltip_text += "• %s: $%.2f\n" % [bill_type, amount]

	set_tooltip_text(tooltip_text.strip_edges())


func set_empty() -> void:
	day_label.text = ""
	modulate = Color(0.45, 0.45, 0.45, 1.0) 
