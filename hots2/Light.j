library Light requires Hots, Weapon, Utils

	globals
		public group mGroup = CreateGroup()
		public boolean mState = false

		// UnitUpdateEvent
		public real mUnitUpdateEventState
		public unit eUnitUpdateUnit
		public boolean eUnitUpdateIsLit
	endglobals

	// TODO: different light levels, ARR_ABILITY_LIGHT, CreateLightLevel takes integer abilityId returns integer
	private function SetState_func takes nothing returns nothing
		local unit u = GetEnumUnit()
		local integer light = GetUnitAbilityLevel(u, ABILITY_LIGHT)
		if mState and light == 0 then
			call UnitAddAbility(u, ABILITY_LIGHT)
		elseif not mState and light > 0 then
			call UnitRemoveAbility(u, ABILITY_LIGHT)
		endif
		set u = null
	endfunction

	// Usually state set to: false at dawn, true at dusk
	public function SetState takes boolean state returns nothing
		set mState = state
		call ForGroup(mGroup, function SetState_func)
	endfunction

	// Change eUnitUpdateIsLit in the listener to modify increased light radius
	private function FireUnitUpdateEvent takes unit u returns nothing
		eUnitUpdateUnit = u
		eUnitUpdateIsLit = false
		mUnitUpdateEventState = 1.0
		mUnitUpdateEventState = 0.0
	endfunction

	public function UnitUpdate takes unit u returns nothing
		call FireUnitUpdateEvent(u)
		
		// TODO: register hots-specific event listener
		if GetItemTypeId(GetUnitWeapon(u, 1)) == ITEM_TORCH or GetItemTypeId(GetUnitWeapon(u, 2)) == ITEM_TORCH then
			set Light_eUnitUpdateIsLit = true
		endif

		if Light_eUnitUpdateIsLit and not IsUnitInGroup(u, mGroup) then
			call GroupAddUnit(mGroup, u)
			if mState then
				call UnitAddAbility(u, ABILITY_LIGHT)
			endif
		elseif not Light_eUnitUpdateIsLit and IsUnitInGroup(u, mGroup) then
			call GroupRemoveUnit(mGroup, u)
			call UnitRemoveAbility(u, ABILITY_LIGHT)
		endif
	endfunction

endlibrary