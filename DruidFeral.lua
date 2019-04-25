DruidFeral = {}
DruidFeral.__index = DruidFeral

setmetatable(DruidFeral, {
  __index = Specialization, -- inherit from the Specialization class
  __call = function (class, ...)
    local self = setmetatable({}, class)
    self:_new(...)
    return self
  end,
})

-- -- Spell IDs
-- 5221, 	"Shred"
-- 1822,	"Rake"
-- 106785,	"Swipe"
-- 106830,	"Thrash"
-- 1079,	"Rip"
-- 22568,	"Ferocious Bite"
-- 285381,	"Primal Wrath"
-- 22570,	"Maim"
-- 8921,	"Moonfire"
-- 8936,	"Regrowth"
-- 5217,	"Tiger's Fury"
-- 106951,	"Berserk"
-- 274837,	"Feral Frenzy"
-- 102543,	"Incarnation: King of the Jungle"

-- -- Buff IDs
-- 768,	"Cat Form"
-- 5215,	"Prowl"
-- 58984,	"Shadowmeld"
-- 5217,	"Tiger's Fury"
-- 69369,	"Rredatory Swiftness"
-- 135700,	"Clearcasting"
-- 145152,	"Bloodtalons"
-- 106951,	"Berserk"
-- 102543,	"Incarnation"
-- 252071,	"Jungle Stalker"
-- 52610,	"Savage Roar"
-- 276021,	"Iron Jaws"
-- 285646,	"Scent of Blood"

-- -- Dot IDs
-- 1079,	"Rip"
-- 155722,	"Rake"
-- 106830,	"Thrash"
-- 164812,	"Moonfire"

-- -- Combat log IDs
-- 106785, "Swipe"
-- 106830, "Thrash"
-- 205381, "Primal Wrath"

function DruidFeral:_new()
	-- all spells are case-sensitive
	-- (this will be improved in the future)
	local spells = {}
	spells.gcd		= 	8921 		--"Moonfire"    -- can be any zero-cooldown spell
	spells.buff 	= { 768,		--"Cat Form"
						5215,		--"Prowl"
						58984,		--"Shadowmeld"
						5217,		--"Tiger's Fury"
						69369,		--"Rredatory Swiftness"
						135700,		--"Clearcasting"
						145152,		--"Bloodtalons"
						106951,		--"Berserk"
						102543,		--"Incarnation"
						252071,		--"Jungle Stalker"
						52610,		--"Savage Roar"
						276021,		--"Iron Jaws"
						285646,		--"Scent of Blood"
						287916,		--"V.I.G.O.R Engaged"
					  }	
    spells.dot 		= {	1079,		--"Rip"
						155722,		--"Rake"
						106830,		--"Thrash"
						164812,		--"Moonfire"
					  }
    spells.cd  		= {	5215,		--"Prowl"
						5217,		--"Tiger's Fury"
						106951,		--"Berserk"
						202028,		--"Brutal Slash"
						274837,		--"Feral Frenzy"
						102543,		--"Incarnation: King of the Jungle"
						58984,		--"58984"
					  }	
	spells.cleave 	= {	106785, 	--"Swipe"
						106830, 	--"Thrash"
						205381, 	--"Primal Wrath"
					  }
	spells.trace 	= { 5221, 		-- "Shred"
						22568, 		-- "Furious Bite"
						106785, 	-- "Swipe"
						285381,		-- "Primal Wrath"
						1079, 		-- "Rip"
						1822, 		-- "Rake"
						106830,		-- "Thrash"
					  }
	spells.auras 	= { 145152, 	-- "Bloodtalons"
						5215, 		-- "Prowl"
						5217, 		-- "Tiger's Fury"
					  }

	Specialization:_new(spells)
	
	self:createActions()
	self.cleave:setTimeout(6)
	
	self.icon_cooldown 			= self:createIcon(106951, 40, -50, 0)
	self.icon_tigers_fury_small = self:createIcon(5217, 25, 0, 0, "BOTTOMRIGHT", "HIGH")
	
	self.icon_rip 				= self:createIcon(1079, 35, -45, 110, _, _, true)
	self.icon_rake 				= self:createIcon(1822, 35, 0, 110, _, _, true)
	self.icon_thrash 			= self:createIcon(106830, 35, 45, 110, _, _, true)

	self.text_rip 				= self:createText(self.icon_rip, 12, 0, -27)
	self.text_rip_above 		= self:createText(self.icon_rip, 12, 0, 27)
	self.text_rake 				= self:createText(self.icon_rake, 12, 0, -27)
	self.text_rake_above 		= self:createText(self.icon_rake, 12, 0, 27)
	self.text_thrash 			= self:createText(self.icon_thrash, 12, 0, -27)
	self.text_thrash_above 		= self:createText(self.icon_thrash, 12, 0, 27)
