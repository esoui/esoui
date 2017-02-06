ZO_GAMEPAD_COLLECTIONS_PANEL_TEXTURE_SQUARE_DIMENSION = 1024
ZO_GAMEPAD_COLLECTIONS_PANEL_TEXTURE_COORD_RIGHT = ZO_GAMEPAD_QUADRANT_2_3_CONTENT_BACKGROUND_WIDTH / ZO_GAMEPAD_COLLECTIONS_PANEL_TEXTURE_SQUARE_DIMENSION

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
    self:SetListsUseTriggerKeybinds(true)
    
    self.categoryList =
        {
            list = self:GetMainList(),
            keybind = self.categoryKeybindStripDescriptor,
            titleText = GetString(SI_MAIN_MENU_COLLECTIONS),
        }

    self.subcategoryList =
        {
            list = self:AddList("SubCategory"),
            keybind = self.subcategoryKeybindStripDescriptor,
            -- The title text will be updated to the name of the collections category
        }

    self.collectionList =
        {
            list = self:AddList("Collection"),
            keybind = self.collectionKeybindStripDescriptor,
            -- The title text will be updated to the name of the collections category/subcategory
        }

    self.updateList = {}

    self.currentList = nil

    self.trySetClearNewFlagCallback = function(callId)
        self:TrySetClearNewFlag(callId)
    end

    self.headerData = {}
    self:RefreshHeader()

    self:InitializeInfoPanel()
    self:InitializeHousingPanel()
    self:InitializeActionsDialog()
    self:InitializeRenameCollectibleDialog()

    self.control:RegisterForEvent(EVENT_VISUAL_LAYER_CHANGED, function()
                                                                    if GAMEPAD_COLLECTIONS_BOOK_SCENE:IsShowing() then
                                                                        if self.currentList ~= nil and self.currentList == self.collectionList then
                                                                            self:UpdateCollectionListVisualLayer()
                                                                        end
                                                                    end
                                                                end)

    SYSTEMS:RegisterGamepadObject(ZO_COLLECTIONS_SYSTEM_NAME, self)

    COLLECTIONS_BOOK_SINGLETON:RegisterCallback("OnCollectibleUpdated", function(...) self:OnCollectibleUpdated(...) end)
    COLLECTIONS_BOOK_SINGLETON:RegisterCallback("OnCollectionUpdated", function() self:OnCollectionUpdated() end)
    COLLECTIONS_BOOK_SINGLETON:RegisterCallback("OnCollectiblesUpdated", function() self:OnCollectionUpdated() end)
    COLLECTIONS_BOOK_SINGLETON:RegisterCallback("OnCollectionNotificationRemoved", function(...) self:OnCollectionNotificationRemoved(...) end)
    COLLECTIONS_BOOK_SINGLETON:RegisterCallback("OnCollectibleNewStatusRemoved", function(...) self:OnCollectionNewStatusRemoved(...) end)
    COLLECTIONS_BOOK_SINGLETON:RegisterCallback("OnUpdateCooldowns", function(...) self:OnUpdateCooldowns(...) end)
    EVENT_MANAGER:RegisterForUpdate("ZO_GamepadCollectionsBook", 250, function() self:UpdateActiveCollectibleCooldownTimer() end)
end

function ZO_GamepadCollectionsBook:InitializeInfoPanel()
    local infoPanel = self.control:GetNamedChild("DLCPanel")
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

function ZO_GamepadCollectionsBook:InitializeHousingPanel()
    local housingPanel = self.control:GetNamedChild("HousingPanel")
    housingPanel.backgroundControl = housingPanel:GetNamedChild("Background")
    
    local container = housingPanel:GetNamedChild("Container")
    housingPanel.collectedStatusLabel = container:GetNamedChild("UnlockStatusLabel")
    housingPanel.nameLabel = container:GetNamedChild("Name")
    housingPanel.nicknameLabel = container:GetNamedChild("Nickname")
    housingPanel.locationLabel = container:GetNamedChild("LocationValue")
    housingPanel.houseTypeLabel = container:GetNamedChild("HouseTypeValue")
    
    local scrollContainer = container:GetNamedChild("ScrollSection"):GetNamedChild("ScrollChild")
    housingPanel.descriptionLabel = scrollContainer:GetNamedChild("Description")
    housingPanel.primaryResidenceHeaderLabel  = scrollContainer:GetNamedChild("PrimaryResidenceHeader")
    housingPanel.primaryResidenceValueLabel = scrollContainer:GetNamedChild("PrimaryResidenceValue")
    housingPanel.hintLabel = scrollContainer:GetNamedChild("Hint")
    
    self.housingPanelControl = housingPanel
