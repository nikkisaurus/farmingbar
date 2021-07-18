local addonName = ...
local addon = LibStub("AceAddon-3.0"):GetAddon("FarmingBar")
local L = LibStub("AceLocale-3.0"):GetLocale("FarmingBar", true)

------------------------------------------------------------

local pairs, unpack = pairs, unpack
local format, strlen, strlower, strsub = string.format, string.len, string.lower, string.sub
local GameTooltip_AddBlankLinesToTooltip = GameTooltip_AddBlankLinesToTooltip

local GetItemCount = GetItemCount
--@retail@
local GetCurrencyInfo = C_CurrencyInfo.GetCurrencyInfo
--@end-retail@

--*------------------------------------------------------------------------

local barCommandSort = {
    moveBar = 1,
    configBar = 2,
    toggleMovable = 3,
    openSettings = 4,
    openHelp = 5,
}

local buttonCommandSort = {
    useItem = 1,
    clearObjective = 2,
    moveObjective = 3,
    dragObjective = 4,
    includeBank = 5,
    showObjectiveEditBox = 6,
    showObjectiveBuilder = 7,
}

--*------------------------------------------------------------------------

local tooltipScanner = CreateFrame("Frame")

local showTooltip
tooltipScanner:SetScript("OnUpdate", function(self)
    local frame = GetMouseFocus()
    local widget = frame and frame.obj
    local tooltip = widget and widget.GetUserData and widget:GetUserData("tooltip")
    if tooltip and addon[tooltip] and not addon.DragFrame:GetObjective() then
        showTooltip = true
        GameTooltip:ClearLines()
        GameTooltip:SetOwner(frame, "ANCHOR_BOTTOMRIGHT", 0, 0)
        addon[tooltip](addon, widget, GameTooltip)
        GameTooltip:Show()
    elseif showTooltip then
        showTooltip = false
        GameTooltip:ClearLines()
        GameTooltip:Hide()
    end
end)

--*------------------------------------------------------------------------

function addon:IsTooltipMod()
    if not addon.db.global.settings.hints.enableModifier then
        return true
    else
        return _G["Is" .. addon.db.global.settings.hints.modifier .. "KeyDown"]()
    end
end

--*------------------------------------------------------------------------

function addon:GetBarTooltip(widget, tooltip)
    if not addon.db.global.settings.tooltips.bar then return end
    local barDB = widget:GetUserData("barDB")

    tooltip:AddLine(self:GetBarTitle(widget:GetBarID()), 0, 1, 0, 1)

    GameTooltip_AddBlankLinesToTooltip(tooltip, 1)

    -- local progressCount, progressTotal = bar:GetProgress()
    local progressCount, progressTotal = 0, 0 --!

    tooltip:AddDoubleLine(L["Progress"], barDB.trackProgress and string.format("%s/%s", progressCount, progressTotal) or L["FALSE"], unpack(self.tooltip_keyvalue))
    tooltip:AddDoubleLine(L["Growth Direction"], L[strsub(barDB.grow[1], 1, 1)..strlower(strsub(barDB.grow[1], 2))], unpack(self.tooltip_keyvalue))
    tooltip:AddDoubleLine(L["Growth Type"], L[strsub(barDB.grow[2], 1, 1)..strlower(strsub(barDB.grow[2], 2))], unpack(self.tooltip_keyvalue))
    tooltip:AddDoubleLine(L["Number of Buttons"], barDB.numVisibleButtons.."/"..self.maxButtons, unpack(self.tooltip_keyvalue))
    tooltip:AddDoubleLine(L["Alpha"], self.round(barDB.alpha * 100, 2).."%", unpack(self.tooltip_keyvalue))
    tooltip:AddDoubleLine(L["Scale"], self.round(barDB.scale * 100, 2).."%", unpack(self.tooltip_keyvalue))
    tooltip:AddDoubleLine(L["Movable"], barDB.movable and L["TRUE"] or L["FALSE"], unpack(self.tooltip_keyvalue))

    if addon.db.global.settings.hints.bars then
        GameTooltip_AddBlankLinesToTooltip(GameTooltip, 1)
        if self:IsTooltipMod() then
            GameTooltip:AddLine(format("%s:", L["Hints"]))
            for k, v in self.pairs(addon.db.global.settings.keybinds.bar, function(a, b) return barCommandSort[a] < barCommandSort[b] end) do
                GameTooltip:AddLine(L.BarHints(k, v), unpack(self.tooltip_description))
            end
        else
            tooltip:AddDoubleLine(L["Show Hints"]..":", L[addon.db.global.settings.hints.modifier], unpack(self.tooltip_keyvalue))
        end
    end
