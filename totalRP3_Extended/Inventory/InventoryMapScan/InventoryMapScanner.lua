-- Copyright The Total RP 3 Extended Authors
-- SPDX-License-Identifier: Apache-2.0

local Ellyb = TRP3_API.Ellyb;
---@type AddOn_TotalRP3
local AddOn_TotalRP3 = AddOn_TotalRP3;

--{{{ Lua imports
local tonumber = tonumber;
--}}}

--{{{ Total RP 3 imports
local Globals = TRP3_API.globals;
local loc = TRP3_API.loc;
local broadcast = AddOn_TotalRP3.Communications.broadcast;
local Map = AddOn_TotalRP3.Map;
--}}}

--
-- Self stash scan
--

---@type MapScanner
local stashSelfMapScanner = AddOn_TotalRP3.MapScanner("stashSelfScan")
-- Set scan display properties
stashSelfMapScanner.scanIcon = Ellyb.Icon("Inv_misc_map_01")
stashSelfMapScanner.scanOptionText = loc.DR_STASHES_SCAN_MY;
stashSelfMapScanner.scanSortIndex = 101;
stashSelfMapScanner.scanTitle = loc.DR_STASHES;
stashSelfMapScanner.duration = 0;
-- Indicate the name of the pin template to use with this scan.
-- The MapDataProvider will use this template to generate the pin
stashSelfMapScanner.dataProviderTemplate = TRP3_StashMapPinMixin.TEMPLATE_NAME;

--{{{ Scan behavior
function stashSelfMapScanner:Scan()
	local mapID = WorldMapFrame:GetMapID();
	local stashData = TRP3_Stashes[Globals.player_realm];
	for _, stash in pairs(stashData) do
		if stash.uiMapID == mapID then
			stashSelfMapScanner:OnScanDataReceived(Globals.player_id, stash.mapX, stash.mapY, stash);
		end
	end
end

-- Players can scan for stashes everywhere except if they're in an instance and checking their current map.
function stashSelfMapScanner:CanScan()
	-- Check if the map we are going to scan is the map the player is currently in
	-- and if we have access to coordinates. If not, it's a protected zone and we cannot scan.
	if Map.getDisplayedMapID() == Map.getPlayerMapID() then
		local x, y = Map.getPlayerCoordinates()
		if not x or not y then
			return false;
		end
	end

	return true;
end
--}}}

--
-- Self drop scan
--

---@type MapScanner
local dropSelfMapScanner = AddOn_TotalRP3.MapScanner("dropSelfScan")
-- Set scan display properties
dropSelfMapScanner.scanIcon = Ellyb.Icon("inv_misc_bag_16")
dropSelfMapScanner.scanOptionText = loc.IT_INV_SCAN_MY_ITEMS;
dropSelfMapScanner.scanSortIndex = 100;
dropSelfMapScanner.scanTitle = loc.TYPE_ITEMS;
-- Indicate the name of the pin template to use with this scan.
-- The MapDataProvider will use this template to generate the pin
dropSelfMapScanner.dataProviderTemplate = TRP3_DropMapPinMixin.TEMPLATE_NAME;

--{{{ Scan behavior
function dropSelfMapScanner:Scan()
	local mapID = WorldMapFrame:GetMapID();
	local dropData = TRP3_Drop[Globals.player_realm];
	for _, drop in pairs(dropData) do
		if drop.uiMapID == mapID then
			dropSelfMapScanner:OnScanDataReceived(Globals.player_id, drop.mapX, drop.mapY, drop);
		end
	end
end

-- Players can scan for drops everywhere except if they're in an instance and checking their current map.
function dropSelfMapScanner:CanScan()
	-- Check if the map we are going to scan is the map the player is currently in
	-- and if we have access to coordinates. If not, it's a protected zone and we cannot scan.
	if Map.getDisplayedMapID() == Map.getPlayerMapID() then
		local x, y = Map.getPlayerCoordinates()
		if not x or not y then
			return false;
		end
	end

	return true;
end
--}}}

--
-- Others stash scan
--

local STASHES_SCAN_COMMAND = "S_SCAN";

---@type MapScanner
local stashOthersMapScanner = AddOn_TotalRP3.MapScanner("inventoryOthersScan")
-- Set scan display properties
stashOthersMapScanner.scanIcon = Ellyb.Icon("Icon_treasuremap")
stashOthersMapScanner.scanOptionText = loc.DR_STASHES_SCAN;
stashOthersMapScanner.scanSortIndex = 102;
stashOthersMapScanner.scanTitle = loc.DR_STASHES;
-- Indicate the name of the pin template to use with this scan.
-- The MapDataProvider will use this template to generate the pin
stashOthersMapScanner.dataProviderTemplate = TRP3_StashMapPinMixin.TEMPLATE_NAME;

--{{{ Scan behavior
function stashOthersMapScanner:Scan()
	broadcast.broadcast(STASHES_SCAN_COMMAND, TRP3_API.BroadcastMethod.World, Map.getDisplayedMapID());
end

-- Players can scan for stashes everywhere except if they're in an instance and checking their current map.
function stashOthersMapScanner:CanScan()
	-- Check if the map we are going to scan is the map the player is currently in
	-- and if we have access to coordinates. If not, it's a protected zone and we cannot scan.
	if Map.getDisplayedMapID() == Map.getPlayerMapID() then
		local x, y = Map.getPlayerCoordinates()
		if not x or not y then
			return false;
		end
	end

	return true;
end
--}}}

--{{{ Broadcast commands
broadcast.registerCommand(STASHES_SCAN_COMMAND, function(sender, mapID)
	if (sender == Globals.player_id) then
		return;
	end

	local stashData = TRP3_Stashes[Globals.player_realm];
	for _, stash in pairs(stashData) do
		if stash.uiMapID == tonumber(mapID) and not stash.BA.NS then
			local total = CountTable(stash.item);
			if total > 0 then
				broadcast.sendP2PMessage(sender, STASHES_SCAN_COMMAND, stash.mapX, stash.mapY, stash.BA.NA or loc.DR_STASHES_NAME, stash.BA.IC or "TEMP", total, stash.CR);
			end
		end
	end
end)

broadcast.registerP2PCommand(STASHES_SCAN_COMMAND, function(sender, mapX, mapY, name, icon, total, owner)
	stashOthersMapScanner:OnScanDataReceived(sender, mapX, mapY, {BA = {NA = name, IC = icon}, total = total, CR = owner});
end)
--}}}
