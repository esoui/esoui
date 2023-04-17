--------------------------
-- Category Layout Base --
--------------------------

ZO_SpecializedCollectionsBook_Keyboard_CategoryLayout_Base = ZO_Object:Subclass()

function ZO_SpecializedCollectionsBook_Keyboard_CategoryLayout_Base:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_SpecializedCollectionsBook_Keyboard_CategoryLayout_Base:Initialize(owner)
    self.categorizedLists = {}
    self.owner = owner
end

function ZO_SpecializedCollectionsBook_Keyboard_CategoryLayout_Base:RefreshCategorizedLists()
    assert(false) -- Must be override
end

function ZO_SpecializedCollectionsBook_Keyboard_CategoryLayout_Base:GetCategorizedLists()
    self:RefreshCategorizedLists()
    return self.categorizedLists
end

function ZO_SpecializedCollectionsBook_Keyboard_CategoryLayout_Base:OnCollectibleLockStateChanged()
    -- Can be overriden
end

----------------------------------
-- Category Layout Unlock State --
----------------------------------

ZO_SpecializedCollectionsBook_Keyboard_CategoryLayout_UnlockState = ZO_SpecializedCollectionsBook_Keyboard_CategoryLayout_Base:Subclass()

function ZO_SpecializedCollectionsBook_Keyboard_CategoryLayout_UnlockState:New(...)
    return ZO_SpecializedCollectionsBook_Keyboard_CategoryLayout_Base.New(self, ...)
end

function ZO_SpecializedCollectionsBook_Keyboard_CategoryLayout_UnlockState:Initialize(owner)
    ZO_SpecializedCollectionsBook_Keyboard_CategoryLayout_Base.Initialize(self, owner)

    self.unlockedList = {}
    self.lockedList = {}
    table.insert(self.categorizedLists,
    {
        name = GetString("SI_COLLECTIBLEUNLOCKSTATE", COLLECTIBLE_UNLOCK_STATE_UNLOCKED_OWNED),
        normalIcon = "EsoUI/Art/Collections/collections_categoryIcon_unlocked_up.dds",
        pressedIcon = "EsoUI/Art/Collections/collections_categoryIcon_unlocked_down.dds",
        mouseoverIcon = "EsoUI/Art/Collections/collections_categoryIcon_unlocked_over.dds",
        collectibles = self.unlockedList,
    })
    table.insert(self.categorizedLists,
    {
        name = GetString("SI_COLLECTIBLEUNLOCKSTATE", COLLECTIBLE_UNLOCK_STATE_LOCKED),
        normalIcon = "EsoUI/Art/Collections/collections_categoryIcon_locked_up.dds",
        pressedIcon = "EsoUI/Art/Collections/collections_categoryIcon_locked_down.dds",
        mouseoverIcon = "EsoUI/Art/Collections/collections_categoryIcon_locked_over.dds",
        collectibles = self.lockedList,
    })

    self:BuildData()
end

function ZO_SpecializedCollectionsBook_Keyboard_CategoryLayout_UnlockState:BuildData()
    self.specializedSortedCollectibles = ZO_SpecializedSortedHouses:New()
    local categoryFilterFunctions = self.owner:GetCategoryFilterFunctions()
    local UNSORTED = false
    local relevantCollectibles = ZO_COLLECTIBLE_DATA_MANAGER:GetAllCollectibleDataObjects(categoryFilterFunctions, { ZO_CollectibleData.IsShownInCollection }, UNSORTED)

    for _, collectibleData in ipairs(relevantCollectibles) do
        self.specializedSortedCollectibles:InsertCollectible(collectibleData)
    end

    self.specializedSortedCollectibles:OnInsertFinished()
end

function ZO_SpecializedCollectionsBook_Keyboard_CategoryLayout_UnlockState:RefreshCategorizedLists()
    local unlockedList = self.unlockedList
    local lockedList = self.lockedList

    ZO_ClearNumericallyIndexedTable(unlockedList)
    ZO_ClearNumericallyIndexedTable(lockedList)

    local relevantCollectibles = self.specializedSortedCollectibles:GetCollectibles()
    for _, data in ipairs(relevantCollectibles) do
        if data:IsUnlocked() then
            table.insert(unlockedList, data)
        else
            table.insert(lockedList, data)
        end
    end
end

