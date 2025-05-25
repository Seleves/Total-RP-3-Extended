-- Copyright The Total RP 3 Extended Authors
-- SPDX-License-Identifier: Apache-2.0

local _, addon = ...

local Globals, Events, Utils = TRP3_API.globals, TRP3_Addon.Events, TRP3_API.utils;
local EMPTY = TRP3_API.globals.empty;
local loc = TRP3_API.loc;
local after  = C_Timer.After;
local getFullID, getClass = TRP3_API.extended.getFullID, TRP3_API.extended.getClass;
local setTooltipForSameFrame = TRP3_API.ui.tooltip.setTooltipForSameFrame;
local refreshTooltipForFrame = TRP3_RefreshTooltipForFrame;

local toolFrame;
local tabBar;

local TAB_TYPE = {
	CREATION    = "CREATION",
	DATABASE    = "DATABASE",
	DISCLAIMER  = "DISCLAIMER",
	CREDITS     = "CREDITS"
};

StaticPopupDialogs["TRP3_SAVE_DISCARD_CANCEL"] = {
	button1 = SAVE,
	button2 = "Discard",
	button3 = CANCEL,
	timeout = false,
	whileDead = true,
	hideOnEscape = true,
	showAlert = true,
};

local USE_NEW_EDITOR = true; -- TODO remove temporary

local drafts = {};

--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
-- API
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

TRP3_API.extended.tools = {};


local BACKGROUNDS = {
	"Interface\\ENCOUNTERJOURNAL\\UI-EJ-Classic",
	"Interface\\ENCOUNTERJOURNAL\\UI-EJ-BurningCrusade",
	"Interface\\ENCOUNTERJOURNAL\\UI-EJ-WrathoftheLichKing",
	"Interface\\ENCOUNTERJOURNAL\\UI-EJ-CATACLYSM",
	"Interface\\ENCOUNTERJOURNAL\\UI-EJ-MistsofPandaria",
	"Interface\\ENCOUNTERJOURNAL\\UI-EJ-WarlordsofDraenor",
}

function TRP3_API.extended.tools.setBackground(backgroundIndex)
	assert(BACKGROUNDS[backgroundIndex], "Unknown background index:" .. tostring(backgroundIndex));
	local texture = BACKGROUNDS[backgroundIndex];
	toolFrame.BkgMain:SetTexture(texture);
	toolFrame.BkgHeader:SetTexture(texture);
end
local setBackground = TRP3_API.extended.tools.setBackground;

local PAGE_BY_TYPE = {
	[TRP3_DB.types.CAMPAIGN] = {
		frame = "campaign",
		tabTextGetter = function(id, class) -- luacheck: ignore 212
			return ("%s: %s"):format(loc.TYPE_CAMPAIGN,  TRP3_API.inventory.getItemLink(class));
		end,
		background = 2,
	},
	[TRP3_DB.types.QUEST] = {
		frame = "quest",
		tabTextGetter = function(id, class) -- luacheck: ignore 212
			return ("%s: %s"):format(loc.TYPE_QUEST,  TRP3_API.inventory.getItemLink(class));
		end,
		background = 2,
	},
	[TRP3_DB.types.QUEST_STEP] = {
		frame = "step",
		tabTextGetter = function(id, class)
			return ("%s: %s"):format(loc.TYPE_QUEST_STEP,  TRP3_API.inventory.getItemLink(class, id));
		end,
		background = 2,
	},
	[TRP3_DB.types.ITEM] = {
		frame = "item",
		tabTextGetter = function(id, class) -- luacheck: ignore 212
			return ("%s: %s"):format(loc.TYPE_ITEM,  TRP3_API.inventory.getItemLink(class));
		end,
		tutorial = true,
		background = 3,
	},
	[TRP3_DB.types.DOCUMENT] = {
		frame = "document",
		tabTextGetter = function(id, class)
			return ("%s: %s"):format(loc.TYPE_DOCUMENT,  TRP3_API.inventory.getItemLink(class, id));
		end,
		background = 4,
	},
	[TRP3_DB.types.DIALOG] = {
		frame = "cutscene",
		tabTextGetter = function(id, class)
			return ("%s: %s"):format(loc.TYPE_DIALOG,  TRP3_API.inventory.getItemLink(class, id));
		end,
		background = 5,
	},
	[TRP3_DB.types.AURA] = {
		frame = "aura",
		tabTextGetter = function(id, class)
			return ("%s: %s"):format(loc.TYPE_AURA,  TRP3_API.inventory.getItemLink(class, id));
		end,
		background = 6,
	},
}