end

------------------------------------------------------------

function addon:GetButtonTooltip(widget, tooltip)
    if not addon.db.global.settings.tooltips.button then return end
    local buttonDB = widget:GetButtonDB()

    ------------------------------------------------------------

    if not widget:IsEmpty() then
        local numTrackers = self.tcount(buttonDB.trackers)
        local count = widget:GetCount()
        local objective = widget:GetObjective()

        if buttonDB.action and buttonDB.actionInfo and (buttonDB.action == "ITEM" or buttonDB.action == "CURRENCY") then
            tooltip:SetHyperlink(format("%s:%s", string.lower(buttonDB.action), buttonDB.actionInfo))

            -- Divider
            GameTooltip_AddBlankLinesToTooltip(GameTooltip, 1)
            GameTooltip_AddBlankLinesToTooltip(GameTooltip, 1)
            GameTooltip:AddTexture(389194, {width = 200, height = 10})
        end

        tooltip:AddLine(objectiveTitle, 0, 1, 0, 1)

        if not addon.db.global.settings.tooltips.hideObjectiveInfo then
            if buttonDB.action and buttonDB.actionInfo then
                if  buttonDB.action == "MACROTEXT" then
                    tooltip:AddDoubleLine(L["Action"], strsub(buttonDB.actionInfo, 1, 15)..(strlen(buttonDB.actionInfo) > 15 and "..." or ""), unpack(self.tooltip_keyvalue))
                else
                    self:GetTrackerDataTable(buttonDB.action, buttonDB.actionInfo, function(data)
                        tooltip:AddDoubleLine(L["Action"],  strsub(data.name, 1, 15)..(strlen(data.name) > 15 and "..." or ""), unpack(self.tooltip_keyvalue))
                    end)
                end
            else
                tooltip:AddDoubleLine(L["Action"], L["None"], unpack(self.tooltip_keyvalue))
            end

            tooltip:AddDoubleLine(L["Condition"], L[strsub(buttonDB.condition, 1, 1)..strlower(strsub(buttonDB.condition, 2))], unpack(self.tooltip_keyvalue))

            GameTooltip_AddBlankLinesToTooltip(tooltip, 1)

            tooltip:AddDoubleLine(L["Count"], self.iformat(count, 1), unpack(self.tooltip_keyvalue))

            tooltip:AddDoubleLine(L["Objective"], objective or L["FALSE"], unpack(self.tooltip_description))

            if objective then
                tooltip:AddDoubleLine(L["Objective Complete"], count >= objective and floor(count / objective).."x" or L["FALSE"], unpack(self.tooltip_description))
            end

            GameTooltip_AddBlankLinesToTooltip(tooltip, 1)

            tooltip:AddDoubleLine(L["Trackers"], numTrackers, unpack(self.tooltip_keyvalue))

            local count = 0
            for key, trackerInfo in pairs(buttonDB.trackers) do
                count = count + 1
                if count > 10 then
                    tooltip:AddLine(format("%d %s...", numTrackers - 10, L["more"]), unpack(self.tooltip_description))
                    tooltip:AddTexture(134400)
                    break
                else
                    local trackerType, trackerID = self:ParseTrackerKey(key)
                    self:GetTrackerDataTable(trackerType, trackerID, function(data)
                        local trackerCount = self:GetTrackerCount(widget, key)

                        local trackerRawCount
                        if trackerType == "ITEM" then
                            trackerRawCount = GetItemCount(trackerID, trackerInfo.includeBank)
                        elseif trackerType == "CURRENCY" and trackerID ~= "" then
                            trackerRawCount = GetCurrencyInfo(trackerID) and GetCurrencyInfo(trackerID).quantity
                        end

                        tooltip:AddDoubleLine(data.name, format("%d (%d) / %d", trackerCount, trackerRawCount, trackerInfo.objective), unpack(self.tooltip_description))
                        tooltip:AddTexture(data.icon or 134400)
                    end)
                end
            end

        end

        GameTooltip_AddBlankLinesToTooltip(tooltip, 1)
    end

    ------------------------------------------------------------

    tooltip:AddDoubleLine("Button ID", widget:GetButtonID(), unpack(self.tooltip_keyvalue))

    if addon.db.global.settings.hints.buttons then
        GameTooltip_AddBlankLinesToTooltip(GameTooltip, 1)
        if self:IsTooltipMod() then
            GameTooltip:AddLine(format("%s:", L["Hints"]))
            for k, v in self.pairs(addon.db.global.settings.keybinds.button, function(a, b) return buttonCommandSort[a] < buttonCommandSort[b] end) do
                if buttonDB or v.showOnEmpty then
                    if not (k == "includeBank" and self.tcount(buttonDB.trackers) > 1) then -- Don't show hint to include bank if there's more than 1 tracker
                        GameTooltip:AddLine(L.ButtonHints(k, v), unpack(self.tooltip_description))
                    end
                end
            end
        else
            tooltip:AddDoubleLine(L["Show Hints"]..":", L[addon.db.global.settings.hints.modifier], unpack(self.tooltip_keyvalue))
        end
    end