function ZO_SpecializedCollectionsBook_Keyboard_CategoryLayout_UnlockState:OnCollectibleLockStateChanged()
    -- A collectible may have been hidden before being unlocked. Rebuild the relevantCollectibles list to unhide them.
    self:BuildData()
end

-----------------------------------
-- Category Layout Subcategories --
-----------------------------------

ZO_SpecializedCollectionsBook_Keyboard_CategoryLayout_Subcategories = ZO_SpecializedCollectionsBook_Keyboard_CategoryLayout_Base:Subclass()

function ZO_SpecializedCollectionsBook_Keyboard_CategoryLayout_Subcategories:New(...)
    return ZO_SpecializedCollectionsBook_Keyboard_CategoryLayout_Base.New(self, ...)
end

function ZO_SpecializedCollectionsBook_Keyboard_CategoryLayout_Subcategories:RefreshCategorizedLists()
    ZO_ClearNumericallyIndexedTable(self.categorizedLists)

    local currentCategoryData
    local currentList

    local relevantCollectibles = self.owner:GetRelevantCollectibles()
    --We presorted by category to make this part easier
    for _, data in ipairs(relevantCollectibles) do
        -- Everything should be put into a subcategory, since we don't handle categories and subcategories elegantly in this scene
        local categoryData = data:GetCategoryData()
        if currentCategoryData ~= categoryData then
            currentCategoryData = categoryData
            currentList = {}
            local normalIcon, pressedIcon, mouseoverIcon = categoryData:GetKeyboardIcons()
            table.insert(self.categorizedLists, 
            { 
                name = categoryData:GetFormattedName(),
                normalIcon = normalIcon,
                pressedIcon = pressedIcon,
                mouseoverIcon = mouseoverIcon,
                collectibles = currentList,
            })
        end

        table.insert(currentList, data)
    end
end

----------------------
-- Scene Base Class --
----------------------

ZO_SpecializedCollectionsBook_Keyboard = ZO_Object:Subclass()

function ZO_SpecializedCollectionsBook_Keyboard:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_SpecializedCollectionsBook_Keyboard:Initialize(control, sceneName, categoryLayoutClass)
    control.owner = self
    self.control = control

    self.sceneName = sceneName
    self.categoryLayoutClass = categoryLayoutClass
    
    self:InitializeControls()
    self:InitializeNavigationList()
    self:InitializeEvents()
    self:InitializeKeybindStripDescriptors()

    local specializedBookScene = ZO_Scene:New(self.sceneName, SCENE_MANAGER)
    specializedBookScene:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            if self.keybindStripDescriptor then
                KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
            end
        elseif newState == SCENE_SHOWN then
            self:OnSceneShown()
        elseif newState == SCENE_HIDDEN then
            if self.keybindStripDescriptor then
                KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
            end
        end
    end)

    self.refreshGroups = ZO_Refresh:New()
    self.refreshGroups:AddRefreshGroup("RefreshList",
    {
        RefreshAll = function()
            self:RefreshListInternal()
        end,
    })

    self.refreshGroups:AddRefreshGroup("CollectibleUpdated",
    {
        RefreshSingle = function(collectibleId)
            local node = self.collectibleIdToTreeNode[collectibleId]
            if node then
                node:RefreshControl()
                if node == self.navigationTree:GetSelectedNode() then
                    self:RefreshDetails()
                end
            end
        end,
    })

    self.refreshGroups:AddRefreshGroup("ZoneChanged",
    {
        RefreshSingle = function()
            self:RefreshDetails()
        end,
    })

    control:SetHandler("OnUpdate", function() self.refreshGroups:UpdateRefreshGroups() end)
end

function ZO_SpecializedCollectionsBook_Keyboard:InitializeControls()
    self.navigationList = self.control:GetNamedChild("NavigationList")

    local contents = self.control:GetNamedChild("Contents")
    self.imageControl = contents:GetNamedChild("Image")
    self.nameLabel = contents:GetNamedChild("Name")

    local scrollSection = contents:GetNamedChild("ScrollContainer"):GetNamedChild("ScrollChild")
    self.descriptionLabel = scrollSection:GetNamedChild("Description")
end