end

function ZO_GamepadCollectionsBook:SetupList(list)
    local function CategoryEntrySetup(control, data, selected, reselectingDuringRebuild, enabled, active)
        ZO_SharedGamepadEntry_OnSetup(control, data, selected, reselectingDuringRebuild, enabled, active)

        local entryData = data.data
        if self:DoesCategoryHaveAnyNewCollectibles(entryData.categoryIndex, entryData.subcategoryIndex) or (COLLECTIONS_BOOK_SINGLETON:IsCategoryIndexDLC(entryData.categoryIndex) and COLLECTIONS_BOOK_SINGLETON:DoesAnyDLCHaveQuestPending()) then
            control.icon:ClearIcons()
            control.icon:AddIcon(entryData.icon)
            control.icon:AddIcon(ZO_GAMEPAD_NEW_ICON_64)
            control.icon:Show()
        end
    end

    list:AddDataTemplate("ZO_GamepadMenuEntryTemplate", CategoryEntrySetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
    list:AddDataTemplateWithHeader("ZO_GamepadMenuEntryTemplate", CategoryEntrySetup, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadMenuEntryHeaderTemplate")

    local function CollectibleEntrySetup(control, data, selected, reselectingDuringRebuild, enabled, active)
        data.brandNew = data.data.isNew or COLLECTIONS_BOOK_SINGLETON:IsDLCIdQuestPending(data.collectibleId)
        if not data.hasNameBeenFormatted then
            data:SetEnabled(not data.blocked)
            data:SetText(zo_strformat(SI_COLLECTIBLE_NAME_FORMATTER, data.name))
            data.hasNameBeenFormatted = true
        end

        ZO_SharedGamepadEntry_OnSetup(control, data, selected, reselectingDuringRebuild, enabled, active)
    end

    list:AddDataTemplate("ZO_GamepadItemEntryTemplate", CollectibleEntrySetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
    list:AddDataTemplateWithHeader("ZO_GamepadItemEntryTemplate", CollectibleEntrySetup, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadMenuEntryHeaderTemplate")
end

function ZO_GamepadCollectionsBook:OnShowing()
    ZO_Gamepad_ParametricList_Screen.OnShowing(self)
    
    self:ShowList(self.categoryList)
    local browseInfo = self.browseToCollectibleInfo
    if browseInfo ~= nil then
        if browseInfo.subcategoryIndex then
            self:ViewSubcategory(browseInfo.categoryIndex, browseInfo.subcategoryIndex)
        else
            self:ViewCategory(browseInfo.categoryIndex)
        end
        self:SelectCollectibleEntry(browseInfo.collectibleId)
        self.browseToCollectibleInfo = nil
    end
end

function ZO_GamepadCollectionsBook:OnHide()
    self:HideCurrentList()
end

function ZO_GamepadCollectionsBook:RefreshHeader()
    ZO_GamepadGenericHeader_RefreshData(self.header, self.headerData)
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

    -- Subcategory Keybind
    self.subcategoryKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        -- Select Subcategory
        {
            name = GetString(SI_GAMEPAD_SELECT_OPTION),
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                self:ViewSubcategory()
            end,
            visible = function()
                local entryData = self.currentList.list:GetTargetData()
                return entryData ~= nil
            end,
            sound = SOUNDS.GAMEPAD_MENU_FORWARD,
        },
    }

    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.subcategoryKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, function() self:ShowList(self.categoryList) end)

    -- Collection Keybind
    self.collectionKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        -- Set Active or Put Away Collectible
        {
            name = function()
                local entryData = self.currentList.list:GetTargetData()
                local collectibleData = entryData.data
                local categoryType = collectibleData.categoryType
                local nameStringId
                if categoryType == COLLECTIBLE_CATEGORY_TYPE_DLC then
                    nameStringId = SI_DLC_BOOK_ACTION_ACCEPT_QUEST
                elseif categoryType == COLLECTIBLE_CATEGORY_TYPE_MEMENTO then
                    nameStringId = SI_COLLECTIBLE_ACTION_USE
                elseif categoryType == COLLECTIBLE_CATEGORY_TYPE_HOUSE then
                    nameStringId = collectibleData.unlocked and SI_HOUSING_BOOK_ACTION_TRAVEL_TO_HOUSE or SI_HOUSING_BOOK_ACTION_PREVIEW_HOUSE
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
                if collectibleData.categoryType == COLLECTIBLE_CATEGORY_TYPE_HOUSE then
                    RequestJumpToHouse(collectibleData.referenceData)
                    SCENE_MANAGER:ShowBaseScene()
                else
                    UseCollectible(collectibleData.collectibleId)
                end
            end,
            visible = function()
                local entryData = self.currentList.list:GetTargetData()
                if entryData and entryData.data then
                    local collectibleData = entryData.data
                    if collectibleData.categoryType == COLLECTIBLE_CATEGORY_TYPE_HOUSE then
                        return true
                    else
                        return collectibleData.useable
                    end
                else
                    return false
                end
            end,
            sound = SOUNDS.DEFAULT_CLICK,
            enabled = function()
                local entryData = self.currentList.list:GetTargetData()
                if entryData and entryData.data then
                    if entryData.data.categoryType == COLLECTIBLE_CATEGORY_TYPE_HOUSE then
                        return true
                    end
                    if entryData.data.useable then
                        local remaining = GetCollectibleCooldownAndDuration(entryData.data.collectibleId)
                        if entryData.data.active then
                            return true
                        elseif remaining > 0 then
                            return false, GetString(SI_COLLECTIONS_COOLDOWN_ERROR)
                        elseif entryData.data.blocked then
                            return false, GetString(SI_COLLECTIONS_BLOCKED_ERROR)
                        else
                            return true
                        end
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
                local categoryType = entryData.categoryType
                return entryData.data.unlocked and IsCollectibleCategorySlottable(categoryType)
            end,
            enabled = function()
                local entryData = self.currentList.list:GetTargetData()
                if entryData.isValidForPlayer then
                    return true
                else
                    return false, GetString(SI_COLLECTIONS_INVALID_ERROR)
                end
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
                local entryData = self.currentList.list:GetTargetData()
                local collectibleData = entryData.data
                return collectibleData.categoryType == COLLECTIBLE_CATEGORY_TYPE_DLC and not IsESOPlusSubscriber()
            end,
        },
    }

    local function OnCollectionListBack()
        if self.subcategoryList.list:IsEmpty() then
            self:ShowList(self.categoryList)
        else
            self:ShowList(self.subcategoryList)
        end
    end
    ZO_Gamepad_AddBackNavigationKeybindDescriptorsWithSound(self.collectionKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, OnCollectionListBack )
end

--Opens up the provided category, or the current category if no categoryIndex is provided
function ZO_GamepadCollectionsBook:ViewCategory(categoryIndex)
    if categoryIndex then
        self.categoryList.list:SetSelectedIndexWithoutAnimation(categoryIndex)
    end
    local entryData = self.categoryList.list:GetTargetData()
    local categoryIndex = entryData.data.categoryIndex

    self:BuildSubcategoryList(categoryIndex)
    if self.subcategoryList.list:IsEmpty() then
        self:BuildCollectionList(categoryIndex)
        self:ShowList(self.collectionList)
    else
        self:ShowList(self.subcategoryList)
    end
end

--Opens up the provided subcategory, or the current subcategory if no categoryIndex or subcategoryIndex is provided
function ZO_GamepadCollectionsBook:ViewSubcategory(categoryIndex, subcategoryIndex)
    if categoryIndex and subcategoryIndex then
        self:ViewCategory(categoryIndex)
        self.subcategoryList.list:SetSelectedIndexWithoutAnimation(subcategoryIndex)
    end

    local entryData = self.subcategoryList.list:GetTargetData()
    local categoryIndex = entryData.data.categoryIndex
    local subcategoryIndex = entryData.data.subcategoryIndex

    self:BuildCollectionList(categoryIndex, subcategoryIndex)
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

function ZO_GamepadCollectionsBook:ShowList(list, dontUpdateTitle)
    if self.currentList == list then
        return
    end
    self:HideCurrentList()

    self.currentList = list
    if list then
        KEYBIND_STRIP:AddKeybindButtonGroup(self.currentList.keybind)
        self:SetCurrentList(list.list)
    end

    if not dontUpdateTitle then
        self.headerData.titleText = zo_strformat(SI_COLLECTIBLE_NAME_FORMATTER, list.titleText)
        self:RefreshHeader()
    end

    if self.currentList == self.collectionList then
        local targetData = self.collectionList.list:GetTargetData()
        self:RefreshTooltip(targetData)
        self.notificationIdToClear = targetData.data.notificationId
        if self.notificationIdToClear or targetData.data.isNew then
            self.clearNewStatusOnSelectionChanged = true
        end
    else
        self:RefreshHeader()
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

        local targetData = self.collectionList.list:GetTargetData()
        if targetData.data.isNew then
            ClearCollectibleNewStatus(targetData.data.collectibleId)
        end

        self.clearNewStatusOnSelectionChanged = false
        self.notificationIdToClear = nil
        self.clearNewStatusCallId = nil
    end

    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.currentList.keybind)

    self:DisableCurrentList()
    self.currentList = nil

    self:RefreshTooltip(nil)
