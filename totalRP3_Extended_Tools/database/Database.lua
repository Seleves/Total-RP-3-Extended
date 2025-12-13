-- Copyright The Total RP 3 Extended Authors
-- SPDX-License-Identifier: Apache-2.0

local _, addon = ...
local loc = TRP3_API.loc;

---@type Ellyb;
local LibDeflate = LibStub:GetLibrary("LibDeflate");

addon.database = {};

local databaseFrame;
local creationsList;
local creationsFilter;

local hasImportExportModule = false;

local SUPPOSED_SERIAL_SIZE_LIMIT = 500000; -- We suppose the text field can only handle 500k pastes

--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
-- List management: util methods
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

local color = "|cffffff00";
local fieldFormat = "%s: " .. color .. "%s|r";

local function getMetadataTooltipText(rootID, rootClass, isRoot, innerID, type)
	local metadata = rootClass.MD or TRP3_API.globals.empty;
	local text = "";

	if isRoot then
		text = text .. fieldFormat:format(loc.ROOT_GEN_ID, "|cff00ffff" .. rootID .. "|r");
		text = text .. "\n" .. fieldFormat:format(loc.ROOT_VERSION, metadata.V or 1);
		text = text .. "\n" .. fieldFormat:format(loc.ROOT_CREATED_BY, metadata.CB or "?");
		text = text .. "\n" .. fieldFormat:format(loc.ROOT_CREATED_ON, metadata.CD or "?");
		text = text .. "\n" .. fieldFormat:format(loc.SEC_LEVEL, TRP3_API.security.getSecurityText(rootClass.securityLevel or TRP3_API.security.SECURITY_LEVEL.LOW));
	else
		text = text .. fieldFormat:format(loc.SPECIFIC_INNER_ID, "|cff00ffff" .. innerID .. "|r");
	end

	text = text .. "\n" .. fieldFormat:format(loc.SPECIFIC_MODE, TRP3_API.extended.tools.getModeLocale(metadata.MO) or "?");
	text = text .. "\n\n" .. TRP3_API.FormatShortcutWithInstruction("LCLICK", loc.CM_OPEN);
	text = text .. "\n" .. TRP3_API.FormatShortcutWithInstruction("RCLICK", loc.DB_ACTIONS);
	if type == TRP3_DB.types.ITEM or type == TRP3_DB.types.CAMPAIGN then
		text = text .. "\n" .. TRP3_API.FormatShortcutWithInstruction("SHIFT-CLICK", loc.CL_TOOLTIP);
	end
	return text;
end

function TRP3_API.extended.tools.formatVersion(version)
	if not version then
		return TRP3_API.utils.str.sanitizeVersion(TRP3_API.globals.extended_display_version);
	end

	-- Fixing the mess
	if (version == 1010) then
		return "1.0.9.1"
	elseif (version == 1011) then
		return "1.1.0"
	elseif (version == 1012) then
		return "1.1.1"
	end

	-- Before the change
	local v = tostring(version);
	local inter = tostring(tonumber(v:sub(2, 3)));
	return v:sub(1, 1) .. "." .. inter .. "." .. v:sub(4, 4);
end

function TRP3_API.extended.tools.getClassVersion(rootID)
	if not rootID.MD.tV and not rootID.MD.dV then
		return "?"
	end

	if rootID.MD.dV then	-- Display version in the creation data (after 1.1.1)
		return rootID.MD.dV
	elseif (rootID.MD.tV <= 1012) then	-- No display version (1.1.1 and before)
		return TRP3_API.extended.tools.formatVersion(rootID.MD.tV);
	else	-- Shouldn't happen
		return rootID.MD.tV
	end
end


--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
-- INIT
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

