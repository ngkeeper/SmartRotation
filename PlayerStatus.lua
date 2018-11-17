PlayerStatus = {}
PlayerStatus.__index = PlayerStatus

setmetatable(PlayerStatus, {
  __call = function (class, ...)
	local self = setmetatable({}, class)
    self:_new(...)
    return self
  end,
})

function PlayerStatus: _new(gcd_spell, buff_spell, dot_spell, cd_spell, casting_spell, cleave_spell, cleave_targets, aoe_targets, dps)

	self.gcd_spell = gcd_spell
	self.buff_spell = buff_spell
	self.dot_spell = dot_spell
	self.cd_spell = cd_spell
	self.casting_spell = casting_spell
	self.cleave_spell = cleave_spell
	self.cleave_targets = cleave_targets or 2
	self.aoe_targets = aoe_targets or self.cleave_targets
	
	local _, ilevel = GetAverageItemLevel()
	local dps_ilevel = 400 * math.exp(0.01 * ilevel) * 0.65 -- f(...) is from simc estimation, 0.65 is a practical coefficient
	self.one_man_dps = dps or dps_ilevel -- for time-to-kill estimation, use lower dps if not sure
	
	self.gcd = 1.5
	
	-- if cd of a spell < gcd + reaction, cd is considered 0
	-- spell icon will pop up [reaction] seconds before it becomes off cd
	-- if reaction is set too high, it results in an idle gap
	-- channeling allows much higher tolerance, because waiting ~= doing nothing
	-- channeling reaction time is the smaller of either the pre-defined value, 
	-- or the left-over channeling time (or normal reaction time, if left-over is less than that)
	self.human_reaction_time = 0.2  			
	self.human_reaction_time_channeling = 1
	
	self.casting = ""
	
	self.cleave = CleaveLog(self.cleave_spell, self.cleave_targets, self.aoe_targets)
	
	-- timestamp in combat log resembles time(), but is accurate to 0.001s
	-- GetTime() is accurate to 0.001s, but has an offset
	-- timestamp - time_offset gives GetTime()
	self.time_offset = nil
	self.time_offset_replcates = {}
	self.time_integer = time()
	
	self.buffs = LabeledMatrix()
	self.buffs: addRow({"up", "stack", "expiration"})
	self.buffs: addColumn(self.buff_spell)
	--self.buffs: printMatrix()
	
	self.dots = LabeledMatrix()
	self.dots: addRow({"up", "refreshable", "expiration"})
	self.dots: addColumn(self.dot_spell)
	
	self.dots_focus = LabeledMatrix()
	self.dots_focus: addRow({"up", "refreshable", "expiration"})
	self.dots_focus: addColumn(self.dot_spell)
	
	self.cds = LabeledMatrix()
	self.cds: addRow({"up", "remain", "charge"})
	self.cds: addColumn(self.cd_spell)
	
	self.last_cast_spell = nil
	self.last_cast_time = time()
	self.last_cast_target = nil
	
	self.casting_spell = nil
	self.casting_time = nil
	self.casting_start = time()
	self.casting_target_GUID = nil	-- Combat log does not give destination for SPELL_CAST_START
									-- Using current target as an estimation
	self.casting_last_check = GetTime()
	
	self.next_spell_time = 0	-- next spell is usable in x seconds
	self.predict_cd = false		-- whether returns cd info based on the time of next spell
	self.predict_buff = false	-- same
	self.predict_dots = false	-- same
	--self.buffs: printMatrix()
	
	return self
end

function PlayerStatus: update()
	--self: updateTime()
	self: updateGCD()
	self: updateBuff()
	self: updateDot()
	self: updateDot("focus")
	self: updateCd()
	self: updatePower(self.power_type)
	self: updateCastingStatus()
	self: updateNextSpellTime()
end
function PlayerStatus: updateCombat()
	self.cleave: update()
	local timestamp, message, _, _, source_name, _, _, dest_guid, dest_name, _, _, spell_id, spell_name = CombatLogGetCurrentEventInfo()
	if not message then 
		return nil 
	end
	
	local player_name = UnitName("player")
	if source_name == player_name then
		--print(message..spell_name)
		-- This is not a good way to get casting status
		-- The combat log has a significant delay (over 0.5 seconds in Ogrimmar)
		-- if message == "SPELL_CAST_START" then 
			-- self.casting_spell = spell_id
			-- self.casting_start = timestamp
			-- self.casting_target_GUID = UnitGUID("target")
			-- self.casting_time = (select(4, GetSpellInfo(self.casting_spell)) / 1000 ) or 0
		-- end
		if message == "SPELL_CAST_SUCCESS" then --or "SPELL_AURA_APPLIED" then 
			self.last_cast_spell = spell_id
            self.last_cast_time = timestamp
			local target_guid = UnitGUID("target")
			local focus_guid = UnitGUID("focus")
			if dest_guid == target_guid then 
				self.last_cast_target = "target"
			elseif dest_guid == focus_guid then 
				self.last_cast_target = "focus"
			else
				self.last_cast_target = nil
			end
        end
	end
	
