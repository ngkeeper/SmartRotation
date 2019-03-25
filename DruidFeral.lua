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
						274837,		--"Feral Frenzy"
						102543,		--"Incarnation: King of the Jungle"
					  }
    spells.cast 	= {	8936, 		--"Regrowth"
					  }		
	spells.cleave 	= {	106785, 	--"Swipe"
						106830, 	--"Thrash"
						205381, 	--"Primal Wrath"
					  }
	spells.melee 	= 5221			--"Shred"	used to scan nearby enemies
					  
	spells.blacklist =	{16953, 		--"Primal Fury"
						}
	
	Specialization:_new(spells)
	
	self:createActions()
	self.cleave:setTimeout(4)
	
	self.icon_cooldown = Specialization:createIcon(106951, 40, -50, 0)
	--self.icon_prowl = Specialization:createIcon(5215, 40, 50, 0)
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
	self:updateAction(act.main.ferocious_bite, {var.dot.rip.up, var.dot.rip.remains or 0 < 3, var.ttk > 10, var.talent.sabertooth})
	self:updateAction(act.main.regrowth, {(var.cp == 5) , var.buff.predatory_swiftness.up, var.talent.bloodtalons, 
										  not var.buff.bloodtalons.up, not var.buff.incarnation.up or var.dot.rip.remain < 8})

	-- cooldown action list									  
	self:updateAction(act.cooldowns.berserk, {var.energy > 30, var.cooldown.tigers_fury.remain > 5 or var.buff.tigers_fury.up})
	self:updateAction(act.cooldowns.tigers_fury, var.energy_max - var.energy > 60 )
	self:updateAction(act.cooldowns.tigers_fury, {var.energy_max - var.energy > 40, var.targets > 2})
	self:updateAction(act.cooldowns.feral_frenzy, var.cp == 0)
	self:updateAction(act.cooldowns.incarnation, {var.energy > 30, var.cooldown.tigers_fury.remain > 15 or var.buff.tigers_fury.up})
	
	-- finishers action list
	self:updateAction(act.finishers.savage_roar, not var.buff.savage_roar.up)
	self:updateAction(act.finishers.primal_wrath, {var.targets > 1, var.dot.rip.remain < 4})
	self:updateAction(act.finishers.primal_wrath2, var.targets >= 2)	-- From Simc, doesn't make sence (same as previuous one)
	self:updateAction(act.finishers.rip, {var.dot.rip.refreshable, not var.talent.sabertooth, var.ttk > 12})
	self:updateAction(act.finishers.savage_roar2, var.buff.savage_roar.remain < 12)
	self:updateAction(act.finishers.maim, var.buff.iron_jaws.up)
	self:updateAction(act.finishers.ferocious_bite)
	
	-- generators action list
	self:updateAction(act.generators.regrowth, {var.talent.bloodtalons, var.buff.predatory_swiftness.up, 
												not var.buff.bloodtalons.up, var.cp == 4, var.dot.rake.remain < 4})
	self:updateAction(act.generators.regrowth2, {var.talent.bloodtalons, var.buff.predatory_swiftness.up, 
												not var.buff.bloodtalons.up, var.talent.lunar_inspiration, var.dot.rake.remain < 1})
	self:updateAction(act.generators.brutal_slash, var.targets > 2)
	self:updateAction(act.generators.thrash_cat, {var.dot.thrash.refreshable, var.targets > 2})
	self:updateAction(act.generators.thrash_cat2, {var.talent.scent_of_blood, not var.buff.scent_of_blood.up, var.targets > 3})
	self:updateAction(act.generators.swipe_cat, var.buff.scent_of_blood.up)
	self:updateAction(act.generators.rake, {var.targets <= 4, not var.dot.rake.up or (not var.talent.bloodtalons and var.dot.rake.refreshable), var.ttk > 6})
	self:updateAction(act.generators.rake2, {var.targets <= 4, var.talent.bloodtalons, var.buff.bloodtalons.up, var.dot.rake.remain < 7, var.ttk > 6})
	self:updateAction(act.generators.moonfire_cat, {var.talent.lunar_inspiration, var.buff.bloodtalons.up, 
													not var.buff.predatory_swiftness.up, var.cp < 5})
	self:updateAction(act.generators.brutal_slash2, {var.buff.tigers_fury.up, var.targets <= 1})
	self:updateAction(act.generators.moonfire_cat2, {var.talent.lunar_inspiration, var.dot.moonfire.refreshable})
	self:updateAction(act.generators.thrash_cat3, {var.dot.thrash.refreshable, ((var.azerite.wild_fleshrending and 
												  (not var.buff.incarnation.up or var.azerite.wild_fleshrending)) or 
												  var.targets > 1)})
	self:updateAction(act.generators.thrash_cat4, {var.dot.thrash.refreshable, not var.azerite.wild_fleshrending, 
												   var.buff.clearcasting.up, 
												  (not var.buff.incarnation.up or var.azerite.wild_fleshrending)})
	self:updateAction(act.generators.swipe_cat2, var.targets > 1 )
	self:updateAction(act.generators.shred, (var.dot.rake.remain > (75 - var.energy - 10)) or var.buff.clearcasting.up)
