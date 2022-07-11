------------------------------
-- Shared Right Panel Logic --
------------------------------

--Category data --

ZO_RestyleCategoryData = ZO_InitializingObject:Subclass()

function ZO_RestyleCategoryData:Initialize(restyleMode, allowsDyeing, specializedCollectibleCategory, specializedCollectibleCategoryEnabled, derivesCollectibleCategoriesFromSlots, omittedRestyleSlotTypes)
    self.restyleMode = restyleMode
    self.allowsDyeing = allowsDyeing
    self.specializedCollectibleCategory = specializedCollectibleCategory
    self.specializedCollectibleCategoryEnabled = specializedCollectibleCategoryEnabled
    self.derivesCollectibleCategoriesFromSlots = derivesCollectibleCategoriesFromSlots
    self.omittedRestyleSlotTypes = omittedRestyleSlotTypes
end

function ZO_RestyleCategoryData:GetRestyleMode()
    return self.restyleMode
end

function ZO_RestyleCategoryData:SetAllowsDyeing(allowsDyeing)
    self.allowsDyeing = allowsDyeing
end

function ZO_RestyleCategoryData:AllowsDyeing()
    return self.allowsDyeing
end

function ZO_RestyleCategoryData:SetSpecializedCollectibleCategory(specializedCollectibleCategory)
    self.specializedCollectibleCategory = specializedCollectibleCategory
end

function ZO_RestyleCategoryData:GetSpecializedCollectibleCategory()
    return self.specializedCollectibleCategory
end

function ZO_RestyleCategoryData:SetSpecializedCollectibleCategoryEnabled(enabled)
    self.specializedCollectibleCategoryEnabled = enabled
end

function ZO_RestyleCategoryData:IsSpecializedCollectibleCategoryEnabled()
    return self.specializedCollectibleCategory and self.specializedCollectibleCategoryEnabled
end

function ZO_RestyleCategoryData:SetDerivesCollectibleCategoriesFromSlots(derivesCollectibleCategoriesFromSlots)
    self.derivesCollectibleCategoriesFromSlots = derivesCollectibleCategoriesFromSlots
end

function ZO_RestyleCategoryData:DerivesCollectibleCategoriesFromSlots()
    return self.derivesCollectibleCategoriesFromSlots
end

function ZO_RestyleCategoryData:IsOmittedRestyleSlotType(restyleSlotType)
    if self.omittedRestyleSlotTypes then
        return ZO_IsElementInNumericallyIndexedTable(self.omittedRestyleSlotTypes, restyleSlotType)
    end
    return false
end

-- Panel --

ZO_RestyleCommon_Keyboard = ZO_InitializingObject:Subclass()

function ZO_RestyleCommon_Keyboard:Initialize(control)
    self.control = control

    self.fragment = ZO_FadeSceneFragment:New(control)
    self.fragment:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
            self:OnShowing()
        elseif newState == SCENE_FRAGMENT_SHOWN then
            self:OnShown()
        elseif newState == SCENE_FRAGMENT_HIDDEN then
            self:OnHidden()
        end
    end)

    self.contentSearchEditBox = control:GetNamedChild("SearchBox")

    self.collectibleCategoryNodeLookup = {}
    self.restyleSlotTypeNodeLookup = {}
    self.collectibleCategoryNodes = {}
    self.restyleSlotDataMetaPool = ZO_RESTYLE_MANAGER:GetRestyleSlotDataMetaPool()

    self:InitializeCategories()
    self:InitializeCurrency()
    self:InitializeKeybindStripDescriptors()

    self.onUpdateSearchResultsCallback = function()
        if self.fragment:IsShowing() then
            self:BuildCategories()
        end
    end

    self.updateKeybindCallback = function()
        self:UpdateKeybind()
    end

    self.navigateToCollectibleCategoryCallback = function(...)
        if self.fragment:IsShowing() then
            self:NavigateToCollectibleCategoryFromRestyleSlotData(...)
        end
    end

    ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("OnCollectionUpdated", function() self:OnCollectionUpdated() end)
    ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("OnCollectibleNewStatusCleared", function(...) self:OnCollectibleNewStatusCleared(...) end)
    ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("OnCollectibleCategoryNewStatusCleared", function(...) self:OnCollectibleCategoryNewStatusCleared(...) end)
