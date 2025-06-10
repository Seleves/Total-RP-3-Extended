local _, addon = ...

local loc = TRP3_API.loc;
local DEFAULT_BG = "Interface\\DRESSUPFRAME\\DressUpBackground-NightElf1";

local function createStep()
	return {
		TX = "Text."
	};
end

TRP3_Tools_EditorCutsceneMixin = CreateFromMixins(TRP3_Tools_EditorObjectMixin);

function TRP3_Tools_EditorCutsceneMixin:OnSizeChanged()
	if self:GetHeight() < self.content:GetHeight() then
		self:SetPoint("BOTTOMRIGHT", -16, 0);
	else
		self:SetPoint("BOTTOMRIGHT", 0, 0);
	end
	self.content:SetWidth(self:GetWidth());
end

function TRP3_Tools_EditorCutsceneMixin:Initialize()

	self.ScrollBar:SetHideIfUnscrollable(true);

	self.content.main.preview:SetScript("OnClick", function()
		self:SaveCurrentStep();
		local dialogData = {};
		self:InterfaceToClass(dialogData);
		TRP3_API.extended.dialog.startDialog(nil, dialogData);
	end);

	TRP3_API.ui.listbox.setupListBox(self.content.step.directionValue, {
		{loc.CM_LEFT, "LEFT"},
		{loc.CM_RIGHT, "RIGHT"},
		{loc.REG_RELATION_NONE, "NONE"}
	});

	self.content.step.backgroundBrowse:SetScript("OnClick", function()
		TRP3_API.popup.showPopup(TRP3_API.popup.IMAGES, {parent = TRP3_ToolFramePopupHolderTODO}, {function(image)
			self.content.step.backgroundValue:SetText(image.url);
		end});
	end);

	self.content.step.imageBrowse:SetScript("OnClick", function()
		TRP3_API.popup.showPopup(TRP3_API.popup.IMAGES, {parent = TRP3_ToolFramePopupHolderTODO}, {function(image)
			self.content.step.imageValue:SetText(image.url);
		end});
	end);

	self.content.step.leftUnitTarget:SetScript("OnClick", function()
		if TRP3_API.utils.str.getUnitNPCID("target") then
			self.content.step.leftUnitValue:SetText(TRP3_API.utils.str.getUnitNPCID("target"));
		end
	end);

	self.content.step.rightUnitTarget:SetScript("OnClick", function()
		if TRP3_API.utils.str.getUnitNPCID("target") then
			self.content.step.rightUnitValue:SetText(TRP3_API.utils.str.getUnitNPCID("target"));
		end
	end);

	self.content.step.direction:SetScript("OnClick", function()
		self.content.step.directionValue:SetShown(self.content.step.direction:GetChecked());
	end);

	self.content.step.name:SetScript("OnClick", function()
		self.content.step.nameValue:SetShown(self.content.step.name:GetChecked());
	end);
	
	self.content.step.background:SetScript("OnClick", function()
		self.content.step.backgroundBrowse:SetShown(self.content.step.background:GetChecked());
		self.content.step.backgroundValue:SetShown(self.content.step.background:GetChecked());
	end);
	
	self.content.step.image:SetScript("OnClick", function()
		self.content.step.imageBrowse:SetShown(self.content.step.image:GetChecked());
		self.content.step.imageValue:SetShown(self.content.step.image:GetChecked());
		self.content.step.imageMore:SetShown(self.content.step.image:GetChecked());
	end);

	self.content.step.leftUnit:SetScript("OnClick", function()
		self.content.step.leftUnitTarget:SetShown(self.content.step.leftUnit:GetChecked());
		self.content.step.leftUnitValue:SetShown(self.content.step.leftUnit:GetChecked());
	end);
	
	self.content.step.rightUnit:SetScript("OnClick", function()
		self.content.step.rightUnitTarget:SetShown(self.content.step.rightUnit:GetChecked());
		self.content.step.rightUnitValue:SetShown(self.content.step.rightUnit:GetChecked());
	end);

	TRP3_API.ui.tooltip.setTooltipForSameFrame(self.content.step.imageMore, "BOTTOMRIGHT", 0, 0, loc.EDITOR_MORE);
	self.content.step.imageMore:SetScript("OnClick", function()
		if self.content.step.imageEditor:IsVisible() then
			self.content.step.imageEditor:Hide();
		else
			self.content.step.imageEditor.ArrowLEFT:SetPoint("LEFT", self.content.step.imageEditor, "RIGHT", 3, -60);
			TRP3_API.ui.frame.configureHoverFrame(self.content.step.imageEditor, self.content.step.imageMore, "RIGHT", -10, 60);
		end
	end);

	addon.utils.prepareForMultiSelectionMode(self.content.main.list);
	
	TRP3_API.ui.listbox.setupListBox(self.content.step.workflow, {{"(no workflow)", ""}});

	self.choiceEditor = CreateFrame("Frame", "TRP3_Tools_EditorCutsceneChoice", TRP3_ToolFrameEditor, "TRP3_Tools_EditorCutsceneChoiceTemplate");
	self.choiceEditor:Initialize();
	self.choiceEditor.title:SetText(loc.DI_CHOICES);
	self.content.step.choices:SetScript("OnClick", function()
		local index, stepData = self.content.main.list.model:FindByPredicate(function(e) return e.active end);
		if stepData then
			self.choiceEditor:OpenForChoice(stepData.CH, function(CH)
				stepData.CH = CH;
				self:ShowStep(index);
			end);
		end
	end);

