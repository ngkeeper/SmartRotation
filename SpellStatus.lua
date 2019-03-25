SpellStatus = {}
SpellStatus.__index = SpellStatus

setmetatable(SpellStatus, {
  __call = function (class, ...)
	local self = setmetatable({}, class)
    self:_new(...)
    return self
  end,
})

function SpellStatus: _new(spells)
	
	self.spells = spells
	-- spells.gcd		The spell to be used to track gcd
	-- spells.buff		Buff ids. Can be different from the spell that applies it.
	-- spells.dot		Dot/debuff ids. Can be different from the spell that applies it.
	-- spells.cd		Spells with cooldown (and need to be tracked).
	-- spells.blacklist Blacklisted spells (used to filter combat logs)
	
	self.gcd = 1.5
	-- if cd of a spell < gcd + reaction, cd is considered 0
	-- spell icon will pop up [reaction] seconds before it becomes off cd
	-- if reaction is set too high, it results in an idle gap
	-- channeling allows much higher tolerance, because waiting ~= doing nothing
	-- channeling reaction time is the smaller of either the pre-defined value, 
	-- or the left-over channeling time (or normal reaction time, if left-over is less than that)
	self.human_reaction_time = 0.2  			
	self.human_reaction_time_channeling = 1
	
	self.buffs = LabeledMatrix()
	self.buffs: addRow({"up", "stack", "expiration"})
	self.buffs: addColumn(self.spells.buff)
	
	self.dots = LabeledMatrix()
	self.dots: addRow({"up", "refreshable", "expiration"})
	self.dots: addColumn(self.spells.dot)
	
	self.dots_focus = LabeledMatrix()
	self.dots_focus: addRow({"up", "refreshable", "expiration"})
	self.dots_focus: addColumn(self.spells.dot)
	
	self.cds = LabeledMatrix()
	self.cds: addRow({"up", "remain", "charge"})
	self.cds: addColumn(self.spells.cd)
	
	self.previous = {}
	self.previous.spell = nil
	self.previous.target = nil
	self.previous.time = nil
	
	self.casting = {}
	self.casting.spell = nil
	self.casting.start = nil
	self.casting.finish = nil
	self.casting.target_GUID = nil	-- Combat log does not give destination for SPELL_CAST_START
									-- Using current target as an estimation
	self.casting_last_check = GetTime()
	
	self.next_spell_time = 0	-- next spell is usable in x seconds
	self.predict_cd = true		-- whether returns cd info based on the time of next spell
	self.predict_buff = true	-- same
	self.predict_dot = true	-- same
	
	return self
end

function SpellStatus: update()
	--self: updateTime()
	self: updateGCD()
	self: updateBuff()
	self: updateDot()
	self: updateDot("focus")
	self: updateCd()
	self: updateCastingStatus()
	self: updateNextSpellTime()
end

function SpellStatus: updateCombat()
	local timestamp, message, _, _, source_name, _, _, dest_guid, dest_name, _, _, spell_id, spell_name = CombatLogGetCurrentEventInfo()
	if not message then 
		return nil 
	end
	
	local player_name = UnitName("player")
	if source_name == player_name then
		--print(tostring(self:isBlacklisted(spell_id)).." "..tostring(spell_name).." "..tostring(spell_id).." "..tostring(message))
		if message == "SPELL_CAST_SUCCESS" and not self:isBlacklisted(spell_id) then --or "SPELL_AURA_APPLIED" then 
			--print(tostring(spell_name).." "..tostring(spell_id))
			self.previous.spell = spell_id
            self.previous.time = timestamp
			local target_guid = UnitGUID("target")
			local focus_guid = UnitGUID("focus")
			if dest_guid == target_guid then 
				self.previous.target = "target"
			elseif dest_guid == focus_guid then 
				self.previous.target = "focus"
			else
				self.previous.target = nil
			end
        end
	end
	
end

function SpellStatus: updateGCD()
	local _, current_gcd = GetSpellCooldown(self.spells.gcd)
	if current_gcd > 0 then self.gcd = current_gcd end
	return self.gcd
end

