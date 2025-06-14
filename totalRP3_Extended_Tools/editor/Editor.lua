local _, addon = ...

local loc = TRP3_API.loc;

addon.editor = {};

local statusBar;
local objectTree;
local noteFrame;
local editorsByType = {};
local modalPopups = {};

local currentEditor;
local currentDraft;
local currentObject;

local function updateTabBar()
	addon.forEachTab(function(editor) 
		if editor.creationId == currentEditor.creationId then
			local body = "";
			local absoluteId;
			local isRoot = true;
			local root, last;
			local level = 1;
			for relativeId in editor.cursor.objectId:gmatch("[^%" .. TRP3_API.extended.ID_SEPARATOR .. "]+") do
				if isRoot then
					absoluteId = relativeId;
					local icon, link = addon.utils.getObjectIconAndLink(currentDraft.index[absoluteId].class);
					root = ("|T%s:16:16|t %s"):format(icon, link);
				else
					absoluteId = absoluteId .. TRP3_API.extended.ID_SEPARATOR .. relativeId;
					local icon, link = addon.utils.getObjectIconAndLink(currentDraft.index[absoluteId].class);
					last = ("|T%s:16:16|t %s"):format(icon, link);
					local indent = ("\n|TInterface\\COMMON\\spacer:16:%d|t|TInterface\\\MONEYFRAME\\Arrow-Right-Down:16:16|t"):format(level*16);
					level = level + 1;
					body = body .. indent .. last;
				end
				isRoot = false;
			end
			if last == nil then
				editor.label = root;
				editor.tooltipHeader = root;
				editor.tooltipBody = nil;
			else
				editor.label = root;
				editor.tooltipHeader = root;
				editor.tooltipBody = body;
			end
		end
	end);
	addon.refreshTabs();
end

function isRelativeIdAvailable(class, relativeId)
	return 
		(not class.QE or not class.QE[relativeId])
	and (not class.ST or not class.ST[relativeId])
	and (not class.IN or not class.IN[relativeId])
	;
end

local function buildObjectTree(creationId, creationClass)
	local index = {};
	local stack = {};
	local model = CreateTreeDataProvider();
	table.insert(stack, {
		relativeId = creationId,
		absoluteId = creationId,
		class      = creationClass,
		parent     = model
	});
	while TableHasAnyEntries(stack) do
		local top = table.remove(stack);
		local icon, link = addon.utils.getObjectIconAndLink(top.class);
		local node = top.parent:Insert({
			icon       = icon,
			link       = link,
			relativeId = top.relativeId,
			absoluteId = top.absoluteId
		});
		index[top.absoluteId] = {
			class = top.class,
			node  = node
		};
		for _, childKey in ipairs_reverse({"QE", "ST", "IN"}) do
			if top.class[childKey] then
				local tmp = {};
				for id, _ in pairs(top.class[childKey]) do
					table.insert(tmp, id);
				end
				table.sort(tmp);
				for _, id in ipairs_reverse(tmp) do
					table.insert(stack, {
						relativeId = id,
						absoluteId = top.absoluteId .. TRP3_API.extended.ID_SEPARATOR .. id,
						class      = top.class[childKey][id],
						parent     = node;
					});
				end
			end
		end
	end
	model:CollapseAll();
	model:GetFirstChildNode():SetCollapsed(false); -- expand level 1
	return model, index;
end

function rebuildTreeAndShow(absoluteId)
	local model, index = buildObjectTree(currentEditor.creationId, currentDraft.class);
	currentObject = nil;
	currentDraft.model = model;
	currentDraft.index = index;
	objectTree.model = currentDraft.model;
	objectTree.widget:SetDataProvider(currentDraft.model);
	addon.displayObject(absoluteId);
	addon.refreshObjectTree();
end

function addon.getCurrentDraftClass(absoluteId)
	if absoluteId then
		return currentDraft.index[absoluteId] and currentDraft.index[absoluteId].class or nil;
	else
		return currentObject and currentObject.class or nil;
	end
end

function addon.getCurrentDraftCreationId()
	return currentEditor.creationId;
end

-----------------------
-- Tree manipulation --
-----------------------

function addon.copySelectedTreeObjects()
	addon.updateCurrentObjectDraft();
	for absoluteId, object in pairs(currentDraft.index) do
		if object.node.data.selected then
			addon.clipboard.append(object.class, object.class.TY, absoluteId, object.node.data.relativeId);
		end
	end
end

