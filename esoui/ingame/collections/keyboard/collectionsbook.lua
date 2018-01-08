ZO_COLLECTIBLE_PADDING = 10
ZO_COLLECTIBLE_STICKER_SINGLE_WIDTH = 175
ZO_COLLECTIBLE_STICKER_SINGLE_HEIGHT = 125
local COLLECTIBLE_STICKER_ROW_STRIDE = 3
ZO_COLLECTIBLE_STICKER_ROW_WIDTH = (ZO_COLLECTIBLE_STICKER_SINGLE_WIDTH + ZO_COLLECTIBLE_PADDING) * COLLECTIBLE_STICKER_ROW_STRIDE
ZO_COLLECTIBLE_STICKER_ROW_HEIGHT = ZO_COLLECTIBLE_STICKER_SINGLE_HEIGHT + ZO_COLLECTIBLE_PADDING
local RETAIN_SCROLL_POSITION = true
local DONT_RETAIN_SCROLL_POSITION = false
local DONT_ANIMATE = true
local ACTIVE_ICON = "EsoUI/Art/Inventory/inventory_icon_equipped.dds"
local HIDDEN_ICON = "EsoUI/Art/Inventory/inventory_icon_hiddenBy.dds"
local VISIBLE_ICON = "EsoUI/Art/Inventory/inventory_icon_visible.dds"
local STICKER_ROW_DATA = 1

local function GetTextColor(enabled, normalColor, disabledColor)
    if enabled then
        return (normalColor or ZO_NORMAL_TEXT):UnpackRGBA()
    end
    return (disabledColor or ZO_DISABLED_TEXT):UnpackRGBA()
end

local function ApplyTextColorToLabel(label, ...)
    label:SetColor(GetTextColor(...))
end

local g_currentMouseTarget = nil

--[[Collectible]]--
-------------------
--[[ Initialization ]]--
------------------------
local Collectible = ZO_Object:Subclass()

function Collectible:New(...)
    local collectible = ZO_Object.New(self)
    collectible:Initialize(...)
    return collectible
end

function Collectible:Initialize(collectibleId)
    self.isCooldownActive = false
    self.cooldownDuration = 0
    self.cooldownStartTime = 0

    self.collectibleId = collectibleId
    if collectibleId then
        COLLECTIONS_BOOK_SINGLETON:RegisterCallback("OnUpdateCooldowns",
                                                    function(...)
                                                        -- don't try to update the control if we aren't the current collectible it's showing
                                                        if self.control and self.control.collectible == self then
                                                            self:OnUpdateCooldowns(...)
                                                        end
                                                    end)
    end
end

function Collectible:Show(control)
    self.control = control
    local collectibleData = self.collectibleId and ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(self.collectibleId) or nil
    if collectibleData then
        control.collectible = self
        self.collectibleData = collectibleData

        self.maxIconHeight = control.icon:GetHeight()

        control.title:SetText(collectibleData:GetFormattedName())

        local iconFile = collectibleData:GetIcon()
        local iconControl = control.icon
        iconControl:SetTexture(iconFile)
        
        local desaturation = (collectibleData:IsLocked() or collectibleData:IsBlocked()) and 1 or 0
        iconControl:SetDesaturation(desaturation)
        control.highlight:SetDesaturation(desaturation)

        local textureSampleProcessingWeightTable = collectibleData:IsUnlocked() and ZO_UNLOCKED_ICON_SAMPLE_PROCESSING_WEIGHT_TABLE or ZO_LOCKED_ICON_SAMPLE_PROCESSING_WEIGHT_TABLE
        for type, weight in pairs(textureSampleProcessingWeightTable) do
            iconControl:SetTextureSampleProcessingWeight(type, weight)
        end

        ApplyTextColorToLabel(control.title, collectibleData:IsUnlocked(), ZO_NORMAL_TEXT, ZO_DISABLED_TEXT)

        control.cooldownIcon:SetTexture(iconFile)
        control.cooldownIconDesaturated:SetTexture(iconFile)
        control.cooldownIconDesaturated:SetDesaturation(1)
        control.cooldownTime:SetText("")

        control.title:SetHidden(false)
        iconControl:SetHidden(false)

        self:RefreshVisualLayer()

        if self:IsCurrentMouseTarget() then
            self:ShowKeybinds()
        end

        self:OnUpdateCooldowns()
    else
        control.title:SetHidden(true)
        control.icon:SetHidden(true)
        control.multiIcon:ClearIcons()
        control.cornerTag:SetHidden(true)
        self:EndCooldown()
        control.collectible = nil
    end
    self:RefreshMouseoverVisuals(DONT_ANIMATE)
