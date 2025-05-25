local _, addon = ...
local loc = TRP3_API.loc;

local SURROGATE_SCRIPT_ID_NONE = 0;
local SURROGATE_SCRIPT_ID_NEW  = 1;

TRP3_Tools_EditorTriggerMixin = {};

function TRP3_Tools_EditorTriggerMixin:Initialize()
	self.gameEventButton:SetScript("OnClick", function() 
		local eventId = strtrim(addon.editor.trigger.gameEventName:GetText());
		if strlen(eventId) > 0 then
			addon.editor.trigger:SetTrigger(eventId, addon.script.triggerType.EVENT);
			addon.editor.trigger:ShowTriggerMain();
		end
	end);
	self.triggerCancelButton:SetScript("OnClick", function() 
		addon.editor.trigger:ShowTriggerMain();
	end);
	self.cancelButton:SetScript("OnClick", function() 
		self:Hide();
	end);
	self.applyButton:SetScript("OnClick", function() 
		-- TODO: there's almost no check on the script name, maybe add sone sensible limits?
		-- I have added trimming, such the the workflow " " isn't possible anymore
		local script = self.script.list:GetSelectedValue();
		if script == SURROGATE_SCRIPT_ID_NEW then
			script = strtrim(self.script.name:GetText());
		elseif script == SURROGATE_SCRIPT_ID_NONE then
			script = nil;
		end
		script = TRP3_API.utils.str.emptyToNil(script);
		self.triggerData.script = script;

		if self.triggerData.type == addon.script.triggerType.OBJECT then
			wipe(self.triggerData.constraint);
		else
			self.constraint.list:Update();
		end
		addon.editor.script:OnTriggerChanged(self.originalTriggerData, self.triggerData);
		self:Hide();
	end);
end

function TRP3_Tools_EditorTriggerMixin:OnScriptSelected(scriptId)
	self.script.name:SetShown(scriptId == SURROGATE_SCRIPT_ID_NEW);
	if scriptId == SURROGATE_SCRIPT_ID_NEW and strtrim(self.script.name:GetText()) == "" then
		local proposal = addon.script.suggestScriptName(addon.getCurrentDraftClass().TY, self.triggerData);
		local scriptName = proposal;
		local n = 1;
		while self.usedScriptNames[scriptName] do
			scriptName = proposal .. tostring(n);
			n = n+1;
		end
		self.script.name:SetText(scriptName);
	end
end

function TRP3_Tools_EditorTriggerMixin:SetTrigger(triggerId, triggerType)
	local icon, whenText = addon.script.getTriggerPreview(addon.getCurrentDraftClass().TY, triggerId, triggerType);
	self.trigger.whenText:SetText(whenText);
	self.trigger.icon.Icon:SetTexture(icon);
	self.triggerData.id = triggerId;
	self.triggerData.type = triggerType;
	if self.isScriptValueDeferred then
		self.isScriptValueDeferred = false;
		self.script.list:SetSelectedValue(self.triggerData.script or SURROGATE_SCRIPT_ID_NEW);
	end
end

function TRP3_Tools_EditorTriggerMixin:ShowTriggerMenu(noCancel)
	self:SetTitle("Choose a trigger");
	self.trigger:Hide();
	self.constraint:Hide();
	self.script:Hide();
	self.applyButton:Hide();
	self.cancelButton:Hide();
	self.triggerCancelButton:SetShown(not noCancel);
	if addon.script.supportsTriggerType(self.objectType, addon.script.triggerType.EVENT) then
		self:LoadGameEvents();
		self.gameEventButton:Show();
		self.gameEventName:SetText(self.triggerData.type == addon.script.triggerType.EVENT and self.triggerData.id or "");
		self.gameEventName:Show();
		self.gameEventTree:Show();
	else
		self.gameEventButton:Hide();
		self.gameEventName:Hide();
		self.gameEventTree:Hide();
	end
	local showConstraintWarning = TableHasAnyEntries(self.triggerData.constraint)
	for index, element in self.objectEventList.model:EnumerateEntireRange() do
		element.showConstraintWarning = showConstraintWarning and element.type == addon.script.triggerType.OBJECT;
	end
	self.objectEventList:Refresh();
	self.objectEventList:Show();
