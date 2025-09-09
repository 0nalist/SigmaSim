# SigmaSim

## Data Serialization

- `StatManager` now saves `FlexNumber` values as `{mantissa, exponent}` dictionaries to preserve extremely large numbers.
- `SaveManager` sanitizes non‑finite numbers before writing JSON, replacing `NaN` with `null` and clamping infinities to a large finite value.