end

-- Feral Druid nees a special module to track dot multipliers
function DruidFeral:update()
	Specialization: update()
	self: updateDotMultipliers()
end

function DruidFeral:createActions()
	local act = self.actions
	
	act.main = {}
	act.main.prowl					= self:newAction(5215, act.main)
	act.main.cat_form 				= self:newAction(768, act.main)
	act.main.rake 					= self:newAction(1822, act.main)
	act.main.ferocious_bite 		= self:newAction(22568, act.main)
	act.main.regrowth 				= self:newAction(8936, act.main)
	
	act.cooldowns = {}
	act.cooldowns.berserk 			= self:newAction(106951, act.cooldowns)
	act.cooldowns.tigers_fury 		= self:newAction(5217, act.cooldowns)
	act.cooldowns.tigers_fury2 		= self:newAction(5217, act.cooldowns)
	act.cooldowns.vigor 			= self:newAction(165572, act.cooldowns)		-- 165572 is NOT a spell id. It's the item ID for VIGOR
	act.cooldowns.feral_frenzy 		= self:newAction(274837, act.cooldowns)
	act.cooldowns.incarnation 		= self:newAction(102543, act.cooldowns)
	act.cooldowns.shadowmeld 		= self:newAction(58984, act.cooldowns)
	
	act.finishers = {}
	act.finishers.savage_roar 		= self:newAction(52610, act.finishers)
	act.finishers.primal_wrath 		= self:newAction(285381, act.finishers)
	act.finishers.primal_wrath2 	= self:newAction(285381, act.finishers)
	act.finishers.rip 				= self:newAction(1079, act.finishers)
	act.finishers.rip2 				= self:newAction(1079, act.finishers)
	act.finishers.rip3 				= self:newAction(1079, act.finishers)
	act.finishers.savage_roar2 		= self:newAction(52610, act.finishers)
	act.finishers.maim 				= self:newAction(22570, act.finishers)
	act.finishers.ferocious_bite 	= self:newAction(22568, act.finishers)
	
	act.generators = {}
	act.generators.regrowth 		= self:newAction(8936, act.generators)
	act.generators.regrowth2 		= self:newAction(8936, act.generators)
	act.generators.brutal_slash 	= self:newAction(202028, act.generators)
	act.generators.thrash_cat 		= self:newAction(106830, act.generators)
	act.generators.thrash_cat2 		= self:newAction(106830, act.generators)
	act.generators.swipe_cat 		= self:newAction(106785, act.generators)
	act.generators.rake 			= self:newAction(1822, act.generators)
	act.generators.rake2 			= self:newAction(1822, act.generators)
	act.generators.moonfire_cat 	= self:newAction(8921, act.generators)
	act.generators.brutal_slash2 	= self:newAction(202028, act.generators)
	act.generators.moonfire_cat2 	= self:newAction(8921, act.generators)
	act.generators.thrash_cat3 		= self:newAction(106830, act.generators)
	act.generators.thrash_cat4 		= self:newAction(106830, act.generators)
	act.generators.swipe_cat2 		= self:newAction(106785, act.generators)
	act.generators.shred 			= self:newAction(5221, act.generators)
	
	--act.opener.tigers_fury = self:newAction()
	--act.opener.rake = self:newAction()
