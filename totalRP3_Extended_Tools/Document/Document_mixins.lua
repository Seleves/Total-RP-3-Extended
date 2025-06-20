local _, addon = ...

local loc = TRP3_API.loc;

local MIN_TOOLBAR_BUTTON_WIDTH = 50;
local MAX_TOOLBAR_BUTTON_WIDTH = 120;

TRP3_Tools_EditorDocumentMixin = CreateFromMixins(TRP3_Tools_EditorObjectMixin);

function TRP3_Tools_EditorDocumentMixin:OnSizeChanged()
	if self:GetHeight() < self.content:GetHeight() then
		self:SetPoint("BOTTOMRIGHT", -16, 0);
	else
		self:SetPoint("BOTTOMRIGHT", 0, 0);
	end
	self.content:SetWidth(self:GetWidth());
	self.content.display.preview.Name:SetWidth(90);
	self.content.display.preview.InfoText:SetWidth(90);

	-- custom adaptive toolbar layout, don't tell meorawr
	local toolbarWidthAvailable = self.content.pages.toolbar:GetWidth() - 10;
	local numButtons = self.content.pages.toolbar:GetNumChildren();
	local maxButtonsPerLine = math.floor(toolbarWidthAvailable / MIN_TOOLBAR_BUTTON_WIDTH);
	local minLinesRequired = math.ceil(numButtons / maxButtonsPerLine);
	local actButtonsPerLine = math.ceil(numButtons / minLinesRequired);
	local actButtonWidth = math.min(MAX_TOOLBAR_BUTTON_WIDTH, toolbarWidthAvailable/actButtonsPerLine);

	local buttons = {self.content.pages.toolbar:GetChildren()};
	for index, button in ipairs(buttons) do
		button:ClearAllPoints();
		button:SetWidth(actButtonWidth);
		button:SetPoint("TOPLEFT", 5 + ((index-1) % actButtonsPerLine) * actButtonWidth, -(7 + math.floor((index-1)/actButtonsPerLine) * button:GetHeight()));
	end
	self.content.pages.toolbar:SetHeight(12 + minLinesRequired*buttons[1]:GetHeight());
end

