local _, addon = ...
local loc = TRP3_API.loc;

TRP3_Tools_EditorObjectRibbonMixin = {};

function TRP3_Tools_EditorObjectRibbonMixin:Initialize()
	self.noteButton:SetScript("OnClick", function()
		addon.modal:ShowModal(TRP3_API.popup.NOTE_EDITOR, {self.NT, function(note) 
			self:SetNote(note);
		end});
	end);
	self.innerObjectsPanel.QU:SetScale(0.8125);
	self.innerObjectsPanel.ST:SetScale(0.8125);
	self.innerObjectsPanel.IT:SetScale(0.8125);
	self.innerObjectsPanel.AU:SetScale(0.8125);
	self.innerObjectsPanel.DO:SetScale(0.8125);
	self.innerObjectsPanel.DI:SetScale(0.8125);
	self.innerObjectsPanel.QU.Icon:SetTexture("Interface\\ICONS\\achievement_quests_completed_07");
	self.innerObjectsPanel.ST.Icon:SetTexture("Interface\\gossipframe\\incompletequesticon");
	self.innerObjectsPanel.IT.Icon:SetTexture("Interface\\ICONS\\inv_misc_generic_craftingreagent04");
	self.innerObjectsPanel.AU.Icon:SetTexture("Interface\\ICONS\\ability_priest_spiritoftheredeemer");
	self.innerObjectsPanel.DO.Icon:SetTexture("Interface\\ICONS\\inv_inscription_scroll");
	self.innerObjectsPanel.DI.Icon:SetTexture("Interface\\ICONS\\ui_chat");
	TRP3_API.ui.tooltip.setTooltipForSameFrame(self.innerObjectsPanel.QU, "BOTTOMRIGHT", 0, 0, loc.IN_INNER_ADD .. ": " .. TRP3_API.extended.tools.getTypeLocale(TRP3_DB.types.QUEST), loc.IN_INNER_HELP);
	TRP3_API.ui.tooltip.setTooltipForSameFrame(self.innerObjectsPanel.ST, "BOTTOMRIGHT", 0, 0, loc.IN_INNER_ADD .. ": " .. TRP3_API.extended.tools.getTypeLocale(TRP3_DB.types.QUEST_STEP), loc.IN_INNER_HELP);
	TRP3_API.ui.tooltip.setTooltipForSameFrame(self.innerObjectsPanel.IT, "BOTTOMRIGHT", 0, 0, loc.IN_INNER_ADD .. ": " .. TRP3_API.extended.tools.getTypeLocale(TRP3_DB.types.ITEM), loc.IN_INNER_HELP);
	TRP3_API.ui.tooltip.setTooltipForSameFrame(self.innerObjectsPanel.AU, "BOTTOMRIGHT", 0, 0, loc.IN_INNER_ADD .. ": " .. TRP3_API.extended.tools.getTypeLocale(TRP3_DB.types.AURA), loc.IN_INNER_HELP);
	TRP3_API.ui.tooltip.setTooltipForSameFrame(self.innerObjectsPanel.DO, "BOTTOMRIGHT", 0, 0, loc.IN_INNER_ADD .. ": " .. TRP3_API.extended.tools.getTypeLocale(TRP3_DB.types.DOCUMENT), loc.IN_INNER_HELP);
	TRP3_API.ui.tooltip.setTooltipForSameFrame(self.innerObjectsPanel.DI, "BOTTOMRIGHT", 0, 0, loc.IN_INNER_ADD .. ": " .. TRP3_API.extended.tools.getTypeLocale(TRP3_DB.types.DIALOG), loc.IN_INNER_HELP);
	self.innerObjectsPanel.QU:SetScript("OnClick", function() 
		addon.editor.requestInnerObject(addon.editor.getCurrentObjectAbsoluteId(), TRP3_DB.types.QUEST);
	end);
	self.innerObjectsPanel.ST:SetScript("OnClick", function() 
		addon.editor.requestInnerObject(addon.editor.getCurrentObjectAbsoluteId(), TRP3_DB.types.QUEST_STEP);
	end);
	self.innerObjectsPanel.IT:SetScript("OnClick", function() 
		addon.editor.requestInnerObject(addon.editor.getCurrentObjectAbsoluteId(), TRP3_DB.types.ITEM);
	end);
	self.innerObjectsPanel.AU:SetScript("OnClick", function() 
		addon.editor.requestInnerObject(addon.editor.getCurrentObjectAbsoluteId(), TRP3_DB.types.AURA);
	end);
	self.innerObjectsPanel.DO:SetScript("OnClick", function() 
		addon.editor.requestInnerObject(addon.editor.getCurrentObjectAbsoluteId(), TRP3_DB.types.DOCUMENT);
	end);
	self.innerObjectsPanel.DI:SetScript("OnClick", function() 
		addon.editor.requestInnerObject(addon.editor.getCurrentObjectAbsoluteId(), TRP3_DB.types.DIALOG);
	end);

	self.documentPreview:SetScript("OnClick", function()
		local temp = {};
		addon.editor.getCurrentPropertiesEditor():InterfaceToClass(temp);
		TRP3_API.extended.document.showDocumentClass(temp, nil);
	end);

	self.cutscenePreview:SetScript("OnClick", function()
		addon.editor.getCurrentPropertiesEditor():SaveCurrentStep();
		local dialogData = {};
		addon.editor.getCurrentPropertiesEditor():InterfaceToClass(dialogData);
		TRP3_API.extended.dialog.startDialog(nil, dialogData);
	end);
	
	self.auraPreview:SetScript("OnEnter", function()
		addon.editor.getCurrentPropertiesEditor():UpdatePreview(true);
		TRP3_AuraTooltip:Attach(self.auraPreview.aura);
	end);

	self.auraPreview:SetScript("OnLeave", function()
		TRP3_AuraTooltip:Detach(self.auraPreview.aura);
	end);

