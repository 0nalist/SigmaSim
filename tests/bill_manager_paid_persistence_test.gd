extends SceneTree

func _ready():
		var bm = Engine.get_singleton("BillManager")
		var tm = Engine.get_singleton("TimeManager")
		bm.reset()
		var date_key = "%d/%d/%d" % [tm.current_day, tm.current_month, tm.current_year]
		bm.mark_bill_paid("Rent", date_key)
		var data = bm.get_save_data()
		bm.reset()
		bm.load_from_data(data)
		assert(bm.is_bill_paid("Rent", date_key))
		print("bill_manager_paid_persistence_test passed")
		quit()
