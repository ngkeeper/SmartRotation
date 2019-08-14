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
	
	local essence = C_AzeriteEssence.GetMilestoneSpell(115)
	-- GetMilestoneSpell() returns a spell id that has the same name with the true spell id
	-- GetSpellInfo(essence) returns the name of the spell, and 
	-- GetSpellInfo() again to get the true spell id
	essence = select(7, GetSpellInfo(GetSpellInfo(essence)))
	
	if ( essence or 0 ) > 0 then 
		table.insert(spells.cd, essence)
		self.essence = essence
	end
	-- for i, v in pairs(C_AzeriteEssence) do
		-- print(i)
	-- end
	-- for i, v in pairs(C_AzeriteItem) do
		-- print(i)
	-- end
	
	
	self.spells = SpellStatus(spells)
	self.gcd_spell = spells.gcd
	self.rc = LibStub("LibRangeCheck-2.0")	-- range check
	
	self.enabled = true
	self.focus = false
	
	self.variables = {}
	self.icons = {}
	self.texts = {}
	self.actions = {}
	self.talent = self.player:talent()
	
	self.anchor_x = self.anchor_x or 0
	self.anchor_y = self.anchor_y or 0
	self.size = 50
	self.ui_ratio = 1
	
	self.icon = self:createIcon(nil, self.size, 0, 0)
	self:createAnimation(self.icon)
	
	self.text = self:createText(self.icon, 16, 0, 40)
	self.text2 = self:createText(self.icon, 16, 0, -40)
	
end

function Specialization: update()
	if not self.enabled then return nil end
	self.spells: update()
	self.cleave: update()
	self:refreshUI()
	
	local str1 = ""
	local str2 = ""
	if SR_DEBUG > 2 then 
		str1 = tostring(self.cleave:targets(true)) -- .." "..
			   --tostring(self.cleave:targetsLowHealth())
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

function Specialization: isEnabled()
	return self.enabled
end

function Specialization: enable()
	self:show()
	self.enabled = true
end

function Specialization: disable()
	self:hide()
	self.enabled = false
end

function Specialization: show()
	for _, v in ipairs(self.icons) do
		v.UIFrame: Show()
	end
end

function Specialization: hide()
	for _, v in ipairs(self.icons) do
		v.UIFrame: Hide()
	end
end

function Specialization: trackFocus(focus)
	self.focus = focus or false
end

function Specialization: setSize(size)
	self.size = size or self.size
	self.ui_ratio = self.size / 50
end

function Specialization: getSize()
	return self.size
end

function Specialization: setPosition(x, y)
	self.anchor_x = x or 0
	self.anchor_y = y or 0
end

function Specialization: getPosition()
	return self.anchor_x, self.anchor_y
end

function Specialization: createText(parent_icon, size, x, y)
	local parent = UIParent
	if parent_icon then parent = self.icons[parent_icon].UIFrame end
	
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
	
	return #self.texts
end

function Specialization: setText(text, message)
	if self.texts[text] then 
		self.texts[text].UIText:SetText(message)
	end
end

function Specialization: createIcon(texture, size, x, y, anchor, strata)
	if type(texture) == "number" then texture = GetSpellTexture(texture) end
	
	local icon = {}
	icon.texture 			= texture
	icon.size 				= size or 50
	icon.x 					= x or 0
	icon.y 					= y or 0
	icon.anchor 			= anchor or "CENTER"
	icon.color 				= {1, 1, 1, 1}
	icon.backdrop_color 	= {0, 0, 0, 1}
	icon.show				= false
	icon.desaturate 		= false
	icon.glow				= false
	icon.cooldown_reverse 	= false
	icon.cooldown_color 	= {0, 0, 0, 0.75}
	icon.cooldown_number	= false
	icon.cooldown_edge		= false
	
	icon.UIFrame = CreateFrame("Frame", nil, UIParent)
	icon.UIFrame:SetFrameStrata(strata or "BACKGROUND")
	icon.UIFrame:SetWidth(icon.size)
	icon.UIFrame:SetHeight(icon.size)
	icon.UIFrame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", 
							   tile = false, 
							   insets = { left = 0, right = 0, top = 0, bottom = 0 }})
	icon.UIFrame:Hide()
	
	icon.UITexture = icon.UIFrame:CreateTexture(nil,"MEDIUM")
	if texture then icon.UITexture:SetTexture(icon.texture, true) end
	icon.UITexture:ClearAllPoints()
	icon.UITexture:SetPoint("TOPLEFT", icon.UIFrame, "TOPLEFT", 1, -1)
	icon.UITexture:SetPoint("BOTTOMRIGHT", icon.UIFrame, "BOTTOMRIGHT", -1, 1)
	icon.UITexture:SetTexCoord(.08, .92 , .08, .92)
	
	icon.UICd = CreateFrame("Cooldown", nil, icon.UIFrame, "CooldownFrameTemplate")
	icon.UICd:SetAllPoints(icon.UIFrame)
	icon.UICd:SetSwipeTexture("Interface\\Buttons\\WHITE8X8")
	
	table.insert(self.icons, icon)
	
	return #self.icons
