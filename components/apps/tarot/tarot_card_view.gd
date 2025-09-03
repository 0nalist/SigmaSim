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
@onready var rarity_label: Label = %RarityLabel
@onready var count_label: Label = %CountLabel
@onready var sell_button: Button = %SellButton

const RARITY_NAMES := {
		1: "Paper",
		2: "Bronze",
		3: "Silver",
		4: "Gold",
		5: "Divine"
}

const RARITY_COLORS := {
		1: Color("6e6e6e"), # dull grey
		2: Color("cd7f32"), # bronze brown
		3: Color("e0e0e0"), # silvery white
		4: Color("ffd700")  # golden yellow
}

const RAINBOW_MATERIAL := preload("res://components/apps/fumble/fumble_label_pride_month_material.tres")

func setup(data: Dictionary, owned: int) -> void:
		if not is_node_ready():
				await ready

				card_id = data.get("id", "")
				name_label.text = data.get("name", "")
				rarity = int(data.get("rarity", 1))
				rarity_label.text = RARITY_NAMES.get(rarity, "")
				if rarity == 5:
						rarity_label.material = RAINBOW_MATERIAL
						rarity_label.add_theme_color_override("font_color", Color.WHITE)
				else:
						rarity_label.material = null
						rarity_label.add_theme_color_override("font_color", RARITY_COLORS.get(rarity, Color.WHITE))
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

func update_rarity(new_rarity: int) -> void:
		rarity = new_rarity
		rarity_label.text = RARITY_NAMES.get(rarity, "")
		if rarity == 5:
						rarity_label.material = RAINBOW_MATERIAL
						rarity_label.add_theme_color_override("font_color", Color.WHITE)
		else:
						rarity_label.material = null
						rarity_label.add_theme_color_override("font_color", RARITY_COLORS.get(rarity, Color.WHITE))
		sell_price = TarotManager.get_sell_price(rarity)
		sell_button.text = "Sell for $%d" % int(sell_price)

func set_rarity_label_visible(is_visible: bool) -> void:
				if not is_node_ready():
								await ready
				rarity_label.visible = is_visible

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
				rarity_label.mouse_filter = Control.MOUSE_FILTER_PASS
				count_label.mouse_filter = Control.MOUSE_FILTER_PASS

func _gui_input(event: InputEvent) -> void:
                if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
                                card_pressed.emit(card_id)

func set_upside_down(is_upside_down: bool) -> void:
                if not is_node_ready():
                                await ready
                texture_rect.pivot_offset = texture_rect.size * 0.5
                texture_rect.rotation_degrees = 180 if is_upside_down else 0
