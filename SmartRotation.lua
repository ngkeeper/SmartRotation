SR_DEBUG = 0
DEBUG = 0

local refresh = 10	-- refresh rate, Hz

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
		player = MageFrost2()
	elseif (talent == 102) then -- "Balance"
		player = DruidBalance()
	elseif (talent == 103) then -- "Feral"
		player = DruidFeral()
	else
		player = nil
	end
	if player then 
		-- convert old saved variables to new format
		if SIZE then 
			SRSRCONFIG = SRSRCONFIG or {}
			player:setSize(SIZE)
			SRCONFIG.size = SIZE
		end
		if X and Y then 
			SRCONFIG = SRCONFIG or {}
			player:setPosition(X, Y)
			SRCONFIG.x = X
			SRCONFIG.y = Y
		end
		
		-- SRCONFIG is the new saved variable
		if SRCONFIG then 
			player:setSize(SRCONFIG.size)
			player:setPosition(SRCONFIG.x, SRCONFIG.y)
		else
			SRCONFIG = {}
			SRCONFIG.size = player:getSize()
			SRCONFIG.x, SRCONFIG.y = player:getPosition()
			SRCONFIG.focus = false
		end
		if not SRCONFIG.tutorial then 
			print("|cff00ffff SmartRotation Tutorial |r (for first-run only)")
			print("|cffffff00 /sr |r -- Show / hide ")
			print("|cffffff00 /sr size [n] |r -- Adjust size")
			print("|cffffff00 /sr pos [x] [y] |r -- Adjust position, (0, 0) is the center")
			print("|cffffff00 /sr focus |r -- Toggle focus tracking")
			print("|cffffff00 /sr tutorial |r -- Reset tutorial (will show tutorial on your next login).")
			SRCONFIG.tutorial = true
		end
				
		if enabled then
			player:enable()
		else
			player:disable()
		end
	end
	return player
end

function printTable ( t )  
    local printTable_cache={}
    local function sub_printTable(t,indent)
        if (printTable_cache[tostring(t)]) then
            print(indent.."*"..tostring(t))
        else
            printTable_cache[tostring(t)]=true
            if (type(t)=="table") then
                for pos,val in pairs(t) do
                    if (type(val)=="table") then
                        print(indent.."["..pos.."] => "..tostring(t).." {")
                        sub_printTable(val,indent..string.rep(" ",string.len(pos)+8))
                        print(indent..string.rep(" ",string.len(pos)+6).."}")
                    elseif (type(val)=="string") then
                        print(indent.."["..pos..'] => "'..val..'"')
                    else
                        print(indent.."["..pos.."] => "..tostring(val))
                    end
                end
            else
                print(indent..tostring(t))
            end
        end
    end
    if (type(t)=="table") then
        print(tostring(t).." {")
        sub_printTable(t,"  ")
        print("}")
    else
        sub_printTable(t,"  ")
    end
    print()
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
			SRCONFIG.size = tonumber(args[2]) or size
			player:setSize(SRCONFIG.size)
		end
		if args[1] == "position" or args[1] == "pos" then
			SRCONFIG.x = tonumber(args[2]) or SRCONFIG.x
			SRCONFIG.y = tonumber(args[3]) or SRCONFIG.y
			player:setPosition(SRCONFIG.x, SRCONFIG.y)
		end
		if args[1] == "focus" then 
			SRCONFIG.focus = not SRCONFIG.focus
			if SRCONFIG.focus then 
				print("SR: Focus module enabled. A yellow icon indicates the spell to be casted on your focus. ")
			else
				print("SR: Focus module disabled.")
			end
		end
		if args[1] == "debug" then 
			if not args[2] then SR_DEBUG = math.max(0, 1 - SR_DEBUG) end 
			if args[2] == "buff" then printTable(player.variables.buff) end
			if args[2] == "dot" then printTable(player.variables.dot) end
			if tonumber(args[2]) then SR_DEBUG = tonumber(args[2]) end 
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

