local _, addon = ...
local loc = TRP3_API.loc;

TRP3_Tools_ScriptConstraintEditorMixin = {};

function TRP3_Tools_ScriptConstraintEditorMixin:PostInitialize()
	self.sharedLeftTermDropdown = CreateFrame("DropdownButton", nil, nil, "TRP3_Tools_TitledDropdownButtonTemplate");
	self.sharedLeftTermDropdown:Hide();
	self.sharedLeftTermDropdown.title:SetText("First operand");
	self.sharedComparatorDropdown = CreateFrame("DropdownButton", nil, nil, "TRP3_Tools_TitledDropdownButtonTemplate");
	self.sharedComparatorDropdown:Hide();
	self.sharedComparatorDropdown.title:SetText("Comparator");
	self.sharedRightTermDropdown = CreateFrame("DropdownButton", nil, nil, "TRP3_Tools_TitledDropdownButtonTemplate");
	self.sharedRightTermDropdown:Hide();
	self.sharedRightTermDropdown.title:SetText("Second operand");
end

function TRP3_Tools_ScriptConstraintEditorMixin:Update()
	local model = {};

	local orStart, prev;
	local hasAnd = false;
	for index, equation in ipairs(self.constraint) do
		local modelItem = {
			equation           = equation,
			isOpenParenthesis  = false,
			isCloseParenthesis = false,
			active             = index == self.activeIndex,
			index              = index
		};
		if index > 1 then
			if equation.logicalOperation == addon.script.logicalOperation.OR then
				orStart = orStart or prev;
			elseif equation.logicalOperation == addon.script.logicalOperation.AND then
				hasAnd = true;
				if orStart then
					orStart.isOpenParenthesis = true;
					prev.isCloseParenthesis = true;
					orStart = nil;
				end
			end
		end
		prev = modelItem;
		table.insert(model, modelItem);
	end
	if hasAnd and orStart then
		orStart.isOpenParenthesis = true;
		prev.isCloseParenthesis = true;
	end
	table.insert(model, {});
	
	local scrollPct = self.widget:GetScrollPercentage();
	self.sharedLeftTermDropdown:Hide();
	self.sharedComparatorDropdown:Hide();
	self.sharedRightTermDropdown:Hide();
	self.model:Flush();
	self.model:InsertTable(model);
	self.widget:SetScrollPercentage(scrollPct);
end

function TRP3_Tools_ScriptConstraintEditorMixin:LinkWithConstraint(constraint)
	self.activeIndex = nil;
	self.constraint = constraint;
	for _, frame in pairs(self.widget:GetFrames()) do
		frame.invalidated = true;
	end
	self.model:Flush();
	self.widget:SetScrollPercentage(0);
	self:Update();
end

function TRP3_Tools_ScriptConstraintEditorMixin:SetActiveIndex(index)
	self.activeIndex = index;
	self:Update();
end

function TRP3_Tools_ScriptConstraintEditorMixin:AddEquation(equation)
	table.insert(self.constraint, equation or {
		logicalOperation = addon.script.logicalOperation.AND,
		leftTerm         = {id = "unit_name", parameters = {"target"}},
		comparator       = "==",
		rightTerm        = {id = "literal_string", parameters = {"Elsa"}},
	});
	self.activeIndex = #self.constraint;
	self:Update();
end

function TRP3_Tools_ScriptConstraintEditorMixin:DeleteIndex(index)
	if self.activeIndex then
		if self.activeIndex == index then
			self.activeIndex = nil;
		elseif self.activeIndex > index then
			self.activeIndex = self.activeIndex - 1;
		end
	end
	table.remove(self.constraint, index);
	self:Update();
end

TRP3_Tools_ScriptConstraintEditorListElementMixin = {};

function TRP3_Tools_ScriptConstraintEditorListElementMixin:GetList()
	return self:GetParent():GetParent():GetParent();
end

function TRP3_Tools_ScriptConstraintEditorListElementMixin:Initialize(data)
	self.data = data;
	self.leftOperandEditor = self.leftOperandEditor or {};
	self.rightOperandEditor = self.rightOperandEditor or {};
	self:Refresh();