end

function DruidFeral:updateVariables()
	local var = self.variables
	
	var.dt = self.spells:timeNextSpell()
	var.previous = self.spells:previousCast()
	var.energy = self.player:power(Enum.PowerType.Energy)
	var.energy_max = self.player:powerMax(Enum.PowerType.Energy)
	var.cp = self.player:power(Enum.PowerType.ComboPoints)
	var.ttk = self.player:timeToKill()
	var.targets = self.cleave:targets()
	--print(var.targets)
	var.azerite = {}
	var.azerite.wild_fleshrending = true --self.player: getAzeriteRank(359) > 0
	
	var.haste = UnitSpellHaste("player")
	var.energy = math.min(var.energy_max, var.energy + 10 * ( 1 + var.haste/100) * var.dt)
	
	var.talent = var.talent or {}
	var.talent.sabertooth = self.talent[1] == 2
	var.talent.lunar_inspiration = self.talent[1] == 3
	var.talent.incarnation = self.talent[5] == 3
	var.talent.scent_of_blood = self.talent[6] == 1
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
	
	-- Turn cleave on/off based on the spells used
	if (var.previous.spell == 5221 or var.previous.spell == 22568)  -- if shred or ferocious_bite, diable cleave 
		and var.previous.time ~= var.cleaveSettingsChanged then 
		self.cleave:temporaryDisable(8)	-- temporarily diable cleave for 8 seconds
										-- longest non-shred/bite sequence is (shred)->rip->regrowth->rake->thrash->(shred)
										-- 7*gcd ~ 7.5 seconds, plus some time for energy regeneration
		var.cleaveSettingsChanged = var.previous.time
	end
	if (var.previous.spell == 106785 or var.previous.spell == 285381)  -- if swipe or primal wrath, enable cleave
		and var.previous.time ~= var.cleaveSettingsChanged then 
		self.cleave:temporaryDisable(0)		-- turn cleave back on
		var.cleaveSettingsChanged = var.previous.time
	end
end

-- nextSpell() will be called on every frame (with timing), by system event
function DruidFeral:nextSpell()	
	self:updateVariables()
	self:updateAllActions()
	
	local main = self:runActionList(self.actions.main)
	local finishers = self:runActionList(self.actions.finishers)
	local generators = self:runActionList(self.actions.generators)
	local cooldowns = self:runActionList(self.actions.cooldowns)
	local spell = main or (self.variables.cp == 5) and finishers or generators
	
	--printTable(self.actions.cooldowns)
	self:updateIcon(_, spell)	-- '_' for main icon
	self:updateIcon(self.icon_cooldown, cooldowns)
	--self:updateIcon(self.icon_prowl, 5215, 5215)
end