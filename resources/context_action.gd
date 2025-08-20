extends Resource
class_name ContextAction

var id: int = 0
var label: String = ""
var enabled: bool = true
var method: String = ""
var args: Array = []

func execute(owner: Node) -> void:
	if not enabled:
		return
	if owner and owner.has_method(method):
		owner.callv(method, args)
