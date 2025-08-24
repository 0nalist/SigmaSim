extends SceneTree

func _ready():
       var bm = Engine.get_singleton("BillManager")
       bm.reset()
       var tm = Engine.get_singleton("TimeManager")
       var date_key = "%d/%d/%d" % [tm.current_day, tm.current_month, tm.current_year]
       var popup = preload("res://components/popups/bill_popup_ui.tscn").instantiate()
       popup.load_custom_save_data({
               "bill_name": "Rent",
               "amount": 1000.0,
               "date_key": date_key
       })
       assert(bm.active_bills.has(date_key))
       assert(bm.active_bills[date_key].size() == 1)
       print("bill_manager_popup_test passed")
       quit()
