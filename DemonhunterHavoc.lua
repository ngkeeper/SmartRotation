-- Only tested with talent 1313211
-- May also support talent 1/3, 2/2, 3/3, 7/2, 7/3
-- Does not support 5/3

DemonhunterHavoc = {}
DemonhunterHavoc.__index = DemonhunterHavoc

setmetatable(DemonhunterHavoc, {
  __index = PlayerRotation, -- inherit from the PlayerRotation class
  __call = function (class, ...)
    local self = setmetatable({}, class)
    self:_new(...)
    return self
  end,
})
function DemonhunterHavoc:_new()
	-- all spells are case-sensitive
	-- (this will be improved in the future)
	local gcd_spell 	= 	162243 		--"Demon's Bite"    -- can be any zero-cooldown spell
	local buff_spell 	= {	162264, 	--"Metamorphosis" 
							208628 		--"Momentum" }
						  }
    local dot_spell 	= {	206491 } 	--"Nemesis"
    local cd_spell 		= {	185123, 	--"Throw Glaive"
							258920, 	--"Immolation Aura"
							188499, 	--"Blade Dance"
							198013, 	--"Eye Beam"
							195072, 	--"Fel Rush"
							191427, 	--"Metamorphosis"
							179057, 	--"Chaos Nova"
							210152, 	--"Death Sweep"
							206491, 	--"Nemesis"
							258860, 	--"Dark Slash"
							258925, 	--"Fel Barrage"
							232893, 	--"Felblade"
							195072 		--"Fel Rush" }
						  }
    local casting_spell = {}
	local cleave_spell 	= {	258921, 	--"Immolation Aura"
							258922,		--"Immolation Aura"
							199552, 	--"Blade Dance"
							200685, 	--"Blade Dance"
							210153,		--"Death Sweep" 
							210155,		--"Death Sweep"
							192611, 	--"Fel Rush"
							275148,		--"Unbound Chaos"
							200166, 	--"Metamorphosis"
							179057 		--"Chaos Nova" 
						  }
	local cleave_targets = 3
	local aoe_targets = 3
	
	-- for i = 1, 40 do
        -- local ub_name, _, ub_stack, _, _, ub_expiration, _, _, _, ub_spell_id = UnitBuff("player", i)
        -- if ub_name then
            -- print(ub_name.." "..tostring(ub_spell_id))
        -- end    
    -- end
	
	PlayerRotation:_new(gcd_spell, buff_spell, dot_spell, cd_spell, casting_spell, cleave_spell, cleave_targets, aoe_targets)
	self.player: setTimeout(6)
	self.player: setPredictAll(true)
	--self.enabled = false
	-- the main icon is included in PlayerRotation class
	self.anchor_x = 0
	self.anchor_y = -200
	self.button: SetPoint("CENTER", self.anchor_x, self.anchor_y)
	self.hightlight_aoe = false
	
	-- create icons for major cd display
	self.button_meta = CreateFrame("Button", "SR_metaphorsis", UIParent, "ActionButtonTemplate")
	self.button_meta: Disable()
	self.button_meta: SetNormalTexture(self.button_meta: GetHighlightTexture())
	self.button_meta.icon: SetTexture(GetSpellTexture(191427))
	self.button_meta: Hide()
	
	self.cooldown_meta = CreateFrame("Cooldown", "SR_metaphorsis_cd", self.button_meta, "CooldownFrameTemplate")
	self.cooldown_meta: SetAllPoints(self.button_meta)
	self.cooldown_meta: SetDrawEdge(false)
	self.cooldown_meta: SetSwipeColor(1, 1, 1, .85)
	self.cooldown_meta:SetHideCountdownNumbers(false)
	
	self.overlay_meta = self.button_meta:CreateTexture("SR_icy_vein_overlay")
	self.overlay_meta:SetAllPoints(self.button_meta)
	self.overlay_meta:SetColorTexture(0, .5, 0, 0)
	
	self.button_nocd = CreateFrame("Button", "SR_secondary_button", UIParent, "ActionButtonTemplate")
	self.button_nocd: Disable()
	self.button_nocd: SetNormalTexture(self.button_nocd: GetHighlightTexture())
	self.button_nocd: Hide()
	
	self.overlay3 = self.button:CreateTexture("SR_secondary_button_overlay")
	self.overlay3:SetAllPoints(self.button_nocd)
	self.overlay3:SetColorTexture(.5, .5, 0, 0)
	
	self:setSize()
