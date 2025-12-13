local _, addon = ...
local loc = TRP3_API.loc;

TRP3_Tools_CreationsListElementMixin = {};

function TRP3_Tools_CreationsListElementMixin:Initialize(data)

	self.data = data;
	self.link:SetText(data.link);
	
	if data.source == "my" then
		self.creator:SetText(TRP3_API.Colors.White("You"));
	else
		self.creator:SetText(data.creator:gsub("-.*", "")); -- character name without realm
	end
	
	self.icon:SetTexture("Interface\\ICONS\\" .. (data.icon or "TEMP"));
	if data.type == TRP3_DB.types.ITEM then
		self.typeIcon:SetTexture("Interface\\GossipFrame\\VendorGossipIcon");
	elseif data.type == TRP3_DB.types.CAMPAIGN then
		self.typeIcon:SetTexture("Interface\\GossipFrame\\CampaignAvailableQuestIcon");
	else
		self.typeIcon:SetTexture();
	end
	
	TRP3_API.ui.tooltip.setTooltipForSameFrame(self, "BOTTOMRIGHT", 0, 0, data.link, data.metadataTooltip);
end

function TRP3_Tools_CreationsListElementMixin:OnEnter()
	TRP3_RefreshTooltipForFrame(self);
	if self.data.type == TRP3_DB.types.ITEM then
		local class = TRP3_API.extended.getClass(self.data.creationId);
		TRP3_API.inventory.showItemTooltip(self, {id = self.data.creationId}, class, true, "ANCHOR_RIGHT");
	end
end

function TRP3_Tools_CreationsListElementMixin:OnLeave()
	TRP3_MainTooltip:Hide();
	TRP3_ItemTooltip:Hide();
end

function TRP3_Tools_CreationsListElementMixin:OnClick(button)
	if button == "LeftButton" then
		addon.openDraft(self.data.creationId);
	elseif button == "RightButton" then
		TRP3_MenuUtil.CreateContextMenu(self, function(_, contextMenu)
			contextMenu:CreateTitle(("|TInterface\\ICONS\\%s:16:16|t %s"):format(self.data.icon, self.data.link));

			local openOption = contextMenu:CreateButton("Open", function()
				addon.openDraft(self.data.creationId);
			end);
			TRP3_MenuUtil.SetElementTooltip(openOption, "Open element...");

			if addon.findDraft(self.data.creationId) then
				local openNewOption = contextMenu:CreateButton("Open in new tab", function()
					addon.openDraft(self.data.creationId, true);
				end);
				TRP3_MenuUtil.SetElementTooltip(openNewOption, "Open element in new tab...");
			end

			if TRP3_API.extended.isObjectMine(self.data.creationId) or TRP3_API.extended.isObjectExchanged(self.data.creationId) then
				local securityOption = contextMenu:CreateButton(loc.SEC_LEVEL_DETAILS, function()
					TRP3_API.security.showSecurityDetailFrame(self.data.creationId);
				end);
				TRP3_MenuUtil.SetElementTooltip(securityOption, loc.DB_SECURITY_TT);
			end

			if self.data.type == TRP3_DB.types.ITEM then
				local class = TRP3_API.extended.getClass(self.data.creationId);
				local addItemOption = contextMenu:CreateButton(loc.DB_ADD_ITEM, function()
					TRP3_API.popup.showNumberInputPopup(loc.DB_ADD_COUNT:format(self.data.link), function(inputValue)
						TRP3_API.inventory.addItem(nil, self.data.creationId, {count = inputValue or 1, madeBy = class.BA and class.BA.CR});
					end, nil, 1);
				end);
				addItemOption:SetEnabled(TRP3_API.extended.isObjectMine(self.data.creationId) or (class.BA and not class.BA.PA))
				TRP3_MenuUtil.SetElementTooltip(addItemOption, loc.DB_ADD_ITEM_TT); -- TODO if disabled, explain why
			end
			
			if ChatEdit_GetActiveWindow() and (self.data.type == TRP3_DB.types.ITEM or self.data.type == TRP3_DB.types.CAMPAIGN) then
				local linkOption = contextMenu:CreateButton("Create chat link", function() 
					if self.data.type == TRP3_DB.types.ITEM then
						TRP3_API.ChatLinks:OpenMakeImportablePrompt(loc.CL_EXTENDED_ITEM, function(canBeImported)
							TRP3_API.extended.ItemsChatLinksModule:InsertLink(self.data.creationId, self.data.creationId, {}, canBeImported);
						end);
					elseif self.data.type == TRP3_DB.types.CAMPAIGN then
						TRP3_API.ChatLinks:OpenMakeImportablePrompt(loc.CL_EXTENDED_CAMPAIGN, function(canBeImported)
							TRP3_API.extended.CampaignsChatLinksModule:InsertLink(self.data.creationId, self.data.creationId, canBeImported);
						end);
					end				
				end);
				TRP3_MenuUtil.SetElementTooltip(linkOption, "inserts link to this item into your current chat"); -- TODO

			end


			local copyOption = contextMenu:CreateButton(loc.EDITOR_ID_COPY, function() 
				TRP3_API.popup.showTextInputPopup(loc.EDITOR_ID_COPY_POPUP, nil, nil, self.data.creationId);
			end);
			TRP3_MenuUtil.SetElementTooltip(copyOption, loc.DB_COPY_ID_TT);

			if self.data.type == TRP3_DB.types.ITEM then
				local innerCopyOption = contextMenu:CreateButton(loc.IN_INNER_COPY_ACTION, function()
					local class = TRP3_API.extended.getClass(self.data.creationId);
					addon.clipboard.clear();
					addon.clipboard.append(class, class.TY, self.data.creationId, self.data.creationId);
				end);
				TRP3_MenuUtil.SetElementTooltip(innerCopyOption, loc.DB_COPY_TT);
			end
			
			local copyOption = contextMenu:CreateButton("Create a copy", function()
				addon.database.copyCreation(self.data.creationId);
			end);
			TRP3_MenuUtil.SetElementTooltip(copyOption, "Inserts a copy of the object into the database");
			
			local exportOption = contextMenu:CreateButton(loc.DB_EXPORT, function()
				addon.database.serializeCreation(self.data.creationId);
			end);
			TRP3_MenuUtil.SetElementTooltip(exportOption, loc.DB_EXPORT_TT_2);
			
			local fullExportOption = contextMenu:CreateButton(loc.DB_FULL_EXPORT, function() 
				addon.database.exportCreation(self.data.creationId);
			end);
			TRP3_MenuUtil.SetElementTooltip(fullExportOption, loc.DB_FULL_EXPORT_TT);
			
			if TRP3_API.extended.isObjectMine(self.data.creationId) or TRP3_API.extended.isObjectExchanged(self.data.creationId) then
				contextMenu:CreateDivider()
				local deleteOption = contextMenu:CreateButton(DELETE, function()
					local _, name = TRP3_API.extended.tools.getClassDataSafeByType(TRP3_API.extended.getClass(self.data.creationId));
					TRP3_API.popup.showConfirmPopup(loc.DB_REMOVE_OBJECT_POPUP:format(self.data.creationId, name or UNKNOWN), function()
						addon.database.removeCreation(self.data.creationId);
					end);
				end);
				TRP3_MenuUtil.SetElementTooltip(deleteOption, loc.DB_DELETE_TT);
			end
			
		end);
	end
