local LOOPDELAY = 0.012
-- around 0.01 is minimum
-- increase this delay if getting disconnected

--[[

	Commands:

	/guidstart								starts collecting class data at current GUIDIndex
	/guidrerun [hex or decimal guid]		starts collecting data at already passed index. Cannot go above GUIDIndex. Used for fixing errors/changes
	/guidstop								stops current collection and moves into the string. Updates GUIDIndex to where you left off. Do a /reload to actually save the data.
	/guidfetch [hex or decimal guid]		prints player associated with that guid on any US West server if they exist.
	/guidindex [decimal guid]				sets GUIDIndex to input. old index will be lost. use guidrerun to correct errors instead.

	Hex guids are entered in the format of: 0000169C
	Do not include a "0x" and always include all 8 digits.


]]



-- not consistent with blizzard enumeration
local class2char = {
	["NONE"] = 			"-",
	["WARRIOR"] = 		"1",
	["PALADIN"]	=		"2",
	["HUNTER"]	=		"3",
	["ROGUE"]	=		"4",
	["PRIEST"]	=		"5",
	["SHAMAN"]	=		"6",
	["MAGE"]	=		"7",
	["WARLOCK"]	=		"8",
	["DRUID"]	=		"9",
	["DEATHKNIGHT"]	=	"0",
}

local ClassColor = {
	["NONE"] = 			"|cFF000000",
	["WARRIOR"] = 		"|cFFC69B6D",
	["PALADIN"]	=		"|cFFF48CBA",
	["HUNTER"]	=		"|cFFAAD372",
	["ROGUE"]	=		"|cFFFFF468",
	["PRIEST"]	=		"|cFFFFFFFF",
	["SHAMAN"]	=		"|cFF0070DD",
	["MAGE"]	=		"|cFF3FC7EB",
	["WARLOCK"]	=		"|cFF8788EE",
	["DRUID"]	=		"|cFFFF7C0A",
	["DEATHKNIGHT"]	=	"|cFFC41E3A",
}

local classTable = {}
local nextIndex
local rerunIndex
if classStr == nil then classStr = "" end
local isRerun = false

local GUIDPrefix = {
	"Player-4647-",
	"Player-4395-",
	"Player-4372-",
	"Player-4373-",
	"Player-4374-",
	"Player-4376-",
	"Player-4725-",
	"Player-4795-"
	}
local numPrefixes = #GUIDPrefix

-- MAIN TEST FUNCTION ----------------------------------------------------------------------------------------------------------------
local newChar
local function testGUID(index)
	local indexstr = string.format("%.8X", index)
	
	-- fetch every guid combo once to cache it from the server
	--		previously unseen guids are nil the first time
	--		thats why it has to be done twice with a delay
	for i=1, numPrefixes, 1 do
		GetPlayerInfoByGUID(GUIDPrefix[i] .. indexstr)
	end
	
	
	-- after a second, go through all combinations to see if it exists
	-- 		if it exists, add it to the string using appendClass()
	--		if it doesnt exist, append using class "NONE"
	C_Timer.After(1, function()
		local exists = false
		for i=1, numPrefixes, 1 do
			if GetPlayerInfoByGUID(GUIDPrefix[i] .. indexstr) ~= nil then
				newChar = class2char[((select(2,GetPlayerInfoByGUID(GUIDPrefix[i] .. indexstr))))]
				
				
				if isRerun and newChar ~= classTable[index] then
					print("Rerun changed " .. classTable[index] .. " to " .. newChar .. " at " .. GUIDPrefix[i] .. indexstr)
				end
				
				classTable[index] = newChar
				exists = true
				break
			end
		end
		
		if not exists then
			newChar = class2char["NONE"]
			if isRerun and newChar ~= classTable[index] then
				local prefix = GUIDPrefix[i]
				if prefix == nil then prefix = "Player-NONE-" end
				print("Rerun changed " .. classTable[index] .. " to " .. newChar .. " at " .. prefix .. indexstr)
			end
			classTable[index] = newChar
		end
	end)
end

-- MAIN LOOPS ----------------------------------------------------------------------------------------------------------------------
-- Change delay value at the top of the file

local keepLooping = false
local function testLoop(index)
	--IndexStringFrame.text:SetText(index)
	C_Timer.After(LOOPDELAY, function()
		if keepLooping then
			testGUID(index)
			nextIndex = nextIndex +1
			testLoop(nextIndex)
		end
	end)
