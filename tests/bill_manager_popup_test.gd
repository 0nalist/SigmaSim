extends SceneTree

func _init():
	var bm = Engine.get_singleton("BillManager")
	var tm = Engine.get_singleton("TimeManager")
	var date_key = "%d/%d/%d" % [tm.current_day, tm.current_month, tm.current_year]
	var data = {
			"autopay_enabled": false,
			"lifestyle_categories": {},
			"lifestyle_indices": {},
			"pane_data": [
					{
							"type": "BillPopupUI",
							"bill_name": "Rent",
							"amount": 1000.0,
							"date_key": date_key
					}
			]
	}
	bm.load_from_data(data)
	assert(bm.active_bills.is_empty())
	bm.show_due_popups()
	assert(bm.active_bills.has(date_key))
	assert(bm.active_bills[date_key].size() == 1)
	print("bill_manager_popup_test passed")
	quit()
