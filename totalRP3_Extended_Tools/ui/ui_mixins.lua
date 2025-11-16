local _, addon = ...

TRP3_Tools_ListMixin = {};

function TRP3_Tools_ListMixin:Initialize()
	local model = CreateDataProvider();
	local view = CreateScrollBoxListLinearView();
	ScrollUtil.InitScrollBoxListWithScrollBar(self.widget, self.scrollBar, view);
	local anchorsWithScrollBar = {
		CreateAnchor("TOPLEFT", 0, 0);
		CreateAnchor("BOTTOMRIGHT", self.scrollBar, -16, 0),
	};
	local anchorsWithoutScrollBar = {
		CreateAnchor("TOPLEFT", 0, 0),
		CreateAnchor("BOTTOMRIGHT", 0, 0);
	};
	ScrollUtil.AddManagedScrollBarVisibilityBehavior(self.widget, self.scrollBar, anchorsWithScrollBar, anchorsWithoutScrollBar);
	self.model = model;
	view:SetElementInitializer(self.listElementTemplate, self.listElementMixin.Initialize);
	view:SetElementResetter(self.listElementMixin.Reset);
	view:SetElementExtentCalculator(self.listElementMixin.GetElementExtent);
	view:SetDataProvider(model);
	if self.PostInitialize then
		self:PostInitialize();
	end
end

function TRP3_Tools_ListMixin:Refresh()
	for _, frame in pairs(self.widget:GetFrames()) do
		if frame.Refresh then
			frame:Refresh();
		end
	end
end

TRP3_Tools_TreeMixin = {};
function TRP3_Tools_TreeMixin:Initialize()
	local model = CreateTreeDataProvider();
	local view = CreateScrollBoxListTreeListView(self.indent);
	ScrollUtil.InitScrollBoxListWithScrollBar(self.widget, self.scrollBar, view);
	local anchorsWithScrollBar = {
		CreateAnchor("TOPLEFT", 0, 0);
		CreateAnchor("BOTTOMRIGHT", self.scrollBar, -16, 0),
	};
	local anchorsWithoutScrollBar = {
		CreateAnchor("TOPLEFT", 0, 0),
		CreateAnchor("BOTTOMRIGHT", 0, 0);
	};
	ScrollUtil.AddManagedScrollBarVisibilityBehavior(self.widget, self.scrollBar, anchorsWithScrollBar, anchorsWithoutScrollBar);
	self.model = model;
	view:SetElementInitializer(self.treeNodeTemplate, self.treeNodeMixin.Initialize);
	view:SetElementResetter(self.treeNodeMixin.Reset);
	view:SetElementExtentCalculator(self.treeNodeMixin.GetElementExtent);
	view:SetDataProvider(model);
end

function TRP3_Tools_TreeMixin:Refresh()
	for _, frame in pairs(self.widget:GetFrames()) do
		if frame.Refresh then
			frame:Refresh();
		end
	end
end

TRP3_Tools_ListElementMixin = {};
function TRP3_Tools_ListElementMixin:SetSelected(selected)
	self.backgroundNormal:SetShown(not selected);
	self.backgroundSelected:SetShown(selected);
end

function TRP3_Tools_ListElementMixin:SetHighlight(highlight)
	self.borderLeft:SetShown(highlight);
	self.borderMid:SetShown(highlight);
	self.borderRight:SetShown(highlight);
end

TRP3_Tools_TabBarMixin = {};

function TRP3_Tools_TabBarMixin:Initialize()
	self.tabPool = CreateFramePool("Button", self.scrollFrame.scrollChild, "TRP3_Tools_TabButtonTemplate");
	self.tabs = {};
	self.scrollFrame.scrollChild:SetHeight(self:GetHeight());
	self.scrollFrame.scrollChild.offset = 0;
	self:Refresh();
end

-- tabData 
--     .label         - tab label
--     .closeable     - whether or not the tab should have a close button
--     .tooltipHeader - 
--     .tooltipBody   -
function TRP3_Tools_TabBarMixin:AddTabAndActivate(tabData)
	local tabButton = self.tabPool:Acquire();
	tabButton.data = tabData;
	tabButton.tabBar = self;
	tabButton.isActive = false;
	tabButton.activationOrder = #self.tabs + 1;
	tabButton:Show();
	table.insert(self.tabs, tabButton);
	self:Activate(tabButton);
end

