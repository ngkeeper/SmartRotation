-- Spell
-- =======================
-- flamestrike		2120
-- pyroblast		11366
-- fire_blast		108853
-- phoenix_flames	257541
-- dragons_breath	31661
-- scorch			2948
-- fireball			133
-- living_bomb		44457
-- meteor			153561


-- Buff
-- =======================
-- Heating Up 		48107
-- Hot Streak		48108
-- Blaster Master	274598
-- Pyroclasm		269651
-- Combustion		190319
-- Rune of Power	116014

MageFire = {}
MageFire.__index = MageFire

setmetatable(MageFire, {
  __index = Specialization, -- inherit from the Specialization class
  __call = function (class, ...)
    local self = setmetatable({}, class)
    self:_new(...)
    return self
  end,
})

function MageFire:_new()
	local spells = {}
	
	spells.gcd 		= 	1459 		--"Arcane Intellect"    -- can be any zero-cooldown spell
	
	spells.buff 	= { 48107,		--"Heating Up"
						48108,		--"Hot Streak"
						274598,		--"Blaster Master"
						269651,		--"Pyroclasm"
						190319,		--"Combustion"
						116014,		--"Rune of Power"
						298357, 	--"Memory of Lucid Dreams"
					  }	
					  
    spells.dot 		= {	12654 }		--"Ignite"
	
    spells.cd 		= {	108853, 	--"Fire Blast"
						257541, 	--"Phoenix Flames"
						31661, 		--"Dragons Breath"
						44457, 		--"Living Bomb"
						153561, 	--"Meteor"
						190319, 	--"Combustion"
						116011, 	--"Rune of Power"
					  }
						  
	
	-- spells that cause cleave damage (and use them as aoe indicators)
	spells.cleave 	= {	205345,		--"Conflagration Flare Up"
						2120,		--"Flame Strike"
						153564,		--"Meteor"
					  }
					  
	-- spells that need to be traced in the combat log
	spells.trace 	= { 133, 		--"Fireball"
						2948, 		--"Scorch"
						108853, 	--"Fire Blast"
						153561, 	--"Meteor"
						11366, 		--"Pyroblast"
						2120, 		--"Flame Strike"
					  }
					  
	Specialization._new(self, spells)
	
	self:createActions()
	self.cleave:setTimeout(6)
	
	self.icon_cooldown 		= self:createIcon(nil, 35, 60, 0)
	self.icon_combustion 	= self:createIcon(190319, 35, -90, 0)
	self.icon_rop 			= self:createIcon(116011, 35, -50, 0)
	self.icon_fire_blast	= self:createIcon(108853, 35, 50, 0)
	self.icon_small 		= self:createIcon(nil, 30, 0, 41)
	self.icon_small_2 		= self:createIcon(nil, 25, 0, 69)
	--self:iconCooldownColor(self.icon_rop, 0.5, 1, 0, 0.5)
	self.text_debug 		= self:createText(self.icon)
	self.text_rop 			= self:createText(self.icon_rop, 20, 11, -10)
	self.text_fire_blast	= self:createText(self.icon_fire_blast, 18, 12, -10)
end


