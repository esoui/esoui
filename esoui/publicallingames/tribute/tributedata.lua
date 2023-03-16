function ZO_GetTributeLockReasonTooltipString()
    local collectibleId = GetTributeRequiredCollectibleId()
    local questId = GetTributeRequiredQuestId()
    local isCollectibleLocked = collectibleId ~= 0 and not IsCollectibleUnlocked(collectibleId)
    local isQuestLocked = questId ~= 0 and not HasCompletedQuest(questId)

    local tooltipText = nil
    if isCollectibleLocked or isQuestLocked then
        local colorizedFeatureName = ZO_SELECTED_TEXT:Colorize(GetQuestName(questId))
        local colorizedSubzoneName = ZO_SELECTED_TEXT:Colorize(GetString(SI_TRIBUTE_TOOLTIP_CITY_NAME))

        local zoneName = GetZoneNameById(TRIBUTE_CHAPTER_ZONE_ID)
        local colorizedZoneName = ZO_SELECTED_TEXT:Colorize(zoneName)

        local questLockedText = zo_strformat(SI_TRIBUTE_TOOLTIP_UNAVAILABLE_REQUIREMENT, colorizedFeatureName, colorizedSubzoneName, colorizedZoneName)

        if isCollectibleLocked then
            local collectibleName = GetCollectibleName(collectibleId)
            local colorizedCollectibleName = ZO_SELECTED_TEXT:Colorize(collectibleName)
            local lockedText = zo_strformat(SI_TRIBUTE_TOOLTIP_UNAVAILABLE_UNLOCK, colorizedZoneName, colorizedCollectibleName)

            tooltipText = zo_strformat(SI_TRIBUTE_TOOLTIP_UNAVAILABLE_FORMATTER, questLockedText, lockedText)
        else
            tooltipText = questLockedText
        end
    end

    return tooltipText
end

function ZO_IsTributeLocked()
    local collectibleId = GetTributeRequiredCollectibleId()
    local questId = GetTributeRequiredQuestId()
    local isCollectibleLocked = collectibleId ~= 0 and not IsCollectibleUnlocked(collectibleId)
    local isQuestLocked = questId ~= 0 and not HasCompletedQuest(questId)
    return isCollectibleLocked or isQuestLocked
end

-----------------------
-- Tribute Icon Data --
-----------------------

ZO_TRIBUTE_ICONS_KEYBOARD =
{
    up = "EsoUI/Art/Tribute/tribute_tabIcon_tribute_up.dds",
    down = "EsoUI/Art/Tribute/tribute_tabIcon_tribute_down.dds",
    over = "EsoUI/Art/Tribute/tribute_tabIcon_tribute_over.dds",
    disabled = "EsoUI/Art/Tribute/tribute_tabIcon_tribute_disabled.dds",
}

ZO_TRIBUTE_ICONS_GAMEPAD =
{
    normal = "EsoUI/Art/Tribute/gamepad/gp_tribute_tabIcon_tribute.dds",
    disabled = "EsoUI/Art/Tribute/gamepad/gp_tribute_tabIcon_tribute_disabled.dds",
}

------------------------------------------
-- Tribute Patron Card Progression Data --
------------------------------------------

ZO_TributePatronCardProgressionData = ZO_InitializingObject:Subclass()

function ZO_TributePatronCardProgressionData:Initialize(tributePatronData, progressionIndex)
    self.tributePatronData = tributePatronData
    self.progressionIndex = progressionIndex

    local upgradeCardId
    self.baseCardId, upgradeCardId, self.quantity = GetTributePatronDockCardInfoByIndex(self.tributePatronData:GetId(), progressionIndex)
    -- Save the storage space if it has no upgrade
    if upgradeCardId ~= 0 then
        self.upgradeCardId = upgradeCardId
    end

    self:RefreshUpgradeStatus()
end

function ZO_TributePatronCardProgressionData:GetCardIndex()
    return self.progressionIndex
end

function ZO_TributePatronCardProgressionData:GetPatronData()
    return self.tributePatronData
end

function ZO_TributePatronCardProgressionData:GetBaseCardId()
    return self.baseCardId
end

function ZO_TributePatronCardProgressionData:GetUpgradeCardId()
    return self.upgradeCardId
