ZO_TributePatronBook_Shared = ZO_InitializingObject:Subclass()

function ZO_TributePatronBook_Shared:Initialize(control, infoContainerControl, templateData)
    self.control = control
    self.templateData = templateData
    self.infoContainerControl = infoContainerControl

    self.starterCardIdCounts = {}
    self.starterUniqueCardIds = {}
    self.dockCardIdCounts = {}
    self.currentDockCards = {}

    self.categoryFilters = {}

    self.scene = scene or ZO_Scene:New(self:GetSceneName(), SCENE_MANAGER)
    self.fragment = ZO_FadeSceneFragment:New(control)
    self.fragment:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
            self.categoriesRefreshGroup:TryClean()
            self:OnFragmentShowing()
        end
    end)

    self:InitializeControls()
    self:InitializeCategories()
    self:InitializeGridList()

    self:RegisterForEvents()
end

ZO_TributePatronBook_Shared.GetSceneName = ZO_TributePatronBook_Shared:MUST_IMPLEMENT()

function ZO_TributePatronBook_Shared:GetScene()
    return self.scene
end

function ZO_TributePatronBook_Shared:GetFragment()
    return self.fragment
end

function ZO_TributePatronBook_Shared:InitializeControls()
    -- Can be overridden
end

function ZO_TributePatronBook_Shared:InitializeCategories()
    -- Categories refresh group
    local categoriesRefreshGroup = ZO_OrderedRefreshGroup:New(ZO_ORDERED_REFRESH_GROUP_AUTO_CLEAN_PER_FRAME)
    categoriesRefreshGroup:AddDirtyState("List", function()
        self:RefreshCategories()
    end)
    categoriesRefreshGroup:AddDirtyState("Visible", function()
        self:RefreshVisibleCategories()
    end)
    categoriesRefreshGroup:SetActive(function()
        return self:IsCategoriesRefreshGroupActive()
    end)
    categoriesRefreshGroup:MarkDirty("List")
    self.categoriesRefreshGroup = categoriesRefreshGroup
end

function ZO_TributePatronBook_Shared:InitializeGridList()
    -- Initialize grid list object
    local templateData = self.templateData
    local gridListControl = self.infoContainerControl:GetNamedChild("GridList")
    self.gridListControl = gridListControl
    self.gridList = self.templateData.gridListClass:New(gridListControl)

    local function GetDescriptionHeight(instanceData)
        return instanceData.height
    end

    local function DescriptionEntrySetup(control, instanceData, list)
        control:SetText(instanceData.text)
    end

    local HIDE_CALLBACK = nil
    local NO_FUNCTION = nil
    local DONT_CENTER = false
    local NOT_SELECTABLE = false
    local headerEntryData = templateData.headerEntryData
    local descriptionEntryData = templateData.descriptionEntryData
    local patronEntryData = templateData.patronEntryData
    local widePatronEntryData = templateData.widePatronEntryData
    local cardEntryData = templateData.cardEntryData
    local wideCardEntryData = templateData.wideCardEntryData

    self.gridList:AddHeaderTemplate(headerEntryData.entryTemplate, headerEntryData.height, ZO_DefaultGridTileHeaderSetup)
    self.gridList:SetHeaderPrePadding(headerEntryData.gridPaddingY)
    self.gridList:AddEntryTemplate(descriptionEntryData.entryTemplate, descriptionEntryData.width, GetDescriptionHeight, DescriptionEntrySetup, HIDE_CALLBACK, NO_FUNCTION, descriptionEntryData.gridPaddingX, descriptionEntryData.gridPaddingY, DONT_CENTER, NOT_SELECTABLE)

    self.gridList:AddEntryTemplate(patronEntryData.entryTemplate, patronEntryData.width, patronEntryData.height, ZO_DefaultGridTileEntrySetup, HIDE_CALLBACK, ZO_DefaultGridTileEntryReset, patronEntryData.gridPaddingX, patronEntryData.gridPaddingY)
    self.gridList:AddEntryTemplate(cardEntryData.entryTemplate, cardEntryData.width, cardEntryData.height, ZO_DefaultGridTileEntrySetup, HIDE_CALLBACK, ZO_DefaultGridTileEntryReset, cardEntryData.gridPaddingX, cardEntryData.gridPaddingY)
    if widePatronEntryData and wideCardEntryData then
        self.gridList:AddEntryTemplate(widePatronEntryData.entryTemplate, widePatronEntryData.width, widePatronEntryData.height, ZO_DefaultGridTileEntrySetup, HIDE_CALLBACK, ZO_DefaultGridTileEntryReset, widePatronEntryData.gridPaddingX, widePatronEntryData.gridPaddingY)
        self.gridList:AddEntryTemplate(wideCardEntryData.entryTemplate, wideCardEntryData.width, wideCardEntryData.height, ZO_DefaultGridTileEntrySetup, HIDE_CALLBACK, ZO_DefaultGridTileEntryReset, wideCardEntryData.gridPaddingX, wideCardEntryData.gridPaddingY)
    end
