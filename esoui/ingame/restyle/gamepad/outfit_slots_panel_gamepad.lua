ZO_GAMEPAD_OUTFIT_GRID_ENTRY_DIMENSIONS = 87
ZO_GAMEPAD_OUTFIT_GRID_ENTRY_BORDER_EDGE_WIDTH = 128
ZO_GAMEPAD_OUTFIT_GRID_ENTRY_BORDER_EDGE_HEIGHT = 16

local REFRESH_PREVIEW_INSTANTLY = true

ZO_Outfit_Slots_Panel_Gamepad = ZO_Restyle_Station_Helper_Panel_Gamepad:Subclass()

function ZO_Outfit_Slots_Panel_Gamepad:New(...)
    local outfits = ZO_Restyle_Station_Helper_Panel_Gamepad.New(self, ...)
    return outfits
end

function ZO_Outfit_Slots_Panel_Gamepad:Initialize(control)
    self.control = control
    
    ZO_Restyle_Station_Helper_Panel_Gamepad.Initialize(self)

    self.pendingLoopAnimationPool = ZO_MetaPool:New(ZO_Pending_LoopAnimation_Pool)

    self.onUpdateCollectionsSearchResultsCallback = function()
        if self:HasActiveFocus() then
            self:UpdateGridList()
        end
    end

    GAMEPAD_OUTFITS_GRID_LIST_PANEL_FRAGMENT = ZO_FadeSceneFragment:New(control)

    self:InitializeKeybindDescriptors()

    self:InitializeGridListPanel()
    self:InitializeSearchBar()
    self:InitializeMultiFocusArea()
    self:InitializeItemMaterialDialog()

    control:SetHandler("OnUpdate", function(_, currentFrameTimeSeconds) self:OnUpdate(currentFrameTimeSeconds) end)

    ZO_OUTFIT_MANAGER:RegisterCallback("ShowLockedChanged", function() self:RebuildList() end)
end

function ZO_Outfit_Slots_Panel_Gamepad:Activate()
    ZO_Restyle_Station_Helper_Panel_Gamepad.Activate(self)
    self:ActivateCurrentFocus()
    DIRECTIONAL_INPUT:Activate(self, self.control)
    self:RefreshTooltip(self.gridListPanelList:GetSelectedData())
end

function ZO_Outfit_Slots_Panel_Gamepad:Deactivate()
    ZO_Restyle_Station_Helper_Panel_Gamepad.Deactivate(self)
    GAMEPAD_TOOLTIPS:ClearLines(GAMEPAD_QUAD1_TOOLTIP)
    -- make sure we leave the preview as it was no matter how we leave this panel
    if self.slotManipulator then
        self.slotManipulator:UpdatePreview(REFRESH_PREVIEW_INSTANTLY)
    end
    self:DeactivateCurrentFocus()
    DIRECTIONAL_INPUT:Deactivate(self)
end

function ZO_Outfit_Slots_Panel_Gamepad:OnShowing()
    COLLECTIONS_BOOK_SINGLETON:SetSearchString(self.searchEdit:GetText())
    COLLECTIONS_BOOK_SINGLETON:SetSearchCategorySpecializationFilters(COLLECTIBLE_CATEGORY_SPECIALIZATION_OUTFIT_STYLES)
    COLLECTIONS_BOOK_SINGLETON:SetSearchChecksHidden(true)
    COLLECTIONS_BOOK_SINGLETON:RegisterCallback("UpdateSearchResults", self.onUpdateCollectionsSearchResultsCallback)
    self:UpdateCurrentOutfitIndex()
end

function ZO_Outfit_Slots_Panel_Gamepad:OnHide()
    COLLECTIONS_BOOK_SINGLETON:UnregisterCallback("UpdateSearchResults", self.onUpdateCollectionsSearchResultsCallback)

    ZO_Restyle_Station_Helper_Panel_Gamepad.OnHide(self)

    self.searchEdit:SetText("")
    ZO_SavePlayerConsoleProfile()