end

function TRP3_Tools_ScriptConstraintEditorListElementMixin:ToggleLogicalOperator()
	if self.data.index then
		if self.data.equation.logicalOperation == addon.script.logicalOperation.OR then
			self.data.equation.logicalOperation = addon.script.logicalOperation.AND;
		elseif self.data.equation.logicalOperation == addon.script.logicalOperation.AND then
			self.data.equation.logicalOperation = addon.script.logicalOperation.OR;
		end
		self:GetList():Update();
	else
		self:GetList():AddEquation();
	end
end

function TRP3_Tools_ScriptConstraintEditorListElementMixin:OnDelete()
	self.invalidated = true;
	self:GetList():DeleteIndex(self.data.index);
end

function TRP3_Tools_ScriptConstraintEditorListElementMixin:Refresh()
	if not self.data.index then 
		self.logicalOperatorButton:SetText("+");
		self.logicalOperatorButton:Show();
		self.open:Hide();
		self.close:Hide();
		self.expression:SetText("Add condition");
		self.delete:Hide();
	else
		self.invalidated = nil;
		self.logicalOperatorButton:SetShown(self.data.index > 1);
		self.open:SetShown(self.data.isOpenParenthesis);
		self.close:SetShown(self.data.isCloseParenthesis);
		if self.data.equation.logicalOperation == addon.script.logicalOperation.OR then
			self.logicalOperatorButton:SetText(loc.OP_OR);
		elseif self.data.equation.logicalOperation == addon.script.logicalOperation.AND then
			self.logicalOperatorButton:SetText(loc.OP_AND);
		end
		self.expression:SetText(addon.script.getOperandPreview(self.data.equation.leftTerm) .. " " .. addon.script.getComparatorText(self.data.equation.comparator) .. " " .. addon.script.getOperandPreview(self.data.equation.rightTerm));
		self.delete:Show();
	end
	if self.data.active then

		local s = self;

		local left = self:GetList().sharedLeftTermDropdown;
		local comp = self:GetList().sharedComparatorDropdown;
		local right = self:GetList().sharedRightTermDropdown;

		left:SetParent(self);
		left:ClearAllPoints();
		left:SetPoint("TOPLEFT", 70, -35);
		left:SetPoint("RIGHT", self, "CENTER", -55, 0);
		TRP3_API.ui.listbox.setupListBox(left, addon.script.getOperandMenu(), function(operandId)
			if operandId ~= s.data.equation.leftTerm.id then
				s.data.equation.leftTerm.id = operandId;
				addon.script.operand.getDefaultOperandEditorValues(s.data.equation.leftTerm);
				addon.script.operand.getOperandEditorValues(s.data.equation.rightTerm, s.rightOperandEditor);
				s.invalidated = true;
				s:GetList():Update();
			end
		end);
		left:SetSelectedValue(self.data.equation.leftTerm.id);
		left:Show();
		
		comp:SetParent(self);
		comp:ClearAllPoints();
		comp:SetPoint("TOP", 25, -35);
		comp:SetWidth(150);
		TRP3_API.ui.listbox.setupListBox(comp, addon.script.comparators, function(comparator)
			if comparator ~= s.data.equation.comparator then
				s.data.equation.comparator = comparator;
				addon.script.operand.getOperandEditorValues(s.data.equation.leftTerm, s.leftOperandEditor);
				addon.script.operand.getOperandEditorValues(s.data.equation.rightTerm, s.rightOperandEditor);
				s.invalidated = true;
				s:GetList():Update();
			end
		end);
		comp:SetSelectedValue(self.data.equation.comparator);
		comp:Show();

		right:SetParent(self);
		right:ClearAllPoints();
		right:SetPoint("TOP", 0, -35);
		right:SetPoint("LEFT", self, "CENTER", 105, 0);
		right:SetPoint("RIGHT", -10, 0);
		TRP3_API.ui.listbox.setupListBox(right, addon.script.getOperandMenu(true), function(operandId)
			if operandId ~= s.data.equation.rightTerm.id then 
				s.data.equation.rightTerm.id = operandId;
				addon.script.operand.getDefaultOperandEditorValues(s.data.equation.rightTerm);
				addon.script.operand.getOperandEditorValues(s.data.equation.leftTerm, s.leftOperandEditor);
				s.invalidated = true;
				s:GetList():Update();
			end
		end);
		right:SetSelectedValue(self.data.equation.rightTerm.id);
		right:Show();

		local offset;
		local leftWidgetSkipList = addon.script.operand.acquireOperandEditor(self.data.equation.leftTerm, self.leftOperandEditor);
		offset = 1;
		for index, widget in ipairs(self.leftOperandEditor) do
			if not leftWidgetSkipList[index] then
				widget:SetParent(self);
				widget:SetPoint("TOPLEFT", 70, -35-offset*35);
				widget:SetPoint("RIGHT", self, "CENTER", -55, 0);
				widget:Show();
				offset = offset + 1;
			end
		end

		offset = 1;
		local rightWidgetSkipList = addon.script.operand.acquireOperandEditor(self.data.equation.rightTerm, self.rightOperandEditor);
		for index, widget in ipairs(self.rightOperandEditor) do
			if not rightWidgetSkipList[index] then
				widget:SetParent(self);
				widget:SetPoint("TOP", 0, -35-offset*35);
				widget:SetPoint("LEFT", self, "CENTER", 105, 0);
				widget:SetPoint("RIGHT", -10, 0);
				widget:Show();
				offset = offset + 1;
			end
		end

