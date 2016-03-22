ZO_DLC_BACKGROUND_TEXTURE_SQUARE_DIMENSION = 1024
ZO_DLC_BACKGROUND_TEXTURE_COORD_RIGHT = ZO_GAMEPAD_QUADRANT_2_3_CONTENT_BACKGROUND_WIDTH / ZO_DLC_BACKGROUND_TEXTURE_SQUARE_DIMENSION

local GAMEPAD_COLLECTIONS_ACTIONS_DIALOG_NAME = "GAMEPAD_COLLECTIONS_ACTIONS_DIALOG"
local GAMEPAD_COLLECTIONS_RENAME_COLLECTIBLE_DIALOG_NAME = "GAMEPAD_COLLECTIONS_INVENTORY_RENAME_COLLECTIBLE"

local NOTIFICATIONS_PROVIDER = GAMEPAD_NOTIFICATIONS:GetCollectionsProvider()
local TIME_NEW_PERSISTS_WHILE_SELECTED_MS = 200

local ZO_GamepadCollectionsBook = ZO_Gamepad_ParametricList_Screen:Subclass()

function ZO_GamepadCollectionsBook:New(...)
    return ZO_Gamepad_ParametricList_Screen.New(self, ...)
end

function ZO_GamepadCollectionsBook:Initialize(control)
    GAMEPAD_COLLECTIONS_BOOK_SCENE = ZO_Scene:New("gamepadCollectionsBook", SCENE_MANAGER)

    local ACTIVATE_ON_SHOW = true
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE, ACTIVATE_ON_SHOW, GAMEPAD_COLLECTIONS_BOOK_SCENE)
    
    self.categoryList = {}
    self.categoryList.list = ZO_Gamepad_ParametricList_Screen.GetMainList(self)
    self.categoryList.fragment = self:GetListFragment(self.categoryList.list)
    self.categoryList.keybind = self.categoryKeybindStripDescriptor
    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.categoryKeybindStripDescriptor , self.categoryList.list)
    self.categoryList.headerText = nil
    self.categoryList.titleText = GetString(SI_MAIN_MENU_COLLECTIONS)

    self.collectionList = {}
    self.collectionList.list = self:AddList("Collection")
    self.collectionList.fragment = self:CreateListFragment("Collection")
    self.collectionList.keybind = self.collectionKeybindStripDescriptor
    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.collectionKeybindStripDescriptor, self.collectionList.list)
    self.collectionList.headerText = GetString(SI_MAIN_MENU_COLLECTIONS)
    self.collectionList.titleText = nil
    self.updateList = {}

    self.currentList = nil

    self.trySetClearNewFlagCallback = function(callId)
        self:TrySetClearNewFlag(callId)
    end

    self.headerData = {}
    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)

    self:InitializeInfoPanel()
    self:InitializeActionsDialog()
    self:InitializeRenameCollectibleDialog()

    SYSTEMS:RegisterGamepadObject(ZO_COLLECTIONS_SYSTEM_NAME, self)

    COLLECTIONS_BOOK_SINGLETON:RegisterCallback("OnCollectibleUpdated", function(...) self:OnCollectibleUpdated(...) end)
    COLLECTIONS_BOOK_SINGLETON:RegisterCallback("OnCollectionUpdated", function(...) self:OnCollectionUpdated(...) end)
    COLLECTIONS_BOOK_SINGLETON:RegisterCallback("OnCollectionNotificationRemoved", function(...) self:OnCollectionNotificationRemoved(...) end)
    COLLECTIONS_BOOK_SINGLETON:RegisterCallback("OnUpdateCooldowns", function(...) self:OnUpdateCooldowns(...) end)
end

function ZO_GamepadCollectionsBook:InitializeInfoPanel()
    local infoPanel = self.control:GetNamedChild("InfoPanel")
    infoPanel.backgroundControl = infoPanel:GetNamedChild("Background")

    local container = infoPanel:GetNamedChild("Container")
    infoPanel.unlockStatusControl = container:GetNamedChild("UnlockStatusLabel")
    infoPanel.nameControl = container:GetNamedChild("Name")
    infoPanel.questStatusControl = container:GetNamedChild("QuestStatusValue")

    local scrollContainer = container:GetNamedChild("ScrollSection"):GetNamedChild("ScrollChild")
    infoPanel.descriptionControl = scrollContainer:GetNamedChild("Description")
    infoPanel.questAcceptIndicator = scrollContainer:GetNamedChild("QuestAcceptIndicator")
    infoPanel.questAcceptDescription = scrollContainer:GetNamedChild("QuestAcceptDescription")
    self.infoPanelControl = infoPanel