function TRP3_Tools_TabBarMixin:Refresh(ensureActiveTabVisibility)
	local totalWidthRequired = 0;
	local activeTabOffsetLeft;
	local activeTabOffsetRight;
	for index, tabButton in ipairs(self.tabs) do
		tabButton.Text:SetText(tabButton.data.label);
		local textRightOffset = 10;
		if tabButton.data.closeable then
			textRightOffset = textRightOffset + tabButton.closeButton:GetWidth();
		end
		
		local tabWidth = math.min(math.max(self.minTabWidth, tabButton.Text:GetStringWidth() + 10 + textRightOffset), self.maxTabWidth);
		tabButton:SetSize(tabWidth, self:GetHeight());
		tabButton:SetPoint("BOTTOMLEFT", totalWidthRequired, 0);
		totalWidthRequired = totalWidthRequired + tabWidth;
		local textOffsetY = -10;
		if tabButton.isActive then
			textOffsetY = -6;
		end
		tabButton.closeButton:SetShown(tabButton.data.closeable);
		tabButton.Text:SetPoint("LEFT", 10, textOffsetY);
		tabButton.Text:SetPoint("RIGHT", -textRightOffset, textOffsetY);
		if tabButton.isActive then
			tabButton.LeftActive:Show();
			tabButton.MiddleActive:Show();
			tabButton.RightActive:Show();
			tabButton.Left:Hide();
			tabButton.Middle:Hide();
			tabButton.Right:Hide();
			tabButton.LeftHighlight:SetPoint("TOPRIGHT", tabButton.LeftActive);
			tabButton.MiddleHighlight:SetPoint("TOPLEFT", tabButton.MiddleActive);
			tabButton.MiddleHighlight:SetPoint("TOPRIGHT", tabButton.MiddleActive);
			tabButton.RightHighlight:SetPoint("TOPLEFT", tabButton.RightActive);
			tabButton.closeButton:SetPoint("RIGHT", -6 , -4);
			activeTabOffsetLeft = totalWidthRequired - tabWidth;
			activeTabOffsetRight = totalWidthRequired;
		else
			tabButton.LeftActive:Hide();
			tabButton.MiddleActive:Hide();
			tabButton.RightActive:Hide();
			tabButton.Left:Show();
			tabButton.Middle:Show();
			tabButton.Right:Show();
			tabButton.LeftHighlight:SetPoint("TOPRIGHT", tabButton.Left);
			tabButton.MiddleHighlight:SetPoint("TOPLEFT", tabButton.Middle);
			tabButton.MiddleHighlight:SetPoint("TOPRIGHT", tabButton.Middle);
			tabButton.RightHighlight:SetPoint("TOPLEFT", tabButton.Right);
			tabButton.closeButton:SetPoint("RIGHT", -6 , -8);
		end
	end
	
	self.scrollFrame.scrollChild:SetWidth(totalWidthRequired);
	if totalWidthRequired > self.scrollFrame:GetWidth() then
		self.scrollFrame.scrollChild.offset = math.min(self.scrollFrame.scrollChild:GetWidth() - self.scrollFrame:GetWidth(), self.scrollFrame.scrollChild.offset);
		self.scrollFrame:SetPoint("TOPLEFT", 32, 0);
		self.scrollFrame:SetPoint("BOTTOMRIGHT", -32, 0);
		self.scrollLeftButton:Show();
		self.scrollRightButton:Show();
		if ensureActiveTabVisibility then
			local visibleLeft = self.scrollFrame.scrollChild.offset;
			local visibleRight = self.scrollFrame.scrollChild.offset + self.scrollFrame:GetWidth();
			local leftClip = math.max(0, visibleLeft - activeTabOffsetLeft);
			local rightClip = math.max(0, activeTabOffsetRight - visibleRight);
			self.scrollFrame.scrollChild.offset = self.scrollFrame.scrollChild.offset + rightClip - leftClip;
			self.scrollFrame.scrollChild:SetPoint("TOPLEFT", -self.scrollFrame.scrollChild.offset, 0);
		end
		self:UpdateScrollButtons();
	else
		self.scrollFrame.scrollChild.offset = 0;
		self.scrollFrame.scrollChild:SetPoint("TOPLEFT", 0, 0);
		self.scrollFrame:SetPoint("TOPLEFT", 0, 0);
		self.scrollFrame:SetPoint("BOTTOMRIGHT", 0, 0);
		self.scrollLeftButton:Hide();
		self.scrollRightButton:Hide();
	end