-- PREVIEW TODO
-- local function onPreviewClick(button)
-- 	local list = button:GetParent();
-- 	---@type TotalRP3_Extended_Operand
-- 	local operandInfo = TRP3_API.script.getOperand(list.operandID);
-- 	if operandInfo then
-- 		local code = ("displayMessage(\"|cffff9900" .. loc.OP_PREVIEW .. ":|cffffffff \" .. tostring(%s));"):format(operandInfo:CodeReplacement(list.argsData or EMPTY));
-- 		local env = {};
-- 		Utils.table.copy(env, previewEnv);
-- 		Utils.table.copy(env, operandInfo.env);
-- 		TRP3_API.script.generateAndRun(code, nil, env);
-- 	end
-- end

	end
end

function TRP3_Tools_ScriptConstraintEditorListElementMixin:GetElementExtent(data)
	if data.active then 
		return 40 + 35 + 35*math.max(addon.script.operand.getOperandEditorExtent(data.equation.leftTerm.id), addon.script.operand.getOperandEditorExtent(data.equation.rightTerm.id));
	else
		return 40;
	end
end

function TRP3_Tools_ScriptConstraintEditorListElementMixin:Reset()
	if self.data.active then
		if not self.invalidated then
			addon.script.operand.getOperandEditorValues(self.data.equation.leftTerm, self.leftOperandEditor);
			addon.script.operand.getOperandEditorValues(self.data.equation.rightTerm, self.rightOperandEditor);
		end
		addon.script.operand.releaseOperandEditor(self.leftOperandEditor);
		addon.script.operand.releaseOperandEditor(self.rightOperandEditor);
		self:GetList().sharedLeftTermDropdown:Hide();
		self:GetList().sharedComparatorDropdown:Hide();
		self:GetList().sharedRightTermDropdown:Hide();
	end
end

function TRP3_Tools_ScriptConstraintEditorListElementMixin:OnClick(button)
	if button == "LeftButton" then
		if not self.data.index then
			self:GetList():AddEquation();
		elseif not self.data.active then
			self:GetList():SetActiveIndex(self.data.index);
		end
	end
end

function TRP3_Tools_ScriptConstraintEditorListElementMixin:OnEnter()
	if not self.data.active then
		self.highlight:Show();
	end
end

function TRP3_Tools_ScriptConstraintEditorListElementMixin:OnLeave()
	self.highlight:Hide();
end
