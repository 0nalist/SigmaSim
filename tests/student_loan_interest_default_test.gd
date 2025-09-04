extends SceneTree

func _ready():
        var pm = Engine.get_singleton("PortfolioManager")
        pm.reset()
        pm.set_student_loans(100.0)
        pm._accrue_student_loan_interest()
        var expected = snapped(100.0 * (1.0 + PortfolioManager.STUDENT_LOAN_INTEREST_DAILY), 0.01)
        assert(pm.get_student_loans() == expected)
        print("student_loan_interest_default_test passed")
        quit()