end

function TRP3_Tools_TabBarMixin:ScrollLeft()
	self.scrollFrame.scrollChild.offset = math.max(0, self.scrollFrame.scrollChild.offset - self.maxTabWidth);
	self.scrollFrame.scrollChild:SetPoint("TOPLEFT", -self.scrollFrame.scrollChild.offset, 0);
	self:UpdateScrollButtons();
end

function TRP3_Tools_TabBarMixin:ScrollRight()
	self.scrollFrame.scrollChild.offset = math.min(self.scrollFrame.scrollChild:GetWidth() - self.scrollFrame:GetWidth(), self.scrollFrame.scrollChild.offset + self.maxTabWidth);
	self.scrollFrame.scrollChild:SetPoint("TOPLEFT", -self.scrollFrame.scrollChild.offset, 0);
	self:UpdateScrollButtons();
end

function TRP3_Tools_TabBarMixin:UpdateScrollButtons()
	self.scrollLeftButton:SetEnabled(self.scrollFrame.scrollChild.offset - 0.01 > 0);
	self.scrollRightButton:SetEnabled(self.scrollFrame.scrollChild.offset + self.scrollFrame:GetWidth() + 0.01 < self.scrollFrame.scrollChild:GetWidth());
end

-- can be overwritten by a mixin
function TRP3_Tools_TabBarMixin:CloseRequest(tabButton, data)
	self:Close(tabButton);
end

function TRP3_Tools_TabBarMixin:Close(tabButton)
	for index, tab in ipairs(self.tabs) do
		if tab == tabButton then
			table.remove(self.tabs, index);
		end
		if tab.activationOrder > tabButton.activationOrder then
			tab.activationOrder = tab.activationOrder - 1;
		end
	end
	self.tabPool:Release(tabButton);
	if tabButton.isActive then
		local maxOrder = 0;
		local maxTab;
		for _, tab in ipairs(self.tabs) do
			if tab.activationOrder > maxOrder then
				maxOrder = tab.activationOrder;
				maxTab = tab
			end
		end
		if maxTab then
			self:Activate(maxTab);
		else
			self:Refresh();
		end
	else
		self:Refresh();
	end
end

function TRP3_Tools_TabBarMixin:Activate(tabButton)
	if tabButton.isActive then
		return
	end
	for _, tab in ipairs(self.tabs) do
		tab.isActive = false;
		if tab.activationOrder > tabButton.activationOrder then
			tab.activationOrder = tab.activationOrder - 1;
		end
	end
	tabButton.isActive = true;
	tabButton.activationOrder = #self.tabs;
	self:Refresh(true);
	if self.OnActivate then
		self:OnActivate(tabButton, tabButton.data);
	end
end

function TRP3_Tools_TabBarMixin:FindTab(predicate)
	for _, tab in ipairs(self.tabs) do
		if predicate(tab.data) then
			return tab;
		end
	end
	return nil;
end

TRP3_Tools_SplitPaneMixin = {};
TRP3_Tools_SplitPaneMixin.Direction = {
	HORIZONTAL = "HORIZONTAL",
	VERTICAL   = "VERTICAL"
};

function TRP3_Tools_SplitPaneMixin:Localize(transformFunction)
	self.first.collapsedLabel = transformFunction(self.first.collapsedLabel);
	self.second.collapsedLabel = transformFunction(self.second.collapsedLabel);
end

local function gatherConstraints(frame)
	local left, top, right, bottom = 0, 0, 0, 0;
	for i = 1, frame:GetNumPoints() do
		local point, relativeTo, relativePoint, x, y = frame:GetPoint(i);
		if relativeTo == frame:GetParent() and point == relativePoint then
			if point == "TOPLEFT" then
				left   = math.max(left, x);
				top    = math.min(top, y);
			elseif point == "TOP" then
				top    = math.min(top, y);
			elseif point == "TOPRIGHT" then
				top    = math.min(top, y);
				right  = math.min(right, x);
			elseif point == "TOPLEFT" then
				left   = math.max(left, x);
			elseif point == "RIGHT" then
				right  = math.min(right, x);
			elseif point == "BOTTOMLEFT" then
				left   = math.max(left, x);
				bottom = math.max(bottom, y);
			elseif point == "BOTTOM" then
				bottom = math.max(bottom, y);
			elseif point == "BOTTOMRIGHT" then
				bottom = math.max(bottom, y);
				right  = math.min(right, x);
			end
		end
	end
	return left, top, right, bottom;
