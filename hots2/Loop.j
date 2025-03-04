//
// Generic loop library
//
// Required global GUI variables:
// TODO: jednak wywal Loop_Tag i Loop_Unit
// - Loop_Unit (Unit)
// - Loop_Tag (Integer)
// - Loop_EventDone (Real)
//

// TODO: this should be a generic library
library Loop
	globals
		private integer KEY_UNIT = StringHash("unit")
		private integer KEY_TAG = StringHash("tag")
		private integer KEY_TIME = StringHash("time")
		// You can map additional data to your unit here!
		public hashtable hash = InitHashtable()
		private integer count = 0
		// Map-specific
		public integer TAG_LANTERN = 0
		public integer TAG_WOZNY = 1
	endglobals

	// Adds the unit to the loop for some time with the specified tag
	// Returns the unit's index if was already looping with this tag or -1 if not
	public function AddUnit takes unit u, real time, integer tag returns integer
		local integer unitId = GetHandleId(u)
		local integer index = count
		local integer ret = -1
		// Check if already looping
		if HaveSavedInteger(hash, unitId, tag) then
			set index = LoadInteger(hash, unitId, tag)
			set ret = index
		else
			set count = count + 1
		endif
		call SaveUnitHandle(hash, index, KEY_UNIT, u)
		call SaveInteger(hash, index, KEY_TAG, tag)
		call SaveReal(hash, index, KEY_TIME, time)
		// Save the index that maps the data on the unit for easy access
		call SaveInteger(hash, unitId, tag, index)
		return ret
	endfunction

	public function Update takes real dt returns nothing
		local integer index = count - 1
		local real time
		loop
			exitwhen index < 0
			set time = LoadReal(hash, index, KEY_TIME)
			if time > 0.0 then
				// Timer's ticking
				call SaveReal(hash, index, KEY_TIME, time - dt)
			else
				// Time elapsed - event!
				set udg_Loop_Unit = LoadUnitHandle(hash, index, KEY_UNIT)
				set udg_Loop_Tag = LoadInteger(hash, index, KEY_TAG)
				set udg_Loop_EventDone = 1.0
				set udg_Loop_EventDone = 0.0
				call FlushChildHashtable(hash, index)
				call FlushChildHashtable(hash, GetHandleId(udg_Loop_Unit))
				// Free unused indeces
				if index == count - 1 then
					set count = count - 1
				endif
			endif
			set index = index - 1
		endloop
	endfunction
endlibrary