end

function ZO_RestyleCommon_Keyboard:InitializeCategories()
    self.categories = self.control:GetNamedChild("Categories")
    self.categoryTree = ZO_Tree:New(self.categories:GetNamedChild("ScrollChild"), 60, -10, 300)

    local function BaseTreeHeaderIconSetup(control, data, open)
        local enabled = data.enabled ~= false
        open = open and enabled

        local iconTexture
        if enabled then
            iconTexture = open and data.pressedIcon or data.normalIcon
        else
            iconTexture = data.disabledIcon
        end

        if not iconTexture then
            iconTexture = ZO_NO_TEXTURE_FILE
        end

        local mouseoverTexture = data.mouseoverIcon or ZO_NO_TEXTURE_FILE
        
        control.icon:SetTexture(iconTexture)
        control.iconHighlight:SetTexture(mouseoverTexture)

        ZO_IconHeader_Setup(control, open, enabled)
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
        node:SetEnabled(data.enabled ~= false)
        BaseTreeHeaderSetup(node, control, data, open)
    end

    local function TreeEntryOnSelected(control, data, selected, reselectingDuringRebuild)
        control:SetSelected(selected)

        if selected and not reselectingDuringRebuild then
            self:RefreshCategoryContent()
        elseif not (selected or data.referenceData.isDyesCategory) then
            if control.statusIcon and control.statusIcon:HasIcon(ZO_KEYBOARD_NEW_ICON) then
                self:ClearNewStatusFromPreviousCategory(data.referenceData)
            end
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
        local rightReferenceData = rightData.referenceData
        -- This functions goal is to find the previously selected node, but the reference datas get recycled, so we have to compare the values of the new nodes to the restyleSlotData we copied off before the clean
        -- We don't want to compare set index though, because we don't want switching between outfits to reset your category
        if rightReferenceData.GetRestyleSlotType and self.reselectTreeNodeRestyleSlotData then
            return rightReferenceData:GetRestyleMode() == self.reselectTreeNodeRestyleSlotData:GetRestyleMode() and rightReferenceData:GetRestyleSlotType() == self.reselectTreeNodeRestyleSlotData:GetRestyleSlotType()
        else
            return leftData.referenceData == rightData.referenceData
        end
    end

    local CHILD_INDENT = 76
    local CHILD_SPACING = 0
    local NO_SELECTED_CALLBACK = nil
    self.categoryTree:AddTemplate("ZO_StatusIconHeader", TreeHeaderSetup_Child, NO_SELECTED_CALLBACK, EqualityFunction, CHILD_INDENT, CHILD_SPACING)
    self.categoryTree:AddTemplate("ZO_StatusIconChildlessHeader", TreeHeaderSetup_Childless, TreeEntryOnSelected_Childless, EqualityFunction)
    self.categoryTree:AddTemplate("ZO_TreeStatusLabelSubCategory", TreeEntrySetup, TreeEntryOnSelected, EqualityFunction)

    self.categoryTree:SetExclusive(true)
    self.categoryTree:SetOpenAnimation("ZO_TreeOpenAnimation")
    self:BuildCategories()
end

function ZO_RestyleCommon_Keyboard:InitializeCurrency()
    ZO_SharedInventory_ConnectPlayerCurrencyLabel(self.control:GetNamedChild("InfoBarMoney"), CURT_MONEY, CURRENCY_LOCATION_CHARACTER, ZO_KEYBOARD_CURRENCY_OPTIONS)
    ZO_SharedInventory_ConnectPlayerCurrencyLabel(self.control:GetNamedChild("InfoBarAltMoney"), CURT_STYLE_STONES, CURRENCY_LOCATION_ACCOUNT, ZO_KEYBOARD_CURRENCY_OPTIONS)
end

function ZO_RestyleCommon_Keyboard:InitializeKeybindStripDescriptors()
    -- Can be overriden
end

function ZO_RestyleCommon_Keyboard:UpdateKeybind()
    if self.keybindStripDescriptor and self.fragment:IsShowing() then
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    end
end