end
function PlayerStatus: updateTime()
	local n = 0
	for _ in pairs(self.time_offset_replcates) do n = n + 1 end
	if n < 5 then 
		local new_time = time()
		if new_time - self.time_integer == 1 then 
			n = n + 1
			self.time_offset_replcates[n] = time() - GetTime()
			self.time_integer = new_time
		elseif new_time - self.time_integer > 1 then 	
			self.time_integer = new_time
		end
	else
		-- calculate average
		local sum = 0
		local vmax = self.time_offset_replcates[1]
		local vmin = self.time_offset_replcates[1]
		n = 0 
		for i, v in ipairs(self.time_offset_replcates) do
			n = n + 1
			sum = sum + v
			vmax = math.max(vmax, v)
			vmin = math.min(vmin, v)
		end
		local avg = sum / n
		
		-- calculate standard deviation
		local sum = 0 
		for i, v in ipairs(self.time_offset_replcates) do
			n = n + 1
			sum = sum + (v-avg)^2
		end
		local std = (sum / math.max(n - 1, 1)) ^ 0.5
		
		if std < 0.1 then 
			self.time_offset = avg
		else
			self.time_offset_replcates = {}
		end
		--print(tostring(avg).." "..tostring(std))
	end
end
function PlayerStatus: updateBuffAndCd()
	self: updateBuff()
	self: updateCd()
end
function PlayerStatus: updatePower(powertype)
	self.power = UnitPower("player", powertype)
	self.power_max = UnitPowerMax("player", powertype)
end
function PlayerStatus: updateGCD()
	local _, current_gcd = GetSpellCooldown(self.gcd_spell)
	if current_gcd > 0 then self.gcd = current_gcd end
	return self.gcd
end
function PlayerStatus: updateNextSpellTime()
	local gcd_start, gcd = GetSpellCooldown(self.gcd_spell)
	local time_gcd = gcd_start > 0 and ( gcd + gcd_start - GetTime() ) or 0
	local time_casting = 0
	if self.casting_spell then 
		time_casting = self.casting_end - GetTime()
	end
	self.next_spell_time = math.max(time_gcd, time_casting)
end
function PlayerStatus: updateCastingStatus()
	--print(tostring(self.casting_spell).." "..tostring(self.casting_target_GUID))
	local _, _, _, uci_start, uci_end, _, _, _, uci_spellid = UnitCastingInfo("player")
	if uci_spellid and uci_start and uci_end then 
		self.casting_last_check = GetTime()
		if math.abs(uci_start / 1000 - (self.casting_start or 0) ) > 0.1 then 
			self.casting_spell = uci_spellid
			self.casting_start = uci_start / 1000
			self.casting_end = uci_end / 1000
			self.casting_target_GUID = UnitGUID("target")
		end
	end
	if GetTime() - self.casting_last_check > 0.3 then 	-- 0.3 to handle some latency
		self.casting_spell = nil
		self.casting_start = nil
		self.casting_end = nil
		self.casting_target_GUID = nil
	end
	
end
function PlayerStatus: updateBuff()
	for i, v in ipairs(self.buff_spell) do
		self.buffs: update("up", v, false)
		self.buffs: update("stack", v, 0) 
		self.buffs: update("expiration", v, 0)
	end
	local gcd_start, gcd_duration = GetSpellCooldown(self.gcd_spell)
	local gcd_remain = math.max(0, gcd_duration - GetTime() + gcd_start)
	local prediction = self.predict_buff and self.next_spell_time or 0
	for i = 1, 40 do
        local ub_name, _, ub_stack, _, _, ub_expiration, _, _, _, ub_spell_id = UnitBuff("player", i)
        if ub_name then
			--print(ub_name..ub_spell_id)
            for j, v in ipairs(self.buff_spell) do
                if ( type(v) == "string" and v == ub_name ) or ( type(v) == "number" and v == ub_spell_id ) then
					local expiration = ub_expiration - GetTime()
					expiration = expiration - math.max(self.next_spell_time, gcd_remain)
					expiration = math.max(0, expiration)
					local expired = (expiration == 0) and not(ub_expiration == 0)
                    self.buffs: update("up", v, not(expired))
					self.buffs: update("stack", v, ub_stack)
					self.buffs: update("expiration", v, expiration)
                end
            end
        end    
    end
	--self.buffs: printMatrix()
