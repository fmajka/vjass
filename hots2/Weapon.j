library Weapon initializer init

	globals
		public hashtable Hash = InitHashtable()

		public integer KeyHand = StringHash("hand")
		public integer KeyWeapon = StringHash("weapon1")
		public integer KeyWeapon2 = StringHash("weapon2")
		public integer KeyDamage = StringHash("damage")
		public integer KeyDiceSides = StringHash("dicesides")
		public integer KeyRange = StringHash("range")
		public integer KeyInterval = StringHash("interval")
		public integer KeyWeaponType = StringHash("weapontype")
		public integer KeyAttachment = StringHash("attachment1")
		public integer KeyAttachment2 = StringHash("attachment2")
		public integer KeySpell = StringHash("spell1")
		public integer KeySpell2 = StringHash("spell2")
		public integer KeyName = StringHash("name")
		public integer KeyTwoHanded = StringHash("twohanded")
		public integer KeyTag = StringHash("tag")
		public integer KeyCount = StringHash("count")

		// Weapon type IDs (used for playing weapon sounds)
		public integer METAL_HEAVY_BASH = 8
		public integer WOOD_HEAVY_BASH = 16
		public integer METAL_MEDIUM_CHOP = 2

		// Dual wield passive ability ID
		integer ABILITY_DUAL_WIELD = 'A018'
		// Dual wield attack speed bonus ability ID
		integer ABILITY_DUAL_ATTACK_SPEED = 'A019'
		// Attack range upgrade
		integer TECH_ATTACK_RANGE = 'R004'

		// Incremented when InitWeapon is called
		public integer COUNT = 0
		public integer array ID_ARR // <-- Stores weapon item IDs

		// Weapon item IDs
		public integer ITEM_STICK = 'I006'
		public integer ITEM_TORCH = 'I007'
		public integer ITEM_WOODEN_DAGGER = 'I00A'
		public integer ITEM_WOODEN_KATANA = 'I00B'
		public integer ITEM_WOODEN_AXE = 'I00E'
	endglobals

	// Adds a new weapon to the system
	private function InitWeapon takes integer itemId, integer damage, integer diceSides, integer range, real intervalRatio, integer weaponTypeId, integer attachmentId, integer spellId, string name, boolean twoHanded returns nothing
		call SaveInteger(Hash, itemId, KeyDamage, damage)
		call SaveInteger(Hash, itemId, KeyDiceSides, diceSides)
		call SaveInteger(Hash, itemId, KeyRange, range)
		call SaveReal(Hash, itemId, KeyInterval, intervalRatio)
		call SaveInteger(Hash, itemId, KeyWeaponType, weaponTypeId)
		call SaveInteger(Hash, itemId, KeyAttachment, attachmentId)
		call SaveInteger(Hash, itemId, KeySpell, spellId)
		call SaveStr(Hash, itemId, KeyName, name)
		call SaveBoolean(Hash, itemId, KeyTwoHanded, twoHanded)
		set ID_ARR[COUNT] = itemId
		set COUNT = COUNT + 1
	endfunction

	// Sets alternate attachment and spell for the weapon wielded in off-hand
	private function InitWeaponDual takes integer itemId, integer attachmentId, integer spellId returns nothing
		local integer primarySpellId = LoadInteger(Hash, itemId, KeySpell)
		call SaveInteger(Hash, itemId, KeyAttachment2, attachmentId)
		call SaveInteger(Hash, itemId, KeySpell2, spellId)
		// Dynamically update secondary spell's tooltip to primary one's
		call BlzSetAbilityTooltip(spellId, BlzGetAbilityTooltip(primarySpellId, 0), 0)
		call BlzSetAbilityTooltip(spellId, BlzGetAbilityTooltip(primarySpellId, 1), 1)
		call BlzSetAbilityActivatedExtendedTooltip(spellId, BlzGetAbilityActivatedExtendedTooltip(primarySpellId, 0), 0)
		call BlzSetAbilityActivatedExtendedTooltip(spellId, BlzGetAbilityActivatedExtendedTooltip(primarySpellId, 1), 1)
	endfunction

	// Add a bonus ability to a weapon
	private function WeaponAddSpell takes integer weaponId, integer spellId returns integer
		local integer count = LoadInteger(Hash, weaponId, KeyCount)
		call SaveInteger(Hash, weaponId, count, spellId)
		set count = count + 1
		call SaveInteger(Hash, weaponId, KeyCount, count)
		return count
	endfunction

	private function init takes nothing returns nothing
		// Args: id, damage, diceSides, rangeLevel, intervalRatio, weaponTypeId, attachmentId, spellId, name (crook postfix)
		call InitWeapon(ITEM_STICK, 1, 0, 2, 1.00, WOOD_HEAVY_BASH, 'A00A', 'A00C', "z Patykiem", false)
		call InitWeaponDual(ITEM_STICK, 'A011', 'A010')

		call InitWeapon(ITEM_TORCH, 1, 0, 2, 1.00, WOOD_HEAVY_BASH, 'A00B', 'A00C', "z Pochodnią", false)
		call InitWeaponDual(ITEM_TORCH, 'A012', 'A010')
		call WeaponAddSpell(ITEM_TORCH, 'A00E')

		call InitWeapon(ITEM_WOODEN_DAGGER, 3, 0, 2, 1.00, WOOD_HEAVY_BASH, 'A00Q', 'A00P', "ze Sztyletem", false)
		call InitWeaponDual(ITEM_WOODEN_DAGGER, 'A014', 'A013')

		call InitWeapon(ITEM_WOODEN_KATANA, 4, 1, 6, 1.00, WOOD_HEAVY_BASH, 'A00R', 'A00O', "z Kataną", true)
		call WeaponAddSpell(ITEM_WOODEN_KATANA, 'A00N')
		call SaveStr(Hash, ITEM_WOODEN_KATANA, KeyTag, "flesh") // Katana special animation tag
		
		call InitWeapon(ITEM_WOODEN_AXE, 6, 0, 2, 1.15, METAL_MEDIUM_CHOP, 'A00X', 'A00W', "z Siekierką", false)
		call InitWeaponDual(ITEM_WOODEN_AXE, 'A015', 'A016')
	endfunction

	function GetUnitDualProficiency takes unit u returns integer
		return IMinBJ(GetPlayerTechCount(GetOwningPlayer(u), 'R000', true), GetPlayerTechCount(GetOwningPlayer(u), 'R001', true))
	endfunction

	// A unit is dual wielding when weapons are equipped in both hands
	function IsUnitDualWielding takes unit u returns boolean
		return HaveSavedHandle(Hash, GetHandleId(u), KeyWeapon) and HaveSavedHandle(Hash, GetHandleId(u), KeyWeapon2)
	endfunction

	function GetUnitHandIndex takes unit u returns integer
		if HaveSavedInteger(Hash, GetHandleId(u), KeyHand) then
			return LoadInteger(Hash, GetHandleId(u), KeyHand)
		endif
		return 1
	endfunction

	// Get weapon used by unit in specific hand (current hand if handIndex == 0)
	function GetUnitWeapon takes unit u, integer handIndex returns item
		if handIndex == 0 then
			set handIndex = GetUnitHandIndex(u)
		endif
 		return LoadItemHandle(Hash, GetHandleId(u), StringHash("weapon" + I2S(handIndex)))
	endfunction

	// Updates unit stats when switching weapons / hands
	private function UnitSwitchWeapon takes unit u, item prevWeapon, item weapon returns nothing
		local player p = GetOwningPlayer(u)
		local boolean isHero = IsUnitType(u, UNIT_TYPE_HERO)
		local integer unitId = GetHandleId(u)
		local integer weaponId = GetItemTypeId(prevWeapon)
		local integer count
		// Weapon stats
		local integer damage = BlzGetUnitBaseDamage(u, 1)
		local integer diceSides = BlzGetUnitDiceSides(u, 1)
		local integer range = GetPlayerTechCount(p, TECH_ATTACK_RANGE, true)
		local real interval = BlzGetUnitAttackCooldown(u, 1)
		// Unequip currently held weapon
		if prevWeapon != null then
			set damage = damage - LoadInteger(Hash, weaponId, KeyDamage)
			set diceSides = diceSides - LoadInteger(Hash, weaponId, KeyDiceSides)
			set range = 0
			set interval = interval / LoadReal(Hash, weaponId, KeyInterval)
			set count = LoadInteger(Hash, weaponId, KeyCount) - 1
			loop
				exitwhen count < 0
				call UnitRemoveAbility(u, LoadInteger(Hash, weaponId, count))
				set count = count - 1
			endloop
			if HaveSavedString(Hash, weaponId, KeyTag) then
				call AddUnitAnimationProperties(u, LoadStr(Hash, weaponId, KeyTag), false)
			endif
		endif
		// Load newly equipped weapon's stats
		if weapon != null and prevWeapon != weapon then
			set weaponId = GetItemTypeId(weapon)
			set damage = damage + LoadInteger(Hash, weaponId, KeyDamage)
			set diceSides = diceSides + LoadInteger(Hash, weaponId, KeyDiceSides)
			set range = LoadInteger(Hash, weaponId, KeyRange)
			set interval = interval * LoadReal(Hash, weaponId, KeyInterval)
			set count = LoadInteger(Hash, weaponId, KeyCount) - 1
			loop
				exitwhen count < 0
				call UnitAddAbility(u, LoadInteger(Hash, weaponId, count))
				set count = count - 1
			endloop
			if HaveSavedString(Hash, weaponId, KeyTag) then
				call AddUnitAnimationProperties(u, LoadStr(Hash, weaponId, KeyTag), true)
			endif
		endif
		// Set stats
		call BlzSetUnitBaseDamage(u, damage, 1)
		call BlzSetUnitBaseDamage(u, damage, 2)
		call BlzSetUnitDiceSides(u, diceSides, 1)
		call BlzSetUnitDiceSides(u, diceSides, 2)
		call BlzSetUnitAttackCooldown(u, interval, 1)
		call BlzSetUnitAttackCooldown(u, interval, 2)
		if isHero then
			call SetPlayerTechResearched(p, TECH_ATTACK_RANGE, range)
		endif
		set p = null
	endfunction

	// Switch hand to a specific one or the other if handIndex == 0
	function UnitSwitchHand takes unit u, integer handIndex returns nothing
		local integer prevIndex = GetUnitHandIndex(u)
		if prevIndex == handIndex then
			return // <-- no changes needed
		endif
		if handIndex == 0 then
			set handIndex = 3 - prevIndex
		endif
		call SaveInteger(Hash, GetHandleId(u), KeyHand, handIndex)
		call UnitSwitchWeapon(u, GetUnitWeapon(u, prevIndex), GetUnitWeapon(u, handIndex))
	endfunction

	// Only handles persistent stuff - also see UnitSwitchWeapon
	function UnitEquipWeaponIndex takes unit u, item weapon, integer handIndex returns nothing
		local item prevWeapon = GetUnitWeapon(u, handIndex)
		local integer unitId = GetHandleId(u)
		local integer weaponId = GetItemTypeId(prevWeapon)
		local integer keyWeapon = StringHash("weapon" + I2S(handIndex))
		local integer keyAttachment = StringHash("attachment" + I2S(handIndex))
		local integer keySpell = StringHash("spell" + I2S(handIndex))
		local string name = "Crook"
		local item exceptWeapon = null
		// Cancel when trying to equip a two-handed weapon as secondary
		if handIndex == 2 and LoadBoolean(Hash, GetItemTypeId(weapon), KeyTwoHanded) then
			return
		endif
		// Unequip current weapon when it's two-handed and equipping secondary weapon
		set exceptWeapon = GetUnitWeapon(u, 1)
		if handIndex == 2 and exceptWeapon != null and LoadBoolean(Hash, GetItemTypeId(exceptWeapon), KeyTwoHanded) then
			call UnitEquipWeaponIndex(u, exceptWeapon, 1)
		endif
		// Unequip secondary weapon when trying to equip a two-handed weapon
		set exceptWeapon = GetUnitWeapon(u, 2)
		if handIndex == 1 and exceptWeapon != null and LoadBoolean(Hash, GetItemTypeId(weapon), KeyTwoHanded) then
			call UnitEquipWeaponIndex(u, exceptWeapon, 2)
		endif
		// Unequip currently held weapon
		if prevWeapon != null then
			call UnitRemoveAbility(u, LoadInteger(Hash, weaponId, keyAttachment))
			call UnitRemoveAbility(u, LoadInteger(Hash, weaponId, keySpell))
			call SetItemDroppable(prevWeapon, true)
		endif
		// Update unit stats if hands match
		if GetUnitHandIndex(u) == handIndex then
			call UnitSwitchWeapon(u, prevWeapon, weapon)
		endif
		// Load newly equipped weapon's stats
		if prevWeapon != weapon then
			set weaponId = GetItemTypeId(weapon)
			call SaveItemHandle(Hash, unitId, keyWeapon, weapon)
			call UnitAddAbility(u, LoadInteger(Hash, weaponId, keyAttachment))
			call UnitAddAbility(u, LoadInteger(Hash, weaponId, keySpell))
			call SetItemDroppable(weapon, false)
		else
			if not IsUnitDualWielding(u) then
				call UnitSwitchHand(u, 1)
			endif
			call RemoveSavedHandle(Hash, unitId, keyWeapon)
		endif
		// Exception - light system update
		if GetItemTypeId(prevWeapon) == ITEM_TORCH or GetItemTypeId(weapon) == ITEM_TORCH then
			set udg_Light_Unit = u
			set udg_Light_Event = 1
		endif
		// Dual wield passive dummy
		if GetUnitWeapon(u, 2) == null and (prevWeapon == weapon or not LoadBoolean(Hash, weaponId, KeyTwoHanded)) then
			call UnitAddAbility(u, ABILITY_DUAL_WIELD)
			call SetUnitAbilityLevel(u, ABILITY_DUAL_WIELD, GetUnitDualProficiency(u))
		else
			call UnitRemoveAbility(u, ABILITY_DUAL_WIELD)
		endif
		// Dual wield attack speed
		if IsUnitDualWielding(u) then
			call UnitAddAbility(u, ABILITY_DUAL_ATTACK_SPEED)
			call SetUnitAbilityLevel(u, ABILITY_DUAL_ATTACK_SPEED, GetUnitDualProficiency(u))
		else
			call UnitRemoveAbility(u, ABILITY_DUAL_ATTACK_SPEED)
		endif
		// Change Crook's name
		if IsUnitType(u, UNIT_TYPE_HERO) then
			if IsUnitDualWielding(u) then
				set name = "Crookito"
			endif
			set weapon = GetUnitWeapon(u, 1)
			if weapon != null then
				set name = name + " " + LoadStr(Hash, GetItemTypeId(weapon), KeyName)
			endif
			call BlzSetUnitName(u, name)
		endif
		set prevWeapon = null
		set exceptWeapon = null
	endfunction

	// Equips the weapon to the main hand
	function UnitEquipWeapon takes unit u, item weapon returns nothing
		call UnitEquipWeaponIndex(u, weapon, 1)
	endfunction

	// Play unit's weapon sound matching target's armor type
	public function CrookPlaySound takes unit source, unit target returns nothing
		local integer sourceId = GetHandleId(source)
		local integer weaponTypeId = METAL_HEAVY_BASH
		local item weapon = GetUnitWeapon(source, 0)
		if weapon != null then
			set weaponTypeId = LoadInteger(Hash, GetItemTypeId(weapon), KeyWeaponType)
		endif
		call UnitDamageTarget(source, target, 0.00, true, false, ATTACK_TYPE_HERO, DAMAGE_TYPE_UNIVERSAL, ConvertWeaponType(weaponTypeId))
	endfunction

endlibrary