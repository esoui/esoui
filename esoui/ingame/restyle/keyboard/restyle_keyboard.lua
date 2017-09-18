ZO_RESTYLE_MODE_CATEGORY_DATA =
{
    [RESTYLE_MODE_EQUIPMENT] =
    {
        specializedCollectibleCategory = nil,
        allowsDyeing = true,
    },
    [RESTYLE_MODE_COLLECTIBLE] =
    {
        specializedCollectibleCategory = nil,
        allowsDyeing = true,
    },
}

ZO_Restyle_Keyboard = ZO_Object:Subclass()

function ZO_Restyle_Keyboard:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_Restyle_Keyboard:Initialize(control)
    self.control = control
    self.rightPanel = control:GetNamedChild("RightPanel")
    self.sheetsContainer = control:GetNamedChild("Sheets")
    self.contentSearchEditBox = self.rightPanel:GetNamedChild("SearchBox")

    self.mode = RESTYLE_MODE_EQUIPMENT

    self.sheetsByMode = {}

    self:InitializeTabs()
    self:InitializeCategories()
    self:InitializeEquipmentSheet()
    self:InitializeCollectibleSheet()
    self:InitializeKeybindStripDescriptors()

    local function OnBlockingSceneActivated()
        self:AttemptExit()
    end

    RESTYLE_SCENE = ZO_InteractScene:New("restyle_keyboard", SCENE_MANAGER, ZO_DYEING_STATION_INTERACTION)
    SYSTEMS:RegisterKeyboardRootScene("restyle", RESTYLE_SCENE)
    RESTYLE_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            MAIN_MENU_MANAGER:SetBlockingScene("restyle_keyboard", OnBlockingSceneActivated)

            SetRestylePreviewMode(self.mode)

            KEYBIND_STRIP:RemoveDefaultExit()
            KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
            
            local currentSheet = self.sheetsByMode[self.mode]
            SCENE_MANAGER:AddFragment(currentSheet:GetFragment())

            local IS_ENABLED = true
            if CanUseCollectibleDyeing() then
                ZO_MenuBar_SetDescriptorEnabled(self.tabs, RESTYLE_MODE_COLLECTIBLE, IS_ENABLED)
            else
                -- if we have the collectible tab selected, switch tabs it before disabling it
                -- so the highlights setup correctly
                local selectedTabType = ZO_MenuBar_GetSelectedDescriptor(self.tabs)
                if selectedTabType == RESTYLE_MODE_COLLECTIBLE then
                    ZO_MenuBar_SelectDescriptor(self.tabs, RESTYLE_MODE_EQUIPMENT)
                end
                ZO_MenuBar_SetDescriptorEnabled(self.tabs, RESTYLE_MODE_COLLECTIBLE, not IS_ENABLED)
            end
            self:RefreshCategoryContent()
            self:InitializeSearch()
        elseif newState == SCENE_HIDDEN then
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
            KEYBIND_STRIP:RestoreDefaultExit()
            MAIN_MENU_MANAGER:ClearBlockingScene(OnBlockingSceneActivated)
        end
    end)

    self.onUpdateCollectionsSearchResultsCallback = function()
        if RESTYLE_SCENE:IsShowing() then
            self:BuildCategories()
        end
    end
end

function ZO_Restyle_Keyboard:OnTabFilterChanged(tabData)
    self.activeTab:SetText(GetString(tabData.activeTabText))
end

function ZO_Restyle_Keyboard:SetMode(mode)
    if self.mode ~= mode then
        self.mode = mode

        for sheetRestyleMode, sheet in pairs(self.sheetsByMode) do
            if mode == sheetRestyleMode then
                SCENE_MANAGER:AddFragment(sheet:GetFragment())
            else
                SCENE_MANAGER:RemoveFragment(sheet:GetFragment())
            end
        end

        -- make sure the current sheet has the latest dye data for its slots
        SetRestylePreviewMode(mode)

        self:InitializeSearch()
        self:BuildCategories()
    end
end

