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
							8092, 		--"Mind Blast"
							205385, 	--"Shadow Crash"
							263346, 	--"Dark Void"
							32379, 		--"Shadow Word: Death"
							205065		--"Void Torrent"
						  }
    local casting_spell = {	228260, 	--"Void Eruption"
							8092, 		--"Mind Blast"
							34914, 		--"Vampiric Touch"
							15407, 		--"Mind Flay"
							48045 		--"Mind Sear" 
						  }
	local cleave_spell 	= {	49821, 		--"Mind Sear"
							263346, 	--"Dark Void"
							--228360, 	--"Void Eruption"
							--228361, 	--"Void Eruption"
							205386 		--"Shadow Crash"
						  }
	local cleave_targets = 2
	local aoe_targets = 6
	
	-- self:getSpellID(dot_spell)
	-- self:getSpellID(cd_spell)
	-- self:getSpellID(casting_spell)
	-- self:getSpellID(cleave_spell)
	
	PlayerRotation:_new(gcd_spell, buff_spell, dot_spell, cd_spell, casting_spell, cleave_spell, cleave_targets, aoe_targets)
	
	self.player: setCleaveTimeout(4.5, 4.5)
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
	self.button_mindbender.icon: SetTexture(GetSpellTexture(200174))
	self.button_mindbender:Hide()
	
	self.button_void_eruption = CreateFrame("Button", "SR_button_void_eruption", UIParent, "ActionButtonTemplate")
	self.button_void_eruption: Disable()
	self.button_void_eruption: SetNormalTexture(self.button_void_eruption: GetHighlightTexture())
	self.button_void_eruption.icon: SetTexture(GetSpellTexture(228260))
	self.button_void_eruption:Hide()
	
	self:setSize()
end
function PriestShadow: setSize(size)
	PlayerRotation:setSize(size)
	self.size = size or self.size
	self.ui_ratio = self.size / 50
	
	self.button_mindbender: SetSize(self.size * 0.65,self.size * 0.65)
	self.button_void_eruption: SetSize(self.size * 0.65,self.size * 0.65)
	self.button_mindbender: SetPoint("CENTER", self.anchor_x + 50 * self.ui_ratio, self.anchor_y )
	self.button_void_eruption: SetPoint("CENTER", self.anchor_x - 50 * self.ui_ratio, self.anchor_y )
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
	PlayerRotation: enable()