end

function ZO_Outfit_Slots_Panel_Gamepad:OnUpdate(currentFrameTimeSeconds)
    if self.nextPreviewTimeS and self.nextPreviewTimeS <= currentFrameTimeSeconds then
        if self:HasActiveFocus() then
            local currentlySelectedOutfitData = self.gridListPanelList:GetSelectedData()
            if currentlySelectedOutfitData then
                local slotManipulator = self.slotManipulator
                local primaryDye, secondaryDye, accentDye = slotManipulator:GetPendingDyeData()

                if currentlySelectedOutfitData.isEmptyCell then
                    self.nextPreviewTimeS = nil
                    return
                elseif currentlySelectedOutfitData.clearAction then
                    local NO_OUTFIT_COLLECTIBLE = 0
                    local NO_ITEM_MATERIAL = nil
                    AddOutfitSlotPreviewElementToPreviewCollection(slotManipulator:GetOutfitSlotIndex(), NO_OUTFIT_COLLECTIBLE, NO_ITEM_MATERIAL, primaryDye, secondaryDye, accentDye)
                    ApplyChangesToPreviewCollectionShown()
                    self.nextPreviewTimeS = nil
                    return
                end

                local collectibleId = currentlySelectedOutfitData:GetId()
                local materialIndex = ZO_OUTFIT_STYLE_DEFAULT_ITEM_MATERIAL_INDEX
                
                if slotManipulator:GetPendingCollectibleId() == collectibleId then
                    materialIndex = slotManipulator:GetPendingItemMaterialIndex()
                elseif slotManipulator:GetCurrentCollectibleId() == collectibleId then
                    materialIndex = slotManipulator:GetCurrentItemMaterialIndex()
                end

                AddOutfitSlotPreviewElementToPreviewCollection(slotManipulator:GetOutfitSlotIndex(), collectibleId, materialIndex, primaryDye, secondaryDye, accentDye)
                ApplyChangesToPreviewCollectionShown()
            end
        end

        self.nextPreviewTimeS = nil
    end
end

function ZO_Outfit_Slots_Panel_Gamepad:InitializeKeybindDescriptors()
    -- Apply
    local apply = ZO_RESTYLE_STATION_GAMEPAD:CreateApplyKeybind(self)

    -- Options
    local options = ZO_RESTYLE_STATION_GAMEPAD:CreateOptionsKeybind()

    -- Undo All
    local undoAll = ZO_RESTYLE_STATION_GAMEPAD:CreateUndoKeybind(self)

    -- Randomize
    local randomize = ZO_RESTYLE_STATION_GAMEPAD:CreateRandomizeKeybind(self)

    local function HandleMultiFocusAreaBack()
        self.slotManipulator:UpdatePreview(REFRESH_PREVIEW_INSTANTLY)
        self:EndSelection()
        PlaySound(SOUNDS.OUTFIT_GAMEPAD_MENU_EXIT)
    end

    -- Grid List
    self.gridKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        -- Back
        KEYBIND_STRIP:GenerateGamepadBackButtonDescriptor(HandleMultiFocusAreaBack),

        -- Select
        {
            name = GetString(SI_GAMEPAD_SELECT_OPTION),
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                self:HandleGridSelectAction()
            end
        },

        apply,
        options,
        undoAll,
    }

    -- Search Bar
    self.searchKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        -- Back
        KEYBIND_STRIP:GenerateGamepadBackButtonDescriptor(HandleMultiFocusAreaBack),

        -- Select
        {
            name = GetString(SI_GAMEPAD_SELECT_OPTION),
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                self:HandleSearchSelectAction()
            end
        },

        apply,
        options,
        undoAll,
    }
end

