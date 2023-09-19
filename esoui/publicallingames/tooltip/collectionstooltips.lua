do
    local DEPRECATED_ARG = nil

    function ZO_Tooltip:LayoutCollectibleFromData(collectibleData, showVisualLayerInfo, cooldownSecondsRemaining, showBlockReason, actorCategory)
        if collectibleData then
            local params =
            {
                collectibleId = collectibleData:GetId(),
                showNickname = true,
                showIfPurchasable = true,
                showHint = true,
                showVisualLayerInfo = showVisualLayerInfo,
                cooldownSecondsRemaining = cooldownSecondsRemaining,
                showBlockReason = showBlockReason,
                actorCategory = actorCategory,
            }
            self:LayoutCollectibleWithParams(params)
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

    -- Required Params: collectibleId
    -- Optional Params: showNickname, showIfPurchasable, showHint, showVisualLayerInfo, cooldownSecondsRemaining, showBlockReason, actorCategory
    function ZO_Tooltip:LayoutCollectibleWithParams(params)
        local collectibleId = params.collectibleId
        local categoryType = GetCollectibleCategoryType(collectibleId)
        local actorCategory = params.actorCategory or GAMEPLAY_ACTOR_CATEGORY_PLAYER
        local isActive = IsCollectibleActive(collectibleId, actorCategory)

        --things added to the collection top section stack downward
        local topSection = self:AcquireSection(self:GetStyle("collectionsTopSection"))

        local specializedCollectibleType = GetSpecializedCollectibleType(collectibleId)
        if specializedCollectibleType == SPECIALIZED_COLLECTIBLE_TYPE_NONE then
            if categoryType == COLLECTIBLE_CATEGORY_TYPE_PLAYER_FX_OVERRIDE then
                local categoryText = GetString("SI_COLLECTIBLECATEGORYTYPE", categoryType)
                local overrideType = GetCollectiblePlayerFxOverrideType(collectibleId)
                local overrideSubtype

                if overrideType == PLAYER_FX_OVERRIDE_TYPE_HARVEST then
                    overrideSubtype = GetCollectiblePlayerFxWhileHarvestingType(collectibleId)
                    if overrideSubtype then
                        local subcategoryText = GetString("SI_PLAYERFXWHILEHARVESTINGTYPE", overrideSubtype)
                        topSection:AddLine(zo_strformat(SI_ITEM_FORMAT_STR_TEXT1_TEXT2, categoryText, subcategoryText))
                    end
                elseif overrideType == PLAYER_FX_OVERRIDE_TYPE_ABILITY then
                    overrideSubtype = GetCollectiblePlayerFxOverrideAbilityType(collectibleId)
                    if overrideSubtype then
                        local subcategoryText = GetString("SI_PLAYERFXOVERRIDEABILITYTYPE", overrideSubtype)
                        topSection:AddLine(zo_strformat(SI_ITEM_FORMAT_STR_TEXT1_TEXT2, categoryText, subcategoryText))
                    end
                end

                if not overrideSubtype then
                    topSection:AddLine(GetString("SI_COLLECTIBLECATEGORYTYPE", categoryType))
                end
            else
                topSection:AddLine(GetString("SI_COLLECTIBLECATEGORYTYPE", categoryType))
            end
        else
            topSection:AddLine(GetString("SI_SPECIALIZEDCOLLECTIBLETYPE", specializedCollectibleType))
        end
        local unlockState = GetCollectibleUnlockStateById(collectibleId)
        topSection:AddLine(GetString("SI_COLLECTIBLEUNLOCKSTATE", unlockState))

        if params.showVisualLayerInfo then
            local isOutfitStylePresentInEffectivelyEquippedOutfit = categoryType == COLLECTIBLE_CATEGORY_TYPE_OUTFIT_STYLE and IsCollectiblePresentInEffectivelyEquippedOutfit(GAMEPLAY_ACTOR_CATEGORY_PLAYER, collectibleId)

            if isActive or isOutfitStylePresentInEffectivelyEquippedOutfit then
                local visualLayerHidden, highestPriorityVisualLayerThatIsShowing = WouldCollectibleBeHidden(collectibleId, actorCategory)
                if visualLayerHidden then
                    topSection:AddLine(ZO_SELECTED_TEXT:Colorize(GetHiddenByStringForVisualLayer(highestPriorityVisualLayerThatIsShowing)))
                end
            end
        end

        self:AddSection(topSection)

        local formattedName = ZO_CachedStrFormat(SI_COLLECTIBLE_NAME_FORMATTER, GetCollectibleName(collectibleId))
        self:AddLine(formattedName, self:GetStyle("title"))

        local headerSection = self:AcquireSection(self:GetStyle("bodyHeader"))

        if params.showNickname then
            local collectibleNickname = GetCollectibleNickname(collectibleId)
            if collectibleNickname ~= "" then
                formattedName = ZO_CachedStrFormat(SI_TOOLTIP_COLLECTIBLE_NICKNAME, collectibleNickname)
                headerSection:AddLine(formattedName, self:GetStyle("bodyHeader"))
            end
        end

        self:AddSection(headerSection)

        if params.cooldownSecondsRemaining and params.cooldownSecondsRemaining > 0 then
            local cooldownSection = self:AcquireSection(self:GetStyle("collectionsStatsSection"))
            local cooldownPair = cooldownSection:AcquireStatValuePair(self:GetStyle("statValuePair"))
            cooldownPair:SetStat(COOLDOWN_TEXT, self:GetStyle("collectionsTopSection"))
        
            local secondsRemainingString = ZO_FormatTimeLargestTwo(params.cooldownSecondsRemaining, TIME_FORMAT_STYLE_DESCRIPTIVE_MINIMAL)
            cooldownPair:SetValue(secondsRemainingString, self:GetStyle("collectionsStatsValue"))
            cooldownSection:AddStatValuePair(cooldownPair)
            self:AddSection(cooldownSection)
        end

        local bodySection = self:AcquireSection(self:GetStyle("collectionsInfoSection"))
        local descriptionStyle = self:GetStyle("bodyDescription")
        
        local description = GetCollectibleDescription(collectibleId)
        if description ~= "" then
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

        if params.showIfPurchasable and IsCollectiblePurchasable(collectibleId) then
            bodySection:AddLine(PURCHASED_TEXT, descriptionStyle)
        end

        if params.showHint then
            local hint = GetCollectibleHint(collectibleId)
            if categoryType == COLLECTIBLE_CATEGORY_TYPE_HOUSE and hint == "" then
                hint = GetString(SI_HOUSING_BOOK_AVAILABLE_FOR_PURCHASE)
            end
            if hint ~= "" then
                local formattedHint = ZO_CachedStrFormat(ZO_CACHED_STR_FORMAT_NO_FORMATTER, hint)
                bodySection:AddLine(formattedHint, descriptionStyle)
            end
        end

        if categoryType == COLLECTIBLE_CATEGORY_TYPE_PERSONALITY then
            local emoteOverrideNames = {GetCollectiblePersonalityOverridenEmoteDisplayNames(collectibleId)}
            if #emoteOverrideNames > 0 then
                local numEmoteNames = #emoteOverrideNames
                local emoteString = ZO_GenerateCommaSeparatedListWithAnd(emoteOverrideNames)
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
            local applyCostNarrationString = ZO_Currency_FormatGamepad(CURT_MONEY, applyCost, ZO_CURRENCY_FORMAT_AMOUNT_NAME)
            local statValuePair = bodySection:AcquireStatValuePair(self:GetStyle("statValuePair"))
            statValuePair:SetStat(GetString(SI_TOOLTIP_COLLECTIBLE_OUTFIT_STYLE_APPLICATION_COST_GAMEPAD), self:GetStyle("statValuePairStat"))
            statValuePair:SetValueWithCustomNarration(applyCostString, applyCostNarrationString, descriptionStyle, self:GetStyle("currencyStatValuePairValue"))
            bodySection:AddStatValuePair(statValuePair)
        elseif  categoryType == COLLECTIBLE_CATEGORY_TYPE_POLYMORPH then
            if isActive and params.showVisualLayerInfo then
                bodySection:AddLine(GetString(SI_POLYMORPH_CAN_HIDE_WARNING), descriptionStyle, self:GetStyle("collectionsPolymorphOverrideWarningStyle"))
            end
        elseif categoryType == COLLECTIBLE_CATEGORY_TYPE_COMBINATION_FRAGMENT then
            local combinationId = GetCollectibleReferenceId(collectibleId)
            local nonFragmentComponentCollectibleIds = { GetCombinationNonFragmentComponentCollectibleIds(combinationId) }
            local formattedNonFragmentComponentCollectibleNames = {}
            local hasUnlockedAllNonFragmentCollectibles = true
            for i, nonFragmentCollectibleId in ipairs(nonFragmentComponentCollectibleIds) do
                local nonFragmentCollectibleName = GetCollectibleName(nonFragmentCollectibleId)
                if nonFragmentCollectibleName ~= "" then
                    local categoryName = GetCollectibleCategoryNameByCollectibleId(nonFragmentCollectibleId)
                    local formattedNonFragmentCollectibleName = string.format(GetString(SI_COLLECTIBLE_NAME_WITH_CATEGORY_NAME_C_STYLE_FORMATTER), nonFragmentCollectibleName, categoryName)
                    table.insert(formattedNonFragmentComponentCollectibleNames, formattedNonFragmentCollectibleName)
                    if not IsCollectibleUnlocked(nonFragmentCollectibleId) then
                        hasUnlockedAllNonFragmentCollectibles = false
                    end
                end
            end

            if #formattedNonFragmentComponentCollectibleNames > 0 then
                local nonFragmentCollectibleNameList = ZO_GenerateCommaSeparatedListWithAnd(formattedNonFragmentComponentCollectibleNames)
                local text = zo_strformat(SI_COLLECTIBLES_REQUIRED_TO_PERFORM_COMBINATION, nonFragmentCollectibleNameList)
                local colorStyle = hasUnlockedAllNonFragmentCollectibles and self:GetStyle("succeeded") or self:GetStyle("failed")
                bodySection:AddLine(text, descriptionStyle, colorStyle)
            end
        elseif categoryType == COLLECTIBLE_CATEGORY_TYPE_PLAYER_FX_OVERRIDE then
            local overrideType = GetCollectiblePlayerFxOverrideType(collectibleId)
            local overrideSubtype

            if overrideType == PLAYER_FX_OVERRIDE_TYPE_HARVEST then
                overrideSubtype = GetCollectiblePlayerFxWhileHarvestingType(collectibleId)
                if overrideSubtype then
                    local subcategoryText = GetString("SI_PLAYERFXWHILEHARVESTINGTYPE", overrideSubtype)
                    bodySection:AddLine(zo_strformat(SI_COLLECTIBLE_TOOLTIP_PLAYER_FX_OVERRIDDEN, subcategoryText), descriptionStyle, self:GetStyle("collectionsPlayerFXOverridden"))
                end
            elseif overrideType == PLAYER_FX_OVERRIDE_TYPE_ABILITY then
                overrideSubtype = GetCollectiblePlayerFxOverrideAbilityType(collectibleId)
                if overrideSubtype then
                    local subcategoryText = GetString("SI_PLAYERFXOVERRIDEABILITYTYPE", overrideSubtype)
                    bodySection:AddLine(zo_strformat(SI_COLLECTIBLE_TOOLTIP_PLAYER_FX_OVERRIDDEN, subcategoryText), descriptionStyle, self:GetStyle("collectionsPlayerFXOverridden"))
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

        if not IsCollectibleAvailableToActorCategory(collectibleId, GAMEPLAY_ACTOR_CATEGORY_COMPANION) then
            bodySection = self:AcquireSection(self:GetStyle("collectionsInfoSection"))
            bodySection:AddLine(GetString(SI_COLLECTIBLE_TOOLTIP_NOT_USABLE_BY_COMPANION), descriptionStyle)
            self:AddSection(bodySection)
        end

        self:AddCollectibleTags(collectibleId)

        if IsCollectibleCategoryPlaceableFurniture(categoryType) then
            local furnishingLimitTypeSection = self:AcquireSection(self:GetStyle("furnishingLimitTypeSection"))
            furnishingLimitTypeSection:AddLine(GetString(SI_TOOLTIP_FURNISHING_LIMIT_TYPE), self:GetStyle("furnishingLimitTypeTitle"))

            local furnishingLimitType = GetCollectibleFurnishingLimitType(collectibleId)
            local furnishingLimitName = GetString("SI_HOUSINGFURNISHINGLIMITTYPE", furnishingLimitType)
            furnishingLimitTypeSection:AddLine(furnishingLimitName, self:GetStyle("furnishingLimitTypeDescription"))

            self:AddSection(furnishingLimitTypeSection)
        end

        bodySection = self:AcquireSection(self:GetStyle("collectionsInfoSection"))

        if categoryType == COLLECTIBLE_CATEGORY_TYPE_COMPANION then
            local questState = GetCollectibleAssociatedQuestState(collectibleId)
            if questState == COLLECTIBLE_ASSOCIATED_QUEST_STATE_INACTIVE or questState == COLLECTIBLE_ASSOCIATED_QUEST_STATE_ACCEPTED then
                --If we get here, we are going to be showing a specialized error message
                --This means we don't want to show the fails restriction or block reason in the tooltip
                failsRestriction = false
                params.showBlockReason = false

                local companionId = GetCollectibleReferenceId(collectibleId)
                local introQuestId = GetCompanionIntroQuestId(companionId)
                local zoneId = GetQuestZoneId(introQuestId)
                local zoneIndex = GetZoneIndex(zoneId)
                local isZoneLocked = IsZoneCollectibleLocked(zoneIndex)
                if isZoneLocked then
                    local lockedZoneCollectibleId = GetCollectibleIdForZone(zoneIndex)
                    local formattedBlockReason = zo_strformat(SI_COLLECTIBLE_TOOLTIP_COMPANION_BLOCKED_BY_QUEST_AND_DLC, GetQuestName(introQuestId), GetZoneNameById(zoneId), GetString("SI_COLLECTIBLECATEGORYTYPE", GetCollectibleCategoryType(lockedZoneCollectibleId)))
                    bodySection:AddLine(formattedBlockReason, descriptionStyle, self:GetStyle("failed"))
                else
                    local formattedBlockReason = zo_strformat(SI_COLLECTIBLE_TOOLTIP_COMPANION_BLOCKED_BY_QUEST, GetQuestName(introQuestId))
                    bodySection:AddLine(formattedBlockReason, descriptionStyle, self:GetStyle("failed"))
                end
            end
        end

        if failsRestriction then
            bodySection:AddLine(GetString(SI_COLLECTIBLE_TOOLTIP_NOT_USABLE_BY_CHARACTER), descriptionStyle, self:GetStyle("failed"))
        elseif params.showBlockReason then
            local usageBlockReason = GetCollectibleBlockReason(collectibleId)
            if usageBlockReason ~= COLLECTIBLE_USAGE_BLOCK_REASON_NOT_BLOCKED then
                local formattedBlockReason = ZO_CachedStrFormat(ZO_CACHED_STR_FORMAT_NO_FORMATTER, GetString("SI_COLLECTIBLEUSAGEBLOCKREASON", usageBlockReason))
                bodySection:AddLine(formattedBlockReason, descriptionStyle, self:GetStyle("failed"))
            end
        end

        self:AddSection(bodySection)
    end