function ZO_RestyleCommon_Keyboard:BuildCategories()
    local categoryData = self.categoryTree:GetSelectedData()
     if categoryData then
        local referenceData = categoryData.referenceData
        -- Because we're using a pool, we need to store off a copy of the restyle slot data for the equality function, in case the previous memory gets reused for a different node
        if referenceData.GetRestyleSetIndex then
            self.reselectTreeNodeRestyleSlotData = ZO_RestyleSlotData:Copy(referenceData)
        end
    end

    self.categoryTree:Reset()
    ZO_ClearTable(self.collectibleCategoryNodeLookup)
    ZO_ClearTable(self.restyleSlotTypeNodeLookup)
    ZO_ClearTable(self.collectibleCategoryNodes)
    self.restyleSlotDataMetaPool:ReleaseAllObjects()

    local restyleCategoryData = self:GetRestyleCategoryData()

    if restyleCategoryData:AllowsDyeing() then
        self:AddDyeCategory()
    elseif restyleCategoryData:GetRestyleMode() == RESTYLE_MODE_COMPANION_EQUIPMENT then
        local DISABLE_DYES = true
        self:AddDyeCategory(DISABLE_DYES)
        SCENE_MANAGER:RemoveFragment(KEYBOARD_OUTFIT_STYLES_PANEL_FRAGMENT)
        SCENE_MANAGER:RemoveFragment(KEYBOARD_DYEING_FRAGMENT)
    end

    if restyleCategoryData:GetSpecializedCollectibleCategory() then
        if restyleCategoryData:DerivesCollectibleCategoriesFromSlots() then
            self:AddSlotCollectibleCategories()
        else
            self:AddAllSpecializedCollectibleCategories()
        end
    end

    local autoSelectNode = nil
    if restyleCategoryData:AllowsDyeing() and restyleCategoryData:GetSpecializedCollectibleCategory() and not restyleCategoryData:IsSpecializedCollectibleCategoryEnabled() then
        autoSelectNode = self.dyeCategoryNode
    end

    self.categoryTree:Commit(autoSelectNode)
    self:UpdateAllCategoryStatusIcons()
    self.reselectTreeNodeRestyleSlotData = nil
end

function ZO_RestyleCommon_Keyboard:InitializeSearch()
    local restyleCategoryData = self:GetRestyleCategoryData()
    if restyleCategoryData then
        if restyleCategoryData:IsSpecializedCollectibleCategoryEnabled() then
            COLLECTIONS_BOOK_SINGLETON:SetSearchString(self.contentSearchEditBox:GetText())
            COLLECTIONS_BOOK_SINGLETON:SetSearchCategorySpecializationFilters(restyleCategoryData:GetSpecializedCollectibleCategory())
            COLLECTIONS_BOOK_SINGLETON:SetSearchChecksHidden(true)
            COLLECTIONS_BOOK_SINGLETON:RegisterCallback("UpdateSearchResults", self.onUpdateSearchResultsCallback)
        else
            COLLECTIONS_BOOK_SINGLETON:UnregisterCallback("UpdateSearchResults", self.onUpdateSearchResultsCallback)
        end

        if restyleCategoryData:AllowsDyeing() then
            ZO_DYEING_MANAGER:SetSearchString(self.contentSearchEditBox:GetText())
            ZO_DYEING_MANAGER:RegisterCallback("UpdateSearchResults", self.onUpdateSearchResultsCallback)
        else
            ZO_DYEING_MANAGER:UnregisterCallback("UpdateSearchResults", self.onUpdateSearchResultsCallback)
        end
    else
        COLLECTIONS_BOOK_SINGLETON:UnregisterCallback("UpdateSearchResults", self.onUpdateSearchResultsCallback)
        ZO_DYEING_MANAGER:UnregisterCallback("UpdateSearchResults", self.onUpdateSearchResultsCallback)
    end
end

function ZO_RestyleCommon_Keyboard.UpdateAnchors(control, hasSubTabs)
    control:ClearAnchors()
    if hasSubTabs then
        control:SetHeight(620)
        control:SetAnchor(RIGHT, nil, nil, -10, 55)
    else
        control:SetHeight(670)
        control:SetAnchor(RIGHT, nil, nil, -10, 30)
    end
