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
    self:InitializeUtilityWheel()

    self.control:RegisterForEvent(EVENT_VISUAL_LAYER_CHANGED, function()
        if GAMEPAD_COLLECTIONS_BOOK_SCENE:IsShowing() then
            if self:IsViewingCollectionsList() then
                self:UpdateCollectionListVisualLayer()
            end
        end
    end)

    SYSTEMS:RegisterGamepadObject(ZO_COLLECTIONS_SYSTEM_NAME, self)

    self.onRefreshActionsCallback = function()
        SCREEN_NARRATION_MANAGER:QueueParametricListEntry(self.currentList.list)
    end

    self.OnGamepadDialogShowing = function()
        if ZO_Dialogs_IsShowingDialogThatShouldShowTooltip() then
            GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
        end
    end

    self.OnGamepadDialogHidden = function()
        -- If we are showing a queued dialog, the hidden for the previously shown dialog could come
        -- after the showing for the new dialog, so make sure we don't reshow any tooltips after hiding them
        if self.currentList and not ZO_Dialogs_IsShowingDialogThatShouldShowTooltip() then
            local listObject = self.currentList.list
            local targetData = listObject:GetTargetData()
            self:RefreshRightPanel(targetData)
        end
    end

    local function OnCollectibleUpdated()
        self:OnCollectibleUpdated()
    end

    ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("OnCollectibleUpdated", OnCollectibleUpdated)
    ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("OnCollectionUpdated", function(...) self:OnCollectionUpdated(...) end)
    ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("PrimaryResidenceSet", OnCollectibleUpdated)
    ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("OnCollectibleNewStatusCleared", function(...) self:OnCollectibleNewStatusCleared(...) end)
    ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("OnCollectibleNotificationRemoved", function(...) self:OnCollectibleNotificationRemoved(...) end)
    ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("OnCollectibleUserFlagsUpdated", function(...) self:OnCollectibleUserFlagsUpdated(...) end)
    COLLECTIONS_BOOK_SINGLETON:RegisterCallback("OnUpdateCooldowns", function(...) self:OnUpdateCooldowns(...) end)
    EVENT_MANAGER:RegisterForUpdate("ZO_GamepadCollectionsBook", 250, function() self:UpdateActiveCollectibleCooldownTimer() end)
    self.control:SetHandler("OnUpdate", function()
        local isPreviewingAvailable = IsCharacterPreviewingAvailable()
        if self.isPreviewAvailable ~= isPreviewingAvailable then
            self.isPreviewAvailable = isPreviewingAvailable
            if self.isPreviewAvailable then
                self.outfitSelectorHeaderFocus:Enable()
            else
                self.outfitSelectorHeaderFocus:Disable()
            end
            KEYBIND_STRIP:UpdateKeybindButtonGroup(self.subcategoryKeybindStripDescriptor)
            KEYBIND_STRIP:UpdateKeybindButtonGroup(self.gridKeybindStripDescriptor)
        end
    end)
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
    housingPanel.supportsWeatherControlValueLabel = container:GetNamedChild("SupportsWeatherControlValue")
    housingPanel.recommendCountHeader = container:GetNamedChild("RecommendCountHeader")
    housingPanel.recommendCountValue = container:GetNamedChild("RecommendCountValue")

    local scrollContainer = container:GetNamedChild("ScrollSection"):GetNamedChild("ScrollChild")
    housingPanel.descriptionLabel = scrollContainer:GetNamedChild("Description")
    housingPanel.primaryResidenceHeaderLabel  = scrollContainer:GetNamedChild("PrimaryResidenceHeader")
    housingPanel.primaryResidenceValueLabel = scrollContainer:GetNamedChild("PrimaryResidenceValue")
    housingPanel.hintLabel = scrollContainer:GetNamedChild("Hint")

    self.housingPanelControl = housingPanel
end