end

function ZO_Tooltip:LayoutImitationCollectibleFromData(imitationCollectibleData, actorCategory)
    local topSection = self:AcquireSection(self:GetStyle("collectionsTopSection"))
    topSection:AddLine(GetString("SI_COLLECTIBLECATEGORYTYPE", imitationCollectibleData:GetCategoryType()))
    self:AddSection(topSection)

    self:AddLine(imitationCollectibleData:GetName(), self:GetStyle("title"))

    local bodySection = self:AcquireSection(self:GetStyle("collectionsInfoSection"))
    bodySection:AddLine(imitationCollectibleData:GetDescription(actorCategory), self:GetStyle("bodyDescription"))

    if imitationCollectibleData:IsActive(actorCategory) and imitationCollectibleData.GetActiveCollectibleText then
        local activeCollectibleText = imitationCollectibleData:GetActiveCollectibleText(actorCategory)
        if activeCollectibleText ~= nil and activeCollectibleText ~= "" then
            bodySection:AddLine(activeCollectibleText, self:GetStyle("bodyDescription"))
        end
    end

    local blockReason = imitationCollectibleData:IsBlocked(actorCategory) and imitationCollectibleData:GetBlockReason(actorCategory) or nil
    if blockReason ~= nil and blockReason ~= "" then
        bodySection:AddLine(blockReason, self:GetStyle("bodyDescription"), self:GetStyle("failed"))
    end

    self:AddSection(bodySection)
