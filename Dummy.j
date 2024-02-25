library Dummy

	globals
		public unit Caster = null

		// Editable by the user
		public integer DEFAULT_ID = 'h004'
	endglobals

	public function CreateIdTarget takes player id, integer dummyId, unit target returns unit
		set Caster = CreateUnit(id, dummyId, GetUnitX(target), GetUnitY(target), 0)
		call ShowUnit(Caster, false)
		call UnitApplyTimedLife(Caster, 'BTLF', 1.0)
		return Caster
	endfunction

	// Create the default dummy
	public function CreateTarget takes player id, unit target returns unit
		return CreateIdTarget(id, DEFAULT_ID, target)
	endfunction

	// Add given ability to last created caster and order to cast it on the target
	public function UnitCastWithOrder takes unit target, integer abilityId, string order returns nothing
		call UnitAddAbility(Caster, abilityId)
		call IssueTargetOrder(Caster, order, target)
	endfunction

	public function UnitCastWithOrderLevel takes unit target, integer abilityId, string order, integer level returns nothing
		call UnitAddAbility(Caster, abilityId)
		call SetUnitAbilityLevel(Caster, abilityId, level)
		call IssueTargetOrder(Caster, order, target)
	endfunction

endlibrary