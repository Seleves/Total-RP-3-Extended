local _, addon = ...
local loc = TRP3_API.loc;

TRP3_Tools_EditorNoteButtonMixin = {};

function TRP3_Tools_EditorNoteButtonMixin:OnClick()
	if self.associatedFrame then
		if self.associatedFrame:IsShown() then
			self.associatedFrame:Close();
		else
			addon.hidePopups();
			self.associatedFrame:Open();
		end
	end
end

function TRP3_Tools_EditorNoteButtonMixin:OnEnter()
	TRP3_API.ui.tooltip.setTooltipForSameFrame(self, "BOTTOMRIGHT", 0, 0, self.tooltipHeader, self.tooltipBody);
	TRP3_RefreshTooltipForFrame(self);
end

function TRP3_Tools_EditorNoteButtonMixin:OnLeave()
	TRP3_MainTooltip:Hide();
end

TRP3_Tools_EditorNoteMixin = {};

function TRP3_Tools_EditorNoteMixin:AssociateWith(button)
	self.associatedButton = button;
	button.associatedFrame = self;
end

function TRP3_Tools_EditorNoteMixin:Close()
	self:UpdateDisplay();
	self:Hide();
end

function TRP3_Tools_EditorNoteMixin:ClassToInterface(class)
	self.note.scroll.text:SetText(class.NT or "");
	self:UpdateDisplay();
end

function TRP3_Tools_EditorNoteMixin:InterfaceToClass(targetClass)
	targetClass.NT = TRP3_API.utils.str.emptyToNil(strtrim(self.note.scroll.text:GetText()));
end

function TRP3_Tools_EditorNoteMixin:UpdateDisplay()
	if self.associatedButton then
		local text = strtrim(self.note.scroll.text:GetText());
		self.associatedButton.tooltipHeader = loc.EDITOR_NOTES;
		if text:len() > 500 then
			self.associatedButton:GetNormalTexture():SetAtlas("minimap-genericevent-hornicon-supertracked");
			self.associatedButton:GetPushedTexture():SetAtlas("minimap-genericevent-hornicon-pressed-supertracked");
			self.associatedButton.tooltipBody = text:sub(1, 500) .. "...|n|n" .. TRP3_API.FormatShortcutWithInstruction("LCLICK", "Edit note");
		elseif text:len() > 0 then
			self.associatedButton:GetNormalTexture():SetAtlas("minimap-genericevent-hornicon-supertracked");
			self.associatedButton:GetPushedTexture():SetAtlas("minimap-genericevent-hornicon-pressed-supertracked");
			self.associatedButton.tooltipBody = text .. "|n|n" .. TRP3_API.FormatShortcutWithInstruction("LCLICK", "Edit note");
		else
			self.associatedButton:GetNormalTexture():SetAtlas("minimap-genericevent-hornicon");
			self.associatedButton:GetPushedTexture():SetAtlas("minimap-genericevent-hornicon-pressed");
			self.associatedButton.tooltipBody = TRP3_API.FormatShortcutWithInstruction("LCLICK", "Add note");
		end
	end
end
