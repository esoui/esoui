ZO_GAMEPAD_COLLECTIONS_PANEL_TEXTURE_SQUARE_DIMENSION = 1024
ZO_GAMEPAD_COLLECTIONS_PANEL_TEXTURE_COORD_RIGHT = ZO_GAMEPAD_QUADRANT_2_3_CONTENT_BACKGROUND_WIDTH / ZO_GAMEPAD_COLLECTIONS_PANEL_TEXTURE_SQUARE_DIMENSION

local GAMEPAD_COLLECTIONS_ACTIONS_DIALOG_NAME = "GAMEPAD_COLLECTIONS_ACTIONS_DIALOG"
local GAMEPAD_COLLECTIONS_RENAME_COLLECTIBLE_DIALOG_NAME = "GAMEPAD_COLLECTIONS_INVENTORY_RENAME_COLLECTIBLE"
local VISIBLE_ICON = "EsoUI/Art/Inventory/inventory_icon_visible.dds"

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

    self:InitializeOutfitSelector()

    self.headerData = {}
    self:RefreshHeader()

    self.currentSlotPreviews = {}

    self:InitializeDLCPanel()
    self:InitializeHousingPanel()
    self:InitializeGridListPanel()
    self:InitializeActionsDialog()
    self:InitializeRenameCollectibleDialog()

    self.control:RegisterForEvent(EVENT_VISUAL_LAYER_CHANGED, function()
                                                                    if GAMEPAD_COLLECTIONS_BOOK_SCENE:IsShowing() then
                                                                        if self:IsViewingCollectionsList() then
                                                                            self:UpdateCollectionListVisualLayer()
                                                                        end
                                                                    end
                                                                end)

    SYSTEMS:RegisterGamepadObject(ZO_COLLECTIONS_SYSTEM_NAME, self)

    local function OnCollectibleUpdated()
        self:OnCollectibleUpdated()
    end

    ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("OnCollectibleUpdated", OnCollectibleUpdated)
    ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("OnCollectionUpdated", function(...) self:OnCollectionUpdated(...) end)
    ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("PrimaryResidenceSet", OnCollectibleUpdated)
    ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("OnCollectibleNewStatusCleared", function(...) self:OnCollectibleNewStatusCleared(...) end)
    ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("OnCollectibleNotificationRemoved", function(...) self:OnCollectibleNotificationRemoved(...) end)
    COLLECTIONS_BOOK_SINGLETON:RegisterCallback("OnUpdateCooldowns", function(...) self:OnUpdateCooldowns(...) end)
    EVENT_MANAGER:RegisterForUpdate("ZO_GamepadCollectionsBook", 250, function() self:UpdateActiveCollectibleCooldownTimer() end)
end

function ZO_GamepadCollectionsBook:InitializeDLCPanel()
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

function ZO_GamepadCollectionsBook:RefreshGridEntryMultiIcon(control, data)
    local statusControl = control.statusMultiIcon
    if statusControl == nil then
        return
    end
    statusControl:ClearIcons()
    if data.isEmptyCell then
        return
    end

    local showMultiIcon = false
    if self:IsPreviewingOutfitStyle(data) then
        statusControl:AddIcon(VISIBLE_ICON)
        showMultiIcon = true
    end
    if data:IsNew() then
        statusControl:AddIcon(ZO_GAMEPAD_NEW_ICON_32)
        showMultiIcon = true
    end

    if showMultiIcon then
        statusControl:Show()
    end
end

function ZO_GamepadCollectionsBook:InitializeGridListPanel()
    local gridListPanel = self.control:GetNamedChild("GridListPanel")
    self.gridListPanelControl = gridListPanel
    self.gridListPanelList = ZO_SingleTemplateGridScrollList_Gamepad:New(gridListPanel, ZO_GRID_SCROLL_LIST_AUTOFILL)

    local function OutfitStyleGridEntrySetup(control, data, list)
        ZO_DefaultGridEntrySetup(control, data, list)

        if data.iconDesaturation == 1 or data.isEmptyCell then
            control:SetAlpha(0.4)
        else
            control:SetAlpha(1)
        end

        self:RefreshGridEntryMultiIcon(control, data)
        -- TODO: find a way to share this with the generic get border function
        control.borderBackground:SetEdgeTexture("EsoUI/Art/Tooltips/Gamepad/gp_toolTip_edge_16.dds", ZO_GAMEPAD_OUTFIT_GRID_ENTRY_BORDER_EDGE_WIDTH, ZO_GAMEPAD_OUTFIT_GRID_ENTRY_BORDER_EDGE_HEIGHT)
    end

    local HIDE_CALLBACK = nil
    local RESET_CONTROL_FUNC = nil
    local SPACING_X = 6
    self.gridListPanelList:SetGridEntryTemplate("ZO_Collections_Outfit_GridEntry_Template_Gamepad", ZO_GAMEPAD_OUTFIT_GRID_ENTRY_DIMENSIONS, ZO_GAMEPAD_OUTFIT_GRID_ENTRY_DIMENSIONS, OutfitStyleGridEntrySetup, HIDE_CALLBACK, RESET_CONTROL_FUNC, SPACING_X, ZO_GRID_SCROLL_LIST_DEFAULT_SPACING_GAMEPAD)
    self.gridListPanelList:SetHeaderTemplate(ZO_GRID_SCROLL_LIST_DEFAULT_HEADER_TEMPLATE_GAMEPAD, ZO_GRID_SCROLL_LIST_DEFAULT_HEADER_TEMPLATE_HEIGHT, ZO_DefaultGridHeaderSetup)
    self.gridListPanelList:SetHeaderPrePadding(ZO_GRID_SCROLL_LIST_DEFAULT_SPACING_GAMEPAD)
    self.gridListPanelList:SetOnSelectedDataChangedCallback(function(previousData, newData) self:OnGridListSelectedDataChanged(previousData, newData) end)
end

