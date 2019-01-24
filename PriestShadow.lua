PriestShadow = {}
PriestShadow.__index = PriestShadow

setmetatable(PriestShadow, {
  __index = PlayerRotation, -- inherit from the PlayerRotation class
  __call = function (class, ...)
    local self = setmetatable({}, class)
    self:_new(...)
    return self
  end,
})

function PriestShadow:_new()
	-- all spells are case-sensitive
	-- (this will be improved in the future)
	local gcd_spell 	= 	589 		--"Shadow Word: Pain"    -- can be any zero-cooldown spell
	local buff_spell 	= { 194249 }	--"Voidform"
    local dot_spell 	= {	589, 		--"Shadow Word: Pain"
							34914 		--"Vampiric Touch"
						  }
    local cd_spell 		= {	228260, 	--"Void Eruption"
							280711, 	--"Dark Ascension"
							228266, 	--"Void Bolt"
							200174, 	--"Mindbender"
							34433,		--"Shadowfiend"
							8092, 		--"Mind Blast"
							205385, 	--"Shadow Crash"
							263346, 	--"Dark Void"
							32379, 		--"Shadow Word: Death"
							205065,		--"Void Torrent"
							205351,		--"Shadow Word: Void" 	
						  }
    local casting_spell = {	228260, 	--"Void Eruption"
							8092, 		--"Mind Blast"
							205351, 	--"Shadow Word: Void" 	
							34914, 		--"Vampiric Touch"
							15407, 		--"Mind Flay"
							48045 		--"Mind Sear" 
						  }
	local cleave_spell 	= {	49821, 		--"Mind Sear"
							263346, 	--"Dark Void"
							228360, 	--"Void Eruption"
							228361, 	--"Void Eruption"
							205386 		--"Shadow Crash"
						  }
	local cleave_targets = 2
	local aoe_targets = 5
	
	-- self:getSpellID(dot_spell)
	-- self:getSpellID(cd_spell)
	-- self:getSpellID(casting_spell)
	-- self:getSpellID(cleave_spell)
	
	PlayerRotation:_new(gcd_spell, buff_spell, dot_spell, cd_spell, casting_spell, cleave_spell, cleave_targets, aoe_targets)
	
	self.player: setTimeout(4)
	self.player: setPredictAll(true) 
	--self.enabled = false
	
	-- the main icon is included in PlayerRotation class
	
	self.anchor_x = 0
	self.anchor_y = -135
	self.button: SetPoint("CENTER", self.anchor_x, self.anchor_y )
	self.hightlight_aoe = false
	
	-- create icons for major cd display
	self.button_mindbender = CreateFrame("Button", "SR_button_mindbender", UIParent, "ActionButtonTemplate")
	self.button_mindbender: Disable()
	self.button_mindbender: SetNormalTexture(self.button_mindbender: GetHighlightTexture())
	local talent_mindbender = (self.talent[6] == 2)
	if talent_mindbender then 
		self.button_mindbender.icon: SetTexture(GetSpellTexture(200174))
	else
		self.button_mindbender.icon: SetTexture(GetSpellTexture(34433))
	end
	self.button_mindbender:Hide()
	
	self.button_void_eruption = CreateFrame("Button", "SR_button_void_eruption", UIParent, "ActionButtonTemplate")
	self.button_void_eruption: Disable()
	self.button_void_eruption: SetNormalTexture(self.button_void_eruption: GetHighlightTexture())
	self.button_void_eruption.icon: SetTexture(GetSpellTexture(228260))
	self.button_void_eruption:Hide()
	
	local talent_dark_void = (self.talent[3] == 3)
	if talent_dark_void then 
		self.button_dark_void = CreateFrame("Button", "SR_button_dark_void", UIParent, "ActionButtonTemplate")
		self.button_dark_void: Disable()
		self.button_dark_void: SetNormalTexture(self.button_dark_void: GetHighlightTexture())
		self.button_dark_void.icon: SetTexture(GetSpellTexture(263346))
		self.button_dark_void: Show()
		
		self.cooldown_dark_void = CreateFrame("Cooldown", "SR_cd_dark_void", self.button_dark_void, "CooldownFrameTemplate")
		self.cooldown_dark_void: SetAllPoints(self.button_dark_void)
		self.cooldown_dark_void: SetDrawEdge(false)
		self.cooldown_dark_void: SetSwipeColor(1, 1, 1, .85)
		self.cooldown_dark_void:SetHideCountdownNumbers(false)
	end
	
	self:setSize()
