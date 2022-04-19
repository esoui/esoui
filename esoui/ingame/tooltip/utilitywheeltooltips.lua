function ZO_Tooltip:LayoutUtilityWheelEmote(emoteId)
    local emoteIndex = GetEmoteIndex(emoteId)
    local slashName, category, _, displayName = GetEmoteInfo(emoteIndex)
    local overriddenByPersonality = IsPlayerEmoteOverridden(emoteId)

    --Things added to the top section stack downwards
    local topSection = self:AcquireSection(self:GetStyle("collectionsTopSection"))
    if overriddenByPersonality then
        topSection:AddLine(GetString("SI_EMOTECATEGORY", EMOTE_CATEGORY_PERSONALITY_OVERRIDE))
    end
    topSection:AddLine(GetString("SI_EMOTECATEGORY", category))
    self:AddSection(topSection)

    self:AddLine(displayName, self:GetStyle("title"))

    local bodySection = self:AcquireSection(self:GetStyle("collectionsInfoSection"))
    local descriptionStyle = self:GetStyle("bodyDescription")
    if overriddenByPersonality then
        bodySection:AddLine(slashName, descriptionStyle, self:GetStyle("collectionsPersonality"))
        bodySection:AddLine(GetString(SI_EMOTE_TOOLTIP_OVERRIDDEN_BY_PERSONALITY), descriptionStyle, self:GetStyle("collectionsPersonality"))
    else
        bodySection:AddLine(slashName, descriptionStyle)
    end
    self:AddSection(bodySection)
end

function ZO_Tooltip:LayoutUtilityWheelQuickChat(quickChatId)
    local formattedName = QUICK_CHAT_MANAGER:GetFormattedQuickChatName(quickChatId)
    local formattedQuickChatMessage = zo_strformat(SI_TOOLTIP_QUICK_CHAT_MESSAGE, QUICK_CHAT_MANAGER:GetQuickChatMessage(quickChatId))

    --Things added to the top section stack downward
    local topSection = self:AcquireSection(self:GetStyle("collectionsTopSection"))
    topSection:AddLine(GetString(SI_QUICK_CHAT_EMOTE_MENU_ENTRY_NAME))
    self:AddSection(topSection)

    self:AddLine(formattedName, self:GetStyle("title"))

    local bodySection = self:AcquireSection(self:GetStyle("collectionsInfoSection"))
    local descriptionStyle = self:GetStyle("bodyDescription")
    bodySection:AddLine(formattedQuickChatMessage, descriptionStyle)
    self:AddSection(bodySection)
end