end

function ZO_GamepadCollectionsBook:SetupList(list)
    local function CategoryEntrySetup(control, data, selected, reselectingDuringRebuild, enabled, active)
        ZO_SharedGamepadEntry_OnSetup(control, data, selected, reselectingDuringRebuild, enabled, active)

        local entryData = data.data
        if self:HasAnyNotifications(entryData.categoryIndex) then
            control.icon:ClearIcons()
            control.icon:AddIcon(entryData.icon)
            control.icon:AddIcon(ZO_GAMEPAD_NEW_ICON_64)
            control.icon:Show()
        end
    end

    list:AddDataTemplate("ZO_GamepadMenuEntryTemplate", CategoryEntrySetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
    list:AddDataTemplateWithHeader("ZO_GamepadMenuEntryTemplate", CategoryEntrySetup, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadMenuEntryHeaderTemplate")

    local function CollectibleEntrySetup(control, data, selected, reselectingDuringRebuild, enabled, active)
        data.brandNew = data.data.notificationId ~= nil

        ZO_SharedGamepadEntry_OnSetup(control, data, selected, reselectingDuringRebuild, enabled, active)
    end

    list:AddDataTemplate("ZO_GamepadItemEntryTemplate", CollectibleEntrySetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
    list:AddDataTemplateWithHeader("ZO_GamepadItemEntryTemplate", CollectibleEntrySetup, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadMenuEntryHeaderTemplate")
end

function ZO_GamepadCollectionsBook:OnShowing()
    ZO_Gamepad_ParametricList_Screen.OnShowing(self)
    
    self:ShowList(self.categoryList)
    if self.browseToCollectibleInfo then
        self:ViewCategory(self.browseToCollectibleInfo.categoryIndex)
        self:SelectCollectibleEntry(self.browseToCollectibleInfo.collectibleId)
        self.browseToCollectibleInfo = nil
    end
end

function ZO_GamepadCollectionsBook:OnHide()
    self:HideCurrentList()
end

function ZO_GamepadCollectionsBook:InitializeKeybindStripDescriptors()
    -- Category Keybind
    self.categoryKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        -- Select Category
        {
            name = GetString(SI_GAMEPAD_SELECT_OPTION),
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                self:ViewCategory()
            end,
            visible = function()
                if self.currentList then
                    local entryData = self.currentList.list:GetTargetData()
                    return entryData ~= nil
                end
                return false
            end,
            sound = SOUNDS.GAMEPAD_MENU_FORWARD,
        },
    }
    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.categoryKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON)

    -- Collection Keybind
    self.collectionKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        -- Set Active or Put Away Collectible
        {
            name = function()
                local categoryType = self.currentList.data.categoryType
                local entryData = self.currentList.list:GetTargetData()
                local collectibleData = entryData.data
                local nameStringId
                if categoryType == COLLECTIBLE_CATEGORY_TYPE_DLC then
                    nameStringId = SI_DLC_BOOK_ACTION_ACCEPT_QUEST
                elseif categoryType == COLLECTIBLE_CATEGORY_TYPE_TROPHY then
                    nameStringId = SI_COLLECTIBLE_ACTION_USE
                elseif collectibleData.active then
                    if categoryType == COLLECTIBLE_CATEGORY_TYPE_ASSISTANT or categoryType == COLLECTIBLE_CATEGORY_TYPE_VANITY_PET then
                        nameStringId = SI_COLLECTIBLE_ACTION_DISMISS
                    else
                        nameStringId = SI_COLLECTIBLE_ACTION_PUT_AWAY
                    end
                else
                    nameStringId = SI_COLLECTIBLE_ACTION_SET_ACTIVE
                end
                return GetString(nameStringId)
            end,
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                local entryData = self.currentList.list:GetTargetData()
                local collectibleData = entryData.data
                UseCollectible(collectibleData.collectibleId)
            end,
            visible = function()
                local entryData = self.currentList.list:GetTargetData()
                if entryData and entryData.data then
                    local collectibleData = entryData.data
                    return collectibleData.useable
                else
                    return false
                end
            end,
            sound = SOUNDS.DEFAULT_CLICK,
            enabled = function()
                local entryData = self.currentList.list:GetTargetData()
                if entryData and entryData.data and entryData.data.useable then
                    local remaining = GetCollectibleCooldownAndDuration(entryData.data.collectibleId)
                    if remaining > 0 then
                        return false, GetString(SI_COLLECTIONS_COOLDOWN_ERROR)
                    elseif entryData.data.blocked then
                        return false, GetString(SI_COLLECTIONS_BLOCKED_ERROR)
                    else
                        return true
                    end
                end
                return false
            end  
        },
        --Assign to Quick Slot
        {
            name = GetString(SI_GAMEPAD_ITEM_ACTION_QUICKSLOT_ASSIGN),
            keybind = "UI_SHORTCUT_SECONDARY",
            callback = function()
                local entryData = self.currentList.list:GetTargetData()
                GAMEPAD_QUICKSLOT:SetCollectibleToQuickslot(entryData.data.collectibleId)
                SCENE_MANAGER:Push("gamepad_quickslot")
            end,
            visible = function()
                local entryData = self.currentList.list:GetTargetData()
                local categoryType = self.currentList.data.categoryType
                return entryData.data.unlocked and IsCollectibleCategorySlottable(categoryType)
            end,
            sound = SOUNDS.GAMEPAD_MENU_FORWARD,
        },
        -- Actions
        {
            -- If there is never going to be a "Link to chat" option then there will only ever be "rename."  Since design considers an
            -- "action panel" with only one action silly, we want to just make "rename" the default keybind with no other action layer
            name = GetString(IsChatSystemAvailableForCurrentPlatform() and SI_GAMEPAD_INVENTORY_ACTION_LIST_KEYBIND or SI_COLLECTIBLE_ACTION_RENAME),
            keybind = "UI_SHORTCUT_TERTIARY",
            callback = function()
                local entryData = self.currentList.list:GetTargetData()
                local collectibleData = entryData.data

                if IsChatSystemAvailableForCurrentPlatform() then
                    local dialogData = 
                    {
                        collectibleId = collectibleData.collectibleId,
                        name = collectibleData.nickname,
                        active = collectibleData.active,
                    }
                    ZO_Dialogs_ShowGamepadDialog(GAMEPAD_COLLECTIONS_ACTIONS_DIALOG_NAME, dialogData)
                else
                    ZO_Dialogs_ShowGamepadDialog(GAMEPAD_COLLECTIONS_RENAME_COLLECTIBLE_DIALOG_NAME, { collectibleId = collectibleData.collectibleId, name = collectibleData.nickname })
                end
            end,
            visible = function()
                local entryData = self.currentList.list:GetTargetData()
                local collectibleData = entryData and entryData.data
                
                if collectibleData then
                    if IsChatSystemAvailableForCurrentPlatform() then --Every collectible can link to chat
                        return true
                    else
                        return IsCollectibleRenameable(collectibleData.collectibleId)
                    end
                else
                    return false
                end
            end,
        },
        --Subscribe
        {
            alignment = KEYBIND_STRIP_ALIGN_RIGHT,
            name = GetString(SI_DLC_BOOK_ACTION_GET_SUBSCRIPTION),
            keybind = "UI_SHORTCUT_RIGHT_STICK",
            callback = function()
                if GetUIPlatform() == UI_PLATFORM_PC then
                    ZO_Dialogs_ShowGamepadDialog("CONFIRM_OPEN_URL_BY_TYPE", { urlType = APPROVED_URL_ESO_ACCOUNT_SUBSCRIPTION }, { mainTextParams = { GetString(SI_ESO_PLUS_SUBSCRIPTION_LINK_TEXT), GetString(SI_URL_APPLICATION_WEB) } })
                else
                    ZO_Dialogs_ShowGamepadDialog("CONSOLE_BUY_ESO_PLUS")
                end
            end,
            visible = function()
                local categoryData = self.currentList.data
                return categoryData.categoryType == COLLECTIBLE_CATEGORY_TYPE_DLC and not IsESOPlusSubscriber()
            end,
        },
    }
    ZO_Gamepad_AddBackNavigationKeybindDescriptorsWithSound(self.collectionKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, function() self:ShowList(self.categoryList) end )
end

--Opens up the provided category, or the current category if no categoryIndex is provided
function ZO_GamepadCollectionsBook:ViewCategory(categoryIndex)
    if categoryIndex then
        self.categoryList.list:SetSelectedIndexWithoutAnimation(categoryIndex)
    end
    local entryData = self.categoryList.list:GetTargetData()
    self.collectionList.data = entryData.data
    self:BuildCollectionList()
    self:ShowList(self.collectionList)
end

function ZO_GamepadCollectionsBook:SelectCollectibleEntry(collectibleId)
    if collectibleId then
        local list = self.collectionList.list
        for i = 1, list:GetNumItems() do
            local data = list:GetDataForDataIndex(i)
            if data.data.collectibleId == collectibleId then
                list:SetSelectedIndexWithoutAnimation(i)
                break
            end
        end
    end
end

function ZO_GamepadCollectionsBook:PerformUpdate()
   self:BuildCategoryList()
end

function ZO_GamepadCollectionsBook:ShowList(list)
    if self.currentList == list then
        return
    end
    self:HideCurrentList()

    self.currentList = list
    if list then
        KEYBIND_STRIP:AddKeybindButtonGroup(self.currentList.keybind)
        SCENE_MANAGER:AddFragment(list.fragment)
        list.list:Activate()
    end

    self.headerData.titleText = zo_strformat(SI_COLLECTIBLE_NAME_FORMATTER, list.titleText)
    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)

    if self.currentList == self.collectionList then
        local targetData = self.collectionList.list:GetTargetData()
        self:RefreshTooltip(targetData)
        self.notificationIdToClear = targetData.data.notificationId
        if self.notificationIdToClear then
            self.clearNewStatusOnSelectionChanged = true
        end
    end
