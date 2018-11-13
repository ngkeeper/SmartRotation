PaladinRetribution = {}
PaladinRetribution.__index = PaladinRetribution

setmetatable(PaladinRetribution, {
  __index = PlayerRotation, -- inherit from the PlayerRotation class
  __call = function (class, ...)
    local self = setmetatable({}, class)
    self:_new(...)
    return self
  end,
})
function PaladinRetribution:_new()
	-- all spells are case-sensitive
	-- (this will be improved in the future)
	local gcd_spell 	= 	85256 		--"Templar's Verdict"    -- can be any zero-cooldown spell
	local buff_spell 	= { 31884,		--"Avenging Wrath"
							84963,		--"Inquisition"
							231895, 	--"Crusade"
							223819	 	--"Divine Purpose"
						  }	
    local dot_spell 	= {	267798	 	--"Execution Sentence"
						  }
    local cd_spell 		= {	184662, 	--"Shield of Vengeance"
							31884, 		--"Avenging Wrath"
							231895, 	--"Crusade"
							84963, 		--"Inquisition"
							35395, 		--"Crusader Strike"
							184575, 	--"Blade of Justice"
							24275,		--"Hammer of Wrath"
							20271, 		--"Judgment"
							267798, 	--"Execution Sentence"
							205228, 	--"Consecration"
							255937		--"Wake of Ashes"
						  }
    local casting_spell = {	19750 		--"Flash of Light"
						  }
	local cleave_spell 	= {	224239, 	--"Divine Storm"
							255937,		--"Wake of Ashes"
							81297 		--"Consecration"
						  }
	local other_spell 	= { 84963, 		--"Inquisition"
							85256 		--"Templar's Verdict"
							
						  }
	local cleave_targets = 2
	local aoe_targets = 3
	PlayerRotation:_new(gcd_spell, buff_spell, dot_spell, cd_spell, casting_spell, cleave_spell, cleave_targets, aoe_targets)
	self.player:setPowerType(9) -- 9 is holy power
	--self.enabled = false
	
	-- the main icon is included in PlayerRotation class
	
	self.anchor_x = 0
	self.anchor_y = -200
	self.button: SetPoint("CENTER", self.anchor_x, self.anchor_y )
	self.hightlight_aoe = false
	
	self.button_cd1 = CreateFrame("Button", "SR_button_mindbender", UIParent, "ActionButtonTemplate")
	self.button_cd1: Disable()
	self.button_cd1: SetNormalTexture(self.button_cd1: GetHighlightTexture())
	self.button_cd1.icon: SetTexture(GetSpellTexture(184662))
	self.button_cd1:Hide()
	
	self.button_cd2 = CreateFrame("Button", "SR_button_void_eruption", UIParent, "ActionButtonTemplate")
	self.button_cd2: Disable()
	self.button_cd2: SetNormalTexture(self.button_cd2: GetHighlightTexture())
	self.button_cd2.icon: SetTexture(GetSpellTexture(31884))
	self.button_cd2:Hide()
	
	self.button_cd3 = CreateFrame("Button", "SR_button_void_eruption", UIParent, "ActionButtonTemplate")
	self.button_cd3: Disable()
	self.button_cd3: SetNormalTexture(self.button_cd3: GetHighlightTexture())
	self.button_cd3.icon: SetTexture(GetSpellTexture(255937))
	self.button_cd3:Hide()
	
	self:setSize()
end
function PaladinRetribution: setSize(size)
	PlayerRotation:setSize(size)
	self.size = size or self.size
	self.ui_ratio = self.size / 50
	self.button_cd1: SetSize(self.size * 0.65,self.size * 0.65)
	self.button_cd2: SetSize(self.size * 0.65,self.size * 0.65)
	self.button_cd3: SetSize(self.size * 0.65,self.size * 0.65)
	self.button_cd1: SetPoint("CENTER", self.anchor_x - 50 * self.ui_ratio, self.anchor_y)
	self.button_cd2: SetPoint("CENTER", self.anchor_x + 50 * self.ui_ratio, self.anchor_y)
	self.button_cd3: SetPoint("CENTER", self.anchor_x, self.anchor_y + 50 * self.ui_ratio)
