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
	local spells.gcd 	= 	8921 		--"Moonfire"    -- can be any zero-cooldown spell
	local spells.buff 	= { 768,		--"Cat Form"
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
    local spells.dot 	= {	1079,		--"Rip"
							155722,		--"Rake"
							106830,		--"Thrash"
							164812,		--"Moonfire"
						  }
    local spells.cd 	= {	202425, 	--"Warrior of Elune"
							102560, 	--"Incarnation"
							194223, 	--"Celestial Alignment"
							211545, 	--"Fury of Elune"
							205636,		--"Force of Nature"
							274281, 	--"New Moon"
							274282, 	--"Half Moon"
							274283,		--"Full Moon" 
						  }
    local spells.cast 	= {	8936, 		--"Regrowth"
						  }
	local spells.cleave = {	106785, 	--"Swipe"
							106830, 	--"Thrash"
							205381, 	--"Primal Wrath"
						  }
	
	Specialization:_new(spells)
	
	self:createActions()
	
	self.icon_berserk = self:createIcon(106951, 40, -50, 0, true)
end

function DruidFeral:createActions()
	local act = self.actions
	
	act.main.cat_form = self:newAction(768)
	act.main.rake = self:newAction(1822)
	act.main.ferocious_bite = self:newAction(22568)
	act.main.regrowth = self:newAction(8936)

	act.finishers.savage_roar = self:newAction(52610)
	act.finishers.primal_wrath = self:newAction(285381)
	--act.finishers.primal_wrath2 = self:newAction(285381)
	act.finishers.rip = self:newAction(1079)
	act.finishers.savage_roar2 = self:newAction(52610)
	act.finishers.maim = self:newAction(22570)
	act.finishers.ferocious_bite = self:newAction(22568)
	
	act.generators.regrowth = self:newAction(8936)
	act.generators.brutal_slash = self:newAction(202028)
	act.generators.thrash_cat = self:newAction(106830)
	act.generators.thrash_cat2 = self:newAction(106830)
	act.generators.swipe_cat = self:newAction(106785)
	act.generators.rake = self:newAction(1822)
	act.generators.rake2 = self:newAction(1822)
	act.generators.moonfire_cat = self:newAction(8921)
	act.generators.brutal_slash2 = self:newAction(202028)
	act.generators.moonfire_cat2 = self:newAction(8921)
	act.generators.thrash_cat3 = self:newAction(106830)
	act.generators.thrash_cat4 = self:newAction(106830)
	act.generators.swipe_cat2 = self:newAction(106785)
	act.generators.shred = self:newAction(5221)
	
	--act.opener.tigers_fury = self:newAction()
	--act.opener.rake = self:newAction()
end

function DruidFeral:updateAllActions()
	local var = self.variables
	local act = self.actions
	
	self:updateAction(act.finishers.savage_roar, not var.buff.savage_roar.up)
	self:updateAction(act.finishers.primal_wrath, {var.targets > 1, var.dot.rip.remain < 4})
	--self:updateAction(act.finishers.primal_wrath2, var.targets >= 2)	-- From Simc, doesn't make sence
	self:updateAction(act.finishers.rip, {var.dot.rip.refreshable, not var.talent.sabertooth, var.ttk > 8})
	self:updateAction(act.finishers.savage_roar2, var.buff.savage_roar.remain < 12)
	self:updateAction(act.finishers.maim, var.buff.iron_jaws.up)
	
end

function DruidFeral:updateVariables()
	local var = self.variables
	
	var.energy = self.player:power(Enum.PowerType.Energy)
	var.cp = self.player:power(Enum.PowerType.ComboPoints)
	var.ttk = self.player:timeToKill()
	var.targets = self.cleave:targetsHit()
	
	var.talent = var.talent or {}
	var.talent.sabertooth = self.talent[1] == 2
	var.talent.lunar_inspiration = self.talent[1] == 3
	var.talent.incarnation = self.talent[5] == 3
	var.talent.scent_of_blood = self.talent[6] == 1
	var.talent.bloodtalons = self.talent[7] == 2
	
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
	
	var.dot.rip = self.spells:dot(1079)
	var.dot.rake = self.spells:dot(155722)
	var.dot.thrash = self.spells:dot(106830)
	var.dot.moonfire = self.spells:dot(164812)
	
end