local function getTypeLocale(type)
	if PAGE_BY_TYPE[type] and PAGE_BY_TYPE[type].loc then
		return PAGE_BY_TYPE[type].loc;
	end
	return UNKNOWN;
end
TRP3_API.extended.tools.getTypeLocale = getTypeLocale;

local function getClassDataSafeByType(class)
	if class.TY == TRP3_DB.types.CAMPAIGN or class.TY == TRP3_DB.types.QUEST or class.TY == TRP3_DB.types.ITEM or class.TY == TRP3_DB.types.AURA then
		return TRP3_API.extended.getClassDataSafe(class);
	end
	if class.TY == TRP3_DB.types.DOCUMENT then
		if class.PA and class.PA[1] and class.PA[1].TX then
			return "inv_scroll_12", class.PA[1].TX:gsub("\n", ""):sub(1, 70) .. "...";
		else
			return "inv_scroll_12", loc.DO_EMPTY;
		end
	end
	if class.TY == TRP3_DB.types.QUEST_STEP then
		return "inv_inscription_scroll", (class.BA.TX or ""):gsub("\n", ""):sub(1, 70) .. "...";
	end
	if class.TY == TRP3_DB.types.DIALOG then
		return "ability_warrior_rallyingcry", (class.DS[1].TX or ""):gsub("\n", ""):sub(1, 70) .. "...";
	end
end
TRP3_API.extended.tools.getClassDataSafeByType = getClassDataSafeByType;

--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
-- Root object action
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

local draftData = {};
local draftRegister = {};



local function getObjectLocale(class)
	return (class.MD or EMPTY).LO or "en";
end
TRP3_API.extended.tools.getObjectLocale = getObjectLocale;

local LOCALE_FLAGS = {
	en = "Interface\\AddOns\\totalRP3_Extended\\libs\\en.tga",
	es = "Interface\\AddOns\\totalRP3_Extended\\libs\\es.tga",
	de = "Interface\\AddOns\\totalRP3_Extended\\libs\\de.tga",
	fr = "Interface\\AddOns\\totalRP3_Extended\\libs\\fr.tga",
}

local function getObjectLocaleImage(locale)
	return LOCALE_FLAGS[locale] or LOCALE_FLAGS.en;
end
TRP3_API.extended.tools.getObjectLocaleImage = getObjectLocaleImage;

local function getModeLocale(mode)
	if mode == TRP3_DB.modes.QUICK then
		return loc.MODE_QUICK;
	end
	if mode == TRP3_DB.modes.NORMAL then
		return loc.MODE_NORMAL;
	end
	if mode == TRP3_DB.modes.EXPERT then
		return loc.MODE_EXPERT;
	end
	return tostring(mode);
end
TRP3_API.extended.tools.getModeLocale = getModeLocale;

local function openObjectAndGetDraft(rootClassID, forceDraftReload)
	for k, _ in pairs(draftRegister) do
		draftRegister[k] = nil;
	end
	if forceDraftReload or toolFrame.rootClassID ~= rootClassID then
		TRP3_API.Log(("Refreshing root draft.\nPrevious: %s\nNex: %s"):format(tostring(toolFrame.rootClassID), tostring(rootClassID)));
		wipe(TRP3_Tools_Parameters.editortabs);
		wipe(draftData);
		toolFrame.rootClassID = rootClassID;
		Utils.table.copy(draftData, getClass(rootClassID));
	end
	TRP3_API.extended.registerDB({[rootClassID] = draftData}, 0, draftRegister);
	return draftData;
end

local function displayRootInfo(rootClassID, rootClass, classID, specificDraft)
	assert(rootClass.MD, "No metadata MD in root class.");
	assert(specificDraft.MD, "No metadata MD in specific class.");
	local color = "|cffffff00";
	local fieldFormat = "|cffff9900%s: " .. color .. "%s|r";

	local objectText = ("%s (%s: |cff00ffff%s|r)"):format(TRP3_API.inventory.getItemLink(rootClass, rootClassID), loc.ROOT_GEN_ID, rootClassID);
	objectText = objectText .. "\n\n" .. fieldFormat:format(loc.ROOT_VERSION, rootClass.MD.V or 0);
	objectText = objectText .. "\n\n|cffff9900" .. loc.ROOT_CREATED:format(color .. (rootClass.MD.CB or "?") .. "|r|cffff9900", "|r" .. color .. (rootClass.MD.CD or "?") .. "|r");
	objectText = objectText .. "\n\n|cffff9900" .. loc.ROOT_SAVED:format(color .. (rootClass.MD.SB or "?") .. "|r|cffff9900", "|r" .. color .. (rootClass.MD.SD or "?") .. "|r");
	toolFrame.root.text:SetText(objectText);

	toolFrame.specific:SetTitleText(getTypeLocale(specificDraft.TY));
	toolFrame.specific:SetTitleWidth(150);

	local specificText = "";
	if rootClassID == classID then
		specificText = specificText .. fieldFormat:format(loc.ROOT_GEN_ID, "|cff00ffff" .. classID .. "|r");
	else
		specificText = specificText .. fieldFormat:format(loc.SPECIFIC_INNER_ID, "|cff00ffff" .. classID .. "|r");
	end
	specificText = specificText .. "\n\n" .. fieldFormat:format(loc.TYPE, getTypeLocale(specificDraft.TY));
	toolFrame.specific.text:SetText(specificText);

	toolFrame.root.select:SetSelectedValue(getObjectLocale(rootClass));