function ZO_Outfit_Slots_Panel_Gamepad:InitializeGridListPanel()
    local gridListPanel = self.control:GetNamedChild("GridListPanel")
    GAMEPAD_OUTFITS_GRID_LIST_FRAGMENT = ZO_FadeSceneFragment:New(gridListPanel)

    self.gridListPanelControl = gridListPanel
    self.gridListPanelList = ZO_SingleTemplateGridScrollList_Gamepad:New(gridListPanel, ZO_GRID_SCROLL_LIST_AUTOFILL)

    local function OutfitStyleGridEntrySetup(control, data, list)
        if data.isEmptyCell then
            control:SetAlpha(0.4)
        else
            control:SetAlpha(1)
            if control.icon then
                ZO_SetDefaultIconSilhouette(control.icon, not data.clearAction and data:IsLocked())
            end
        end

        ZO_DefaultGridEntrySetup(control, data, list)
        ZO_RestyleStation_Gamepad_SetOutfitEntryBorder(control, data, self.slotManipulator, self.pendingLoopAnimationPool)
    end

    local function OutfitStyleGridEntryReset(control)
        ZO_ObjectPool_DefaultResetControl(control)
        ZO_RestyleStation_Gamepad_CleanupAnimationOnControl(control)
    end

    local HIDE_CALLBACK = nil
    local SPACING_X = 6
    self.gridListPanelList:SetGridEntryTemplate("ZO_OutfitStyle_GridEntry_Template_Gamepad", ZO_GAMEPAD_OUTFIT_GRID_ENTRY_DIMENSIONS, ZO_GAMEPAD_OUTFIT_GRID_ENTRY_DIMENSIONS, OutfitStyleGridEntrySetup, HIDE_CALLBACK, OutfitStyleGridEntryReset, SPACING_X, ZO_GRID_SCROLL_LIST_DEFAULT_SPACING_GAMEPAD)
    self.gridListPanelList:SetHeaderTemplate(ZO_GRID_SCROLL_LIST_DEFAULT_HEADER_TEMPLATE_GAMEPAD, ZO_GRID_SCROLL_LIST_DEFAULT_HEADER_TEMPLATE_HEIGHT, ZO_DefaultGridHeaderSetup)
    self.gridListPanelList:SetHeaderPrePadding(ZO_GRID_SCROLL_LIST_DEFAULT_SPACING_GAMEPAD)
    self.gridListPanelList:SetOnSelectedDataChangedCallback(function(previousData, newData) self:OnGridListSelectedDataChanged(previousData, newData) end)
end

function ZO_Outfit_Slots_Panel_Gamepad:InitializeSearchBar()
    self.contentHeader = self.control:GetNamedChild("ContentHeader")
    local searchControl = self.contentHeader:GetNamedChild("SearchFilter")
    local searchEdit = searchControl:GetNamedChild("SearchEdit")

    local function SearchEditFocusLost()
        ZO_GamepadEditBox_FocusLost(searchEdit)
        SCREEN_NARRATION_MANAGER:QueueFocus(self.filterSwitcher)
    end

    local function SearchEditTextChanged()
        COLLECTIONS_BOOK_SINGLETON:SetSearchString(searchEdit:GetText())
    end

    searchEdit:SetHandler("OnFocusLost", SearchEditFocusLost)
    searchEdit:SetHandler("OnTextChanged", SearchEditTextChanged)
    searchEdit:SetDefaultText(GetString(SI_GAMEPAD_OUTFITS_DEFAULT_SEARCH_TEXT))

    self.searchEdit = searchEdit

    self.filterSwitcher = ZO_GamepadFocus:New(self.searchEdit, ZO_MovementController:New(MOVEMENT_CONTROLLER_DIRECTION_HORIZONTAL))

    local searchData = 
    {
        highlight = searchControl:GetNamedChild("Highlight"),
        canFocus = function() return not searchControl:IsHidden() and not searchEdit:IsHidden() end,
        activate = function() SCREEN_NARRATION_MANAGER:QueueFocus(self.filterSwitcher) end,
        narrationText = function() return ZO_FormatEditBoxNarrationText(self.searchEdit, GetString(SI_SCREEN_NARRATION_EDIT_BOX_SEARCH_NAME)) end,
    }
    self.filterSwitcher:AddEntry(searchData)