end

function ZO_RestyleCommon_Keyboard:RefreshCategoryContent()
    if self.fragment:IsShowing() then
        local categoryData = self.categoryTree:GetSelectedData()
        if categoryData then
            local referenceData = categoryData.referenceData
            if referenceData.isDyesCategory then
                if KEYBOARD_OUTFIT_STYLES_PANEL_FRAGMENT:IsShowing() then
                    ZO_OUTFIT_STYLES_PANEL_KEYBOARD:UnregisterCallback("MouseTargetChanged", self.updateKeybindCallback)
                    SCENE_MANAGER:RemoveFragment(KEYBOARD_OUTFIT_STYLES_PANEL_FRAGMENT)
                end
                self.UpdateAnchors(ZO_DYEING_KEYBOARD.control, self.currentSubTabDescriptor)
                SCENE_MANAGER:AddFragment(KEYBOARD_DYEING_FRAGMENT)
            else
                ZO_OUTFIT_STYLES_PANEL_KEYBOARD:SetCategoryReferenceData(referenceData)
                SCENE_MANAGER:RemoveFragment(KEYBOARD_DYEING_FRAGMENT)
                if not KEYBOARD_OUTFIT_STYLES_PANEL_FRAGMENT:IsShowing() then
                    self.UpdateAnchors(ZO_OUTFIT_STYLES_PANEL_KEYBOARD.control, self.currentSubTabDescriptor)
                    SCENE_MANAGER:AddFragment(KEYBOARD_OUTFIT_STYLES_PANEL_FRAGMENT)
                    ZO_OUTFIT_STYLES_PANEL_KEYBOARD:RegisterCallback("MouseTargetChanged", self.updateKeybindCallback)
                end
            end
        else
            SCENE_MANAGER:RemoveFragment(KEYBOARD_OUTFIT_STYLES_PANEL_FRAGMENT)
            SCENE_MANAGER:RemoveFragment(KEYBOARD_DYEING_FRAGMENT)
        end
        self:UpdateKeybind()
    end
end

function ZO_RestyleCommon_Keyboard:ClearNewStatusFromPreviousCategory(referenceData)
    local collectibleCategoryData = referenceData.GetCollectibleCategoryData and referenceData:GetCollectibleCategoryData() or referenceData
    local categoryIndex, subcategoryIndex = collectibleCategoryData:GetCategoryIndicies()
    ClearCollectibleCategoryNewStatuses(categoryIndex, subcategoryIndex)
end

function ZO_RestyleCommon_Keyboard:AddCategory(nodeTemplate, parent, name, referenceData, normalIcon, pressedIcon, mouseoverIcon, disabledIcon, enabled)
    local entryData =
    {
        referenceData = referenceData,
        name = name,
        parentData = parent and parent.data or nil,
        normalIcon = normalIcon,
        pressedIcon = pressedIcon,
        mouseoverIcon = mouseoverIcon,
        disabledIcon = disabledIcon,
        enabled = enabled,
    }

    local node = self.categoryTree:AddNode(nodeTemplate, entryData, parent)
    entryData.node = node
    return node
end