end

function TRP3_Tools_SplitPaneMixin:Initialize()
	
	self.orientation = self.orientation or TRP3_Tools_SplitPaneMixin.Direction.HORIZONTAL;
	
	self.ratio = self.ratio or 0.5;
	self.prevRatio = self.prevRatio or 0.5;
	
	self.first  = select(1, self:GetChildren());
	self.second = select(2, self:GetChildren());
	
	self.first.minExtent = self.first.minExtent or 0;
	self.first.maxExtent = self.first.maxExtent or math.huge;
	
	self.second.minExtent = self.second.minExtent or 0;
	self.second.maxExtent = self.second.maxExtent or math.huge;
	
	local l1, t1, r1, b1 = gatherConstraints(self.first);
	local l2, t2, r2, b2 = gatherConstraints(self.second);
		
	self.first:ClearAllPoints();
	self.second:ClearAllPoints();
	
	if self.orientation == TRP3_Tools_SplitPaneMixin.Direction.HORIZONTAL then
		self.divider = CreateFrame("Frame", nil, self, "TRP3_Tools_HorizontalDividerTemplate");
		self.divider:SetPoint("TOPLEFT");
		self.divider:SetPoint("BOTTOM");
		
		self.divider.label:SetRotation(math.pi/2);
		
		self.first:SetPoint("TOPLEFT", l1, t1);
		self.first:SetPoint("BOTTOMRIGHT", self.divider, "BOTTOMLEFT", r1, b1);
		
		self.second:SetPoint("TOPLEFT", self.divider, "TOPRIGHT", l2, t2);
		self.second:SetPoint("BOTTOMRIGHT", r2, b2);
	else
		self.divider = CreateFrame("Frame", nil, self, "TRP3_Tools_VerticalDividerTemplate");
		self.divider:SetPoint("TOPLEFT");
		self.divider:SetPoint("RIGHT");
		
		self.first:SetPoint("TOPLEFT", l1, t1);
		self.first:SetPoint("BOTTOMRIGHT", self.divider, "TOPRIGHT", r1, b1);
		
		self.second:SetPoint("TOPLEFT", self.divider, "BOTTOMLEFT", l2, t2);
		self.second:SetPoint("BOTTOMRIGHT", r2, b2);
	end
	
	self:SetRatio();
end