end

function ZO_Outfit_Slots_Panel_Gamepad:InitializeMultiFocusArea()
    local function SearchActivateCallback()
        self.filterSwitcher:Activate()
    end

    local function SearchDeactivateCallback()
        self.filterSwitcher:Deactivate()
        self.searchEdit:LoseFocus()
    end
    self.searchArea = ZO_GamepadMultiFocusArea_Base:New(self, SearchActivateCallback, SearchDeactivateCallback)
    self.searchArea:SetKeybindDescriptor(self.searchKeybindStripDescriptor)

    local FOREGO_DIRECTIONAL_INPUT = true
    local function GridActivateCallback()
        self.gridListPanelList:Activate(FOREGO_DIRECTIONAL_INPUT)
    end

    local function GridDeactivateCallback()
        self.gridListPanelList:Deactivate(FOREGO_DIRECTIONAL_INPUT)
    end
    self.gridArea = ZO_GamepadInteractiveSortFilterFocusArea_Grid:New(self, GridActivateCallback, GridDeactivateCallback)
    self.gridArea:SetKeybindDescriptor(self.gridKeybindStripDescriptor)
    self.gridArea.gridList = self.gridListPanelList

    self:AddNextFocusArea(self.searchArea)
    self:AddNextFocusArea(self.gridArea)

    local DONT_ACTIVATE_FOCUS_AREA = false
    self:SelectFocusArea(self.gridArea, DONT_ACTIVATE_FOCUS_AREA)
end

function ZO_Outfit_Slots_Panel_Gamepad:InitializeItemMaterialDialog()
    ZO_Dialogs_RegisterCustomDialog("GAMEPAD_OUTFIT_ITEM_MATERIAL_OPTIONS",
    {
        canQueue= true,
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
        },
        title =
        {
            text = GetString(SI_GAMEPAD_OUTFITS_SELECT_MATERIAL_DIALOG_TITLE)
        },
        setup = function(dialog)
            local parametricList = dialog.info.parametricList
            ZO_ClearNumericallyIndexedTable(parametricList)

            local data = dialog.data
            local targetOutfitData = data.selectedData
            local outfitStyleId = targetOutfitData:GetReferenceId()
            local numMaterials = GetNumOutfitStyleItemMaterials(outfitStyleId)

            for materialIndex = 1, numMaterials do
                local materialName = GetOutfitStyleItemMaterialName(outfitStyleId, materialIndex)
                local entryData = ZO_GamepadEntryData:New(materialName)
                entryData.materialIndex = materialIndex
                entryData.setup = ZO_SharedGamepadEntry_OnSetup

                local listItem =
                {
                    template = "ZO_GamepadItemEntryTemplate",
                    entryData = entryData,
                }

                table.insert(parametricList, listItem)
            end

            dialog:setupFunc()
        end,
        parametricList = {}, -- Generated Dynamically
        parametricListOnSelectionChangedCallback = function(dialog, list, newSelectedData, oldSelectedData)
            local data = dialog.data
            local slotManipulator = data.slotManipulator
            local primaryDye, secondaryDye, accentDye = slotManipulator:GetPendingDyeData()
            AddOutfitSlotPreviewElementToPreviewCollection(slotManipulator:GetOutfitSlotIndex(), data.selectedData:GetId(), newSelectedData.materialIndex, primaryDye, secondaryDye, accentDye)
            ApplyChangesToPreviewCollectionShown()
        end,
        blockDialogReleaseOnPress = true,
        buttons = 
        {
            {
                keybind = "DIALOG_PRIMARY",
                text = SI_GAMEPAD_SELECT_OPTION,
                callback = function(dialog)
                    local targetData = dialog.entryList:GetTargetData()
                    if targetData then
                        local slotManipulator = dialog.data.slotManipulator
                        slotManipulator:SetPendingCollectibleIdAndItemMaterialIndex(dialog.data.selectedData:GetId(), targetData.materialIndex)
                        self.gridListPanelList:RefreshGridList()
                        self:EndSelection()
                        slotManipulator:UpdatePreview(REFRESH_PREVIEW_INSTANTLY)
                        ZO_Dialogs_ReleaseDialogOnButtonPress("GAMEPAD_OUTFIT_ITEM_MATERIAL_OPTIONS")
                    end
                end,
            },
            {
                keybind = "DIALOG_NEGATIVE",
                text = SI_GAMEPAD_BACK_OPTION,
                callback =  function(dialog)
                    dialog.data.slotManipulator:UpdatePreview(REFRESH_PREVIEW_INSTANTLY)
                    ZO_Dialogs_ReleaseDialogOnButtonPress("GAMEPAD_OUTFIT_ITEM_MATERIAL_OPTIONS")
                end,
            },
        }
    })
