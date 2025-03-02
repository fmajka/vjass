//
// HotS-specific library packing annoucer sound functions into 1 file
// Updated to HotS2 on 10.02.2024
// Refactored on 02.03.2025
//

library Announcer initializer init requires Audio

	globals
		public string PATH = "war3mapImported\\"
		private integer KEY_FALLBACK = StringHash("fallback")
		
		public string TYPE_SET = "Set"
		public string TYPE_EAT = "Eat"
		public string TYPE_DRINK = "Drink"
		public string TYPE_TAUNT = "Taunt"
		public string TYPE_TAUNT_TWO = "TauntTwo"
		public string TYPE_TAUNT_MANY = "TauntMany"
		public string TYPE_HIT = "Hit"
		public string TYPE_KILL = "Kill"
		public string TYPE_KILL_FIRE = "KillFire"
		public string TYPE_DEATH = "Death"

		public integer GACHI
		public integer ADMIXON

		// Array of announcer ids assigned to player ids (index = player id)
		public integer array mAnnouncer
		public hashtable hash = InitHashtable()
		public integer announcerIndex = 1
	endglobals

	private function InitAnnouncer takes string prefix returns integer
		local integer announcerId = announcerIndex
		call SaveStr(hash, announcerId, StringHash("prefix"), prefix)
		set announcerIndex = announcerIndex + 1
		return announcerId
	endfunction

	private function InitSoundPack takes integer announcerId, string sfxType, integer count returns nothing
		call SaveInteger(hash, announcerId, StringHash(sfxType), count)
	endfunction

	private function InitFallback takes string sfxType, string fallbackType returns nothing
		call SaveStr(hash, StringHash(sfxType), KEY_FALLBACK, fallbackType)	
	endfunction

	private function init takes nothing returns nothing
		call InitFallback(TYPE_DRINK, TYPE_EAT)
		call InitFallback(TYPE_TAUNT_TWO, TYPE_TAUNT_MANY)
		call InitFallback(TYPE_TAUNT_MANY, TYPE_TAUNT)
		call InitFallback(TYPE_KILL_FIRE, TYPE_KILL)
		call InitFallback(TYPE_DEATH, TYPE_HIT)

		set GACHI = InitAnnouncer("gachi")
		call InitSoundPack(GACHI, TYPE_SET, 1)
		call InitSoundPack(GACHI, TYPE_EAT, 3)
		call InitSoundPack(GACHI, TYPE_TAUNT, 4)
		call InitSoundPack(GACHI, TYPE_TAUNT_TWO, 1)
		call InitSoundPack(GACHI, TYPE_TAUNT_MANY, 1)
		call InitSoundPack(GACHI, TYPE_HIT, 4)
		call InitSoundPack(GACHI, TYPE_KILL, 7)
		call InitSoundPack(GACHI, TYPE_KILL_FIRE, 1)
		call InitSoundPack(GACHI, TYPE_DEATH, 2)
	endfunction

	public function PlaySoundType takes unit u, string sfxType returns nothing
		local integer playerId = GetPlayerId(GetOwningPlayer(u))
		local integer announcerId = mAnnouncer[playerId]
		local integer sfxKey = StringHash(sfxType)
		local integer count = LoadInteger(hash, announcerId, sfxKey)
		local integer prio = 1
		local string prefix
		local string path
		// No announcer - skip
		if announcerId == 0 then
			return
		endif
		// Try to go for a fallback sound if no sound of spcified type exists
		if count == 0 then
			if HaveSavedString(hash, sfxKey, KEY_FALLBACK) then
				call PlaySoundType(u, LoadStr(hash, sfxKey, KEY_FALLBACK))
			endif
			return
		endif
		// Death sound prio
		if sfxType == TYPE_DEATH then
			set prio = Audio_PRIO_DEATH
		endif
		// Get sound path
		set prefix = LoadStr(hash, announcerId, StringHash("prefix"))
		set path = PATH + prefix + sfxType + I2S(GetRandomInt(1, count)) + ".mp3"

		call UnitSpeak(u, path, prio)

		set prefix = null
		set path = null
	endfunction

	public function GetWormSpawnString takes integer count returns string
		if count > 2 then 
			return TYPE_TAUNT_MANY
		elseif count == 2 then
			return TYPE_TAUNT_TWO
		else
			return TYPE_TAUNT
		endif
	endfunction

	// Setters & Getters
	public function SetPlayerAnnouncer takes player p, integer announcerId returns nothing
		local integer id = GetPlayerId(p)
		local unit u = udg_Crook[id + 1]

		set mAnnouncer[id] = announcerId
		call PlaySoundType(u, TYPE_SET)

		set u = null
	endfunction

	public function GetPlayerAnnouncer takes player p returns integer
		return mAnnouncer[GetPlayerId(p)]
	endfunction

	// TODO: one day I'll need to handle this...
	public function UnitKilledByImpostor takes unit u, unit door returns nothing
		local integer i = 0
		local player p
		
		loop
			exitwhen i == udg_PlayerCount
			set p = Player(i)

			// Play sound locally for each player based on their announcer
			if p == GetLocalPlayer() then
				if mAnnouncer[i] == GACHI then
					call StopSound(gg_snd_gachiImpostor1, false, false)
    			call PlaySoundOnUnitBJ(gg_snd_gachiImpostor1, 100, u)
				elseif mAnnouncer[i] == ADMIXON then
					//call UnitPlay(u, gg_snd_admixImpostor1)
				else
					//call UnitPlay(u, gg_snd_defaultImpostor1)
				endif
        	endif

			set i = i + 1
		endloop

		set p = null
	endfunction

endlibrary