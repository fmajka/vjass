library Utils initializer Init
	globals
		integer array PLAYER_RED
		integer array PLAYER_GREEN
		integer array PLAYER_BLUE
	endglobals

	private function Init takes nothing returns nothing
		//! textmacro InitColor takes ID, RED, GREEN, BLUE
		set PLAYER_RED[$ID$] = $RED$
		set PLAYER_GREEN[$ID$] = $GREEN$
		set PLAYER_BLUE[$ID$] = $BLUE$
		//! endtextmacro
		//! runtextmacro InitColor("0", "255", "3", "3")
		//! runtextmacro InitColor("1", "0", "66", "255")
		//! runtextmacro InitColor("2", "28", "230", "185")
		//! runtextmacro InitColor("3", "84", "0", "129")
		//! runtextmacro InitColor("4", "255", "252", "0")
		//! runtextmacro InitColor("5", "254", "138", "14")
		//! runtextmacro InitColor("6", "32", "192", "0")
		//! runtextmacro InitColor("7", "229", "91", "176")
		//! runtextmacro InitColor("8", "149", "150", "151")
		//! runtextmacro InitColor("9", "126", "191", "241")
		//! runtextmacro InitColor("10", "16", "98", "70")
		//! runtextmacro InitColor("11", "78", "42", "3")
		//! runtextmacro InitColor("12", "155", "0", "0")
		//! runtextmacro InitColor("13", "0", "0", "195")
		//! runtextmacro InitColor("14", "0", "234", "255")
		//! runtextmacro InitColor("15", "190", "0", "254")
		//! runtextmacro InitColor("16", "235", "205", "135")
		//! runtextmacro InitColor("17", "248", "164", "139")
		//! runtextmacro InitColor("18", "191", "255", "128")
		//! runtextmacro InitColor("19", "220", "185", "235")
		//! runtextmacro InitColor("20", "80", "79", "85")
		//! runtextmacro InitColor("21", "235", "240", "255")
		//! runtextmacro InitColor("22", "0", "120", "30")
		//! runtextmacro InitColor("23", "164", "111", "51")
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

endlibrary