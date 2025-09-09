extends RefCounted
# Autoload NumberFormatter

const SHORT_UNITS: Array[String] = ["", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc"]
const LONG_UNITS: Array[String] = [
	"", "Thousand", "Million", "Billion", "Trillion",
	"Quadrillion", "Quintillion", "Sextillion", "Septillion", "Octillion"
]

# Add commas: 1,234,567.89
static func format_commas(number: float, decimals: int = 2, hide_trailing_zeroes: bool = false) -> String:
	var effective_decimals: int = decimals
	if abs(number) >= 1000.0:
		effective_decimals = 0

	var s: String = "%.*f" % [effective_decimals, number]
	var parts: PackedStringArray = s.split(".")
	var int_part: String = parts[0]
	var frac_part: String = ""
	if parts.size() > 1:
		frac_part = parts[1]
	var sign: String = ""

	if int_part.begins_with("-"):
		sign = "-"
		int_part = int_part.substr(1)

	var out_str: String = ""
	while int_part.length() > 3:
		out_str = "," + int_part.right(3) + out_str
		int_part = int_part.left(int_part.length() - 3)
	out_str = int_part + out_str

	if effective_decimals > 0:
		if hide_trailing_zeroes:
			var frac_trimmed: String = frac_part.rstrip("0")
			if frac_trimmed == "":
				return sign + out_str
			return sign + out_str + "." + frac_trimmed
		else:
			return sign + out_str + "." + frac_part

	return sign + out_str

# Short text: 4.2M, 9.8T
static func format_short(number: float, decimals: int = 2) -> String:
	var n: float = abs(number)
	var sign: String = ""
	if number < 0.0:
		sign = "-"

	if n < 1000.0:
		return "%s%.*f" % [sign, decimals, n]

	var idx: int = 0
	while n >= 1000.0 and idx < SHORT_UNITS.size() - 1:
		n /= 1000.0
		idx += 1

	return "%s%.*f%s" % [sign, decimals, n, SHORT_UNITS[idx]]

# Long text: 2.1 Million
static func format_long(number: float, decimals: int = 2) -> String:
	var n: float = abs(number)
	var sign: String = ""
	if number < 0.0:
		sign = "-"

	if n < 1000.0:
		return "%s%.*f" % [sign, decimals, n]

	var idx: int = 0
	while n >= 1000.0 and idx < LONG_UNITS.size() - 1:
		n /= 1000.0
		idx += 1

	return "%s%.*f %s" % [sign, decimals, n, LONG_UNITS[idx]]

# Scientific: 6.02e23
static func format_sci(number: float, decimals: int = 2) -> String:
	if number == 0.0:
		return "0"
	var sign: String = ""
	if number < 0.0:
		sign = "-"

	var n: float = abs(number)
	var exponent: int = int(floor(log(n) / log(10.0)))
	var mantissa: float = n / pow(10.0, float(exponent))
	return "%s%.*fe%d" % [sign, decimals, mantissa, exponent]

# Mantissa/exponent formatting helpers for FlexNumber
static func format_mantissa_exponent(mantissa: float, exponent: int, decimals: int = 2) -> String:
	return "%.*fe%d" % [decimals, mantissa, exponent]

static func format_flex(number: FlexNumber, decimals: int = 2, style: String = "commas") -> String:
	if number.is_big():
		return format_mantissa_exponent(number._mantissa, number._exponent, decimals)
	return format_number(number.to_float(), style, decimals)

# Main interface (now static so it can be called from static helpers)
static func format_number(number: Variant, style: String = "commas", decimals: int = 2) -> String:
	if number is FlexNumber:
		return format_flex(number, decimals, style)

	match style:
		"commas":
			return format_commas(float(number), decimals)
		"short":
			return format_short(float(number), decimals)
		"long":
			return format_long(float(number), decimals)
		"sci", "scientific":
			return format_sci(float(number), decimals)
		_:
			return str(number)
