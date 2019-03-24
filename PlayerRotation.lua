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
	self.status = {}
	self.icons = {}
	
	self:updateTalent()
	self.azerite = self:getAzeriteInfo()
	
	self.rc = LibStub("LibRangeCheck-2.0")	-- range check
	
	self.anchor_x = 0
	self.anchor_y = 0
	self.size = 50
	self.ui_ratio = 1
	
	self.button = CreateFrame("Button", "SR_main_button", UIParent, "ActionButtonTemplate")
	self.button: Disable()
	self.button: SetNormalTexture(self.button: GetHighlightTexture())
	self.button: Show()
	--self.button = self:createIcon(nil, self.size, 0, 0)
	
	self.text = self.button:CreateFontString("SR_main_button_text","OVERLAY")
	self.text:SetFont("Fonts\\FRIZQT__.ttf", 24, "THICKOUTLINE")
	self.text:SetTextColor(1, 1, 1)
	--self.text:SetAllPoints(self.button)
	self.text:SetJustifyH("CENTER")
	self.text:SetJustifyV("MIDDLE")
	self.text:SetText("")
	
	self.overlay = self.button:CreateTexture("SR_main_button_overlay")
	self.overlay:SetAllPoints(self.button)
	self.overlay:SetColorTexture(.5, .5, 0, 0)

	self:refreshUI()
end
function PlayerRotation: createIcon(texture, size, x, y, cd)
	local icon = {}
	--icon.name = name
	icon.texture = texture
	icon.size = size or 50
	icon.x = x or 0
	icon.y = y or 0
	
	icon.UIFrame = CreateFrame("Frame", nil, UIParent)
	icon.UIFrame:SetFrameStrata("BACKGROUND")
	icon.UIFrame:SetWidth(icon.size)
	icon.UIFrame:SetHeight(icon.size)
	
	icon.UITexture = icon.UIFrame:CreateTexture(nil,"MEDIUM")
	icon.UITexture:SetTexture(icon.texture)
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
function PlayerRotation: iconConfig(icon, texture, size, x, y)
	icon.texture = texture or icon.texture
	icon.size = size or icon.size
	icon.x = x or icon.x
	icon.y = y or icon.y
	self:refreshUI()
end
function PlayerRotation: iconCooldown(icon, start, duration)
	self.icons[icon].UICd:SetCooldown(start, duration)
end
function PlayerRotation: iconGlow(icon)
	ActionButton_ShowOverlayGlow(self.icons[icon].UIFrame)
end
function PlayerRotation: iconHideGlow(icon)
	ActionButton_HideOverlayGlow(self.icons[icon].UIFrame)
end
function PlayerRotation: iconColor(icon, r, g, b, alpha)
	r = r or 1
	g = g or 1
	b = b or 1
	alpha = alpha or 1
	self.icons[icon].UITexture:SetVertexColor(r, g, b, alpha)
end

function PlayerRotation: enable()
	self.button: Show()
	for _, v in ipairs(self.icons) do
		v.UIFrame: Show()
	end
	self.enabled = true
end
function PlayerRotation: isEnabled()
	return self.enabled
end

function PlayerRotation: disable()
	self.button: Hide()
	for _, v in ipairs(self.icons) do
		v.UIFrame: Hide()
	end
	self.enabled = false
end
function PlayerRotation: setSize(size)
	self.size = size or self.size
	self.ui_ratio = self.size / 50
	self:refreshUI()
end
function PlayerRotation: getSize()
	return self.size
end
function PlayerRotation: setPosition(x, y)
	self.anchor_x = x or self.anchor_x
	self.anchor_y = y or self.anchor_y
	self:refreshUI()
end
function PlayerRotation: getPosition()
	return self.anchor_x, self.anchor_y
end
function PlayerRotation: refreshUI()
	self.button: SetSize(self.size,self.size)
	self.button: SetPoint("CENTER", self.anchor_x, self.anchor_y)
	self.button: Show()
	self.text: SetPoint("CENTER", 2 * self.ui_ratio, 40 * self.ui_ratio)
	
	for _, v in ipairs(self.icons) do
		v.UIFrame: SetWidth(v.size * self.ui_ratio)
		v.UIFrame: SetHeight(v.size * self.ui_ratio)
		v.UIFrame: SetPoint("CENTER", self.anchor_x + v.x * self.ui_ratio, self.anchor_y + v.y * self.ui_ratio)
		v.UIFrame: Show()
	end

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
function PlayerRotation: getAzeriteInfo()
	local azerite = LabeledMatrix()
	azerite:addRow("rank")
	
	local slot = {1, 3, 5}
	for _, i in ipairs(slot) do
		local item = Item:CreateFromEquipmentSlot(i)
		if (not item:IsItemEmpty()) then
			local itemLoc = ItemLocation:CreateFromEquipmentSlot(i)
			if itemLoc then  
				if C_AzeriteEmpoweredItem.IsAzeriteEmpoweredItem(itemLoc) then 
					local tierInfo = C_AzeriteEmpoweredItem.GetAllTierInfo(itemLoc)
					for tier, info in pairs(tierInfo) do
						for _, powerId in pairs(info.azeritePowerIDs) do
							if C_AzeriteEmpoweredItem.IsPowerSelected(itemLoc, powerId) then 
								local r = azerite:get("rank", powerId)
								if not r then 
									azerite:addColumn(powerId)
								end
								--print(tostring(powerId))
								azerite:update("rank", powerId, ( r or 0 ) + 1)
							end
						end
					end
				end
			end
		end
	end
	return azerite
end
function PlayerRotation: getAzeriteRank(powerId)
	if not powerId then return nil end
	if not self.azerite then 
		self.azerite = self:getAzeriteInfo()
	end
	return self.azerite: get("rank", powerId)
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
		local time_to_kill = math.ceil(self.player: timeToKill())
		--self.text:SetText(time_to_kill > 0 and tostring(time_to_kill) or "")
		self.text:SetText(self.player: getCleaveTargets())
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