end

function ZO_TributePatronBook_Shared:RegisterForEvents()
    local function OnProgressionUpgradeStatusChanged(patronId)
        if patronId == self.patronId then
            self:BuildGridList()
        end
    end

    local function OnPatronsUpdated()
        if self:IsCategoriesRefreshGroupActive() and self.patronId ~= nil then
            self:BuildGridList()
        end
    end

    local function OnPatronsDataDirty()
        self.categoriesRefreshGroup:MarkDirty("List")
    end

    local function OnCollectibleUpdated(collectibleId)
        local categoryType = GetCollectibleCategoryType(collectibleId)
        if categoryType == COLLECTIBLE_CATEGORY_TYPE_TRIBUTE_PATRON then
            OnPatronsDataDirty()
        end
    end

    local function OnCollectionUpdated(collectibleUpdateType, collectiblesByNewUnlockState)
        for _, unlockState in pairs(collectiblesByNewUnlockState) do
            for _, collectible in pairs(unlockState) do
                local categoryType = GetCollectibleCategoryType(collectible.collectibleId)
                if categoryType == COLLECTIBLE_CATEGORY_TYPE_TRIBUTE_PATRON then
                    OnPatronsDataDirty()
                    return
                end
            end
        end
    end

    TRIBUTE_DATA_MANAGER:RegisterCallback("PatronsUpdated", OnPatronsUpdated)
    TRIBUTE_DATA_MANAGER:RegisterCallback("PatronsDataDirty", OnPatronsDataDirty)
    TRIBUTE_DATA_MANAGER:RegisterCallback("ProgressionUpgradeStatusChanged", OnProgressionUpgradeStatusChanged)
    TRIBUTE_DATA_MANAGER:RegisterCallback("UpdateSearchResults", function() self:OnUpdateSearchResults() end)
    ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("OnCollectibleUpdated", OnCollectibleUpdated)
    ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("OnCollectionUpdated", OnCollectionUpdated)
    ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("OnCollectibleNewStatusCleared", OnCollectibleUpdated)
end

ZO_TributePatronBook_Shared.BuildGridList = ZO_TributePatronBook_Shared:MUST_IMPLEMENT()

function ZO_TributePatronBook_Shared.CompareTributeStarterCards(leftCardId, rightCardId)
    local leftCardName = GetTributeCardName(leftCardId)
    local rightCardName = GetTributeCardName(rightCardId)
    return leftCardName < rightCardName
end

function ZO_TributePatronBook_Shared.CompareTributeCards(leftCardTable, rightCardTable)
    local leftBaseCardId = leftCardTable.baseCardId
    local rightBaseCardId = rightCardTable.baseCardId

    -- TODO Tribute: Update compare function to take upgrade status of cards for this player into account
    if leftBaseCardId == rightBaseCardId then
        local leftUpgradeCardId = leftCardTable.upgradeCardId
        local rightUpgradeCardId = rightCardTable.upgradeCardId

        local leftCardName = GetTributeCardName(leftUpgradeCardId)
        local rightCardName = GetTributeCardName(rightUpgradeCardId)
        return leftCardName < rightCardName
    else
        local leftCardName = GetTributeCardName(leftBaseCardId)
        local rightCardName = GetTributeCardName(rightBaseCardId)
        return leftCardName < rightCardName
    end
end

function ZO_TributePatronBook_Shared:SetupStarterCards()
    local patronData = TRIBUTE_DATA_MANAGER:GetTributePatronData(self.patronId)
    local numStarterCards = patronData:GetNumStarterCards()

    self.starterCardIdCounts = {}
    self.starterUniqueCardIds = {}
    for index = 1, numStarterCards do
        local cardId = patronData:GetStarterCardIdByIndex(index)
        if not self.starterCardIdCounts[cardId] then
            self.starterCardIdCounts[cardId] = 1
            table.insert(self.starterUniqueCardIds, cardId)
        else
            self.starterCardIdCounts[cardId] = self.starterCardIdCounts[cardId] + 1
        end
    end

    table.sort(self.starterUniqueCardIds, ZO_TributePatronBook_Shared.CompareTributeStarterCards)
end

function ZO_TributePatronBook_Shared:SetupDockCards()
    local patronData = TRIBUTE_DATA_MANAGER:GetTributePatronData(self.patronId)
    self.currentDockCards, self.availableUpgradeCards = patronData:GetDockCards()
end

