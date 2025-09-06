extends Pane
class_name TarotApp

@onready var draw_button: Button = %DrawButton
@onready var cooldown_label: Label = %CooldownLabel
@onready var draw_result: Control = %DrawResult
@onready var nav_bar: PaneNavBar = %PaneNavBar
@onready var draw_view: VBoxContainer = %DrawView
@onready var readings_view: VBoxContainer = %ReadingsView
@onready var reading_result: Control = %ReadingResult
@onready var reading_button: Button = %ReadingButton
@onready var reading_cost_label: Label = %ReadingCostLabel
@onready var collection_view: ScrollContainer = %CollectionView
@onready var collection_grid: GridContainer = %CollectionGrid
@onready var card_collection_examiner: CardCollectionExaminer = %CardCollectionExaminer

var card_views: Dictionary = {}
var _active_tab: String = "Draw"

func _ready() -> void:
	draw_button.pressed.connect(_on_draw_button_pressed)
	reading_button.pressed.connect(_on_reading_button_pressed)
	nav_bar.add_nav_button("Draw", "Draw")
	nav_bar.add_nav_button("Readings", "Readings")
	nav_bar.add_nav_button("Collection", "Collection")
	nav_bar.tab_selected.connect(func(tab_id: String): _activate_tab(tab_id))
	TarotManager.collection_changed.connect(_on_collection_changed)
	TimeManager.minute_passed.connect(_on_minute_passed)
	TimeManager.hour_passed.connect(_on_hour_passed)
	UpgradeManager.upgrade_purchased.connect(_on_upgrade_purchased)
	_build_collection_view()
	_update_cooldown_label()
	_update_reading_cost_label()
	_show_last_drawn_card()
	_show_reading_cards(TarotManager.last_reading)
	nav_bar.set_active("Draw")


func _build_collection_view() -> void:
	for child in collection_grid.get_children():
		child.queue_free()
	card_views.clear()
	for card in TarotManager.get_all_cards_ordered():
		var id: String = card.get("id", "")
		var count: int = TarotManager.get_card_count(id)
		var rarity = TarotManager.get_highest_owned_rarity(id)
		var view: TarotCardView = TarotManager.instantiate_card_view(id, count, false, rarity)
		collection_grid.add_child(view)
		view.set_rarity_label_visible(false)
		view.texture_rect.custom_minimum_size = Vector2(32, 56)
		view.card_pressed.connect(card_collection_examiner.show_card)

		card_views[id] = view

		await get_tree().process_frame


func _on_collection_changed(card_id: String, count: int) -> void:
	var view = card_views.get(card_id)
	if view:
		var rarity = TarotManager.get_highest_owned_rarity(card_id)
		view.update_rarity(rarity)
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
	_update_reading_cost_label()

func _show_last_drawn_card() -> void:
	for child in draw_result.get_children():
		child.queue_free()
	var id = TarotManager.last_card_id
	var rarity = TarotManager.last_card_rarity
	if id == "" or rarity <= 0:
		return
	var count_for_rarity = TarotManager.get_card_rarity_count(id, rarity)
	var view = TarotManager.instantiate_card_view(id, count_for_rarity, true, rarity)
	var upside_down = RNGManager.tarot_orientation.get_rng().randf() < 0.5
	view.set_upside_down(upside_down)
	view.show_single_count = true
	view.modulate.a = 0.0
	draw_result.add_child(view)
	var t = create_tween()
	t.tween_property(view, "modulate:a", 1.0, 0.3)
	if upside_down:
			t.tween_property(view.texture_rect, "rotation_degrees", 180, 0.3)

func _show_reading_cards(cards: Array) -> void:
	for child in reading_result.get_children():
		if child != reading_button and child != reading_cost_label and child != reading_button:
			child.queue_free()
	var index := 0
	var flip_rng = RNGManager.tarot_orientation.get_rng()
	for c in cards:
		var id: String = c.get("id", "")
		var rarity: int = int(c.get("rarity", 1))
		var count_for_rarity = TarotManager.get_card_rarity_count(id, rarity)
		var view = TarotManager.instantiate_card_view(id, count_for_rarity, true, rarity)
		var upside_down = flip_rng.randf() < 0.5
		view.set_upside_down(upside_down)
		view.show_single_count = true
		view.modulate.a = 0.0
		reading_result.add_child(view)
		var t = create_tween()
		t.tween_property(view, "modulate:a", 1.0, 0.3).set_delay(index * 0.2)
		if upside_down:
			t.tween_property(view.texture_rect, "rotation_degrees", 180, 0.3)
		index += 1


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
	reading_cost_label.text = "%d EX for %d card(s)" % [int(cost), count]

func _on_minute_passed(_total_minutes: int) -> void:
	_update_cooldown_label()

func _on_hour_passed(_current_hour: int, _total_minutes: int) -> void:
	_update_reading_cost_label()

func _activate_tab(tab_name: String) -> void:
	if tab_name == "Draw":
		draw_view.visible = true
		readings_view.visible = false
		collection_view.visible = false
	elif tab_name == "Readings":
		draw_view.visible = false
		readings_view.visible = true
		collection_view.visible = false
	else:
		draw_view.visible = false
		readings_view.visible = false
		collection_view.visible = true
	_active_tab = tab_name

func _on_upgrade_purchased(id: String, _new_level: int) -> void:
	if id == "tarot_extra_card":
		_update_reading_cost_label()
