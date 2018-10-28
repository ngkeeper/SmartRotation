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
	self.one_man_dps = dps or 8000 -- for time-to-kill estimation, use lower dps if not sure
	
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
	
	--self.buffs: printMatrix()
	
	return self
end

function PlayerStatus: update()
	self: updateGCD()
	self: updateBuff()
	self: updateDot()
	self: updateDot("focus")
	self: updateCd()
	self: updatePower(self.power_type)
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

function PlayerStatus: updateBuff()
	for i, v in ipairs(self.buff_spell) do
		self.buffs: update("up", v, false)
		self.buffs: update("stack", v, 0) 
		self.buffs: update("expiration", v, 0)
	end
	for i = 1, 40 do
        local ub_name, _, ub_stack, _, _, ub_expiration, _, _, _, ub_spell_id = UnitBuff("player", i)
        if ub_name then
			--print(ub_name..ub_spell_id)
            for j, v in ipairs(self.buff_spell) do
                if ( type(v) == "string" and v == ub_name ) or ( type(v) == "number" and v == ub_spell_id ) then
                    self.buffs: update("up", v, true)
					self.buffs: update("stack", v, ub_stack)
					self.buffs: update("expiration", v, ub_expiration - GetTime())
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
					dots: update("up", v, true)
					dots: update("expiration", v, ud_expiration)
                    local _, _, _ , cast_time = GetSpellInfo(v);
                    cast_time = cast_time / 1000
                    if ud_duration * 0.3 + cast_time - ( ud_expiration - GetTime() ) < 0 then
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
        if cd_remain <= gcd_remain + reaction_time then
            cd_ready = true
        else
            cd_ready = false
        end
		
		local charge = GetSpellCharges(v)
		self.cds:update("remain", v, cd_remain)
		self.cds:update("up", v, cd_ready)
		self.cds:update("charge", v, charge)
		
		
    end 
	--print(self.cds:get("up", 228266))
	--self.cds: printMatrix()
end

function PlayerStatus: timeToKill(unit)
	local target = unit or "target"
	local hp_target = UnitHealth(target)
	if not(UnitCanAttack("player","target")) or not(UnitExists("target")) then hp_target = 0 end
	local group_size = math.max(1, GetNumGroupMembers())
	
	self.time_to_kill = hp_target / (self.one_man_dps * group_size)
	return self.time_to_kill
end

function PlayerStatus: isSpellCasting(spell)
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
	if not is_cd_spell then 
		cd_ready = true 
	else
		cd_ready = self.cds: get("up", spell_label)
	end
	local usable = select(1, IsUsableSpell(spell))
	local not_being_cast = not(self: isSpellCasting(spell)) 
	
	return (cd_ready and usable and not_being_cast)
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
	local expiration = dots: get("expiration", spell)
	return math.max(0, expiration - GetTime())
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
function PlayerStatus: getGCD()
	return self.gcd
end