function ZO_GamepadCollectionsBook:InitializeUtilityWheel()
    local quickslotControl = self.control:GetNamedChild("Quickslot")
    self.wheelControl = quickslotControl:GetNamedChild("Wheel")
    self.assignLabel = quickslotControl:GetNamedChild("Assign")
    self.selectedCollectibleNameLabel = quickslotControl:GetNamedChild("SelectedCollectibleName")
    local wheelData =
    {
        hotbarCategories = { HOTBAR_CATEGORY_QUICKSLOT_WHEEL },
        numSlots = ACTION_BAR_UTILITY_BAR_SIZE,
        showPendingIcon = true,
        showCategoryLabel = true,
        onSelectionChangedCallback = function()
            KEYBIND_STRIP:UpdateKeybindButtonGroup(self.utilityAssignmentKeybindStripDescriptor)
        end,
        customNarrationObjectName = "CollectionsAssignableUtilityWheel",
        headerNarrationFunction = function()
            local narrations = {}
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_GAMEPAD_COLLECTIBLE_ASSIGN_INSTRUCTIONS)))
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.pendingUtilityWheelCollectibleData:GetFormattedName()))
            return narrations
        end,
    }
    self.wheel = ZO_AssignableUtilityWheel_Gamepad:New(self.wheelControl, wheelData)
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

        self:RefreshGridEntryMultiIcon(control, data)
        -- TODO: find a way to share this with the generic get border function
        control.borderBackground:SetEdgeTexture("EsoUI/Art/Tooltips/Gamepad/gp_toolTip_edge_16.dds", ZO_GAMEPAD_OUTFIT_GRID_ENTRY_BORDER_EDGE_WIDTH, ZO_GAMEPAD_OUTFIT_GRID_ENTRY_BORDER_EDGE_HEIGHT)

        if data.isEmptyCell then
            control:SetAlpha(0.4)
        elseif data:IsBlocked(GAMEPLAY_ACTOR_CATEGORY_PLAYER) and not data:IsLocked() then
            control:SetAlpha(1)
            if control.icon then
                control.icon:SetDesaturation(1)
            end
        else
            control:SetAlpha(1)
            if control.icon then
                ZO_SetDefaultIconSilhouette(control.icon, data:IsLocked())
            end
        end
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
        if collectibleData:IsInstanceOf(ZO_CollectibleData) then
            data:InitializeCollectibleVisualData(collectibleData, GAMEPLAY_ACTOR_CATEGORY_PLAYER)
        end

        ZO_SharedGamepadEntry_OnSetup(control, data, selected, reselectingDuringRebuild, enabled, active)

        if collectibleData:IsInstanceOf(ZO_CollectibleData) then
            --Order matters. This needs to be run *after* ZO_SharedGamepadEntry_OnSetup
            ZO_SetDefaultIconSilhouette(control.icon, collectibleData:IsLocked())
        end
    end

    list:AddDataTemplate("ZO_GamepadCollectibleEntryTemplate", CollectibleEntrySetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
    list:AddDataTemplateWithHeader("ZO_GamepadCollectibleEntryTemplate", CollectibleEntrySetup, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadMenuEntryHeaderTemplate")
end

function ZO_GamepadCollectionsBook:OnShowing()
    ZO_Gamepad_ParametricList_Screen.OnShowing(self)
    self:ShowList(self.categoryList)
    GAMEPAD_TOOLTIPS:SetTooltipResetScrollOnClear(GAMEPAD_LEFT_TOOLTIP, false)

    ITEM_PREVIEW_GAMEPAD:RegisterCallback("RefreshActions", self.onRefreshActionsCallback)

    -- There may be other scenes which need to return to the same place within CollectionsBook. Add them here.
    -- Initializing here also prevents external screens from requesting CollectionsBook to open to a specific spot.
    if SCENE_MANAGER:GetPreviousSceneName() ~= "gamepad_player_emote"
        and SCENE_MANAGER:GetPreviousSceneName() ~= "gamepad_outfits_selection" then
        -- If we were returning to this screen from a child scene, we would want to return selection to the same item.
        -- We're opening this screen a new time, so clear possible cached indices.
        self.savedOutfitStyleIndex = nil
        self.savedCollectibleData = nil
    end

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
    elseif self.savedCollectibleData then
        local categoryData = self.savedCollectibleData:GetCategoryData()
        if categoryData:IsSubcategory() then
            self:ViewSubcategory(categoryData)
        else
            self:ViewCategory(categoryData)
        end
        self:SelectCollectibleEntry(self.savedCollectibleData:GetId())
    end
    
    self.savedOutfitStyleIndex = nil
    self.savedCollectibleData = nil

    CALLBACK_MANAGER:RegisterCallback("OnGamepadDialogShowing", self.OnGamepadDialogShowing)
    CALLBACK_MANAGER:RegisterCallback("OnGamepadDialogHidden", self.OnGamepadDialogHidden)
end

function ZO_GamepadCollectionsBook:OnHiding()
    self:HideAssignableUtilityWheel()

    ITEM_PREVIEW_GAMEPAD:UnregisterCallback("RefreshActions", self.onRefreshActionsCallback)

    CALLBACK_MANAGER:UnregisterCallback("OnGamepadDialogShowing", self.OnGamepadDialogShowing)
    CALLBACK_MANAGER:UnregisterCallback("OnGamepadDialogHidden", self.OnGamepadDialogHidden)
    GAMEPAD_TOOLTIPS:SetTooltipResetScrollOnClear(GAMEPAD_LEFT_TOOLTIP, true)

    self.shouldFrameRight = nil
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

    local actorCategory, currentlyEquippedOutfitIndex = ZO_OUTFITS_SELECTOR_GAMEPAD:GetCurrentActorCategoryAndIndex()
    if currentlyEquippedOutfitIndex then
        local currentOutfit = ZO_OUTFIT_MANAGER:GetOutfitManipulator(actorCategory, currentlyEquippedOutfitIndex)
        self.outfitSelectorNameLabel:SetText(currentOutfit:GetOutfitName())
    else
        self.outfitSelectorNameLabel:SetText(GetString(SI_NO_OUTFIT_EQUIP_ENTRY))
    end

    self.outfitSelectorHeaderFocus:Update()
end

function ZO_GamepadCollectionsBook:CanPreview(collectibleData)
    if collectibleData and collectibleData:IsInstanceOf(ZO_CollectibleData) then
        -- TODO: Temporarily disable mementos until time can be scheduled to audit mementos that don't preview correctly
        if collectibleData:GetCategoryType() == COLLECTIBLE_CATEGORY_TYPE_MEMENTO then
            return false
        end
        return CanCollectibleBePreviewed(collectibleData:GetId())
    end
    return false
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
        --Re-narrate when the previews are cleared
        SCREEN_NARRATION_MANAGER:QueueParametricListEntry(self.currentList.list)
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
            enabled = function()
                if self.outfitSelectorHeaderFocus:IsActive() and not self.isPreviewAvailable then
                    return false, GetString("SI_EQUIPOUTFITRESULT", EQUIP_OUTFIT_RESULT_OUTFIT_SWITCHING_UNAVAILABLE)
                end

                return true
            end,
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

    ZO_Gamepad_AddBackNavigationKeybindDescriptorsWithSound(self.subcategoryKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, function()
        self:ClearAllCurrentSlotPreviews()
        self:ShowList(self.categoryList)
    end)

    local function ClearPreviewGrid()
        self:ClearAllCurrentSlotPreviews()
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.gridKeybindStripDescriptor)
        --Re-narrate when the previews are cleared
        SCREEN_NARRATION_MANAGER:QueueGridListEntry(self.gridListPanelList)
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
            enabled = function()
                local collectibleData = self.gridListPanelList:GetSelectedData()
                if self.isPreviewAvailable and (not collectibleData.IsBlocked or not collectibleData:IsBlocked(GAMEPLAY_ACTOR_CATEGORY_PLAYER)) then
                    return true
                elseif not self.isPreviewAvailable then
                    return false, GetString(SI_PREVIEW_UNAVAILABLE_ERROR)
                end
                return false
            end,
            callback = function()
                self:TogglePreviewSelectedOutfitStyle()
            end,
            visible = function()
                 local currentlySelectedCollectibleData = self.gridListPanelList:GetSelectedData()
                 return  currentlySelectedCollectibleData and not currentlySelectedCollectibleData.isEmptyCell
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
                if collectibleData:IsUsable(GAMEPLAY_ACTOR_CATEGORY_PLAYER) or (collectibleData.IsHouse and collectibleData:IsHouse()) then
                    local nameStringId = collectibleData:GetPrimaryInteractionStringId(GAMEPLAY_ACTOR_CATEGORY_PLAYER)
                    return GetString(nameStringId)
                elseif collectibleData.CanPlaceInCurrentHouse and collectibleData:CanPlaceInCurrentHouse() then
                    return GetString(SI_ITEM_ACTION_PLACE_FURNITURE)
                end
            end,
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                local collectibleData = self:GetCurrentTargetData()
                if collectibleData.IsHouse and collectibleData:IsHouse() then
                    if collectibleData:IsLocked() then
                        -- Preview, behavior will always be inside
                        RequestJumpToHouse(collectibleData:GetReferenceId())
                        SCENE_MANAGER:ShowBaseScene()
                    else
                        ZO_Dialogs_ShowGamepadDialog("GAMEPAD_TRAVEL_TO_HOUSE_OPTIONS_DIALOG", collectibleData)
                    end
                elseif collectibleData:IsUsable(GAMEPLAY_ACTOR_CATEGORY_PLAYER) then
                    if IsCurrentlyPreviewing() then
                        ITEM_PREVIEW_GAMEPAD:EndCurrentPreview()
                    end
                    collectibleData:Use(GAMEPLAY_ACTOR_CATEGORY_PLAYER)
                    --Re-narrate after using the collectible
                    SCREEN_NARRATION_MANAGER:QueueParametricListEntry(self.currentList.list)
                elseif collectibleData.CanPlaceInCurrentHouse and collectibleData:CanPlaceInCurrentHouse() then
                    COLLECTIONS_BOOK_SINGLETON.TryPlaceCollectibleFurniture(collectibleData)
                end
            end,
            visible = function()
                local collectibleData = self:GetCurrentTargetData()
                if collectibleData then
                     if collectibleData.IsHouse and collectibleData:IsHouse() then
                        return true
                    elseif collectibleData:IsUsable(GAMEPLAY_ACTOR_CATEGORY_PLAYER) and collectibleData:GetPrimaryInteractionStringId() ~= nil then
                        return true
                    elseif collectibleData.CanPlaceInCurrentHouse and collectibleData:CanPlaceInCurrentHouse() then
                        return true
                    end
                else
                    return false
                end
            end,
            sound = SOUNDS.DEFAULT_CLICK,
            enabled = function()
                local collectibleData = self:GetCurrentTargetData()
                if collectibleData:IsInstanceOf(ZO_RandomMountCollectibleData) then
                    --This is a random mount data entry, not a regular ZO_CollectibleData
                    return not collectibleData:IsBlocked(GAMEPLAY_ACTOR_CATEGORY_PLAYER), collectibleData:GetBlockReason(GAMEPLAY_ACTOR_CATEGORY_PLAYER)
                elseif collectibleData.IsHouse and collectibleData:IsHouse() then
                    local cannotJumpString = collectibleData:IsUnlocked() and GetString(SI_COLLECTIONS_CANNOT_JUMP_TO_HOUSE_FROM_LOCATION) or GetString(SI_COLLECTIONS_CANNOT_PREVIEW_HOUSE_FROM_LOCATION)
                    return CanJumpToHouseFromCurrentLocation(), cannotJumpString
                elseif collectibleData:IsUsable(GAMEPLAY_ACTOR_CATEGORY_PLAYER) then
                    local remainingMs = GetCollectibleCooldownAndDuration(collectibleData:GetId())
                    if collectibleData:IsActive(GAMEPLAY_ACTOR_CATEGORY_PLAYER) then
                        return true
                    elseif remainingMs > 0 then
                        return false, GetString(SI_COLLECTIONS_COOLDOWN_ERROR)
                    elseif collectibleData:IsBlocked(GAMEPLAY_ACTOR_CATEGORY_PLAYER) then
                        local blockReason = GetCollectibleBlockReason(collectibleData:GetId(), GAMEPLAY_ACTOR_CATEGORY_PLAYER)
                        return false, zo_strformat(GetString("SI_COLLECTIBLEUSAGEBLOCKREASON", blockReason))
                    else
                        return true
                    end
                elseif collectibleData.CanPlaceInCurrentHouse and collectibleData:CanPlaceInCurrentHouse() then
                    return true
                end
            end
        },
        -- Assign to Quick Slot / Unlock
        {
            name = function()
                local collectibleData = self:GetCurrentTargetData()
                if collectibleData:IsSlottable() or (collectibleData:IsUnlocked() and collectibleData:IsCategoryType(COLLECTIBLE_CATEGORY_TYPE_EMOTE)) then
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
                    self:ShowAssignableUtilityWheel(collectibleData)
                elseif collectibleData:IsUnlocked() and collectibleData:IsCategoryType(COLLECTIBLE_CATEGORY_TYPE_EMOTE) then
                    local emoteInfo = PLAYER_EMOTE_MANAGER:GetEmoteItemInfo(collectibleData:GetReferenceId())
                    if emoteInfo then
                        local data =
                        {
                            type = ACTION_TYPE_EMOTE,
                            emoteCategory = emoteInfo.emoteCategory,
                        }
                        GAMEPAD_PLAYER_EMOTE:QueueBrowseToCategoryData(data)
                    end
                    self.savedCollectibleData = collectibleData
                    SCENE_MANAGER:Push("gamepad_player_emote")
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
                    if not collectibleData:IsInstanceOf(ZO_CollectibleData) then
                        return false
                    elseif collectibleData:IsSlottable() then
                        return true
                    elseif collectibleData:IsUnlocked() and collectibleData:IsCategoryType(COLLECTIBLE_CATEGORY_TYPE_EMOTE) then
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
                ZO_Dialogs_ShowGamepadDialog(GAMEPAD_COLLECTIONS_ACTIONS_DIALOG_NAME, collectibleData)
            end,
            visible = function()
                local collectibleData = self:GetCurrentTargetData()
                if collectibleData then
                    if not collectibleData:IsInstanceOf(ZO_CollectibleData) then
                        return false
                    end

                    local isHouse = collectibleData:IsHouse()
                    local isPrimaryResidence = collectibleData:IsPrimaryResidence()
                    return IsChatSystemAvailableForCurrentPlatform() or collectibleData:IsRenameable() or self:CanPurchaseCurrentTarget() or self:CanUpgradeCurrentTarget() or collectibleData:IsFavoritable() or (isHouse and not isPrimaryResidence)
                end

                return false
            end,
        },
        -- Preview
        {
            name = GetString(SI_COLLECTIBLE_ACTION_PREVIEW),
            keybind = "UI_SHORTCUT_QUATERNARY",
            callback = function()
                local collectibleData = self:GetCurrentTargetData()
                ITEM_PREVIEW_GAMEPAD:PreviewCollectible(collectibleData:GetId())
                KEYBIND_STRIP:UpdateKeybindButtonGroup(self.collectionKeybindStripDescriptor)
                --Re-narrate when the keybinds change
                SCREEN_NARRATION_MANAGER:QueueParametricListEntry(self.currentList.list)
            end,
            enabled = function()
                return IsCharacterPreviewingAvailable(), GetString(SI_PREVIEW_UNAVAILABLE_ERROR)
            end,
            visible = function()
                local collectibleData = self:GetCurrentTargetData()
                return self:CanPreview(collectibleData) and not ITEM_PREVIEW_GAMEPAD:IsCurrentlyPreviewing(ZO_ITEM_PREVIEW_COLLECTIBLE, collectibleData:GetId())
            end,
        },
        -- End Preview
        {
            name = GetString(SI_COLLECTIBLE_ACTION_END_PREVIEW),
            keybind = "UI_SHORTCUT_LEFT_STICK",
            callback = function()
                ITEM_PREVIEW_GAMEPAD:EndCurrentPreview()
                KEYBIND_STRIP:UpdateKeybindButtonGroup(self.collectionKeybindStripDescriptor)
                --Re-narrate when the keybinds change
                SCREEN_NARRATION_MANAGER:QueueParametricListEntry(self.currentList.list)
            end,
            visible = function()
                return IsCurrentlyPreviewing()
            end,
        },
        --Subscribe
        {
            alignment = KEYBIND_STRIP_ALIGN_RIGHT,
            name = GetString(SI_DLC_BOOK_ACTION_GET_SUBSCRIPTION),
            keybind = "UI_SHORTCUT_RIGHT_STICK",
            callback = function()
                ZO_ShowBuySubscriptionPlatformDialog()
            end,
            visible = function()
                local collectibleData = self:GetCurrentTargetData()
                if collectibleData then
                    if not collectibleData:IsInstanceOf(ZO_CollectibleData) then
                        return false
                    else
                        return collectibleData:IsStory() and collectibleData:IsUnlockedViaSubscription() and not IsESOPlusSubscriber()
                    end
                end

                return false
            end,
        },
    }

    local function OnCollectionListBack()
        if self.subcategoryList.list:IsEmpty() then
            self:ShowList(self.categoryList)
        else
            self:ShowList(self.subcategoryList)
        end
        ITEM_PREVIEW_GAMEPAD:EndCurrentPreview()
    end
    ZO_Gamepad_AddBackNavigationKeybindDescriptorsWithSound(self.collectionKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, OnCollectionListBack )
    
    --Utility Wheel Keybinds
    self.utilityAssignmentKeybindStripDescriptor = {}

    local function OnUtilityWheelBack()
        self:HideAssignableUtilityWheel()
    end

    local function OnAssignPendingData()
        self.wheel:TryAssignPendingToSelectedEntry()
    end

    local function ShouldShowAssignKeybind()
        return self.wheel:GetSelectedRadialEntry() ~= nil
    end

    ZO_Gamepad_AddForwardNavigationKeybindDescriptors(self.utilityAssignmentKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, OnAssignPendingData, GetString(SI_GAMEPAD_ITEM_ACTION_QUICKSLOT_ASSIGN), ShouldShowAssignKeybind)
    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.utilityAssignmentKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, OnUtilityWheelBack)

