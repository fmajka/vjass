library HOTS requires Utils, TextTag, Spawner

	globals
		public player PLAYER_VILLAGE = Player(10) // Number 11
		public player PLAYER_WORMS = Player(11) // Number 12
		public player PLAYER_FLORA = Player(12) // Number 13

		// TODO: change ID to on-fire dummy caster
		public integer UNIT_TYPE_FIRE = 'h000'

		public integer ATTR_Q = 0
		public integer ATTR_W = 1
		public integer ATTR_E = 2
		public integer ATTR_R = 3
	endglobals

	// Worm API
	function SetWormIdProps takes integer wormId, integer food, integer foodl, real heal, real heall returns nothing
		call SaveInteger(udg_Worm_Hash, wormId, StringHash("food"), food)
		call SaveInteger(udg_Worm_Hash, wormId, StringHash("foodl"), foodl)
		call SaveReal(udg_Worm_Hash, wormId, StringHash("heal"), heal)
		call SaveReal(udg_Worm_Hash, wormId, StringHash("heall"), heall)
	endfunction

	function GetWormHunger takes unit u returns integer
		local integer id = GetUnitTypeId(u)
		return LoadInteger(udg_Worm_Hash, id, StringHash("food")) + GetUnitLvl(u) * LoadInteger(udg_Worm_Hash, id, StringHash("foodl"))
	endfunction

	function GetWormHeal takes unit u returns real
		local integer id = GetUnitTypeId(u)
		return LoadReal(udg_Worm_Hash, id, StringHash("heal")) + GetUnitLvl(u) * LoadReal(udg_Worm_Hash, id, StringHash("heall"))
	endfunction
	

	// Displays warning texttag above unit
	public function UnitWarn takes unit u, string text returns texttag
	    local texttag tt = CreateTextTagUnitColor(text, u, 40.0, 9.0, COLOR_ID_WARNING)
	    call SetTextTagVelocityBJ(tt, 60, 90)
	    call SetTextTagFadeSpan(tt, 1.0, 3.0)
	    return tt
	endfunction


	function GetDamageTextColor takes unit source, unit target returns integer
		// TODO: block color
		if GetUnitTypeId(target) == UNIT_TYPE_FIRE then
			return TextTag_COLOR_ID_ORANGE
		elseif IsUnitAlly(target, PLAYER_VILLAGE) then
			return TextTag_COLOR_ID_RED
		elseif IsUnitEnemy(target, PLAYER_VILLAGE) then
			return TextTag_COLOR_ID_YELLOW
		endif
		return -1
	endfunction


	function GetPlayerAttr takes player p, integer attrId returns integer
		if attrId == ATTR_Q then
			return GetPlayerTechCount(p, 'R000', true)
		elseif attrId == ATTR_W then
			return GetPlayerTechCount(p, 'R001', true)
		elseif attrId == ATTR_E then
			return GetPlayerTechCount(p, 'R002', true)
		elseif attrId == ATTR_R then
			return GetPlayerTechCount(p, 'R003', true)
		endif
		return 0
	endfunction


	function UnitHeal takes unit u, real heal, boolean showText, boolean fromFood returns nothing
		local texttag tt
		local real health = GetUnitState(u, UNIT_STATE_LIFE)
		if heal <= 0 then
			return
		endif
		
	    if fromFood then
	    	// Filatelistyka healing from food bonus
	    	set heal = heal * (1 + 0.1 * GetPlayerAttr(GetOwningPlayer(u), ATTR_R))
	    	call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Undead\\VampiricAura\\VampiricAuraTarget.mdl", u, "origin"))
	    endif

	    call SetUnitState(u, UNIT_STATE_LIFE, health + heal)

	    // TODO: show floating health text
	    if showText and IsUnitVisible(u, PLAYER_VILLAGE) then
			set tt = CreateTextTagUnitColor(I2S(R2IR(heal)), u, GetRandomReal(15, 45), 7 * (1 + 0.01 * heal), TextTag_COLOR_ID_GREEN)
			call SetTextTagVelocityBJ(tt, 40, 90)
			call SetTextTagFadeSpan(tt, 1.0, 2.5)
	    endif
	endfunction


	function CrookAddHunger takes unit u, integer val returns nothing
		// Filatelistyka saturation bonus
		set val = val + R2IR(val * 0.1 * GetPlayerAttr(GetOwningPlayer(u), ATTR_R))

	    set val = GetHeroStr(u, false) + val
	    call SetHeroStr(u, IMaxBJ(1, IMinBJ(100, val)), true)
	endfunction


	function CrookAddThirst takes unit u, integer val returns nothing
	    set val = GetHeroAgi(u, false) + val
	    call SetHeroAgi(u, IMaxBJ(1, IMinBJ(100, val)), true)
	    set udg_Player_Thirst[GetConvertedPlayerId(GetOwningPlayer(u))] = 0.00
	endfunction


	function CrookAddXP takes unit u, integer xp returns nothing
		local texttag tt
		// Filatelistyka XP scaling
		set xp = xp + R2IR(xp * 0.08 * GetPlayerAttr(GetOwningPlayer(u), ATTR_R))

		call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Human\\SpellSteal\\SpellStealTarget.mdl", u, "overhead"))

		if not IsUnitType(u, UNIT_TYPE_HERO) then
			return
		endif

		set tt = CreateTextTagUnitColor("+" + I2S(xp) + "xp!", u, 30, 7 * (1 + 0.01 * I2R(xp)), -1)
	    call SetTextTagVelocityBJ(tt, 32, 90)
	    call SetTextTagFadeSpan(tt, 1.5, 3.0)
	    call SetTextTagPlayer(tt, GetOwningPlayer(u))

		call AddHeroXP(u, xp, true)
	endfunction


	function InteractUnit takes unit u returns nothing
        call GroupAddUnit(udg_Interact_Group, u)
        call SaveReal(udg_Interact_Hash, GetHandleId(u), StringHash("time"), GetRandomReal(180, 300))
        call SetUnitVertexColor(u, 192, 192, 192, 128)
	endfunction


	function GetRNG takes real chance returns boolean
		if GetRandomReal(0, 1) < chance then
			return true
		endif
		return false
	endfunction


	function GetRandomCoinId takes nothing returns integer
		local real chance = GetRandomReal(0, 1)
		// 69-25-5-1
		if chance < 0.01 then
			return 'I001'
		elseif chance < 0.06 then
			return 'I004'
		elseif chance < 0.31 then
			return 'I003'
		else
			return 'I002'
		endif
	endfunction

endlibrary