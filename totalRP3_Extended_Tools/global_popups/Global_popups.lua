local _, addon = ...
local loc = TRP3_API.loc;

addon.global_popups = {};

local objectBrowser = TRP3_ObjectBrowser;
local filteredObjectList = {};

local function onBrowserClose()
	TRP3_API.popup.hidePopups();
	objectBrowser:Hide();
end

local function onBrowserLineClick(frame)
	onBrowserClose();
	if objectBrowser.onSelectCallback then
		objectBrowser.onSelectCallback(frame.objectID);
	end
end

local fieldFormat = "%s: " .. TRP3_API.Colors.Yellow("%s|r");

local function decorateBrowserLine(frame, index)
	local objectID = filteredObjectList[index];
	local class = TRP3_API.extended.getClass(objectID);
	local fullLink = TRP3_API.inventory.getItemLink(class, objectID, true);
	local link = TRP3_API.inventory.getItemLink(class, objectID);

	_G[frame:GetName().."Text"]:SetText(fullLink);

	local text = "";
	local title = fullLink;
	local parts = {strsplit(TRP3_API.extended.ID_SEPARATOR, objectID)};
	local rootClass = TRP3_API.extended.getClass(parts[1]);
	local metadata = rootClass.MD or TRP3_API.globals.empty;

	text = text .. fieldFormat:format(loc.TYPE, TRP3_API.extended.tools.getTypeLocale(class.TY));
	text = text .. "\n" .. fieldFormat:format(loc.ROOT_CREATED_BY, metadata.CB or "?");
	text = text .. "\n" .. fieldFormat:format(loc.SEC_LEVEL, TRP3_API.security.getSecurityText(rootClass.securityLevel or SECURITY_LEVEL.LOW));

	if class.TY == TRP3_DB.types.ITEM then
		local base = class.BA or TRP3_API.globals.empty;

		text = text .. "\n";

		text = text .. "\n" .. TRP3_API.utils.str.icon(base.IC or "temp", 25) .. " " .. link;
		if base.LE or base.RI then
			if base.LE and not base.RI then
				text = text .. "\n" .. TRP3_API.Colors.White(base.LE);
			elseif base.RI and not base.LE then
				text = text .. "\n" .. TRP3_API.Colors.White(base.RI);
			else
				text = text .. "\n" .. TRP3_API.Colors.White(base.LE .. " - " .. base.RI);
			end
		end
		if base.DE then
			local argsStructure = {object = {id = objectID}};
			text = text .. "\n" .. TRP3_API.Colors.Yellow("\"" .. TRP3_API.script.parseArgs(base.DE .. "\"", argsStructure));
		end
		text = text .. "\n" .. TRP3_API.Colors.White(TRP3_API.extended.formatWeight(base.WE or 0) .. " - " .. C_CurrencyInfo.GetCoinTextureString(base.VA or 0));

	end

	TRP3_API.ui.tooltip.setTooltipForSameFrame(frame, "TOP", 0, 5, title, text);

	frame.objectID = objectID;
end

local function filterMatch(filter, value)
	-- No filter or bad filter
	if filter == nil or filter:len() == 0 then
		return true;
	end
	return string.find(value:lower(), filter:lower(), 1, true);
end

local function filteredObjectBrowser()
	local filter = objectBrowser.filter.box:GetText();
	wipe(filteredObjectList);

	local total, count = 0, 0;
	for objectFullID, class in pairs(TRP3_DB.global) do
		if not class.hideFromList and class.TY == objectBrowser.type then
			if not objectBrowser.itemFilter or class.TY ~= TRP3_DB.types.ITEM or not class.BA or not class.BA.PA then
				local _, name = TRP3_API.extended.tools.getClassDataSafeByType(class);
				if filterMatch(filter, objectFullID) or filterMatch(filter, name) then
					tinsert(filteredObjectList, objectFullID);
					count = count + 1;
				end
				total = total + 1;
			end
		end
	end
	objectBrowser.filter.total:SetText( (#filteredObjectList) .. " / " .. total );

	table.sort(filteredObjectList);

	TRP3_API.ui.list.initList(
		{
			widgetTab = objectBrowser.widgetTab,
			decorate = decorateBrowserLine
		},
		filteredObjectList,
		objectBrowser.content.slider
	);
end

local function showObjectBrowser(onSelectCallback, type, itemFilter)
	objectBrowser.title:SetText(loc.DB_BROWSER .. " (" .. TRP3_API.extended.tools.getTypeLocale(type) .. ")")
	objectBrowser.onSelectCallback = onSelectCallback;
	objectBrowser.type = type;
	objectBrowser.filter.box:SetText("");
	objectBrowser.filter.box:SetFocus();
	objectBrowser.itemFilter = itemFilter;
	filteredObjectBrowser();
end

function objectBrowser.init()
	TRP3_API.ui.list.handleMouseWheel(objectBrowser.content, objectBrowser.content.slider);
	objectBrowser.content.slider:SetValue(0);

	-- Create icons
	objectBrowser.widgetTab = {};

	-- Create lines
	for line = 0, 8 do
		local button = CreateFrame("Button", "TRP3_ObjectBrowserButton_" .. line, objectBrowser.content, "TRP3_ObjectBrowserLine");
		button:SetPoint("TOP", objectBrowser.content, "TOP", 0, -10 + (line * (-31)));
		button:SetScript("OnClick", onBrowserLineClick);
		tinsert(objectBrowser.widgetTab, button);
	end

	objectBrowser.filter.box:SetScript("OnTextChanged", filteredObjectBrowser);
	objectBrowser.close:SetScript("OnClick", onBrowserClose);

	objectBrowser.filter.box.title:SetText(loc.UI_FILTER);

	TRP3_API.popup.OBJECTS = "objects";
	TRP3_API.popup.POPUPS[TRP3_API.popup.OBJECTS] = {
		frame = objectBrowser,
		showMethod = showObjectBrowser,
	};
end

function addon.global_popups.initialize()
	objectBrowser.init();
	TRP3_Tools_EmotesBrowser:Initialize();
end