function ZO_GamepadCollectionsBook:SetupList(list)
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
        data:SetNew(collectibleData:IsNew())
        data:SetEnabled(not collectibleData:IsBlocked())
        ZO_SharedGamepadEntry_OnSetup(control, data, selected, reselectingDuringRebuild, enabled, active)
    end

    list:AddDataTemplate("ZO_GamepadCollectibleEntryTemplate", CollectibleEntrySetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
    list:AddDataTemplateWithHeader("ZO_GamepadCollectibleEntryTemplate", CollectibleEntrySetup, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadMenuEntryHeaderTemplate")
end

function ZO_GamepadCollectionsBook:OnShowing()
    ZO_Gamepad_ParametricList_Screen.OnShowing(self)
    self:ShowList(self.categoryList)
    local browseInfo = self.browseToCollectibleInfo
    if browseInfo ~= nil then
        local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(browseInfo.collectibleId)
        local categoryData = collectibleData:GetCategoryData()
        local isOutfitStyle = categoryData:IsSpecializedCategory(COLLECTIBLE_CATEGORY_SPECIALIZATION_OUTFIT_STYLES)

        if isOutfitStyle then
            self:ViewCategory(categoryData:GetParentData())
            self:SelectSubCategoryData(categoryData)
        else
            if categoryData:IsSubcategory() then
                self:ViewSubcategory(categoryData)
            else
                self:ViewCategory(categoryData)
            end

            self:SelectCollectibleEntry(browseInfo.collectibleId)
        end

        self.browseToCollectibleInfo = nil
    elseif self.savedOutfitStyleIndex then
        self:ShowList(self.subcategoryList)
        self.subcategoryList.list:SetSelectedIndexWithoutAnimation(self.savedOutfitStyleIndex)
    elseif self.savedQuickSlotCollectibleData then
        local categoryData = self.savedQuickSlotCollectibleData:GetCategoryData()
        if categoryData:IsSubcategory() then
            self:ViewSubcategory(categoryData)
        else
            self:ViewCategory(categoryData)
        end
        self:SelectCollectibleEntry(self.savedQuickSlotCollectibleData:GetId())
    end
    
    self.savedOutfitStyleIndex = nil
    self.savedQuickSlotCollectibleData = nil
end

function ZO_GamepadCollectionsBook:OnHide()
    if self.gridListPanelList:IsActive() then
        self:ExitGridList()
    end
    self:HideCurrentList()
    self:ClearAllCurrentSlotPreviews()
end

function ZO_GamepadCollectionsBook:RefreshHeader()
    ZO_GamepadGenericHeader_RefreshData(self.header, self.headerData)

    if self.currentList then
        local currentListData = self.currentList.list:GetTargetData()
        local isSubCategoryList = self.subcategoryList == self.currentList
        local isOutfitCategory = currentListData.IsOutfitStylesCategory and currentListData:IsOutfitStylesCategory()
        local hideSelector = not (isOutfitCategory and isSubCategoryList)

        self.outfitSelectorControl:SetHidden(hideSelector)
        if hideSelector then
            -- make sure the cursor is not in the header when it isn't showing
            self:RequestLeaveHeader()
        end
    end

    local currentlyEquippedOutfitIndex = ZO_OUTFITS_SELECTOR_GAMEPAD:GetCurrentOutfitIndex()
    if currentlyEquippedOutfitIndex then
        local currentOutfit = ZO_OUTFIT_MANAGER:GetOutfitManipulator(currentlyEquippedOutfitIndex)
        self.outfitSelectorNameLabel:SetText(currentOutfit:GetOutfitName())
    else
        self.outfitSelectorNameLabel:SetText(GetString(SI_NO_OUTFIT_EQUIP_ENTRY))
    end

    self.outfitSelectorHeaderFocus:Update()
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

    local function RefreshGridList()
        local categoryData = self.subcategoryList.list:GetTargetData()
        if categoryData then
            self:RefreshGridListPanel(categoryData)
        end
    end

    local function ClearPreviewList()
        self:ClearAllCurrentSlotPreviews()
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.subcategoryKeybindStripDescriptor)
    end

    local showLockedOption = ZO_RESTYLE_STATION_GAMEPAD:CreateOptionActionDataOutfitStylesShowLocked(RefreshGridList)

    -- Subcategory Keybind
    self.subcategoryKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        -- Select Subcategory
        {
            name = GetString(SI_GAMEPAD_SELECT_OPTION),
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                if self.outfitSelectorHeaderFocus:IsActive() then
                    self:ShowOutfitSelector()
                else
                    if self.currentCategoryData:IsOutfitStylesCategory() then
                        self:EnterGridList()
                    else
                        self:ViewSubcategory()
                    end
                end
            end,
            visible = function()
                local entryData = self.currentList.list:GetTargetData()
                return entryData ~= nil
            end,
            sound = SOUNDS.GAMEPAD_MENU_FORWARD,
        },

        -- Options
        {
            name = GetString(SI_GAMEPAD_DYEING_OPTIONS),
            keybind = "UI_SHORTCUT_TERTIARY",
            callback = function() ZO_Dialogs_ShowGamepadDialog("GAMEPAD_RESTYLE_STATION_OPTIONS", { showLockedOption }) end,
            visible = function()
                return self.currentCategoryData:IsOutfitStylesCategory()
            end,
        },

        -- Clear Preview
        {
            name = GetString(SI_OUTFIT_STYLES_BOOK_END_ALL_PREVIEWS_KEYBIND),
            keybind = "UI_SHORTCUT_LEFT_STICK",
            callback = ClearPreviewList,
            visible = function()
                return self.currentCategoryData:IsOutfitStylesCategory() and self:HasAnyCurrentSlotPreviews()
            end,
        }
    }

    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.subcategoryKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, function()
                                                                                                                            self:ClearAllCurrentSlotPreviews()
                                                                                                                            self:ShowList(self.categoryList) 
                                                                                                                        end)

    local function ClearPreviewGrid()
        self:ClearAllCurrentSlotPreviews()
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.gridKeybindStripDescriptor)
    end

    -- Grid Keybind
    self.gridKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        -- Select
        {
            name = function()
                local currentlySelectedCollectibleData = self.gridListPanelList:GetSelectedData()
                if self:IsPreviewingOutfitStyle(currentlySelectedCollectibleData) then
                    return GetString(SI_OUTFIT_STYLES_BOOK_END_PREVIEW_KEYBIND)
                else
                    return GetString(SI_OUTFIT_STYLES_BOOK_PREVIEW_KEYBIND)
                end
            end,
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                self:TogglePreviewSelectedOutfitStyle()
            end,
            visible = function()
                 local currentlySelectedCollectibleData = self.gridListPanelList:GetSelectedData()
                 return currentlySelectedCollectibleData and not currentlySelectedCollectibleData.isEmptyCell
            end,
            sound = SOUNDS.GAMEPAD_MENU_FORWARD,
        },
        
        -- Options
        {
            name = GetString(SI_GAMEPAD_DYEING_OPTIONS),
            keybind = "UI_SHORTCUT_TERTIARY",
            callback = function() ZO_Dialogs_ShowGamepadDialog("GAMEPAD_RESTYLE_STATION_OPTIONS", { showLockedOption }) end,
        },

        -- Clear Preview
        {
            name = GetString(SI_OUTFIT_STYLES_BOOK_END_ALL_PREVIEWS_KEYBIND),
            keybind = "UI_SHORTCUT_LEFT_STICK",
            callback = ClearPreviewGrid,
            visible = function() return self:HasAnyCurrentSlotPreviews() end
        }
    }

    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.gridKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, function() self:ExitGridList() end)

    -- Collection Keybind
    self.collectionKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        -- Set Active or Put Away Collectible
        {
            name = function()
                local collectibleData = self:GetCurrentTargetData()
                local nameStringId
                if collectibleData:IsStory() then
                    nameStringId = SI_DLC_BOOK_ACTION_ACCEPT_QUEST
                elseif collectibleData:IsCategoryType(COLLECTIBLE_CATEGORY_TYPE_MEMENTO) then
                    nameStringId = SI_COLLECTIBLE_ACTION_USE
                elseif collectibleData:IsCategoryType(COLLECTIBLE_CATEGORY_TYPE_COMBINATION_FRAGMENT) then
                    nameStringId = SI_COLLECTIBLE_ACTION_COMBINE
                elseif collectibleData:IsHouse() then
                    nameStringId = collectibleData:IsUnlocked() and SI_HOUSING_BOOK_ACTION_TRAVEL_TO_HOUSE or SI_HOUSING_BOOK_ACTION_PREVIEW_HOUSE
                elseif collectibleData:IsActive() then
                    if collectibleData:IsCategoryType(COLLECTIBLE_CATEGORY_TYPE_ASSISTANT) or collectibleData:IsCategoryType(COLLECTIBLE_CATEGORY_TYPE_VANITY_PET) then
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
                local collectibleData = self:GetCurrentTargetData()
                if collectibleData:IsHouse() then
                    RequestJumpToHouse(collectibleData:GetReferenceId())
                    SCENE_MANAGER:ShowBaseScene()
                else
                    collectibleData:Use()
                end
            end,
            visible = function()
                local collectibleData = self:GetCurrentTargetData()
                if collectibleData then
                    if collectibleData:IsHouse() then
                        return true
                    else
                        return collectibleData:IsUsable()
                    end
                else
                    return false
                end
            end,
            sound = SOUNDS.DEFAULT_CLICK,
            enabled = function()
                local collectibleData = self:GetCurrentTargetData()
                if collectibleData:IsHouse() then
                    local cannotJumpString = collectibleData:IsUnlocked() and GetString(SI_COLLECTIONS_CANNOT_JUMP_TO_HOUSE_FROM_LOCATION) or GetString(SI_COLLECTIONS_CANNOT_PREVIEW_HOUSE_FROM_LOCATION)
                    return CanJumpToHouseFromCurrentLocation(), cannotJumpString
                else -- IsUsable
                    local remainingMs = GetCollectibleCooldownAndDuration(collectibleData:GetId())
                    if collectibleData:IsActive() then
                        return true
                    elseif remainingMs > 0 then
                        return false, GetString(SI_COLLECTIONS_COOLDOWN_ERROR)
                    elseif collectibleData:IsBlocked() then
                        return false, GetString(SI_COLLECTIONS_BLOCKED_ERROR)
                    else
                        return true
                    end
                end
            end
        },
        -- Assign to Quick Slot / Unlock
        {
            name = function()
                local collectibleData = self:GetCurrentTargetData()
                if collectibleData:IsSlottable() then
                    return GetString(SI_GAMEPAD_ITEM_ACTION_QUICKSLOT_ASSIGN)
                elseif self:CanPurchaseCurrentTarget() then
                    return GetString(SI_GAMEPAD_DLC_BOOK_ACTION_OPEN_CROWN_STORE)
                elseif self:CanUpgradeCurrentTarget() then
                    return GetString(SI_DLC_BOOK_ACTION_CHAPTER_UPGRADE)
                end
            end,
            keybind = "UI_SHORTCUT_SECONDARY",
            callback = function()
                local collectibleData = self:GetCurrentTargetData()
                if collectibleData:IsSlottable() then
                    self.savedQuickSlotCollectibleData = collectibleData
                    GAMEPAD_QUICKSLOT:SetCollectibleToQuickslot(collectibleData:GetId())
                    SCENE_MANAGER:Push("gamepad_quickslot")
                elseif self:CanPurchaseCurrentTarget() then
                    local searchTerm = zo_strformat(SI_CROWN_STORE_SEARCH_FORMAT_STRING, collectibleData:GetName())
                    ShowMarketAndSearch(searchTerm, MARKET_OPEN_OPERATION_COLLECTIONS_DLC)
                elseif self:CanUpgradeCurrentTarget() then
                    ZO_ShowChapterUpgradePlatformScreen(MARKET_OPEN_OPERATION_COLLECTIONS_DLC)
                end
            end,
            visible = function()
                local collectibleData = self:GetCurrentTargetData()
                if collectibleData then
                    if collectibleData:IsSlottable() then
                        return true
                    elseif self:CanPurchaseCurrentTarget() then
                        return true
                    elseif self:CanUpgradeCurrentTarget() then
                        return true
                    end
                end

                return false
            end,
            enabled = function()
                local collectibleData = self:GetCurrentTargetData()
                if collectibleData:IsSlottable() then
                    if collectibleData:IsValidForPlayer() then
                        return true
                    else
                        return false, GetString(SI_COLLECTIONS_INVALID_ERROR)
                    end
                else
                    return true
                end
            end,
            sound = SOUNDS.GAMEPAD_MENU_FORWARD,
        },
        -- Actions
        {
            name = GetString(SI_GAMEPAD_INVENTORY_ACTION_LIST_KEYBIND),
            keybind = "UI_SHORTCUT_TERTIARY",
            callback = function()
                local collectibleData = self:GetCurrentTargetData()

                local dialogData = 
                {
                    collectibleId = collectibleData:GetId(),
                    name = collectibleData:GetNickname(),
                    active = collectibleData:IsActive(),
                }
                ZO_Dialogs_ShowGamepadDialog(GAMEPAD_COLLECTIONS_ACTIONS_DIALOG_NAME, dialogData)
            end,
            visible = function()
                local collectibleData = self:GetCurrentTargetData()

                if collectibleData then
                    return IsChatSystemAvailableForCurrentPlatform() or collectibleData:IsRenameable() or self:CanPurchaseCurrentTarget() or self:CanUpgradeCurrentTarget()
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
                local collectibleData = self:GetCurrentTargetData()
                return collectibleData and collectibleData:IsStory() and collectibleData:IsUnlockedViaSubscription() and not IsESOPlusSubscriber()
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

--Opens up the provided category, or the current category if no categoryData is provided
function ZO_GamepadCollectionsBook:ViewCategory(categoryData)
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

function ZO_GamepadCollectionsBook:SelectSubCategoryData(subcategoryData)
    for index = 1, self.subcategoryList.list:GetNumEntries() do
        local entryData = self.subcategoryList.list:GetEntryData(index)
        if entryData.dataSource == subcategoryData then
            self.subcategoryList.list:SetSelectedIndexWithoutAnimation(index)
        end
    end
end

--Opens up the provided subcategory, or the current subcategory if no subcategoryData is provided
function ZO_GamepadCollectionsBook:ViewSubcategory(subcategoryData)
    if subcategoryData and subcategoryData:IsSubcategory() then
        self:ViewCategory(subcategoryData:GetParentData())

        self:SelectSubCategoryData(subcategoryData)
    end

    subcategoryData = self.subcategoryList.list:GetTargetData()

    local RESET_SELECTION_TO_TOP = true
    self:BuildCollectionList(subcategoryData, RESET_SELECTION_TO_TOP)
    self:ShowList(self.collectionList)
end

function ZO_GamepadCollectionsBook:SelectCollectibleEntry(collectibleId)
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
        local listObject = list.list
        KEYBIND_STRIP:AddKeybindButtonGroup(self.currentList.keybind)
        self:SetCurrentList(listObject)
        local targetData = listObject:GetTargetData()
        self:RefreshRightPanel(targetData)
        if list == self.subcategoryList and targetData:IsOutfitStylesCategory() then
            self:StartPreviewFromBase()
        else
            ITEM_PREVIEW_GAMEPAD:ResetOutfitPreview()
            RefreshPreviewCollectionShown()
        end
    end

    if not dontUpdateTitle then
        self.headerData.titleText = list.titleText
        self:RefreshHeader()
    end

    if self:IsViewingCollectionsList() then
        local collectibleData = self:GetCurrentTargetData()
        if collectibleData then
            self.notificationIdToClear = collectibleData.notificationId
            if self.notificationIdToClear or collectibleData:IsNew() then
                self.clearNewStatusOnSelectionChanged = true
            end

            if collectibleData:IsCategoryType(COLLECTIBLE_CATEGORY_TYPE_DLC) then
                if IsESOPlusSubscriber() then
                    TriggerTutorial(TUTORIAL_TRIGGER_COLLECTIONS_DLC_OPENED_AS_SUBSCRIBER)
                end
            end
        end
    else
        self:RefreshHeader()
    end
end

function ZO_GamepadCollectionsBook:HideCurrentList()
    if self.currentList == nil then
        return
    end

    if self:IsViewingCollectionsList() then
        if self.notificationIdToClear then
            RemoveCollectibleNotification(self.notificationIdToClear)
        end

        local collectibleData = self:GetCurrentTargetData()
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

function ZO_GamepadCollectionsBook:OnCollectionUpdated()
    if not self.control:IsHidden() then
        if self.categoryList then
            self:ShowList(self.categoryList)
            self.categoryList.list:SetSelectedIndex(1)
            self:BuildCategoryList()
        end
    end
end

function ZO_GamepadCollectionsBook:OnCollectibleUpdated()
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

function ZO_GamepadCollectionsBook:OnCollectibleStatusUpdated()
    if not self.control:IsHidden() then
        if self:IsViewingCollectionsList() then
            self.currentList.list:RefreshVisible()
        end
        self.categoryList.list:RefreshVisible()
        self.subcategoryList.list:RefreshVisible()
    end
end

function ZO_GamepadCollectionsBook:OnCollectibleNotificationRemoved(notificationId, collectibleId)
    self:OnCollectibleStatusUpdated()
end

function ZO_GamepadCollectionsBook:OnCollectibleNewStatusCleared(collectibleId)
    self:OnCollectibleStatusUpdated()
end

function ZO_GamepadCollectionsBook:BuildCategoryList()
    self.categoryList.list:Clear()

    -- Add the categories entries
    for categoryIndex, categoryData in ZO_COLLECTIBLE_DATA_MANAGER:CategoryIterator({ ZO_CollectibleCategoryData.HasShownCollectiblesInCollection }) do
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

function ZO_GamepadCollectionsBook:BuildSubcategoryList(categoryData)
    local subcategoryListInfo = self.subcategoryList
    local subcategoryList = subcategoryListInfo.list

    subcategoryList:Clear()

    subcategoryListInfo.titleText = categoryData:GetFormattedName()

    -- Add the categories entries
    for subcategoryIndex, subcategoryData in categoryData:SubcategoryIterator({ZO_CollectibleCategoryData.HasShownCollectiblesInCollection}) do
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

function ZO_GamepadCollectionsBook:BuildCollectionList(categoryData, resetSelectionToTop)
    local collectionListInfo = self.collectionList
    local collectionList = collectionListInfo.list

    collectionList:Clear()
    collectionListInfo.titleText = nil

    local unlockedData = {}
    local lockedData = {}

    for _, collectibleData in categoryData:SortedCollectibleIterator({ ZO_CollectibleData.IsShownInCollection }) do
        local entryData = self:BuildCollectibleData(collectibleData)
        if collectibleData:IsUnlocked() then
            table.insert(unlockedData, entryData)
        else
            table.insert(lockedData, entryData)
        end
    end

    collectionListInfo.titleText = categoryData:GetFormattedName()

    self:BuildListFromTable(collectionList, unlockedData, GetString("SI_COLLECTIBLEUNLOCKSTATE", COLLECTIBLE_UNLOCK_STATE_UNLOCKED_OWNED))
    self:BuildListFromTable(collectionList, lockedData, GetString("SI_COLLECTIBLEUNLOCKSTATE", COLLECTIBLE_UNLOCK_STATE_LOCKED))

    collectionList:Commit(resetSelectionToTop)

    KEYBIND_STRIP:UpdateKeybindButtonGroup(collectionListInfo.keybind)

    self.currentCategoryData = categoryData

    self.updateList = unlockedData
end

function ZO_GamepadCollectionsBook:UpdateCollectionListVisualLayer()
    local list = self.collectionList.list
    for i = 1, list:GetNumItems() do
        local collectibleData = list:GetDataForDataIndex(i)
        collectibleData:SetIsHiddenByWardrobe(collectibleData:IsVisualLayerHidden())
    end
    self:RefreshRightPanel(self.collectionList.list:GetTargetData())
end

function ZO_GamepadCollectionsBook:BuildCollectibleData(collectibleData)
    local collectibleId = collectibleData:GetId()

    local entryData = ZO_GamepadEntryData:New(collectibleData:GetFormattedName(), collectibleData:GetIcon())
    entryData:SetDataSource(collectibleData)
    entryData:SetCooldownIcon(collectibleData:GetIcon())

    entryData.isEquippedInCurrentCategory = collectibleData:IsActive()
    
    entryData:SetIsHiddenByWardrobe(collectibleData:IsVisualLayerHidden())

    ZO_UpdateCollectibleEntryDataIconVisuals(entryData)

    local remainingMs, durationMs = GetCollectibleCooldownAndDuration(collectibleId)
    if remainingMs > 0 and durationMs > 0 then
        entryData:SetCooldown(remainingMs, durationMs)
        entryData.refreshWhenFinished = true
    end

    return entryData
end

function ZO_GamepadCollectionsBook:BuildListFromTable(list, dataTable, header)
    if #dataTable >= 1 then
        for i,entryData in ipairs(dataTable) do
            if i == 1 then
                entryData:SetHeader(header)
                list:AddEntryWithHeader("ZO_GamepadCollectibleEntryTemplate", entryData)
            else
                list:AddEntry("ZO_GamepadCollectibleEntryTemplate", entryData)
            end
        end
    end
end

function ZO_GamepadCollectionsBook:OnSelectionChanged(list, selectedData, oldSelectedData)
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

function ZO_GamepadCollectionsBook:TrySetClearNewFlag(callId)
    if self.clearNewStatusCallId == callId then
        self.clearNewStatusOnSelectionChanged = true
    end
end

function ZO_GamepadCollectionsBook:RefreshRightPanel(entryData)
    if self:IsViewingCollectionsList() then
        if entryData then
            if entryData:IsStory() then
                self:RefreshDLCTooltip(entryData)
            elseif entryData:IsHouse() then
                self:RefreshHousingTooltip(entryData)
            else
                self:RefreshStandardTooltip(entryData)
            end
        else
            SCENE_MANAGER:RemoveFragment(GAMEPAD_NAV_QUADRANT_2_3_BACKGROUND_FRAGMENT)
            SCENE_MANAGER:RemoveFragment(GAMEPAD_COLLECTIONS_BOOK_DLC_PANEL_FRAGMENT)
            SCENE_MANAGER:RemoveFragment(GAMEPAD_COLLECTIONS_BOOK_HOUSING_PANEL_FRAGMENT)
            GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
        end
    else
        self:UpdateGridPanelVisibility(entryData)
        SCENE_MANAGER:RemoveFragment(GAMEPAD_COLLECTIONS_BOOK_DLC_PANEL_FRAGMENT)
        SCENE_MANAGER:RemoveFragment(GAMEPAD_COLLECTIONS_BOOK_HOUSING_PANEL_FRAGMENT)
        GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
    end
end

function ZO_GamepadCollectionsBook:RefreshStandardTooltip(collectibleData)
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP, true)

    local timeRemainingS = collectibleData:GetCooldownTimeRemainingMs() / 1000
    local SHOW_VISUAL_LAYER_INFO = true
    local SHOW_BLOCK_REASON = true
    GAMEPAD_TOOLTIPS:LayoutCollectibleFromData(GAMEPAD_LEFT_TOOLTIP, collectibleData, SHOW_VISUAL_LAYER_INFO, timeRemainingS, SHOW_BLOCK_REASON)