end

------------------------------------------------------------

function addon:GetExcludeListLabelTooltip(widget, tooltip)
    if addon.db.global.settings.hints.ObjectiveBuilder then
        if self:IsTooltipMod() then
            tooltip:AddLine(format("%s:", L["Hint"]))
            tooltip:AddLine(L.RemoveExcludeHint, unpack(self.tooltip_description))
        else
            tooltip:AddDoubleLine(L["Show Hints"]..":", L[addon.db.global.settings.hints.modifier], unpack(self.tooltip_keyvalue))
        end
    end
end

------------------------------------------------------------

function addon:GetFilterAutoItemsTooltip(widget, tooltip)
    if addon.db.global.settings.hints.ObjectiveBuilder then
        if self:IsTooltipMod() then
            GameTooltip:AddLine(format("%s:", L["Hint"]))
            GameTooltip:AddLine(L.FilterAutoItemsHint, unpack(self.tooltip_description))
        else
            tooltip:AddDoubleLine(L["Show Hints"]..":", L[addon.db.global.settings.hints.modifier], unpack(self.tooltip_keyvalue))
        end
    end
end

------------------------------------------------------------

function addon:GetObjectiveButtonTooltip(widget, tooltip)
    local buttonDB = widget:GetButtonDB()
    if not buttonDB then return end
    local numTrackers = #buttonDB.trackers

    ------------------------------------------------------------

    tooltip:AddLine(buttonDB.title)
    tooltip:AddDoubleLine(L["Tracked"], addon:GetNumButtonsContainingObjective(buttonDB.title), unpack(self.tooltip_keyvalue))

    GameTooltip_AddBlankLinesToTooltip(tooltip, 1)
    if buttonDB.action and buttonDB.actionInfo then
        if  buttonDB.action == "MACROTEXT" then
            tooltip:AddDoubleLine(L["Action"], strsub(buttonDB.actionInfo, 1, 15)..(strlen(buttonDB.actionInfo) > 15 and "..." or ""), unpack(self.tooltip_keyvalue))
        else
            self:GetTrackerDataTable(buttonDB.action, buttonDB.actionInfo, function(data)
                tooltip:AddDoubleLine(L["Action"],  strsub(data.name, 1, 15)..(strlen(data.name) > 15 and "..." or ""), unpack(self.tooltip_keyvalue))
            end)
        end
    else
        tooltip:AddDoubleLine(L["Action"], L["None"], unpack(self.tooltip_keyvalue))
    end

    tooltip:AddDoubleLine(L["Condition"], L[strsub(buttonDB.condition, 1, 1)..strlower(strsub(buttonDB.condition, 2))], unpack(self.tooltip_keyvalue))

    GameTooltip_AddBlankLinesToTooltip(tooltip, 1)
    tooltip:AddDoubleLine(L["Trackers"], numTrackers, unpack(self.tooltip_keyvalue))
    local count = 0
    for key, trackerInfo in pairs(buttonDB.trackers) do
        local trackerType, trackerID = self:ParseTrackerKey(key)
        count = count + 1
        if count > 10 then
            tooltip:AddLine(format("%d %s...", numTrackers - 10, L["more"]), unpack(self.tooltip_description))
            tooltip:AddTexture(134400)
            break
        else
            self:GetTrackerDataTable(trackerType, trackerID, function(data)
                tooltip:AddDoubleLine(data.name, trackerInfo.objective, unpack(self.tooltip_description))
                tooltip:AddTexture(data.icon or 134400)
            end)
        end
    end

    ------------------------------------------------------------

    if addon.db.global.settings.hints.ObjectiveBuilder then
        GameTooltip_AddBlankLinesToTooltip(tooltip, 1)
        if self:IsTooltipMod() then
            tooltip:AddLine(format("%s:", L["Hint"]))
            tooltip:AddLine(L.ObjectiveContextMenuHint, unpack(self.tooltip_description))
        else
            tooltip:AddDoubleLine(L["Show Hints"]..":", L[addon.db.global.settings.hints.modifier], unpack(self.tooltip_keyvalue))
        end
    end
