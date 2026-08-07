class_name WorldScale
extends RefCounted

## Canonical conversion source for real-world metric values in the compressed world.
const METERS_PER_UNIT: float = 45.0
const LEGACY_METERS_PER_UNIT: float = 42.07
const LEGACY_TO_CURRENT: float = 42.07 / 45.0

## Converts a real-world distance in metres to current world units.
static func meters_to_units(meters: float) -> float:
	return meters / METERS_PER_UNIT

## Preserves a value authored in legacy world units when it represents metres.
static func legacy_units_to_current(legacy_units: float) -> float:
	return legacy_units * LEGACY_TO_CURRENT