end

function ZO_GamepadCollectionsBook:RefreshDLCTooltip(collectibleData)
    local infoPanel = self.infoPanelControl
    infoPanel.backgroundControl:SetTexture(collectibleData:GetGamepadBackgroundImage())
    infoPanel.nameControl:SetText(collectibleData:GetFormattedName())
    infoPanel.descriptionControl:SetText(collectibleData:GetDescription())
    infoPanel.unlockStatusControl:SetText(GetString("SI_COLLECTIBLEUNLOCKSTATE", collectibleData:GetUnlockState()))
    
    local isUnlocked = collectibleData:IsUnlocked()
    local isActive = collectibleData:IsActive()

    local questAcceptLabelStringId = isActive and SI_DLC_BOOK_QUEST_STATUS_ACCEPTED or SI_DLC_BOOK_QUEST_STATUS_NOT_ACCEPTED
    local questName = collectibleData:GetQuestName()
    infoPanel.questStatusControl:SetText(zo_strformat(SI_GAMEPAD_DLC_BOOK_QUEST_STATUS_INFO, questName, GetString(questAcceptLabelStringId)))
    
    local showsQuest = isUnlocked and not isActive
    local questAcceptIndicator = infoPanel.questAcceptIndicator
    local questAcceptDescription = infoPanel.questAcceptDescription

    if showsQuest then
        questAcceptIndicator:SetText(GetString(SI_COLLECTIONS_QUEST_AVAILABLE))
        questAcceptIndicator:SetHidden(false)
        
        questAcceptDescription:SetText(collectibleData:GetQuestDescription())
        questAcceptDescription:SetHidden(false)
    elseif not isUnlocked then
        local isChapter = collectibleData:IsCategoryType(COLLECTIBLE_CATEGORY_TYPE_CHAPTER)
        if collectibleData:IsPurchasable() or collectibleData:IsUnlockedViaSubscription() or isChapter then
            local acquireText = isChapter and GetString(SI_COLLECTIONS_QUEST_AVAILABLE_WITH_UPGRADE) or GetString(SI_COLLECTIONS_QUEST_AVAILABLE_WITH_UNLOCK)
            questAcceptIndicator:SetText(acquireText)
            questAcceptIndicator:SetHidden(false)
        else
            questAcceptIndicator:SetHidden(true)
        end

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
    housingPanel.backgroundControl:SetTexture(collectibleData:GetGamepadBackgroundImage())
    housingPanel.nameLabel:SetText(collectibleData:GetFormattedName())
    housingPanel.locationLabel:SetText(collectibleData:GetFormattedHouseLocation())
    housingPanel.houseTypeLabel:SetText(GetString("SI_HOUSECATEGORYTYPE", collectibleData:GetHouseCategoryType()))
    housingPanel.descriptionLabel:SetText(collectibleData:GetDescription())
    housingPanel.collectedStatusLabel:SetText(GetString("SI_COLLECTIBLEUNLOCKSTATE", collectibleData:GetUnlockState()))
    housingPanel.nicknameLabel:SetText(collectibleData:GetFormattedNickname())

    if not CanJumpToHouseFromCurrentLocation() then
        local disableReason = isUnlocked and GetString(SI_COLLECTIONS_CANNOT_JUMP_TO_HOUSE_FROM_LOCATION) or GetString(SI_COLLECTIONS_CANNOT_PREVIEW_HOUSE_FROM_LOCATION)
        housingPanel.hintLabel:SetText(ZO_ERROR_COLOR:Colorize(disableReason))
        housingPanel.hintLabel:SetHidden(false)
        housingPanel.primaryResidenceHeaderLabel:SetHidden(true)
        housingPanel.primaryResidenceValueLabel:SetHidden(true)
    elseif collectibleData:IsUnlocked() then
        local primaryResidenceText = collectibleData:IsPrimaryResidence() and GetString(SI_YES) or GetString(SI_NO)
        housingPanel.primaryResidenceValueLabel:SetText(primaryResidenceText)
        
        housingPanel.primaryResidenceHeaderLabel:SetHidden(false)
        housingPanel.primaryResidenceValueLabel:SetHidden(false)
        housingPanel.hintLabel:SetHidden(true)
    else
        housingPanel.hintLabel:SetText(collectibleData:GetHint())
        housingPanel.hintLabel:SetHidden(false)
        housingPanel.primaryResidenceHeaderLabel:SetHidden(true)
        housingPanel.primaryResidenceValueLabel:SetHidden(true)
    end

    SCENE_MANAGER:AddFragment(GAMEPAD_NAV_QUADRANT_2_3_BACKGROUND_FRAGMENT)
    SCENE_MANAGER:AddFragment(GAMEPAD_COLLECTIONS_BOOK_HOUSING_PANEL_FRAGMENT)
