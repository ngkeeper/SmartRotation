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
	self.low_health_threshold = 0
	
	self.blacklist = {"Explosives"}
	self:reset()
end

function CleaveLog2: targets(override)
	local hit = self:targetsHit() or 0
	local nearby = self:targetsNearby() or 0
	local aggro = self:targetsAggro() or 0
	local low_health = self:targetsLowHealth() or 0
	
	local enemies = math.max(hit, nearby, aggro)
	if hit > 0 then enemies = math.max(hit, nearby) end
	
	if not override then 
		enemies = self.temporary_disabled and 0 or enemies
	end
	return enemies, hit, nearby, aggro, low_health
end

function CleaveLog2: targetsHit()
	return self.targets_hit
end

function CleaveLog2: targetsNearby()
	return self.nearby
end

function CleaveLog2: targetsAggro()
	return self.aggro
end

function CleaveLog2: targetsLowHealth()
	return self.low_health
end

function CleaveLog2: setTimeout(timeout)
	self.timeout = timeout or self.timeout
end

function CleaveLog2: setLowHealthThreshold(health)
	self.low_health_threshold = health or 0
end

function CleaveLog2: reset()
	self.enemies = {}			-- enemies hit by the pre-defined cleave spells only
	self.enemies_tanked = {}	-- enemies tanked by the tank
	self.tanks = {}
	self.targets_hit = 0
	self.nearby = 0
	self.aggro = 0
	self.low_health = 0
	self.temporary_disabled = nil
	self.temporary_disabled_expiration = nil
	self.temporary_disabled_flag = nil
end

function CleaveLog2: update()
	local t = time()
	local targets_hit = 0
	local targets_aggro = 0
	
	for i, v in ipairs(self.enemies) do
		if (t - v.timestamp > self.timeout) or not v.active then
			v.active = false
		end
		if v.active then
			targets_hit = targets_hit + 1 
		end
	end
	
	for i, v in ipairs(self.enemies_tanked) do
		if (t - v.timestamp > self.timeout) or not v.active then
			v.active = false
		end
		if v.active then
			targets_aggro = targets_aggro + 1 
		end
	end
	
	self.temporary_disabled = (t <= (self.temporary_disabled_expiration or 0))
	self.targets_hit = targets_hit
	self.aggro = targets_aggro
	
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
	local aggro = 0
	local low_health = 0
	
	self: scanTanks()
	
	for i = 1, 40 do
		local unit = "nameplate"..i
		if UnitExists(unit) then
			if UnitCanAttack("player", unit) then 
				if IsItemInRange(self.melee_range_item, unit) and 
					not self:isBlackListed(UnitName(unit)) then 
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

function CleaveLog2: scanTanks()
	self.tanks = self.tanks or {}
	
	self.last_tank_scan = self.last_tank_scan or 0
	if time() - self.last_tank_scan < 30 then return nil end
	self.last_tank_scan = time()
	
	self.tanks = {}
	--table.insert(self.tanks, UnitGUID("party1"))
	
	if IsInGroup() then 
		local group = IsInRaid() and "raid" or "party"
		local unitid = GetNumGroupMembers()
		for i = 1, unitid do
			local member = group..i
			local role = UnitGroupRolesAssigned(member)
			if role == "TANK" then 
				table.insert(self.tanks, UnitGUID(member))
			end
        end
	end
	--printTable(self.tanks)
end

function CleaveLog2: isBlackListed(name)
	local bl = false
	for i, v in ipairs(self.blacklist) do 
		if v == name then bl = true end 
	end
	return bl
end

function CleaveLog2: updateCombat()
	local timestamp, message, _, source_GUID, source_name, _, _, 
		  dest_GUID, dest_name, _, _, spell_id, spell_name = CombatLogGetCurrentEventInfo()
	local player_name = UnitName("player")
	
	if not(message) then return nil end
	
	if self:isBlackListed(dest_name) then return nil end
	
	--print(message, source_name, dest_name)
	
	if message == "UNIT_DIED" then 
		for i, v in ipairs(self.enemies) do 
			if v.guid == dest_GUID then 
				v.active = false
			end
		end
		for i, v in ipairs(self.enemies_tanked) do 
			if v.guid == dest_GUID then 
				v.active = false
			end
		end
	end
	
	if message == "SWING_DAMAGE" or message == "SPELL_DAMAGE" then 
		local tank_hitting = false
		for i, v in ipairs(self.tanks) do 
			if v == source_GUID then tank_hitting = true end
		end 
		if tank_hitting then 
			local slot
			for i, v in ipairs(self.enemies_tanked) do 
				if v.guid == dest_GUID then 
					slot = i
				end
			end
			if not slot then 
				for i = 1, 40 do
					if not self.enemies_tanked[i] then 
						slot = i
						break
					elseif not self.enemies_tanked[i].active then 
						slot = i
						break
					end
				end
			end
			slot = slot or 1
			self.enemies_tanked[slot] = {}
			self.enemies_tanked[slot].name = dest_name
			self.enemies_tanked[slot].guid = dest_GUID
			self.enemies_tanked[slot].timestamp = timestamp
			self.enemies_tanked[slot].active = true
			self.enemies_tanked[slot].low_health = false
		end
		--printTable(self.enemies_tanked)
	end
	
	if not(source_name == player_name) or not(message == "SPELL_DAMAGE") then 
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
				elseif not self.enemies[i].active then 
					slot = i
					break
				end
			end
		end
		slot = slot or 1
		self.enemies[slot] = {}
		self.enemies[slot].name = dest_name
		self.enemies[slot].guid = dest_GUID
		self.enemies[slot].timestamp = timestamp
		self.enemies[slot].active = true
		self.enemies[slot].low_health = false
	end
end


