extends Pane
class_name WalletUI

@onready var stack: WalletStack = %WalletStack

var _cards_by_id: Dictionary = {} # String -> Control

const WALLET_DEBUG: bool = false

func _d(msg: String) -> void:
        if WALLET_DEBUG:
                print("[WalletUI] " + msg)

func _ready() -> void:
	_build_cards()
	_connect_bus()
	stack.active_card_changed.connect(_on_active_card_changed)
	# Start with the Brag card shown
	stack.set_active_by_id("brag")

func _build_cards() -> void:
	stack.clear_cards()

	var brag: BragCard = BragCard.new()
	_cards_by_id["brag"] = brag
	stack.add_card("brag", brag)

        var credit: CreditCardFull = CreditCardFull.new()
        _cards_by_id["credit"] = credit
        stack.add_card("credit", credit)

	var loan: StudentLoanCard = StudentLoanCard.new()
	_cards_by_id["student_loan"] = loan
	stack.add_card("student_loan", loan)

func _connect_bus() -> void:
        Events.wallet_focus_card.connect(_on_focus_card)
        Events.wallet_flash_value.connect(_on_flash_value)
        Events.wallet_animate_to.connect(_on_animate_to)

func _on_focus_card(id: String) -> void:
	stack.set_active_by_id(id)

func _on_flash_value(id: String, _amount: float) -> void:
	var c: Control = _cards_by_id.get(id, null)
	if c == null:
		return
	if c.has_method("bump_value_color"):
		c.call("bump_value_color")

func _on_animate_to(id: String, to_value: float) -> void:
        var c: Control = _cards_by_id.get(id, null)
        if c == null:
                return
        if c.has_method("animate_to_util"):
                c.call("animate_to_util", to_value) # Credit card implements; others can ignore

func _on_active_card_changed(_id: String) -> void:
        # optional: update window title, etc.
        pass

func _debug_sim_cash_gain(amount: float) -> void:
        if not WALLET_DEBUG:
                return
        PortfolioManager.cash += amount
        PortfolioManager.emit_signal("cash_updated", PortfolioManager.cash)
        PortfolioManager.emit_signal("resource_changed", "cash", PortfolioManager.cash)
        Events.focus_wallet_card("brag")

func _debug_sim_credit_purchase(amount: float) -> void:
        if not WALLET_DEBUG:
                return
        BillManager.emit_signal("credit_txn_occurred", amount)
        Events.focus_wallet_card("credit")
        Events.animate_wallet_to("credit", 42.0)

func _debug_sim_loan_payment(amount: float) -> void:
        if not WALLET_DEBUG:
                return
        BillManager.emit_signal("student_loan_changed")
        Events.focus_wallet_card("student_loan")
