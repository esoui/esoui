ZO_GRID_SCROLL_LIST_OUTFIT_STYLE_TEMPLATE_DIMENSIONS_KEYBOARD = 67
ZO_GRID_SCROLL_LIST_OUTFIT_STYLE_TEMPLATE_ICON_DIMENSIONS_KEYBOARD = 52
ZO_GRID_SCROLL_LIST_OUTFIT_STYLE_SPACING_KEYBOARD = 5
local VISIBLE_ICON = "EsoUI/Art/Inventory/inventory_icon_visible.dds"

local RETAIN_SCROLL_POSITION = true

ZO_OutfitStylesPanel_Keyboard = ZO_CallbackObject:Subclass()

function ZO_OutfitStylesPanel_Keyboard:New(...)
    local object = ZO_CallbackObject.New(self)
    object:Initialize(...)
    return object
end

function ZO_OutfitStylesPanel_Keyboard:Initialize(control)
    self.control = control
    self.isDirty = true
    self.collectibleCategoryData = nil
    self.noStylesLabel = control:GetNamedChild("NoStylesLabel")
    self.currentSlotPreviews = {}
    
    self.entryDataObjectPool = ZO_EntryDataPool:New(ZO_GridSquareEntryData_Shared)

    self.pendingLoopAnimationPool = ZO_MetaPool:New(ZO_Pending_LoopAnimation_Pool)

    ZO_OUTFIT_MANAGER:RegisterCallback("OptionsInfoAvailable", function() ZO_CheckButton_SetCheckState(self.showLockedCheckBox, ZO_OUTFIT_MANAGER:GetShowLocked()) end)

    KEYBOARD_OUTFIT_STYLES_PANEL_FRAGMENT = ZO_FadeSceneFragment:New(control)
    KEYBOARD_OUTFIT_STYLES_PANEL_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
            self:OnShowing()
        elseif newState == SCENE_FRAGMENT_HIDING then
            self:OnHiding()
        end
    end)
    self.fragment = KEYBOARD_OUTFIT_STYLES_PANEL_FRAGMENT

    self:InitializeProgressBar()
    self:InitializeSortsAndFilters()
    self:InitializeGridListPanel()
    self:RegisterEvents()
end

function ZO_OutfitStylesPanel_Keyboard:InitializeProgressBar()
    self.progressBar = self.control:GetNamedChild("ProgressStatusBar")
    ZO_StatusBar_SetGradientColor(self.progressBar, ZO_XP_BAR_GRADIENT_COLORS)
    self.progressBarProgressLabel = self.progressBar:GetNamedChild("Progress")
end

function ZO_OutfitStylesPanel_Keyboard:InitializeSortsAndFilters()
    self.showLockedCheckBox = self.control:GetNamedChild("ShowLocked")
    self.typeFilterControl = self.control:GetNamedChild("TypeFilter")

    local function UpdateShowLockedAndRefresh(button, checked)
        ZO_OUTFIT_MANAGER:SetShowLocked(checked)
    end

    ZO_CheckButton_SetToggleFunction(self.showLockedCheckBox, UpdateShowLockedAndRefresh)
    ZO_CheckButton_SetLabelText(self.showLockedCheckBox, GetString(SI_RESTYLE_SHOW_LOCKED))
    ZO_CheckButton_SetLabelWrapMode(self.showLockedCheckBox, TEXT_WRAP_MODE_ELLIPSIS, self.typeFilterControl:GetLeft() - self.showLockedCheckBox:GetRight() - 10)

    self.typeFilterDropDown = ZO_ComboBox_ObjectFromContainer(self.typeFilterControl)
    self.typeFilterDropDown:SetSortsItems(false)
    
    local function RefreshVisible()
        self:RefreshVisible()
    end

    self.allTypesFilterEntry = self.typeFilterDropDown:CreateItemEntry(GetString(SI_OUTFIT_ALL_TYPES_FILTER), RefreshVisible)
    self.newFilterEntry = self.typeFilterDropDown:CreateItemEntry(GetString(SI_OUTFIT_NEW_FILTER), RefreshVisible)

    ZO_OUTFIT_MANAGER:RegisterCallback("ShowLockedChanged", function()
        ZO_CheckButton_SetCheckState(self.showLockedCheckBox, ZO_OUTFIT_MANAGER:GetShowLocked())
        RefreshVisible()
    end)
end

