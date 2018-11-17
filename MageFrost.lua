MageFrost = {}
MageFrost.__index = MageFrost

setmetatable(MageFrost, {
  __index = PlayerRotation, -- inherit from the PlayerRotation class
  __call = function (class, ...)
    local self = setmetatable({}, class)
    self:_new(...)
    return self
  end,
})
function MageFrost:_new()
	-- all mage spells (from wowhead)
	-- 84714	frozen orb
	-- 190356	blizzard????
	-- 153595	comet storm
	-- 157997	ice nova
	-- 44614	flurry
	-- 205021	ray of frost
	-- 257537	ebonbolt
	-- 199786	glacial spike
	-- 120		cone of cold
	-- 116		frostbolt
	-- 30455	ice lance
	-- 12472	icy veins
	-- 55342	mirror image
	-- 116011	rune of power
	
	-- spells may have different ids in combat log
	-- this affects "cleave_spell" and "buff_spell"
	
	local gcd_spell 	= 	30455 		--"Ice Lance"    -- can be any zero-cooldown spell
	local buff_spell 	= { 44544,		--"Fingers of Frost"
							190446,		--"Brain Freeze"
							205473,		--"Icicles"
							270232,		--"Freezing Rain"
							12472,		--"Icy Veins"
						  }	
    local dot_spell 	= {	228358 }	--"Winter's Chill"
    local cd_spell 		= {	84714, 		--"Frozen Orb"
							190356, 	--"Blizzard"
							153595, 	--"Comet Storm"
							157997, 	--"Ice Nova"
							205021, 	--"Ray of Frost"
							257537, 	--"Ebonbolt"
							120,		--"Cone of Cold"
							12472, 		--"Icy Veins"
							55342, 		--"Mirror Image"
							116011 		--"Rune of Power"
						  }
    local casting_spell = {	116, 		--"Frostbolt"
							257537, 	--"Ebonbolt"
							199786, 	--"Glacial Spike"
							190356, 	--"Blizzard"
							44614,		--"Flurry"
						  }
	local cleave_spell 	= {	--84721, 		--"Frozen Orb"
							--153596,		--"Comet Storm"
							190357,		--"Blizzard"
							--122, 		--"Frost Nova"
							228598, 	--"Ice Lance"
							228600, 	--"Glacial Spike"
							120,		--"Cone of Cold"
						  }
	local other_spell 	= {}
	
	local cleave_targets = 2
	local aoe_targets = 4
	PlayerRotation:_new(gcd_spell, buff_spell, dot_spell, cd_spell, casting_spell, cleave_spell, cleave_targets, aoe_targets)
	
	self.player: setCleaveTimeout(3, 3)
	self.player: setPredictAll(true) 
	self.pet_exists = false;
	self.on_flying_mount = false;
	
	--self.enabled = false
	
	-- the main icon is included in PlayerRotation class
	
	self.anchor_x = 0
	self.anchor_y = - 195
	self.button: SetPoint("CENTER", self.anchor_x, self.anchor_y )
	self.hightlight_aoe = false
	
	self.ui_ratio = self.size / 50
	self.button_cd1 = CreateFrame("Button", "SR_frozen_orb", UIParent, "ActionButtonTemplate")
	self.button_cd1: Disable()
	self.button_cd1: SetNormalTexture(self.button_cd1: GetHighlightTexture())
	self.button_cd1.icon: SetTexture(GetSpellTexture(84714))
	
	self.cooldown_cd1 = CreateFrame("Cooldown", "SR_frozen_orb_cd", self.button_cd1, "CooldownFrameTemplate")
	self.cooldown_cd1: SetAllPoints(self.button_cd1)
	self.cooldown_cd1: SetDrawEdge(false)
	self.cooldown_cd1: SetSwipeColor(1, 1, 1, .85)
	self.cooldown_cd1:SetHideCountdownNumbers(false)
	
	self.button_cd2 = CreateFrame("Button", "SR_comet_storm", UIParent, "ActionButtonTemplate")
	self.button_cd2: Disable()
	self.button_cd2: SetNormalTexture(self.button_cd2: GetHighlightTexture())
	self.button_cd2.icon: SetTexture(GetSpellTexture(153595))
	
	self.cooldown_cd2 = CreateFrame("Cooldown", "SR_comet_storm_cd", self.button_cd2, "CooldownFrameTemplate")
	self.cooldown_cd2: SetAllPoints(self.button_cd2)
	self.cooldown_cd2: SetDrawEdge(false)
	self.cooldown_cd2: SetSwipeColor(1, 1, 1, .85)
	self.cooldown_cd2:SetHideCountdownNumbers(false)
	
	self.button_cd3 = CreateFrame("Button", "SR_icy_vein", UIParent, "ActionButtonTemplate")
	self.button_cd3: Disable()
	self.button_cd3: SetNormalTexture(self.button_cd3: GetHighlightTexture())
	self.button_cd3.icon: SetTexture(GetSpellTexture(12472))
	
	self.cooldown_cd3 = CreateFrame("Cooldown", "SR_icy_vein_cd", self.button_cd3, "CooldownFrameTemplate")
	self.cooldown_cd3: SetAllPoints(self.button_cd3)
	self.cooldown_cd3: SetDrawEdge(false)
	self.cooldown_cd3: SetSwipeColor(1, 1, 1, .85)
	self.cooldown_cd3:SetHideCountdownNumbers(false)
	
	self.overlay_cd3 = self.button_cd3:CreateTexture("SR_icy_vein_overlay")
	self.overlay_cd3:SetAllPoints(self.button_cd3)
	self.overlay_cd3:SetColorTexture(0, .5, 0, 0)
	
	self.button_cd4 = CreateFrame("Button", "SR_blizzard", UIParent, "ActionButtonTemplate")
	self.button_cd4: Disable()
	self.button_cd4: SetNormalTexture(self.button_cd3: GetHighlightTexture())
	self.button_cd4.icon: SetTexture(GetSpellTexture(190356))
	
	self.cooldown_cd4 = CreateFrame("Cooldown", "SR_blizzard_cd", self.button_cd4, "CooldownFrameTemplate")
	self.cooldown_cd4: SetAllPoints(self.button_cd4)
	self.cooldown_cd4: SetDrawEdge(false)
	self.cooldown_cd4: SetSwipeColor(1, 1, 1, .85)
	self.cooldown_cd4:SetHideCountdownNumbers(false)
	
	self:setSize(60)
