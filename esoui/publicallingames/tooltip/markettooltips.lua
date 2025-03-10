function ZO_Tooltip:AddInstantUnlockEligibilityFailures(...)
    local count = select("#", ...)
    if count > 0 then
        local ineligibilitySection = self:AcquireSection(self:GetStyle("instantUnlockIneligibilitySection"))
        for i = 1, count do
            local errorStringId = select(i, ...)
            if errorStringId ~= 0 then
                ineligibilitySection:AddLine(GetErrorString(errorStringId), self:GetStyle("instantUnlockIneligibilityLine"))
            end
        end
        self:AddSection(ineligibilitySection)
    end
end

do
    local BUNDLE_HEADER = GetString(SI_MARKET_PRODUCT_TOOLTIP_BUNDLE)
    local DLC_HEADER = GetString(SI_MARKET_PRODUCT_TOOLTIP_DLC)

    function ZO_Tooltip:LayoutMarketProduct(productId, showCollectiblePurchasableHint)
        local productType = GetMarketProductType(productId)
        -- For some market product types we can just use other tooltip layouts
        if productType == MARKET_PRODUCT_TYPE_COLLECTIBLE then
            local params =
            {
                collectibleId = GetMarketProductCollectibleInfo(productId),
                showIfPurchasable = showCollectiblePurchasableHint,
                showHint = type ~= COLLECTIBLE_CATEGORY_TYPE_HOUSE,
            }
            self:LayoutCollectibleWithParams(params)
        elseif productType == MARKET_PRODUCT_TYPE_ITEM then
            local itemLink = GetMarketProductItemLink(productId)
            local stackCount = GetMarketProductStackCount(productId)
            self:LayoutItemWithStackCountSimple(itemLink, stackCount)
        elseif productType == MARKET_PRODUCT_TYPE_CROWN_CRATE then
            local crateId = GetMarketProductCrownCrateId(productId)
            local stackCount = GetMarketProductStackCount(productId)
            self:LayoutCrownCrate(crateId, stackCount)
        elseif productType == MARKET_PRODUCT_TYPE_CURRENCY then
            local currencyType = GetMarketProductCurrencyType(productId)
            local amount = GetMarketProductStackCount(productId)
            self:LayoutCurrency(currencyType, amount)
        elseif productType == MARKET_PRODUCT_TYPE_INSTANT_UNLOCK then
            local instantUnlockId = GetMarketProductInstantUnlockId(productId)
            self:LayoutInstantUnlock(instantUnlockId)
            --Instant Unlock Restrictions
            if GetMarketProductInstantUnlockType(productId) ~= INSTANT_UNLOCK_NONE then
                local expectedClaimResult = CouldAcquireMarketProduct(productId)
                if expectedClaimResult == MARKET_PURCHASE_RESULT_FAIL_INSTANT_UNLOCK_REQ_LIST then
                    self:AddInstantUnlockEligibilityFailures(GetMarketProductEligibilityErrorStringIds(productId))
                elseif expectedClaimResult == MARKET_PURCHASE_RESULT_TEMPORARY_HOTBAR_PROHIBITION then
                    local ineligibilitySection = self:AcquireSection(self:GetStyle("instantUnlockIneligibilitySection"))
                    ineligibilitySection:AddLine(GetString("SI_MARKETPURCHASABLERESULT", MARKET_PURCHASE_RESULT_TEMPORARY_HOTBAR_PROHIBITION), self:GetStyle("instantUnlockIneligibilityLine"))
                    self:AddSection(ineligibilitySection)
                end
            end
        else
            -- things added to the topSection stack upwards
            local topSection = self:AcquireSection(self:GetStyle("topSection"))

            if productType == MARKET_PRODUCT_TYPE_BUNDLE then
                if DoesMarketProductContainDLC(productId) and GetMarketProductNumBundledProducts(productId) == 1 then
                    topSection:AddLine(DLC_HEADER)
                else
                    topSection:AddLine(BUNDLE_HEADER)
                end
            end

            self:AddSection(topSection)

            -- Name
            local displayName = GetMarketProductDisplayName(productId)
            local stackCount = GetMarketProductStackCount(productId)
            if productType == MARKET_PRODUCT_TYPE_HOUSING then
                local houseId = GetMarketProductHouseId(productId)
                if houseId > 0 then
                    local houseCollectibleId = GetCollectibleIdForHouse(houseId)
                    local houseDisplayName = GetCollectibleName(houseCollectibleId)
                    displayName = ZO_SELECTED_TEXT:Colorize(zo_strformat(SI_MARKET_PRODUCT_HOUSE_NAME_FORMATTER, houseDisplayName, displayName))
                end
            elseif stackCount > 1 then
                displayName = zo_strformat(SI_TOOLTIP_ITEM_NAME_WITH_QUANTITY, displayName, stackCount)
            else
                displayName = zo_strformat(SI_TOOLTIP_ITEM_NAME, displayName)
            end

            self:AddLine(displayName, self:GetStyle("title"))

            -- Description
            local bodySection = self:AcquireSection(self:GetStyle("collectionsInfoSection"))
            bodySection:AddLine(zo_strformat(GetMarketProductDescription(productId)), self:GetStyle("bodyDescription"))
            self:AddSection(bodySection)
        end
    end