function TRP3_Tools_EditorDocumentMixin:Initialize()
	self.ScrollBar:SetHideIfUnscrollable(true);
	local s = self;

	local display = self.content.display;
	local pages = self.content.pages;
	
	-- Background
	display.background:SetScript("OnClick", function()
		TRP3_API.popup.showPopup(
			TRP3_API.popup.BACKGROUNDS, 
			{parent = TRP3_ToolFrame, point = "CENTER", parentPoint = "CENTER"}, 
			{function(imageInfo) s.BCK = imageInfo and imageInfo.id or 8; end, nil, nil, s.BCK or 8}
		);
	end);

	-- Border
	TRP3_API.ui.listbox.setupListBox(display.border, {
		{loc.DO_PAGE_BORDER_1, TRP3_API.extended.document.BorderType.PARCHMENT},
	});

	display.h1_font.title:SetText(loc.DO_PAGE_FONT:format("H1"));
	display.h2_font.title:SetText(loc.DO_PAGE_FONT:format("H2"));
	display.h3_font.title:SetText(loc.DO_PAGE_FONT:format("H3"));
	display.p_font.title:SetText(loc.DO_PAGE_FONT:format("P"));

	local getFontStructure = function(h)
		return {
			{"DestinyFontHuge", "DestinyFontHuge"},
			{"QuestFont_Huge", "QuestFont_Huge"},
			{"GameFontNormalLarge", "GameFontNormalLarge"},
			{"GameTooltipHeader", "GameTooltipHeader"},
		};
	end

	TRP3_API.ui.listbox.setupListBox(display.h1_font, getFontStructure("H1"));
	TRP3_API.ui.listbox.setupListBox(display.h2_font, getFontStructure("H2"));
	TRP3_API.ui.listbox.setupListBox(display.h3_font, getFontStructure("H3"));
	TRP3_API.ui.listbox.setupListBox(display.p_font, getFontStructure("P"));
	
	TRP3_API.ui.text.setupToolbar(pages.toolbar, pages.editor.scroll.text, TRP3_ToolFrame, "CENTER", "CENTER");

	display.preview:SetScript("OnClick", function()
		local temp = {};
		s:InterfaceToClass(temp);
		TRP3_API.extended.document.showDocumentClass(temp, nil);
	end);
	
	display.importBook:SetScript("OnClick", function()
		s:ImportItemTextFrame();
	end);
	
	pages.addPage:SetScript("OnClick", function() 
		s:AddPage();
	end);

	pages.editor:SetupSuggestions(addon.editor.populateObjectTagMenu);

	addon.utils.prepareForMultiSelectionMode(self.content.pages.list);

	-- -- Pages
	-- pages = toolFrame.document.normal.pages;
	-- TRP3_API.ui.text.setupToolbar(pages.toolbar, pages.editor.scroll.text, pages, "RIGHT", "LEFT");
	-- pages.remove:SetText(loc.DO_PAGE_REMOVE);
	-- pages.remove:SetScript("OnClick", removePage);

	-- -- Manager
	-- manager = toolFrame.document.normal.summary;
	-- manager.title:SetText(loc.DO_PAGE_MANAGER);
	-- manager.add:SetText(loc.DO_PAGE_ADD);
	-- setTooltipForSameFrame(manager.next, "BOTTOM", 0, -5, loc.DO_PAGE_NEXT);
	-- setTooltipForSameFrame(manager.previous, "BOTTOM", 0, -5, loc.DO_PAGE_PREVIOUS);
	-- setTooltipForSameFrame(manager.first, "BOTTOM", 0, -5, loc.DO_PAGE_FIRST);
	-- setTooltipForSameFrame(manager.last, "BOTTOM", 0, -5, loc.DO_PAGE_LAST);
	-- manager.next:SetText(">");
	-- manager.previous:SetText("<");
	-- manager.first:SetText("<<");
	-- manager.last:SetText(">>");
	-- manager.add:SetScript("OnClick", addPage);
	-- manager.first:SetScript("OnClick", function() loadPage(1); end);
	-- manager.previous:SetScript("OnClick", function() loadPage(manager.current - 1); end);
	-- manager.next:SetScript("OnClick", function() loadPage(manager.current + 1); end);
	-- manager.last:SetScript("OnClick", function() loadPage(#toolFrame.specificDraft.PA); end);


end

function TRP3_Tools_EditorDocumentMixin:ClassToInterface(class, creationClass)
	self.content.display.border:SetSelectedValue(class.BO or TRP3_API.extended.document.BorderType.PARCHMENT);
	self.content.display.height:SetText(class.HE or "600");
	self.content.display.width:SetText(class.WI or "450");
	self.content.display.h1_font:SetSelectedValue(class.H1_F or "DestinyFontHuge");
	self.content.display.h2_font:SetSelectedValue(class.H2_F or "QuestFont_Huge");
	self.content.display.h3_font:SetSelectedValue(class.H3_F or "GameFontNormalLarge");
	self.content.display.p_font:SetSelectedValue(class.P_F or "GameTooltipHeader");
	self.content.display.tile:SetChecked(class.BT or false);
	self.content.display.resizable:SetChecked(class.FR or false);

	self.BCK = class.BCK or 8;
	self:ClassToPages(class);
	self:ShowPage(1); -- TODO get page from cursor
end

function TRP3_Tools_EditorDocumentMixin:InterfaceToClass(targetClass)

	self:SaveCurrentPage();

	targetClass.BO = self.content.display.border:GetSelectedValue() or TRP3_API.extended.document.BorderType.PARCHMENT;
	targetClass.HE = tonumber(self.content.display.height:GetText()) or 600;
	targetClass.WI = tonumber(self.content.display.width:GetText()) or 450;
	targetClass.H1_F = self.content.display.h1_font:GetSelectedValue() or "DestinyFontHuge";
	targetClass.H2_F = self.content.display.h2_font:GetSelectedValue() or "QuestFont_Huge";
	targetClass.H3_F = self.content.display.h3_font:GetSelectedValue() or "GameFontNormalLarge";
	targetClass.P_F = self.content.display.p_font:GetSelectedValue() or "GameTooltipHeader";
	targetClass.BT = self.content.display.tile:GetChecked();
	targetClass.FR = self.content.display.resizable:GetChecked();

	targetClass.BCK = self.BCK or 8;
	self:PagesToClass(targetClass);
end

function TRP3_Tools_EditorDocumentMixin:ClassToPages(class)
	local list = self.content.pages.list;
	local pages = {};
	if class.PA and TableHasAnyEntries(class.PA) then
		for index, page in ipairs(class.PA) do
			table.insert(pages, {
				active = index == 1,
				label = "Page " .. index,
				content = page.TX
			});
		end
	else
		table.insert(pages, {
			active = true,
			label = "Page 1",
			content = ""
		});
	end

	--local scrollPct = list.widget:GetScrollPercentage();
	list.model:Flush();
	list.model:InsertTable(pages);
	--list.widget:SetScrollPercentage(0);
	
end

function TRP3_Tools_EditorDocumentMixin:PagesToClass(targetClass)
	targetClass.PA = targetClass.PA or {};
	wipe(targetClass.PA);
	local list = self.content.pages.list;
	for index, element in list.model:EnumerateEntireRange() do
		table.insert(targetClass.PA, {
			TX = element.content
		});
	end
end

function TRP3_Tools_EditorDocumentMixin:SaveCurrentPage()
	local list = self.content.pages.list;
	local index, element = list.model:FindByPredicate(function(e) return e.active end);
	if element then
		element.content = self.content.pages.editor.scroll.text:GetText();
	end
end

function TRP3_Tools_EditorDocumentMixin:ShowPage(pageIndex)
	local list = self.content.pages.list;
	for index, element in list.model:EnumerateEntireRange() do
		element.active = index == pageIndex;
	end
	list.widget:ScrollToElementDataIndex(pageIndex);
	list:Refresh();
	if list.model:Find(pageIndex) then
		self.content.pages.editor.scroll.text:SetText(list.model:Find(pageIndex).content or "");
	else
		self.content.pages.editor.scroll.text:SetText("");
	end
	self.content.pages.editor.scroll.text:SetFocus();
end

function TRP3_Tools_EditorDocumentMixin:UpdatePageLabels()
	for index, element in self.content.pages.list.model:EnumerateEntireRange() do
		element.label = "Page " .. index;
	end
end

function TRP3_Tools_EditorDocumentMixin:AddPage(targetIndex, content, noUpdate)
	local list = self.content.pages.list;
	targetIndex = targetIndex or list.model:GetSize() + 1;
	list.model:InsertAtIndex({
		content = content or ""
	}, targetIndex);
	if noUpdate then
		return
	end
	self:UpdatePageLabels();
	self:ShowPage(targetIndex);
end

function TRP3_Tools_EditorDocumentMixin:DeletePage(pageData)
	local list = self.content.pages.list;
	local pageIndex = list.model:FindIndex(pageData);
	if pageIndex then
		list.model:RemoveIndex(pageIndex);
		
		if list.model:GetSize() <= 0 then
			list.model:Insert({
				content = ""
			});
		end
		self:UpdatePageLabels();
		if pageData.active then
			self:ShowPage(math.max(pageIndex-1, 1));
		else
			list:Refresh();
		end
	end
end

function TRP3_Tools_EditorDocumentMixin:DeleteSelectedPages()
	local list = self.content.pages.list;
	local pages = {};
	local pageIndex;
	for index, element in list.model:EnumerateEntireRange() do
		if not element.selected then
			table.insert(pages, element);
		elseif element.active then
			pageIndex = #pages;
		end
	end
	if not TableHasAnyEntries(pages) then
		table.insert(pages, {
			content = ""
		});
	end
	list.model:Flush();
	list.model:InsertTable(pages);
	self:UpdatePageLabels();
	pageIndex = math.max(1, pageIndex or list.model:FindByPredicate(function(e) return e.active end) or 1);
	self:ShowPage(pageIndex);
end

function TRP3_Tools_EditorDocumentMixin:ImportItemTextFrame()
	if ItemTextFrame:IsShown() then
		local list = self.content.pages.list;
		if list.model:GetSize() == 1 and list.model:Find(1).content == nil or list.model:Find(1).content == "" then
			list.model:RemoveIndex(1);
		end
		local firstPageInserted = list.model:GetSize() + 1;
		local currPage = ItemTextGetPage();
		for i = 1,currPage-1 do
			ItemTextPrevPage();
		end
		if ItemTextGetItem() ~= nil and ItemTextGetItem() ~= "" then
			list.model:Insert({
				content = "{h1:c}" .. (ItemTextGetItem() or "") .. "{/h1}\n" .. ItemTextGetText()
			});
		else
			list.model:Insert({
				content = ItemTextGetText()
			});
		end
		while ItemTextHasNextPage() do
			ItemTextNextPage();
			list.model:Insert({
				content = ItemTextGetText()
			});
		end
		self:UpdatePageLabels();
		self:SaveCurrentPage();
		self:ShowPage(firstPageInserted);
	else
		TRP3_API.utils.message.displayMessage("Please open the object from which you want to import text.", 4);
	end
end

TRP3_Tools_DocumentPageListElementMixin = {};

function TRP3_Tools_DocumentPageListElementMixin:Initialize(data)
	self.data = data;

	local tooltipText = 
		TRP3_API.FormatShortcutWithInstruction("LCLICK", "edit page") .. "|n" ..
		TRP3_API.FormatShortcutWithInstruction("RCLICK", "more options") .. "|n" ..
		TRP3_API.FormatShortcutWithInstruction("SHIFT-CLICK", "select range") .. "|n" ..
		TRP3_API.FormatShortcutWithInstruction("CTRL-CLICK", "select this page")
	;
	TRP3_API.ui.tooltip.setTooltipForSameFrame(self, "BOTTOMRIGHT", 0, 0, "Document page", tooltipText);
	self:Refresh();
end

function TRP3_Tools_DocumentPageListElementMixin:Refresh()
	self.label:SetText(self.data.label);
	self:SetHighlight(self.data.active);
	self:SetSelected(self.data.selected);
end

function TRP3_Tools_DocumentPageListElementMixin:OnEnter()
	TRP3_RefreshTooltipForFrame(self);
end

function TRP3_Tools_DocumentPageListElementMixin:OnLeave()
	TRP3_MainTooltip:Hide();
end

function TRP3_Tools_DocumentPageListElementMixin:OnClick(button)
	local documentEditor = addon.editor.getCurrentPropertiesEditor();
	local pageIndex = documentEditor.content.pages.list.model:FindIndex(self.data);
	
	if button == "LeftButton" then
		if IsControlKeyDown() then
			documentEditor.content.pages.list:ToggleSingleSelect(self.data);
		elseif IsShiftKeyDown() then
			documentEditor.content.pages.list:ToggleRangeSelect(self.data);
		else
			documentEditor:SaveCurrentPage();
			documentEditor:ShowPage(self:GetElementDataIndex());
		end
	elseif button == "RightButton" then
		TRP3_MenuUtil.CreateContextMenu(self, function(_, contextMenu)
			contextMenu:CreateTitle(self.data.label);
			
			local addBeforeOption = contextMenu:CreateButton("Insert page before", function()
				documentEditor:SaveCurrentPage();
				documentEditor:AddPage(pageIndex);
			end);
			TRP3_MenuUtil.SetElementTooltip(addBeforeOption, "Insert an empty page before this page");

			local addAfterOption = contextMenu:CreateButton("Insert page after", function()
				documentEditor:SaveCurrentPage();
				documentEditor:AddPage(pageIndex + 1);
			end);
			TRP3_MenuUtil.SetElementTooltip(addAfterOption, "Insert an empty page after this page");

			contextMenu:CreateDivider();
			local copyOption = contextMenu:CreateButton("Copy", function()
				addon.clipboard.clear();
				addon.clipboard.append({TX = self.data.content}, addon.clipboard.types.DOCUMENT_PAGE);
			end);
			TRP3_MenuUtil.SetElementTooltip(copyOption, "Copy this page");
			if self.data.selected then
				local copySelectionOption = contextMenu:CreateButton("Copy selected pages", function()
					addon.clipboard.clear();
					for index, element in documentEditor.content.pages.list.model:EnumerateEntireRange() do
						if element.selected then
							addon.clipboard.append({TX = element.content}, addon.clipboard.types.DOCUMENT_PAGE);
						end
					end
					documentEditor.content.pages.list:SetAllSelected(false);
				end);
				TRP3_MenuUtil.SetElementTooltip(copySelectionOption, "Copy all selected pages");
			end

			if addon.clipboard.isPasteCompatible(addon.clipboard.types.DOCUMENT_PAGE) then
				local count = addon.clipboard.count();

				local beforeText, afterText;
				if count == 1 then
					beforeText = "Paste page before";
					afterText = "Paste page after";
				else
					beforeText = "Paste " .. count .. " pages before";
					afterText = "Paste " .. count .. " pages after";
				end

				local pasteBeforeOption = contextMenu:CreateButton(beforeText, function()
					for index = 1, count do
						documentEditor:AddPage(pageIndex + index - 1, addon.clipboard.retrieveShallow(index).TX, true);
					end
					documentEditor:SaveCurrentPage();
					documentEditor:UpdatePageLabels();
					documentEditor:ShowPage(pageIndex + count - 1);
				end);
				TRP3_MenuUtil.SetElementTooltip(pasteBeforeOption, beforeText);

				local pasteBeforeOption = contextMenu:CreateButton(afterText, function()
					for index = 1, count do
						documentEditor:AddPage(pageIndex + index, addon.clipboard.retrieveShallow(index).TX, true);
					end
					documentEditor:SaveCurrentPage();
					documentEditor:UpdatePageLabels();
					documentEditor:ShowPage(pageIndex + count);
				end);
				TRP3_MenuUtil.SetElementTooltip(pasteBeforeOption, afterText);
			end

			contextMenu:CreateDivider();
			local deleteOption = contextMenu:CreateButton(DELETE, function()
				self:OnDelete();
			end);
			TRP3_MenuUtil.SetElementTooltip(deleteOption, "Delete this page");

			if self.data.selected then
				local deleteSelectionOption = contextMenu:CreateButton("Delete selection", function()
					documentEditor:SaveCurrentPage();
					documentEditor:DeleteSelectedPages();
				end);
				TRP3_MenuUtil.SetElementTooltip(deleteSelectionOption, "Delete all selected pages");
			end
			
		end);
	end
end

function TRP3_Tools_DocumentPageListElementMixin:OnDelete()
	addon.editor.getCurrentPropertiesEditor():SaveCurrentPage();
	addon.editor.getCurrentPropertiesEditor():DeletePage(self.data);
end