end

function ZO_TributePatronCardProgressionData:GetQuantity()
    return self.quantity
end

function ZO_TributePatronCardProgressionData:CanBeUpgraded()
    return self.upgradeCardId ~= nil
end

function ZO_TributePatronCardProgressionData:RefreshUpgradeStatus()
    if self:CanBeUpgraded() then
        local hadUpgrade = self.hasUpgrade
        -- Save the storage space if not upgraded
        self.hasUpgrade = IsCollectibleTributePatronBookCardUpgraded(self.tributePatronData:GetId(), self.progressionIndex) or nil
        if self.hasUpgrade ~= hadUpgrade then
           return true
        end
    end
    return false
end

function ZO_TributePatronCardProgressionData:HasUpgrade()
    return self.hasUpgrade
end

-------------------------
-- Tribute Patron Data --
-------------------------

ZO_TributePatronData = ZO_InitializingObject:Subclass()

function ZO_TributePatronData:Initialize(patronId)
    self.patronId = patronId
    self.dockCardsDirty = true

    -- Get Tribute Patron Category information
    local tributePatronCategoryId = GetTributePatronCategoryId(patronId)
    if tributePatronCategoryId ~= 0 then
        local tributePatronCategoryData = TRIBUTE_DATA_MANAGER:GetOrCreateTributePatronCategoryData(tributePatronCategoryId)
        self.tributePatronCategoryData = tributePatronCategoryData
        tributePatronCategoryData:AddTributePatronData(self)
    end

    self.dockCardProgressions = {}
    for cardProgressionIndex = 1, GetTributePatronNumDockCards(self.patronId) do
        table.insert(self.dockCardProgressions, ZO_TributePatronCardProgressionData:New(self, cardProgressionIndex))
    end
end

function ZO_TributePatronData:RefreshProgressions(refreshReason)
    local changedProgressions = {}
    for _, progressionData in ipairs(self.dockCardProgressions) do
        if progressionData:RefreshUpgradeStatus() then
            table.insert(changedProgressions, progressionData)
        end
    end

    if #changedProgressions > 0 then
        self:MarkDockCardsDirty()
        -- If we're initing, either because we just created the object or because we got an init event, we don't want CSAs.
        -- So the refreshReason can help CSA system determine if the trigger of this refresh is something that's worthy of a CSA.
        TRIBUTE_DATA_MANAGER:OnProgressionUpgradeStatusChanged(self.patronId, changedProgressions, refreshReason)
    end
end

function ZO_TributePatronData:GetId()
    return self.patronId
end

function ZO_TributePatronData:GetName()
    return GetTributePatronName(self.patronId)
end

function ZO_TributePatronData:GetFormattedName()
    return ZO_CachedStrFormat(SI_TRIBUTE_PATRON_NAME_FORMATTER, self:GetName())
end

function ZO_TributePatronData:GetFormattedNameAndSuitIcon()
    return ZO_CachedStrFormat(SI_TRIBUTE_PATRON_NAME_WITH_SUIT_ICON_FORMATTER, self:GetName(), self:GetPatronSuitIcon())
end

function ZO_TributePatronData:GetRarity()
    return GetTributePatronRarity(self.patronId)
end

function ZO_TributePatronData:GetFormattedColorizedName()
    local qualityColor = GetItemQualityColor(self:GetRarity())
    return qualityColor:Colorize(self:GetFormattedName())
end

function ZO_TributePatronData:GetDisabledFormattedColorizedName()
    local qualityColor = GetDimItemQualityColor(self:GetRarity())
    return qualityColor:Colorize(self:GetFormattedName())
end

function ZO_TributePatronData:GetCategoryData()
    return self.tributePatronCategoryData
end

function ZO_TributePatronData:IsPatronLocked()
    local patronCollectibleId = self:GetPatronCollectibleId()
    if patronCollectibleId ~= 0 then
        return not IsCollectibleUnlocked(patronCollectibleId)
    end
    return false
end

function ZO_TributePatronData:GetPatronCollectibleId()
    return GetTributePatronCollectibleId(self.patronId)
end

function ZO_TributePatronData:GetNumStarterCards()
    return GetTributePatronNumStarterCards(self.patronId)
end