end

function ZO_Tooltip:AddCollectibleTags(collectibleId)
    local numTags = GetNumCollectibleTags(collectibleId)
    if numTags > 0 then
        local tagStrings = {}

        -- Build a map of tag category -> table of tags in that category
        for i = 1, numTags do
            local tagDescription, tagCategory, hideInUi = GetCollectibleTagInfo(collectibleId, i)
            if tagDescription ~= "" and not hideInUi then
                if not tagStrings[tagCategory] then
                    tagStrings[tagCategory] = {}
                end
                table.insert(tagStrings[tagCategory], zo_strformat(SI_TOOLTIP_ITEM_TAG_FORMATER, tagDescription)) 
            end
        end

        -- Iterate through categories, and build a section for each category with tags in it
        for i = TAG_CATEGORY_MIN_VALUE, TAG_CATEGORY_MAX_VALUE do
            if tagStrings[i] then
                local itemTagsSection = self:AcquireSection(self:GetStyle("itemTagsSection"))
                local categoryName = GetString("SI_ITEMTAGCATEGORY", i)
                if categoryName ~= "" then
                    itemTagsSection:AddLine(categoryName, self:GetStyle("itemTagTitle"))
                end
                table.sort(tagStrings[i])
                itemTagsSection:AddLine(table.concat(tagStrings[i], GetString(SI_LIST_COMMA_SEPARATOR)), self:GetStyle("itemTagDescription"))
                self:AddSection(itemTagsSection)
            end
        end
    end
end