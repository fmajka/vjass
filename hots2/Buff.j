// 2026-08-08: Rewritten to be MUI and support multiple buff levels at the same time
library Buff initializer Init requires Dummy, Hots

	globals
		private hashtable mHash = InitHashtable()

		public unit array mArrUnit
		public integer array mArrBuffType
		public integer array mArrLevel
		public real array mArrTime
		public integer mCount = 0

		private integer array ARR_BUFF_ID
		private integer array ARR_DUMMY_ABILITY
		private string array ARR_ORDER
		private integer BUFF_COUNT = 0

		// FireLevelChangedEvent
		public real mLevelChangedEventState = 0.0
		public unit eLevelChangedUnit
		public integer eLevelChangedBuffType
		public integer eLevelChangedPrevLevel
		public integer eLevelChangedLevel
	endglobals

	// Registers new buff type with corresponding dummy ability and cast order and returns its buffType
	public function RegisterBuff takes integer buffId, integer dummyAbility, string order returns integer
		integer id = BUFF_COUNT
		set ARR_BUFF_ID[id] = buffId
		set ARR_DUMMY_ABILITY[id] = dummyAbility
		set ARR_ORDER[id] = order
		set BUFF_COUNT = BUFF_COUNT + 1
		return id
	endfunction

	// TODO: use Loop.j to set regen effect
	private function FireLevelChangedEvent takes unit u, integer buffType, integer prevLevel, integer level returns nothing
		set eLevelChangedUnit = u
		set eLevelChangedBuffType = buffType
		set eLevelChangedPrevLevel = prevLevel
		set eLevelChangedLevel = level
		set mLevelChangedEventState = 1.0
		set mLevelChangedEventState = 0.0
	endfunction

	// Loops through all the buffs to find max level of given buff the unit has
	// Additionally count buffs the unit has and clear its hashtable entry if no buffs present
	private function FindUnitMaxBuffLevel takes unit u, integer buffType returns integer
		local integer maxLevel = 0
		local boolean hasBuffs = false
		local integer i = mCount - 1
		loop
			exitwhen i < 0
			if mArrUnit[i] == u and mArrTime[i] > 0.0 then
				set hasBuffs = true
				if mArrBuffTyppe[i] == buffType and mArrLevel[i] > maxLevel then
					set maxLevel = mArrLevel[i]
				endif
			endif
			set i = i - 1
		endloop
		if not hasBuffs then
			call FlushChildHashtable(mHash, GetHandleId(u))
		endif
		return maxLevel
	endfunction

	public function AddBuff takes unit u, integer buffType, integer level, real time returns nothing
		local integer maxLevelFound = 0
		local integer emptyIdx = mCount
		local integer i = mCount - 1
		// Loop to find max buff level or update existing buff of same type/level
		// TODO: use FindUnitMaxBuffLevel instead?
		loop
			exitwhen i < 0
			if mArrTime <= 0.0 then
				set emptyIdx = i
			elseif mArrUnit[i] == u and mArrBuffType[i] == buffType then
				if mArrLevel[i] == level then
					set mArrTime[i] = RMaxBJ(mArrTime[i], time)
					return
				else
					set maxLevelFound = mArrLevel[i]
				endif
			endif
			set i = i - 1
		endloop
		// Insert new buff
		if emptyIdx == mCount then
			set mCount = mCount + 1
		endif
		if level > maxLevelFound then
			if level == 0 then
				call Dummy_UnitBuff(u, ARR_DUMMY_ABILITY[buffType], ARR_ORDER[buffType])
			endif
			call SaveInteger(mHash, GetHandleId(u), buffType, level)
			call FireLevelChangedEvent(u, buffType, maxLevelFound, level)
		endif
		set mArrUnit[emptyIdx] = u
		set mArrBuffType[emptyIdx] = buffType
		set mArrLevel[emptyIdx] = level
		set mArrTime[emptyIdx] = time
	endfunction

	public function Update takes real dt returns nothing
		local integer i = mCount - 1
		local integer prevMaxLevel = 0
		local integer maxLevel = 0
		loop
			exitwhen i < 0
			if mArrTime[i] > 0.0 then
				set mArrTime[i] = mArrTime[i] - dt
				// Buff just expired
				if mArrTime[i] <= 0 then
					set prevMaxLevel = LoadInteger(mHash, GetHandleId(mArrUnit[i]), mArrBuffType[i])
					set maxLevel = FindUnitMaxBuffLevel(mArrUnit[i], mArrBuffType[i])
					call FireLevelChangedEvent(mArrUnit[i], mArrBuffType[i], prevMaxLevel, maxLevel)
					call SaveInteger(mHash, GetHandleId(mArrUnit[i]), mArrBuffType[i], maxLevel)
					if maxLevel == 0 then
						call UnitRemoveAbility(u, ARR_BUFF_ID[mArrBuffType[i]])
					endif
				endif
			elseif i == mCount - 1 then
				set mCount = mCount - 1
			endif
			set i = i - 1
		endloop
	endfunction
endlibrary
