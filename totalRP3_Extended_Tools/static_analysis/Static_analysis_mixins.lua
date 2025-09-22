local _, addon = ...
local loc = TRP3_API.loc;

TRP3_Tools_StaticAnalysisMixin = {};

function TRP3_Tools_StaticAnalysisMixin:Initialize()
	TRP3_API.popup.STATIC_ANALYSIS = "static_analysis";
	TRP3_API.popup.POPUPS[TRP3_API.popup.STATIC_ANALYSIS] = {
		frame = self,
		showMethod = function(issueList)
			self.content.list:SetShown(TableHasAnyEntries(issueList));
			self.content.emptyText:SetShown(not TableHasAnyEntries(issueList));
			self.content.list.model:Flush();
			self.content.list.model:InsertTable(issueList);
		end,
	};
	addon.localize(self);
end

function TRP3_Tools_StaticAnalysisMixin:Close()
	self:Hide();
end

TRP3_Tools_StaticAnalysisListElementMixin = {};

TRP3_Tools_StaticAnalysisListElementMixin = {};

function TRP3_Tools_StaticAnalysisListElementMixin:Initialize(data)
	self.data = data;
	self.title:SetText(data.title);
	self.description:SetText(data.description);
	self.location:SetText(("|T%s:16:16|t %s"):format(data.icon, data.link));
	--local tooltiptext = strjoin("|n", unpack(data.slashCommands)) .. "|n|n" ..
	--	TRP3_API.FormatShortcutWithInstruction("LCLICK", "Select emote");
	--TRP3_API.ui.tooltip.setTooltipForSameFrame(self, "BOTTOMRIGHT", 0, 0, data.token, tooltiptext);
end

function TRP3_Tools_StaticAnalysisListElementMixin:OnEnter()
	--TRP3_RefreshTooltipForFrame(self);
end

function TRP3_Tools_StaticAnalysisListElementMixin:OnLeave()
	--TRP3_MainTooltip:Hide();
end

function TRP3_Tools_StaticAnalysisListElementMixin:OnClick()
	--TRP3_Tools_EmotesBrowser:Select(self.data.token);
	-- TODO go to location
end