function MageFire:createActions()
	local act = self.actions
	
	act.main 			= {}
	act.rop 			= {}
	act.comb			= {}
	act.comb_bm			= {}
	act.standard		= {}
	act.misc			= {}
	
	-- Use arcane intellect to check if player can cast spells	
	act.misc.arcane_intellect		= self:newAction(1459, act.misc)
	
	act.main.fire_blast				= self:newAction(108853, act.main)
	act.main.rune_of_power			= self:newAction(116011, act.main)
	
	act.standard.flamestrike 		= self:newAction(2120, act.standard)
	act.standard.pyroblast 			= self:newAction(11366, act.standard)
	act.standard.pyroblast_2		= self:newAction(11366, act.standard)
	act.standard.pyroblast_3 		= self:newAction(11366, act.standard)
	act.standard.pyroblast_4 		= self:newAction(11366, act.standard)
	act.standard.fire_blast 		= self:newAction(108853, act.standard)
	act.standard.fire_blast_2		= self:newAction(108853, act.standard)
	act.standard.pyroblast_5		= self:newAction(11366, act.standard)
	act.standard.phoenix_flames		= self:newAction(257541, act.standard)
	act.standard.living_bomb 		= self:newAction(44457, act.standard)
	act.standard.meteor 			= self:newAction(153561, act.standard)
	act.standard.dragons_breath	 	= self:newAction(31661, act.standard)
	act.standard.scorch 			= self:newAction(2948, act.standard)
	act.standard.fireball 			= self:newAction(133, act.standard)
	act.standard.scorch_2 			= self:newAction(2948, act.standard)
	
	act.rop.flamestrike 			= self:newAction(2120, act.rop)
	act.rop.pyroblast 				= self:newAction(11366, act.rop)
	act.rop.fire_blast 				= self:newAction(108853, act.rop)
	act.rop.living_bomb 			= self:newAction(44457, act.rop)
	act.rop.meteor 					= self:newAction(153561, act.rop)
	act.rop.pyroblast_2 			= self:newAction(11366, act.rop)
	act.rop.fire_blast_2			= self:newAction(108853, act.rop)
	act.rop.fire_blast_3			= self:newAction(108853, act.rop)
	act.rop.pyroblast_3				= self:newAction(11366, act.rop)
	act.rop.phoenix_flames 			= self:newAction(257541, act.rop)
	act.rop.scorch 					= self:newAction(2948, act.rop)
	act.rop.dragons_breath 			= self:newAction(31661, act.rop)
	act.rop.flamestrike_2 			= self:newAction(2120, act.rop)
	act.rop.fireball 				= self:newAction(133, act.rop)
	
	act.comb.fire_blast				= self:newAction(108853, act.comb)
	act.comb.rune_of_power			= self:newAction(116011, act.comb)
	act.comb.fire_blast_2			= self:newAction(108853, act.comb)
	act.comb.living_bomb			= self:newAction(44457, act.comb)
	act.comb.meteor					= self:newAction(153561, act.comb)
	act.comb.combustion				= self:newAction(190319, act.comb)
	act.comb.flamestrike			= self:newAction(2120, act.comb)
	act.comb.pyroblast				= self:newAction(11366, act.comb)
	act.comb.pyroblast_2			= self:newAction(11366, act.comb)
	act.comb.phoenix_flames			= self:newAction(257541, act.comb)
	act.comb.scorch					= self:newAction(2948, act.comb)
	act.comb.living_bomb_2			= self:newAction(44457, act.comb)
	act.comb.dragons_breath			= self:newAction(31661, act.comb)
	act.comb.scorch_2				= self:newAction(2948, act.comb)
	act.comb.fireball				= self:newAction(133, act.comb)
end