end

function PlayerStatus: updateDot(unit)
	local target = unit or "target"
	local dots = self.dots
	if target == "focus" then
		dots = self.dots_focus
	end 
	-- table objects are passed by reference
	-- "dots" is a reference of either self.dots or self.dots_focus
	local gcd_start, gcd_duration = GetSpellCooldown(self.gcd_spell)
	local gcd_remain = math.max(0, gcd_duration - GetTime() + gcd_start)
	local prediction = self.predict_dot and self.next_spell_time or 0
	
	for i, v in ipairs(self.dot_spell) do 
		dots: update("up", v, false)
		dots: update("refreshable", v, true)
		dots: update("expiration", v, 0)
	end 
	for i = 1, 40 do
		local ud_name, _, _, _, ud_duration, ud_expiration, _, _, _, ud_spell_id = UnitDebuff(target, i, "PLAYER")
        if ud_name then
            for j, v in ipairs(self.dot_spell) do
                if ( type(v) == "string" and v == ud_name ) or ( type(v) == "number" and v == ud_spell_id ) then
					local expiration = ud_expiration - GetTime()
					expiration = expiration - math.max(self.next_spell_time, gcd_remain)
					expiration = math.max(0, expiration)
					dots: update("up", v, expiration > 0)
					dots: update("expiration", v, expiration)
                    local _, _, _ , cast_time = GetSpellInfo(v);
                    cast_time = cast_time / 1000
                    if ud_duration * 0.3 + cast_time < expiration then
                        dots: update("refreshable", v, false)
                    end
                end
            end
        end
    end
	--print(self.dots: get("up", 589))
	--print(self.dots_focus: get("up", 589))
end

function PlayerStatus: updateCd()
	local gcd_start, gcd_duration = GetSpellCooldown(self.gcd_spell)
	local gcd_remain = math.max(0, gcd_duration - GetTime() + gcd_start)
	
	local channel_name, _, _, _, chennel_end = UnitChannelInfo("player")
	
	local reaction_time = self.human_reaction_time
	-- gives longer reaction time if channeling
	if channel_name then
		local channel_remain = math.max(chennel_end/1000 - GetTime())
		reaction_time = math.max(self.human_reaction_time, math.min(self.human_reaction_time_channeling, channel_remain))
	end
		
    for i, v in ipairs(self.cd_spell) do
		
		-- for some reason, GetSpellCooldown(spell_id)
		-- always returns 0, 0 for some spells, e.g. void bolt
		-- using spell name solves the problem
		local spell = v
		if type(v) == "number" then 
			spell = select(1, GetSpellInfo(spell))
		end
		
		
        local cd_start, cd_duration = GetSpellCooldown(spell)
		
		cd_start = cd_start or 0
		local cd_duration = cd_duration or 0
        local cd_remain = math.max(0, cd_duration - GetTime() + cd_start)
		local prediction = self.predict_cd and self.next_spell_time or 0
        if cd_remain <= math.max(reaction_time + gcd_remain, prediction) then
            cd_ready = true
        else
            cd_ready = false
        end
		
		local charge = GetSpellCharges(v)
		self.cds:update("remain", v, math.max(0, cd_remain - prediction))
		self.cds:update("up", v, cd_ready)
		self.cds:update("charge", v, charge)
		-- "charge" need to be improved using self.next_spell_time
		
    end 
	--print(self.cds:get("up", 228266))
	--self.cds: printMatrix()
end

function PlayerStatus: timeToKill(unit)
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
	self.time_to_kill = hp_target / (self.one_man_dps * n_dps)
	return self.time_to_kill, n_dps
end

function PlayerStatus: isSpellCasting(spell)
	-- local uci_spell, _, _, uci_start, uci_end, _, _, _, uci_spell_id  = UnitCastingInfo("player")
	-- if uci_spell then 
		-- local casting = uci_spell
		-- if type(spell) == "number" then casting = uci_spell_id end
		-- return ( spell == casting )
	-- else 
		-- return false 
	-- end
	return (spell == self.casting_spell)
