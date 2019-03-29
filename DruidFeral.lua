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
					  }
    spells.cast 	= {	8936, 		--"Regrowth"
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
					  }

	Specialization:_new(spells)
	
	self:createActions()
	self.cleave:setTimeout(6)
	self.cleave:setLowHealthThreshold(self.player:dps() * 3)
	
	self.icon_cooldown = Specialization:createIcon(106951, 40, -50, 0)
	self.icon_tigers_fury_small = Specialization:createIcon(5217, 25, -12, 12, nil, "HIGH")

end

function DruidFeral:createActions()
	local act = self.actions
	
	act.main = {}
	act.main.prowl = self:newAction(5215, act.main)
	act.main.cat_form = self:newAction(768, act.main)
	act.main.rake = self:newAction(1822, act.main)
	act.main.ferocious_bite = self:newAction(22568, act.main)
	act.main.regrowth = self:newAction(8936, act.main)
	
	act.cooldowns = {}
	act.cooldowns.berserk = self:newAction(106951, act.cooldowns)
	act.cooldowns.tigers_fury = self:newAction(5217, act.cooldowns)
	act.cooldowns.tigers_fury2 = self:newAction(5217, act.cooldowns)
	act.cooldowns.feral_frenzy = self:newAction(274837, act.cooldowns)
	act.cooldowns.incarnation = self:newAction(102543, act.cooldowns)
	--act.cooldowns.shadowmeld = self:newAction(, act.cooldowns)
	
	act.finishers = {}
	act.finishers.savage_roar = self:newAction(52610, act.finishers)
	act.finishers.primal_wrath = self:newAction(285381, act.finishers)
	act.finishers.primal_wrath2 = self:newAction(285381, act.finishers)
	act.finishers.rip = self:newAction(1079, act.finishers)
	act.finishers.rip2 = self:newAction(1079, act.finishers)
	act.finishers.rip3 = self:newAction(1079, act.finishers)
	act.finishers.savage_roar2 = self:newAction(52610, act.finishers)
	act.finishers.maim = self:newAction(22570, act.finishers)
	act.finishers.ferocious_bite = self:newAction(22568, act.finishers)
	
	act.generators = {}
	act.generators.regrowth = self:newAction(8936, act.generators)
	act.generators.regrowth2 = self:newAction(8936, act.generators)
	act.generators.brutal_slash = self:newAction(202028, act.generators)
	act.generators.thrash_cat = self:newAction(106830, act.generators)
	act.generators.thrash_cat2 = self:newAction(106830, act.generators)
	act.generators.swipe_cat = self:newAction(106785, act.generators)
	act.generators.rake = self:newAction(1822, act.generators)
	act.generators.rake2 = self:newAction(1822, act.generators)
	act.generators.moonfire_cat = self:newAction(8921, act.generators)
	act.generators.brutal_slash2 = self:newAction(202028, act.generators)
	act.generators.moonfire_cat2 = self:newAction(8921, act.generators)
	act.generators.thrash_cat3 = self:newAction(106830, act.generators)
	act.generators.thrash_cat4 = self:newAction(106830, act.generators)
	act.generators.swipe_cat2 = self:newAction(106785, act.generators)
	act.generators.shred = self:newAction(5221, act.generators)
	
	--act.opener.tigers_fury = self:newAction()
	--act.opener.rake = self:newAction()
end