function TRP3_Tools_SplitPaneMixin:SetRatio(newRatio)
	local availableExtent;
	if self.orientation == TRP3_Tools_SplitPaneMixin.Direction.HORIZONTAL then
		availableExtent = self:GetWidth() - self.divider:GetWidth();
	else
		availableExtent = self:GetHeight() - self.divider:GetHeight();
	end
	
	if availableExtent <= 0 then
		return
	end
	
	if availableExtent < self.first.minExtent + self.second.minExtent then
		-- case 1: both frames cannot be visible at the same time
		if (newRatio or self.ratio) < self.first.minExtent / (self.first.minExtent + self.second.minExtent) then
			self.ratio = 0;
			self.prevRatio = 1;
		else
			self.ratio = 1;
			self.prevRatio = 0;
		end
	elseif availableExtent > self.first.maxExtent + self.second.maxExtent then
		-- case 2: both frames together don't occupy enough space
		self.ratio = self.first.maxExtent / availableExtent;
		self.prevRatio = self.ratio;
	else
		if self.ratio > 0 and self.ratio < 1 then
			self.prevRatio = self.ratio;
		end
		local minRatio = math.max(self.first.minExtent / availableExtent, 1 - self.second.maxExtent / availableExtent);
		local maxRatio = math.min(self.first.maxExtent / availableExtent, 1 - self.second.minExtent / availableExtent);
		newRatio = newRatio or self.ratio;
		if newRatio < minRatio then
			if self.ratio <= 0 and newRatio > 0 then
				self.ratio = minRatio;
			elseif self.first.collapsible and newRatio < minRatio / 2 then
				self.ratio = 0;
			else
				self.ratio = minRatio;
			end
		elseif newRatio > maxRatio then
			if self.ratio >= 1 and newRatio < 1 then
				self.ratio = maxRatio;
			elseif self.second.collapsible and newRatio > (1 + maxRatio) / 2 then
				self.ratio = 1
			else
				self.ratio = maxRatio;
			end
		else
			self.ratio = newRatio;
		end
		
	end
	
	if self.ratio <= 0 then
		self.first:Hide();
		self.second:Show();
		self.divider.collapseFirst:Hide();
		self.divider.collapseSecond:Show();
		self.divider.label:SetText("Expand: " .. self.first.collapsedLabel);
	elseif self.ratio >= 1 then
		self.first:Show();
		self.second:Hide();
		self.divider.collapseFirst:Show();
		self.divider.collapseSecond:Hide();
		self.divider.label:SetText("Expand: " .. self.second.collapsedLabel);
	else
		self.first:Show();
		self.second:Show();
		self.divider.collapseFirst:SetShown(self.first.collapsible);
		self.divider.collapseSecond:SetShown(self.second.collapsible);
		self.divider.label:SetText();
	end
	
	if self.divider.collapseFirst:IsShown() then
		if self.orientation == TRP3_Tools_SplitPaneMixin.Direction.HORIZONTAL then
			self.divider.collapseSecond:SetPoint("TOP", self.divider.collapseFirst, "BOTTOM", 0, -4);
		else
			self.divider.collapseSecond:SetPoint("LEFT", self.divider.collapseFirst, "RIGHT", 4, 0);
		end
	else
		if self.orientation == TRP3_Tools_SplitPaneMixin.Direction.HORIZONTAL then
			self.divider.collapseSecond:SetPoint("TOP", 0, -4);
		else
			self.divider.collapseSecond:SetPoint("LEFT", 4, 0);
		end
	end
	
	if self.orientation == TRP3_Tools_SplitPaneMixin.Direction.HORIZONTAL then
		self.divider:SetPoint("TOPLEFT", availableExtent * self.ratio, 0);
	else
		self.divider:SetPoint("TOPLEFT", 0, -availableExtent * self.ratio, 0);
	end
end

function TRP3_Tools_SplitPaneMixin:GetRatio()
	return self.ratio;
end

function TRP3_Tools_SplitPaneMixin:OnSizeChanged()
	self:SetRatio();
end

TRP3_Tools_DividerMixin = {};

function TRP3_Tools_DividerMixin:OnMouseDown()
	
	self.cx, self.cy = GetCursorPosition();
	
	if self:GetParent().resizeable == false then
		return
	end
	
	local wCurr, wMin, wMax, hCurr, hMin, hMax;
	if self:GetParent().orientation == TRP3_Tools_SplitPaneMixin.Direction.HORIZONTAL then
		wCurr = self:GetWidth() + select(4, self:GetPointByName("TOPLEFT"));
		wMin  = (self:GetParent().first.collapsible and 0 or self:GetParent().first.minExtent) + self:GetWidth();
		if self:GetParent().second.collapsible then
			wMax = self:GetParent():GetWidth();
		else
			wMax = math.min(self:GetParent():GetWidth(), self:GetParent().first.maxExtent + self:GetWidth(), self:GetParent():GetWidth() - self:GetParent().second.minExtent);
		end
		hCurr = self:GetParent():GetHeight();
		hMin  = hCurr;
		hMax  = hCurr;
	else
		wCurr = self:GetParent():GetWidth();
		wMin  = wCurr;
		wMax  = wCurr;
		hCurr = self:GetHeight() - select(5, self:GetPointByName("TOPLEFT"));
		hMin  = (self:GetParent().first.collapsible and 0 or self:GetParent().first.minExtent) + self:GetHeight();
		if self:GetParent().second.collapsible then
			hMax = self:GetParent():GetHeight();
		else
			hMax = math.min(self:GetParent():GetHeight(), self:GetParent().first.maxExtent + self:GetHeight(), self:GetParent():GetHeight() - self:GetParent().second.minExtent);
		end
	end
	
	if hMin >= hMax and wMin >= wMax then
		return
	end
	
	self.shadowFrame:ClearAllPoints();
	self.shadowFrame:SetPoint("TOPLEFT", self:GetParent(), "TOPLEFT");
	self.shadowFrame:SetSize(wCurr, hCurr);
	self.shadowFrame:SetResizeBounds(wMin, hMin, wMax, hMax);
	self.shadowFrame:Show();
	self.shadowFrame:StartSizing();
end

