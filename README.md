# SigmaSim

## Data Serialization

 - `StatManager` saves `FlexNumber` stats as dictionaries using the schema `{mantissa: float, exponent: int}` so even extremely large values serialize and deserialize automatically.
- `SaveManager` sanitizes non‑finite numbers before writing JSON, replacing `NaN` with `null` and clamping infinities to a large finite value.