function ZO_OutfitStylesPanel_Keyboard:InitializeGridListPanel()
    local gridListPanel = self.control:GetNamedChild("Pane")
    self.gridListPanelControl = gridListPanel
    self.gridListPanelList = ZO_SingleTemplateGridScrollList_Keyboard:New(gridListPanel, ZO_GRID_SCROLL_LIST_AUTOFILL)

    local HEADER_HEIGHT = 30
    local HIDE_CALLBACK = nil
    local PENDING_ANIMATION_INSET = 0

    local function OutfitStyleGridEntrySetup(control, data, selected)
        ZO_DefaultGridEntrySetup(control, data, selected)

        self:RefreshGridEntryMultiIcon(control, data)

        if data.isEmptyCell then
            control:SetAlpha(0.4)
        else
            control:SetAlpha(1)
            ZO_SetDefaultIconSilhouette(control.icon, not data.clearAction and data:IsLocked())
            control.highlight:SetDesaturation(data.iconDesaturation)
            local actorCategory = self:GetActorCategory()
            if data.IsBlocked and data:IsBlocked(actorCategory) then
                if control.icon ~= nil then
                    control.icon:SetDesaturation(1)
                end
            end
            local isCurrent = false
            local isPending = false
            if self.restyleSlotData then
                local outfitSlotManipulator = ZO_OUTFIT_MANAGER:GetOutfitSlotManipulatorFromRestyleSlotData(self.restyleSlotData)
                if outfitSlotManipulator then
                    isCurrent, isPending = outfitSlotManipulator:GetCollectibleDataAssociations(data)
                end
            else
                if self.currentOutfitManipulator then
                    isCurrent, isPending = self.currentOutfitManipulator:GetCollectibleDataAssociations(data)
                end
            end

            local hideEquippedGlow = data.clearAction or not isCurrent or not ZO_RestyleCanApplyChanges()
            control.equippedGlow:SetHidden(hideEquippedGlow)
            if isPending then
                local isLocked = not data.clearAction and data:IsLocked()
                ZO_PendingLoop.ApplyToControl(control, self.pendingLoopAnimationPool, PENDING_ANIMATION_INSET, isLocked)
            end
        end
    end

    local function OutfitStyleGridEntryReset(control)
        ZO_ObjectPool_DefaultResetControl(control)
        control.equippedGlow:SetHidden(true)
        if control.pendingLoop then
            control.pendingLoop:ReleaseObject()
        end

        if control.highlightAnimation then
            control.highlightAnimation:PlayInstantlyToStart()
        end

        ZO_GridEntry_SetIconScaledUpInstantly(control, false)
    end

    self.gridListPanelList:SetGridEntryTemplate("ZO_OutfitStyle_GridEntry_Template_Keyboard", ZO_GRID_SCROLL_LIST_OUTFIT_STYLE_TEMPLATE_DIMENSIONS_KEYBOARD, ZO_GRID_SCROLL_LIST_OUTFIT_STYLE_TEMPLATE_DIMENSIONS_KEYBOARD, OutfitStyleGridEntrySetup, HIDE_CALLBACK, OutfitStyleGridEntryReset, ZO_GRID_SCROLL_LIST_OUTFIT_STYLE_SPACING_KEYBOARD, ZO_GRID_SCROLL_LIST_OUTFIT_STYLE_SPACING_KEYBOARD)
    self.gridListPanelList:SetHeaderTemplate(ZO_GRID_SCROLL_LIST_DEFAULT_HEADER_TEMPLATE_KEYBOARD, HEADER_HEIGHT, ZO_DefaultGridHeaderSetup)
    self.gridListPanelList:SetHeaderPrePadding(ZO_GRID_SCROLL_LIST_OUTFIT_STYLE_SPACING_KEYBOARD * 3)
end

function ZO_OutfitStylesPanel_Keyboard:RegisterEvents()
    local function RefreshVisible()
        if self.fragment:IsShowing() then
            self:RefreshVisible()
        end
    end

    local function RefreshMultiIcon(control, data, selected)
        self:RefreshGridEntryMultiIcon(control, data)
    end

    local function OnCollectibleNewStatusCleared(collectibleId)
        local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(collectibleId)
        local entry = self:GetEntryByCollectibleData(collectibleData)
        if entry then
            self.gridListPanelList:RefreshGridListEntryData(entry.dataEntry.data, RefreshMultiIcon)
        end
    end

    local function OnCollectibleCategoryNewStatusCleared(categoryId)
        if self.collectibleCategoryData and self.collectibleCategoryData:GetId() == categoryId then
            self:RefreshVisible()
        end
    end

    COLLECTIONS_BOOK_SINGLETON:RegisterCallback("UpdateSearchResults", RefreshVisible)
    ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("OnCollectionUpdated", RefreshVisible)
    ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("OnCollectibleNewStatusCleared", OnCollectibleNewStatusCleared)
    ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("OnCollectibleCategoryNewStatusCleared", OnCollectibleCategoryNewStatusCleared)

    local function OnOutfitPendingDataChanged(actorCategory, outfitIndex)
        if self.currentOutfitManipulator and self.currentOutfitManipulator:GetOutfitIndex() == outfitIndex then
            self.pendingLoopAnimationPool:ReleaseAllObjects()
            self.gridListPanelList:RefreshGridList()
        end
    end

    ZO_OUTFIT_MANAGER:RegisterCallback("PendingDataChanged", OnOutfitPendingDataChanged)