function ZO_Restyle_Keyboard:HandleTabChange(tabData, nextMode)
    if ZO_Dyeing_AreTherePendingDyes(self.mode) then
        self.pendingTabData = tabData
        self.pendingMode = nextMode
        if ZO_Dyeing_AreAllItemsBound(self.mode) then
            ZO_Dialogs_ShowDialog("SWTICH_DYE_MODE")
        else
            ZO_Dialogs_ShowDialog("SWTICH_DYE_MODE_BIND")
        end
    else
        self:OnTabFilterChanged(tabData)
        self:SetMode(nextMode)
    end
end

function ZO_Restyle_Keyboard:InitializeTabs()
    local function GenerateTab(name, mode, normal, pressed, highlight, disabled, customTooltip)
        return {
            activeTabText = name,
            categoryName = name,

            descriptor = mode,
            normal = normal,
            pressed = pressed,
            highlight = highlight,
            disabled = disabled,
            CustomTooltipFunction = customTooltip,
            alwaysShowTooltip = true,
            callback = function(tabData, playerDriven) 
                            if playerDriven then 
                                self:HandleTabChange(tabData, mode) 
                            end 
                       end,
        }
    end

    self.tabs = self.rightPanel:GetNamedChild("Tabs")
    self.activeTab = self.rightPanel:GetNamedChild("TabsLabel")

    ZO_MenuBar_AddButton(self.tabs, GenerateTab(SI_DYEING_DYE_EQUIPMENT_TAB, RESTYLE_MODE_EQUIPMENT, "EsoUI/Art/Dye/dyes_tabIcon_dye_up.dds", "EsoUI/Art/Dye/dyes_tabIcon_dye_down.dds", "EsoUI/Art/Dye/dyes_tabIcon_dye_over.dds", "EsoUI/Art/Dye/dyes_tabIcon_dye_disabled.dds"))
    ZO_MenuBar_AddButton(self.tabs, GenerateTab(SI_DYEING_DYE_COLLECTIBLE_TAB, RESTYLE_MODE_COLLECTIBLE, "EsoUI/Art/Dye/dyes_tabIcon_costumeDye_up.dds", "EsoUI/Art/Dye/dyes_tabIcon_costumeDye_down.dds", "EsoUI/Art/Dye/dyes_tabIcon_costumeDye_over.dds", "EsoUI/Art/Dye/dyes_tabIcon_costumeDye_disabled.dds", function(...) self:LayoutCollectionAppearanceTooltip(...) end))

    ZO_MenuBar_SelectDescriptor(self.tabs, RESTYLE_MODE_EQUIPMENT)
    self.activeTab:SetText(GetString(SI_DYEING_DYE_EQUIPMENT_TAB))
end

function ZO_Restyle_Keyboard:LayoutCollectionAppearanceTooltip(tooltip)
    local description
    local title
    if CanUseCollectibleDyeing() then
        title = zo_strformat(SI_DYEING_COLLECTIBLE_STATUS, ZO_DEFAULT_ENABLED_COLOR:Colorize(GetString(SI_ESO_PLUS_STATUS_UNLOCKED)))
        description = GetString(SI_DYEING_COLLECTIBLE_TAB_DESCRIPTION_UNLOCKED)
    else
        title = zo_strformat(SI_DYEING_COLLECTIBLE_STATUS, ZO_DEFAULT_ENABLED_COLOR:Colorize(GetString(SI_ESO_PLUS_STATUS_LOCKED)))
        description = GetString(SI_DYEING_COLLECTIBLE_TAB_DESCRIPTION_LOCKED)
    end

    SetTooltipText(tooltip, title)
    local r, g, b = ZO_TOOLTIP_DEFAULT_COLOR:UnpackRGB()
    tooltip:AddLine(description, "", r, g, b)
end