end

function ZO_GamepadCollectionsBook:UpdateGridPanelVisibility(categoryData)
    if categoryData and categoryData:IsOutfitStylesCategory() and categoryData:GetNumCollectibles() > 0 then
        self:RefreshGridListPanel(categoryData)

        SCENE_MANAGER:AddFragment(GAMEPAD_NAV_QUADRANT_2_3_BACKGROUND_FRAGMENT)
        SCENE_MANAGER:AddFragment(GAMEPAD_COLLECTIONS_BOOK_GRID_LIST_PANEL_FRAGMENT)
    else
        SCENE_MANAGER:RemoveFragment(GAMEPAD_NAV_QUADRANT_2_3_BACKGROUND_FRAGMENT)
        SCENE_MANAGER:RemoveFragment(GAMEPAD_COLLECTIONS_BOOK_GRID_LIST_PANEL_FRAGMENT)
    end
end

function ZO_GamepadCollectionsBook:EnterGridList()
    self:DeactivateCurrentList()
    self.gridListPanelList:Activate()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.subcategoryKeybindStripDescriptor)
    KEYBIND_STRIP:AddKeybindButtonGroup(self.gridKeybindStripDescriptor)
end

function ZO_GamepadCollectionsBook:ExitGridList()
    self.gridListPanelList:Deactivate()
    self:ActivateCurrentList()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.gridKeybindStripDescriptor)
    KEYBIND_STRIP:AddKeybindButtonGroup(self.subcategoryKeybindStripDescriptor)
