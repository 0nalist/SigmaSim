extends SceneTree

func _ready():
        var pm = Engine.get_singleton("PortfolioManager")
        var bm = Engine.get_singleton("BillManager")
        pm.reset()
        bm.reset()
        pm.add_cash(100.0)
        bm.add_debt_resource({
                "name": "Test Debt",
                "balance": 100.0
        })
        var card = DebtCardUI.new()
        get_root().add_child(card)
        await card.ready
        card.init({
                "name": "Test Debt",
                "balance": 100.0
        })
        card.pay_slider.value = 50.0
        card._on_pay_pressed()
        var res = bm.get_debt_resources()[0]
        assert(res.get("balance") == 50.0)
        print("debt_card_pay_test passed")
        quit()

