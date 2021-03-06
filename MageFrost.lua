MageFrost = {}
MageFrost.__index = MageFrost

setmetatable(MageFrost, {
  __index = Specialization, -- inherit from the Specialization class
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
	
	local spells = {}
	
	spells.gcd 		= 	30455 		--"Ice Lance"    -- can be any zero-cooldown spell
	
	spells.buff 	= { 44544,		--"Fingers of Frost"
						190446,		--"Brain Freeze"
						205473,		--"Icicles"
						270232,		--"Freezing Rain"
						12472,		--"Icy Veins"
					  }	
					  
    spells.dot 		= {	228358 }	--"Winter's Chill"
	
    spells.cd 		= {	84714, 		--"Frozen Orb"
						190356, 	--"Blizzard"
						153595, 	--"Comet Storm"
						157997, 	--"Ice Nova"
						205021, 	--"Ray of Frost"
						257537, 	--"Ebonbolt"
						120,		--"Cone of Cold"
						12472, 		--"Icy Veins"
						55342, 		--"Mirror Image"
						116011, 	--"Rune of Power"
						33395,		--"Freeze (Water Elemental)"
						122, 		--"Frost Nova"
						295373,		--"Concentrated Flame"
					  }
						  
	-- spells that cause cleave damage (and use them as aoe indicators)
	spells.cleave 	= {	84721, 		--"Frozen Orb"
						153596,		--"Comet Storm"
						190357,		--"Blizzard"
						--122, 		--"Frost Nova"
						228598, 	--"Ice Lance"
						228597, 	--"Frostbolt"
						257538, 	--"Ebonbolt"
						228600, 	--"Glacial Spike"
						120,		--"Cone of Cold"
					  }
					  
	-- spells that need to be traced in the combat log
	spells.trace 	= { 30455, 		--"Ice Lance"
						44614, 		--"Flurry"
						84714, 		--"Frozen Orb"
						257537, 	--"Ebonbolt"
						116, 		--"Frostbolt"
						199786, 	--"Glacial Spike"
						153595, 	--"Comet Storm"
						33395,		--"Freeze (Water Elemental)"
					  }

	Specialization._new(self, spells)
	
	self:createActions()
	self.cleave:setTimeout(6)
	
	self.icon_cooldown 	= self:createIcon(84714, 35, -60, 0)
	self.icon_icy_veins = self:createIcon(12472, 35, -100, 0)
	self.icon_blizzard 	= self:createIcon(190356, 35, 60, 0)
	self.icon_icicles 	= self:createIcon(199786, 35, 100, 0)
	self.text_icicles 	= self:createText(self.icon_icicles, 16, 1, -1)
	
	self.icon_freeze = self:createIcon(33395, 25, 0, 0, "BOTTOMRIGHT", "HIGH")
end

function MageFrost:createActions()
	local act = self.actions
	
	act.main 		= {}
	act.cooldowns 	= {}
	act.aoe 		= {}
	act.aoe_cds 	= {}
	act.single		= {}
	act.single_cds 	= {}
	act.freeze 		= {}
	act.misc		= {}
	
	act.main.ice_lance 			= self:newAction(30455, act.main)
		
	act.cooldowns.icy_veins 	= self:newAction(12472, act.cooldowns)
	act.cooldowns.mirror_image 	= self:newAction(55342, act.cooldowns)
	act.cooldowns.rune_of_power = self:newAction(116011, act.cooldowns)
		
	act.aoe.blizzard 			= self:newAction(190356, act.aoe)
	act.aoe.flurry 				= self:newAction(44614, act.aoe)
	act.aoe.flurry2 			= self:newAction(44614, act.aoe)
	act.aoe.ice_lance 			= self:newAction(30455, act.aoe)
	act.aoe.concentrated_flame 	= self:newAction(295373, act.single)
	act.aoe.ebonbolt 			= self:newAction(257537, act.aoe)
	act.aoe.glacial_spike 		= self:newAction(199786, act.aoe)
	act.aoe.cone_of_cold 		= self:newAction(120, act.aoe)
	act.aoe.frostbolt 			= self:newAction(116, act.aoe)
	
	act.aoe_cds.frozen_orb 		= self:newAction(84714, act.aoe_cds)
	act.aoe_cds.comet_storm 	= self:newAction(153595, act.aoe_cds)
	act.aoe_cds.ice_nova 		= self:newAction(157997, act.aoe_cds)
	act.aoe_cds.ray_of_frost 	= self:newAction(205021, act.aoe_cds)
	
	act.single.flurry 			= self:newAction(44614, act.single)
	act.single.flurry2 			= self:newAction(44614, act.single)
	act.single.flurry3 			= self:newAction(44614, act.single)
	act.single.blizzard 		= self:newAction(190356, act.single)
	act.single.blizzard2 		= self:newAction(190356, act.single)
	act.single.ice_lance 		= self:newAction(30455, act.single)
	act.single.concentrated_flame = self:newAction(295373, act.single)
	act.single.ebonbolt 		= self:newAction(257537, act.single)
	act.single.blizzard3 		= self:newAction(190356, act.single)
	act.single.glacial_spike 	= self:newAction(199786, act.single)
	act.single.frostbolt 		= self:newAction(116, act.single)
	
	act.single_cds.ice_nova 	= self:newAction(157997, act.single_cds)
	act.single_cds.frozen_orb 	= self:newAction(84714, act.single_cds)
	act.single_cds.comet_storm 	= self:newAction(153595, act.single_cds)
	act.single_cds.ray_of_frost = self:newAction(205021, act.single_cds)
	act.single_cds.ice_nova2 	= self:newAction(157997, act.single_cds)
	
	act.freeze.pet_freeze 		= self:newAction(33395, act.freeze)
	act.freeze.pet_freeze2 		= self:newAction(33395, act.freeze)
	act.freeze.frost_nova 		= self:newAction(122, act.freeze)
	
	act.misc.ice_lance			= self:newAction(30455, act.misc)
end

function MageFrost:updateVariables()
	local var = self.variables
	
	var.gcd 					= self.spells:getGcd()
	var.dt						= self.spells:timeNextSpell()
	var.targets 				= self.cleave:targets()
	var.ttk 					= self.player:timeToKill() 
	var.ttk_effective			= var.ttk * math.min(2, 0.9 + (var.targets == 0 and 0.1 or 0) + var.targets / 10 )
	
	var.target_can_be_cced 		= self.player:canBeCCed()
	
	var.distance = select(2, self:getRange("target"))
	var.distance = var.distance or -1
	
	var.azerite = {}
	--var.azerite.wild_fleshrending = self.player: getAzeriteRank(359) > 0
	
	var.haste = UnitSpellHaste("player")
	
	var.talent = var.talent or {}
	var.talent.lonely_winter 	= self.talent[1] == 2
	var.talent.rune_of_power 	= self.talent[3] == 3
	var.talent.ebonbolt 		= self.talent[4] == 3
	var.talent.freezing_rain 	= self.talent[6] == 1
	var.talent.splitting_ice 	= self.talent[6] == 2
	var.talent.comet_storm 		= self.talent[6] == 3
	var.talent.glacial_spike 	= self.talent[7] == 3
	
	var.casting = var.casting or {}
	var.casting.ebonbolt 		= self.spells:isCasting(257537)
	var.casting.glacial_spike 	= self.spells:isCasting(199786)
	var.casting.flurry 			= self.spells:isCasting(44614)
	var.casting.frostbolt 		= self.spells:isCasting(116, true)
	var.casting.blizzard 		= self.spells:isCasting(190356)
	var.casting.water_elemental = self.spells:isCasting(31687)
	
	var.cooldown = var.cooldown or {}
	var.cooldown.frozen_orb 	= self.spells:cooldown(84714)
	var.cooldown.frost_nova 	= self.spells:cooldown(122)
	var.cooldown.freeze 		= self.spells:cooldown(33395)
	var.cooldown.comet_storm	= self.spells:cooldown(153595)
	var.cooldown.icy_veins		= self.spells:cooldown(12472)
	var.cooldown.essence 		= self.spells:cooldown(self.essence)
	
	var.buff = var.buff or {}
	var.buff.icicles 			= self.spells:buff(205473)
	var.buff.brain_freeze 		= self.spells:buff(190446)
	var.buff.fingers_of_frost 	= self.spells:buff(44544)
	var.buff.freezing_rain 		= self.spells:buff(270232)
	var.buff.icy_veins 			= self.spells:buff(12472)
	
	var.debuff = var.debuff or {}
	var.debuff.winters_chill 	= self.spells:dot(228358) 
	
	var.recent = var.recent or {}
	var.recent.ice_lance		= self.spells:recentCast(30455)
	var.recent.flurry 			= self.spells:recentCast(44614)
	var.recent.frozen_orb 		= self.spells:recentCast(84714)
	var.recent.ebonbolt 		= self.spells:recentCast(257537)
	var.recent.frostbolt 		= self.spells:recentCast(116)
	var.recent.glacial_spike 	= self.spells:recentCast(199786)
	var.recent.comet_storm 		= self.spells:recentCast(153595)
	var.recent.freeze 			= self.spells:recentCast(33395)
	
	var.previous_cast 			= self.spells:recentCast()
	
	--------------------------------
	-- Frost Mage specific variables
	
	-- Detect if water element exists
	var.on_flying_mount = IsFlying() or var.on_flying_mount and IsMounted()
	var.pet_exists = UnitExists("pet") and not(var.on_flying_mount) or var.pet_exists and var.on_flying_mount
	
	-- If casting ebonbolt, we can expect an upcoming brain freeze 
	var.buff.brain_freeze.up 		= var.casting.ebonbolt or var.buff.brain_freeze.up
	var.buff.brain_freeze.remain 	= var.casting.ebonbolt and 15 or var.buff.brain_freeze.remain
	
	-- If casting frost bolt, icicles will get one more stack
	-- If casting glacial_spike, icicles will be lost
	var.buff.icicles.stack_raw = var.buff.icicles.stack
	var.buff.icicles.stack = math.min(5, var.buff.icicles.stack + (var.casting.frostbolt and 1 or 0) )
	var.buff.icicles.stack = var.casting.glacial_spike and 0 or var.buff.icicles.stack
	
	-- Time to the next glacial spike, to if the brain freeze lasts as long, 
	local casttime_frostbolt 		= select(4, GetSpellInfo(116)) / 1000
	local casttime_glacial_spike 	= select(4, GetSpellInfo(199786)) / 1000
	var.time_next_gs = (5 - (var.casting.glacial_spike and 5 or var.buff.icicles.stack) ) * casttime_frostbolt 
						+ ( var.casting.glacial_spike and 0 or casttime_glacial_spike )
						+ self.spells:timeNextSpell()
	
	-- Condition for glacial spike (GS)
	-- GS is treated differently because GS is considered not usable with 4 icicles and casting a frostbolt
	var.gs_condition = 	var.talent.glacial_spike and
						var.buff.icicles.stack == 5 and var.ttk_effective > var.time_next_gs and 
						( var.buff.brain_freeze.up or 
							( var.talent.splitting_ice and var.targets >= 2 ) or 
							( var.target_can_be_cced and 
								( var.cooldown.freeze.up or 
									( var.cooldown.frost_nova.up and var.distance <= 12 ) ) ) )
end

function MageFrost: updateAllActions()
	local var = self.variables
	local act = self.actions
	
	-- main / pre-combat action list
	--print(var.casting.flurry or var.recent.flurry.cast)
	self:updateAction(act.main.ice_lance, 	  { var.casting.flurry or var.previous_cast.spell_id == 44614, 
												not var.buff.fingers_of_frost.up, var.previous_cast.spell_id ~= 30455 })
	
	self:updateAction(act.cooldowns.icy_veins)
	self:updateAction(act.cooldowns.mirror_image)
	self:updateAction(act.cooldowns.rune_of_power, var.recent.frozen_orb.cast)
	
	self:updateAction(act.aoe_cds.frozen_orb)
	self:updateAction(act.aoe_cds.comet_storm)
	self:updateAction(act.aoe_cds.ice_nova)
	self:updateAction(act.aoe_cds.ray_of_frost)
	
	self:updateAction(act.aoe.blizzard, _, _, false)
	self:updateAction(act.aoe.flurry, 			var.casting.ebonbolt or 
												var.buff.brain_freeze.up and 
												( var.casting.frostbolt and not var.buff.fingers_of_frost.up and
												( var.buff.icicles.stack < 4 or not var.talent.glacial_spike ) or 
												var.casting.glacial_spike ) )
	self:updateAction(act.aoe.flurry2,		  {	var.talent.glacial_spike, var.buff.brain_freeze.up, 
												var.casting.glacial_spike or
												var.buff.brain_freeze.remain < var.time_next_gs } )
	self:updateAction(act.aoe.ice_lance, 		var.buff.fingers_of_frost.up)
	self:updateAction(act.aoe.concentrated_flame)
	self:updateAction(act.aoe.ebonbolt,   	  {	not var.talent.glacial_spike or var.buff.icicles.stack == 5, 
												not var.buff.brain_freeze.up, var.ttk_effective > var.time_next_gs + var.gcd * 2 } )
	self:updateAction(act.aoe.glacial_spike, _, var.gs_condition)	-- 3rd parameter for override
	self:updateAction(act.aoe.cone_of_cold,   {	var.distance <= 12, var.targets > 6 })
	self:updateAction(act.aoe.frostbolt)
	
	self:updateAction(act.single_cds.ice_nova)
	self:updateAction(act.single_cds.frozen_orb)
	self:updateAction(act.single_cds.comet_storm)
	self:updateAction(act.single_cds.ray_of_frost, { not var.recent.frozen_orb.cast, var.cooldown.frozen_orb.remain > 5 } )
	self:updateAction(act.single_cds.ice_nova2)
	
	self:updateAction(act.single.flurry, 	  {	var.casting.ebonbolt, 
												not var.talent.glacial_spike or var.buff.icicles.stack < 4 } )
	self:updateAction(act.single.flurry2, 	  {	var.casting.glacial_spike, var.buff.brain_freeze.up, 
												var.buff.brain_freeze.remain > var.time_next_gs } )
	self:updateAction(act.single.flurry3, 	  {	var.casting.frostbolt, var.buff.brain_freeze.up, not var.buff.fingers_of_frost.up, 
												not var.talent.glacial_spike or var.buff.icicles.stack < 4 } )
	self:updateAction(act.single.blizzard, 	  	var.targets > 2, _, false )
	self:updateAction(act.single.blizzard2,   {	var.targets > 1 and 
												var.buff.freezing_rain.up and var.buff.fingers_of_frost.stack < 2 } )
	self:updateAction(act.single.ice_lance, 	var.buff.fingers_of_frost.up)
	self:updateAction(act.single.concentrated_flame)
	self:updateAction(act.single.ebonbolt, 	  {	not var.talent.glacial_spike or var.buff.icicles.stack == 5, 
												not var.buff.brain_freeze.up, var.ttk_effective > var.time_next_gs + var.gcd * 2 } )
	self:updateAction(act.single.blizzard3,   {	var.targets > 1, var.buff.freezing_rain.up } )
	self:updateAction(act.single.glacial_spike, _, var.gs_condition)	-- 3rd parameter for override
	self:updateAction(act.single.frostbolt, _, true)
	
	self:updateAction(act.freeze.pet_freeze,  {	var.casting.glacial_spike, not var.recent.glacial_spike.cast,
												(var.targets > 1 and var.talent.splitting_ice) or not var.buff.brain_freeze.up })
	self:updateAction(act.freeze.pet_freeze2,  	var.recent.comet_storm.cast )
	self:updateAction(act.freeze.frost_nova,  { var.casting.glacial_spike, not var.recent.glacial_spike.cast,
												var.distance <= 12, not var.recent.freeze.cast, 
												var.targets > 1 or not var.buff.brain_freeze.up } )
	
	self:updateAction(act.misc.ice_lance)
end

function MageFrost: nextSpell()
	local var = self.variables
	
	self:updateVariables()
	self:updateAllActions()
	
	local targets 				= var.targets
	local main 					= self:runActionList(self.actions.main)
	local cooldowns 			= self:runActionList(self.actions.cooldowns)
	local aoe 					= self:runActionList(self.actions.aoe)
	local aoe_cds 				= self:runActionList(self.actions.aoe_cds)
	local single, priority		= self:runActionList(self.actions.single)
	local single_cds 			= self:runActionList(self.actions.single_cds)
	local freeze 				= self:runActionList(self.actions.freeze)
	
	-- The "misc" action list consists an unconditional ice lance action
	-- to detect if player can cast spells
	local can_use_spells = self:runActionList(self.actions.misc)
	if not can_use_spells then 
		self:hideAllIcons()
		return
	else
		self:showAllIcons()
	end
	--print(main)
	local spell = main or ( targets >= 4 ) and aoe or single
	local short_cds = ( targets >= 4 ) and aoe_cds or single_cds
	
	local blizzard_usable = (self.actions.aoe.blizzard.usable or self.actions.single.blizzard.usable)
							and targets > 2 and not main and priority > 3
	
	self:updateIcon(_, spell)
	self:updateIcon(self.icon_cooldown, short_cds)
	self:updateIcon(self.icon_freeze, freeze)
	self:updateIcon(self.icon_icicles, _, _, 135855)
	
	if not short_cds then 
		if var.cooldown.comet_storm.remain < var.cooldown.frozen_orb.remain and var.talent.comet_storm then 
			self:updateIcon(self.icon_cooldown, 153595, 153595)
		else 
			self:updateIcon(self.icon_cooldown, 84714, 84714)
		end
	end
	
	if blizzard_usable then 
		self:updateIcon(self.icon_blizzard, 190356, 190356, _, _, {0, 1, 0, 1})
	else
		self:updateIcon(self.icon_blizzard, 190356, 190356)
	end
	
	--self:iconColor(self.icon_icicles, 1, 1, 1, ( var.buff.icicles.stack_raw + 1 )/ 6 )
	self:setText(self.text_icicles, tostring(var.buff.icicles.stack_raw))
	if var.buff.icicles.stack == 5 then
		self:iconDesaturate(self.icon_icicles, false)
	else 
		self:iconDesaturate(self.icon_icicles)
	end
	
	local hide_pet_icon = var.pet_exists or var.talent.lonely_winter or var.casting.water_elemental
	
	-- The icy veins icon is overridden. Hide if player can't cast.
	if hide_pet_icon then 
		if var.buff.icy_veins.up then 
			self:updateIcon(self.icon_icy_veins, 12472)
			self:iconSetBuffAnimation(self.icon_icy_veins, 12472)
		elseif self.essence	== 295840 and var.cooldown.essence.remain <= var.cooldown.icy_veins.remain then 
			self:updateIcon(self.icon_icy_veins, self.essence, self.essence)
		else 
			self:updateIcon(self.icon_icy_veins, 12472, 12472)
		end
	else
		self:updateIcon(self.icon_icy_veins, 31687, 31687, _, _, {0, 1, 0, 1})
	end
	
end