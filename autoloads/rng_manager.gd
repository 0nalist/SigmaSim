extends Node

# Master seed used to derive deterministic seeds for each subsystem
var seed: int = 0

class RNGStream:
	var rng := RandomNumberGenerator.new()
	var seed: int = 0

	func init_seed(seed_value: int) -> void:
		seed = seed_value
		rng.seed = seed

	func get_rng() -> RandomNumberGenerator:
		return rng

	func get_state() -> int:
		return rng.state

	func set_state(state: int) -> void:
		rng.state = state


	func shuffle(arr: Array) -> void:
		for i in range(arr.size() - 1, 0, -1):
			var j = rng.randi_range(0, i)
			var temp = arr[i]
			arr[i] = arr[j]
			arr[j] = temp

class GlobalRNG extends RNGStream:
	pass

class GPURNG extends RNGStream:
	pass

class RizzBattleDataRNG extends RNGStream:
	pass

class FumbleManagerRNG extends RNGStream:
	pass

class FumbleProfileStackRNG extends RNGStream:
	pass

class WorkerManagerRNG extends RNGStream:
	pass

class MarketManagerRNG extends RNGStream:
	pass

class SiggyRNG extends RNGStream:
	pass

class TickerRNG extends RNGStream:
	pass

class EarlyBirdRNG extends RNGStream:
	pass

class CryptoRNG extends RNGStream:
	pass

class PortraitCreatorRNG extends RNGStream:
	pass

class FumbleBattleUIRNG extends RNGStream:
	pass

class LockedInRNG extends RNGStream:
	pass

class FumbleBattleLogicRNG extends RNGStream:
	pass

class TaskManagerRNG extends RNGStream:
	pass

class NPCManagerRNG extends RNGStream:
	pass

class TarotCardRNG extends RNGStream:
	pass

class TarotRarityRNG extends RNGStream:
		pass

class TarotOrientationRNG extends RNGStream:
		pass

var global := GlobalRNG.new()
var gpu := GPURNG.new()
var rizz_battle_data := RizzBattleDataRNG.new()
var fumble_manager := FumbleManagerRNG.new()
var fumble_profile_stack := FumbleProfileStackRNG.new()
var worker_manager := WorkerManagerRNG.new()
var market_manager := MarketManagerRNG.new()
var siggy := SiggyRNG.new()
var ticker := TickerRNG.new()
var early_bird := EarlyBirdRNG.new()
var crypto := CryptoRNG.new()
var portrait_creator := PortraitCreatorRNG.new()
var fumble_battle_ui := FumbleBattleUIRNG.new()
var locked_in := LockedInRNG.new()
var fumble_battle_logic := FumbleBattleLogicRNG.new()
var task_manager := TaskManagerRNG.new()
var npc_manager := NPCManagerRNG.new()
var tarot_card := TarotCardRNG.new()
var tarot_rarity := TarotRarityRNG.new()
var tarot_orientation := TarotOrientationRNG.new()

var streams := {
	"global": global,
	"gpu": gpu,
	"rizz_battle_data": rizz_battle_data,
	"fumble_manager": fumble_manager,
	"fumble_profile_stack": fumble_profile_stack,
	"worker_manager": worker_manager,
	"market_manager": market_manager,
	"siggy": siggy,
	"ticker": ticker,
	"early_bird": early_bird,
	"crypto": crypto,
	"portrait_creator": portrait_creator,
	"fumble_battle_ui": fumble_battle_ui,
	"locked_in": locked_in,
	"fumble_battle_logic": fumble_battle_logic,
	"task_manager": task_manager,
	"npc_manager": npc_manager,
	"tarot_card": tarot_card,
	"tarot_rarity": tarot_rarity,
		"tarot_orientation": tarot_orientation,
}

func reset() -> void:
	seed = 0
	for name in streams.keys():
			var stream_class = streams[name].get_script()
			streams[name] = stream_class.new()
			set(name, streams[name])

func _derive_seed(name: String) -> int:
		return hash(str(seed) + ":" + name)

func init_seed(seed_value: int) -> void:
	print("RNGManager.init_seed:", seed_value)
	seed = seed_value
	global.init_seed(seed)
	gpu.init_seed(_derive_seed("gpu"))
	rizz_battle_data.init_seed(_derive_seed("rizz_battle_data"))
	NameManager.set_name_seed(_derive_seed("name_manager"))
	fumble_manager.init_seed(_derive_seed("fumble_manager"))
	fumble_profile_stack.init_seed(_derive_seed("fumble_profile_stack"))
	worker_manager.init_seed(_derive_seed("worker_manager"))
	market_manager.init_seed(_derive_seed("market_manager"))
	siggy.init_seed(_derive_seed("siggy"))
	ticker.init_seed(_derive_seed("ticker"))
	early_bird.init_seed(_derive_seed("early_bird"))
	crypto.init_seed(_derive_seed("crypto"))
	portrait_creator.init_seed(_derive_seed("portrait_creator"))
	fumble_battle_ui.init_seed(_derive_seed("fumble_battle_ui"))
	locked_in.init_seed(_derive_seed("locked_in"))
	fumble_battle_logic.init_seed(_derive_seed("fumble_battle_logic"))
	task_manager.init_seed(_derive_seed("task_manager"))
	npc_manager.init_seed(_derive_seed("npc_manager"))
	tarot_card.init_seed(_derive_seed("tarot_card"))
	tarot_rarity.init_seed(_derive_seed("tarot_rarity"))
	tarot_orientation.init_seed(_derive_seed("tarot_orientation"))
	if OS.is_debug_build():
			print("Global RNG Seed: ", seed)

func get_rng() -> RandomNumberGenerator:
	return global.get_rng()

func reseed_with_unix_time() -> void:
	init_seed(Time.get_unix_time_from_system())
	PlayerManager.user_data["global_rng_seed"] = seed

func shuffle(arr: Array) -> void:
	global.shuffle(arr)


func get_save_data() -> Dictionary:
	var data := {}
	for stream_name in streams.keys():
		data[stream_name] = streams[stream_name].get_state()
	return data

func load_from_data(data: Dictionary) -> void:
	for stream_name in streams.keys():
		var stream: RNGStream = streams[stream_name]
		stream.set_state(data.get(stream_name, stream.seed))
