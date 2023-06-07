-----------------------------
-- Companion Collection Book
-----------------------------

local GAMEPAD_COMPANION_COLLECTIONS_ACTIONS_DIALOG_NAME = "GAMEPAD_COMPANION_COLLECTIONS_ACTIONS_DIALOG"

ZO_CompanionCollectionBook_Gamepad = ZO_Gamepad_ParametricList_Screen:Subclass()

function ZO_CompanionCollectionBook_Gamepad:Initialize(control)
    COMPANION_COLLECTION_BOOK_GAMEPAD_FRAGMENT = ZO_FadeSceneFragment:New(control)

    COMPANION_COLLECTION_BOOK_GAMEPAD_SCENE = ZO_InteractScene:New("companionCollectionBookGamepad", SCENE_MANAGER, ZO_COMPANION_MANAGER:GetInteraction())
    COMPANION_COLLECTION_BOOK_GAMEPAD_SCENE:AddFragment(COMPANION_COLLECTION_BOOK_GAMEPAD_FRAGMENT)

    local ACTIVATE_ON_SHOW = true
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE, ACTIVATE_ON_SHOW, COMPANION_COLLECTION_BOOK_GAMEPAD_SCENE)

    self.currentSlotPreviews = {}

    self.trySetClearNewFlagCallback = function(callId)
        self:TrySetClearNewFlag(callId)
    end

    self:InitializeHeader()
    self:InitializeKeybindStripDescriptors()
    self:InitializeCategoryLists()
    self:InitializeActionsDialog()

    local function OnVisualLayerChanged()
        if COMPANION_COLLECTION_BOOK_GAMEPAD_SCENE:IsShowing() and self:IsViewingCollectionsList() then
            self:UpdateCollectionListVisualLayer()
        end
    end

    self.control:RegisterForEvent(EVENT_VISUAL_LAYER_CHANGED, OnVisualLayerChanged)
    SYSTEMS:RegisterGamepadObject(ZO_COLLECTIONS_SYSTEM_NAME, self)

    local function OnCollectibleUpdated()
        self:OnCollectibleUpdated()
    end

    ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("OnCollectibleUpdated", OnCollectibleUpdated)
    ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("OnCollectionUpdated", function(...) self:OnCollectionUpdated(...) end)
    ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("OnCollectibleNewStatusCleared", function(...) self:OnCollectibleNewStatusCleared(...) end)
    ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("OnCollectibleNotificationRemoved", function(...) self:OnCollectibleNotificationRemoved(...) end)
    COLLECTIONS_BOOK_SINGLETON:RegisterCallback("OnUpdateCooldowns", function(...) self:OnUpdateCooldowns(...) end)

    EVENT_MANAGER:RegisterForUpdate("ZO_GamepadCompanionCollectionsBook", 250, function() self:UpdateActiveCollectibleCooldownTimer() end)
    self.control:SetHandler("OnUpdate", function()
        -- TODO: For companion previewable
        local isPreviewingAvailable = IsCharacterPreviewingAvailable()
        if self.isPreviewAvailable ~= isPreviewingAvailable then
            self.isPreviewAvailable = isPreviewingAvailable
            KEYBIND_STRIP:UpdateKeybindButtonGroup(self.subcategoryKeybindStripDescriptor)
        end
    end)
end

function ZO_CompanionCollectionBook_Gamepad:InitializeHeader()
    self.headerData =
    {
        titleText = GetString(SI_COMPANION_MENU_COLLECTIONS_TITLE),
    }
    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)
end

function ZO_CompanionCollectionBook_Gamepad:InitializeCategoryLists()
    self:SetListsUseTriggerKeybinds(true)
    self.isPreviewAvailable = true

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
end