end
function PriestShadow: setSize(size)
	PlayerRotation:setSize(size)
	self.size = size or self.size
	self.ui_ratio = self.size / 50
	
	local talent_dark_void = (self.talent[3] == 3)
	
	self.button_mindbender: SetSize(self.size * 0.65,self.size * 0.65)
	self.button_void_eruption: SetSize(self.size * 0.65,self.size * 0.65)
	self.button_void_eruption: SetPoint("CENTER", self.anchor_x - 50 * self.ui_ratio, self.anchor_y )
	
	if not(talent_dark_void) then 
		self.button_mindbender: SetPoint("CENTER", self.anchor_x + 50 * self.ui_ratio, self.anchor_y )
	else 
		self.button_dark_void: SetSize(self.size * 0.65,self.size * 0.65)
		self.button_mindbender: SetPoint("CENTER", self.anchor_x + 85 * self.ui_ratio, self.anchor_y )
		self.button_dark_void: SetPoint("CENTER", self.anchor_x + 50 * self.ui_ratio, self.anchor_y )
	end
end	
function PriestShadow: setPosition(x, y)
	PlayerRotation:setPosition(x, y)
	self.anchor_x = x or self.anchor_x
	self.anchor_y = y or self.anchor_y
	self:setSize()
end
function PriestShadow: enable()
	self.button_void_eruption: Show()
	self.button_mindbender: Show()
	if self.button_dark_void then self.button_dark_void: Show() end
	PlayerRotation: enable()
end
function PriestShadow: disable()	
	PlayerRotation: disable()
	self.button_void_eruption: Hide()
	self.button_mindbender: Hide()
	if self.button_dark_void then self.button_dark_void: Hide() end