end

function ZO_Tooltip:LayoutMarketProductListing(marketProductId, presentationIndex)
    local DONT_SHOW_AS_PURCHASABLE = false
    self:LayoutMarketProduct(marketProductId, DONT_SHOW_AS_PURCHASABLE)

    local achievementId, completedAchievement = GetMarketProductUnlockedByAchievementInfo(marketProductId)
    if achievementId ~= 0 then
        local criteriaSection = self:AcquireSection(self:GetStyle("achievementCriteriaSection"))
        criteriaSection:AddLine(GetString(SI_MARKET_PRODUCT_TOOLTIP_REQUIRED_ACHIEVEMENT_HEADER), self:GetStyle("achievementSummaryCriteriaHeader"))
        local achievementName = GetAchievementName(achievementId)
        criteriaSection:AddSection(self:GetCheckboxSection(zo_strformat(achievementName), completedAchievement))
        self:AddSection(criteriaSection)

        if completedAchievement and IsMarketProductPurchased(marketProductId) then
            local purchasableOnAltSection = self:AcquireSection(self:GetStyle("bodySection"))
            if GetNumSkyshardsInAchievement(achievementId) > 0 then
                purchasableOnAltSection:AddLine(GetString(SI_MARKET_PRODUCT_TOOLTIP_SKYSHARD_PURCHASABLE_ON_ALT_CHARACTER_DESCRIPTION), self:GetStyle("bodyDescription"), self:GetStyle("whiteFontColor"))
            elseif GetNumAttainSkillLineRanksInAchievement(achievementId) > 0 then
                purchasableOnAltSection:AddLine(GetString(SI_MARKET_PRODUCT_TOOLTIP_SKILL_LINE_PURCHASABLE_ON_ALT_CHARACTER_DESCRIPTION), self:GetStyle("bodyDescription"), self:GetStyle("whiteFontColor"))
            else
                purchasableOnAltSection:AddLine(GetString(SI_MARKET_PRODUCT_TOOLTIP_PURCHASABLE_ON_ALT_CHARACTER_DESCRIPTION), self:GetStyle("bodyDescription"), self:GetStyle("whiteFontColor"))
            end
            self:AddSection(purchasableOnAltSection)
        end
    end

    local passesReqList, errorStringId = DoesMarketProductPassPurchasableReqList(marketProductId)
    if not passesReqList and errorStringId ~= 0 then
        local ineligibilitySection = self:AcquireSection(self:GetStyle("instantUnlockIneligibilitySection"))
        ineligibilitySection:AddLine(GetErrorString(errorStringId), self:GetStyle("instantUnlockIneligibilityLine"))
        self:AddSection(ineligibilitySection)
    end

    local currencyType, cost, costAfterDiscount, discountPercent, esoPlusCost = GetMarketProductPricingByPresentation(marketProductId, presentationIndex)
    if esoPlusCost then
        local dealText
        if cost then
            dealText = GetString(SI_MARKET_PRODUCT_TOOLTIP_ESO_PLUS_DEAL_DESCRIPTION)
        else
            dealText = GetString(SI_MARKET_PRODUCT_TOOLTIP_ESO_PLUS_EXCLUSIVE_DESCRIPTION)
        end

        local INHERIT_COLOR = true
        local esoPlusDealString = zo_iconTextFormatNoSpace("EsoUI/Art/Market/Gamepad/gp_ESOPlus_Chalice_WHITE_64.dds", "100%", "100%", dealText, INHERIT_COLOR)

        local bodySection = self:AcquireSection(self:GetStyle("bodySection"))
        bodySection:AddLine(esoPlusDealString, self:GetStyle("bodyDescription"), self:GetStyle("esoPlusColorStyle"))
        self:AddSection(bodySection)
    end

    local associatedAchievementId = GetMarketProductAssociatedAchievementId(marketProductId)
    if associatedAchievementId > 0 then
        -- Add padding
        local bodySection = self:AcquireSection(self:GetStyle("bodySection"))
        self:AddSectionEvenIfEmpty(bodySection)
        self:LayoutAchievement(associatedAchievementId)
    end
