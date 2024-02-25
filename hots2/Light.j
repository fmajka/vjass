library Light requires HOTS, Weapon, Utils

	globals
		public group Group = CreateGroup()
		public boolean State = false
	endglobals

	private function SetState_func takes nothing returns nothing
		local unit u = GetEnumUnit()
		local integer light = GetUnitAbilityLevel(u, HOTS_ABILITY_LIGHT)

		if State and light == 0 then
			call UnitAddAbility(u, HOTS_ABILITY_LIGHT)
		elseif not State and light > 0 then
			call UnitRemoveAbility(u, HOTS_ABILITY_LIGHT)
		endif

		set u = null
	endfunction

	public function SetState takes boolean state returns nothing
		set State = state
		call ForGroup(Group, function SetState_func)
	endfunction

	public function UnitUpdate takes unit u returns nothing
		local boolean lit = false
		if GetItemTypeId(Weapon_GetUnitWeapon(u)) == Weapon_ITEM_TORCH then
			set lit = true
		endif

		if lit and not IsUnitInGroup(u, Group) then
			call GroupAddUnit(Group, u)
			if State then
				call UnitAddAbility(u, HOTS_ABILITY_LIGHT)
			endif
		elseif not lit and IsUnitInGroup(u, Group) then
			call GroupRemoveUnit(Group, u)
			call UnitRemoveAbility(u, HOTS_ABILITY_LIGHT)
		endif
	endfunction

endlibrary