class_name PortraitFactory

static func djb2(name: String) -> int:
	var hash := 5381
	for i in range(name.length()):
		hash = ((hash << 5) + hash) + name.unicode_at(i)
		hash &= 0xFFFFFFFF
	return hash

static func rng_from_seed(seed: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	return rng

static func generate_config_for_name(full_name: String) -> PortraitConfig:
	var seed := djb2(full_name)
	var rng := rng_from_seed(seed)
	var cfg := PortraitConfig.new()
	cfg.name = full_name
	cfg.seed = seed

	for layer in PortraitCache.layers_order():
			var info := PortraitCache.layer_info(layer)
			var textures := info.get("textures", []) as Array
			var count := textures.size()
			var idx := 0

			match layer:
					"face":
							if count > 0:
									idx = rng.randi_range(1, count)
					"hair_back":
							if count > 0 and rng.randf() < 0.4:
									idx = rng.randi_range(1, count)
					"hair":
							if count > 0 and rng.randf() < 0.95:
									idx = rng.randi_range(1, count)
					_:
							# Eyes/Nose/Mouth/Shirt: 0.1% chance to be missing
							if count > 0 and rng.randf() >= 0.001:
									idx = rng.randi_range(1, count)

			cfg.indices[layer] = idx
			if idx > 0 and layer != "hair" and layer != "hair_back":
					cfg.colors[layer] = Color(rng.randf(), rng.randf(), rng.randf(), 1.0)

	var hair_idx = cfg.indices.get("hair", 0)
	var hair_back_idx = cfg.indices.get("hair_back", 0)
	if hair_idx > 0:
			var col = Color(rng.randf(), rng.randf(), rng.randf(), 1.0)
			cfg.colors["hair"] = col
			if hair_back_idx > 0:
					cfg.colors["hair_back"] = col
	elif hair_back_idx > 0:
			cfg.colors["hair_back"] = Color(rng.randf(), rng.randf(), rng.randf(), 1.0)

	return cfg

static func ensure_config_for_npc(idx: int, full_name: String) -> PortraitConfig:
	var slot_id := SaveManager.current_slot_id
	var where := "id = %d AND slot_id = %d" % [idx, slot_id]
	var rows = DBManager.db.select_rows("npc", where, ["portrait_config"])

	if rows.size() > 0:
		var raw = rows[0].get("portrait_config", null)

		var parsed_dict := {}
		if raw != null:
			var variant = JSON.parse_string(str(raw))
			if variant is Dictionary:
				parsed_dict = variant

		if parsed_dict is Dictionary and not (parsed_dict as Dictionary).is_empty():
			return PortraitConfig.from_dict(parsed_dict)

		var cfg := generate_config_for_name(full_name)
		DBManager.db.update_rows("npc", where, {
			"portrait_config": JSON.stringify(cfg.to_dict())
		})
		return cfg
	else:
		var cfg := generate_config_for_name(full_name)
		DBManager.db.insert_row("npc", {
			"id": idx,
			"slot_id": slot_id,
			"full_name": full_name,
			"portrait_config": JSON.stringify(cfg.to_dict())
		})
		return cfg