end

function ZO_GamepadCollectionsBook:HideCurrentList()
    if self.currentList == nil then
        return
    end

    if self.currentList == self.collectionList then
        if self.notificationIdToClear then
            RemoveCollectibleNotification(self.notificationIdToClear)
        end

        self.clearNewStatusOnSelectionChanged = false
        self.notificationIdToClear = nil
        self.clearNewStatusCallId = nil
    end

    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.currentList.keybind)

    SCENE_MANAGER:RemoveFragment(self.currentList.fragment)
    self.currentList.list:Deactivate()
    self.currentList = nil

    self:RefreshTooltip(nil)
end

function ZO_GamepadCollectionsBook:OnCollectionUpdated()
    if not self.control:IsHidden() then
        if self.categoryList then
            self:BuildCategoryList()
        end
    end
end

function ZO_GamepadCollectionsBook:OnCollectibleUpdated(collectibleId)
    if not self.control:IsHidden() then
        if self.currentList == self.collectionList and self.collectionList then
            self:BuildCollectionList()
        end
        self.categoryList.list:RefreshVisible()
    end
end

function ZO_GamepadCollectionsBook:OnCollectionNotificationRemoved(notificationId, collectibleId)
    if not self.control:IsHidden() then
        if self.currentList == self.collectionList then
            self.currentList.list:RefreshVisible()
        end
        self.categoryList.list:RefreshVisible()
    end
