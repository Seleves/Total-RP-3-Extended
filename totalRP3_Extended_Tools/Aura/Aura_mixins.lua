local _, addon = ...
local loc = TRP3_API.loc;

TRP3_Tools_EditorAuraMixin = CreateFromMixins(TRP3_Tools_EditorObjectMixin);

function TRP3_Tools_EditorAuraMixin:OnSizeChanged()
	if self:GetHeight() < self.content:GetHeight() then
		self:SetPoint("BOTTOMRIGHT", -16, 0);
	else
		self:SetPoint("BOTTOMRIGHT", 0, 0);
	end
	self.content:SetWidth(self:GetWidth());
end

function TRP3_Tools_EditorAuraMixin:OnIconSelected(icon)
	self.content.display.preview.aura.class.BA.IC = icon;
	self.content.display.preview:SetAuraAndShow(self.content.display.preview.aura);
end

function TRP3_Tools_EditorAuraMixin:Initialize()
	self.ScrollBar:SetHideIfUnscrollable(true);
	local s = self;

	local display = self.content.display;
	local gameplay = self.content.gameplay;

	local presetBuffs = {
		{category = ""                   , color = nil     , helpful = true},
		{category = loc.AU_PRESET_CURSE  , color = "9600ff", helpful = false},
		{category = loc.AU_PRESET_DISEASE, color = "966400", helpful = false},
		{category = loc.AU_PRESET_MAGIC  , color = "3296ff", helpful = false},
		{category = loc.AU_PRESET_POISON , color = "009600", helpful = false},
		{category = ""                   , color = "c80000", helpful = false},
	};
	local presetMenu = {
		{"|cffffffff" .. loc.AU_PRESET_BUFF    .. "|r", 1},
		{"|cff9600ff" .. loc.AU_PRESET_CURSE   .. "|r", 2},
		{"|cff966400" .. loc.AU_PRESET_DISEASE .. "|r", 3},
		{"|cff3296ff" .. loc.AU_PRESET_MAGIC   .. "|r", 4},
		{"|cff009600" .. loc.AU_PRESET_POISON  .. "|r", 5},
		{"|cffc80000" .. loc.AU_PRESET_OTHER   .. "|r", 6},
	};
	local applyPreset = function(presetId)
		display.category:SetText(presetBuffs[presetId].category);
		display.helpful:SetChecked(presetBuffs[presetId].helpful);
		if presetBuffs[presetId].color then
			display.borderPicker.setColor(TRP3_API.CreateColorFromHexString(presetBuffs[presetId].color):GetRGBAsBytes());
		else
			display.borderPicker.setColor(nil);
		end
	end
	
	display.overlay:SetScript("OnTextChanged", function()
		display.preview:SetAuraTexts(nil, TRP3_API.utils.str.emptyToNil(strtrim(display.overlay:GetText())));
	end);
	display.overlay:SetupSuggestions(addon.editor.populateObjectTagMenu);

	display.description:SetupSuggestions(addon.editor.populateObjectTagMenu);

	display.preset:SetScript("OnClick", function(self)
		TRP3_MenuUtil.CreateContextMenu(self, function(_, description)
			for _, preset in pairs(presetMenu) do
				description:CreateButton(preset[1], applyPreset, preset[2]);
			end
		end);
	end);

	display.borderPicker.onSelection = function(red, green, blue)
		if red and green and blue then
			display.preview.aura.color = {
				h = TRP3_API.CreateColorFromBytes(red, green, blue):GenerateHexColorOpaque(),
				r = red/255,
				g = green/255,
				b = blue/255,
			};
		else
			display.preview.aura.color = nil;
		end
		display.preview:SetAuraAndShow(display.preview.aura);
	end
	display.borderPicker:SetScript("OnClick", function(self, button)
		if button == "LeftButton" then
			if IsShiftKeyDown() or (TRP3_API.configuration.getValue("default_color_picker")) then
				TRP3_API.popup.showDefaultColorPicker({self.setColor, self.red, self.green, self.blue});
			else
				TRP3_API.popup.showPopup(TRP3_API.popup.COLORS, {parent = TRP3_ToolFrame}, {self.setColor, self.red, self.green, self.blue});
			end
		elseif button == "RightButton" then
			self.setColor(nil, nil, nil);
		end
	end);
	TRP3_API.ui.tooltip.setTooltipForSameFrame(display.borderPicker, "RIGHT", 0, 5, loc.AU_FIELD_COLOR, loc.AU_FIELD_COLOR_TT
	.. "|n|n" .. TRP3_API.FormatShortcutWithInstruction("LCLICK", loc.REG_PLAYER_COLOR_TT_SELECT)
	.. "|n" .. TRP3_API.FormatShortcutWithInstruction("RCLICK", loc.REG_PLAYER_COLOR_TT_DISCARD)
	.. "|n" .. TRP3_API.FormatShortcutWithInstruction("SHIFT-CLICK", loc.REG_PLAYER_COLOR_TT_DEFAULTPICKER));

	display.preview.aura = {
		persistent = {
			expiry = math.huge,
		},
		class = {
			BA = {
			}
		},
	};
	display.preview:SetScript("OnEnter", function(self)
		display.preview.aura.persistent.expiry = time() + (gameplay.hasDuration:GetChecked() and tonumber(gameplay.duration:GetText()) or math.huge);
		display.preview.aura.class.BA.DE = TRP3_API.script.parseArgs(TRP3_API.utils.str.emptyToNil(strtrim(display.description.scroll.text:GetText())), TRP3_API.globals.empty);
		display.preview.aura.class.BA.NA = TRP3_API.utils.str.emptyToNil(strtrim(display.name:GetText()));
		display.preview.aura.class.BA.CA = TRP3_API.utils.str.emptyToNil(strtrim(display.category:GetText()));
		display.preview.aura.class.BA.FL = TRP3_API.utils.str.emptyToNil(strtrim(display.flavor.scroll.text:GetText()));
		display.preview.aura.class.BA.CC = gameplay.cancellable:GetChecked();
		TRP3_AuraTooltip:Attach(display.preview);
	end);
	display.preview:SetScript("OnMouseUp", function(self)
		TRP3_API.popup.showPopup(
			TRP3_API.popup.ICONS, 
			{parent = TRP3_ToolFrame, point = "CENTER", parentPoint = "CENTER"}, 
			{function(icon) s:OnIconSelected(icon); end, nil, nil, display.preview.aura.class.BA.IC}
		);
	end);

	gameplay.hasDuration:SetScript("OnClick", function()
		if gameplay.hasDuration:GetChecked() then
			local currDuration = tonumber(gameplay.duration:GetText());
			if not currDuration or currDuration >= math.huge or currDuration <= 0 then
				gameplay.duration:SetText("300");
			end
			gameplay.duration:Show();
		else
			gameplay.duration:Hide();
		end
	end)

	gameplay.alwaysActive:SetScript("OnClick", function()
		gameplay.ensureExpiry:SetShown(gameplay.alwaysActive:GetChecked());
	end)

	gameplay.hasInterval:SetScript("OnClick", function()
		if gameplay.hasInterval:GetChecked() then
			local currInterval = tonumber(gameplay.interval:GetText());
			if not currInterval or currInterval >= math.huge or currInterval <= 0 then
				gameplay.interval:SetText("10");
			end
			gameplay.interval:Show();
		else
			gameplay.interval:Hide();
		end
	end)

