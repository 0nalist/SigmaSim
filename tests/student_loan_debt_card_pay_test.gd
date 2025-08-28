extends SceneTree

func _ready():
        var pm = Engine.get_singleton("PortfolioManager")
        var bm = Engine.get_singleton("BillManager")
        pm.reset()
        bm.reset()
        pm.add_cash(100.0)
        pm.set_student_loans(100.0)
        bm.add_debt_resource({
                "name": "Student Loan",
                "balance": 100.0
        })
        var card = DebtCardUI.new()
        get_root().add_child(card)
        await card.ready
        card.init({
                "name": "Student Loan",
                "balance": 100.0
        })
        card.pay_slider.value = 50.0
        card._on_pay_pressed()
        assert(pm.get_student_loans() == 50.0)
        var res = bm.get_debt_resources()[0]
        assert(res.get("balance") == 50.0)
        print("student_loan_debt_card_pay_test passed")
        quit()