end

function ZO_GamepadCollectionsBook:BuildCategoryList()
    self.categoryList.list:Clear()

    -- Add the categories entries
    for categoryIndex = 1, GetNumCollectibleCategories() do
        local categoryName, numSubCategories, numCollectibles, unlockedCollectibles, totalCollectibles, hidesUnearned, categoryType = GetCollectibleCategoryInfo(categoryIndex)
        local gamepadIcon = GetCollectibleCategoryGamepadIcon(categoryIndex)
        categoryName = zo_strformat(SI_COLLECTIBLE_NAME_FORMATTER, categoryName)

        local entryData = ZO_GamepadEntryData:New(categoryName, gamepadIcon)
        entryData.data = {
            categoryIndex = categoryIndex,
            categoryName = categoryName,
            categoryType = categoryType,
            numCollectibles = numCollectibles,
            unlockedCollectibles = unlockedCollectibles,
            totalCollectibles = totalCollectibles,
            icon = gamepadIcon,
        }
        entryData:SetIconTintOnSelection(true)

        self.categoryList.list:AddEntry("ZO_GamepadMenuEntryTemplate", entryData)
    end
    self.categoryList.list:Commit()

    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.categoryList.keybind)
end

function ZO_GamepadCollectionsBook:BuildCollectionList()
    self.collectionList.list:Clear()

    local data = self.collectionList.data

    local unlockedData = {}
    local lockedData = {}

    local categoryName, numSubCategories, numCollectibles,_,_,_,categoryType = GetCollectibleCategoryInfo(data.categoryIndex)

    -- Add top level collectibles
    for collectibleIndex = 1, numCollectibles do
        local entryData = self:BuildCollectibleData(data.categoryIndex, nil, collectibleIndex, categoryType)
        if not entryData.data.isPlaceholder then
            if entryData.data.unlocked then
                table.insert(unlockedData, entryData)
            else
                table.insert(lockedData, entryData)
            end
        end
    end

    -- Add subcategories
    for subCategoryIndex=1, numSubCategories do
        local subCategoryName, subNumCollectibles,_,_,subCategoryType = GetCollectibleSubCategoryInfo(data.categoryIndex, subCategoryIndex)
        for collectibleIndex = 1, subNumCollectibles do
            local entryData = self:BuildCollectibleData(data.categoryIndex, subCategoryIndex, collectibleIndex, subCategoryType)
            if not entryData.data.isPlaceholder then
                if entryData.data.unlocked then
                    table.insert(unlockedData, entryData)
                else
                    table.insert(lockedData, entryData)
                end
            end
        end
    end

    self:BuildListFromTable(self.collectionList.list, unlockedData, GetString("SI_COLLECTIBLEUNLOCKSTATE", COLLECTIBLE_UNLOCK_STATE_UNLOCKED_OWNED))
    self:BuildListFromTable(self.collectionList.list, lockedData, GetString("SI_COLLECTIBLEUNLOCKSTATE", COLLECTIBLE_UNLOCK_STATE_LOCKED))

    self.collectionList.list:Commit()

    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.collectionList.keybind)

    self:RefreshTooltip(self.collectionList.list:GetTargetData())

    self.collectionList.titleText = data.categoryName

    self.updateList = unlockedData