function ZO_TributePatronData:GetStarterCardIdByIndex(cardIndex)
    return GetTributePatronStarterCardIdByIndex(self.patronId, cardIndex)
end

function ZO_TributePatronData:GetNumDockCards()
    return #self.dockCardProgressions
end

function ZO_TributePatronData:GetDockCardInfoByIndex(cardIndex)
    local dockCardProgression = self.dockCardProgressions[cardIndex]
    if dockCardProgression then
        return dockCardProgression:GetBaseCardId(), dockCardProgression:GetUpgradeCardId(), dockCardProgression:GetQuantity()
    else
        -- baseCardId, upgradeCardId, quantity
        return 0, 0, 0
    end
end

function ZO_TributePatronData:HasDockCardUpgrade(cardIndex)
    local dockCardProgression = self.dockCardProgressions[cardIndex]
    if dockCardProgression then
        return dockCardProgression:HasUpgrade()
    end
    return false
end

function ZO_TributePatronData:GetSuitAtlas(cardType)
    return GetTributePatronSuitAtlas(self.patronId, cardType)
end

function ZO_TributePatronData:GetPatronSuitIcon()
    return GetTributePatronSuitIcon(self.patronId)
end

function ZO_TributePatronData:GetPatronSmallIcon()
    return GetTributePatronSmallIcon(self.patronId)
end

function ZO_TributePatronData:GetPatronLargeIcon()
    return GetTributePatronLargeIcon(self.patronId)
end

function ZO_TributePatronData:GetPatronLargeRingIcon()
    return GetTributePatronLargeRingIcon(self.patronId)
end

function ZO_TributePatronData:GetLoreDescription()
    return GetTributePatronLoreDescription(self.patronId)
end

function ZO_TributePatronData:GetTributePatronPlayStyleDescription()
    return GetTributePatronPlayStyleDescription(self.patronId)
end

function ZO_TributePatronData:GetTributePatronAcquireHint()
    return zo_strformat(SI_TRIBUTE_ACQUIRE_HINT_FORMATTER, GetTributePatronAcquireHint(self.patronId))
end

function ZO_TributePatronData:GetUpgradeHintTextByIndex(cardIndex)
    return GetTributeCardUpgradeHintText(self.patronId, cardIndex)
end

function ZO_TributePatronData:GetNumRequirementsForFavorState(favorState)
    return GetNumTributePatronRequirementsForFavorState(self.patronId, favorState)
end

function ZO_TributePatronData:GetNumMechanicsForFavorState(favorState)
    return GetNumTributePatronMechanicsForFavorState(self.patronId, favorState)
end

function ZO_TributePatronData:GetNumPassiveMechanicsForFavorState(favorState)
    return GetNumTributePatronPassiveMechanicsForFavorState(self.patronId, favorState)
end

function ZO_TributePatronData:GetRequirementText(favorState, requirementIndex)
    return GetTributePatronRequirementText(self.patronId, favorState, requirementIndex)
end

function ZO_TributePatronData:GetRequirementInfo(favorState, requirementIndex)
    return GetTributePatronRequirementInfo(self.patronId, favorState, requirementIndex)
end

function ZO_TributePatronData:GetMechanicText(favorState, mechanicIndex, prependIcon)
    return GetTributePatronMechanicText(self.patronId, favorState, mechanicIndex, prependIcon)
end

function ZO_TributePatronData:GetMechanicInfo(favorState, mechanicIndex)
    return GetTributePatronMechanicInfo(self.patronId, favorState, mechanicIndex)
end

function ZO_TributePatronData:GetPassiveMechanicText(favorState, mechanicIndex, prependIcon)
    return GetTributePatronPassiveMechanicText(self.patronId, favorState, mechanicIndex, prependIcon)
end

function ZO_TributePatronData:GetPassiveMechanicInfo(favorState, mechanicIndex)
    return GetTributePatronPassiveMechanicInfo(self.patronId, favorState, mechanicIndex)
end

function ZO_TributePatronData:GetRequirementsText(favorState)
    return GetTributePatronRequirementsText(self.patronId, favorState)
end

function ZO_TributePatronData:GetMechanicsText(favorState)
    return GetTributePatronMechanicsText(self.patronId, favorState)
end