end

function ZO_GamepadCollectionsBook:ShowAssignableUtilityWheel(collectibleData)
    local useAccessibleWheel = GetSetting_Bool(SETTING_TYPE_ACCESSIBILITY, ACCESSIBILITY_SETTING_ACCESSIBLE_QUICKWHEELS)

    local categoryData = collectibleData:GetCategoryData()
    local hotbarCategory = GetHotbarForCollectibleCategoryId(categoryData.categoryId)
    --Determine which wheels we want to show
    local hotbarCategories
    if hotbarCategory then
        hotbarCategories = {hotbarCategory, HOTBAR_CATEGORY_QUICKSLOT_WHEEL}
    else
        hotbarCategories = { HOTBAR_CATEGORY_QUICKSLOT_WHEEL }
    end

    --Either show the accessible or regular utility wheel
    if useAccessibleWheel then
        self.savedCollectibleData = collectibleData
        local actionId = collectibleData:GetId()
        ACCESSIBLE_ASSIGNABLE_UTILITY_WHEEL_GAMEPAD:SetPendingSimpleAction(ACTION_TYPE_COLLECTIBLE, actionId)
        ACCESSIBLE_ASSIGNABLE_UTILITY_WHEEL_GAMEPAD:Show(hotbarCategories)
    else
        self.wheel:SetHotbarCategories(hotbarCategories)
        --Disable the current collections list before bringing up the wheel
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.currentList.keybind)
        self:DeactivateCurrentList()

        local actionId = collectibleData:GetId()
        self.wheel:SetPendingSimpleAction(ACTION_TYPE_COLLECTIBLE, actionId)

        self.assignLabel:SetHidden(false)
        self.selectedCollectibleNameLabel:SetHidden(false)
        self.selectedCollectibleNameLabel:SetText(collectibleData:GetFormattedName())
        self.pendingUtilityWheelCollectibleData = collectibleData

        KEYBIND_STRIP:AddKeybindButtonGroup(self.utilityAssignmentKeybindStripDescriptor)

        GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
        GAMEPAD_COLLECTIONS_BOOK_SCENE:AddFragment(GAMEPAD_NAV_QUADRANT_2_3_4_BACKGROUND_FRAGMENT)
        -- This will Activate the menu and show it
        self.wheel:Show()
    end