end
function MageFrost: setSize(size)
	PlayerRotation:setSize(size)
	self.size = size or self.size
	self.ui_ratio = self.size / 50
	
	self.button_cd1: SetSize(self.size * 0.65,self.size * 0.65)
	self.button_cd2: SetSize(self.size * 0.65, self.size * 0.65)
	self.button_cd3: SetSize(self.size * 0.65, self.size * 0.65)
	self.button_cd4: SetSize(self.size * 0.65, self.size * 0.65)
	self.button_cd1: SetPoint("CENTER", self.anchor_x - 25 * self.ui_ratio, self.anchor_y + 50 * self.ui_ratio)
	self.button_cd2: SetPoint("CENTER", self.anchor_x + 25 * self.ui_ratio, self.anchor_y + 50 * self.ui_ratio)
	self.button_cd3: SetPoint("CENTER", self.anchor_x - 50 * self.ui_ratio, self.anchor_y )
	self.button_cd4: SetPoint("CENTER", self.anchor_x + 50 * self.ui_ratio, self.anchor_y )
	
	local talent_comet_storm = (self.talent[6] == 3)
	if not talent_comet_storm then 
		self.button_cd1: SetPoint("CENTER", self.anchor_x, self.anchor_y + 50 * self.ui_ratio)
	end
end	
function MageFrost: setPosition(x, y)
	PlayerRotation:setPosition(x, y)
	self.anchor_x = x or self.anchor_x
	self.anchor_y = y or self.anchor_y
	self:setSize()
end
function MageFrost: enable()
	PlayerRotation: enable()
	self.button_cd1: Show()
	self.button_cd2: Show()
	self.button_cd3: Show()
	self.button_cd4: Show()
end
function MageFrost: disable()	
	PlayerRotation: disable()
	self.button_cd1: Hide()
	self.button_cd2: Hide()
	self.button_cd3: Hide()
	self.button_cd4: Hide()
