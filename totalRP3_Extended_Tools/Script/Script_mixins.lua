local _, addon = ...
local loc = TRP3_API.loc;

local SECURITY_COLORS = {
	[TRP3_API.security.SECURITY_LEVEL.LOW]    = TRP3_API.Colors.Red,
	[TRP3_API.security.SECURITY_LEVEL.MEDIUM] = TRP3_API.Colors.Orange,
	[TRP3_API.security.SECURITY_LEVEL.HIGH]   = TRP3_API.Colors.Green
};
local function applySecurityColorToTexture(securityLevel, texture)
	local color = SECURITY_COLORS[securityLevel] or TRP3_API.Colors.Grey;
	texture:SetColorTexture(color.r, color.g, color.b, color.a);
end

local TRIGGER_SORT_MAP = {
	[addon.script.triggerType.OBJECT] = 1,
	[addon.script.triggerType.ACTION] = 2,
	[addon.script.triggerType.EVENT] = 3
};
local function sortTriggers(triggers)
	local actionSortIndex = 0;
	local eventSortIndex = 0;
	for index, trigger in ipairs(triggers) do
		if trigger.type == addon.script.triggerType.OBJECT then
			_, trigger.sortIndex = addon.script.getObjectTrigger(addon.getCurrentDraftClass().TY, trigger.id);
		elseif trigger.type == addon.script.triggerType.ACTION then
			actionSortIndex = actionSortIndex + 1;
			trigger.sortIndex = actionSortIndex;
		elseif trigger.type == addon.script.triggerType.EVENT then
			eventSortIndex = eventSortIndex + 1;
			trigger.sortIndex = eventSortIndex;
		else
			trigger.sortIndex = 0;
		end
	end
	table.sort(triggers, function(t1, t2) 
		if t1.type ~= t2.type then
			return (TRIGGER_SORT_MAP[t1.type] or 0) < (TRIGGER_SORT_MAP[t2.type] or 0);
		end
		return t1.sortIndex < t2.sortIndex;
	end);
end

TRP3_Tools_EditorScriptMixin = {};

local conditionPreviewTermFramePool = CreateFramePool("Frame", nil, "TRP3_Tools_ScriptConditionTermPreviewTemplate");

function TRP3_Tools_EditorScriptMixin:Initialize()
	addon.script:Initialize();
	self.triggers = {};
	self.scripts = {};
end

function TRP3_Tools_EditorScriptMixin:OnTriggerChanged(originalTrigger, newTrigger)
	if newTrigger.script and not self.scripts[newTrigger.script] then
		self.scripts[newTrigger.script] = {};
		self:UpdateScriptList();
	end
	if originalTrigger then
		wipe(originalTrigger);
		TRP3_API.utils.table.copy(originalTrigger, newTrigger);
	else
		local newTriggerCopy = {};
		TRP3_API.utils.table.copy(newTriggerCopy, newTrigger);
		table.insert(self.triggers, newTriggerCopy);
	end
	self:UpdateTriggerList();
	self.scriptList:SetSelectedValue(newTrigger.script);
end

function TRP3_Tools_EditorScriptMixin:OnEffectApplied(effectData)
	local newEffectData = {};
	TRP3_API.utils.table.copy(newEffectData, effectData);
	if self.effectEditorTarget.replace then
		self.scripts[self.effectEditorTarget.scriptId][self.effectEditorTarget.effectIndex] = newEffectData;
	else
		table.insert(self.scripts[self.effectEditorTarget.scriptId], self.effectEditorTarget.effectIndex, newEffectData);
	end
	self:OnScriptSelected(self.effectEditorTarget.scriptId);
end

function TRP3_Tools_EditorScriptMixin:DeleteEffect(scriptId, effectIndex)
	table.remove(self.scripts[scriptId], effectIndex);
	self:OnScriptSelected(scriptId);
end

function TRP3_Tools_EditorScriptMixin:DeleteTrigger(trigger)
	for index, t in ipairs(self.triggers) do
		if t == trigger then
			table.remove(self.triggers, index);
			break;
		end
	end
	self:UpdateTriggerList();
	if trigger.script == self.scriptList:GetSelectedValue() then
		self.scriptList:SetSelectedValue(nil);
	end
end