end

------------------------------------------------------------

function addon:GetNewObjectiveButtonTooltip(widget, tooltip)
    if addon.db.global.settings.hints.ObjectiveBuilder then
        if self:IsTooltipMod() then
            tooltip:AddLine(format("%s:", L["Hint"]))
            tooltip:AddLine(L.NewObjectiveHint, unpack(self.tooltip_description))
        else
            tooltip:AddDoubleLine(L["Show Hints"]..":", L[addon.db.global.settings.hints.modifier], unpack(self.tooltip_keyvalue))
        end
    end
end

------------------------------------------------------------

function addon:GetTrackerButtonTooltip(widget, tooltip)
    local _, objectiveInfo = self.ObjectiveBuilder:GetSelectedObjectiveInfo()
    local tracker = widget:GetTrackerKey()
    local trackerInfo = objectiveInfo.trackers[tracker]
    if not trackerInfo then return end
    local numExcluded = #trackerInfo.exclude

    ------------------------------------------------------------

    tooltip:SetHyperlink(format("%s:%s", string.lower(trackerInfo.trackerType), trackerInfo.trackerID))

    GameTooltip_AddBlankLinesToTooltip(tooltip, 1)
    tooltip:AddDoubleLine(L["Objective"], trackerInfo.objective or L["FALSE"], unpack(self.tooltip_keyvalue))
    tooltip:AddDoubleLine(L["Include Bank"], trackerInfo.includeBank and L["TRUE"] or L["FALSE"], unpack(self.tooltip_keyvalue))
    tooltip:AddDoubleLine(L["Include All Characters"], trackerInfo.includeAllCharacters and L["TRUE"] or L["FALSE"], unpack(self.tooltip_keyvalue))

    GameTooltip_AddBlankLinesToTooltip(tooltip, 1)
    tooltip:AddDoubleLine(L["Excluded"], numExcluded, unpack(self.tooltip_keyvalue))
    for key, excludedTitle in pairs(trackerInfo.exclude) do
        if key > 10 then
            tooltip:AddLine(format("%d %s...", numExcluded - 10, L["more"]), unpack(self.tooltip_description))
            tooltip:AddTexture(134400)
            break
        else
            tooltip:AddLine(excludedTitle)
            tooltip:AddTexture(self:GetObjectiveIcon(excludedTitle))
        end
    end

    ------------------------------------------------------------

    if addon.db.global.settings.hints.ObjectiveBuilder then
        GameTooltip_AddBlankLinesToTooltip(tooltip, 1)
        if self:IsTooltipMod() then
            tooltip:AddLine(format("%s:", L["Hint"]))
            tooltip:AddLine(L.TrackerContextMenuHint, unpack(self.tooltip_description))
        else
            tooltip:AddDoubleLine(L["Show Hints"]..":", L[addon.db.global.settings.hints.modifier], unpack(self.tooltip_keyvalue))
        end
    end
end