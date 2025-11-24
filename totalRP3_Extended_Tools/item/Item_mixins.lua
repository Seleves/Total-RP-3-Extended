local _, addon = ...
local loc = TRP3_API.loc;

TRP3_Tools_EditorItemMixin = CreateFromMixins(TRP3_Tools_EditorObjectMixin);

function TRP3_Tools_EditorItemMixin:OnSizeChanged()
	self.display.preview.Name:SetWidth(self:GetWidth()/8);
	self.display.preview.InfoText:SetWidth(self:GetWidth()/8);
end

function TRP3_Tools_EditorItemMixin:Initialize()
	local s = self;
	
	--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
	-- DISPLAY
	--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

	-- Display
	local display = self.display;
	
	display.name:SetScript("OnTextChanged", function()
		s:UpdatePreviews();
	end);

	display.left:SetupSuggestions("Tag", addon.editor.populateObjectTagMenu);
	display.right:SetupSuggestions("Tag", addon.editor.populateObjectTagMenu);
	display.description:SetupSuggestions("Tag", addon.editor.populateObjectTagMenu);

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
		addon.modal:ShowModal(TRP3_API.popup.ICONS, {function(icon) s:UpdatePreviews(icon); end, nil, nil, display.preview.selectedIcon});
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
	local gameplay = self.gameplay;
	
	-- Value edit box title != tooltip title
	gameplay.value.title:SetText(loc.IT_TT_VALUE_FORMAT:format(TRP3_API.utils.str.texture("Interface\\MONEYFRAME\\UI-CopperIcon", 15)));
	
	-- Weight edit box title != tooltip title
	gameplay.weight.title:SetText(loc.IT_TT_WEIGHT_FORMAT);

	gameplay.usetext:SetupSuggestions("Tag", addon.editor.populateObjectTagMenu);

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

	display.inspectVariables:SetScript("OnClick", function() 
		local absoluteId = addon.editor.getCurrentObjectAbsoluteId();
		addon.modal:ShowModal(TRP3_API.popup.VARIABLE_INSPECTOR, {absoluteId, TRP3_DB.types.ITEM});
	end);

end

function TRP3_Tools_EditorItemMixin:ClassToInterface(class, _, cursor)
	local BA = class.BA or TRP3_API.globals.empty;
	local US = class.US or TRP3_API.globals.empty;
	
	self.display.name:SetText(BA.NA or "");
	self.display.description:SetText(BA.DE or "");
	self.display.quality:SetSelectedValue(BA.QA or Enum.ItemQuality.Common);
	self.display.left:SetText(BA.LE or "");
	self.display.right:SetText(BA.RI or "");
	self.gameplay.component:SetChecked(BA.CO or false);
	self.gameplay.crafted:SetChecked(BA.CR or false);
	self.gameplay.quest:SetChecked(BA.QE or false);
	
	self.gameplay.value:SetText(BA.VA or "0");
	self.gameplay.weight:SetText(BA.WE or "0");
	self.gameplay.soulbound:SetChecked(BA.SB or false);
	self.gameplay.unique:SetChecked((BA.UN or 0) > 0);
	self.gameplay.uniquecount:SetText(BA.UN or "1");
	self.gameplay.stack:SetChecked((BA.ST or 0) > 0);
	self.gameplay.stackcount:SetText(BA.ST or "20");
	self.gameplay.use:SetChecked(BA.US or false);
	self.gameplay.usetext:SetText(US.AC or "");
	self.gameplay.wearable:SetChecked(BA.WA or false);
	self.display.container:SetChecked(BA.CT or false);
	self.gameplay.noAdd:SetChecked(BA.PA or false);
	self.gameplay.mute = true;
	self.gameplay.pickSound:SetSelectedValue(BA.PS or 1186);
	self.gameplay.dropSound:SetSelectedValue(BA.DS or 1203);
	self.gameplay.mute = nil;
	
	local containerData = BA.CT and BA.CO or TRP3_API.globals.empty;
	self.display.containerType:SetSelectedValue(containerData.SI or "5x4");
	self.display.containerDurability:SetText(containerData.DU or "0");
	self.display.containerMaxweight:SetText(containerData.MW or "0");
	self.display.containerOnlyinner:SetChecked(containerData.OI or false);
	
	self:UpdatePreviews(BA.IC or "TEMP");

	self:UpdateElementVisibility();

	self.display.inspectVariables:SetShown(TRP3_API.extended.isObjectMine(addon.getCurrentDraftCreationId()));
	
end

