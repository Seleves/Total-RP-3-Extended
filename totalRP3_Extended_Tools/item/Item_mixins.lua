local loc = TRP3_API.loc;

TRP3_Tools_EditorItemMixin = CreateFromMixins(TRP3_Tools_EditorObjectMixin);

function TRP3_Tools_EditorItemMixin:OnSizeChanged()
	if self:GetHeight() < self.content:GetHeight() then
		self:SetPoint("BOTTOMRIGHT", -16, 0);
	else
		self:SetPoint("BOTTOMRIGHT", 0, 0);
	end
	self.content:SetWidth(self:GetWidth());
	self.content.display.preview.Name:SetWidth(self:GetWidth()/8);
	self.content.display.preview.InfoText:SetWidth(self:GetWidth()/8);
end

function TRP3_Tools_EditorItemMixin:Initialize()
	
	local s = self;
	
	self.ScrollBar:SetHideIfUnscrollable(true);
	
	
	--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
	-- DISPLAY
	--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

	-- Display
	local display = self.content.display;
	
	display.name:SetScript("OnTextChanged", function()
		s:UpdatePreviews();
	end);

	-- Quality
	local qualityList = {
		{TRP3_API.inventory.getQualityColorText(Enum.ItemQuality.Poor) .. ITEM_QUALITY0_DESC, Enum.ItemQuality.Poor},
		{TRP3_API.inventory.getQualityColorText(Enum.ItemQuality.Common) .. ITEM_QUALITY1_DESC, Enum.ItemQuality.Common},
		{TRP3_API.inventory.getQualityColorText(Enum.ItemQuality.Uncommon) .. ITEM_QUALITY2_DESC, Enum.ItemQuality.Uncommon},
		{TRP3_API.inventory.getQualityColorText(Enum.ItemQuality.Rare) .. ITEM_QUALITY3_DESC, Enum.ItemQuality.Rare},
		{TRP3_API.inventory.getQualityColorText(Enum.ItemQuality.Epic) .. ITEM_QUALITY4_DESC, Enum.ItemQuality.Epic},
		{TRP3_API.inventory.getQualityColorText(Enum.ItemQuality.Legendary) .. ITEM_QUALITY5_DESC, Enum.ItemQuality.Legendary},
		{TRP3_API.inventory.getQualityColorText(Enum.ItemQuality.Artifact) .. ITEM_QUALITY6_DESC, Enum.ItemQuality.Artifact},
		{TRP3_API.inventory.getQualityColorText(Enum.ItemQuality.Heirloom) .. ITEM_QUALITY7_DESC, Enum.ItemQuality.Heirloom},
	};
	TRP3_API.ui.listbox.setupListBox(display.quality, qualityList);

	local containerTypes = {
		{loc.IT_CO_SIZE_COLROW:format(5, 4), "5x4"},
		{loc.IT_CO_SIZE_COLROW:format(2, 4), "2x4"},
		{loc.IT_CO_SIZE_COLROW:format(1, 4), "1x4"},
	};
	-- Container Size
	TRP3_API.ui.listbox.setupListBox(display.containerType, containerTypes, function() s:UpdateElementVisibility(); end);
	
	-- Container Durability
	display.containerDurability:SetScript("OnTextChanged", function() s:UpdatePreviews(); end);
	
	-- Preview
	display.preview:SetScript("OnEnter", function(self)
		local tempObject = {};
		s:InterfaceToClass(tempObject);
		TRP3_API.inventory.showItemTooltip(self, {madeBy = TRP3_API.globals.player_id}, tempObject, true);
	end);
	display.preview:SetScript("OnLeave", function(self)
		TRP3_ItemTooltip:Hide();
	end);
	display.preview:SetScript("OnClick", function(self)
		TRP3_API.popup.showPopup(
			TRP3_API.popup.ICONS, 
			{parent = TRP3_ToolFrame, point = "CENTER", parentPoint = "CENTER"}, 
			{function(icon) s:UpdatePreviews(icon); end, nil, nil, display.preview.selectedIcon}
		);
	end);
	
	for _, bagPreview in pairs({"bag5x4", "bag2x4", "bag1x4"}) do
		local preview = display[bagPreview];
		preview.close:Disable();
		preview.LockIcon:Hide();
		if bagPreview == "bag5x4" then
			preview:SetScale(0.5);
		else
			preview:SetScale(0.75);
		end
	end

	--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
	-- Gameplay
	--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

	-- Gameplay
	local gameplay = self.content.gameplay;
	
	-- Value edit box title != tooltip title
	gameplay.value.title:SetText(loc.IT_TT_VALUE_FORMAT:format(TRP3_API.utils.str.texture("Interface\\MONEYFRAME\\UI-CopperIcon", 15)));
	
	-- Weight edit box title != tooltip title
	gameplay.weight.title:SetText(loc.IT_TT_WEIGHT_FORMAT);

	-- Pick up sound
	local pickUpList = {};
	for i = 1183, 1199 do
		tinsert(pickUpList, {loc["IT_PU_SOUND_" .. i], i});
	end
	tinsert(pickUpList, {loc["IT_PU_SOUND_".. 1221], 1221});
	TRP3_API.ui.listbox.setupListBox(gameplay.pickSound, pickUpList, function(value)
		if not gameplay.mute then
			TRP3_API.ui.misc.playSoundKit(value, "SFX");
		end
	end);

	-- Drop sound
	local dropList = {};
	for i = 1200, 1217 do
		tinsert(dropList, {loc["IT_DR_SOUND_" .. i], i});
	end
	TRP3_API.ui.listbox.setupListBox(gameplay.dropSound, dropList, function(value)
		if not gameplay.mute then
			TRP3_API.ui.misc.playSoundKit(value, "SFX");
		end
	end);

	local onCheckClicked = function()
		self:UpdateElementVisibility();
	end
	gameplay.unique:SetScript("OnClick", onCheckClicked);
	gameplay.stack:SetScript("OnClick", onCheckClicked);
	gameplay.use:SetScript("OnClick", onCheckClicked);
	display.container:SetScript("OnClick", onCheckClicked);
	gameplay.quest:SetScript("OnClick", onCheckClicked);