end

local function rerunLoop(index)
	C_Timer.After(LOOPDELAY, function()
		if keepLooping then
			testGUID(index)
			rerunIndex = rerunIndex +1
			
			-- do not go over existing GUIDIndex for a rerun
			if rerunIndex < GUIDIndex then
				rerunLoop(rerunIndex)
			else
				print("The max index for a rerun has been reached.")
				keepLooping = false
				isRerun = false
			end
		end
	end)
end

-- load data from string into table. Used by guidstart and guidrerun
-- adds a delay when loading so the script doesnt time out
-- I hate this but I dont know a better way
local function loadTable(rerun,intnum)
	local incrementSize = 1000000
	local loopIndex = 1
	local numIncrements = #classStr/incrementSize
	local incCount = 1
	if math.floor(numIncrements) < numIncrements then
		numIncrements = math.floor(numIncrements+1)
	else
		numIncrements = math.floor(numIncrements)
	end
	
	local function loadingComplete()
		if not rerun then
			nextIndex = GUIDIndex
			print("Loaded String Data. Collecting data starting from index " .. nextIndex .. " (" .. string.format("%.8X", nextIndex) .. ")...")
			
			-- main data collection loop
			keepLooping = true
			testLoop(nextIndex)
		else
			rerunIndex = intnum
			print("Loaded String Data. Collecting rerun data starting from index " .. rerunIndex .. " (" .. string.format("%.8X", rerunIndex) .. ")...")
			
			-- main data collection loop
			keepLooping = true
			isRerun = true
			rerunLoop(rerunIndex)
		end
	end
	
	local function loadTableLoop(index)
		local maxIndex = index+incrementSize-1
		if maxIndex > #classStr then maxIndex = #classStr end
		
		for i=index, maxIndex do
			classTable[i] = string.char(string.byte(classStr, i))
		end
		
		print(incCount .. "/" .. numIncrements)
		
		
		C_Timer.After(1, function()
			loopIndex = loopIndex+incrementSize
			incCount = incCount+1
			if loopIndex <= #classStr then
				loadTableLoop(loopIndex)
			else
				loadingComplete()
			end
		end)
		
	end
	
	loadTableLoop(loopIndex)
	
end


-- SLASH COMMANDS ------------------------------------------------------------------------------------------------------------------

-- Change main GUIDIndex (be very careful with this)
SLASH_GUIDINDEX1 = "/guidindex"
SlashCmdList["GUIDINDEX"] = function(num)
	if num == "" then
		if GUIDIndex == nil then 
			print("Current index is: nil")
		else
			print("Current index is: " .. GUIDIndex)
		end
	else
		if keepLooping then
			print("Cannot change index while data collection is in progress.")
		else
			local oldIndex = GUIDIndex
			if oldIndex == nil then oldIndex = "nil" end
			GUIDIndex = tonumber(num)
			print("Changing GUID Index from " .. oldIndex .. " to " .. GUIDIndex .. ".")
		end
	end
end

-- Start data collection where you left off
SLASH_GUIDSTART1 = "/guidstart"
SlashCmdList["GUIDSTART"] = function()
	if keepLooping then
		print("Data collection is already in progress.")
	else
		print("Loading String Data into the Table")
		loadTable(false,nil)
		-- see loadingComplete for remainder
	end
end

-- Stop data collection for either reruns or standard
SLASH_GUIDSTOP1 = "/guidstop"
SlashCmdList["GUIDSTOP"] = function()
	if not keepLooping then
		print("No data collection is in progress.")
	elseif not isRerun then
		keepLooping = false
		print("Stopping data collection at index " .. nextIndex .. " (" .. string.format("%.8X", nextIndex) .. ")...")
		C_Timer.After(1.5, function()
			GUIDIndex = nextIndex
			-- load into string
			classStr = table.concat(classTable)
			print("/reload to save data!")
		end)
	elseif isRerun then
		keepLooping = false
		isRerun = false
		print("Stopping rerun data collection at index " .. rerunIndex .. " (" .. string.format("%.8X", rerunIndex) .. ")...")
		C_Timer.After(1.5, function()
			-- load into string
			classStr = table.concat(classTable)
			print("/reload to save data!")
		end)
	end
end