end

--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
-- Editor save delegate
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

local goToPage;

local function checkCreation(classID, data)
	local warnings = {};
	TRP3_API.extended.iterateObject(classID, data, function(childClassID, childClass)
		local frame = toolFrame[PAGE_BY_TYPE[childClass.TY].frame or ""];
		if frame and frame.validator then
			frame.validator(childClassID, childClass, warnings);
		end
	end);
	return warnings;
end

local function doSave()
	assert(toolFrame.rootClassID, "No rootClassID in editor.");
	assert(toolFrame.fullClassID, "No fullClassID in editor.");
	local rootClassID, fullClassID = toolFrame.rootClassID, toolFrame.fullClassID;

	local rootDraft = toolFrame.rootDraft;
	local object = getClass(rootClassID);
	wipe(object);
	Utils.table.copy(object, rootDraft);
	object.MD.V = object.MD.V + 1;
	object.MD.SD = date("%d/%m/%y %H:%M:%S");
	object.MD.SB = Globals.player_id;
	object.MD.tV = Globals.extended_version;
	object.MD.dV = Utils.str.sanitizeVersion(Globals.extended_display_version);

	TRP3_API.security.computeSecurity(rootClassID, object);
	TRP3_API.extended.unregisterObject(rootClassID);
	TRP3_API.extended.registerObject(rootClassID, object, 0);
	TRP3_API.script.clearRootCompilation(rootClassID);
	TRP3_API.extended.auras.refresh();
	TRP3_Extended:TriggerEvent(TRP3_Extended.Events.REFRESH_BAG);
	TRP3_Extended:TriggerEvent(TRP3_Extended.Events.REFRESH_CAMPAIGN, rootClassID);

	goToPage(fullClassID, true);
end

