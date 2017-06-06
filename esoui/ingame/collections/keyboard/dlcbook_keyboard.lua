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

function DLCBook_Keyboard:SetupAdditionalCollectibleData(data)
    data.categoryIndex, data.subcategoryIndex = GetCategoryInfoFromCollectibleId(data.collectibleId)
    data.unlockedViaSubscription = DoesESOPlusUnlockCollectible(data.collectibleId)
    data.requiresEntitlement = DoesCollectibleRequireEntitlement(data.collectibleId)
end

do
    local function StorySort(entry1, entry2)
        if entry1.categoryIndex ~= entry2.categoryIndex then
            return entry1.categoryIndex < entry2.categoryIndex
        elseif entry1.subcategoryIndex ~= entry2.subcategoryIndex then
            return entry1.subcategoryIndex < entry2.subcategoryIndex
        elseif entry1.sortOrder ~= entry2.sortOrder then
            return entry1.sortOrder < entry2.sortOrder
        else
            return entry1.name < entry2.name
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
    local currentCategoryIndex
    local currentSubcategoryIndex
    local currentList

    --We presorted by category above to make this part easier
    for _, data in ipairs(collectiblesData) do
        -- Everything should be put into a subcategory, since we don't handle categories and subcategories elegantly in this scene
        if data.categoryIndex and data.subcategoryIndex then
            if currentCategoryIndex ~= data.categoryIndex or currentSubcategoryIndex ~= data.subcategoryIndex then
                currentCategoryIndex = data.categoryIndex
                currentSubcategoryIndex = data.subcategoryIndex
                currentList = {}
                table.insert(lists, 
                { 
                    name = GetCollectibleSubCategoryInfo(currentCategoryIndex, currentSubcategoryIndex),
                    collectibles = currentList,
                })
            end

            table.insert(currentList, data)
        end
    end

    return lists
end

function DLCBook_Keyboard:RefreshDetails()
    ZO_SpecializedCollectionsBook_Keyboard.RefreshDetails(self)

    local data = self.navigationTree:GetSelectedData()

    if data then
        self.unlockStatusControl:SetText(GetString("SI_COLLECTIBLEUNLOCKSTATE", data.unlockState))

        local questAcceptLabelStringId = data.active and SI_DLC_BOOK_QUEST_STATUS_ACCEPTED or SI_DLC_BOOK_QUEST_STATUS_NOT_ACCEPTED
        local questName = GetCollectibleQuestPreviewInfo(data.collectibleId)
        self.questStatusControl:SetText(zo_strformat(SI_DLC_BOOK_QUEST_STATUS, questName, GetString(questAcceptLabelStringId)))

        local showsQuest = not (data.active or data.unlockState == COLLECTIBLE_UNLOCK_STATE_LOCKED)
        local questAvailableControl = self.questAvailableControl
        local questDescriptionControl = self.questDescriptionControl
        local canUnlockOnStore = data.unlockState ~= COLLECTIBLE_UNLOCK_STATE_UNLOCKED_OWNED and data.purchasable
        local canUnlockWithSubscription = not IsESOPlusSubscriber() and data.unlockedViaSubscription
        local canUpgrade = data.unlockState ~= COLLECTIBLE_UNLOCK_STATE_UNLOCKED_OWNED and data.requiresEntitlement
        if showsQuest then
            questAvailableControl:SetText(GetString(SI_COLLECTIONS_QUEST_AVAILABLE))
            questAvailableControl:SetHidden(false)
            
            local questDescription = select(2, GetCollectibleQuestPreviewInfo(data.collectibleId))
            questDescriptionControl:SetText(questDescription)
            questDescriptionControl:SetHidden(false)
        elseif data.unlockState == COLLECTIBLE_UNLOCK_STATE_LOCKED then
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

        local questAcceptButtonStringId = data.active and SI_DLC_BOOK_ACTION_QUEST_ACCEPTED or SI_DLC_BOOK_ACTION_ACCEPT_QUEST
        self.questAcceptButton:SetText(GetString(questAcceptButtonStringId))
        self.questAcceptButton:SetEnabled(data.unlockState ~= COLLECTIBLE_UNLOCK_STATE_LOCKED and not data.active)
        self.unlockPermanentlyButton:SetHidden(not canUnlockOnStore)
        self.subscribeButton:SetHidden(not canUnlockWithSubscription)
        self.chapterUpgrade:SetHidden(not canUpgrade)
    end
end

function DLCBook_Keyboard:UseSelectedDLC()
    local data = self.navigationTree:GetSelectedData()
    UseCollectible(data.collectibleId)
end

function DLCBook_Keyboard:SearchSelectedDLCInStore()
    local data = self.navigationTree:GetSelectedData()
    local searchTerm = zo_strformat(SI_CROWN_STORE_SEARCH_FORMAT_STRING, data.name)
    ShowMarketAndSearch(searchTerm, MARKET_OPEN_OPERATION_COLLECTIONS_DLC)
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