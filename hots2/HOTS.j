library HOTS initializer init requires Utils, TextTag, Spawner, Projectile

	globals
		player PLAYER_VILLAGE = Player(10) // Number 11
		player PLAYER_WORMS = Player(11) // Number 12
		player PLAYER_FLORA = Player(12) // Number 13

		integer UNIT_WORM = 'h003'
		integer UNIT_FIRE = 'h005'
		integer UNIT_GRUBBY = 'h009'

		integer ABILITY_LIGHT = 'A00H'
		integer ABILITY_DISARM = 'A00K'
		integer ABILITY_GLOW_LEFT = 'A01D'
		integer ABILITY_GLOW_RIGHT = 'A01G'

		integer ATTR_Q = 0
		integer ATTR_W = 1
		integer ATTR_E = 2
		integer ATTR_R = 3

		private integer KeyFood = StringHash("food")
		private integer KeyFoodL = StringHash("foodl")
		private integer KeyHeal = StringHash("heal")
		private integer KeyHealL = StringHash("heall")

		integer DAMAGE_SPELL = 1
		integer DAMAGE_SPELLNOCOMBO = 2

		integer TASK_BIOLOG = 1

		integer PROJECTILE_DAGGER
		integer DASH_KATANA
		integer PROJECTILE_AXE
		integer PROJECTILE_HUNGER

		boolexpr FILTER_LIVING_WORMS
		boolexpr FILTER_WOLF_UNSPAWNABLE
	endglobals

	private function filterLivingWorms takes nothing returns boolean
		local unit u = GetFilterUnit()
		local boolean result = (GetUnitTypeId(u) == UNIT_WORM or GetUnitTypeId(u) == UNIT_GRUBBY) and IsUnitAliveBJ(u)
		set u = null
		return result
	endfunction

	private function filterWolfUnspawnable takes nothing returns boolean
		local player passive = Player(PLAYER_NEUTRAL_PASSIVE)
		local unit u = GetFilterUnit()
		local player owner = GetOwningPlayer(u)
		local boolean result = owner != passive and owner != PLAYER_FLORA and IsUnitAliveBJ(u)
		set passive = null
		set u = null
		set owner = null
		return result
	endfunction

	private function init takes nothing returns nothing
		set PROJECTILE_DAGGER = InitProjectile("Abilities\\Spells\\NightElf\\shadowstrike\\ShadowStrikeMissile.mdl", 60, 1125, 1125, 40, Combat_IN_RANGE_ENEMY_ATTACKABLE, 1)
		set DASH_KATANA = InitDash(600, 1300, 60, Combat_IN_RANGE_ENEMY_ATTACKABLE, 1)
		set PROJECTILE_AXE = InitProjectile("Abilities\\Weapons\\RexxarMissile\\RexxarMissile.mdl", 50, 1, 2, 90, Combat_IN_RANGE_ENEMY_ATTACKABLE, 999)
		set Projectile_TRIGGER_UPDATE_EVENT[PROJECTILE_AXE] = true
		set FILTER_LIVING_WORMS = Condition(function filterLivingWorms)
		set FILTER_WOLF_UNSPAWNABLE = Condition(function filterWolfUnspawnable)
		set PROJECTILE_HUNGER= InitProjectile("Abilities\\Spells\\Undead\\DeathCoil\\DeathCoilMissile.mdl", 30, 1050, 700, 35, Combat_IN_RANGE_ENEMY_ATTACKABLE, 1)
	endfunction

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

	function EraseWorm takes item wormItem returns nothing
		local integer itemHandle = GetHandleId(wormItem)
		local unit worm = LoadUnitHandle(udg_Worm_Hash, itemHandle, StringHash("unit"))
		call FlushChildHashtable(udg_Worm_Hash, itemHandle)
		call RemoveUnit(worm)
		set worm = null
	endfunction

	// Displays warning texttag above unit
	function UnitWarn takes unit u, string text returns texttag
	    local texttag tt = CreateTextTagUnitColor(text, u, 40.0, 9.0, TextTag_COLOR_WARNING)
	    call SetTextTagVelocityBJ(tt, 60, 90)
	    call SetTextTagFadeSpan(tt, 1.0, 3.0)
	    return tt
	endfunction

	function GetDamageTextColor takes unit source, unit target returns integer
		// TODO: block color
		if GetUnitTypeId(source) == UNIT_FIRE then
			return TextTag_COLOR_ORANGE
		elseif IsUnitAlly(target, PLAYER_VILLAGE) then
			return TextTag_COLOR_RED
		elseif IsUnitEnemy(target, PLAYER_VILLAGE) then
			return TextTag_COLOR_YELLOW
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
			set tt = CreateTextTagUnitColor(I2S(R2IR(heal)), u, GetRandomReal(15, 45), 7 * (1 + 0.01 * heal), TextTag_COLOR_GREEN)
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

	function CrookAddXP takes unit u, integer xp returns texttag
		local texttag tt
		// Filatelistyka XP scaling
		set xp = xp + R2IR(xp * 0.08 * GetPlayerAttr(GetOwningPlayer(u), ATTR_R))
		call FlashEffectTarget("Abilities\\Spells\\Human\\SpellSteal\\SpellStealTarget.mdl", u, "overhead")
		if not IsUnitType(u, UNIT_TYPE_HERO) then
			return null
		endif
		set tt = CreateTextTagUnitColor("+" + I2S(xp) + "xp!", u, 30, 7 * (1 + 0.01 * I2R(xp)), -1)
		call SetTextTagVelocityBJ(tt, 32, 90)
		call SetTextTagFadeSpan(tt, 2.0, 3.5)
		call SetTextTagPlayer(tt, GetOwningPlayer(u))
		call AddHeroXP(u, xp, true)
		return tt
	endfunction

	function CrookAddGold takes unit u, integer gold, boolean makeSound returns nothing
		local texttag tt = CreateTextTagUnitColor("+" + I2S(gold), u, 0, 10, TextTag_COLOR_GOLD)
		call SetTextTagVelocityBJ(tt, 64.0, 90.0)
		call SetTextTagFadeSpan(tt, 1.0, 1.5)
		call AdjustPlayerStateBJ(gold, GetOwningPlayer(u), PLAYER_STATE_RESOURCE_GOLD)
		call UnitMakeSound(u, "Abilities\\Spells\\Items\\ResourceItems\\ReceiveGold.wav")
	endfunction

	function GetSpellDamage takes unit u returns real
		local real base = BlzGetUnitBaseDamage(u, 1) + GetRandomInt(1, BlzGetUnitDiceSides(u, 1))
		set base = base * (1 + 0.15 * GetPlayerAttr(GetOwningPlayer(u), ATTR_W))
		if IsUnitType(u, UNIT_TYPE_HERO) then
			return GetHeroLevel(u) + base
		endif
		return GetUnitLvl(u) + base
    endfunction

	function InteractUnit takes unit u returns boolean
		if IsUnitInGroup(u, udg_Interact_Group) then
			return false
		endif
		call GroupAddUnit(udg_Interact_Group, u)
		call SaveReal(udg_Interact_Hash, GetHandleId(u), StringHash("time"), GetRandomReal(180, 300))
		call SetUnitVertexColor(u, 192, 192, 192, 128)
		return true
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

	function RockSpawnWorms takes unit rock returns integer
		local real chance = 0.33
		local integer wormType = UNIT_WORM
		local integer i = GetUnitLevel(rock)
		local integer count = 0
		local integer level = GetRandomInt(1, 10)
		local location loc
		if not InteractUnit(rock) then
			return 0
		endif
		if udg_Rain then
			set chance = 2 * chance
		endif
		if RectContainsUnit(gg_rct_Jungle, rock) then
			set wormType = UNIT_GRUBBY
			set level = GetRandomInt(7, 14)
		endif
		loop
			exitwhen i == 0
			if GetRNG(chance) then
				set count = count + 1
				set loc = PolarProjectionXY(GetUnitX(rock), GetUnitY(rock), GetRandomReal(8, 24), GetRandomDirectionDeg())
				call SetUnitLvl(CreateUnitAtLoc(PLAYER_WORMS, wormType, loc, GetRandomDirectionDeg()), level)
				call RemoveLocation(loc)
			endif
			set i = i - 1
		endloop
		set loc = null
		return count
	endfunction

	///////////
	// MUSIC //
	///////////

	function UpdatePlayerMusicBase takes player p, string forced, string skipped returns nothing
		if p != GetLocalPlayer() then
			return
		endif
		if udg_Boss != null then
			call PlayMusic(gg_snd_WeHaveToDefeatIt)
		elseif (RectContainsUnit(gg_rct_Jungle, udg_Crook[GetConvertedPlayerId(p)]) or forced == gg_snd_jungleloq) and skipped != gg_snd_jungleloq then
			call PlayMusic(gg_snd_jungleloq) // Jungle music
		elseif udg_Rain then
			call PlayMusic(gg_snd_RainyWaltz) // Rainy waltz
		else
			call PlayMusic(gg_snd_metinloq) // Default music
		endif
	endfunction

	function UpdatePlayerMusicForce takes player p, string forced returns nothing
		call UpdatePlayerMusicBase(p, forced, null)
	endfunction

	function UpdatePlayerMusicSkip takes player p, string skipped returns nothing
		call UpdatePlayerMusicBase(p, null, skipped)
	endfunction

	function CallbackUpdateMusic takes nothing returns nothing
		call UpdatePlayerMusicBase(GetEnumPlayer(), null, null)
	endfunction

	function UpdateMusic takes nothing returns nothing
		call ForForce(udg_Players, function CallbackUpdateMusic)
	endfunction

	////////////
	// DAMAGE //
	////////////

	function ClearDamageTags takes nothing returns nothing
		set udg_damageSpell = false
		set udg_damageNoCombo = false
		set udg_damageNoOnHit = false
	endfunction

	function DealDamage takes unit source, unit target, real damage, integer tag returns nothing
		if tag == DAMAGE_SPELL then
			set udg_damageSpell = true
		elseif tag == DAMAGE_SPELLNOCOMBO then
			set udg_damageSpell = true
			set udg_damageNoCombo = true
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