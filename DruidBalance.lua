DruidBalance = {}
DruidBalance.__index = DruidBalance

setmetatable(DruidBalance, {
  __index = Specialization, -- inherit from the PlayerRotation class
  __call = function (class, ...)
    local self = setmetatable({}, class)
    self:_new(...)
    return self
  end,
})

function DruidBalance:_new()
	local spells = {}
	
	-- can be any zero-cooldown spell
	spells.gcd		= 	93402 		--"Sunfire"    
	
	spells.buff 	= { 102560,		--"Incarnation"
						194223, 	--"Celestial Alignment"
						279709, 	--"Starlord"
						164545, 	--"Solar Empowerment"
						164547, 	--"Lunar Empowerment"
						202425, 	--"Warrior of Elune"
						24858, 		--"Moonkin Form"
						783, 		--"Travel Form"
						287790, 	--"Arcanic Pulsar"
					  }	
    
	spells.dot 		= {	164815, 	--"Sunfire"
						164812, 	--"Moonfire"
						202347,		--"Stellar Flare"
					  }
    
	spells.cd  		= {	202425, 	--"Warrior of Elune"
						102560, 	--"Incarnation"
						194223, 	--"Celestial Alignment"
						211545, 	--"Fury of Elune"
						205636,		--"Force of Nature"
						274281, 	--"New Moon"
						274282, 	--"Half Moon"
						274283,		--"Full Moon" 
					  }	
	
	-- Spells that cause cleave damage.
	-- Use IDs from the SPELL_DAMAGE combat log.
	-- These IDs are usually different from the original spell IDs.
	-- Associated with self.cleave.
	spells.cleave 	= {	164812, 	--"Moonfire"
						194153, 	--"Lunar Strike"
						191037, 	--"Starfall"
						279729,		--"Solar Wrath"
						211545, 	--"Fury of Elune"
					  }
	
	-- Spells that need to be tracked from the SPELL_CAST combat log.
	-- Associated with self.spells:recentCast().
	spells.trace 	= { 78674, 		-- "Starsurge"
						164815, 	-- "Sunfire"
						164812, 	-- "Moonfire"
						202347,		-- "Stellar Flare"
						194153, 	-- "Lunar Strike"
						190984, 	-- "Solar Wrath"
					  }
	
	-- Auras that need to be tracked from the SPELL_AURA_APPLIED/REMOVED combat log.
	-- Use the default buff module if possible, for better latency and resource.
	-- This aura tracker records timestamps of auras 
	-- to determine the interactions between casts and auras.
	-- Associated with self.spells:auraUp(), doesSpellCastRemoveAura().
	spells.auras 	= { 164545, 	-- "Solar Empowerment"
						164547, 	-- "Lunar Empowerment"
					  }
	
	Specialization._new(self, spells)
	
	self:createActions()
	self.cleave:setTimeout(6)
	
	self.icon_left				= self:createIcon(102560, 35, -50, 0)
	self.icon_right 			= self:createIcon(24858, 35, 50, 0)
	
	self.icon_sunfire			= self:createIcon(164815, 35, -45, 110, _, _, true)
	self.icon_moonfire			= self:createIcon(164812, 35, 0, 110, _, _, true)
	self.icon_stellar_flare		= self:createIcon(202347, 35, 45, 110, _, _, true)
	
	self.texture_cancel			= self:createTexture(_, "Interface\\AddOns\\SmartRotation\\cancel-icon")
	
	self.text_sunfire			= self:createText(self.icon_sunfire, 12, 0, -27)
	self.text_moonfire			= self:createText(self.icon_moonfire, 12, 0, -27)
	self.text_stellar_flare		= self:createText(self.icon_stellar_flare, 12, 0, -27)
	
end