end

function DruidFeral:updateAllActions()
	local var = self.variables
	local act = self.actions
	
	-- main / pre-combat action list
	self:updateAction(act.main.prowl, 					not var.buff.prowl.up)
	self:updateAction(act.main.cat_form, 				not var.buff.cat_form.up)
	self:updateAction(act.main.rake, 				  {	var.buff.prowl.up or var.buff.shadowmeld.up, var.targets < 8 } )
	self:updateAction(act.main.ferocious_bite, 		  {	not var.disable_finisher, var.cp >= 1, var.dot.rip.up, 
														(var.dot.rip.remain or 0) < 3, var.ttk > 10, var.talent.sabertooth})
	self:updateAction(act.main.regrowth, 			  {	(var.cp == 5) , var.buff.predatory_swiftness.up, var.talent.bloodtalons, 
														not var.buff.bloodtalons.up, 
														not var.buff.incarnation.up or var.dot.rip.remain < 8})

	-- cooldown action list		
	self:updateAction(act.cooldowns.berserk, 		  {	var.energy > 30, 
														var.cooldown.tigers_fury.remain > 5 or var.buff.tigers_fury.up})
	self:updateAction(act.cooldowns.tigers_fury, 		var.energy_max - var.energy > ( var.buff.tigers_fury.up and 60 or 50 ) )
	self:updateAction(act.cooldowns.vigor, _,		    var.buff.vigor_engaged.stack == 6 and var.cooldown.vigor.up and var.ttk > 0 )
	self:updateAction(act.cooldowns.feral_frenzy, 		var.cp == 0)
	self:updateAction(act.cooldowns.incarnation, 	  {	var.energy > 30, var.cooldown.tigers_fury.remain > 15 or var.buff.tigers_fury.up})
	self:updateAction(act.cooldowns.shadowmeld, 	  {	var.cp < 5, var.energy >= 35, var.multiplier.rip < 2.1, 
														var.buff.tigers_fury.up, 
														(var.buff.bloodtalons.up or not var.talent.bloodtalons), 
														(not var.talent.incarnation or var.cooldown.incarnation.remain > 18), 
														not var.buff.incarnation.up })

													
	-- finishers action list
	self:updateAction(act.finishers.savage_roar, 		not var.buff.savage_roar.up)
	self:updateAction(act.finishers.primal_wrath, 	  {	var.targets > 2 or var.targets_high_health > 1, 
														var.dot.rip.remain < 4 or 
														(var.targets - var.count.primal_wrath.waste >= math.max(2, var.targets * 0.4)) })
	self:updateAction(act.finishers.primal_wrath2, 	  {	var.targets > 4, var.talent.bloodtalons})
	self:updateAction(act.finishers.rip, 			  {	not var.dot.rip.up, var.ttk > 8,  
														(var.targets_high_health <= 1) or not var.talent.primal_wrath })
	self:updateAction(act.finishers.rip2, 			  {	var.dot.rip.refreshable, var.ttk > 8, 
														(var.targets_high_health <= 1) or not var.talent.primal_wrath, 
														not var.talent.sabertooth })
	self:updateAction(act.finishers.rip3, 			  {	var.talent.sabertooth, var.dot.rip.remain < 20 or var.buff.tigers_fury.up, 
														(var.targets_high_health <= 1) or not var.talent.primal_wrath, 
														var.new_multiplier_rip > var.multiplier.rip, 
														var.buff.bloodtalons.up, var.ttk > 8})
	self:updateAction(act.finishers.savage_roar2, 		var.buff.savage_roar.remain < 12)
	self:updateAction(act.finishers.maim, 				var.buff.iron_jaws.up)
	self:updateAction(act.finishers.ferocious_bite)
	
	-- keep swiping for aoe, even at 5 cp
	if var.targets > 4 and var.cp == 5 and 
		var.talent.moment_of_clarity and var.azerite.wild_fleshrending and 
		not act.finishers.primal_wrath.triggered and not act.finishers.primal_wrath2.triggered then 
		var.disable_finisher = true	
	else
		var.disable_finisher = false
	end
	
	-- generators action list
	self:updateAction(act.generators.regrowth, 		  {	var.talent.bloodtalons, var.buff.predatory_swiftness.up, 
														not var.buff.bloodtalons.up, var.cp == 4, var.dot.rake.remain < 4})
	self:updateAction(act.generators.regrowth2, 	  {	var.talent.bloodtalons, var.buff.predatory_swiftness.up, 
														not var.buff.bloodtalons.up, var.talent.lunar_inspiration, 
														var.dot.rake.remain < 1})
	self:updateAction(act.generators.brutal_slash, 		var.targets > 2)
	self:updateAction(act.generators.thrash_cat, 	  {	var.dot.thrash.refreshable or 
														(var.targets - var.count.thrash.waste >= math.max(1, var.targets * 0.4)), 
														var.targets > 2, 
														not var.buff.scent_of_blood.up or not var.dot.thrash.up})
	self:updateAction(act.generators.thrash_cat2, 	  {	var.talent.scent_of_blood, not var.buff.bloodtalons.up, 
														not var.buff.scent_of_blood.up or not var.dot.thrash.up, var.targets > 3})
	self:updateAction(act.generators.swipe_cat, 	  {	not var.talent.brutal_slash, var.buff.scent_of_blood.up})
	self:updateAction(act.generators.rake, 			  {	var.targets <= 3, var.ttk > 6, not var.dot.rake.up or
														(not var.talent.bloodtalons and var.dot.rake.refreshable and 
														var.new_multiplier_rake > var.multiplier.rake * 0.85)})
	self:updateAction(act.generators.rake2, 		  {	var.targets <= 3, var.new_multiplier_rake > var.multiplier.rake * 0.85,
														var.talent.bloodtalons, var.buff.bloodtalons.up, 
														var.dot.rake.remain < 7, var.ttk > 6})
	self:updateAction(act.generators.moonfire_cat, 	  {	var.talent.lunar_inspiration, var.buff.bloodtalons.up, 
														not var.buff.predatory_swiftness.up, var.cp < 5})
	self:updateAction(act.generators.brutal_slash2, 	var.buff.tigers_fury.up )
	self:updateAction(act.generators.moonfire_cat2,   {	var.talent.lunar_inspiration, var.dot.moonfire.refreshable})
	self:updateAction(act.generators.thrash_cat3, 	  {	var.dot.thrash.refreshable or 
														(var.targets - var.count.thrash.waste >= math.max(1, var.targets * 0.4)), 
														not var.buff.bloodtalons.up, 
														((var.azerite.wild_fleshrending and 
														(not var.buff.incarnation.up or var.azerite.wild_fleshrending)) or 
														var.targets > 1) })
	self:updateAction(act.generators.thrash_cat4, 	  {	var.dot.thrash.refreshable, not var.azerite.wild_fleshrending, 
														var.buff.clearcasting.up, not var.buff.bloodtalons.up, 
														(not var.buff.incarnation.up or var.azerite.wild_fleshrending)})
	self:updateAction(act.generators.swipe_cat2, 	  {	not var.talent.brutal_slash, var.targets > 1} )
	self:updateAction(act.generators.shred, 			(var.dot.rake.remain > (65 - var.energy)) or var.buff.clearcasting.up )