end

function ZO_GamepadCollectionsBook:HideAssignableUtilityWheel()
    if self.pendingUtilityWheelCollectibleData then
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.utilityAssignmentKeybindStripDescriptor)
        self.assignLabel:SetHidden(true)
        self.selectedCollectibleNameLabel:SetHidden(true)

        -- This will deactivate the menu and hide it
        self.wheel:Hide()
        GAMEPAD_COLLECTIONS_BOOK_SCENE:RemoveFragment(GAMEPAD_NAV_QUADRANT_2_3_4_BACKGROUND_FRAGMENT)

        --Re-show the tooltip that we had supressed while the wheel was up
        self:RefreshStandardTooltip(self.pendingUtilityWheelCollectibleData)
        self.pendingUtilityWheelCollectibleData = nil

        --Reactivate the collectible list now that we are done with the wheel
        KEYBIND_STRIP:AddKeybindButtonGroup(self.currentList.keybind)
        self:ActivateCurrentList()
    end
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
            if collectibleData:IsInstanceOf(ZO_CollectibleData) and collectibleData:GetId() == collectibleId then
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
            ApplyChangesToPreviewCollectionShown()
        end
    end

    if not dontUpdateTitle then
        self.headerData.titleText = list.titleText
        self:RefreshHeader()
    end

    if self:IsViewingCollectionsList() then
        local collectibleData = self:GetCurrentTargetData()
        if collectibleData then
            if collectibleData:IsInstanceOf(ZO_CollectibleData) then
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

function ZO_GamepadCollectionsBook:OnCollectionUpdated(collectionUpdateType)
    if not self.control:IsHidden() then
        if self.gridListPanelList and self.gridListPanelList:IsActive() then
            self:ExitGridList()
        end

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
        elseif self.gridListPanelList:IsActive() then
            self.gridListPanelList:RefreshGridList()
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

function ZO_GamepadCollectionsBook:OnCollectibleUserFlagsUpdated(collectibleId)
    self:OnCollectibleUpdated(collectibleId)
end

function ZO_GamepadCollectionsBook:BuildCategoryList()
    self.categoryList.list:Clear()

    -- Add the categories entries
    for categoryIndex, categoryData in ZO_COLLECTIBLE_DATA_MANAGER:CategoryIterator({ ZO_CollectibleCategoryData.HasShownCollectiblesInCollection }) do
        -- Tribute patron special categories are in a different scene
        if not categoryData:IsTributePatronCategory() then
            local formattedCategoryName = categoryData:GetFormattedName()
            local gamepadIcon = categoryData:GetGamepadIcon()

            local entryData = ZO_GamepadEntryData:New(formattedCategoryName, gamepadIcon)
            entryData:SetDataSource(categoryData)
            entryData:SetIconTintOnSelection(true)

            self.categoryList.list:AddEntry("ZO_GamepadMenuEntryTemplate", entryData)
        end
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

    local favoriteData = {}
    local unlockedData = {}
    local lockedData = {}
    self.updateList = {}

    local hasAnyCollectibles = false

    for _, collectibleData in categoryData:SortedCollectibleIterator({ ZO_CollectibleData.IsShownInCollection }) do
        local entryData = self:BuildCollectibleData(collectibleData)
        if collectibleData:IsUnlocked() then
            if collectibleData:IsFavorite() then
                table.insert(favoriteData, entryData)
            else
                table.insert(unlockedData, entryData)
            end

            table.insert(self.updateList, entryData)
        else
            table.insert(lockedData, entryData)
        end

        hasAnyCollectibles = true
    end

    collectionListInfo.titleText = categoryData:GetFormattedName()

    if hasAnyCollectibles then
        -- Add Random Selections
        local collectibleCategoryTypesInCategory = categoryData:GetCollectibleCategoryTypesInCategory()
        if collectibleCategoryTypesInCategory[COLLECTIBLE_CATEGORY_TYPE_MOUNT] then
            local setRandomFavoriteMountData = ZO_RandomMountCollectibleData:New(RANDOM_MOUNT_TYPE_FAVORITE)
            local randomFavoriteMountEntryData = self:BuildCollectibleCategorySetRandomSelectionData(setRandomFavoriteMountData)
            ZO_UpdateCollectibleEntryDataIconVisuals(randomFavoriteMountEntryData, GAMEPLAY_ACTOR_CATEGORY_PLAYER)
            collectionList:AddEntry("ZO_GamepadCollectibleEntryTemplate", randomFavoriteMountEntryData)

            local setRandomMountData = ZO_RandomMountCollectibleData:New(RANDOM_MOUNT_TYPE_ANY)
            local randomMountEntryData = self:BuildCollectibleCategorySetRandomSelectionData(setRandomMountData)
            ZO_UpdateCollectibleEntryDataIconVisuals(randomMountEntryData, GAMEPLAY_ACTOR_CATEGORY_PLAYER)
            collectionList:AddEntry("ZO_GamepadCollectibleEntryTemplate", randomMountEntryData)
        end
    end

    self:BuildListFromTable(collectionList, favoriteData, GetString(SI_COLLECTIONS_FAVORITES_CATEGORY_HEADER))
    self:BuildListFromTable(collectionList, unlockedData, GetString("SI_COLLECTIBLEUNLOCKSTATE", COLLECTIBLE_UNLOCK_STATE_UNLOCKED_OWNED))
    self:BuildListFromTable(collectionList, lockedData, GetString("SI_COLLECTIBLEUNLOCKSTATE", COLLECTIBLE_UNLOCK_STATE_LOCKED))

    collectionList:Commit(resetSelectionToTop)

    KEYBIND_STRIP:UpdateKeybindButtonGroup(collectionListInfo.keybind)

    self.currentCategoryData = categoryData
end

function ZO_GamepadCollectionsBook:UpdateCollectionListVisualLayer()
    local list = self.collectionList.list
    for i = 1, list:GetNumItems() do
        local entryData = list:GetDataForDataIndex(i)

        if entryData.IsVisualLayerHidden then
            entryData:SetIsHiddenByWardrobe(entryData:IsVisualLayerHidden(GAMEPLAY_ACTOR_CATEGORY_PLAYER))
        end
    end

    self:RefreshRightPanel(self.collectionList.list:GetTargetData())
end

function ZO_GamepadCollectionsBook:BuildCollectibleCategorySetRandomSelectionData(collectibleData)
    local entryData = ZO_GamepadEntryData:New(collectibleData:GetName(), collectibleData:GetIcon())
    entryData:SetDataSource(collectibleData)
    entryData.actorCategory = GAMEPLAY_ACTOR_CATEGORY_PLAYER
    entryData.isEquippedInCurrentCategory = collectibleData:IsActive(GAMEPLAY_ACTOR_CATEGORY_PLAYER)

    return entryData
