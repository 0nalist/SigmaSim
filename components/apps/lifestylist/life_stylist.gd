extends Pane
class_name LifeStylist

@onready var category_list: VBoxContainer = %CategoryList
@onready var weekly_cost_label: Label = %WeeklyCostLabel
@onready var daily_cost_label: Label = %DailyCostLabel
@onready var daily_countdown_label: Label = %DailyCostCountdownLabel
@onready var header_label: Label = %HeaderLabel

@export var lifestyle_row_scene: PackedScene

# Exported colors to allow easy theme changes
@export var background_color: Color = Color.hex(0x242424ff) # ARGB/RGBA int is OK in G4
@export var header_text_color: Color = Color.hex(0xffffffff)
@export var text_color: Color = Color.hex(0xe0e0e0ff)
@export var accent_color: Color = Color.hex(0x000000ff)

var total_weekly_cost: int = 0

func _ready() -> void:
	TimeManager.minute_passed.connect(_on_minute_passed)
	_apply_theme()

	# Create and configure each lifestyle row
	for category in BillManager.lifestyle_options.keys():
		var options: Array = BillManager.get_lifestyle_options(category)
		var row: LifestyleRow = lifestyle_row_scene.instantiate()
		row.text_color = text_color
		category_list.add_child(row)
		row.setup(category, options)
		row.option_changed.connect(_on_row_changed)

		# Set selection from BillManager or default to 0
		var selected_index: int = BillManager.lifestyle_indices.get(category, 0)
		selected_index = clamp(selected_index, 0, options.size() - 1)
		row.dropdown.select(selected_index)
		row._on_option_selected(selected_index)

	_update_cost_labels()


func _on_row_changed(category: String, option_index: int) -> void:
	# Update BillManager and cost labels when any option changes
	var row: LifestyleRow = _get_row_by_category(category)
	if row == null:
		return

	var selected: Dictionary = row.spending_options[option_index]
	BillManager.set_lifestyle_choice(category, selected, option_index)
	_update_cost_labels()


func _update_cost_labels() -> void:
	var total_weekly: int = 0
	for raw_row in category_list.get_children():
		var row: LifestyleRow = raw_row as LifestyleRow
		if row == null:
			continue
		var selected: Dictionary = row.spending_options[row.dropdown.selected]
		total_weekly += int(selected.get("cost", 0))

	var total_daily_cost: int = BillManager.get_daily_lifestyle_cost()
	total_weekly_cost = total_weekly

	weekly_cost_label.text = "$%d / week" % total_weekly_cost
	daily_cost_label.text = "$%d / day" % total_daily_cost


func _on_minute_passed(current_minutes: int) -> void:
	var minutes_per_day: int = 24 * 60
	var target_minutes: int = 9 * 60  # 9:00 AM
	var current_time_of_day: int = current_minutes % minutes_per_day
	var minutes_remaining: int = (target_minutes - current_time_of_day + minutes_per_day) % minutes_per_day
	var hours: int = minutes_remaining / 60
	var mins: int = minutes_remaining % 60

	daily_countdown_label.text = "Next bill in %02d:%02d" % [hours, mins]


func _apply_theme() -> void:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	
	#await ready
	
	style.bg_color = background_color
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8

	# Godot 4: use add_theme_stylebox_override
	add_theme_stylebox_override("panel", style)

	header_label.add_theme_color_override("font_color", header_text_color)
	weekly_cost_label.add_theme_color_override("font_color", text_color)
	daily_cost_label.add_theme_color_override("font_color", text_color)
	daily_countdown_label.add_theme_color_override("font_color", accent_color)



func _get_row_by_category(category_name: String) -> LifestyleRow:
	for raw_row in category_list.get_children():
		var row: LifestyleRow = raw_row as LifestyleRow
		if row != null and row.category_name == category_name:
			return row
	return null
