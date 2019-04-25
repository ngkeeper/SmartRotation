Specialization = {}
Specialization.__index = Specialization

setmetatable(Specialization, {
  __call = function (class, ...)
	local self = setmetatable({}, class)
    self:_new(...)
    return self
  end,
})

function Specialization: _new(spells)
	self.player = Player()
	self.cleave = CleaveLog2(spells.cleave)
	self.spells = SpellStatus(spells)
	self.rc = LibStub("LibRangeCheck-2.0")	-- range check
	
	self.enabled = true
	self.next_spell = nil
	self.next_spell_trigger = false
	self.next_spell_on_focus = false
	
	self.variables = {}
	self.icons = {}
	self.texts = {}
	self.actions = {}
	self.talent = self.player:talent()
	
	self.anchor_x = 0
	self.anchor_y = 0
	self.size = 50
	self.ui_ratio = 1
	
	self.icon = self:createIcon(nil, self.size, self.anchor_x, self.anchor_y)
	self.text = self:createText(self.icon, 16, 0, 40)
	self.text2 = self:createText(self.icon, 16, 0, -40)
	
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

function Specialization: createText(parentIcon, size, x, y)
	local parent = UIParent
	if parentIcon then parent = self.icons[parentIcon].UIFrame end
	
	local text = {}
	text.x = x or 0
	text.y = y or 0
	text.size = size or 12
	text.parent = parent
	
	text.UIText = parent:CreateFontString(nil,"OVERLAY")
	text.UIText:SetFont("Fonts\\FRIZQT__.ttf", text.size, "OUTLINE")
	text.UIText:SetTextColor(1, 1, 1)
	text.UIText:SetJustifyH("CENTER")
	text.UIText:SetJustifyV("MIDDLE")
	text.UIText:SetText("")
	
	table.insert(self.texts, text)
	
	self:refreshUI()
	return #self.texts
end

function Specialization: setText(text, message)
	if self.texts[text] then 
		self.texts[text].UIText:SetText(message)
	end
end

function Specialization: createIcon(texture, size, x, y, anchor, strata, reverseCd)
	if type(texture) == "number" then texture = GetSpellTexture(texture) end
	
	local icon = {}
	icon.texture = texture
	icon.size = size or 50
	icon.x = x or 0
	icon.y = y or 0
	icon.anchor = anchor or "CENTER"
	
	icon.UIFrame = CreateFrame("Frame", nil, UIParent)
	icon.UIFrame:SetFrameStrata(strata or "BACKGROUND")
	icon.UIFrame:SetWidth(icon.size)
	icon.UIFrame:SetHeight(icon.size)
	icon.UIFrame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", 
							   tile = false, 
							   insets = { left = 0, right = 0, top = 0, bottom = 0 }})
	icon.UIFrame:SetBackdropColor(0,0,0,1)
	
	icon.UITexture = icon.UIFrame:CreateTexture(nil,"MEDIUM")
	if texture then icon.UITexture:SetTexture(icon.texture, true) end
	icon.UITexture:ClearAllPoints()
	icon.UITexture:SetPoint("TOPLEFT", icon.UIFrame, "TOPLEFT", 1, -1)
	icon.UITexture:SetPoint("BOTTOMRIGHT", icon.UIFrame, "BOTTOMRIGHT", -1, 1)
	icon.UITexture:SetTexCoord(.08, .92 , .08, .92)
	
	icon.UICd = CreateFrame("Cooldown", nil, icon.UIFrame, "CooldownFrameTemplate")
	icon.UICd:SetAllPoints(icon.UIFrame)
	icon.UICd:SetDrawEdge(false)
	icon.UICd:SetReverse(reverseCd or false)
	icon.UICd:SetSwipeColor(1, 1, 1, .85)
	icon.UICd:SetHideCountdownNumbers(reverseCd or false)
	
	
	
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

function Specialization: iconGlow(icon, glow)
	if type(glow) == "nil" then glow = true end
	if glow then 
		ActionButton_ShowOverlayGlow(self.icons[icon].UIFrame)
	else 
		ActionButton_HideOverlayGlow(self.icons[icon].UIFrame)
	end
end

function Specialization: iconDesaturate(icon, desaturate)
	if type(desaturate) == "nil" then desaturate = true end
	if desaturate then 
		self.icons[icon].UITexture:SetDesaturated(1)
	else 
		self.icons[icon].UITexture:SetDesaturated(nil)
	end
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
		v.UIFrame: SetPoint(v.anchor, "UIParent", "CENTER", 
							self.anchor_x + v.x * self.ui_ratio, self.anchor_y + v.y * self.ui_ratio)
		v.UIFrame: Show()
	end
	for _, v in ipairs(self.texts) do
		--print(v.parent)
		v.UIText: SetPoint(	"CENTER", v.parent, "CENTER", v.x * self.ui_ratio, v.y * self.ui_ratio)
	end
end

