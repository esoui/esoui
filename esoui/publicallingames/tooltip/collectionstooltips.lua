do
    local DEPRECATED_ARG = nil

    function ZO_Tooltip:LayoutCollectibleFromData(collectibleData, showVisualLayerInfo, cooldownSecondsRemaining, showBlockReason)
        if collectibleData then
            self:LayoutCollectible(collectibleData:GetId(), DEPRECATED_ARG, collectibleData:GetName(), collectibleData:GetNickname(), collectibleData:IsPurchasable(), collectibleData:GetDescription(), collectibleData:GetHint(), DEPRECATED_ARG, collectibleData:GetCategoryType(), showVisualLayerInfo, cooldownSecondsRemaining, showBlockReason)
        end
    end
end

do
    local HIDE_VISUAL_LAYER_INFO = false
    local NO_COOLDOWN = nil
    local HIDE_BLOCK_REASON = false

    function ZO_Tooltip:LayoutCollectibleFromLink(collectibleLink)
        local collectibleId = GetCollectibleIdFromLink(collectibleLink)
        if collectibleId then
            local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(collectibleId)
            self:LayoutCollectibleFromData(collectibleData, HIDE_VISUAL_LAYER_INFO, NO_COOLDOWN, HIDE_BLOCK_REASON)
        end
    end
end

