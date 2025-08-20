extends Node
#Autoload ContextMenuManager

var _popup_menu: PopupMenu
var _owner: Node
var _actions: Dictionary = {}

func _ready() -> void:
	_popup_menu = PopupMenu.new()
	get_tree().root.add_child.call_deferred(_popup_menu)
	_popup_menu.hide()
	_popup_menu.id_pressed.connect(_on_id_pressed)

func open_for(owner: Node, screen_pos: Vector2, actions: Array) -> void:
	_owner = owner
	_actions.clear()
	_popup_menu.clear()
	for action in actions:
		var ctx: ContextAction = action
		_actions[ctx.id] = ctx
		_popup_menu.add_item(ctx.label, ctx.id)
		var idx: int = _popup_menu.get_item_count() - 1
		_popup_menu.set_item_disabled(idx, not ctx.enabled)
	_popup_menu.position = screen_pos
	_popup_menu.reset_size()
	_popup_menu.popup()

func _on_id_pressed(id: int) -> void:
	if _actions.has(id):
		var action: ContextAction = _actions[id]
		action.execute(_owner)
	_popup_menu.hide()