function ZO_SpecializedCollectionsBook_Keyboard:InitializeNavigationList()
    self.navigationTree = ZO_Tree:New(self.navigationList:GetNamedChild("ScrollChild"), 60, -10, 300)

    local function TreeHeaderSetup(node, control, categoryData, open, userRequested)
        control.text:SetModifyTextType(MODIFY_TEXT_TYPE_UPPERCASE)
        control.text:SetText(categoryData.name)
        
        control.icon:SetTexture(open and categoryData.pressedIcon or categoryData.normalIcon)
        control.iconHighlight:SetTexture(categoryData.mouseoverIcon)

        ZO_IconHeader_Setup(control, open)

        if open and userRequested then
            self.navigationTree:SelectFirstChild(node)
        end
    end

    local function TreeEntrySetup(node, control, data, open)
        control:SetText(data:GetFormattedName())
        control:SetSelected(node:IsSelected())

        control.statusMultiIcon = control:GetNamedChild("StatusIcon")
        control.statusMultiIcon:ClearIcons()

        if data:IsNew() then
            control.statusMultiIcon:AddIcon("EsoUI/Art/Miscellaneous/new_icon.dds")
        end
        if data:IsPrimaryResidence() then
            control.statusMultiIcon:AddIcon("EsoUI/Art/Collections/PrimaryHouse.dds")
        end
        if data:IsFavorite() then
            control.statusMultiIcon:AddIcon("EsoUI/Art/Collections/Favorite_StarOnly.dds")
        end

        control.statusMultiIcon:Show()
    end

    local function TreeEntryOnSelected(control, data, selected, reselectingDuringRebuild)
        control:SetSelected(selected)

         if selected then
            self.selectedId = data:GetId()
            if not reselectingDuringRebuild then
                self:RefreshDetails()
            end

            local notificationId = data:GetNotificationId()
            if notificationId then
                RemoveCollectibleNotification(notificationId)
            end

            ClearCollectibleNewStatus(data:GetId())

            if self.keybindStripDescriptor then
                KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
            end
        end
    end

    local function TreeEntryEquality(left, right)
        return left:GetName() == right:GetName()
    end
    
    local CHILD_INDENT = 76
    local CHILD_SPACING = 0
    self.navigationTree:AddTemplate("ZO_StatusIconHeader", TreeHeaderSetup, nil, nil, CHILD_INDENT, CHILD_SPACING)
    self.navigationTree:AddTemplate("ZO_SpecializedCollection_Book_NavigationEntry_Keyboard", TreeEntrySetup, TreeEntryOnSelected, TreeEntryEquality)
    self.navigationTree:SetOpenAnimation("ZO_TreeOpenAnimation")
    self.navigationTree:SetExclusive(true)
    self.navigationTree.owner = self
    self.categoryLayoutObject = self.categoryLayoutClass:New(self)

    self.headerNodes = {}
    self.collectibleIdToTreeNode = {}

    self:RefreshListInternal()
end

function ZO_SpecializedCollectionsBook_Keyboard:InitializeEvents()
    ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("OnCollectibleUpdated", function(...) self:OnCollectibleUpdated(...) end)
    ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("OnCollectionUpdated", function(...) self:OnCollectionUpdated(...) end)
    ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("OnCollectibleNewStatusCleared", function(...) self:OnCollectibleNewStatusCleared(...) end)
    ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("OnCollectibleNotificationRemoved", function(...) self:OnCollectibleNotificationRemoved(...) end)
end

function ZO_SpecializedCollectionsBook_Keyboard:InitializeKeybindStripDescriptors()
    -- Intentionally left blank, override in children if required.
end

function ZO_SpecializedCollectionsBook_Keyboard:GetSelectedData()
    return self.navigationTree:GetSelectedData()
end

function ZO_SpecializedCollectionsBook_Keyboard:FocusCollectibleId(id)
    local node = self.collectibleIdToTreeNode[id]

    if node then
        if self.navigationTree:GetSelectedNode() == node then
            local RESELECT = true
            node:OnSelected(RESELECT)
        else
            self.navigationTree:SelectNode(node)
        end
    end
end

function ZO_SpecializedCollectionsBook_Keyboard:GetRelevantCollectibles()
    local categoryFilterFunctions = self:GetCategoryFilterFunctions()
    local SORTED = true
    return ZO_COLLECTIBLE_DATA_MANAGER:GetAllCollectibleDataObjects(categoryFilterFunctions, { ZO_CollectibleData.IsShownInCollection }, SORTED)
end