end

function TRP3_Tools_EditorAuraMixin:ClassToInterface(class, creationClass)
	local BA = class.BA or TRP3_API.globals.empty;

	self.content.display.name:SetText(BA.NA or "");
	self.content.display.category:SetText(BA.CA or "");
	if BA.CO then
		self.content.display.borderPicker.setColor(TRP3_API.CreateColorFromHexString(BA.CO):GetRGBAsBytes());
	else
		self.content.display.borderPicker.setColor(nil);
	end

	self.content.display.description:SetText(BA.DE or "");
	self.content.display.flavor:SetText(BA.FL or "");
	self.content.display.overlay:SetText(BA.OV or "");
	self.content.display.helpful:SetChecked(BA.HE or false);
	self.content.display.preview:SetAuraTexts(nil, BA.OV or "");
	self:OnIconSelected(BA.IC);

	local hasDuration = (BA.DU or math.huge) < math.huge;
	self.content.gameplay.hasDuration:SetChecked(hasDuration);
	self.content.gameplay.duration:SetShown(hasDuration);
	self.content.gameplay.duration:SetText(BA.DU or "300");

	self.content.gameplay.alwaysActive:SetChecked(BA.AA or false);
	self.content.gameplay.ensureExpiry:SetChecked(BA.EE or false);
	self.content.gameplay.ensureExpiry:SetShown(BA.AA);

	self.content.gameplay.boundToCampaign:SetShown(creationClass.TY == TRP3_DB.types.CAMPAIGN);
	self.content.gameplay.boundToCampaign:SetChecked(BA.BC or false);

	self.content.gameplay.cancellable:SetChecked(BA.CC or false);

	local hasInterval = (BA.IV or math.huge) < math.huge;
	self.content.gameplay.hasInterval:SetChecked(hasInterval);
	self.content.gameplay.interval:SetShown(hasInterval);
	self.content.gameplay.interval:SetText(BA.IV or "10");
	self.content.gameplay.inspectable:SetChecked(BA.WE or false);