end

function TRP3_Tools_EditorCutsceneMixin:ClassToInterface(class, creationClass)
	local BA = class.BA or TRP3_API.globals.empty;
	self.content.main.distance:SetText(BA.DI or "0");

	local steps = {};
	TRP3_API.utils.table.copy(steps, class.DS);
	if not TableHasAnyEntries(steps) then
		table.insert(steps, createStep());
	end
	table.insert(steps, {isAddButton = true});
	self.content.main.list.model:Flush();
	self.content.main.list.model:InsertTable(steps);
	self.content.main.alternate:SetChecked(false); -- TODO get this from cursor
	self.deferShowStep = true; -- wait for the OnScriptsChanged from the scripts frame to load workflow ids, then show first step
end

function TRP3_Tools_EditorCutsceneMixin:InterfaceToClass(targetClass)
	self:SaveCurrentStep();
	targetClass.BA = targetClass.BA or {};
	targetClass.BA.DI = tonumber(strtrim(self.content.main.distance:GetText())) or 0;
	targetClass.DS = targetClass.DS or {};
	wipe(targetClass.DS);
	for _, stepData in self.content.main.list.model:EnumerateEntireRange() do
		if not stepData.isAddButton then
			local copy = {};
			TRP3_API.utils.table.copy(copy, stepData);
			copy.active = nil;
			copy.selected = nil;
			table.insert(targetClass.DS, copy);
		end
	end
end

function TRP3_Tools_EditorCutsceneMixin:OnScriptsChanged(changes)
	local scriptMap = {};
	local scriptListWithNoneOption = {};
	for _, script in pairs(changes) do
		if script.newId then
			table.insert(scriptListWithNoneOption, {script.newId, script.newId});
			if script.oldId then
				scriptMap[script.oldId] = script.newId;
			end
		end
	end
	table.insert(scriptListWithNoneOption, {"(no workflow)", ""});
	TRP3_API.ui.listbox.setupListBox(self.content.step.workflow, scriptListWithNoneOption);

	self:SaveCurrentStep();

	for _, stepData in self.content.main.list.model:EnumerateEntireRange() do
		if stepData.WO then
			stepData.WO = scriptMap[stepData.WO];
		end
	end

	if self.deferShowStep then
		self:ShowStep(1); -- TODO get step from cursor
		self.deferShowStep = nil;
	else
		local index, stepData = self.content.main.list.model:FindByPredicate(function(e) return e.active end);
		if stepData then
			self:ShowStep(index);
		end
	end
