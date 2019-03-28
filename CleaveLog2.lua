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
	self.nearby_enabled = true
	self.cleave_spells = spells
	self.melee_range_item = 32321
	self.low_health_threshold = 2
	self:reset()
end

function CleaveLog2: targets()
	local hit = self:targetsHit() or 0
	local nearby = self:targetsNearby() or 0
	local low_health = self:targetsLowHealth() or 0
	local enemies = hit
	if hit == 0 then enemies = nearby end
	--if hit > nearby then enemies = nearby end
	
	return enemies, hit, nearby, low_health
end

function CleaveLog2: targetsHit()
	return self.temporary_disabled and 0 or self.targets_hit
end

function CleaveLog2: targetsNearby()
	return self.temporary_disabled and 0 or self.nearby
end

function CleaveLog2: targetsLowHealth()
	return self.temporary_disabled and 0 or self.low_health
end

function CleaveLog2: setTimeout(timeout)
	self.timeout = timeout or self.timeout
end

function CleaveLog2: setLowHealthThreshold(health)
	self.low_health_threshold = health or 0
end

function CleaveLog2: reset()
	self.enemies = {}	-- enemies hit by the pre-defined cleave spells only
	self.targets_hit = 0
	self.nearby = 0
	self.low_health = 0
	self.temporary_disabled = nil
	self.temporary_disabled_expiration = nil
	self.temporary_disabled_flag = nil
end

function CleaveLog2: update()
	local t = time()
	local targets_hit = 0
	for i, v in ipairs(self.enemies) do
		if (t - v.timestamp > self.timeout) or not v.active then
			v.active = false
		end
		if v.active then
			targets_hit = targets_hit + 1 
		end
	end
	
	self.temporary_disabled = (t <= (self.temporary_disabled_expiration or 0))
	self.targets_hit = targets_hit
	
	self:scanNameplates()

	-- print("--------")
	-- print(self.targets_hit)
	-- for i,v in ipairs(self.guid_active) do
		-- print(tostring(i).." "..tostring(floor(time() - self.guid_timestamp[i])).." "..tostring(self.guid[i]))
	-- end
end
function CleaveLog2: temporaryDisable(duration, flag)
	
	if flag then 
		if (self.temporary_disabled_flag or 0) >= flag then 
			return nil 
		end
	end
	--print(duration)
	duration = duration or 6
	self.temporary_disabled = true
	self.temporary_disabled_expiration = time() + duration 
	self.temporary_disabled_flag = flag
	
	if duration == 0 then 
		self.temporary_disabled = false
		self.temporary_disabled_expiration = nil
		self.temporary_disabled_flag = flag
	end
end
function CleaveLog2: scanNameplates()
	local nearby = 0
	local low_health = 0
	for i = 1, 40 do
		local unit = "nameplate"..i
		if UnitExists(unit) then
			if UnitCanAttack("player", unit) then 
				if IsItemInRange(self.melee_range_item, unit) then 
				--and IsSpellInRange("shred", unit) ~= 0 then
					nearby = nearby + 1
				end
				
				for i, v in ipairs(self.enemies) do 
					if v.guid == UnitGUID(unit) then 
						if UnitHealth(unit) <= self.low_health_threshold then 
							v.low_health = true
							low_health = low_health + 1
						else
							v.low_health = false
						end
					end 
				end
			end
		end
	end
	self.nearby = nearby;
	self.low_health = low_health;
end
function CleaveLog2: updateCombat()
	local timestamp, message, _, _, source_name, _, _, dest_GUID, _, _, _, spell_id, spell_name = CombatLogGetCurrentEventInfo()
	local player_name = UnitName("player")
	
	if not(message) then return nil end
	if message == "UNIT_DIED" then 
		for i, v in ipairs(self.enemies) do 
			if v.guid == dest_GUID then 
				v.active = false
			end
		end
	end
	
	if not(source_name == player_name) or not(message == "SPELL_DAMAGE") then 
		return nil 
	end
	
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
		--print(spell_name.." "..tostring(spell_id).." "..tostring(dest_GUID))   
		local slot
		for i, v in ipairs(self.enemies) do 
			if v.guid == dest_GUID then 
				slot = i
			end
		end
		if not slot then 
			for i = 1, 40 do
				if not self.enemies[i] then 
					slot = i
					break
				end
			end
		end
		slot = slot or 1
		self.enemies[slot] = {}
		self.enemies[slot].guid = dest_GUID
		self.enemies[slot].timestamp = timestamp
		self.enemies[slot].active = true
		self.enemies[slot].low_health = false
	end
end