end

function ZO_GamepadCollectionsBook:BuildCollectibleData(categoryIndex, subCategoryIndex, collectibleIndex, categoryType)
    local collectibleId = GetCollectibleId(categoryIndex, subCategoryIndex, collectibleIndex)
    local name, description, iconFile, lockedIconFile, unlocked, purchasable, active, _, hint, isPlaceholder = GetCollectibleInfo(collectibleId)
    local unlockState = GetCollectibleUnlockStateById(collectibleId)
    iconFile = unlocked and iconFile or lockedIconFile
    local backgroundFile = GetCollectibleGamepadBackgroundImage(collectibleId)
    local useable = IsCollectibleUsable(collectibleId)
    local categoryBlocked = IsCollectibleCategoryBlocked(categoryType)
    local notificationId = self:GetNotificationIdForCollectible(collectibleId)

    local entryData = ZO_GamepadEntryData:New(zo_strformat(SI_COLLECTIBLE_NAME_FORMATTER, name), iconFile)
    entryData.data = {
        name = name,
        nickname = GetCollectibleNickname(collectibleId),
        description = description,
        hint = hint,
        iconFile = iconFile,
        backgroundFile = backgroundFile,
        collectibleId = collectibleId,
        unlocked = unlocked,
        unlockState = unlockState,
        purchasable = purchasable,
        useable = useable,
        active = active,
        blocked = categoryBlocked,
        isPlaceholder = isPlaceholder,
        notificationId = notificationId,
        lastCooldownDuration = 0
    }
    entryData.isEquippedInCurrentCategory = active
    entryData:InitializeCollectibleVisualData(entryData.data)

    if categoryBlocked == true then
        entryData:SetIconDesaturation(1)
    else
        entryData:SetIconDesaturation(0)
    end

    local remaining, duration = GetCollectibleCooldownAndDuration(entryData.data.collectibleId)
    if remaining > 0 and duration > 0 then
        entryData:SetCooldown(remaining, duration)
        entryData.data.lastCooldownDuration = duration
    end

    return entryData
end

function ZO_GamepadCollectionsBook:BuildListFromTable(list, dataTable, header)
    if #dataTable >= 1 then
        for i,entryData in ipairs(dataTable) do
            if i == 1 then
                entryData:SetHeader(header)
                list:AddEntryWithHeader("ZO_GamepadItemEntryTemplate", entryData)
            else
                list:AddEntry("ZO_GamepadItemEntryTemplate", entryData)
            end
        end
    end
end

