extends Control
class_name SystemUpgradeUI

@export var system_name: String

@onready var upgrades_list: VBoxContainer = %UpgradesList
@onready var info_label: Label = %InfoLabel # Optional, for messages
@onready var sort_option_button: OptionButton = %SortOptionButton

# Optionally allow filtering locked upgrades in UI
@export var show_locked: bool = true

@export var upgrade_ui: PackedScene

var sort_mode: int = 0

func _ready() -> void:
        UpgradeManager.connect("upgrade_purchased", _on_upgrade_changed)
        # If you add an "upgrade_unlocked" signal, connect here.
        sort_option_button.add_item("Name", 0)
        sort_option_button.add_item("Price: Low to High", 1)
        sort_option_button.add_item("Price: High to Low", 2)
        sort_option_button.item_selected.connect(_on_sort_option_selected)
        refresh_upgrades()

func _exit_tree() -> void:
	if UpgradeManager.is_connected("upgrade_purchased", _on_upgrade_changed):
		UpgradeManager.disconnect("upgrade_purchased", _on_upgrade_changed)
	# Repeat for any other signals

func refresh_upgrades() -> void:
        for child in upgrades_list.get_children():
                child.queue_free()
        var upgrades = UpgradeManager.get_upgrades_for_system(system_name, show_locked)
        match sort_mode:
                1:
                        upgrades.sort_custom(_sort_by_price_asc)
                2:
                        upgrades.sort_custom(_sort_by_price_desc)
                _:
                        upgrades.sort_custom(_sort_by_unlock_then_id) # Optional: unlocked first, then by id/name
        for upgrade in upgrades:
                var row = upgrade_ui.instantiate()
                upgrades_list.add_child(row)

                row.set_upgrade(upgrade)
                row.set_locked(UpgradeManager.is_locked(upgrade["id"]))
                row.set_level(StatManager.get_upgrade_level(upgrade["id"]))
                row.connect("purchase_requested", _on_purchase_requested)


func _sort_by_unlock_then_id(a, b):
        # Show unlocked upgrades first, then by id
        var a_locked = UpgradeManager.is_locked(a["id"])
        var b_locked = UpgradeManager.is_locked(b["id"])
        if a_locked == b_locked:
                return a["id"] < b["id"]
        return a_locked < b_locked

func _sort_by_price_asc(a, b):
        var a_locked = UpgradeManager.is_locked(a["id"])
        var b_locked = UpgradeManager.is_locked(b["id"])
        if a_locked != b_locked:
                return a_locked < b_locked
        var cost_a = UpgradeManager.get_cost_for_next_level(a["id"]).get("cash", 0)
        var cost_b = UpgradeManager.get_cost_for_next_level(b["id"]).get("cash", 0)
        if cost_a == cost_b:
                return a["id"] < b["id"]
        return cost_a < cost_b

func _sort_by_price_desc(a, b):
        var a_locked = UpgradeManager.is_locked(a["id"])
        var b_locked = UpgradeManager.is_locked(b["id"])
        if a_locked != b_locked:
                return a_locked < b_locked
        var cost_a = UpgradeManager.get_cost_for_next_level(a["id"]).get("cash", 0)
        var cost_b = UpgradeManager.get_cost_for_next_level(b["id"]).get("cash", 0)
        if cost_a == cost_b:
                return a["id"] < b["id"]
        return cost_a > cost_b

func _on_sort_option_selected(index: int) -> void:
        sort_mode = index
        refresh_upgrades()

func _on_purchase_requested(upgrade_id: String):
	if UpgradeManager.purchase(upgrade_id):
		_display_message("Upgrade purchased: %s" % upgrade_id)
		refresh_upgrades()
	else:
		_display_message("Cannot purchase upgrade: %s" % upgrade_id)

func _on_upgrade_changed(id: String, new_level: int):
	# Called when an upgrade is purchased or unlocked; refresh UI.
	refresh_upgrades()

func _display_message(msg: String) -> void:
	if info_label:
		info_label.text = msg