function TRP3_Tools_DividerMixin:OnMouseUp()
	self.shadowFrame:StopMovingOrSizing();
	self.shadowFrame:Hide();
	
	local cx, cy = GetCursorPosition();
	local isCollapseUnique = not self.collapseFirst:IsShown() or not self.collapseSecond:IsShown();
	if (self.cx - cx) * (self.cx - cx) + (self.cy - cy) * (self.cy - cy) <= 1 and (self:GetParent().ratio <= 0 or self:GetParent().ratio >= 1 or isCollapseUnique) then
		if self:GetParent().ratio <= 0 then
			self:CollapseSecond();
		elseif self:GetParent().ratio >= 1 then
			self:CollapseFirst();
		elseif self.collapseFirst:IsShown() then
			self:CollapseFirst();
		elseif self.collapseSecond:IsShown() then
			self:CollapseSecond();
		end
	elseif self:GetParent().resizeable ~= false then
		if self:GetParent().orientation == TRP3_Tools_SplitPaneMixin.Direction.HORIZONTAL then
			self:GetParent():SetRatio((self.shadowFrame:GetWidth() - self:GetWidth()) / (self:GetParent():GetWidth() - self:GetWidth()));
		else
			self:GetParent():SetRatio((self.shadowFrame:GetHeight() - self:GetHeight()) / (self:GetParent():GetHeight() - self:GetHeight()));
		end
	end
end

function TRP3_Tools_DividerMixin:CollapseFirst()
	if self:GetParent().ratio >= 1 then
		self:GetParent():SetRatio(self:GetParent().prevRatio);
	elseif self:GetParent().ratio > 0 then
		self:GetParent():SetRatio(0);
	end
end

function TRP3_Tools_DividerMixin:CollapseSecond()
	if self:GetParent().ratio <= 0 then
		self:GetParent():SetRatio(self:GetParent().prevRatio);
	elseif self:GetParent().ratio < 1 then
		self:GetParent():SetRatio(1);
	end
end

function TRP3_Tools_DividerMixin:OnHide()
	self.shadowFrame:StopMovingOrSizing();
	self.shadowFrame:Hide();
end

TRP3_Tools_QuestButtonMixin = {};

function TRP3_Tools_QuestButtonMixin:Initialize()
	if self.icon then
		TRP3_API.ui.frame.setupIconButton(self, self.icon);
	end
end

function TRP3_Tools_QuestButtonMixin:Localize(transform)
	self.Name:SetText(transform(self.name));
	self.InfoText:SetText(transform(self.infoText));
	self.name = nil;
	self.infoText = nil;
end

TRP3_Tools_TitledEditBoxMixin = {};
function TRP3_Tools_TitledEditBoxMixin:Localize(transform)
	self.titleText = transform(self.titleText);
	self.title:SetText(self.titleText);
end

TRP3_Tools_TitledHelpEditBoxMixin = {};

function TRP3_Tools_TitledHelpEditBoxMixin:Localize(transform)
	self.titleText = transform(self.titleText);
	self.helpText  = transform(self.helpText);
	self.title:SetText(self.titleText);
	TRP3_API.ui.tooltip.setTooltipForSameFrame(self.help, "RIGHT", 0, 5, self.titleText, self.helpText);
end

TRP3_Tools_TitledSuggestiveHelpEditBoxMixin = {};

function TRP3_Tools_TitledSuggestiveHelpEditBoxMixin:Localize(transform)
	self.titleText = transform(self.titleText);
	self.helpText  = transform(self.helpText);
	self.title:SetText(self.titleText);
	TRP3_API.ui.tooltip.setTooltipForSameFrame(self.help, "RIGHT", 0, 5, self.titleText, self.helpText);
end

function TRP3_Tools_TitledSuggestiveHelpEditBoxMixin:SetupSuggestions(title, dataProvider, replaceAllText)
	self.suggestionTitle = title or "";
	self.suggestionDataProvider = dataProvider;
	self.suggestionReplaceAllText = replaceAllText;
	if dataProvider then
		self.suggestion:Show();
		self.help:SetPoint("RIGHT", self.suggestion, "LEFT", -2, 0);
		self:SetTextInsets(8, 43, 1, 0);
	else
		self.suggestion:Hide();
		self.help:SetPoint("RIGHT", self, "RIGHT", -2, 0);
		self:SetTextInsets(8, 16, 1, 0);
	end
end