end

function TRP3_Tools_EditorItemMixin:ClassToInterface(class)
	local BA = class.BA or TRP3_API.globals.empty;
	local US = class.US or TRP3_API.globals.empty;
	
	self.content.display.name:SetText(BA.NA or "");
	self.content.display.description:SetText(BA.DE or "");
	self.content.display.quality:SetSelectedValue(BA.QA or Enum.ItemQuality.Common);
	self.content.display.left:SetText(BA.LE or "");
	self.content.display.right:SetText(BA.RI or "");
	self.content.gameplay.component:SetChecked(BA.CO or false);
	self.content.gameplay.crafted:SetChecked(BA.CR or false);
	self.content.gameplay.quest:SetChecked(BA.QE or false);
	
	self.content.gameplay.value:SetText(BA.VA or "0");
	self.content.gameplay.weight:SetText(BA.WE or "0");
	self.content.gameplay.soulbound:SetChecked(BA.SB or false);
	self.content.gameplay.unique:SetChecked((BA.UN or 0) > 0);
	self.content.gameplay.uniquecount:SetText(BA.UN or "1");
	self.content.gameplay.stack:SetChecked((BA.ST or 0) > 0);
	self.content.gameplay.stackcount:SetText(BA.ST or "20");
	self.content.gameplay.use:SetChecked(BA.US or false);
	self.content.gameplay.usetext:SetText(US.AC or "");
	self.content.gameplay.wearable:SetChecked(BA.WA or false);
	self.content.display.container:SetChecked(BA.CT or false);
	self.content.gameplay.noAdd:SetChecked(BA.PA or false);
	self.content.gameplay.mute = true;
	self.content.gameplay.pickSound:SetSelectedValue(BA.PS or 1186);
	self.content.gameplay.dropSound:SetSelectedValue(BA.DS or 1203);
	self.content.gameplay.mute = nil;
	
	local containerData = BA.CT and BA.CO or TRP3_API.globals.empty;
	self.content.display.containerType:SetSelectedValue(containerData.SI or "5x4");
	self.content.display.containerDurability:SetText(containerData.DU or "0");
	self.content.display.containerMaxweight:SetText(containerData.MW or "0");
	self.content.display.containerOnlyinner:SetChecked(containerData.OI or false);
	
	self:UpdatePreviews(BA.IC);

	self:UpdateElementVisibility();
	
end

