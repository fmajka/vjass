library Projectile requires Combat
	globals
		public integer id
		public unit source
		public unit target
		private group collideGroup = CreateGroup()
		// Projectile type properties
		private integer COUNT = 0
		public string array PATH
		public real array Z
		public real array DISTANCE
		public real array SPEED
		public real array RADIUS
		public boolexpr array FILTER
		public integer array HIT_COUNT
		public boolean array IS_PROJECTILE // false used for the source unit dashing
		public boolean array TRIGGER_UPDATE_EVENT // set udg_Projectile_EventUpdate on every tick
		// Projectile instance properties
		private integer count = 0
		public integer array arrType
		public real array arrX
		public real array arrY
		public real array arrAngle
		public real array arrDistance
		public effect array arrFx
		public unit array arrSource
		public group array arrHitGroup
		public boolean array arrDone
	endglobals

	function InitProjectile takes string path, real z, real dist, real speed, real r, boolexpr filter, integer hitCount returns integer
		local integer i = COUNT
		set PATH[i] = path
		set Z[i] = z
		set DISTANCE[i] = dist
		set SPEED[i] = speed
		set RADIUS[i] = r
		set FILTER[i] = filter
		set HIT_COUNT[i] = hitCount
		set IS_PROJECTILE[i] = true
		set TRIGGER_UPDATE_EVENT[i] = false
		set COUNT = COUNT + 1
		return i
	endfunction

	// Makes the casting unit dash instead of creating a projectile
	// Doesn't use some of the properties
	function InitDash takes real dist, real speed, real r, boolexpr filter, integer hitCount returns integer
		local integer i = COUNT
		set DISTANCE[i] = dist
		set SPEED[i] = speed
		set RADIUS[i] = r
		set FILTER[i] = filter
		set HIT_COUNT[i] = hitCount
		set IS_PROJECTILE[i] = false
		set TRIGGER_UPDATE_EVENT[i] = false
		set COUNT = COUNT + 1
		return i
	endfunction

	// Creates a new projectile of specified type on source unit's position
	// Returns the created projectile's ID (array index)
	function UnitSpawnProjectile takes unit source, integer projType, real angle returns integer
		local integer i = count
		local real x = GetUnitX(source)
		local real y = GetUnitY(source)
		local real rad = bj_DEGTORAD * angle
		set arrType[i] = projType
		set arrX[i] = x
		set arrY[i] = y
		set arrAngle[i] = rad
		set arrDistance[i] = DISTANCE[projType]
		set arrFx[i] = AddSpecialEffect(PATH[projType], x, y)
		//call BlzSetSpecialEffectPosition(arrFx[i], x, y, Z[projType])
		call BlzSetSpecialEffectRoll(arrFx[i], rad + bj_PI)
		set arrSource[i] = source
		set arrHitGroup[i] = CreateGroup()
		set arrDone[i] = false
		set count = count + 1
		return i
	endfunction

	// Makes the source unit dash (could say that it turns into a projectile)
	function UnitDash takes unit source, integer dashType, real angle returns integer
		local integer i = count
		local real x = GetUnitX(source)
		local real y = GetUnitY(source)
		local real rad = bj_DEGTORAD * angle
		set arrType[i] = dashType
		set arrX[i] = x
		set arrY[i] = y
		set arrAngle[i] = rad
		set arrDistance[i] = DISTANCE[dashType]
		set arrSource[i] = source
		set arrHitGroup[i] = CreateGroup()
		set arrDone[i] = false
		set count = count + 1
		return i
	endfunction

	public function GetHitsRemaining takes integer index returns integer
		return HIT_COUNT[arrType[index]] - CountUnitsInGroup(arrHitGroup[index])
	endfunction

	public function Update takes real dt returns nothing
		local integer i = count - 1
		local integer projType
		local real dist
		local location loc
		local unit u
		local boolean clearing = true
		loop
			exitwhen i < 0
			set projType = arrType[i]
			// Set globals
			set id = i
			set source = arrSource[i]
			set udg_Projectile_Type = projType
			// Check if projectile is still going
			if arrDistance[i] <= 0 or GetHitsRemaining(i) == 0 then
				if not arrDone[i] then
					set arrDone[i] = true
					set udg_Projectile_EventDone = 1
					set udg_Projectile_EventDone = 0
					if IS_PROJECTILE[projType] then
						call DestroyEffect(arrFx[i])
					endif
				endif
				// Clear unused projectiles at the end of the array
				if clearing then
					set count = count - 1
					call DestroyGroup(arrHitGroup[i])
				endif
			else
				// Update projectile
				set clearing = false
				set dist = SPEED[projType] * dt
				// Updat event hook
				if TRIGGER_UPDATE_EVENT[projType] then
					set udg_Projectile_EventUpdate = 1
					set udg_Projectile_EventUpdate = 0
				endif
				// Move
				if IS_PROJECTILE[projType] then
					set arrX[i] = arrX[i] + dist * Cos(arrAngle[i])
					set arrY[i] = arrY[i] + dist * Sin(arrAngle[i])
					set loc = Location(arrX[i], arrY[i]) // Used for getting ground height
					call BlzSetSpecialEffectPosition(arrFx[i], arrX[i], arrY[i], GetLocationZ(loc) + Z[projType])
					call RemoveLocation(loc)
				else
					set arrX[i] = GetUnitX(source) + dist * Cos(arrAngle[i])
					set arrY[i] = GetUnitY(source) + dist * Sin(arrAngle[i])
					call SetUnitPosition(arrSource[i], arrX[i], arrY[i]) // Respects collision
				endif
				set arrDistance[i] = arrDistance[i] - dist
				// Collide
				call GetInRangePlayerMatching(collideGroup, arrX[i], arrY[i], RADIUS[projType], GetOwningPlayer(source), FILTER[projType])
				loop
					exitwhen CountUnitsInGroup(collideGroup) == 0 or GetHitsRemaining(i) == 0
					set u = GroupGetNearestXY(collideGroup, arrX[i], arrY[i])
					call GroupRemoveUnit(collideGroup, u)
					if not IsUnitInGroup(u, arrHitGroup[i]) then
						set target = u
						call GroupAddUnit(arrHitGroup[i], u)
						set udg_Projectile_EventHit = 1
						set udg_Projectile_EventHit = 0
					endif
				endloop
				call GroupClear(collideGroup)
			endif
			set i = i - 1
		endloop
		set u = null
	endfunction
endlibrary