function MageFire:updateVariables()
	local var = self.variables
	
	var.gcd 					= self.spells:getGcd()
	var.dt						= self.spells:timeNextSpell()
	var.targets 				= self.cleave:targets()
	var.ttk 					= self.player:timeToKill() 
	var.ttk_effective			= var.ttk * math.min(2, 0.9 + (var.targets == 0 and 0.1 or 0) + var.targets / 10 )
	
	var.target_health_percentage = select(3, self.player:unitHealth())
	
	var.distance = select(2, self:getRange("target"))
	var.distance = var.distance or -1
	
	var.azerite_bm = self.player: getAzeriteRank(215) > 0
	
	var.haste = UnitSpellHaste("player")
	
	var.talent = var.talent or {}
	var.talent.firestarter 		= self.talent[1] == 1
	var.talent.searing_torch 	= self.talent[1] == 3
	var.talent.rune_of_power 	= self.talent[3] == 3
	var.talent.flame_on			= self.talent[4] == 1
	var.talent.alexstraszas_fury= self.talent[4] == 2
	var.talent.phoenix_flames 	= self.talent[4] == 3
	var.talent.flame_patch 		= self.talent[6] == 1
	var.talent.kindling 		= self.talent[7] == 1
	
	var.casting = var.casting or {}
	var.casting.meteor 			= self.spells:isCasting(153561)
	var.casting.fireball 		= self.spells:isCasting(133)
	var.casting.scorch 			= self.spells:isCasting(2948)
	var.casting.pyroblast 		= self.spells:isCasting(11366)
	var.casting.phoenix_flames 	= self.spells:isCasting(257541)
	var.casting.rune_of_power 	= self.spells:isCasting(116011)
	
	var.cooldown = var.cooldown or {}
	var.cooldown.combustion 	= self.spells:cooldown(190319)
	var.cooldown.rune_of_power 	= self.spells:cooldown(116011)
	var.cooldown.fire_blast		= self.spells:cooldown(108853)
	var.cooldown.meteor			= self.spells:cooldown(153561)
	var.cooldown.phoenix_flames	= self.spells:cooldown(257541)
	var.cooldown.essence		= self.spells:cooldown(self.essence)
	
	var.buff = var.buff or {}
	var.buff.combustion			= self.spells:buff(190319)
	var.buff.heating_up 		= self.spells:buff(48107)
	var.buff.hot_streak 		= self.spells:buff(48108)
	var.buff.rune_of_power 		= self.spells:buff(116014)
	var.buff.pyroclasm 			= self.spells:buff(269651)
	var.buff.blaster_master 	= self.spells:buff(274598)
	var.buff.lucid_dreams 		= self.spells:buff(298357)
	
	var.rop_start, var.rop_duration = select(3, GetTotemInfo(1))
	var.rop_start = var.rop_start + 0.5 -- There is a ~0.5s delay for no reason
	var.rop_remain = var.rop_start + var.rop_duration - GetTime()
	var.rop_remain = math.max(var.rop_remain, 0)
	
	if var.buff.rune_of_power.up then
		var.buff.rune_of_power.remain = var.rop_remain
	end
	
	var.debuff = var.debuff or {}
	var.debuff.ignite 	= self.spells:dot(12654) 
	
	var.recent = var.recent or {}
	var.recent.meteor			= self.spells:recentCast(153561)
	var.recent.fireball 		= self.spells:recentCast(133)
	var.recent.scorch 			= self.spells:recentCast(2948)
	var.recent.pyroblast 		= self.spells:recentCast(11366)
	var.recent.flamestrike 		= self.spells:recentCast(2120)
	var.recent.phoenix_flames	= self.spells:recentCast(257541)
	
	
	var.recent.fireball.landed	= select(3, self.spells:recentCast(133))
	var.recent.pyroblast.landed	= select(3, self.spells:recentCast(11366))
	var.recent.meteor.landed	= select(3, self.spells:recentCast(153561))
	
	var.previous_cast 			= self.spells:recentCast()
	
	--------------------------------
	-- Fire Mage specific variables
	var.fireball_cast_time 			= 2.25 / ( 1 + var.haste / 100 )
	var.scorch_cast_time 			= 1.5 / ( 1 + var.haste / 100 )
	var.pyroblast_cast_time 		= 4.5 / ( 1 + var.haste / 100 )
	var.fire_blast_recharge_time 	= (10 / ( 1 + var.haste / 100 )) * (var.buff.lucid_dreams.up and 0.5 or 1)
	
	var.fire_blast_max_charge = 2 + (var.talent.flame_on and 1 or 0 )
	var.fire_blast_full_recharge_time = (var.fire_blast_max_charge - var.cooldown.fire_blast.charge_fractional) * var.fire_blast_recharge_time
	
	var.firestarter_active = var.talent.firestarter and ( var.target_health_percentage > 0.9 )
	var.searing_torch_active = var.talent.searing_torch and ( var.target_health_percentage < 0.3 ) and ( var.target_health_percentage > 0 )
	
	var.pyroblast_in_flight = var.recent.pyroblast.cast and not var.recent.pyroblast.landed
	var.fireball_in_flight = var.recent.fireball.cast and not var.recent.fireball.landed
	var.meteor_in_flight = var.recent.meteor.cast and not var.recent.meteor.landed
	
	var.fire_blast_pooling 	  = var.talent.rune_of_power and var.cooldown.rune_of_power.remain < var.fire_blast_full_recharge_time and 
								( var.cooldown.combustion.remain > 60 or var.firestarter_active ) and 
								var.cooldown.rune_of_power.charge > 0 or 
								var.cooldown.combustion.remain < var.fire_blast_full_recharge_time + ( var.azerite_bm and var.fire_blast_recharge_time or 0 ) and
								not var.firestarter_active 
	
	-- Need to be implemented
	var.phoenix_pooling = false
	
	var.living_bomb_conditions = var.targets > 1 and not var.buff.combustion.up and 
								(var.cooldown.combustion.remain > 12 or var.cooldown.combustion.up)
	var.meteor_conditions 	  = ( var.buff.rune_of_power.up or var.casting.rune_of_power ) and 
								( not var.firestarter_active or var.cooldown.rune_of_power.remain > var.ttk) or  
								var.cooldown.rune_of_power.charge < 1 or 
								( var.cooldown.combustion.remain > 45 or var.cooldown.combustion.up ) and 
								not var.talent.rune_of_power and ( not var.talent.firestarter or not var.firestarter_active)
	
	var.enough_fire_blast_for_combustion = ( var.cooldown.fire_blast.charge_fractional + 
											( var.buff.combustion.remain - 3 ) % var.fire_blast_recharge_time - 
											var.buff.combustion.remain % 2.5 >= 0 ) or
											not var.azerite_bm or not var.talent.flame_on or var.buff.combustion.remain <= 3 or 
											var.buff.blaster_master.remain < 0.5