do
    local NO_PARENT = nil

    function ZO_RestyleCommon_Keyboard:AddCollectibleParentCategories(categoryEnabledCallback)
        local restyleCategoryData = self:GetRestyleCategoryData()
        local specializedCollectibleCategory = restyleCategoryData:GetSpecializedCollectibleCategory()
        local searchResults = COLLECTIONS_BOOK_SINGLETON:GetSearchResults()

        local function AddCategory(categoryIndex, enabled)
            local categoryData = ZO_COLLECTIBLE_DATA_MANAGER:GetCategoryDataByIndicies(categoryIndex)
            if categoryData then
                local categoryName = categoryData:GetName()
                local normalIcon, pressedIcon, mouseoverIcon, disabledIcon = categoryData:GetKeyboardIcons()
                local template = enabled and "ZO_StatusIconHeader" or "ZO_StatusIconChildlessHeader"
                local node = self:AddCategory(template, NO_PARENT, categoryName, categoryData, normalIcon, pressedIcon, mouseoverIcon, disabledIcon, enabled)
                table.insert(self.collectibleCategoryNodes, node)
                return node
            end
        end

        local function IsValidCategoryData(categoryData)
            if categoryData:IsSpecializedCategory(specializedCollectibleCategory) then
                return categoryData:GetNumSubcategories() > 0 --No support for non-subcategorized collectibles in restyle
            end
            return false
        end

        local categoryDataNodes = {}
        for categoryIndex, categoryData in ZO_COLLECTIBLE_DATA_MANAGER:CategoryIterator({ IsValidCategoryData }) do
            local enabled = restyleCategoryData:IsSpecializedCollectibleCategoryEnabled() and (not categoryEnabledCallback or categoryEnabledCallback(categoryData))
            local categoryNode = AddCategory(categoryIndex, enabled)
            categoryDataNodes[categoryData] = categoryNode
        end

        return categoryDataNodes
    end

    local DYE_REFERENCE_DATA = { isDyesCategory = true }

    function ZO_RestyleCommon_Keyboard:AddDyeCategory(isDisabled)
        self.dyeCategoryNode = self:AddCategory("ZO_StatusIconChildlessHeader", NO_PARENT, GetString(SI_RESTYLE_DYES_CATEGORY_NAME), DYE_REFERENCE_DATA, "EsoUI/Art/Dye/dyes_categoryIcon_up.dds", "EsoUI/Art/Dye/dyes_categoryIcon_down.dds", "EsoUI/Art/Dye/dyes_categoryIcon_over.dds", "EsoUI/Art/Dye/dyes_categoryIcon_disabled.dds", not isDisabled)
    end
end

function ZO_RestyleCommon_Keyboard:AddSlotCollectibleCategories()
    local restyleCategoryData = self:GetRestyleCategoryData()

    local function AddSubcategory(restyleSlotData, parentNode)
        local subcategoryData = restyleSlotData:GetCollectibleCategoryData()
        if subcategoryData then
            local subcategoryName = restyleSlotData:GetDefaultDescriptor()
            local node = self:AddCategory("ZO_TreeStatusLabelSubCategory", parentNode, subcategoryName, restyleSlotData)
            self.restyleSlotTypeNodeLookup[restyleSlotData:GetRestyleSlotType()] = node
            table.insert(self.collectibleCategoryNodes, node)
        end
    end

    local specializedCollectibleCategory = restyleCategoryData:GetSpecializedCollectibleCategory()
    local searchResults = COLLECTIONS_BOOK_SINGLETON:GetSearchResults()

    if specializedCollectibleCategory == COLLECTIBLE_CATEGORY_SPECIALIZATION_OUTFIT_STYLES then
        local CategoryEnabledCallback = nil
        local actorCategory = self.currentSubTabDescriptor and self.currentSubTabDescriptor.actorCategory or GAMEPLAY_ACTOR_CATEGORY_PLAYER
        if not ZO_OUTFIT_MANAGER:HasWeaponsCurrentlyHeldToOverride(actorCategory) then
            -- If no weapon is equipped, show the weapons category, but disable it
            local weaponCategoryId = GetOutfitSlotDataCollectibleCategoryId(OUTFIT_SLOT_WEAPON_MAIN_HAND)
            local weaponSubcategoryData = ZO_COLLECTIBLE_DATA_MANAGER:GetCategoryDataById(weaponCategoryId)
            local weaponCategoryData = weaponSubcategoryData and weaponSubcategoryData:GetParentData()
            if weaponCategoryData then
                CategoryEnabledCallback = function(categoryData)
                    return categoryData ~= weaponCategoryData
                end
            end
        end

        local categoryDataNodes = self:AddCollectibleParentCategories(CategoryEnabledCallback)

        if restyleCategoryData:IsSpecializedCollectibleCategoryEnabled() then
            for outfitSlot = OUTFIT_SLOT_ITERATION_BEGIN, OUTFIT_SLOT_ITERATION_END do
                local isArmor = ZO_OUTFIT_MANAGER:IsOutfitSlotArmor(outfitSlot)
                local isEquippedWeapon = ZO_OUTFIT_MANAGER:IsWeaponOutfitSlotCurrentlyHeld(outfitSlot, actorCategory)
                if (isArmor or isEquippedWeapon) and not restyleCategoryData:IsOmittedRestyleSlotType(outfitSlot) then
                    local subcategoryId = GetOutfitSlotDataCollectibleCategoryId(outfitSlot)
                    local subcategoryData = ZO_COLLECTIBLE_DATA_MANAGER:GetCategoryDataById(subcategoryId)
                    local categoryData = subcategoryData and subcategoryData:GetParentData()
                    local categoryNode = categoryData and categoryDataNodes[categoryData]
                    if categoryNode then
                        local restyleSlotData = self.restyleSlotDataMetaPool:AcquireObject()
                        restyleSlotData:SetRestyleMode(restyleCategoryData.restyleMode)
                        restyleSlotData:SetRestyleSlotType(outfitSlot)
                        AddSubcategory(restyleSlotData, categoryNode)
                    end
                end
            end
        end
    end
