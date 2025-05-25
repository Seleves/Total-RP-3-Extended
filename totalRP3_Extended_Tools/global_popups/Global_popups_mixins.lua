local _, addon = ...
local loc = TRP3_API.loc;

TRP3_Tools_EmotesListElementMixin = {};

function TRP3_Tools_EmotesListElementMixin:Initialize(data)
	self.data = data;
	self.token:SetText(data.token);
	self.command:SetText(strjoin(", ", unpack(data.slashCommands)));
	local tooltiptext = strjoin("|n", unpack(data.slashCommands)) .. "|n|n" ..
		TRP3_API.FormatShortcutWithInstruction("LCLICK", "Select emote");
	TRP3_API.ui.tooltip.setTooltipForSameFrame(self, "BOTTOMRIGHT", 0, 0, data.token, tooltiptext);
end


function TRP3_Tools_EmotesListElementMixin:OnEnter()
	TRP3_RefreshTooltipForFrame(self);
end

function TRP3_Tools_EmotesListElementMixin:OnLeave()
	TRP3_MainTooltip:Hide();
end

function TRP3_Tools_EmotesListElementMixin:OnClick()
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
			self:FilterEmotes();
		end,
	};
	self.filter.box:SetScript("OnTextChanged", function() 
		self:FilterEmotes();
	end);
end

function TRP3_Tools_EmotesBrowserMixin:Select(token)
	self:Close();
	if self.onSelectCallback then
		self.onSelectCallback(token);
	end
end

function TRP3_Tools_EmotesBrowserMixin:FilterEmotes()
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
