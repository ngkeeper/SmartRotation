PlayerRotation = {}
PlayerRotation.__index = PlayerRotation

setmetatable(PlayerRotation, {
  __call = function (class, ...)
	local self = setmetatable({}, class)
    self:_new(...)
    return self
  end,
})

function PlayerRotation: _new(gcd_spell, buff_spell, dot_spell, cd_spell, casting_spell, cleave_spell, cleave_targets, aoe_targets, single_target_dps)
	--print("PlayerRotation Constructor: "..tostring(gcd_spell))
	local player = PlayerStatus(gcd_spell, buff_spell, dot_spell, cd_spell, casting_spell, cleave_spell, cleave_targets, aoe_targets, single_target_dps)
	self.player = player
	self.enabled = true
	self.next_spell = ""
	self.next_spell_trigger = false
	self.next_spell_on_focus = false
	self.talent = {}
	self:updateTalent()
	
	self.rc = LibStub("LibRangeCheck-2.0")	-- range check
	
	self.anchor_x = 0
	self.anchor_y = 0
	self.button = CreateFrame("Button", "SR_main_button", UIParent, "ActionButtonTemplate")
	self.button: SetPoint("CENTER", self.anchor_x, self.anchor_y)
	self.button: Disable()
	self.size = 50
	self.button: SetSize(self.size,self.size)
	self.button: SetNormalTexture(self.button: GetHighlightTexture())
	--self.button.icon: SetTexture()
	self.button: Show()
	
	self.text = self.button:CreateFontString("SR_main_button_text","OVERLAY")
	self.text:SetFont("Fonts\\FRIZQT__.ttf", 24, "THICKOUTLINE")
	self.text:SetTextColor(1, 1, 1)
	self.text:SetPoint("CENTER",self.anchor_x, self.anchor_y)
	self.text:SetText("")
	
	self.overlay = self.button:CreateTexture("SR_main_button_overlay")
	self.overlay:SetAllPoints(self.button)
	self.overlay:SetColorTexture(.5, .5, 0, 0)

end


function PlayerRotation: enable()
	self.button: Show()
	self.enabled = true
end
function PlayerRotation: isEnabled()
	return self.enabled
end

function PlayerRotation: disable()
	self.button: Hide()
	self.enabled = false
end
function PlayerRotation: setSize(size)
	if size then 
		self.size = math.max(size, 0)
		self.button: SetSize(size, size)
	end
end
function PlayerRotation: getSize()
	return self.size
end
function PlayerRotation: setPosition(x, y)
	if x and y then
		self.anchor_x = x
		self.anchor_y = y
		self.button: SetPoint("CENTER", x, y)
	end
end
function PlayerRotation: getPosition()
	return self.anchor_x, self.anchor_y
end
function PlayerRotation: update()
	if not self.enabled then return nil end
	self.player: update()
	
end
function PlayerRotation: updateCombat()
	if not self.enabled then return nil end
	self.player: updateCombat()	
end
function PlayerRotation: updateTalent()
	for i = 1, 7 do
		local column = select(2, GetTalentTierInfo(i, 1))
		self.talent[i] = column
	end
end
function PlayerRotation: updateIcon(button, overlay, spell)
	overlay = overlay or (not(button) and self.overlay)
	size = not(button) and self.size
	button = button or self.button
	spell = spell or self.next_spell
	
	local overlay_color = 0
	if self.enabled and spell then 
		button.icon: SetTexture(GetSpellTexture(spell))
		button: Show()
		if UnitCanAttack("player", "target") then 
			local spellname = select(1, GetSpellInfo(spell))
			if spellname then 
				overlay_color = ((IsSpellInRange(spellname, "target") == 0) and 1) or 0
			end
		end
	else
		button: Hide()
	end
	if size then 
		local large_aoe_icon = self.highlight_aoe or false
		if self.player:isCleave() and large_aoe_icon then 
			button: SetSize(self.size * 1.2,self.size * 1.2)
		else	
			button: SetSize(self.size,self.size)
		end
	end 
	if self.next_spell_on_focus then 
		--self.text:SetText("")
		overlay_color = 2
	end
	if overlay then 	
		if overlay_color == 0 then 
			overlay:SetColorTexture(0, 0, 0, 0)
		elseif overlay_color == 1 then 
			overlay:SetColorTexture(.5, 0, 0, .5)
		elseif overlay_color == 2 then 
			overlay:SetColorTexture(.5, .5, 0, .4)
		end
	end
	
	if DEBUG > 0 then 
		self.text:SetText(tostring(math.ceil(self.player: timeToKill())))
	end
end
function PlayerRotation: getRange(unit)
	unit = unit or "target"
	local range_min, range_max = self.rc:GetRange(unit)
	return range_min, range_max
end
function PlayerRotation: setAction(spell, conditions, push)
	-- If "push" is defined, the function will not take any action.
	-- But the return value will indicated the status of the spell.
	if not self.next_spell_trigger then return nil end
	local spell_ready = self.player:isSpellReady(spell)
	
	local all_conditions_met = false
	if type(conditions) == "nil" then
		all_conditions_met = true
	end
	if type(conditions) == "boolean" then
		all_conditions_met = conditions
	end
	if type(conditions) == "table" then
		all_conditions_met = true
		for i, v in ipairs(conditions) do 
			all_conditions_met = all_conditions_met and v
		end
	end
	-- if spell == 44614 then
		-- print(tostring(spell_ready).." "..tostring(conditions[1]).." "..tostring(conditions[2]).." "..tostring(conditions[3]))
	-- end
	if spell_ready and all_conditions_met then
		if not(push) then 
			self.next_spell = spell
			self.next_spell_on_focus = false
			self.next_spell_trigger = false
		end
	end
	return (spell_ready and all_conditions_met), spell_ready, all_conditions_met
end
function PlayerRotation: setActionFocus(spell, conditions, nospellcheck)
	if not self.next_spell_trigger then return nil end
	
	local guid_target = UnitGUID("target")
	local guid_focus = UnitGUID("focus")
	if not(guid_focus) or guid_focus == guid_target then return nil end
	
	local _, instance = GetInstanceInfo()
	if instance == "arena" then return nil end
	if not UnitCanAttack("player", "focus") then return false end
	
	local action_ready, _, all_conditions_met = self: setAction(spell, conditions, 1)
	 
	if action_ready or ( nospellcheck and all_conditions_met ) then 
		self.next_spell = spell
		self.next_spell_on_focus = true
		self.next_spell_trigger = false
		return true
	end
	return false
end