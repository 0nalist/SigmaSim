extends VBoxContainer
class_name TarotCardView

var card_id: String = ""
var rarity: int = 1
var count: int = 0
var sell_price: float = 0.0
var mark_sold_on_sell: bool = false

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
        sell_price = float(rarity)
        var tex_path: String = data.get("texture_path", "")
        var tex = load(tex_path)
        if tex:
                texture_rect.texture = tex
        update_count(owned)
        sell_button.text = "Sell for $%d" % int(sell_price)
        sell_button.pressed.connect(_on_sell_pressed)

func update_count(new_count: int) -> void:
	count = new_count
	count_label.visible = count > 1
	count_label.text = "x%d" % count
        sell_button.visible = count > 0
        texture_rect.modulate = Color(1,1,1,1) if count > 0 else Color(0.5,0.5,0.5,1)
        if count > 0:
                sell_button.disabled = false
                sell_button.text = "Sell for $%d" % int(sell_price)

func _on_sell_pressed() -> void:
        TarotManager.sell_card(card_id)
        var new_count := TarotManager.get_card_count(card_id)
        update_count(new_count)
        if mark_sold_on_sell:
                sell_button.text = "SOLD"
                sell_button.disabled = true
                sell_button.visible = true