end

function DruidFeral:updateVariables()
	local var = self.variables
	
	var.dt 			= self.spells:timeNextSpell()
	var.energy 		= self.player:power(Enum.PowerType.Energy)
	var.energy_max 	= self.player:powerMax(Enum.PowerType.Energy)
	var.cp 			= self.player:power(Enum.PowerType.ComboPoints)
	
	self.cleave:setLowHealthThreshold(select(2, self.player:dps()) * 4)
	
	var.targets = self.cleave:targets()
	var.targets_low_health = select(5, self.cleave:targets())
	var.targets_high_health = var.targets - var.targets_low_health
	
	var.ttk = self.player:timeToKill()
	var.ttk_effective = var.ttk * math.min(2, 0.9 + (var.targets == 0 and 0.1 or 0) + var.targets / 10 )
	
	var.azerite = {}
	var.azerite.wild_fleshrending = self.player: getAzeriteRank(359) > 0
	
	var.haste = UnitSpellHaste("player")
	var.energy = math.min(var.energy_max, var.energy + 10 * ( 1 + var.haste/100) * var.dt)
	
	var.talent = var.talent or {}
	var.talent.predator 			= self.talent[1] == 1
	var.talent.sabertooth 			= self.talent[1] == 2
	var.talent.lunar_inspiration 	= self.talent[1] == 3
	var.talent.incarnation 			= self.talent[5] == 3
	var.talent.scent_of_blood 		= self.talent[6] == 1
	var.talent.brutal_slash 		= self.talent[6] == 2
	var.talent.primal_wrath 		= self.talent[6] == 3
	var.talent.moment_of_clarity 	= self.talent[7] == 1
	var.talent.bloodtalons 			= self.talent[7] == 2
	
	var.cooldown = var.cooldown or {}
	var.cooldown.tigers_fury 		= self.spells:cooldown(5217)
	var.cooldown.berserk 			= self.spells:cooldown(106951)
	var.cooldown.incarnation 		= self.spells:cooldown(102543)
	var.cooldown.vigor				= self.spells:itemCooldown(165572)
	
	var.buff = var.buff or {}
	var.buff.prowl 					= self.spells:buff(5215)
	var.buff.shadowmeld 			= self.spells:buff(58984)
	var.buff.cat_form 				= self.spells:buff(768)
	var.buff.predatory_swiftness 	= self.spells:buff(69369)
	var.buff.bloodtalons 			= self.spells:buff(145152)
	var.buff.incarnation 			= self.spells:buff(102543)
	var.buff.tigers_fury 			= self.spells:buff(5217)
	var.buff.berserk 				= self.spells:buff(106951)
	var.buff.scent_of_blood 		= self.spells:buff(285646)
	var.buff.clearcasting 			= self.spells:buff(135700)
	var.buff.iron_jaws 				= self.spells:buff(276021)
	var.buff.savage_roar 			= self.spells:buff(52610)
	var.buff.vigor_engaged			= self.spells:buff(287916)
	
	var.dot = var.dot or {}
	var.dot.rip 					= self.spells:dot(1079, (var.cp + 1) * 4)
	var.dot.rake 					= self.spells:dot(155722, 15)
	var.dot.thrash 					= self.spells:dot(106830, 15)
	var.dot.moonfire 				= self.spells:dot(164812, 16)
	
	var.count = var.count or {}
	var.count.rake 					= self.spells:dotCount(155722, 15)
	var.count.thrash 				= self.spells:dotCount(106830, 15)
	var.count.primal_wrath 			= self.spells:dotCount(1079, (var.cp + 1) * 2)
	
	var.recent = var.recent or {}
	var.recent.rip					= self.spells:recentCast(1079)
	var.recent.rake 				= self.spells:recentCast(1822)
	var.recent.thrash	 			= self.spells:recentCast(106830)
	var.recent.primal_wrath			= self.spells:recentCast(285381)
	var.recent.shred				= self.spells:recentCast(5221)
	var.recent.swipe				= self.spells:recentCast(106785)
	
	--------------------
	-- The following is specific to Feral Druid
	-- Detects the multipliers of the present dots
	
	-- "new" multiplier is the current multiplier (if applying a new dot)
	-- not the multiplier on a present dot
	var.new_multiplier_rip			= ( var.buff.tigers_fury.up and 1.15 or 1 ) * ( var.buff.bloodtalons.up and 1.25 or 1 )
	var.new_multiplier_thrash 		= var.new_multiplier_rip
	var.new_multiplier_rake 		= var.new_multiplier_rip * ( var.buff.prowl.up and 2 or 1 )
	
	var.multiplier 					= var.multiplier or {}
	
	local dot_handle = self.spells:getDotHandle("target")
	if dot_handle then 
		var.multiplier.rip = dot_handle:get("multiplier", 1079) or 1
		var.multiplier.rake = dot_handle:get("multiplier", 155722) or 1
		var.multiplier.thrash = dot_handle:get("multiplier", 106830) or 1
	end
	
	var.multiplier.rip 				= var.dot.rip.up and var.multiplier.rip or 0
	var.multiplier.rake 			= var.dot.rake.up and var.multiplier.rake or 0
	var.multiplier.thrash 			= var.dot.thrash.up and var.multiplier.thrash or 0

	--printTable(var.multiplier)
