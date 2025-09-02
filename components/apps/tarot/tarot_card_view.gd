extends VBoxContainer
class_name TarotCardView

var card_id: String = ""
var rarity: int = 1
var count: int = 0
var sell_price: float = 0.0
var mark_sold_on_sell: bool = false
var show_single_count: bool = false

signal card_pressed(card_id: String)

@onready var texture_rect: TextureRect = %TextureRect
@onready var name_label: Label = %NameLabel
@onready var count_label: Label = %CountLabel
@onready var sell_button: Button = %SellButton

func setup(data: Dictionary, owned: int) -> void:
	if not is_node_ready():
		await ready
	
		card_id = data.get("id", "")
		name_label.text = data.get("name", "")
		rarity = int(data.get("rarity", 1))
		sell_price = TarotManager.get_sell_price(rarity)
		var tex_path: String = data.get("texture_path", "")
		var tex = load(tex_path)
		if tex:
				texture_rect.texture = tex
		update_count(owned)
		sell_button.text = "Sell for $%d" % int(sell_price)
		sell_button.pressed.connect(_on_sell_pressed)

func update_count(new_count: int) -> void:
		count = new_count
		count_label.visible = count > 0 and (count > 1 or show_single_count)
		count_label.text = "x%d" % count
		sell_button.visible = count > 0
		texture_rect.modulate = Color(1,1,1,1) if count > 0 else Color(0.5,0.5,0.5,1)
		if count > 0:
				sell_button.disabled = false
				sell_button.text = "Sell for $%d" % int(sell_price)

func _on_sell_pressed() -> void:
		TarotManager.sell_card(card_id, rarity)
		var new_count = TarotManager.get_card_rarity_count(card_id, rarity)
		update_count(new_count)
		if mark_sold_on_sell:
				sell_button.text = "SOLD"
				sell_button.disabled = true
				sell_button.visible = true

func _ready() -> void:
		texture_rect.mouse_filter = Control.MOUSE_FILTER_PASS
		name_label.mouse_filter = Control.MOUSE_FILTER_PASS
		count_label.mouse_filter = Control.MOUSE_FILTER_PASS

func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				card_pressed.emit(card_id)
