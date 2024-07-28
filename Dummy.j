library Dummy

	globals
		public unit lastCaster = null

		// Editable by the user
		public integer DEFAULT_DUMMY_ID = 'h004'
	endglobals

	private function CreateDummyAtUnit takes player p, integer dummyId, unit u returns boolean
		if not IsUnitAliveBJ(u) then
			return false
		endif
		set lastCaster = CreateUnit(p, dummyId, GetUnitX(u), GetUnitY(u), 0.0)
		call ShowUnit(lastCaster, false)
		call UnitApplyTimedLife(lastCaster, 'BTLF', 1.0)
		return true
	endfunction

	// Creates the default dummy that buffs the target; dummy owner == target owner
	public function UnitBuff takes unit target, integer abilityId, string order returns unit
		if not CreateDummyAtUnit(GetOwningPlayer(target), DEFAULT_DUMMY_ID, target) then
			return null
		endif
		call UnitAddAbility(lastCaster, abilityId)
		call IssueTargetOrder(lastCaster, order, target)
		return lastCaster
	endfunction

	// Specifies owner of the dummy
	public function UnitBuffFromPlayer takes unit target, integer abilityId, string order, player p returns unit
		if not CreateDummyAtUnit(p, DEFAULT_DUMMY_ID, target) then
			return null
		endif
		call UnitAddAbility(lastCaster, abilityId)
		call IssueTargetOrder(lastCaster, order, target)
		return lastCaster
	endfunction

	// Assumes that specified dummy already has the ability
	public function UnitBuffFromPlayerDummy takes unit target, string order, player p, integer dummyId returns unit
		if not CreateDummyAtUnit(p, dummyId, target) then
			return null
		endif
		call IssueTargetOrder(lastCaster, order, target)
		return lastCaster
	endfunction

endlibrary