function ZO_TributePatronData:IsNew()
    local patronCollectibleId = self:GetPatronCollectibleId()
    return IsCollectibleNew(patronCollectibleId)
end

function ZO_TributePatronData:IsNeutral()
    return IsTributePatronNeutral(self.patronId)
end

function ZO_TributePatronData:GetFamily()
    return GetTributePatronFamily(self.patronId)
end

function ZO_TributePatronData:DoesSkipNeutralFavorState()
    return DoesTributePatronSkipNeutralFavorState(self.patronId)
end

function ZO_TributePatronData:SetSearchResultsVersion(searchResultsVersion)
    self.searchResultsVersion = searchResultsVersion
    if self.tributePatronCategoryData then
        self.tributePatronCategoryData:SetSearchResultsVersion(searchResultsVersion)
    end
end

function ZO_TributePatronData:IsSearchResult()
    if self.searchResultsVersion then
        if self.searchResultsVersion == TRIBUTE_DATA_MANAGER:GetSearchResultsVersion() then
            return true
        else
            -- Old search result, might as well clean it up while we're here
            self.searchResultsVersion = nil
        end
    end
    return false
end

-- Call this from the data manager when the player unlock data changes
function ZO_TributePatronData:MarkDockCardsDirty()
    self.dockCardsDirty = true
end

function ZO_TributePatronData.CompareTributeCards(leftCardTable, rightCardTable)
    local leftIsUpgraded = leftCardTable.upgradesFrom ~= nil
    local rightIsUpgraded = rightCardTable.upgradesFrom ~= nil
    if leftIsUpgraded == rightIsUpgraded then
        local leftIsUpgradeable = leftCardTable.upgradesTo ~= nil
        local rightIsUpgradeable = rightCardTable.upgradesTo ~= nil
        if leftIsUpgradeable == rightIsUpgradeable then
            local leftCardName = GetTributeCardName(leftCardTable.cardId)
            local rightCardName = GetTributeCardName(rightCardTable.cardId)
            return leftCardName < rightCardName
        elseif leftIsUpgradeable then
            return true
        else -- rightIsUpgradeable
            return false
        end
    elseif leftIsUpgraded then
        return true
    else -- rightIsUpgraded
        return false
    end
end

function ZO_TributePatronData:CompareTo(otherPatronData)
    return self:GetName() < otherPatronData:GetName()
end

-- Returns two tables, each numerically indexed and filled with entries with at least two fields: cardId and count
-- currentCards - The cards you will be play a match with. Entries might also have exactly one of these two additional fields
--      upgradesTo - This card is not upgraded, but can be upgraded to this id
--      upgradesFrom - This card is already upgraded, and this is the id of the base card it upgraded from
-- availableUpgradeCards - Upgrades you don't have but can still be acquired. Will always have one additional field
--      upgradesFrom - This is the id of the base card it will upgrade
function ZO_TributePatronData:GetDockCards()
    if self.dockCardsDirty then
        -- Build the data tables
        self.currentCards = {}
        self.availableUpgradeCards = {}
        for _, progressionData in ipairs(self.dockCardProgressions) do
            local cardIndex = progressionData:GetCardIndex()
            local baseCardId = progressionData:GetBaseCardId()
            local upgradeCardId = progressionData:GetUpgradeCardId()
            local quantity = progressionData:GetQuantity()
            local hasUpgrade = progressionData:HasUpgrade()
            if not upgradeCardId then
                local currentCardData =
                {
                    cardId = baseCardId,
                    cardIndex = cardIndex,
                    count = quantity,
                }
                table.insert(self.currentCards, currentCardData)
            else
                if hasUpgrade then
                    local currentCardData =
                    {
                        cardId = upgradeCardId,
                        upgradesFrom = baseCardId,
                        cardIndex = cardIndex,
                        count = quantity,
                        hasUpgrade = hasUpgrade,
                    }
                    table.insert(self.currentCards, currentCardData)
                else
                    local currentCardData =
                    {
                        cardId = baseCardId,
                        upgradesTo = upgradeCardId,
                        cardIndex = cardIndex,
                        count = quantity,
                        hasUpgrade = hasUpgrade,
                    }
                    table.insert(self.currentCards, currentCardData)

                    local upgradeCardData =
                    {
                        cardId = upgradeCardId,
                        upgradesFrom = baseCardId,
                        cardIndex = cardIndex,
                        count = quantity,
                        hasUpgrade = hasUpgrade,
                    }
                    table.insert(self.availableUpgradeCards, upgradeCardData)
                end
            end
        end
        self.dockCardsDirty = false
    end

    table.sort(self.currentCards, ZO_TributePatronData.CompareTributeCards)
    table.sort(self.availableUpgradeCards, ZO_TributePatronData.CompareTributeCards)

    return self.currentCards, self.availableUpgradeCards