function DruidBalance:createActions()
	local act = self.actions
	
	act.cooldowns = {}
	act.cooldowns.moonkin_form 		= self:newAction(24858, act.cooldowns)
	act.cooldowns.warrior_of_elune 	= self:newAction(202425, act.cooldowns)
	act.cooldowns.fury_of_elune 	= self:newAction(211545, act.cooldowns)
	
	act.spenders = {}
	act.spenders.cancel_starlord	= self:newAction("CANCEL_STARLORD", act.spenders)
	act.spenders.starfall 			= self:newAction(191037, act.spenders)
	act.spenders.starsurge 			= self:newAction(78674, act.spenders)
	act.spenders.sunfire 			= self:newAction(164815, act.spenders)
	act.spenders.moonfire 			= self:newAction(164812, act.spenders)
	
	act.dots = {}
	act.dots.sunfire 				= self:newAction(164815, act.dots)
	act.dots.moonfire 				= self:newAction(164812, act.dots)
	act.dots.stellar_flare 			= self:newAction(202347, act.dots)
	
	act.generators = {}
	act.generators.new_moon 		= self:newAction(164815, act.generators)
	act.generators.half_moon 		= self:newAction(164815, act.generators)
	act.generators.full_moon 		= self:newAction(164815, act.generators)
	act.generators.lunar_strike 	= self:newAction(164815, act.generators)
	act.generators.solar_wrath 		= self:newAction(164815, act.generators)
end

