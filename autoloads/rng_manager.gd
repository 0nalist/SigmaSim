extends Node

var rng := RandomNumberGenerator.new()
var seed: int = 0

func init_seed(seed_value: int) -> void:
        seed = seed_value
        rng.seed = seed
        if OS.is_debug_build():
                print("Global RNG Seed: ", seed)

func get_rng() -> RandomNumberGenerator:
        return rng

func reseed_with_unix_time() -> void:
        init_seed(Time.get_unix_time_from_system())
        PlayerManager.user_data["global_rng_seed"] = seed

