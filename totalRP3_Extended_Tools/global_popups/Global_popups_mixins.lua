local _, addon = ...
local loc = TRP3_API.loc;

TRP3_Tools_ObjectsBrowserListElementMixin = {};

function TRP3_Tools_ObjectsBrowserListElementMixin:Initialize(data)
	self.data = data;
	self.title:SetText(data.title);
	TRP3_API.ui.tooltip.setTooltipForSameFrame(self, "BOTTOMRIGHT", 0, 0, data.title, data.tooltip);
end

function TRP3_Tools_ObjectsBrowserListElementMixin:OnEnter()
	TRP3_RefreshTooltipForFrame(self);
end

function TRP3_Tools_ObjectsBrowserListElementMixin:OnLeave()
	TRP3_MainTooltip:Hide();
end

function TRP3_Tools_ObjectsBrowserListElementMixin:OnClick()
	TRP3_Tools_ObjectsBrowser:Select(self.data.absoluteId);
end

TRP3_Tools_ObjectsBrowserMixin = {};

function TRP3_Tools_ObjectsBrowserMixin:Initialize()
	self.filter.box.title:SetText(loc.UI_FILTER);
	TRP3_API.popup.OBJECTS = "objects";
	TRP3_API.popup.POPUPS[TRP3_API.popup.OBJECTS] = {
		frame = self,
		showMethod = function(onSelectCallback, objectType, inventoryMode)
			self.onSelectCallback = onSelectCallback;
			self.title:SetText(loc.DB_BROWSER .. " (" .. TRP3_API.extended.tools.getTypeLocale(objectType) .. ")")
			self.objectType = objectType;
			self.inventoryMode = inventoryMode;
			self.filter.box:SetText("");
			self.filter.box:SetFocus();
			if not self.inventoryMode then
				addon.updateCurrentObjectDraft(); -- make sure any name/quality changes are reflected properly when opening the browser
			end
			self.filter.restrictToCreation:SetShown(not self.inventoryMode);
			self:Filter();
		end,
	};
	self.filter.box:SetScript("OnTextChanged", function() 
		self:Filter();
	end);
	self.filter.restrictToCreation:SetScript("OnClick", function() 
		self:Filter();
	end);
	addon.localize(self.filter.restrictToCreation);
end

function TRP3_Tools_ObjectsBrowserMixin:Select(token)
	self:Close();
	if self.onSelectCallback then
		self.onSelectCallback(token);
	end
end

local function generateObjectsBrowserLineData(absoluteId, classSource)
	
	local rootClass;
	local class = classSource(absoluteId);

	local partialId = "";
	local title = "";
	for relativeId in absoluteId:gmatch("[^%" .. TRP3_API.extended.ID_SEPARATOR .. "]+") do
		partialId = partialId .. relativeId;
		local _, link = addon.utils.getObjectIconAndLink(classSource(partialId), relativeId);
		if title == "" then
			title = link;
			rootClass = classSource(partialId);
		else
			title = title .. " |TInterface\\\MONEYFRAME\\Arrow-Right-Down:16:16|t" .. link;
		end
		partialId = partialId .. TRP3_API.extended.ID_SEPARATOR;
	end

	local tooltip = "";
	local fieldFormat = "%s: " .. TRP3_API.Colors.Yellow("%s|r");
	tooltip = tooltip .. fieldFormat:format(loc.TYPE, TRP3_API.extended.tools.getTypeLocale(class.TY));
	tooltip = tooltip .. "|n" .. fieldFormat:format(loc.ROOT_CREATED_BY, (rootClass.MD or TRP3_API.globals.empty).CB or "?");
	tooltip = tooltip .. "|n" .. fieldFormat:format(loc.SEC_LEVEL, TRP3_API.security.getSecurityText(rootClass.securityLevel or SECURITY_LEVEL.LOW));
	if class.TY == TRP3_DB.types.ITEM then
		local base = class.BA or TRP3_API.globals.empty;
		local _, link = addon.utils.getObjectIconAndLink(classSource(absoluteId));
		tooltip = tooltip .. "|n";
		tooltip = tooltip .. "|n" .. TRP3_API.utils.str.icon(base.IC or "temp", 25) .. " " .. link;
		if base.LE or base.RI then
			if base.LE and not base.RI then
				tooltip = tooltip .. "|n" .. TRP3_API.Colors.White(base.LE);
			elseif base.RI and not base.LE then
				tooltip = tooltip .. "|n" .. TRP3_API.Colors.White(base.RI);
			else
				tooltip = tooltip .. "|n" .. TRP3_API.Colors.White(base.LE .. " - " .. base.RI);
			end
		end
		if base.DE then
			local argsStructure = {object = {id = objectID}};
			tooltip = tooltip .. "|n" .. TRP3_API.Colors.Yellow("\"" .. TRP3_API.script.parseArgs(base.DE .. "\"", argsStructure));
		end
		tooltip = tooltip .. "|n" .. TRP3_API.Colors.White(TRP3_API.extended.formatWeight(base.WE or 0) .. " - " .. C_CurrencyInfo.GetCoinTextureString(base.VA or 0));
	end
	tooltip = tooltip .. "|n|n" .. TRP3_API.FormatShortcutWithInstruction("LCLICK", "Select object");	

	return {
		absoluteId = absoluteId,
		title      = title,
		tooltip    = tooltip
	};
end