end

function TRP3_Tools_EditorCutsceneMixin:CountScriptReferences(scriptId)
	self:SaveCurrentStep();
	local count = 0;
	for _, stepData in self.content.main.list.model:EnumerateEntireRange() do
		if stepData.WO == scriptId then
			count = count + 1;
		end
	end
	return count;
end

function TRP3_Tools_EditorCutsceneMixin:SaveCurrentStep()
	local index, data = self.content.main.list.model:FindByPredicate(function(e) return e.active end);
	if data then
		self.content.step.imageEditor:Hide();
		data.TX = TRP3_API.utils.str.emptyToNil(strtrim(self.content.step.text:GetText()));
		data.LO = self.content.step.loot:GetChecked();
		data.EP = self.content.step.endpoint:GetChecked();
		data.N  = tonumber(self.content.step.next:GetText());
		data.ND = self.content.step.direction:GetChecked()  and self.content.step.directionValue:GetSelectedValue() or nil;
		data.NA = self.content.step.name:GetChecked()       and self.content.step.nameValue:GetText()               or nil;
		data.LU = self.content.step.leftUnit:GetChecked()   and self.content.step.leftUnitValue:GetText()           or nil;
		data.RU = self.content.step.rightUnit:GetChecked()  and self.content.step.rightUnitValue:GetText()          or nil;
		data.BG = self.content.step.background:GetChecked() and self.content.step.backgroundValue:GetText()         or nil;
		if self.content.step.image:GetChecked() then
			data.IM = {
				UR = self.content.step.imageValue:GetText(),
				TO = tonumber(self.content.step.imageEditor.top:GetText()),
				BO = tonumber(self.content.step.imageEditor.bottom:GetText()),
				LE = tonumber(self.content.step.imageEditor.left:GetText()),
				RI = tonumber(self.content.step.imageEditor.right:GetText()),
				WI = tonumber(self.content.step.imageEditor.width:GetText()),
				HE = tonumber(self.content.step.imageEditor.height:GetText()),
			};
		else
			data.IM = nil;
		end
		data.WO = TRP3_API.utils.str.emptyToNil(self.content.step.workflow:GetSelectedValue());
	end
end

function TRP3_Tools_EditorCutsceneMixin:ShowStep(stepIndex)
	local list = self.content.main.list;
	for index, element in list.model:EnumerateEntireRange() do
		element.active = index == stepIndex;
	end
	list.widget:ScrollToElementDataIndex(stepIndex);
	list:Refresh();
	local data = list.model:Find(stepIndex);
	if data then
		self.content.step.imageEditor:Hide();
		self.content.step.title:SetText(("%s: %d"):format(loc.DI_STEP_EDIT, stepIndex));
		self.content.step.text:SetText(data.TX or "");
		self.content.step.next:SetText(data.N or "");
		local numOptions = CountTable(data.CH or TRP3_API.globals.empty);
		if numOptions > 0 then
			self.content.step.choices:SetText(numOptions .. " " .. loc.DI_CHOICES);
		else
			self.content.step.choices:SetText(loc.DI_CHOICES);
		end
		self.content.step.loot:SetChecked(data.LO or false);
		self.content.step.endpoint:SetChecked(data.EP or false);
		self.content.step.direction:SetChecked(data.ND ~= nil);
		self.content.step.direction:GetScript("OnClick")();
		self.content.step.directionValue:SetSelectedValue(data.ND or "NONE");
		self.content.step.name:SetChecked(data.NA ~= nil);
		self.content.step.name:GetScript("OnClick")();
		self.content.step.nameValue:SetText(data.NA or "${trp:player:full}");
		self.content.step.leftUnit:SetChecked(data.LU ~= nil);
		self.content.step.leftUnit:GetScript("OnClick")();
		self.content.step.leftUnitValue:SetText(data.LU or "player");
		self.content.step.rightUnit:SetChecked(data.RU ~= nil);
		self.content.step.rightUnit:GetScript("OnClick")();
		self.content.step.rightUnitValue:SetText(data.RU or "target");
		self.content.step.background:SetChecked(data.BG ~= nil);
		self.content.step.background:GetScript("OnClick")();
		self.content.step.backgroundValue:SetText(data.BG or DEFAULT_BG);
		self.content.step.image:SetChecked(data.IM ~= nil);
		self.content.step.image:GetScript("OnClick")();
		self.content.step.imageValue:SetText(data.IM and data.IM.UR or "");
		self.content.step.workflow:SetSelectedValue(data.WO or "");
		self.content.step.imageEditor.width:SetText(data.IM and data.IM.WI or "256");
		self.content.step.imageEditor.height:SetText(data.IM and data.IM.HE or "256");
		self.content.step.imageEditor.top:SetText(data.IM and data.IM.TO or "0");
		self.content.step.imageEditor.bottom:SetText(data.IM and data.IM.BO or "1");
		self.content.step.imageEditor.left:SetText(data.IM and data.IM.LE or "0");
		self.content.step.imageEditor.right:SetText(data.IM and data.IM.RI or "1");
	end
	self.content.step.text.scroll.text:SetFocus();