end

function TRP3_Tools_EditorTriggerMixin:ShowTriggerMain()
	self:SetTitle("Edit trigger");
	self.trigger:Show();
	self.script:Show();
	self.applyButton:Show();
	self.cancelButton:Show();
	self.constraint:SetShown(self.triggerData.type ~= addon.script.triggerType.OBJECT);
	self.triggerCancelButton:Hide();
	self.gameEventTree:Hide();
	self.gameEventButton:Hide();
	self.gameEventName:Hide();
	self.objectEventList:Hide();
end

function TRP3_Tools_EditorTriggerMixin:OpenForTrigger(triggerData)
	local s = self;

	self.originalTriggerData = triggerData;

	self.triggerData = self.triggerData or {};
	self.usedScriptNames = self.usedScriptNames or {};
	self.usedObjectTriggers = self.usedObjectTriggers or {};
	self.objectType = addon.getCurrentDraftClass().TY;

	wipe(self.triggerData);
	wipe(self.usedScriptNames);
	wipe(self.usedObjectTriggers);

	TRP3_API.utils.table.copy(self.triggerData, triggerData); -- TODO maybe a shallow copy is sufficient?
	self.triggerData.constraint = self.triggerData.constraint or {};

	for _, trigger in pairs(addon.editor.script.triggers) do
		if trigger.type == addon.script.triggerType.OBJECT and self.triggerData.id ~= trigger.id then
			self.usedObjectTriggers[trigger.id] = true;
		end
	end
	self.script.name:SetText("");

	local scriptList = {};
	for scriptId, _ in pairs(addon.editor.script.scripts) do
		table.insert(scriptList, {scriptId, scriptId});
		self.usedScriptNames[scriptId] = true;
	end
	table.sort(scriptList, function(a, b) 
		return a[1] < b[1];
	end);
	if TableHasAnyEntries(scriptList) then
		table.insert(scriptList, {});
	end
	table.insert(scriptList, {"(no workflow)", SURROGATE_SCRIPT_ID_NONE});
	table.insert(scriptList, {"(create new workflow)", SURROGATE_SCRIPT_ID_NEW});

	TRP3_API.ui.listbox.setupListBox(self.script.list, scriptList, function(scriptId) s:OnScriptSelected(scriptId); end, "(no workflow)");
	
	if triggerData then
		self:SetTrigger(self.triggerData.id, self.triggerData.type);
		self.script.list:SetSelectedValue(self.triggerData.script or SURROGATE_SCRIPT_ID_NONE);
		self.isScriptValueDeferred = false;
		self:ShowTriggerMain();
	else
		self.isScriptValueDeferred = true;
		self:ShowTriggerMenu(true);
	end

	self.constraint.list:LinkWithConstraint(self.triggerData.constraint);

	local objectEventList = {};
	
	if addon.script.supportsTriggerType(self.objectType, addon.script.triggerType.OBJECT) then
		for _, trigger in ipairs(addon.script.objectTriggers[self.objectType] or TRP3_API.globals.empty) do
			if not self.usedObjectTriggers[trigger.id] then
				local icon, whenText = addon.script.getTriggerPreview(self.objectType, trigger.id, addon.script.triggerType.OBJECT);
				table.insert(objectEventList, {
					id         = trigger.id,
					type       = addon.script.triggerType.OBJECT,
					icon       = icon,
					whenText   = whenText
				});
			end
		end
	end

	if addon.script.supportsTriggerType(self.objectType, addon.script.triggerType.ACTION) then
		for _, trigger in ipairs(addon.script.actionTriggersSorted) do
			local icon, whenText = addon.script.getTriggerPreview(self.objectType, trigger.id, addon.script.triggerType.ACTION);
			table.insert(objectEventList, {
				id         = trigger.id,
				type       = addon.script.triggerType.ACTION,
				icon       = icon,
				whenText   = whenText
			});
		end
	end

	self.objectEventList.model:Flush();
	self.objectEventList.model:InsertTable(objectEventList);

	self:Open();
