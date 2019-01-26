DruidBalance = {}
DruidBalance.__index = DruidBalance

setmetatable(DruidBalance, {
  __index = PlayerRotation, -- inherit from the PlayerRotation class
  __call = function (class, ...)
    local self = setmetatable({}, class)
    self:_new(...)
    return self
  end,
})

function DruidBalance:_new()
	-- all spells are case-sensitive
	-- (this will be improved in the future)
	local gcd_spell 	= 	93402 		--"Sunfire"    -- can be any zero-cooldown spell
	local buff_spell 	= { 102560,		--"Incarnation"
							194223, 	--"Celestial Alignment"
							279709, 	--"Starlord"
							164545, 	--"Solar Empowerment"
							164547, 	--"Lunar Empowerment"
							202425, 	--"Warrior of Elune"
							24858, 		--"Moonkin Form"
							783, 		--"Travel Form"
							287790, 	--"Arcanic Pulsar"
						  }	
    local dot_spell 	= {	164815, 	--"Sunfire"
							164812, 	--"Moonfire"
							202347,		--"Stellar Flare"
						  }
    local cd_spell 		= {	202425, 	--"Warrior of Elune"
							102560, 	--"Incarnation"
							194223, 	--"Celestial Alignment"
							211545, 	--"Fury of Elune"
							205636,		--"Force of Nature"
							274281, 	--"New Moon"
							274282, 	--"Half Moon"
							274283,		--"Full Moon" 
						  }
    local casting_spell = {	202347, 	--"Stellar Flare"
							194153, 	--"Lunar Strike"
							190984, 	--"Solar Wrath" 	
							274281, 	--"New Moon"
							274282, 	--"Half Moon"
							274283,		--"Full Moon" 
						  }
	local cleave_spell 	= {	164812, 	--"Moonfire"
							194153, 	--"Lunar Strike"
							191037, 	--"Starfall"
							279729,		--"Solar Wrath"
							211545, 	--"Fury of Elune"
						  }
						  
	-- 78674 starsurge
	
	local cleave_targets = 2
	local aoe_targets = 4
	
	PlayerRotation:_new(gcd_spell, buff_spell, dot_spell, cd_spell, casting_spell, cleave_spell, cleave_targets, aoe_targets)
	
	self.player: setTimeout(4)
	self.player: setPredictAll(true) 
	--self.enabled = false
	
	self:createGraphics()
	
end
function DruidBalance: createGraphics()
	self.anchor_x = 0
	self.anchor_y = -135
	self.button: SetPoint("CENTER", self.anchor_x, self.anchor_y )
	self.hightlight_aoe = false

	-- the main icon is included in PlayerRotation class
	-- create icons for major cd display
	self.button_ca_inc = CreateFrame("Button", "SR_ca_inc", UIParent, "ActionButtonTemplate")
	self.button_ca_inc: Disable()
	self.button_ca_inc: SetNormalTexture(self.button_ca_inc: GetHighlightTexture())
	self.button_ca_inc.icon: SetTexture(GetSpellTexture(194223))
	if self.talent[5] == 3 then self.button_ca_inc.icon: SetTexture(GetSpellTexture(102560)) end
	
	self.cooldown_ca_inc = CreateFrame("Cooldown", "SR_ca_inc_cd", self.button_ca_inc, "CooldownFrameTemplate")
	self.cooldown_ca_inc: SetAllPoints(self.button_ca_inc)
	self.cooldown_ca_inc: SetDrawEdge(false)
	self.cooldown_ca_inc: SetSwipeColor(1, 1, 1, .85)
	self.cooldown_ca_inc:SetHideCountdownNumbers(false)
	
	self.overlay_ca_inc = self.button_ca_inc:CreateTexture("SR_ca_inc_overlay")
	self.overlay_ca_inc:SetAllPoints(self.button_ca_inc)
	self.overlay_ca_inc:SetColorTexture(.15, .5, 0, 0.7)
	
	self.button_cds = CreateFrame("Button", "SR_cds", UIParent, "ActionButtonTemplate")
	self.button_cds: Disable()
	self.button_cds: SetNormalTexture(self.button_cds: GetHighlightTexture())
	--self.button_cds.icon: SetTexture(GetSpellTexture(211545))
	self.button_cds: Hide()
	
	self.texture_cancel = self.button:CreateTexture("SR_texture_cancel", "Overlay")
	self.texture_cancel:SetTexture("Interface\\AddOns\\SmartRotation\\cancel-icon")
	self.texture_cancel:SetAllPoints(self.button)
	self.texture_cancel:SetVertexColor(1, 1, 1, 1)
	self.texture_cancel:Hide()
	
	self:setSize()