function ZO_Restyle_Keyboard:InitializeCategories()
    self.categories = self.rightPanel:GetNamedChild("Categories")
    self.categoryTree = ZO_Tree:New(self.categories:GetNamedChild("ScrollChild"), 60, -10, 300)

    local function BaseTreeHeaderIconSetup(control, data, open)
        local iconTexture = (open and data.pressedIcon or data.normalIcon) or ZO_NO_TEXTURE_FILE
        local mouseoverTexture = data.mouseoverIcon or ZO_NO_TEXTURE_FILE
        
        control.icon:SetTexture(iconTexture)
        control.iconHighlight:SetTexture(mouseoverTexture)

        ZO_IconHeader_Setup(control, open)
    end

    local function BaseTreeHeaderSetup(node, control, data, open)
        control.text:SetModifyTextType(MODIFY_TEXT_TYPE_UPPERCASE)
        control.text:SetText(data.name)
        BaseTreeHeaderIconSetup(control, data, open)
    end

    local function TreeHeaderSetup_Child(node, control, data, open, userRequested)
        BaseTreeHeaderSetup(node, control, data, open)

        if open and userRequested then
            self.categoryTree:SelectFirstChild(node)
        end
    end

    local function TreeHeaderSetup_Childless(node, control, data, open)
        BaseTreeHeaderSetup(node, control, data, open)
    end

    local function TreeEntryOnSelected(control, data, selected, reselectingDuringRebuild)
        control:SetSelected(selected)

        if selected and not reselectingDuringRebuild then
            self:RefreshCategoryContent()
        end
    end

    local function TreeEntryOnSelected_Childless(control, data, selected, reselectingDuringRebuild)
        TreeEntryOnSelected(control, data, selected, reselectingDuringRebuild)
        BaseTreeHeaderIconSetup(control, data, selected)
    end

    local function TreeEntrySetup(node, control, data, open)
        control:SetSelected(false)
        control:SetText(data.name)
    end

    local function EqualityFunction(leftData, rightData)
        local leftReferenceData = leftData.referenceData
        local rightReferenceData = rightData.referenceData
        if leftReferenceData and rightReferenceData then
            if leftReferenceData.isDyesCategory == rightReferenceData.isDyesCategory and
               leftReferenceData.collectibleCategoryIndex == rightReferenceData.collectibleCategoryIndex and
               leftReferenceData.collectibleSubcategoryIndex == rightReferenceData.collectibleSubcategoryIndex then
                return true
            end
        end
        return false
    end

    local CHILD_INDENT = 76
    local CHILD_SPACING = 0
    local NO_SELECTED_CALLBACK = nil
    self.categoryTree:AddTemplate("ZO_IconHeader", TreeHeaderSetup_Child, NO_SELECTED_CALLBACK, EqualityFunction, CHILD_INDENT, CHILD_SPACING)
    self.categoryTree:AddTemplate("ZO_IconChildlessHeader", TreeHeaderSetup_Childless, TreeEntryOnSelected_Childless, EqualityFunction)
    self.categoryTree:AddTemplate("ZO_TreeLabelSubCategory", TreeEntrySetup, TreeEntryOnSelected, EqualityFunction)

    self.categoryTree:SetExclusive(true)
    self.categoryTree:SetOpenAnimation("ZO_TreeOpenAnimation")
    self:BuildCategories()
end

function ZO_Restyle_Keyboard:BuildCategories()
    self.categoryTree:Reset()

    local restyleModeCategoryData = ZO_RESTYLE_MODE_CATEGORY_DATA[self.mode]

    if restyleModeCategoryData.specializedCollectibleCategory then
        self:AddCollectibleCategories(restyleModeCategoryData.specializedCollectibleCategory)
    end

    if restyleModeCategoryData.allowsDyeing then
        self:AddDyeCategory()
    end
    
    self.categoryTree:Commit()
end

function ZO_Restyle_Keyboard:InitializeSearch()
    local restyleModeCategoryData = ZO_RESTYLE_MODE_CATEGORY_DATA[self.mode]
    if restyleModeCategoryData then
        if restyleModeCategoryData.specializedCollectibleCategory then
            COLLECTIONS_BOOK_SINGLETON:SetSearchString(self.contentSearchEditBox:GetText())
            COLLECTIONS_BOOK_SINGLETON:SetSearchCategorySpecializationFilters(restyleModeCategoryData.specializedCollectibleCategory)
            COLLECTIONS_BOOK_SINGLETON:RegisterCallback("UpdateSearchResults", self.onUpdateCollectionsSearchResultsCallback)
        else
            COLLECTIONS_BOOK_SINGLETON:UnregisterCallback("UpdateSearchResults", self.onUpdateCollectionsSearchResultsCallback)
        end

        if restyleModeCategoryData.allowsDyeing then
            ZO_DYEING_MANAGER:SetSearchString(self.contentSearchEditBox:GetText())
        end
    end
