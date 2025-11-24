library PlayerInput initializer Init

	globals
		public unit pepe = null
		public real dirX = 0
		public real dirY = 0
		public boolean isMoving = false

		public integer stateId = 0
		public real stateDuration = 0

		public constant integer STATE_ID_IDLE = 0
		public constant integer STATE_ID_JUMP = 1
		public constant integer STATE_ID_AIRBORNE = 2

		private integer animationIndex = 0

		public boolean array isDown
		public boolean array justPressed
		public boolean array justReleased

		public constant integer KEY_ID_W = 0
		public constant integer KEY_ID_S = 1
		public constant integer KEY_ID_A = 2
		public constant integer KEY_ID_D = 3
		public constant integer KEY_ID_SPACE = 4
		public constant integer NUM_KEYS = 5
	endglobals

	// TODO: get state from unit / pass player id?
	private function CanPass takes unit u, real x, real y returns boolean
		local location loc = Location(x, y)
		local boolean result = not IsTerrainPathable(x, y, PATHING_TYPE_WALKABILITY) or (stateId == STATE_ID_JUMP and GetUnitFlyHeight(pepe) >= GetLocationZ(loc))
		call RemoveLocation(loc)
		set loc = null
		return result
	endfunction

	private function UpdateKey takes integer keyId, boolean down returns nothing
		local string downStr = "up"
		if down then
			set downStr = "down"
		endif
		call BJDebugMsg("State of " + I2S(keyId) + " changed to: " + downStr)
		set isDown[keyId] = down
		if down then 
			set justPressed[keyId] = true
		else
			set justReleased[keyId] = true
		endif
	endfunction

	private function UpdateAnimation takes integer change returns nothing
		set animationIndex = animationIndex + change
		call BJDebugMsg("Now playing animation " + I2S(animationIndex))
		call SetUnitAnimationByIndex(pepe, animationIndex)
	endfunction

	private function UpdateState takes integer newStateId, boolean override returns nothing
		if stateId == STATE_ID_JUMP then
			set newStateId = STATE_ID_AIRBORNE
		endif
		// TODO: each state has prio, may or may not override other state
		if stateId == newStateId or (stateId != STATE_ID_IDLE and not override) then
			return
		endif
		call BJDebugMsg("State set to: " + I2S(stateId))
		if newStateId == STATE_ID_IDLE then
			call SetUnitTimeScale(pepe, 1.0)
			if isMoving then
				call SetUnitAnimationByIndex(pepe, 6)
				call BJDebugMsg("Aniamtion set to: " + I2S(6))
			else
				call SetUnitAnimationByIndex(pepe, 1)
				call BJDebugMsg("Aniamtion set to: " + I2S(1))
			endif
		elseif newStateId == STATE_ID_JUMP then
			// set stateDuration = 0.03
			set stateDuration = 0.5
			// call SetUnitTimeScale(pepe, 10.0)
			call SetUnitTimeScale(pepe, 2.5)
			call SetUnitAnimationByIndex(pepe, 78)
		elseif newStateId == STATE_ID_AIRBORNE then
			// set stateDuration = 0.75
			// call SetUnitTimeScale(pepe, 1.0)
		endif
		// Set state
		set stateId = newStateId
	endfunction

	public function Loop takes real dt returns nothing
		local integer i = 0
		local real angle = 0
		local real x = GetUnitX(pepe)
		local real y = GetUnitY(pepe)
		// Update state
		set stateDuration = stateDuration - dt
		if stateDuration <= 0 then
			call UpdateState(STATE_ID_IDLE, true)
		endif
		// New state?
		if isDown[KEY_ID_SPACE] then
			call UpdateState(STATE_ID_JUMP, false)
		endif
		// Pepe movement
		if isDown[KEY_ID_D] and not isDown[KEY_ID_A] then
			set dirX = 1.0
		elseif isDown[KEY_ID_A] and not isDown[KEY_ID_D] then
			set dirX = -1.0
		else
			set dirX = 0.0
		endif
		if isDown[KEY_ID_W] and not isDown[KEY_ID_S] then
			set dirY = 1.0
		elseif isDown[KEY_ID_S] and not isDown[KEY_ID_W] then
			set dirY = -1.0
		else
			set dirY = 0.0
		endif
		if dirX != 0 or dirY != 0 then 
			set angle = Atan2(dirY, dirX)
			set x = x + Cos(angle) * GetUnitMoveSpeed(pepe) * dt
			set y = y + Sin(angle) * GetUnitMoveSpeed(pepe) * dt
			if CanPass(pepe, x, y) then
				call SetUnitX(pepe, x)
				call SetUnitY(pepe, y)
			endif
			call SetUnitFacing(pepe, bj_RADTODEG * angle)
			if not isMoving and stateId == STATE_ID_IDLE then
				call SetUnitAnimationByIndex(pepe, 6)
				set isMoving = true
			endif
		elseif isMoving and stateId == STATE_ID_IDLE then
			call SetUnitAnimationByIndex(pepe, 1)
			set isMoving = false
		endif
		// Cleanup
		loop
			exitwhen i == NUM_KEYS
			set justPressed[i] = false
			set justReleased[i] = false
			set i = i + 1
		endloop
	endfunction
		
	private function KeyDownActions takes nothing returns nothing
		local boolean down = BlzGetTriggerPlayerIsKeyDown()
		local oskeytype key = BlzGetTriggerPlayerKey()
		if key == OSKEY_W then
			call UpdateKey(KEY_ID_W, down)
		elseif key == OSKEY_S then
			call UpdateKey(KEY_ID_S, down)
		elseif key == OSKEY_A then
			call UpdateKey(KEY_ID_A, down)
		elseif key == OSKEY_D then
			call UpdateKey(KEY_ID_D, down)
		// TODO: Animation debug
		elseif key == OSKEY_Q then
			call UpdateAnimation(-1)
		elseif key == OSKEY_E then
			call UpdateAnimation(1)
		elseif key == OSKEY_SPACE then
			call UpdateKey(KEY_ID_SPACE, down)
		endif
	endfunction

	function Init takes nothing returns nothing
		local trigger t = CreateTrigger()
		call TriggerAddAction(t, function KeyDownActions)
		call BlzTriggerRegisterPlayerKeyEvent(t, Player(0), OSKEY_W, 0, true)
		call BlzTriggerRegisterPlayerKeyEvent(t, Player(0), OSKEY_W, 0, false)
		call BlzTriggerRegisterPlayerKeyEvent(t, Player(0), OSKEY_A, 0, true)
		call BlzTriggerRegisterPlayerKeyEvent(t, Player(0), OSKEY_A, 0, false)
		call BlzTriggerRegisterPlayerKeyEvent(t, Player(0), OSKEY_S, 0, true)
		call BlzTriggerRegisterPlayerKeyEvent(t, Player(0), OSKEY_S, 0, false)
		call BlzTriggerRegisterPlayerKeyEvent(t, Player(0), OSKEY_D, 0, true)
		call BlzTriggerRegisterPlayerKeyEvent(t, Player(0), OSKEY_D, 0, false)
		call BlzTriggerRegisterPlayerKeyEvent(t, Player(0), OSKEY_Q, 0, true)
		// call BlzTriggerRegisterPlayerKeyEvent(t, Player(0), OSKEY_Q, 0, false)
		call BlzTriggerRegisterPlayerKeyEvent(t, Player(0), OSKEY_E, 0, true)
		// call BlzTriggerRegisterPlayerKeyEvent(t, Player(0), OSKEY_E, 0, false)
		call BlzTriggerRegisterPlayerKeyEvent(t, Player(0), OSKEY_SPACE, 0, true)
		call BlzTriggerRegisterPlayerKeyEvent(t, Player(0), OSKEY_SPACE, 0, false)
	endfunction

endlibrary