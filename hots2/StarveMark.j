library StarveMark requires Combat, Utils, HOTS
	globals
		public real CAST_TIME = 1.25
		public real RADIUS = 90
		public string FX_PATH = "Abilities\\Spells\\Undead\\VampiricAura\\VampiricAura.mdl"
		private real FADE_TIME = -1.0

		private integer KEY_X = StringHash("x")
		private integer KEY_Y = StringHash("y")
		private integer KEY_TRIGGERED = StringHash("triggered")
		private integer KEY_CASTER = StringHash("caster")
		private integer KEY_COUNT = StringHash("count")
		private integer KEY_TIME = StringHash("time")

		private group g = CreateGroup()
		private group affected = CreateGroup()
		private hashtable hash = InitHashtable()
		private integer count = 0

		// Used by the callback function
		private unit caster
		private real x
		private real y
		private real totalHeal = 0.0
	endglobals

	private function UpdateCallback takes nothing returns nothing
		local unit u = GetEnumUnit()
		local real mod = 0.3
		local real damage = 0
		if IsUnitType(u, UNIT_TYPE_HERO) then
			set mod = mod * 0.01 * I2R(GetHeroStr(u, false))
			set damage = mod * GetUnitState(u, UNIT_STATE_MAX_LIFE)
			set totalHeal = totalHeal + mod * (1 - GetUnitHpRatio(caster))
			call SetHeroStr(u, R2I((1 - mod) * I2R(GetHeroStr(u, false))), true)
		else
			set damage = mod * GetUnitState(u, UNIT_STATE_LIFE)
			set totalHeal = totalHeal + damage
		endif
		call FlashEffectTarget("Abilities\\Spells\\Other\\Stampede\\StampedeMissileDeath.mdl", u, "chest")
		call DealDamage(caster, u, damage, DAMAGE_SPELLNOCOMBO)
		call Dummy_UnitBuffFromPlayer(u, 'A00M', "slow", GetOwningPlayer(caster))
		set u = null
	endfunction

	public function Update takes real dt returns nothing
		local integer i = count - 1
		local integer subcount
		local real time
		local boolean triggered
		local boolean done
		local effect fx
		loop
			exitwhen i < 0
			set time = LoadReal(hash, i, KEY_TIME)
			set done = time <= FADE_TIME
			set time = time - dt
			if time <= 0 then
				call GroupClear(affected)
				set caster = LoadUnitHandle(hash, i, KEY_CASTER)
				set triggered = LoadBoolean(hash, i, KEY_TRIGGERED)
				set subcount = LoadInteger(hash, i, KEY_COUNT) - 1
				loop
					exitwhen done or subcount < 0
					set fx = LoadEffectHandle(hash, i, subcount)
					if triggered then
						if time <= FADE_TIME then
							call BlzSetSpecialEffectHeight(fx, -256)
							call FlushChildHashtable(hash, GetHandleId(fx))
							call DestroyEffect(fx)
						else
							call BlzSetSpecialEffectAlpha(fx, R2I((1.0 - time / FADE_TIME) * 255.0))
						endif
					else
						set x = LoadReal(hash, GetHandleId(fx), KEY_X)
						set y = LoadReal(hash, GetHandleId(fx), KEY_Y)
						call FlashEffect("Abilities\\Spells\\Undead\\Impale\\ImpaleMissTarget.mdl", x, y)
						call GroupClear(g)
						call GetInRangePlayerEnemy(g, x, y, RADIUS, GetOwningPlayer(caster))
						call GroupAddGroup(g, affected)
					endif
					set subcount = subcount - 1
				endloop
				if not triggered then
					set totalHeal = 0.0
					call SaveBoolean(hash, i, KEY_TRIGGERED, true)
					call ForGroup(affected, function UpdateCallback)
					call UnitHeal(caster, totalHeal, true, true) // From food! xd
				elseif time <= FADE_TIME then
					if i == count - 1 then
						call FlushChildHashtable(hash, i)
						set count = count - 1
					endif
				endif
			endif
			call SaveReal(hash, i, KEY_TIME, time)
			set i = i - 1
		endloop
		set fx = null
	endfunction

	public function Cast takes unit caster returns nothing
		local integer i = 0
		local unit u
		local effect fx
		set x = GetUnitX(caster)
		set y = GetUnitY(caster)
		call GroupClear(affected)
		call GetInRangePlayerEnemy(affected, x, y, 768.0, GetOwningPlayer(caster))
		loop
			set u = FirstOfGroup(affected)
			exitwhen u == null
			set x = GetUnitX(u)
			set y = GetUnitY(u)
			set fx = AddSpecialEffect(FX_PATH, x, y)
			call SaveReal(hash, GetHandleId(fx), KEY_X, x)
			call SaveReal(hash, GetHandleId(fx), KEY_Y, y)
			call SaveEffectHandle(hash, count, i, fx)
			call GroupRemoveUnit(affected, u)
			set i = i + 1
		endloop
		if i > 0 then
			call SaveUnitHandle(hash, count, KEY_CASTER, caster)
			call SaveBoolean(hash, count, KEY_TRIGGERED, false)
			call SaveReal(hash, count, KEY_TIME, CAST_TIME)
			call SaveInteger(hash, count, KEY_COUNT, i)
			set count = count + 1
		endif
		set fx = null
		set u = null
	endfunction

endlibrary