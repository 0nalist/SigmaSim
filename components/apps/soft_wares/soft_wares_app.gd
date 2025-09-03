extends Pane
class_name SoftWaresApp

const SOFTWARE_ITEM_SCENE: PackedScene = preload("res://components/apps/soft_wares/soft_ware_item.tscn")

@onready var items_container: VBoxContainer = %ItemsContainer

func _ready() -> void:
	_populate_items()

func _populate_items() -> void:
                                var used_icons: Dictionary = {}
                                var exclude := ["SoftWares", "OwerView", "SigmaMail", "Installer"]
                                for app_name in WindowManager.app_registry.keys():
                                                if app_name in exclude:
                                                                continue
                                                var scene: PackedScene = WindowManager.app_registry[app_name]
                                                var pane = scene.instantiate()
                                                if not (pane is Pane):
                                                                pane.queue_free()
                                                                continue
                                                var icon: Texture2D = pane.window_icon
                                                var icon_path: String = icon.resource_path if icon else ""
                                                if used_icons.has(icon_path):
                                                                pane.queue_free()
                                                                continue
                                                used_icons[icon_path] = true
                                                var item: SoftWareItem = SOFTWARE_ITEM_SCENE.instantiate() as SoftWareItem
                                                item.app_icon = icon
                                                item.app_title = pane.window_title
                                                item.app_description = ""
                                                item.app_cost = 5
                                                item.app_id = app_name.to_lower()
                                                item.upgrade_scene = pane.upgrade_pane
                                                items_container.add_child(item)
                                                pane.queue_free()

