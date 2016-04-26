function ZO_Tooltip:LayoutCollectibleFromLink(collectibleLink)
    local collectibleId = GetCollectibleIdFromLink(collectibleLink)
    if collectibleId then
        local name, description, _, _, _, purchasable, _, _, hint, isPlaceholder = GetCollectibleInfo(collectibleId)
        local nickname = GetCollectibleNickname(collectibleId)
        local unlockState = GetCollectibleUnlockStateById(collectibleId)
        self:LayoutCollectible(nil, name, nickname, unlockState, purchaseable, description, hint, isPlaceholder)
    end
end

do
    local g_collectibleNameCache = 
    {
        formatter = SI_COLLECTIBLE_NAME_FORMATTER,
        cache = {},
    }
    local g_collectibleNicknameCache = 
    {
        formatter = SI_GAMEPAD_COLLECTIONS_NICKNAME_FORMAT,
        cache = {},
    }
    local g_collectibleDescriptionCache = 
    {
        formatter = SI_GAMEPAD_COLLECTIONS_DESCRIPTION_FORMATTER,
        cache = {},
    }

    local function GetCachedText(cacheTable, rawText)
        local formattedName = cacheTable.cache[rawText]
        if not formattedName then
            formattedName = zo_strformat(cacheTable.formatter, rawText)
            cacheTable.cache[rawText] = formattedName
        end
        return formattedName
    end

    local PURCHASED_TEXT = GetString(SI_COLLECTIBLE_TOOLTIP_PURCHASABLE)
    local COOLDOWN_TEXT = GetString(SI_GAMEPAD_TOOLTIP_COOLDOWN_HEADER)

    function ZO_Tooltip:LayoutCollectible(collectionName, collectibleName, collectibleNickname, unlockState, isPurchasable, description, hint, isPlaceholder, highestPriorityVisualLayerThatIsShowing, visualLayerHidden, cooldownSecondsRemaining, usageBlockReason)
        if not isPlaceholder then
            --things added to the collection top section stacks to the right (side by side)
            local topSection = self:AcquireSection(self:GetStyle("collectionsTopSection"))

            if collectionName then
                local formattedName = GetCachedText(g_collectibleNameCache, collectionName)
                topSection:AddLine(formattedName)
            end

            topSection:AddLine(GetString("SI_COLLECTIBLEUNLOCKSTATE", unlockState))

            if visualLayerHidden then
                topSection:AddLine(ZO_SELECTED_TEXT:Colorize(GetHiddenByStringForVisualLayer(highestPriorityVisualLayerThatIsShowing)))
            end

            self:AddSection(topSection)
        end

        local formattedName = GetCachedText(g_collectibleNameCache, collectibleName)
        self:AddLine(formattedName, qualityNormal, self:GetStyle("title"))
    
        local headerSection = self:AcquireSection(self:GetStyle("bodyHeader"))

        if collectibleNickname and collectibleNickname ~= "" then
            formattedName = GetCachedText(g_collectibleNicknameCache, collectibleNickname)
            headerSection:AddLine(formattedName, qualityNormal, self:GetStyle("bodyHeader"))
        end

        self:AddSection(headerSection)

        if cooldownSecondsRemaining and cooldownSecondsRemaining > 0 then
            local cooldownSection = self:AcquireSection(self:GetStyle("collectionsStatsSection"))
            local cooldownPair = cooldownSection:AcquireStatValuePair(self:GetStyle("statValuePair"))
            cooldownPair:SetStat(COOLDOWN_TEXT, self:GetStyle("collectionsTopSection"))
        
            local secondsRemainingString = ZO_FormatTimeLargestTwo(cooldownSecondsRemaining, TIME_FORMAT_STYLE_DESCRIPTIVE_MINIMAL)
            cooldownPair:SetValue(secondsRemainingString, self:GetStyle("collectionsStatsValue"))
            cooldownSection:AddStatValuePair(cooldownPair)
            self:AddSection(cooldownSection)
        end

        local bodySection = self:AcquireSection(self:GetStyle("collectionsInfoSection"))
        local descriptionStyle = self:GetStyle("bodyDescription")

        if description then
            local formattedDescription = GetCachedText(g_collectibleDescriptionCache, description)
            bodySection:AddLine(formattedDescription, descriptionStyle)
        end

        if isPurchasable then 
            bodySection:AddLine(PURCHASED_TEXT, descriptionStyle)
        end

        if hint then
            local formattedHint = GetCachedText(g_collectibleDescriptionCache, hint)
            bodySection:AddLine(formattedHint, descriptionStyle)
        end

        if usageBlockReason then
            bodySection:AddLine(GetString("SI_COLLECTIBLEUSAGEBLOCKREASON", usageBlockReason), descriptionStyle, self:GetStyle("failed"))
        end

        self:AddSection(bodySection)
    end
end