function TRP3_Tools_TitledSuggestiveHelpEditBoxMixin:AcceptSuggestion(value)
	if self.suggestionReplaceAllText then
		self:SetText(value);
	else
		self:Insert(value);
	end
end

function TRP3_Tools_TitledSuggestiveHelpEditBoxMixin:OpenSuggestions()
	if self.suggestionDataProvider then
		local onAccept = function(value) 
			self:AcceptSuggestion(value);
		end;
		TRP3_MenuUtil.CreateContextMenu(self.suggestion, function(_, menu)
			if self.suggestionReplaceAllText then
				menu:CreateTitle("Set: " .. self.suggestionTitle);
			else
				menu:CreateTitle("Insert: " .. self.suggestionTitle);
			end
			self.suggestionDataProvider(menu, onAccept);
		end);
	end
end

TRP3_Tools_CheckBoxMixin = {};

function TRP3_Tools_CheckBoxMixin:Localize(transform)
	self.titleText = transform(self.titleText);
	self.helpText  = transform(self.helpText);
	self:SetText(self.titleText);
	TRP3_API.ui.tooltip.setTooltipForSameFrame(self, "RIGHT", 0, 5, self.titleText, self.helpText);
end

TRP3_Tools_TitledDropdownButtonMixin = {};

function TRP3_Tools_TitledDropdownButtonMixin:Localize(transform)
	self.titleText = transform(self.titleText);
	self.helpText  = transform(self.helpText);
	self.title:SetText(self.titleText);
end

TRP3_Tools_TitledPanelMixin = {};

function TRP3_Tools_TitledPanelMixin:Localize(transform)
	self.titleText = transform(self.titleText);
	self.title:SetText(self.titleText);
end

TRP3_Tools_TitledTextAreaMixin = {};

function TRP3_Tools_TitledTextAreaMixin:Localize(transform)
	self.titleText = transform(self.titleText);
	self.title:SetText(self.titleText);
end

function TRP3_Tools_TitledTextAreaMixin:SetText(text)
	self.scroll.text:SetText(text);
end

function TRP3_Tools_TitledTextAreaMixin:GetText()
	return self.scroll.text:GetText();
end

function TRP3_Tools_TitledTextAreaMixin:Insert(...)
	self.scroll.text:Insert(...);
end

function TRP3_Tools_TitledTextAreaMixin:SetFocus(...)
	self.scroll.text:SetFocus(...);
end

TRP3_Tools_TitledHelpTextAreaMixin = CreateFromMixins(TRP3_Tools_TitledTextAreaMixin);

function TRP3_Tools_TitledHelpTextAreaMixin:Localize(transform)
	self.titleText = transform(self.titleText);
	self.helpText  = transform(self.helpText);
	self.title:SetText(self.titleText);
	TRP3_API.ui.tooltip.setTooltipAll(self.dummy, "RIGHT", 0, 5, self.titleText, self.helpText);
end

TRP3_Tools_TitledSuggestiveHelpTextAreaMixin = CreateFromMixins(TRP3_Tools_TitledHelpTextAreaMixin);

function TRP3_Tools_TitledSuggestiveHelpTextAreaMixin:SetupSuggestions(title, dataProvider, replaceAllText)
	self.suggestionTitle = title or "";
	self.suggestionDataProvider = dataProvider;
	self.suggestionReplaceAllText = replaceAllText;
	self:Update();
end

function TRP3_Tools_TitledSuggestiveHelpTextAreaMixin:AcceptSuggestion(value)
	if self.suggestionReplaceAllText then
		self:SetText(value);
	else
		self:Insert(value);
	end
end

function TRP3_Tools_TitledSuggestiveHelpTextAreaMixin:OpenSuggestions()
	if self.suggestionDataProvider then
		local onAccept = function(value) 
			self:AcceptSuggestion(value);
		end;
		TRP3_MenuUtil.CreateContextMenu(self.suggestion, function(_, menu)
			if self.suggestionReplaceAllText then
				menu:CreateTitle("Set: " .. self.suggestionTitle);
			else
				menu:CreateTitle("Insert: " .. self.suggestionTitle);
			end
			self.suggestionDataProvider(menu, onAccept);
		end);
	end
end