end

do
    local NO_PARENT = nil

    function ZO_Restyle_Keyboard:AddCollectibleCategories(specializedCollectibleCategory)
        local function AddCategory(categoryIndex)
            local categoryName = GetCollectibleCategoryInfo(categoryIndex)
            local normalIcon, pressedIcon, mouseoverIcon = GetCollectibleCategoryKeyboardIcons(categoryIndex)
            local categoryData = { collectibleCategoryIndex = categoryIndex }
            return self:AddCategory("ZO_IconHeader", NO_PARENT, categoryName, categoryData, normalIcon, pressedIcon, mouseoverIcon)
        end

        local function AddSubcategory(categoryIndex, subcategoryIndex, parentNode)
            local subcategoryName, numCollectibles = GetCollectibleSubCategoryInfo(categoryIndex, subcategoryIndex)
            local subcategoryData = 
            {
                collectibleCategoryIndex = categoryIndex,
                collectibleSubcategoryIndex = subcategoryIndex,
                numCollectibles = numCollectibles,
            }
            self:AddCategory("ZO_TreeLabelSubCategory", parentNode, subcategoryName, subcategoryData)
        end

        local searchResults = COLLECTIONS_BOOK_SINGLETON:GetSearchResults()
        if searchResults then
            for categoryIndex, categorySearchResults in pairs(searchResults) do
                local numValidSubCategories = NonContiguousCount(categorySearchResults)
                if categorySearchResults[ZO_COLLECTIONS_SEARCH_ROOT] then
                    numValidSubCategories = numValidSubCategories - 1
                end

                if numValidSubCategories > 0 then
                    local categoryNode = AddCategory(categoryIndex)

                    for subcategoryIndex, subcategorySearchResults in pairs(categorySearchResults) do
                        if subcategoryIndex ~= ZO_COLLECTIONS_SEARCH_ROOT then
                            AddSubcategory(categoryIndex, subcategoryIndex, categoryNode)
                        end
                    end
                end
            end
        else
            for categoryIndex = 1, GetNumCollectibleCategories() do
                if GetCollectibleCategorySpecialization(categoryIndex) == specializedCollectibleCategory then
                    local categoryName, numSubcategories = GetCollectibleCategoryInfo(categoryIndex)
                    if numSubcategories > 0 then --No support for non-subcategorized collectibles in restyle
                        local categoryNode = AddCategory(categoryIndex)

                        for subcategoryIndex = 1, numSubcategories do
                            AddSubcategory(categoryIndex, subcategoryIndex, categoryNode)
                        end
                    end
                end
            end
        end
    end

    local DYE_REFERENCE_DATA = { isDyesCategory = true }

    function ZO_Restyle_Keyboard:AddDyeCategory(attemptReselectReferenceData)
        self.dyeCategoryNode = self:AddCategory("ZO_IconChildlessHeader", NO_PARENT, GetString(SI_RESTYLE_DYES_CATEGORY_NAME), DYE_REFERENCE_DATA, "EsoUI/Art/Dye/dyes_categoryIcon_up.dds", "EsoUI/Art/Dye/dyes_categoryIcon_down.dds", "EsoUI/Art/Dye/dyes_categoryIcon_over.dds")
    end
end