end

function ZO_Outfit_Slots_Panel_Gamepad:UpdateGridList()
    local gridListPanelList = self.gridListPanelList
    gridListPanelList:ClearGridList()
    
    if not self.slotManipulator then
        gridListPanelList:CommitGridList()
        return
    end

    local slotManipulator = self.slotManipulator
    local outfitSlot = slotManipulator:GetOutfitSlotIndex()
    local categoryId = GetOutfitSlotDataCollectibleCategoryId(outfitSlot)
    local searchResults = COLLECTIONS_BOOK_SINGLETON:GetSearchResults()
    local tempTable = {}

    local relevantSearchResults = nil
    local hiddenStyleCollectibleId = GetOutfitSlotDataHiddenOutfitStyleCollectibleId(self.slotManipulator:GetOutfitSlotIndex())
    local function FilterCollectible(collectibleData)
        if relevantSearchResults and not relevantSearchResults[collectibleData:GetIndex()] then
            if not hiddenStyleCollectibleId or collectibleData:GetId() ~= hiddenStyleCollectibleId then
                return false
            end
        end

        if collectibleData:IsHiddenFromCollection() then
            return false
        end

        if not ZO_OUTFIT_MANAGER:GetShowLocked() and collectibleData:IsLocked() then
            return false
        end

        return true
    end


    local selectedData = nil
    local function FindSelectedData(collectibleData)
        local isCurrent, isPending = slotManipulator:GetCollectibleDataAssociations(collectibleData)
        if isPending then
            selectedData = collectibleData
        elseif isCurrent then
            if not selectedData then -- show Pending over Current
                selectedData = collectibleData
            end
        end

        return true
    end

    local function InsertEntryIntoTable(tempTable, data)
        local collectibleEntryData = ZO_GridSquareEntryData_Shared:New(data)
        local actorCategory = self.currentOutfitManipulator and self.currentOutfitManipulator:GetActorCategory() or GAMEPLAY_ACTOR_CATEGORY_PLAYER
        ZO_UpdateCollectibleEntryDataIconVisuals(collectibleEntryData, actorCategory)
        FindSelectedData(collectibleEntryData)
        table.insert(tempTable, collectibleEntryData)
    end

    -- Clear
    local entryData = ZO_GridSquareEntryData_Shared:New()
    entryData.clearAction = true
    entryData.iconFile = ZO_Restyle_GetOutfitSlotClearTexture(outfitSlot)
    entryData.gridHeaderName = ""
    table.insert(tempTable, entryData)

    local categoryData = ZO_COLLECTIBLE_DATA_MANAGER:GetCategoryDataById(categoryId)

    if searchResults then
        local categoryIndex, subcategoryIndex = categoryData:GetCategoryIndicies()
        if searchResults[categoryIndex] and searchResults[categoryIndex][subcategoryIndex] then
            relevantSearchResults = searchResults[categoryIndex][subcategoryIndex]
        else
            relevantSearchResults = {}
        end
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

    for i, entry in ipairs(tempTable) do
        gridListPanelList:AddEntry(entry)
    end

    gridListPanelList:CommitGridList()

    if selectedData then
        local NO_CALLBACK = nil
        local ANIMATE_INSTANTLY = true
        gridListPanelList:ScrollDataToCenter(selectedData, NO_CALLBACK, ANIMATE_INSTANTLY)
    end
