extends SceneTree

func _ready() -> void:
        await get_tree().process_frame
        var prev_cash := PortfolioManager.cash
        var prev_credit_limit := PortfolioManager.credit_limit
        PortfolioManager.credit_limit = 0
        PortfolioManager.cash = 0
        StatManager.recalculate_all_stats_once()

        var ui: SystemUpgradeUI = load("res://data/upgrades/system_upgrade_ui.tscn").instantiate()
        ui.system_name = "fumble"
        get_root().add_child(ui)
        await get_tree().process_frame
        await get_tree().process_frame

        var row := _find_upgrade_row(ui, "fumble_personal_trainer")
        assert(row != null)
        assert(row.buy_button.disabled)

        PortfolioManager.cash = 1000
        StatManager.recalculate_all_stats_once()
        await get_tree().process_frame
        await get_tree().process_frame

        row = _find_upgrade_row(ui, "fumble_personal_trainer")
        assert(row != null)
        assert(!row.buy_button.disabled)

        PortfolioManager.cash = prev_cash
        PortfolioManager.credit_limit = prev_credit_limit
        print("fumble_special_offers_affordability_test passed")
        quit()

func _find_upgrade_row(ui: SystemUpgradeUI, id: String):
        for child in ui.upgrades_list.get_children():
                if child.upgrade_data.get("id") == id:
                        return child
        return null