end

function ZO_OutfitStylesPanel_Keyboard:GetFragment()
    return self.fragment
end

function ZO_OutfitStylesPanel_Keyboard:OnShowing()
    if self.isDirty then
        self:RefreshVisible()
    end

    if ZO_RestyleCanApplyChanges() then
        TriggerTutorial(TUTORIAL_TRIGGER_OUTFIT_STYLES_SHOWN)
    end
end

function ZO_OutfitStylesPanel_Keyboard:OnHiding()

end

function ZO_OutfitStylesPanel_Keyboard:HasAnyCurrentSlotPreviews()
    return NonContiguousCount(self.currentSlotPreviews) > 0
end


function ZO_OutfitStylesPanel_Keyboard:ClearAllCurrentSlotPreviews()
    for outfitSlot, _ in pairs(self.currentSlotPreviews) do
        ClearOutfitSlotPreviewElementFromPreviewCollection(outfitSlot)
    end
    ApplyChangesToPreviewCollectionShown()
    ZO_ClearTable(self.currentSlotPreviews)
    self:FireCallbacks("PreviewSlotsChanged")
    self.gridListPanelList:RefreshGridList()
end

do
    local FOUND_VISUAL_ARMOR_TYPES = {}
    local FOUND_WEAPON_MODEL_TYPES = {}
    local IGNORE_CALLBACK = true

    function ZO_OutfitStylesPanel_Keyboard:SetCategoryReferenceData(referenceData)
        if referenceData.GetCollectibleCategoryData then
            self.restyleSlotData = ZO_RestyleSlotData:Copy(referenceData)
            self.collectibleCategoryData = referenceData:GetCollectibleCategoryData()
        else
            self.restyleSlotData = nil
            self.collectibleCategoryData = referenceData
        end

        ZO_ClearTable(FOUND_VISUAL_ARMOR_TYPES)
        ZO_ClearTable(FOUND_WEAPON_MODEL_TYPES)

        local typeFilterDropDown = self.typeFilterDropDown
        local previouslySelectedTypeFilterEntry = typeFilterDropDown:GetSelectedItemData()
        local autoSelectTypeFilterEntry = (previouslySelectedTypeFilterEntry == self.newFilterEntry) and self.newFilterEntry or self.allTypesFilterEntry

        typeFilterDropDown:ClearItems()
        typeFilterDropDown:AddItem(self.allTypesFilterEntry, ZO_COMBOBOX_SUPPRESS_UPDATE)
        typeFilterDropDown:AddItem(self.newFilterEntry, ZO_COMBOBOX_SUPPRESS_UPDATE)

        if self.collectibleCategoryData then
            local unlockedCount = 0
            local totalCount = 0
            for _, collectibleData in self.collectibleCategoryData:CollectibleIterator({ ZO_CollectibleData.IsShownInCollection }) do
                if collectibleData:IsArmorStyle() then
                    FOUND_VISUAL_ARMOR_TYPES[collectibleData:GetVisualArmorType()] = true
                elseif collectibleData:IsWeaponStyle() then
                    FOUND_WEAPON_MODEL_TYPES[collectibleData:GetWeaponModelType()] = true
                end
                totalCount = totalCount + 1
                if collectibleData:IsUnlocked() then
                    unlockedCount = unlockedCount + 1
                end
            end

            self.progressBar:SetMinMax(0, totalCount)
            self.progressBar:SetValue(unlockedCount)
            self.progressBarProgressLabel:SetText(zo_strformat(SI_OUTFIT_STYLE_PROGRESS_BAR_PROGRESS, unlockedCount, totalCount))

            local function RefreshVisible()
                self:RefreshVisible()
            end

            for visualArmorType = VISUAL_ARMORTYPE_ITERATION_BEGIN, VISUAL_ARMORTYPE_ITERATION_END do
                if FOUND_VISUAL_ARMOR_TYPES[visualArmorType] then
                    local entry = typeFilterDropDown:CreateItemEntry(GetString("SI_VISUALARMORTYPE", visualArmorType), RefreshVisible)
                    entry.visualArmorType = visualArmorType
                    typeFilterDropDown:AddItem(entry, ZO_COMBOBOX_SUPPRESS_UPDATE)

                    if previouslySelectedTypeFilterEntry and (visualArmorType == previouslySelectedTypeFilterEntry.visualArmorType) then
                        autoSelectTypeFilterEntry = entry
                    end
                end
            end

            for weaponModelType = WEAPON_MODEL_TYPE_ITERATION_BEGIN, WEAPON_MODEL_TYPE_ITERATION_END do
                if FOUND_WEAPON_MODEL_TYPES[weaponModelType] then
                    local entry = typeFilterDropDown:CreateItemEntry(GetString("SI_WEAPONMODELTYPE", weaponModelType), RefreshVisible)
                    entry.weaponModelType = weaponModelType
                    typeFilterDropDown:AddItem(entry, ZO_COMBOBOX_SUPPRESS_UPDATE)

                    if previouslySelectedTypeFilterEntry and (weaponModelType == previouslySelectedTypeFilterEntry.weaponModelType) then
                        autoSelectTypeFilterEntry = entry
                    end
                end
            end
        end

        typeFilterDropDown:UpdateItems()
        typeFilterDropDown:SelectItem(autoSelectTypeFilterEntry, IGNORE_CALLBACK)

        --NONE always shows, so if there's only 1 extra category, there's no point in allowing filtering cause it won't change anything
        self.typeFilterControl:SetHidden(typeFilterDropDown:GetNumItems() <= 2)

        self:RefreshVisible()
    end
