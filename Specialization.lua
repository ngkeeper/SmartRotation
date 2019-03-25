Specialization = {}
Specialization.__index = Specialization

setmetatable(Specialization, {
  __call = function (class, ...)
	local self = setmetatable({}, class)
    self:_new(...)
    return self
  end,
})

function Specialization: _new(spells, single_target_dps)

	self.player = Player()
	self.cleave = CleaveLog(spells.cleave)
	self.spells = SpellStatus(spells)
	self.rc = LibStub("LibRangeCheck-2.0")	-- range check
	
	self.enabled = true
	self.next_spell = nil
	self.next_spell_trigger = false
	self.next_spell_on_focus = false
	
	self.variables = {}
	self.icons = {}
	self.actions = {}
	self.talent = self.player:talent()
	
	self.anchor_x = 0
	self.anchor_y = 0
	self.size = 50
	self.ui_ratio = 1
	
	self.icon = self:createIcon(nil, self.size, self.anchor_x, self.anchor_y, true)

	self:refreshUI()
end

function Specialization: isEnabled()
	return self.enabled
end

function Specialization: enable()
	for _, v in ipairs(self.icons) do
		v.UIFrame: Show()
	end
	self.enabled = true
end

function Specialization: disable()
	for _, v in ipairs(self.icons) do
		v.UIFrame: Hide()
	end
	self.enabled = false
end

function Specialization: setSize(size)
	self.size = size or self.size
	self.ui_ratio = self.size / 50
	self:refreshUI()
end

function Specialization: getSize()
	return self.size
end

function Specialization: setPosition(x, y)
	self.anchor_x = x or self.anchor_x
	self.anchor_y = y or self.anchor_y
	self:refreshUI()
end

function Specialization: getPosition()
	return self.anchor_x, self.anchor_y
end

function Specialization: createIcon(texture, size, x, y, cd)
	if type(texture) == "number" then texture = GetSpellTexture(texture) end

	local icon = {}
	icon.texture = texture
	icon.size = size or 50
	icon.x = x or 0
	icon.y = y or 0
	
	icon.UIFrame = CreateFrame("Frame", nil, UIParent)
	icon.UIFrame:SetFrameStrata("BACKGROUND")
	icon.UIFrame:SetWidth(icon.size)
	icon.UIFrame:SetHeight(icon.size)
	
	icon.UITexture = icon.UIFrame:CreateTexture(nil,"MEDIUM")
	if texture then icon.UITexture:SetTexture(icon.texture) end
	icon.UITexture:SetAllPoints(icon.UIFrame)
	
	if cd then 
		icon.UICd = CreateFrame("Cooldown", nil, icon.UIFrame, "CooldownFrameTemplate")
		icon.UICd:SetAllPoints(icon.UIFrame)
		icon.UICd:SetDrawEdge(false)
		icon.UICd:SetSwipeColor(1, 1, 1, .85)
		icon.UICd:SetHideCountdownNumbers(false)
	end
	
	table.insert(self.icons, icon)
	
	self:refreshUI()
	return #self.icons
end

function Specialization: iconConfig(icon, texture, size, x, y)
	icon.texture = texture or icon.texture
	icon.size = size or icon.size
	icon.x = x or icon.x
	icon.y = y or icon.y
	self:refreshUI()
end

function Specialization: iconCooldown(icon, start, duration)
	self.icons[icon].UICd:SetCooldown(start, duration)
end

function Specialization: iconGlow(icon)
	ActionButton_ShowOverlayGlow(self.icons[icon].UIFrame)
end

function Specialization: iconHideGlow(icon)
	ActionButton_HideOverlayGlow(self.icons[icon].UIFrame)
end

function Specialization: iconColor(icon, r, g, b, alpha)
	r = r or 1
	g = g or 1
	b = b or 1
	alpha = alpha or 1
	self.icons[icon].UITexture:SetVertexColor(r, g, b, alpha)
end
function Specialization: iconTexture(icon, texture)
	self.icons[icon].UITexture:SetTexture(texture)
end
function Specialization: refreshUI()
	-- self.icon: SetSize(self.size,self.size)
	-- self.icon: SetPoint("CENTER", self.anchor_x, self.anchor_y)
	-- self.icon: Show()
	-- self.text: SetPoint("CENTER", 2 * self.ui_ratio, 40 * self.ui_ratio)
	
	for _, v in ipairs(self.icons) do
		v.UIFrame: SetWidth(v.size * self.ui_ratio)
		v.UIFrame: SetHeight(v.size * self.ui_ratio)
		v.UIFrame: SetPoint("CENTER", self.anchor_x + v.x * self.ui_ratio, self.anchor_y + v.y * self.ui_ratio)
		v.UIFrame: Show()
	end
end

function Specialization: update()
	if not self.enabled then return nil end
	self.spells: update()
end

function Specialization: updateCombat()
	if not self.enabled then return nil end
	self.spells: updateCombat()	
end

function Specialization: updateIcon(icon, spell)
	size = not(button) and self.size
	icon = icon or self.icon
	spell = spell or self.next_spell
	
	local color = 0
	if self.enabled and spell then 
		icon.UITexture: SetTexture(GetSpellTexture(spell))
		--icon.UIFrame: Show()
		if UnitCanAttack("player", "target") then 
			local spellname = select(1, GetSpellInfo(spell))
			if spellname then 
				color = ((IsSpellInRange(spellname, "target") == 0) and 1) or 0
			end
		end
	else
		icon.UIFrame: Hide()
	end
	if self.next_spell_on_focus then 
		--self.text:SetText("")
		color = 2
	end

	if color == 0 then 
		icon.UITexture:SetVertexColor(1, 1, 1, 1)
	elseif color == 1 then 
		icon.UITexture:SetVertexColor(1, .7, .7, 1)
	elseif color == 2 then 
		icon.UITexture:SetVertexColor(1, 1, .7, 1)
	end
	
	-- if DEBUG > 0 then 
		-- local time_to_kill = math.ceil(self.spells: timeToKill())
		-- --self.text:SetText(time_to_kill > 0 and tostring(time_to_kill) or "")
		-- self.text:SetText(self.spells: getCleaveTargets())
	-- end
end

function Specialization: getRange(unit)
	unit = unit or "target"
	local range_min, range_max = self.rc:GetRange(unit)
	return range_min, range_max
end

function Specialization: newActionList(actions)
	local list = {}
	for i, v in ipairs(actions) do 
		table.insert(list, v)
	end
	return list
end

function Specialization: runActionList(list)
	for i, v in ipairs(list) do 
		if v.triggered then 
			return v.spell
		end
	end
	return nil
end

function Specialization: newAction(spell, conditions, enabled)
	local action = {}
	self: updateAction(action, conditions, enabled)
	return action
end

function Specialization: updateAction(action, conditions, enabled)
	enabled = enabled or true
	
	action.spell = spell
	action.enabled = enabled
	
	if spell then 
		action.usable = self.spells:isSpellReady(spell)
		if spell == "POOL" then 
			action.usable = true
		end
	else
		action.usable = true
	end
	
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
	action.condition = all_conditions_met
	action.triggered = action.usable and actions.condition and action.enabled
	
	return action
end

function Specialization: setActionFocus(spell, conditions, nospellcheck)
	if not self.next_spell_trigger then return nil end
	if not SRCONFIG.focus then return nil end
	
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