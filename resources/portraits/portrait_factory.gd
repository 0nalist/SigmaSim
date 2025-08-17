class_name PortraitFactory

static func djb2(name: String) -> int:
	var hash := 5381
	for i in name.length():
		hash = ((hash << 5) + hash) + name.unicode_at(i)
		hash &= 0xFFFFFFFF
	return hash

static func rng_from_seed(seed: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	return rng

static func generate_config_for_name(full_name: String) -> PortraitConfig:
	var seed = djb2(full_name)
	var rng = rng_from_seed(seed)
	var cfg := PortraitConfig.new()
	cfg.name = full_name
	cfg.seed = seed
	for layer in PortraitCache.layers_order():
		var info := PortraitCache.layer_info(layer)
		var count := (info.get("textures", []) as Array).size()
		var idx := 0
		match layer:
		"face":
			if count > 0:
				idx = rng.randi_range(1, count)
		"hair_back":
			if rng.randf() < 0.4 and count > 0:
				idx = rng.randi_range(1, count)
		"hair":
			if rng.randf() < 0.95 and count > 0:
				idx = rng.randi_range(1, count)
		_:
			if rng.randf() >= 0.001 and count > 0:
				idx = rng.randi_range(1, count)
		cfg.indices[layer] = idx
		if idx > 0:
			cfg.colors[layer] = Color(rng.randf(), rng.randf(), rng.randf(), 1.0)
	return cfg

static func ensure_config_for_npc(idx: int, full_name: String) -> PortraitConfig:
	var slot_id = SaveManager.current_slot_id
	var rows = DBManager.db.select_rows("npc", "id = %d AND slot_id = %d" % [idx, slot_id], ["portrait_config"])
	if rows.size() > 0:
		var raw = rows[0].get("portrait_config", null)
		var parsed = raw if typeof(raw) == TYPE_DICTIONARY else DBManager.from_json(str(raw))
		if typeof(parsed) == TYPE_DICTIONARY and parsed.size() > 0:
			return PortraitConfig.from_dict(parsed)
		var cfg := generate_config_for_name(full_name)
		DBManager.db.update_rows("npc", "id = %d AND slot_id = %d" % [idx, slot_id], {"portrait_config": to_json(cfg.to_dict())})
		return cfg
	else:
		var cfg := generate_config_for_name(full_name)
		DBManager.db.insert_row("npc", {"id": idx, "slot_id": slot_id, "full_name": full_name, "portrait_config": to_json(cfg.to_dict())})
		return cfg