end	
function PaladinRetribution: setPosition(x, y)
	PlayerRotation:setPosition(x, y)
	self.anchor_x = x or self.anchor_x
	self.anchor_y = y or self.anchor_y
	self:setSize()
end
function PaladinRetribution: enable()
	self.button_cd1: Show()
	self.button_cd2: Show()
	self.button_cd3: Show()
	PlayerRotation: enable()
end
function PaladinRetribution: disable()	
	self.button_cd1: Hide()
	self.button_cd2: Hide()
	self.button_cd3: Hide()
	PlayerRotation: disable()
end 
function PaladinRetribution: nextSpell()
	if not(self.enabled) then 
		return nil
	end
	local adds_coming = false	-- there's no way to predict if adds are coming
	local gcd = self.player:getGCD()
	local time_to_kill = self.player:timeToKill()
	local is_cleave = self.player:isCleave()
	local is_aoe = self.player:isAOE()
	local holy_power = self.player:getPower()
	
	local health_target = UnitHealth("target")
	local health_max_target = UnitHealthMax("target")
	local health_percentage_target = UnitHealth("target") / math.max(UnitHealthMax("target"), 1)
	
	local talent_righteous_verdict = (self.talent[1] == 2)
	local talent_execution_sentence = (self.talent[1] == 3)
	local talent_hammer_of_wrath = (self.talent[2] == 3)
	local talent_divine_judgement = (self.talent[4] == 1)
	local talent_crusade = (self.talent[7] == 2)
	local talent_inquisition = (self.talent[7] == 3)
	
	local buff_avenging_wrath = self.player:isBuffUp(31884)
	local buff_inquisition = self.player:isBuffUp(84963)
	local buff_crusade = self.player:isBuffUp(231895)
	local buff_divine_purpose = self.player:isBuffUp(223819)
	
	local buff_remain_inquisition = self.player:getBuffRemain(84963)
	local buff_stack_crusade = self.player:getBuffStack(231895)
		
	local charge_crusader_strike = self.player:getSpellCharge(35395)
	
	local cd_crusader_strike = self.player:getCdRemain(35395)
	local cd_judgement = self.player:getCdRemain(20271)
	local cd_concecration = self.player:getCdRemain(205228)
	local cd_avenging_wrath = self.player:getCdRemain(31884)
	local cd_execution_sentence = self.player:getCdRemain(267798)
	local cd_crusade = self.player:getCdRemain(231895)
	local cd_blade_of_justice = self.player:getCdRemain(184575)
	local cd_hammer_of_wrath = self.player:getCdRemain(24275)
	
	-- simc variables
	local HoW = not(talent_hammer_of_wrath) or (health_percentage_target >= 0.2 and (not(buff_avenging_wrath) or not(buff_crusade)))
	local ds_castable = is_aoe or (not(talent_righteous_verdict) and talent_divine_judgement and is_cleave)
	
	self.next_spell_trigger = true
	self.next_spell = nil
	
	local cd1 = self:setAction(184662, true, 1)
	local cd2, cd2_ready, cd2_conditions = self:setAction(31884, not(talent_inquisition) or buff_inquisition, 1)
	
	if holy_power >= 5 then 
		-- finisher end	
		self:setAction(84963, not(buff_inquisition) or 
				   ( buff_remain_inquisition < 5 and holy_power >= 3 ) or 
				   ( talent_execution_sentence and cd_execution_sentence < 10 and buff_remain_inquisition < 15 ) or 
				   ( cd_avenging_wrath < 15 and buff_remain_inquisition < 20 and holy_power >= 3 ) )
		self:setAction(267798, { not(is_aoe), not(talent_crusade) or cd_crusade > gcd * 2} )
		self:setAction(53385, { ds_castable, buff_divine_purpose} )
		self:setAction(53385, { ds_castable, not(talent_crusade) or cd_crusade > gcd * 2} )
		self:setAction(85256, { buff_divine_purpose, not(talent_execution_sentence) or cd_execution_sentence > gcd}) 
		self:setAction(85256, { not(talent_crusade) or cd_crusade > gcd * 2, 
					   not(talent_execution_sentence) or ( buff_crusade and buff_stack_crusade < 10) or cd_execution_sentence > gcd * 2 })
		-- finisher end	
	end
	local woa, woa_ready, woa_conditions = self:setAction(255937, { holy_power == 0 or (holy_power == 1 and cd_blade_of_justice > gcd), time_to_kill > 8 or is_aoe}, 1)
	--print(is_cleave)
	--print(tostring(woa1)..tostring(woa2))
	self:setAction(184575, holy_power <= 2 or ( holy_power == 3 and (cd_hammer_of_wrath > gcd * 2 or HoW)))
	self:setAction(20271, holy_power <= 2 or ( holy_power <= 4 and ( cd_blade_of_justice > gcd * 2 or HoW )) )
	self:setAction(24275, holy_power <= 4)
	self:setAction(205228, holy_power <= 2 or 
				   ( holy_power <= 3 and cd_blade_of_justice > gcd * 2 ) or 
				   ( holy_power == 4 and cd_blade_of_justice > gcd * 2 and cd_judgement > gcd * 2 ) )
	
	if talent_hammer_of_wrath and ( health_percentage_target < 0.2 or buff_avenging_wrath or buff_crusade ) and (buff_divine_purpose or buff_stack_crusade < 10) then 
		-- finisher start
		self:setAction(84963, not(buff_inquisition) or 
				   ( buff_remain_inquisition < 5 and holy_power >= 3 ) or 
				   ( talent_execution_sentence and cd_execution_sentence < 10 and buff_remain_inquisition < 15 ) or 
				   ( cd_avenging_wrath < 15 and buff_remain_inquisition < 20 and holy_power >= 3 ) )
		self:setAction(267798, { not(is_aoe), not(talent_crusade) or cd_crusade > gcd * 2} )
		self:setAction(53385, { ds_castable, not(talent_crusade) or cd_crusade > gcd * 2} )
		self:setAction(85256, { not(talent_crusade) or cd_crusade > gcd * 2, 
					   not(talent_execution_sentence) or ( buff_crusade and buff_stack_crusade < 10) or cd_execution_sentence > gcd * 2 })
		-- finisher end	
	end
	self:setAction(35395, { charge_crusader_strike >= 1 and cd_crusader_strike < 1.5, 
					holy_power <= 2 or 
					(holy_power <= 3 and cd_blade_of_justice > gcd * 2 ) or 
					(holy_power == 4 and cd_blade_of_justice > gcd * 2 and cd_judgement > gcd * 2 and cd_concecration > gcd * 2) })

	
	-- finisher start
	self:setAction(84963, not(buff_inquisition) or 
			   ( buff_remain_inquisition < 5 and holy_power >= 3 ) or 
			   ( talent_execution_sentence and cd_execution_sentence < 10 and buff_remain_inquisition < 15 ) or 
			   ( cd_avenging_wrath < 15 and buff_remain_inquisition < 20 and holy_power >= 3 ) )
	self:setAction(267798, { not(is_aoe), not(talent_crusade) or cd_crusade > gcd * 2} )
	self:setAction(53385, { ds_castable, not(talent_crusade) or cd_crusade > gcd * 2} )
	self:setAction(85256, { not(talent_crusade) or cd_crusade > gcd * 2, 
				   not(talent_execution_sentence) or ( buff_crusade and buff_stack_crusade < 10) or cd_execution_sentence > gcd * 2 })	
	-- finisher end			   
	self:setAction(35395, holy_power <= 4 )		

	
	self:updateIcon()
	if cd1 then 
		self.button_cd1: Show()
	else
		self.button_cd1: Hide()
	end
	if cd2_ready then 
		self.button_cd2: Show()
	else
		self.button_cd2: Hide()
	end
	
	if woa_ready then 
		self.button_cd3: Show()
		if woa_conditions then
			ActionButton_ShowOverlayGlow(self.button_cd3)
		else 
			ActionButton_HideOverlayGlow(self.button_cd3)
		end
	else
		ActionButton_HideOverlayGlow(self.button_cd3)
		self.button_cd3: Hide()
	end
	
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