end

function ZO_GamepadCollectionsBook:OnCollectionUpdated()
    if not self.control:IsHidden() then
        if self.categoryList then
            self:ShowList(self.categoryList)
            self.categoryList.list:SetSelectedIndex(1)
            self:BuildCategoryList()
        end
    end
end

function ZO_GamepadCollectionsBook:OnCollectibleUpdated(collectibleId)
    if not self.control:IsHidden() then
        if self.currentList ~= nil and self.currentList == self.collectionList then
            self:BuildCollectionList(self.currentCategoryIndex, self.currentSubcategoryIndex)
        end
        self.categoryList.list:RefreshVisible()
        self.subcategoryList.list:RefreshVisible()
    end
end

function ZO_GamepadCollectionsBook:OnCollectibleStatusUpdated()
    if not self.control:IsHidden() then
        if self.currentList == self.collectionList then
            self.currentList.list:RefreshVisible()
        end
        self.categoryList.list:RefreshVisible()
        self.subcategoryList.list:RefreshVisible()
    end
end

function ZO_GamepadCollectionsBook:OnCollectionNotificationRemoved(notificationId, collectibleId)
    self:OnCollectibleStatusUpdated()
end

function ZO_GamepadCollectionsBook:OnCollectionNewStatusRemoved(collectibleId)
    self:OnCollectibleStatusUpdated()
