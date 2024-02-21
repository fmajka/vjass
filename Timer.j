library Timer

	globals
		public hashtable Hash = InitHashtable()
		public integer KeyCount = StringHash("count")

		public timer T
		public unit U
	endglobals


	public function UnitStart takes unit u, string name, real time, code callback returns boolean
		local boolean fresh = false
		local integer unitId = GetHandleId(u)
		local integer keyName = StringHash(name)
		local integer count = LoadInteger(Hash, unitId, KeyCount)

		set T = LoadTimerHandle(Hash, unitId, keyName)
		if T == null then
			set T = CreateTimer()
			// Unit and timer remember each other
			call SaveTimerHandle(Hash, unitId, keyName, T)
			call SaveUnitHandle(Hash, GetHandleId(T), keyName, u)
			set fresh = true
			// Store number of timers on the unit
			call SaveInteger(Hash, unitId, KeyCount, count + 1)
		endif

		call TimerStart(T, time, false, callback)
		return fresh
	endfunction


	public function TimerEnd takes timer t, integer keyName returns nothing
		local integer timerId = GetHandleId(t)
		local integer unitId
		local integer count

		local timer testTimer

		set U = LoadUnitHandle(Hash, timerId, keyName)
		set unitId = GetHandleId(U)
		set count = LoadInteger(Hash, GetHandleId(U), KeyCount)

		call FlushChildHashtable(Hash, timerId)
		call DestroyTimer(t)

		set testTimer = LoadTimerHandle(Hash, unitId, keyName)

		// Only flush unit if there are no timers left
		if count <= 1 then
			call FlushChildHashtable(Hash, unitId)
		else
			call SaveInteger(Hash, unitId, KeyCount, count - 1)
		endif
	endfunction

endlibrary