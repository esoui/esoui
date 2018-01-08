------------------
--Initialization--
------------------

local DLCBook_Keyboard = ZO_SpecializedCollectionsBook_Keyboard:Subclass()

function DLCBook_Keyboard:New(...)
    return ZO_SpecializedCollectionsBook_Keyboard.New(self, ...)
end

function DLCBook_Keyboard:InitializeControls()
    ZO_SpecializedCollectionsBook_Keyboard.InitializeControls(self)
    local contents = self.control:GetNamedChild("Contents")
    local scrollSection = contents:GetNamedChild("ScrollContainer"):GetNamedChild("ScrollChild")
    self.unlockStatusControl = scrollSection:GetNamedChild("UnlockStatusLabel")
    self.questStatusControl = scrollSection:GetNamedChild("QuestStatusLabel")
    self.questAvailableControl = scrollSection:GetNamedChild("QuestAvailable")
    self.questDescriptionControl = scrollSection:GetNamedChild("QuestDescription")

    local buttons = contents:GetNamedChild("DLCInteractButtons")
    self.questAcceptButton = buttons:GetNamedChild("QuestAccept")
    self.unlockPermanentlyButton = buttons:GetNamedChild("UnlockPermanently")
    self.chapterUpgrade = buttons:GetNamedChild("ChapterUpgrade")

    self.subscribeButton = contents:GetNamedChild("SubscribeButton")
end

---------------
--Interaction--
---------------

do
    local function StorySort(entry1, entry2)
        local category1Data = entry1:GetCategoryData()
        local category2Data = entry2:GetCategoryData()

        if category1Data ~= category2Data then
            local categoryIndex1, subcategoryIndex1 = category1Data:GetCategoryIndicies()
            local categoryIndex2, subcategoryIndex2 = category2Data:GetCategoryIndicies()

            if categoryIndex1 ~= categoryIndex2 then
                return categoryIndex1 < categoryIndex2
            else
                return subcategoryIndex1 < subcategoryIndex2
            end
        elseif entry1:GetSortOrder() ~= entry2:GetSortOrder() then
            return entry1:GetSortOrder() < entry2:GetSortOrder()
        else
            return entry1:GetName() < entry2:GetName()
        end
    end

    function DLCBook_Keyboard:SortCollectibleData(collectibleData)
        table.sort(collectibleData, StorySort)
    end
end

function DLCBook_Keyboard:GetCategorizedLists()
    local collectiblesData = self:GetRelevantCollectibles()

    local categoryMapping = {}

    local lists = {}
    local currentCategoryData
    local currentList

    --We presorted by category above to make this part easier
    for _, data in ipairs(collectiblesData) do
        -- Everything should be put into a subcategory, since we don't handle categories and subcategories elegantly in this scene
        local categoryData = data:GetCategoryData()
        if currentCategoryData ~= categoryData then
            currentCategoryData = categoryData
            currentList = {}
            table.insert(lists, 
            { 
                name = categoryData:GetName(),
                collectibles = currentList,
            })
        end

        table.insert(currentList, data)
    end

    return lists
end

