-- These are tooltips that are generic enough to be used by multiple UIs for various purposes
-- do not add layout functions that are specific to one UI

--If there are three or more functions for one system move it to its own file

function ZO_Tooltip:LayoutTextBlockTooltip(text)
    local section = self:AcquireSection(self:GetStyle("bodySection"))
    section:AddLine(text, self:GetStyle("bodyDescription"))
    self:AddSection(section)
end

function ZO_Tooltip:LayoutKeybindTextBlockTooltip(formatString, formatStringParams, keybindIndex)
    local section = self:AcquireSection(self:GetStyle("bodySection"))
    section:AddParameterizedKeybindLine(formatString, formatStringParams, keybindIndex, self:GetStyle("bodyDescription"))
    self:AddSection(section)
end