end

function ZO_OutfitStylesPanel_Keyboard:RefreshGridEntryMultiIcon(control, data)
    local statusControl = control.statusMultiIcon
    if not statusControl then
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
    if not data.clearAction and data:IsNew() then
        statusControl:AddIcon(ZO_KEYBOARD_NEW_ICON)
        showMultiIcon = true
    end

    if showMultiIcon then
        statusControl:Show()
    end
end

function ZO_OutfitStylesPanel_Keyboard:RefreshVisible(retainScrollPosition)
    if not self.fragment:IsShowing() then
        self.isDirty = true
        return
    end

    local gridListPanelList = self.gridListPanelList
    gridListPanelList:ClearGridList(retainScrollPosition)
    self.entryDataObjectPool:ReleaseAllObjects()
    self.pendingLoopAnimationPool:ReleaseAllObjects()

    if self.collectibleCategoryData then
        if self.restyleSlotData then
            -- We can't rely on the restyle slot data passed in to have the correct set index before this point, so we check that here
            local currentSetIndex = ZO_RESTYLE_SHEET_WINDOW_KEYBOARD:GetCurrentSheet():GetRestyleSetIndex()
            self.restyleSlotData:SetRestyleSetIndex(currentSetIndex)
        end

        local showLocked = ZO_OUTFIT_MANAGER:GetShowLocked()
        local typeFilterEntry = self.typeFilterDropDown:GetSelectedItemData()
        local filterVisualArmorType = typeFilterEntry and typeFilterEntry.visualArmorType
        local filterWeaponModelType = typeFilterEntry and typeFilterEntry.weaponModelType
        local filterNew = typeFilterEntry == self.newFilterEntry

        local relevantSearchResults = nil
        local searchResults = COLLECTIONS_BOOK_SINGLETON:GetSearchResults()
        if searchResults then
            local categoryIndex, subcategoryIndex = self.collectibleCategoryData:GetCategoryIndicies()
            if searchResults[categoryIndex] and searchResults[categoryIndex][subcategoryIndex] then
                relevantSearchResults = searchResults[categoryIndex][subcategoryIndex]
            else
                relevantSearchResults = {}
            end
        end

        local hiddenStyleCollectibleId = self.restyleSlotData and GetOutfitSlotDataHiddenOutfitStyleCollectibleId(self.restyleSlotData:GetRestyleSlotType())

        local function FilterCollectible(collectibleData)
            if relevantSearchResults and not relevantSearchResults[collectibleData:GetIndex()] then
                -- When we know the slot this grid is associated with, don't filter out hidden style with a search
                if not hiddenStyleCollectibleId or collectibleData:GetId() ~= hiddenStyleCollectibleId then
                    return false
                end
            end

            if collectibleData:IsHiddenFromCollection() then
                return false
            end

            if not showLocked and collectibleData:IsLocked() then
                return false
            end

            if filterNew then
                return collectibleData:IsNew()
            end

            if filterVisualArmorType then
                local collectibleVisualArmorType = collectibleData:GetVisualArmorType()
                if collectibleVisualArmorType ~= filterVisualArmorType and collectibleVisualArmorType ~= VISUAL_ARMORTYPE_NONE then -- Always show none
                    return false
                end
            end

            if filterWeaponModelType then
                local collectibleWeaponModelType = collectibleData:GetWeaponModelType()
                if collectibleWeaponModelType ~= filterWeaponModelType and collectibleWeaponModelType ~= WEAPON_MODEL_TYPE_NONE then -- Always show none
                    return false
                end
            end

            return true
        end

        local dataByWeaponAndArmorType = self.collectibleCategoryData:GetCollectibleDataBySpecializedSort()

        if ZO_RestyleCanApplyChanges() and self.restyleSlotData then
            -- Clear
            local clearEntryData = ZO_GridSquareEntryData_Shared:New()
            clearEntryData.clearAction = true
            clearEntryData.preferredOutfitSlot = self.restyleSlotData:GetRestyleSlotType()
            clearEntryData.iconFile = self.restyleSlotData:GetClearIcon()
            clearEntryData.gridHeaderName = ""
            gridListPanelList:AddEntry(clearEntryData)
        end

        local function InsertEntryIntoTable(collectibleData)
            local entryData = self.entryDataObjectPool:AcquireObject()
            entryData:SetDataSource(collectibleData)
            if not collectibleData.clearAction then
                local actorCategory = self:GetActorCategory()
                ZO_UpdateCollectibleEntryDataIconVisuals(entryData, actorCategory)
            end
            gridListPanelList:AddEntry(entryData)
        end

        local NO_WEAPON_OR_ARMOR_TYPE = 0
        -- make sure to add the hide option first
        if dataByWeaponAndArmorType[NO_WEAPON_OR_ARMOR_TYPE] then
            local gearTypeNone = dataByWeaponAndArmorType[NO_WEAPON_OR_ARMOR_TYPE]:GetCollectibles()
            for _, collectibleData in ipairs(gearTypeNone) do
                InsertEntryIntoTable(collectibleData)
            end
        end

        for type, weaponOrArmorSortedCollectibles in pairs(dataByWeaponAndArmorType) do
            if type > NO_WEAPON_OR_ARMOR_TYPE then
                local weaponOrArmorData = weaponOrArmorSortedCollectibles:GetCollectibles()
                for _, collectibleData in ipairs(weaponOrArmorData) do
                    if FilterCollectible(collectibleData) then
                        InsertEntryIntoTable(collectibleData)
                    end
                end
            end
        end
    end


    gridListPanelList:CommitGridList()

    self.noStylesLabel:SetHidden(gridListPanelList:HasEntries())

    self.isDirty = false