end
function DruidBalance: setSize(size)
	PlayerRotation:setSize(size)
	self.size = size or self.size
	self.ui_ratio = self.size / 50
	self.button_ca_inc: SetSize(self.size * 0.7, self.size * 0.7)
	self.button_cds: SetSize(self.size * 0.7, self.size * 0.7)
	self.button_ca_inc: SetPoint("CENTER", self.anchor_x - 50 * self.ui_ratio, self.anchor_y )
	self.button_cds: SetPoint("CENTER", self.anchor_x + 50 * self.ui_ratio, self.anchor_y )
end	
function DruidBalance: setPosition(x, y)
	PlayerRotation:setPosition(x, y)
	self.anchor_x = x or self.anchor_x
	self.anchor_y = y or self.anchor_y
	self:setSize()
end
function DruidBalance: enable()
	PlayerRotation: enable()
	self.button_ca_inc: Show()
	self.button_cds: Show()
end
function DruidBalance: disable()	
	PlayerRotation: disable()
	self.button_ca_inc: Hide()
	self.button_cds: Hide()
end 
function DruidBalance: updateStatus()
	local s = self.status

	s.gcd = self.player:getGCD()
	s.time_to_kill = self.player:timeToKill() 
	s.focus_time_to_kill = self.player:timeToKill("focus")
	s.is_cleave = self.player:isCleave()
	s.is_aoe = self.player:isAOE()
	s.targets_hit = math.max(1, self.player: getCleaveTargets())
	
	s.talent_natures_balance = (self.talent[1] == 1)
	s.talent_starlord = (self.talent[5] == 2)
	s.talent_incarnation = (self.talent[5] == 3)
	s.talent_stellar_drift = (self.talent[6] == 1)
	s.talent_twin_moons = (self.talent[6] == 2)
	s.talent_shooting_stars = (self.talent[7] == 1)
	
	s.astral_power = self.player: getPower()
	
	s.last_cast = self.player: getLastCast()
	s.last_cast_time = self.player: getLastCastTime()
	if s.last_cast_time >= 2 * s.gcd then s.last_cast = 0 end
	if s.last_cast == 78674 and not s.single_target_lock then 	-- stop AOE rotation if starsurge is used
		--self.player:resetCleave() 
		s.single_target_timer = GetTime() + 4
	end	
	s.single_target_timer = s.single_target_timer or GetTime()
	s.single_target_lock = ( GetTime() - s.single_target_timer ) < 0
	
	s.next_spell_time = self.player: getNextSpellTime() 
	
	s.casting_solar_wrath = self.player: isSpellCasting(190984)
	s.casting_lunar_strike = self.player: isSpellCasting(194153)
	s.casting_stellar_flare = self.player: isSpellCasting(202347)
	s.casting_new_moon = self.player: isSpellCasting(274281)
	s.casting_half_moon = self.player: isSpellCasting(274282)
	s.casting_full_moon = self.player: isSpellCasting(274283)

	-- ap_check, ref Hekili v8.1.0-09
	-- astral_power.current 
	-- - action.[spell].cost 
	-- + ( talent.shooting_stars.enabled and 4 or 0 ) 
	-- + ( talent.natures_balance.enabled and ceil( execute_time / 1.5 ) or 0 ) 
	-- < astral_power.max
	
	s.ap_predict = s.astral_power + ( s.talent_shooting_stars and 4 or 0) 
		+ ( s.talent_natures_balance and ceil( s.next_spell_time / 1.5 ) or 0 )
	s.ap_predict = s.ap_predict + ( s.casting_solar_wrath and 8 or 0 )
	s.ap_predict = s.ap_predict + ( s.casting_lunar_strike and 12 or 0 )
	s.ap_predict = s.ap_predict + ( s.casting_stellar_flare and 8 or 0 )
	s.ap_predict = s.ap_predict + ( s.casting_new_moon and 10 or 0 )
	s.ap_predict = s.ap_predict + ( s.casting_half_moon and 20 or 0 )
	s.ap_predict = s.ap_predict + ( s.casting_full_moon and 40 or 0 )
	s.ap_predict = min(s.ap_predict, 100)
	
	s.ap_deficit = 100 - s.ap_predict
	
	s.refreshable_sunfire = self.player: isDotRefreshable(164815, "target", 18)
	s.refreshable_moonfire = self.player: isDotRefreshable(164812, "target", 22)
	s.refreshable_stellar_flare = self.player: isDotRefreshable(202347, "target", 24)
	s.focus_refreshable_sunfire = self.player: isDotRefreshable(164815, "focus", 18)
	s.focus_refreshable_moonfire = self.player: isDotRefreshable(164812, "focus", 22)
	s.focus_refreshable_stellar_flare = self.player: isDotRefreshable(202347, "focus", 24)
	s.dot_moonfire = self.player: isDotUp(164812)
	
	s.buff_moonkin_form = self.player: isBuffUp(24858)
	s.buff_travel_form = self.player: isBuffUp(783)
	
	--s.buff_solar_empowerment = self.player: isBuffUp(164545)
	s.buff_stack_solar_empowerment = self.player: getBuffStack(164545) - ( s.casting_solar_wrath and 1 or 0 )
	s.buff_solar_empowerment = s.buff_stack_solar_empowerment > 0
	
	--s.buff_lunar_empowerment = self.player: isBuffUp(164547) 
	s.buff_stack_lunar_empowerment = self.player: getBuffStack(164547) - ( s.casting_lunar_strike and 1 or 0 )
	s.buff_lunar_empowerment = s.buff_stack_lunar_empowerment > 0
	
	s.buff_starlord = self.player: isBuffUp(279709)
	s.buff_remain_starlord = self.player: getBuffRemain(279709)
	s.buff_stack_starlord = self.player: getBuffStack(279709) or 0
	s.buff_stack_arcanic_pulsar = self.player: getBuffStack(287790) or 0
	
	s.buff_incarnation = self.player: isBuffUp(102560)
	s.buff_remain_incarnation = self.player: getBuffRemain(102560)
	s.buff_celestial_alignment = self.player: isBuffUp(194223)
	s.buff_remain_celestial_alignment = self.player: getBuffRemain(194223)
	s.buff_warrior_of_elune = self.player: isBuffUp(202425)
	
	s.ca_inc_up = s.buff_incarnation or s.buff_celestial_alignment
	s.ca_inc_remain = s.buff_remain_incarnation or s.buff_remain_celestial_alignment
	
	s.ca_inc_cd = s.ca_inc_cd or 0
	s.ca_inc_cd_start = s.ca_inc_cd_start or 0
	local cd_start, cd_total = GetSpellCooldown(102560)
	if cd_total > s.gcd then
		s.ca_inc_cd = cd_total
		s.ca_inc_cd_start = cd_start
	end
	local cd_start, cd_total = GetSpellCooldown(194223)
	if cd_total > s.gcd then
		s.ca_inc_cd = cd_total
		s.ca_inc_cd_start = cd_start
	end
	s.ca_inc_cd_remain = math.max(0, s.ca_inc_cd + s.ca_inc_cd_start - GetTime())
	
	s.az_ss = self:getAzeriteRank(122) or 0 	-- Azerite power: streaking stars
	s.az_ap = self:getAzeriteRank(200) or 0		-- Azerite power: arcanic pulsar
	--print(tostring(s.az_ss).." "..tostring(s.az_ap))
	
	s.sf_targets = 4
	if s.talent_twin_moons and s.talent_starlord then s.sf_targets = 5 end
	if s.talent_stellar_drift and not(s.talent_starlord) then s.sf_targets = 3 end
	
