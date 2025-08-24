# Big-number with fast mantissa/exponent and cheap merges.
# Prioritizes throughput: caches small powers of 10, jumps normalization with log()
# (converted to base-10), and ignores work when exponent gaps are large.
class_name FlexNumber

# === Tunables ===
const THRESHOLD: float = 1_000_000_000.0
const EXP_DIFF_CUTOFF: int = 12

# Extend cache to reduce pow() calls meaningfully without memory bloat.
# Range covers [-32, +32] -> 65 entries
const POW10_BIAS: int = 32
const POW10: Array[float] = [
	1e-32, 1e-31, 1e-30, 1e-29, 1e-28, 1e-27, 1e-26, 1e-25, 1e-24, 1e-23,
	1e-22, 1e-21, 1e-20, 1e-19, 1e-18, 1e-17, 1e-16, 1e-15, 1e-14, 1e-13,
	1e-12, 1e-11, 1e-10, 1e-9,  1e-8,  1e-7,  1e-6,  1e-5,  1e-4,  1e-3,
	1e-2,  1e-1,  1.0,
	1e1,   1e2,   1e3,   1e4,   1e5,   1e6,   1e7,   1e8,   1e9,   1e10,
	1e11,  1e12,  1e13,  1e14,  1e15,  1e16,  1e17,  1e18,  1e19,  1e20,
	1e21,  1e22,  1e23,  1e24,  1e25,  1e26,  1e27,  1e28,  1e29,  1e30,
	1e31,  1e32
]

static func _fast_pow10(k: int) -> float:
	var idx: int = k + POW10_BIAS
	if idx >= 0 and idx < POW10.size():
		return POW10[idx]
	return pow(10.0, float(k))

static func _decompose(value: float) -> Array:
	# Returns [mantissa: float, exponent: int] with mantissa in [1,10) or (-10,-1], except 0.
	var m: float = value
	var e: int = 0
	if m == 0.0:
		return [0.0, 0]
	var am: float = absf(m)

	# If way outside range, jump using base-10 log to reduce loops to O(1).
	if am >= 1_000_000.0 or am <= 0.000001:
		var ge: float = floor(log(am) / log(10.0))
		e = int(ge)
		m = m / _fast_pow10(e)
		am = absf(m)

	# Finish with tiny integer steps to land in [1,10)
	while am >= 10.0:
		m *= 0.1
		e += 1
		am = absf(m)
	while am < 1.0:
		m *= 10.0
		e -= 1
		am = absf(m)
	return [m, e]

static func _compose(m: float, e: int) -> float:
	# Compose mantissa/exponent, using cache when possible.
	return m * _fast_pow10(e)

var _is_big: bool = false
var _value: float = 0.0
var _mantissa: float = 0.0  # In [1,10) or (-10,-1], except zero
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
		var pair: Array = _decompose(v)
		_mantissa = pair[0]
		_exponent = int(pair[1])
	else:
		_is_big = false
		_value = v

func is_big() -> bool:
	return _is_big

func to_float() -> float:
	if _is_big:
		return _compose(_mantissa, _exponent)
	return _value

func add(amount: float) -> void:
	if amount == 0.0:
		return

	# Small self: stay small if possible
	if not _is_big:
		var v: float = _value + amount
		if v != 0.0 and absf(v) >= THRESHOLD:
			_is_big = true
			var pair_promote: Array = _decompose(v)
			_mantissa = pair_promote[0]
			_exponent = int(pair_promote[1])
		else:
			_value = v
		return

	# Big self: merge efficiently
	var aabs: float = absf(amount)
	if aabs < THRESHOLD:
		# Scale small addend into current exponent domain: m += amount / 10^e
		_mantissa += amount / _fast_pow10(_exponent)
		_normalize()
		return

	# Big addend: decompose once
	var other: Array = _decompose(amount)
	var m_other: float = other[0]
	var e_other: int = int(other[1])

	var diff: int = _exponent - e_other
	if diff >= EXP_DIFF_CUTOFF:
		return  # other is negligible
	if diff <= -EXP_DIFF_CUTOFF:
		_mantissa = m_other
		_exponent = e_other
		return

	# Close enough: m += m_other * 10^{-diff}
	_mantissa += m_other * _fast_pow10(-diff)
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
			var pair_promote: Array = _decompose(v)
			_mantissa = pair_promote[0]
			_exponent = int(pair_promote[1])
		else:
			_value = v
		return

	# Big self:
	var aabs: float = absf(amount)
	if aabs < THRESHOLD:
		# Scale mantissa only; normalization is cheap
		_mantissa *= amount
		_normalize()
		return

	# Big factor: decompose to avoid huge loops
	var other: Array = _decompose(amount)
	_mantissa *= other[0]
	_exponent += int(other[1])
	_normalize()

func _normalize() -> void:
	if not _is_big:
		return

	var am: float = absf(_mantissa)
	if am == 0.0:
		_is_big = false
		_value = 0.0
		return

	# Jump if way out of range using base-10 log via natural log conversion
	if am >= 1_000_000.0 or am <= 0.000001:
		var ge: float = floor(log(am) / log(10.0))
		var shift: int = int(ge)
		if shift != 0:
			_mantissa = _mantissa / _fast_pow10(shift)
			_exponent += shift
			am = absf(_mantissa)

	# Finish with tiny integer steps
	while am >= 10.0:
		_mantissa *= 0.1
		_exponent += 1
		am = absf(_mantissa)
	while am < 1.0:
		_mantissa *= 10.0
		_exponent -= 1
		am = absf(_mantissa)

	# Demotion: safe because normalized |mantissa| < 10 and exponent <= 8 implies |value| < 1e9
	if _exponent <= 8:
		_is_big = false
		_value = _compose(_mantissa, _exponent)