end

function TRP3_Tools_EditorCutsceneMixin:AddStep(targetIndex, stepData, noUpdate)
	local list = self.content.main.list;
	targetIndex = targetIndex or list.model:GetSize();

	for _, element in list.model:EnumerateEntireRange() do
		if element.N and element.N >= targetIndex then
			element.N = element.N + 1;
		end
		for _, option in pairs(element.CH or TRP3_API.globals.empty) do
			if option.N and option.N >= targetIndex then
				option.N = option.N + 1;
			end
		end
	end

	local stepToAdd = stepData;
	if not stepToAdd then
		stepToAdd = createStep();
		if self.content.main.alternate:GetChecked() then
			local directionRefStep;
			if targetIndex > 1 then
				directionRefStep = list.model:Find(targetIndex - 1);
			elseif targetIndex < list.model:GetSize() - 1 then
				directionRefStep = list.model:Find(targetIndex + 1);
			end
			if directionRefStep then
				if directionRefStep.ND == "LEFT" then
					stepToAdd.ND = "RIGHT";
				elseif directionRefStep.ND == "RIGHT" then
					stepToAdd.ND = "LEFT";
				end
			end

			local nameRefStep;
			if targetIndex > 2 then
				nameRefStep = list.model:Find(targetIndex - 2);
			elseif targetIndex < list.model:GetSize() - 2 then
				nameRefStep = list.model:Find(targetIndex + 2);
			end
			if nameRefStep then
				stepToAdd.NA = nameRefStep.NA;
			end
		end
	end

	list.model:InsertAtIndex(stepToAdd, targetIndex);
	if noUpdate then
		return
	end
	self:ShowStep(targetIndex);
end

function TRP3_Tools_EditorCutsceneMixin:DeleteStep(stepData)
	local list = self.content.main.list;
	local stepIndex = list.model:FindIndex(stepData);
	if stepIndex then

		for _, element in list.model:EnumerateEntireRange() do
			if element.N and element.N > stepIndex then
				element.N = element.N - 1;
			elseif element.N and element.N == stepIndex then
				element.N = nil;
			end
			for _, option in pairs(element.CH or TRP3_API.globals.empty) do
				if option.N and option.N > stepIndex then
					option.N = option.N - 1;
				elseif option.N and option.N == stepIndex then
					option.N = nil;
				end
			end
		end

		list.model:RemoveIndex(stepIndex);
		if list.model:GetSize() <= 1 then
			list.model:InsertAtIndex(createStep(), 1);
		end
		if stepData.active then
			self:ShowStep(math.max(stepIndex-1, 1));
		else
			list:Refresh();
		end
	end
end