end

function Specialization: createAnimation(icon_id, animation, duration)
	icon_id = icon_id or self.icon
	animation = animation or "Scale"
	duration = duration or 1
	
	local icon = self.icons[icon_id]
	icon.UIAnimationGroup = icon.UIFrame:CreateAnimationGroup()
	icon.UIAnimation = icon.UIAnimationGroup:CreateAnimation(animation)
	if animation == "Scale" then 
		icon.UIAnimation:SetScale(0.92, 0.92)
	end
	icon.UIAnimation:SetDuration(0.2)
    icon.UIAnimation:SetSmoothing("OUT")
	
end

function Specialization: createTexture(icon, path)
	icon = icon or self.icon
	local offset = 8 * self.icons[icon].size / 50
	local texture = self.icons[icon].UIFrame:CreateTexture(nil, "Overlay")
	texture:SetTexture(path)
	texture:SetPoint("TOPLEFT", self.icons[icon].UIFrame, "TOPLEFT", offset, -offset)
	texture:SetPoint("BOTTOMRIGHT", self.icons[icon].UIFrame, "BOTTOMRIGHT", -offset, offset)
	texture:SetVertexColor(1,1,1,1)
	texture:Show()
	return texture
end

function Specialization: updateIcon(icon_id, spell, cd_spell, texture, icon_color, border_color)
	icon_id = icon_id or self.icon
	size = not(button) and self.size
	icon = self.icons[icon_id]
	texture = texture or GetSpellTexture(spell)
	
	local show_gcd = false
	if cd_spell == "gcd" then
		cd_spell = self.gcd_spell
		show_gcd = true
	end	
	
	icon.color = ( type(icon_color) == "table" ) and icon_color or {1, 1, 1, 1}
	icon.backdrop_color = ( type(border_color) == "table" ) and border_color or {0, 0, 0, 1}
	
	if not texture then 
		icon.show = false
		icon.texture = nil
	else 
		icon.show = true
		icon.texture = texture
		local spellname = select(1, GetSpellInfo(spell))
		if spellname then 
			if IsSpellInRange(spellname, "target") == 0 and not icon_color then 
				icon.color = {1, 0.5, 0.5, 1}
			end
		end
	end
	
	if (icon_id == self.icon or not icon_id) and self.cleave:disabled() 
		and self.enabled and ( spell or texture ) and not border_color then 
		icon.backdrop_color = {1, 1, 0, 1}
	end
	
	if cd_spell and icon.UICd then 
		local charge, charge_max, start, duration = GetSpellCharges(cd_spell)
		if charge then 
			self:iconCooldownReverse(icon_id, false)
			self:iconCooldownNumber(icon_id, false)
			if charge == charge_max then 	-- not charging
				self:iconCooldownEdge(icon_id, false)
				self:iconCooldownNumber(icon_id, false)
				self:iconCooldownColor(icon_id, 0, 0, 0, 0)
			elseif charge > 0 then 	-- charging, but have extra charges
				self:iconCooldownEdge(icon_id, true)
				self:iconCooldownNumber(icon_id, false)
				self:iconCooldownColor(icon_id, 0, 0, 0, 0)
				self:iconSetCooldown(icon_id, start, duration)
			else	-- charging, no charges left
				self:iconCooldownEdge(icon_id, true)
				self:iconCooldownNumber(icon_id, true)
				self:iconCooldownColor(icon_id, 0, 0, 0, 0.75)
				self:iconSetCooldown(icon_id, start, duration)
			end
			
		else
			start, duration = GetSpellCooldown(cd_spell)
			self:iconCooldownReverse(icon_id, false)
			self:iconCooldownEdge(icon_id, false)
			self:iconCooldownNumber(icon_id, true)
			self:iconCooldownColor(icon_id, 0, 0, 0, 0.75)
			if duration > 1.5 or show_gcd then 
				self:iconSetCooldown(icon_id, start, duration)
			else
				self:iconSetCooldown(icon_id, 0, 0)
			end
		end
	else
		self:iconSetCooldown(icon_id, 0, 0)
	end	
	
	if not spell then 
		self:iconSetCooldown(icon_id, 0, 0)
	end
	
	if icon_id == self.icon then 
		local gcd_spell = self.spells:gcdSpell()
		if (gcd_spell or 0) > 0 then 
			local start, duration = GetSpellCooldown(self.spells:gcdSpell())
			if duration > 0 and 
			not self.icons[self.icon].UIAnimationGroup:IsPlaying() 
			and (start > (self.icons[self.icon].last_gcd_start or 0)) then 
				self.icons[self.icon].UIAnimationGroup:Restart() 
				self.icons[self.icon].last_gcd_start = start
				--self.icons[self.icon].UIAnimationGroup:Play() 
			end
		end 
	end
