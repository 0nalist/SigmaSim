extends Node
# Autoload singleton: ConversationManager

signal conversation_started(conv_id: String, npc_id: int)
signal node_entered(conv_id: String, node_id: String, speaker: String, text: String)
signal choice_presented(choice_id: String, options: Array)
signal conversation_ended(conv_id: String, npc_id: int)

# Loaded data
var conversation_registry: Dictionary = {}
var nodes: Dictionary = {}
var choices: Dictionary = {}

# Persistent per NPC state
var npc_conversation_state: Dictionary = {}

func _ready() -> void:
    _load_data()

func _load_data() -> void:
    _conversation_registry_load()
    _nodes_load()
    _choices_load()

func _conversation_registry_load() -> void:
    var path: String = "res://autoloads/conversations.json"
    if FileAccess.file_exists(path):
        var text: String = FileAccess.get_file_as_string(path)
        var parsed = JSON.parse_string(text)
        if typeof(parsed) == TYPE_DICTIONARY:
            conversation_registry = parsed

func _nodes_load() -> void:
    var path: String = "res://autoloads/nodes.json"
    if FileAccess.file_exists(path):
        var text: String = FileAccess.get_file_as_string(path)
        var parsed = JSON.parse_string(text)
        if typeof(parsed) == TYPE_DICTIONARY:
            nodes = parsed

func _choices_load() -> void:
    var path: String = "res://autoloads/choices.json"
    if FileAccess.file_exists(path):
        var text: String = FileAccess.get_file_as_string(path)
        var parsed = JSON.parse_string(text)
        if typeof(parsed) == TYPE_DICTIONARY:
            choices = parsed

func _get_state(npc_id: int) -> Dictionary:
    if not npc_conversation_state.has(npc_id):
        var state: Dictionary = {
            "active_conv_id": "",
            "active_node_id": "",
            "history": [],
            "outcomes": {},
            "cooldowns": {}
        }
        npc_conversation_state[npc_id] = state
    return npc_conversation_state[npc_id]

func start(conv_id: String, npc_id: int, initiator: String) -> void:
    var state: Dictionary = _get_state(npc_id)
    state.active_conv_id = conv_id
    var meta: Dictionary = conversation_registry.get(conv_id, {})
    var start_node_id: String = ""
    if initiator == "player":
        start_node_id = meta.get("player_start", "")
    else:
        start_node_id = meta.get("npc_start", "")
    state.active_node_id = start_node_id
    emit_signal("conversation_started", conv_id, npc_id)
    if start_node_id != "":
        _enter_node(conv_id, start_node_id, npc_id)

func _enter_node(conv_id: String, node_id: String, npc_id: int) -> void:
    var state: Dictionary = _get_state(npc_id)
    state.active_node_id = node_id
    var conv_nodes: Dictionary = nodes.get(conv_id, {})
    var node: Dictionary = conv_nodes.get(node_id, {})
    var speaker: String = node.get("speaker", "")
    var raw_text: String = node.get("text", "")
    var text: String = _resolve_text(raw_text, npc_id)
    emit_signal("node_entered", conv_id, node_id, speaker, text)

func progress(node_id: String, npc_id: int) -> void:
    var state: Dictionary = _get_state(npc_id)
    var conv_id: String = state.active_conv_id
    if conv_id == "":
        return
    var conv_nodes: Dictionary = nodes.get(conv_id, {})
    if not conv_nodes.has(node_id):
        return
    var node: Dictionary = conv_nodes.get(node_id, {})
    var next_id: String = node.get("next", "")
    if next_id == "":
        return
    if next_id == "END":
        _end_conversation(npc_id)
        return
    if next_id.begins_with("choice:"):
        var choice_id: String = next_id.substr(7)
        _present_choice(choice_id, npc_id)
        return
    if next_id.begins_with("conv:"):
        var conv_switch: String = next_id.substr(5)
        start(conv_switch, npc_id, "npc")
        return
    _enter_node(conv_id, next_id, npc_id)