function TRP3_Tools_EditorCutsceneMixin:DeleteSelectedSteps()
	local list = self.content.main.list;
	local steps = {};
	local stepIndex;
	local stepIndexMapping = {};
	for index, element in list.model:EnumerateEntireRange() do
		if not element.isAddButton then
			if not element.selected then
				table.insert(steps, element);
				stepIndexMapping[index] = #steps;
			elseif element.active then
				stepIndex = #steps;
			end
		end
	end
	if not TableHasAnyEntries(steps) then
		table.insert(steps, createStep());
	end
	table.insert(steps, {isAddButton = true});
	list.model:Flush();
	list.model:InsertTable(steps);

	for _, element in list.model:EnumerateEntireRange() do
		if element.N then
			element.N = stepIndexMapping[element.N];
		end
		for _, option in pairs(element.CH or TRP3_API.globals.empty) do
			if option.N then
				option.N = stepIndexMapping[option.N];
			end
		end
	end

	stepIndex = math.max(1, stepIndex or list.model:FindByPredicate(function(e) return e.active end) or 1);
	self:ShowStep(stepIndex);
end

function TRP3_Tools_EditorCutsceneMixin:StepExists(stepIndex)
	local data = self.content.main.list.model:Find(stepIndex);
	return data and not data.isAddButton;
end

TRP3_Tools_CutsceneStepListElementMixin = {};

function TRP3_Tools_CutsceneStepListElementMixin:Initialize(data)
	self.data = data;
	self:Refresh();
end

function TRP3_Tools_CutsceneStepListElementMixin:Refresh()
	local tooltipTitle;
	local tooltipText;
	if self.data.isAddButton then
		self.icon:SetTexture("Interface\\PaperDollInfoFrame\\Character-Plus");
		self.label:SetText(loc.DI_STEP_ADD);
		self:SetHighlight(false);
		self:SetSelected(false);
		self.delete:Hide();
		tooltipTitle = loc.DI_STEP_ADD;
		tooltipText = TRP3_API.FormatShortcutWithInstruction("LCLICK", loc.DI_STEP_ADD);
	else
		self.label:SetText(("|cff00ff00Step %d:|r |cffffffff%s|r"):format(self:GetElementDataIndex(), self.data.TX or ""));

		if self.data.CH then
			self.icon:SetTexture("Interface\\GossipFrame\\ActiveLegendaryQuestIcon");
			tooltipTitle = loc.DI_CHOICES;
		elseif self.data.EP then
			self.icon:SetTexture("Interface\\GossipFrame\\AvailableLegendaryQuestIcon");
			tooltipTitle = loc.DI_END;
		else
			self.icon:SetTexture("Interface\\GossipFrame\\PetitionGossipIcon");
			tooltipTitle = loc.DI_STEP;
		end

		self:SetHighlight(self.data.active);
		self:SetSelected(self.data.selected);
		self.delete:Show();

		tooltipText = 
			TRP3_API.FormatShortcutWithInstruction("LCLICK", "edit step") .. "|n" ..
			TRP3_API.FormatShortcutWithInstruction("RCLICK", "more options") .. "|n" ..
			TRP3_API.FormatShortcutWithInstruction("SHIFT-CLICK", "select range") .. "|n" ..
			TRP3_API.FormatShortcutWithInstruction("CTRL-CLICK", "select this step")
		;
	end
	TRP3_API.ui.tooltip.setTooltipForSameFrame(self, "BOTTOMRIGHT", 0, 0, tooltipTitle, tooltipText);
end

function TRP3_Tools_CutsceneStepListElementMixin:OnEnter()
	TRP3_RefreshTooltipForFrame(self);
end

function TRP3_Tools_CutsceneStepListElementMixin:OnLeave()
	TRP3_MainTooltip:Hide();
end

