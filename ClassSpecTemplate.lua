ClassSpec = {}
ClassSpec.__index = ClassSpec

setmetatable(ClassSpec, {
  __index = PlayerRotation, -- inherit from the PlayerRotation class
  __call = function (class, ...)
    local self = setmetatable({}, class)
    self:_new(...)
    return self
  end,
})
function ClassSpec:_new()
	-- gcd, casting, cd spell ids can be found from Wowhead
	-- or use the following command in game: 
	-- /run print(select(7, GetSpellInfo("[spell]")))
	
	-- buff and debuffs may have different spell ids than original spells
	-- cleave spells almost always show up in different spell ids in the combat log
	-- use the commented COMBAT_LOG_EVENT sections in the main program to find these spell ids
	
	local gcd_spell 	= 	 	-- can be any zero-cooldown spell
	local buff_spell 	= { }	-- buffs (if need to be tracked)
	local dot_spell 	= {	}	-- debuffs or dot spells
	local cd_spell 		= {	}	-- spells with cd (if you want to know if that spell is on cd)
	local casting_spell = {	}	-- non-instant spells (if you want to do something if that spell is being cast)
	local cleave_spell 	= { }	-- spells that have aoe/cleave effects, to determine how many targets are hit
								-- do not list spells with high damage frequency, e.g. eye beam, comet storm, void eruptions
	local other_spell 	= { }	-- reserved
	
	local cleave_targets = 2	-- threshold for "cleave" status
	local aoe_targets = 4		-- threshold for "aoe" status
	local single_target_dps = 8000	-- used for time-to-kill estimation, low time-to-kill will stall using major cooldown
	
	PlayerRotation:_new(gcd_spell, buff_spell, dot_spell, cd_spell, casting_spell, cleave_spell, cleave_targets, aoe_targets, single_target_dps)
	
	self.player: setCleaveTimeout(3, 3)	-- how fast (cleave, aoe) status dies out. 
										-- E.g. 3 seconds after last cleave hit, single target sequence is executed
	
	-- a main icon is included in PlayerRotation class
	
	self.anchor_x = 0			-- coordinates of the main icon
	self.anchor_y = - 195
	self.button: SetPoint("CENTER", self.anchor_x, self.anchor_y )
	self.hightlight_aoe = false
	
	self.ui_ratio = self.size / 50
	
	-- create custom icons and ui widgets here
	-- self.button is reserved for the main icon. use other names here
	self.button1 = CreateFrame("Button", "SR_icy_vein", UIParent, "ActionButtonTemplate")
	self.button1: Disable()
	self.button1: SetNormalTexture(self.button_cd3: GetHighlightTexture())
	self.button1.icon: SetTexture(GetSpellTexture(12472))
	
	self.cooldown = CreateFrame("Cooldown", "SR_icy_vein_cd", self.button_cd3, "CooldownFrameTemplate")
	self.cooldown: SetAllPoints(self.button_cd3)
	self.cooldown: SetDrawEdge(false)
	self.cooldown: SetSwipeColor(1, 1, 1, .85)
	
	self.overlay = self.button_cd3:CreateTexture("SR_icy_vein_overlay")
	self.overlay:SetAllPoints(self.button_cd3)
	self.overlay:SetColorTexture(0, .5, 0, 0)

	self:setSize(60)
end

function ClassSpec: setSize(size)	-- overrides the inherited setSize()
	PlayerRotation:setSize(size)
	self.size = size or self.size
	self.ui_ratio = self.size / 50
	self.button1: SetSize(self.size * 0.75, self.size * 0.75)
	self.button1: SetPoint("CENTER", self.anchor_x - 25 * self.ui_ratio, self.anchor_y + 50 * self.ui_ratio)
	-- no need to set size and position for overlays
end	
function ClassSpec: setPosition(x, y)	-- overrides the inherited setPosition()
	PlayerRotation:setPosition(x, y)
	self.anchor_x = x or self.anchor_x
	self.anchor_y = y or self.anchor_y
	self:setSize()
end
function ClassSpec: enable()	-- overrides the inherited enable()
	PlayerRotation: enable()
	self.button1: Show()	-- overlays will show with parent buttons
end
function ClassSpec: disable() 	-- overrides the inherited disable()
	PlayerRotation: disable()
	self.button1: Hide()	-- overlays will hide with parent buttons
