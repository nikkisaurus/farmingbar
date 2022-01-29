local addonName = ...
local addon = LibStub("AceAddon-3.0"):GetAddon("FarmingBar")
local L = LibStub("AceLocale-3.0"):GetLocale("FarmingBar", true)

function addon:InitializeTooltips()
	self.tooltip = CreateFrame("GameTooltip", "FarmingBar_Tooltip", UIParent, "GameTooltipTemplate")
	self.tooltipFrame = self:GetDBValue("global", "settings.tooltips.useGameTooltip") and GameTooltip or self.tooltip
	local tooltipFrame = self.tooltipFrame

	function tooltipFrame:Load(owner, anchor, x, y, lines)
		tooltipFrame:ClearLines()
		tooltipFrame:SetOwner(owner, anchor, x, y)
		for _, line in pairs(lines) do
			if line.double then
				--tooltipFrame:AddDoubleLine(k, v, unpack(kColor), unpack(vColor)) -- TODO
			else
				tooltipFrame:AddLine(line.line, unpack(line.color))
			end
		end
		tooltipFrame:Show()
	end

	function tooltipFrame:Clear()
		tooltipFrame:ClearLines()
		tooltipFrame:Hide()
	end
end