end

function ZO_OutfitStylesPanel_Keyboard:SetCurrentOutfitManipulator(newManipulator)
    if self.currentOutfitManipulator ~= newManipulator then
        self.currentOutfitManipulator = newManipulator
        self:RefreshVisible()
    end
end

function ZO_OutfitStylesPanel_Keyboard:SetPendingOutfitStyleInCurrentOutfit(collectibleData, itemMaterialIndex, preferredOutfitSlot)
    if self.currentOutfitManipulator then
        preferredOutfitSlot = preferredOutfitSlot or ZO_OUTFIT_MANAGER:GetPreferredOutfitSlotForStyle(collectibleData)

        if preferredOutfitSlot then
            local slotManipulator = self.currentOutfitManipulator:GetSlotManipulator(preferredOutfitSlot)
            local collectibleId = collectibleData.clearAction and 0 or collectibleData:GetId()
            slotManipulator:SetPendingCollectibleIdAndItemMaterialIndex(collectibleId, itemMaterialIndex)
        end
    end
end

function ZO_OutfitStylesPanel_Keyboard:IsPreviewingOutfitStyle(collectibleData, itemMaterialIndex, preferredOutfitSlot)
    preferredOutfitSlot = preferredOutfitSlot or ZO_OUTFIT_MANAGER:GetPreferredOutfitSlotForStyle(collectibleData)

    if preferredOutfitSlot then
        local currentPreviewDataForSlot = self.currentSlotPreviews[preferredOutfitSlot]
        local collectibleId = collectibleData.clearAction and 0 or collectibleData:GetId()
        if currentPreviewDataForSlot and currentPreviewDataForSlot.collectibleId == collectibleId then
            if itemMaterialIndex == nil or currentPreviewDataForSlot.itemMaterialIndex == itemMaterialIndex then
                return true
            end
        end
    end
    return false
end