function DruidBalance:updateVariables()
	local var = self.variables
	
	var.gcd 		= self.spells:getGcd()
	var.dt 			= self.spells:timeNextSpell()
	var.ap			= self.player:power(Enum.PowerType.LunarPower)
	var.ap_max 		= self.player:powerMax(Enum.PowerType.LunarPower)
	
	self.cleave:setLowHealthThreshold(select(2, self.player:dps()) * 6)
	
	var.targets 			= self.cleave:targets()
	var.targets_low_health 	= select(5, self.cleave:targets())
	var.targets_high_health = var.targets - var.targets_low_health
	
	var.ttk = self.player:timeToKill()
	var.ttk_effective = var.ttk * math.min(2, 0.9 + (var.targets == 0 and 0.1 or 0) + var.targets / 10 )
	
	var.azerite = {}
	var.azerite.streaking_stars 	= self.player: getAzeriteRank(122) > 0
	var.azerite.arcanic_pulsar 		= self.player: getAzeriteRank(200) > 0
	var.azerite.lively_spirit 		= self.player: getAzeriteRank(364) > 0
	
	var.talent = var.talent or {}
	var.talent.natures_balance 		= self.talent[1] == 1
	var.talent.warrior_of_elune 	= self.talent[1] == 2
	var.talent.starlord 			= self.talent[5] == 2
	var.talent.incarnation 			= self.talent[5] == 3
	var.talent.stellar_drift 		= self.talent[6] == 1
	var.talent.twin_moons 			= self.talent[6] == 2
	var.talent.stellar_flare		= self.talent[6] == 3
	var.talent.shooting_stars 		= self.talent[7] == 1
	var.talent.fury_of_elune 		= self.talent[7] == 2
		
	var.cooldown = var.cooldown or {}
	var.cooldown.incarnation 			= self.spells:cooldown(102560)
	var.cooldown.celestial_alignment 	= self.spells:cooldown(194223)
	
	var.cooldown.ca_inc = var.talent.incarnation and var.cooldown.incarnation or var.cooldown.celestial_alignment
	
	var.buff = var.buff or {}
	var.buff.moonkin_form 			= self.spells:buff(24858)
	var.buff.travel_form 			= self.spells:buff(783)
	var.buff.solar_empowerment 		= self.spells:buff(164545)
	var.buff.lunar_empowerment 		= self.spells:buff(164547)
	var.buff.starlord 				= self.spells:buff(279709)
	var.buff.arcanic_pulsar 		= self.spells:buff(287790)
	var.buff.incarnation 			= self.spells:buff(102560)
	var.buff.celestial_alignment 	= self.spells:buff(194223)
	var.buff.warrior_of_elune 		= self.spells:buff(202425)
	
	var.buff.ca_inc = var.talent.incarnation and var.buff.incarnation or var.buff.celestial_alignment
	
	var.casting = var.casting or {}
	-- The default casting detector adds a short delay (~300ms) after a cast finishes.
	-- The second parameter removes such delay. 
	-- The delay is usually preferrable, as there is a delay between ending casts and landing spells
	-- However, such delay will result in inaccurate resource estimation
	-- Remove delay (i.e., 'true' for the 2nd parameter) if the spell is related to resource generation
	-- Keep delay (i.e., default) if the spell applies buff/debuff
	var.casting.solar_wrath 		= self.spells:isCasting(190984, true)
	var.casting.lunar_strike 		= self.spells:isCasting(194153, true)
	var.casting.stellar_flare 		= self.spells:isCasting(202347)
	var.casting.new_moon 			= self.spells:isCasting(274281, true)
	var.casting.half_moon 			= self.spells:isCasting(274282, true)
	var.casting.full_moon 			= self.spells:isCasting(274283, true)
	
	var.dot = var.dot or {}
	var.dot.sunfire 				= self.spells:dot(164815, 18)
	var.dot.moonfire 				= self.spells:dot(164812, 22)
	var.dot.stellar_flare			= self.spells:dot(202347, 24)
	
	var.count = var.count or {}
	var.count.sunfire 				= self.spells:dotCount(164815, 18)
	var.count.moonfire 				= self.spells:dotCount(164812, 22)
	var.count.stellar_flare 		= self.spells:dotCount(202347, 24)
	
	var.recent = var.recent or {}
	var.recent.starsurge			= self.spells:recentCast(78674)
	var.recent.starfall				= self.spells:recentCast(191037)
	
	var.previous_cast 				= self.spells:recentCast()
	
	var.buff.lunar_empowerment.stack = max(var.buff.lunar_empowerment.stack - (var.casting.lunar_strike and 1 or 0), 0)
	var.buff.lunar_empowerment.up = var.buff.lunar_empowerment.up and var.buff.lunar_empowerment.stack > 0
	var.buff.solar_empowerment.stack = max(var.buff.solar_empowerment.stack - (var.casting.solar_wrath and 1 or 0), 0)
	var.buff.solar_empowerment.up = var.buff.solar_empowerment.up and var.buff.solar_empowerment.stack > 0
	
	var.ap_predict = var.ap + ( var.talent.natures_balance and ceil( var.dt / 1.5 ) or 0 )
	var.ap_predict = var.ap_predict + ( var.casting.solar_wrath and 8 or 0 )
	var.ap_predict = var.ap_predict + ( var.casting.lunar_strike and 12 or 0 )
	var.ap_predict = var.ap_predict + ( var.casting.stellar_flare and 8 or 0 )
	var.ap_predict = var.ap_predict + ( var.casting.new_moon and 10 or 0 )
	var.ap_predict = var.ap_predict + ( var.casting.half_moon and 20 or 0 )
	var.ap_predict = var.ap_predict + ( var.casting.full_moon and 40 or 0 )
	var.ap_predict = min(var.ap_predict, var.ap_max)
	
	var.ap_deficit = var.ap_max - var.ap_predict - 
					( var.talent.shooting_stars and ( var.dot.moonfire.up or var.dot.sunfire.up ) and 4 or 0 ) 
	
	var.sf_targets = 4
	if var.talent.twin_moons and ( var.azerite.arcanic_pulsar or var.talent.starlord ) then 
		var.sf_targets = var.sf_targets + 1
	end
	if not var.azerite.arcanic_pulsar and not var.talent.starlord and var.talent.stellar_drift then 
		var.sf_targets = var.sf_targets - 1
	end
end

