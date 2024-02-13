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

endlibrary