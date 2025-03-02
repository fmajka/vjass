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

	// Returns the number of items of type given unit has in its inventory
	public function CountUnitItemType takes unit u, integer itemId, item dropped returns integer
		local integer i = 0
		local integer size = UnitInventorySize(u)
		local integer count = 0
		local boolean countCharges = LoadBoolean(hash, itemId, KEY_CHARGES)
		local item stack = null
		loop
			exitwhen i == size
			set stack = UnitItemInSlot(u, i)
			if stack != dropped and GetItemTypeId(stack) == itemId then
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

	private function UpdatePlayerItemCountBase takes player p, integer itemId, item ignoredItem returns nothing
		local integer playerId = GetConvertedPlayerId(p)
		local integer count
		local integer techId
		if not HaveSavedInteger(hash, KEY_TECH, itemId) then
			return
		endif
		set techId = LoadInteger(hash, KEY_TECH, itemId)
		set count = CountUnitItemType(udg_Chest[playerId], itemId, ignoredItem)
		set count = count + CountUnitItemType(udg_Crook[playerId], itemId, ignoredItem)
		call SetPlayerTechResearched(p, techId, count)
	endfunction

	public function UpdatePlayerItemCount takes player p, integer itemId returns nothing
		call UpdatePlayerItemCountBase(p, itemId, null)
	endfunction

	private function ItemManipulateActions takes nothing returns nothing
		local integer itemId = GetItemTypeId(GetManipulatedItem())
		local item ignoredItem = null
		if GetTriggeringTrigger() == dropTrigger then
			set ignoredItem = GetManipulatedItem()
		endif
		call UpdatePlayerItemCountBase(GetTriggerPlayer(), itemId, ignoredItem)
		set ignoredItem = null
	endfunction

	// Removes a specified number of itemId from unit's inventory
	// Returns remaining item count to be removed
	private function UnitRemoveItemCount takes unit u, integer itemId, integer count returns integer
		local integer slot = 0
		local integer size = UnitInventorySize(u)
		local integer charges
		local boolean countCharges = LoadBoolean(hash, itemId, KEY_CHARGES)
		local item stack
		loop
			exitwhen slot == size or count == 0
			set stack = UnitItemInSlot(u, slot)
			if stack != null and GetItemTypeId(stack) == itemId then
				if countCharges then
					set charges = GetItemCharges(stack)
					if charges > count then
						call SetItemCharges(stack, charges - count)
						call UpdatePlayerItemCount(GetOwningPlayer(u), itemId)
						return 0
					else
						call RemoveItem(stack)
						set count = count - charges
					endif
				else
					call RemoveItem(stack)
					set count = count - 1
				endif
			endif
			set slot = slot + 1
		endloop
		set stack = null
		return count
	endfunction

	private function CraftActions takes nothing returns nothing
		local player p = GetTriggerPlayer()
		local integer playerId = GetConvertedPlayerId(p)
		local integer abilityId = GetSpellAbilityId()
		local integer count
		local integer itemId
		local integer charges
		local integer techId
		local integer result = LoadInteger(hash, abilityId, KEY_RESULT)
		if not IsPlayerInForce(p, udg_Players) or result == 0 then
			return
		endif
		set count = LoadInteger(hash, abilityId, KEY_COUNT) - 1
		loop
			exitwhen count < 0
			set itemId = LoadInteger(hash, abilityId, count)
			set charges = LoadInteger(hash, abilityId, itemId)
			set techId = LoadInteger(hash, KEY_TECH, itemId)
			// First remove items from chest, then the remaining from Crook's inventory
			call UnitRemoveItemCount(udg_Crook[playerId], itemId, UnitRemoveItemCount(udg_Chest[playerId], itemId, charges))
			set count = count - 1
		endloop
		call UnitAddItemByIdSwapped(result, GetTriggerUnit())
		if GetLocalPlayer() == p then
			call PlaySoundBJ( gg_snd_PickUpItem )
		endif
		set p = null
	endfunction

	private function Init takes nothing returns nothing
		call TriggerRegisterAnyUnitEventBJ(pickupTrigger, EVENT_PLAYER_UNIT_PICKUP_ITEM)
		call TriggerAddAction(pickupTrigger, function ItemManipulateActions)
		call TriggerRegisterAnyUnitEventBJ(dropTrigger, EVENT_PLAYER_UNIT_DROP_ITEM)
		call TriggerAddAction(dropTrigger, function ItemManipulateActions)
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
		call AddIngredient('A00D', 'I005', 1)
		call AddIngredient('A00D', 'I00G', 1)
		call AddIngredient('A00D', 'I008', 1)
		call AddIngredient('A00D', 'I00F', 3)
		// call AddIngredient('A00D', 'I00F', 1)
		// call AddIngredient('A00D', 'I006', 2)
	endfunction

endlibrary