end 
function MageFrost: nextSpell()
	if not(self.enabled) then 
		return nil
	end
	
	
	self.on_flying_mount = IsFlying() or self.on_flying_mount and IsMounted()
	self.pet_exists = UnitExists("pet") and not(self.on_flying_mount) or self.pet_exists and self.on_flying_mount
	
	local adds_coming = false	-- there's no way to predict if adds are coming
	local gcd = self.player:getGCD()
	local time_to_kill = self.player:timeToKill()
	local is_cleave = self.player:isCleave()
	local is_aoe = self.player:isAOE()

	local _, target_distance = self:getRange("target")
	target_distance = target_distance or -1
	
	local last_cast = self.player: getLastCast()
	local last_cast_time = self.player: getLastCastTime()
	if last_cast_time >= 2 * gcd then last_cast = 0 end
	
	local health_target = UnitHealth("target")
	local health_max_target = UnitHealthMax("target")
	local health_percentage_target = UnitHealth("target") / math.max(UnitHealthMax("target"), 1)
	
	local talent_lonely_winter = (self.talent[1] == 2)
	local talent_rune_of_power = (self.talent[3] == 3)
	local talent_ebonbolt = (self.talent[4] == 3)
	local talent_freezing_rain = (self.talent[6] == 1)
	local talent_splitting_ice = (self.talent[6] == 2)
	local talent_comet_storm = (self.talent[6] == 3)
	local talent_glacial_spike = (self.talent[7] == 3)
	
	if talent_freezing_rain then 
		self.player: setAOEThreshold(5)
	else
		self.player: setAOEThreshold(4)
	end
	
	local casting_ebonbolt = self.player:isSpellCasting(257537)
	local casting_glacial_spike = self.player:isSpellCasting(199786)
	local casting_frostbolt = self.player:isSpellCasting(116)
	local casting_blizzard = self.player:isSpellCasting(190356)
	local casting_flurry = self.player:isSpellCasting(44614)
	
	
	local buff_stack_icicles = self.player:getBuffStack(205473)
	local buff_brain_freeze = self.player:isBuffUp(190446) or casting_ebonbolt
	local buff_fingers_of_frost = self.player:isBuffUp(44544)
	local buff_freezing_rain = self.player:isBuffUp(270232)
	local buff_stack_fingers_of_frost = self.player:getBuffStack(44544)
	local buff_icy_veins = self.player:isBuffUp(12472)
	local debuff_winters_chill = self.player:isDotUp(228358) 
	
	if casting_frostbolt then buff_stack_icicles = buff_stack_icicles + 1 end
	
	self.next_spell_trigger = true
	self.next_spell = nil
	
	-- simc rotation
	
	--actions+=/ice_lance,if=prev_gcd.1.flurry&brain_freeze_active&!buff.fingers_of_frost.react
	self:setAction(30455, { last_cast == 44614 or casting_flurry, not(buff_fingers_of_frost)}) --simc requires "buff_brain_freeze", very weird
	local iv_action, iv_usable = self:setAction(12472, time_to_kill > 30, 1)
	self:setAction(55342)
	self:setAction(116011, last_cast == 84714)
	
	local fo_usable, cs_usable, fo_action, cs_action, blz_usable, blz_action
	cs_usable = self:setAction(153595, true, 1)
	fo_usable = self:setAction(84714, true, 1)
	blz_usable = self:setAction(190356, true, 1)
	
	local gs_ready = ( buff_stack_icicles >= 5 )
	local gs_condition
	if is_aoe then 
		fo_action = self:setAction(84714, time_to_kill > 10, 1)	-- frozen orb
		blz_action = self:setAction(190356, true, 1)	-- blizzard
		cs_action = self:setAction(153595, {not fo_action, not casting_blizzard, time_to_kill > 10}, 1)	-- comet storm
		self:setAction(157997)	-- ice nova
		self:setAction(44614, (casting_ebonbolt or last_cast == 257537) or 
			( buff_brain_freeze and ( (casting_glacial_spike or last_cast == 199786) or 
			( ( casting_frostbolt or last_cast == 116 ) and (buff_stack_icicles < 4 or not(talent_glacial_spike))) )))	-- flurry
		self:setAction(30455, buff_fingers_of_frost)	-- ice lance
		self:setAction(205021) 	-- ray of frost
		self:setAction(257537, time_to_kill > 10) 	-- ebonbolt
		_, _, gs_condition = self:setAction(199786, buff_brain_freeze or (casting_ebonbolt or last_cast == 257537)
			or (is_cleave and talent_splitting_ice), 1 )	-- glacial spike
		-- if casting frostbolt and have 4 icicles, glacial spike will be ready as the next spell
		if gs_condition and gs_ready then 
			self.next_spell = 199786
			self.next_spell_trigger = false
		end
		self:setAction(120, {target_distance <= 12, target_distance >= 0})	-- cone of cold
		self:setAction(116)		-- frost bolt
	else
		self:setAction(157997, debuff_winters_chill) -- ice nova
		self:setAction(44614, {not(talent_glacial_spike), (casting_ebonbolt or last_cast == 257537)
			or (last_cast == 116 and buff_brain_freeze) })	-- flurry
		self:setAction(44614, {talent_glacial_spike, buff_brain_freeze, 
			(casting_glacial_spike or last_cast == 199786) or 
			( (casting_ebonbolt or last_cast == 257537) and buff_stack_icicles < 4 ) or 
			(last_cast == 116 and buff_stack_icicles < 4) })	-- flurry
		fo_action = self:setAction(84714, time_to_kill > 15, 1)	-- frozen orb
		self:setAction(190356, {is_cleave, buff_freezing_rain, buff_stack_fingers_of_frost < 2})	-- blizzard
		self:setAction(30455, buff_fingers_of_frost)	-- ice lance
		cs_action = self:setAction(153595, {not fo_action, time_to_kill > 15}, 1)	-- comet storm
		self:setAction(257537, {( not(talent_glacial_spike) or (buff_stack_icicles == 5) ),not(buff_brain_freeze), time_to_kill > 10} )	-- ebonbolt
		self:setAction(205021, {not(buff_fingers_of_frost), last_cast ~= 84714})	-- ray of frost
		self:setAction(190356, {is_cleave, buff_freezing_rain})	-- blizzard
		_, _, gs_condition = self:setAction(199786, buff_brain_freeze or (casting_ebonbolt or last_cast == 257537)
			or (is_cleave and talent_splitting_ice), 1 )	-- glacial spike
		-- if casting frostbolt and have 4 icicles, glacial spike will be ready as the next spell
		if gs_condition and gs_ready then 
			self.next_spell = 199786
			self.next_spell_trigger = false
		end
		self:setAction(157997)	-- ice nova
		self:setAction(44614, {not(buff_brain_freeze), false})	-- flurry, false = buff.winters_reach.react
		self:setAction(116)		-- frost bolt
	end
	if self.next_spell_trigger then self.next_spell = 116 end
	
	
	self:updateIcon()
	
	-- if fo_usable then 
		-- self.button_cd1: Show()
		-- if fo_action then 
			-- ActionButton_ShowOverlayGlow(self.button_cd1)
		-- else
			-- ActionButton_HideOverlayGlow(self.button_cd1)
		-- end
	-- else
		-- self.button_cd1: Hide()
	-- end
	-- if cs_usable then 
		-- self.button_cd2: Show()
		-- if cs_action then 
			-- ActionButton_ShowOverlayGlow(self.button_cd2)
		-- else
			-- ActionButton_HideOverlayGlow(self.button_cd2)
		-- end
	-- else
		-- self.button_cd2: Hide()
	-- end
	local hide_pet_icon = self.pet_exists or talent_lonely_winter
	if hide_pet_icon then
		self.button_cd3.icon: SetTexture(GetSpellTexture(12472))
		ActionButton_HideOverlayGlow(self.button_cd3)
	else 
		self.button_cd3.icon: SetTexture(GetSpellTexture(31687))
		if IsUsableSpell(31687) then 
			ActionButton_ShowOverlayGlow(self.button_cd3)
		end
	end
	if fo_action then 
		ActionButton_ShowOverlayGlow(self.button_cd1)
	else
		ActionButton_HideOverlayGlow(self.button_cd1)
	end
	if talent_comet_storm then 
		self.button_cd2: Show()
		if cs_action then 
			ActionButton_ShowOverlayGlow(self.button_cd2)
		else
			ActionButton_HideOverlayGlow(self.button_cd2)
		end
	else 
		self.button_cd2: Hide()
	end
	-- if iv_action then 
		-- ActionButton_ShowOverlayGlow(self.button_cd3)
	-- else
		-- ActionButton_HideOverlayGlow(self.button_cd3)
	-- end
	if blz_action then 
		ActionButton_ShowOverlayGlow(self.button_cd4)
	else
		ActionButton_HideOverlayGlow(self.button_cd4)
	end
	
	
	local foStart, foCd = GetSpellCooldown(84714)
	if foCd > gcd then 
		self.cooldown_cd1: SetCooldown(foStart, foCd)
	end
	local csStart, csCd = GetSpellCooldown(153595)
	if csCd > gcd then 
		self.cooldown_cd2: SetCooldown(csStart, csCd)
	end
	local ivStart, ivCd = GetSpellCooldown(12472)
	if ivCd > gcd then 
		self.cooldown_cd3: SetCooldown(ivStart, ivCd)
	end
	local blzStart, blzCd = GetSpellCooldown(190356)
	if blzCd > gcd then 
		self.cooldown_cd4: SetCooldown(blzStart, blzCd)
	end
	
	if buff_icy_veins then 
		self.overlay_cd3:SetColorTexture(0, .5, 0, 0.6)
	else
		self.overlay_cd3:SetColorTexture(0, .5, 0, 0)
	end
	if DEBUG > 4 then
		print("SR: Mage frost module")
		print("SR: Enabled: ".. tostring(self.enabled))
		print("SR: Next spell: ".. tostring(self.next_spell))
		print("SR: Tagets hit: ".. tostring(self.player: getCleaveTargets()))
		print("SR: Cleave: ".. tostring(self.player: isCleave()))
		print("SR: AOE: ".. tostring(self.player: isAOE()))
		print(" ")
	end
	return self.next_spell
end