end

do
    local DONT_REFRESH_IMMEDIATELY = false
    local REFRESH_IMMEDIATELY = true

    function ZO_GamepadCollectionsBook:ClearAllCurrentSlotPreviews()
        local previewCollectionId = SYSTEMS:GetObject("itemPreview"):GetPreviewCollectionId()
        for outfitSlot, _ in pairs(self.currentSlotPreviews) do
            ClearOutfitSlotPreviewElementFromPreviewCollection(previewCollectionId, outfitSlot, DONT_REFRESH_IMMEDIATELY)
        end
        RefreshPreviewCollectionShown()
        ZO_ClearTable(self.currentSlotPreviews)
        self.gridListPanelList:RefreshGridList()
    end

    function ZO_GamepadCollectionsBook:TogglePreviewSelectedOutfitStyle()
        local previewCollectionId = SYSTEMS:GetObject("itemPreview"):GetPreviewCollectionId()
        local itemMaterialIndex = ZO_OUTFIT_STYLE_DEFAULT_ITEM_MATERIAL_INDEX

        if previewCollectionId ~= 0 then
            local currentlySelectedCollectibleData = self.gridListPanelList:GetSelectedData()
            if currentlySelectedCollectibleData and not currentlySelectedCollectibleData.isEmptyCell then
                local preferredOutfitSlot = ZO_OUTFIT_MANAGER:GetPreferredOutfitSlotForStyle(currentlySelectedCollectibleData)
                if self:IsPreviewingOutfitStyle(currentlySelectedCollectibleData, itemMaterialIndex, preferredOutfitSlot) then
                    ClearOutfitSlotPreviewElementFromPreviewCollection(previewCollectionId, preferredOutfitSlot, REFRESH_IMMEDIATELY)
                    self.currentSlotPreviews[preferredOutfitSlot] = nil
                else
                    local primaryDye, secondaryDye, accentDye = 0, 0, 0
                    local currentOutfitIndex = ZO_OUTFITS_SELECTOR_GAMEPAD:GetCurrentOutfitIndex()
                    if currentOutfitIndex then
                        local outfitManipulator = ZO_OUTFIT_MANAGER:GetOutfitManipulator(currentOutfitIndex)
                        local slotManipulator = outfitManipulator:GetSlotManipulator(preferredOutfitSlot)
                        if slotManipulator then
                            primaryDye, secondaryDye, accentDye = slotManipulator:GetPendingDyeData()
                        end
                    else
                        local equipSlot = GetEquipSlotForOutfitSlot(preferredOutfitSlot)
                        if CanEquippedItemBeShownInOutfitSlot(equipSlot, preferredOutfitSlot) then
                            primaryDye, secondaryDye, accentDye = GetPendingSlotDyes(RESTYLE_MODE_EQUIPMENT, ZO_RESTYLE_DEFAULT_SET_INDEX, equipSlot)
                        end
                    end

                    local collectibleId = currentlySelectedCollectibleData:GetId()
                    self.currentSlotPreviews[preferredOutfitSlot] = 
                    {
                        collectibleId = collectibleId,
                        itemMaterialIndex = itemMaterialIndex,
                    }

                    AddOutfitSlotPreviewElementToPreviewCollection(previewCollectionId, preferredOutfitSlot, collectibleId, itemMaterialIndex, primaryDye, secondaryDye, accentDye, REFRESH_IMMEDIATELY)
                end
                self.gridListPanelList:RefreshGridList()
            end
        end

        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.gridKeybindStripDescriptor)
    end