end

----------------------------------
-- Tribute Patron Category Data --
----------------------------------

ZO_TributePatronCategoryData = ZO_InitializingObject:Subclass()

function ZO_TributePatronCategoryData:Initialize(categoryId)
    self.categoryId = categoryId
    self.tributePatrons = {}
end

function ZO_TributePatronCategoryData:AddTributePatronData(tributePatronData)
    table.insert(self.tributePatrons, tributePatronData)
end

function ZO_TributePatronCategoryData:SortTributePatronData()
    table.sort(self.tributePatrons, ZO_TributePatronData.CompareTo)
end

function ZO_TributePatronCategoryData:GetId()
    return self.categoryId
end

function ZO_TributePatronCategoryData:GetName()
    return GetTributePatronCategoryName(self.categoryId)
end

function ZO_TributePatronCategoryData:GetFormattedName()
    return ZO_CachedStrFormat(SI_TRIBUTE_PATRON_CATEGORY_NAME_FORMATTER, self:GetName())
end

function ZO_TributePatronCategoryData:GetKeyboardIcons()
    return GetTributePatronCategoryKeyboardIcons(self.categoryId)
end

function ZO_TributePatronCategoryData:GetGamepadIcon()
    return GetTributePatronCategoryGamepadIcon(self.categoryId)
end

function ZO_TributePatronCategoryData:GetOrder()
    return GetTributePatronCategorySortOrder(self.categoryId)
end

function ZO_TributePatronCategoryData:GetNumPatrons()
    return #self.tributePatrons
end

function ZO_TributePatronCategoryData:PatronIterator(filterFunctions)
    return ZO_FilteredNumericallyIndexedTableIterator(self.tributePatrons, filterFunctions)
end

function ZO_TributePatronCategoryData:HasAnyNewPatronCollectibles()
    for _, tributePatron in self:PatronIterator({ZO_TributePatronData.IsNew}) do
        return true
    end
    return false
end

function ZO_TributePatronCategoryData:SetSearchResultsVersion(searchResultsVersion)
    self.searchResultsVersion = searchResultsVersion
end

function ZO_TributePatronCategoryData:IsSearchResult()
    if self.searchResultsVersion then
        if self.searchResultsVersion == TRIBUTE_DATA_MANAGER:GetSearchResultsVersion() then
            return true
        else
            -- Old search result, might as well clean it up while we're here
            self.searchResultsVersion = nil
        end
    end
    return false
end

function ZO_TributePatronCategoryData:CompareTo(otherTributePatronCategoryData)
    local order = self:GetOrder()
    local otherOrder = otherTributePatronCategoryData:GetOrder()
    if order == otherOrder then
        return self:GetName() < otherTributePatronCategoryData:GetName()
    else
        return order < otherOrder
    end
end

function ZO_TributePatronCategoryData:Equals(otherTributePatronCategoryData)
    return self:GetId() == otherTributePatronCategoryData:GetId()
end

-----------------------
-- Tribute Card Data --
-----------------------

ZO_TributeCardData = ZO_InitializingObject:Subclass()

function ZO_TributeCardData:Initialize(patronDefId, cardDefId)
    self.numMechanicsByActivationSource = {}
    if cardDefId and patronDefId then
        self:Setup(patronDefId, cardDefId)
    end
end

function ZO_TributeCardData:Setup(patronDefId, cardDefId)
    self.cardDefId = cardDefId
    self.patronDefId = patronDefId

    ZO_ClearTable(self.numMechanicsByActivationSource)

    for activationSource = TRIBUTE_MECHANIC_ACTIVATION_SOURCE_ITERATION_BEGIN, TRIBUTE_MECHANIC_ACTIVATION_SOURCE_ITERATION_END do
        self.numMechanicsByActivationSource[activationSource] = GetNumTributeCardMechanics(self.cardDefId, activationSource)
    end