end

function ZO_Outfit_Slots_Panel_Gamepad:RebuildList()
    self:UpdateGridList()
    self:UpdateActiveFocusKeybinds()
end

function ZO_Outfit_Slots_Panel_Gamepad:RefreshList()
    self.gridListPanelList:RefreshGridList()
    self:UpdateActiveFocusKeybinds()
end

function ZO_Outfit_Slots_Panel_Gamepad:UpdateCurrentOutfitIndex()
    local currentActorCategory, currentEditingIndex = ZO_OUTFITS_SELECTOR_GAMEPAD:GetCurrentActorCategoryAndIndex()
    if not currentEditingIndex then
         self:SetOutfitManipulator(nil)
    else
        self:SetOutfitManipulator(ZO_OUTFIT_MANAGER:GetOutfitManipulator(currentActorCategory, currentEditingIndex))
    end
end

function ZO_Outfit_Slots_Panel_Gamepad:SetOutfitManipulator(newManipulator)
    if self.currentOutfitManipulator ~= newManipulator then
        self.currentOutfitManipulator = newManipulator
    end
end

function ZO_Outfit_Slots_Panel_Gamepad:HandleGridSelectAction()
    local currentlySelectedOutfitData = self.gridListPanelList:GetSelectedData()
    if not currentlySelectedOutfitData or currentlySelectedOutfitData.isEmptyCell then
        return
    end

    local slotManipulator = self.slotManipulator

    if currentlySelectedOutfitData.clearAction then
        slotManipulator:Clear()
    else
        local collectibleId = currentlySelectedOutfitData:GetId()
        local selectedCollectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(collectibleId)

        if selectedCollectibleData:IsLocked() then
            ZO_Alert(ALERT, NO_SOUND, GetString(SI_GAMEPAD_OUTFITS_CANT_ADD_LOCKED_STYLE))
            return
        else
            if slotManipulator:GetPendingCollectibleId() == collectibleId then
                slotManipulator:ClearPendingChanges()
            else
                local outfitStyleId = currentlySelectedOutfitData:GetReferenceId()
                local numMaterials = GetNumOutfitStyleItemMaterials(outfitStyleId)
                local eligibleSlots = { GetEligibleOutfitSlotsForCollectible(collectibleId) }
                for i, eligibleSlot in ipairs(eligibleSlots) do
                    if slotManipulator:GetOutfitSlotIndex() == eligibleSlot then
                        if numMaterials <= 1 then
                            slotManipulator:SetPendingCollectibleIdAndItemMaterialIndex(collectibleId, ZO_OUTFIT_STYLE_DEFAULT_ITEM_MATERIAL_INDEX)
                            break
                        else
                            ZO_Dialogs_ShowGamepadDialog("GAMEPAD_OUTFIT_ITEM_MATERIAL_OPTIONS", { slotManipulator = slotManipulator, selectedData = currentlySelectedOutfitData })
                            return
                        end
                    end
                end
            end
        end
    end

    self:UpdateActiveFocusKeybinds()
    self.gridListPanelList:RefreshGridList()
    self:EndSelection()
end

function ZO_Outfit_Slots_Panel_Gamepad:HandleSearchSelectAction()
    self.searchEdit:TakeFocus()
end