function ZO_Restyle_Keyboard:AddCategory(nodeTemplate, parent, name, referenceData, normalIcon, pressedIcon, mouseoverIcon)
    local entryData = 
    {
        referenceData = referenceData, 
        name = name,
        parentData = parent and parent.data or nil,
        normalIcon = normalIcon, 
        pressedIcon = pressedIcon, 
        mouseoverIcon = mouseoverIcon,
    }

    local soundId = parent and SOUNDS.JOURNAL_PROGRESS_SUB_CATEGORY_SELECTED or SOUNDS.JOURNAL_PROGRESS_CATEGORY_SELECTED
    local node = self.categoryTree:AddNode(nodeTemplate, entryData, parent, soundId)
    entryData.node = node
    return node
end

function ZO_Restyle_Keyboard:RefreshCategoryContent()
    if SCENE_MANAGER:IsShowing("restyle_keyboard") then
        local categoryData = self.categoryTree:GetSelectedData()
        local referenceData = categoryData.referenceData
        if referenceData.isDyesCategory then
            SCENE_MANAGER:AddFragment(KEYBOARD_DYEING_FRAGMENT)
            --TODO: Remove the collectible grid fragment
        elseif referenceData.collectibleCategoryIndex then
            SCENE_MANAGER:RemoveFragment(KEYBOARD_DYEING_FRAGMENT)
            --TODO: Add the collectible grid fragment
        end
    end
end

function ZO_Restyle_Keyboard:InitializeSheet(sheetClassTemplate, slotGridData)
    local function OnDyeSlotClicked(...)
        self:OnDyeSlotClicked(...)
    end

    local function OnDyeSlotEnter(...)
        self:OnDyeSlotEnter(...)
    end

    local function OnDyeSlotExit(...)
        self:OnDyeSlotExit(...)
    end

    local sheet = sheetClassTemplate:New(self.sheetsContainer, slotGridData)
    sheet:InitializeOnDyeSlotCallbacks(OnDyeSlotClicked, OnDyeSlotEnter, OnDyeSlotExit)
    self.sheetsByMode[sheet:GetRestyleMode()] = sheet
end

function ZO_Restyle_Keyboard:InitializeEquipmentSheet()
    local slotGridData =
    {
        [ZO_RESTYLE_SHEET_CONTAINER.PRIMARY] = 
        {
            [EQUIP_SLOT_HEAD] = { row = 1, column = 1, controlName = "Head" }, [EQUIP_SLOT_OFF_HAND] = { row = 1, column = 2, controlName = "Shield" }, [EQUIP_SLOT_BACKUP_OFF] = { row = 1, column = 2, controlName = "BackupShield" }, -- Switches with Shield on show based on ActiveWeaponPair
            [EQUIP_SLOT_SHOULDERS] = { row = 2, column = 1, controlName = "Shoulders" }, [EQUIP_SLOT_CHEST] = { row = 2, column = 2, controlName = "Chest" },
            [EQUIP_SLOT_HAND] = { row = 3, column = 1, controlName = "Hand" }, [EQUIP_SLOT_WAIST] = { row = 3, column = 2, controlName = "Waist" },
            [EQUIP_SLOT_LEGS] = { row = 4, column = 1, controlName = "Legs" }, [EQUIP_SLOT_FEET] = { row = 4, column = 2, controlName = "Feet" },
        },
    }
    self:InitializeSheet(ZO_RestyleEquipmentSlotsSheet, slotGridData)
end

function ZO_Restyle_Keyboard:InitializeCollectibleSheet()
    local slotGridData =
    {
        [ZO_RESTYLE_SHEET_CONTAINER.PRIMARY] = 
        {
            [COLLECTIBLE_CATEGORY_TYPE_HAT] = { row = 1, column = 1, controlName = "Hat" }, [COLLECTIBLE_CATEGORY_TYPE_COSTUME] = { row = 1, column = 2, controlName = "Costume" },
        },
    }
    self:InitializeSheet(ZO_RestyleCollectibleSlotsSheet, slotGridData)
end