function TRP3_Tools_EditorScriptMixin:OnScriptSelected(scriptId)
	local effects = {};
	if scriptId and self.scripts[scriptId] then
		for index, effect in ipairs(self.scripts[scriptId]) do
			table.insert(effects, {
				title   = addon.script.getEffectTitle(effect),
				preview = addon.script.getEffectPreview(effect),
				icon    = "Interface\\Icons\\" .. addon.script.getEffectIcon(effect),
				constraint = self:ConstraintToPreview(effect.constraint, "IF"),
				security = addon.script.getEffectSecurity(effect)
			});
		end
		table.insert(effects, {isAddButton = true}); -- add button
	end
	self.effectList.model:Flush();
	self.effectList.model:InsertTable(effects);

	for index, trigger in self.triggerList.model:EnumerateEntireRange() do
		trigger.active = self.triggers[index] and self.triggers[index].script == scriptId;
	end
	self.triggerList:Refresh();

end

function TRP3_Tools_EditorScriptMixin:ConstraintToPreview(constraint, qualifier)
	local constraintPreview = {};
	local orStart;
	local hasAnd = false;
	for index, equation in ipairs(constraint) do
		local equationPreview = {
			expression = addon.script.getOperandPreview(equation.leftTerm) .. " " .. addon.script.getComparatorText(equation.comparator) .. " " .. addon.script.getOperandPreview(equation.rightTerm),
			close = ""
		};
		if index == 1 then
			equationPreview.open = qualifier or "";
		else
			if equation.logicalOperation == addon.script.logicalOperation.OR then
				equationPreview.open = loc.OP_OR;
				orStart = orStart or index - 1;
			elseif equation.logicalOperation == addon.script.logicalOperation.AND then
				equationPreview.open = loc.OP_AND;
				hasAnd = true;
				if orStart then
					constraintPreview[orStart].open = strtrim(constraintPreview[orStart].open .. " (");
					constraintPreview[index-1].close = ")";
					orStart = nil;
				end
			end
		end
		table.insert(constraintPreview, equationPreview);
	end
	if hasAnd and orStart then
		constraintPreview[orStart].open = strtrim(constraintPreview[orStart].open .. " (");
		constraintPreview[#constraintPreview].close = ")";
	end
	return constraintPreview;
end

function TRP3_Tools_EditorScriptMixin:TriggerToPreview(class, trigger)
	local triggerPreview = {};

	triggerPreview.icon, triggerPreview.whenText, triggerPreview.tooltipTitle, triggerPreview.tooltipText = addon.script.getTriggerPreview(class.TY, trigger.id, trigger.type);

	if trigger.script then
		triggerPreview.thenText = ("then start workflow %s"):format(addon.script.formatters.constant(trigger.script));
	else
		triggerPreview.thenText = ("then start workflow %s"):format(addon.script.formatters.unknown(""));
	end
	triggerPreview.constraint = self:ConstraintToPreview(trigger.constraint, "WHILE"); -- TODO
	triggerPreview.active = trigger.script and trigger.script == self.scriptList:GetSelectedValue();
	return triggerPreview;
end

function TRP3_Tools_EditorScriptMixin:ClassToInterface(class, creationClass)
	
	local s = self;

	wipe(self.triggers);
	wipe(self.scripts);

	for scriptId, scriptData in pairs(class.SC or TRP3_API.globals.empty) do
		self.scripts[scriptId] = addon.script.getNormalizedEffectListData(scriptData or TRP3_API.globals.empty);
	end

	self:UpdateScriptList();
	self.triggers = addon.script.getNormalizedTriggerData(class, self.scripts);

	self:UpdateTriggerList();

	self.scriptList:SetSelectedValue(nil);

end

function TRP3_Tools_EditorScriptMixin:UpdateScriptList()
	local scriptList = {};
	for scriptId, _ in pairs(self.scripts) do
		table.insert(scriptList, {scriptId, scriptId});
	end
	table.sort(scriptList, function(a, b) 
		return a[1] < b[1];
	end);
	TRP3_API.ui.listbox.setupListBox(self.scriptList, scriptList, function(scriptId) self:OnScriptSelected(scriptId); end, "(no workflow selected)");
end

function TRP3_Tools_EditorScriptMixin:UpdateTriggerList()
	local triggerList = {};
	local class = addon.getCurrentDraftClass();
	local usedObjectTriggerCount = 0;
	for index, trigger in ipairs(self.triggers) do
		if trigger.type == addon.script.triggerType.OBJECT then
			usedObjectTriggerCount = usedObjectTriggerCount + 1;
		end
		table.insert(triggerList, self:TriggerToPreview(class, trigger));
	end
	sortTriggers(triggerList);
	
	if addon.script.supportsTriggerType(class.TY, addon.script.triggerType.ACTION)
	or addon.script.supportsTriggerType(class.TY, addon.script.triggerType.EVENT)
	or usedObjectTriggerCount < CountTable(addon.script.objectTriggers[class.TY] or TRP3_API.globals.empty)
	then
		table.insert(triggerList, {isAddButton = true});
	end

	self.triggerList.model:Flush();
	self.triggerList.model:InsertTable(triggerList);
end

function TRP3_Tools_EditorScriptMixin:InterfaceToClass(targetClass)

	targetClass.SC = nil;
	for scriptId, script in pairs(self.scripts) do
		targetClass.SC = targetClass.SC or {};
		targetClass.SC[scriptId] = addon.script.getSaveFormatEffectListData(script);
	end

	targetClass.LI = nil; -- TODO
	targetClass.AC = nil;
	targetClass.HA = nil;
	
	if targetClass.US then
		targetClass.US.SC = nil;
	end
	
	for _, trigger in ipairs(self.triggers) do
		if trigger.type == addon.script.triggerType.OBJECT then
			targetClass.LI = targetClass.LI or {};
			targetClass.LI[trigger.id] = trigger.script;
			if targetClass.TY == TRP3_DB.types.ITEM and trigger.id == "OU" then
				targetClass.US = targetClass.US or {};
				targetClass.US.SC = trigger.script;
			end
		elseif trigger.type == addon.script.triggerType.ACTION then
			targetClass.AC = targetClass.AC or {};
			table.insert(targetClass.AC, {
				TY = trigger.id,
				SC = trigger.script,
				CO = addon.script.getSaveFormatConstraintData(trigger.constraint);
			});
		elseif trigger.type == addon.script.triggerType.EVENT then
			targetClass.HA = targetClass.HA or {};
			table.insert(targetClass.HA, {
				EV = trigger.id,
				SC = trigger.script,
				CO = addon.script.getSaveFormatConstraintData(trigger.constraint);
			});
		end
	end

end

TRP3_Tools_ScriptTriggerListElementMixin = {};

function TRP3_Tools_ScriptTriggerListElementMixin:Initialize(data)
	self.data = data;
	self:Refresh();
end

function TRP3_Tools_ScriptTriggerListElementMixin:Refresh()
	self:Reset();	
	if self.data.active then
		self:SetBackdrop(BACKDROP_CALLOUT_GLOW_0_16);
	else
		self:SetBackdrop(TRP3_BACKDROP_MIXED_TUTORIAL_TOOLTIP_418_24_5555);
	end

	if self.data.isAddButton then
		self.icon.Icon:SetTexture("Interface\\PaperDollInfoFrame\\Character-Plus");
		self.whenText:SetText("Add trigger");
		self.thenText:SetText("");
	else
		self.icon.Icon:SetTexture(self.data.icon);
		self.whenText:SetText(self.data.whenText);
		self.thenText:SetText(self.data.thenText);

		for index, constraint in ipairs(self.data.constraint) do
			local widget = conditionPreviewTermFramePool:Acquire();
			widget:SetParent(self);
			widget:ClearAllPoints();
			widget:SetPoint("TOP", 0, -(38 + index*20));
			widget:SetPoint("LEFT");
			widget:SetPoint("RIGHT");
			widget.open:SetText(constraint.open);
			widget.expression:SetText(constraint.expression);
			widget.close:SetText(constraint.close);
			widget:Show();
			table.insert(self.constraintWidgets, widget);
		end
	end
end

function TRP3_Tools_ScriptTriggerListElementMixin:GetElementExtent(data)
	return data.isAddButton and 64 or (90 + 20*#data.constraint);
end

function TRP3_Tools_ScriptTriggerListElementMixin:Reset()
	self.constraintWidgets = self.constraintWidgets or {};
	for index, widget in ipairs(self.constraintWidgets) do
		conditionPreviewTermFramePool:Release(widget);
	end
	wipe(self.constraintWidgets);
end

function TRP3_Tools_ScriptTriggerListElementMixin:OnClick(button)
	if self.data.isAddButton then
		addon.editor.trigger:OpenForTrigger();
	else
		local trigger = addon.editor.script.triggers[addon.editor.script.triggerList.model:FindIndex(self.data)];
		if button == "LeftButton" then
			if self.data.active or not trigger.script then
				addon.editor.trigger:OpenForTrigger(trigger);
			end
			addon.editor.script.scriptList:SetSelectedValue(trigger.script);
		elseif button == "RightButton" then
			TRP3_MenuUtil.CreateContextMenu(self, function(_, contextMenu)
				local editOption = contextMenu:CreateButton("Edit trigger...", function()
					addon.editor.trigger:OpenForTrigger(trigger);
					addon.editor.script.scriptList:SetSelectedValue(trigger.script);
				end);
				TRP3_MenuUtil.SetElementTooltip(editOption, "Edit trigger...");

				if trigger.script then
					local openOption = contextMenu:CreateButton("Edit workflow...", function()
						addon.editor.script.scriptList:SetSelectedValue(trigger.script);
					end);
					TRP3_MenuUtil.SetElementTooltip(openOption, "Edit workflow...");
				end

				contextMenu:CreateDivider();
				
				local deleteTriggerOption = contextMenu:CreateButton("Delete trigger", function()
					addon.editor.script:DeleteTrigger(trigger);
				end);
				TRP3_MenuUtil.SetElementTooltip(deleteTriggerOption, "Delete trigger");
				
				local deleteTriggerAndScriptOption = contextMenu:CreateButton("Delete trigger and workflow", function()
					-- TODO implement
				end);
				deleteTriggerAndScriptOption:SetEnabled(false); -- TODO make this only available if refCount == 1
				TRP3_MenuUtil.SetElementTooltip(deleteTriggerAndScriptOption, "Delete trigger and workflow");
				
			end);
		end
	end
end

TRP3_Tools_ScriptEffectListElementMixin = {};

function TRP3_Tools_ScriptEffectListElementMixin:Initialize(data)
	self.data = data;
	self:Refresh();
end

function TRP3_Tools_ScriptEffectListElementMixin:Refresh()
	self:Reset();
	if not self.data.isAddButton then
		self.icon.Icon:SetTexture(self.data.icon);
		self.title:SetText(self.data.title);
		self.preview:SetText(self.data.preview);
		applySecurityColorToTexture(self.data.security, self.securityIndicator);
		for index, constraint in ipairs(self.data.constraint) do
			local widget = conditionPreviewTermFramePool:Acquire();
			widget:SetParent(self);
			widget:ClearAllPoints();
			widget:SetPoint("TOP", 0, -(38 + index*20));
			widget:SetPoint("LEFT");
			widget:SetPoint("RIGHT");
			widget.open:SetText(constraint.open);
			widget.expression:SetText(constraint.expression);
			widget.close:SetText(constraint.close);
			widget:Show();
			table.insert(self.constraintWidgets, widget);
		end
	else
		self.icon.Icon:SetTexture("Interface\\PaperDollInfoFrame\\Character-Plus");
		self.title:SetText("Add effect");
		self.preview:SetText("");
		applySecurityColorToTexture(0, self.securityIndicator);
	end
end

function TRP3_Tools_ScriptEffectListElementMixin:GetElementExtent(data)
	return not data.isAddButton and (100 + 20*#data.constraint) or 64;
end

function TRP3_Tools_ScriptEffectListElementMixin:Reset()
	self.constraintWidgets = self.constraintWidgets or {};
	for index, widget in ipairs(self.constraintWidgets) do
		conditionPreviewTermFramePool:Release(widget);
	end
	wipe(self.constraintWidgets);
end

function TRP3_Tools_ScriptEffectListElementMixin:OnClick(button)
	local scriptId = addon.editor.script.scriptList:GetSelectedValue();
	if not scriptId or not addon.editor.script.scripts[scriptId] then 
		return;
	end
	local effectIndex = addon.editor.script.effectList.model:FindIndex(self.data);
	local effect = addon.editor.script.scripts[scriptId][effectIndex];
	if button == "LeftButton" then
		addon.editor.script.effectEditorTarget = {
			scriptId    = scriptId,
			effectIndex = effectIndex,
			replace     = not self.data.isAddButton
		};
		addon.editor.effect:OpenForEffect(effect);
	elseif button == "RightButton" and not self.data.isAddButton then
		TRP3_MenuUtil.CreateContextMenu(self, function(_, contextMenu)
			local editOption = contextMenu:CreateButton("Edit effect...", function()
				addon.editor.script.effectEditorTarget = {
					scriptId    = scriptId,
					effectIndex = effectIndex,
					replace     = true
				};
				addon.editor.effect:OpenForEffect(effect);
			end);
			TRP3_MenuUtil.SetElementTooltip(editOption, "Edit effect...");

			contextMenu:CreateDivider();
			
			local deleteTriggerOption = contextMenu:CreateButton("Delete effect", function()
				addon.editor.script:DeleteEffect(scriptId, effectIndex);
			end);
			TRP3_MenuUtil.SetElementTooltip(deleteTriggerOption, "Delete effect");
		end);
	end
end
