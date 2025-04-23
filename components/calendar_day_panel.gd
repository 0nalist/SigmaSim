extends PanelContainer
class_name CalendarDayPanel

@onready var day_label: Label = %DayLabel
@onready var icon_row: HBoxContainer = %IconRow
@onready var today_indicator: ColorRect = %TodayIndicator

var day: int = 0
var is_past: bool = false
var active_bills: Array[String] = []

# Bills that should trigger tooltip refresh when updated
const TOOLTIP_SENSITIVE_BILLS: Array[String] = ["Credit Card", "Student Loan"]
const TRACKED_RESOURCES: Array[String] = ["student_loans", "debt", "cash", "credit", "student_loan_min_payment"]

var bill_colors := {
	"Rent": Color.RED,
	"Medical Insurance": Color.BLUE,
	"Student Loan": Color.GREEN,
	"Credit Card": Color.PURPLE
}

func _ready() -> void:
	PortfolioManager.resource_changed.connect(_on_resource_changed)

func set_day(day_number: int, is_in_past: bool, bills: Array) -> void:
	day = day_number
	is_past = is_in_past
	active_bills = bills.duplicate()
	_update_day_label()
	_update_icons()
	_update_tooltip()

func _update_day_label() -> void:
	day_label.text = str(day)
	if is_past:
		modulate = Color(0.6, 0.6, 0.6)
		day_label.text += " X"
	else:
		modulate = Color(1, 1, 1)

func _update_icons() -> void:
	for child in icon_row.get_children():
		child.queue_free()

	for bill_type in active_bills:
		var circle := ColorRect.new()
		circle.color = bill_colors.get(bill_type, Color.GRAY)
		circle.custom_minimum_size = Vector2(10, 10)
		icon_row.add_child(circle)

func _update_tooltip() -> void:
	if active_bills.is_empty():
		set_tooltip_text("")
		return

	var tooltip_text := "Bill Due:\n"
	for bill_type in active_bills:
		var amount: float = BillManager.get_bill_amount(bill_type)
		tooltip_text += "• %s: $%.2f\n" % [bill_type, amount]

	set_tooltip_text(tooltip_text.strip_edges())

func _on_resource_changed(name: String, _value: float) -> void:
	if name in TRACKED_RESOURCES:
		for bill in active_bills:
			if bill in TOOLTIP_SENSITIVE_BILLS:
				_update_tooltip()
				break

func set_today_indicator(show_indicator: bool) -> void:
	today_indicator.visible = show_indicator

func set_empty() -> void:
	day_label.text = ""
	modulate = Color(0.45, 0.45, 0.45, 1.0)