end

function Specialization: iconSetCooldown(icon, start, duration)
	self.icons[icon].UICd:SetHideCountdownNumbers(not self.icons[icon].cooldown_number) 
	self.icons[icon].UICd:SetCooldown(start, duration)
end

function Specialization: iconSetDotAnimation(icon_id, dot_id, refreshable)
	local present
	for i = 1, 40 do
		local ud_name, _, _, _, ud_duration, ud_expiration, _, _, _, ud_spell_id = UnitDebuff("target", i, "player")
        if ud_spell_id == dot_id then
			self:iconCooldownReverse(icon_id, true)
			self:iconCooldownNumber(icon_id, false)
            self:iconSetCooldown(icon_id, ud_expiration - ud_duration, ud_duration)
			present = true
        end
    end
	if refreshable and present then
		self:iconColor(icon_id, 0.5, 1, 0.5, 1)
	end
	if not present then 
		self:iconDesaturate(icon_id, true)
		self:iconSetCooldown(icon_id, 0, 0)
	else 
		self:iconDesaturate(icon_id, false)
	end
end

function Specialization: iconSetBuffAnimation(icon_id, buff_id)
	for i = 1, 40 do
        local ub_name, _, ub_stack, _, ub_duration, ub_expiration, _, _, _, ub_spell_id = UnitBuff("player", i)
        if ub_spell_id == buff_id then
			self:iconCooldownNumber(icon_id, true)
			self:iconCooldownColor(icon_id, 0.5, 1, 0, 0.5)
			self:iconCooldownReverse(icon_id, true)
			self:iconSetCooldown(icon_id, ub_expiration - ub_duration, ub_duration)
		end
	end
end

function Specialization: iconConfig(icon, texture, size, x, y)
	self.icons[icon].texture = texture or self.icons[icon].texture
	self.icons[icon].size = size or self.icons[icon].size
	self.icons[icon].x = x or self.icons[icon].x
	self.icons[icon].y = y or self.icons[icon].y
end

function Specialization: iconGlow(icon, glow)
	if type(glow) == "nil" then glow = true end
	self.icons[icon].glow = glow
end

function Specialization: iconDesaturate(icon, desaturate)
	if type(desaturate) == "nil" then desaturate = true end
	if self.icons[icon] then 
		self.icons[icon].desaturate = desaturate
	end
end

function Specialization: iconColor(icon, r, g, b, alpha)
	if self.icons[icon] then 
		self.icons[icon].color = { r or 1, g or 1, b or 1, alpha or 1 }
	end
end