function TRP3_Tools_CutsceneStepListElementMixin:OnClick(button)
	local cutsceneEditor = addon.editor.getCurrentPropertiesEditor();
	local stepIndex = cutsceneEditor.content.main.list.model:FindIndex(self.data);
	
	if self.data.isAddButton then
		if button == "LeftButton" and not IsModifierKeyDown() then
			cutsceneEditor:SaveCurrentStep();
			cutsceneEditor:AddStep(stepIndex);
		end
	elseif button == "LeftButton" then
		if IsControlKeyDown() then
			cutsceneEditor.content.main.list:ToggleSingleSelect(self.data);
		elseif IsShiftKeyDown() then
			cutsceneEditor.content.main.list:ToggleRangeSelect(self.data);
		else
			cutsceneEditor:SaveCurrentStep();
			cutsceneEditor:ShowStep(self:GetElementDataIndex());
		end
	elseif button == "RightButton" then
		TRP3_MenuUtil.CreateContextMenu(self, function(_, contextMenu)
			contextMenu:CreateTitle(loc.DI_STEP);
			
			local addBeforeOption = contextMenu:CreateButton("Insert step before", function()
				cutsceneEditor:SaveCurrentStep();
				cutsceneEditor:AddStep(stepIndex);
			end);
			TRP3_MenuUtil.SetElementTooltip(addBeforeOption, "Insert a new step before this step");

			local addAfterOption = contextMenu:CreateButton("Insert step after", function()
				cutsceneEditor:SaveCurrentStep();
				cutsceneEditor:AddStep(stepIndex + 1);
			end);
			TRP3_MenuUtil.SetElementTooltip(addAfterOption, "Insert a new step after this step");

			contextMenu:CreateDivider();
			local copyOption = contextMenu:CreateButton("Copy", function()
				addon.clipboard.clear();
				addon.clipboard.append(self.data, addon.clipboard.types.DIALOG_STEP);
			end);
			TRP3_MenuUtil.SetElementTooltip(copyOption, "Copy this step");
			if self.data.selected then
				local copySelectionOption = contextMenu:CreateButton("Copy selected steps", function()
					addon.clipboard.clear();
					for index, element in cutsceneEditor.content.main.list.model:EnumerateEntireRange() do
						if element.selected then
							addon.clipboard.append(element, addon.clipboard.types.DIALOG_STEP);
						end
					end
					cutsceneEditor.content.main.list:SetAllSelected(false);
				end);
				TRP3_MenuUtil.SetElementTooltip(copySelectionOption, "Copy all selected steps");
			end

			if addon.clipboard.isPasteCompatible(addon.clipboard.types.DIALOG_STEP) then
				local count = addon.clipboard.count();

				local beforeText, afterText;
				if count == 1 then
					beforeText = "Paste step before";
					afterText = "Paste step after";
				else
					beforeText = "Paste " .. count .. " steps before";
					afterText = "Paste " .. count .. " steps after";
				end

				local pasteBeforeOption = contextMenu:CreateButton(beforeText, function()
					for index = 1, count do
						cutsceneEditor:AddStep(stepIndex + index - 1, addon.clipboard.retrieve(index), true);
					end
					cutsceneEditor:ShowStep(stepIndex + count - 1);
				end);
				TRP3_MenuUtil.SetElementTooltip(pasteBeforeOption, beforeText);

				local pasteBeforeOption = contextMenu:CreateButton(afterText, function()
					for index = 1, count do
						cutsceneEditor:AddStep(stepIndex + index, addon.clipboard.retrieve(index), true);
					end
					cutsceneEditor:ShowStep(stepIndex + count);
				end);
				TRP3_MenuUtil.SetElementTooltip(pasteBeforeOption, afterText);
			end

			contextMenu:CreateDivider();
			local deleteOption = contextMenu:CreateButton(DELETE, function()
				self:OnDelete();
			end);
			TRP3_MenuUtil.SetElementTooltip(deleteOption, "Delete this step");

			if self.data.selected then
				local deleteSelectionOption = contextMenu:CreateButton("Delete selection", function()
					cutsceneEditor:SaveCurrentStep();
					cutsceneEditor:DeleteSelectedSteps();
				end);
				TRP3_MenuUtil.SetElementTooltip(deleteSelectionOption, "Delete all selected steps");
			end
			
		end);
	end
end

function TRP3_Tools_CutsceneStepListElementMixin:OnDelete()
	addon.editor.getCurrentPropertiesEditor():SaveCurrentStep();
	addon.editor.getCurrentPropertiesEditor():DeleteStep(self.data);
