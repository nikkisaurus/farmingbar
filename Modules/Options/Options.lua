local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
local AceGUI = LibStub("AceGUI-3.0")

--[[ Menus ]]
local function GetTreeMenu()
    local menu = {
        {
            value = "Bars",
            text = L["Bars"],
            children = {},
        },
    }

    for barID, _ in pairs(private.db.profile.bars) do
        tinsert(menu[1].children, {
            value = "bar" .. barID,
            text = format("%s %d", L["Bar"], barID)
        })
    end

    return menu
end

--[[ Callbacks ]]
local function treeGroup_OnGroupSelected(treeGroup, _, path)
    local group, subgroup = strsplit("\001", path)
    private["Get" .. group .. "Options"](private, treeGroup, subgroup)
end

--[[ Options ]]
function private:AddChildren(parent, ...)
    for _, child in pairs({ ... }) do
        parent:AddChild(child)
    end
end

function private:SetOptionTooltip(widget, text)
    widget:SetCallback("OnEnter", function()
        private:LoadTooltip(widget.frame, "ANCHOR_RIGHT", 0, 0,
            { { line = text, color = private.defaults.tooltip_desc } })
    end)
    widget:SetCallback("OnLeave", function()
        private:ClearTooltip()
    end)
end

function private:NotifyChange(parent)
    for _, child in pairs(parent.children) do
        if child.children then
            private:NotifyChange(child)
        else
            local NotifyChange = child:GetUserData("NotifyChange")
            if NotifyChange then
                NotifyChange()
            end
        end
    end
end

function private:LoadOptions()
    if not private.options then
        private:InitializeOptions()
    end

    private.options:Show()
end

function private:InitializeOptions()
    local options = AceGUI:Create("Frame")
    options:SetTitle(L.addonName)
    options:SetLayout("Fill")
    options:Hide()
    private.options = options

    local treeGroup = AceGUI:Create("TreeGroup")
    treeGroup:SetTree(GetTreeMenu())
    treeGroup:SetCallback("OnGroupSelected", treeGroup_OnGroupSelected)

    private:AddChildren(options, treeGroup)
end