end
function DruidBalance: nextSpell()
	if not(self.enabled) then 
		--self.button_void_eruption:Hide()
		--self.button_mindbender:Hide()
		return nil
	end
	
	self:updateStatus()
	local s = self.status

	self.player: setAOEThreshold(s.sf_targets)
	
	-- self:setAction(spell, conditions, [optional]): 
	-- modifies self.next_spell if all conditions are met
	-- returns self.next_spell, or a nil value if spell is not usable or conditions are not met
	-- if a third parameter is defined, setAction() not make any change
	self.next_spell_trigger = true
	
	-- these major cds will be displayed as independent icons
	-- if spell usable - show icon; 
	-- if spell is the next rotation action - glow icon	

	-------------------
	-- simc action list
	-- print(charge_shadow_word_void)
	
	
	local woe_action, woe_usable = self: setAction(202425, s.time_to_kill > 6, 1)	-- "Warrior of Elune"
	local foe_action, foe_usable = self: setAction(211545, {s.ca_inc_up or s.ca_inc_cd_remain > 30, s.ap_deficit >= 8}, 1)	-- "Fury of Elune"
	
	local cancel_starlord = self: setAction(93402, {s.buff_starlord, s.buff_remain_starlord < 8, s.ap_deficit < 8})
	
	self: setAction(191037, {s.buff_stack_starlord < 3 or s.buff_remain_starlord >= 8, s.is_aoe, not s.single_target_lock})	--"Starfall"
	local _, _, condSS = self: setAction(78674, { s.talent_starlord and 
							 ( s.buff_stack_starlord < 3 or s.buff_remain_starlord >= 8 and s.buff_stack_arcanic_pulsar < 8) or 
							 not s.talent_starlord and ( s.buff_stack_arcanic_pulsar < 8 or s.ca_inc_up ) ,
							 s.single_target_lock or not s.is_aoe, s.buff_stack_lunar_empowerment + s.buff_stack_solar_empowerment < 4, 
							 s.buff_stack_solar_empowerment < 3, s.buff_stack_lunar_empowerment < 3,
							 s.az_ss == 0 or (not s.ca_inc_up) or s.last_cast ~= 78674 } )  --"Starsurge" 
	--print(condSS)
	
	self: setAction(78674, s.ap_deficit < 8) -- s.time_to_kill < s.gcd * ( s.astral_power % 40 ) "Starsurge" 
	
	self: setAction(164815, {s.refreshable_sunfire, s.time_to_kill * s.targets_hit > 6, s.ap_deficit >= 3, 
							 -- s.targets_hit > 1 + (( s.talent_twin_moons or s.dot_moonfire ) and 1 or 0), 
							 s.az_ss == 0 or (not s.ca_inc_up) or s.last_cast ~= 164815 }) -- “Sunfire"
	self: setActionFocus(164815, {s.focus_refreshable_sunfire, s.focus_time_to_kill * s.targets_hit > 6, s.ap_deficit >= 3, 
							 -- s.targets_hit > 1 + (( s.talent_twin_moons or s.dot_moonfire ) and 1 or 0), 
							 s.az_ss == 0 or (not s.ca_inc_up) or s.last_cast ~= 164815 }) -- “Sunfire"
	
	self: setAction(164812, {s.refreshable_moonfire, s.time_to_kill * s.targets_hit > 9, s.ap_deficit >= 3, 
							 s.az_ss == 0 or (not s.ca_inc_up) or s.last_cast ~= 164812 }) -- "Moonfire"
	self: setActionFocus(164812, {s.focus_refreshable_moonfire, s.focus_time_to_kill * s.targets_hit > 9, s.ap_deficit >= 3, 
							 s.az_ss == 0 or (not s.ca_inc_up) or s.last_cast ~= 164812 }) -- "Moonfire"
	
	local stellar_flare_conditions = s.refreshable_stellar_flare and 
									 s.time_to_kill * s.targets_hit > 9 and s.ap_deficit >= 8 and 
									 (s.az_ss == 0 or (not s.ca_inc_up) or (s.last_cast ~= 202347 and not s.casting_stellar_flare)) 
	self: setAction(202347, stellar_flare_conditions) -- "Stellar Flare"
	self: setActionFocus(202347, {s.focus_refreshable_stellar_flare,  
								  s.focus_time_to_kill * s.targets_hit > 9, s.ap_deficit >= 8,  
								  s.az_ss == 0 or (not s.ca_inc_up) or (s.last_cast ~= 202347 and not s.casting_stellar_flare)}, 
						 stellar_flare_conditions and s.casting_stellar_flare) -- "Stellar Flare"
	--self: setActionFocus(202347, stellar_flare_conditions, stellar_flare_conditions and s.casting_stellar_flare) -- "Stellar Flare"
	-- setActionFocus() will not register the event if the spell is already being cast 
	-- however, if player is casting stellar flare on 'target', SR should still prompt player to cast on 'focus'
	
	local not_casting_moon = not ( s.casting_new_moon or s.casting_half_moon or s.casting_full_moon )
	self: setAction(274281, {s.ap_deficit >= 10, not_casting_moon})	--"New Moon"
	self: setAction(274282, {s.ap_deficit >= 20, not_casting_moon})	--"Half Moon"
	self: setAction(274283, {s.ap_deficit >= 40, not_casting_moon})	--"Full Moon"
	self: setAction(194153, {s.buff_stack_solar_empowerment < 3, 
							 s.ap_deficit >= 12 or s.buff_stack_lunar_empowerment == 3, 
							 (s.buff_warrior_of_elune or s.buff_lunar_empowerment or s.is_cleave and not s.buff_solar_empowerment) and 
							 (s.az_ss == 0 or (not s.ca_inc_up) or 
							 (s.last_cast ~= 194153 and not s.casting_lunar_strike and (true or not(s.talent_incarnation)) or (s.last_cast == 190984 or s.casting_solar_wrath) and not s.casting_lunar_strike)) 
							 or s.az_ss > 0 and s.ca_inc_up and (s.last_cast == 190984 or s.casting_solar_wrath) and not s.casting_lunar_strike }
							 )	--"Lunar Strike"
	--actions+=/lunar_strike,if=buff.solar_empowerment.stack<3&(ap_check|buff.lunar_empowerment.stack=3)&((buff.warrior_of_elune.up|buff.lunar_empowerment.up|spell_targets>=2&!buff.solar_empowerment.up)&(!variable.az_ss|!buff.ca_inc.up|(!prev.lunar_strike&!talent.incarnation.enabled|prev.solar_wrath))|variable.az_ss&buff.ca_inc.up&prev.solar_wrath)
	self: setAction(190984, s.az_ss < 3 or not(s.ca_inc_up) or (s.last_cast ~= 190984 and not s.casting_solar_wrath) )	--"Solar Wrath"
	self: setAction(164815)
	
	if self.next_spell_trigger == true then 
		self.next_spell_trigger = false
		self.next_spell = 190984
	end
	
	----------------------
	-- display the results
	self:updateIcon()
	
	if cancel_starlord then 
		self:updateIcon(nil, nil, 279709)
		self.texture_cancel: Show()
	else
		self.texture_cancel: Hide()
	end
	
	local button_cd_glow = false
	
	if woe_usable then 
		self:updateIcon(self.button_cds, nil, 202425)
		if woe_action and self.next_spell == 194153 then button_cd_glow = true end
	else
		if foe_usable then 
			self:updateIcon(self.button_cds, nil, 211545)
			if foe_action then button_cd_glow = true end
		else 
			self.button_cds: Hide()
		end
	end
	
	if not s.buff_moonkin_form and not s.buff_travel_form and not IsMounted() then 
		self:updateIcon(self.button_cds, nil, 24858)
		button_cd_glow = true
	end
	
	if button_cd_glow then 
		ActionButton_ShowOverlayGlow(self.button_cds)
	else 
		ActionButton_HideOverlayGlow(self.button_cds)
	end
	
	if s.ca_inc_cd_remain > 0 then 
		self.cooldown_ca_inc:SetCooldown(s.ca_inc_cd_start, s.ca_inc_cd)
	end
	if s.ca_inc_up then self.overlay_ca_inc: Show() else self.overlay_ca_inc: Hide() end
	--self.overlay:SetColorTexture(1, 1, 1, 1)
	--self.overlay:SetTexture("Interface\\AddOns\\SmartRotation\\cancel-mark.tga")
	
	--print(self.player: getLastCast())
	--print(self.player: getLastCastTime())
	if DEBUG > 4 then
		print("SR: Balance Druid module")
		print("SR: Enabled: ".. tostring(self.enabled))
		print("SR: Next spell: ".. tostring(self.next_spell))
		print("SR: Tagets hit: ".. tostring(self.player: getCleaveTargets()))
		print("SR: Cleave: ".. tostring(self.player: isCleave()))
		print("SR: AOE: ".. tostring(self.player: isAOE()))
		print(" ")
	end
	return self.next_spell
end

