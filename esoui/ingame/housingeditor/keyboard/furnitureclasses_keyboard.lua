--
--[[ ZO_HousingBrowserList ]]--
--

ZO_HousingBrowserList = ZO_Object:Subclass()

function ZO_HousingBrowserList:New(...)
    local browserList = ZO_Object.New(self)
    browserList:Initialize(...)
    return browserList
end

function ZO_HousingBrowserList:Initialize(control, owner)
    self.control = control
    self.owner = owner

    self.contents = control:GetNamedChild("Contents")

    self.parentCategoryTemplate = "ZO_IconHeader"
    self.childlessCategoryTemplate = "ZO_IconChildlessHeader"
    self.subCategoryTemplate = "ZO_HousingFurnitureBrowserSubCategory"

    self:InitializeCategories(self.contents)

    self.fragment = ZO_FadeSceneFragment:New(self.control)

    self.fragment:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
            self:OnShowing()
        elseif newState == SCENE_FRAGMENT_HIDDEN then
            self:OnHidden()
        end
    end)

    self:InitializeKeybindStrip()
end

function ZO_HousingBrowserList:GetFragment()
    return self.fragment
end

function ZO_HousingBrowserList:OnShowing()
    if self.keybindStripDescriptor then
        KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
    end
end

function ZO_HousingBrowserList:OnHidden()
    if self.keybindStripDescriptor then
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
    end
end

function ZO_HousingBrowserList:GetCategoryInfo(categoryId, categoryObject)
    local normalIcon, pressedIcon, mouseoverIcon
    local isFakedSubcategory = false
    if categoryId == ZO_FURNITURE_NEEDS_CATEGORIZATION_FAKE_CATEGORY then
        isFakedSubcategory = true
    else
        normalIcon, pressedIcon, mouseoverIcon = GetFurnitureCategoryKeyboardIcons(categoryId)
    end
    local formattedName = zo_strformat(SI_HOUSING_FURNITURE_CATEGORY_FORMAT, categoryObject:GetName(), categoryObject:GetNumEntryItemsRecursive())
    return formattedName, normalIcon, pressedIcon, mouseoverIcon, isFakedSubcategory
end

do
    local function AddNodeLookup(lookup, node, parent, categoryId)
        if categoryId ~= nil then
            local parentCategory = categoryId
            local subCategory

            if parent then
                parentCategory = parent.data.categoryId
                subCategory = categoryId
            end

            local categoryTable = lookup[parentCategory]
            
            if categoryTable == nil then
                categoryTable = { subCategories = {} }
                lookup[parentCategory] = categoryTable
            end

            if subCategory then
                categoryTable.subCategories[subCategory] = node
            else
                categoryTable.node = node
            end
        end
    end

    function ZO_HousingBrowserList:AddCategory(tree, nodeTemplate, parent, categoryId, categoryObject)
        local name, normalIcon, pressedIcon, mouseoverIcon, isFakedSubcategory = self:GetCategoryInfo(categoryId, categoryObject)
        local entryData = 
        {
            isFakedSubcategory = isFakedSubcategory,
            categoryId = categoryId,
            categoryEntries = categoryObject:GetAllEntries(),
            name = name,
            parentData = parent and parent.data or nil,
            normalIcon = normalIcon,
            pressedIcon = pressedIcon,
            mouseoverIcon = mouseoverIcon,
        }

        local soundId = parent and SOUNDS.JOURNAL_PROGRESS_SUB_CATEGORY_SELECTED or SOUNDS.JOURNAL_PROGRESS_CATEGORY_SELECTED
        local node = tree:AddNode(nodeTemplate, entryData, parent, soundId)
        AddNodeLookup(self.nodeLookupData, node, parent, categoryId)
        entryData.node = node
        categoryObject.node = node

        return node
    end

    function ZO_HousingBrowserList:BuildCategories()
        local currentSelectedData = self.categoryTree:GetSelectedData()
        self.categoryTree:Reset()
        self.nodeLookupData = {}

        local hasCategory = false
        local categoryTreeData = self:GetCategoryTreeData()
        if categoryTreeData then
            local allTopLevelCategories = categoryTreeData:GetAllSubcategories()
            for index, categoryObject in ipairs(allTopLevelCategories) do
                self:AddTopLevelCategory(categoryObject)
                hasCategory = true
            end
        end

        local nodeToSelect
        if currentSelectedData then
            local categoryId
            local subcatgoryId
            local parentData = currentSelectedData.parentData
            if parentData then
                categoryId = parentData.categoryId
                subcatgoryId = currentSelectedData.categoryId
            else
                categoryId = currentSelectedData.categoryId
            end
            nodeToSelect = self:GetCategoryData(categoryId, subcatgoryId)
        end

        self.categoryTree:Commit(nodeToSelect)

        if hasCategory then
            self:SetNoItemTextShown(false)
        else
            self.selectedCategoryEntries = nil
            self.contentsList:RefreshData()
            self:SetNoItemTextShown(true, self:GetNoItemText())
        end
    end
