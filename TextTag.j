library TextTag initializer Init

	globals
		// Players to loop through with SetTextTagPlayer()
		// Can be replaced for better performance
		public force mPlayers = bj_FORCE_ALL_PLAYERS

		private integer array ARR_RED
		private integer array ARR_GREEN
		private integer array ARR_BLUE

		// TODO: think about the naming
		private player SetTextTagPlayer_player
		private texttag SetTextTagPlayer_texttag

		private integer COLOR_COUNT = 0
		public integer COLOR_RED
		public integer COLOR_YELLOW 
		public integer COLOR_GREEN
		public integer COLOR_GREY
		public integer COLOR_ORANGE
		public integer COLOR_WARNING
		public integer COLOR_GOLD
		public integer COLOR_LIGHT_PURPLE
	endglobals

	private function InitColor takes integer r, integer g, integer b returns integer
		local integer id = COLOR_COUNT
		set ARR_RED[id] = r
		set ARR_GREEN[id] = g
		set ARR_BLUE[id] = b
		set COLOR_COUNT = COLOR_COUNT + 1
		return id
	endfunction

	private function Init takes nothing returns nothing
		set COLOR_RED          = InitColor(255, 51, 0)
		set COLOR_YELLOW       = InitColor(255, 242, 5)
		set COLOR_GREEN        = InitColor(51, 255, 51)
		set COLOR_GREY         = InitColor(192, 192, 192)
		set COLOR_ORANGE       = InitColor(255, 128, 0)
		set COLOR_WARNING      = InitColor(255, 0, 0)
		set COLOR_GOLD         = InitColor(255, 192, 0)
		set COLOR_LIGHT_PURPLE = InitColor(192, 100, 228)
	endfunction

	function CreateTextTagUnitColor takes string str, unit u, real z, real size, integer colorId returns texttag
		local texttag tt = CreateTextTag()
		call SetTextTagTextBJ(tt, str, size)
		call SetTextTagPosUnit(tt, u, z)
		if colorId >= 0 then
			call SetTextTagColor(tt, ARR_RED[colorId], ARR_GREEN[colorId], ARR_BLUE[colorId], 255)
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

	private function SetTextTagPlayerCallback takes nothing returns nothing
		if GetEnumPlayer() != SetTextTagPlayer_player and GetEnumPlayer() == GetLocalPlayer() then
			call SetTextTagVisibility(SetTextTagPlayer_texttag, false)
		endif
	endfunction

	function SetTextTagPlayer takes texttag tag, player p returns nothing
		set SetTextTagPlayer_texttag = tag
		set SetTextTagPlayer_player = p
		call ForForce(mPlayers, function SetTextTagPlayerCallback)
	endfunction

endlibrary