end

function ZO_GamepadCollectionsBook:BuildCollectibleData(collectibleData)
    local function GetStoryNarrationText(entryData, entryControl)
        local narrations = {}

        -- Generate the standard parametric list entry narration
        ZO_AppendNarration(narrations, ZO_GetSharedGamepadEntryDefaultNarrationText(entryData, entryControl))

        -- Unlock state narration
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString("SI_COLLECTIBLEUNLOCKSTATE", entryData:GetUnlockState())))

        -- DLC name narration
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(entryData:GetFormattedName()))

        -- Quest status narration
        local isActive = entryData.isEquippedInCurrentCategory
        local questAcceptLabelString = isActive and GetString(SI_DLC_BOOK_QUEST_STATUS_ACCEPTED) or GetString(SI_DLC_BOOK_QUEST_STATUS_NOT_ACCEPTED)
        local questName = entryData:GetQuestName()
        local questNameWithStatus = zo_strformat(SI_GAMEPAD_DLC_BOOK_QUEST_STATUS_INFO, questName, questAcceptLabelString)

        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_GAMEPAD_DLC_BOOK_QUEST_STATUS_HEADER)))
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(questNameWithStatus))

        -- DLC description narration
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(entryData:GetDescription()))

        -- Quest-related narration
        local questAvailableText = nil
        local questDescription = nil
        local isUnlocked = entryData:IsUnlocked()
        local showsQuest = isUnlocked and not isActive

        if showsQuest then
            questAvailableText = GetString(SI_COLLECTIONS_QUEST_AVAILABLE)
            questDescription = entryData:GetQuestDescription()
        elseif not isUnlocked then
            local isChapter = entryData:IsCategoryType(COLLECTIBLE_CATEGORY_TYPE_CHAPTER)
            if entryData:IsPurchasable() or entryData:IsUnlockedViaSubscription() or isChapter then
                questAvailableText = isChapter and GetString(SI_COLLECTIONS_QUEST_AVAILABLE_WITH_UPGRADE) or GetString(SI_COLLECTIONS_QUEST_AVAILABLE_WITH_UNLOCK)
            end
        end

        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(questAvailableText))
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(questDescription))

        return narrations
    end

    local function GetHouseNarrationText(entryData, entryControl)
        local narrations = {}

        -- Generate the standard parametric list entry narration
        ZO_AppendNarration(narrations, ZO_GetSharedGamepadEntryDefaultNarrationText(entryData, entryControl))

        -- Unlock state narration
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString("SI_COLLECTIBLEUNLOCKSTATE", entryData:GetUnlockState())))

        -- House name narration
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(entryData:GetFormattedName()))

        -- House nickname narration
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(entryData:GetFormattedNickname()))

        -- House location narration
        local locationName = entryData:GetFormattedHouseLocation()
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_HOUSING_LOCATION_HEADER)))
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(locationName))

        -- House type narration
        local houseType = zo_strformat(SI_HOUSE_TYPE_FORMATTER, GetString("SI_HOUSECATEGORYTYPE", entryData:GetHouseCategoryType()))
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_HOUSING_HOUSE_TYPE_HEADER)))
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(houseType))

        -- House supports weather control narration
        local houseFlags = entryData:GetHouseFlags()
        local hasWeatherControlSupport = ZO_FlagHelpers.MaskHasFlag(houseFlags, HOUSE_FLAGS_SUPPORTS_WEATHER_CONTROL)
        local hasWeatherControlSupportString = hasWeatherControlSupport and GetString(SI_YES) or GetString(SI_NO)
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_HOUSING_HOUSE_SUPPORTS_WEATHER_CONTROL_HEADER)))
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(hasWeatherControlSupportString))

        --Home Tour Recommendations narration
        local houseId = entryData:GetReferenceId()
        local recommendCount = GetNumHouseToursPlayerListingRecommendations(houseId)
        if recommendCount > 0 then
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_HOUSING_HOUSE_TOUR_RECOMMENDATION_COUNT_HEADER)))
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(recommendCount))
        end

        -- House description narration
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(entryData:GetDescription()))

        -- Additional narration (includes whether or not the house is the player's primary residence; if the player cannot teleport;
        -- or an acquire hint; these three values are all mutually exclusive
        local additionalHeaderText = nil
        local additionalText = nil
        local isUnlocked = entryData:IsUnlocked()

        if not CanJumpToHouseFromCurrentLocation() then
            additionalText = isUnlocked and GetString(SI_COLLECTIONS_CANNOT_JUMP_TO_HOUSE_FROM_LOCATION) or GetString(SI_COLLECTIONS_CANNOT_PREVIEW_HOUSE_FROM_LOCATION)
        elseif isUnlocked then
            additionalHeaderText = GetString(SI_HOUSING_PRIMARY_RESIDENCE_HEADER)
            additionalText = entryData:IsPrimaryResidence() and GetString(SI_YES) or GetString(SI_NO)
        else
            additionalText = zo_strformat(SI_COLLECTIBLE_ACQUIRE_HINT_FORMATTER, entryData:GetHint())
        end

        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(additionalHeaderText))
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(additionalText))

        return narrations
    end

    local function GetCollectibleNarrationText(entryData, entryControl)
        local narrations = {}

        -- Generate the standard parametric list entry narration
        ZO_AppendNarration(narrations, ZO_GetSharedGamepadEntryDefaultNarrationText(entryData, entryControl))

        if IsCurrentlyPreviewing() then
            ZO_AppendNarration(narrations, ITEM_PREVIEW_GAMEPAD:GetPreviewSpinnerNarrationText())
        end

        return narrations
    end

    local collectibleId = collectibleData:GetId()

    local entryData = ZO_GamepadEntryData:New(collectibleData:GetFormattedName(), collectibleData:GetIcon())
    entryData:SetDataSource(collectibleData)
    entryData:SetCooldownIcon(collectibleData:GetIcon())

    if collectibleData:IsStory() then
        local questState = collectibleData:GetCollectibleAssociatedQuestState()
        entryData.isEquippedInCurrentCategory = questState == COLLECTIBLE_ASSOCIATED_QUEST_STATE_ACCEPTED or questState == COLLECTIBLE_ASSOCIATED_QUEST_STATE_COMPLETED
        entryData.narrationText = GetStoryNarrationText
    elseif collectibleData:IsHouse() then
        entryData.isEquippedInCurrentCategory = collectibleData:IsActive(GAMEPLAY_ACTOR_CATEGORY_PLAYER)
        entryData.narrationText = GetHouseNarrationText
    else
        entryData.isEquippedInCurrentCategory = collectibleData:IsActive(GAMEPLAY_ACTOR_CATEGORY_PLAYER) and not collectibleData:ShouldSuppressActiveState(GAMEPLAY_ACTOR_CATEGORY_PLAYER)
        entryData.narrationText = GetCollectibleNarrationText
    end

    entryData:SetIsHiddenByWardrobe(collectibleData:IsVisualLayerHidden(GAMEPLAY_ACTOR_CATEGORY_PLAYER))

    ZO_UpdateCollectibleEntryDataIconVisuals(entryData, GAMEPLAY_ACTOR_CATEGORY_PLAYER)

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

        -- Since this screen disabled resetting scroll in order to stop tooltip jitter when timers update,
        -- now we need to reset the scroll manually.
        local newCollectibleName = GetCollectibleName(selectedData.dataSource.collectibleId)
        if newCollectibleName ~= self.currentCollectibleName then
            self.currentCollectibleName = newCollectibleName
            GAMEPAD_TOOLTIPS:ResetScrollTooltipToTop(GAMEPAD_LEFT_TOOLTIP)
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
    if self.pendingUtilityWheelCollectibleData then
        -- Don't cover the wheel if it's open.
        return
    elseif entryData then
        if entryData.dataSource:IsInstanceOf(ZO_CollectibleCategoryData) then
            self:UpdateGridPanelVisibility(entryData)
            SCENE_MANAGER:RemoveFragment(GAMEPAD_COLLECTIONS_BOOK_DLC_PANEL_FRAGMENT)
            SCENE_MANAGER:RemoveFragment(GAMEPAD_COLLECTIONS_BOOK_HOUSING_PANEL_FRAGMENT)
            GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
        elseif entryData.dataSource:IsInstanceOf(ZO_RandomMountCollectibleData) then
            self:RefreshRandomMountTooltip(entryData)
        elseif entryData:IsStory() then
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

    local questState = collectibleData:GetCollectibleAssociatedQuestState()

    local isUnlocked = collectibleData:IsUnlocked()
    local isActive = questState == COLLECTIBLE_ASSOCIATED_QUEST_STATE_ACCEPTED or questState == COLLECTIBLE_ASSOCIATED_QUEST_STATE_COMPLETED

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
    housingPanel.houseTypeLabel:SetText(zo_strformat(SI_HOUSE_TYPE_FORMATTER, GetString("SI_HOUSECATEGORYTYPE", collectibleData:GetHouseCategoryType())))

    local houseFlags = collectibleData:GetHouseFlags()
    local hasWeatherControlSupport = ZO_FlagHelpers.MaskHasFlag(houseFlags, HOUSE_FLAGS_SUPPORTS_WEATHER_CONTROL)
    local hasWeatherControlSupportString = hasWeatherControlSupport and GetString(SI_YES) or GetString(SI_NO)
    housingPanel.supportsWeatherControlValueLabel:SetText(hasWeatherControlSupportString)

    local houseId = collectibleData:GetReferenceId()
    local recommendCount = GetNumHouseToursPlayerListingRecommendations(houseId)
    if recommendCount > 0 then
        housingPanel.recommendCountValue:SetText(ZO_CommaDelimitNumber(recommendCount))
        housingPanel.recommendCountHeader:SetHidden(false)
        housingPanel.recommendCountValue:SetHidden(false)
    else
        housingPanel.recommendCountHeader:SetHidden(true)
        housingPanel.recommendCountValue:SetHidden(true)
    end

    housingPanel.descriptionLabel:SetText(collectibleData:GetDescription())
    housingPanel.collectedStatusLabel:SetText(GetString("SI_COLLECTIBLEUNLOCKSTATE", collectibleData:GetUnlockState()))
    housingPanel.nicknameLabel:SetText(collectibleData:GetFormattedNickname())

    if not CanJumpToHouseFromCurrentLocation() then
        local disableReason = collectibleData:IsUnlocked() and GetString(SI_COLLECTIONS_CANNOT_JUMP_TO_HOUSE_FROM_LOCATION) or GetString(SI_COLLECTIONS_CANNOT_PREVIEW_HOUSE_FROM_LOCATION)
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
        housingPanel.hintLabel:SetText(zo_strformat(SI_COLLECTIBLE_ACQUIRE_HINT_FORMATTER, collectibleData:GetHint()))
        housingPanel.hintLabel:SetHidden(false)
        housingPanel.primaryResidenceHeaderLabel:SetHidden(true)
        housingPanel.primaryResidenceValueLabel:SetHidden(true)
    end

    SCENE_MANAGER:AddFragment(GAMEPAD_NAV_QUADRANT_2_3_BACKGROUND_FRAGMENT)
    SCENE_MANAGER:AddFragment(GAMEPAD_COLLECTIONS_BOOK_HOUSING_PANEL_FRAGMENT)