function ZO_TributePatronBook_Shared:AddDescriptionEntry()
    local patronData = TRIBUTE_DATA_MANAGER:GetTributePatronData(self.patronId)
    local loreDescription = patronData:GetLoreDescription()
    local playStyleDescription = patronData:GetTributePatronPlayStyleDescription()
    local acquireHint = patronData:GetTributePatronAcquireHint()

    local displayText = loreDescription
    if  playStyleDescription ~= "" then
        if displayText ~= "" then
            displayText = string.format("%s\n\n%s", displayText, playStyleDescription)
        else
            displayText = playStyleDescription
        end
    end
    if patronData:IsPatronLocked() and acquireHint ~= "" then
        if displayText ~= "" then
            displayText = string.format("%s\n\n%s", displayText, acquireHint)
        else
            displayText = acquireHint
        end
    end

    self.setupLabel:SetText(displayText)

    local data =
    {
        height = self.setupLabel:GetHeight(),
        text = displayText,
    }
    self.gridList:AddEntry(data, self.templateData.descriptionEntryData.entryTemplate)
end

function ZO_TributePatronBook_Shared:AddPatronEntry()
    local patronData = TRIBUTE_DATA_MANAGER:GetTributePatronData(self.patronId)

    local entryData = ZO_EntryData:New(patronData)
    entryData.gridHeaderName = GetString(SI_TRIBUTE_PATRON_TITLE)
    entryData.gridHeaderTemplate = self.templateData.headerEntryData.entryTemplate

    local patronEntryTemplate = self.templateData.patronEntryData.entryTemplate
    if self.templateData.widePatronEntryData and #self.starterUniqueCardIds <= 1 then
        patronEntryTemplate = self.templateData.widePatronEntryData.entryTemplate
    end
    self.gridList:AddEntry(entryData, patronEntryTemplate)
end

function ZO_TributePatronBook_Shared:AddStarterCardEntries()
    local cardTemplateData = self.templateData.cardEntryData

    if self.templateData.wideCardEntryData and #self.starterUniqueCardIds <= 1 then
        cardTemplateData = self.templateData.wideCardEntryData
    end

    for index, cardId in ipairs(self.starterUniqueCardIds) do
        local cardData =
        {
            cardId = cardId,
            count = self.starterCardIdCounts[cardId],
            isStarter = true
        }
        self:AddCardEntryById(cardData, cardTemplateData, GetString(SI_TRIBUTE_PATRON_TITLE), self.templateData.wideCardEntryData and #self.starterUniqueCardIds <= 1)
    end
end

function ZO_TributePatronBook_Shared:AddDockCardEntries()
    local NOT_WIDE = false
    local cardTemplateData = self.templateData.cardEntryData

    for index, cardData in ipairs(self.currentDockCards) do
        self:AddCardEntryById(cardData, cardTemplateData, GetString(SI_TRIBUTE_PATRON_CARD_TITLE), NOT_WIDE)
    end
end

function ZO_TributePatronBook_Shared:AddCardUpgradeEntries()
    local NOT_WIDE = false
    local cardTemplateData = self.templateData.cardEntryData

    for index, cardData in ipairs(self.availableUpgradeCards) do
        self:AddCardEntryById(cardData, cardTemplateData, GetString(SI_TRIBUTE_PATRON_UPGRADE_TITLE), NOT_WIDE)
    end
end

function ZO_TributePatronBook_Shared:AddCardEntryById(cardData, cardTemplateData, header, isWide)
    local entryData = ZO_EntryData:New(cardData)
    entryData.gridHeaderName = header
    entryData.gridHeaderTemplate = self.templateData.headerEntryData.entryTemplate
    entryData.patronId = self.patronId
    entryData.cardTemplateData = cardTemplateData
    entryData.isWide = isWide

    self.gridList:AddEntry(entryData, cardTemplateData.entryTemplate)
end

function ZO_TributePatronBook_Shared:OnFragmentShowing()
    -- Can be overridden
end

function ZO_TributePatronBook_Shared:OnUpdateSearchResults()
    self:RefreshFilters()
end

function ZO_TributePatronBook_Shared:RefreshFilters()
    ZO_ClearNumericallyIndexedTable(self.categoryFilters)

    if self:IsSearchSupported() and TRIBUTE_DATA_MANAGER:HasSearchFilter() then
        table.insert(self.categoryFilters, ZO_TributePatronData.IsSearchResult)
    end

    self.categoriesRefreshGroup:MarkDirty("List")
end


function ZO_TributePatronBook_Shared:IsCategoriesRefreshGroupActive()
    return self.fragment:IsShowing()
end

function ZO_TributePatronBook_Shared:GetSelectedCategory()
    assert(false) -- Must be overridden
end

function ZO_TributePatronBook_Shared:IsSearchSupported()
    -- Can be overridden
    return false
end

function ZO_TributePatronBook_Shared:IsViewingCategory(tributePatronCategoryData)
    local categoryData = self:GetSelectedCategory()
    return categoryData and categoryData:GetId() == tributePatronCategoryData:GetId()
end

-- Do not call this directly, instead call self.categoriesRefreshGroup:MarkDirty("List")
function ZO_TributePatronBook_Shared:RefreshCategories()
    assert(false) -- Must be overridden
end

-- Do not call this directly, instead call self.categoriesRefreshGroup:MarkDirty("Visible")
function ZO_TributePatronBook_Shared:RefreshVisibleCategories()
    assert(false) -- Must be overridden
end