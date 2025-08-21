extends Pane

@export var debt_card_scene: PackedScene = preload("res://components/ui/debt_card_ui.tscn")
@onready var card_container: VBoxContainer = %CardContainer
@onready var credit_score_label: Label = %CreditScoreLabel

func _ready():
    BillManager.debt_resources_changed.connect(_refresh_cards)
    PortfolioManager.resource_changed.connect(_on_resource_changed)
    _refresh_cards()
    _update_credit_score()

func _refresh_cards() -> void:
    for c in card_container.get_children():
        c.queue_free()
    for debt in BillManager.get_debt_resources():
        var card = debt_card_scene.instantiate() as DebtCardUI
        card.setup(debt)
        card_container.add_child(card)

func _update_credit_score() -> void:
    var score = PortfolioManager.get_credit_score()
    credit_score_label.text = "%d" % score

func _on_resource_changed(resource_name: String, _value: float) -> void:
    if resource_name in ["student_loans", "credit", "cash"]:
        for card in card_container.get_children():
            card.update_display()
    if resource_name == "debt":
        _update_credit_score()