function Specialization: iconBorderColor(icon, r, g, b, alpha)
	if self.icons[icon] then 
		self.icons[icon].backdrop_color = { r or 0, g or 0, b or 0, alpha or 1 }
	end
end

function Specialization: iconTexture(icon, texture)
	if self.icons[icon] then 
		self.icons[icon].texture = texture
	end
end

function Specialization: iconTextureResize(icon, ratio_x, ratio_y)
	if self.icons[icon] then 
		local dx = ratio_x / 2
		local dy = ratio_y / 2
		self.icons[icon].UITexture:SetTexCoord(dx, 1 - dx, dy, 1 - dy)
	end
end

function Specialization: iconResize(icon, width, height)
	if width and height and self.icons[icon] then 
		self.icons[icon].width = width
		self.icons[icon].height = height
	end
end

function Specialization: iconMirrorX(icon)
	if self.icons[icon] then 
		self.icons[icon].UITexture:SetTexCoord(0, 1, 1, 0)
	end
end

function Specialization: iconMirrorY(icon)
	if self.icons[icon] then 
		self.icons[icon].UITexture:SetTexCoord(1, 0, 0, 1)
	end
end

function Specialization: iconRotate(icon, angle)
	if self.icons[icon] then 
		self.icons[icon].UITexture:SetRotation(angle / 180 * math.pi)
	end
end

function Specialization: iconCooldownColor(icon, r, g, b, alpha)
	if self.icons[icon] then 
		self.icons[icon].cooldown_color = {r or 0, g or 0, b or 0, alpha or 0.75}
	end
end

function Specialization: iconCooldownReverse(icon, reversed)
	if type(reversed) ~= "nil" then 
		if self.icons[icon] then 
			self.icons[icon].cooldown_reverse = reversed 
		end
	end
end

function Specialization: iconCooldownNumber(icon, number)
	if self.icons[icon] then 
		self.icons[icon].cooldown_number = number
	end
end

function Specialization: iconCooldownEdge(icon, edge)
	if self.icons[icon] then 
		self.icons[icon].cooldown_edge = edge
	end
end
function Specialization: hideAllIcons()
	for i, v in ipairs(self.icons) do
		v.UIFrame:Hide()
	end
end

function Specialization: showAllIcons()
	for i, v in ipairs(self.icons) do
		if v.show then 
			v.UIFrame:Show()
		end
	end
end

function Specialization: refreshUI()
	for _, v in ipairs(self.icons) do
		if v.width and v.height then 
			v.UIFrame: SetWidth(v.width * self.ui_ratio)
			v.UIFrame: SetHeight(v.height * self.ui_ratio)
		else
			v.UIFrame: SetWidth(v.size * self.ui_ratio)
			v.UIFrame: SetHeight(v.size * self.ui_ratio)
		end
		v.UIFrame: SetPoint(v.anchor, "UIParent", "CENTER", 
							self.anchor_x + v.x * self.ui_ratio, self.anchor_y + v.y * self.ui_ratio)
		v.UIFrame:SetBackdropColor(unpack(v.backdrop_color or {0, 0, 0, 1}))
		
		v.UITexture:SetTexture(v.texture, true)
		v.UITexture:SetVertexColor(unpack(v.color or {1, 1, 1, 1}))
		
		v.UICd:SetDrawEdge(v.cooldown_edge)
		v.UICd:SetReverse(v.cooldown_reverse) 
		v.UICd:SetDrawBling(false)
		v.UICd:SetSwipeColor(unpack(v.cooldown_color or {0, 0, 0, 0.75}))
		
		if v.desaturate then 
			v.UITexture:SetDesaturated(1)
		else 
			v.UITexture:SetDesaturated(nil)
		end
		
		if v.glow then 
			ActionButton_ShowOverlayGlow(v.UIFrame)
		else 
			ActionButton_HideOverlayGlow(v.UIFrame)
		end
		
		if v.show then 
			v.UIFrame:Show()
		else
			v.UIFrame:Hide()
		end
	end
	for _, v in ipairs(self.texts) do
		--print(v.parent)
		v.UIText: SetPoint(	"CENTER", v.parent, "CENTER", v.x * self.ui_ratio, v.y * self.ui_ratio)
	end
	
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