function ZO_OutfitStylesPanel_Keyboard:TogglePreviewOutfitStyle(collectibleData, itemMaterialIndex, preferredOutfitSlot)
    preferredOutfitSlot = preferredOutfitSlot or ZO_OUTFIT_MANAGER:GetPreferredOutfitSlotForStyle(collectibleData)

    if preferredOutfitSlot and IsCharacterPreviewingAvailable() then
        if self:IsPreviewingOutfitStyle(collectibleData, itemMaterialIndex, preferredOutfitSlot) then
            ClearOutfitSlotPreviewElementFromPreviewCollection(preferredOutfitSlot)
            ApplyChangesToPreviewCollectionShown()
            self.currentSlotPreviews[preferredOutfitSlot] = nil
            self:FireCallbacks("PreviewSlotsChanged")
            self.gridListPanelList:RefreshGridList()
            return
        end

        local primaryDyeId = 0
        local secondaryDyeId = 0
        local accentDyeId = 0
        if self.currentOutfitManipulator then
            local slotManipulator = self.currentOutfitManipulator:GetSlotManipulator(preferredOutfitSlot)
            primaryDyeId, secondaryDyeId, accentDyeId = slotManipulator:GetPendingDyeData()
        else
            local actorCategory = self:GetActorCategory()
            local equipSlot = GetEquipSlotForOutfitSlot(preferredOutfitSlot)
            if CanEquippedItemBeShownInOutfitSlot(actorCategory, equipSlot, preferredOutfitSlot) then
                primaryDyeId, secondaryDyeId, accentDyeId = GetPendingSlotDyes(RESTYLE_MODE_EQUIPMENT, ZO_RESTYLE_DEFAULT_SET_INDEX, equipSlot)
            end
        end
            
        itemMaterialIndex = itemMaterialIndex or ZO_OUTFIT_STYLE_DEFAULT_ITEM_MATERIAL_INDEX
        local collectibleId = collectibleData.clearAction and 0 or collectibleData:GetId()
        AddOutfitSlotPreviewElementToPreviewCollection(preferredOutfitSlot, collectibleId, itemMaterialIndex, primaryDyeId, secondaryDyeId, accentDyeId)
        ApplyChangesToPreviewCollectionShown()
        self.currentSlotPreviews[preferredOutfitSlot] = 
        {
            collectibleId = collectibleId,
            itemMaterialIndex = itemMaterialIndex,
        }
        self:FireCallbacks("PreviewSlotsChanged")
        self.gridListPanelList:RefreshGridList()
    end
end

function ZO_OutfitStylesPanel_Keyboard:OnRestyleOutfitStyleEntrySelected(entryData, initialContextMenuRefCount)
    local collectibleData = entryData.data
    if collectibleData then
        local actorCategory = self:GetActorCategory()
        if collectibleData.isEmptyCell or (collectibleData.IsBlocked and collectibleData:IsBlocked(actorCategory)) then
            return
        end

        local preferredOutfitSlot = entryData.preferredOutfitSlot
        if not preferredOutfitSlot then
            preferredOutfitSlot = self.restyleSlotData and self.restyleSlotData:GetRestyleSlotType()
        end

        if not collectibleData.clearAction then
            local outfitStyleId = collectibleData:GetReferenceId()
            local numMaterials = GetNumOutfitStyleItemMaterials(outfitStyleId)
            if numMaterials > 1 then
                ClearMenu()

                for materialIndex = 1, numMaterials do
                    local materialName = GetOutfitStyleItemMaterialName(outfitStyleId, materialIndex)
                    AddMenuItem(zo_strformat(SI_OUTFIT_STYLE_ITEM_MATERIAL_NAME_FORMATTER, materialName), function()
                        if ZO_RestyleCanApplyChanges() then
                            self:SetPendingOutfitStyleInCurrentOutfit(collectibleData, materialIndex, preferredOutfitSlot)
                        else
                            self:TogglePreviewOutfitStyle(collectibleData, materialIndex, preferredOutfitSlot)
                        end
                    end)
                end

                ShowMenu(entryData.control, initialContextMenuRefCount)
                return
            end
        end

        if ZO_RestyleCanApplyChanges() then
            self:SetPendingOutfitStyleInCurrentOutfit(collectibleData, ZO_OUTFIT_STYLE_DEFAULT_ITEM_MATERIAL_INDEX, preferredOutfitSlot)
        else
            self:TogglePreviewOutfitStyle(collectibleData, ZO_OUTFIT_STYLE_DEFAULT_ITEM_MATERIAL_INDEX, preferredOutfitSlot)
        end
    end
end