end

function ZO_GamepadCollectionsBook:RefreshRandomMountTooltip(collectibleData)
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP, true)

    GAMEPAD_TOOLTIPS:LayoutImitationCollectibleFromData(GAMEPAD_LEFT_TOOLTIP, collectibleData, GAMEPLAY_ACTOR_CATEGORY_PLAYER)
end

function ZO_GamepadCollectionsBook:UpdateGridPanelVisibility(categoryData)
    local shouldFrameRight = false
    if categoryData and categoryData:IsOutfitStylesCategory() and categoryData:GetNumCollectibles() > 0 then
        self:RefreshGridListPanel(categoryData)

        SCENE_MANAGER:AddFragment(GAMEPAD_NAV_QUADRANT_2_3_BACKGROUND_FRAGMENT)
        SCENE_MANAGER:AddFragment(GAMEPAD_COLLECTIONS_BOOK_GRID_LIST_PANEL_FRAGMENT)

        shouldFrameRight = true
    else
        SCENE_MANAGER:RemoveFragment(GAMEPAD_NAV_QUADRANT_2_3_BACKGROUND_FRAGMENT)
        SCENE_MANAGER:RemoveFragment(GAMEPAD_COLLECTIONS_BOOK_GRID_LIST_PANEL_FRAGMENT)
    end

    if shouldFrameRight ~= self.shouldFrameRight then
        self.shouldFrameRight = shouldFrameRight
        if shouldFrameRight then
            SCENE_MANAGER:RemoveFragmentGroup(FRAGMENT_GROUP.FRAME_TARGET_GAMEPAD_COLLECTIONS)
            SCENE_MANAGER:AddFragmentGroup(FRAGMENT_GROUP.FRAME_TARGET_GAMEPAD_RIGHT_FURTHER_AWAY)
        else
            SCENE_MANAGER:RemoveFragmentGroup(FRAGMENT_GROUP.FRAME_TARGET_GAMEPAD_RIGHT_FURTHER_AWAY)
            SCENE_MANAGER:AddFragmentGroup(FRAGMENT_GROUP.FRAME_TARGET_GAMEPAD_COLLECTIONS)
        end
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

function ZO_GamepadCollectionsBook:ClearAllCurrentSlotPreviews()
    for outfitSlot, _ in pairs(self.currentSlotPreviews) do
        ClearOutfitSlotPreviewElementFromPreviewCollection(outfitSlot)
    end
    ApplyChangesToPreviewCollectionShown()
    ZO_ClearTable(self.currentSlotPreviews)
    self.gridListPanelList:RefreshGridList()
end