end

function Collectible:RefreshVisualLayer()
    self:RefreshTooltip()
    self:RefreshMultiIcon()
end

function Collectible:RefreshMultiIcon()
    local control = self.control
    control.multiIcon:ClearIcons()

    local collectibleData = self.collectibleData
    if collectibleData:IsActive() then
        control.multiIcon:AddIcon(ACTIVE_ICON)

        if collectibleData:WouldBeHidden() then
            control.multiIcon:AddIcon(HIDDEN_ICON)
        end
    end

    if collectibleData:IsNew() then
        control.multiIcon:AddIcon(ZO_KEYBOARD_NEW_ICON)
    end

    control.multiIcon:Show()
end

function Collectible:SetHighlightHidden(hidden, dontAnimate)
    local control = self.control
    control.highlight:SetHidden(false) -- let alpha take care of the actual hiding
    if not control.highlightAnimation then
        control.highlightAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("JournalProgressHighlightAnimation", control.highlight)
    end

    local isUnlocked = self.collectibleData and self.collectibleData:IsUnlocked()

    if hidden then
        ApplyTextColorToLabel(control.title, isUnlocked, ZO_NORMAL_TEXT, ZO_DISABLED_TEXT)
        if dontAnimate then
            control.iconAnimation:PlayInstantlyToStart()
            control.highlightAnimation:PlayInstantlyToStart()
        else
            control.iconAnimation:PlayBackward()
            control.highlightAnimation:PlayBackward()
        end
    else
        ApplyTextColorToLabel(control.title, isUnlocked, ZO_HIGHLIGHT_TEXT, ZO_SELECTED_TEXT)
        if dontAnimate then
            control.highlightAnimation:PlayInstantlyToEnd()
            if self.isCooldownActive ~= true then
                control.iconAnimation:PlayInstantlyToEnd()
            end
        else
            control.highlightAnimation:PlayForward()
            if self.isCooldownActive ~= true then
                control.iconAnimation:PlayForward()
            end
        end
    end
end

function Collectible:GetInteractionTextEnum()
    local textEnum
    local collectibleData = self.collectibleData

    if collectibleData:IsActive() then
        if collectibleData:IsCategoryType(COLLECTIBLE_CATEGORY_TYPE_VANITY_PET) or collectibleData:IsCategoryType(COLLECTIBLE_CATEGORY_TYPE_ASSISTANT) then
            textEnum = SI_COLLECTIBLE_ACTION_DISMISS
        else
            textEnum = SI_COLLECTIBLE_ACTION_PUT_AWAY
        end
    elseif self.isCooldownActive ~= true and not collectibleData:IsBlocked() then
        if collectibleData:IsCategoryType(COLLECTIBLE_CATEGORY_TYPE_MEMENTO) then
            textEnum = SI_COLLECTIBLE_ACTION_USE
        else
            textEnum = SI_COLLECTIBLE_ACTION_SET_ACTIVE
        end
    end
    return textEnum
end

function Collectible:ShowCollectibleMenu()
    local collectibleData = self.collectibleData
    if collectibleData then
        ClearMenu()

        local collectibleId = collectibleData:GetId()

        --Use
        if collectibleData:IsUsable() then
            local textEnum = self:GetInteractionTextEnum()
            if textEnum then
                AddMenuItem(GetString(textEnum), function() UseCollectible(collectibleId) end)
            end
        end

        if IsChatSystemAvailableForCurrentPlatform() then
            --Link in chat
            local link = GetCollectibleLink(collectibleId, LINK_STYLE_BRACKETS)
            AddMenuItem(GetString(SI_ITEM_ACTION_LINK_TO_CHAT), function() ZO_LinkHandler_InsertLink(zo_strformat(SI_TOOLTIP_ITEM_NAME, link)) end)
        end

        --Rename
        if collectibleData:IsRenameable() then
            AddMenuItem(GetString(SI_COLLECTIBLE_ACTION_RENAME), ZO_CollectionsBook.GetShowRenameDialogClosure(collectibleId))
        end

        ShowMenu(self.control)
    end
end

local g_keybindUseCollectible = {
    name = nil,
    keybind = "UI_SHORTCUT_PRIMARY",
    callback = nil,
}

local g_keybindRenameCollectible = {
    name = GetString(SI_COLLECTIBLE_ACTION_RENAME),
    keybind = "UI_SHORTCUT_SECONDARY",
    callback = nil,
}