end

function ZO_RestyleCommon_Keyboard:AddAllSpecializedCollectibleCategories()
    local function AddSubcategory(categoryIndex, subcategoryIndex, parentNode)
        local subcategoryData = ZO_COLLECTIBLE_DATA_MANAGER:GetCategoryDataByIndicies(categoryIndex, subcategoryIndex)
        if subcategoryData then
            local subcategoryName = subcategoryData:GetFormattedName()
            local node = self:AddCategory("ZO_TreeStatusLabelSubCategory", parentNode, subcategoryName, subcategoryData)
            self.collectibleCategoryNodeLookup[subcategoryData:GetId()] = node
            table.insert(self.collectibleCategoryNodes, node)
        end
    end

    local categoryDataNodes = self:AddCollectibleParentCategories()
    local restyleCategoryData = self:GetRestyleCategoryData()
    if restyleCategoryData:IsSpecializedCollectibleCategoryEnabled() then
        local searchResults = COLLECTIONS_BOOK_SINGLETON:GetSearchResults()

        for categoryData, categoryNode in pairs(categoryDataNodes) do
            for subcategoryIndex, subcategoryData in categoryData:SubcategoryIterator() do
                local categoryIndex = categoryData:GetCategoryIndicies()
                AddSubcategory(categoryIndex, subcategoryIndex, categoryNode)
            end
        end
    end
end

do
    local function ScrollToCollectibleData(specializedCollectibleCategory, scrollToCollectibleData)
        if scrollToCollectibleData then
            if specializedCollectibleCategory == COLLECTIBLE_CATEGORY_SPECIALIZATION_OUTFIT_STYLES then
                ZO_OUTFIT_STYLES_PANEL_KEYBOARD:ScrollToCollectibleData(scrollToCollectibleData)
                PlaySound(SOUNDS.OUTFIT_GO_TO_STYLE)
                return true
            end
        end
        return false
    end

    function ZO_RestyleCommon_Keyboard:NavigateToCollectibleData(collectibleData)
        if self.fragment:IsShowing() then
            if self:GetRestyleCategoryData():DerivesCollectibleCategoriesFromSlots() then
                return false
            end

            local categoryData = collectibleData:GetCategoryData()
            local node = self.collectibleCategoryNodeLookup[categoryData:GetId()]
            if node then
                self.categoryTree:SelectNode(node)
                if not ScrollToCollectibleData(self:GetRestyleCategoryData():GetSpecializedCollectibleCategory(), collectibleData) then
                    PlaySound(SOUNDS.DEFAULT_CLICK)
                end
            end
        else
            self.pendingNavigateToData = collectibleData
        end
    end

    function ZO_RestyleCommon_Keyboard:NavigateToCollectibleCategoryFromRestyleSlotData(restyleSlotData)
        local node = nil
        if self:GetRestyleCategoryData():DerivesCollectibleCategoriesFromSlots() then
            node = self.restyleSlotTypeNodeLookup[restyleSlotData:GetRestyleSlotType()]
        else
            local collectibleCategoryId = GetOutfitSlotDataCollectibleCategoryId(restyleSlotData:GetRestyleSlotType())
            node = self.collectibleCategoryNodeLookup[collectibleCategoryId]
        end

        if node then
            self.categoryTree:SelectNode(node)

            local scrollToCollectibleData = restyleSlotData:GetPendingCollectibleData()
            if not ScrollToCollectibleData(self:GetRestyleCategoryData():GetSpecializedCollectibleCategory(), scrollToCollectibleData) then
                PlaySound(SOUNDS.DEFAULT_CLICK)
            end
        end
    end