function ZO_GamepadCollectionsBook:TogglePreviewSelectedOutfitStyle()
    local itemMaterialIndex = ZO_OUTFIT_STYLE_DEFAULT_ITEM_MATERIAL_INDEX

    local currentlySelectedCollectibleData = self.gridListPanelList:GetSelectedData()
    if currentlySelectedCollectibleData and not currentlySelectedCollectibleData.isEmptyCell then
        local preferredOutfitSlot = ZO_OUTFIT_MANAGER:GetPreferredOutfitSlotForStyle(currentlySelectedCollectibleData)
        if self:IsPreviewingOutfitStyle(currentlySelectedCollectibleData, itemMaterialIndex, preferredOutfitSlot) then
            ClearOutfitSlotPreviewElementFromPreviewCollection(preferredOutfitSlot)
            ApplyChangesToPreviewCollectionShown()
            self.currentSlotPreviews[preferredOutfitSlot] = nil
        else
            local primaryDye, secondaryDye, accentDye = 0, 0, 0
            local actorCategory, currentOutfitIndex = ZO_OUTFITS_SELECTOR_GAMEPAD:GetCurrentActorCategoryAndIndex()
            if currentOutfitIndex then
                local outfitManipulator = ZO_OUTFIT_MANAGER:GetOutfitManipulator(actorCategory, currentOutfitIndex)
                local slotManipulator = outfitManipulator:GetSlotManipulator(preferredOutfitSlot)
                if slotManipulator then
                    primaryDye, secondaryDye, accentDye = slotManipulator:GetPendingDyeData()
                end
            else
                local equipSlot = GetEquipSlotForOutfitSlot(preferredOutfitSlot)
                if CanEquippedItemBeShownInOutfitSlot(GAMEPLAY_ACTOR_CATEGORY_PLAYER, equipSlot, preferredOutfitSlot) then
                    primaryDye, secondaryDye, accentDye = GetPendingSlotDyes(RESTYLE_MODE_EQUIPMENT, ZO_RESTYLE_DEFAULT_SET_INDEX, equipSlot)
                end
            end

            local collectibleId = currentlySelectedCollectibleData:GetId()
            self.currentSlotPreviews[preferredOutfitSlot] = 
            {
                collectibleId = collectibleId,
                itemMaterialIndex = itemMaterialIndex,
            }

            AddOutfitSlotPreviewElementToPreviewCollection(preferredOutfitSlot, collectibleId, itemMaterialIndex, primaryDye, secondaryDye, accentDye)
            ApplyChangesToPreviewCollectionShown()
        end
        self.gridListPanelList:RefreshGridList()
        --Re-narrate when the preview state is toggled
        SCREEN_NARRATION_MANAGER:QueueGridListEntry(self.gridListPanelList)
    end

    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.gridKeybindStripDescriptor)
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
    ZO_OUTFITS_SELECTOR_GAMEPAD:SetCurrentActorCategory(GAMEPLAY_ACTOR_CATEGORY_PLAYER)
    local _, currentOutfitIndex = ZO_OUTFITS_SELECTOR_GAMEPAD:GetCurrentActorCategoryAndIndex()
    if currentOutfitIndex then
        ITEM_PREVIEW_GAMEPAD:PreviewOutfit(GAMEPLAY_ACTOR_CATEGORY_PLAYER, currentOutfitIndex)
    else
        ITEM_PREVIEW_GAMEPAD:PreviewUnequipOutfit(GAMEPLAY_ACTOR_CATEGORY_PLAYER)
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
        ZO_UpdateCollectibleEntryDataIconVisuals(entryData, GAMEPLAY_ACTOR_CATEGORY_PLAYER)
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
        return collectibleData and collectibleData:IsPurchasable() and collectibleData:CanAcquire() and not collectibleData:IsHouse()
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
            -- Primary Interaction
            {
                template = "ZO_GamepadMenuEntryTemplate",
                text = function(dialog)
                    local collectibleData = dialog.data
                    local nameStringId = collectibleData:GetPrimaryInteractionStringId(GAMEPLAY_ACTOR_CATEGORY_PLAYER)
                    return GetString(nameStringId)
                end,
                templateData =
                {
                    setup = ZO_SharedGamepadEntry_OnSetup,
                    callback = function(dialog)
                        local collectibleData = dialog.data
                        collectibleData:Use(GAMEPLAY_ACTOR_CATEGORY_PLAYER)
                    end,
                    visible = function(dialog)
                        local collectibleData = dialog.data
                        if not collectibleData then
                            return false
                        end
                        return collectibleData:IsUsable(GAMEPLAY_ACTOR_CATEGORY_PLAYER) and not collectibleData:IsSkillStyle()
                    end,
                    enabled = function(dialog)
                        local collectibleData = dialog.data
                        if collectibleData:IsActive(GAMEPLAY_ACTOR_CATEGORY_PLAYER) then
                            return true
                        end
                        local remainingMs = GetCollectibleCooldownAndDuration(collectibleData:GetId())
                        if remainingMs > 0 then
                            return false
                        end
                        if collectibleData:IsBlocked(GAMEPLAY_ACTOR_CATEGORY_PLAYER) then
                            return false
                        end
                        return true
                    end,
                },
            },
            -- Place Furniture
            {
                template = "ZO_GamepadMenuEntryTemplate",
                templateData = 
                {
                    text = GetString(SI_ITEM_ACTION_PLACE_FURNITURE),
                    setup = ZO_SharedGamepadEntry_OnSetup,
                    callback = function(dialog)
                        local collectibleData = dialog.data
                        COLLECTIONS_BOOK_SINGLETON.TryPlaceCollectibleFurniture(collectibleData)
                    end,
                    visible = function(dialog)
                        local collectibleData = dialog.data
                        return collectibleData and collectibleData.CanPlaceInCurrentHouse and collectibleData:CanPlaceInCurrentHouse()
                    end,
                },
            },
            -- Link In Chat
            {
                template = "ZO_GamepadMenuEntryTemplate",
                templateData = 
                {
                    text = GetString(SI_ITEM_ACTION_LINK_TO_CHAT),
                    setup = ZO_SharedGamepadEntry_OnSetup,
                    callback = function(dialog)
                        local link = ZO_LinkHandler_CreateChatLink(GetCollectibleLink, dialog.data:GetId())
                        ZO_LinkHandler_InsertLinkAndSubmit(zo_strformat(SI_TOOLTIP_ITEM_NAME, link))
                    end,
                    visible = function(dialog)
                        return IsChatSystemAvailableForCurrentPlatform() and not (dialog.data:IsHouse() and dialog.data:IsUnlocked())
                    end,
                },
            },
            -- Link Invite In Chat (Housing)
            {
                template = "ZO_GamepadMenuEntryTemplate",
                templateData = 
                {
                    text = GetString(SI_HOUSING_LINK_IN_CHAT),
                    setup = ZO_SharedGamepadEntry_OnSetup,
                    callback = function(dialog)
                        local houseId = dialog.data:GetReferenceId()
                        local ownerDisplayName = GetDisplayName()
                        ZO_HousingBook_LinkHouseInChat(houseId, ownerDisplayName)
                    end,
                    visible = function(dialog)
                        return IsChatSystemAvailableForCurrentPlatform() and (dialog.data:IsHouse() and dialog.data:IsUnlocked())
                    end,
                },
            },
            -- Link Invite in Mail (Housing)
            {
                template = "ZO_GamepadMenuEntryTemplate",
                templateData = 
                {
                    text = GetString(SI_HOUSING_LINK_IN_MAIL),
                    setup = ZO_SharedGamepadEntry_OnSetup,
                    callback = function(dialog)
                        local houseId = dialog.data:GetReferenceId()
                        local ownerDisplayName = GetDisplayName()
                        local link = ZO_HousingBook_GetHouseLink(houseId, ownerDisplayName)
                        if link then
                            MAIL_GAMEPAD.inbox:InsertBodyText(link)
                        end
                    end,
                    visible = function(dialog)
                        return IsChatSystemAvailableForCurrentPlatform() and (dialog.data:IsHouse() and dialog.data:IsUnlocked())
                    end,
                },
            },
            -- Show Achievement
            {
                template = "ZO_GamepadMenuEntryTemplate",
                templateData = 
                {
                    text = GetString(SI_COLLECTIBLE_ACTION_SHOW_ACHIEVEMENT),
                    setup = ZO_SharedGamepadEntry_OnSetup,
                    callback = function(dialog)
                        local collectibleData = self:GetCurrentTargetData()
                        local linkedAchievement = collectibleData:GetLinkedAchievement()
                        SYSTEMS:GetObject("achievements"):ShowAchievement(linkedAchievement)
                    end,
                    visible = function(dialog)
                        local collectibleData = self:GetCurrentTargetData()
                        if collectibleData and collectibleData:IsInstanceOf(ZO_CollectibleData) then
                            local linkedAchievement = collectibleData:GetLinkedAchievement()
                            return linkedAchievement > 0
                        end
                        return false
                    end,
                },
            },
            -- Show in Skills
            {
                template = "ZO_GamepadMenuEntryTemplate",
                templateData = 
                {
                    text = GetString(SI_COLLECTIBLE_ACTION_SHOW_IN_SKILLS),
                    setup = ZO_SharedGamepadEntry_OnSetup,
                    callback = function(dialog)
                        local collectibleData = self:GetCurrentTargetData()
                        local skillStyleProgressionId = collectibleData:GetSkillStyleProgressionId()
                        local skillData = SKILLS_DATA_MANAGER:GetSkillDataByProgressionId(skillStyleProgressionId)
                        MAIN_MENU_GAMEPAD:ShowScene("gamepad_skills_root")
                        GAMEPAD_SKILLS:SelectSkillLineBySkillData(skillData)
                    end,
                    visible = function(dialog)
                        local collectibleData = self:GetCurrentTargetData()
                        if collectibleData and collectibleData:IsInstanceOf(ZO_CollectibleData) then
                            local skillStyleProgressionId = collectibleData:GetSkillStyleProgressionId()
                            local skillData = SKILLS_DATA_MANAGER:GetSkillDataByProgressionId(skillStyleProgressionId)
                            return collectibleData:IsSkillStyle() and skillData:IsPurchased()
                        end
                        return false
                    end,
                },
            },
            -- Rename
            {
                template = "ZO_GamepadMenuEntryTemplate",
                templateData = 
                {
                    text = GetString(SI_COLLECTIBLE_ACTION_RENAME),
                    setup = ZO_SharedGamepadEntry_OnSetup,
                    callback = function(dialog)
                       local nickname = dialog.data:GetNickname()
                       local defaultNickname = dialog.data:GetDefaultNickname()
                       --Only pre-fill the edit text if it's different from the default nickname
                       local initialEditText = ""
                       if nickname ~= defaultNickname then
                           initialEditText = nickname
                       end
                       ZO_Dialogs_ShowGamepadDialog(GAMEPAD_COLLECTIONS_RENAME_COLLECTIBLE_DIALOG_NAME, { collectibleId = dialog.data:GetId(), name = initialEditText, defaultName = defaultNickname })
                    end,
                    visible = function(dialog)
                        return dialog.data:IsRenameable()
                    end
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
                        local searchTerm = zo_strformat(SI_CROWN_STORE_SEARCH_FORMAT_STRING, dialog.data:GetName())
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
                templateData = 
                {
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
            -- Add/Remove Favorite
            {
                template = "ZO_GamepadMenuEntryTemplate",
                text = function(dialog)
                    return dialog.data:IsFavorite() and GetString(SI_COLLECTIBLE_ACTION_REMOVE_FAVORITE) or GetString(SI_COLLECTIBLE_ACTION_ADD_FAVORITE)
                end,
                templateData = 
                {
                    setup = ZO_SharedGamepadEntry_OnSetup,
                    callback = function(dialog)
                        SetOrClearCollectibleUserFlag(dialog.data:GetId(), COLLECTIBLE_USER_FLAG_FAVORITE, not dialog.data:IsFavorite())
                    end,
                    visible = function(dialog)
                        return dialog.data:IsFavoritable()
                    end
                },
            },
            -- Set as Primary Residence
            {
                template = "ZO_GamepadMenuEntryTemplate",
                text = GetString(SI_HOUSING_FURNITURE_SETTINGS_GENERAL_PRIMARY_RESIDENCE_BUTTON_TEXT),
                templateData = 
                {
                    setup = ZO_SharedGamepadEntry_OnSetup,
                    callback = function(dialog)
                        COLLECTIONS_BOOK_SINGLETON:SetPrimaryResidence(dialog.data:GetReferenceId())
                    end,
                    visible = function(dialog)
                        return dialog.data:IsUnlocked() and dialog.data:IsHouse() and not dialog.data:IsPrimaryResidence()
                    end
                },
            },
            -- Tour Home
            {
                template = "ZO_GamepadMenuEntryTemplate",
                text = GetString(SI_COLLECTIBLE_ACTION_TOUR_THIS_HOME),
                templateData = 
                {
                    setup = ZO_SharedGamepadEntry_OnSetup,
                    callback = function(dialog)
                        --Order matters. Attempt to browse to the house before showing it in the activity finder
                        HOUSE_TOURS_GAMEPAD:BrowseSpecificHouse(dialog.data:GetReferenceId())
                        ZO_ACTIVITY_FINDER_ROOT_GAMEPAD:ShowCategory(HOUSE_TOURS_GAMEPAD:GetCategoryData())
                    end,
                    visible = function(dialog)
                        return dialog.data:IsHouse() and ZO_IsHouseToursEnabled()
                    end
                },
            },
        },
        buttons =
        {
            {
                keybind = "DIALOG_PRIMARY",
                text = SI_OK,
                callback = function(dialog)
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

    local function UpdateSelectedName(name, isHouse)
        if(self.selectedName ~= name or not self.noViolations) then
            self.selectedName = name

            if isHouse then
                self.nameViolations = { IsValidHouseName(self.selectedName) }
            else
                self.nameViolations = { IsValidCollectibleName(self.selectedName) }
            end
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

    local function SetActiveEdit(edit, isHouse)
        edit:TakeFocus()
        UpdateSelectedName(inputText, isHouse)
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
                template = "ZO_Gamepad_GenericDialog_Parametric_TextFieldItem",
                templateData = 
                {
                    nameField = true,
                    textChangedCallback = function(control) 
                        inputText = control:GetText()
                        local isHouse
                        if parametricDialog.data then
                            parametricDialog.data.name = inputText
                            isHouse = GetCollectibleCategoryType(parametricDialog.data.collectibleId) == COLLECTIBLE_CATEGORY_TYPE_HOUSE
                        end
                        UpdateSelectedName(inputText, isHouse)
                    end,
                    setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                        control.editBoxControl.textChangedCallback = data.textChangedCallback
                        control.editBoxControl:SetMaxInputChars(COLLECTIBLE_NAME_MAX_LENGTH)
                        data.control = control

                        if parametricDialog.data then
                            control.editBoxControl:SetText(zo_strformat(SI_COLLECTIBLE_NAME_FORMATTER, parametricDialog.data.name))
                            control.editBoxControl:SetDefaultText(zo_strformat(SI_COLLECTIBLE_NAME_FORMATTER, parametricDialog.data.defaultName))
                        end
                    end, 
                    narrationText = ZO_GetDefaultParametricListEditBoxNarrationText,
                    narrationTooltip = GAMEPAD_LEFT_DIALOG_TOOLTIP,
                },
                
            },
        },
        blockDialogReleaseOnPress = true,
        buttons =
        {
            {
                keybind = "DIALOG_PRIMARY",
                text = SI_GAMEPAD_SELECT_OPTION,
                callback = function(dialog)
                    local data = dialog.entryList:GetTargetData()
                    local isHouse
                    if dialog.data then
                        isHouse = GetCollectibleCategoryType(dialog.data.collectibleId) == COLLECTIBLE_CATEGORY_TYPE_HOUSE
                    end
                    SetActiveEdit(data.control.editBoxControl, isHouse)
                end,
            },
            {
                keybind = "DIALOG_SECONDARY",
                text = SI_GAMEPAD_COLLECTIONS_SAVE_NAME_OPTION,
                callback = function(dialog)
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
                keybind = "DIALOG_TERTIARY",
                text = SI_COLLECTIONS_INVENTORY_DIALOG_DEFAULT_NAME,
                callback = function(dialog)
                    local data = dialog.entryList:GetTargetData()
                    data.control.editBoxControl:SetText("")
                end,
            },
            {
                keybind = "DIALOG_NEGATIVE",
                text = SI_DIALOG_CANCEL,
                callback = function(dialog)
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
    SCREEN_NARRATION_MANAGER:QueueFocus(self.outfitSelectorHeaderFocus)
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
    --If self.pendingUtilityWheelCollectibleData is set that means we are currently assigning to the utility wheel
    return self.currentList == self.collectionList and not self.pendingUtilityWheelCollectibleData 
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