end

function ZO_GamepadCollectionsBook:BuildCategoryList()
    self.categoryList.list:Clear()

    -- Add the categories entries
    for categoryIndex = 1, GetNumCollectibleCategories() do
        local categoryName, numSubCategories, numCollectibles, unlockedCollectibles = GetCollectibleCategoryInfo(categoryIndex)
        local gamepadIcon = GetCollectibleCategoryGamepadIcon(categoryIndex)
        categoryName = zo_strformat(SI_COLLECTIBLE_NAME_FORMATTER, categoryName)

        local entryData = ZO_GamepadEntryData:New(categoryName, gamepadIcon)
        entryData.data = {
            categoryIndex = categoryIndex,
            categoryName = categoryName,
            numCollectibles = numCollectibles,
            unlockedCollectibles = unlockedCollectibles,
            icon = gamepadIcon,
        }
        entryData:SetIconTintOnSelection(true)

        self.categoryList.list:AddEntry("ZO_GamepadMenuEntryTemplate", entryData)
    end
    self.categoryList.list:Commit()

    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.categoryList.keybind)
end

function ZO_GamepadCollectionsBook:GetCollectibleIds(categoryIndex, subCategoryIndex, index, ...)
    if index >= 1 then
        local id = GetCollectibleId(categoryIndex, subCategoryIndex, index)
        index = index - 1
        return self:GetCollectibleIds(categoryIndex, subCategoryIndex, index, id, ...)
    end
    return ...
end