function TRP3_Tools_TitledSuggestiveHelpTextAreaMixin:Update()
	local availableScrollBarHeight = self:GetHeight() + self.scroll.scrollBarTopY - self.scroll.scrollBarBottomY;
	local top = self.scroll.scrollBarTopY;
	local bottom = self.scroll.scrollBarBottomY;
	if self.suggestionDataProvider then
		self.suggestion:Show();
		availableScrollBarHeight = availableScrollBarHeight - 27;
		top = self.scroll.scrollBarTopY - 19;
	else
		self.suggestion:Hide();
	end
	if self.expandable then
		self.expand:Show();
		availableScrollBarHeight = availableScrollBarHeight - 27;
		bottom = self.scroll.scrollBarBottomY + 19;
	else
		self.expand:Hide();
	end
	if availableScrollBarHeight >= 75 or not (self.suggestionDataProvider ~= nil or self.expandable) then
		self.suggestion:SetPoint("TOPRIGHT", -2, 0);
		self.expand:SetPoint("BOTTOMRIGHT", -2, 0);
		self.scroll.text:SetWidth(self:GetWidth() - 30);
	else
		top = self.scroll.scrollBarTopY;
		bottom = self.scroll.scrollBarBottomY;
		self.suggestion:SetPoint("TOPRIGHT", self.scroll.scrollBarX - 10, 0);
		self.expand:SetPoint("BOTTOMRIGHT", self.scroll.scrollBarX - 10, 0);
		self.scroll.text:SetWidth(self:GetWidth() - 50);
	end
	self.scroll.ScrollBar:SetPoint("TOPLEFT", self.scroll, "TOPRIGHT", self.scroll.scrollBarX, top);
	self.scroll.ScrollBar:SetPoint("BOTTOMLEFT", self.scroll, "BOTTOMRIGHT", self.scroll.scrollBarX, bottom);
end

function TRP3_Tools_TitledSuggestiveHelpTextAreaMixin:Expand()
	local textControls = {};
	if self.suggestionDataProvider then
		table.insert(textControls, {
			title = self.suggestionTitle,
			callback = function(button, widget) 
				local onAccept = function(value) 
					if self.suggestionReplaceAllText then
						widget:SetText(value);
					else
						widget:Insert(value);
					end
				end;
				TRP3_MenuUtil.CreateContextMenu(self.suggestion, function(_, menu)
					if self.suggestionReplaceAllText then
						menu:CreateTitle("Set: " .. self.suggestionTitle);
					else
						menu:CreateTitle("Insert: " .. self.suggestionTitle);
					end
					self.suggestionDataProvider(menu, onAccept);
				end);
			end
		});
	end
	for _, textControl in ipairs(self.customTextControls or TRP3_API.globals.empty) do
		table.insert(textControls, textControl);
	end
	addon.modal:ShowModal(TRP3_API.popup.TEXT_EDITOR, {self, textControls});
end

function TRP3_Tools_TitledSuggestiveHelpTextAreaMixin:AddTextControl(title, callback)
	self.customTextControls = self.customTextControls or {};
	table.insert(self.customTextControls, {
		title = title,
		callback = callback
	});
end

TRP3_Tools_TitledPopupMixin = {};

function TRP3_Tools_TitledPopupMixin:Localize(transform)
	self.titleText = transform(self.titleText);
	self:SetTitle(self.titleText);
end

function TRP3_Tools_TitledPopupMixin:SetTitle(title)
	self.title:SetText(title);
end

function TRP3_Tools_TitledPopupMixin:Close()
	self:Hide();
end

function TRP3_Tools_TitledPopupMixin:Open()
	self:Raise();
	self:Show();
end

TRP3_Tools_BrowseButtonMixin = {};

function TRP3_Tools_BrowseButtonMixin:Initialize()
	TRP3_API.ui.tooltip.setTooltipForSameFrame(self, "BOTTOMRIGHT", 0, 0, BROWSE);
end

TRP3_Tools_TargetButtonMixin = {};

function TRP3_Tools_TargetButtonMixin:Localize(transform)
	self.titleText = transform(self.titleText);
	self.helpText  = transform(self.helpText);
	TRP3_API.ui.tooltip.setTooltipForSameFrame(self, "BOTTOMRIGHT", 0, 0, self.titleText, self.helpText);
end

function TRP3_Tools_TargetButtonMixin:Initialize()
	TRP3_API.ui.tooltip.setTooltipForSameFrame(self, "BOTTOMRIGHT", 0, 0, self.titleText, self.helpText);
end
