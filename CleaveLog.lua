CleaveLog = {}
CleaveLog.__index = CleaveLog

setmetatable(CleaveLog, {
  __call = function (class, ...)
	local self = setmetatable({}, class)
    self:_new(...)
    return self
  end,
})

function CleaveLog: _new(spells, targets_cleave, targets_aoe)
	
	self.targets_hit = 1
	self.is_cleave = false
	self.is_aoe = false
	self.cleave_timeout = 8
	self.aoe_timeout = 8
	self.spell_timeout = 0
	self.last_hit = time() - self.cleave_timeout
	self.last_cleave = time() - self.cleave_timeout
	self.last_aoe = time() - self.cleave_timeout
	self.cleave_spells = spells
	self.targets_cleave = targets_cleave or 2
	self.targets_aoe = targets_aoe or self.targets_cleave
	return self
end

function CleaveLog: targetsHit()
	return self.targets_hit
end

function CleaveLog: isCleave()
	if time() - self.last_cleave > self.cleave_timeout then
		self.is_cleave = false
	else 
		self.is_cleave = true
	end
	return self.is_cleave
end
function CleaveLog: isAOE()
	if time() - self.last_aoe > self.aoe_timeout then
		self.is_aoe = false
	else 
		self.is_aoe = true
	end
	return self.is_aoe
end
function CleaveLog: getCleaveThreshold(targets)
	return self.targets_cleave
end
function CleaveLog: setCleaveThreshold(targets)
	self.targets_cleave = targets or 2
	if self.targets_cleave > self.targets_aoe then 
		self: setAOEThreshold(self.targets_cleave)
	end
	return self.targets_cleave
end
function CleaveLog: getAOEThreshold(targets)
	return self.targets_aoe 
end
function CleaveLog: setAOEThreshold(targets)
	self.targets_aoe = targets or (self.targets_cleave or 2)
	if self.targets_aoe < self.targets_cleave then 
		self.targets_aoe = self.targets_cleave
	end
	return self.targets_aoe
end
function CleaveLog: setTimeout(cleave, aoe)
	self.cleave_timeout = cleave or self.cleave_timeout
	self.aoe_timeout = aoe or self.aoe_timeout
end
function CleaveLog: update()  
    local timestamp, message, _, _, source_name, _, _, _, _, _, _, spell_id, spell_name = CombatLogGetCurrentEventInfo()
	local player_name = UnitName("player")
	
	if not(message) or not(source_name == player_name) or not(message == "SPELL_DAMAGE") then 
		return nil 
	end
	
    --print(tostring(spell_name).." "..tostring(spell_id))
	if not message then 
		return nil 
	end    
    
    local is_relevant_spell = false
	
    for i, v in ipairs(self.cleave_spells) do
		local spell = spell_name
		if type(v) == "number" then spell = spell_id end
		--print(spell)
        if v == spell then 
            is_relevant_spell = true
        end
    end
    
    -- If you tried to cast your cleave spell
    if is_relevant_spell then
		-- if this event ran on the same exact moment as last event
		if (timestamp == self.last_hit) then -- simultaneous hit
			
			self.targets_hit = self.targets_hit + 1
		else
			if timestamp - self.last_hit > self.spell_timeout then
				self.targets_hit = 1
			end
		end                                                        
		-- store the time of last event
		if self.targets_hit >= self.targets_cleave then
			self.last_cleave = timestamp
		end
		if self.targets_hit >= self.targets_aoe then
			self.last_aoe = timestamp
		end
		self.last_hit = timestamp
    elseif timestamp - self.last_cleave > self.cleave_timeout then
        self.targets_hit = 1
    end
    --print(self.targets_hit)
	
    if timestamp - self.last_cleave > self.cleave_timeout then
        self.is_cleave = false
    else 
        self.is_cleave = true
    end
	if timestamp - self.last_aoe > self.aoe_timeout then
        self.is_aoe = false
    else 
        self.is_aoe = true
    end
end