end

function MageFire: updateAllActions()
	local var = self.variables
	local act = self.actions
	
	self:updateAction(act.misc.arcane_intellect)
	
	self:updateAction(act.main.rune_of_power, 	  {	var.firestarter_active or var.cooldown.combustion.remain > 60 and not var.buff.combustion.up, 
													var.cooldown.fire_blast.charge_fractional > 2.5 or 
													var.cooldown.fire_blast.charge_fractional > 1.5 and var.cooldown.meteor.remain < 6
													or var.cooldown.combustion.remain > 105 } )
	self:updateAction(act.main.fire_blast, 		  { self.essence == 298357, var.azerite_bm, 
													var.cooldown.fire_blast.charge == var.fire_blast_max_charge, 
													not var.buff.hot_streak.up, 
													not ( var.buff.heating_up.up and 
													  ( var.buff.combustion.up and 
													    ( var.fireball_in_flight or var.pyroblast_in_flight or var.casting.scorch ) or 
														var.searing_torch_active ) ), 
													not ( not var.buff.heating_up.up and not var.buff.hot_streak.up and 
													  not var.buff.combustion.up and (var.fireball_in_flight or var.pyroblast_in_flight) ) } )
	
	self:updateAction(act.standard.flamestrike,   { var.talent.flame_patch and var.targets > 1 and not var.firestarter_active or var.targets > 4, 
													var.buff.hot_streak.up } )
	self:updateAction(act.standard.pyroblast, 	  { var.buff.hot_streak.up, var.buff.hot_streak.remain < var.fireball_cast_time } )
	self:updateAction(act.standard.pyroblast_2,   { var.buff.hot_streak.up, 
													var.recent.fireball.cast or var.casting.fireball or var.firestarter_active or var.pyroblast_in_flight})
	self:updateAction(act.standard.pyroblast_3,   { var.buff.hot_streak.up, var.searing_torch_active})
	self:updateAction(act.standard.pyroblast_4,   { var.buff.pyroclasm.up, var.pyroblast_cast_time < var.buff.pyroclasm.remain } )
	self:updateAction(act.standard.fire_blast, 	  { not var.cooldown.combustion.up and 
													( not var.buff.rune_of_power.up and not var.casting.rune_of_power) or var.firestarter_active, 
													not var.talent.kindling, not var.fire_blast_pooling, 
													( ( var.casting.fireball or var.casting.pyroblast ) and 
													  ( var.buff.heating_up.up or var.firestarter_active and 
														not var.buff.hot_streak.up and not var.buff.heating_up.up ) ) or  
													( var.searing_torch_active and 
													  ( var.buff.heating_up.up and not var.casting.scorch or
													    not var.buff.hot_streak.up and not var.buff.heating_up.up and var.casting.scorch and 
														not var.pyroblast_in_flight and not var.fireball_in_flight ) ) or 
													var.firestarter_active and ( var.pyroblast_in_flight or var.fireball_in_flight ) and 
													not var.buff.heating_up.up and not var.buff.hot_streak.up })
	self:updateAction(act.standard.fire_blast_2,  { var.talent.kindling, var.buff.heating_up.up, 
													var.cooldown.combustion.remain > 
													var.fire_blast_recharge_time + 2 + ( var.talent.kindling and 1 or 0 ) or 
													( not var.talent.rune_of_power or var.cooldown.rune_of_power.remain > var.ttk and 
													  var.cooldown.rune_of_power.charge < 1 ) and 
													var.cooldown.combustion.remain > var.ttk })
	self:updateAction(act.standard.pyroblast_5,   { var.recent.scorch.cast or var.casting.scorch, var.buff.heating_up.up, var.searing_torch_active, 
													( var.talent.flame_patch and var.targets <= 1 and not var.firestarter_active ) or 
													( var.targets < 4 and not var.talent.flame_patch ) })
	self:updateAction(act.standard.phoenix_flames,{ not var.phoenix_pooling, 
													var.buff.heating_up.up or 
													( not var.buff.hot_streak.up and 
													  ( var.cooldown.fire_blast.charge > 0 or var.searing_torch_active ) ) })
	self:updateAction(act.standard.living_bomb,   	var.living_bomb_conditions )
	self:updateAction(act.standard.meteor, 		  	var.meteor_conditions )
	self:updateAction(act.standard.dragons_breath,{ false, var.targets > 1 , var.distance <= 12 })
	self:updateAction(act.standard.scorch, _, 		var.searing_torch_active )
	self:updateAction(act.standard.fireball, _, 	true)
	self:updateAction(act.standard.scorch_2, _, 	true)
	
	
	self:updateAction(act.rop.flamestrike, 		  { ( var.talent.flame_patch and var.targets > 1 ) or var.targets > 4, var.buff.hot_streak.up } ) 
	self:updateAction(act.rop.pyroblast, 			var.buff.hot_streak.up ) 
	self:updateAction(act.rop.fire_blast, 		  {	not var.firestarter_active, -- and not var.cooldown.combustion.up, 
													not var.buff.heating_up.up and not var.buff.hot_streak.up and 
													not var.previous_cast.spell_id ~= 108853 and 
													( var.cooldown.fire_blast.charge >= 2 or 
													  ( var.cooldown.phoenix_flames.charge >= 1 and var.talent.phoenix_flames ) or 
													  ( var.talent.alexstraszas_fury and var.cooldown.dragons_breath.up ) or 
													  var.searing_torch_active or var.firestarter_active ) } ) 
	self:updateAction(act.rop.living_bomb, 			var.living_bomb_conditions ) 
	self:updateAction(act.rop.meteor, 				var.meteor_conditions ) 
	self:updateAction(act.rop.pyroblast_2, 		  { var.buff.pyroclasm.up, var.pyroblast_cast_time < var.buff.pyroclasm.remain, 
													var.buff.rune_of_power.remain > var.pyroblast_cast_time } ) 
	self:updateAction(act.rop.fire_blast_2, 	  {	--not var.cooldown.combustion.up or 
													not var.firestarter_active and 
													( var.buff.rune_of_power.up or var.casting.rune_of_power ), 
													var.buff.heating_up.up and not var.searing_torch_active} ) 
	self:updateAction(act.rop.fire_blast_3, 	  {	--not var.cooldown.combustion.up or 
													not var.firestarter_active and 
													( var.buff.rune_of_power.up or var.casting.rune_of_power ),
													var.searing_torch_active, 
													var.buff.heating_up.up and not var.casting.scorch or 
													not var.buff.heating_up.up and not var.buff.hot_streak.up } ) 
	self:updateAction(act.rop.pyroblast_3, 		  {	var.casting.scorch or var.recent.scorch.cast, var.buff.heating_up.up, 
													var.searing_torch_active, not var.talent.flame_patch or var.targets <= 1 } ) 
	self:updateAction(act.rop.phoenix_flames, 	  {	not var.recent.phoenix_flames.cast, var.buff.heating_up.up } ) 
	self:updateAction(act.rop.scorch, _,			var.searing_torch_active ) 
	self:updateAction(act.rop.dragons_breath, 	  { false, var.targets > 2, var.distance <= 12 } ) 
	self:updateAction(act.rop.flamestrike_2, 	 	var.talent.flame_patch and var.targets > 2 or var.targets > 5 ) 
	self:updateAction(act.rop.fireball, _, 			true) 
	
	self:updateAction(act.comb.fire_blast,		  {	var.enough_fire_blast_for_combustion, -- or 
													-- var.equipped_hyperthread_wristwraps and var.cooldown.hyperthread_wristwraps_300142.remain < 5, 
													var.buff.combustion.up, 
													not var.casting.scorch and not var.pyroblast_in_flight and var.buff.heating_up.up or 
													var.casting.scorch and not var.buff.hot_streak.up and 
													( not var.buff.heating_up.up or var.azerite_bm ) or 
													( var.azerite_bm and var.talent.flame_on and var.pyroblast_in_flight and 
													  not var.buff.heating_up.up and not var.buff.hot_streak.up ) } )
	self:updateAction(act.comb.rune_of_power,	  { not var.buff.combustion.up, not var.buff.rune_of_power.up, var.cooldown.combustion.up } )
	self:updateAction(act.comb.fire_blast_2,	  { var.azerite_bm, var.talent.flame_on, var.buff.blaster_master.stack <= 1, 
													not var.buff.hot_streak.up, 
													( var.talent.rune_of_power and var.casting.rune_of_power or 
													  var.cooldown.combustion.up or var.buff.combustion.up ) } )
	self:updateAction(act.comb.living_bomb,		  	var.living_bomb_conditions )
	self:updateAction(act.comb.meteor,			  	var.meteor_conditions )
	self:updateAction(act.comb.combustion,		  {	var.meteor_in_flight or not var.talent.meteor, 
													var.buff.rune_of_power.up or var.casting.rune_of_power or not var.talent.rune_of_power } )
	self:updateAction(act.comb.flamestrike,		  {	( var.talent.flame_patch and var.targets > 2 ) or var.targets > 6, 
													var.buff.hot_streak.up, not var.azerite_bm } )
	self:updateAction(act.comb.pyroblast,		  {	var.buff.pyroclasm.up, var.buff.combustion.remain > var.pyroblast_cast_time } )
	self:updateAction(act.comb.pyroblast_2,			var.buff.hot_streak.up or (var.buff.heating_up.up and var.pyroblast_in_flight) or 
													( ( var.buff.heating_up.up or var.pyroblast_in_flight )
													  and var.casting.scorch and var.buff.combustion.remain > 0.2 ) )
	self:updateAction(act.comb.phoenix_flames)
	self:updateAction(act.comb.scorch, _,			var.buff.combustion.remain > var.scorch_cast_time and var.buff.combustion.up or not var.buff.combustion.up )
	self:updateAction(act.comb.living_bomb_2,	  {	var.buff.combustion.remain < var.gcd, var.targets > 1 } )
	self:updateAction(act.comb.dragons_breath,	  {	false, var.distance <= 12, var.buff.combustion.remain < var.gcd, var.buff.combustion.up} )
	self:updateAction(act.comb.scorch_2, _,		  	var.searing_torch_active )
	self:updateAction(act.comb.fireball, _,		  	true )
