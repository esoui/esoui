local NOTIFICATIONS_PROVIDER = NOTIFICATIONS:GetCollectionsProvider()

------------------
--Initialization--
------------------

local DLCBook_Keyboard = ZO_Object:Subclass()

function DLCBook_Keyboard:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function DLCBook_Keyboard:Initialize(control)
    control.owner = self
    self.control = control

    self:InitializeControls()
    self:InitializeNavigationList()
    self:InitializeEvents()

    local dlcBook = ZO_Scene:New("dlcBook", SCENE_MANAGER)

    dlcBook:RegisterCallback("StateChange", function(oldState, newState)
                                                if (newState == SCENE_SHOWN) then
                                                    self:RefreshListIfDirty()
                                                end
                                            end)
end

function DLCBook_Keyboard:InitializeControls()
    self.navigationList = self.control:GetNamedChild("NavigationList")

    local contents = self.control:GetNamedChild("Contents")
    self.imageControl = contents:GetNamedChild("Image")
    self.nameControl = contents:GetNamedChild("Name")

    local scrollSection = contents:GetNamedChild("ScrollContainer"):GetNamedChild("ScrollChild")
    self.descriptionControl = scrollSection:GetNamedChild("Description")
    self.unlockStatusControl = scrollSection:GetNamedChild("UnlockStatusLabel")
    self.questStatusControl = scrollSection:GetNamedChild("QuestStatusLabel")
    self.questAvailableControl = scrollSection:GetNamedChild("QuestAvailable")
    self.questDescriptionControl = scrollSection:GetNamedChild("QuestDescription")

    local buttons = contents:GetNamedChild("DLCInteractButtons")
    self.questAcceptButton = buttons:GetNamedChild("QuestAccept")
    self.unlockPermanentlyButton = buttons:GetNamedChild("UnlockPermanently")

    self.subscribeButton = contents:GetNamedChild("SubscribeButton")
    self.subscribeButton:SetHidden(IsESOPlusSubscriber())
end

function DLCBook_Keyboard:InitializeNavigationList()
    self.navigationTree = ZO_Tree:New(self.navigationList:GetNamedChild("ScrollChild"), 60, -10, 300)

    local openTexture = "EsoUI/Art/Buttons/tree_open_up.dds"
    local closedTexture = "EsoUI/Art/Buttons/tree_closed_up.dds"
    local overOpenTexture = "EsoUI/Art/Buttons/tree_open_over.dds"
    local overClosedTexture = "EsoUI/Art/Buttons/tree_closed_over.dds"

    local function TreeHeaderSetup(node, control, name, open)
        control.text:SetModifyTextType(MODIFY_TEXT_TYPE_UPPERCASE)
        control.text:SetText(name)

        control.icon:SetTexture(open and openTexture or closedTexture)
        control.iconHighlight:SetTexture(open and overOpenTexture or overClosedTexture)

        local ENABLED = true
        local DISABLE_SCALING = true
        ZO_IconHeader_Setup(control, open, ENABLED, DISABLE_SCALING)
    end

    self.navigationTree:AddTemplate("ZO_DLCBookNavigationHeader_Keyboard", TreeHeaderSetup, nil, nil, nil, 0)

    local function TreeEntrySetup(node, control, data, open)
        control:SetText(zo_strformat(SI_COLLECTIBLE_NAME_FORMATTER, data.name))
        control:SetSelected(false)

        control.statusIcon = control:GetNamedChild("StatusIcon")
        data.notificationId = NOTIFICATIONS_PROVIDER:GetNotificationIdForCollectible(data.collectibleId)
        control.statusIcon:SetHidden(data.notificationId == nil)
    end

    local function TreeEntryOnSelected(control, data, selected, reselectingDuringRebuild)
        control:SetSelected(selected)

         if selected then
            self.selectedId = data.collectibleId
            if not reselectingDuringRebuild then
                self:RefreshDetails()
            end

            if data.notificationId then
                if SCENE_MANAGER:IsShowing("dlcBook") then
                    RemoveCollectibleNotification(data.notificationId)
                else
                    self.dirty = true
                end
            end
        end
    end

    local function TreeEntryEquality(left, right)
        return left.name == right.name
    end

    self.navigationTree:AddTemplate("ZO_DLCBookNavigationEntry_Keyboard", TreeEntrySetup, TreeEntryOnSelected, TreeEntryEquality)
    self.navigationTree:SetOpenAnimation("ZO_TreeOpenAnimation")

    self.headerNodes = {}
    self.collectibleIdToTreeNode = {}

    self:RefreshList()