function ZO_CompanionCollectionBook_Gamepad:InitializeKeybindStripDescriptors()
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

    local function ClearPreviewList()
        self:ClearAllCurrentSlotPreviews()
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.subcategoryKeybindStripDescriptor)
    end

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

    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.subcategoryKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, function()
        self:ClearAllCurrentSlotPreviews()
        self:ShowList(self.categoryList)
    end)

    -- Collection Keybind
    self.collectionKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        -- Set Active or Put Away Collectible
        {
            name = function()
                local collectibleData = self:GetCurrentTargetData()
                local nameStringId = collectibleData:GetPrimaryInteractionStringId(GAMEPLAY_ACTOR_CATEGORY_COMPANION)
                return GetString(nameStringId)
            end,
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                local collectibleData = self:GetCurrentTargetData()
                collectibleData:Use(GAMEPLAY_ACTOR_CATEGORY_COMPANION)
            end,
            sound = SOUNDS.DEFAULT_CLICK,
            visible = function()
                local collectibleData = self:GetCurrentTargetData()
                if collectibleData then
                    return collectibleData:IsUsable(GAMEPLAY_ACTOR_CATEGORY_COMPANION)
                else
                    return false
                end
            end,
            enabled = function()
                local collectibleData = self:GetCurrentTargetData()
                if collectibleData:IsInstanceOf(ZO_CollectibleData) then
                    local remainingMs = GetCollectibleCooldownAndDuration(collectibleData:GetId())
                    if collectibleData:IsActive(GAMEPLAY_ACTOR_CATEGORY_COMPANION) then
                        return true
                    elseif remainingMs > 0 then
                        return false, GetString(SI_COLLECTIONS_COOLDOWN_ERROR)
                    elseif collectibleData:IsBlocked(GAMEPLAY_ACTOR_CATEGORY_COMPANION) then
                        -- TODO: Determine if companion collectible actions can be blocked
                        return false, GetString(SI_COLLECTIONS_BLOCKED_ERROR)
                    else
                        return true
                    end
                else
                    --This is an imitation collectible data
                    return not collectibleData:IsBlocked(GAMEPLAY_ACTOR_CATEGORY_COMPANION), collectibleData:GetBlockReason(GAMEPLAY_ACTOR_CATEGORY_COMPANION)
                end
            end
        },
        -- Actions
        {
            name = GetString(SI_GAMEPAD_INVENTORY_ACTION_LIST_KEYBIND),
            keybind = "UI_SHORTCUT_TERTIARY",
            callback = function()
                local collectibleData = self:GetCurrentTargetCollectibleData()

                local dialogData =
                {
                    collectibleId = collectibleData:GetId(),
                    name = collectibleData:GetNickname(),
                    active = collectibleData:IsActive(GAMEPLAY_ACTOR_CATEGORY_COMPANION),
                }
                ZO_Dialogs_ShowGamepadDialog(GAMEPAD_COMPANION_COLLECTIONS_ACTIONS_DIALOG_NAME, dialogData)
            end,
            visible = function()
                local collectibleData = self:GetCurrentTargetCollectibleData()

                if collectibleData then
                    return IsChatSystemAvailableForCurrentPlatform() or collectibleData:IsRenameable() or self:CanPurchaseCurrentTarget()
                else
                    return false
                end
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
    ZO_Gamepad_AddBackNavigationKeybindDescriptorsWithSound(self.collectionKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, OnCollectionListBack)
end

function ZO_CompanionCollectionBook_Gamepad:PerformUpdate()
   self.dirty = false
   self:BuildCategoryList()
end

function ZO_CompanionCollectionBook_Gamepad:SetupList(list)
    local function CategoryEntrySetup(control, data, selected, reselectingDuringRebuild, enabled, active)
        ZO_SharedGamepadEntry_OnSetup(control, data, selected, reselectingDuringRebuild, enabled, active)

        if data:HasAnyNewCollectibles() then
            control.icon:ClearIcons()
            if data:IsTopLevelCategory() then
                control.icon:AddIcon(data:GetGamepadIcon())
            end
            control.icon:AddIcon(ZO_GAMEPAD_NEW_ICON_64)
            control.icon:Show()
        end
    end

    list:AddDataTemplate("ZO_GamepadMenuEntryTemplate", CategoryEntrySetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
    list:AddDataTemplateWithHeader("ZO_GamepadMenuEntryTemplate", CategoryEntrySetup, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadMenuEntryHeaderTemplate")

    local function CollectibleEntrySetup(control, data, selected, reselectingDuringRebuild, enabled, active)
        local collectibleData = data.dataSource
        if collectibleData:IsInstanceOf(ZO_CollectibleData) then
            data:SetNew(collectibleData:IsNew())
        end
        data:SetEnabled(not collectibleData:IsBlocked(GAMEPLAY_ACTOR_CATEGORY_COMPANION))
        ZO_SetDefaultIconSilhouette(control.icon, collectibleData:IsLocked())

        ZO_SharedGamepadEntry_OnSetup(control, data, selected, reselectingDuringRebuild, enabled, active)
    end

    list:AddDataTemplate("ZO_GamepadCompanionCollectible", CollectibleEntrySetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
    list:AddDataTemplateWithHeader("ZO_GamepadCompanionCollectible", CollectibleEntrySetup, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadMenuEntryHeaderTemplate")
end

function ZO_CompanionCollectionBook_Gamepad:OnShowing()
    ZO_Gamepad_ParametricList_Screen.OnShowing(self)
    self:ShowList(self.categoryList)
    local browseInfo = self.browseToCollectibleInfo
    if browseInfo ~= nil then
        local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(browseInfo.collectibleId)
        local categoryData = collectibleData:GetCategoryData()

        if categoryData:IsSubcategory() then
            self:ViewSubcategory(categoryData)
        else
            self:ViewCategory(categoryData)
        end

        self:SelectCollectibleEntry(browseInfo.collectibleId)

        self.browseToCollectibleInfo = nil
    end
end

function ZO_CompanionCollectionBook_Gamepad:OnHide()
    self:HideCurrentList()
    self:ClearAllCurrentSlotPreviews()
end

function ZO_CompanionCollectionBook_Gamepad:RefreshHeader()
    ZO_GamepadGenericHeader_RefreshData(self.header, self.headerData)
end

--Opens up the provided category, or the current category if no categoryData is provided
function ZO_CompanionCollectionBook_Gamepad:ViewCategory(categoryData)
    if categoryData then
        for index = 1, self.categoryList.list:GetNumEntries() do
            local entryData = self.categoryList.list:GetEntryData(index)
            if entryData.dataSource == categoryData then
                self.categoryList.list:SetSelectedIndexWithoutAnimation(index)
            end
        end
    end

    categoryData = self.categoryList.list:GetTargetData()

    self:BuildSubcategoryList(categoryData)
    if self.subcategoryList.list:IsEmpty() then
        local RESET_SELECTION_TO_TOP = true
        self:BuildCollectionList(categoryData, RESET_SELECTION_TO_TOP)
        self:ShowList(self.collectionList)
    else
        self:ShowList(self.subcategoryList)
    end
end

function ZO_CompanionCollectionBook_Gamepad:SelectSubCategoryData(subcategoryData)
    for index = 1, self.subcategoryList.list:GetNumEntries() do
        local entryData = self.subcategoryList.list:GetEntryData(index)
        if entryData.dataSource == subcategoryData then
            self.subcategoryList.list:SetSelectedIndexWithoutAnimation(index)
        end
    end
end

--Opens up the provided subcategory, or the current subcategory if no subcategoryData is provided
function ZO_CompanionCollectionBook_Gamepad:ViewSubcategory(subcategoryData)
    if subcategoryData and subcategoryData:IsSubcategory() then
        self:ViewCategory(subcategoryData:GetParentData())

        self:SelectSubCategoryData(subcategoryData)
    end

    subcategoryData = self.subcategoryList.list:GetTargetData()

    local RESET_SELECTION_TO_TOP = true
    self:BuildCollectionList(subcategoryData, RESET_SELECTION_TO_TOP)
    self:ShowList(self.collectionList)
end

function ZO_CompanionCollectionBook_Gamepad:SelectCollectibleEntry(collectibleId)
    if collectibleId then
        local list = self.collectionList.list
        for i = 1, list:GetNumItems() do
            local collectibleData = list:GetDataForDataIndex(i)
            if collectibleData:GetId() == collectibleId then
                list:SetSelectedIndexWithoutAnimation(i)
                break
            end
        end
    end
end

function ZO_CompanionCollectionBook_Gamepad:ShowList(list, dontUpdateTitle)
    if self.currentList == list then
        return
    end
    self:HideCurrentList()

    self.currentList = list
    if list then
        local listObject = list.list
        KEYBIND_STRIP:AddKeybindButtonGroup(self.currentList.keybind)
        self:SetCurrentList(listObject)
        local targetData = listObject:GetTargetData()
        self:RefreshRightPanel(targetData)
        if list == self.subcategoryList then
            self:StartPreviewFromBase()
        else
            ApplyChangesToPreviewCollectionShown()
        end
    end

    if not dontUpdateTitle then
        self.headerData.titleText = list.titleText
        self:RefreshHeader()
    end

    if self:IsViewingCollectionsList() then
        local collectibleData = self:GetCurrentTargetCollectibleData()
        if collectibleData then
            self.notificationIdToClear = collectibleData.notificationId
            if self.notificationIdToClear or collectibleData:IsNew() then
                self.clearNewStatusOnSelectionChanged = true
            end
        end
    else
        self:RefreshHeader()
    end
end

function ZO_CompanionCollectionBook_Gamepad:HideCurrentList()
    if self.currentList == nil then
        return
    end

    if self:IsViewingCollectionsList() then
        if self.notificationIdToClear then
            RemoveCollectibleNotification(self.notificationIdToClear)
        end

        local collectibleData = self:GetCurrentTargetCollectibleData()
        if collectibleData and collectibleData:IsNew() then
            ClearCollectibleNewStatus(collectibleData:GetId())
        end

        self.clearNewStatusOnSelectionChanged = false
        self.notificationIdToClear = nil
        self.clearNewStatusCallId = nil
    end

    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.currentList.keybind)

    self:DisableCurrentList()

    self.currentList = nil
end

function ZO_CompanionCollectionBook_Gamepad:OnCollectionUpdated(collectionUpdateType)
    if not self.control:IsHidden() then
        if collectionUpdateType == ZO_COLLECTION_UPDATE_TYPE.RANDOM_MOUNT_SETTING_CHANGED then
            -- if random mount changed, we really just want to update the current list just like
            -- OnCollectibleUpdated does.
            self:OnCollectibleUpdated()
        elseif self.categoryList then
            self:ShowList(self.categoryList)
            self.categoryList.list:SetSelectedIndex(1)
            self:BuildCategoryList()
        end
    end
end

function ZO_CompanionCollectionBook_Gamepad:OnCollectibleUpdated()
    if not self.control:IsHidden() then
        self:BuildCategoryList()

        local currentCategoryData = self.currentCategoryData
        if currentCategoryData then
            if currentCategoryData:IsSubcategory() then
                self:BuildSubcategoryList(currentCategoryData:GetParentData())
                self.currentCategoryData = currentCategoryData -- Rebuilding the subcategory resets the current category to the parent, so we need to set it back
            elseif currentCategoryData:GetNumSubcategories() > 0 then
                self:BuildSubcategoryList(currentCategoryData)
            end

            if self:IsViewingCollectionsList() then
                local DONT_RESET_SELECTION_TO_TOP = false
                self:BuildCollectionList(currentCategoryData, DONT_RESET_SELECTION_TO_TOP)
            end
        end
    end
end

function ZO_CompanionCollectionBook_Gamepad:OnCollectibleStatusUpdated()
    if not self.control:IsHidden() then
        if self:IsViewingCollectionsList() then
            self.currentList.list:RefreshVisible()
        end
        self.categoryList.list:RefreshVisible()
        self.subcategoryList.list:RefreshVisible()
    end
end

function ZO_CompanionCollectionBook_Gamepad:OnCollectibleNotificationRemoved(notificationId, collectibleId)
    self:OnCollectibleStatusUpdated()
end

function ZO_CompanionCollectionBook_Gamepad:OnCollectibleNewStatusCleared(collectibleId)
    self:OnCollectibleStatusUpdated()
end

function ZO_CompanionCollectionBook_Gamepad:BuildCategoryList()
    self.categoryList.list:Clear()

    -- Add the categories entries
    for categoryIndex, categoryData in ZO_COLLECTIBLE_DATA_MANAGER:CategoryIterator({ ZO_CollectibleCategoryData.IsStandardCategory, ZO_CollectibleCategoryData.HasShownCollectiblesInCollection, ZO_CollectibleCategoryData.HasAnyCompanionUsableCollectibles }) do
        local formattedCategoryName = categoryData:GetFormattedName()
        local gamepadIcon = categoryData:GetGamepadIcon()

        local entryData = ZO_GamepadEntryData:New(formattedCategoryName, gamepadIcon)
        entryData:SetDataSource(categoryData)
        entryData:SetIconTintOnSelection(true)

        self.categoryList.list:AddEntry("ZO_GamepadMenuEntryTemplate", entryData)
    end
    self.categoryList.list:Commit()

    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.categoryList.keybind)
end

function ZO_CompanionCollectionBook_Gamepad:BuildSubcategoryList(categoryData)
    local subcategoryListInfo = self.subcategoryList
    local subcategoryList = subcategoryListInfo.list

    subcategoryList:Clear()

    subcategoryListInfo.titleText = categoryData:GetFormattedName()

    -- Add the categories entries
    for subcategoryIndex, subcategoryData in categoryData:SubcategoryIterator({ ZO_CollectibleCategoryData.HasShownCollectiblesInCollection, ZO_CollectibleCategoryData.HasAnyCompanionUsableCollectibles }) do
        local formattedSubcategoryName = subcategoryData:GetFormattedName()
        
        local entryData = ZO_GamepadEntryData:New(formattedSubcategoryName)
        entryData:SetDataSource(subcategoryData)
        entryData:SetIconTintOnSelection(true)

        subcategoryList:AddEntry("ZO_GamepadMenuEntryTemplate", entryData)
    end

    subcategoryList:Commit()

    KEYBIND_STRIP:UpdateKeybindButtonGroup(subcategoryListInfo.keybind)

    self.currentCategoryData = categoryData
end

function ZO_CompanionCollectionBook_Gamepad:BuildCollectionList(categoryData, resetSelectionToTop)
    local collectionListInfo = self.collectionList
    local collectionList = collectionListInfo.list

    collectionList:Clear()
    collectionListInfo.titleText = nil

    local unlockedData = {}
    local lockedData = {}
    
    for _, collectibleData in categoryData:SortedCollectibleIterator({ ZO_CollectibleData.IsShownInCollection, ZO_CollectibleData.IsCollectibleCategoryCompanionUsable, ZO_CollectibleData.IsCollectibleAvailableToCompanion }) do
        local entryData = self:BuildCollectibleData(collectibleData)
        if collectibleData:IsUnlocked() then
            table.insert(unlockedData, entryData)
        else
            table.insert(lockedData, entryData)
        end
    end

    collectionListInfo.titleText = categoryData:GetFormattedName()

    if #unlockedData > 0 or #lockedData > 0 then
        -- Add defaults
        local collectibleCategoryTypesInCategory = categoryData:GetCollectibleCategoryTypesInCategory()
        for categoryType in pairs(collectibleCategoryTypesInCategory) do
            local setToDefaultCollectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetSetToDefaultCollectibleData(categoryType, GAMEPLAY_ACTOR_CATEGORY_COMPANION)
            if setToDefaultCollectibleData then
                local defaultEntryData = self:BuildCollectibleCategorySetToDefaultData(setToDefaultCollectibleData)
                collectionList:AddEntry("ZO_GamepadCompanionCollectible", defaultEntryData)
            end
        end

        if collectibleCategoryTypesInCategory[COLLECTIBLE_CATEGORY_TYPE_MOUNT] then
            local setRandomMountData = ZO_RandomMountCollectibleData:New(RANDOM_MOUNT_TYPE_ANY)
            local randomMountEntryData = self:BuildCollectibleCategorySetRandomSelectionData(setRandomMountData)
            ZO_UpdateCollectibleEntryDataIconVisuals(randomMountEntryData, GAMEPLAY_ACTOR_CATEGORY_COMPANION)
            collectionList:AddEntry("ZO_GamepadCompanionCollectible", randomMountEntryData)
        end
    end

    self:BuildListFromTable(collectionList, unlockedData, GetString("SI_COLLECTIBLEUNLOCKSTATE", COLLECTIBLE_UNLOCK_STATE_UNLOCKED_OWNED))
    self:BuildListFromTable(collectionList, lockedData, GetString("SI_COLLECTIBLEUNLOCKSTATE", COLLECTIBLE_UNLOCK_STATE_LOCKED))

    collectionList:Commit(resetSelectionToTop)

    KEYBIND_STRIP:UpdateKeybindButtonGroup(collectionListInfo.keybind)

    self.currentCategoryData = categoryData

    self.updateList = unlockedData
end

function ZO_CompanionCollectionBook_Gamepad:UpdateCollectionListVisualLayer()
    local list = self.collectionList.list
    for i = 1, list:GetNumItems() do
        local collectibleData = list:GetDataForDataIndex(i)

        -- ESO-725038: ZO_SetToDefaultCollectibleData doesn't implement IsVisualLayerHidden
        -- so if the visual layer updates while a collectibleData of this type is shown we don't
        -- want to attempt to show it. Should we run into other instantiations of ZO_SetToDefaultCollectibleData
        -- besides "Default Mount" that have a visual layer we should implement the function on that class.
        -- An example of this happening is when werewolf ends while viewing the
        -- companion mount subcategory which has a default collectible entry of "Default Mount"
        if collectibleData:IsInstanceOf(ZO_CollectibleData) then
            collectibleData:SetIsHiddenByWardrobe(collectibleData:IsVisualLayerHidden(GAMEPLAY_ACTOR_CATEGORY_COMPANION))
        end
    end
    self:RefreshRightPanel(self.collectionList.list:GetTargetData())
end

function ZO_CompanionCollectionBook_Gamepad:BuildCollectibleCategorySetToDefaultData(setToDefaultCollectibleData)
    local entryData = ZO_GamepadEntryData:New(setToDefaultCollectibleData:GetName(), setToDefaultCollectibleData:GetIcon())
    entryData:SetDataSource(setToDefaultCollectibleData)
    entryData.actorCategory = GAMEPLAY_ACTOR_CATEGORY_COMPANION
    entryData.isEquippedInCurrentCategory = setToDefaultCollectibleData:IsActive(GAMEPLAY_ACTOR_CATEGORY_COMPANION) and not setToDefaultCollectibleData:ShouldSuppressActiveState(GAMEPLAY_ACTOR_CATEGORY_COMPANION)

    return entryData
end

function ZO_CompanionCollectionBook_Gamepad:BuildCollectibleCategorySetRandomSelectionData(collectibleData)
    local entryData = ZO_GamepadEntryData:New(collectibleData:GetName(), collectibleData:GetIcon())
    entryData:SetDataSource(collectibleData)
    entryData.actorCategory = GAMEPLAY_ACTOR_CATEGORY_COMPANION
    entryData.isEquippedInCurrentCategory = collectibleData:IsActive(GAMEPLAY_ACTOR_CATEGORY_COMPANION)

    return entryData
end

function ZO_CompanionCollectionBook_Gamepad:BuildCollectibleData(collectibleData)
    local collectibleId = collectibleData:GetId()

    local entryData = ZO_GamepadEntryData:New(collectibleData:GetFormattedName(), collectibleData:GetIcon())
    entryData:SetDataSource(collectibleData)
    entryData:SetCooldownIcon(collectibleData:GetIcon())

    entryData.actorCategory = GAMEPLAY_ACTOR_CATEGORY_COMPANION
    entryData.isEquippedInCurrentCategory = collectibleData:IsActive(GAMEPLAY_ACTOR_CATEGORY_COMPANION) and not collectibleData:ShouldSuppressActiveState(GAMEPLAY_ACTOR_CATEGORY_COMPANION)

    entryData:SetIsHiddenByWardrobe(collectibleData:IsVisualLayerHidden(GAMEPLAY_ACTOR_CATEGORY_COMPANION))

    ZO_UpdateCollectibleEntryDataIconVisuals(entryData, GAMEPLAY_ACTOR_CATEGORY_COMPANION)

    local remainingMs, durationMs = GetCollectibleCooldownAndDuration(collectibleId)
    if remainingMs > 0 and durationMs > 0 then
        entryData:SetCooldown(remainingMs, durationMs)
        entryData.refreshWhenFinished = true
    end

    return entryData
end

function ZO_CompanionCollectionBook_Gamepad:BuildListFromTable(list, dataTable, header)
    if #dataTable >= 1 then
        for i,entryData in ipairs(dataTable) do
            if i == 1 then
                entryData:SetHeader(header)
                list:AddEntryWithHeader("ZO_GamepadCompanionCollectible", entryData)
            else
                list:AddEntry("ZO_GamepadCompanionCollectible", entryData)
            end
        end
    end
end

function ZO_CompanionCollectionBook_Gamepad:OnSelectionChanged(list, selectedData, oldSelectedData)
    if list == self.collectionList.list then
        self.notificationIdToClear = nil
        self.clearNewStatusCallId = nil

        if oldSelectedData then
            if self.clearNewStatusOnSelectionChanged then
                if oldSelectedData.notificationId ~= nil then
                    RemoveCollectibleNotification(oldSelectedData.notificationId)
                    oldSelectedData.notificationId = nil
                end
                ClearCollectibleNewStatus(oldSelectedData:GetId())
            end
        end

        self.clearNewStatusOnSelectionChanged = false

        if selectedData then
            self.notificationIdToClear = selectedData.notificationId
            if selectedData:IsNew() or self.notificationIdToClear ~= nil then
                self.clearNewStatusCallId = zo_callLater(self.trySetClearNewFlagCallback, TIME_NEW_PERSISTS_WHILE_SELECTED_MS)
            end
        end
    end
    
    if self.currentList and list == self.currentList.list then
        self:RefreshRightPanel(selectedData)
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.currentList.keybind)
    end
end

function ZO_CompanionCollectionBook_Gamepad:TrySetClearNewFlag(callId)
    if self.clearNewStatusCallId == callId then
        self.clearNewStatusOnSelectionChanged = true
    end
end

function ZO_CompanionCollectionBook_Gamepad:RefreshRightPanel(entryData)
    if self:IsViewingCollectionsList() then
        if entryData then
            self:RefreshStandardTooltip(entryData)
        else
            GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
        end
    else
        GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
    end
end

function ZO_CompanionCollectionBook_Gamepad:RefreshStandardTooltip(collectibleData)
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP, true)

    if collectibleData:IsInstanceOf(ZO_CollectibleData) then
        local timeRemainingS = collectibleData:GetCooldownTimeRemainingMs() / 1000
        local SHOW_VISUAL_LAYER_INFO = true
        local SHOW_BLOCK_REASON = true
        GAMEPAD_TOOLTIPS:LayoutCollectibleFromData(GAMEPAD_LEFT_TOOLTIP, collectibleData, SHOW_VISUAL_LAYER_INFO, timeRemainingS, SHOW_BLOCK_REASON, GAMEPLAY_ACTOR_CATEGORY_COMPANION)
    else
        GAMEPAD_TOOLTIPS:LayoutImitationCollectibleFromData(GAMEPAD_LEFT_TOOLTIP, collectibleData, GAMEPLAY_ACTOR_CATEGORY_COMPANION)
    end
end

function ZO_CompanionCollectionBook_Gamepad:ClearAllCurrentSlotPreviews()
    ApplyChangesToPreviewCollectionShown()
    ZO_ClearTable(self.currentSlotPreviews)
end

function ZO_CompanionCollectionBook_Gamepad:HasAnyCurrentSlotPreviews()
    return NonContiguousCount(self.currentSlotPreviews) > 0
end

function ZO_CompanionCollectionBook_Gamepad:StartPreviewFromBase()
    ITEM_PREVIEW_GAMEPAD:PreviewUnequipOutfit(GAMEPLAY_ACTOR_CATEGORY_COMPANION)
end

function ZO_CompanionCollectionBook_Gamepad:OnUpdateCooldowns()
    for i, collectibleData in ipairs(self.updateList) do
        local remainingMs = GetCollectibleCooldownAndDuration(collectibleData:GetId())
        if remainingMs ~= collectibleData:GetCooldownTimeRemainingMs() or (remainingMs <= 0 and collectibleData.refreshWhenFinished) then
            self:OnCollectibleUpdated(collectibleData:GetId())
            return
        end
    end
end

function ZO_CompanionCollectionBook_Gamepad:UpdateActiveCollectibleCooldownTimer()
    if not self.control:IsHidden() and self:IsViewingCollectionsList() then
        local collectibleData = self:GetCurrentTargetCollectibleData()
        if collectibleData and collectibleData:IsOnCooldown() then
            self:RefreshRightPanel(collectibleData)
        end
    end
end

function ZO_CompanionCollectionBook_Gamepad:IsViewingCollectionsList()
    return self.currentList == self.collectionList
end

function ZO_CompanionCollectionBook_Gamepad:IsViewingCategoryList()
    return self.currentList == self.categoryList
end

function ZO_CompanionCollectionBook_Gamepad:IsViewingSubcategoryList()
    return self.currentList == self.subcategoryList
end

function ZO_CompanionCollectionBook_Gamepad:GetCurrentTargetData()
    return self.currentList.list:GetTargetData()
end

function ZO_CompanionCollectionBook_Gamepad:GetCurrentTargetCollectibleData()
    local targetData = self:GetCurrentTargetData()
    if targetData and targetData:IsInstanceOf(ZO_CollectibleData) then
        return targetData
    end
    return nil
end

function ZO_CompanionCollectionBook_Gamepad:CanPurchaseCurrentTarget()
    if self:IsViewingCollectionsList() then
        local collectibleData = self:GetCurrentTargetCollectibleData()
        return collectibleData and collectibleData:IsPurchasable() and collectibleData:CanAcquire() and not collectibleData:IsHouse()
    end
    return false
end

-----------------
-- Actions Dialog
-----------------

function ZO_CompanionCollectionBook_Gamepad:InitializeActionsDialog()
    ZO_Dialogs_RegisterCustomDialog(GAMEPAD_COMPANION_COLLECTIONS_ACTIONS_DIALOG_NAME,
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
                templateData =
                {
                    text = GetString(SI_ITEM_ACTION_LINK_TO_CHAT),
                    setup = ZO_SharedGamepadEntry_OnSetup,
                    callback = function(dialog)
                        local link = ZO_LinkHandler_CreateChatLink(GetCollectibleLink, dialog.data.collectibleId)
                        ZO_LinkHandler_InsertLinkAndSubmit(zo_strformat(SI_TOOLTIP_ITEM_NAME, link))
                    end,
                    visible = IsChatSystemAvailableForCurrentPlatform
                },
            },
            -- Unlock Permanently (Purchase)
            {
                template = "ZO_GamepadMenuEntryTemplate",
                templateData =
                {
                    text = GetString(SI_GAMEPAD_DLC_BOOK_ACTION_OPEN_CROWN_STORE),
                    setup = ZO_SharedGamepadEntry_OnSetup,
                    callback = function(dialog)
                        local collectibleData = self:GetCurrentTargetData()
                        local searchTerm = zo_strformat(SI_CROWN_STORE_SEARCH_FORMAT_STRING, collectibleData:GetName())
                        ShowMarketAndSearch(searchTerm, MARKET_OPEN_OPERATION_COLLECTIONS_DLC)
                    end,
                    visible = function()
                        return self:CanPurchaseCurrentTarget()
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

-----------------------------
-- Global XML Functions
-----------------------------

function ZO_CompanionCollectionBook_Gamepad_OnInitialize(control)
    COMPANION_COLLECTION_BOOK_GAMEPAD = ZO_CompanionCollectionBook_Gamepad:New(control)
end