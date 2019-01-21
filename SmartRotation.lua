DEBUG = 0

local refresh = 10		-- refresh rate, Hz

-- player object creation function
function createPlayer(currentPlayer, enabled)
	local talent = select(1, GetSpecializationInfo(GetSpecialization()))
	if currentPlayer then currentPlayer:disable() end 
	local player
	if (talent == 258) then --"Shadow"
		player = PriestShadow()
	elseif (talent == 577) then -- "Havoc"
		player = DemonhunterHavoc()
	elseif (talent == 70) then -- "Retribution"
		player = PaladinRetribution()
	elseif (talent == 64) then -- "Frost"
		player = MageFrost()
	elseif (talent == 102) then -- "Balance"
		player = DruidBalance()
	else
		player = nil
	end
	if player then 
		-- convert old saved variables to new format
		if SIZE then 
			CONFIG = CONFIG or {}
			player:setSize(SIZE)
			CONFIG.size = SIZE
		end
		if X and Y then 
			CONFIG = CONFIG or {}
			player:setPosition(X, Y)
			CONFIG.x = X
			CONFIG.y = Y
		end
		
		-- CONFIG is the new saved variable
		if CONFIG then 
			player:setSize(CONFIG.size)
			player:setPosition(CONFIG.x, CONFIG.y)
		else
			CONFIG = {}
			CONFIG.size = player:getSize()
			CONFIG.x, CONFIG.y = player:getPosition()
			CONFIG.focus = false
		end
		if not CONFIG.tutorial then 
			print("|cff00ffff SmartRotation Tutorial |r (for first-run only)")
			print("|cffffff00 /sr |r -- Show / hide ")
			print("|cffffff00 /sr size [n] |r -- Adjust size")
			print("|cffffff00 /sr pos [x] [y] |r -- Adjust position, (0, 0) is the center")
			print("|cffffff00 /sr focus |r -- Toggle focus tracking")
			print("|cffffff00 /sr tutorial |r -- Reset tutorial (will show tutorial on your next login).")
			CONFIG.tutorial = true
		end
				
		if enabled then
			player:enable()
		else
			player:disable()
		end
	end
	return player
end

local player
local enabled = true

SLASH_SRONOFF1 = "/sr"
SLASH_SRONOFF2 = "/smartrotation"
-- /sr 					toggle on/off
-- /sr size x			set icon size, default 50
-- /sr position x y		set icon position, default 0, -80

SlashCmdList.SRONOFF = function(msg)
	if player then
		if msg == "" then 
			if enabled then
				enabled = false
				player:disable()
			else
				enabled = true
				player:enable()
			end
		end
		
		local args = {}
		for v in msg:gmatch("%S+") do 
			table.insert(args, v)
		end
		if args[1] == "size" then
			CONFIG.size = tonumber(args[2]) or size
			player:setSize(CONFIG.size)
		end
		if args[1] == "position" or args[1] == "pos" then
			CONFIG.x = tonumber(args[2]) or CONFIG.x
			CONFIG.y = tonumber(args[3]) or CONFIG.y
			player:setPosition(CONFIG.x, CONFIG.y)
		end
		if args[1] == "focus" then 
			CONFIG.focus = not CONFIG.focus
			if CONFIG.focus then 
				print("SR: Focus module enabled. A yellow icon indicates the spell to be casted on your focus. ")
			else
				print("SR: Focus module disabled.")
			end
		end
	end
end

-- login event
local fLogin = CreateFrame("Frame")
fLogin: RegisterEvent("PLAYER_LOGIN")
fLogin: SetScript("OnEvent", function(self, event, ...)
end)

-- update events
local fUpdate = CreateFrame("Frame")
fUpdate: RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
fUpdate: RegisterEvent("PLAYER_TALENT_UPDATE")
--fUpdate: RegisterEvent("UPDATE_ALL_UI_WIDGETS")
fUpdate: SetScript("OnEvent", function(self, event, ...)
	player = createPlayer(player, enabled)
	if player then
		player: updateTalent()
	end
end)


local last_refresh = GetTime()
-- combat events
local f = CreateFrame("Frame")
f:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
f:SetScript("OnEvent", function(self, event, ...)
	---------------------------
	-- for development use only
	-- print damage spells
	-- local _, message, _, _, source_name, _, _, _, _, _, _, spell_id, spell_name = CombatLogGetCurrentEventInfo()
	-- local player_name = UnitName("player")
	-- if message and source_name == player_name and message == "SPELL_DAMAGE" then 
		-- print(string.format("%s %d", spell_name, spell_id))
	-- end
	
	-- print all buffs
	-- for i = 1, 40 do
		-- local ub_name, _, ub_stack, _, _, ub_expiration, _, _, _, ub_spell_id = UnitBuff("player", i)
		-- if ub_name then
			-- print(string.format("%s %d", ub_name, ub_spell_id))
		-- end    
	-- end
	
	-- print all debuffs on target
	-- for i = 1, 40 do
		-- local ud_name, _, _, _, ud_duration, ud_expiration, _, _, _, ud_spell_id = UnitDebuff("target", i, "PLAYER")
        -- if ud_name then
			-- print(string.format("%s %d", ud_name, ud_spell_id))
        -- end
    -- end
	---------------------------
	if player then
		player: updateCombat()
	end
end)

-- update on every frame
f:SetScript("OnUpdate", function(self, ...)
	local timestamp = GetTime()
	if timestamp - last_refresh > 1 / refresh then 
		---------------------------
		-- for development use only

		---------------------------
		
		last_refresh = timestamp
		if player then 
			local toDisable = UnitInVehicle("player") or UnitOnTaxi("player")
			if toDisable and player: isEnabled() then
				player: disable()
			end
			if not(toDisable) and not(player: isEnabled()) and enabled then
				player: enable()
			end
			player: update()
			player: nextSpell()
		end
	end
end)