end

TRP3_Tools_EditorCutsceneChoiceMixin = {};

function TRP3_Tools_EditorCutsceneChoiceMixin:Initialize()
	self.choiceData = {};
	for index = 1, 5 do
		table.insert(self.choiceData, {constraint = {}});
	end
	self.optionEditor.text.titleText = loc.DI_CHOICE;
	self.optionEditor.text.helpText = loc.DI_CHOICE_TT;
	self.optionEditor.text:Localize(function(x) return x; end);
	self.optionEditor.next.titleText = loc.DI_CHOICE_STEP;
	self.optionEditor.next.helpText = loc.DI_CHOICE_STEP_TT;
	self.optionEditor.next:Localize(function(x) return x; end);
	
	self.applyButton:SetScript("OnClick", function() 
		self:OpenOption(0); -- will update whatever option is opened
		local choices = {};
		for index, option in ipairs(self.choiceData) do
			if option.text then
				table.insert(choices, {
					TX = option.text,
					N  = option.next,
					C  = addon.script.getSaveFormatConstraintData(option.constraint)
				});
			end
		end
		if not TableHasAnyEntries(choices) then
			choices = nil;
		end
		self:Hide();
		self.callback(choices);
	end);

end

function TRP3_Tools_EditorCutsceneChoiceMixin:OpenForChoice(choiceData, callback)
	for index, option in ipairs(self.choiceData) do
		option.next = nil;
		option.text = nil;
		option.constraint = {};
		if choiceData and choiceData[index] then
			option.next = choiceData[index].N;
			option.text = choiceData[index].TX;
			option.constraint = addon.script.getNormalizedConstraintData(choiceData[index].C or TRP3_API.globals.empty);
		end
	end
	self.callback = callback;
	self.optionIndex = 0;
	self:OpenOption(0);
	self:Open();
end

function TRP3_Tools_EditorCutsceneChoiceMixin:OpenOption(optionIndex)
	if self.choiceData[self.optionIndex] then
		self.choiceData[self.optionIndex].text = TRP3_API.utils.str.emptyToNil(strtrim(self.optionEditor.text:GetText()));
		self.choiceData[self.optionIndex].next = tonumber(self.optionEditor.next:GetText());
		self.optionEditor.constraint:Update();
	end
	self.optionEditor:Hide();
	self.optionIndex = optionIndex;
	for index, option in ipairs(self.choiceData) do
		local optionFrame = self["option" .. index];
		if self.optionIndex == index then
			optionFrame:SetHeight(200);
			optionFrame.button:Hide();
			self.optionEditor:SetParent(optionFrame);
			self.optionEditor:SetAllPoints();
			self.optionEditor:Show();
			self.optionEditor.text:SetText(option.text or "");
			self.optionEditor.next:SetText(option.next or "");
			self.optionEditor.constraint:LinkWithConstraint(option.constraint);
		else
			if option.text then
				if TableHasAnyEntries(option.constraint) then
					optionFrame.button.text:SetText("|cFF00FF00[Conditional]|r " .. option.text);
				else
					optionFrame.button.text:SetText(option.text);
				end
				if not option.next then
					optionFrame.button.next:SetText("|TInterface\\\MONEYFRAME\\Arrow-Right-Down:16:16|t end");
				elseif addon.editor.getCurrentPropertiesEditor():StepExists(option.next) then
					optionFrame.button.next:SetText("|TInterface\\\MONEYFRAME\\Arrow-Right-Down:16:16|t Step " .. (option.next));
				else
					optionFrame.button.next:SetText("|TInterface\\\MONEYFRAME\\Arrow-Right-Down:16:16|t Step " .. addon.script.formatters.unknown(option.next));
				end
			else
				optionFrame.button.text:SetText("|cFF808080(click to add an option)|r");
				optionFrame.button.next:SetText("");
			end
			optionFrame:SetHeight(40);
			optionFrame.button:Show();
		end
	end
	
end