end

function ZO_RestyleCommon_Keyboard:OnSearchTextChanged()
    local restyleCategoryData = self:GetRestyleCategoryData()
    if restyleCategoryData then
        local editText = self.contentSearchEditBox:GetText()
        if restyleCategoryData:IsSpecializedCollectibleCategoryEnabled() then
            COLLECTIONS_BOOK_SINGLETON:SetSearchString(editText)
        end

        if restyleCategoryData:AllowsDyeing() then
            ZO_DYEING_MANAGER:SetSearchString(editText)
        end
    end
end

function ZO_RestyleCommon_Keyboard:OnShowing()
    self:RegisterForEvents()

    self:InitializeModeData()

    self:AddKeybinds()

    self:InitializeSearch()
    self:BuildCategories()
    self:RefreshCategoryContent()
end

function ZO_RestyleCommon_Keyboard:OnShown()
    if self.pendingNavigateToData then
        self:NavigateToCollectibleData(self.pendingNavigateToData)
        self.pendingNavigateToData = nil
    end
end

function ZO_RestyleCommon_Keyboard:OnHidden()
    self:UnregisterForEvents()

    self:RemoveKeybinds()
end

function ZO_RestyleCommon_Keyboard:OnCollectionUpdated()
    if self.fragment:IsShowing() then
        self:UpdateAllCategoryStatusIcons()
    end
end

function ZO_RestyleCommon_Keyboard:OnCollectibleNewStatusCleared(collectibleId)
    if self.fragment:IsShowing() then
        self:UpdateCollectibleStatus(collectibleId)
    end
end

function ZO_RestyleCommon_Keyboard:OnCollectibleCategoryNewStatusCleared(categoryId)
    if self.fragment:IsShowing() then
        self:UpdateCategoryStatus(categoryId)
    end
end

function ZO_RestyleCommon_Keyboard:RegisterForEvents()
    ZO_RESTYLE_SHEET_WINDOW_KEYBOARD:RegisterCallback("SheetSlotRefreshed", self.updateKeybindCallback)
    self.control:RegisterForEvent(EVENT_ACTIVE_WEAPON_PAIR_CHANGED, function()
        self:BuildCategories()
    end)
    ZO_RESTYLE_SHEET_WINDOW_KEYBOARD:RegisterCallback("SheetMouseoverDataChanged", self.updateKeybindCallback)
    ZO_RESTYLE_SHEET_WINDOW_KEYBOARD:RegisterCallback("NavigateToCollectibleCategoryFromRestyleSlotData", self.navigateToCollectibleCategoryCallback)
end

function ZO_RestyleCommon_Keyboard:UnregisterForEvents()
    ZO_RESTYLE_SHEET_WINDOW_KEYBOARD:UnregisterCallback("SheetSlotRefreshed", self.updateKeybindCallback)
    self.control:UnregisterForEvent(EVENT_ACTIVE_WEAPON_PAIR_CHANGED)
    ZO_RESTYLE_SHEET_WINDOW_KEYBOARD:UnregisterCallback("SheetMouseoverDataChanged", self.updateKeybindCallback)
    ZO_RESTYLE_SHEET_WINDOW_KEYBOARD:UnregisterCallback("NavigateToCollectibleCategoryFromRestyleSlotData", self.navigateToCollectibleCategoryCallback)
end

function ZO_RestyleCommon_Keyboard:AddKeybinds()
    if self.keybindStripDescriptor then
        KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
    end
end

function ZO_RestyleCommon_Keyboard:RemoveKeybinds()
    if self.keybindStripDescriptor then
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
    end
end

function ZO_RestyleCommon_Keyboard:InitializeModeData()
    -- To be overridden
