extends CenterContainer
class_name CardCollectionExaminer

const CARD_VIEW_SCENE = preload("res://components/apps/tarot/tarot_card_view.tscn")

@onready var card_holder: HBoxContainer = %CardHolder
@onready var close_button: Button = %CloseButton

var current_card_id: String = ""

func _ready() -> void:
	visible = false
	close_button.pressed.connect(hide)
	TarotManager.collection_changed.connect(_on_collection_changed)

func show_card(card_id: String) -> void:
	current_card_id = card_id
	for child in card_holder.get_children():
		child.queue_free()
	var base = TarotManager.deck.get_card(card_id)
	if base.is_empty():
		return
	for rarity in [1,2,3,4,5]:
		var data = base.duplicate()
		data["rarity"] = rarity
		var count = TarotManager.get_card_rarity_count(card_id, rarity)
		var view: TarotCardView = CARD_VIEW_SCENE.instantiate()
		view.show_single_count = true
		view.hide_divine_film_if_unowned = true
		view.setup(data, count)
		card_holder.add_child(view)
	show()

func _on_collection_changed(card_id: String, _count: int) -> void:
	if not visible or card_id != current_card_id:
		return
	for view in card_holder.get_children():
		var rarity = view.rarity
		view.update_count(TarotManager.get_card_rarity_count(card_id, rarity))