function SpellStatus: updateNextSpellTime()
	local gcd_start, gcd = GetSpellCooldown(self.spells.gcd)
	local time_gcd = gcd_start > 0 and ( gcd + gcd_start - GetTime() ) or 0
	local time_casting = 0
	if self.casting.spell then 
		time_casting = self.casting.finish - GetTime()
	end
	self.next_spell_time = math.max(time_gcd, time_casting)
end

function SpellStatus: updateCastingStatus()
	--print(tostring(self.casting.spell).." "..tostring(self.casting_target_GUID))
	local _, _, _, uci_start, uci_end, _, _, _, uci_spellid = UnitCastingInfo("player")
	if uci_spellid and uci_start and uci_end then 
		self.casting_last_check = GetTime()
		if math.abs(uci_start / 1000 - (self.casting.start or 0) ) > 0.1 then 
			self.casting.spell = uci_spellid
			self.casting.start = uci_start / 1000
			self.casting.finish = uci_end / 1000
			self.casting.target_GUID = UnitGUID("target")
		end
	end
	if GetTime() - self.casting_last_check > 0.3 then 	-- 0.3 to handle some latency
		self.casting.spell = nil
		self.casting.start = nil
		self.casting.finish = nil
		self.casting.target_GUID = nil
	end
	
end

function SpellStatus: updateBuff()
	for i, v in ipairs(self.spells.buff) do
		self.buffs: update("up", v, false)
		self.buffs: update("stack", v, 0) 
		self.buffs: update("expiration", v, 0)
	end
	local gcd_start, gcd_duration = GetSpellCooldown(self.spells.gcd)
	local gcd_remain = math.max(0, gcd_duration - GetTime() + gcd_start)
	local prediction = self.predict_buff and self.next_spell_time or 0
	for i = 1, 40 do
        local ub_name, _, ub_stack, _, _, ub_expiration, _, _, _, ub_spell_id = UnitBuff("player", i)
        if ub_name then
			--print(ub_name..ub_spell_id)
            for j, v in ipairs(self.spells.buff) do
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

function SpellStatus: updateDot(unit)
	local target = unit or "target"
	local dots = self.dots
	if target == "focus" then
		dots = self.dots_focus
	end 
	-- table objects are passed by reference
	-- "dots" is a reference of either self.dots or self.dots_focus
	local gcd_start, gcd_duration = GetSpellCooldown(self.spells.gcd)
	local gcd_remain = math.max(0, gcd_duration - GetTime() + gcd_start)
	local prediction = self.predict_dot and self.next_spell_time or 0
	
	for i, v in ipairs(self.spells.dot) do 
		dots: update("up", v, false)
		dots: update("refreshable", v, true)
		dots: update("expiration", v, 0)
	end 
	for i = 1, 40 do
		local ud_name, _, _, _, ud_duration, ud_expiration, _, _, _, ud_spell_id = UnitDebuff(target, i, "PLAYER")
        if ud_name then
            for j, v in ipairs(self.spells.dot) do
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

function SpellStatus: updateCd()
	local gcd_start, gcd_duration = GetSpellCooldown(self.spells.gcd)
	local gcd_remain = math.max(0, gcd_duration - GetTime() + gcd_start)
	
	local channel_name, _, _, _, chennel_end = UnitChannelInfo("player")
	
	local reaction_time = self.human_reaction_time
	-- gives longer reaction time if channeling
	if channel_name then
		local channel_remain = math.max(chennel_end/1000 - GetTime())
		reaction_time = math.max(self.human_reaction_time, math.min(self.human_reaction_time_channeling, channel_remain))
	end
		
    for i, v in ipairs(self.spells.cd) do
		
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
		
		local charge, max_charge, cd_start1, cd_duration1 = GetSpellCharges(v)
		if max_charge then 
			local cd_remain1 = 0 
			if cd_start1 < 4200000 then 
				cd_remain1 = math.max(0, cd_duration1 * (max_charge - charge) - GetTime() + cd_start1)
				cd_remain1 = math.max(0, cd_remain1 - prediction)
				charge = max_charge - math.ceil(cd_remain1 / cd_duration1)
			end
		end
		self.cds:update("remain", v, math.max(0, cd_remain - prediction))
		self.cds:update("up", v, cd_ready)
		self.cds:update("charge", v, charge)
		--if spell == "Fury of Elune" then print(gcd_duration) end
    end 
	--print(self.cds:get("up", 228266))
	--self.cds: printMatrix()
