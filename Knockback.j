library Knockback
	globals
		public real FRICTION = 1300
		private unit array arrUnits
		private real array arrVel
		private real array arrAngle
		private integer count = 0
		// Global variable for update callback
		private boolean collisionFound = false
	endglobals

	function KnockbackUnitPolar takes unit u, real distance, real angle returns nothing
		local integer i = 0
		local real v0 = SquareRoot(2 * distance * FRICTION) // Real physics!!!
		// Check if it is even possible to knock this unit back
		if IsUnitType(u, UNIT_TYPE_STRUCTURE) or GetUnitDefaultMoveSpeed(u) == 0 then
			return
		endif
		// Check if unit is already being knocked back
		loop
			exitwhen i == count
			if u == arrUnits[i] then
				exitwhen true
			endif
			set i = i + 1
		endloop
		set arrUnits[i] = u
		set arrVel[i] = v0
		set arrAngle[i] = angle * bj_DEGTORAD
		if i == count then
			set count = count + 1
		endif
	endfunction

	private function CallbackUpdate takes nothing returns nothing
		set collisionFound = true
	endfunction

	public function Update takes real dt returns nothing
		local unit u
		local location loc
		local real x
		local real y
		local boolean clearing = true
		local integer i = count - 1
		loop
			set u = arrUnits[i]
			exitwhen i < 0
			if clearing and arrVel[i] <= 0 then
				set count = count - 1
			else
				set clearing = false
				set x = GetUnitX(u) + arrVel[i] * Cos(arrAngle[i]) * dt
				set y = GetUnitY(u) + arrVel[i] * Sin(arrAngle[i]) * dt
				if IsTerrainPathable(x, y, PATHING_TYPE_WALKABILITY) then
					set collisionFound = true
				else
					set loc = Location(x, y)
					call EnumDestructablesInCircleBJ(64.0 + BlzGetUnitCollisionSize(u), loc, function CallbackUpdate)
					call RemoveLocation(loc)
				endif
				if collisionFound then
					set arrVel[i] = arrVel[i] / 2
					set collisionFound = false // Reset global variable
				else
					call SetUnitX(u, x)
					call SetUnitY(u, y)
				endif
				set arrVel[i] = arrVel[i] - FRICTION * dt
				// Make unit move slower while knocked back
				call SetUnitMoveSpeed(u, GetUnitDefaultMoveSpeed(u) - RAbsBJ(arrVel[i]))
			endif
			set i = i - 1
		endloop
		set loc = null
		set u = null
	endfunction
endlibrary