end

function ZO_GamepadCollectionsBook:HasAnyCurrentSlotPreviews() 
    return NonContiguousCount(self.currentSlotPreviews) > 0 
end

function ZO_GamepadCollectionsBook:IsPreviewingOutfitStyle(collectibleData, itemMaterialIndex, preferredOutfitSlot)
    preferredOutfitSlot = preferredOutfitSlot or ZO_OUTFIT_MANAGER:GetPreferredOutfitSlotForStyle(collectibleData)

    if preferredOutfitSlot then
        local currentPreviewDataForSlot = self.currentSlotPreviews[preferredOutfitSlot]
        local collectibleId = collectibleData:GetId()
        if currentPreviewDataForSlot and currentPreviewDataForSlot.collectibleId == collectibleId then
            if itemMaterialIndex == nil or currentPreviewDataForSlot.itemMaterialIndex == itemMaterialIndex then
                return true
            end
        end
    end
    return false
end

function ZO_GamepadCollectionsBook:OnGridListSelectedDataChanged(previousData, newData)
    GAMEPAD_TOOLTIPS:ClearLines(GAMEPAD_QUAD1_TOOLTIP)

    if previousData and not previousData.isEmptyCell then
        ClearCollectibleNewStatus(previousData:GetId())
        if previousData.notificationId then
            RemoveCollectibleNotification(previousData.notificationId)
        end
        self.gridListPanelList:RefreshGridListEntryData(previousData, function(control, data, list)
            self:RefreshGridEntryMultiIcon(control, data)
        end)
    end

    if newData and not newData.isEmptyCell then
        local SHOW_VISUAL_LAYER_INFO = true
        local SHOW_BLOCK_REASON = true
        local TIME_REMAINING_S = nil


        GAMEPAD_TOOLTIPS:LayoutCollectibleFromData(GAMEPAD_QUAD1_TOOLTIP, newData, SHOW_VISUAL_LAYER_INFO, TIME_REMAINING_S, SHOW_BLOCK_REASON)
    end
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.gridKeybindStripDescriptor)
end