function DruidBalance:updateAllActions()
	-- self:updateAction(action, {condition1, conditon2, ..})
	-- 
	-- updateAction() checks if all condtions are met and 
	-- if the spell is (1)off cooldown (2)usable(resource) (3)not being cast
	--
	-- Use updateAction(action, _, [true/false]) to override
	-- 
	-- When should this override be used:
	-- (1) The spell can be consecutively casted, or
	-- (2) The spell requires resource from a previous casting spell.
	--     e.g. Player has 4 icicles, and is casting frostbolt. 
	-- 			It can be expected that player will get another icicle from the frostbolt,
	-- 			and will be able to cast Glacial Spike. 
	-- 			SR should prompt Glacial Spike despite the spell is not currently usable (4 icicles). 
	-- (3) The action is not to cast a spell (e.g. use item, cancel aura). 
	--
	-- All actions have to be updated, including unconditioned ones
	local var = self.variables
	local act = self.actions
	
	act.cooldowns.warrior_of_elune 	= self:newAction(202425, act.cooldowns)
	act.cooldowns.fury_of_elune 	= self:newAction(211545, act.cooldowns)
	
	act.spenders = {}
	act.spenders.cancel_starlord	= self:newAction("CANCEL_STARLORD", act.spenders)
	act.spenders.starfall 			= self:newAction(191037, act.spenders)
	act.spenders.starsurge 			= self:newAction(78674, act.spenders)
	act.spenders.sunfire 			= self:newAction(164815, act.spenders)
	act.spenders.moonfire 			= self:newAction(164812, act.spenders)
	
	act.dots = {}
	act.dots.sunfire 				= self:newAction(164815, act.dots)
	act.dots.moonfire 				= self:newAction(164812, act.dots)
	act.dots.stellar_flare 			= self:newAction(202347, act.dots)
	
	act.dots_focus = {}
	act.dots_focus.sunfire 			= self:newAction(164815, act.dots_focus)
	act.dots_focus.moonfire 		= self:newAction(164812, act.dots_focus)
	act.dots_focus.stellar_flare 	= self:newAction(202347, act.dots_focus)
	
	act.generators = {}
	act.generators.new_moon 		= self:newAction(274281, act.generators)
	act.generators.half_moon 		= self:newAction(274282, act.generators)
	act.generators.full_moon 		= self:newAction(274283, act.generators)
	act.generators.lunar_strike 	= self:newAction(194153, act.generators)
	act.generators.solar_wrath 		= self:newAction(190984, act.generators)
	
	act.misc = {}
	act.misc.sunfire 				= self:newAction(164815, act.misc)
	var.targets = 1
	self:updateAction(act.cooldowns.moonkin_form, 		not var.buff.moonkin_form.up)
	self:updateAction(act.cooldowns.warrior_of_elune)
	self:updateAction(act.cooldowns.fury_of_elune, {	var.buff.ca_inc.up or var.cooldown.ca_inc.remain > 30, 
														var.ap_deficit >= 8 } )

	-- override because "cancel starlord" is not a spell													
	self:updateAction(act.spenders.cancel_starlord, _, 	var.buff.starlord.up and var.buff.starlord.remain < 8 and var.ap_deficit < 8 )
	self:updateAction(act.spenders.starfall,		  {	var.buff.starlord.stack < 3 or var.buff.starlord.remain >= 8, 
														var.targets >= var.sf_targets })

	-- override because of resource (astral power)
	self:updateAction(act.spenders.starsurge, _,		var.ap_predict >= 40 and 
														( var.talent.starlord and 
														  ( var.buff.starlord.stack < 3 or var.buff.starlord.remain >= 8 and 
														    var.buff.arcanic_pulsar.stack < 8 ) or 
														  not var.talent.starlord and 
														  (var.buff.arcanic_pulsar.stack < 8 or var.buff.ca_inc.up ) ) and
														var.targets < var.sf_targets and 
														var.buff.lunar_empowerment.stack + var.buff.solar_empowerment.stack < 4 and 
														var.buff.solar_empowerment.stack < 3 and var.buff.lunar_empowerment.stack < 3 and 
														( not var.azerite.streaking_stars or not var.buff.ca_inc.up or 
														  not var.recent.starsurge.cast ) or 
														var.ap_deficit < 8 )
	self:updateAction(act.spenders.sunfire,	  		  { var.buff.ca_inc.up, var.buff.ca_inc.remain < var.gcd, 
														var.azerite.streaking_stars, var.dot.moonfire.remain > var.dot.sunfire.remain })
	self:updateAction(act.spenders.moonfire,	  	  { var.buff.ca_inc.up, var.buff.ca_inc.remain < var.gcd, 
														var.azerite.streaking_stars })

	local sunfire_conditions 						  = var.ttk_effective > 6 and var.ap_deficit >= 3 and 
														not var.azerite.streaking_stars or not var.buff.ca_inc.up or var.previous_cast ~= 164815
	local moonfire_conditions 						  = var.ttk_effective > 9 and var.ap_deficit >= 3 and 
														not var.azerite.streaking_stars or not var.buff.ca_inc.up or var.previous_cast ~= 164812
	local stellar_flare_conditions 					  = var.ttk_effective > 9 and var.ap_deficit >= 8 and 
														not var.azerite.streaking_stars or not var.buff.ca_inc.up or var.previous_cast ~= 202347
	
	self:updateAction(act.dots.sunfire, 			  { var.dot.sunfire.refreshable, sunfire_conditions } )
	self:updateAction(act.dots.moonfire, 			  { var.dot.moonfire.refreshable, moonfire_conditions } )
	self:updateAction(act.dots.stellar_flare, 		  { var.dot.stellar_flare.refreshable, stellar_flare_conditions } )
	
	
	local not_casting_moon = not ( var.casting.new_moon or var.casting.half_moon or var.casting.full_moon )
	self:updateAction(act.generators.new_moon, 		  {	var.ap_deficit >= 10, not_casting_moon} )
	self:updateAction(act.generators.half_moon, 	  {	var.ap_deficit >= 20, not_casting_moon} )
	self:updateAction(act.generators.full_moon, 	  {	var.ap_deficit >= 40, not_casting_moon} )
	
	-- override because of consecutive casts
	self:updateAction(act.generators.lunar_strike, _,	var.buff.solar_empowerment.stack < 3 and 
														( var.ap_deficit >= 12 or var.buff.lunar_empowerment.stack == 3 ) and
														( ( var.buff.warrior_of_elune.up or var.buff.lunar_empowerment.up or 
														    var.targets > 1 and not var.buff.solar_empowerment.up ) and 
														  ( not var.azerite.streaking_stars or not var.buff.ca_inc.up ) or 
														  var.azerite.streaking_stars and var.buff.ca_inc.up and 
														  ( var.previous_cast == 190984 or var.casting.solar_wrath ) ))
	self:updateAction(act.generators.solar_wrath, _,	not var.azerite.streaking_stars or not var.buff.ca_inc.up 
														or var.previous_cast ~= 202347 and not var.casting.solar_wrath)

	self:updateAction(act.misc.sunfire)