function ZO_GamepadCollectionsBook:BuildSubcategoryList(categoryIndex)
    local subcategoryListInfo = self.subcategoryList
    local subcategoryList = subcategoryListInfo.list

    subcategoryList:Clear()

    local categoryName, numSubCategories, numCollectibles = GetCollectibleCategoryInfo(categoryIndex)
    subcategoryListInfo.titleText = categoryName

    -- Add the categories entries
    for subcategoryIndex = 1, numSubCategories do
        local subCategoryName, subNumCollectibles, subNumUnlockedCollectibles = GetCollectibleSubCategoryInfo(categoryIndex, subcategoryIndex)
        local formattedSubcategoryName = zo_strformat(SI_COLLECTIBLE_NAME_FORMATTER, subCategoryName)

        local icon
        --[[
        -- TODO: Show eye icon next to subcategories that have visible active collectibles
        -- commented out for now for some design investigation
        if COLLECTIONS_BOOK_SINGLETON.DoesCollectibleListHaveVisibleCollectible(self:GetCollectibleIds(categoryIndex, subcategoryIndex, subNumCollectibles)) then
            icon = "EsoUI/Art/Inventory/inventory_icon_visible.dds"
        end
        --]]

        local entryData = ZO_GamepadEntryData:New(formattedSubcategoryName, icon)
        entryData.data = {
            categoryIndex = categoryIndex,
            subcategoryIndex = subcategoryIndex,
            categoryName = formattedSubcategoryName,
            numCollectibles = subNumCollectibles,
            unlockedCollectibles = subNumUnlockedCollectibles,
            icon = icon,
        }
        entryData:SetIconTintOnSelection(true)

        subcategoryList:AddEntry("ZO_GamepadMenuEntryTemplate", entryData)
    end

    subcategoryList:Commit()

    KEYBIND_STRIP:UpdateKeybindButtonGroup(subcategoryListInfo.keybind)

    self.currentCategoryIndex = categoryIndex
end

function ZO_GamepadCollectionsBook:BuildCollectionList(categoryIndex, subcategoryIndex)
    local collectionListInfo = self.collectionList
    local collectionList = collectionListInfo.list

    collectionList:Clear()
    collectionListInfo.titleText = nil

    local unlockedData = {}
    local lockedData = {}

    local categoryName, numSubCategories, numCollectibles = GetCollectibleCategoryInfo(categoryIndex)

    -- If there are subcategories, but the neutral category doesn't have anything in it, then choose the first subcategory
    if not subcategoryIndex and numCollectibles == 0 and numSubCategories > 0 then
        subcategoryIndex = 1
    end

    local function BuildCollectibleDataEntry(categoryIndex, subcategoryIndex, collectibleIndex)
        local entryData = self:BuildCollectibleData(categoryIndex, subcategoryIndex, collectibleIndex)
        if not entryData.data.isPlaceholder then
            if entryData.data.unlocked then
                --Special case: The primary residence is sorted to the top of the category for housing
                local housingData = entryData.housingData
                if housingData and housingData.isPrimaryResidence then
                    table.insert(unlockedData, 1, entryData)
                else
                    table.insert(unlockedData, entryData)
                end
            else
                table.insert(lockedData, entryData)
            end
        end
    end

    -- Looking at a subcategory
    if subcategoryIndex then
        local subCategoryName, subNumCollectibles = GetCollectibleSubCategoryInfo(categoryIndex, subcategoryIndex)
        for collectibleIndex = 1, subNumCollectibles do
            BuildCollectibleDataEntry(categoryIndex, subcategoryIndex, collectibleIndex)
        end
        collectionListInfo.titleText = subCategoryName
    else
        -- Add top level collectibles
        for collectibleIndex = 1, numCollectibles do
            BuildCollectibleDataEntry(categoryIndex, nil, collectibleIndex)
        end

        -- If there are any subcategories, then this is the general tab
        if numSubCategories == 0 then
            collectionListInfo.titleText = categoryName
        end
    end

    self:BuildListFromTable(collectionList, unlockedData, GetString("SI_COLLECTIBLEUNLOCKSTATE", COLLECTIBLE_UNLOCK_STATE_UNLOCKED_OWNED))
    self:BuildListFromTable(collectionList, lockedData, GetString("SI_COLLECTIBLEUNLOCKSTATE", COLLECTIBLE_UNLOCK_STATE_LOCKED))

    collectionList:Commit()

    KEYBIND_STRIP:UpdateKeybindButtonGroup(collectionListInfo.keybind)

    self:RefreshTooltip(collectionList:GetTargetData())

    self.currentCategoryIndex = categoryIndex
    self.currentSubcategoryIndex = subcategoryIndex

    self.updateList = unlockedData
end