function ZO_GamepadCollectionsBook:OnSelectionChanged(list, selectedData, oldSelectedData)
    if self.currentList == self.collectionList then
        self:RefreshTooltip(selectedData)
        self.notificationIdToClear = nil
        self.clearNewStatusCallId = nil

        if oldSelectedData and oldSelectedData.data.notificationId then
            if self.clearNewStatusOnSelectionChanged then
                RemoveCollectibleNotification(oldSelectedData.data.notificationId)
                oldSelectedData.data.notificationId = nil
            end
        end

        self.clearNewStatusOnSelectionChanged = false

        if selectedData and selectedData.data.notificationId then
            self.notificationIdToClear = selectedData.data.notificationId
            self.clearNewStatusCallId = zo_callLater(self.trySetClearNewFlagCallback, TIME_NEW_PERSISTS_WHILE_SELECTED_MS)
        end
    end
    if self.currentList then
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.currentList.keybind)
    end
end

function ZO_GamepadCollectionsBook:TrySetClearNewFlag(callId)
    if self.clearNewStatusCallId == callId then
        self.clearNewStatusOnSelectionChanged = true
    end
end

function ZO_GamepadCollectionsBook:RefreshTooltip(entryData)
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
    GAMEPAD_TOOLTIPS:SetBottomRailHidden(GAMEPAD_LEFT_TOOLTIP, true)
    SCENE_MANAGER:RemoveFragment(GAMEPAD_NAV_QUADRANT_2_3_BACKGROUND_FRAGMENT)
    SCENE_MANAGER:RemoveFragment(GAMEPAD_COLLECTIONS_BOOK_INFO_PANEL_FRAGMENT)

    if entryData and entryData.data then
        local categoryData = self.collectionList.data
        local collectibleData = entryData.data
        if categoryData.categoryType == COLLECTIBLE_CATEGORY_TYPE_DLC then
            local infoPanel = self.infoPanelControl
            infoPanel.backgroundControl:SetTexture(collectibleData.backgroundFile)
            infoPanel.nameControl:SetText(zo_strformat(SI_COLLECTIBLE_NAME_FORMATTER, collectibleData.name))
            infoPanel.descriptionControl:SetText(collectibleData.description)
            infoPanel.unlockStatusControl:SetText(GetString("SI_COLLECTIBLEUNLOCKSTATE", collectibleData.unlockState))

            local questAcceptLabelStringId = collectibleData.active and SI_DLC_BOOK_QUEST_STATUS_ACCEPTED or SI_DLC_BOOK_QUEST_STATUS_NOT_ACCEPTED
            local questName = GetCollectibleQuestPreviewInfo(collectibleData.collectibleId)
            infoPanel.questStatusControl:SetText(zo_strformat(SI_GAMEPAD_DLC_BOOK_QUEST_STATUS_INFO, questName, GetString(questAcceptLabelStringId)))
            
            local showsQuest = not (collectibleData.active or collectibleData.unlockState == COLLECTIBLE_UNLOCK_STATE_LOCKED)
            local questAcceptIndicator = infoPanel.questAcceptIndicator
            local questAcceptDescription = infoPanel.questAcceptDescription
            if showsQuest then
                questAcceptIndicator:SetText(GetString(SI_COLLECTIONS_QUEST_AVAILABLE))
                questAcceptIndicator:SetHidden(false)
                
                local questDescription = select(2, GetCollectibleQuestPreviewInfo(collectibleData.collectibleId))
                questAcceptDescription:SetText(questDescription)
                questAcceptDescription:SetHidden(false)
            elseif collectibleData.unlockState == COLLECTIBLE_UNLOCK_STATE_LOCKED then
                questAcceptIndicator:SetText(GetString(SI_COLLECTIONS_QUEST_AVAILABLE_WITH_UNLOCK))
                questAcceptIndicator:SetHidden(false)
                questAcceptDescription:SetHidden(true)
            else
                questAcceptIndicator:SetHidden(true)
                questAcceptDescription:SetHidden(true)
            end

            SCENE_MANAGER:AddFragment(GAMEPAD_NAV_QUADRANT_2_3_BACKGROUND_FRAGMENT)
            SCENE_MANAGER:AddFragment(GAMEPAD_COLLECTIONS_BOOK_INFO_PANEL_FRAGMENT)
        else
            local categoryName = categoryData.name
            GAMEPAD_TOOLTIPS:LayoutCollectible(GAMEPAD_LEFT_TOOLTIP, categoryName, collectibleData.name, collectibleData.nickname, collectibleData.unlockState, collectibleData.purchasable, collectibleData.description, collectibleData.hint, collectibleData.isPlaceholder)
        end
    end
end

