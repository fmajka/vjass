library Audio
	globals
		hashtable hash = InitHashtable()
		sound lastSound = null
		public integer PRIO_DEATH = 10
	endglobals

	// Base extendable function for playing sounds, used by below functions
	private function UnitMakeSoundBase takes unit u, string path, real pitch, boolean kill returns nothing
		// TODO: a more generic check
		if not IsUnitVisible(u, PLAYER_VILLAGE) then
			return
		endif
		//"war3mapImported\\drincc.mp3"
		set lastSound = CreateSound(path, false, true, false, 10, 10, "DefaultEAXON")
		call SetSoundDuration(lastSound, GetSoundFileDuration(path))
		call SetSoundChannel(lastSound, 0)
		call SetSoundVolume(lastSound, 127)
		call SetSoundPitch(lastSound, pitch)
		call SetSoundDistances(lastSound, 600.0, 10000.0)
		call SetSoundDistanceCutoff(lastSound, 3000.0)
		call SetSoundConeAngles(lastSound, 0.0, 0.0, 127)
		call SetSoundConeOrientation(lastSound, 0.0, 0.0, 0.0)
		call AttachSoundToUnit(lastSound, u)
		call StartSound(lastSound)
		if kill then
			call KillSoundWhenDone(lastSound)
		endif
	endfunction

	// Create and play a new basic 3D sound for players
	function UnitMakeSound takes unit u, string path returns nothing
		call UnitMakeSoundBase(u, path, 1.0, true)
	endfunction

	// Also adjust pitch
	function UnitMakeSoundPitch takes unit u, string path, real pitch returns nothing
		call UnitMakeSoundBase(u, path, pitch, true)
	endfunction

	// Speech cleanup
	private function SpeechTimerCallback takes nothing returns nothing
		local timer t = GetExpiredTimer()
		local unit u = LoadUnitHandle(hash, GetHandleId(t), StringHash("unit"))
		set lastSound = LoadSoundHandle(hash, GetHandleId(u), StringHash("speech"))
		call StopSound(lastSound, true, false)
		call FlushChildHashtable(hash, GetHandleId(u))
		call FlushChildHashtable(hash, GetHandleId(t))
		call DestroyTimer(t)
		set u = null
		set t = null
	endfunction

	// Incorporates speech, sounds with priority == 0 or positive can be overriden by equal prio
	function UnitSpeak takes unit u, string path, integer prio returns nothing
		local integer id = GetHandleId(u)
		local integer currentPrio = LoadInteger(hash, id, StringHash("prio"))
		local timer t
		set lastSound = null
		// Can only speak death quotes when dead
		// TODO: PRIO_DEATH isn't handled correctly?
		if not IsUnitAliveBJ(u) and IAbsBJ(prio) < PRIO_DEATH then
			return
		endif
		// Check if can speak
		if IAbsBJ(prio) > IAbsBJ(currentPrio) or (IAbsBJ(prio) == IAbsBJ(currentPrio) and currentPrio >= 0) then
			// Stop currently playing quote
			set lastSound = LoadSoundHandle(hash, id, StringHash("speech"))
			if lastSound != null then
				call StopSound(lastSound, true, false)
				set t = LoadTimerHandle(hash, id, StringHash("timer"))
			else
				set t = CreateTimer()
				call SaveTimerHandle(hash, id, StringHash("timer"), t)
			endif
			// Set new quote
			call UnitMakeSoundBase(u, path, 1.0, false)
			call SaveSoundHandle(hash, id, StringHash("speech"), lastSound)
			call SaveInteger(hash, id, StringHash("prio"), prio)
			// Quote timer with saved unit
			call SaveUnitHandle(hash, GetHandleId(t), StringHash("unit"), u)
			call TimerStart(t, GetSoundDurationBJ(lastSound), false, function SpeechTimerCallback)
		endif
		set t = null
	endfunction
endlibrary