end

function DLCBook_Keyboard:RefreshListIfDirty()
    if self.dirty then
        self:RefreshList()
        self.dirty = false
    end
end

function DLCBook_Keyboard:InitializeEvents()
    COLLECTIONS_BOOK_SINGLETON:RegisterCallback("OnCollectibleUpdated", function(...) self:OnCollectibleUpdated(...) end)
    COLLECTIONS_BOOK_SINGLETON:RegisterCallback("OnCollectionUpdated", function() self:OnCollectionUpdated() end)
    COLLECTIONS_BOOK_SINGLETON:RegisterCallback("OnCollectionNotificationRemoved", function(...) self:OnCollectionNotificationRemoved(...) end)
end

---------------
--Interaction--
---------------

function DLCBook_Keyboard:GetSelectedDLCData()
    return self.navigationTree:GetSelectedData()
end

function DLCBook_Keyboard:FocusDLCWithCollectibleId(id)
    local node = self.collectibleIdToTreeNode[id]

    if node then
        if self.navigationTree:GetSelectedNode() == node then
            local RESELECT = true
            node:OnSelected(RESELECT)
        else
            self.navigationTree:SelectNode(node)
        end
    end
end

function DLCBook_Keyboard:RefreshList()
    ZO_ClearTable(self.headerNodes)
    ZO_ClearTable(self.collectibleIdToTreeNode)
    self.navigationTree:Reset()
    local firstNode = nil
    local selectedNode = nil

    for i = 1, GetTotalCollectiblesByCategoryType(COLLECTIBLE_CATEGORY_TYPE_DLC) do
        local collectibleId = GetCollectibleIdFromType(COLLECTIBLE_CATEGORY_TYPE_DLC, i)
        local name, description, _, _, unlocked, _, active, _, _, isPlaceholder = GetCollectibleInfo(collectibleId)
        if not isPlaceholder then
            local unlockState = GetCollectibleUnlockStateById(collectibleId)
            local simplifiedUnlockState = unlockState == COLLECTIBLE_UNLOCK_STATE_LOCKED and COLLECTIBLE_UNLOCK_STATE_LOCKED or COLLECTIBLE_UNLOCK_STATE_UNLOCKED_OWNED
            local background = GetCollectibleKeyboardBackgroundImage(collectibleId)
            if not self.headerNodes[simplifiedUnlockState] then
                self.headerNodes[simplifiedUnlockState] = self.navigationTree:AddNode("ZO_DLCBookNavigationHeader_Keyboard", GetString("SI_COLLECTIBLEUNLOCKSTATE", simplifiedUnlockState), nil, SOUNDS.JOURNAL_PROGRESS_CATEGORY_SELECTED)
            end
            local headerNode = self.headerNodes[simplifiedUnlockState]

            local data =
            {
                collectibleId = collectibleId,
                name = name,
                description = description,
                background = background,
                unlockState = unlockState,
                active = active,
            }
            local dlcNode = self.navigationTree:AddNode("ZO_DLCBookNavigationEntry_Keyboard", data, headerNode, SOUNDS.JOURNAL_PROGRESS_SUB_CATEGORY_SELECTED)
            self.collectibleIdToTreeNode[collectibleId] = dlcNode
            if not firstNode then
                firstNode = dlcNode
            end

            if self.selectedId and self.selectedId == data.collectibleId then
                selectedNode = dlcNode
            end
        end
    end

    self.navigationTree:Commit()
    local navigateToNode = selectedNode or firstNode

    if navigateToNode then
        self.navigationTree:SelectNode(navigateToNode)
    end
    self:RefreshDetails()
end