end

function DruidFeral:updateDotMultipliers()
	local var = self.variables
	if not var.recent then return nil end
	
	local _, recent_rake = self.spells:recentCast(1822)
	for i, v in ipairs(recent_rake) do 
		local dot_handle = self.spells:getDotHandleByGuid(v.dest_guid)
		local multiplier
		multiplier 		= self.spells:auraUp(5217, v.time) and 1.15 or 1
		multiplier 		= multiplier * (self:doesSpellCastRemoveAura(v, 145152) and 1.25 or 1)
		multiplier 		= multiplier * (self:doesSpellCastRemoveAura(v, 5215) and 2 or 1)
		if dot_handle then 
			dot_handle:update("multiplier", 155722, multiplier)
		end
	end
	
	local _, recent_rip = self.spells:recentCast(1079)
	for i, v in ipairs(recent_rip) do 
		local dot_handle = self.spells:getDotHandleByGuid(v.dest_guid)
		local multiplier
		multiplier 			= self.spells:auraUp(5217, v.time) and 1.15 or 1
		multiplier 			= multiplier * (self:doesSpellCastRemoveAura(v, 145152) and 1.25 or 1)
		if dot_handle then 
			dot_handle:update("multiplier", 1079, multiplier)
		end
	end
	
	-- There should be a better way to deal with aoe-type dots
	--
	-- The current strategy is to track SPELL_CAST_SUCCESS logs to get targets
	-- AOE spell doesn't have target info in SPELL_CAST_SUCCESS logs
	-- (only one SPELL_CAST_SUCCESS per aoe cast)
	-- Instead, SPELL_DAMAGE logs from the initial hit may contain target info
	-- (multiple SPELL_DAMAGE per aoe cast)
	--
	-- Need to implement "recentAoeCast" in SpellStatus to solve this issue. 
	-- For now, aoe-type dots will change multipliers for all nearby enemies
	
	local _, recent_primal_wrath = self.spells:recentCast(285381)
	for i, v in ipairs(recent_primal_wrath) do 
		local dot_handle = self.spells:getDotHandleByGuid(v.dest_guid)
		local multiplier
		multiplier 			= self.spells:auraUp(5217, v.time) and 1.15 or 1
		multiplier 			= multiplier * (self:doesSpellCastRemoveAura(v, 145152) and 1.25 or 1)
		
		for i = 1, 40 do
			local unit = "nameplate"..i
			if UnitExists(unit) then
				if UnitCanAttack("player", unit) then 
					if IsItemInRange(32321, unit) then 
						local dot_handle = self.spells:getDotHandleByGuid(UnitGUID(unit))
						if dot_handle then 
							dot_handle:update("multiplier", 1079, multiplier)
						end
					end
				end
			end
		end
	end
	
	local _, recent_thrash = self.spells:recentCast(106830)
	for i, v in ipairs(recent_thrash) do 
		local dot_handle = self.spells:getDotHandleByGuid(v.dest_guid)
		local multiplier
		multiplier		= self.spells:auraUp(5217, v.time) and 1.15 or 1
		multiplier 		= multiplier * (self:doesSpellCastRemoveAura(v, 145152) and 1.25 or 1)
		
		for i = 1, 40 do
			local unit = "nameplate"..i
			if UnitExists(unit) then
				if UnitCanAttack("player", unit) then 
					if IsItemInRange(32321, unit) then 
						local dot_handle = self.spells:getDotHandleByGuid(UnitGUID(unit))
						if dot_handle then 
							dot_handle:update("multiplier", 106830, multiplier)
						end
					end
				end
			end
		end
	end