end

function MageFire: rotation()
	local var = self.variables
	
	self:updateVariables()
	self:updateAllActions()
	
	-- The "misc" action list is to detect if player can cast spells
	local can_use_spells = self:runActionList(self.actions.misc)
	if not can_use_spells then 
		self:hideAllIcons()
		return
	else 
		self:showAllIcons()
	end
	
	local main			= self:runActionList(self.actions.main)
	local standard		= self:runActionList(self.actions.standard)
	local rop			= self:runActionList(self.actions.rop)
	local combustion	= self:runActionList(self.actions.comb)
	
	local spell = standard
	local phase = "standard"
	local small = nil
	local small_2 = nil
	
	if var.buff.combustion.up or ( self.essence == 298357 and var.cooldown.essence.remain > 110 ) then 
		phase = "combustion"
		spell = combustion
		-- if prompting fire blast
		if main == 108853 and not var.buff.combustion.up and not var.casting.rune_of_power then 
			spell = main
			small = 116011
		elseif spell == 108853 then 
			if var.cooldown.meteor.up then 
				small = 153561
			elseif var.pyroblast_in_flight or var.buff.heating_up.up then
				small = 11366
			end
		end
		-- if prompting meteor
		if spell == 153561 then 
			if var.cooldown.combustion.up then 
				small = 190319
			end	
		end
		-- if prompting combustion
		if spell == 190319 then
			if var.buff.hot_streak.up then 	
				--small_2 = 11366
				small = 108853
			else
				--small_2 = 108853
				small = 11366
			end
		end
		-- if prompting pyroblast
		if spell == 11366 and var.buff.combustion.remain > 1 then 
			if var.buff.blaster_master.stack >= 3 and var.buff.blaster_master.remain > var.scorch_cast_time then 
				small = 2948
			elseif var.cooldown.fire_blast.remain < var.gcd + 0.2 then
				small = 108853
			elseif var.buff.combustion.remain > var.scorch_cast_time + var.gcd then 
				small = 2948
			end
		end
		-- if prompting scorch
		if spell == 2948 then 
			if var.buff.blaster_master.remain > 0.5 + var.scorch_cast_time then
				small = 11366
			else
				small = 108853
			end			
		end
	elseif var.buff.rune_of_power.up or var.casting.rune_of_power then 
		phase = "rop"
		spell = rop
	end
	
	local show_gcd = spell == 190319 -- or phase == "combustion" and spell == 11366
	
	--self:setText(self.text_debug, tostring(i))
	self:updateIcon(nil, spell, show_gcd and "gcd" or nil)
	self:updateIcon(self.icon_small, small)
	self:updateIcon(self.icon_small_2, small_2)
	self:updateIcon(self.icon_fire_blast, 108853, 108853)
	
	if var.cooldown.rune_of_power.charge then 
		self:setText(self.text_rop, var.cooldown.rune_of_power.charge)
	else
		self:setText(self.text_rop, "")
	end
	
	if var.cooldown.fire_blast.charge then 
		self:setText(self.text_fire_blast,var.cooldown.fire_blast.charge)
	else
		self:setText(self.text_fire_blast, "")
	end
	
	if var.buff.combustion.up then 
		self:updateIcon(self.icon_combustion, 190319)
		self:iconSetBuffAnimation(self.icon_combustion, 190319)
	elseif self.essence == 298357 and var.cooldown.combustion.remain < 3 and var.cooldown.essence.up then 
		self:updateIcon(self.icon_combustion, 298357, 298357)
	else 
		self:updateIcon(self.icon_combustion, 190319, 190319)
	end
	
	if var.rop_remain > 0 then 
		self:updateIcon(self.icon_rop, 116011)
		if var.buff.rune_of_power.up then 
			self:iconCooldownColor(self.icon_rop, 0.5, 1, 0, 0.5)
		else
			self:iconCooldownColor(self.icon_rop, 0.5, 0.5, 0.5, 0.75)
		end
		self:iconSetCooldown(self.icon_rop, var.rop_start, var.rop_duration)
	else 
		if main == 116011 then 
			self:updateIcon(self.icon_rop, 116011, 116011, nil, nil, {1, 0, 0, 1})
		else
			self:updateIcon(self.icon_rop, 116011, 116011)
		end
	end
	
	if var.recent.pyroblast.cast and
		self.cleave:targets(true) > 4  then 
		self.cleave:temporaryDisable(8, var.recent.pyroblast.time)
	end
	if var.recent.flamestrike.cast then 
		self.cleave:temporaryDisable(0, var.recent.flamestrike.time)
	end 
end