function Collectible:ShowKeybinds()
    local function UpdateKeybind(keybind)
        if KEYBIND_STRIP:HasKeybindButton(keybind) then
            KEYBIND_STRIP:UpdateKeybindButton(keybind)
        else
            KEYBIND_STRIP:AddKeybindButton(keybind)
        end
    end

    local collectibleData = self.collectibleData
    local collectibleId = collectibleData:GetId()

    if collectibleData:IsUsable() then
        local textEnum = self:GetInteractionTextEnum()
        if textEnum then
            g_keybindUseCollectible.name = GetString(textEnum)
            g_keybindUseCollectible.callback = function() UseCollectible(collectibleId) end
            UpdateKeybind(g_keybindUseCollectible)
        end
    end

    if collectibleData:IsRenameable() then
        g_keybindRenameCollectible.callback = ZO_CollectionsBook.GetShowRenameDialogClosure(collectibleId)

        UpdateKeybind(g_keybindRenameCollectible)
    end
end

function Collectible:HideKeybinds()
    KEYBIND_STRIP:RemoveKeybindButton(g_keybindUseCollectible)
    KEYBIND_STRIP:RemoveKeybindButton(g_keybindRenameCollectible)
end

do
    local SHOW_NICKNAME, SHOW_HINT, SHOW_BLOCK_REASON = true, true, true
    function Collectible:OnMouseEnter()
        if self.collectibleData then
            InitializeTooltip(ItemTooltip, self.control.parent, RIGHT, -5, 0, LEFT)
            ItemTooltip:SetCollectible(self.collectibleData:GetId(), SHOW_NICKNAME, SHOW_HINT, SHOW_BLOCK_REASON)
            g_currentMouseTarget = self
            self:ShowKeybinds()
            self:RefreshMouseoverVisuals()
        end
    end

    function Collectible:RefreshTooltip()
        if self:IsCurrentMouseTarget() then
            ClearTooltip(ItemTooltip)
            InitializeTooltip(ItemTooltip, self.parentRow, RIGHT, -5, 0, LEFT)
            ItemTooltip:SetCollectible(self.collectibleData:GetId(), SHOW_NICKNAME, SHOW_HINT, SHOW_BLOCK_REASON)
        end
    end
end

function Collectible:OnMouseExit()
    local collectibleData = self.collectibleData
    if collectibleData then
        ClearTooltip(ItemTooltip)
        self:HideKeybinds()
        g_currentMouseTarget = nil
        self:RefreshMouseoverVisuals()

        if collectibleData:GetNotificationId() then
            RemoveCollectibleNotification(collectibleData:GetNotificationId())
        end

        if collectibleData:IsNew() then
            ClearCollectibleNewStatus(collectibleData:GetId())
        end
    end
end

function Collectible:RefreshMouseoverVisuals(dontAnimate)
    local areVisualsHidden = not self:IsCurrentMouseTarget()
    self:SetHighlightHidden(areVisualsHidden, dontAnimate)
    if self.collectibleData and self.collectibleData:IsPurchasable() then
        self.control.cornerTag:SetHidden(areVisualsHidden)
    end
end

function Collectible:IsCurrentMouseTarget()
    return g_currentMouseTarget == self
end

function Collectible:OnClicked(button)
    if(button == MOUSE_BUTTON_INDEX_RIGHT) then
        --TODO: Add open store bridge (if applicable)
        self:ShowCollectibleMenu()
    end
end

function Collectible:OnMouseDoubleClick(button)
    if(button == MOUSE_BUTTON_INDEX_LEFT) then
        local collectibleData = self.collectibleData
        if collectibleData and collectibleData:IsUsable() then
            UseCollectible(collectibleData:GetId())
        end
    end
end

function Collectible:OnEffectivelyHidden()
    self:HideKeybinds()
end

function Collectible:OnUpdate()
    if self.collectibleData and self.collectibleData:IsUsable() and self.isCooldownActive then
        self:UpdateCooldownEffect()
    end
end

function Collectible:OnUpdateCooldowns()
    local collectibleData = self.collectibleData
    if collectibleData and collectibleData:IsUsable() then
        local remaining, duration = GetCollectibleCooldownAndDuration(collectibleData:GetId())
        if remaining > 0 and duration > 0 then
            self.cooldownDuration = duration
            self.cooldownStartTime = GetFrameTimeMilliseconds() - (duration - remaining)
            self:BeginCooldown()
            return
        end
    end

    self:EndCooldown()
end

function Collectible:BeginCooldown()
    local control = self.control
    self.isCooldownActive = true
    control.cooldownIcon:SetHidden(false)
    control.cooldownIconDesaturated:SetHidden(false)
    control.cooldownTime:SetHidden(false)
    control.cooldownEdge:SetHidden(false)
    self:SetHighlightHidden(true)
    self:HideKeybinds()
