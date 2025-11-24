local _, addon = ...

local loc = TRP3_API.loc;

TRP3_Tools_EditorQuestStepMixin = CreateFromMixins(TRP3_Tools_EditorObjectMixin);

function TRP3_Tools_EditorQuestStepMixin:Initialize()
	self.main.pre:SetupSuggestions("Tag", addon.editor.populateObjectTagMenu);
	self.main.post:SetupSuggestions("Tag", addon.editor.populateObjectTagMenu);

	self.main.goToStep:SetScript("OnClick", function() 
		local absoluteId = addon.editor.getCurrentObjectAbsoluteId();
		if TRP3_API.extended.classExists(absoluteId) then
			local questAbsoluteId, stepId = addon.utils.splitId(absoluteId);
			local campaignId, questId = addon.utils.splitId(questAbsoluteId);
			local questLog = TRP3_API.quest.getQuestLog()[campaignId];
			if not questLog or not questLog.QUEST or not questLog.QUEST[questId] then
				TRP3_API.quest.startQuest(campaignId, questId);
			end
			if questLog and questLog.QUEST and questLog.QUEST[questId] then
				TRP3_API.quest.goToStep(campaignId, questId, stepId);
			end
		else
			TRP3_API.utils.message.displayMessage("The quest step cannot be activated because it hasn't been saved.", 4);
		end
	end);
end

function TRP3_Tools_EditorQuestStepMixin:ClassToInterface(class, creationClass, cursor)
	local BA = class.BA or TRP3_API.globals.empty;
	self.main.pre:SetText(BA.TX or "");
	self.main.post:SetText(BA.DX or "");
	self.main.auto:SetChecked(BA.IN or false);
	self.main.final:SetChecked(BA.FI or false);
	self.main.goToStep:SetShown(TRP3_API.extended.isObjectMine(addon.getCurrentDraftCreationId()));
end

function TRP3_Tools_EditorQuestStepMixin:InterfaceToClass(targetClass, targetCursor)
	targetClass.BA = targetClass.BA or {};
	targetClass.BA.NA = addon.editor.getCurrentObjectRelativeId(); -- TODO why is this needed?
	targetClass.BA.TX = TRP3_API.utils.str.emptyToNil(strtrim(self.main.pre:GetText()));
	targetClass.BA.DX = TRP3_API.utils.str.emptyToNil(strtrim(self.main.post:GetText()));
	targetClass.BA.IN = self.main.auto:GetChecked();
	targetClass.BA.FI = self.main.final:GetChecked();
end
