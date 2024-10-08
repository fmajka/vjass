library Utils

	// Round real to integer
	function R2IR takes real r returns integer
		return R2I(r + 0.5)
	endfunction

	// Converts boolean to a "true" / "false" string
	function B2S takes boolean b returns string
		if b then
			return "true"
		else
			return "false"
		endif
	endfunction

	// Get unit percentage hp within as a range [0-1]
	function GetUnitHpRatio takes unit u returns real
		return GetUnitState(u, UNIT_STATE_LIFE) / GetUnitState(u, UNIT_STATE_MAX_LIFE)
	endfunction

	// Polar projection of x, y coordinates to a new location
	function PolarProjectionXY takes real x, real y, real radius, real deg returns location
		local real rad = deg * bj_DEGTORAD
		return Location(x + radius * Cos(rad), y + radius * Sin(rad))
	endfunction

	function UnitInventoryFull takes unit u returns boolean
		return UnitInventorySize(u) <= UnitInventoryCount(u)
	endfunction

	function IsDay takes nothing returns boolean
		local real t = GetTimeOfDay()
		return t >= 6.00 and t < 18.00
	endfunction

	function IsNight takes nothing returns boolean
		local real t = GetTimeOfDay()
		return t < 6.00 or t >= 18.00
	endfunction

	// Creates and immediatelly destroys effect
	function FlashEffect takes string path, real x, real y returns nothing
		call DestroyEffect(AddSpecialEffect(path, x, y))
	endfunction

	// Creates and immediatelly destroys effect attached to a target
	function FlashEffectTarget takes string path, unit target, string attachment returns nothing
		call DestroyEffect(AddSpecialEffectTarget(path, target, attachment))
	endfunction

endlibrary