end

-- nextSpell() will be called on every frame (with timing), by system event
function DruidFeral:nextSpell()	
	
	self:updateVariables()
	self:updateAllActions()
	
	local var = self.variables
	
	local main 			= self:runActionList(self.actions.main)
	local finishers 	= self:runActionList(self.actions.finishers)
	local generators 	= self:runActionList(self.actions.generators)
	local cooldowns 	= self:runActionList(self.actions.cooldowns)
	
	local spell = main or 
				  ((var.cp == 5) and not var.disable_finisher) and finishers 
				  or generators
	
	--printTable(self.actions.cooldowns)
	self:updateIcon(_, spell)	-- '_' for main icon
	if cooldowns == 165572 then 	-- 165572 is the itemId of VIGOR, 133870 is the texture 
		self:updateIcon(self.icon_cooldown, _, _, 133870)
	else
		self:updateIcon(self.icon_cooldown, cooldowns)
	end
	
	--print(var.cooldown.tigers_fury.up and spell == generators )
	if spell and 
		( var.talent.predator and 
		((var.targets_low_health > 0) or (var.ttk < 6 and var.ttk > 0 )) and 
		var.cooldown.tigers_fury.up and ( spell == generators or spell == finishers) or 
		cooldowns == 5217 ) then 
		self:updateIcon(self.icon_tigers_fury_small, 5217)
	else 
		self:updateIcon(self.icon_tigers_fury_small, nil)
	end
	
	-- Turn cleave on/off based on the spells used
	if var.recent.shred.cast and
		self.cleave:targets(true) > 1 and not var.talent.brutal_slash then 
		self.cleave:temporaryDisable(8, var.recent.shred.time)
	end 
	if var.recent.swipe.cast or var.recent.primal_wrath.cast then 
		self.cleave:temporaryDisable(0, math.max(var.recent.swipe.time or 0, var.recent.primal_wrath.time or 0))
	end 
	
	if SR_DEBUG > 1 then 
		self:updateIcon(self.icon_rip, _, _, GetSpellTexture(1079))
		self:updateIcon(self.icon_rake, _, _, GetSpellTexture(1822))
		self:updateIcon(self.icon_thrash, _, _, GetSpellTexture(106830))
		
		self:updateDotIcon(self.icon_rip, 1079, var.dot.rip.refreshable)
		self:updateDotIcon(self.icon_rake, 155722, var.dot.rake.refreshable)
		self:updateDotIcon(self.icon_thrash, 106830, var.dot.thrash.refreshable)
		
		self:setText(self.text_rip, tostring(math.floor(var.multiplier.rip * 100 + 0.5 )).."%")
		self:setText(self.text_rake, tostring(math.floor(var.multiplier.rake * 100 + 0.5 )).."%")
		self:setText(self.text_thrash, tostring(math.floor(var.multiplier.thrash * 100 + 0.5 )).."%")
		
		self:setText(self.text_rip_above, tostring(var.count.primal_wrath.up).."("..tostring(var.count.primal_wrath.refreshable)..")")
		self:setText(self.text_rake_above, tostring(var.count.rake.up).."("..tostring(var.count.rake.refreshable)..")")
		self:setText(self.text_thrash_above, tostring(var.count.thrash.up).."("..tostring(var.count.thrash.refreshable)..")")
	else 
		self:updateIcon(self.icon_rip, nil)
		self:updateIcon(self.icon_rake, nil)
		self:updateIcon(self.icon_thrash, nil)
		
		self:setText(self.text_rip, "")
		self:setText(self.text_rake, "")
		self:setText(self.text_thrash, "")
	end
	
end