end

TRP3_Tools_CreationsActionsMixin = {};

function TRP3_Tools_CreationsActionsMixin:Initialize()
	
	self.blankItem:SetScript("OnClick", function()
		local itemID, _ = TRP3_API.extended.tools.createItem(TRP3_API.extended.tools.getBlankItemData(TRP3_DB.modes.EXPERT));
		addon.openDraft(itemID);
	end);

	self.containerItem:SetScript("OnClick", function()
		local itemID, _ = TRP3_API.extended.tools.createItem(TRP3_API.extended.tools.getContainerItemData());
		addon.openDraft(itemID);
	end);

	self.documentItem:SetScript("OnClick", function()
		local generatedID = TRP3_API.utils.str.id();
		local itemID, _ = TRP3_API.extended.tools.createItem(TRP3_API.extended.tools.getDocumentItemData(generatedID), generatedID);
		addon.openDraft(itemID);
	end);

	self.auraItem:SetScript("OnClick", function()
		local generatedID = TRP3_API.utils.str.id();
		local itemID, _ = TRP3_API.extended.tools.createItem(TRP3_API.extended.tools.getAuraItemData(generatedID), generatedID);
		addon.openDraft(itemID);
	end);

	self.blankCampaign:SetScript("OnClick", function()
		local generatedID = TRP3_API.utils.str.id();
		local campaignID, _ = TRP3_API.extended.tools.createCampaign(TRP3_API.extended.tools.getCampaignData(generatedID), generatedID);
		addon.openDraft(campaignID);
	end);

	self.import:SetScript("OnClick", function()
		TRP3_ToolFrame.database.import.content.scroll.text:SetText("");
		TRP3_ToolFrame.database.import:Show();
	end);

	self.importFull:SetScript("OnClick", function()
		if C_AddOns.IsAddOnLoaded("totalRP3_Extended_ImpExport") then
			if TRP3_Extended_ImpExport.object then
				local version = TRP3_Extended_ImpExport.version;
				local ID = TRP3_Extended_ImpExport.id;
				local data = TRP3_Extended_ImpExport.object;
				local displayVersion = TRP3_API.utils.str.sanitizeVersion(TRP3_Extended_ImpExport.display_version);
				local link = TRP3_API.inventory.getItemLink(data);
				local by = data.MD.CB;
				local objectVersion = data.MD.V or 0;
				local type = TRP3_API.extended.tools.getTypeLocale(data.TY);
				TRP3_API.popup.showConfirmPopup(loc.DB_IMPORT_FULL_CONFIRM:format(type, link, by, objectVersion), function()
					C_Timer.After(0.25, function()
						addon.database.importCreation(version, ID, data, displayVersion);
					end);
				end);
			else
				TRP3_API.utils.message.displayMessage(loc.DB_IMPORT_EMPTY, 2);
			end
		else
			TRP3_API.utils.message.displayMessage(loc.DB_EXPORT_MODULE_NOT_ACTIVE, 2);
		end
	end);

	self.hardsave:SetScript("OnClick", function()
		ReloadUI();
	end);

	self.credits:SetScript("OnClick", function()
		addon.openCredits();
	end);
	
end
