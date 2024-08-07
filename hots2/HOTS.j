library HOTS requires Utils, TextTag, Spawner

	globals
		player PLAYER_VILLAGE = Player(10) // Number 11
		player PLAYER_WORMS = Player(11) // Number 12
		player PLAYER_FLORA = Player(12) // Number 13

		integer UNIT_TYPE_FIRE = 'h005'

		integer ABILITY_LIGHT = 'A00H'
		integer ABILITY_DISARM = 'A00K'

		integer ATTR_Q = 0
		integer ATTR_W = 1
		integer ATTR_E = 2
		integer ATTR_R = 3

		private integer KeyFood = StringHash("food")
		private integer KeyFoodL = StringHash("foodl")
		private integer KeyHeal = StringHash("heal")
		private integer KeyHealL = StringHash("heall")

		integer DAMAGE_SPELL = 1
	endglobals

	// Worm API
	function SetWormIdProps takes integer wormId, integer food, integer foodl, real heal, real heall returns nothing
		call SaveInteger(udg_Worm_Hash, wormId, KeyFood, food)
		call SaveInteger(udg_Worm_Hash, wormId, KeyFoodL, foodl)
		call SaveReal(udg_Worm_Hash, wormId, KeyHeal, heal)
		call SaveReal(udg_Worm_Hash, wormId, KeyHealL, heall)
	endfunction

	function GetWormHunger takes unit u returns integer
		local integer id = GetUnitTypeId(u)
		return LoadInteger(udg_Worm_Hash, id, KeyFood) + GetUnitLvl(u) * LoadInteger(udg_Worm_Hash, id, KeyFoodL)
	endfunction

	function GetWormHeal takes unit u returns real
		local integer id = GetUnitTypeId(u)
		return LoadReal(udg_Worm_Hash, id, KeyHeal) + GetUnitLvl(u) * LoadReal(udg_Worm_Hash, id, KeyHealL)
	endfunction


	// Create and play a new 3D sound for players
	function UnitMakeSound takes unit u, string path returns nothing
		local sound sfx = null
		if not IsUnitVisible(u, PLAYER_VILLAGE) then
			return
		endif

		//"war3mapImported\\drincc.mp3"
		set sfx = CreateSound(path, false, true, true, 10, 10, "DefaultEAXON")
		call SetSoundDuration(sfx, GetSoundFileDuration(path))
		call SetSoundChannel(sfx, 0)
		call SetSoundVolume(sfx, 127)
		call SetSoundPitch(sfx, 1.0)
		call SetSoundDistances(sfx, 600.0, 10000.0)
		call SetSoundDistanceCutoff(sfx, 3000.0)
		call SetSoundConeAngles(sfx, 0.0, 0.0, 127)
		call SetSoundConeOrientation(sfx, 0.0, 0.0, 0.0)

		call AttachSoundToUnit(sfx, u)
		call StartSound(sfx)
		call KillSoundWhenDone(sfx)
		set sfx = null
	endfunction


	// Displays warning texttag above unit
	function UnitWarn takes unit u, string text returns texttag
	    local texttag tt = CreateTextTagUnitColor(text, u, 40.0, 9.0, TextTag_COLOR_ID_WARNING)
	    call SetTextTagVelocityBJ(tt, 60, 90)
	    call SetTextTagFadeSpan(tt, 1.0, 3.0)
	    return tt
	endfunction


	function GetDamageTextColor takes unit source, unit target returns integer
		// TODO: block color
		if GetUnitTypeId(source) == UNIT_TYPE_FIRE then
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


	function PlayerBuffDuration takes player p, real duration returns real
		return duration * (1 + 0.1 * GetPlayerAttr(p, ATTR_R))
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
	    	call FlashEffectTarget("Abilities\\Spells\\Undead\\VampiricAura\\VampiricAuraTarget.mdl", u, "origin")
	    endif

	    call SetUnitState(u, UNIT_STATE_LIFE, health + heal)

	    if showText and heal > 0.5 and IsUnitVisible(u, PLAYER_VILLAGE) then
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

		call FlashEffectTarget("Abilities\\Spells\\Human\\SpellSteal\\SpellStealTarget.mdl", u, "overhead")

		if not IsUnitType(u, UNIT_TYPE_HERO) then
			return
		endif

		set tt = CreateTextTagUnitColor("+" + I2S(xp) + "xp!", u, 30, 7 * (1 + 0.01 * I2R(xp)), -1)
	    call SetTextTagVelocityBJ(tt, 32, 90)
	    call SetTextTagFadeSpan(tt, 2.0, 3.5)
	    call SetTextTagPlayer(tt, GetOwningPlayer(u))

		call AddHeroXP(u, xp, true)
	endfunction


	function GetSpellDamage takes unit u returns real
		local real base = BlzGetUnitBaseDamage(u, 1) + GetRandomInt(1, BlzGetUnitDiceSides(u, 1))
		set base = base * (1 + 0.15 * GetPlayerAttr(GetOwningPlayer(u), ATTR_W))
		if IsUnitType(u, UNIT_TYPE_HERO) then
			return GetHeroLevel(u) + base
		endif
		return GetUnitLvl(u) + base
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

	function ClearDamageTags takes nothing returns nothing
		set udg_damageSpell = false
	endfunction

	function DealDamage takes unit source, unit target, real damage, integer tag returns nothing
		if tag == DAMAGE_SPELL then
				set udg_damageSpell = true
		endif
		call UnitDamageTarget(source, target, damage, true, false, ATTACK_TYPE_HERO, DAMAGE_TYPE_NORMAL, WEAPON_TYPE_WHOKNOWS)
		call ClearDamageTags()
	endfunction



	/////////////////////
	// TIMER CALLBACKS //
	/////////////////////

	public function Lantern_func takes nothing returns nothing
		local integer keyName = StringHash("lantern")
		
		call Timer_TimerEnd(GetExpiredTimer(), keyName) // Sets Timer_T, Timer_U

		call SetUnitAnimation(Timer_U, "death")
		call GroupRemoveUnit(udg_Lantern_LitGroup, Timer_U)
	endfunction

	public function WoznyLight_func takes nothing returns nothing
		local integer keyName = StringHash("woznylight")
		local integer count

		call Timer_TimerEnd(GetExpiredTimer(), keyName) // Sets Timer_T, Timer_U

		set count = GetUnitUserData(Timer_U)
		call IssueTargetOrder(Timer_U, "innerfire", udg_Lantern_UnitArr[count])
	endfunction

endlibrary