function ZO_OutfitStylesPanel_Keyboard:OnOutfitStyleEntryRightClick(entryData)
    local collectibleData = entryData.data
    if collectibleData and not collectibleData.isEmptyCell then
        ClearMenu()

        local actorCategory = self:GetActorCategory()
        if IsCharacterPreviewingAvailable() and not (collectibleData.IsBlocked and collectibleData:IsBlocked(actorCategory)) then
            AddMenuItem(GetString(SI_OUTFIT_STYLE_EQUIP_BIND), function() self:OnRestyleOutfitStyleEntrySelected(entryData) end)
        end

        if not collectibleData.clearAction then
            if IsChatSystemAvailableForCurrentPlatform() then
                --Link in chat
                AddMenuItem(GetString(SI_ITEM_ACTION_LINK_TO_CHAT), function() ZO_LinkHandler_InsertLink(GetCollectibleLink(collectibleData:GetId(), LINK_STYLE_BRACKETS)) end)
            end

            if collectibleData:IsLocked() and collectibleData:IsPurchasable() then
                AddMenuItem(GetString(SI_OUTFIT_COLLECTIBLE_SHOW_IN_MARKET), function()
                    local function GoToCrownStore()
                        local searchTerm = zo_strformat(SI_CROWN_STORE_SEARCH_FORMAT_STRING, collectibleData:GetName())
                        ShowMarketAndSearch(searchTerm, MARKET_OPEN_OPERATION_COLLECTIONS_OUTFITS)
                    end

                    if ZO_RESTYLE_SHEET_WINDOW_KEYBOARD:AreChangesPending() then
                        ZO_RESTYLE_SHEET_WINDOW_KEYBOARD:ShowRevertRestyleChangesDialog("CONFIRM_REVERT_CHANGES", GoToCrownStore)
                    else
                        GoToCrownStore()
                    end
                end)
            end
        end

        ShowMenu(self.control)
    end
end

do
    local SHOW_NICKNAME = true
    local SHOW_PURCHASABLE_HINT = true
    local SHOW_BLOCK_REASON = true

    function ZO_OutfitStylesPanel_Keyboard:OnOutfitStyleEntryMouseEnter(control)
        if not control.highlightAnimation then
            control.highlightAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_OutfitStyle_GridEntry_HighlightAnimation", control.highlight)
        end

        control.highlightAnimation:PlayForward()

        ZO_GridEntry_SetIconScaledUp(control, true)

        local collectibleData = control.dataEntry.data
        if not collectibleData.isEmptyCell then
            local offsetX = control:GetParent():GetLeft() - control:GetLeft() - 5
            InitializeTooltip(ItemTooltip, control, RIGHT, offsetX, 0, LEFT)

            local actorCategory = self:GetActorCategory()

            if collectibleData.clearAction then
                ItemTooltip:AddLine(GetString(SI_OUTFIT_CLEAR_OPTION_TITLE), "ZoFontWinH2", ZO_SELECTED_TEXT:UnpackRGB())
                ZO_Tooltip_AddDivider(ItemTooltip)
                ItemTooltip:AddLine(GetString(SI_OUTFIT_CLEAR_OPTION_DESCRIPTION), "ZoFontGameMedium", ZO_TOOLTIP_DEFAULT_COLOR:UnpackRGB())

                local preferredOutfitSlot = ZO_OUTFIT_MANAGER:GetPreferredOutfitSlotForStyle(collectibleData)
                local applyCost = GetOutfitSlotClearCost(preferredOutfitSlot)

                local formattedApplyCost = zo_strformat(SI_TOOLTIP_COLLECTIBLE_OUTFIT_STYLE_APPLICATION_COST_KEYBOARD_NO_FORMAT, ZO_Currency_FormatKeyboard(CURT_MONEY, applyCost, ZO_CURRENCY_FORMAT_AMOUNT_ICON))
                ItemTooltip:AddLine(formattedApplyCost, "ZoFontWinH4", ZO_TOOLTIP_DEFAULT_COLOR:UnpackRGB())
            else
                ItemTooltip:SetCollectible(collectibleData.collectibleId, SHOW_NICKNAME, SHOW_PURCHASABLE_HINT, SHOW_BLOCK_REASON, actorCategory)
            end

            if not ZO_RestyleCanApplyChanges() and not (collectibleData.IsBlocked and collectibleData:IsBlocked(actorCategory)) and IsCharacterPreviewingAvailable() then
                WINDOW_MANAGER:SetMouseCursor(MOUSE_CURSOR_PREVIEW)
            end

            self.mouseOverEntryData = control.dataEntry
        end

        self:FireCallbacks("MouseTargetChanged")
    end
end

function ZO_OutfitStylesPanel_Keyboard:OnOutfitStyleEntryMouseExit(control)
    control.highlightAnimation:PlayBackward()
    ZO_GridEntry_SetIconScaledUp(control, false)
    ClearTooltip(ItemTooltip)
    self.mouseOverEntryData = nil
    --The exit can fire after the control has already been cleaned out of the entry list, meaning it won't have data anymore
    local collectibleData = control.dataEntry and control.dataEntry.data
    if collectibleData and collectibleData.dataSource and not collectibleData.isEmptyCell and not collectibleData.clearAction then
        if collectibleData:GetNotificationId() then
            RemoveCollectibleNotification(collectibleData:GetNotificationId())
        end

        if collectibleData:IsNew() then
            ClearCollectibleNewStatus(collectibleData:GetId())
        end
    end

    WINDOW_MANAGER:SetMouseCursor(MOUSE_CURSOR_DO_NOT_CARE)

    self:FireCallbacks("MouseTargetChanged")
