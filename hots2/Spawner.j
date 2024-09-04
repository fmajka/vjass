library Spawner initializer init

	globals
		boolexpr COND_EXP_ELIGIBLE

		public hashtable Hash = InitHashtable()
		public integer KeyLevel = StringHash("level")
		public integer KeyDamage = StringHash("damage")
		public integer KeyDamageL = StringHash("damagel")
		public integer KeyHp = StringHash("hp")
		public integer KeyHpL = StringHash("hpl")
		public integer KeyR = StringHash("r")
		public integer KeyG = StringHash("g")
		public integer KeyB = StringHash("b")
		public integer KeyRL = StringHash("rl")
		public integer KeyGL = StringHash("gl")
		public integer KeyBL = StringHash("bl")
		public integer KeyScale = StringHash("scale")
		public integer KeyScaleL = StringHash("scalel")

		public real damageMultiplier = 1.0
		public real hpMultiplier = 1.0
	endglobals

	function filterExpEligible takes nothing returns boolean
	    return IsUnitType(GetFilterUnit(), UNIT_TYPE_HERO)
	endfunction

	public function DefineUnitBaseDamage takes integer id, real damage, real damageL returns nothing
		call SaveReal(Hash, id, KeyDamage, damage)
		call SaveReal(Hash, id, KeyDamageL, damageL)
	endfunction

	public function DefineUnitMaxHP takes integer id, real hp, real hpL returns nothing
		call SaveReal(Hash, id, KeyHp, hp)
		call SaveReal(Hash, id, KeyHpL, hpL)
	endfunction

	public function DefineUnitColor takes integer id, real r, real g, real b, real rL, real gL, real bL returns nothing
		call SaveReal(Hash, id, KeyR, r)
		call SaveReal(Hash, id, KeyG, g)
		call SaveReal(Hash, id, KeyB, b)
		call SaveReal(Hash, id, KeyRL, rL)
		call SaveReal(Hash, id, KeyGL, gL)
		call SaveReal(Hash, id, KeyBL, bL)
	endfunction

	public function DefineUnitScale takes integer id, real scale, real scaleL returns nothing
		call SaveReal(Hash, id, KeyScale, scale)
		call SaveReal(Hash, id, KeyScaleL, scaleL)
	endfunction

	function SetUnitLvl takes unit u, integer lvl returns unit
		local real percentHp = GetUnitLifePercent(u)
		local integer id = GetUnitTypeId(u)
		local real rlvl = I2R(lvl)

		local real dmg = LoadReal(Hash, id, KeyDamage) + rlvl*LoadReal(Hash, id, KeyDamageL)
		local real hp = LoadReal(Hash, id, KeyHp) + rlvl*LoadReal(Hash, id, KeyHpL)
		local real r = LoadReal(Hash, id, KeyR) + rlvl*LoadReal(Hash, id, KeyRL)
		local real g = LoadReal(Hash, id, KeyG) + rlvl*LoadReal(Hash, id, KeyGL)
		local real b = LoadReal(Hash, id, KeyB) + rlvl*LoadReal(Hash, id, KeyBL)
		local real scale = LoadReal(Hash, id, KeyScale) + rlvl*LoadReal(Hash, id, KeyScaleL)

		call SaveInteger(Hash, GetHandleId(u), KeyLevel, lvl)
		call BlzSetUnitName(u, GetObjectName(id) + " lvl. " + I2S(lvl))

		call BlzSetUnitBaseDamage(u, R2I(dmg * damageMultiplier), 0)
		call BlzSetUnitBaseDamage(u, R2I(dmg * damageMultiplier), 1)
		call BlzSetUnitBaseDamage(u, R2I(dmg * damageMultiplier), 2)
		call BlzSetUnitMaxHP(u, R2I(hp * hpMultiplier))
		call SetUnitVertexColorBJ(u, r, g, b, 0)
		call SetUnitScale(u, scale, scale, scale)

		call SetUnitLifePercentBJ(u, percentHp)

		return u
	endfunction

	function GetUnitLvl takes unit u returns integer
		return LoadInteger(Hash, GetHandleId(u), KeyLevel)
	endfunction

	private function init takes nothing returns nothing
		set COND_EXP_ELIGIBLE = Condition(function filterExpEligible)

		// Worm
		call DefineUnitBaseDamage('h003', 6, 2)
		call DefineUnitMaxHP('h003', 43, 6)
		call DefineUnitScale('h003', 0.3, 0.02)
		call DefineUnitColor('h003', 100, 100, 100, 0, -8, -8)

		// Wolf
		call DefineUnitBaseDamage('n007', 2, 1)
		call DefineUnitMaxHP('n007', 30, 6)
		call DefineUnitScale('n007', 0.36, 0.02)
		call DefineUnitColor('n007', 100, 100, 100, 0, -3, 0)

		// Grubby...
		call DefineUnitBaseDamage('h009', 6, 1.5)
		call DefineUnitMaxHP('h009', 37, 7)
		call DefineUnitScale('h009', 0.36, 0.02)
		call DefineUnitColor('h009', 50, 75, 100, 0, -4, 0)
	endfunction

endlibrary