function ZO_Restyle_Keyboard:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,

        -- Apply dye
        {
            name = GetString(SI_DYEING_COMMIT),
            keybind = "UI_SHORTCUT_SECONDARY",

            visible = function() return ZO_Dyeing_AreTherePendingDyes(self.mode) end,
            callback = function() self:CommitSelection() end,
        },

        -- Uniform Randomize
        {
            name = GetString(SI_DYEING_RANDOMIZE),
            keybind = "UI_SHORTCUT_TERTIARY",

            callback = function() self:UniformRandomize() end,
        },

        -- Undo
        {
            name = GetString(SI_DYEING_UNDO),
            keybind = "UI_SHORTCUT_NEGATIVE",
            visible = function() return ZO_Dyeing_AreTherePendingDyes(self.mode) end,
            callback = function() self:UndoPendingChanges() end,
        },

        -- Special exit button
        {
            alignment = KEYBIND_STRIP_ALIGN_RIGHT,
            name = GetString(SI_EXIT_BUTTON),
            keybind = "UI_SHORTCUT_EXIT",
            callback = function() self:AttemptExit() end,
        },
    }
end

function ZO_Restyle_Keyboard:OnDyeSlotClicked(restyleSlotData, dyeChannel, button)
    ZO_DYEING_KEYBOARD:OnDyeSlotClicked(restyleSlotData, dyeChannel, button)
end

do
    local UNKNOWN_DYE = false
    local IS_NON_PLAYER_DYE = true
    local IS_LEFT_ANCHORED = false

    function ZO_Restyle_Keyboard:OnDyeSlotEnter(restyleSlotData, dyeChannel, dyeControl)
        local activeTool = ZO_DYEING_KEYBOARD:GetActiveTool()
        if activeTool then
            local highlightSlot, highlightDyeChannel = activeTool:GetHighlightRules(restyleSlotData:GetRestyleSlotType(), dyeChannel)
            self:GetCurrentSheet():ToggleDyeableSlotHightlight(highlightSlot, true, highlightDyeChannel)
            WINDOW_MANAGER:SetMouseCursor(activeTool:GetCursorType())
        end
        local dyeId = select(dyeChannel, restyleSlotData:GetPendingDyes())
        local swatch = ZO_DYEING_KEYBOARD:GetSwatchControlFromDyeId(dyeId)
        if swatch then
            if KEYBOARD_DYEING_FRAGMENT:IsShowing() then
                ZO_Dyeing_CreateTooltipOnMouseEnter(swatch, swatch.dyeName, swatch.known, swatch.achievementId)
            else
                ZO_Dyeing_CreateTooltipOnMouseEnter(dyeControl, swatch.dyeName, swatch.known, swatch.achievementId, not IS_NON_PLAYER_DYE, IS_LEFT_ANCHORED)
            end
        else
            local dyeName, _, _, _, achievementId = GetDyeInfoById(dyeId)
            if dyeName ~= "" then
                ZO_Dyeing_CreateTooltipOnMouseEnter(dyeControl, dyeName, UNKNOWN_DYE, achievementId, IS_NON_PLAYER_DYE, IS_LEFT_ANCHORED)
            end
        end
    end
end

do
    local NO_SLOT = nil
    local NO_CHANNEL = nil

    function ZO_Restyle_Keyboard:OnDyeSlotExit(restyleSlotData, dyeChannel)
        self:GetCurrentSheet():ToggleDyeableSlotHightlight(NO_SLOT, false, NO_CHANNEL)
        WINDOW_MANAGER:SetMouseCursor(MOUSE_CURSOR_DO_NOT_CARE)
        ZO_Dyeing_ClearTooltipOnMouseExit()
    end
end

function ZO_Restyle_Keyboard:OnPendingDyesChanged(restyleSlotData)
    local currentSheet = self:GetCurrentSheet()

    if restyleSlotData then
        currentSheet:RefreshDyeableSlotDyes(restyleSlotData)
    else
        currentSheet:MarkViewDirty()
    end

    if SCENE_MANAGER:IsShowing("restyle_keyboard") then
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    end
end