function DLCBook_Keyboard:RefreshDetails()
    local data = self.navigationTree:GetSelectedData()

    if data then
        self.imageControl:SetTexture(data.background)
        self.nameControl:SetText(zo_strformat(SI_COLLECTIBLE_NAME_FORMATTER, data.name))
        self.descriptionControl:SetText(data.description)
        self.unlockStatusControl:SetText(GetString("SI_COLLECTIBLEUNLOCKSTATE", data.unlockState))

        local questAcceptLabelStringId = data.active and SI_DLC_BOOK_QUEST_STATUS_ACCEPTED or SI_DLC_BOOK_QUEST_STATUS_NOT_ACCEPTED
        local questName = GetCollectibleQuestPreviewInfo(data.collectibleId)
        self.questStatusControl:SetText(zo_strformat(SI_DLC_BOOK_QUEST_STATUS, questName, GetString(questAcceptLabelStringId)))

        local showsQuest = not (data.active or data.unlockState == COLLECTIBLE_UNLOCK_STATE_LOCKED)
        local questAvailableControl = self.questAvailableControl
        local questDescriptionControl = self.questDescriptionControl
        if showsQuest then
            questAvailableControl:SetText(GetString(SI_COLLECTIONS_QUEST_AVAILABLE))
            questAvailableControl:SetHidden(false)
            
            local questDescription = select(2, GetCollectibleQuestPreviewInfo(data.collectibleId))
            questDescriptionControl:SetText(questDescription)
            questDescriptionControl:SetHidden(false)
        elseif data.unlockState == COLLECTIBLE_UNLOCK_STATE_LOCKED then
            questAvailableControl:SetText(GetString(SI_COLLECTIONS_QUEST_AVAILABLE_WITH_UNLOCK))
            questAvailableControl:SetHidden(false)
            questDescriptionControl:SetHidden(true)
        else
            questAvailableControl:SetHidden(true)
            questDescriptionControl:SetHidden(true)
        end

        local questAcceptButtonStringId = data.active and SI_DLC_BOOK_ACTION_QUEST_ACCEPTED or SI_DLC_BOOK_ACTION_ACCEPT_QUEST
        self.questAcceptButton:SetText(GetString(questAcceptButtonStringId))
        self.questAcceptButton:SetEnabled(data.unlockState ~= COLLECTIBLE_UNLOCK_STATE_LOCKED and not data.active)
        self.unlockPermanentlyButton:SetHidden(data.unlockState == COLLECTIBLE_UNLOCK_STATE_UNLOCKED_OWNED)
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

function DLCBook_Keyboard:BrowseToCollectible(collectibleId)
    self:FocusDLCWithCollectibleId(collectibleId)
    SCENE_MANAGER:Show("dlcBook")
end

function DLCBook_Keyboard:IsCategoryIndexDLC(categoryIndex)
    local categoryType = select(7, GetCollectibleCategoryInfo(categoryIndex))
    return categoryType == COLLECTIBLE_CATEGORY_TYPE_DLC
end

----------
--Events--
----------

function DLCBook_Keyboard:OnCollectibleUpdated(collectibleId, justUnlocked)
    if justUnlocked then
        self:RefreshList()
    else
        local node = self.collectibleIdToTreeNode[collectibleId]
        if node then
            local data = node:GetData()
            data.active = select(7, GetCollectibleInfo(collectibleId))

            local unlockState = GetCollectibleUnlockStateById(collectibleId)
            if data.unlockState ~= unlockState then
                self:RefreshList()
            else
                self:RefreshDetails()
            end
        end
    end
end

function DLCBook_Keyboard:OnCollectionNotificationRemoved(notificationId, collectibleId)
    local node = self.collectibleIdToTreeNode[collectibleId]

    if node then
        self:RefreshList()
    end
end

function DLCBook_Keyboard:OnCollectionUpdated()
    self:RefreshList()
end

function ZO_DLCBook_Keyboard_OnQuestAcceptClicked(control)
    DLC_BOOK_KEYBOARD:UseSelectedDLC()
end

function ZO_DLCBook_Keyboard_OnUnlockPermanentlyClicked(control)
    DLC_BOOK_KEYBOARD:SearchSelectedDLCInStore()
end

function ZO_DLCBook_Keyboard_OnSubscribeClicked(control)
    ZO_Dialogs_ShowDialog("CONFIRM_OPEN_URL_BY_TYPE", { urlType = APPROVED_URL_ESO_ACCOUNT_SUBSCRIPTION }, { mainTextParams = { GetString(SI_ESO_PLUS_SUBSCRIPTION_LINK_TEXT), GetString(SI_URL_APPLICATION_WEB) } })
end

function ZO_DLCBook_Keyboard_OnInitialize(control)
    DLC_BOOK_KEYBOARD = DLCBook_Keyboard:New(control)
end