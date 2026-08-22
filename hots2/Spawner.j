// TODO: it's generic now
library Spawner

	globals
		private integer KEY_LEVEL   = StringHash("level")
		private integer KEY_DAMAGE  = StringHash("damage")
		private integer KEY_DAMAGEL = StringHash("damagel")
		private integer KEY_HP      = StringHash("hp")
		private integer KEY_HPL     = StringHash("hpl")
		private integer KEY_R       = StringHash("r")
		private integer KEY_G       = StringHash("g")
		private integer KEY_B       = StringHash("b")
		private integer KEY_RL      = StringHash("rl")
		private integer KEY_GL      = StringHash("gl")
		private integer KEY_BL      = StringHash("bl")
		private integer KEY_SCALE   = StringHash("scale")
		private integer KEY_SCALEL  = StringHash("scalel")

		public hashtable mHash = InitHashtable()
		public real mDamageMultiplier = 1.0
		public real mHpMultiplier = 1.0
	endglobals

	public function DefineUnitBaseDamage takes integer id, real damage, real damageL returns nothing
		call SaveReal(mHash, id, KEY_DAMAGE, damage)
		call SaveReal(mHash, id, KEY_DAMAGEL, damageL)
	endfunction

	public function DefineUnitMaxHP takes integer id, real hp, real hpL returns nothing
		call SaveReal(mHash, id, KEY_HP, hp)
		call SaveReal(mHash, id, KEY_HPL, hpL)
	endfunction

	public function DefineUnitColor takes integer id, real r, real g, real b, real rL, real gL, real bL returns nothing
		call SaveReal(mHash, id, KEY_R, r)
		call SaveReal(mHash, id, KEY_G, g)
		call SaveReal(mHash, id, KEY_B, b)
		call SaveReal(mHash, id, KEY_RL, rL)
		call SaveReal(mHash, id, KEY_GL, gL)
		call SaveReal(mHash, id, KEY_BL, bL)
	endfunction

	public function DefineUnitScale takes integer id, real scale, real scaleL returns nothing
		call SaveReal(mHash, id, KEY_SCALE, scale)
		call SaveReal(mHash, id, KEY_SCALEL, scaleL)
	endfunction

	function SetUnitLvl takes unit u, integer lvl returns unit
		local real percentHp = GetUnitLifePercent(u)
		local integer id = GetUnitTypeId(u)
		local real rlvl = I2R(lvl)

		local real dmg =   LoadReal(mHash, id, KEY_DAMAGE) + rlvl * LoadReal(mHash, id, KEY_DAMAGEL)
		local real hp =    LoadReal(mHash, id, KEY_HP)     + rlvl * LoadReal(mHash, id, KEY_HPL)
		local real r =     LoadReal(mHash, id, KEY_R)      + rlvl * LoadReal(mHash, id, KEY_RL)
		local real g =     LoadReal(mHash, id, KEY_G)      + rlvl * LoadReal(mHash, id, KEY_GL)
		local real b =     LoadReal(mHash, id, KEY_B)      + rlvl * LoadReal(mHash, id, KEY_BL)
		local real scale = LoadReal(mHash, id, KEY_SCALE)  + rlvl * LoadReal(mHash, id, KEY_SCALEL)

		call SaveInteger(mHash, GetHandleId(u), KEY_LEVEL, lvl)
		call BlzSetUnitName(u, GetObjectName(id) + " lvl. " + I2S(lvl))

		// TODO: actually check game version
		call BlzSetUnitBaseDamage(u, R2I(dmg * mDamageMultiplier), 0)
		call BlzSetUnitBaseDamage(u, R2I(dmg * mDamageMultiplier), 1)
		call BlzSetUnitBaseDamage(u, R2I(dmg * mDamageMultiplier), 2)
		call BlzSetUnitMaxHP(u, R2I(hp * mHpMultiplier))
		call SetUnitVertexColorBJ(u, r, g, b, 0)
		call SetUnitScale(u, scale, scale, scale)

		call SetUnitLifePercentBJ(u, percentHp)

		return u
	endfunction

	// TODO: move to hots.j as a utility function with no prefix?
	function GetUnitLvl takes unit u returns integer
		return LoadInteger(mHash, GetHandleId(u), KEY_LEVEL)
	endfunction

endlibrary