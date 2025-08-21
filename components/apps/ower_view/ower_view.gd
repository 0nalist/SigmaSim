extends Pane

@onready var wallet: VBoxContainer = %Wallet
var card_scene: PackedScene = preload("res://components/apps/ower_view/debt_card_ui.tscn")

func _ready() -> void:
	BillManager.debt_resources_changed.connect(_on_debt_changed)
	PortfolioManager.cash_updated.connect(_on_cash_updated)
	_on_debt_changed()

func _on_debt_changed() -> void:
	for child in wallet.get_children():
		child.queue_free()
	var resources: Array = BillManager.get_debt_resources()
	for res in resources:
		var card: DebtCardUI = card_scene.instantiate()
		card.init(res)
		wallet.add_child(card)

func _on_cash_updated(_cash: float) -> void:
	for child in wallet.get_children():
		if child is DebtCardUI:
			child.update_slider()