function DruidFeral:updateAllActions()
	local var = self.variables
	local act = self.actions
	
	-- main / pre-combat action list
	self:updateAction(act.main.prowl, not var.buff.prowl.up)
	self:updateAction(act.main.cat_form, not var.buff.cat_form.up)
	self:updateAction(act.main.rake, var.buff.prowl.up or var.buff.shadowmeld.up)
	self:updateAction(act.main.ferocious_bite, {not var.disable_finisher, var.cp >= 1, var.dot.rip.up, (var.dot.rip.remain or 0) < 3, var.ttk > 10, var.talent.sabertooth})
	self:updateAction(act.main.regrowth, {(var.cp == 5) , var.buff.predatory_swiftness.up, var.talent.bloodtalons, 
										  not var.buff.bloodtalons.up, not var.buff.incarnation.up or var.dot.rip.remain < 8})

	-- cooldown action list		
	self:updateAction(act.cooldowns.berserk, {var.energy > 30, var.cooldown.tigers_fury.remain > 5 or var.buff.tigers_fury.up})
	self:updateAction(act.cooldowns.tigers_fury, var.energy_max - var.energy > 60 )
	--self:updateAction(act.cooldowns.tigers_fury2, {var.energy_max - var.energy > 50, var.targets > 2})
	self:updateAction(act.cooldowns.feral_frenzy, var.cp == 0)
	self:updateAction(act.cooldowns.incarnation, {var.energy > 30, var.cooldown.tigers_fury.remain > 15 or var.buff.tigers_fury.up})
	
	-- finishers action list
	self:updateAction(act.finishers.savage_roar, not var.buff.savage_roar.up)
	self:updateAction(act.finishers.primal_wrath, {var.targets > 1, var.dot.rip.remain < 4})
	self:updateAction(act.finishers.primal_wrath2, {var.targets > 1, var.talent.bloodtalons})
	self:updateAction(act.finishers.rip, {not var.dot.rip.up, var.ttk > 8})
	self:updateAction(act.finishers.rip2, {var.dot.rip.refreshable, not var.talent.sabertooth, var.ttk > 8})
	self:updateAction(act.finishers.rip3, {var.dot.rip.remain < 20, var.multiplier.rip == 1, var.buff.bloodtalons.up, var.ttk > 8})
	self:updateAction(act.finishers.savage_roar2, var.buff.savage_roar.remain < 12)
	self:updateAction(act.finishers.maim, var.buff.iron_jaws.up)
	self:updateAction(act.finishers.ferocious_bite)
	
	-- keep swiping for aoe, even at 5 cp
	if var.targets > 1 and var.cp == 5 and 
		var.talent.moment_of_clarity and var.azerite.wild_fleshrending and 
		not act.finishers.primal_wrath.triggered and not act.finishers.primal_wrath2.triggered then 
		var.disable_finisher = true	
	else
		var.disable_finisher = false
	end
	
	-- generators action list
	self:updateAction(act.generators.regrowth, {var.talent.bloodtalons, var.buff.predatory_swiftness.up, 
												not var.buff.bloodtalons.up, var.cp == 4, var.dot.rake.remain < 4})
	self:updateAction(act.generators.regrowth2, {var.talent.bloodtalons, var.buff.predatory_swiftness.up, 
												not var.buff.bloodtalons.up, var.talent.lunar_inspiration, var.dot.rake.remain < 1})
	self:updateAction(act.generators.brutal_slash, var.targets > 2)
	self:updateAction(act.generators.thrash_cat, {var.dot.thrash.refreshable, not var.buff.bloodtalons.up, var.targets > 2})
	self:updateAction(act.generators.thrash_cat2, {var.talent.scent_of_blood, not var.buff.bloodtalons.up, 
												   not var.buff.scent_of_blood.up, var.targets > 3})
	self:updateAction(act.generators.swipe_cat, {not var.talent.brutal_slash, var.buff.scent_of_blood.up})
	self:updateAction(act.generators.rake, {var.targets <= 3, var.ttk > 6, not var.dot.rake.up or
											(not var.talent.bloodtalons and var.dot.rake.refreshable and var.multiplier.rake < 2)})
	self:updateAction(act.generators.rake2, {var.targets <= 3, var.multiplier.rake <= 1.25,
											 var.talent.bloodtalons, var.buff.bloodtalons.up, var.dot.rake.remain < 7, var.ttk > 6})
	self:updateAction(act.generators.moonfire_cat, {var.talent.lunar_inspiration, var.buff.bloodtalons.up, 
													not var.buff.predatory_swiftness.up, var.cp < 5})
	self:updateAction(act.generators.brutal_slash2, {var.buff.tigers_fury.up, var.targets <= 1})
	self:updateAction(act.generators.moonfire_cat2, {var.talent.lunar_inspiration, var.dot.moonfire.refreshable})
	self:updateAction(act.generators.thrash_cat3, {var.dot.thrash.refreshable, not var.buff.bloodtalons.up, 
												  ((var.azerite.wild_fleshrending and 
												  (not var.buff.incarnation.up or var.azerite.wild_fleshrending)) or 
												  var.targets > 1)})
	self:updateAction(act.generators.thrash_cat4, {var.dot.thrash.refreshable, not var.azerite.wild_fleshrending, 
												   var.buff.clearcasting.up, not var.buff.bloodtalons.up, 
												  (not var.buff.incarnation.up or var.azerite.wild_fleshrending)})
	self:updateAction(act.generators.swipe_cat2, {not var.talent.brutal_slash, var.targets > 1} )
	self:updateAction(act.generators.shred, (var.dot.rake.remain > (75 - var.energy - 10)) or var.buff.clearcasting.up)
end