func _present_choice(choice_id: String, npc_id: int) -> void:
    var state: Dictionary = _get_state(npc_id)
    var conv_id: String = state.active_conv_id
    var conv_choices: Dictionary = choices.get(conv_id, {})
    var choice_def: Dictionary = conv_choices.get(choice_id, {})
    var options_def: Array = choice_def.get("options", [])
    var options_out: Array = []
    for opt in options_def:
        var conditions: Array = opt.get("conditions", [])
        if not _conditions_met(conditions, npc_id):
            continue
        var text: String = _resolve_text(opt.get("text", ""), npc_id)
        var entry: Dictionary = {
            "id": opt.get("id", ""),
            "text": text
        }
        options_out.append(entry)
    emit_signal("choice_presented", choice_id, options_out)

func choose(choice_id: String, option_id: String, npc_id: int) -> void:
    var state: Dictionary = _get_state(npc_id)
    var conv_id: String = state.active_conv_id
    var conv_choices: Dictionary = choices.get(conv_id, {})
    var choice_def: Dictionary = conv_choices.get(choice_id, {})
    var options_def: Array = choice_def.get("options", [])
    var selected: Dictionary = {}
    for opt in options_def:
        if opt.get("id", "") == option_id:
            selected = opt
            break
    if selected.is_empty():
        return
    var rng: RandomNumberGenerator
    if RNGManager != null:
        rng = RNGManager.global.get_rng()
    else:
        rng = RandomNumberGenerator.new()
    var chance: float = float(selected.get("success_chance", 1.0))
    var roll: float = rng.randf()
    var success: bool = roll <= chance
    if success:
        _apply_effects(selected.get("effects_success", []), npc_id)
        var next_node_s: String = selected.get("success_node", "")
        if next_node_s != "":
            _enter_node(conv_id, next_node_s, npc_id)
    else:
        _apply_effects(selected.get("effects_failure", []), npc_id)
        var next_node_f: String = selected.get("failure_node", "")
        if next_node_f != "":
            _enter_node(conv_id, next_node_f, npc_id)

func _end_conversation(npc_id: int) -> void:
    var state: Dictionary = _get_state(npc_id)
    var conv_id: String = state.active_conv_id
    state.active_conv_id = ""
    state.active_node_id = ""
    if not state.history.has(conv_id):
        state.history.append(conv_id)
    var meta: Dictionary = conversation_registry.get(conv_id, {})
    var cooldown: int = int(meta.get("cooldown", 0))
    if cooldown > 0:
        state.cooldowns[conv_id] = Time.get_unix_time_from_system() + cooldown
    if DBManager != null and DBManager.has_method("log_completed_conversation"):
        DBManager.log_completed_conversation(conv_id, npc_id, Time.get_unix_time_from_system())
    if DBManager != null and DBManager.has_method("set_npc_conversation_outcomes"):
        DBManager.set_npc_conversation_outcomes(npc_id, state.outcomes)
    emit_signal("conversation_ended", conv_id, npc_id)

func _conditions_met(conditions: Array, npc_id: int) -> bool:
    for cond in conditions:
        var ctype: String = cond.get("type", "")
        if ctype == "cash_at_least":
            if StatManager == null:
                return false
            var amount: float = float(cond.get("amount", 0))
            var cash_val: float = StatManager.get_stat_float("cash", 0.0)
            if cash_val < amount:
                return false
        elif ctype == "npc_stat_at_least":
            if NPCManager == null or not NPCManager.has_method("get_npc_stat"):
                return false
            var stat: String = cond.get("stat", "")
            var value = cond.get("value", 0)
            var npc_val = NPCManager.get_npc_stat(npc_id, stat)
            if float(npc_val) < float(value):
                return false
        elif ctype == "flag_true":
            var flag_t: String = cond.get("flag", "")
            var state: Dictionary = _get_state(npc_id)
            if not bool(state.outcomes.get(flag_t, false)):
                return false
        elif ctype == "flag_false":
            var flag_f: String = cond.get("flag", "")
            var state_f: Dictionary = _get_state(npc_id)
            if bool(state_f.outcomes.get(flag_f, false)):
                return false
        elif ctype == "relationship_stage_at_least":
            if NPCManager == null or not NPCManager.has_method("get_relationship_stage"):
                return false
            var stage: int = int(cond.get("stage", 0))
            var cur_stage: int = int(NPCManager.get_relationship_stage(npc_id))
            if cur_stage < stage:
                return false
    return true