do
    local PURCHASED_TEXT = GetString(SI_COLLECTIBLE_TOOLTIP_PURCHASABLE)
    local COOLDOWN_TEXT = GetString(SI_GAMEPAD_TOOLTIP_COOLDOWN_HEADER)
    local QUALITY_NORMAL = nil

    function ZO_Tooltip:LayoutCollectible(collectibleId, deprecatedCollectionName, collectibleName, collectibleNickname, isPurchasable, description, hint, deprecatedArg, categoryType, showVisualLayerInfo, cooldownSecondsRemaining, showBlockReason)
        local isActive = IsCollectibleActive(collectibleId)

        --things added to the collection top section stack downward
        local topSection = self:AcquireSection(self:GetStyle("collectionsTopSection"))

        local specializedCollectibleType = GetSpecializedCollectibleType(collectibleId)
        if specializedCollectibleType == SPECIALIZED_COLLECTIBLE_TYPE_NONE then
            topSection:AddLine(GetString("SI_COLLECTIBLECATEGORYTYPE", categoryType))
        else
            topSection:AddLine(GetString("SI_SPECIALIZEDCOLLECTIBLETYPE", specializedCollectibleType))
        end
        local unlockState = GetCollectibleUnlockStateById(collectibleId)
        topSection:AddLine(GetString("SI_COLLECTIBLEUNLOCKSTATE", unlockState))
            
        if showVisualLayerInfo then
            local isOutfitStylePresentInEffectivelyEquippedOutfit = categoryType == COLLECTIBLE_CATEGORY_TYPE_OUTFIT_STYLE and IsCollectiblePresentInEffectivelyEquippedOutfit(collectibleId)

            if isActive or isOutfitStylePresentInEffectivelyEquippedOutfit then
                local visualLayerHidden, highestPriorityVisualLayerThatIsShowing = WouldCollectibleBeHidden(collectibleId)
                if visualLayerHidden then
                    topSection:AddLine(ZO_SELECTED_TEXT:Colorize(GetHiddenByStringForVisualLayer(highestPriorityVisualLayerThatIsShowing)))
                end
            end
        end

        self:AddSection(topSection)

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

        if categoryType == COLLECTIBLE_CATEGORY_TYPE_COMBINATION_FRAGMENT then
            local combinationId = GetCollectibleReferenceId(collectibleId)
            local combinationDescription = GetCombinationDescription(combinationId)
            if combinationDescription ~= "" then
                bodySection:AddLine(zo_strformat(SI_ITEM_FORMAT_STR_COMBINATION, combinationDescription), descriptionStyle)
            end
        end

        if isPurchasable then 
            bodySection:AddLine(PURCHASED_TEXT, descriptionStyle)
        end

        if hint and hint ~= "" then
            local formattedHint = ZO_CachedStrFormat(ZO_CACHED_STR_FORMAT_NO_FORMATTER, hint)
            bodySection:AddLine(formattedHint, descriptionStyle)
        end

        if categoryType == COLLECTIBLE_CATEGORY_TYPE_PERSONALITY then
            local emoteOverrideNames = {GetCollectiblePersonalityOverridenEmoteDisplayNames(collectibleId)}
            if #emoteOverrideNames > 0 then
                local numEmoteNames = #emoteOverrideNames
                local emoteString = ZO_GenerateCommaSeparatedList(emoteOverrideNames)
                local formattedEmoteString = zo_strformat(SI_COLLECTIBLE_TOOLTIP_PERSONALITY_OVERRIDES_DISPLAY_NAMES_FORMATTER, emoteString, numEmoteNames)
                bodySection:AddLine(formattedEmoteString, descriptionStyle, self:GetStyle("collectionsPersonality"))
            end
        elseif categoryType == COLLECTIBLE_CATEGORY_TYPE_EMOTE then
            local emoteId = GetCollectibleReferenceId(collectibleId)
            local emoteIndex = GetEmoteIndex(emoteId)
            if emoteIndex then
                local displayName = select(4, GetEmoteInfo(emoteIndex))
                bodySection:AddLine(zo_strformat(SI_COLLECTIBLE_TOOLTIP_EMOTE_DISPLAY_NAME_FORMATTER, displayName), descriptionStyle, self:GetStyle("collectionsEmoteGranted"))
            end
        elseif categoryType == COLLECTIBLE_CATEGORY_TYPE_OUTFIT_STYLE then
            local outfitStyleId = GetCollectibleReferenceId(collectibleId)
            local numMaterials = GetNumOutfitStyleItemMaterials(outfitStyleId)
            if numMaterials > 1 then
                local materialsNames = {}
                for i = 1, numMaterials do
                    local materialName = GetOutfitStyleItemMaterialName(outfitStyleId, i)
                    table.insert(materialsNames, materialName)
                end

                local formattedMaterialNames = table.concat(materialsNames, GetString(SI_LIST_COMMA_SEPARATOR))
                local materialString = zo_strformat(SI_TOOLTIP_OUTFIT_STYLE_AVAILABLE_IN, formattedMaterialNames)

                bodySection:AddLine(materialString, descriptionStyle, self:GetStyle("collectionsEquipmentStyle"))
            end

            local applyCost, isFree = GetOutfitStyleCost(outfitStyleId)
            if isFree then
                applyCost = 0
            end
            local applyCostString = ZO_Currency_FormatGamepad(CURT_MONEY, applyCost, ZO_CURRENCY_FORMAT_AMOUNT_ICON)
            local statValuePair = bodySection:AcquireStatValuePair(self:GetStyle("statValuePair"))
            statValuePair:SetStat(GetString(SI_TOOLTIP_COLLECTIBLE_OUTFIT_STYLE_APPLICATION_COST_GAMEPAD), self:GetStyle("statValuePairStat"))
            statValuePair:SetValue(applyCostString, descriptionStyle, self:GetStyle("currencyStatValuePairValue"))
            bodySection:AddStatValuePair(statValuePair)
        elseif  categoryType == COLLECTIBLE_CATEGORY_TYPE_POLYMORPH then
            if isActive and showVisualLayerInfo then
                bodySection:AddLine(GetString(SI_POLYMORPH_CAN_HIDE_WARNING), descriptionStyle, self:GetStyle("collectionsPolymorphOverrideWarningStyle"))
            end
        elseif categoryType == COLLECTIBLE_CATEGORY_TYPE_COMBINATION_FRAGMENT then
            local combinationId = GetCollectibleReferenceId(collectibleId)
            local baseCollectibleId = GetCombinationFirstNonFragmentCollectibleComponentId(combinationId)
            if baseCollectibleId ~= 0 then
                local text = self:GetRequiredCollectibleText(baseCollectibleId)
                if text ~= "" then
                    local colorStyle = IsCollectibleUnlocked(baseCollectibleId) and self:GetStyle("succeeded") or self:GetStyle("failed")
                    bodySection:AddLine(text, descriptionStyle, colorStyle)
                end
            end
        end

        self:AddSection(bodySection)

        -- Layout the use restrictions
        local failsRestriction = false
        local restrictionsSection = self:AcquireSection(self:GetStyle("collectionsRestrictionsSection"))

        for restrictionType = COLLECTIBLE_RESTRICTION_TYPE_ITERATION_BEGIN, COLLECTIBLE_RESTRICTION_TYPE_ITERATION_END do
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

        if GetCurrentZoneHouseId() ~= 0 and IsCollectibleCategoryPlaceableFurniture(categoryType) then
            local furnishingLimitTypeSection = self:AcquireSection(self:GetStyle("furnishingLimitTypeSection"))
            furnishingLimitTypeSection:AddLine(GetString(SI_TOOLTIP_FURNISHING_LIMIT_TYPE), self:GetStyle("furnishingLimitTypeTitle"))

            local furnishingLimitType = GetCollectibleFurnishingLimitType(collectibleId)
            local furnishingLimitName = GetString("SI_HOUSINGFURNISHINGLIMITTYPE", furnishingLimitType)
            furnishingLimitTypeSection:AddLine(furnishingLimitName, self:GetStyle("furnishingLimitTypeDescription"))

            self:AddSection(furnishingLimitTypeSection)
        end

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