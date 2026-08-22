library HotsConst
	globals
		integer ABILITY_DISARM            = 'A00K'
		integer ABILITY_DUAL_ATTACK_SPEED = 'A019'
		integer ABILITY_DUAL_WIELD        = 'A018'
		integer ABILITY_GLOW_LEFT         = 'A01D'
		integer ABILITY_GLOW_RIGHT        = 'A01G'
		integer ABILITY_LIGHT             = 'A00H'

		integer ATTR_Q = 0
		integer ATTR_W = 1
		integer ATTR_E = 2
		integer ATTR_R = 3

        integer BUFF_ID_BEPOWER = 'B001'
        integer BUFF_ID_SONIK   = 'B002'

		integer DAMAGE_SPELL        = 1
		integer DAMAGE_SPELLNOCOMBO = 2

		boolexpr FILTER_LIVING_WORMS
		boolexpr FILTER_WOLF_UNSPAWNABLE
		boolexpr FILTER_EXP_ELIGIBLE

		integer ITEM_APPLE         = 'I000'
		integer ITEM_BEPOWER       = 'I008'
        integer ITEM_BEWORM        = 'I00H'
		integer ITEM_COIN_1        = 'I002'
		integer ITEM_COIN_2        = 'I003'
		integer ITEM_COIN_5        = 'I004'
		integer ITEM_COIN_10       = 'I001'
		integer ITEM_GRUBBY        = 'I00G'
		integer ITEM_STICK         = 'I006'
		integer ITEM_SUGAR         = 'I00F'
		integer ITEM_TORCH         = 'I007'
		integer ITEM_WOODEN_DAGGER = 'I00A'
		integer ITEM_WOODEN_KATANA = 'I00B'
		integer ITEM_WOODEN_AXE    = 'I00E'
		integer ITEM_WORM          = 'I005'

		// TODO: should be defined in Hots.j via function call
        public integer LOOP_TAG_LANTERN = 0
		public integer LOOP_TAG_WOZNY   = 1

		player PLAYER_VILLAGE = Player(10) // Number 11
		player PLAYER_WORMS   = Player(11) // Number 12
		player PLAYER_FLORA   = Player(12) // Number 13

		// Task.j - task IDs
		// TODO: should be defined in Hots.j via function call
		integer TASK_BIOLOG = 1

		integer TECH_ATTACK_RANGE = 'R004'

		integer UNIT_CROOK  = 'H002'
		integer UNIT_FIRE   = 'h005'
		integer UNIT_GRUBBY = 'h009'
		integer UNIT_WOLF   = 'n007'
		integer UNIT_WORM   = 'h003'
	endglobals

	private function FilterExpEligible takes nothing returns boolean
		return GetUnitTypeId(GetFilterUnit()) == UNIT_CROOK
	endfunction

	private function FilterLivingWorms takes nothing returns boolean
		local unit u = GetFilterUnit()
		local boolean result = (GetUnitTypeId(u) == UNIT_WORM or GetUnitTypeId(u) == UNIT_GRUBBY) and IsUnitAliveBJ(u)
		set u = null
		return result
	endfunction

	private function FilterWolfUnspawnable takes nothing returns boolean
		local player passive = Player(PLAYER_NEUTRAL_PASSIVE)
		local unit u = GetFilterUnit()
		local player owner = GetOwningPlayer(u)
		local boolean result = owner != passive and owner != PLAYER_FLORA and IsUnitAliveBJ(u)
		set passive = null
		set u = null
		set owner = null
		return result
	endfunction

	private function Init takes nothing returns nothing
		set FILTER_EXP_ELIGIBLE     = Condition(function FilterExpEligible)
		set FILTER_LIVING_WORMS     = Condition(function FilterLivingWorms)
		set FILTER_WOLF_UNSPAWNABLE = Condition(function FilterWolfUnspawnable)
	endfunction
endlibrary