end

function TRP3_Tools_EditorTriggerMixin:LoadGameEvents()
	if self.gameEventTree.isInitialized then
		return
	end
	self.gameEventTree.isInitialized = true;

	local events = {
		{
			NA = "Total RP 3 Extended events",
			PR = true, -- priority in list
			EV =
			{
				{
					NA = "TRP3_KILL",
					PA =
					{
						{ NA = "unitType", TY = "string" }, -- [1]
						{ NA = "killerGUID", TY = "string" }, -- [2]
						{ NA = "killerName", TY = "string" }, -- [3]
						{ NA = "victimGUID", TY = "string" }, -- [4]
						{ NA = "victimName", TY = "string" }, -- [5]
						{ NA = "victimNPC_ID / victimPlayerClassID", TY = "string" }, -- [6]
						{ NA = "victimPlayerClassName", TY = "string" }, -- [7]
						{ NA = "victimPlayerRaceID", TY = "string" }, -- [8]
						{ NA = "victimPlayerRaceName", TY = "string" }, -- [9]
						{ NA = "victimPlayerGender", TY = "number" } -- [10]
					}
	
				},
				{
					NA = "TRP3_SIGNAL",
					PA =
					{
						{ NA = "signalID", TY = "string" }, -- [1]
						{ NA = "signalValue", TY = "string" }, -- [2]
						{ NA = "senderName", TY = "string" } -- [3]
					}
	
				},
				{
					NA = "TRP3_EMOTE",
					PA =
					{
						{ NA = "emoteToken", TY = "string" }, -- [1]
					}
				},
				{
					NA = "TRP3_ROLL",
					PA =
					{
						{ NA = "diceRolled", TY = "string" }, -- [1]
						{ NA = "result", TY = "number" } -- [2]
					}
	
				},
				{
					NA = "TRP3_ITEM_USED",
					PA =
					{
						{ NA = "itemID", TY = "string" }, -- [1]
						{ NA = "errorMessage", TY = "string" } -- [2]
					}
	
				}
			}
		}
	};

	APIDocumentation_LoadUI();

	local apiTable = APIDocumentation:GetAPITableByTypeName("system");
	for _, apiSystem in pairs(apiTable) do
		if apiSystem.Events and issecurevariable(apiSystem, "Events") and TableHasAnyEntries(apiSystem.Events) then
			local system = {NA = apiSystem.Name, EV = {}};
			for _, apiEvent in pairs(apiSystem.Events) do
				local event = {NA = apiEvent.LiteralName, PA = {}};
				for argIndex, payloadArg in pairs(apiEvent.Payload or TRP3_API.globals.empty) do
					table.insert(event.PA, {NA = payloadArg.Name, TY = payloadArg.Type, IX = argIndex});
				end
				table.sort(event.PA, function(a, b) return a.IX < b.IX; end);
				table.insert(system.EV, event);
			end
			table.sort(system.EV, function(a, b) return a.NA < b.NA; end);
			table.insert(events, system);
		end
	end
	table.sort(events, function(a, b) 
		if a.PR ~= b.PR then 
			return a.PR or false;
		end
		return a.NA < b.NA;
	end);

	local model = CreateTreeDataProvider();

	for _, system in pairs(events) do
		local systemNode = model:Insert({
			title = system.NA
		});
		for _, event in pairs(system.EV) do
			local icon, whenText = addon.script.getTriggerPreview(self.objectType, event.NA, addon.script.triggerType.EVENT);
			local tooltip = "";
			if TableHasAnyEntries(event.PA) then
				tooltip = "Event arguments:";
			end
			for index, argument in ipairs(event.PA) do
				tooltip = tooltip .. "|n" .. addon.script.formatters.taggable(("${event.%d}"):format(index)) .. ": " .. argument.NA .. " - " .. argument.TY;
			end
			systemNode:Insert({
				id = event.NA,
				icon = icon,
				whenText = whenText,
				payload = event.PA,
				tooltip = tooltip
			});
			
		end
	end
	model:CollapseAll();
	self.gameEventTree.model = model;
	self.gameEventTree.widget:SetDataProvider(model);