end

function Collectible:EndCooldown()
    local control = self.control
    self.isCooldownActive = false
    control.cooldownIcon:SetTextureCoords(0, 1, 0, 1)
    control.cooldownIcon:SetHeight(self.maxIconHeight)
    control.cooldownIcon:SetHidden(true)
    control.cooldownIconDesaturated:SetHidden(true)
    control.cooldownTime:SetHidden(true)
    control.cooldownEdge:SetHidden(true)
    control.cooldownTime:SetText("")
    if self:IsCurrentMouseTarget() then
        self:ShowKeybinds()
        self:SetHighlightHidden(false)
    end
end

function Collectible:UpdateCooldownEffect()
    local duration = self.cooldownDuration
    local cooldown = self.cooldownStartTime + duration - GetFrameTimeMilliseconds()
    local percentCompleted = (1 - (cooldown / duration)) or 1
    local height = zo_ceil(self.maxIconHeight * percentCompleted)
    local textureCoord = 1 - (height / self.maxIconHeight)

    local control = self.control
    control.cooldownIcon:SetHeight(height)
    control.cooldownIcon:SetTextureCoords(0, 1, textureCoord, 1)

    if not self.collectibleData:IsActive() then
        local secondsRemaining = cooldown / 1000
        control.cooldownTime:SetText(ZO_FormatTimeAsDecimalWhenBelowThreshold(secondsRemaining))
    else
        control.cooldownTime:SetText("")
    end
end


--[[ Collection ]]--
--------------------
--[[ Initialization ]]--
------------------------
ZO_CollectionsBook = ZO_SortFilterList:Subclass()

function ZO_CollectionsBook:New(...)
    return ZO_SortFilterList.New(self, ...)
end

function ZO_CollectionsBook:Initialize(control)
    ZO_SortFilterList.Initialize(self, control)

    self.categoryNodeLookupData = {}

    self:InitializeControls()
    self:InitializeEvents()

    self.blankCollectibleObject = Collectible:New() --Used to blank out tile controls with no collectibleId
    self.collectibleObjectList = {}

    self:InitializeCategories()
    self:InitializeFilters(filterData)
    self:InitializeStickerGrid()

    self.control:SetHandler("OnUpdate", function() self.refreshGroups:UpdateRefreshGroups() end)

    self.scene = ZO_Scene:New("collectionsBook", SCENE_MANAGER)
    self.scene:RegisterCallback("StateChange",
        function(oldState, newState)
            if newState == SCENE_SHOWING then
                self.refreshGroups:UpdateRefreshGroups() --In case we need to rebuild the categories
                ZO_Scroll_ResetToTop(self.list)
                self:UpdateCollectionVisualLayer()
                COLLECTIONS_BOOK_SINGLETON:SetSearchString(self.contentSearchEditBox:GetText())
                COLLECTIONS_BOOK_SINGLETON:SetSearchCategorySpecializationFilters(COLLECTIBLE_CATEGORY_SPECIALIZATION_NONE)
                COLLECTIONS_BOOK_SINGLETON:SetSearchChecksHideWhenLocked(true)
            end
        end)

    self:UpdateCollection()

    SYSTEMS:RegisterKeyboardObject(ZO_COLLECTIONS_SYSTEM_NAME, self)
end

function ZO_CollectionsBook:InitializeControls()
    self.categoryFilterComboBox = self.control:GetNamedChild("Filter")
    self.contentSearchEditBox = self.control:GetNamedChild("SearchBox")
    self.scrollbar = self.list:GetNamedChild("ScrollBar")
    self.noMatches = self.control:GetNamedChild("NoMatchMessage")
end

function ZO_CollectionsBook:InitializeEvents()
    local function OnUpdateSearchResults()
        if self.scene:IsShowing() then
            self:UpdateCollection()
        end
    end

    self.control:RegisterForEvent(EVENT_VISUAL_LAYER_CHANGED, function() self:UpdateCollectionVisualLayer() end)

    COLLECTIONS_BOOK_SINGLETON:RegisterCallback("UpdateSearchResults", OnUpdateSearchResults)
    ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("OnCollectibleUpdated", function(...) self:OnCollectibleUpdated(...) end)
    ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("OnCollectionUpdated", function() self:OnCollectionUpdated() end)
    ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("OnCollectibleNewStatusCleared", function(...) self:OnCollectibleNewStatusCleared(...) end)

    self.refreshGroups = ZO_Refresh:New()
    self.refreshGroups:AddRefreshGroup("FullUpdate",
    {
        RefreshAll = function()
            self:UpdateCollection()
        end,
    })

    self.refreshGroups:AddRefreshGroup("CollectibleUpdated",
    {
        RefreshSingle = function(collectibleId)
            self:UpdateCollectible(collectibleId)
        end,
    })
