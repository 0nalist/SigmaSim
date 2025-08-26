extends Pane
class_name LifeStylist

@onready var category_list = %CategoryList
@onready var weekly_cost_label: Label = %WeeklyCostLabel
@onready var daily_cost_label: Label = %DailyCostLabel
@onready var daily_countdown_label: Label = %DailyCostCountdownLabel
@onready var header_label: Label = %HeaderLabel

@export var lifestyle_row_scene: PackedScene

# Exported colors to allow easy theme changes
@export var background_color: Color = Color.hex("242424")
@export var header_text_color: Color = Color.hex("ffffff")
@export var text_color: Color = Color.hex("e0e0e0")
@export var accent_color: Color = Color.hex("4caf50")

var total_weekly_cost: int = 0

func _ready():
        TimeManager.minute_passed.connect(_on_minute_passed)
        _apply_theme()

        # Create and configure each lifestyle row
        for category in BillManager.lifestyle_options.keys():
                var options = BillManager.get_lifestyle_options(category)
                var row = lifestyle_row_scene.instantiate()
                row.text_color = text_color
                category_list.add_child(row)
                row.setup(category, options)
                row.option_changed.connect(_on_row_changed)

                # Set selection from BillManager or default to 0
                var selected_index = BillManager.lifestyle_indices.get(category, 0)
                selected_index = clamp(selected_index, 0, options.size() - 1)
                row.dropdown.select(selected_index)
                row._on_option_selected(selected_index)

        _update_cost_labels()


func _on_row_changed(category: String, option_index: int):
	# Update BillManager and cost labels when any option changes
	var row = _get_row_by_category(category)
	if row == null:
		return

	var selected = row.spending_options[option_index]
	BillManager.set_lifestyle_choice(category, selected, option_index)

	_update_cost_labels()


func _update_cost_labels():
	var total_weekly_cost := 0
	for raw_row in category_list.get_children():
		var row = raw_row as LifestyleRow
		if row == null:
			continue
		var selected = row.spending_options[row.dropdown.selected]
		total_weekly_cost += selected.get("cost", 0)

	var total_daily_cost = BillManager.get_daily_lifestyle_cost()
	weekly_cost_label.text = "$%d / week" % total_weekly_cost
	daily_cost_label.text = "$%d / day" % total_daily_cost


func _on_minute_passed(current_minutes: int):
	var minutes_per_day = 24 * 60
	var target_minutes = 9 * 60  # 9:00 AM
	var current_time_of_day = current_minutes % minutes_per_day
	var minutes_remaining = (target_minutes - current_time_of_day + minutes_per_day) % minutes_per_day
	var hours = minutes_remaining / 60
	var mins = minutes_remaining % 60

        daily_countdown_label.text = "Next bill in %02d:%02d" % [hours, mins]


func _apply_theme():
        var style := StyleBoxFlat.new()
        style.bg_color = background_color
        style.corner_radius_all = 8
        add_theme_style_override("panel", style)

        header_label.add_theme_color_override("font_color", header_text_color)
        weekly_cost_label.add_theme_color_override("font_color", text_color)
        daily_cost_label.add_theme_color_override("font_color", text_color)
        daily_countdown_label.add_theme_color_override("font_color", accent_color)


func _get_row_by_category(category_name: String) -> LifestyleRow:
	for raw_row in category_list.get_children():
		var row = raw_row as LifestyleRow
		if row != null and row.category_name == category_name:
			return row
	return null