function ZO_GamepadCollectionsBook:UpdateCollectionListVisualLayer()
    local list = self.collectionList.list
    for i = 1, list:GetNumItems() do
        local data = list:GetDataForDataIndex(i)
        local visualLayerHidden, highestPriorityVisualLayerThatIsShowing = WouldCollectibleBeHidden(data.collectibleId)

        data.visualLayerHidden = visualLayerHidden
        data.highestPriorityVisualLayerThatIsShowing = highestPriorityVisualLayerThatIsShowing
    end
    self:RefreshTooltip(self.collectionList.list:GetTargetData())
end

function ZO_GamepadCollectionsBook:BuildCollectibleData(categoryIndex, subCategoryIndex, collectibleIndex)
    local collectibleId = GetCollectibleId(categoryIndex, subCategoryIndex, collectibleIndex)
    local name, description, iconFile, lockedIconFile, unlocked, purchasable, active, categoryType, hint, isPlaceholder = GetCollectibleInfo(collectibleId)
    local unlockState = GetCollectibleUnlockStateById(collectibleId)
    iconFile = unlocked and iconFile or lockedIconFile
    local backgroundFile = GetCollectibleGamepadBackgroundImage(collectibleId)
    local useable = IsCollectibleUsable(collectibleId)
    local collectibleBlocked = IsCollectibleBlocked(collectibleId)
    local notificationId = self:GetNotificationIdForCollectible(collectibleId)
    local visualLayerHidden, highestPriorityVisualLayerThatIsShowing = WouldCollectibleBeHidden(collectibleId)
    local isNew = IsCollectibleNew(collectibleId)
    local isValidForPlayer = IsCollectibleValidForPlayer(collectibleId)
    
    local referenceData = GetCollectibleReferenceId(collectibleId)

    local housingData
    if categoryType == COLLECTIBLE_CATEGORY_TYPE_HOUSE then
        local houseFoundInZoneId = GetHouseFoundInZoneId(referenceData)

        if hint == "" then
            hint = GetString(SI_HOUSING_BOOK_AVAILABLE_FOR_PURCHASE)
        else
            hint = ZO_CachedStrFormat(ZO_CACHED_STR_FORMAT_NO_FORMATTER, hint)
        end

        housingData = {
            location = GetZoneNameById(houseFoundInZoneId),
            houseCategoryType = GetHouseCategoryType(referenceData),
            isPrimaryResidence = IsPrimaryHouse(referenceData),
        }
    end

    if visualLayerHidden and not active then
        visualLayerHidden = false
    end

    local entryData = ZO_GamepadEntryData:New(name, iconFile)
    entryData.data = {
        collectibleId = collectibleId,
        referenceData = referenceData,
        name = name,
        nickname = GetCollectibleNickname(collectibleId),
        description = description,
        hint = hint,
        iconFile = iconFile,
        backgroundFile = backgroundFile,
        collectibleId = collectibleId,
        categoryType = categoryType,
        unlocked = unlocked,
        unlockState = unlockState,
        purchasable = purchasable,
        useable = useable,
        active = active,
        visualLayerHidden = visualLayerHidden,
        highestPriorityVisualLayerThatIsShowing = highestPriorityVisualLayerThatIsShowing,
        blocked = collectibleBlocked,
        isPlaceholder = isPlaceholder,
        notificationId = notificationId,
        hasNameBeenFormatted = false,
        isNew = isNew,
        isValidForPlayer = isValidForPlayer,
        housingData = housingData,
    }
    entryData.isEquippedInCurrentCategory = active

    if visualLayerHidden then
        entryData:SetIsHiddenByWardrobe(true)
    end

    entryData:InitializeCollectibleVisualData(entryData.data)

    if collectibleBlocked then
        entryData:SetIconDesaturation(1)
    else
        entryData:SetIconDesaturation(0)
    end

    local remainingMS, durationMS = GetCollectibleCooldownAndDuration(entryData.data.collectibleId)
    if remainingMS > 0 and durationMS > 0 then
        entryData:SetCooldown(remainingMS, durationMS)
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

        if oldSelectedData then
            if self.clearNewStatusOnSelectionChanged then
                local oldData = oldSelectedData.data
                if oldData.notificationId ~= nil then
                    RemoveCollectibleNotification(oldData.notificationId)
                    oldData.notificationId = nil
                end
                ClearCollectibleNewStatus(oldData.collectibleId)
                oldData.isNew = false
            end
        end

        self.clearNewStatusOnSelectionChanged = false

        if selectedData then
            local newData = selectedData.data
            self.notificationIdToClear = newData.notificationId
            if newData.isNew or self.notificationIdToClear ~= nil then
                self.clearNewStatusCallId = zo_callLater(self.trySetClearNewFlagCallback, TIME_NEW_PERSISTS_WHILE_SELECTED_MS)
            end
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
    if entryData and entryData.data then
        local collectibleData = entryData.data
        if collectibleData.categoryType == COLLECTIBLE_CATEGORY_TYPE_DLC then
            self:RefreshDLCTooltip(collectibleData)
        elseif collectibleData.categoryType == COLLECTIBLE_CATEGORY_TYPE_HOUSE then
            self:RefreshHousingTooltip(collectibleData)
        else
            self:RefreshStandardTooltip(collectibleData, entryData)
        end
    else
        SCENE_MANAGER:RemoveFragment(GAMEPAD_NAV_QUADRANT_2_3_BACKGROUND_FRAGMENT)
        SCENE_MANAGER:RemoveFragment(GAMEPAD_COLLECTIONS_BOOK_DLC_PANEL_FRAGMENT)
        SCENE_MANAGER:RemoveFragment(GAMEPAD_COLLECTIONS_BOOK_HOUSING_PANEL_FRAGMENT)
        GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
    end