end

do
    local FILTER_DATA = 
    {
        SI_COLLECTIONS_BOOK_FILTER_SHOW_ALL,
        SI_COLLECTIONS_BOOK_FILTER_SHOW_LOCKED,
        SI_COLLECTIONS_BOOK_FILTER_SHOW_USABLE,
        SI_COLLECTIONS_BOOK_FILTER_SHOW_UNLOCKED,
    }

    function ZO_CollectionsBook:InitializeFilters(startingStringId)
        local comboBox = ZO_ComboBox_ObjectFromContainer(self.categoryFilterComboBox)
        comboBox:SetSortsItems(false)
        comboBox:SetFont("ZoFontWinT1")
        comboBox:SetSpacing(4)
    
        local function OnFilterChanged(comboBox, entryText, entry)
            self.categoryFilterComboBox.filterType = entry.filterType
            local categoryData = self.categoryTree:GetSelectedData()
            if categoryData then
                self:BuildContentList(categoryData, DONT_RETAIN_SCROLL_POSITION)
            end
        end

        for i, stringId in ipairs(FILTER_DATA) do
            local entry = comboBox:CreateItemEntry(GetString(stringId), OnFilterChanged)
            entry.filterType = stringId
            comboBox:AddItem(entry)
        end

        comboBox:SelectFirstItem()
    end
end

do
    local CHILD_INDENT = 76
    local CHILD_SPACING = 0

    function ZO_CollectionsBook:InitializeCategories()
        local control = self.control
        self.categories = control:GetNamedChild("Categories")
        self.categoryTree = ZO_Tree:New(self.categories:GetNamedChild("ScrollChild"), 60, -10, 300)

        local function BaseTreeHeaderIconSetup(control, categoryData, open)
            local normalIcon, pressedIcon, mouseoverIcon = categoryData:GetKeyboardIcons()
            control.icon:SetTexture(open and pressedIcon or normalIcon)
            control.iconHighlight:SetTexture(mouseoverIcon)

            ZO_IconHeader_Setup(control, open)
        end

        local function BaseTreeHeaderSetup(node, control, categoryData, open)
            control.text:SetModifyTextType(MODIFY_TEXT_TYPE_UPPERCASE)
            control.text:SetText(categoryData:GetFormattedName())
            BaseTreeHeaderIconSetup(control, categoryData, open)
        end

        local function TreeHeaderSetup_Child(node, control, categoryData, open, userRequested)
            BaseTreeHeaderSetup(node, control, categoryData, open)

            if(open and userRequested) then
                self.categoryTree:SelectFirstChild(node)
            end
        end

        local function TreeHeaderSetup_Childless(node, control, categoryData, open)
            BaseTreeHeaderSetup(node, control, categoryData, open)
        end

        local function TreeEntryOnSelected(control, categoryData, selected, reselectingDuringRebuild)
            control:SetSelected(selected)

            if selected then
                self:BuildContentList(categoryData, DONT_RETAIN_SCROLL_POSITION)
            end
        end

        local function TreeEntryOnSelected_Childless(control, categoryData, selected, reselectingDuringRebuild)
            TreeEntryOnSelected(control, categoryData, selected, reselectingDuringRebuild)
            BaseTreeHeaderIconSetup(control, categoryData, selected)
        end

        local function TreeEntrySetup(node, control, categoryData, open)
            control:SetSelected(false)
            control:SetText(categoryData:GetFormattedName())
        end

        self.categoryTree:AddTemplate("ZO_StatusIconHeader", TreeHeaderSetup_Child, nil, nil, CHILD_INDENT, CHILD_SPACING)
        self.categoryTree:AddTemplate("ZO_StatusIconChildlessHeader", TreeHeaderSetup_Childless, TreeEntryOnSelected_Childless)
        self.categoryTree:AddTemplate("ZO_TreeStatusLabelSubCategory", TreeEntrySetup, TreeEntryOnSelected)

        self.categoryTree:SetExclusive(true)
        self.categoryTree:SetOpenAnimation("ZO_TreeOpenAnimation")
    end
end