function ZO_SpecializedCollectionsBook_Keyboard:RefreshListInternal()
    ZO_ClearTable(self.headerNodes)
    ZO_ClearTable(self.collectibleIdToTreeNode)
    self.navigationTree:Reset()

    local categorizedLists = self.categoryLayoutObject:GetCategorizedLists()
    
    local firstNode = nil
    local selectedNode = nil

    for _, categorizedList in ipairs(categorizedLists) do
        if #categorizedList.collectibles > 0 then
            local headerNode = self.navigationTree:AddNode("ZO_StatusIconHeader", categorizedList)

            for _, collectibleData in ipairs(categorizedList.collectibles) do
                local node = self.navigationTree:AddNode("ZO_SpecializedCollection_Book_NavigationEntry_Keyboard", collectibleData, headerNode)
                self.collectibleIdToTreeNode[collectibleData:GetId()] = node
                if not firstNode then
                    firstNode = node
                end

                if self.selectedId and self.selectedId == collectibleData:GetId() then
                    selectedNode = node
                end
            end
        end
    end

    self.navigationTree:Commit()
    local navigateToNode = selectedNode or firstNode

    if navigateToNode then
        self.navigationTree:SelectNode(navigateToNode)
    end
    self:RefreshDetails()
end

function ZO_SpecializedCollectionsBook_Keyboard:RefreshDetails()
    local data = self.navigationTree:GetSelectedData()

    if data then
        self.imageControl:SetTexture(data:GetKeyboardBackgroundImage())
        self.nameLabel:SetText(data:GetFormattedName())
        self.descriptionLabel:SetText(data:GetDescription())
    end
end

function ZO_SpecializedCollectionsBook_Keyboard:BrowseToCollectible(collectibleId)
    self:FocusCollectibleId(collectibleId)
    MAIN_MENU_KEYBOARD:ToggleSceneGroup("collectionsSceneGroup", self.sceneName)
end

function ZO_SpecializedCollectionsBook_Keyboard:OnCollectibleUpdated(collectibleId)
    local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(collectibleId)
    if self:IsCollectibleRelevant(collectibleData) then
        local node = self.collectibleIdToTreeNode[collectibleId]
        if node then
            self:RefreshSingle(collectibleId)
        end
    end
end

function ZO_SpecializedCollectionsBook_Keyboard:UpdateCollectibleTreeEntry(collectibleId)
    if not SCENE_MANAGER:IsShowing(self.sceneName) then
        self.dirty = true
    else
        local node = self.collectibleIdToTreeNode[collectibleId]
        if node then
            node:RefreshControl()
        end
    end
end

function ZO_SpecializedCollectionsBook_Keyboard:TreeEntry_OnMouseUp(control, upInside, button)
    -- Additional functionality can be added here or in derived classes, as in HousingBook_Keyboard:TreeEntry_OnMouseUp
end

function ZO_SpecializedCollectionsBook_Keyboard:OnCollectibleNotificationRemoved(notificationId, collectibleId)
    self:UpdateCollectibleTreeEntry(collectibleId)
end

function ZO_SpecializedCollectionsBook_Keyboard:OnCollectibleNewStatusCleared(collectibleId)
    self:UpdateCollectibleTreeEntry(collectibleId)
end

function ZO_SpecializedCollectionsBook_Keyboard:OnCollectionUpdated(collectionUpdateType, collectiblesByNewUnlockState)
    if NonContiguousCount(collectiblesByNewUnlockState) > 0 or collectionUpdateType == ZO_COLLECTION_UPDATE_TYPE.REBUILD then
        self.categoryLayoutObject:OnCollectibleLockStateChanged()
        self:RefreshList()
    end
end

function ZO_SpecializedCollectionsBook_Keyboard:OnSceneShown()
    self.refreshGroups:UpdateRefreshGroups()
end

function ZO_SpecializedCollectionsBook_Keyboard:RefreshList()
    self.refreshGroups:RefreshAll("RefreshList")
end

function ZO_SpecializedCollectionsBook_Keyboard:RefreshSingle(collectibleId)
    self.refreshGroups:RefreshSingle("CollectibleUpdated", collectibleId)
end

function ZO_SpecializedCollectionsBook_Keyboard:GetCategoryFilterFunctions()
    assert(false) -- override in derived classes
end

function ZO_SpecializedCollectionsBook_Keyboard:IsCollectibleRelevant(collectibleData)
    assert(false) -- override in derived classes
end

function ZO_SpecializedCollection_Book_NavigationEntry_Keyboard_OnMouseUp(control, ...)
    control.node:GetTree().owner:TreeEntry_OnMouseUp(control, ...)
end