end

function SpellStatus: isCasting(spell, uci)
	-- the default option has ~300ms delay
	-- this feature is to prevent the "gap"
	-- that exists between "end of cast" and "spell lands"
	-- use 'uci' for no-delay cast prediction
	if not uci then return (spell == self.casting.spell) end
	
	-- if 'uci' is defined
	local uci_spell, _, _, uci_start, uci_end, _, _, _, uci_spell_id  = UnitCastingInfo("player")
	if uci_spell then 
		local casting = uci_spell
		if type(spell) == "number" then casting = uci_spell_id end
		return ( spell == casting )
	else 
		return false 
	end
end


function SpellStatus: isSpellReady(spell)
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
	local usable, nomana = IsUsableSpell(spell)
	usable = usable or nomana
	local not_being_cast = not(self: isCasting(spell)) 
	local switched_target = (UnitGUID("target") ~= self.casting.target_GUID)
	local not_recently_cast = not(is_cd_spell or is_dot_spell) or not(self.casting.spell == spell_label)

	
	return cd_ready and usable and 
		( (not_being_cast and not_recently_cast) or (switched_target and not(is_cd_spell) ) )
end 


function SpellStatus: cooldown(spell)
	local cd = {}
	cd.charge = self.cds: get("charge", spell)
	cd.remain = self.cds: get("remain", spell)
	cd.up = self.cds: get("up", spell)
	return cd
end

function SpellStatus: spellCharge(spell)
	return self.cds: get("charge", spell)
end

function SpellStatus: spellRemainCD(spell)
	return self.cds: get("remain", spell)
end

function SpellStatus: buff(spell)
	local b = {}
	b.up = self:buffUp(spell)
	b.stack = self:buffStack(spell)
	b.remain = self:buffRemain(spell)
	return b
end

function SpellStatus: buffUp(spell)
	return self.buffs: get("up", spell)
end

function SpellStatus: buffStack(spell)
	return self.buffs: get("stack", spell)
end

function SpellStatus: buffRemain(spell)
	return self.buffs: get("expiration", spell)
end

function SpellStatus: dot(spell, duration, unit)
	local d = {}
	d.up = self:dotUp(spell, unit)
	d.remain = self:dotRemain(spell, unit)
	d.refreshable = self:dotRefreshable(spell, unit, duration)
	return d
end

function SpellStatus: dotUp(spell, unit)
	unit = unit or "target"
	local dots = self.dots
	if unit == "focus" then dots = self.dots_focus end
	return dots: get("up", spell)
end

function SpellStatus: dotRefreshable(spell, unit, duration)
	unit = unit or "target"
	local dots = self.dots
	if unit == "focus" then dots = self.dots_focus end
	-- 'duration' is optional 
	-- if duration is not given, it will default as the full duration of the current dot 
	-- however, if the current dot is already 130% elongated, the refreshable state estimate will be not accurate
	if duration then 
		local dot_up = dots: get("up", spell)
		local dot_remain = dots: get("expiration", spell)
		local dot_refreshable = false
		if not dot_up or dot_remain < duration * 0.3 then 
			dot_refreshable = true
		end
		return dot_refreshable
	end
	
	-- the original 'refreshable' status is based on dynamic duration
	return dots: get("refreshable", spell)
end

function SpellStatus: dotRemain(spell, unit)
	unit = unit or "target"
	local dots = self.dots
	if unit == "focus" then dots = self.dots_focus end
	return dots: get("expiration", spell)
end

function SpellStatus: isBlacklisted(spell)
	local bl = false
	if self.spells.blacklist then 
		for _, v in pairs(self.spells.blacklist) do 
			bl = bl or (v==spell)
		end
	end
	return bl
end

function SpellStatus: previousCast()
	local previous = {}
	if true then --time() - self.previous.time <= 2 then 
		previous.spell = self.previous.spell
		previous.target = self.previous.target
		previous.time = self.previous.time
	end
	return previous
end

function SpellStatus: enablePrediction(predict)
	predict = predict or true
	self.predict_cd = predict
	self.predict_buff = predict
	self.predict_dot = predict
end

function SpellStatus: gcd()
	return self.gcd
end

function SpellStatus: timeNextSpell()	-- time to next 
	return self.next_spell_time
end