function TRP3_Tools_EditorItemMixin:InterfaceToClass(targetClass, targetCursor)
	targetClass.BA = targetClass.BA or {};
	targetClass.US = targetClass.US or {};
	
	targetClass.BA.NA = TRP3_API.utils.str.emptyToNil(strtrim(self.display.name:GetText()));
	targetClass.BA.DE = TRP3_API.utils.str.emptyToNil(strtrim(self.display.description:GetText()));
	targetClass.BA.LE = TRP3_API.utils.str.emptyToNil(strtrim(self.display.left:GetText()));
	targetClass.BA.RI = TRP3_API.utils.str.emptyToNil(strtrim(self.display.right:GetText()));
	targetClass.BA.QA = self.display.quality:GetSelectedValue() or Enum.ItemQuality.Common;
	targetClass.BA.CO = self.gameplay.component:GetChecked();
	targetClass.BA.CR = self.gameplay.crafted:GetChecked();
	targetClass.BA.QE = self.gameplay.quest:GetChecked();
	targetClass.BA.IC = self.display.preview.selectedIcon;
	targetClass.BA.VA = tonumber(self.gameplay.value:GetText()) or 0;
	targetClass.BA.WE = tonumber(self.gameplay.weight:GetText()) or 0;
	targetClass.BA.SB = self.gameplay.soulbound:GetChecked();
	targetClass.BA.UN = self.gameplay.unique:GetChecked() and tonumber(self.gameplay.uniquecount:GetText());
	targetClass.BA.ST = self.gameplay.stack:GetChecked() and tonumber(self.gameplay.stackcount:GetText());
	targetClass.BA.WA = self.gameplay.wearable:GetChecked();
	targetClass.BA.CT = self.display.container:GetChecked();
	targetClass.BA.PA = self.gameplay.noAdd:GetChecked();
	targetClass.BA.US = self.gameplay.use:GetChecked();
	if targetClass.BA.US then
		targetClass.US.AC = TRP3_API.utils.str.emptyToNil(strtrim(self.gameplay.usetext:GetText()));
		targetClass.US.SC = "onUse";
	else
		targetClass.US.AC = nil;
		targetClass.US.SC = nil;
	end
	targetClass.BA.PS = self.gameplay.pickSound:GetSelectedValue() or 1186;
	targetClass.BA.DS = self.gameplay.dropSound:GetSelectedValue() or 1203;
	
	if targetClass.BA.CT then
		targetClass.CO = targetClass.CO or {};
		targetClass.CO.SI = self.display.containerType:GetSelectedValue() or "5x4";
		local row, column = targetClass.CO.SI:match("(%d)x(%d)");
		targetClass.CO.SR = row;
		targetClass.CO.SC = column;
		targetClass.CO.DU = tonumber(self.display.containerDurability:GetText());
		targetClass.CO.MW = tonumber(self.display.containerMaxweight:GetText());
		targetClass.CO.OI = self.display.containerOnlyinner:GetChecked() or false;
	elseif targetClass.CO then
		-- TODO not sure if intended, but previously, these fields were not cleared if an item is changed from container item to regular item
		wipe(targetClass.CO);
		targetClass.CO = nil;
	end
	
end

function TRP3_Tools_EditorItemMixin:UpdatePreviews(icon)
	icon = icon or self.display.preview.selectedIcon;
	self.display.preview.Icon:SetTexture("Interface\\ICONS\\" .. (icon or "TEMP"));
	self.display.preview.selectedIcon = icon or "TEMP";
	
	local durability = "";
	local durabilityValue = tonumber(self.display.containerDurability:GetText());
	if durabilityValue and durabilityValue > 0 then
		durability = (TRP3_API.utils.str.texture("Interface\\GROUPFRAME\\UI-GROUP-MAINTANKICON", 15) .. "%s/%s"):format(durabilityValue, durabilityValue);
	end
	
	for _, bagPreview in pairs({"bag5x4", "bag2x4", "bag1x4"}) do
		local preview = self.display[bagPreview];
		TRP3_API.inventory.decorateContainer(preview, {
			BA = {
				IC = icon,
				NA = TRP3_API.utils.str.emptyToNil(strtrim(self.display.name:GetText()))
			}
		});
		preview.DurabilityText:SetText(durability);
		preview.WeightText:SetText(TRP3_API.extended.formatWeight(0) .. TRP3_API.utils.str.texture("Interface\\GROUPFRAME\\UI-Group-MasterLooter", 15));
	end
	
end

function TRP3_Tools_EditorItemMixin:UpdateElementVisibility()
	self.gameplay.uniquecount:Hide();
	self.gameplay.stackcount:Hide();
	self.gameplay.usetext:Hide();
	self.display.preview.Quest:Hide();
	if self.gameplay.unique:GetChecked() then
		self.gameplay.uniquecount:Show();
	end
	if self.gameplay.stack:GetChecked() then
		self.gameplay.stackcount:Show();
	end
	if self.gameplay.use:GetChecked() then
		self.gameplay.usetext:Show();
	end
	if self.gameplay.quest:GetChecked() then
		self.display.preview.Quest:Show();
	end
	
	self.display.bag5x4:Hide();
	self.display.bag2x4:Hide();
	self.display.bag1x4:Hide();
	
	if self.display.container:GetChecked() then
		self.display.containerType:Show();
		self.display.containerDurability:Show();
		self.display.containerMaxweight:Show();
		self.display.containerOnlyinner:Show();
		local size = self.display.containerType:GetSelectedValue() or "5x4"
		if size == "5x4" then
			self.display.bag5x4:Show();
		elseif size == "2x4" then
			self.display.bag2x4:Show();
		elseif size == "1x4" then
			self.display.bag1x4:Show();
		end
	else
		self.display.containerType:Hide();
		self.display.containerDurability:Hide();
		self.display.containerMaxweight:Hide();
		self.display.containerOnlyinner:Hide();
	end
end

function TRP3_Tools_EditorItemMixin:OnScriptsChanged(changes)
	-- TODO presence of an "onUse" workflow and Usable should be equivalent, so both things should be linked
	-- on the other hand, the UI should probably not auto-sync those settings.
	-- temporary solution: activate Usable when the user creates an onUse, but don't deactivate if onUse is deleted
	if not self.gameplay.use:GetChecked() and addon.editor.script:HasScriptForTrigger("OU", addon.script.triggerType.OBJECT) then
		self.gameplay.use:SetChecked(true);
		self:UpdateElementVisibility();
	end
end
