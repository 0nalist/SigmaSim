extends Node
#Autoload: MarkupParser

var _global_sources := [] # Array of objects/dicts to search for variables

func _ready():
	# Register common variable sources
	_global_sources = [
		PlayerManager,
		NameManager
	]

# Allows runtime registration of more sources (e.g., GameState, AppManager)
func register_global_source(source):
	if not _global_sources.has(source):
		_global_sources.append(source)

func parse(template: String, npc: Object, context: Dictionary = {}) -> String:
	var regex = RegEx.new()
	regex.compile(r"{([A-Za-z_][A-Za-z0-9_]*)}")
	var result := ""
	var pos := 0
	for match in regex.search_all(template):
		var var_name = match.get_string(1)
		var value = _resolve_tag(var_name, npc, context)
		# Apply same capitalization as tag (first letter only)
		if var_name.length() > 0 and _is_upper_ascii_letter(var_name[0]):
			value = value.capitalize()
		result += template.substr(pos, match.get_start() - pos)
		result += value
		pos = match.get_end()
	result += template.substr(pos)
	return result

static func _is_upper_ascii_letter(char: String) -> bool:
	return char.length() == 1 and char >= "A" and char <= "Z"



func _resolve_tag(tag: String, npc: Object, context: Dictionary) -> String:
	var tag_lc = tag.to_lower()
	# 1. Context dictionary takes priority
	if context.has(tag):
		return str(context[tag])
	if context.has(tag_lc):
		return str(context[tag_lc])
	# 2. NPC-specific tags, supports like/likes/like1/like2, etc.
	if npc:
		# likes
		if tag_lc == "likes":
			return _join_with_and(_get_any(npc, "likes"))
		if tag_lc == "like":
			var likes = _get_any(npc, "likes")
			if likes and likes.size() > 0:
				return str(likes[0])
			return "nothing"
		# Like1, Like2, ...
		if tag_lc.begins_with("like") and tag_lc.length() > 4 and tag_lc.substr(4).is_valid_int():
			var idx = int(tag_lc.substr(4)) - 1
			var likes = _get_any(npc, "likes")
			if likes and idx >= 0 and idx < likes.size():
				return str(likes[idx])
			return "nothing"
		# tags
		if tag_lc == "tags":
			return _join_with_and(_get_any(npc, "tags"))
		if tag_lc == "tag":
			var tags = _get_any(npc, "tags")
			if tags and tags.size() > 0:
				return str(tags[0])
			return "none"
		if tag_lc.begins_with("tag") and tag_lc.length() > 3 and tag_lc.substr(3).is_valid_int():
			var idx = int(tag_lc.substr(3)) - 1
			var tags = _get_any(npc, "tags")
			if tags and idx >= 0 and idx < tags.size():
				return str(tags[idx])
			return "none"
		# Other NPC properties (use reflection)
		var npc_val = _get_any(npc, tag)
		if npc_val != null:
			return str(npc_val)
		var npc_val_lc = _get_any(npc, tag_lc)
		if npc_val_lc != null:
			return str(npc_val_lc)
        # 3. Special tags: Random first/last name (use NameManager singleton)
        var tag_flat = tag_lc.replace("_", "")
        if tag_flat == "randomfirstname":
                return NameManager.get_random_first_name() if NameManager.has_method("get_random_first_name") else "FirstName"
        if tag_flat == "randomlastname":
                return NameManager.get_random_last_name() if NameManager.has_method("get_random_last_name") else "LastName"
	# 4. Search global sources (PlayerManager, etc)
	for src in _global_sources:
		var val = _get_any(src, tag)
		if val != null:
			return str(val)
		var val_lc = _get_any(src, tag_lc)
		if val_lc != null:
			return str(val_lc)
	# Not found
	return "?"

# Helper: gets variable from object, dict, or resource by name (using get(), [], or property)
static func _get_any(obj, key: String):
	if obj == null:
		return null
	# If it's a dictionary
	if typeof(obj) == TYPE_DICTIONARY and obj.has(key):
		return obj[key]
	# Custom get_var method
	if obj.has_method("get_var"):
		var v = obj.get_var(key)
		if v != null:
			return v
	# Custom get_stat method
	if obj.has_method("get_stat"):
		var v = obj.get_stat(key)
		if v != null:
			return v
	# Godot objects with property list (including Resources/Nodes)
	if obj.has_method("get_property_list"):
		for prop in obj.get_property_list():
			if prop.name == key:
				return obj.get(key)
	# Fallback for classes with get()
	if obj.has_method("get"):
		# Avoid infinite loop if get("get") is itself!
		if key != "get":
			var v = obj.get(key)
			if v != null:
				return v
	# Direct field lookup for classes with public members (as a last resort)
	if key in obj:
		return obj[key]
	return null


# Joins a list as "a, b, and c"
static func _join_with_and(arr: Array) -> String:
	if arr == null or arr.size() == 0:
		return "nothing"
	if arr.size() == 1:
		return str(arr[0])
	if arr.size() == 2:
		return "%s and %s" % [arr[0], arr[1]]
	return "%s, and %s" % [", ".join(arr.slice(0, arr.size() - 1)), arr[arr.size() - 1]]
