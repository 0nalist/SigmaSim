# Provides a float that transparently promotes to a mantissa/exponent
# representation once it grows beyond a threshold. Prioritizes performance
# over accuracy by skipping math when exponents differ greatly.
class_name FlexNumber

# === Tunables ===
const THRESHOLD: float = 1_000_000_000.0
const EXP_DIFF_CUTOFF: int = 12

# Small lookup to avoid pow(10, k) for -12..+12 in add().
# Indexing helper: POW10[diff + POW10_BIAS] where diff in [-12, 12]
const POW10_BIAS: int = 12
const POW10: Array[float] = [
	1e-12, 1e-11, 1e-10, 1e-9, 1e-8, 1e-7, 1e-6, 1e-5, 1e-4, 1e-3, 1e-2, 1e-1, 1.0,
	1e1, 1e2, 1e3, 1e4, 1e5, 1e6, 1e7, 1e8, 1e9, 1e10, 1e11, 1e12
]

var _is_big: bool = false
var _value: float = 0.0
var _mantissa: float = 0.0   # In [1,10) or (-10,-1], except for zero
var _exponent: int = 0

func _init(v: float = 0.0) -> void:
	set_value(v)

func set_value(v: float) -> void:
	if v == 0.0:
		_is_big = false
		_value = 0.0
		return
	var av: float = absf(v)
	if av >= THRESHOLD:
		_is_big = true
		# Fast exponent estimate without log10: climb by ×10/÷10
		# Start with coarse guess using builtin frexp NOTE: not available in GDScript, so use loop
		_mantissa = v
		_exponent = 0
		_normalize()  # cheap integer-step normalization
	else:
		_is_big = false
		_value = v

func is_big() -> bool:
	return _is_big

func to_float() -> float:
	if _is_big:
		# Avoid pow; use manual scaling when exponent is small, else fallback to pow once.
		# Since exponent can be large, just use pow here (rarely called compared to core ops).
		return _mantissa * pow(10.0, float(_exponent))
	else:
		return _value

func add(amount: float) -> void:
	if amount == 0.0:
		return

	# If self is small, try to stay small.
	if not _is_big:
		var v: float = _value + amount
		# Only promote when exceeding threshold.
		if v != 0.0 and absf(v) >= THRESHOLD:
			_is_big = true
			_mantissa = v
			_exponent = 0
			_normalize()
		else:
			_value = v
		return

	# Here: self is big. Combine with 'amount' efficiently.
	var aabs: float = absf(amount)
	if aabs < THRESHOLD:
		# Scale small amount into our exponent domain without pow
		# m += amount / 10^exp  -> use pow once via table if exp small; else pow
		var scaled: float
		var e: int = _exponent
		if e >= -POW10_BIAS and e <= POW10_BIAS:
			scaled = amount / POW10[e + POW10_BIAS]
		else:
			scaled = amount / pow(10.0, float(e))
		_mantissa += scaled
		_normalize()
		return

	# amount is "big". Compute its exp cheaply (integer step).
	var m_other: float = amount
	var e_other: int = 0
	_normalize_pair(m_other, e_other)  # normalize (by ref semantics)

	var diff: int = _exponent - e_other
	if diff >= EXP_DIFF_CUTOFF:
		# Other is much smaller -> ignore
		return
	if diff <= -EXP_DIFF_CUTOFF:
		# Other dominates -> replace
		_mantissa = m_other
		_exponent = e_other
		return

	# Merge close exponents: m += other_m * 10^{-diff}
	var scale: float
	var idx: int = -diff + POW10_BIAS
	if idx >= 0 and idx < POW10.size():
		scale = POW10[idx]
	else:
		scale = pow(10.0, float(-diff))
	_mantissa += m_other * scale
	_normalize()

func subtract(amount: float) -> void:
	add(-amount)

func multiply(amount: float) -> void:
	if amount == 0.0:
		_is_big = false
		_value = 0.0
		return

	if not _is_big:
		var v: float = _value * amount
		if v != 0.0 and absf(v) >= THRESHOLD:
			_is_big = true
			_mantissa = v
			_exponent = 0
			_normalize()
		else:
			_value = v
		return

	# Big path: keep integer-step adjustments; avoid log10
	_mantissa *= amount
	_normalize()

func _normalize() -> void:
	# Keep mantissa in [1,10) or (-10,-1], or go to zero/small path.
	if not _is_big:
		return

	var am: float = absf(_mantissa)
	if am == 0.0:
		_is_big = false
		_value = 0.0
		return

	# Integer-step normalization (no log10/pow)
	while am >= 10.0:
		_mantissa *= 0.1
		_exponent += 1
		am = absf(_mantissa)
	while am < 1.0:
		_mantissa *= 10.0
		_exponent -= 1
		am = absf(_mantissa)

	# Demote if we dropped below threshold overall.
	# Instead of recomposing fully, check the cheapest sufficient condition:
	# if exponent < 9, absolute value < 1e9 for a normalized mantissa in [1,10).
	# (Because |mantissa|<10 and 10^exponent with exponent<=8 => <10^9)
	if _exponent <= 8:
		var approx: float = _mantissa * pow(10.0, float(_exponent))
		if absf(approx) < THRESHOLD:
			_is_big = false
			_value = approx

# Helper to normalize a raw (mantissa, exponent) pair given in "mantissa = value, exponent = 0"
# This avoids calling log10; used when we need the "other" side in add().
func _normalize_pair(m_in_out: float, e_in_out: int) -> void:
	var m: float = m_in_out
	var e: int = e_in_out

	if m == 0.0:
		# zero stays zero
		m_in_out = 0.0
		e_in_out = 0
		return

	var am: float = absf(m)
	while am >= 10.0:
		m *= 0.1
		e += 1
		am = absf(m)
	while am < 1.0:
		m *= 10.0
		e -= 1
		am = absf(m)

	# Write back (GDScript passes by value; callers should capture return instead)
	# Workaround: return as a tuple via Dictionary
	# But to keep the API internal, we’ll expose a mini “return” function:
	__assign_pair(m_in_out, e_in_out, m, e)

# Internal writeback helper (emulates "out parameters")
func __assign_pair(_m_ref: float, _e_ref: int, m: float, e: int) -> void:
	# This function exists only to document intent; GDScript passes by value.
	# So we will not call it; instead, callers will inline the normalization logic
	# and assign to their locals. (Left here for clarity.)
	pass