function addon.pasteClipboardAsInnerObjects(absoluteId)
	local object = currentDraft.index[absoluteId];
	if addon.clipboard.isInnerCompatible(object.class.TY) then
		local newRelativeIds = {};
		for index = 1, addon.clipboard.count() do
			local oldInnerAbsoluteId = addon.clipboard.retrieveId(index);
			local ids = {strsplit(TRP3_API.extended.ID_SEPARATOR, oldInnerAbsoluteId)};
			local relativeId = ids[#ids] or "";
			table.insert(newRelativeIds, relativeId);
			if not isRelativeIdAvailable(object.class, relativeId) then
				return false, "At least one object cannot be pasted here, because its id already exists."; -- TODO
			end
		end
		
		for index = 1, addon.clipboard.count() do
			local oldInnerAbsoluteId = addon.clipboard.retrieveId(index);
			local newRelativeId = newRelativeIds[index];
			local innerClass = addon.clipboard.retrieve(index);
			innerClass.MD = nil;
			addon.utils.replaceId(innerClass, oldInnerAbsoluteId, absoluteId .. TRP3_API.extended.ID_SEPARATOR .. newRelativeId);
			if innerClass.TY == TRP3_DB.types.QUEST then
				object.class.QE = object.class.QE or {};
				object.class.QE[newRelativeId] = innerClass;
			elseif innerClass.TY == TRP3_DB.types.QUEST_STEP then
				object.class.ST = object.class.ST or {};
				object.class.ST[newRelativeId] = innerClass;
			else
				object.class.IN = object.class.IN or {};
				object.class.IN[newRelativeId] = innerClass;
			end
		end
		
		rebuildTreeAndShow(absoluteId);
		return true;
	else
		return false, "At least one object cannot be pasted here, because the type doesn't fit."; -- TODO
	end
end

function addon.appendInnerObject(absoluteId, relativeId, type)
	local object = currentDraft.index[absoluteId];
	if isRelativeIdAvailable(object.class, relativeId) then
		addon.updateCurrentObjectDraft();
		local innerClass, field = addon.utils.createEmptyClass(type);
		object.class[field] = object.class[field] or {};
		object.class[field][relativeId] = innerClass;
		local innerAbsoluteId = absoluteId .. TRP3_API.extended.ID_SEPARATOR .. relativeId;
		rebuildTreeAndShow(innerAbsoluteId);
		return true;
	else
		return false, loc.IN_INNER_NO_AVAILABLE;
	end
end

function addon.replaceCurrentDraftClass(absoluteId, newClassShallow, originalAbsoluteId)
	addon.updateCurrentObjectDraft();
	local class = currentDraft.index[absoluteId].class;
	local MD = class.MD;
	wipe(class);
	TRP3_API.utils.table.copy(class, newClassShallow);
	addon.utils.replaceId(class, originalAbsoluteId, absoluteId);
	class.MD = MD;
	rebuildTreeAndShow(absoluteId);
end

function addon.deleteInnerObjectById(absoluteId)
	local parentId   = currentDraft.index[absoluteId].node:GetParent().data.absoluteId;
	local parent     = currentDraft.index[parentId];
	local object     = currentDraft.index[absoluteId];
	local relativeId = object.node.data.relativeId;
	if object.class.TY == TRP3_DB.types.QUEST then
		parent.class.QE[relativeId] = nil;
	elseif object.class.TY == TRP3_DB.types.QUEST_STEP then
		parent.class.ST[relativeId] = nil;
	else
		parent.class.IN[relativeId] = nil;
	end
	rebuildTreeAndShow(parentId);
end

function addon.changeRelativeId(absoluteId, newRelativeId)
	local parentId = currentDraft.index[absoluteId].node:GetParent().data.absoluteId;
	local parent = currentDraft.index[parentId];
	if isRelativeIdAvailable(parent.class, newRelativeId) then
		addon.updateCurrentObjectDraft();
		local object = currentDraft.index[absoluteId];
		local oldRelativeId = object.node.data.relativeId;
		if object.class.TY == TRP3_DB.types.QUEST then
			parent.class.QE[newRelativeId] = parent.class.QE[oldRelativeId];
			parent.class.QE[oldRelativeId] = nil;
		elseif object.class.TY == TRP3_DB.types.QUEST_STEP then
			parent.class.ST[newRelativeId] = parent.class.ST[oldRelativeId];
			parent.class.ST[oldRelativeId] = nil;
		else
			parent.class.IN[newRelativeId] = parent.class.IN[oldRelativeId];
			parent.class.IN[oldRelativeId] = nil;
		end
		local newAbsoluteId = parentId .. TRP3_API.extended.ID_SEPARATOR .. newRelativeId;
		addon.utils.replaceId(currentDraft.class, absoluteId, newAbsoluteId);
		local currentObjectId = currentEditor.cursor.objectId;
		if absoluteId == currentObjectId then 
			currentObjectId = newAbsoluteId;
		elseif addon.utils.isInnerId(absoluteId, currentObjectId) then
			currentObjectId = newAbsoluteId .. currentObjectId:sub(absoluteId:len() + 1);
		end
		rebuildTreeAndShow(currentObjectId);
		return true;
	else
		return false, loc.IN_INNER_NO_AVAILABLE;
	end
end

-- 
function addon.updateCurrentObjectDraft()
	if not currentObject then
		return
	end
	
	if currentObject.class.TY and editorsByType[currentObject.class.TY] then
		editorsByType[currentObject.class.TY]:InterfaceToClass(currentObject.class);
		currentObject.node.data.icon, currentObject.node.data.link = addon.utils.getObjectIconAndLink(currentObject.class);
		addon.refreshObjectTree();
		updateTabBar();
	end
	
	noteFrame:InterfaceToClass(currentObject.class);
	addon.editor.script:InterfaceToClass(currentObject.class);
end

function addon.saveEditor()
	-- TODO save window positions, inner items scroll positions etc.
end

function addon.resetEditor()
	addon.updateCurrentObjectDraft();
	currentEditor = nil;
	currentDraft = nil;
	currentObject = nil;
end

function addon.displayObject(objectId)
	if not currentEditor then
		return
	end
	
	if currentObject then
		currentObject.node.data.active = false;
	end
	
	currentEditor.cursor.objectId = objectId;
	currentObject = currentDraft.index[currentEditor.cursor.objectId];
	
	currentObject.node.data.active = true;
	
	updateTabBar();
	
	for _, typeEditor in pairs(editorsByType) do
		if typeEditor then
			typeEditor:Hide();
		end
	end
	if currentObject.class.TY and editorsByType[currentObject.class.TY] then
		editorsByType[currentObject.class.TY]:Show();
		editorsByType[currentObject.class.TY]:ClassToInterface(currentObject.class, currentDraft.class);
	end
	
	noteFrame:ClassToInterface(currentObject.class);
	addon.editor.script:ClassToInterface(currentObject.class, currentDraft.class);
end

function addon.editor.getCurrentPropertiesEditor()
	if currentObject then
		return editorsByType[currentObject.class.TY];
	end
end

function addon.editor.getCurrentObjectRelativeId()
	if currentObject then
		return currentObject.node.data.relativeId;
	end
end

function addon.hidePopups()
	TRP3_API.popup.hidePopups();
	for _, popup in pairs(modalPopups) do
		popup:Close();
	end
end

function addon.createDraft(creationId)
	local draftClass = {};
	local draftRegister = {};
	TRP3_API.utils.table.copy(draftClass, TRP3_API.extended.getClass(creationId));
	TRP3_API.extended.registerDB({[creationId] = draftClass}, 0, draftRegister); -- TODO legacy
	local model, index = buildObjectTree(creationId, draftClass);
	local draft = {
		class       = draftClass,
		register    = draftRegister,
		model       = model,
		index       = index
	};
	return draft;
end

local function displayRootInfo()
	assert(currentDraft.class.MD, "No metadata MD in root class.");
	statusBar.id:SetText(currentEditor.creationId);
	statusBar.version:SetText(currentDraft.class.MD.V or 0);
	
	local color = "|cffffff00";
	statusBar.creationTime:SetText("|cffff9900" .. loc.ROOT_CREATED:format(color .. (currentDraft.class.MD.CB or "?") .. "|r|cffff9900", "|r" .. color .. (currentDraft.class.MD.CD or "?") .. "|r"));
	statusBar.changeTime:SetText("|cffff9900" .. loc.ROOT_SAVED:format(color .. (currentDraft.class.MD.SB or "?") .. "|r|cffff9900", "|r" .. color .. (currentDraft.class.MD.SD or "?") .. "|r"));

	statusBar.language:SetSelectedValue(TRP3_API.extended.tools.getObjectLocale(currentDraft.class));
	
	statusBar.save:SetEnabled(TRP3_Tools_DB[currentEditor.creationId] ~= nil);
end

function addon.showEditor(editor)
	currentEditor = editor;
	currentDraft  = addon.getDraft(currentEditor.creationId);
	
	displayRootInfo();
	
	for absoluteId, object in pairs(currentDraft.index) do
		object.node.data.selected = false;
		object.node.data.active = absoluteId == currentEditor.cursor.objectId;
	end
	
	objectTree.model = currentDraft.model;
	objectTree.widget:SetDataProvider(currentDraft.model);
	
	addon.displayObject(currentEditor.cursor.objectId);
end

function addon.refreshObjectTree()
	objectTree:Refresh();
end

-- local function checkCreation(classID, data)
	-- local warnings = {};
	-- TRP3_API.extended.iterateObject(classID, data, function(childClassID, childClass)
		-- local frame = toolFrame[PAGE_BY_TYPE[childClass.TY].frame or ""];
		-- if frame and frame.validator then
			-- frame.validator(childClassID, childClass, warnings);
		-- end
	-- end);
	-- return warnings;
-- end

local function onSave()
	addon.updateCurrentObjectDraft();
	
	if not TRP3_Tools_DB[currentEditor.creationId] then
		return
	end
	
	-- local warnings = checkCreation(toolFrame.rootClassID, toolFrame.rootDraft);
	-- if #warnings > 0 then
		-- local joinedString = strjoin("\n\n", unpack(warnings));
		-- TRP3_API.popup.showConfirmPopup(loc.EDITOR_WARNINGS:format(#warnings, joinedString), function()
			-- doSave();
		-- end);
	-- else
		-- doSave();
	-- end
	-- TODO make the checkCreation do something
	addon.saveDraft(currentEditor.creationId);
	displayRootInfo();
end

function TRP3_API.extended.tools.initEditor(toolFrame)
	statusBar  = TRP3_ToolFrameEditor.statusBar;
	objectTree = TRP3_ToolFrameEditor.split.tree; -- = TRP3_ToolFrameEditorTree
	noteFrame  = TRP3_ToolFrameEditor.noteFrame;

	addon.editor.trigger = TRP3_ToolFrameEditor.triggerFrame;
	addon.editor.effect  = TRP3_ToolFrameEditor.effectFrame;
	addon.editor.script  = TRP3_ToolFrameEditor.split.split.script;

	-- statusBar.id:SetText(loc.EDITOR_ID_COPY);
	-- statusBar.id:SetScript("OnClick", function()
		-- TRP3_API.popup.showTextInputPopup(loc.EDITOR_ID_COPY_POPUP, nil, nil, currentEditor.creationId);
	-- end); -- TODO copy id feature
	
	editorsByType[TRP3_DB.types.CAMPAIGN]   = TRP3_ToolFrameEditor.split.split.properties.campaign;
	editorsByType[TRP3_DB.types.QUEST]      = TRP3_ToolFrameEditor.split.split.properties.quest;
	editorsByType[TRP3_DB.types.QUEST_STEP] = TRP3_ToolFrameEditor.split.split.properties.questStep;
	editorsByType[TRP3_DB.types.ITEM]       = TRP3_ToolFrameEditor.split.split.properties.item;
	editorsByType[TRP3_DB.types.DOCUMENT]   = TRP3_ToolFrameEditor.split.split.properties.document;
	editorsByType[TRP3_DB.types.DIALOG]     = TRP3_ToolFrameEditor.split.split.properties.cutscene;
	editorsByType[TRP3_DB.types.AURA]       = TRP3_ToolFrameEditor.split.split.properties.aura;
	
	for _, editor in pairs(editorsByType) do
		if editor then
			editor:Initialize();
		end
	end
	
	addon.editor.script:Initialize();
	addon.editor.trigger:Initialize();
	addon.editor.effect:Initialize();
	
	local template = "|T%s:11:16|t";
	local types = {
		{template:format(TRP3_API.extended.tools.getObjectLocaleImage("en")), "en"},
		{template:format(TRP3_API.extended.tools.getObjectLocaleImage("fr")), "fr"},
		{template:format(TRP3_API.extended.tools.getObjectLocaleImage("es")), "es"},
		{template:format(TRP3_API.extended.tools.getObjectLocaleImage("de")), "de"},
	}
	TRP3_API.ui.listbox.setupListBox(statusBar.language, types, function(value)
		if currentDraft.class.MD then
			currentDraft.class.MD.LO = value;
		end
	end);
	
	statusBar.save:SetScript("OnClick", onSave);
	
	noteFrame:AssociateWith(TRP3_ToolFrameEditor.split.split.properties.noteButton);
	
	table.insert(modalPopups, noteFrame);
	
end