end

TRP3_Tools_ScriptObjectEventListElementMixin = {};

function TRP3_Tools_ScriptObjectEventListElementMixin:Initialize(data)
	self.data = data;
	self:Refresh();
end

function TRP3_Tools_ScriptObjectEventListElementMixin:Refresh()
	self.icon.Icon:SetTexture(self.data.icon);
	if self.data.showConstraintWarning then
		self.whenText:SetText(self.data.whenText .. "|n|cFFFF0000(cannot be conditioned)|r");
	else
		self.whenText:SetText(self.data.whenText);
	end
end

function TRP3_Tools_ScriptObjectEventListElementMixin:OnClick()
	addon.editor.trigger:SetTrigger(self.data.id, self.data.type);
	addon.editor.trigger:ShowTriggerMain();
end

TRP3_Tools_ScriptGameEventTreeNodeMixin = {};

function TRP3_Tools_ScriptGameEventTreeNodeMixin:Initialize(node)
	self.node = node;
	self:Refresh();
end

function TRP3_Tools_ScriptGameEventTreeNodeMixin:Refresh()
	
	self.whenText:SetText(self.node.data.whenText or self.node.data.title);

	local tooltip;
	if self.node.data.title then
		self.icon:Hide();
		self.toggleChildren:Show();
		if self.node:IsCollapsed() then
			self.toggleChildren.normalTexture:SetTexture("Interface\\Buttons\\UI-PlusButton-UP");
			self.toggleChildren.pushedTexture:SetTexture("Interface\\Buttons\\UI-PlusButton-DOWN");
			tooltip = TRP3_API.FormatShortcutWithInstruction("LCLICK", "expand section");
		else
			self.toggleChildren.normalTexture:SetTexture("Interface\\Buttons\\UI-MinusButton-UP");
			self.toggleChildren.pushedTexture:SetTexture("Interface\\Buttons\\UI-MinusButton-DOWN");
			tooltip = TRP3_API.FormatShortcutWithInstruction("LCLICK", "collanpse section");
		end
	else
		self.icon.Icon:SetTexture(self.node.data.icon);
		self.icon:Show();
		self.toggleChildren:Hide();
		tooltip = self.node.data.tooltip .. "|n" .. TRP3_API.FormatShortcutWithInstruction("LCLICK", "select");
	end

	TRP3_API.ui.tooltip.setTooltipForSameFrame(self, "BOTTOMRIGHT", 0, 0, self.node.data.id or self.node.data.title, tooltip);

end

function TRP3_Tools_ScriptGameEventTreeNodeMixin:OnClick()
	if self.node.data.title then
		self:OnToggleChildren();
	else
		addon.editor.trigger:SetTrigger(self.node.data.id, addon.script.triggerType.EVENT);
		addon.editor.trigger:ShowTriggerMain();
	end
end

function TRP3_Tools_ScriptGameEventTreeNodeMixin:OnToggleChildren()
	self.node:ToggleCollapsed();
	addon.editor.trigger.gameEventTree:Refresh();
end

function TRP3_Tools_ScriptGameEventTreeNodeMixin:OnEnter()
	TRP3_RefreshTooltipForFrame(self);
end

function TRP3_Tools_ScriptGameEventTreeNodeMixin:OnLeave()
	TRP3_MainTooltip:Hide();
end
