local _, addon = ...

local loc = TRP3_API.loc;

TRP3_Tools_EditorQuestStepMixin = CreateFromMixins(TRP3_Tools_EditorObjectMixin);

function TRP3_Tools_EditorQuestStepMixin:OnSizeChanged()
	if self:GetHeight() < self.content:GetHeight() then
		self:SetPoint("BOTTOMRIGHT", -16, 0);
	else
		self:SetPoint("BOTTOMRIGHT", 0, 0);
	end
	self.content:SetWidth(self:GetWidth());
end

function TRP3_Tools_EditorQuestStepMixin:Initialize()
	self.ScrollBar:SetHideIfUnscrollable(true);
	self.content.main.pre:SetupSuggestions(addon.editor.populateObjectTagMenu);
	self.content.main.post:SetupSuggestions(addon.editor.populateObjectTagMenu);
end

function TRP3_Tools_EditorQuestStepMixin:ClassToInterface(class, creationClass, cursor)
	local BA = class.BA or TRP3_API.globals.empty;
	self.content.main.pre:SetText(BA.TX or "");
	self.content.main.post:SetText(BA.DX or "");
	self.content.main.auto:SetChecked(BA.IN or false);
	self.content.main.final:SetChecked(BA.FI or false);
end

function TRP3_Tools_EditorQuestStepMixin:InterfaceToClass(targetClass, targetCursor)
	targetClass.BA = targetClass.BA or {};
	targetClass.BA.NA = addon.editor.getCurrentObjectRelativeId(); -- TODO why is this needed?
	targetClass.BA.TX = TRP3_API.utils.str.emptyToNil(strtrim(self.content.main.pre:GetText()));
	targetClass.BA.DX = TRP3_API.utils.str.emptyToNil(strtrim(self.content.main.post:GetText()));
	targetClass.BA.IN = self.content.main.auto:GetChecked();
	targetClass.BA.FI = self.content.main.final:GetChecked();
end