function ZO_GamepadCollectionsBook:BrowseToCollectible(collectibleId, categoryIndex, subcategoryIndex)
    self.browseToCollectibleInfo = 
    {
        categoryIndex = categoryIndex,
        collectibleId = collectibleId,
    }

    SCENE_MANAGER:CreateStackFromScratch("mainMenuGamepad", "gamepadCollectionsBook")
end

--[[Global functions]]--
------------------------

function ZO_GamepadCollectionsBook:InitializeActionsDialog()

    local dialog = ZO_GenericGamepadDialog_GetControl(GAMEPAD_DIALOGS.PARAMETRIC)
    ZO_Dialogs_RegisterCustomDialog(GAMEPAD_COLLECTIONS_ACTIONS_DIALOG_NAME,
    {
        gamepadInfo = 
        {
            dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
        },
        canQueue = true,
        setup = function()
            dialog.setupFunc(dialog)
        end,
        title =
        {
            text = SI_GAMEPAD_INVENTORY_ACTION_LIST_KEYBIND,
        },
        parametricList =
        {
            -- Link In Chat
            {
                template = "ZO_GamepadMenuEntryTemplate",
                templateData = {
                    text = GetString(SI_ITEM_ACTION_LINK_TO_CHAT),
                    setup = ZO_SharedGamepadEntry_OnSetup,
                    callback = function()
                        local link = ZO_LinkHandler_CreateChatLink(GetCollectibleLink, dialog.data.collectibleId)
                        ZO_LinkHandler_InsertLink(zo_strformat(SI_TOOLTIP_ITEM_NAME, link))
                        CHAT_SYSTEM:SubmitTextEntry()
                    end,
                },
            },
            -- Rename
            {
                template = "ZO_GamepadMenuEntryTemplate",
                templateData = {
                    text = GetString(SI_COLLECTIBLE_ACTION_RENAME),
                    setup = ZO_SharedGamepadEntry_OnSetup,
                    callback = function()
                       ZO_Dialogs_ShowGamepadDialog(GAMEPAD_COLLECTIONS_RENAME_COLLECTIBLE_DIALOG_NAME, { collectibleId = dialog.data.collectibleId, name = dialog.data.name })
                    end,
                    visible = function()
                        return IsCollectibleRenameable(dialog.data.collectibleId)
                    end
                },
            },
            -- Unlock Permanently (Purchase)
            {
                template = "ZO_GamepadMenuEntryTemplate",
                templateData = {
                    text = GetString(SI_GAMEPAD_DLC_BOOK_ACTION_OPEN_CROWN_STORE),
                    setup = ZO_SharedGamepadEntry_OnSetup,
                    callback = function()
                        local entryData = self.currentList.list:GetTargetData()
                        local collectibleData = entryData.data
                        local searchTerm = zo_strformat(SI_CROWN_STORE_SEARCH_FORMAT_STRING, collectibleData.name)
                        ShowMarketAndSearch(searchTerm, MARKET_OPEN_OPERATION_COLLECTIONS_DLC)
                    end,
                    visible = function()
                        local entryData = self.currentList.list:GetTargetData()
                        local collectibleData = entryData.data
                        return collectibleData.purchasable and collectibleData.unlockState ~= COLLECTIBLE_UNLOCK_STATE_UNLOCKED_OWNED
                    end
                },
            },
        },
        buttons =
        {
            {
                keybind = "DIALOG_PRIMARY",
                text = SI_OK,
                callback =  function(dialog)
                    local data = dialog.entryList:GetTargetData()
                     data.callback()
                end,
            },

            {
                keybind = "DIALOG_NEGATIVE",
                text = SI_DIALOG_CANCEL,
            },
        }
    })
end

-------------------
-- Rename Collectible
-------------------

