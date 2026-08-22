library Utils initializer Init
	globals
		integer array PLAYER_RED
		integer array PLAYER_GREEN
		integer array PLAYER_BLUE
	endglobals

	private function InitColor takes integer id, real r, real g, real b returns nothing
		set PLAYER_RED[id] = r
		set PLAYER_GREEN[id] = g
		set PLAYER_BLUE[id] = b
	endfunction

	private function Init takes nothing returns nothing
		call InitColor(0, 255, 3, 3)
		call InitColor(1, 0, 66, 255)
		call InitColor(2, 28, 230, 185)
		call InitColor(3, 84, 0, 129)
		call InitColor(4, 255, 252, 0)
		call InitColor(5, 254, 138, 14)
		call InitColor(6, 32, 192, 0)
		call InitColor(7, 229, 91, 176)
		call InitColor(8, 149, 150, 151)
		call InitColor(9, 126, 191, 241)
		call InitColor(10, 16, 98, 70)
		call InitColor(11, 78, 42, 3)
		call InitColor(12, 155, 0, 0)
		call InitColor(13, 0, 0, 195)
		call InitColor(14, 0, 234, 255)
		call InitColor(15, 190, 0, 254)
		call InitColor(16, 235, 205, 135)
		call InitColor(17, 248, 164, 139)
		call InitColor(18, 191, 255, 128)
		call InitColor(19, 220, 185, 235)
		call InitColor(20, 80, 79, 85)
		call InitColor(21, 235, 240, 255)
		call InitColor(22, 0, 120, 30)
		call InitColor(23, 164, 111, 51)
	endfunction

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

	//////////////////////
	// MATH API HELPERS //
	//////////////////////

	function DistanceBetweenUnits takes unit a, unit b returns real
		local real xDiff = GetUnitX(b) - GetUnitX(a)
		local real yDiff = GetUnitY(b) - GetUnitY(a)
		return SquareRoot(xDiff*xDiff + yDiff*yDiff)
	endfunction

	function DistanceBetweenXY takes real x1, real y1, real x2, real y2 returns real
		local real xDiff = x2 - x1
		local real yDiff = y2 - y1
		return SquareRoot(xDiff*xDiff + yDiff*yDiff)
	endfunction

	function AngleBetweenUnits takes unit a, unit b returns real
		local real xDiff = GetUnitX(b) - GetUnitX(a)
		local real yDiff = GetUnitY(b) - GetUnitY(a)
		return bj_RADTODEG * Atan2(yDiff, xDiff)
	endfunction

	function AngleBetweenXY takes real x1, real y1, real x2, real y2 returns real
		local real xDiff = x2 - x1
		local real yDiff = y2 - y1
		return bj_RADTODEG * Atan2(yDiff, xDiff)
	endfunction

endlibrary