end

function ZO_Tooltip:LayoutEsoPlusTrialNotification(marketProductId)
    local legendaryColor = GetItemQualityColor(ITEM_DISPLAY_QUALITY_LEGENDARY)
    local coloredHeader = legendaryColor:Colorize(GetString(SI_MARKET_FREE_TRIAL_TOOLTIP_HEADER))
    self:AddLine(coloredHeader, self:GetStyle("title"))

    local bodySection = self:AcquireSection(self:GetStyle("bodySection"))
    local endTimeString = GetMarketProductEndTimeString(marketProductId)
    bodySection:AddLine(zo_strformat(SI_MARKET_FREE_TRIAL_TOOLTIP_DESCRIPTION, endTimeString), self:GetStyle("bodyDescription"))
    self:AddSection(bodySection)

    if not IsOnESOPlusFreeTrial() then
        -- using a second body section here to separate out the start instruction from the description
        local bodySection2 = self:AcquireSection(self:GetStyle("bodySection"))
        -- the action here should match the actual action in the keybind strip to start the free trial
        bodySection2:AddKeybindLine("UI_SHORTCUT_PRIMARY", SI_MARKET_FREE_TRIAL_TOOLTIP_START_INSTRUCTIONS, self:GetStyle("bodyDescription"))
        self:AddSection(bodySection2)
    end
end

function ZO_Tooltip:LayoutEsoPlusMembershipTooltip(statusText)
    self:AddLine(GetString(SI_GAMEPAD_MEMBERSHIP_INFO_TOOLTIP_TITLE), self:GetStyle("title"))

    local statValuePair = self:AcquireStatValuePair(self:GetStyle("statValuePair"))
    statValuePair:SetStat(GetString(SI_MARKET_SUBSCRIPTION_PAGE_SUBSCRIPTION_STATUS_LABEL_GAMEPAD), self:GetStyle("statValuePairStat"))
    statValuePair:SetValue(statusText, self:GetStyle("statValuePairValue"))
    self:AddStatValuePair(statValuePair)

    local overview = GetMarketSubscriptionGamepadInfo()
    local bodySection = self:AcquireSection(self:GetStyle("bodySection"))
    bodySection:AddLine(overview, self:GetStyle("bodyDescription"))
    self:AddSection(bodySection)
end

function ZO_Tooltip:LayoutCrownCrate(crateId, stackCount)
    -- things added to the topSection stack upwards
    local topSection = self:AcquireSection(self:GetStyle("topSection"))
    local crateCount = GetCrownCrateCount(crateId)
    if crateCount > 0 then
        local topSubsection = topSection:AcquireSection(self:GetStyle("topSubsectionItemDetails"))
        topSubsection:AddLine(zo_iconTextFormat("EsoUI/Art/Tooltips/icon_crown_crate.dds", 24, 24, crateCount))
        topSection:AddSection(topSubsection)
    end

    self:AddSection(topSection)

    -- Name
    local displayName = GetCrownCrateName(crateId)
    if stackCount > 1 then
        displayName = zo_strformat(SI_TOOLTIP_ITEM_NAME_WITH_QUANTITY, displayName, stackCount)
    else
        displayName = zo_strformat(SI_TOOLTIP_ITEM_NAME, displayName)
    end
    self:AddLine(displayName, self:GetStyle("title"))

    -- Description
    local bodySection = self:AcquireSection(self:GetStyle("collectionsInfoSection"))
    local description = GetCrownCrateDescription(crateId)
    bodySection:AddLine(description, self:GetStyle("bodyDescription"))
    self:AddSection(bodySection)
end

