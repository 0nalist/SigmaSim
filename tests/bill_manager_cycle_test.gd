extends SceneTree

func _ready():
        var bm = Engine.get_singleton("BillManager")
        bm.reset()
        var tm = Engine.get_singleton("TimeManager")
        tm.reset()
        var sundays = [2, 9, 16, 23]
        var expected = ["Rent", "Medical Insurance", "Student Loan", "Credit Card"]
        for i in range(sundays.size()):
                var bills = bm.get_due_bills_for_date(sundays[i], tm.current_month, tm.current_year)
                assert(expected[i] in bills)
        print("bill_manager_cycle_test passed")
        quit()