function DLCBook_Keyboard:RefreshDetails()
    ZO_SpecializedCollectionsBook_Keyboard.RefreshDetails(self)

    local collectibleData = self.navigationTree:GetSelectedData()

    if collectibleData then
        self.unlockStatusControl:SetText(GetString("SI_COLLECTIBLEUNLOCKSTATE", collectibleData:GetUnlockState()))

        local isLocked = collectibleData:IsLocked()
        local isActive = collectibleData:IsActive()
        local isNotOwned = not collectibleData:IsOwned()

        local questAcceptLabelStringId = isActive and SI_DLC_BOOK_QUEST_STATUS_ACCEPTED or SI_DLC_BOOK_QUEST_STATUS_NOT_ACCEPTED
        local questName = collectibleData:GetQuestName()
        self.questStatusControl:SetText(zo_strformat(SI_DLC_BOOK_QUEST_STATUS, questName, GetString(questAcceptLabelStringId)))

        local showsQuest = not (isActive or isLocked)
        local questAvailableControl = self.questAvailableControl
        local questDescriptionControl = self.questDescriptionControl
        local canUnlockOnStore = isNotOwned and collectibleData:IsPurchasable()
        local canUnlockWithSubscription = not IsESOPlusSubscriber() and collectibleData:IsUnlockedViaSubscription()
        local canUpgrade = isNotOwned and collectibleData:RequiresEntitlement()
        if showsQuest then
            questAvailableControl:SetText(GetString(SI_COLLECTIONS_QUEST_AVAILABLE))
            questAvailableControl:SetHidden(false)
            
            questDescriptionControl:SetText(collectibleData:GetQuestDescription())
            questDescriptionControl:SetHidden(false)
        elseif isLocked then
            if canUnlockOnStore or canUnlockWithSubscription or canUpgrade then
                local acquireText = canUpgrade and GetString(SI_COLLECTIONS_QUEST_AVAILABLE_WITH_UPGRADE) or GetString(SI_COLLECTIONS_QUEST_AVAILABLE_WITH_UNLOCK)
                questAvailableControl:SetText(acquireText)
                questAvailableControl:SetHidden(false)
            else
                questAvailableControl:SetHidden(true)
            end
            questDescriptionControl:SetHidden(true)
        else
            questAvailableControl:SetHidden(true)
            questDescriptionControl:SetHidden(true)
        end

        local questAcceptButtonStringId = isActive and SI_DLC_BOOK_ACTION_QUEST_ACCEPTED or SI_DLC_BOOK_ACTION_ACCEPT_QUEST
        self.questAcceptButton:SetText(GetString(questAcceptButtonStringId))
        self.questAcceptButton:SetEnabled(not (isLocked or isActive))
        self.unlockPermanentlyButton:SetHidden(not canUnlockOnStore)
        self.subscribeButton:SetHidden(not canUnlockWithSubscription)
        self.chapterUpgrade:SetHidden(not canUpgrade)
    end
end

function DLCBook_Keyboard:UseSelectedDLC()
    local collectibleData = self.navigationTree:GetSelectedData()
    UseCollectible(collectibleData:GetId())
end

function DLCBook_Keyboard:SearchSelectedDLCInStore()
    local collectibleData = self.navigationTree:GetSelectedData()
    local searchTerm = zo_strformat(SI_CROWN_STORE_SEARCH_FORMAT_STRING, collectibleData:GetName())
    ShowMarketAndSearch(searchTerm, MARKET_OPEN_OPERATION_COLLECTIONS_DLC)
end

function DLCBook_Keyboard:OnSceneShown()
    ZO_SpecializedCollectionsBook_Keyboard.OnSceneShown(self)
    if IsESOPlusSubscriber() then
        TriggerTutorial(TUTORIAL_TRIGGER_COLLECTIONS_DLC_OPENED_AS_SUBSCRIBER)
    end
end

----------
--Events--
----------

function ZO_DLCBook_Keyboard_OnQuestAcceptClicked(control)
    DLC_BOOK_KEYBOARD:UseSelectedDLC()
end

function ZO_DLCBook_Keyboard_OnUnlockPermanentlyClicked(control)
    DLC_BOOK_KEYBOARD:SearchSelectedDLCInStore()
end

function ZO_DLCBook_Keyboard_OnSubscribeClicked(control)
    ZO_Dialogs_ShowDialog("CONFIRM_OPEN_URL_BY_TYPE", { urlType = APPROVED_URL_ESO_ACCOUNT_SUBSCRIPTION }, { mainTextParams = { GetString(SI_ESO_PLUS_SUBSCRIPTION_LINK_TEXT), GetString(SI_URL_APPLICATION_WEB) } })
end

function ZO_DLCBook_Keyboard_OnChapterUpgradeClicked(control)
    ZO_Dialogs_ShowDialog("CHAPTER_UPGRADE_STORE")
end

function ZO_DLCBook_Keyboard_OnInitialize(control)
    DLC_BOOK_KEYBOARD = DLCBook_Keyboard:New(control, "dlcBook", COLLECTIBLE_CATEGORY_TYPE_CHAPTER, COLLECTIBLE_CATEGORY_TYPE_DLC)
end