end

function ZO_HousingBrowserList:GetCategoryData(categoryId, subCategoryId)
    if categoryId ~= nil then
        local categoryTable = self.nodeLookupData[categoryId]
        if categoryTable ~= nil then
            if subCategoryId ~= nil then
                return categoryTable.subCategories[subCategoryId]
            else
                if categoryTable.node:IsLeaf() then
                    return categoryTable.node
                else
                    return categoryTable.node:GetChildren()[1]
                end
            end
        end
    end
end

function ZO_HousingBrowserList:AddTopLevelCategory(categoryObject)
    local categoryId = categoryObject:GetCategoryId()
    local parent
    local tree = self.categoryTree
    local nodeTemplate = self.childlessCategoryTemplate
    local hasChildren = categoryObject:GetHasSubcategories()
    if hasChildren then
        nodeTemplate = self.parentCategoryTemplate
    end

    local NO_PARENT = nil
    local parent = self:AddCategory(tree, nodeTemplate, NO_PARENT, categoryId, categoryObject)
        
    if hasChildren then
        local allSubcategories = categoryObject:GetAllSubcategories()
        for index, subcategoryObject in ipairs(allSubcategories) do
            local subcategoryId = subcategoryObject:GetCategoryId()
            self:AddCategory(tree, self.subCategoryTemplate, parent, subcategoryId, subcategoryObject)
        end
    end

    return parent
end

function ZO_HousingBrowserList:InitializeCategories(control)
    self.categories = control:GetNamedChild("CategoryList")
    self.categoryTree = ZO_Tree:New(self.categories:GetNamedChild("ScrollChild"), 60, -10, 300)
    self.noMatchMessageLabel = control:GetNamedChild("NoMatchMessage")

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
            self:OnCategorySelected(data)
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

    self.categoryTree:AddTemplate(self.parentCategoryTemplate, TreeHeaderSetup_Child, nil, nil, 60, 0)
    self.categoryTree:AddTemplate(self.childlessCategoryTemplate, TreeHeaderSetup_Childless, TreeEntryOnSelected_Childless)
    self.categoryTree:AddTemplate(self.subCategoryTemplate, TreeEntrySetup, TreeEntryOnSelected)

    self.categoryTree:SetExclusive(true)
    self.categoryTree:SetOpenAnimation("ZO_TreeOpenAnimation")
end

function ZO_HousingBrowserList:SetNoItemTextShown(shown, text)
    self.noMatchMessageLabel:SetHidden(not shown)
    if shown then
        self.noMatchMessageLabel:SetText(text)
    end
end

function ZO_HousingBrowserList:OnCategorySelected(data)
    assert(false) -- Needs to be overridden in derived classes
end

function ZO_HousingBrowserList:GetCategoryTreeData()
    assert(false) -- Needs to be overridden in derived classes
end

function ZO_HousingBrowserList:InitializeKeybindStrip()
    --Override
end

--
--[[ ZO_HousingFurnitureList ]]--
--

ZO_HousingFurnitureList = ZO_Object.MultiSubclass(ZO_HousingBrowserList, ZO_CallbackObject)

function ZO_HousingFurnitureList:New(...)
    local list = ZO_CallbackObject.New(self)
    list:Initialize(...)
    return list
end

function ZO_HousingFurnitureList:Initialize(...)
    ZO_HousingBrowserList.Initialize(self, ...)
    self:InitializeList()

    self.CompareFurnitureEntriesFunction = function(a, b)
        return self:CompareFurnitureEntries(a.data, b.data)
    end

    self:AddListDataTypes()

    local searchEditBox = self.control:GetNamedChild("ContentsSearchBoxBox")
    if searchEditBox then
        searchEditBox:SetHandler("OnTextChanged", function(editBox)
            self:OnSearchTextChanged(editBox)
        end)
    end

    self.freeSlotsLabel = self.contents:GetNamedChild("InfoBarFreeSlots")
end