end
function PlayerStatus: isSpellCastingNoDelay(spell)
	-- self:isSpellCasting() has ~300ms delay
	-- this feature is to prevent the "gap"
	-- that exists between "end of cast" and "spell lands"
	-- use this function for no-delay cast prediction
	
	local uci_spell, _, _, uci_start, uci_end, _, _, _, uci_spell_id  = UnitCastingInfo("player")
	if uci_spell then 
		local casting = uci_spell
		if type(spell) == "number" then casting = uci_spell_id end
		return ( spell == casting )
	else 
		return false 
	end
end

function PlayerStatus: isSpellReady(spell)
	-- for some reason, IsUsableSpell(spell_id)
	-- always returns true for talent spells, even if they are not chosen
	-- using spell name solves the problem

	local spell_label = spell
	if type(spell) == "number" then
		spell = select(1, GetSpellInfo(spell))
	end
	
	local cd_ready
	local is_cd_spell = self.cds: searchColumn(spell_label)
	local is_dot_spell = self.dots: searchColumn(spell_label)
	if not is_cd_spell then 
		cd_ready = true 
	else
		cd_ready = self.cds: get("up", spell_label)
	end
	local usable = select(1, IsUsableSpell(spell))
	local not_being_cast = not(self: isSpellCasting(spell)) 
	local switched_target = (UnitGUID("target") ~= self.casting_target_GUID)
	local not_recently_cast = not(is_cd_spell or is_dot_spell) or not(self.casting_spell == spell_label)
	
	return cd_ready and usable and 
		( (not_being_cast and not_recently_cast) or (switched_target and not(is_cd_spell) ) )
end 


function PlayerStatus: isDotUp(spell, unit)
	unit = unit or "target"
	local dots = self.dots
	if unit == "focus" then dots = self.dots_focus end
	return dots: get("up", spell)
end

function PlayerStatus: isDotRefreshable(spell, unit)
	unit = unit or "target"
	local dots = self.dots
	if unit == "focus" then dots = self.dots_focus end
	return dots: get("refreshable", spell)
end
function PlayerStatus: setPowerType(powertype)
	self.power_type = powertype
end
function PlayerStatus: getPower()
	return self.power
end
function PlayerStatus: getPowerMax()
	return self.power_max
end
function PlayerStatus: getSpellCharge(spell)
	return self.cds: get("charge", spell)
end
function PlayerStatus: getCdRemain(spell)
	return self.cds: get("remain", spell)
end
function PlayerStatus: isBuffUp(spell)
	return self.buffs: get("up", spell)
end

function PlayerStatus: getBuffStack(spell)
	return self.buffs: get("stack", spell)
end
function PlayerStatus: getBuffRemain(spell)
	return self.buffs: get("expiration", spell)
end
function PlayerStatus: getBuffStack(spell)
	return self.buffs: get("stack", spell)
end

function PlayerStatus: getDotRemain(spell, unit)
	unit = unit or "target"
	local dots = self.dots
	if unit == "focus" then dots = self.dots_focus end
	return dots: get("expiration", spell)
end
function PlayerStatus: getLastCast()
	return self.last_cast_spell
end
function PlayerStatus: getLastCastTarget()
	return self.last_cast_target
end
function PlayerStatus: getLastCastTime()
	return time() - self.last_cast_time
end
function PlayerStatus: isCleave()
	return self.cleave: isCleave()
end
function PlayerStatus: isAOE()
	return self.cleave: isAOE()
end
function PlayerStatus: getCleaveTargets()
	return self.cleave: targetsHit()
end
function PlayerStatus: getCleaveThreshold()
	return self.cleave: getThreshold()
end
function PlayerStatus: setCleaveThreshold(targets)
	self.cleave: setCleaveThreshold(targets)
end
function PlayerStatus: setAOEThreshold(targets)
	self.cleave: setAOEThreshold(targets)
end
function PlayerStatus: setCleaveTimeout(cleave, aoe)
	self.cleave: setTimeout(cleave, aoe)
end 
function PlayerStatus: setPredictCd(predict)
	self.predict_cd = predict or false
end
function PlayerStatus: setPredictBuff(predict)
	self.predict_buff = predict or false
end
function PlayerStatus: setPredictDot(predict)
	self.predict_dot = predict or false
end
function PlayerStatus: setPredictAll(predict)
	self:setPredictCd(predict)
	self:setPredictBuff(predict)
	self:setPredictDot(predict)
end
function PlayerStatus: getGCD()
	return self.gcd
end
function PlayerStatus: getNextSpellTime()
	return self.next_spell_time
end