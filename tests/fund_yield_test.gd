extends SceneTree

func _ready() -> void:
	var fund := Fund.new()
	fund.expected_return = 10.0
	fund.variability = 0.0
	var result := fund.simulate_yield(100.0)
	assert(is_equal_approx(result, 110.0))

	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	fund.variability = 5.0
	var res_var := fund.simulate_yield(100.0, {}, rng)
	var min_val := 100.0 * (1.0 + (fund.expected_return - fund.variability) / 100.0)
	var max_val := 100.0 * (1.0 + (fund.expected_return + fund.variability) / 100.0)
	assert(res_var >= min_val - 0.0001 and res_var <= max_val + 0.0001)

	var index_fund := Fund.new()
	index_fund.index_fund = true
	index_fund.index_assets = {"AAA": 1, "BBB": 1}
	var idx_res := index_fund.simulate_yield(100.0, {"AAA": 10.0, "BBB": 20.0})
	assert(is_equal_approx(idx_res, 115.0))

	print("fund_yield_test passed")
	quit()