function ZO_HousingFurnitureList:InitializeList()
    local contentsList = ZO_SortFilterList:New(self.contents)
    self.contentsList = contentsList
    contentsList.BuildMasterList = function()
        self:ContentsBuildMasterList()
    end
    contentsList.FilterScrollList = function()
        self:ContentsFilterScrollList()
    end
    contentsList.SortScrollList = function()
        self:ContentsSortScrollList()
    end
    contentsList.CommitScrollList = function()
        self:ContentsCommitScrollList()
    end
    ZO_ScrollList_EnableSelection(contentsList:GetListControl(), "ZO_ThinListHighlight", function(...) self:OnSelectionChanged(...) end)
    ZO_ScrollList_SetDeselectOnReselect(contentsList:GetListControl(), false)
end

function ZO_HousingFurnitureList:GetList()
    return self.contentsList:GetListControl()
end

function ZO_HousingFurnitureList:OnShowing()
    ZO_HousingBrowserList.OnShowing(self)

    self:UpdateFreeSlots()
end

function ZO_HousingFurnitureList:OnHidden()
    ZO_HousingBrowserList.OnHidden(self)

    self:ClearSelection()
end

function ZO_HousingFurnitureList:OnSearchTextChanged(editBox)
    ZO_EditDefaultText_OnTextChanged(editBox)
end

function ZO_HousingFurnitureList:AddDataType(dataType, controlTemplate, entryHeight, setupFunction, hideFunction)
    ZO_ScrollList_AddDataType(self.contentsList:GetListControl(), dataType, controlTemplate, entryHeight, setupFunction, hideFunction)
end

function ZO_HousingFurnitureList:UpdateLists()
    -- When the furniture data is updated the most recently selected item might have been destroyed so clear it out just in case.
    self:ClearSelection()

    self:BuildCategories()
    self:UpdateFreeSlots()
end

function ZO_HousingFurnitureList:UpdateContentsSort()
    self.contentsList:RefreshSort()
end

function ZO_HousingFurnitureList:UpdateContentsVisible()
    self.contentsList:RefreshVisible()
end

function ZO_HousingFurnitureList:BuildCategories()
    ZO_HousingBrowserList.BuildCategories(self)
end

function ZO_HousingFurnitureList:OnCategorySelected(data)
    self.selectedCategoryEntries = data.categoryEntries
    self.contentsList:RefreshData()
end

function ZO_HousingFurnitureList:ContentsBuildMasterList()
    if self.selectedCategoryEntries then
        self.contentsMasterList = ZO_ShallowTableCopy(self.selectedCategoryEntries)
    else
        self.contentsMasterList = {}
    end
end

function ZO_HousingFurnitureList:ContentsFilterScrollList()
    local scrollData = ZO_ScrollList_GetDataList(self.contentsList:GetListControl())
    ZO_ClearNumericallyIndexedTable(scrollData)

    for _, entryData in ipairs(self.contentsMasterList) do
        table.insert(scrollData, ZO_ScrollList_CreateDataEntry(entryData:GetDataType(), entryData))
    end
end

function ZO_HousingFurnitureList:CompareFurnitureEntries(a, b)
    return a:GetRawName() < b:GetRawName()
end

function ZO_HousingFurnitureList:ContentsSortScrollList()
    local scrollData = ZO_ScrollList_GetDataList(self:GetList())
    table.sort(scrollData, self.CompareFurnitureEntriesFunction)
end

function ZO_HousingFurnitureList:ContentsCommitScrollList()
    ZO_SortFilterList.CommitScrollList(self.contentsList)
    --Reselect the most recently selected data if it is in this contents list
    ZO_ScrollList_SelectData(self.contentsList:GetListControl(), self.mostRecentlySelectedData)
end

function ZO_HousingFurnitureList:SetMostRecentlySelectedData(data)
    self.mostRecentlySelectedData = data
    if self.keybindStripDescriptor then
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    end

    if self.mostRecentlySelectedData then
        ZO_HousingFurnitureBrowser_Base.PreviewFurniture(self.mostRecentlySelectedData)
    else
        ITEM_PREVIEW_KEYBOARD:EndCurrentPreview()
    end

    self:FireCallbacks("OnMostRecentlySelectedDataChanged", data)
end

function ZO_HousingFurnitureList:GetMostRecentlySelectedData()
    return self.mostRecentlySelectedData
end

