library Weapon initializer init

	globals
		public hashtable Hash = InitHashtable()

		public integer KeyWeapon = StringHash("weapon")
		public integer KeyDamage = StringHash("damage")
		public integer KeyDiceSides = StringHash("dicesides")
		public integer KeyRange = StringHash("range")
		public integer KeyInterval = StringHash("interval")
		public integer KeyWeaponType = StringHash("weapontype")
		public integer KeyAttachment = StringHash("attachment")
		public integer KeyName = StringHash("name")
		public integer KeyCount = StringHash("count")

		// Weapon type IDs (used for playing weapon sounds)
		public integer METAL_HEAVY_BASH = 8
		public integer WOOD_HEAVY_BASH = 16

		// Attack range upgrade
		public integer TECH_ATTACK_RANGE = 'R004'

		// Incremented when InitWeapon is called
		public integer COUNT = 0
		public integer array ID_ARR // <-- Stores weapon item IDs

		// Weapon item IDs
		public integer ITEM_STICK = 'I006'
		public integer ITEM_TORCH = 'I007'
	endglobals

	// Adds a new weapon to the system
	public function InitWeapon takes integer itemId, integer damage, integer diceSides, integer range, real intervalRatio, integer weaponTypeId, integer attachmentId, string name returns nothing
		call SaveInteger(Hash, itemId, KeyDamage, damage)
		call SaveInteger(Hash, itemId, KeyDiceSides, diceSides)
		call SaveInteger(Hash, itemId, KeyRange, range)
		call SaveReal(Hash, itemId, KeyInterval, intervalRatio)
		call SaveInteger(Hash, itemId, KeyWeaponType, weaponTypeId)
		call SaveInteger(Hash, itemId, KeyAttachment, attachmentId)
		call SaveStr(Hash, itemId, KeyName, name)

		set ID_ARR[COUNT] = itemId
		set COUNT = COUNT + 1
	endfunction

	// TODO: SPELL_COUNT, spells stored in a hashtable matching weapon's id
	public function WeaponAddSpell takes integer weaponId, integer spellId returns integer
		local integer count = LoadInteger(Hash, weaponId, KeyCount)
		call SaveInteger(Hash, weaponId, count, spellId)
		set count = count + 1
		call SaveInteger(Hash, weaponId, KeyCount, count)
		return count
	endfunction

	private function init takes nothing returns nothing
		// Args: id, damage, diceSides, rangeLevel, intervalRatio, weaponTypeId, attachmentId, name (crook postfix)
		call InitWeapon(ITEM_STICK, 1, 0, 2, 1.00, WOOD_HEAVY_BASH, 'A00A', "z Patykiem")
		call WeaponAddSpell(ITEM_STICK, 'A00C')
		call InitWeapon(ITEM_TORCH, 1, 0, 2, 1.00, WOOD_HEAVY_BASH, 'A00B', "z Pochodnią")
		call WeaponAddSpell(ITEM_TORCH, 'A00C')
		call WeaponAddSpell(ITEM_TORCH, 'A00E')
	endfunction


	public function GetUnitWeapon takes unit u returns item
 		return LoadItemHandle(Hash, GetHandleId(u), KeyWeapon)
	endfunction


	public function UnitEquipWeapon takes unit u, item weapon returns nothing
		local player p = GetOwningPlayer(u)
		local integer unitId = GetHandleId(u)
		local boolean isHero = IsUnitType(u, UNIT_TYPE_HERO)
		local integer count

		local item currentWeapon = GetUnitWeapon(u)
		local integer weaponId = GetItemTypeId(currentWeapon)

		// Weapon stats
		local integer damage = BlzGetUnitBaseDamage(u, 1)
		local integer diceSides = BlzGetUnitDiceSides(u, 1)
		local integer range = GetPlayerTechCount(p, TECH_ATTACK_RANGE, true)
		local real interval = BlzGetUnitAttackCooldown(u, 1)
		local string name = GetUnitName(u)

		// Unequip currently held weapon
		if currentWeapon != null then
			set damage = damage - LoadInteger(Hash, weaponId, KeyDamage)
			set diceSides = diceSides - LoadInteger(Hash, weaponId, KeyDiceSides)
			set range = 0
			set interval = interval / LoadReal(Hash, weaponId, KeyInterval)

			call UnitRemoveAbility(u, LoadInteger(Hash, weaponId, KeyAttachment))
			// Remove weapon abilities
			set count = LoadInteger(Hash, weaponId, KeyCount) - 1
			loop
				exitwhen count < 0
				call UnitRemoveAbility(u, LoadInteger(Hash, weaponId, count))
				set count = count - 1
			endloop

			if isHero then
				set name = LoadStr(Hash, unitId, KeyName) // <-- Stored base name
			endif
		endif

		// Load newly equipped weapon's stats
		if currentWeapon != weapon then
			call SaveItemHandle(Hash, unitId, KeyWeapon, weapon)
			set weaponId = GetItemTypeId(weapon)

			set damage = damage + LoadInteger(Hash, weaponId, KeyDamage)
			set diceSides = diceSides + LoadInteger(Hash, weaponId, KeyDiceSides)
			set range = LoadInteger(Hash, weaponId, KeyRange)
			set interval = interval * LoadReal(Hash, weaponId, KeyInterval)

			call UnitAddAbility(u, LoadInteger(Hash, weaponId, KeyAttachment))
			// Add new weapon's abilities
			set count = LoadInteger(Hash, weaponId, KeyCount) - 1
			loop
				exitwhen count < 0
				call UnitAddAbility(u, LoadInteger(Hash, weaponId, count))
				set count = count - 1
			endloop

			if isHero then
				call SaveInteger(Hash, unitId, KeyWeaponType, LoadInteger(Hash, weaponId, KeyWeaponType))
				call SaveStr(Hash, unitId, KeyName, name) // <-- Previous name
				set name = name + " " + LoadStr(Hash, weaponId, KeyName)
			endif
		// Weaponless - clear all weapon data
		else
			call FlushChildHashtable(Hash, unitId)
		endif

		// Set stats
		call BlzSetUnitBaseDamage(u, damage, 1)
		call BlzSetUnitBaseDamage(u, damage, 2)
		call BlzSetUnitDiceSides(u, diceSides, 1)
		call BlzSetUnitDiceSides(u, diceSides, 2)
		call BlzSetUnitAttackCooldown(u, interval, 1)
		call BlzSetUnitAttackCooldown(u, interval, 2)

		// Crook additional props
		if isHero then
			call SetPlayerTechResearched(p, TECH_ATTACK_RANGE, range)
			call BlzSetUnitName(u, name)
		endif

		// Exception - light system update
		if GetItemTypeId(currentWeapon) == ITEM_TORCH or GetItemTypeId(weapon) == ITEM_TORCH then
			set udg_Light_Unit = u
			set udg_Light_Event = 1
		endif

		set currentWeapon = null
		set p = null
	endfunction


	// Play unit's weapon sound matching target's armor type
	public function CrookPlaySound takes unit source, unit target returns nothing
		local integer sourceId = GetHandleId(source)
		local integer weaponTypeId = METAL_HEAVY_BASH
		if HaveSavedInteger(Hash, sourceId, KeyWeaponType) then
			set weaponTypeId = LoadInteger(Hash, sourceId, KeyWeaponType)
		endif

		call UnitDamageTarget(source, target, 0.00, true, false, ATTACK_TYPE_HERO, DAMAGE_TYPE_UNIVERSAL, ConvertWeaponType(weaponTypeId))
	endfunction

endlibrary