function TRP3_Tools_ObjectsBrowserMixin:Filter()
	local filterText = strtrim(self.filter.box:GetText():lower());
	local filter;
	if filterText == "" then
		filter = function(value)
			return true;
		end
	else
		filter = function(value)
			return string.find(value:lower(), filterText, 1, true);
		end
	end

	local model = {};
	local total, count = 0, 0;

	local currentCreationId = (not self.inventoryMode and addon.getCurrentDraftCreationId()) or nil;

	if self.inventoryMode or not self.filter.restrictToCreation:GetChecked() then
		for absoluteId, class in pairs(TRP3_DB.global) do
			if not class.hideFromList and class.TY == self.objectType and not addon.utils.isInnerIdOrEqual(currentCreationId, absoluteId) then
				if 
					not self.inventoryMode 
					or class.TY ~= TRP3_DB.types.ITEM 
					or TRP3_API.extended.isObjectMine(absoluteId)
					or not class.BA or not class.BA.PA
				then
					local _, name = TRP3_API.extended.tools.getClassDataSafeByType(class);
					if filter(absoluteId) or filter(name) then
						table.insert(model, generateObjectsBrowserLineData(absoluteId, TRP3_API.extended.getClass));
						count = count + 1;
					end
					total = total + 1;
				end
			end
		end
	end

	if currentCreationId then
		addon.editor.forEachObjectInCurrentDraft(function(absoluteId, relativeId, class)
			if class.TY == self.objectType then
				local _, name = TRP3_API.extended.tools.getClassDataSafeByType(class);
				if filter(absoluteId) or filter(name) then
					table.insert(model, generateObjectsBrowserLineData(absoluteId, addon.getCurrentDraftClass));
					count = count + 1;
				end
				total = total + 1;
			end
		end);
	end

	self.filter.total:SetText(count .. " / " .. total);

	table.sort(model, function(a, b) 
		return a.absoluteId < b.absoluteId;
	end);

	self.content.list.model:Flush();
	self.content.list.model:InsertTable(model);
end

function TRP3_Tools_ObjectsBrowserMixin:Close()
	TRP3_API.popup.hidePopups();
	self:Hide();
end

TRP3_Tools_EmotesBrowserListElementMixin = {};

function TRP3_Tools_EmotesBrowserListElementMixin:Initialize(data)
	self.data = data;
	self.token:SetText(data.token);
	self.command:SetText(strjoin(", ", unpack(data.slashCommands)));
	local tooltiptext = strjoin("|n", unpack(data.slashCommands)) .. "|n|n" ..
		TRP3_API.FormatShortcutWithInstruction("LCLICK", "Select emote");
	TRP3_API.ui.tooltip.setTooltipForSameFrame(self, "BOTTOMRIGHT", 0, 0, data.token, tooltiptext);
end

function TRP3_Tools_EmotesBrowserListElementMixin:OnEnter()
	TRP3_RefreshTooltipForFrame(self);
end

function TRP3_Tools_EmotesBrowserListElementMixin:OnLeave()
	TRP3_MainTooltip:Hide();
end

function TRP3_Tools_EmotesBrowserListElementMixin:OnClick()
	TRP3_Tools_EmotesBrowser:Select(self.data.token);
end

TRP3_Tools_EmotesBrowserMixin = {};

function TRP3_Tools_EmotesBrowserMixin:Initialize()
	self.filter.box.title:SetText(loc.UI_FILTER);

	TRP3_API.popup.EMOTES = "emotes";
	TRP3_API.popup.POPUPS[TRP3_API.popup.EMOTES] = {
		frame = self,
		showMethod = function(onSelectCallback)
			self.onSelectCallback = onSelectCallback;
			self.filter.box:SetText("");
			self.filter.box:SetFocus();
			self:Filter();
		end,
	};
	self.filter.box:SetScript("OnTextChanged", function() 
		self:Filter();
	end);
end

function TRP3_Tools_EmotesBrowserMixin:Select(token)
	self:Close();
	if self.onSelectCallback then
		self.onSelectCallback(token);
	end
end

function TRP3_Tools_EmotesBrowserMixin:Filter()
	local emoteList = addon.utils.getEmoteList();
	local model = {};
	local distance = {};
	local filterStr = strtrim(self.filter.box:GetText()):lower();
	if strlen(filterStr) > 0 then
		for index, emote in ipairs(emoteList) do
			local d = addon.utils.editDistance(emote.token:lower(), filterStr, 0.5);
			for cIndex, command in ipairs(emote.slashCommands) do
				d = math.min(d, addon.utils.editDistance(command:lower(), filterStr, 0.5));
			end
			distance[emote.token] = d;
		end
	end
	for index, emote in ipairs(emoteList) do
		if (distance[emote.token] or 0) < 0.5 then
			table.insert(model, emote);
		end
	end
	table.sort(model, function(emote1, emote2) 
		local delta = (distance[emote1.token] or 0) - (distance[emote2.token] or 0);
		if delta ~= 0 then
			return delta < 0;
		end
		return emote1.token < emote2.token;
	end);
	self.filter.total:SetText(CountTable(model) .. "/" .. CountTable(emoteList));
	self.content.list.model:Flush();
	self.content.list.model:InsertTable(model);
end

function TRP3_Tools_EmotesBrowserMixin:Close()
	TRP3_API.popup.hidePopups();
	self:Hide();
end