function ZO_Outfit_Slots_Panel_Gamepad:RefreshTooltip(selectedData)
    GAMEPAD_TOOLTIPS:ClearLines(GAMEPAD_QUAD1_TOOLTIP)
    if selectedData then
        if selectedData.clearAction then
            local preferredOutfitSlot = ZO_OUTFIT_MANAGER:GetPreferredOutfitSlotForStyle(selectedData)
            GAMEPAD_TOOLTIPS:LayoutClearOutfitSlot(GAMEPAD_QUAD1_TOOLTIP, preferredOutfitSlot)
        elseif not selectedData.isEmptyCell then
            local SHOW_VISUAL_LAYER_INFO = true
            local SHOW_BLOCK_REASON = true
            local TIME_REMAINING_S = nil
            local actorCategory = self.currentOutfitManipulator and self.currentOutfitManipulator:GetActorCategory() or GAMEPLAY_ACTOR_CATEGORY_PLAYER
            GAMEPAD_TOOLTIPS:LayoutCollectibleFromData(GAMEPAD_QUAD1_TOOLTIP, selectedData, SHOW_VISUAL_LAYER_INFO, TIME_REMAINING_S, SHOW_BLOCK_REASON, actorCategory)
        end
    end
end

do
    local NEXT_OUTFIT_PREVIEW_TIME_S = .25

    function ZO_Outfit_Slots_Panel_Gamepad:OnGridListSelectedDataChanged(previousData, newData)
        if self:IsActive() then
            self:RefreshTooltip(newData)
            if newData then
                self.nextPreviewTimeS = GetFrameTimeSeconds() + NEXT_OUTFIT_PREVIEW_TIME_S
            end
        end
    end
end

function ZO_Outfit_Slots_Panel_Gamepad:SetSlotManipulator(slotManipulator)
    if self.slotManipulator ~= slotManipulator then
        self.slotManipulator = slotManipulator
    end
    self:UpdateGridList()
end

function ZO_Outfit_Slots_Panel_Gamepad:UndoPendingChanges()
    self.currentOutfitManipulator:ClearPendingChanges()
    self:RefreshList()
end

-- Shared Functions --

do
    local PENDING_ANIMATION_INSET = -1
    function ZO_RestyleStation_Gamepad_SetOutfitEntryBorder(control, data, slotManipulator, pendingPool)
        local edgeTexture
        local isCurrent
        local isPending
        if data.isEmptyCell or data.clearAction then
            edgeTexture = "EsoUI/Art/Tooltips/Gamepad/gp_toolTip_edge_16.dds"
        else
            isCurrent, isPending = slotManipulator:GetCollectibleDataAssociations(data)
            if isPending then
                if not control.icon.pendingLoop then
                    ZO_PendingLoop.ApplyToControl(control.icon, pendingPool, PENDING_ANIMATION_INSET, data:IsLocked())
                end
                edgeTexture = "EsoUI/Art/Restyle/Gamepad/gp_outfits_edge_bluePending_16.dds"
            elseif isCurrent then
                edgeTexture = "EsoUI/Art/Restyle/Gamepad/gp_outfits_edge_blueSaved_16.dds"
            else
                edgeTexture = "EsoUI/Art/Tooltips/Gamepad/gp_toolTip_edge_16.dds"
            end
        end

        if not isPending then
            ZO_RestyleStation_Gamepad_CleanupAnimationOnControl(control)
        end

        control.borderBackground:SetEdgeTexture(edgeTexture, ZO_GAMEPAD_OUTFIT_GRID_ENTRY_BORDER_EDGE_WIDTH, ZO_GAMEPAD_OUTFIT_GRID_ENTRY_BORDER_EDGE_HEIGHT)
    end
end

function ZO_RestyleStation_Gamepad_CleanupAnimationOnControl(control)
    if control.icon.pendingLoop then
        control.icon.pendingLoop:ReleaseObject()
    end
end

-- XML Functions --

function ZO_Outfit_Slots_Panel_Gamepad_OnInitialize(control)
    ZO_OUTFITS_PANEL_GAMEPAD = ZO_Outfit_Slots_Panel_Gamepad:New(control)
end
