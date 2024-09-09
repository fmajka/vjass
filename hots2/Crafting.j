library Crafting initializer Init
	globals
		private hashtable hash = InitHashtable()
		private trigger pickupTrigger = CreateTrigger()
		private trigger dropTrigger = CreateTrigger()
		private trigger craftTrigger = CreateTrigger()
		private integer KEY_CHARGES = StringHash("charges")
		private integer KEY_COUNT = StringHash("count")
		private integer KEY_RESULT = StringHash("result")
		private integer KEY_TECH = StringHash("tech")
	endglobals

	private function InitItemTech takes integer itemId, integer techId, boolean countCharges returns nothing
		call SaveInteger(hash, KEY_TECH, itemId, techId)
		call SaveBoolean(hash, itemId, KEY_CHARGES, countCharges)
	endfunction

	private function CreateRecipe takes integer abilityId, integer itemId returns nothing
		call SaveInteger(hash, abilityId, KEY_RESULT, itemId)
	endfunction

	private function AddIngredient takes integer abilityId, integer itemId, integer charges returns nothing
		local integer count = LoadInteger(hash, abilityId, KEY_COUNT)
		call SaveInteger(hash, abilityId, count, itemId)
		call SaveInteger(hash, abilityId, itemId, charges)
		call SaveInteger(hash, abilityId, KEY_COUNT, count + 1)
	endfunction

	function UnitCountItemType takes unit u, integer id, item dropped returns integer
		local integer i = 0
		local integer size = UnitInventorySize(u)
		local integer count = 0
		local boolean countCharges = LoadBoolean(hash, id, KEY_CHARGES)
		local item stack = null
		loop
			exitwhen i == size
			set stack = UnitItemInSlot(u, i)
			if stack != dropped and GetItemTypeId(stack) == id then
				if countCharges then
					set count = count + GetItemCharges(stack)
				else
					set count = count + 1
				endif
			endif
			set i = i + 1
		endloop
		set stack = null
		return count
	endfunction

	private function ItemPickupActions takes nothing returns nothing
		local integer itemId = GetItemTypeId(GetManipulatedItem())
		local integer count = UnitCountItemType(GetTriggerUnit(), itemId, null)
		local integer techId
		if HaveSavedInteger(hash, KEY_TECH, itemId) then
			set techId = LoadInteger(hash, KEY_TECH, itemId)
			call BJDebugMsg("techId: " + I2S(techId) + ", count: " + I2S(count) + ", player: " + GetPlayerName(GetTriggerPlayer()))
			call SetPlayerTechResearched(GetTriggerPlayer(), techId, count)
		endif
	endfunction

	private function ItemDropActions takes nothing returns nothing
		local integer itemId = GetItemTypeId(GetManipulatedItem())
		local integer count = UnitCountItemType(GetTriggerUnit(), itemId, GetManipulatedItem())
		local integer techId
		if HaveSavedInteger(hash, KEY_TECH, itemId) then
			set techId = LoadInteger(hash, KEY_TECH, itemId)
			call BJDebugMsg("techId: " + I2S(techId) + ", count: " + I2S(count) + ", player: " + GetPlayerName(GetTriggerPlayer()))
			call SetPlayerTechResearched(GetTriggerPlayer(), techId, count)
		endif
	endfunction

	private function CraftActions takes nothing returns nothing
		local player p = GetTriggerPlayer()
		local integer abilityId = GetSpellAbilityId()
		local integer count
		local integer itemId
		local integer charges
		local integer techId
		local integer result = LoadInteger(hash, abilityId, KEY_RESULT)
		if result == 0 then
			return
		endif
		set count = LoadInteger(hash, abilityId, KEY_COUNT) - 1
		call BJDebugMsg("Tried to craft, count=" + I2S(count))
		loop
			exitwhen count < 0
			set itemId = LoadInteger(hash, abilityId, count)
			set charges = LoadInteger(hash, abilityId, itemId)
			set techId = LoadInteger(hash, KEY_TECH, itemId)
			call BJDebugMsg("Craft - itemId: " + I2S(itemId) + ", charges: " + I2S(charges) + ", count=" + I2S(count))
			// TODO: remove items
			call SetPlayerTechResearched(p, techId, GetPlayerTechCount(p, techId, true) - charges)
			set count = count - 1
		endloop
		call UnitAddItemByIdSwapped(result, GetTriggerUnit())
		set p = null
	endfunction

	private function Init takes nothing returns nothing
		call TriggerRegisterAnyUnitEventBJ(pickupTrigger, EVENT_PLAYER_UNIT_PICKUP_ITEM)
		call TriggerAddAction(pickupTrigger, function ItemPickupActions)
		call TriggerRegisterAnyUnitEventBJ(dropTrigger, EVENT_PLAYER_UNIT_DROP_ITEM)
		call TriggerAddAction(dropTrigger, function ItemDropActions)
		call TriggerRegisterAnyUnitEventBJ(craftTrigger, EVENT_PLAYER_UNIT_SPELL_EFFECT)
		call TriggerAddAction(craftTrigger, function CraftActions)
		// Match items to research dummies
		call InitItemTech('I005', 'R006', false)
		call InitItemTech('I00G', 'R007', false)
		call InitItemTech('I008', 'R008', false)
		call InitItemTech('I00F', 'R009', true)
		call InitItemTech('I006', 'R00A', false)
		// BeWorm
		call CreateRecipe('A00D', 'I00H')
		call AddIngredient('A00D', 'I00F', 1)
		call AddIngredient('A00D', 'I006', 2)
		// Test
		//call AddIngredient('A00D', 'I005', 1)
		//call AddIngredient('A00D', 'I00G', 1)
		//call AddIngredient('A00D', 'I008', 1)
		//call AddIngredient('A00D', 'I00F', 3)
	endfunction

endlibrary