end 
function ClassSpec: nextSpell()
	-- this is the major function to implement
	-- this function is called on 20 times per second in the main program
	-- update the player status, and predict the best spell
	-- then update the icons
	
	if not(self.enabled) then 
		return nil
	end
	
	-- these are common variables for most classes
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
	
	-- get talent choices
	local talent_freezing_rain = (self.talent[6] == 1)
	
	-- some talent may affect aoe/cleave threshold
	-- once it's set, it stays there 
	-- maybe this part can be part of the constructor
	if talent_freezing_rain then 
		self.player: setAOEThreshold(4)
	else
		self.player: setAOEThreshold(3)
	end
	
	-- get if a spell is being cast
	local casting_ebonbolt = self.player:isSpellCasting(257537)
	
	-- get buffs, debuffs, and stacks
	-- in this case, ebonbolt provides brain freeze
	-- then i can predict the buff if ebonbolt is being cast
	-- this reduces 'suprise' to the player
	local buff_stack_icicles = self.player:getBuffStack(205473)
	local buff_brain_freeze = self.player:isBuffUp(190446) or casting_ebonbolt
	local debuff_winters_chill = self.player:isDotUp(228358) 
	
	----------------------------------
	-- the action sequence begins here
	----------------------------------
	
	-- use self:setAction(spellid, {condition1, condition2, ...}) to set an action
	-- (1) it checks if the spell is 'not on cd' and 'not being cast'
	-- (2) it checks if all conditions are met
	-- if (1) and (2),
	-- set 'self.next_spell_trigger' to false, this skips all further setAction()
	
	-- to fake-fire a spell, use self:setAction(spellid, conditions, 1)
	-- this returns three values, spell_ready & conditons_met, spell_ready, conditions_met
	-- it won't change 'self.next_spell_trigger'
	-- it is usually useful to treat major cooldowns this way
	-- so that players can choose not to use every cooldown on trash 
	
	-- reset self.next_spell_trigger
	self.next_spell_trigger = true
	self.next_spell = nil
	
	-- simc rotation
	
	-- icy vein has a indepedent icon
	local iv_action, iv_usable = self:setAction(12472, time_to_kill > 30, 1)	-- icy vein
	
	-- if a spell is set in if statement, you will need this separate line 
	fo_usable = self:setAction(84714, true, 1)	-- frozen orb
	
	if is_aoe then 
		-- three types of 'conditions' are accpeted
		-- {condition1, condition2, ...} are connected by AND
		fo_action = self:setAction(84714, time_to_kill > 10, 1)	-- frozen orb
		self:setAction(120, {target_distance <= 12, target_distance >= 0})	-- cone of cold
		self:setAction(116)		-- frost bolt
	else
		-- some complicated conditions
		self:setAction(44614, {not(talent_glacial_spike), (casting_ebonbolt or last_cast == 257537)
			or (last_cast == 116 and buff_brain_freeze) })	-- flurry
		self:setAction(44614, {talent_glacial_spike, buff_brain_freeze, 
			(casting_glacial_spike or last_cast == 199786) or (casting_ebonbolt or last_cast == 257537) or 
			(last_cast == 116 and buff_stack_icicles < 4) })	-- flurry
		self:setAction(199786, buff_brain_freeze or (casting_ebonbolt or last_cast == 257537)
			or (is_cleave and talent_splitting_ice) )	-- glacial spike
	end
	
	-- the default spell if none of these setAction() hit
	if self.next_spell_trigger then self.next_spell = 116 end
	
	-- update the main icon
	self:updateIcon()
	
	-- some typical icons & cds
	
	-- icon shows if a spell is off cd
	-- and glows if it's the best rotation spell
	if fo_usable then 
		self.button_cd1: Show()
		if fo_action then 
			ActionButton_ShowOverlayGlow(self.button_cd1)
		else
			ActionButton_HideOverlayGlow(self.button_cd1)
		end
	else
		self.button_cd1: Hide()
	end
	
	-- a traditional cd icon, always there
	-- turns green in its duration
	local ivStart, ivCd = GetSpellCooldown(12472)
	if ivCd > gcd then 
		self.cooldown_cd3: SetCooldown(ivStart, ivCd)
	end	
	if buff_icy_veins then 
		self.overlay_cd3:SetColorTexture(0, .5, 0, 0.6)
	else
		self.overlay_cd3:SetColorTexture(0, .5, 0, 0)
	end
	
	-- print some debug info
	if DEBUG > 0 then
		print("SR: Class Spec module")
		print("SR: Enabled: ".. tostring(self.enabled))
		print("SR: Next spell: ".. tostring(self.next_spell))
		print("SR: Tagets hit: ".. tostring(self.player: getCleaveTargets()))
		print("SR: Cleave: ".. tostring(self.player: isCleave()))
		print("SR: AOE: ".. tostring(self.player: isAOE()))
		print(" ")
	end
	return self.next_spell
end
