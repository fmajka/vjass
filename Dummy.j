library Dummy

	globals
		private unit mLastCaster = null

		// TODO: should be set from outside
		public integer DEFAULT_DUMMY_ID = 'h004'
	endglobals

	private function CreateDummyAtUnit takes player p, integer dummyId, unit u returns boolean
		if not IsUnitAliveBJ(u) then
			return false
		endif
		set mLastCaster = CreateUnit(p, dummyId, GetUnitX(u), GetUnitY(u), 0.0)
		call ShowUnit(mLastCaster, false)
		call UnitApplyTimedLife(mLastCaster, 'BTLF', 1.0)
		return true
	endfunction

	// Creates the default dummy that buffs the target; dummy owner == target owner
	public function UnitBuff takes unit target, integer abilityId, string order returns unit
		if not CreateDummyAtUnit(GetOwningPlayer(target), DEFAULT_DUMMY_ID, target) then
			return null
		endif
		call UnitAddAbility(mLastCaster, abilityId)
		call IssueTargetOrder(mLastCaster, order, target)
		return mLastCaster
	endfunction

	// Specifies owner of the dummy
	public function UnitBuffFromPlayer takes unit target, integer abilityId, string order, player p returns unit
		if not CreateDummyAtUnit(p, DEFAULT_DUMMY_ID, target) then
			return null
		endif
		call UnitAddAbility(mLastCaster, abilityId)
		call IssueTargetOrder(mLastCaster, order, target)
		return mLastCaster
	endfunction

	// Assumes that specified dummy already has the ability
	public function UnitBuffFromPlayerDummy takes unit target, string order, player p, integer dummyId returns unit
		if not CreateDummyAtUnit(p, dummyId, target) then
			return null
		endif
		call IssueTargetOrder(mLastCaster, order, target)
		return mLastCaster
	endfunction

endlibrary