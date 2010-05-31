SLAMChain = LibStub("AceAddon-3.0"):NewAddon("SLAMChain", "AceTimer-3.0", "AceEvent-3.0","AceComm-3.0","AceConsole-3.0","AceHook-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local AceEvent = LibStub("AceEvent-3.0")

-- Spell IDs: Aura Mastery = 31821
--            Divine Sacrifice = 64205


function SLAMChain:OnInitialize()
	self:RegisterChatCommand("slamc", "ChatCommand")
end

function SLAMChain:OnEnable()
	self.enabled = false
	self.numberofPaladins = 4
	self.playerMatrix = {
		player1 = {
			name = "Dizzy",
			AMCooldown = "never",
			AMCDTime = 0,
			AMTimerHandle = nil,
			DGCooldown = "never",
			DGCDTime = 0,
			DGTimerHandle = nil,
			},
		player2 = {
			name = "Eldum",
			AMCooldown = "false",
			AMCDTime = 0,
			AMTimerHandle = nil,
			DGCooldown = "false",
			DGCDTime = 0,
			DGTimerHandle = nil,
		},
		player3 = {
			name = "Krän",
			AMCooldown = "false",
			AMCDTime = 0,
			AMTimerHandle = nil,
			DGCooldown = "never",
			DGCDTime = 0,
			DGTimerHandle = nil,
		},
		player4 = {
			name = "Askunia",
			AMCooldown = "false",
			AMCDTime = 0,
			AMTimerHandle = nil,
			DGCooldown = "false",
			DGCDTime = 0,
			DGTimerHandle = nil,
		}
	}
	self:UnregisterAllEvents()
end

function SLAMChain:HandleDGCooldownTimer(playerName)
	-- If this Timer fires it means that the Cooldown of DG has finished!
	print(("Divine Guardian cooldown on %s finished"):format(self.playerMatrix[playerName]["name"]))
	self.playerMatrix[playerName]["DGCooldown"]="false"
end

function SLAMChain:HandleAMCooldownTimer(playerName)
	-- If this Timer fires it means that the Cooldown of AM has finished!
	print(("Aura Mastery cooldown on %s finished"):format(self.playerMatrix[playerName]["name"]))
	self.playerMatrix[playerName]["AMCooldown"]="false"
	self:CancelTimer(self.playerMatrix[playerName]["AMTimerHandle"])
end

function SLAMChain:HandleAMCDTime(playerName)
	self.playerMatrix[playerName]["AMCDTime"]=self.playerMatrix[playerName]["AMCDTime"]-1
end

function SLAMChain:HandleDGCDTime(playerName)
	self.playerMatrix[playerName]["DGCDTime"]=self.playerMatrix[playerName]["DGCDTime"]-1
end

function SLAMChain:SpellApplied(event, timestamp, eventType, srcGuid, srcName, srcFlags, dstGuid, dstName, dstFlags, ...)
	if (eventType=="SPELL_CAST_SUCCESS") then
		local spellId, spellName, spellSchool = select (1, ... )
		if (spellId==31821 and UnitInRaid(srcName)) then
			local nextPlayerFound=false
			local output = "Aura Mastery used by "..srcName
			SendChatMessage(output,"RAID")
			
			-- Schedule the Cooldown Timer!
			for i=1,self.numberofPaladins do
				if self.playerMatrix["player"..i]["name"]==srcName then
					if self.playerMatrix["player"..i]["AMCooldown"]=="false" then
						self.playerMatrix["player"..i]["AMCooldown"]="true"
						self:ScheduleTimer("HandleAMCooldownTimer", 120, "player"..i)
						self.playerMatrix["player"..i]["AMTimerHandle"] = self:ScheduleRepeatingTimer("HandleAMCDTime", 1, "player"..i)
						self.playerMatrix["player"..i]["AMCDTime"]=120
					end
				end
			end
			
			-- Get the next one in Line to use a Cooldown!
			for i=1,self.numberofPaladins do
				if self.playerMatrix["player"..i]["AMCooldown"]=="false" and nextPlayerFound==false and not UnitIsDeadOrGhost(self.playerMatrix["player"..i]["name"]) and UnitIsConnected(self.playerMatrix["player"..i]["name"]) then
					-- Send a /w and /raid Announce
					SendChatMessage("You are next with AM!","WHISPER",GetDefaultLanguage("player"),self.playerMatrix["player"..i]["name"])
					local nextAMMessage=self.playerMatrix["player"..i]["name"].." is next on Aura Mastery Duty!"
					SendChatMessage(nextAMMessage,"RAID")
					nextPlayerFound=true
				end
			end
			if nextPlayerFound==false then
				-- Check if any of the Paladins is able to use AM in 20 seconds
				for i=1,self.numberofPaladins do
					if self.playerMatrix["player"..i]["AMCDTime"]<=20 and nextPlayerFound==false and self.playerMatrix["player"..i]["AMCooldown"]=="true" and not UnitIsDeadOrGhost(self.playerMatrix["player"..i]["name"]) and UnitIsConnected(self.playerMatrix["player"..i]["name"]) then
						-- Send a /w and /raid Announce
						SendChatMessage("You are next with AM!","WHISPER",GetDefaultLanguage("player"),self.playerMatrix["player"..i]["name"])
						local nextAMMessage=self.playerMatrix["player"..i]["name"].." is next on Aura Mastery Duty!"
						SendChatMessage(nextAMMessage,"RAID")
						nextPlayerFound=true
					end
				end
						
				-- Assign one of the pallies to do DG next
				for i=1,self.numberofPaladins do
					if self.playerMatrix["player"..i]["DGCooldown"]=="false" and nextPlayerFound==false and not UnitIsDeadOrGhost(self.playerMatrix["player"..i]["name"]) and UnitIsConnected(self.playerMatrix["player"..i]["name"]) then
						SendChatMessage("You are next with DG!","WHISPER",GetDefaultLanguage("player"),self.playerMatrix["player"..i]["name"])
						local nextDGMessage=self.playerMatrix["player"..i]["name"].." is next on Divine Sacrifice Duty!"
						SendChatMessage(nextDGMessage,"RAID")
						nextPlayerFound=true
					end
				end
			end
			if nextPlayerFound==false then
				-- Check if any of the Paladins can use DG in 20 seconds
				for i=1,self.numberofPaladins do
					if self.playerMatrix["player"..i]["DGCDTime"]<=20 and nextPlayerFound==false and self.playerMatrix["player"..i]["DGCooldown"]=="true" and not UnitIsDeadOrGhost(self.playerMatrix["player"..i]["name"]) and UnitIsConnected(self.playerMatrix["player"..i]["name"]) then
						SendChatMessage("You are next with DG!","WHISPER",GetDefaultLanguage("player"),self.playerMatrix["player"..i]["name"])
						local nextDGMessage=self.playerMatrix["player"..i]["name"].." is next on Divine Sacrifice Duty!"
						SendChatMessage(nextDGMessage,"RAID")
						nextPlayerFound=true
					end
				end
			end
			if nextPlayerFound==false then
				-- No DG or AM available in Time warn the Raid!
				SendChatMessage("No cooldowns available for next Infest!","RAID")
			end
		end
		if (spellId==64205 and UnitInRaid(srcName)) then
			local nextPlayerFound=false
			local output = "Divine Guardian used by "..srcName
			SendChatMessage(output,"RAID")
			
			-- Schedule the Cooldown Timer!
			for i=1,self.numberofPaladins do
				if self.playerMatrix["player"..i]["name"]==srcName then
					if self.playerMatrix["player"..i]["DGCooldown"]=="false" then
						self.playerMatrix["player"..i]["DGCooldown"]="true"
						self:ScheduleTimer("HandleDGCooldownTimer", 120, "player"..i)
						self.playerMatrix["player"..i]["DGTimerHandle"] = self:ScheduleRepeatingTimer("HandleDGCDTime", 1, "player"..i)
						self.playerMatrix["player"..i]["DGCDTime"]=120
					end
				end
			end

			-- Check if a AM cooldown is available for use
			for i=1,self.numberofPaladins do
				if self.playerMatrix["player"..i]["AMCooldown"]=="false" and nextPlayerFound==false and not UnitIsDeadOrGhost(self.playerMatrix["player"..i]["name"]) and UnitIsConnected(self.playerMatrix["player"..i]["name"]) then
					SendChatMessage("You are next with AM!","WHISPER",GetDefaultLanguage("player"),self.playerMatrix["player"..i]["name"])
					local nextAMMessage=self.playerMatrix["player"..i]["name"].." is next on Aura Mastery Duty!"
					SendChatMessage(nextAMMessage,"RAID")
					nextPlayerFound=true
				end
			end
			
			if nextPlayerFound==false then
				-- Check if any of the Paladins is able to use AM in 20 seconds
				for i=1,self.numberofPaladins do
					if self.playerMatrix["player"..i]["AMCDTime"]<=20 and nextPlayerFound==false and self.playerMatrix["player"..i]["AMCooldown"]=="true" and not UnitIsDeadOrGhost(self.playerMatrix["player"..i]["name"]) and UnitIsConnected(self.playerMatrix["player"..i]["name"]) then
						-- Send a /w and /raid Announce
						SendChatMessage("You are next with AM!","WHISPER",GetDefaultLanguage("player"),self.playerMatrix["player"..i]["name"])
						local nextAMMessage=self.playerMatrix["player"..i]["name"].." is next on Aura Mastery Duty!"
						SendChatMessage(nextAMMessage,"RAID")
						nextPlayerFound=true
					end
				end
			end

			if nextPlayerFound==false then
				-- Assign the next DG
				for i=1,self.numberofPaladins do
					if self.playerMatrix["player"..i]["DGCooldown"]=="false" and nextPlayerFound==false and not UnitIsDeadOrGhost(self.playerMatrix["player"..i]["name"]) and UnitIsConnected(self.playerMatrix["player"..i]["name"]) then
						SendChatMessage("You are next with DG!","WHISPER",GetDefaultLanguage("player"),self.playerMatrix["player"..i]["name"])
						local nextDGMessage=self.playerMatrix["player"..i]["name"].." is next on Divine Sacrifice Duty!"
						SendChatMessage(nextDGMessage,"RAID")
						nextPlayerFound=true
					end
				end
			end
			if nextPlayerFound==false then
				-- No DG or AM available in Time warn the Raid!
				SendChatMessage("No cooldowns available for next Infest!","RAID")
			end
		end
	end
end

function SLAMChain:ChatCommand()
	if (self.enabled==false)
	then
		print("SLAMChain is now Enabled!")
		self.enabled=true
		self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", "SpellApplied")
	else
		print("SLAMChain is now Disabled!")
		self.enabled=false
		self:UnRegisterAllEvents()
	end
end