end

function ZO_RestyleCommon_Keyboard:GetRestyleCategoryData()
    assert(false) -- Must be overridden
end

function ZO_RestyleCommon_Keyboard:GetFragment()
    return self.fragment
end

do
    local function GetRestyleSlotCollectibleCategoryId(specializedCollectibleCategory, restyleSlotType)
        if specializedCollectibleCategory == COLLECTIBLE_CATEGORY_SPECIALIZATION_OUTFIT_STYLES then
            return GetOutfitSlotDataCollectibleCategoryId(restyleSlotType)
        end
        return 0
    end

    function ZO_RestyleCommon_Keyboard:UpdateCategoryStatus(categoryId)
        local restyleCategoryData = self:GetRestyleCategoryData()
        local specializedCollectibleCategory = restyleCategoryData:GetSpecializedCollectibleCategory()
        if specializedCollectibleCategory then
            local anyMatchingCategoryNode = nil

            if restyleCategoryData:DerivesCollectibleCategoriesFromSlots() then
                for restyleSlotType, categoryNode in pairs(self.restyleSlotTypeNodeLookup) do
                    if GetRestyleSlotCollectibleCategoryId(specializedCollectibleCategory, restyleSlotType) == categoryId then
                        self:UpdateCategoryStatusIcon(categoryNode)
                        anyMatchingCategoryNode = categoryNode
                    end
                end
            else
                anyMatchingCategoryNode = self.collectibleCategoryNodeLookup[categoryId]
                if anyMatchingCategoryNode then
                    self:UpdateCategoryStatusIcon(anyMatchingCategoryNode)
                end
            end

            if anyMatchingCategoryNode then
                local collectibleCategoryData = ZO_COLLECTIBLE_DATA_MANAGER:GetCategoryDataById(categoryId)
                if collectibleCategoryData:IsSubcategory() then
                    self:UpdateCategoryStatusIcon(anyMatchingCategoryNode:GetParent())
                    MAIN_MENU_KEYBOARD:RefreshCategoryBar()
                    MAIN_MENU_KEYBOARD:UpdateSceneGroupButtons("collectionsSceneGroup")
                end
            end
        end
    end
end

function ZO_RestyleCommon_Keyboard:UpdateCollectibleStatus(collectibleId)
    local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(collectibleId)
    if collectibleData then
        local categoryData = collectibleData:GetCategoryData()
        if categoryData then
            self:UpdateCategoryStatus(categoryData:GetId())
        end
    end
end

function ZO_RestyleCommon_Keyboard:UpdateAllCategoryStatusIcons()
    for _, categoryNode in ipairs(self.collectibleCategoryNodes) do
        self:UpdateCategoryStatusIcon(categoryNode)
    end
end

function ZO_RestyleCommon_Keyboard:UpdateCategoryStatusIcon(categoryNode)
    local referenceData = categoryNode.data.referenceData
    local collectibleCategoryData = referenceData.GetCollectibleCategoryData and referenceData:GetCollectibleCategoryData() or referenceData
    local categoryControl = categoryNode.control

    if not categoryControl.statusIcon then
        categoryControl.statusIcon = categoryControl:GetNamedChild("StatusIcon")
    end

    categoryControl.statusIcon:ClearIcons()

    if collectibleCategoryData:HasAnyNewCollectibles() then
        local newsAreFiltered = false
        if not collectibleCategoryData:IsSubcategory() and self:GetRestyleCategoryData():DerivesCollectibleCategoriesFromSlots() then
            newsAreFiltered = true
            local children = categoryNode:GetChildren()
            if children then
                for _, childNode in ipairs(categoryNode:GetChildren()) do
                    local restyleSlotData = childNode.data.referenceData
                    local collectibleSubCategoryData = restyleSlotData:GetCollectibleCategoryData()
                    if collectibleSubCategoryData:HasAnyNewCollectibles() then
                        newsAreFiltered = false
                        break
                    end
                end
            end
        end

        if not newsAreFiltered then
            categoryControl.statusIcon:AddIcon(ZO_KEYBOARD_NEW_ICON)
        end
    end

    categoryControl.statusIcon:Show()
end