function ZO_GamepadCollectionsBook:InitializeRenameCollectibleDialog()
    local dialog = ZO_GenericGamepadDialog_GetControl(GAMEPAD_DIALOGS.PARAMETRIC)

    local inputText = ""
    local dialogName = GAMEPAD_COLLECTIONS_RENAME_COLLECTIBLE_DIALOG_NAME

    local function ReleaseDialog()
        ZO_Dialogs_ReleaseDialogOnButtonPress(dialogName)
    end

    local function UpdateSelectedName(name)
        if(self.selectedName ~= name or not self.noViolations) then
            self.selectedName = name
            self.nameViolations = { IsValidCollectibleName(self.selectedName) }
            self.noViolations = #self.nameViolations == 0
            
            if(not self.noViolations) then
                local HIDE_UNVIOLATED_RULES = true
                local violationString = ZO_ValidNameInstructions_GetViolationString(self.selectedName, self.nameViolations, HIDE_UNVIOLATED_RULES)
            
                local headerData = 
                {
                    titleText = GetString(SI_INVALID_NAME_DIALOG_TITLE),
                    messageText = violationString,
                    messageTextAlignment = TEXT_ALIGN_LEFT,
                }
                GAMEPAD_TOOLTIPS:ShowGenericHeader(GAMEPAD_LEFT_DIALOG_TOOLTIP, headerData)
                ZO_GenericGamepadDialog_ShowTooltip(dialog)
            else
                ZO_GenericGamepadDialog_HideTooltip(dialog)
            end
        end

        KEYBIND_STRIP:UpdateCurrentKeybindButtonGroups()
    end
    
    local function SetActiveEdit(edit)
        local SAVE_EXISTING_TEXT = true
        edit:TakeFocus()
        UpdateSelectedName(inputText)
    end

    ZO_Dialogs_RegisterCustomDialog(dialogName,
    {
        canQueue = true,
        gamepadInfo = 
        {
            dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
        },

        setup = function()
            dialog.setupFunc(dialog)
        end,

        title =
        {
            text = SI_COLLECTIONS_INVENTORY_DIALOG_RENAME_COLLECTIBLE_TITLE,
        },
        mainText = 
        {
            text = SI_COLLECTIONS_INVENTORY_DIALOG_RENAME_COLLECTIBLE_MAIN,
        },
        parametricList =
        {
            -- user name
            {
                template = "ZO_GamepadTextFieldItem",
                templateData = {
                    nameField = true,
                    textChangedCallback = function(control) 
                        inputText = control:GetText()
                        UpdateSelectedName(inputText)
                    end,  
                    setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                        control.editBoxControl.textChangedCallback = data.textChangedCallback
                        control.editBoxControl:SetMaxInputChars(COLLECTIBLE_NAME_MAX_LENGTH)
                        data.control = control

                        if dialog.data then
                            control.editBoxControl:SetText(zo_strformat(SI_COLLECTIBLE_NAME_FORMATTER, dialog.data.name))
                        else
                            ZO_EditDefaultText_Initialize(control.editBoxControl, "")
                        end
                    end, 
                },
                
            },
        },
        blockDialogReleaseOnPress = true,
        buttons =
        {
            {
                keybind = "DIALOG_PRIMARY",
                text = SI_GAMEPAD_SELECT_OPTION,
                callback =  function(dialog)
                    local data = dialog.entryList:GetTargetData()
                    SetActiveEdit(data.control.editBoxControl)
                end,
            },
            {
                keybind = "DIALOG_SECONDARY",
                text = SI_GAMEPAD_COLLECTIONS_SAVE_NAME_OPTION,
                callback =  function(dialog)
                                local collectibleId = dialog.data.collectibleId
                                RenameCollectible(collectibleId, inputText)
                                ReleaseDialog()
                end,
                visible = function()
                    return self.noViolations
                end,
                clickSound = SOUNDS.DIALOG_ACCEPT,
            },

            {
                keybind = "DIALOG_NEGATIVE",
                text = SI_DIALOG_CANCEL,
                callback =  function(dialog)
                    ReleaseDialog()
                end,
            },
        }
    })

end

function ZO_GamepadCollectionsBook:HasAnyNotifications(optionalCategoryIndexFilter, optionalSubcategoryIndexFilter)
    return NOTIFICATIONS_PROVIDER:HasAnyNotifications(optionalCategoryIndexFilter, optionalSubcategoryIndexFilter)
end

function ZO_GamepadCollectionsBook:GetNotificationIdForCollectible(collectibleId)
    return NOTIFICATIONS_PROVIDER:GetNotificationIdForCollectible(collectibleId)
end

function ZO_GamepadCollectionsBook:OnUpdateCooldowns()
    for i, entryData in ipairs(self.updateList) do
        local collectibleData = entryData.data
        local _, duration = GetCollectibleCooldownAndDuration(collectibleData.collectibleId)
        if duration ~= collectibleData.lastCooldownDuration then
            self:OnCollectibleUpdated(collectibleData.collectibleId)
            return
        end
    end
end

--[[Global functions]]--
------------------------
function ZO_GamepadCollectionsBook_OnInitialize(control)
    GAMEPAD_COLLECTIONS_BOOK = ZO_GamepadCollectionsBook:New(control)
end
