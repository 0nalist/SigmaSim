extends HBoxContainer
class_name LifestyleRow

@export var category_name: String
@export var spending_options: Array = []

@onready var label: Label = %Label
@onready var dropdown: OptionButton = %Dropdown
@onready var cost_label: Label = %CostLabel
@onready var effects_label: Label = %EffectsLabel


signal option_changed(category: String, option_index: int)

func _ready():
	var popup = %Dropdown.get_popup()
	popup.add_theme_font_size_override("font_size", 12)

	label.text = category_name
	for option in spending_options:
		dropdown.add_item(option["name"])

	dropdown.connect("item_selected", _on_option_selected)

func setup(category: String, options: Array):
	category_name = category
	spending_options = options
	label.text = category_name
	for option in spending_options:
		dropdown.add_item(option["name"])
	dropdown.select(0)
	_on_option_selected(0)


func _on_option_selected(index: int):
	var selected = spending_options[index]
	var weekly = selected.get("cost", 0)
	var daily = int(round(weekly / 7.0))

	var is_four_week_bill = category_name in ["Housing", "Medical Insurance"]
	if is_four_week_bill:
		var monthly = weekly * 4
		cost_label.text = "$%d / 4 weeks ($%d/day)" % [monthly, daily]
	else:
		cost_label.text = "$%d / week ($%d/day)" % [weekly, daily]

	effects_label.text = selected.get("effects_label", "")
	emit_signal("option_changed", category_name, index)