function ZO_HousingFurnitureList:OnSelectionChanged(previouslySelectedData, selectedData, selectingDuringRebuild)
    -- When switching between categories the list will clear it's selection
    -- but we want to preserve the last selection so we can restore it later
    -- so if selectedData is nil we will skip he call to SetMostRecentlySelectedData
    if selectedData then
        self:SetMostRecentlySelectedData(selectedData)
    end
end

function ZO_HousingFurnitureList:ClearSelection()
    ZO_ScrollList_SelectData(self:GetList(), nil)
    self:SetMostRecentlySelectedData(nil)
end

function ZO_HousingFurnitureList:GetNoItemsText()
    --Override
    assert(false)
end

function ZO_HousingFurnitureList:UpdateFreeSlots()
    local numUsedSlots, numSlots = PLAYER_INVENTORY:GetNumSlots(INVENTORY_BACKPACK)
    if self.numUsedSlots ~= numUsedSlots or self.numSlots ~= numSlots then
        self.numUsedSlots = numUsedSlots
        self.numSlots = numSlots
        if numUsedSlots < numSlots then
            self.freeSlotsLabel:SetText(zo_strformat(SI_INVENTORY_BACKPACK_REMAINING_SPACES, numUsedSlots, numSlots))
        else
            self.freeSlotsLabel:SetText(zo_strformat(SI_INVENTORY_BACKPACK_COMPLETELY_FULL, numUsedSlots, numSlots))
        end
    end
end

--
--[[ ZO_HousingSettingsList ]]--
--

ZO_HousingSettingsList = ZO_SocialListKeyboard:Subclass()

function ZO_HousingSettingsList:New(...)
    return ZO_SocialListKeyboard.New(self, ...)
end

function ZO_HousingSettingsList:Initialize(userGroup, control, owner, rowDataType, rowTemplate)
    ZO_SocialListKeyboard.Initialize(self, control)

    self.userGroup = userGroup
    self.owner = owner
    self.rowDataType = rowDataType
    self.rowTemplate = rowTemplate
    self.masterList = {}

    self:SetEmptyText(GetString(SI_GAMEPAD_HOUSING_PERMISSIONS_NO_ENTRIES))
    self.sortFunction = function(listEntry1, listEntry2) return self:CompareEntries(listEntry1, listEntry2) end
    ZO_ScrollList_AddDataType(self.list, rowDataType, rowTemplate, 30, function(control, data) self:SetupRow(control, data) end)
    ZO_ScrollList_EnableHighlight(self.list, "ZO_ThinListHighlight")
end

function ZO_HousingSettingsList:ColorRow(control, data, mouseIsOver)
    local textColor, iconColor = self:GetRowColors(data, mouseIsOver)
    ZO_SocialList_ColorRow(control, data, textColor, iconColor, textColor)

    if data.permissionPresetName then
        local permissions = GetControl(control, "Permissions")
        permissions:SetColor(iconColor:UnpackRGBA())
    end
end

function ZO_HousingSettingsList:SetActive(hidden)
    self.control:SetHidden(hidden)
end

function ZO_HousingSettingsList:SetupRow(control, data)
    ZO_SortFilterList.SetupRow(self, control, data)

    local displayName = GetControl(control, "DisplayName")
    local permissions = GetControl(control, "Permissions")

    if displayName then
        displayName:SetText(ZO_FormatUserFacingDisplayName(data.displayName))
    end

    if permissions then
        permissions:SetText(data.permissionPresetName)
    end

    control.panel = self
end

function ZO_HousingSettingsList:SortScrollList()
    if self.currentSortKey ~= nil and self.currentSortOrder ~= nil then
        local scrollData = ZO_ScrollList_GetDataList(self.list)
        table.sort(scrollData, self.sortFunction)
    end

    self:RefreshVisible()
end

function ZO_HousingSettingsList:CompareEntries(listEntry1, listEntry2)
    return ZO_TableOrderingFunction(listEntry1.data, listEntry2.data, self.currentSortKey, ZO_HOUSING_SETTINGS_LIST_ENTRY_SORT_KEYS, self.currentSortOrder)
end

function ZO_HousingSettingsList:FilterScrollList()
    ZO_HousingSettings_FilterScrollList(self.list, self.masterList, self.rowDataType)
end

function ZO_HousingSettingsList:GetUserGroup()
    return self.userGroup
end

function ZO_HousingSettingsList_CreateScrollData(displayName, currentHouse, userGroup, index, permissionPresetName)
    return { 
                displayName = displayName, 
                userGroup = userGroup,
                index = index,
                currentHouse = currentHouse, 
                permissionPresetName = permissionPresetName,
                online = true, -- since we are using this data in a social list, and we don't know the status of the individual or guild, we are default to true so that the text is properly colorized
           }
