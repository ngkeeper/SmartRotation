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
	self:reset()
end

function CleaveLog2: targets()
	local hit = self:targetsHit() or 0
	local nearby = self:targetsNearby() or 0
	--print(hit.." ".. nearby)
	local enemies = hit
	if hit == 0 then enemies = nearby end
	if hit > nearby then enemies = nearby end
	return enemies
end

function CleaveLog2: targetsHit()
	--print(tostring(self.temporary_disabled) .." "..tostring((self.temporary_disabled_expiration or time()) - time()))
	return self.temporary_disabled and 0 or self.targets_hit
end

function CleaveLog2: targetsNearby()
	--print(tostring(self.temporary_disabled) .." "..tostring((self.temporary_disabled_expiration or time()) - time()))
	return self.temporary_disabled and 0 or self.nearby
end

function CleaveLog2: setTimeout(timeout)
	self.timeout = timeout or self.timeout
end

function CleaveLog2: reset()
	self.guid = {}
	self.guid_timestamp = {}
	self.guid_active = {}
	self.targets_hit = 0
	self.nearby = 0
	self.temporary_disabled = nil
	self.temporary_disabled_expiration = nil
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
	
	self.temporary_disabled = (t <= (self.temporary_disabled_expiration or 0))
	self.targets_hit = targets_hit
	
	if nearby_enabled or true then 
		self:scanNearby()
	end
	-- print("--------")
	-- print(self.targets_hit)
	-- for i,v in ipairs(self.guid_active) do
		-- print(tostring(i).." "..tostring(floor(time() - self.guid_timestamp[i])).." "..tostring(self.guid[i]))
	-- end
end
function CleaveLog2: temporaryDisable(duration)
	duration = duration or 6
	self.temporary_disabled = true
	self.temporary_disabled_expiration = time() + duration 
	if duration == 0 then 
		self.temporary_disabled = false
		self.temporary_disabled_expiration = nil
	end
end
function CleaveLog2: scanNearby()
	local nearby = 0
	for i = 1, 40 do
		local unit = "nameplate"..i
		if UnitExists(unit) then
			if UnitCanAttack("player", unit) and IsItemInRange(self.melee_range_item, unit) then 
			--and IsSpellInRange("shred", unit) ~= 0 then
				nearby = nearby + 1
			end
		end
	end
	self.nearby = nearby;
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
		--print(spell_name.." "..tostring(spell_id).." "..tostring(dest_GUID))   
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