function ZO_GamepadCollectionsBook:StartPreviewFromBase()
    local currentOutfitIndex = ZO_OUTFITS_SELECTOR_GAMEPAD:GetCurrentOutfitIndex()
    if currentOutfitIndex then
        ITEM_PREVIEW_GAMEPAD:PreviewOutfit(currentOutfitIndex)
    else
        ITEM_PREVIEW_GAMEPAD:PreviewUnequipOutfit()
    end
end

function ZO_GamepadCollectionsBook:RefreshGridListPanel(categoryData)
    self.currentGridListCategoryData = categoryData
    local gridListPanelList = self.gridListPanelList
    gridListPanelList:ClearGridList()

    local tempTable = {}
    local showLocked = ZO_OUTFIT_MANAGER:GetShowLocked()

    local function FilterCollectible(collectibleData)
        if not showLocked and collectibleData:IsLocked() then
            return false
        end

        return ZO_CollectibleData.IsShownInCollection(collectibleData)
    end

    local function InsertEntryIntoTable(tempTable, data)
        local entryData = ZO_GridSquareEntryData_Shared:New(data)
        ZO_UpdateCollectibleEntryDataIconVisuals(entryData)
        table.insert(tempTable, entryData)
    end

    local dataByWeaponAndArmorType = categoryData:GetCollectibleDataBySpecializedSort()
    local NO_WEAPON_OR_ARMOR_TYPE = 0

    -- make sure to add the hide option first
    if dataByWeaponAndArmorType[NO_WEAPON_OR_ARMOR_TYPE] then
        local gearTypeNone = dataByWeaponAndArmorType[NO_WEAPON_OR_ARMOR_TYPE]:GetCollectibles()
        for _, collectibleData in ipairs(gearTypeNone) do
            InsertEntryIntoTable(tempTable, collectibleData)
        end
    end

    for type, weaponOrArmorSortedCollectibles in pairs(dataByWeaponAndArmorType) do
        if type > NO_WEAPON_OR_ARMOR_TYPE then
            local weaponOrArmorData = weaponOrArmorSortedCollectibles:GetCollectibles()
            for _, collectibleData in ipairs(weaponOrArmorData) do
                if FilterCollectible(collectibleData) then
                    InsertEntryIntoTable(tempTable, collectibleData)
                end
            end
        end
    end

    for _, entryData in ipairs(tempTable) do
        gridListPanelList:AddEntry(entryData)
    end
    
    gridListPanelList:CommitGridList()
