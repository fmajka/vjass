library TextTag initializer init

	globals
		// Players to loop through with SetTextTagPlayer()
		// Can be replaced for better performance
		public force mPlayers = bj_FORCE_ALL_PLAYERS

		public integer COLOR_ID_RED = 0
		public integer COLOR_ID_YELLOW = 1
		public integer COLOR_ID_GREEN = 2
		public integer COLOR_ID_GREY = 3
		public integer COLOR_ID_ORANGE = 4
		public integer COLOR_ID_WARNING = 5

		private integer array RED
		private integer array GREEN
		private integer array BLUE

		private player SetTextTagPlayer_player
		private texttag SetTextTagPlayer_texttag
	endglobals


	private function init takes nothing returns nothing
		set RED[COLOR_ID_RED] = 255
		set GREEN[COLOR_ID_RED] = 51
		set BLUE[COLOR_ID_RED] = 0

		set RED[COLOR_ID_YELLOW] = 255
		set GREEN[COLOR_ID_YELLOW] = 242
		set BLUE[COLOR_ID_YELLOW] = 5

		set RED[COLOR_ID_GREEN] = 51
		set GREEN[COLOR_ID_GREEN] = 255
		set BLUE[COLOR_ID_GREEN] = 51

		set RED[COLOR_ID_GREY] = 192
		set GREEN[COLOR_ID_GREY] = 192
		set BLUE[COLOR_ID_GREY] = 192

		set RED[COLOR_ID_ORANGE] = 255
		set GREEN[COLOR_ID_ORANGE] = 128
		set BLUE[COLOR_ID_ORANGE] = 0

		set RED[COLOR_ID_WARNING] = 255
		set GREEN[COLOR_ID_WARNING] = 0
		set BLUE[COLOR_ID_WARNING] = 0
	endfunction


	function CreateTextTagUnitColor takes string s, unit u, real z, real size, integer colorId returns texttag
		local texttag tt = CreateTextTag()

		call SetTextTagTextBJ(tt, s, size)
		call SetTextTagPosUnit(tt, u, z)
		if colorId >= 0 then
			call SetTextTagColor(tt, RED[colorId], GREEN[colorId], BLUE[colorId], 255)
		else
			call SetTextTagColor(tt, 255, 255, 255, 255)
		endif

	    return tt
	endfunction


	function SetTextTagFadeSpan takes texttag tt, real fadepoint, real lifespan returns nothing
		call SetTextTagPermanent(tt, false)
	    call SetTextTagFadepoint(tt, fadepoint)
	    call SetTextTagLifespan(tt, lifespan)
	endfunction


	private function SetTextTagPlayer_func takes nothing returns nothing
		if GetEnumPlayer() != SetTextTagPlayer_player and GetEnumPlayer() == GetLocalPlayer() then
			call SetTextTagVisibility(SetTextTagPlayer_texttag, false)
		endif
	endfunction

	function SetTextTagPlayer takes texttag tag, player whichPlayer returns nothing
		set SetTextTagPlayer_texttag = tag
		set SetTextTagPlayer_player = whichPlayer
		
		call ForForce(mPlayers, function SetTextTagPlayer_func)
	endfunction

	/////////////
	// Presets //
	/////////////

	public function UnitWarn takes unit u, string text returns texttag
	    local texttag tt = CreateTextTagUnitColor(text, u, 40.0, 9.0, COLOR_ID_WARNING)
	    call SetTextTagVelocityBJ(tt, 60, 90)
	    call SetTextTagFadeSpan(tt, 1.0, 3.0)
	    return tt
	endfunction

endlibrary