end

function ZO_OutfitStylesPanel_Keyboard:GetMouseOverEntryData()
    return self.mouseOverEntryData
end

function ZO_OutfitStylesPanel_Keyboard:ScrollToCollectibleData(scrollToCollectibleData)
    local entry = self:GetEntryByCollectibleData(scrollToCollectibleData)
    if entry then
        local NO_CALLBACK = nil
        local ANIMATE_INSTANTLY = true
        self.gridListPanelList:ScrollDataToCenter(entry, NO_CALLBACK, ANIMATE_INSTANTLY)
    end
end

function ZO_OutfitStylesPanel_Keyboard:GetEntryByCollectibleData(collectibleData)
    local entries = self.entryDataObjectPool:GetActiveObjects()
    for _, entry in pairs(entries) do
        if not entry.clearAction and entry:GetId() == collectibleData:GetId() then
            return entry
        end
    end
    return nil
end

function ZO_OutfitStylesPanel_Keyboard:OnProgressBarMouseEnter()
    InitializeTooltip(InformationTooltip, self.progressBarProgressLabel, RIGHT, -10, 0, LEFT)
    SetTooltipText(InformationTooltip, zo_strformat(SI_OUTFIT_STYLE_PROGRESS_BAR_TOOLTIP_TEXT, self.collectibleCategoryData:GetName()))
end

function ZO_OutfitStylesPanel_Keyboard:OnProgressBarMouseExit()
    ClearTooltip(InformationTooltip)
end


function ZO_OutfitStylesPanel_Keyboard:GetActorCategory()
    return self.restyleSlotData and ZO_OUTFIT_MANAGER.GetActorCategoryByRestyleMode(self.restyleSlotData.restyleMode) or GAMEPLAY_ACTOR_CATEGORY_PLAYER
end

------------------------------
-- Global Functions For XML --
------------------------------

function ZO_OutfitStyle_GridEntry_Template_Keyboard_OnMouseEnter(control)
    ZO_OUTFIT_STYLES_PANEL_KEYBOARD:OnOutfitStyleEntryMouseEnter(control)
end

function ZO_OutfitStyle_GridEntry_Template_Keyboard_OnMouseExit(control)
    ZO_OUTFIT_STYLES_PANEL_KEYBOARD:OnOutfitStyleEntryMouseExit(control)
end

function ZO_OutfitStyle_GridEntry_Template_Keyboard_OnMouseUp(control, button, upInside)
    if upInside then
        if button == MOUSE_BUTTON_INDEX_RIGHT then
            ZO_OUTFIT_STYLES_PANEL_KEYBOARD:OnOutfitStyleEntryRightClick(control.dataEntry)
        end
    end
end

do
    local INITIAL_CONTEXT_MENU_REF_COUNT = 1

    function ZO_OutfitStyle_GridEntry_Template_Keyboard_OnMouseDoubleClick(control, button)
        if button == MOUSE_BUTTON_INDEX_LEFT then
            ZO_OUTFIT_STYLES_PANEL_KEYBOARD:OnRestyleOutfitStyleEntrySelected(control.dataEntry, INITIAL_CONTEXT_MENU_REF_COUNT)
        end
    end
end

function ZO_OutfitStyle_GridEntry_Template_Keyboard_OnDragStart(control)
    if ZO_RestyleCanApplyChanges() then
        local collectibleData = control.dataEntry.data
        if collectibleData and not collectibleData.isEmptyCell and not collectibleData.clearAction and collectibleData:IsUnlocked() then
            PickupCollectible(collectibleData:GetId())
        end
    end
end

function ZO_OutfitStylesProgressBar_Keyboard_OnMouseEnter(control)
    ZO_OUTFIT_STYLES_PANEL_KEYBOARD:OnProgressBarMouseEnter()
end

function ZO_OutfitStylesProgressBar_Keyboard_OnMouseExit(control)
    ZO_OUTFIT_STYLES_PANEL_KEYBOARD:OnProgressBarMouseExit()
end

function ZO_OutfitStylesPanel_Keyboard_OnInitialized(control)
    ZO_OUTFIT_STYLES_PANEL_KEYBOARD = ZO_OutfitStylesPanel_Keyboard:New(control)
end