function ZO_Restyle_Keyboard:AttemptExit(exitingToAchievementId)
    self.exitingToAchievementId = exitingToAchievementId

    if ZO_Dyeing_AreTherePendingDyes(self.mode) then
        if ZO_Dyeing_AreAllItemsBound(self.mode) then
            if self.exitingToAchievementId then
                ZO_Dialogs_ShowDialog("EXIT_DYE_UI_TO_ACHIEVEMENT")
            else
                ZO_Dialogs_ShowDialog("EXIT_DYE_UI")
            end
        else
            if self.exitingToAchievementId then
                ZO_Dialogs_ShowDialog("EXIT_DYE_UI_TO_ACHIEVEMENT_BIND")
            else
                ZO_Dialogs_ShowDialog("EXIT_DYE_UI_BIND")
            end
        end
    else
        self:ConfirmExit()
    end
end

function ZO_Restyle_Keyboard:ConfirmExit(applyChanges)
    if applyChanges then
        self:ConfirmCommitSelection()
        PlaySound(SOUNDS.DYEING_APPLY_CHANGES_FROM_DIALOGUE)
    end
    if self.exitingToAchievementId then
        SYSTEMS:GetObject("achievements"):ShowAchievement(self.exitingToAchievementId)
        self.exitingToAchievementId = nil
    else
        SCENE_MANAGER:ShowBaseScene()
    end
end

function ZO_Restyle_Keyboard:ConfirmSwitchMode(applyChanges)
    if applyChanges then
        self:ConfirmCommitSelection()
        PlaySound(SOUNDS.DYEING_APPLY_CHANGES_FROM_DIALOGUE)
    else
        self:UndoPendingChanges()
    end

    self:OnTabFilterChanged(self.pendingTabData)
    self:SetMode(self.pendingMode)

    self.pendingTabData = nil
    self.pendingMode = nil
end

function ZO_Restyle_Keyboard:CommitSelection()
    if ZO_Dyeing_AreAllItemsBound(self.mode) then
        self:ConfirmCommitSelection()
        PlaySound(SOUNDS.DYEING_APPLY_CHANGES)
    else
        ZO_Dialogs_ShowDialog("CONFIRM_APPLY_DYE")
    end
end

function ZO_Restyle_Keyboard:ConfirmCommitSelection()
    ApplyPendingDyes()
    InitializePendingDyes()
    self:OnPendingDyesChanged()
end

function ZO_Restyle_Keyboard:CancelExitToAchievements()
    self.exitingToAchievementId = nil
end

function ZO_Restyle_Keyboard:CancelExit()
    MAIN_MENU_MANAGER:CancelBlockingSceneNextScene()
end

function ZO_Restyle_Keyboard:UniformRandomize()
    ZO_Dyeing_UniformRandomize(self.mode, function() return ZO_DYEING_KEYBOARD:GetRandomUnlockedDyeId() end)
    self:OnPendingDyesChanged()
end

function ZO_Restyle_Keyboard:UndoPendingChanges()
    InitializePendingDyes()
    self:OnPendingDyesChanged()
    PlaySound(SOUNDS.DYEING_UNDO_CHANGES)
end

function ZO_Restyle_Keyboard:GetCurrentSheet()
    return self.sheetsByMode[self.mode]
end

function ZO_Restyle_Keyboard:GetMode()
    return self.mode
end

function ZO_Restyle_Keyboard:OnSearchTextChanged()
    local restyleModeCategoryData = ZO_RESTYLE_MODE_CATEGORY_DATA[self.mode]
    local editText = self.contentSearchEditBox:GetText()
    if restyleModeCategoryData.specializedCollectibleCategory then
        COLLECTIONS_BOOK_SINGLETON:SetSearchString(editText)
    end

    if restyleModeCategoryData.allowsDyeing then
        ZO_DYEING_MANAGER:SetSearchString(editText)
    end
end

function ZO_Restyle_Keyboard_OnSearchTextChanged(editBox)
    ZO_EditDefaultText_OnTextChanged(editBox)
    ZO_RESTYLE_KEYBOARD:OnSearchTextChanged()
end

function ZO_Restyle_Keyboard_OnInitialized(control)
    ZO_RESTYLE_KEYBOARD = ZO_Restyle_Keyboard:New(control)
    SYSTEMS:RegisterKeyboardObject("restyle", ZO_RESTYLE_KEYBOARD)
end