end

--
--[[ ZO_HousingSettingsVisitorList_Keyboard ]]--
--
ZO_HousingSettingsVisitorList_Keyboard = ZO_HousingSettingsList:Subclass()

function ZO_HousingSettingsVisitorList_Keyboard:New(...)
    return ZO_HousingSettingsList.New(self, HOUSE_PERMISSION_USER_GROUP_INDIVIDUAL, ...)
end

function ZO_HousingSettingsVisitorList_Keyboard:BuildMasterList()
    self.currentHouse = self.owner.currentHouse
    self.numPermissions = GetNumHousingPermissions(self.currentHouse, HOUSE_PERMISSION_USER_GROUP_INDIVIDUAL)
    ZO_HousingSettings_BuildMasterList_Visitor(self.currentHouse, self.userGroup, self.numPermissions, self.masterList, ZO_HousingSettingsList_CreateScrollData)
end

function ZO_HousingSettingsVisitorList_Keyboard:GetAddUserGroupDialogTitle()
    return GetString(SI_DIALOG_TITLE_ADD_INDIVIDUAL_PERMISSION)
end

--
--[[ ZO_HousingSettingsBanList_Keyboard ]]--
--

ZO_HousingSettingsBanList_Keyboard = ZO_HousingSettingsList:Subclass()

function ZO_HousingSettingsBanList_Keyboard:New(...)
    return ZO_HousingSettingsList.New(self, HOUSE_PERMISSION_USER_GROUP_INDIVIDUAL, ...)
end

function ZO_HousingSettingsBanList_Keyboard:BuildMasterList()
    self.currentHouse = self.owner.currentHouse
    self.numPermissions = GetNumHousingPermissions(self.currentHouse, HOUSE_PERMISSION_USER_GROUP_INDIVIDUAL)
    ZO_HousingSettings_BuildMasterList_Ban(self.currentHouse, self.userGroup, self.numPermissions, self.masterList, ZO_HousingSettingsList_CreateScrollData)
end

function ZO_HousingSettingsBanList_Keyboard:GetAddUserGroupDialogTitle()
    return GetString(SI_DIALOG_TITLE_BAN_INDIVIDUAL_PERMISSION)
end

--
--[[ ZO_HousingSettingsGuildVisitorList_Keyboard ]]--
--

ZO_HousingSettingsGuildVisitorList_Keyboard = ZO_HousingSettingsList:Subclass()

function ZO_HousingSettingsGuildVisitorList_Keyboard:New(...)
    return ZO_HousingSettingsList.New(self, HOUSE_PERMISSION_USER_GROUP_GUILD, ...)
end

function ZO_HousingSettingsGuildVisitorList_Keyboard:BuildMasterList()
    self.currentHouse = self.owner.currentHouse
    self.numPermissions = GetNumHousingPermissions(self.currentHouse, HOUSE_PERMISSION_USER_GROUP_GUILD)
    ZO_HousingSettings_BuildMasterList_Visitor(self.currentHouse, self.userGroup, self.numPermissions, self.masterList, ZO_HousingSettingsList_CreateScrollData)
end

function ZO_HousingSettingsGuildVisitorList_Keyboard:GetAddUserGroupDialogTitle()
    return GetString(SI_DIALOG_TITLE_ADD_GUILD_PERMISSION)
end

--
--[[ ZO_HousingSettingsGuildBanList_Keyboard ]]--
--

ZO_HousingSettingsGuildBanList_Keyboard = ZO_HousingSettingsList:Subclass()

function ZO_HousingSettingsGuildBanList_Keyboard:New(...)
    return ZO_HousingSettingsList.New(self, HOUSE_PERMISSION_USER_GROUP_GUILD, ...)
end

function ZO_HousingSettingsGuildBanList_Keyboard:BuildMasterList()
    self.currentHouse = self.owner.currentHouse
    self.numPermissions = GetNumHousingPermissions(self.currentHouse, HOUSE_PERMISSION_USER_GROUP_GUILD)
    ZO_HousingSettings_BuildMasterList_Ban(self.currentHouse, self.userGroup, self.numPermissions, self.masterList, ZO_HousingSettingsList_CreateScrollData)
end

function ZO_HousingSettingsGuildBanList_Keyboard:GetAddUserGroupDialogTitle()
    return GetString(SI_DIALOG_TITLE_BAN_GUILD_PERMISSION)
end