do
    internalassert(INSTANT_UNLOCK_MAX_VALUE == 17, "Update gamepad tooltip for new instant unlock type")
    local UNLOCK_LABEL = GetString(SI_MARKET_PRODUCT_TOOLTIP_UNLOCK)

    function ZO_Tooltip:LayoutInstantUnlock(instantUnlockId)
        -- things added to the topSection stack upwards
        local topSection = self:AcquireSection(self:GetStyle("topSection"))

        local instantUnlockCategory = GetInstantUnlockRewardCategory(instantUnlockId)
        local headerString = GetString("SI_INSTANTUNLOCKREWARDCATEGORY", instantUnlockCategory)
        topSection:AddLine(headerString)
        self:AddSection(topSection)

        -- Name
        local displayName = GetInstantUnlockRewardDisplayName(instantUnlockId)
        displayName = zo_strformat(SI_TOOLTIP_ITEM_NAME, displayName)
        self:AddLine(displayName, self:GetStyle("title"))

        -- Body
        local instantUnlockDescription = GetInstantUnlockRewardDescription(instantUnlockId)
        local tooltipLines = {}
        if instantUnlockCategory == INSTANT_UNLOCK_REWARD_CATEGORY_UPGRADE then
            local statsSection = self:AcquireSection(self:GetStyle("baseStatsSection"))
            local statValuePair = statsSection:AcquireStatValuePair(self:GetStyle("statValuePair"))
            statValuePair:SetStat(UNLOCK_LABEL, self:GetStyle("statValuePairStat"))

            local currentUnlock
            local maxUnlock
            local instantUnlockType = GetInstantUnlockRewardType(instantUnlockId)
            if instantUnlockType == INSTANT_UNLOCK_PLAYER_BACKPACK then
                currentUnlock = GetCurrentBackpackUpgrade()
                maxUnlock = GetMaxBackpackUpgrade()
            elseif instantUnlockType == INSTANT_UNLOCK_PLAYER_BANK then
                currentUnlock = GetCurrentBankUpgrade()
                maxUnlock = GetMaxBankUpgrade()
            elseif instantUnlockType == INSTANT_UNLOCK_CHARACTER_SLOT then
                currentUnlock = GetCurrentCharacterSlotsUpgrade()
                maxUnlock = GetMaxCharacterSlotsUpgrade()
            elseif instantUnlockType == INSTANT_UNLOCK_OUTFIT then
                currentUnlock = GetNumUnlockedOutfits(GAMEPLAY_ACTOR_CATEGORY_PLAYER)
                maxUnlock = MAX_OUTFIT_UNLOCKS
            elseif instantUnlockType == INSTANT_UNLOCK_ARMORY_BUILD_SLOT then
                currentUnlock = GetNumUnlockedArmoryBuilds()
                maxUnlock = MAX_NUM_ARMORY_BUILDS
            end

            table.insert(tooltipLines, instantUnlockDescription)

            statValuePair:SetValue(zo_strformat(SI_MARKET_PRODUCT_TOOLTIP_UNLOCK_LEVEL, currentUnlock, maxUnlock), self:GetStyle("statValuePairValue"))
            statsSection:AddStatValuePair(statValuePair)
            self:AddSection(statsSection)
        elseif instantUnlockCategory == INSTANT_UNLOCK_REWARD_CATEGORY_SERVICE_TOKEN then
            local tokenCountString
            local instantUnlockType = GetInstantUnlockRewardType(instantUnlockId)
            if instantUnlockType == INSTANT_UNLOCK_RENAME_TOKEN then
                tokenCountString = zo_strformat(SI_SERVICE_TOOLTIP_SERVICE_TOKENS_AVAILABLE, GetNumServiceTokens(SERVICE_TOKEN_NAME_CHANGE), GetString("SI_SERVICETOKENTYPE", SERVICE_TOKEN_NAME_CHANGE))
            elseif instantUnlockType == INSTANT_UNLOCK_RACE_CHANGE_TOKEN then
                tokenCountString = zo_strformat(SI_SERVICE_TOOLTIP_SERVICE_TOKENS_AVAILABLE, GetNumServiceTokens(SERVICE_TOKEN_RACE_CHANGE), GetString("SI_SERVICETOKENTYPE", SERVICE_TOKEN_RACE_CHANGE))
            elseif instantUnlockType == INSTANT_UNLOCK_APPEARANCE_CHANGE_TOKEN then
                tokenCountString = zo_strformat(SI_SERVICE_TOOLTIP_SERVICE_TOKENS_AVAILABLE, GetNumServiceTokens(SERVICE_TOKEN_APPEARANCE_CHANGE), GetString("SI_SERVICETOKENTYPE", SERVICE_TOKEN_APPEARANCE_CHANGE))
            elseif instantUnlockType == INSTANT_UNLOCK_ALLIANCE_CHANGE_TOKEN then
                tokenCountString = zo_strformat(SI_SERVICE_TOOLTIP_SERVICE_TOKENS_AVAILABLE, GetNumServiceTokens(SERVICE_TOKEN_ALLIANCE_CHANGE), GetString("SI_SERVICETOKENTYPE", SERVICE_TOKEN_ALLIANCE_CHANGE))
            end

            table.insert(tooltipLines, instantUnlockDescription)

            table.insert(tooltipLines, tokenCountString)
        else
            table.insert(tooltipLines, instantUnlockDescription)
        end

        -- Description
        local bodySection = self:AcquireSection(self:GetStyle("collectionsInfoSection"))
        for i = 1, #tooltipLines do
            bodySection:AddLine(tooltipLines[i], self:GetStyle("bodyDescription"))
        end
        self:AddSection(bodySection)
    end
end