end

function DruidBalance:nextSpell()	

	self:updateVariables()
	self:updateAllActions()
	
	local var = self.variables
	
	local cooldown 		= self:runActionList(self.actions.cooldowns)
	local spender 		= self:runActionList(self.actions.spenders)
	local dot 			= self:runActionList(self.actions.dots)
	local dot_focus 	= self:runActionList(self.actions.dots_focus)
	local generator 	= self:runActionList(self.actions.generators)
	
	-- The "misc" action list consists an unconditional sunfire action
	-- to detect if player can cast spells.
	-- Use this to hide the overriden actions if player cannot cast spells.
	local can_use_spells = self:runActionList(self.actions.misc)
	
	-- Spenders are associated with predicted astral power.
	-- Adds a buffer to reduce the "noise".
	-- This delays the spender by ~300ms.
	local spender_filtered 
	if spender and (spender == self.last_spender or spender) then 
		self.spender_buffer = ( self.spender_buffer or 2 ) + 1
		spender_filtered = ( self.spender_buffer >= 3 ) and spender or nil
	else 
		self.last_spender = spender
		self.spender_buffer = 0
	end
	
	-- self:updateIcon(icon, spell, [cooldown, texture])
	-- Displays the spell on the specified icon (main icon if not specified).
	-- Hide icons with 'nil' spell arg. 
	-- Use texture arg if the desired texture is not a spell.
	
	if not can_use_spells then 
		self:updateIcon(_, nil)
		self:updateIcon(self.icon_left, nil)
		self:updateIcon(self.icon_right, nil)
	else
		local spell = spender_filtered or dot or generator
		if spell == "CANCEL_STARLORD" then 
			self:updateIcon(_, _, _, 462651)
			self.texture_cancel:Show()
		else
			self:updateIcon(_, spell)
			self.texture_cancel:Hide()
		end
		self:updateIcon(self.icon_right, cooldown)
		local id_ca_inc = var.talent.incarnation and 102560 or 194223
		if not var.buff.ca_inc.up then 
			self:updateIcon(self.icon_left, id_ca_inc, id_ca_inc)
		else
			self:updateIcon(self.icon_left, id_ca_inc)
			self:iconSetBuffAnimation(self.icon_left, id_ca_inc)
		end
		if not cooldown then 
			if var.talent.warrior_of_elune then 
				self:updateIcon(self.icon_right, 202425, 202425)
			elseif var.talent.fury_of_elune then 
				self:updateIcon(self.icon_right, 211545, 211545)
			end
		end
	end
		
	if SR_DEBUG > 0 then 
		if not var.talent.stellar_flare then 
			self:iconConfig(self.icon_sunfire, _, _, -22.5, _)
			self:iconConfig(self.icon_moonfire, _, _, 22.5, _)
		else
			self:iconConfig(self.icon_sunfire, _, _, -45, _)
			self:iconConfig(self.icon_moonfire, _, _, 0, _)
		end
		self:updateIcon(self.icon_sunfire, 164815, _, _, {1, 1, 1, 1})
		self:updateIcon(self.icon_moonfire, 164812, _, _, {1, 1, 1, 1})
		
		self:iconSetDotAnimation(self.icon_sunfire, 164815, var.dot.sunfire.refreshable)
		self:iconSetDotAnimation(self.icon_moonfire, 164812, var.dot.moonfire.refreshable)
		
		if var.talent.stellar_flare then 
			self:updateIcon(self.icon_stellar_flare, 202347, _, _, {1, 1, 1, 1})
			self:iconSetDotAnimation(self.icon_stellar_flare, 202347, var.dot.stellar_flare.refreshable)
		else
			self:updateIcon(self.icon_stellar_flare, nil)
		end 
	else 
		self:updateIcon(self.icon_sunfire, nil)
		self:updateIcon(self.icon_moonfire, nil)
		self:updateIcon(self.icon_stellar_flare, nil)
	end
	
	if SR_DEBUG > 1 then 
		self:setText(self.text_sunfire, tostring(var.count.sunfire.up).."("..tostring(var.count.sunfire.refreshable)..")")
		self:setText(self.text_moonfire, tostring(var.count.moonfire.up).."("..tostring(var.count.moonfire.refreshable)..")")
		
		if var.talent.stellar_flare then 
			self:setText(self.text_stellar_flare, tostring(var.count.stellar_flare.up).."("..tostring(var.count.stellar_flare.refreshable)..")")
		else
			self:setText(self.text_stellar_flare, "")
		end 
	else
		self:setText(self.text_sunfire, "")
		self:setText(self.text_moonfire, "")
		self:setText(self.text_stellar_flare, "")
	end
end