func _apply_effects(effects: Array, npc_id: int) -> void:
    var state: Dictionary = _get_state(npc_id)
    for eff in effects:
        var etype: String = eff.get("type", "")
        if etype == "add_cash":
            if StatManager != null and StatManager.has_method("add_cash"):
                StatManager.add_cash(float(eff.get("amount", 0.0)))
        elif etype == "set_stat":
            if StatManager != null and StatManager.has_method("set_base_stat"):
                StatManager.set_base_stat(eff.get("stat", ""), eff.get("value", 0))
        elif etype == "increment_npc_stat":
            if NPCManager != null and NPCManager.has_method("increment_npc_stat"):
                NPCManager.increment_npc_stat(npc_id, eff.get("stat", ""), eff.get("amount", 0))
        elif etype == "set_npc_stat":
            if NPCManager != null and NPCManager.has_method("set_npc_stat"):
                NPCManager.set_npc_stat(npc_id, eff.get("stat", ""), eff.get("value", 0))
        elif etype == "set_flag":
            state.outcomes[eff.get("flag", "")] = true
        elif etype == "clear_flag":
            state.outcomes[eff.get("flag", "")] = false

func _resolve_text(raw: String, npc_id: int) -> String:
    var segments: Array = raw.split(";;")
    var candidates: Array = []
    for seg in segments:
        var part: String = seg.strip_edges()
        var weight: int = 1
        if part.find("|") != -1:
            var sp = part.rsplit("|", false, 1)
            if sp.size() == 2 and sp[1].is_valid_int():
                part = sp[0]
                weight = int(sp[1])
        if part.begins_with("[cond:"):
            var end: int = part.find("]")
            if end != -1:
                var cond_json: String = part.substr(6, end - 6)
                var arr = JSON.parse_string(cond_json)
                part = part.substr(end + 1)
                if typeof(arr) == TYPE_ARRAY:
                    if not _conditions_met(arr, npc_id):
                        continue
        var candidate: Dictionary = {
            "text": part,
            "weight": weight
        }
        candidates.append(candidate)
    if candidates.is_empty():
        return ""
    var total: int = 0
    for c in candidates:
        total += int(c.get("weight", 1))
    var rng: RandomNumberGenerator
    if RNGManager != null:
        rng = RNGManager.global.get_rng()
    else:
        rng = RandomNumberGenerator.new()
    var roll: int = rng.randi_range(1, total)
    var accum: int = 0
    var chosen: String = candidates[0].get("text", "")
    for c in candidates:
        accum += int(c.get("weight", 1))
        if roll <= accum:
            chosen = c.get("text", "")
            break
    if PlayerManager != null:
        var name: String = PlayerManager.user_data.get("name", "Player")
        chosen = chosen.replace("{{player_name}}", name)
    return chosen

func get_available_conversations(npc_id: int, trigger: String) -> Array:
    var available: Array = []
    var state: Dictionary = _get_state(npc_id)
    var now: int = Time.get_unix_time_from_system()
    for conv_id in conversation_registry.keys():
        var meta: Dictionary = conversation_registry.get(conv_id, {})
        if meta.get("trigger_type", "") != trigger:
            continue
        var conds: Array = meta.get("conditions", [])
        if not _conditions_met(conds, npc_id):
            continue
        var cool: Dictionary = state.cooldowns
        if cool.has(conv_id):
            var ready: int = int(cool.get(conv_id, 0))
            if now < ready:
                continue
        var repeatable: bool = bool(meta.get("repeatable", false))
        if not repeatable and state.history.has(conv_id):
            continue
        available.append(conv_id)
    return available

func get_save_data() -> Dictionary:
    return {"npc_conversation_state": npc_conversation_state}

func load_from_data(data: Dictionary) -> void:
    if DBManager != null and DBManager.has_method("get_all_npc_conversation_state"):
        var db_state = DBManager.get_all_npc_conversation_state()
        if typeof(db_state) == TYPE_DICTIONARY:
            npc_conversation_state = db_state
            return
    npc_conversation_state = data.get("npc_conversation_state", {}).duplicate(true)

