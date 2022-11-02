function ZO_Tooltip:LayoutNotification(note, messageText)
    local bodySection = self:AcquireSection(self:GetStyle("bodySection"))

    if messageText then
        bodySection:AddLine(messageText, self:GetStyle("bodyDescription"))
    end

    if note then
        bodySection:AddLine(note, self:GetStyle("notificationNote"))
    end

    self:AddSection(bodySection)
end

function ZO_Tooltip:LayoutKeybindNotification(categoryData, entryData)
    local bodySection = self:AcquireSection(self:GetStyle("bodySection"))
    local params = {
        ZO_SELECTED_TEXT:Colorize(categoryData:GetName()),
        ZO_SELECTED_TEXT:Colorize(entryData.data:GetName()),
        "UI_SHORTCUT_RIGHT_STICK",
    }
    local KEYBIND_INDEX = 3
    bodySection:AddParameterizedKeybindLine(SI_COLLECTIONS_UPDATED_NOTIFICATION_MESSAGE_MORE_INFO_GAMEPAD, params, KEYBIND_INDEX, self:GetStyle("bodyDescription"))
    self:AddSection(bodySection)
end