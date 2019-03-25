CleaveLog2 = {}
CleaveLog2.__index = CleaveLog2

setmetatable(CleaveLog2, {
  __call = function (class, ...)
	local self = setmetatable({}, class)
    self:_new(...)
    return self
  end,
})

function CleaveLog2: _new(spells)
	self:reset()
	self.timeout = 6
	self.cleave_spells = spells
end

function CleaveLog2: targetsHit()
	return self.targets_hit 
end

function CleaveLog2: setTimeout(timeout)
	self.timeout = timeout or self.timeout
end

function CleaveLog2: reset()
	self.guid = {}
	self.guid_timestamp = {}
	self.guid_active = {}
	self.targets_hit = 0
end

function CleaveLog2: update()
	local t = time()
	local targets_hit = 0
	
	for i, _ in ipairs(self.guid_active) do
		if t - self.guid_timestamp[i] > self.timeout then
			self.guid_active[i] = false
		else 
			targets_hit = targets_hit + 1 
		end
	end
	
	self.targets_hit = targets_hit
	
	-- print("--------")
	-- print(self.targets_hit)
	-- for i,v in ipairs(self.guid_active) do
		-- print(tostring(i).." "..tostring(floor(time() - self.guid_timestamp[i])).." "..tostring(self.guid[i]))
	-- end
end

function CleaveLog2: updateCombat()
	local timestamp, message, _, _, source_name, _, _, dest_GUID, _, _, _, spell_id, spell_name = CombatLogGetCurrentEventInfo()
	local player_name = UnitName("player")
	
	if not(message) or not(source_name == player_name) or not(message == "SPELL_DAMAGE") then 
		return nil 
	end
	--print(spell_name.." "..tostring(spell_id).." "..tostring(dest_GUID))    
    local is_relevant_spell = false
	
    for i, v in ipairs(self.cleave_spells) do
		local spell = spell_name
		if type(v) == "number" then spell = spell_id end
        if v == spell then 
            is_relevant_spell = true
        end
    end
    
    -- If you tried to cast your cleave spell
    if is_relevant_spell then
		local slot
		for i, v in ipairs(self.guid_active) do 
			if self.guid[i] == dest_GUID then 
				slot = i
			end
		end
		if not slot then 
			for i = 1, 20 do
				if not self.guid_active[i] then 
					slot = i
					break
				end
			end
		end
		slot = slot or 1
		self.guid[slot] = dest_GUID
		self.guid_timestamp[slot] = timestamp
		self.guid_active[slot] = true
	end
end

-- old version of cleave log
-- use simultaneous hits to determine targets hit
-- however, it cannot correctly count if spell creates rapid hits (e.g. frozen orb)

-- function CleaveLog2: update()  
    -- local timestamp, message, _, _, source_name, _, _, dest_GUID, _, _, _, spell_id, spell_name = CombatLogGetCurrentEventInfo()
	-- local player_name = UnitName("player")

	-- if not(message) or not(source_name == player_name) or not(message == "SPELL_DAMAGE") then 
		-- return nil 
	-- end
	-- --print(spell_name.." "..tostring(spell_id).." "..tostring(dest_GUID))    
    -- local is_relevant_spell = false
	
    -- for i, v in ipairs(self.cleave_spells) do
		-- local spell = spell_name
		-- if type(v) == "number" then spell = spell_id end
        -- if v == spell then 
            -- is_relevant_spell = true
        -- end
    -- end

    -- -- If you tried to cast your cleave spell
    -- if is_relevant_spell then
		-- --print(self.targets_hit)
		-- -- if this event ran on the same exact moment as last event
		-- if (timestamp == self.last_hit) then -- simultaneous hit
			
			-- self.targets_hit = self.targets_hit + 1
		-- else
			-- if timestamp - self.last_hit > self.spell_timeout then
				-- self.targets_hit = 1
			-- end
		-- end                                                        
		-- -- store the time of last event
		-- if self.targets_hit >= self.targets_cleave then
			-- self.last_cleave = timestamp
		-- end
		-- if self.targets_hit >= self.targets_aoe then
			-- self.last_aoe = timestamp
		-- end
		-- self.last_hit = timestamp
    -- elseif timestamp - self.last_cleave >= self.cleave_timeout then
        -- self.targets_hit = 1
    -- end
    -- --print(self.targets_hit)
	
    -- if timestamp - self.last_cleave >= self.cleave_timeout then
        -- self.is_cleave = false
    -- else 
        -- self.is_cleave = true
    -- end
	-- if timestamp - self.last_aoe >= self.aoe_timeout then
        -- self.is_aoe = false
    -- else 
        -- self.is_aoe = true
    -- end
-- end