local function onSave(editor)
	assert(editor, "No editor.");
	assert(editor.onSave, "No save method in editor.");
	assert(toolFrame.rootClassID, "No rootClassID in editor.");
	assert(toolFrame.fullClassID, "No fullClassID in editor.");

	-- Force save the current view in draft
	editor.onSave();
	local warnings = checkCreation(toolFrame.rootClassID, toolFrame.rootDraft);
	if #warnings > 0 then
		local joinedString = strjoin("\n\n", unpack(warnings));
		TRP3_API.popup.showConfirmPopup(loc.EDITOR_WARNINGS:format(#warnings, joinedString), function()
			doSave();
		end);
	else
		doSave();
	end
end

--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
-- Pages
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

function goToPage(fullClassID, forceDraftReload)
	local parts = {strsplit(TRP3_API.extended.ID_SEPARATOR, fullClassID)};
	local rootClassID = parts[1];
	local specificClassID = parts[#parts];

	-- First of all, save to draft if same rootID !
	if toolFrame.rootClassID == rootClassID and toolFrame.currentEditor then
		toolFrame.currentEditor.onSave();
	end

	-- Go to page
	toolFrame.database:Hide();
	toolFrame.actions:Show();
	toolFrame.specific:Show();
	toolFrame.root:Show();
	toolFrame.tutoframe:Hide();

	-- Load data
	local rootDraft = drafts[rootClassID].class;
	local specificDraft = drafts[rootClassID].register[fullClassID];
	assert(specificDraft, "Can't find specific object in draftRegister: " .. fullClassID);

	local selectedPageData, selectedPageFrame;
	-- Hide all
	for classType, pageData in pairs(PAGE_BY_TYPE) do
		local frame = toolFrame[pageData.frame or ""];
		if specificDraft.TY ~= classType then
			if frame then
				frame:Hide();
			end
		else
			selectedPageFrame = frame;
			selectedPageData = pageData;
		end
	end

	assert(selectedPageFrame, "No editor for type " .. specificDraft.TY);
	assert(selectedPageFrame.onLoad, "No load entry for type " .. specificDraft.TY);

	TRP3_ExtendedTutorial.loadStructure(nil);

	-- Show selected
	
	addon.currentEditor.cursor.objectId = fullClassID;
	
	setBackground(selectedPageData.background or 1);
	displayRootInfo(rootClassID, rootDraft, specificClassID, specificDraft);
	toolFrame.rootClassID = rootClassID;
	toolFrame.currentEditor = selectedPageFrame;
	toolFrame.fullClassID = fullClassID;
	toolFrame.specificClassID = specificClassID;
	toolFrame.rootDraft = rootDraft;
	toolFrame.specificDraft = specificDraft;
	toolFrame.currentEditor.onLoad();
	toolFrame.currentEditor:Show();


	toolFrame.actions.save:Disable();
	if TRP3_Tools_DB[rootClassID] then
		toolFrame.actions.save:Enable();
	end
	setTooltipForSameFrame(toolFrame.actions.save, "TOP", 0, 5, SAVE, loc.EDITOR_SAVE_TT:format(TRP3_API.inventory.getItemLink(rootDraft, rootClassID)));
	setTooltipForSameFrame(toolFrame.actions.cancel, "TOP", 0, 5, CANCEL, loc.EDITOR_CANCEL_TT:format(TRP3_API.inventory.getItemLink(rootDraft, rootClassID)));

	-- Create buttons up to the target
	NavBar_Reset(toolFrame.navBar);
	local fullId = "";
	for _, part in pairs(parts) do
		fullId = getFullID(fullId, part);
		local reconstruct = fullId;
		local class = drafts[rootClassID].register[reconstruct];
		local text = PAGE_BY_TYPE[class.TY].tabTextGetter(part, class);
		NavBar_AddButton(toolFrame.navBar, {id = reconstruct, name = text, OnClick = function()
			goToPage(reconstruct);
		end});
		local navButton = toolFrame.navBar.navList[#toolFrame.navBar.navList];
		navButton:SetScript("OnEnter", function(self)
			NavBar_ButtonOnEnter(self);
			refreshTooltipForFrame(self);
		end);
		navButton:SetScript("OnLeave", function(self)
			NavBar_ButtonOnLeave(self);
			TRP3_MainTooltip:Hide();
		end);
		if fullId == part then
			setTooltipForSameFrame(navButton, "TOP", 0, 5, loc.ROOT_GEN_ID, "|cff00ffff" .. part);
		else
			setTooltipForSameFrame(navButton, "TOP", 0, 5, loc.SPECIFIC_INNER_ID, "|cff00ffff" .. part);
		end
	end

end

TRP3_ToolFrameTabsMixin = {};
function TRP3_ToolFrameTabsMixin:CloseRequest(tabButton, data)
	if data.type == TAB_TYPE.CREATION then
		local openTabCount = 0;
		for _, tab in ipairs(tabBar.tabs) do
			if tab.data.type == TAB_TYPE.CREATION and tab.data.creationId == data.creationId then
				openTabCount = openTabCount + 1;
			end
		end
		if USE_NEW_EDITOR then
			addon.updateCurrentObjectDraft();
		end
		if openTabCount <= 1 then
			if TRP3_API.extended.isObjectMine(data.creationId) and not addon.utils.deepCompare(drafts[data.creationId].class, TRP3_API.extended.getClass(data.creationId)) then
				StaticPopupDialogs["TRP3_SAVE_DISCARD_CANCEL"].text = "Your creation " .. data.label .. " has unsaved changes.|nDo you want to save them?";
				StaticPopupDialogs["TRP3_SAVE_DISCARD_CANCEL"].OnAccept = function()
					addon.saveDraft(data.creationId);
					addon.deleteDraft(data.creationId);
					tabBar:Close(tabButton);
				end;
				StaticPopupDialogs["TRP3_SAVE_DISCARD_CANCEL"].OnCancel = function()
					addon.deleteDraft(data.creationId);
					tabBar:Close(tabButton);
				end;
				local dialog = StaticPopup_Show("TRP3_SAVE_DISCARD_CANCEL");
				if dialog then
					dialog:ClearAllPoints();
					dialog:SetPoint("CENTER", UIParent, "CENTER");
				end
			else
				addon.deleteDraft(data.creationId);
				self:Close(tabButton);
			end
		else
			self:Close(tabButton);
		end
	else
		self:Close(tabButton);
	end
end

function TRP3_ToolFrameTabsMixin:OnActivate(tabButton, data)
	addon.currentEditor = data;
	
	if USE_NEW_EDITOR then
		addon.saveEditor();
		addon.resetEditor();
	end
	
	toolFrame.database:Hide();
	toolFrame.editor:Hide();
	toolFrame.backers:Hide();
	toolFrame.disclaimer:Hide();

	toolFrame.actions:Hide();
	toolFrame.specific:Hide();
	toolFrame.root:Hide();
	toolFrame.tutoframe:Hide();
	toolFrame.navBar:Hide(); -- TODO legacy	
	for _, pageData in pairs(PAGE_BY_TYPE) do
		local frame = toolFrame[pageData.frame or ""];
		if frame then
			frame:Hide();
		end
	end

	if data.type == TAB_TYPE.DATABASE then
		NavBar_Reset(toolFrame.navBar);
		setBackground(1);
		toolFrame.database:Show();
		addon.refreshCreationsList();
	elseif data.type == TAB_TYPE.CREATION then
		if USE_NEW_EDITOR then
			addon.showEditor(data);
			toolFrame.editor:Show();
		else
			toolFrame.navBar:Show(); -- TODO legacy
			goToPage(data.cursor.objectId);
		end
	elseif data.type == TAB_TYPE.CREDITS then
		toolFrame.backers.scroll.child.HTML:SetText(Utils.str.toHTML(TRP3_KS_BACKERS:format(TRP3_API.extended.tools.formatVersion())));
		toolFrame.backers.scroll.child.HTML:SetScript("OnHyperlinkClick", function(self, url, text, button) -- luacheck: ignore 212
			TRP3_API.Ellyb.Popups:OpenURL(url);
		end)
		toolFrame.backers:Show();
	elseif data.type == TAB_TYPE.DISCLAIMER then
		--toolFrame.disclaimer.html:SetText(Utils.str.toHTML(loc.DISCLAIMER)); -- TODO uncomment
		toolFrame.disclaimer.html:SetText(Utils.str.toHTML([[{h1:c}Prototype - please read{/h1}

	You're using a {col:ff0000}Development Version{/col} of the Total RP 3 Extended database!

	Despite my best efforts you may encounter:

	• Missing features
	• Bugs in the user interface
	• Creations that don't work properly
	• Incompatible save files

	{h2}In order to avoid frustration, please make a {col:ff0000}Data Backup{/col} beforehand.{/h2}

	You can find here a tutorial about finding all saved data:
	{link*https://github.com/Total-RP/Total-RP-3/wiki/Saved-Variables*Where are my information stored?}

	You can find here a tutorial about syncing your data to a cloud service:
	{link*https://github.com/Total-RP/Total-RP-3/wiki/How-to-backup-and-synchronize-your-add-ons-settings-using-a-cloud-service*How to backup and synchronize your add-ons settings using a cloud service}

	The latest DEV updates are on {link*https://github.com/Seleves/Total-RP-3-Extended/tree/main*GitHub}.
	Feel free to report problems or post feedback. Please also have a look at the "known issues" section.

	Thank you for testing and your feedback.

	{p:r}Seleves{/p}]])); -- TODO remove
		toolFrame.disclaimer.html.ok:SetScript("OnClick", function()
			TRP3_Tools_Flags.has_seen_disclaimer = true;
			tabBar:Close(tabBar:FindTab(function(data) return data.type == TAB_TYPE.DISCLAIMER; end));
			addon.openDatabase();
		end);
		toolFrame.disclaimer.html:SetScript("OnHyperlinkClick", function(_, link)
			TRP3_API.popup.showTextInputPopup(loc.UI_LINK_WARNING, nil, nil, link);
		end);
		toolFrame.disclaimer:Show();
	end
end

function addon.openDraft(creationId, forceNewEditor, cursor)
	if not drafts[creationId] then
		drafts[creationId] = addon.createDraft(creationId);
	end
	local existingEditor = not forceNewEditor and addon.findDraft(creationId);
	if forceNewEditor or not existingEditor then
		local class = TRP3_API.extended.getClass(creationId);
		local link = TRP3_API.inventory.getItemLink(class, creationId);
		tabBar:AddTabAndActivate({
			type       = TAB_TYPE.CREATION,
			creationId = creationId, 
			label      = link, 
			tooltipHeader = link,
			closeable  = true,
			cursor     = cursor or {
				objectId = creationId
			}
		});
	else
		tabBar:Activate(existingEditor);
	end
end

function addon.getDraft(creationId)
	return drafts[creationId];
end

function addon.findDraft(creationId)
	return tabBar:FindTab(function(data) return data.creationId == creationId; end);
end

function addon.deleteDraft(creationId)
	wipe(drafts[creationId].class);
	wipe(drafts[creationId].register);
	wipe(drafts[creationId]);
	drafts[creationId] = nil;
end

function addon.saveDraft(creationId)
	local draftClass = drafts[creationId].class;
	draftClass.MD.V = draftClass.MD.V + 1;
	draftClass.MD.SD = date("%d/%m/%y %H:%M:%S");
	draftClass.MD.SB = TRP3_API.globals.player_id;
	draftClass.MD.tV = TRP3_API.globals.extended_version;
	draftClass.MD.dV = TRP3_API.utils.str.sanitizeVersion(TRP3_API.globals.extended_display_version);
	
	local object = TRP3_API.extended.getClass(creationId);
	wipe(object);
	TRP3_API.utils.table.copy(object, draftClass);
	
	TRP3_API.security.computeSecurity(creationId, object);

	-- TODO security level is computed on the database object, not the draft.
	-- that's why the updated security detail needs to be copied back into the draft
	-- Check if this is necessary
	draftClass.securityLevel = object.securityLevel;
	draftClass.details = draftClass.details or {};
	wipe(draftClass.details);
	TRP3_API.utils.table.copy(draftClass.details, object.details);

	TRP3_API.extended.unregisterObject(creationId);
	TRP3_API.extended.registerObject(creationId, object, 0);
	TRP3_API.script.clearRootCompilation(creationId);
	TRP3_API.extended.auras.refresh();
	TRP3_Extended:TriggerEvent(TRP3_Extended.Events.REFRESH_BAG);
	TRP3_Extended:TriggerEvent(TRP3_Extended.Events.REFRESH_CAMPAIGN, creationId);
end

function addon.closeAllDrafts(creationId)
	local tabsToClose = {};
	for _, tab in ipairs(tabBar.tabs) do
		if tab.data.type == TAB_TYPE.CREATION and tab.data.creationId == data.creationId then
			table.insert(tabsToClose, tab);
		end
	end
	for _, tab in pairs(tabsToClose) do
		tabBar:Close(tab);
	end
end

function addon.openDatabase()
	local databaseTab = tabBar:FindTab(function(data) return data.type == TAB_TYPE.DATABASE; end);
	if not databaseTab then
		tabBar:AddTabAndActivate({
			type       = TAB_TYPE.DATABASE, 
			label      = loc.DB, 
			closeable  = false
		});
	else
		tabBar:Activate(databaseTab);
	end
end

function addon.openDisclaimer()
	local disclaimerTab = tabBar:FindTab(function(data) return data.type == TAB_TYPE.DISCLAIMER; end);
	if not disclaimerTab then
		tabBar:AddTabAndActivate({
			type       = TAB_TYPE.DISCLAIMER, 
			label      = "Before you start...", 
			closeable  = false
		});
	else
		tabBar:Activate(disclaimerTab);
	end
end

function addon.openCredits()
	local creditsTab = tabBar:FindTab(function(data) return data.type == TAB_TYPE.CREDITS; end);
	if not creditsTab then
		tabBar:AddTabAndActivate({
			type       = TAB_TYPE.CREDITS, 
			label      = "Credits", 
			closeable  = true
		});
	else
		tabBar:Activate(creditsTab);
	end
end

function addon.refreshTabs()
	tabBar:Refresh();
end

function addon.forEachTab(tabFun)
	for _, tab in pairs(tabBar.tabs) do
		tabFun(tab.data);
	end
end

TRP3_API.extended.tools.goToListPage = addon.openDatabase;

-- this API must stay, it is used by the Extended main addon
TRP3_API.extended.tools.goToPage = goToPage;

-- this call was previously exposed to the API
TRP3_API.extended.tools.toList = addon.openDatabase;

function TRP3_API.extended.tools.saveTab(fullClassID, tab)
	TRP3_Tools_Parameters.editortabs[fullClassID] = tab;
end

function TRP3_API.extended.tools.getSaveTab(fullClassID, maxTabSize)
	local savedTab = TRP3_Tools_Parameters.editortabs[fullClassID];
	if savedTab and savedTab <= maxTabSize then
		return savedTab;
	else
		return 1;
	end
end

--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
-- Misc functions
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

function TRP3_API.extended.tools.truncateDecimals(args, decimals)
	if decimals and tonumber(args) then
		local tenpow = 10 ^ decimals;
		args = tostring( floor( tonumber(args) * tenpow + 0.5 ) / tenpow ) or "0";
	end
	return tostring(args);
end

--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
-- INIT
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

function TRP3_API.extended.tools.showFrame()
	--print(toolFrame:GetWidth(), toolFrame:GetHeight())

	--toolFrame:SetSize(toolFrame:GetSize());
	toolFrame:Show();
	toolFrame:Raise();
end

local function localizeTransformer(text)
	if text and text:match("^%$%{.*%}$") then
		return loc[text:sub(3, -2)] or text;
	end
	return text;
end
local localize;
localize = function(frame)
	local frameType = frame.GetFrameType and frame:GetFrameType();
	
	if frame.Localize then
		frame:Localize(localizeTransformer);
	elseif (frameType == "Button") and frame.GetText and frame.SetText then
		frame:SetText(localizeTransformer(frame:GetText()));
	end
	for _, region in pairs({frame:GetRegions()}) do
		if region.GetText and region.SetText then
			region:SetText(localizeTransformer(region:GetText()));
		end
	end
	
	for _, child in pairs({frame:GetChildren()}) do
		localize(child);
	end
end

local function onStart()

	localize(toolFrame);

	toolFrame.root:SetTitleText(loc.ROOT_TITLE);
	toolFrame.root:SetTitleWidth(150);
	toolFrame.actions:SetTitleText(loc.DB_ACTIONS);
	toolFrame.actions:SetTitleWidth(100);

	--toolFrame.actions.cancel:SetText(CANCEL)
	toolFrame.actions.save:SetScript("OnClick", function()
		onSave(toolFrame.currentEditor);
	end);
	toolFrame.actions.cancel:SetScript("OnClick", function()
		-- TODO also close the tab or maybe remove that button. it's redundant
		addon.openDatabase();
	end);
	toolFrame.root.id:SetText(loc.EDITOR_ID_COPY);
	toolFrame.root.id:SetScript("OnClick", function()
		TRP3_API.popup.showTextInputPopup(loc.EDITOR_ID_COPY_POPUP, nil, nil, toolFrame.rootClassID);
	end);
	toolFrame.specific.id:SetText(loc.EDITOR_ID_COPY);
	toolFrame.specific.id:SetScript("OnClick", function()
		TRP3_API.popup.showTextInputPopup(loc.EDITOR_ID_COPY_POPUP, nil, nil, toolFrame.fullClassID);
	end);

	PAGE_BY_TYPE[TRP3_DB.types.CAMPAIGN].loc = loc.TYPE_CAMPAIGN;
	PAGE_BY_TYPE[TRP3_DB.types.QUEST].loc = loc.TYPE_QUEST;
	PAGE_BY_TYPE[TRP3_DB.types.QUEST_STEP].loc = loc.TYPE_QUEST_STEP;
	PAGE_BY_TYPE[TRP3_DB.types.ITEM].loc = loc.TYPE_ITEM;
	PAGE_BY_TYPE[TRP3_DB.types.DOCUMENT].loc = loc.TYPE_DOCUMENT;
	PAGE_BY_TYPE[TRP3_DB.types.DIALOG].loc = loc.TYPE_DIALOG;
	PAGE_BY_TYPE[TRP3_DB.types.AURA].loc = loc.TYPE_AURA;

	-- toolFrame.Close:SetScript("OnClick", function(self) self:GetParent():Hide(); end);

	-- toolFrame.Resize.minWidth = 1150;
	-- toolFrame.Resize.minHeight = 730;
	-- toolFrame:SetSize(toolFrame.Resize.minWidth, toolFrame.Resize.minHeight);
	-- toolFrame.Resize.resizableFrame = toolFrame;
	-- toolFrame.Resize.onResizeStop = function()
	-- 	toolFrame.Minimize:Hide();
	-- 	toolFrame.Maximize:Show();
	-- 	TRP3_Extended:TriggerEvent(TRP3_Extended.Events.NAVIGATION_EXTENDED_RESIZED, toolFrame:GetWidth(), toolFrame:GetHeight());
	-- end;

	-- toolFrame.Maximize:SetScript("OnClick", function()
	-- 	toolFrame.Maximize:Hide();
	-- 	toolFrame.Minimize:Show();
	-- 	toolFrame:SetSize(UIParent:GetWidth(), UIParent:GetHeight());
	-- 	after(0.1, function()
	-- 		TRP3_Extended:TriggerEvent(TRP3_Extended.Events.NAVIGATION_EXTENDED_RESIZED, toolFrame:GetWidth(), toolFrame:GetHeight());
	-- 	end);
	-- end);

	-- toolFrame.Minimize:SetScript("OnClick", function()
	-- 	toolFrame:SetSize(toolFrame.Resize.minWidth, toolFrame.Resize.minHeight);
	-- 	after(0.1, function()
	-- 		toolFrame.Resize.onResizeStop();
	-- 	end);
	-- end);

	-- Root panel locale selection
	local template = "|T%s:11:16|t";
	local types = {
		{loc.DB_LOCALE},
		{template:format(getObjectLocaleImage("en")), "en"},
		{template:format(getObjectLocaleImage("fr")), "fr"},
		{template:format(getObjectLocaleImage("es")), "es"},
		{template:format(getObjectLocaleImage("de")), "de"},
	}
	TRP3_API.ui.listbox.setupListBox(toolFrame.root.select, types, function(value)
		if toolFrame.rootDraft and toolFrame.rootDraft.MD then
			toolFrame.rootDraft.MD.LO = value;
		end
	end, nil, 55, true);
	toolFrame.root.select:SetWidth(55);

	-- Tab bar init
	local homeData = {
		name = loc.DB,
		OnClick = function()
			addon.openDatabase();
		end
	}
	toolFrame.navBar.home:SetWidth(110);
	toolFrame.navBar.home:SetScript("OnEnter", function(self)
		NavBar_ButtonOnEnter(self);
		refreshTooltipForFrame(self);
	end);
	toolFrame.navBar.home:SetScript("OnLeave", function(self)
		NavBar_ButtonOnLeave(self);
		TRP3_MainTooltip:Hide();
	end);

	setTooltipForSameFrame(toolFrame.navBar.home, "TOP", 0, 5, loc.DB, loc.DB_WARNING);
	local DummyDropdownFrame = CreateFrame("Frame");
	NavBar_Initialize(toolFrame.navBar, "NavButtonTemplate", homeData, toolFrame.navBar.home, toolFrame.navBar.overflow);
	UIDropDownMenu_Initialize(DummyDropdownFrame, nop); -- Some voodoo magic to prevent taint due to Edit Mode

	-- Init effects and operands
	local effectMenu = TRP3_API.extended.tools.getEffectOperandLocale();
	TRP3_API.extended.tools.initBaseEffects();
	TRP3_API.extended.tools.initCampaignEffects();
	TRP3_API.extended.tools.initItemEffects();
	TRP3_API.extended.tools.initAuraEffects();

	-- Init editors
	TRP3_API.extended.tools.initScript(toolFrame, effectMenu);

	addon.global_popups.initialize();

	TRP3_InnerObjectEditor.init(toolFrame);
	TRP3_LinksEditor.init(toolFrame);
	TRP3_API.extended.tools.initDocument(toolFrame);
	TRP3_API.extended.tools.initCampaign(toolFrame);
	TRP3_API.extended.tools.initQuest(toolFrame);
	TRP3_API.extended.tools.initStep(toolFrame)
	TRP3_API.extended.tools.initItems(toolFrame);
	TRP3_API.extended.tools.initCutscene(toolFrame);
	TRP3_API.extended.tools.initAura(toolFrame);
	TRP3_API.extended.tools.initList(toolFrame);
	TRP3_API.extended.tools.initEditor(toolFrame);
	
	TRP3_ExtendedTutorial.init(toolFrame);

	TRP3_Extended:TriggerEvent(TRP3_Extended.Events.NAVIGATION_EXTENDED_RESIZED, toolFrame:GetWidth(), toolFrame:GetHeight());

	-- Bindings

	BINDING_NAME_TRP3_EXTENDED_TOOLS = loc.TB_TOOLS;

	TRP3_API.RegisterCallback(TRP3_Addon, Events.WORKFLOW_ON_FINISH, function()
		if TRP3_Tools_Flags.has_seen_disclaimer then
			addon.openDisclaimer(); -- TODO remove
			--addon.openDatabase(); -- TODO uncomment
		else
			addon.openDisclaimer();
		end
		
	end);

	TRP3_API.ui.frame.setupMove(toolFrame);
end

local function onInit()
	toolFrame = TRP3_ToolFrame;
	toolFrame.warnings = {};
	
	tabBar = TRP3_ToolFrameTabs;

	if not TRP3_Tools_Parameters then
		TRP3_Tools_Parameters = {};
	end
	if not TRP3_Tools_Parameters.editortabs then
		TRP3_Tools_Parameters.editortabs = {};
	end
	if not TRP3_Tools_Flags then
		TRP3_Tools_Flags = {};
	end
end

local MODULE_STRUCTURE = {
	["name"] = "Extended Tools",
	["description"] = "Total RP 3 extended tools: item, document and campaign creation.",
	["version"] = Globals.extended_version,
	["id"] = "trp3_extended_tools",
	["onStart"] = onStart,
	["onInit"] = onInit,
	["minVersion"] = Globals.required_trp3_build,
	["requiredDeps"] = {
		{"trp3_extended", Globals.extended_version},
	}
};

TRP3_API.module.registerModule(MODULE_STRUCTURE);