end

function ZO_TributeCardData:GetCardDefId()
    return self.cardDefId
end

function ZO_TributeCardData:GetPatronDefId()
    return self.patronDefId
end

function ZO_TributeCardData:GetPatronData()
    return TRIBUTE_DATA_MANAGER:GetTributePatronData(self.patronDefId)
end

function ZO_TributeCardData:GetName()
    return GetTributeCardName(self.cardDefId)
end

function ZO_TributeCardData:GetFormattedName()
    return ZO_CachedStrFormat(SI_TRIBUTE_CARD_NAME_FORMATTER, self:GetName())
end

function ZO_TributeCardData:GetAcquireCost()
    local resourceType, quantity = GetTributeCardAcquireCost(self.cardDefId)
    return resourceType, quantity
end

function ZO_TributeCardData:DoesTaunt()
    return DoesTributeCardTaunt(self.cardDefId)
end

function ZO_TributeCardData:GetCardType()
    return GetTributeCardType(self.cardDefId)
end

function ZO_TributeCardData:IsContract()
    return IsTributeCardContract(self.cardDefId)
end

function ZO_TributeCardData:IsCurse()
    return IsTributeCardCurse(self.cardDefId)
end

function ZO_TributeCardData:DoesChooseOneMechanic()
    return DoesTributeCardChooseOneMechanic(self.cardDefId)
end

function ZO_TributeCardData:DoesHaveTriggerMechanic()
    return DoesTributeCardHaveTriggerMechanic(self.cardDefId)
end

function ZO_TributeCardData:GetDefeatCost()
    return GetTributeCardDefeatCost(self.cardDefId)
end

function ZO_TributeCardData:GetRarity()
    return GetTributeCardRarity(self.cardDefId)
end

function ZO_TributeCardData:GetColorizedName()
    local qualityColor = GetItemQualityColor(self:GetRarity())
    return qualityColor:Colorize(self:GetName())
end

function ZO_TributeCardData:GetColorizedFormattedName()
    local qualityColor = GetItemQualityColor(self:GetRarity())
    return qualityColor:Colorize(self:GetFormattedName())
end

function ZO_TributeCardData:GetNumMechanics(activationSource)
    return self.numMechanicsByActivationSource[activationSource] or 0
end

function ZO_TributeCardData:GetMechanicInfo(activationSource, mechanicIndex)
    return GetTributeCardMechanicInfo(self.cardDefId, activationSource, mechanicIndex)
end

function ZO_TributeCardData:GetMechanicText(activationSource, mechanicIndex, prependIcon)
    return GetTributeCardMechanicText(self.cardDefId, activationSource, mechanicIndex, prependIcon)
end

function ZO_TributeCardData:GetFlavorText()
    return GetTributeCardFlavorText(self.cardDefId)
end

function ZO_TributeCardData:GetAcquireCostTextureFile(showContract)
    local costResourceType, costQuantity = self:GetAcquireCost()
    if showContract then
        return string.format("EsoUI/Art/Tribute/tributeCardCost_Contract_%d.dds", costResourceType)
    else
        return string.format("EsoUI/Art/Tribute/tributeCardCost_%d.dds", costResourceType)
    end
end

function ZO_TributeCardData:GetDefeatCostTextureFile()
    local textureFile = nil
    if self:GetCardType() == TRIBUTE_CARD_TYPE_AGENT then
        local doesTaunt = self:DoesTaunt()
        textureFile = doesTaunt and "EsoUI/Art/Tribute/tributeCardDefeatBanner_Taunt.dds" or "EsoUI/Art/Tribute/tributeCardDefeatBanner_Health.dds"
    end
    return textureFile
end

function ZO_TributeCardData:GetPortrait()
    local portraitImage, portraitGlowImage = GetTributeCardPortrait(self.cardDefId)
    return portraitImage, portraitGlowImage
end

function ZO_TributeCardData:GetPortraitIcon()
    local portraitIcon = GetTributeCardPortraitIcon(self.cardDefId)
    return portraitIcon 
end