end

function ZO_GamepadCollectionsBook:RefreshStandardTooltip(collectibleData, entryData)
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP, true)
    GAMEPAD_TOOLTIPS:SetBottomRailHidden(GAMEPAD_LEFT_TOOLTIP, true)

    local categoryName = collectibleData.categoryName
    local timeRemainingS = entryData:GetCooldownTimeRemainingMs() / 1000
    local SHOW_VISUAL_LAYER_INFO = true
    local SHOW_BLOCK_REASON = true
    GAMEPAD_TOOLTIPS:LayoutCollectible(GAMEPAD_LEFT_TOOLTIP, collectibleData.collectibleId, categoryName, collectibleData.name, collectibleData.nickname, collectibleData.purchasable, collectibleData.description, collectibleData.hint, collectibleData.isPlaceholder, SHOW_VISUAL_LAYER_INFO, timeRemainingS, SHOW_BLOCK_REASON)
end

function ZO_GamepadCollectionsBook:RefreshDLCTooltip(collectibleData)
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
    SCENE_MANAGER:AddFragment(GAMEPAD_COLLECTIONS_BOOK_DLC_PANEL_FRAGMENT)
end

function ZO_GamepadCollectionsBook:RefreshHousingTooltip(collectibleData)
    local housingPanel = self.housingPanelControl
    local housingData = collectibleData.housingData
    housingPanel.backgroundControl:SetTexture(collectibleData.backgroundFile)
    housingPanel.nameLabel:SetText(zo_strformat(SI_COLLECTIBLE_NAME_FORMATTER, collectibleData.name))
    housingPanel.locationLabel:SetText(ZO_CachedStrFormat(SI_ZONE_NAME, housingData.location))
    housingPanel.houseTypeLabel:SetText(GetString("SI_HOUSECATEGORYTYPE", housingData.houseCategoryType))
    housingPanel.descriptionLabel:SetText(collectibleData.description)
    housingPanel.collectedStatusLabel:SetText(GetString("SI_COLLECTIBLEUNLOCKSTATE", collectibleData.unlockState))
    
    local hasNickName = collectibleData.nickname ~= ""
    if hasNickName then
        housingPanel.nicknameLabel:SetText(ZO_CachedStrFormat(SI_TOOLTIP_COLLECTIBLE_NICKNAME, collectibleData.nickname))
    else
        housingPanel.nicknameLabel:SetText("")
    end

    if collectibleData.unlockState == COLLECTIBLE_UNLOCK_STATE_LOCKED then
        housingPanel.hintLabel:SetText(collectibleData.hint)
        
        housingPanel.hintLabel:SetHidden(false)
        housingPanel.primaryResidenceHeaderLabel:SetHidden(true)
        housingPanel.primaryResidenceValueLabel:SetHidden(true)
    else
        local primaryResidenceText = housingData.isPrimaryResidence and GetString(SI_YES) or GetString(SI_NO)
        housingPanel.primaryResidenceValueLabel:SetText(primaryResidenceText)
        
        housingPanel.primaryResidenceHeaderLabel:SetHidden(false)
        housingPanel.primaryResidenceValueLabel:SetHidden(false)
        housingPanel.hintLabel:SetHidden(true)
    end

    SCENE_MANAGER:AddFragment(GAMEPAD_NAV_QUADRANT_2_3_BACKGROUND_FRAGMENT)
    SCENE_MANAGER:AddFragment(GAMEPAD_COLLECTIONS_BOOK_HOUSING_PANEL_FRAGMENT)