end
function PriestShadow: disable()	
	PlayerRotation: disable()
	self.button_void_eruption: Hide()
	self.button_mindbender: Hide()
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
	local talent_misery = (self.talent[3] == 2)
	local talent_dark_void = (self.talent[3] == 3)
	local talent_legacy_of_the_void = (self.talent[7] == 1)
	local insanity = self.player: getPower()
	
	if talent_misery then 
		self.player: setAOEThreshold(7)
	else
		self.player: setAOEThreshold(6)
	end
	
	
	
	local dot_refreshable_shadow_word_pain = self.player: isDotRefreshable(589)	--"Shadow Word: Pain"
	local dot_refreshable_vampiric_touch = self.player: isDotRefreshable(34914)	--"Vampiric Touch"
	local dot_refreshable_focus_shadow_word_pain = self.player: isDotRefreshable(589, "focus")	--"Shadow Word: Pain"
	local dot_refreshable_focus_vampiric_touch = self.player: isDotRefreshable(34914, "focus")	--"Vampiric Touch"
	
	local dot_remain_shadow_word_pain = self.player:getDotRemain(589)	--"Shadow Word: Pain"
	local dot_remain_vampiric_touch = self.player:getDotRemain(34914)	--"Vampiric Touch"
	local dot_remain_focus_shadow_word_pain = self.player:getDotRemain(589, "focus")	--"Shadow Word: Pain"
	local dot_remain_focus_vampiric_touch = self.player:getDotRemain(34914, "focus")	--"Vampiric Touch"
	local all_dots_up = self.player:isDotUp(589) and self.player:isDotUp(34914)
	
	local cd_shadow_word_death = self.player:getCdRemain(32379)	--"Shadow Word: Death"
	local cd_dark_void = self.player:getCdRemain(263346)	--"Shadow Word: Death"
	local cd_void_bolt = self.player:getCdRemain(228266)	--"Void Bolt"
	
	local charge_shadow_word_death = self.player:getSpellCharge(32379)	--"Shadow Word: Death"
	local casting_void_eruption = self.player: isSpellCasting(228260)	--"Void Eruption"
	local casting_dark_void = self.player: isSpellCasting(263346)	--"Dark Void"
	local casting_dark_void_no_delay = self.player: isSpellCastingNoDelay(263346)	--"Dark Void"
	local casting_mind_blast_no_delay = self.player: isSpellCastingNoDelay(8092)	--"Mind Blast"
	
	local buff_voidform = self.player:isBuffUp(194249) or casting_void_eruption	--"Voidform"
	local buff_stack_voidform = self.player:getBuffStack(194249)	--"Voidform"
	
	local next_spell_time = self.player: getNextSpellTime()
	
	-- Estimating insanity by next available cast time
	-- from calibration, (this may correlate with character stats)
	-- insanity loss rate = 4.52 + 2 * 0.436 * t (buff_stack_voidform)
	-- integral | (t0, t0 + dt) = 4.52 * dt + 0.436 * ( (t0 + dt)^2 - t0^2 )
	insanity_loss = 4.52 * next_spell_time + 0.436 * ( (buff_stack_voidform + next_spell_time)^2 - buff_stack_voidform^2 )
	insanity = math.max(0, insanity - insanity_loss)
	buff_voidform = buff_voidform and (insanity > 0)
	insanity = insanity + (casting_dark_void_no_delay and 30 or 0) + (casting_mind_blast_no_delay and 14 or 0)
	
	-- self:setAction(spell, conditions, [optional]): 
	-- modifies self.next_spell if all conditions are met
	-- returns self.next_spell, or a nil value if spell is not usable or conditions are not met
	-- if a third parameter is defined, setAction() not make any change
	self.next_spell_trigger = true
	
	-- these major cds will be displayed as independent icons
	-- if spell usable - show icon; 
	-- if spell is the next rotation action - glow icon
	
	local void_eruption_action, dark_ascension_action, mindbender_action 	
	local void_eruption_usable, dark_ascension_usable, mindbender_usable 	
	--void_eruption_usable = self: setAction(228260, true, 1)	--"Void Eruption"
	void_eruption_usable = insanity >= (talent_legacy_of_the_void and 60 or 90)
	dark_ascension_usable = self: setAction(280711, true, 1)	--"Dark Ascension"
	mindbender_usable = self: setAction(200174, true, 1)	--"Mindbender"
	
	-------------------
	-- simc action list
	
	if is_aoe then 
		-- simc: actions.aoe
		_, _, void_eruption_action = self: setAction(228260, {not(buff_voidform)}, 1)	--"Void Eruption"
		dark_ascension_action = self: setAction(280711, {not(buff_voidform), not(casting_void_eruption)}, 1 )	--"Dark Ascension"
		self: setAction(228266, {buff_voidform, dot_remain_shadow_word_pain > 1})	--"Void Bolt"
		self: setAction(263346, not(adds_coming) )	--"Dark Void"
		mindbender_action = self: setAction(200174, time_to_kill > 10, 1)	--"Mindbender"
		self: setAction(205385, not(adds_coming) )	--"Shadow Crash"
		self: setAction(48045)	--"Mind Sear"
		self: setAction(589)	--"Shadow Word: Pain"
	elseif is_cleave then 
		--simc: actions.cleave
		_, _, void_eruption_action = self: setAction(228260, {not(buff_voidform)}, 1 )	--"Void Eruption"
		dark_ascension_action = self: setAction(280711, {not(buff_voidform), not(casting_void_eruption)}, 1 )	--"Dark Ascension"
		self: setAction(228266, buff_voidform )	--"Void Bolt"
		if cd_void_bolt < 0.2 and buff_voidform then 
			self.next_spell_trigger = false
			self.next_spell = 228266
		end
		self: setAction(32379, time_to_kill < 3 or not(buff_voidform) )	--"Shadow Word: Death"
		self: setAction(263346, not(adds_coming) )	--"Dark Void"
		mindbender_action = self: setAction(200174, time_to_kill > 10, 1)	--"Mindbender"
		self: setAction(8092)	--"Mind Blast"
		self: setAction(205385, not(adds_coming) )	--"Shadow Crash"
		self: setAction(589, { dot_refreshable_shadow_word_pain, time_to_kill > 4, not(casting_dark_void), not(talent_misery), (cd_dark_void > 6.5) or not(talent_dark_void)} )
		local vt_conditions1 = dot_refreshable_vampiric_touch and ( time_to_kill > 6 )
		self: setAction(34914, vt_conditions1 )	--"Vampiric Touch"
		local vt_conditions2 = talent_misery and dot_refreshable_shadow_word_pain and ( time_to_kill > 4 )
		self: setAction(34914, vt_conditions2 )	--"Vampiric Touch"
		local vt_nocheck = (vt_conditions1 or vt_conditions2) and self.player:isSpellCasting(34914)
		self: setActionFocus(589, { dot_refreshable_focus_shadow_word_pain, time_to_kill > 4, not(casting_dark_void), not(talent_misery), (cd_dark_void > 6.5) or not(talent_dark_void)} ) -- , not(talent_dark_void)
		self: setActionFocus(34914, {dot_refreshable_focus_vampiric_touch, time_to_kill > 6}, vt_nocheck)	--"Vampiric Touch"
		self: setActionFocus(34914, {talent_misery, dot_refreshable_focus_shadow_word_pain, time_to_kill > 4}, vt_nocheck )	--"Vampiric Touch"
		self: setAction(205065)	--"Void Torrent"
		self: setAction(48045)	--"Mind Sear"
		self: setAction(589)	--"Shadow Word: Pain"
	else
		-- simc: actions.single
		_, _, void_eruption_action = self: setAction(228260, {not(buff_voidform), time_to_kill > 10}, 1 )	--"Void Eruption"
		dark_ascension_action = self: setAction(280711, {not(buff_voidform), not(casting_void_eruption),  time_to_kill > 10}, 1 )	--"Dark Ascension"
		self: setAction(228266, buff_voidform )	--"Void Bolt"
		if cd_void_bolt < 0.2 and buff_voidform then 
			self.next_spell_trigger = false
			self.next_spell = 228266
		end
		self: setAction(32379, time_to_kill < 3 or charge_shadow_word_death == 2 or ( charge_shadow_word_death == 1 and cd_shadow_word_death < gcd ))	--"Shadow Word: Death"
		self: setAction(263346, not(adds_coming) )	--"Dark Void"
		mindbender_action = self: setAction(200174, time_to_kill > 10, 1)	--"Mindbender"
		self: setAction(32379, not(buff_voidform) or ( charge_shadow_word_death == 2 and buff_stack_voidform < 15))	--"Shadow Word: Death"
		self: setAction(205385, not(adds_coming) )	--"Shadow Crash"
		self: setAction(8092, all_dots_up)	--"Mind Blast"
		self: setAction(205065, {dot_remain_shadow_word_pain > 4, dot_remain_vampiric_touch > 4})	--"Void Torrent"
		self: setAction(589, { dot_refreshable_shadow_word_pain, time_to_kill > 4, not(casting_dark_void), not(talent_misery), (cd_dark_void > 6.5) or not(talent_dark_void)} ) --"Shadow Word: Pain" , not(talent_dark_void)
		local vt_conditons = (dot_refreshable_vampiric_touch and time_to_kill > 6) or (talent_misery and dot_refreshable_shadow_word_pain)
		self: setAction(34914, vt_conditons )	--"Vampiric Touch"
		local vt_nocheck = vt_conditons and self.player:isSpellCasting(34914)
		self: setActionFocus(589, { dot_refreshable_focus_shadow_word_pain, time_to_kill > 4, not(casting_dark_void), not(talent_misery), (cd_dark_void > 6.5) or not(talent_dark_void)} ) --"Shadow Word: Pain" , not(talent_dark_void)
		self: setActionFocus(34914, (dot_refreshable_focus_vampiric_touch and time_to_kill > 6) or (talent_misery and dot_refreshable_focus_shadow_word_pain), vt_nocheck)	--"Vampiric Touch"
		self: setAction(8092)	--"Mind Blast"
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
	if not(buff_voidform) then 
		if void_eruption_usable and void_eruption_action then 
			self.button_void_eruption: Show()
			self.button_void_eruption.icon: SetTexture(GetSpellTexture(228260))	--"Void Eruption"
			ActionButton_ShowOverlayGlow(self.button_void_eruption)
		elseif dark_ascension_usable and dark_ascension_action then
			self.button_void_eruption: Show()
			self.button_void_eruption.icon: SetTexture(GetSpellTexture(280711))	--"Dark Ascension"
			ActionButton_ShowOverlayGlow(self.button_void_eruption)
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
	if mindbender_action then
		self.button_mindbender: Show()
		if void_eruption_action or dark_ascension_action then 
			ActionButton_HideOverlayGlow(self.button_mindbender)
		else
			ActionButton_ShowOverlayGlow(self.button_mindbender)
		end
	elseif mindbender_usable then 
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


