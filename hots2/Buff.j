library Buff initializer init requires Dummy, HOTS

	globals
		private hashtable Hash = InitHashtable()
		public integer KeyRegen = StringHash("regen")

		public real array TimeArr
		private integer BUFF_COUNT = 0
		private integer array ABILITY_ARR
		private integer array BUFF_ARR
		private string array ORDER_ARR

		public integer BE_POWER = 0
		public integer SONIK = 1
	endglobals

	// Register new buff with corresponding dummy ability and cast order
	private function AddBuffAbilityOrder takes integer abilityBuffId, integer abilityId, string order returns nothing
		set BUFF_ARR[BUFF_COUNT] = abilityBuffId
		set ABILITY_ARR[BUFF_COUNT] = abilityId
		set ORDER_ARR[BUFF_COUNT] = order
		set BUFF_COUNT = BUFF_COUNT + 1
	endfunction

	// Init buff ability array
	private function init takes nothing returns nothing
		call AddBuffAbilityOrder('B001', 'A00I', "bloodlust") // BE_POWER = 0
		call AddBuffAbilityOrder('B002', 'A00L', "innerfire") // SONIK = 1
	endfunction

	// Called when player's crook drinks a potion...
	// TODO: dummy items for crooks instead of casters for better performance?
	// TODO: this should work for normal units as well?
	public function SetUnitBuff takes unit u, integer buffId, real duration returns nothing
		local player p = GetOwningPlayer(u)
		local integer i = GetPlayerId(p) * BUFF_COUNT + buffId

		set TimeArr[i] = RMaxBJ(TimeArr[i], duration)
		// call Dummy_CreateTarget(p, u)
		// call Dummy_UnitCastWithOrder(u, ABILITY_ARR[buffId], ORDER_ARR[buffId])
		call Dummy_UnitBuff(u, ABILITY_ARR[buffId], ORDER_ARR[buffId])

		set p = null
	endfunction

	// For regeneration buffs
	public function SetUnitRegenLevel takes unit u, real duration, integer level returns nothing
		local player p = GetOwningPlayer(u)
		local integer i = GetPlayerId(p) * BUFF_COUNT + SONIK
		local integer uid = GetHandleId(u)

		local integer currentLevel = LoadInteger(Hash, uid, KeyRegen)
		set level = IMaxBJ(level, currentLevel)
		call SaveInteger(Hash, uid, KeyRegen, level)

		set TimeArr[i] = RMaxBJ(TimeArr[i], duration)
		// call Dummy_CreateTarget(p, u)
		// call Dummy_UnitCastWithOrder(u, ABILITY_ARR[SONIK], ORDER_ARR[SONIK])
		call Dummy_UnitBuff(u, ABILITY_ARR[SONIK], ORDER_ARR[SONIK])
		

		set p = null
	endfunction

	// Called in the main update loop
	public function Update takes real dt returns nothing
		local integer playerId = 0
		local integer buffId
		local integer i
		local unit u
		local integer lvl
		loop
			exitwhen playerId == udg_PlayerCount

			set buffId = 0
			loop
				exitwhen buffId == BUFF_COUNT
				set i = playerId * BUFF_COUNT + buffId
				set u = udg_Crook[playerId + 1]

				set TimeArr[i] = TimeArr[i] - dt
				if TimeArr[i] <= 0.00 then
					if GetUnitAbilityLevel(u, BUFF_ARR[buffId]) > 0 then
						call UnitRemoveAbility(u, BUFF_ARR[buffId])
						// Place exceptions right here...
						if buffId == SONIK then
							call RemoveSavedInteger(Hash, GetHandleId(u), KeyRegen)
						endif
					endif
				else
					// Regen healing
					if buffId == SONIK then
						set lvl = LoadInteger(Hash, GetHandleId(u), KeyRegen)
						call UnitHeal(u, 0.05*lvl, false, false)
					endif
				endif

				set buffId = buffId + 1
			endloop

			set playerId = playerId + 1
		endloop

		set u = null
	endfunction

endlibrary