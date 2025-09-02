extends Pane
class_name TarotApp

@onready var draw_button: Button = %DrawButton
@onready var cooldown_label: Label = %CooldownLabel
@onready var draw_result: Control = %DrawResult
@onready var draw_tab_button: Button = %DrawTabButton
@onready var collection_tab_button: Button = %CollectionTabButton
@onready var draw_view: VBoxContainer = %DrawView
@onready var collection_view: ScrollContainer = %CollectionView
@onready var collection_grid: GridContainer = %CollectionGrid

var card_views: Dictionary = {}
var _active_tab: StringName = &"Draw"

func _ready() -> void:
	draw_button.pressed.connect(_on_draw_button_pressed)
	draw_tab_button.pressed.connect(_on_draw_tab_pressed)
	collection_tab_button.pressed.connect(_on_collection_tab_pressed)
	TarotManager.collection_changed.connect(_on_collection_changed)
	TimeManager.minute_passed.connect(_on_minute_passed)
	_build_collection_view()
	_update_cooldown_label()
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
		card_views[id] = view

func _on_collection_changed(card_id: String, count: int) -> void:
	var view = card_views.get(card_id)
	if view:
		view.update_count(count)

func _on_draw_button_pressed() -> void:
	var card = TarotManager.draw_card()
	if card.is_empty():
		return
	for child in draw_result.get_children():
		child.queue_free()
	var id = card.get("id", "")
	var view = TarotManager.instantiate_card_view(id, TarotManager.get_card_count(id))
	draw_result.add_child(view)
	_update_cooldown_label()

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

func _on_minute_passed(_total_minutes: int) -> void:
	_update_cooldown_label()

func _activate_tab(tab_name: StringName) -> void:
	if tab_name == &"Draw":
		draw_tab_button.set_pressed(true)
		collection_tab_button.set_pressed(false)
		draw_view.visible = true
		collection_view.visible = false
	else:
		draw_tab_button.set_pressed(false)
		collection_tab_button.set_pressed(true)
		draw_view.visible = false
		collection_view.visible = true
	_active_tab = tab_name

func _on_draw_tab_pressed() -> void:
	_activate_tab(&"Draw")

func _on_collection_tab_pressed() -> void:
	_activate_tab(&"Collection")