end

function ZO_GamepadCollectionsBook:BrowseToCollectible(collectibleId, categoryIndex, subcategoryIndex)
    self.browseToCollectibleInfo = 
    {
        categoryIndex = categoryIndex,
        subcategoryIndex = subcategoryIndex,
        collectibleId = collectibleId,
    }

    SCENE_MANAGER:CreateStackFromScratch("mainMenuGamepad", "gamepadCollectionsBook")
end

--[[Global functions]]--
------------------------

function ZO_GamepadCollectionsBook:InitializeActionsDialog()
    local parametricDialog = ZO_GenericGamepadDialog_GetControl(GAMEPAD_DIALOGS.PARAMETRIC)
    ZO_Dialogs_RegisterCustomDialog(GAMEPAD_COLLECTIONS_ACTIONS_DIALOG_NAME,
    {
        gamepadInfo = 
        {
            dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
        },
        canQueue = true,
        setup = function(dialog)
            dialog:setupFunc()
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
                    callback = function(dialog)
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
                    callback = function(dialog)
                       ZO_Dialogs_ShowGamepadDialog(GAMEPAD_COLLECTIONS_RENAME_COLLECTIBLE_DIALOG_NAME, { collectibleId = dialog.data.collectibleId, name = dialog.data.name })
                    end,
                    visible = function(dialog)
                        return IsCollectibleRenameable(parametricDialog.data.collectibleId)
                    end
                },
            },
            -- Unlock Permanently (Purchase)
            {
                template = "ZO_GamepadMenuEntryTemplate",
                templateData = {
                    text = GetString(SI_GAMEPAD_DLC_BOOK_ACTION_OPEN_CROWN_STORE),
                    setup = ZO_SharedGamepadEntry_OnSetup,
                    callback = function(dialog)
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
                     data.callback(dialog)
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
    local parametricDialog = ZO_GenericGamepadDialog_GetControl(GAMEPAD_DIALOGS.PARAMETRIC)

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
                ZO_GenericGamepadDialog_ShowTooltip(parametricDialog)
            else
                ZO_GenericGamepadDialog_HideTooltip(parametricDialog)
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

        setup = function(dialog)
            dialog:setupFunc()
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

                        if parametricDialog.data then
                            control.editBoxControl:SetText(zo_strformat(SI_COLLECTIBLE_NAME_FORMATTER, parametricDialog.data.name))
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

function ZO_GamepadCollectionsBook:DoesCategoryHaveAnyNewCollectibles(categoryIndex, subcategoryIndex)
    return COLLECTIONS_BOOK_SINGLETON.DoesCategoryHaveAnyNewCollectibles(categoryIndex, subcategoryIndex)
end

function ZO_GamepadCollectionsBook:HasAnyNewCollectibles()
    return COLLECTIONS_BOOK_SINGLETON.HasAnyNewCollectibles()
end

function ZO_GamepadCollectionsBook:GetNotificationIdForCollectible(collectibleId)
    return NOTIFICATIONS_PROVIDER:GetNotificationIdForCollectible(collectibleId)
end

function ZO_GamepadCollectionsBook:OnUpdateCooldowns()
    for i, entryData in ipairs(self.updateList) do
        local collectibleData = entryData.data
        local _, durationMs = GetCollectibleCooldownAndDuration(collectibleData.collectibleId)
        if durationMs ~= entryData:GetCooldownDurationMs() then
            self:OnCollectibleUpdated(collectibleData.collectibleId)
            return
        end
    end
end

function ZO_GamepadCollectionsBook:UpdateActiveCollectibleCooldownTimer()
    if not self.control:IsHidden() and self.currentList == self.collectionList and self.collectionList then
        local entryData = self.currentList.list:GetTargetData()
        if entryData and entryData:IsOnCooldown() then
            self:RefreshTooltip(entryData)
        end
    end
end

--[[Global functions]]--
------------------------
function ZO_GamepadCollectionsBook_OnInitialize(control)
    GAMEPAD_COLLECTIONS_BOOK = ZO_GamepadCollectionsBook:New(control)
end
