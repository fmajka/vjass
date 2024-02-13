//
// HotS-specific library packing annoucer sound functions into 1 file
// Updated to HotS2 on 10.02.2024
//

library Announcer initializer init

	globals
		private sound array udg_SFX_GachiEat
		private sound array udg_SFX_GachiTaunt
		private sound array udg_SFX_GachiHit
		private sound array udg_SFX_GachiKill
		private sound array udg_SFX_GachiDeath

		public integer NONE = 0
		public integer GACHI = 1
		public integer ADMIXON = 2

		public integer array mAnnouncer
	endglobals

	private function init takes nothing returns nothing
		set udg_SFX_GachiEat[0] = gg_snd_gachiEat1
		set udg_SFX_GachiEat[1] = gg_snd_gachiEat2
		set udg_SFX_GachiEat[2] = gg_snd_gachiEat3
		set udg_SFX_GachiTaunt[0] = gg_snd_gachiTaunt1
		set udg_SFX_GachiTaunt[1] = gg_snd_gachiTaunt2
		set udg_SFX_GachiTaunt[2] = gg_snd_gachiTaunt3
		set udg_SFX_GachiTaunt[3] = gg_snd_gachiTaunt4
		set udg_SFX_GachiHit[0] = gg_snd_gachiHit1
		set udg_SFX_GachiHit[1] = gg_snd_gachiHit2
		set udg_SFX_GachiHit[2] = gg_snd_gachiHit3
		set udg_SFX_GachiHit[3] = gg_snd_gachiHit4
		set udg_SFX_GachiKill[0] = gg_snd_gachiKill1
		set udg_SFX_GachiKill[1] = gg_snd_gachiKill2
		set udg_SFX_GachiKill[2] = gg_snd_gachiKill3
		set udg_SFX_GachiKill[3] = gg_snd_gachiKill4
		set udg_SFX_GachiKill[4] = gg_snd_gachiKill5
		set udg_SFX_GachiKill[5] = gg_snd_gachiKill6
		set udg_SFX_GachiKill[6] = gg_snd_gachiKill7
		set udg_SFX_GachiDeath[0] = gg_snd_gachiDeath1
		set udg_SFX_GachiDeath[1] = gg_snd_gachiDeath2
	endfunction

	// Abstraction for playing sounds
	private function UnitPlay takes unit u, sound sfx returns nothing
		call StopSound(sfx, false, false)
        call PlaySoundOnUnitBJ(sfx, 100, u)
	endfunction

	// Setters & Getters
	public function SetPlayerAnnouncer takes player p, integer announcerId returns nothing
		local integer id = GetPlayerId(p)
		local unit u = udg_Crook[id + 1]

		set mAnnouncer[id] = announcerId

		if announcerId == GACHI then
			call UnitPlay(u, gg_snd_gachiSet1)
		elseif announcerId == ADMIXON then
			//call UnitPlay(u, gg_snd_admixSet1)
		endif

		set u = null
	endfunction

	public function GetPlayerAnnouncer takes player p returns integer
		return mAnnouncer[GetPlayerId(p)]
	endfunction

	// Callable functions
	public function UnitEat takes unit u returns nothing
		local integer id = GetPlayerId(GetOwningPlayer(u))

		if mAnnouncer[id] == GACHI then
			call UnitPlay(u, udg_SFX_GachiEat[GetRandomInt(0, 2)])
		elseif mAnnouncer[id] == ADMIXON then
			//call UnitPlay(u, udg_SFX_AdmixEat[GetRandomInt(0, 1)])
		endif
	endfunction

	public function UnitDrink takes unit u returns nothing
		local integer id = GetPlayerId(GetOwningPlayer(u))

		if mAnnouncer[id] == GACHI then
			call UnitPlay(u, udg_SFX_GachiEat[GetRandomInt(0, 2)])
		elseif mAnnouncer[id] == ADMIXON then
			//call UnitPlay(u, udg_SFX_AdmixDrink[GetRandomInt(0, 1)])
		endif
	endfunction

	public function UnitSpawnWorms takes unit u, integer amount returns nothing
		local integer id = GetPlayerId(GetOwningPlayer(u))
		if amount <= 0 then
			return
		endif

		if mAnnouncer[id] == GACHI then
			if amount == 1 then
				call UnitPlay(u, udg_SFX_GachiTaunt[GetRandomInt(0, 3)])
			elseif amount == 2 then
				call UnitPlay(u, gg_snd_gachiTauntTwo1)
			else
				call UnitPlay(u, gg_snd_gachiTauntMany1)
			endif
		elseif mAnnouncer[id] == ADMIXON then
			if amount == 1 then
				//call UnitPlay(u, udg_SFX_AdmixTaunt[GetRandomInt(0, 5)])
			else
				//call UnitPlay(u, udg_SFX_AdmixTauntMany[GetRandomInt(0, 2)])
			endif
		endif
	endfunction

	public function UnitKilled takes unit u returns nothing
		local integer id = GetPlayerId(GetOwningPlayer(u))

		if mAnnouncer[id] == GACHI then
			// TODO: suction?
			call UnitPlay(u, udg_SFX_GachiKill[GetRandomInt(0, 6)])
		elseif mAnnouncer[id] == ADMIXON then
			//call UnitPlay(u, udg_SFX_AdmixKill[GetRandomInt(0, 4)])
		endif
	endfunction

	public function UnitBurned takes unit u returns nothing
		local integer id = GetPlayerId(GetOwningPlayer(u))
		set u = udg_Crook[id]

		// Killer wasn't one of the players
		if id >= udg_TOTAL_PLAYERS then
			return
		endif

		if mAnnouncer[id] == GACHI then
			call UnitPlay(u, gg_snd_gachiKillFire1)
		elseif mAnnouncer[id] == ADMIXON then
			//call UnitPlay(u, gg_snd_admixKillFire1)
		endif
	endfunction

	public function UnitHurt takes unit u returns nothing
		local integer id = GetPlayerId(GetOwningPlayer(u))

		if mAnnouncer[id] == GACHI then
			call UnitPlay(u, udg_SFX_GachiHit[GetRandomInt(0, 3)])
		elseif mAnnouncer[id] == ADMIXON then
			//call UnitPlay(u, udg_SFX_AdmixHit[GetRandomInt(0, 2)])
		endif
	endfunction

	public function UnitDeath takes unit u returns nothing
		local integer id = GetPlayerId(GetOwningPlayer(u))

		if mAnnouncer[id] == GACHI then
			call UnitPlay(u, udg_SFX_GachiDeath[GetRandomInt(0, 1)])
		elseif mAnnouncer[id] == ADMIXON then
			//call UnitPlay(u, udg_SFX_AdmixHit[GetRandomInt(0, 2)])
		endif
	endfunction

	public function UnitKilledByImpostor takes unit u, unit door returns nothing
		local integer i = 0
		local player p
		
		loop
			exitwhen i == udg_TOTAL_PLAYERS
			set p = Player(i)

			// Play sound locally for each player based on their announcer
			if p == GetLocalPlayer() then
				if mAnnouncer[i] == GACHI then
					call UnitPlay(u, gg_snd_gachiImpostor1)
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