end

function TRP3_Tools_EditorAuraMixin:InterfaceToClass(targetClass)
	targetClass.BA = targetClass.BA or {};
	
	targetClass.BA.NA = TRP3_API.utils.str.emptyToNil(strtrim(self.content.display.name:GetText()));
	targetClass.BA.CA = TRP3_API.utils.str.emptyToNil(strtrim(self.content.display.category:GetText()));
	local r, g, b = self.content.display.borderPicker.red, self.content.display.borderPicker.green, self.content.display.borderPicker.blue;
	if r and g and b then
		targetClass.BA.CO = TRP3_API.CreateColorFromBytes(r, g, b):GenerateHexColorOpaque();
	else
		targetClass.BA.CO = nil;
	end
	targetClass.BA.DE = TRP3_API.utils.str.emptyToNil(strtrim(self.content.display.description:GetText()));
	targetClass.BA.FL = TRP3_API.utils.str.emptyToNil(strtrim(self.content.display.flavor:GetText()));
	targetClass.BA.OV = TRP3_API.utils.str.emptyToNil(strtrim(self.content.display.overlay:GetText()));
	targetClass.BA.HE = self.content.display.helpful:GetChecked();
	targetClass.BA.IC = self.content.display.preview.aura.class.BA.IC;

	if self.content.gameplay.hasDuration:GetChecked() then
		targetClass.BA.DU = self.content.gameplay.duration:GetNumber();
		if targetClass.BA.DU <= 0 then
			targetClass.BA.DU = nil;
		end
	else
		targetClass.BA.DU = nil;
	end

	targetClass.BA.AA = self.content.gameplay.alwaysActive:GetChecked();
	targetClass.BA.EE = self.content.gameplay.ensureExpiry:GetChecked();
	targetClass.BA.BC = self.content.gameplay.boundToCampaign:GetChecked();
	targetClass.BA.CC = self.content.gameplay.cancellable:GetChecked();
	targetClass.BA.WE = self.content.gameplay.inspectable:GetChecked();

	if self.content.gameplay.hasInterval:GetChecked() then
		targetClass.BA.IV = math.max(self.content.gameplay.interval:GetNumber(), 0.1); -- because I say so
	else
		targetClass.BA.IV = nil;
	end

end