function ZO_CollectionsBook:InitializeStickerGrid()
    local function SetupRow(control, data)
        for i = 1, COLLECTIBLE_STICKER_ROW_STRIDE do
            local stickerControl = control:GetNamedChild("Sticker" .. i)

            local id = data[i]
            local collectibleObject
            if id then
                collectibleObject = self.collectibleObjectList[id]
                if not collectibleObject then
                    collectibleObject = Collectible:New(id)
                    self.collectibleObjectList[id] = collectibleObject
                end
            else
                collectibleObject = self.blankCollectibleObject
            end
            collectibleObject:Show(stickerControl)
        end
    end

    ZO_ScrollList_AddDataType(self.list, STICKER_ROW_DATA, "ZO_CollectibleStickerRow", ZO_COLLECTIBLE_STICKER_ROW_HEIGHT, SetupRow)
end

--[[ Refresh ]]--
-----------------

function ZO_CollectionsBook:BuildCategories()
    self.categoryTree:Reset()
    ZO_ClearTable(self.categoryNodeLookupData)
        
    local function AddCategoryByCategoryIndex(categoryIndex)
        local categoryData = ZO_COLLECTIBLE_DATA_MANAGER:GetCategoryDataByIndicies(categoryIndex)
        --Some categories are handled by specialized scenes.
        if categoryData:IsStandardCategory() then
            self:AddTopLevelCategory(categoryData)
        end
    end

    local searchResults = COLLECTIONS_BOOK_SINGLETON:GetSearchResults()
    if searchResults then
        for categoryIndex, data in pairs(searchResults) do
            AddCategoryByCategoryIndex(categoryIndex)
        end
    else
        for categoryIndex, categoryData in ZO_COLLECTIBLE_DATA_MANAGER:CategoryIterator(ZO_CollectibleCategoryData.HasShownCollectiblesInCollection) do
            AddCategoryByCategoryIndex(categoryIndex)
        end
    end
    self.categoryTree:Commit()

    self:UpdateAllCategoryStatusIcons()
end

do
    function ZO_CollectionsBook:AddTopLevelCategory(categoryData)
        local searchResults = COLLECTIONS_BOOK_SINGLETON:GetSearchResults()

        if not searchResults then
            local hasChildren = categoryData:GetNumSubcategories() > 0
            local nodeTemplate = hasChildren and "ZO_StatusIconHeader" or "ZO_StatusIconChildlessHeader"

            local parentNode = self:AddCategory(nodeTemplate, categoryData)
        
            for subcategoryIndex, subcategoryData in categoryData:SubcategoryIterator(ZO_CollectibleCategoryData.HasShownCollectiblesInCollection) do
                self:AddCategory("ZO_TreeStatusLabelSubCategory", subcategoryData, parentNode)
            end
        else
            local categoryIndex = categoryData:GetCategoryIndicies()
            local hasChildren = NonContiguousCount(searchResults[categoryIndex]) > 1 or searchResults[categoryIndex][ZO_COLLECTIONS_SEARCH_ROOT] == nil
            local nodeTemplate = hasChildren and "ZO_StatusIconHeader" or "ZO_StatusIconChildlessHeader"

            local parentNode = self:AddCategory(nodeTemplate, categoryData)
        
            for subcategoryIndex, data in pairs(searchResults[categoryIndex]) do
                if subcategoryIndex ~= ZO_COLLECTIONS_SEARCH_ROOT then
                    local subcategoryData = ZO_COLLECTIBLE_DATA_MANAGER:GetCategoryDataByIndicies(categoryIndex, subcategoryIndex)
                    self:AddCategory("ZO_TreeStatusLabelSubCategory", subcategoryData, parentNode)
                end
            end
        end
    end
end

function ZO_CollectionsBook:AddCategory(nodeTemplate, categoryData, parentNode)
    local soundId = parentNode and SOUNDS.JOURNAL_PROGRESS_SUB_CATEGORY_SELECTED or SOUNDS.JOURNAL_PROGRESS_CATEGORY_SELECTED
    local node = self.categoryTree:AddNode(nodeTemplate, categoryData, parentNode, soundId)
    self.categoryNodeLookupData[categoryData:GetId()] = node
    return node
end

function ZO_CollectionsBook:UpdateCategoryStatus(categoryNode)
    local categoryData = categoryNode.data
    
    if categoryData:IsSubcategory() then
        self:UpdateCategoryStatusIcon(categoryNode:GetParent())
    end

    self:UpdateCategoryStatusIcon(categoryNode)
end

function ZO_CollectionsBook:UpdateAllCategoryStatusIcons()
    for _, categoryNode in pairs(self.categoryNodeLookupData) do
        self:UpdateCategoryStatusIcon(categoryNode)
    end
