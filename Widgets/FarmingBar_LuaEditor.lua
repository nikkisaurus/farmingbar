local addonName = ...
local addon = LibStub("AceAddon-3.0"):GetAddon("FarmingBar")
local L = LibStub("AceLocale-3.0"):GetLocale("FarmingBar", true)

-- Optional libraries
local ACD = LibStub("AceConfigDialog-3.0")
local AceGUI = LibStub("AceGUI-3.0", true)
local LSM = LibStub("LibSharedMedia-3.0")

local Type = "FarmingBar_LuaEditor"
local Version = 1

-- *------------------------------------------------------------------------
-- Widget methods

local methods = {
    OnAcquire = function(self)
        self.frame:Hide()
    end,

    OnRelease = function(self)
        self.window.obj:Release()
        addon.indent.disable(self.editbox.editBox)
        self.editbox.obj:Release()
    end,

    LoadCode = function(self, info, text)
        self.editbox:SetUserData("info", info)
        self.editbox:SetText(text)
        self.editbox:Fire("OnTextChanged")
        self.frame:Show()
    end,

    SetStatusText = function(self, text)
        self.window:SetStatusText(text)
    end,

    SetTitle = function(self, title)
        self.window:SetTitle(title)
    end,
}

-- *------------------------------------------------------------------------
-- Constructor

local function Constructor()
    local window = AceGUI:Create("Frame")
    window:SetLayout("FILL")

    local frame = window.frame
    frame:SetClampedToScreen(true)
    frame:SetPoint("CENTER", 0, 0)
    frame:Show()

    local editbox = AceGUI:Create("MultiLineEditBox")
    addon.indent.enable(editbox.editBox, _, 4) -- adds syntax highlighting
    editbox:SetLabel("")
    window:AddChild(editbox)

    editbox:SetCallback("OnEnterPressed", function(self, _, text)
        local info = self:GetUserData("info")
        if info[5] then
            addon:SetBarDBValue(info[2], text, info[5])
        else
            addon:SetDBValue(info[1], info[2], text)
        end
        self.obj:Release()
    end)

    editbox:SetCallback("OnTextChanged", function(self)
        local info = self:GetUserData("info")
        local scope, key, func, args = unpack(info)
        if not func or not addon[func] then
            return
        else
            func = addon[func]
        end

        -- Update preview while typing
        local preview, err = func(addon, addon.unpack(args, {}), self:GetText())
        window:SetStatusText(preview)

        C_Timer.After(0.01, function()
            if err then
                editbox.button:Disable()
            else
                editbox.button:Enable()
            end
        end)
    end)

    local widget = {
        type = Type,
        window = window,
        frame = frame,
        editbox = editbox,
        statustext = window.statustext,
    }

    window.obj, frame.obj, editbox.obj = widget, widget, widget

    for method, func in pairs(methods) do
        widget[method] = func
    end

    return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
