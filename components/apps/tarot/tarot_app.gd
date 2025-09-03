extends Pane
class_name TarotApp

@onready var draw_button: Button = %DrawButton
@onready var cooldown_label: Label = %CooldownLabel
@onready var draw_result: Control = %DrawResult
@onready var draw_tab_button: Button = %DrawTabButton
@onready var reading_tab_button: Button = %ReadingsTabButton
@onready var collection_tab_button: Button = %CollectionTabButton
@onready var draw_view: VBoxContainer = %DrawView
@onready var readings_view: VBoxContainer = %ReadingsView
@onready var reading_result: Control = %ReadingResult
@onready var reading_button: Button = %ReadingButton
@onready var reading_cost_label: Label = %ReadingCostLabel
@onready var collection_view: ScrollContainer = %CollectionView
@onready var collection_grid: GridContainer = %CollectionGrid
@onready var card_collection_examiner: CardCollectionExaminer = %CardCollectionExaminer

var card_views: Dictionary = {}
var _active_tab: StringName = &"Draw"

func _ready() -> void:
	draw_button.pressed.connect(_on_draw_button_pressed)
	reading_button.pressed.connect(_on_reading_button_pressed)
	draw_tab_button.pressed.connect(_on_draw_tab_pressed)
	reading_tab_button.pressed.connect(_on_readings_tab_pressed)
	collection_tab_button.pressed.connect(_on_collection_tab_pressed)
	TarotManager.collection_changed.connect(_on_collection_changed)
	TimeManager.minute_passed.connect(_on_minute_passed)
	UpgradeManager.upgrade_purchased.connect(_on_upgrade_purchased)
	_build_collection_view()
	_update_cooldown_label()
	_update_reading_cost_label()
	_show_last_drawn_card()
	_activate_tab(&"Draw")


func _build_collection_view() -> void:
	for child in collection_grid.get_children():
		child.queue_free()
	card_views.clear()
	for card in TarotManager.get_all_cards_ordered():
		var id: String = card.get("id", "")
		var count: int = TarotManager.get_card_count(id)
		var view: TarotCardView = TarotManager.instantiate_card_view(id, count)
		collection_grid.add_child(view)
		view.set_rarity_label_visible(false)
		view.texture_rect.custom_minimum_size = Vector2(32, 56)
		view.card_pressed.connect(card_collection_examiner.show_card)

		card_views[id] = view

func _on_collection_changed(card_id: String, count: int) -> void:
	var view = card_views.get(card_id)
	if view:
		view.update_count(count)

func _on_draw_button_pressed() -> void:
	var card = TarotManager.draw_card()
	if card.is_empty():
		print("tarot card is empty")
		return
	_show_last_drawn_card()
	_update_cooldown_label()

func _on_reading_button_pressed() -> void:
	var count := 1 + UpgradeManager.get_level("tarot_extra_card")
	var cards = TarotManager.draw_reading(count)
	if cards.is_empty():
			return
	_show_reading_cards(cards)

func _show_last_drawn_card() -> void:
	for child in draw_result.get_children():
		child.queue_free()
	var id = TarotManager.last_card_id
	var rarity = TarotManager.last_card_rarity
	if id == "" or rarity <= 0:
		return
	var count_for_rarity = TarotManager.get_card_rarity_count(id, rarity)
	var view = TarotManager.instantiate_card_view(id, count_for_rarity, true, rarity)
	view.show_single_count = true
	draw_result.add_child(view)

func _show_reading_cards(cards: Array) -> void:
	for child in reading_result.get_children():
		if child != reading_button and child != reading_cost_label and child != reading_button:
			child.queue_free()
	for c in cards:
		var id: String = c.get("id", "")
		var rarity: int = int(c.get("rarity", 1))
		var count_for_rarity = TarotManager.get_card_rarity_count(id, rarity)
		var view = TarotManager.instantiate_card_view(id, count_for_rarity, true, rarity)
		view.show_single_count = true
		reading_result.add_child(view)


func _update_cooldown_label() -> void:
	var remaining = TarotManager.time_until_next_draw()
	if remaining <= 0:
		cooldown_label.text = "Ready to draw"
		draw_button.disabled = false
	else:
		var hours = remaining / 60
		var minutes = remaining % 60
		cooldown_label.text = "%02dh %02dm" % [hours, minutes]
		draw_button.disabled = true

func _update_reading_cost_label() -> void:
	var extra := UpgradeManager.get_level("tarot_extra_card")
	var count := 1 + extra
	var cost = TarotManager.reading_cost * count
	reading_cost_label.text = "$" + str(cost) + " for %d card(s)" % count

func _on_minute_passed(_total_minutes: int) -> void:
	_update_cooldown_label()

func _activate_tab(tab_name: StringName) -> void:
	if tab_name == &"Draw":
			draw_tab_button.set_pressed(true)
			reading_tab_button.set_pressed(false)
			collection_tab_button.set_pressed(false)
			draw_view.visible = true
			readings_view.visible = false
			collection_view.visible = false
	elif tab_name == &"Readings":
			draw_tab_button.set_pressed(false)
			reading_tab_button.set_pressed(true)
			collection_tab_button.set_pressed(false)
			draw_view.visible = false
			readings_view.visible = true
			collection_view.visible = false
	else:
			draw_tab_button.set_pressed(false)
			reading_tab_button.set_pressed(false)
			collection_tab_button.set_pressed(true)
			draw_view.visible = false
			readings_view.visible = false
			collection_view.visible = true
	_active_tab = tab_name

func _on_draw_tab_pressed() -> void:
	_activate_tab(&"Draw")

func _on_readings_tab_pressed() -> void:
	_activate_tab(&"Readings")

func _on_collection_tab_pressed() -> void:
	_activate_tab(&"Collection")

func _on_upgrade_purchased(id: String, _new_level: int) -> void:
	if id == "tarot_extra_card":
		_update_reading_cost_label()
