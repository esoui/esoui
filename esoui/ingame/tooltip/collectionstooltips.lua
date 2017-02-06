do
    local NO_COLLECTION_NAME = nil
    local HIDE_VISUAL_LAYER_INFO = false
    local NO_COOLDOWN = nil
    local HIDE_BLOCK_REASON = false
    function ZO_Tooltip:LayoutCollectibleFromLink(collectibleLink)
        local collectibleId = GetCollectibleIdFromLink(collectibleLink)
        if collectibleId then
            local name, description, _, _, _, purchasable, _, _, hint, isPlaceholder = GetCollectibleInfo(collectibleId)
            local nickname = GetCollectibleNickname(collectibleId)
            self:LayoutCollectible(collectibleId, NO_COLLECTION_NAME, name, nickname, purchaseable, description, hint, isPlaceholder, HIDE_VISUAL_LAYER_INFO, NO_COOLDOWN, HIDE_BLOCK_REASON)
        end
    end
end

do
    local PURCHASED_TEXT = GetString(SI_COLLECTIBLE_TOOLTIP_PURCHASABLE)
    local COOLDOWN_TEXT = GetString(SI_GAMEPAD_TOOLTIP_COOLDOWN_HEADER)
    local QUALITY_NORMAL = nil

    function ZO_Tooltip:LayoutCollectible(collectibleId, collectionName, collectibleName, collectibleNickname, isPurchasable, description, hint, isPlaceholder, showVisualLayerInfo, cooldownSecondsRemaining, showBlockReason)
        if not isPlaceholder then
            --things added to the collection top section stacks to the right (side by side)
            local topSection = self:AcquireSection(self:GetStyle("collectionsTopSection"))

            if collectionName then
                local formattedName = ZO_CachedStrFormat(SI_COLLECTIBLE_NAME_FORMATTER, collectionName)
                topSection:AddLine(formattedName)
            end

            local unlockState = GetCollectibleUnlockStateById(collectibleId)
            topSection:AddLine(GetString("SI_COLLECTIBLEUNLOCKSTATE", unlockState))

            if showVisualLayerInfo then
                local visualLayerHidden, highestPriorityVisualLayerThatIsShowing = WouldCollectibleBeHidden(collectibleId)
                if visualLayerHidden then
                    topSection:AddLine(ZO_SELECTED_TEXT:Colorize(GetHiddenByStringForVisualLayer(highestPriorityVisualLayerThatIsShowing)))
                end
            end

            self:AddSection(topSection)
        end

        local formattedName = ZO_CachedStrFormat(SI_COLLECTIBLE_NAME_FORMATTER, collectibleName)
        self:AddLine(formattedName, QUALITY_NORMAL, self:GetStyle("title"))
    
        local headerSection = self:AcquireSection(self:GetStyle("bodyHeader"))

        if collectibleNickname and collectibleNickname ~= "" then
            formattedName = ZO_CachedStrFormat(SI_TOOLTIP_COLLECTIBLE_NICKNAME, collectibleNickname)
            headerSection:AddLine(formattedName, QUALITY_NORMAL, self:GetStyle("bodyHeader"))
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
            local formattedDescription = ZO_CachedStrFormat(ZO_CACHED_STR_FORMAT_NO_FORMATTER, description)
            bodySection:AddLine(formattedDescription, descriptionStyle)
        end

        if isPurchasable then 
            bodySection:AddLine(PURCHASED_TEXT, descriptionStyle)
        end

        if hint and hint ~= "" then
            local formattedHint = ZO_CachedStrFormat(ZO_CACHED_STR_FORMAT_NO_FORMATTER, hint)
            bodySection:AddLine(formattedHint, descriptionStyle)
        end

        local emoteOverrideNames = {GetCollectiblePersonalityOverridenEmoteDisplayNames(collectibleId)}
        if #emoteOverrideNames > 0 then
            local numEmoteNames = #emoteOverrideNames
            local emoteString = ZO_GenerateCommaSeparatedList(emoteOverrideNames)
            local formattedEmoteString = zo_strformat(SI_COLLECTIBLE_TOOLTIP_PERSONALITY_OVERRIDES_DISPLAY_NAMES_FORMATTER, emoteString, numEmoteNames)
            bodySection:AddLine(formattedEmoteString, descriptionStyle, self:GetStyle("collectionsPersonality"))
        end

        self:AddSection(bodySection)

        -- Layout the use restrictions
        local failsRestriction = false
        local restrictionsSection = self:AcquireSection(self:GetStyle("collectionsRestrictionsSection"))

        for restrictionType = COLLECTIBLE_RESTRICTION_TYPE_MIN_VALUE, COLLECTIBLE_RESTRICTION_TYPE_MAX_VALUE do
            local hasRestrictions, passesRestrictions, allowedNamesString = GetCollectibleRestrictionsByType(collectibleId, restrictionType)
            if hasRestrictions then
                local statValuePair = restrictionsSection:AcquireStatValuePair(self:GetStyle("statValuePair"), self:GetStyle("fullWidth"))
                statValuePair:SetStat(GetString("SI_COLLECTIBLERESTRICTIONTYPE", restrictionType), self:GetStyle("statValuePairStat"))
                if passesRestrictions then
                    statValuePair:SetValue(allowedNamesString, self:GetStyle("statValuePairValue"))
                else
                    statValuePair:SetValue(allowedNamesString, self:GetStyle("failed"), self:GetStyle("statValuePairValue"))
                    failsRestriction = true
                end
                restrictionsSection:AddStatValuePair(statValuePair)
            end
        end

        self:AddSection(restrictionsSection)

        bodySection = self:AcquireSection(self:GetStyle("collectionsInfoSection"))

        if failsRestriction then
            bodySection:AddLine(GetString(SI_COLLECTIBLE_TOOLTIP_NOT_USABLE_BY_CHARACTER), descriptionStyle, self:GetStyle("failed"))
        elseif showBlockReason then
            local usageBlockReason = GetCollectibleBlockReason(collectibleId)
            if usageBlockReason ~= COLLECTIBLE_USAGE_BLOCK_REASON_NOT_BLOCKED then
                local formattedBlockReason = ZO_CachedStrFormat(ZO_CACHED_STR_FORMAT_NO_FORMATTER, GetString("SI_COLLECTIBLEUSAGEBLOCKREASON", usageBlockReason))
                bodySection:AddLine(formattedBlockReason, descriptionStyle, self:GetStyle("failed"))
            end
        end

        self:AddSection(bodySection)
    end
end