end

function TRP3_Tools_EditorObjectRibbonMixin:ClassToInterface(class)
	self.title:SetText(TRP3_API.extended.tools.getTypeLocale(class.TY));
	self.id:SetText(addon.editor.getCurrentObjectRelativeId());
	self.innerObjectsPanel.QU:SetShown(class.TY == TRP3_DB.types.CAMPAIGN);
	self.innerObjectsPanel.ST:SetShown(class.TY == TRP3_DB.types.QUEST);
	if class.TY == TRP3_DB.types.CAMPAIGN or class.TY == TRP3_DB.types.QUEST then
		self.innerObjectsPanel:SetWidth(137);
	else
		self.innerObjectsPanel:SetWidth(111);
	end
	self.documentPreview:SetShown(class.TY == TRP3_DB.types.DOCUMENT);
	self.cutscenePreview:SetShown(class.TY == TRP3_DB.types.DIALOG);
	self.auraPreview:SetShown(class.TY == TRP3_DB.types.AURA);
	self:SetNote(class.NT);
end

function TRP3_Tools_EditorObjectRibbonMixin:InterfaceToClass(class)
	class.NT = self.NT;
end

function TRP3_Tools_EditorObjectRibbonMixin:SetNote(note)
	self.NT = TRP3_API.utils.str.emptyToNil(strtrim(note or ""));
	if self.NT then
		self.noteButton.text:SetText(TRP3_API.Colors.Yellow(loc.EDITOR_NOTES .. ": ") .. self.NT);
	else
		self.noteButton.text:SetText(TRP3_API.Colors.Yellow(loc.EDITOR_NOTES .. ": ") .. TRP3_API.Colors.Grey("(click to add notes)"));
	end
	TRP3_API.ui.tooltip.setTooltipForSameFrame(self.noteButton, "BOTTOMRIGHT", 0, 0, loc.EDITOR_NOTES, 
		(self.NT or "") .. "\n\n" ..
		TRP3_API.FormatShortcutWithInstruction("LCLICK", "edit free notes")
	);
end

function TRP3_Tools_EditorObjectRibbonMixin:SetAuraPreview(aura)
	self.auraPreview.aura:SetAuraAndShow(aura);
	self.auraPreview.aura:SetAuraTexts(nil, aura.class.BA.OV);
end