end
function DemonhunterHavoc: setSize(size)
	PlayerRotation:setSize(size)
	self.size = size or self.size
	self.ui_ratio = self.size / 50
	self.button_meta: SetSize(self.size * 0.75,self.size * 0.75)
	self.button_nocd: SetSize(self.size * 0.75,self.size * 0.75)
	self.button_meta: SetPoint("CENTER", self.anchor_x - 50 * self.ui_ratio, self.anchor_y)
	self.button_nocd: SetPoint("CENTER", self.anchor_x + 50 * self.ui_ratio, self.anchor_y)
end	
function DemonhunterHavoc: setPosition(x, y)
	PlayerRotation:setPosition(x, y)
	self.anchor_x = x or self.anchor_x
	self.anchor_y = y or self.anchor_y
	self:setSize()
end
function DemonhunterHavoc: enable()
	PlayerRotation: enable()
	self.button_meta: Show()
	self.button_nocd: Show()
end
function DemonhunterHavoc: disable()
	PlayerRotation: disable()
	self.button_meta: Hide()
	self.button_nocd: Hide()
end
function DemonhunterHavoc: nextSpell()
	-- for i = 1, 40 do
        -- local ub_name, _, ub_stack, _, _, ub_expiration, _, _, _, ub_spell_id = UnitBuff("player", i)
        -- if ub_name then
            -- print(ub_name.." "..tostring(ub_spell_id))
        -- end    
    -- end
	--print(self.player:isBuffUp(162264))
	if not(self.enabled) then 
		--self.button_meta:Hide()
		return nil
	end
		
	local adds_coming = false	-- there's no way to predict if adds are coming
	local gcd = self.player:getGCD()
	local time_to_kill = self.player:timeToKill()
	local is_cleave = self.player:isCleave() 
	local is_AOE = self.player:isAOE() 
	
	-- prepare for simc variables
	local talent_blind_fury = (self.talent[1] == 1)
	local talent_demon_blades = (self.talent[2] == 2)
	local talent_trail_of_ruin = (self.talent[3] == 1)
	local talent_first_blood = (self.talent[5] == 2)
	local talent_dark_slash = (self.talent[5] == 3)
	local talent_demonic = (self.talent[7] == 1)
	local talent_momentum = (self.talent[7] == 2)
	local talent_nemisis = (self.talent[7] == 3)
	
	if talent_trail_of_ruin then 
		self.player: setCleaveThreshold(2)
	else
		self.player: setCleaveThreshold(3)
	end
	
	local fury = self.player: getPower()
	local fury_deficit = self.player: getPowerMax() - self.player: getPower()
	
	local buff_metamorphosis = self.player:isBuffUp(162264) --"Metamorphosis"
	local buff_momentum = self.player:isBuffUp(208628) --"Momentum"
	
	local buff_remain_metamorphosis = self.player:getBuffRemain(162264) --"Metamorphosis"
	
	local debuff_nemesis = self.player:isDotUp(208628) --"Nemesis"
	
	local cd_metamorphosis = self.player:getCdRemain(191427) --"Metamorphosis"
	local cd_nemesis = self.player:getCdRemain(206491) --"Nemesis"
	local cd_eye_beam = self.player:getCdRemain(198013) --"Eye Beam"
	
	local ready_metamorphosis = self.player:isSpellReady(191427) --"Metamorphosis"
	local ready_nemesis = self.player:isSpellReady(206491) --"Nemesis"
	local ready_dark_slash = self.player:isSpellReady(258860) --"Dark Slash"
	local ready_eye_beam = self.player:isSpellReady(198013) --"Eye Beam"
	
	local charge_fel_rush = self.player:getSpellCharge(195072) --"Fel Rush"
	
	-------------------
	-- simc action list
	
	-- the following variables are from simc's profile
	local blade_dance = talent_first_blood or self.player:isCleave()
	local waiting_for_nemesis = not(not(talent_nemisis) or ready_nemesis or cd_nemesis > 60)
	local pooling_for_meta = not(talent_demonic) and cd_metamorphosis < 6 and fury_deficit > 30 and (not(waiting_for_nemesis) or cd_nemesis < 10)
	
	local fury_reduction = 0
	if talent_first_blood then fury_reduction = 20 end 
	local pooling_for_blade_dance = blade_dance and (fury < 75 - fury_reduction)
	
	local waiting_for_dark_slash = talent_dark_slash and not(pooling_for_blade_dance) and not(pooling_for_meta) and ready_dark_slash
	local waiting_for_momentum = talent_momentum and not(buff_momentum)
	
	
	
	-- self:setAction(spell, conditions, [optional]): 
	-- modifies self.next_spell if all conditions are met
	-- returns self.next_spell, or a nil value if spell is not usable or conditions are not met
	-- if a third parameter is defined, setAction() not make any change
	
	self.next_spell = 162243	-- use 'nil' will hide icon on cc/death/etc.
	self.next_spell_trigger = true
	
	-- simc: actions.cooldown
	local meta = self:setAction(191427, true, 1) -- checks if metamorphosis is usable
	local meta1 = self:setAction(191427, {not(buff_metamorphosis),not(talent_demonic or pooling_for_meta or waiting_for_nemesis), time_to_kill > 25}, 1)
	self:setAction(210152, {buff_metamorphosis, blade_dance}) -- "Death Sweep"
	local meta2 = self:setAction(191427, {talent_demonic, buff_metamorphosis, time_to_kill > 25}, 1) 
	self:setAction(206491, {is_cleave, not(debuff_nemesis)}) --"Nemesis"
	self:setAction(206491, not(is_cleave)) --"Nemesis"
	
	-- simc: actions.demonic
	self:setAction(258925, is_cleave) -- "Fel Barrage"
	self:setAction(210152, {buff_metamorphosis, blade_dance}) -- "Death Sweep"
	self:setAction(198013, is_cleave or not(adds_coming)) --"Eye Beam"
	self:setAction(188499, {blade_dance, cd_eye_beam > 5}) -- "Blade Dance", removed "not(ready_metamorphosis)" to for manual meta
	self:setAction(258920) -- "Immolation Aura"
	self:setAction(232893, fury < 40 or ( not(buff_metamorphosis) and fury_deficit >= 40 )) -- "Felblade"
	self:setAction(201427, {buff_metamorphosis, talent_blind_fury or fury_deficit < 30 or buff_remain_metamorphosis < 5, not(pooling_for_blade_dance)}) -- "Annihilation"
	self:setAction(162794, {talent_blind_fury or fury_deficit < 30, not(pooling_for_meta), not(pooling_for_blade_dance)}) -- "Chaos Strike"
	self:setAction(195072, {talent_demon_blades, not(ready_eye_beam), charge_fel_rush == 2}) -- "Fel Rush"
	--self:setAction(195072, {talent_demon_blades, not(ready_eye_beam), azerite.unbound_chaos.rank>0}) -- "Fel Rush"
	
	self:setAction(162243) -- "Demon's Bite"
	
	local main_spell = self.next_spell
	self.next_spell = 162243
	self.next_spell_trigger = true
	
	-- secondary icon, using no major cds
	self:setAction(210152, {buff_metamorphosis, blade_dance}) -- "Death Sweep"
	self:setAction(188499, {blade_dance}) -- "Blade Dance", removed "not(ready_metamorphosis)" to for manual meta
	self:setAction(232893, fury < 40 or ( not(buff_metamorphosis) and fury_deficit >= 40 )) -- "Felblade"
	self:setAction(201427, {buff_metamorphosis, talent_blind_fury or fury_deficit < 30 or buff_remain_metamorphosis < 5, not(pooling_for_blade_dance)}) -- "Annihilation"
	self:setAction(162794, {talent_blind_fury or fury_deficit < 30, not(pooling_for_blade_dance)}) -- "Chaos Strike"
	self:setAction(162243) -- "Demon's Bite"
	
	local secondary_spell = self.next_spell
	self.next_spell = main_spell
	
	----------------------
	-- display the results
	self:updateIcon()
	self:updateIcon(self.button_nocd, self.overlay3, secondary_spell)
	-- if meta then 
		-- self.button_meta:Show()
	-- else
		-- ActionButton_HideOverlayGlow(self.button_meta)
		-- self.button_meta:Hide()
	-- end
	if meta1 or meta2 then 
		ActionButton_ShowOverlayGlow(self.button_meta)
	else
		ActionButton_HideOverlayGlow(self.button_meta)
	end
	local meta_start, meta_cd = GetSpellCooldown(191427)
	if meta_cd > gcd then 
		self.cooldown_meta: SetCooldown(meta_start, meta_cd)
	end
	if buff_metamorphosis then 
		self.overlay_meta:SetColorTexture(0, .5, 0, 0.6)
	else
		self.overlay_meta:SetColorTexture(0, .5, 0, 0)
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


