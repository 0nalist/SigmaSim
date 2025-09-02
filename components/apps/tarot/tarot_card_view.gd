extends VBoxContainer
class_name TarotCardView

var card_id: String = ""
var rarity: int = 1
var count: int = 0

@onready var texture_rect: TextureRect = %TextureRect
@onready var name_label: Label = %NameLabel
@onready var count_label: Label = %CountLabel
@onready var sell_button: Button = %SellButton

func setup(data: Dictionary, owned: int) -> void:
    card_id = data.get("id", "")
    name_label.text = data.get("name", "")
    rarity = int(data.get("rarity", 1))
    var tex_path: String = data.get("texture_path", "")
    var tex = load(tex_path)
    if tex:
        texture_rect.texture = tex
    update_count(owned)
    sell_button.pressed.connect(_on_sell_pressed)

func update_count(new_count: int) -> void:
    count = new_count
    count_label.visible = count > 1
    count_label.text = "x%d" % count
    sell_button.visible = count > 0
    texture_rect.modulate = Color(1,1,1,1) if count > 0 else Color(0.5,0.5,0.5,1)

func _on_sell_pressed() -> void:
    TarotManager.sell_card(card_id)