end

function ZO_CollectionsBook:UpdateCategoryStatusIcon(categoryNode)
    local categoryData = categoryNode.data
    local categoryControl = categoryNode.control

    if not categoryControl.statusIcon then
        categoryControl.statusIcon = categoryControl:GetNamedChild("StatusIcon")
    end

    categoryControl.statusIcon:ClearIcons()

    if categoryData:HasAnyNewCollectibles() then
        categoryControl.statusIcon:AddIcon(ZO_KEYBOARD_NEW_ICON)
    end

    local collectiblesData = self:GetCollectiblesData(categoryData)
    for _, collectibleData in ipairs(collectiblesData) do
        if collectibleData:IsVisualLayerShowing() then
            categoryControl.statusIcon:AddIcon(VISIBLE_ICON)
            break
        end
    end

    categoryControl.statusIcon:Show()
end

function ZO_CollectionsBook:GetCollectiblesData(categoryData)
    local collectiblesData = {}

    local searchResults = COLLECTIONS_BOOK_SINGLETON:GetSearchResults()
    local searchResultsSubcategory = nil
    if searchResults then
        local categoryIndex, subcategoryIndex = categoryData:GetCategoryIndicies()
        local categoryResults = searchResults[categoryIndex]
        if categoryResults then
            local effectiveSubcategoryIndex = subcategoryIndex or ZO_COLLECTIONS_SEARCH_ROOT
            searchResultsSubcategory = categoryResults[effectiveSubcategoryIndex]
        end
    end

    for collectibleIndex, collectibleData in categoryData:CollectibleIterator(ZO_CollectibleData.IsShownInCollection) do
        if not searchResultsSubcategory or searchResultsSubcategory[collectibleIndex] then
            table.insert(collectiblesData, collectibleData)
        end
    end

    return collectiblesData
end

function ZO_CollectionsBook:BuildContentList(categoryData, retainScrollPosition)
    local position = self.scrollbar:GetValue()
    self:LayoutCollection(unpack(self:GetCollectiblesData(categoryData)))
        
    if retainScrollPosition then
        self.scrollbar:SetValue(position)

        if(g_currentMouseTarget ~= nil) then
            g_currentMouseTarget:OnMouseExit()
        end

        local mouseOverControl = WINDOW_MANAGER:GetMouseOverControl()
        if (mouseOverControl and not mouseOverControl:IsHidden() and mouseOverControl.collectible) then
            mouseOverControl.collectible:OnMouseEnter()
        end
    end
end

do
    local function ShouldAddCollectible(filterType, collectibleData)
        if collectibleData:IsPlaceholder() then
            return false
        else
            if filterType == SI_COLLECTIONS_BOOK_FILTER_SHOW_ALL then
                return true
            end

            if collectibleData:IsUnlocked() then
                if filterType == SI_COLLECTIONS_BOOK_FILTER_SHOW_UNLOCKED then
                    return true
                elseif filterType == SI_COLLECTIONS_BOOK_FILTER_SHOW_USABLE then
                    return collectibleData:IsValidForPlayer()
                else
                    return false
                end
            else
                return filterType == SI_COLLECTIONS_BOOK_FILTER_SHOW_LOCKED
            end
        end
    end

    function ZO_CollectionsBook:LayoutCollection(...)
        ZO_Scroll_ResetToTop(self.list)
        local scrollData = ZO_ScrollList_GetDataList(self.list)
        ZO_ClearNumericallyIndexedTable(scrollData)

        local rowData = {}
        for currentIndex = 1, select("#", ...) do
            local collectibleData = select(currentIndex, ...)
            if ShouldAddCollectible(self.categoryFilterComboBox.filterType, collectibleData) then
                table.insert(rowData, collectibleData:GetId())
                if #rowData == COLLECTIBLE_STICKER_ROW_STRIDE then
                    table.insert(scrollData, ZO_ScrollList_CreateDataEntry(STICKER_ROW_DATA, rowData))
                    rowData = {}
                end
            end
        end

        if #rowData > 0 then
            table.insert(scrollData, ZO_ScrollList_CreateDataEntry(STICKER_ROW_DATA, rowData))
        end

        --Fill out the rest of the grid
        local minRows = zo_floor(self.list:GetHeight() / (ZO_COLLECTIBLE_STICKER_SINGLE_HEIGHT + ZO_COLLECTIBLE_PADDING))
        for i = #scrollData + 1, minRows do
            table.insert(scrollData, ZO_ScrollList_CreateDataEntry(STICKER_ROW_DATA, {}))
        end

        self:CommitScrollList()
    end