end 
function PriestShadow: nextSpell()
	if not(self.enabled) then 
		--self.button_void_eruption:Hide()
		--self.button_mindbender:Hide()
		return nil
	end
	
	local adds_coming = false	-- there's no way to predict if adds are coming
	local gcd = self.player:getGCD()
	local time_to_kill = self.player:timeToKill()
	local is_cleave = self.player:isCleave()
	local is_aoe = self.player:isAOE()
	
	local talent_shadow_word_void = (self.talent[1] == 3)
	local talent_misery = (self.talent[3] == 2)
	local talent_dark_void = (self.talent[3] == 3)
	local talent_mindbender = (self.talent[6] == 2)
	local talent_legacy_of_the_void = (self.talent[7] == 1)
	local insanity = self.player: getPower()
	
	if talent_misery then 
		self.player: setAOEThreshold(6)
	else
		self.player: setAOEThreshold(5)
	end
	
	local last_cast = self.player: getLastCast()
	local last_cast_time = self.player: getLastCastTime()
	if last_cast_time >= 2 * gcd then last_cast = 0 end
	if last_cast == 15407 then self.player:resetCleave(1) end		-- stop AOE rotation if mind flay is used
	
	local dot_refreshable_shadow_word_pain = self.player: isDotRefreshable(589, "target", 16)	--"Shadow Word: Pain"
	local dot_refreshable_vampiric_touch = self.player: isDotRefreshable(34914, "target", 21)	--"Vampiric Touch"
	local dot_refreshable_focus_shadow_word_pain = self.player: isDotRefreshable(589, "focus", 16)	--"Shadow Word: Pain"
	local dot_refreshable_focus_vampiric_touch = self.player: isDotRefreshable(34914, "focus", 21)	--"Vampiric Touch"
	
	local dot_remain_shadow_word_pain = self.player:getDotRemain(589)	--"Shadow Word: Pain"
	local dot_remain_vampiric_touch = self.player:getDotRemain(34914)	--"Vampiric Touch"
	local dot_remain_focus_shadow_word_pain = self.player:getDotRemain(589, "focus")	--"Shadow Word: Pain"
	local dot_remain_focus_vampiric_touch = self.player:getDotRemain(34914, "focus")	--"Vampiric Touch"
	local all_dots_up = dot_remain_shadow_word_pain > 3 and dot_remain_vampiric_touch > 3
	
	local cd_shadow_word_death = self.player:getCdRemain(32379)	--"Shadow Word: Death"
	local cd_dark_void = self.player:getCdRemain(263346)	--"Shadow Word: Death"
	local cd_void_bolt = self.player:getCdRemain(228266)	--"Void Bolt"
	
	local charge_shadow_word_death = self.player:getSpellCharge(32379)	--"Shadow Word: Death"
	local charge_shadow_word_void = self.player:getSpellCharge(205351)	--"Shadow Word: Void"
	
	local casting_void_eruption = self.player: isSpellCasting(228260)	--"Void Eruption"
	local casting_dark_void = self.player: isSpellCasting(263346)	--"Dark Void"
	local casting_dark_void_no_delay = self.player: isSpellCastingNoDelay(263346)	--"Dark Void"
	local casting_mind_blast_no_delay = self.player: isSpellCastingNoDelay(8092)	--"Mind Blast"
	local casting_shadow_word_void_no_delay = self.player: isSpellCastingNoDelay(205351)	--"Shadow Word: Void"
	charge_shadow_word_void = math.max(0, charge_shadow_word_void - ( casting_shadow_word_void_no_delay and 1 or 0 ))
	--if charge_shadow_word_void == 0 and casting_shadow_word_void_no_delay then charge_shadow_word_void = 1 end
	
	local buff_voidform = self.player:isBuffUp(194249) or casting_void_eruption	--"Voidform"
	local buff_stack_voidform = self.player:getBuffStack(194249)	--"Voidform"
	
	local next_spell_time = self.player: getNextSpellTime()
	buff_stack_voidform = buff_stack_voidform + math.floor(next_spell_time) * ( buff_stack_voidform and 1 or 0 )
	
	-- Estimating insanity by next available cast time
	-- from calibration, (this may correlate with character stats)
	-- insanity loss rate = 4.52 + 2 * 0.436 * t (buff_stack_voidform)
	-- integral | (t0, t0 + dt) = 4.52 * dt + 0.436 * ( (t0 + dt)^2 - t0^2 )
	insanity_loss = 4.52 * next_spell_time + 0.436 * ( (buff_stack_voidform + next_spell_time)^2 - buff_stack_voidform^2 )
	insanity_loss = insanity_loss * .925 	-- patch 8.1
	insanity = math.max(0, insanity - insanity_loss * (buff_voidform and 1 or 0))
	buff_voidform = buff_voidform and (insanity > 0)
	insanity = insanity + (casting_dark_void_no_delay and 30 or 0) + 
						  (casting_mind_blast_no_delay and 14 or 0) + 
						  (casting_shadow_word_void_no_delay and 14 or 0)
	
	-- self:setAction(spell, conditions, [optional]): 
	-- modifies self.next_spell if all conditions are met
	-- returns self.next_spell, or a nil value if spell is not usable or conditions are not met
	-- if a third parameter is defined, setAction() not make any change
	self.next_spell_trigger = true
	
	-- these major cds will be displayed as independent icons
	-- if spell usable - show icon; 
	-- if spell is the next rotation action - glow icon
	
	local void_eruption_action, dark_ascension_action, mindbender_action, dark_void_action	
	local void_eruption_usable, dark_ascension_usable, mindbender_usable, dark_void_usable
	--void_eruption_usable = self: setAction(228260, true, 1)	--"Void Eruption"
	void_eruption_usable = insanity >= (talent_legacy_of_the_void and 60 or 90)
	dark_ascension_usable = self: setAction(280711, true, 1)	--"Dark Ascension"
	mindbender_usable = self: setAction(200174, true, 1)	--"Mindbender"
	shadowfiend_usable = self: setAction(34433, true, 1)	--"Shadowfiend"
	dark_void_usable = self: setAction(263346, true, 1)	--"Dark Void"
	

	-------------------
	-- simc action list
	-- print(charge_shadow_word_void)
	if is_aoe then 
		-- simc: actions.aoe
		_, _, void_eruption_action = self: setAction(228260, {not(buff_voidform)}, 1)	--"Void Eruption"
		dark_ascension_action = self: setAction(280711, {not(buff_voidform), not(casting_void_eruption)}, 1 )	--"Dark Ascension"
		self: setAction(228266, {buff_voidform, dot_remain_shadow_word_pain > 1})	--"Void Bolt"
		dark_void_action = self: setAction(263346, not(buff_voidform), 1)	--"Dark Void"
		mindbender_action = self: setAction(200174, {time_to_kill > 10, buff_stack_voidform >= 8}, 1)	--"Mindbender"
		shadowfiend_action = self: setAction(34433, {time_to_kill > 10, buff_stack_voidform >= 8}, 1)	--"Shadowfiend"
		self: setAction(205385, not(adds_coming) )	--"Shadow Crash"
		self: setAction(48045)	--"Mind Sear"
		self: setAction(589)	--"Shadow Word: Pain"
	elseif is_cleave then 
		--simc: actions.cleave
		_, _, void_eruption_action = self: setAction(228260, {not(buff_voidform), all_dots_up}, 1 )	--"Void Eruption"
		dark_ascension_action = self: setAction(280711, {not(buff_voidform), not(casting_void_eruption), all_dots_up}, 1 )	--"Dark Ascension"
		self: setAction(228266, buff_voidform )	--"Void Bolt"
		if cd_void_bolt < 0.2 and buff_voidform then 
			self.next_spell_trigger = false
			self.next_spell = 228266
		end
		self: setAction(32379, time_to_kill < 3 or not(buff_voidform) )	--"Shadow Word: Death"
		dark_void_action = self: setAction(263346, not(buff_voidform), 1)	--"Dark Void"
		mindbender_action = self: setAction(200174, {time_to_kill > 10, buff_stack_voidform >= 10}, 1)	--"Mindbender"
		shadowfiend_action = self: setAction(34433, {time_to_kill > 10, buff_stack_voidform >= 10}, 1)	--"Shadowfiend"
		self: setAction(8092, not(talent_shadow_word_void))	--"Mind Blast"
		self: setActionShadowWordVoid({talent_shadow_word_void, charge_shadow_word_void == 2, buff_stack_voidform < 18})	--"Shadow Word: Void"
		self: setAction(205385, not(adds_coming) )	--"Shadow Crash"
		self: setAction(589, { dot_refreshable_shadow_word_pain, time_to_kill > 4, not(casting_dark_void), not(talent_misery), (cd_dark_void > 15) or not(talent_dark_void)} )
		local vt_conditions1 = dot_refreshable_vampiric_touch and ( time_to_kill > 6/2 )
		self: setAction(34914, vt_conditions1 )	--"Vampiric Touch"
		local vt_conditions2 = talent_misery and dot_refreshable_shadow_word_pain and ( time_to_kill > 4/2 )
		self: setAction(34914, vt_conditions2 )	--"Vampiric Touch"
		local vt_nocheck = (vt_conditions1 or vt_conditions2) and self.player:isSpellCasting(34914)
		self: setActionFocus(589, { dot_refreshable_focus_shadow_word_pain, time_to_kill > 4/2, not(casting_dark_void), not(talent_misery), (cd_dark_void > 15 + dot_remain_shadow_word_pain) or not(talent_dark_void)} ) -- , not(talent_dark_void)
		self: setActionFocus(34914, {dot_refreshable_focus_vampiric_touch, time_to_kill > 6/2}, vt_nocheck)	--"Vampiric Touch"
		self: setActionFocus(34914, {talent_misery, dot_refreshable_focus_shadow_word_pain, time_to_kill > 4/2}, vt_nocheck )	--"Vampiric Touch"
		self: setAction(205065)	--"Void Torrent"
		self: setActionShadowWordVoid({talent_shadow_word_void, charge_shadow_word_void > 0, buff_stack_voidform < 11})	--"Shadow Word: Void"
		self: setAction(48045)	--"Mind Sear"
		self: setAction(589)	--"Shadow Word: Pain"
	else
		-- simc: actions.single
		_, _, void_eruption_action = self: setAction(228260, {not(buff_voidform), all_dots_up, time_to_kill > 10}, 1 )	--"Void Eruption"
		dark_ascension_action = self: setAction(280711, {not(buff_voidform), not(casting_void_eruption), all_dots_up, time_to_kill > 10}, 1 )	--"Dark Ascension"
		self: setAction(228266, buff_voidform )	--"Void Bolt"
		if cd_void_bolt < 0.2 and buff_voidform then 
			self.next_spell_trigger = false
			self.next_spell = 228266
		end
		self: setAction(32379, time_to_kill < 3 or charge_shadow_word_death == 2 or ( charge_shadow_word_death == 1 and cd_shadow_word_death < gcd ))	--"Shadow Word: Death"
		dark_void_action = self: setAction(263346, {not(buff_voidform), time_to_kill > 4}, 1)	--"Dark Void"
		mindbender_action = self: setAction(200174, {time_to_kill > 10, buff_stack_voidform >= 10}, 1)	--"Mindbender"
		shadowfiend_action = self: setAction(34433, {time_to_kill > 10, buff_stack_voidform >= 10}, 1)	--"Shadowfiend"
		self: setAction(32379, not(buff_voidform) or ( charge_shadow_word_death == 2 and buff_stack_voidform < 15))	--"Shadow Word: Death"
		self: setAction(205385, not(adds_coming) )	--"Shadow Crash"
		self: setAction(8092, {not(talent_shadow_word_void), all_dots_up})	--"Mind Blast"
		self: setActionShadowWordVoid({talent_shadow_word_void, charge_shadow_word_void == 2, buff_stack_voidform < 18})	--"Shadow Word: Void"
		self: setAction(205065, {dot_remain_shadow_word_pain > 4, dot_remain_vampiric_touch > 4})	--"Void Torrent"
		self: setAction(589, { dot_refreshable_shadow_word_pain, time_to_kill > 4, not(casting_dark_void), not(talent_misery), (cd_dark_void > 15 + dot_remain_shadow_word_pain) or not(talent_dark_void)} ) --"Shadow Word: Pain" , not(talent_dark_void)
		local vt_conditons = (dot_refreshable_vampiric_touch and time_to_kill > 6 ) or 
							 (talent_misery and dot_refreshable_shadow_word_pain and time_to_kill > 4 )
		self: setAction(34914, vt_conditons )	--"Vampiric Touch"
		local vt_nocheck = vt_conditons and self.player:isSpellCasting(34914)
		self: setActionFocus(589, { dot_refreshable_focus_shadow_word_pain, time_to_kill > 4, not(casting_dark_void), not(talent_misery), (cd_dark_void > 6.5) or not(talent_dark_void)} ) --"Shadow Word: Pain" , not(talent_dark_void)
		self: setActionFocus(34914, (dot_refreshable_focus_vampiric_touch and time_to_kill > 6) or (talent_misery and dot_refreshable_focus_shadow_word_pain), vt_nocheck)	--"Vampiric Touch"
		self: setAction(8092, not(talent_shadow_word_void))	--"Mind Blast"
		self: setActionShadowWordVoid({talent_shadow_word_void, charge_shadow_word_void > 0, buff_stack_voidform < 11})	--"Shadow Word: Void"
		self: setAction(15407)	--"Mind Flay"
		self: setAction(589)	--"Shadow Word: Pain"
	end 
	
	----------------------
	-- display the results
	self:updateIcon()
	
	-- display secondary icons
	if not(void_eruption_usable) and not(dark_ascension_usable) then 
		self.button_void_eruption: Hide()
	end
	
	local glow = false
	if not(buff_voidform) then 
		if void_eruption_usable and void_eruption_action then 
			self.button_void_eruption: Show()
			self.button_void_eruption.icon: SetTexture(GetSpellTexture(228260))	--"Void Eruption"
			ActionButton_ShowOverlayGlow(self.button_void_eruption)
			glow = true
		elseif dark_ascension_usable and dark_ascension_action then
			self.button_void_eruption: Show()
			self.button_void_eruption.icon: SetTexture(GetSpellTexture(280711))	--"Dark Ascension"
			ActionButton_ShowOverlayGlow(self.button_void_eruption)
			glow = true
		elseif void_eruption_usable then 
			self.button_void_eruption: Show()
			self.button_void_eruption.icon: SetTexture(GetSpellTexture(228260))	--"Void Eruption"
			ActionButton_HideOverlayGlow(self.button_void_eruption)
		elseif dark_ascension_usable then 
			self.button_void_eruption: Show()
			self.button_void_eruption.icon: SetTexture(GetSpellTexture(280711))	--"Dark Ascension"
			ActionButton_HideOverlayGlow(self.button_void_eruption)
		else
			ActionButton_HideOverlayGlow(self.button_void_eruption)
			self.button_void_eruption: Hide()
		end
	else
		ActionButton_HideOverlayGlow(self.button_void_eruption)
		self.button_void_eruption: Hide()
	end
	--print(tostring(shadowfiend_action or mindbender_action).. " "..tostring(shadowfiend_usable or mindbender_usable))
	
	local dvStart, dvCd = GetSpellCooldown(263346)
	if dvCd > gcd then 
		self.cooldown_dark_void: SetCooldown(dvStart, dvCd)
	end	
	if dark_void_action then 
		if not(glow) then 
			ActionButton_ShowOverlayGlow(self.button_dark_void)
			glow = true
		end
	else
		if self.button_dark_void then ActionButton_HideOverlayGlow(self.button_dark_void) end
	end
	
	if shadowfiend_action or mindbender_action then
		self.button_mindbender: Show()
		if void_eruption_action or dark_ascension_action then 
			ActionButton_HideOverlayGlow(self.button_mindbender)
		else
			if not(glow) and talent_mindbender then
				ActionButton_ShowOverlayGlow(self.button_mindbender)
				glow = true
			end
		end
	elseif shadowfiend_usable or mindbender_usable then 
		self.button_mindbender: Show()
		ActionButton_HideOverlayGlow(self.button_mindbender)
	else
		ActionButton_HideOverlayGlow(self.button_mindbender)
		self.button_mindbender: Hide()
	end
	
	--print(self.player: getLastCast())
	--print(self.player: getLastCastTime())
	if DEBUG > 4 then
		print("SR: Priest Shadow module")
		print("SR: Enabled: ".. tostring(self.enabled))
		print("SR: Next spell: ".. tostring(self.next_spell))
		print("SR: Tagets hit: ".. tostring(self.player: getCleaveTargets()))
		print("SR: Cleave: ".. tostring(self.player: isCleave()))
		print("SR: AOE: ".. tostring(self.player: isAOE()))
		print(" ")
	end
	return self.next_spell
end

function PriestShadow: setActionShadowWordVoid(conditions)
	if not self.next_spell_trigger then return nil end
	
	local spell = 205351
	local all_conditions_met = false
	if type(conditions) == "nil" then
		all_conditions_met = true
	end
	if type(conditions) == "boolean" then
		all_conditions_met = conditions
	end
	if type(conditions) == "table" then
		all_conditions_met = true
		for i, v in ipairs(conditions) do 
			all_conditions_met = all_conditions_met and v
		end
	end
	if all_conditions_met then
		self.next_spell = spell
		self.next_spell_on_focus = false
		self.next_spell_trigger = false
	end
	return all_conditions_met
end