end

function ZO_GamepadCollectionsBook:BrowseToCollectible(collectibleId)
    self.browseToCollectibleInfo = 
    {
        collectibleId = collectibleId,
    }

    SCENE_MANAGER:CreateStackFromScratch("mainMenuGamepad", "gamepadCollectionsBook")
end

function ZO_GamepadCollectionsBook:CanPurchaseCurrentTarget()
    if self:IsViewingCollectionsList() then
        local collectibleData = self:GetCurrentTargetData()
        return collectibleData and collectibleData:IsPurchasable() and not collectibleData:IsOwned() and not collectibleData:IsHouse()
    end
    return false
end

function ZO_GamepadCollectionsBook:CanUpgradeCurrentTarget()
    if self:IsViewingCollectionsList() then
        local collectibleData = self:GetCurrentTargetData()
        return collectibleData and collectibleData:IsCategoryType(COLLECTIBLE_CATEGORY_TYPE_CHAPTER) and not collectibleData:IsOwned()
    end
    return false
end

-----------------
-- Actions Dialog
-----------------

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
                    visible = IsChatSystemAvailableForCurrentPlatform
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
                        local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(parametricDialog.data.collectibleId)
                        return collectibleData and collectibleData:IsRenameable()
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
                        local collectibleData = self:GetCurrentTargetData()
                        local searchTerm = zo_strformat(SI_CROWN_STORE_SEARCH_FORMAT_STRING, collectibleData:GetName())
                        ShowMarketAndSearch(searchTerm, MARKET_OPEN_OPERATION_COLLECTIONS_DLC)
                    end,
                    visible = function()
                        return self:CanPurchaseCurrentTarget()
                    end
                },
            },
            -- Chapter Upgrade
            {
                template = "ZO_GamepadMenuEntryTemplate",
                templateData = {
                    text = GetString(SI_DLC_BOOK_ACTION_CHAPTER_UPGRADE),
                    setup = ZO_SharedGamepadEntry_OnSetup,
                    callback = function(dialog)
                        ZO_ShowChapterUpgradePlatformScreen(MARKET_OPEN_OPERATION_COLLECTIONS_DLC)
                    end,
                    visible = function()
                        return self:CanUpgradeCurrentTarget()
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

----------------------------
-- Rename Collectible Dialog
----------------------------

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

function ZO_GamepadCollectionsBook:InitializeOutfitSelector()
    self.outfitSelectorControl = self.header:GetNamedChild("OutfitSelector")
    self.outfitSelectorNameLabel = self.outfitSelectorControl:GetNamedChild("OutfitName")
    self.outfitSelectorHeaderFocus = ZO_Outfit_Selector_Header_Focus_Gamepad:New(self.outfitSelectorControl)
    self:SetupHeaderFocus(self.outfitSelectorHeaderFocus)
end

function ZO_GamepadCollectionsBook:ShowOutfitSelector()
    self.savedOutfitStyleIndex = self.currentList.list:GetSelectedIndex()
    SCENE_MANAGER:Push("gamepad_outfits_selection")
end

function ZO_GamepadCollectionsBook:OnEnterHeader()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.currentList.keybind)
end

function ZO_GamepadCollectionsBook:CanEnterHeader()
    return not self.outfitSelectorControl:IsHidden()
end

function ZO_GamepadCollectionsBook:OnLeaveHeader()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.currentList.keybind)
end

function ZO_GamepadCollectionsBook:OnUpdateCooldowns()
    for i, collectibleData in ipairs(self.updateList) do
        local remainingMs = GetCollectibleCooldownAndDuration(collectibleData:GetId())
        if remainingMs ~= collectibleData:GetCooldownTimeRemainingMs() or (remainingMs <= 0 and collectibleData.refreshWhenFinished) then
            self:OnCollectibleUpdated(collectibleData:GetId())
            return
        end
    end
end

function ZO_GamepadCollectionsBook:UpdateActiveCollectibleCooldownTimer()
    if not self.control:IsHidden() and self:IsViewingCollectionsList() then
        local collectibleData = self:GetCurrentTargetData()
        if collectibleData and collectibleData:IsOnCooldown() then
            self:RefreshRightPanel(collectibleData)
        end
    end
end

function ZO_GamepadCollectionsBook:IsViewingCollectionsList()
    return self.currentList == self.collectionList
end

function ZO_GamepadCollectionsBook:IsViewingCategoryList()
    return self.currentList == self.categoryList
end

function ZO_GamepadCollectionsBook:IsViewingSubcategoryList()
    return self.currentList == self.subcategoryList
end

function ZO_GamepadCollectionsBook:GetCurrentTargetData()
    return self.currentList.list:GetTargetData()
end

--[[Global functions]]--
------------------------
function ZO_GamepadCollectionsBook_OnInitialize(control)
    GAMEPAD_COLLECTIONS_BOOK = ZO_GamepadCollectionsBook:New(control)
end