function Specialization: update()
	if not self.enabled then return nil end
	self.spells: update()
	self.cleave: update()
	
	local str1 = ""
	local str2 = ""
	if SR_DEBUG > 0 then 
		str1 = tostring(self.cleave:targets(true)).." "..
			  tostring(self.cleave:targetsLowHealth())
		local ttk, dps = self.player:timeToKill()
		ttk = math.min(99, ttk)
		str2 = tostring(math.floor(ttk*10)/10)
	end
	self:setText(self.text, str1)
	self:setText(self.text2, str2)
end

function Specialization: updateCombat()		-- call on combat log event
	if not self.enabled then return nil end
	self.spells: updateCombat()	
	self.cleave: updateCombat()
end

function Specialization: updateTalent()		-- call on talent change events
	if not self.enabled then return nil end
	self.talent = self.player:talent()
end

function Specialization: updateDotIcon(iconId, dotid, refreshable)
	local present
	for i = 1, 40 do
		local ud_name, _, _, _, ud_duration, ud_expiration, _, _, _, ud_spell_id = UnitDebuff("target", i, "player")
        if ud_spell_id == dotid then
            self:iconCooldown(iconId, ud_expiration - ud_duration, ud_duration)
			present = true
        end
    end
	if refreshable and present then 
		self.icons[iconId].UITexture:SetVertexColor(.5, 1, .5, 1)
	end
	if not present then 
		self.icons[iconId].UITexture:SetDesaturated(1)
		self:iconCooldown(iconId, 0, 0)
	else 
		self.icons[iconId].UITexture:SetDesaturated(nil)
	end
end

function Specialization: updateIcon(iconId, spell, cdSpell, texture)
	size = not(button) and self.size
	icon = self.icons[iconId] or self.icons[self.icon]
	spell = spell or self.next_spell
	
	local color = 0
	if texture then 	
		icon.UITexture: SetTexture(texture, true)
		icon.UIFrame:SetBackdropColor(0,0,0,1)
	else
		if self.enabled and spell then 
			icon.UITexture: SetTexture(GetSpellTexture(spell), true)
			icon.UIFrame:SetBackdropColor(0,0,0,1)
			if UnitCanAttack("player", "target") then 
				local spellname = select(1, GetSpellInfo(spell))
				if spellname then 
					color = ((IsSpellInRange(spellname, "target") == 0) and 1) or 0
				end
			end
		else
			icon.UIFrame:SetBackdropColor(0,0,0,0)
			icon.UITexture: SetTexture(nil)
		end
	end
	
	if self.next_spell_on_focus then 
		--self.text:SetText("")
		color = 2
	end
	
	if color == 0 then 
		icon.UITexture:SetVertexColor(1, 1, 1, 1)
	elseif color == 1 then 
		icon.UITexture:SetVertexColor(1, .5, .5, 1)
	elseif color == 2 then 
		icon.UITexture:SetVertexColor(1, 1, 0, 1)
	end
	
	if cdSpell and icon.UICd then 
		local start, duration = GetSpellCooldown(cdSpell)
		if duration > 1.5 then 
			self:iconCooldown(iconId or self.icon, start, duration)
		end
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

function Specialization: doesSpellCastRemoveAura(spell_cast, aura)
	local aura_timestamps = self.spells: auraRemoved(aura)
	if not spell_cast.cast then 
		return nil
	end
	
	local time_diff
	for i, v in ipairs(aura_timestamps) do 
		time_diff = math.min(time_diff or (v - spell_cast.time), math.abs(v - spell_cast.time))
	end
	
	--if spell == 1822 and aura == 5215 then 
		--printTable(aura_timestamps)
		--print(time_diff)
	--end
	
	if not time_diff then return nil end
	
	return ( time_diff < .5 ) and ( time_diff > -0.2 )
end

function Specialization: newActionList(actions)
	local list = {}
	for i, v in ipairs(actions) do 
		table.insert(list, v)
	end
	return list
end

function Specialization: runActionList(list)
	-- if not self.printonce then 
		-- printTable(list) 
		-- self.printonce = true
	-- end
	
	local spell, priority
	
	for i, v in pairs(list) do 
		if v.triggered and v.enabled then 
			--print(tostring(v.spell).." "..tostring(v.priority))
			priority = priority or v.priority
			if (v.priority <= priority) then
				priority = v.priority
				spell = v.spell
			end
		end
	end
	return spell, priority
end

function Specialization: newAction(spell, list, conditions, enabled)
	local action = {}
	action.spell = spell
	action.priority = 1
	
	-- '#list' doesn't work here, use for loop to count # of elements
	for i, v in pairs(list) do
		action.priority = action.priority + 1
	end
	
	self: updateAction(action, conditions, _, enabled)
	return action
end

function Specialization: updateAction(action, conditions, override, enabled)
	enabled = not (enabled == false)
	action.enabled = enabled
	
	if action.spell then 
		action.usable = self.spells:isSpellReady(action.spell)
		if action.spell == "POOL" then 
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
		for i = 1, #conditions do 
			all_conditions_met = all_conditions_met and conditions[i]
		end
	end
	action.condition = all_conditions_met
	action.triggered = action.usable and action.condition and action.enabled
	
	if override == true or override == false then 
		action.triggered = override
	end	
	
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