end

function ZO_CollectionsBook:OnCollectionUpdated()
    self:UpdateCollectionLater()
end

function ZO_CollectionsBook:UpdateCollectionLater()
    self.refreshGroups:RefreshAll("FullUpdate")
end

function ZO_CollectionsBook:UpdateCollection()
    self:BuildCategories()
    local searchResults = COLLECTIONS_BOOK_SINGLETON:GetSearchResults()
    local foundNoMatches = searchResults and NonContiguousCount(searchResults) == 0
    self.categoryFilterComboBox:SetHidden(foundNoMatches)
    self.noMatches:SetHidden(not foundNoMatches)
    self.list:SetHidden(foundNoMatches)
end

function ZO_CollectionsBook:OnCollectibleUpdated(collectibleId)
    self.refreshGroups:RefreshSingle("CollectibleUpdated", collectibleId)
    MAIN_MENU_KEYBOARD:RefreshCategoryBar()
    MAIN_MENU_KEYBOARD:UpdateSceneGroupButtons("collectionsSceneGroup")
end

function ZO_CollectionsBook:UpdateCollectible(collectibleId)
    local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(collectibleId)
    if collectibleData then
        local categoryData = collectibleData:GetCategoryData()
        local categoryNode = self.categoryNodeLookupData[categoryData:GetId()]
        if categoryNode then
            self:UpdateCategoryStatus(categoryNode)

            local selectedCategoryData = self.categoryTree:GetSelectedData()
            if categoryData == selectedCategoryData  then
                self:BuildContentList(categoryData, RETAIN_SCROLL_POSITION)
            end
        else
            self:UpdateCollection()
        end
    end
end

function ZO_CollectionsBook:OnCollectibleStatusUpdated(collectibleId)
    self.refreshGroups:RefreshSingle("CollectibleUpdated", collectibleId)
    MAIN_MENU_KEYBOARD:RefreshCategoryBar()
    MAIN_MENU_KEYBOARD:UpdateSceneGroupButtons("collectionsSceneGroup")
end

function ZO_CollectionsBook:OnCollectibleNewStatusCleared(collectibleId)
    self:OnCollectibleStatusUpdated(collectibleId)
end

function ZO_CollectionsBook:BrowseToCollectible(collectibleId)
    self.refreshGroups:UpdateRefreshGroups() --In case we need to rebuild the categories before we select a category

    local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(collectibleId)
    if collectibleData then
        local categoryData = collectibleData:GetCategoryData()
        if categoryData then
            if categoryData:IsDLCCategory() then
                DLC_BOOK_KEYBOARD:BrowseToCollectible(collectibleId)
            elseif categoryData:IsHousingCategory() then
                HOUSING_BOOK_KEYBOARD:BrowseToCollectible(collectibleId)
            elseif categoryData:IsOutfitStylesCategory() then
                ZO_OUTFIT_STYLES_BOOK_KEYBOARD:NavigateToCollectibleData(collectibleData)
            else
                --Select the category or subcategory of the collectible
                local categoryNode = self.categoryNodeLookupData[categoryData:GetId()]
                if categoryNode then
                    self.categoryTree:SelectNode(categoryNode)
                end

                --TODO: Scroll the collectibles list to show the collectible

                MAIN_MENU_KEYBOARD:ToggleSceneGroup("collectionsSceneGroup", "collectionsBook")
            end
        end
    end
end

function ZO_CollectionsBook:UpdateCollectionVisualLayer()
    self:RefreshVisible()
    self:UpdateAllCategoryStatusIcons()
end

function ZO_CollectionsBook.GetShowRenameDialogClosure(collectibleId)
    return function() ZO_CollectionsBook.ShowRenameDialog(collectibleId) end
end

function ZO_CollectionsBook.ShowRenameDialog(collectibleId)
    if collectibleId ~= 0 then
	    local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(collectibleId)
	    if collectibleData then
		    local nickname = collectibleData:GetNickname()
            ZO_Dialogs_ShowDialog("COLLECTIONS_INVENTORY_RENAME_COLLECTIBLE", { collectibleId = collectibleId }, { initialEditText = nickname })
        end
    end
end

--[[Global functions]]--
------------------------

function ZO_CollectionsBook_OnInitialize(control)
    COLLECTIONS_BOOK = ZO_CollectionsBook:New(control)
end

function ZO_CollectionsBook_OnSearchTextChanged(editBox)
    ZO_EditDefaultText_OnTextChanged(editBox)
    COLLECTIONS_BOOK_SINGLETON:SetSearchString(editBox:GetText())
end