-- helper function that just prints a player. Used in guidfetch
local function printPlayer(intGUID, name, class, classEng, race, gender, realm)
	if realm == "" then realm = GetRealmName() end
	if gender == 2 then gender = "Male" elseif gender == 3 then gender = "Female" end
	print(ClassColor[classEng] .. intGUID .. " (" .. string.format("%.8X", intGUID) .. ")|r")
	print(ClassColor[classEng] .. name .. ": " .. gender .. " " .. race .. " " .. class .. " " .. realm .. "|r")
end

-- Print a player for a given GUID
-- If 8 digits long and starts with 0, assume hex
-- its going to be a looooooooong time until we see guids starting with 1
SLASH_GUIDFETCH1 = "/guidfetch"
SlashCmdList["GUIDFETCH"] = function(num)
	local guid
	local valid = false
	if #num == 8 and string.sub(num, 1,1) == "0" then -- if hex
		num = "0x" .. num
		local intnum = tonumber(num)
		if intnum == nil then
			print("Invalid number: " .. num)
		else
			guid = string.format("%.8X", intnum)
			valid = true
		end
	else -- if decimal
		local intnum = tonumber(num)
		if intnum == nil then
			print("Invalid number: " .. num)
		else
			guid = string.format("%.8X", intnum)
			valid = true
		end
	end
	
	-- if valid input, print character from guid
	if valid then
		for i=1, numPrefixes, 1 do
			GetPlayerInfoByGUID(GUIDPrefix[i] .. guid)
		end
		
		C_Timer.After(1, function()
			local exists = false
			for i=1, numPrefixes, 1 do
				if GetPlayerInfoByGUID(GUIDPrefix[i] .. guid) ~= nil then
					local class, classEng, race, _, gender, name, realm = GetPlayerInfoByGUID(GUIDPrefix[i] .. guid)
					printPlayer(num, name, class, classEng, race, gender, realm)
					exists = true
					break
				end
			end
			
			if not exists then
				print(ClassColor["NONE"] .. num .. " (" .. string.format("%.8X", num) .. ")|r")
				print(ClassColor["NONE"] .. "This player does not exist.|r")
			end
		end)
	end
end

-- Reruns start at an already passed index and overwrite it with updated data w/ a notification.
-- This is used to identify errors that may have been made in the first pass.
-- So far no errors have been found.
SLASH_GUIDRERUN1 = "/guidrerun"
SlashCmdList["GUIDRERUN"] = function(num)
	local guid
	local intnum
	local valid = false
	if #num == 8 and string.sub(num, 1,1) == "0" then -- if hex
		num = "0x" .. num
		intnum = tonumber(num)
		if intnum == nil then
			print("Invalid number: " .. num)
		else
			guid = string.format("%.8X", intnum)
			valid = true
		end
	else -- if decimal
		intnum = tonumber(num)
		if intnum == nil then
			print("Invalid number: " .. num)
		else
			guid = string.format("%.8X", intnum)
			valid = true
		end
	end
	
	-- if valid input, start the rerun loop
	if valid then
		if keepLooping then
			print("Data collection is already in progress.")
		else
			print("Loading String Data into the Table")
			loadTable(true,intnum)
			-- see loadingComplete for remainder
		end
	end
end


-- Logout Warning
-- reminder to stop data collection before you are logged out if you are alt-tabbed
StaticPopup1:HookScript("OnShow", function()
	if StaticPopup1.which == "CAMP" and keepLooping then
		SendChatMessage("Hey! You Are Logging Out!", "WHISPER", nil, UnitName("player"))
		PlaySound(7256, "master")
	end
end)


-- 20 minute warning after afk (5 minutes until 30 min kick)
local afkCounter = 0
local afkActiveTable = {}
local afkEventFrame = CreateFrame("Frame")

afkEventFrame:RegisterEvent("CHAT_MSG_SYSTEM")
afkEventFrame:HookScript("OnEvent", function(_, _, message)
	if message == "You are now Away: Away" then 				-- on afk start
		afkCounter = afkCounter+1
		local myNumber = afkCounter
		afkActiveTable[myNumber] = true
		C_Timer.After(1200, function()
			if afkActiveTable[myNumber] then
				SendChatMessage("25 Minute Warning!", "WHISPER", nil, UnitName("player"))
				PlaySound(7256, "master")
			end
		end)
	elseif message == "You are no longer Away." then			-- on afk end
		for i=1,#afkActiveTable do
			afkActiveTable[i] = false
		end
	end
end)