function addon.database.initialize(frame)
	databaseFrame = frame;
	
	creationsList   = databaseFrame.split.creations.listWrapper.list;
	creationsFilter = databaseFrame.split.creations.filter;
	
	creationsFilter:SetTitleText(loc.DB_FILTERS);
	creationsFilter:SetTitleWidth(150);

	-- Events
	TRP3_API.RegisterCallback(TRP3_Extended, TRP3_Extended.Events.ON_OBJECT_UPDATED, function(_, objectID, objectType) -- luacheck: ignore 212
		addon.database.refreshCreationsList();
	end);
	
	creationsList.model:SetSortComparator(function(a, b) 
		return a.name < b.name;
	end, true);

	-- Filters
	creationsFilter.name:SetScript("OnEnterPressed", addon.database.refreshCreationsList);
	creationsFilter.id:SetScript("OnEnterPressed", addon.database.refreshCreationsList);
	creationsFilter.owner:SetScript("OnEnterPressed", addon.database.refreshCreationsList);
	TRP3_API.ui.frame.setupEditBoxesNavigation({
		creationsFilter.owner,
		creationsFilter.name,
		creationsFilter.id,
	})
	local types = {
		{loc.ALL, ""},
		{loc.TYPE_CAMPAIGN, TRP3_DB.types.CAMPAIGN},
		{loc.TYPE_ITEM, TRP3_DB.types.ITEM}
	}
	TRP3_API.ui.listbox.setupListBox(creationsFilter.type, types, addon.database.refreshCreationsList);
	
	local template = "|T%s:11:16|t";
	local locales = {
		{loc.ALL, ""},
		{template:format(TRP3_API.extended.tools.getObjectLocaleImage("en")), "en"},
		{template:format(TRP3_API.extended.tools.getObjectLocaleImage("fr")), "fr"},
		{template:format(TRP3_API.extended.tools.getObjectLocaleImage("es")), "es"},
		{template:format(TRP3_API.extended.tools.getObjectLocaleImage("de")), "de"},
	}
	TRP3_API.ui.listbox.setupListBox(creationsFilter.locale, locales, addon.database.refreshCreationsList);
	creationsFilter.locale:SetSelectedValue("");
	creationsFilter.type:SetSelectedValue("");
	creationsFilter.search:SetScript("OnClick", addon.database.refreshCreationsList);
	creationsFilter.clear:SetScript("OnClick", function()
		creationsFilter.type:SetSelectedValue("");
		creationsFilter.locale:SetSelectedValue("");
		creationsFilter.name:SetText("");
		creationsFilter.id:SetText("");
		creationsFilter.owner:SetText("");
		addon.database.refreshCreationsList();
	end);

	-- Export
	do
		databaseFrame.export.title:SetText(loc.DB_EXPORT);

		---@type SimpleHTML
		local wagoInfo = databaseFrame.export.wagoInfo;
		wagoInfo:SetText(HTML_START .. loc.DB_WAGO_INFO .. HTML_END);
		wagoInfo:SetScript("OnHyperlinkClick", function(self, url)
			TRP3_API.popup.showTextInputPopup(loc.UI_LINK_WARNING, nil, nil, url);
		end);
	end

	---@type SimpleHTML
	local wagoInfo = databaseFrame.import.wagoInfo;
	wagoInfo:SetText(HTML_START .. loc.DB_IMPORT_TT_WAGO .. HTML_END);
	wagoInfo:SetScript("OnHyperlinkClick", function(self, url)
		TRP3_API.popup.showTextInputPopup(loc.UI_LINK_WARNING, nil, nil, url);
	end);

	databaseFrame.import.title:SetText(loc.DB_IMPORT);
	databaseFrame.import.content.title:SetText(loc.DB_IMPORT_TT);

	databaseFrame.import.save:SetText(loc.DB_IMPORT_WORD);
	databaseFrame.import.save:SetScript("OnClick", function()
		local code = databaseFrame.import.content.scroll.text:GetText();
		local encoded, usesLibDeflate = code:gsub("^%!", "");
		if usesLibDeflate == 1 then
			code = LibDeflate:DecodeForPrint(encoded);
			code = AddOn_TotalRP3.Compression.decompress(code, false);
		end
		code = code:gsub("||", "|");
		local object = TRP3_API.utils.serial.safeDeserialize(code);
		if object and type(object) == "table" and (#object == 3 or #object == 4) then
			local version = object[1];
			local ID = object[2];
			local data = object[3];
			local displayVersion = TRP3_API.utils.str.sanitizeVersion(object[4]);
			local link = TRP3_API.inventory.getItemLink(data);
			local by = data.MD.CB;
			local objectVersion = data.MD.V or 0;
			local type = TRP3_API.extended.tools.getTypeLocale(data.TY);
			TRP3_API.popup.showConfirmPopup(loc.DB_IMPORT_FULL_CONFIRM:format(type, link, by, objectVersion), function()
				C_Timer.After(0.25, function()
					importFunction(version, ID, data, displayVersion);
					addon.database.refreshCreationsList(); -- After importing go to full database, so we see what we have imported
					-- TODO make sure the imported object is visible
				end);
			end);
		else
			TRP3_API.utils.message.displayMessage(loc.DB_IMPORT_ERROR1, 2);
		end
	end);

	-- Detect import/export module
	hasImportExportModule = C_AddOns.IsAddOnLoaded("totalRP3_Extended_ImpExport");
	if hasImportExportModule then
		if not TRP3_Extended_ImpExport then
			TRP3_Extended_ImpExport = {};
		end
		if TRP3_Tools_Flags.exportAlert then
			TRP3_Tools_Flags.exportAlert = nil;
			TRP3_API.utils.message.displayMessage(loc.DB_EXPORT_DONE, 2);
		end
	end
	
end
TRP3_API.extended.tools.initList = addon.database.initialize; -- TODO consider removing this from the API


function addon.database.refreshCreationsList()

	local typeFilter    = creationsFilter.type:GetSelectedValue();
	local localeFilter  = creationsFilter.locale:GetSelectedValue();
	local createdFilter = TRP3_API.utils.str.emptyToNil(strtrim(creationsFilter.owner:GetText()));
	local nameFilter    = TRP3_API.utils.str.emptyToNil(strtrim(creationsFilter.name:GetText()));
	local idFilter      = TRP3_API.utils.str.emptyToNil(strtrim(creationsFilter.id:GetText()));
	local hasFilter     = createdFilter or nameFilter or idFilter or typeFilter ~= "" or localeFilter ~= "";
	
	local filter = function(class)
		return true;
	end;
	
	if hasFilter then
		filter = function(class)
			return 
				(not createdFilter  or (class.MD.CB and class.MD.CB:lower():find(createdFilter:lower())))
			and (not nameFilter     or (class.BA.NA and class.BA.NA:lower():find(nameFilter:lower())))
			and (not idFilter       or (classFullID:lower():find(idFilter:lower())))
			and (typeFilter == ""   or typeFilter == class.TY)
			and (localeFilter == "" or localeFilter == class.MD.LO)
			;			
		end;
	end

	local rootCreations = {};
	local creationsTotal = 0;
	local creationsFiltered = 0;
	for _, source in pairs({"my", "exchange", "inner"}) do
		for creationId, class in pairs(TRP3_DB[source] or TRP3_API.globals.empty) do
			if not creationId:find(TRP3_API.extended.ID_SEPARATOR) and not class.hideFromList then
				local icon = TRP3_API.extended.tools.getClassDataSafeByType(class);
				local link = TRP3_API.inventory.getItemLink(class, creationId);
				creationsTotal = creationsTotal + 1;
				if filter(class) then
					table.insert(rootCreations, {
						type = class.TY,
						icon = icon,
						link = link,
						creationId = creationId,
						name = (class.BA and class.BA.NA) or "",
						creator = (class.MD and class.MD.CB) or "unknown",
						source = source,
						metadataTooltip = getMetadataTooltipText(creationId, class, true, creationId, class.TY)
					});
					creationsFiltered = creationsFiltered + 1;
				end
			end
		end
	end
	
	if hasFilter then
		creationsList:GetParent().filterText:SetText(("filter: showing %d out of %d creations"):format(creationsFiltered, creationsTotal));
		creationsList:GetParent().filterText:Show();
		creationsList:SetPoint("TOPLEFT", 0, -20);
	else
		creationsList:GetParent().filterText:Hide();
		creationsList:SetPoint("TOPLEFT");
	end
	
	local scrollPct = creationsList.widget:GetScrollPercentage();
	creationsList.model:Flush();
	creationsList.model:InsertTable(rootCreations);
	creationsList.widget:SetScrollPercentage(scrollPct);
end

function addon.database.removeCreation(creationId)
	addon.closeAllDrafts(creationId);
	TRP3_API.extended.removeObject(creationId);
	addon.database.refreshCreationsList();
end

function addon.database.serializeCreation(creationId)
	local class = TRP3_API.extended.getClass(creationId);
	local serial = TRP3_API.utils.serial.serialize({TRP3_API.globals.extended_version, creationId, class, TRP3_API.utils.str.sanitizeVersion(TRP3_API.globals.extended_display_version)});
	serial = serial:gsub("|", "||");
	serial = AddOn_TotalRP3.Compression.compress(serial, false);
	serial = "!" .. LibDeflate:EncodeForPrint(serial);
	if serial:len() < SUPPOSED_SERIAL_SIZE_LIMIT then
		databaseFrame.export.content.scroll.text:SetText(serial);
		databaseFrame.export.content.title:SetText(loc.DB_EXPORT_HELP:format(TRP3_API.inventory.getItemLink(class), serial:len() / 1024));
		databaseFrame.export:Show();
	else
		TRP3_API.utils.message.displayMessage(loc.DB_EXPORT_TOO_LARGE:format(serial:len() / 1024), 2);
	end
end

function addon.database.exportCreation(creationId)
	if hasImportExportModule then
		wipe(TRP3_Extended_ImpExport);
		TRP3_Extended_ImpExport.id = creationId;
		TRP3_Extended_ImpExport.object = {};
		TRP3_Extended_ImpExport.date = date("%d/%m/%y %H:%M:%S");
		TRP3_Extended_ImpExport.version = TRP3_API.globals.extended_version;
		TRP3_Extended_ImpExport.display_version = TRP3_API.utils.str.sanitizeVersion(TRP3_API.globals.extended_display_version);
		TRP3_API.utils.table.copy(TRP3_Extended_ImpExport.object, TRP3_API.extended.getClass(creationId));
		TRP3_Tools_Flags.exportAlert = true;
		ReloadUI();
	else
		TRP3_API.utils.message.displayMessage(loc.DB_EXPORT_MODULE_NOT_ACTIVE, 2);
	end
end

function addon.database.copyCreation(creationId)
	local fromClass = TRP3_API.extended.getClass(creationId);
	local copiedData = {};
	local generatedId = TRP3_API.utils.str.id();
	TRP3_API.utils.table.copy(copiedData, fromClass);
	copiedData.MD = {
		MO = copiedData.MD.MO,
		V = 1,
		CD = date("%d/%m/%y %H:%M:%S");
		CB = TRP3_API.globals.player_id,
		SD = date("%d/%m/%y %H:%M:%S");
		SB = TRP3_API.globals.player_id,
	};
	addon.utils.replaceId(copiedData, creationId, generatedId);
	local copyId, _ = TRP3_API.extended.tools.createItem(copiedData, generatedId);
	addon.database.refreshCreationsList();
	addon.openDraft(copyId);
end

function addon.database.importCreation(version, ID, data, displayVersion)
	local type = data.TY;
	local objectVersion = data.MD.V or 0;
	local author = data.MD.CB;

	displayVersion = TRP3_API.utils.str.sanitizeVersion(displayVersion)

	assert(type and author, "Corrupted import structure.");

	local import = function()
		if TRP3_API.extended.classExists(ID) then
			TRP3_API.extended.removeObject(ID);
		end
		local DB;
		if author == TRP3_API.globals.player_id then
			DB = TRP3_DB.my;
		else
			DB = TRP3_DB.exchange;
		end
		DB[ID] = {};
		TRP3_API.utils.table.copy(DB[ID], data);
		TRP3_API.extended.registerObject(ID, DB[ID], 0);
		TRP3_API.security.registerSender(ID, author);
		databaseFrame.import:Hide();
		addon.database.refreshCreationsList();
		TRP3_API.utils.message.displayMessage(loc.DB_IMPORT_DONE, 3);
		TRP3_Extended:TriggerEvent(TRP3_Extended.Events.REFRESH_BAG);
		TRP3_Extended:TriggerEvent(TRP3_Extended.Events.REFRESH_CAMPAIGN);

		if DB[ID].securityLevel ~= 3 then
			TRP3_API.security.showSecurityDetailFrame(ID, databaseFrame:GetParent());
		end
	end

	local checkVersion = function()
		if TRP3_API.extended.classExists(ID) and TRP3_API.extended.getClass(ID).MD.V > objectVersion then
			TRP3_API.popup.showConfirmPopup(loc.DB_IMPORT_VERSION:format(objectVersion, TRP3_API.extended.getClass(ID).MD.V), function()
				C_Timer.After(0.25, import);
			end);
		else
			import();
		end
	end

	if version ~= TRP3_API.globals.extended_version then
		TRP3_API.popup.showConfirmPopup(loc.DB_IMPORT_CONFIRM:format(displayVersion or TRP3_API.extended.tools.formatVersion(version), TRP3_API.extended.tools.formatVersion()), function()
			C_Timer.After(0.25, checkVersion);
		end);
	else
		checkVersion();
	end
end