function DruidFeral:updateVariables()
	local var = self.variables
	
	var.dt = self.spells:timeNextSpell()
	var.energy = self.player:power(Enum.PowerType.Energy)
	var.energy_max = self.player:powerMax(Enum.PowerType.Energy)
	var.cp = self.player:power(Enum.PowerType.ComboPoints)
	var.ttk = self.player:timeToKill()
	var.targets = self.cleave:targets()
	var.targets_low_health = self.cleave:targetsLowHealth()
	
	var.azerite = {}
	var.azerite.wild_fleshrending = self.player: getAzeriteRank(359) > 0
	
	var.haste = UnitSpellHaste("player")
	var.energy = math.min(var.energy_max, var.energy + 10 * ( 1 + var.haste/100) * var.dt)
	
	var.talent = var.talent or {}
	var.talent.predator = self.talent[1] == 1
	var.talent.sabertooth = self.talent[1] == 2
	var.talent.lunar_inspiration = self.talent[1] == 3
	var.talent.incarnation = self.talent[5] == 3
	var.talent.scent_of_blood = self.talent[6] == 1
	var.talent.brutal_slash = self.talent[6] == 2
	var.talent.moment_of_clarity = self.talent[7] == 1
	var.talent.bloodtalons = self.talent[7] == 2
	
	var.cooldown = var.cooldown or {}
	var.cooldown.tigers_fury = self.spells:cooldown(5217)
	var.cooldown.berserk = self.spells:cooldown(106951)
	
	var.buff = var.buff or {}
	var.buff.prowl = self.spells:buff(5215)
	var.buff.shadowmeld = self.spells:buff(58984)
	var.buff.cat_form = self.spells:buff(768)
	var.buff.predatory_swiftness = self.spells:buff(69369)
	var.buff.bloodtalons = self.spells:buff(145152)
	var.buff.incarnation = self.spells:buff(102543)
	var.buff.tigers_fury = self.spells:buff(5217)
	var.buff.berserk = self.spells:buff(106951)
	var.buff.scent_of_blood = self.spells:buff(285646)
	var.buff.clearcasting = self.spells:buff(135700)
	var.buff.iron_jaws = self.spells:buff(276021)
	var.buff.savage_roar = self.spells:buff(52610)
	
	var.dot = var.dot or {}
	var.dot.rip = self.spells:dot(1079, (var.cp + 1) * 4)
	var.dot.rake = self.spells:dot(155722, 15)
	var.dot.thrash = self.spells:dot(106830, 15)
	var.dot.moonfire = self.spells:dot(164812, 16)
	
	local prowl_rake = self:doesSpellRemoveAura(1822, 5215)
	local bloodtalons_rip = self:doesSpellRemoveAura(1079, 145152)
	local bloodtalons_rake = self:doesSpellRemoveAura(1822, 145152)
	local bloodtalons_thrash = self:doesSpellRemoveAura(106830, 145152)
	
	var.multiplier = var.multiplier or {}
	var.multiplier.rip = var.multiplier.rip or 1
	var.multiplier.rake = var.multiplier.rake or 1
	var.multiplier.thrash = var.multiplier.thrash or 1
	
	if bloodtalons_rip then 
		var.multiplier.rip = 1 + bloodtalons_rip * 0.25
	end
	
	if prowl_rake and bloodtalons_rake then 
		var.multiplier.rake = ( 1 + prowl_rake ) * ( 1 + bloodtalons_rake * 0.25 )
	elseif prowl_rake then 
		var.multiplier.rake = 1 + prowl_rake
	elseif bloodtalons_rake then 
		var.multiplier.rake = 1 + bloodtalons_rake * 0.25
	end
	
	if bloodtalons_thrash then 
		var.multiplier.thrash = 1 + bloodtalons_thrash * 0.25
	end
	
	var.multiplier.rip = var.dot.rip.up and var.multiplier.rip or 0
	var.multiplier.rake = var.dot.rake.up and var.multiplier.rake or 0
	var.multiplier.thrash = var.dot.thrash.up and var.multiplier.thrash or 0
	--print(prowl_rake)
	--printTable(var.multiplier)
	
end

-- nextSpell() will be called on every frame (with timing), by system event
function DruidFeral:nextSpell()	

	-- Turn cleave on/off based on the spells used
	local shredCast, shredTime = self.spells:recentlyCast(5221)
	if shredCast and not self.variables.talent.brutal_slash then 
		self.cleave:temporaryDisable(8, shredTime)
	end 
	local swipeCast, swipeTime = self.spells:recentlyCast(106785)
	if swipeCast then 
		self.cleave:temporaryDisable(0, swipeTime)
	end 
	
	self:updateVariables()
	self:updateAllActions()
	
	local main = self:runActionList(self.actions.main)
	local finishers = self:runActionList(self.actions.finishers)
	local generators = self:runActionList(self.actions.generators)
	local cooldowns = self:runActionList(self.actions.cooldowns)
	local spell = main or 
				  ((self.variables.cp == 5) and not self.variables.disable_finisher) and finishers 
				  or generators
	
	--printTable(self.actions.cooldowns)
	self:updateIcon(_, spell)	-- '_' for main icon
	self:updateIcon(self.icon_cooldown, cooldowns)
	
	--print(self.variables.cooldown.tigers_fury.up and spell == generators )
	if self.variables.talent.predator and spell and
		((self.variables.targets_low_health > 0) or (self.variables.ttk < 6 and self.variables.ttk > 0 ))
		and self.variables.cooldown.tigers_fury.up and ( spell == generators or spell == finishers) then 
		self:updateIcon(self.icon_tigers_fury_small, 5217)
	else 
		self:updateIcon(self.icon_tigers_fury_small, nil)
	end
	
	-- local str = tostring(self.cleave:targets()) .." "..tostring( self.cleave:targetsLowHealth())
	-- self.text:SetText(str)
end