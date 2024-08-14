library Task requires HOTS
	globals
		public unit lastCrook
		public quest lastTask
		public hashtable hash = InitHashtable()
		public quest array tasks
		public integer count = 0
		private integer KEY_ID = StringHash("id")
		private integer KEY_GIVER = StringHash("giver")
		private integer KEY_REWARD = StringHash("reward")
		private integer KEY_TITLE = StringHash("title")
		private integer ABILITY_QUEST_UNDISCOVERED = 'A00Y'
		private integer ABILITY_QUEST_ACTIVE = 'A00Z'
	endglobals

	function IsUnitTaskGiver takes unit u returns boolean
		return GetUnitAbilityLevel(u, ABILITY_QUEST_ACTIVE) > 0 or GetUnitAbilityLevel(u, ABILITY_QUEST_UNDISCOVERED) > 0
	endfunction

	function CreateTask takes integer id, unit giver, integer reward, string title, string desc, string iconPath returns quest
		local integer i = count
		local quest lastTask = CreateQuest()
		local integer taskHandle = GetHandleId(lastTask)
		call SaveInteger(hash, taskHandle, KEY_ID, id)
		call SaveInteger(hash, taskHandle, KEY_REWARD, reward)
		call SaveUnitHandle(hash, taskHandle, KEY_GIVER, giver)
		call SaveStr(hash, taskHandle, KEY_TITLE, title)
		call QuestSetTitle(lastTask, title)
		call QuestSetDescription(lastTask, desc)
		call QuestSetIconPath(lastTask, iconPath)
		call QuestSetDiscovered(lastTask, false)
		call UnitAddAbility(giver, ABILITY_QUEST_UNDISCOVERED)
		set tasks[count] = lastTask
		set count = count + 1
		return lastTask
	endfunction

	function CrookInteractTask takes unit crook, quest task, unit giver returns nothing
		local integer taskHandle = GetHandleId(task)
		if IsQuestFailed(task) then
			return
		endif
		set lastCrook = crook
		set lastTask = task
		set udg_Task_ID = LoadInteger(hash, taskHandle, KEY_ID)
		if not IsQuestDiscovered(task) then
			call QuestSetDiscovered(task, true)
			call StopSoundBJ(gg_snd_QuestNew, false)
			call StartSound(gg_snd_QuestNew)
			call DisplayTextToForce(GetPlayersAll(), "Nowe zadanie: |cffffcc00" + LoadStr(hash, taskHandle, KEY_TITLE) + "|r")
			call UnitRemoveAbility(giver, ABILITY_QUEST_UNDISCOVERED)
			call UnitAddAbility(giver, ABILITY_QUEST_ACTIVE)
			set udg_Task_EventDiscover = 1
			set udg_Task_EventDiscover = 0
		elseif not IsQuestCompleted(task) then
			set udg_Task_EventUpdate = 1
			set udg_Task_EventUpdate = 0
		endif
	endfunction

	function CrookInteractTaskGiver takes unit crook, unit giver returns nothing
		local integer i = 0
		local unit u
		loop
			exitwhen i == count
			set u = LoadUnitHandle(hash, GetHandleId(tasks[i]), KEY_GIVER)
			if u == giver then
				call CrookInteractTask(crook, tasks[i], giver)
			endif
			set i = i + 1
		endloop
		set u = null
	endfunction

	function FailTask takes quest task returns nothing
		local unit giver = LoadUnitHandle(hash, GetHandleId(task), KEY_GIVER)
		if IsQuestCompleted(task) or IsQuestFailed(task) then
			set giver = null
			return
		endif
		if IsQuestDiscovered(task) then
			call UnitRemoveAbility(giver, ABILITY_QUEST_ACTIVE)
		else
			call UnitRemoveAbility(giver, ABILITY_QUEST_UNDISCOVERED)
		endif
		call QuestSetFailed(task, true)
		set giver = null
	endfunction

	function CrookCompleteTask takes unit crook, quest task returns nothing
		local integer taskHandle = GetHandleId(task)
		local integer reward = LoadInteger(hash, taskHandle, KEY_REWARD)
		local unit giver = LoadUnitHandle(hash, taskHandle, KEY_GIVER)
		local string title = LoadStr(hash, taskHandle, KEY_TITLE)
		call QuestSetCompleted(task, true)
		call UnitRemoveAbility(giver, ABILITY_QUEST_ACTIVE)
		call SetTextTagColor(CrookAddXP(crook, 5 * reward), 128, 0, 255, 255)
		call CrookAddGold(crook, reward, true)
		call StopSoundBJ(gg_snd_QuestCompleted, false)
    call StartSound(gg_snd_QuestCompleted)
		call DisplayTextToForce(GetPlayersAll(), "Zadanie wykonane: |cffffcc00" + title + "|r")
		set giver = null
	endfunction

endlibrary
