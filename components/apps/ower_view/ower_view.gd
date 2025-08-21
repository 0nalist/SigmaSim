extends Pane

@onready var card_container: HBoxContainer = %CardContainer
@onready var prev_button: Button = %PrevButton
@onready var next_button: Button = %NextButton

var cards: Array[DebtCardUI] = []
var current_index: int = 0

func _ready() -> void:
	var resources: Dictionary = BillManager.get_debt_resources()
	for name in resources.keys():
		var card: DebtCardUI = preload("res://components/apps/ower_view/debt_card_ui.tscn").instantiate()
		card.setup(name, resources[name])
		card_container.add_child(card)
		cards.append(card)
	_update_visible_card()
	prev_button.pressed.connect(_on_prev_pressed)
	next_button.pressed.connect(_on_next_pressed)

func _update_visible_card() -> void:
	for i in range(cards.size()):
		cards[i].visible = (i == current_index)

func _on_prev_pressed() -> void:
	if cards.is_empty():
		return
	current_index = (current_index - 1 + cards.size()) % cards.size()
	_update_visible_card()

func _on_next_pressed() -> void:
	if cards.is_empty():
		return
	current_index = (current_index + 1) % cards.size()
	_update_visible_card()

