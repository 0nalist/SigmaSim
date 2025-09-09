extends Node
#class_name NumberFormatter

const SHORT_UNITS = ["", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc"]
const LONG_UNITS = [
	"", "Thousand", "Million", "Billion", "Trillion",
	"Quadrillion", "Quintillion", "Sextillion", "Septillion", "Octillion"
]

# Add commas: 1,234,567.89
func format_commas(number: float, decimals: int = 2, hide_trailing_zeroes: bool = false) -> String:
	if abs(number) >= 1000:
		decimals = 0
	var s = "%.*f" % [decimals, number]
	var int_part = s.split(".")[0]
	var frac_part = ""
	if decimals > 0:
		frac_part = s.split(".")[1]
	var sign = ""
	if int_part.begins_with("-"):
		sign = "-"
		int_part = int_part.substr(1)
	var out = ""
	while int_part.length() > 3:
		out = "," + int_part.right(3) + out
		int_part = int_part.left(int_part.length() - 3)
	out = int_part + out
	if decimals > 0:
		var frac_trimmed = frac_part.rstrip("0")
		if hide_trailing_zeroes:
			if frac_trimmed == "":
				return sign + out
			return sign + out + "." + frac_trimmed
		else:
			return sign + out + "." + frac_part
	return sign + out




# Short text: 4.2M, 9.8T
static func format_short(number: float, decimals: int = 2) -> String:
	var n = abs(number)
	var sign = "-" if number < 0 else ""
	if n < 1_000:
		return "%s%.*f" % [sign, decimals, n]
	var idx = 0
	while n >= 1_000 and idx < SHORT_UNITS.size() - 1:
		n /= 1_000.0
		idx += 1
	return "%s%.*f%s" % [sign, decimals, n, SHORT_UNITS[idx]]

# Long text: 2.1 Million
static func format_long(number: float, decimals: int = 2) -> String:
	var n = abs(number)
	var sign = "-" if number < 0 else ""
	if n < 1_000:
		return "%s%.*f" % [sign, decimals, n]
	var idx = 0
	while n >= 1_000 and idx < LONG_UNITS.size() - 1:
		n /= 1_000.0
		idx += 1
	return "%s%.*f %s" % [sign, decimals, n, LONG_UNITS[idx]]

# Scientific: 6.02e23
static func format_sci(number: float, decimals: int = 2) -> String:
	if number == 0:
		return "0"
	var sign = "-" if number < 0 else ""
	var n = abs(number)
	var exponent = int(floor(log(n) / log(10)))
	var mantissa = n / pow(10, exponent)
	return "%s%.*fe%d" % [sign, decimals, mantissa, exponent]

# Mantissa/exponent formatting helpers for FlexNumber
static func format_mantissa_exponent(mantissa: float, exponent: int, decimals: int = 2) -> String:
	return "%.*fe%d" % [decimals, mantissa, exponent]

static func format_flex(number: FlexNumber, decimals: int = 2, style: String = "commas") -> String:
	if number.is_big():
		return format_mantissa_exponent(number._mantissa, number._exponent, decimals)
	return format_number(number.to_float(), style, decimals)

# Main interface
func format_number(number: Variant, style: String = "commas", decimals: int = 2) -> String:
        if number is FlexNumber:
                return format_flex(number, decimals, style)
        match style:
                "commas":
                        return format_commas(number, decimals)
                "short":
                        return format_short(number, decimals)
                "long":
                        return format_long(number, decimals)
                "sci", "scientific":
                        return format_sci(number, decimals)
                _:
                        return str(number)

# Smart format: commas below 1B, scientific above
func smart_format(number: Variant, decimals: int = 2, hide_trailing_zeroes: bool = false) -> String:
        if number is FlexNumber:
                if number.is_big():
                        return format_mantissa_exponent(number._mantissa, number._exponent, decimals)
                number = number.to_float()
        var n: float = float(number)
        if abs(n) >= 1_000_000_000.0:
                return format_sci(n, decimals)
        return format_commas(n, decimals, hide_trailing_zeroes)
