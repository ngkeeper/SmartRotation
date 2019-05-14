Player = {}
Player.__index = Player

setmetatable(Player, {
  __call = function (class, ...)
	local self = setmetatable({}, class)
    self:_new(...)
    return self
  end,
})

function Player: _new()
	self.azerite = self:getAzeriteInfo()
	local _, ilevel = GetAverageItemLevel()
	-- for time-to-kill estimation, use lower dps if not sure
	self.one_man_dps = 400 * math.exp(0.01 * ilevel) * 0.8 -- f(...) is from simc estimation, 0.7 is an estimation factor
	self.team_dps = self.one_man_dps
end

function Player: dps()
	return self.one_man_dps, self.team_dps
end

function Player: talent(tier)
	if tier then 
		return select(2, GetTalentTierInfo(tier, 1))
	else
		local t = {}
		for i = 1, 7 do
			local selection = select(2, GetTalentTierInfo(i, 1))
			t[i] = selection
		end
		return t
	end
end

function Player: power(powerType)
	return UnitPower("player", powerType)
end

function Player: powerMax(powerType)
	return UnitPowerMax("player", powerType)
end

function Player: getAzeriteInfo()
	local azerite = LabeledMatrix()
	azerite:addRow("rank")
	
	local slot = {1, 3, 5}
	for _, i in ipairs(slot) do
		local item = Item:CreateFromEquipmentSlot(i)
		if (not item:IsItemEmpty()) then
			local itemLoc = ItemLocation:CreateFromEquipmentSlot(i)
			if itemLoc then  
				if C_AzeriteEmpoweredItem.IsAzeriteEmpoweredItem(itemLoc) then 
					local tierInfo = C_AzeriteEmpoweredItem.GetAllTierInfo(itemLoc)
					for tier, info in pairs(tierInfo) do
						for _, powerId in pairs(info.azeritePowerIDs) do
							if C_AzeriteEmpoweredItem.IsPowerSelected(itemLoc, powerId) then 
								local r = azerite:get("rank", powerId)
								if not r then 
									azerite:addColumn(powerId)
								end
								--print(tostring(powerId))
								azerite:update("rank", powerId, ( r or 0 ) + 1)
							end
						end
					end
				end
			end
		end
	end
	--printTable(azerite)
	return azerite
end

function Player: getAzeriteRank(powerId)
	if not powerId then return nil end
	if not self.azerite then 
		self.azerite = self:getAzeriteInfo()
	end
	return self.azerite: get("rank", powerId) or 0
end

function Player: canBeCCed(unit)
	unit = unit or "target"
	local level = UnitLevel(unit)
	return ( level > 0 and level <= 120 ) 
end

function Player: timeToKill(unit)
	local target = unit or "target"
	local hp_target = UnitHealth(target)
	if not(UnitCanAttack("player","target")) or not(UnitExists("target")) then hp_target = 0 end
	local group_size = math.max(1, GetNumGroupMembers())
	local n_dps = 0
	if IsInGroup() then 
		local group = IsInRaid() and "raid" or "party"
		local unitid = GetNumGroupMembers()
		if group == "party" then 	
			unitid = unitid - 1 -- party1-4 does not include player
			n_dps = n_dps + 1	-- assume player is always dps (otherwise he doesn't need this addon)
		end
		for i = 1, unitid do
			local member = group..i
			local role = UnitGroupRolesAssigned(member)
			local inrange = UnitInRange(member)
			-- the following doesn't work in raids / dungeons
			--local distanceSquared, checkedDistance = UnitDistanceSquared(member)
			--local notFarAway = (distanceSquared ^ 0.5 <= 60) and checkedDistance
			if role == "DAMAGER" and inrange then n_dps = n_dps + 1 end
			if role == "TANK" and inrange then n_dps = n_dps + 0.5 end
        end
	end
	n_dps = math.max(1, n_dps)
	--print(n_dps)
	
	self.team_dps = self.one_man_dps * n_dps;
	self.time_to_kill = hp_target / self.team_dps
	-- if self.predict_buff and self.predict_cd and self.predict_dot then 
		-- self.time_to_kill = math.max(0, self.time_to_kill - self.next_spell_time)
	-- end
	return self.time_to_kill, self.team_dps, n_dps
end