function TRP3_Tools_EditorItemMixin:InterfaceToClass(targetClass)
	targetClass.BA = targetClass.BA or {};
	targetClass.US = targetClass.US or {};
	
	targetClass.BA.NA = TRP3_API.utils.str.emptyToNil(strtrim(self.content.display.name:GetText()));
	targetClass.BA.DE = TRP3_API.utils.str.emptyToNil(strtrim(self.content.display.description:GetText()));
	targetClass.BA.LE = TRP3_API.utils.str.emptyToNil(strtrim(self.content.display.left:GetText()));
	targetClass.BA.RI = TRP3_API.utils.str.emptyToNil(strtrim(self.content.display.right:GetText()));
	targetClass.BA.QA = self.content.display.quality:GetSelectedValue() or Enum.ItemQuality.Common;
	targetClass.BA.CO = self.content.gameplay.component:GetChecked();
	targetClass.BA.CR = self.content.gameplay.crafted:GetChecked();
	targetClass.BA.QE = self.content.gameplay.quest:GetChecked();
	targetClass.BA.IC = self.content.display.preview.selectedIcon;
	targetClass.BA.VA = tonumber(self.content.gameplay.value:GetText()) or 0;
	targetClass.BA.WE = tonumber(self.content.gameplay.weight:GetText()) or 0;
	targetClass.BA.SB = self.content.gameplay.soulbound:GetChecked();
	targetClass.BA.UN = self.content.gameplay.unique:GetChecked() and tonumber(self.content.gameplay.uniquecount:GetText());
	targetClass.BA.ST = self.content.gameplay.stack:GetChecked() and tonumber(self.content.gameplay.stackcount:GetText());
	targetClass.BA.WA = self.content.gameplay.wearable:GetChecked();
	targetClass.BA.CT = self.content.display.container:GetChecked();
	targetClass.BA.PA = self.content.gameplay.noAdd:GetChecked();
	targetClass.BA.US = self.content.gameplay.use:GetChecked();
	targetClass.US.AC = TRP3_API.utils.str.emptyToNil(strtrim(self.content.gameplay.usetext:GetText()));
	targetClass.US.SC = "onUse";
	targetClass.BA.PS = self.content.gameplay.pickSound:GetSelectedValue() or 1186;
	targetClass.BA.DS = self.content.gameplay.dropSound:GetSelectedValue() or 1203;
	
	if targetClass.BA.CT then
		targetClass.CO = targetClass.CO or {};
		targetClass.CO.SI = self.content.display.containerType:GetSelectedValue() or "5x4";
		local row, column = targetClass.CO.SI:match("(%d)x(%d)");
		targetClass.CO.SR = row;
		targetClass.CO.SC = column;
		targetClass.CO.DU = tonumber(self.content.display.containerDurability:GetText());
		targetClass.CO.MW = tonumber(self.content.display.containerMaxweight:GetText());
		targetClass.CO.OI = self.content.display.containerOnlyinner:GetChecked() or false;
	elseif targetClass.CO then
		-- TODO not sure if intended, but previously, these fields were not cleared if an item is changed from container item to regular item
		wipe(targetClass.CO);
		targetClass.CO = nil;
	end
	
end

function TRP3_Tools_EditorItemMixin:UpdatePreviews(icon)
	icon = icon or self.content.display.preview.selectedIcon;
	self.content.display.preview.Icon:SetTexture("Interface\\ICONS\\" .. (icon or "TEMP"));
	self.content.display.preview.selectedIcon = icon;
	
	local durability = "";
	local durabilityValue = tonumber(self.content.display.containerDurability:GetText());
	if durabilityValue and durabilityValue > 0 then
		durability = (TRP3_API.utils.str.texture("Interface\\GROUPFRAME\\UI-GROUP-MAINTANKICON", 15) .. "%s/%s"):format(durabilityValue, durabilityValue);
	end
	
	for _, bagPreview in pairs({"bag5x4", "bag2x4", "bag1x4"}) do
		local preview = self.content.display[bagPreview];
		TRP3_API.inventory.decorateContainer(preview, {
			BA = {
				IC = icon,
				NA = TRP3_API.utils.str.emptyToNil(strtrim(self.content.display.name:GetText()))
			}
		});
		preview.DurabilityText:SetText(durability);
		preview.WeightText:SetText(TRP3_API.extended.formatWeight(0) .. TRP3_API.utils.str.texture("Interface\\GROUPFRAME\\UI-Group-MasterLooter", 15));
	end
	
	
end

function TRP3_Tools_EditorItemMixin:UpdateElementVisibility()
	self.content.gameplay.uniquecount:Hide();
	self.content.gameplay.stackcount:Hide();
	self.content.gameplay.usetext:Hide();
	self.content.display.preview.Quest:Hide();
	if self.content.gameplay.unique:GetChecked() then
		self.content.gameplay.uniquecount:Show();
	end
	if self.content.gameplay.stack:GetChecked() then
		self.content.gameplay.stackcount:Show();
	end
	if self.content.gameplay.use:GetChecked() then
		self.content.gameplay.usetext:Show();
	end
	if self.content.gameplay.quest:GetChecked() then
		self.content.display.preview.Quest:Show();
	end
	
	self.content.display.bag5x4:Hide();
	self.content.display.bag2x4:Hide();
	self.content.display.bag1x4:Hide();
	
	if self.content.display.container:GetChecked() then
		self.content.display.containerType:Show();
		self.content.display.containerDurability:Show();
		self.content.display.containerMaxweight:Show();
		self.content.display.containerOnlyinner:Show();
		local size = self.content.display.containerType:GetSelectedValue() or "5x4"
		if size == "5x4" then
			self.content.display.bag5x4:Show();
		elseif size == "2x4" then
			self.content.display.bag2x4:Show();
		elseif size == "1x4" then
			self.content.display.bag1x4:Show();
		end
	else
		self.content.display.containerType:Hide();
		self.content.display.containerDurability:Hide();
		self.content.display.containerMaxweight:Hide();
		self.content.display.containerOnlyinner:Hide();
	end
end
