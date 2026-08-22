library Loot initializer Init
	globals
		private integer KEY_MODEL = StringHash("model")
		private integer KEY_SCALE = StringHash("scale")
		private integer KEY_RED = StringHash("red")
		private integer KEY_GREEN = StringHash("green")
		private integer KEY_BLUE = StringHash("blue")
		private integer KEY_FX = StringHash("fx")
		private integer KEY_VZ = StringHash("vz")
		private integer KEY_ROLL = StringHash("roll")
		private integer KEY_YAW = StringHash("yaw")
		private integer KEY_VROLL= StringHash("vroll")
		private integer KEY_VYAW = StringHash("vyaw")

		private string DEFAULT_PATH = "Objects\\InventoryItems\\TreasureChest\\treasurechest.mdl"
		private string EYE_CANDY_PATH = "Objects\\InventoryItems\\tomeRed\\tomeRed.mdl"
		
		private hashtable mHash = InitHashtable()
		private item array mArrItem
		private integer mItemCount = 0

		// TODO: init from outside?
		private real GRAVITY = 125.0
	endglobals

	// Sets item's model path and scale in the system; if path is null then DEFAULT_PATH is used
	private function SetItemModel takes integer id, string path, real scale returns nothing
		if path != null then
			call SaveStr(mHash, id, KEY_MODEL, path)
		endif
		call SaveReal(mHash, id, KEY_SCALE, scale)
	endfunction

	private function SetItemColor takes integer id, integer red, integer green, integer blue returns nothing
		call SaveInteger(mHash, id, KEY_RED, red)
		call SaveInteger(mHash, id, KEY_GREEN, green)
		call SaveInteger(mHash, id, KEY_BLUE, blue)
	endfunction

	private function SetItemModelEx takes integer id, string path, real scale, integer red, integer green, integer blue returns nothing
		call SetItemModel(id, path, scale)
		call SetItemColor(id, red, green, blue)
	endfunction

	// TODO: init in Hots.j
	private function Init takes nothing returns nothing
		call SetItemModel(ITEM_APPLE, "war3mapImported\\RedApple.mdl", 2.0)
		call SetItemModel(ITEM_COIN_1, "Objects\\InventoryItems\\PotofGold\\PotofGold.mdl", 0.7)
		call SetItemModelEx(ITEM_COIN_2, "Objects\\InventoryItems\\PotofGold\\PotofGold.mdl", 0.75, 255, 155, 255)
		call SetItemModelEx(ITEM_COIN_5, "Objects\\InventoryItems\\PotofGold\\PotofGold.mdl", 0.8, 100, 255, 100)
		call SetItemModelEx(ITEM_COIN_10, "Objects\\InventoryItems\\PotofGold\\PotofGold.mdl", 0.85, 0, 30, 255)
		call SetItemModel(ITEM_STICK, "war3mapImported\\branch2.mdl", 0.8)
		call SetItemModel(ITEM_TORCH, "TinyTorch1.mdl", 0.8)
		call SetItemModel(ITEM_SUGAR, "war3mapImported\\sugarrchest.mdl", 0.75)
	endfunction

	public function ArcItem takes item drop returns nothing
		local real duration = GetRandomReal(0.75, 1.0)
		local integer itemId = GetHandleId(drop)
		local integer typeId = GetItemTypeId(drop)
		local string path = DEFAULT_PATH
		local effect fx
		if IsItemOwned(drop) then
			return
		endif
		call SetItemVisible(drop, false)
		if HaveSavedString(mHash, typeId, KEY_MODEL) then
			set path = LoadStr(mHash, typeId, KEY_MODEL)
		endif
		set fx = AddSpecialEffect(path, GetItemX(drop), GetItemY(drop))
		call BlzSetSpecialEffectScale(fx, LoadReal(mHash, typeId, KEY_SCALE))
		if HaveSavedInteger(mHash, typeId, KEY_RED) then
			call BlzSetSpecialEffectColor(fx, LoadInteger(mHash, typeId, KEY_RED), LoadInteger(mHash, typeId, KEY_GREEN), LoadInteger(mHash, typeId, KEY_BLUE))
		endif
		call SaveEffectHandle(mHash, itemId, KEY_FX, fx)
		call SaveReal(mHash, itemId, KEY_VZ, GRAVITY * duration / 2.0)
		call SaveReal(mHash, itemId, KEY_ROLL, 0)
		call SaveReal(mHash, itemId, KEY_YAW, 0)
		call SaveReal(mHash, itemId, KEY_VROLL, 1.5 * bj_PI / duration)
		call SaveReal(mHash, itemId, KEY_VYAW, 2.0 * bj_PI / duration)
		set mArrItem[mItemCount] = drop
		set mItemCount = mItemCount + 1
		set fx = null
	endfunction

	// TODO: rename to Update
	public function ArcUpdate takes real dt returns nothing
		local integer i = mItemCount - 1
		local integer itemId
		local real locZ
		local real newZ
		local real vz
		local real roll
		local real yaw
		local item drop
		local effect fx
		local location loc
		loop
			exitwhen i < 0
			set drop = mArrItem[i]
			set loc = GetItemLoc(drop)
			set itemId = GetHandleId(drop)
			set fx = LoadEffectHandle(mHash, itemId, KEY_FX)
			set vz = LoadReal(mHash, itemId, KEY_VZ)
			set newZ = BlzGetLocalSpecialEffectZ(fx) + vz
			set locZ = GetLocationZ(loc)
			// Hit the ground check
			if newZ < locZ then
				call BlzSetSpecialEffectScale(fx, 0.0)
				call DestroyEffect(fx)
				call SetItemVisible(drop, true)
				call FlushChildHashtable(mHash, itemId)
				// Bonus effect for cool drops
				if GetItemLevel(drop) > 1 then
					set fx = AddSpecialEffect(EYE_CANDY_PATH, GetItemX(drop), GetItemY(drop))
					call BlzSetSpecialEffectScale(fx, 0.0)
					call BlzSetSpecialEffectTimeScale(fx, 10.0)
					call DestroyEffect(fx)
				endif
				// Pop form array
				if i == mItemCount - 1 then
					set mArrItem[i] = null
					set mItemCount = mItemCount - 1
				endif
			else
				set roll = LoadReal(mHash, itemId, KEY_ROLL) + LoadReal(mHash, itemId, KEY_VROLL) * dt
				set yaw =  LoadReal(mHash, itemId, KEY_YAW)  + LoadReal(mHash, itemId, KEY_VYAW)  * dt
				call BlzSetSpecialEffectRoll(fx, roll)
				call BlzSetSpecialEffectYaw(fx, yaw)
				call BlzSetSpecialEffectZ(fx, newZ)
				call SaveReal(mHash, itemId, KEY_ROLL, roll)
				call SaveReal(mHash, itemId, KEY_YAW, yaw)
				call SaveReal(mHash, itemId, KEY_VZ, vz - GRAVITY * dt)
			endif
			call RemoveLocation(loc)
			set i = i - 1
		endloop
		set drop = null
		set fx = null
		set loc = null
	endfunction
endlibrary