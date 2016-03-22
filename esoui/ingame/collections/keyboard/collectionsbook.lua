local MAX_SUMMARY_CATEGORIES = 10
local SUMMARY_CATEGORY_BAR_HEIGHT = 16
local SUMMARY_CATEGORY_PADDING = 50
local COLLECTIBLE_PADDING = 10
local COLLECTIBLE_STICKER_SINGLE_WIDTH = 170
local COLLECTIBLE_STICKER_SINGLE_HEIGHT = 125
local COLLECTIBLE_STICKER_ROW_STRIDE = 3
local MAX_COLLECTIBLE_ROW_WIDTH = (COLLECTIBLE_STICKER_SINGLE_WIDTH + COLLECTIBLE_PADDING) * COLLECTIBLE_STICKER_ROW_STRIDE
local RETAIN_SCROLL_POSITION = true
local DONT_RETAIN_SCROLL_POSITION = true
local ACTIVE_ICON = "EsoUI/Art/Inventory/inventory_icon_equipped.dds"
local NOTIFICATIONS_PROVIDER = NOTIFICATIONS:GetCollectionsProvider()

--Descriptive defaults for readibility in function calls
local FORCE_HIDE_PROGRESS_TEXT = true
local DONT_HIDE_LOCKED = false

local function GetTextColor(enabled, normalColor, disabledColor)
    if enabled then
        return (normalColor or ZO_NORMAL_TEXT):UnpackRGBA()
    end
    return (disabledColor or ZO_DISABLED_TEXT):UnpackRGBA()
end

local function ApplyTextColorToLabel(label, ...)
    label:SetColor(GetTextColor(...))
end

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

function Collectible:Initialize(control, gridDimensions)
    control.collectible = self
    self.control = control
    self.gridDimensions = gridDimensions

    self.title = control:GetNamedChild("Title")
    self.highlight = control:GetNamedChild("Highlight")
    self.icon = control:GetNamedChild("Icon")
    self.multiIcon = control:GetNamedChild("MultiIcon")
    self.cornerTag = control:GetNamedChild("CornerTag")
    
    self.cooldownIcon = control:GetNamedChild("CooldownIcon")
    self.cooldownIconDesaturated = control:GetNamedChild("CooldownIconDesaturated")
    self.cooldownTime = control:GetNamedChild("CooldownTime")
    self.cooldownEdge = control:GetNamedChild("CooldownEdge")
    self.isCooldownActive = false
    self.maxIconHeight = self.icon:GetHeight()
    self.cooldownDuration = 0
    self.cooldownStartTime = 0

    self.iconAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("JournalProgressIconSlotMouseOverAnimation", self.icon)
    
    COLLECTIONS_BOOK_SINGLETON:RegisterCallback("OnUpdateCooldowns", function(...) self:OnUpdateCooldowns(...) end)
end

function Collectible:Show(collectibleId, previousControl)
    self.collectibleId = collectibleId
    local name, description, icon, lockedIcon, unlocked, purchasable, isActive, categoryType = self:GetCollectibleInfo()
    local effectiveIcon = unlocked and icon or lockedIcon
    
    self.unlocked = unlocked
    self.purchasable = purchasable
    self.title:SetText(zo_strformat(SI_COLLECTIBLE_NAME_FORMATTER, name))
    self.icon:SetTexture(effectiveIcon)
    ApplyTextColorToLabel(self.title, unlocked, ZO_NORMAL_TEXT, ZO_DISABLED_TEXT)
    
    self.cooldownIcon:SetTexture(effectiveIcon)
    self.cooldownIconDesaturated:SetTexture(effectiveIcon)
    self.cooldownIconDesaturated:SetDesaturation(1)
    self.cooldownTime:SetText("")

    self.title:SetHidden(false)
    self.icon:SetHidden(false)
    self:SetAnchor(previousControl)
    self.control:SetHidden(false)

    self.categoryType = categoryType
    
    self.active = isActive
    self:RefreshMultiIcon()
    self:SetBlockedState(IsCollectibleCategoryBlocked(categoryType))

    self.isUsable = IsCollectibleUsable(collectibleId)

    if self.isCurrentMouseTarget then
        self:ShowKeybinds()
    end

    self:OnUpdateCooldowns()
end

function Collectible:RefreshMultiIcon()
    self.multiIcon:ClearIcons()

    if self.active then
       self.multiIcon:AddIcon(ACTIVE_ICON)
    end

    self.notificationId = NOTIFICATIONS_PROVIDER:GetNotificationIdForCollectible(self.collectibleId)
    if self.notificationId then
        self.multiIcon:AddIcon(ZO_KEYBOARD_NEW_ICON)
    end

    self.multiIcon:Show()
end

function Collectible:ShowBlank(previousControl)
    self.collectibleId = nil
    self.purchasable = false
    self.title:SetHidden(true)
    self.icon:SetHidden(true)
    self:SetAnchor(previousControl)
    self.control:SetHidden(false)
    self.multiIcon:ClearIcons()
    self.cornerTag:SetHidden(true)
    if self.isCooldownActive then
        self:EndCooldown()
    end
end

function Collectible:GetId()
    return self.collectibleId
end

function Collectible:GetCollectibleInfo()
    return GetCollectibleInfo(self.collectibleId)
end

function Collectible:SetAnchor(previousControl)
    self.control:ClearAnchors()
    local width = self.control:GetWidth()
    local height = self.control:GetHeight()
    if not previousControl then
        self.control:SetAnchor(TOPLEFT, nil, TOPLEFT, COLLECTIBLE_PADDING, 0)
        self.right = width + COLLECTIBLE_PADDING
        self.bottom = height
    else
        --We assume that collectibles will be sorted largest to smallest, to avoid weird Tetris combinations
        if previousControl.right + width > MAX_COLLECTIBLE_ROW_WIDTH then
            self.control:SetAnchor(TOPLEFT, nil, TOPLEFT, COLLECTIBLE_PADDING, previousControl.bottom + COLLECTIBLE_PADDING)
            self.right = width + COLLECTIBLE_PADDING
            self.bottom = previousControl.bottom + height + COLLECTIBLE_PADDING
        else
            self.control:SetAnchor(TOPLEFT, previousControl.control, TOPRIGHT, COLLECTIBLE_PADDING, 0)
            self.right = previousControl.right + width + COLLECTIBLE_PADDING
            self.bottom = previousControl.bottom
        end
    end
end

function Collectible:GetControl()
    return self.control
end

function Collectible:Reset()
    self.control:SetHidden(true)
end

function Collectible:SetHighlightHidden(hidden)
    self.highlight:SetHidden(false) -- let alpha take care of the actual hiding
    if not self.highlightAnimation then
        self.highlightAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("JournalProgressHighlightAnimation", self.highlight)
    end

    if(hidden) then
        ApplyTextColorToLabel(self.title, self.unlocked, ZO_NORMAL_TEXT, ZO_DISABLED_TEXT)
        self.iconAnimation:PlayBackward()
        self.highlightAnimation:PlayBackward()
    else
        ApplyTextColorToLabel(self.title, self.unlocked, ZO_HIGHLIGHT_TEXT, ZO_SELECTED_TEXT)
        self.highlightAnimation:PlayForward()
        if self.isCooldownActive ~= true then
            self.iconAnimation:PlayForward()
        end
    end
end

function Collectible:GetInteractionTextEnum()
    local textEnum
    if self.isCooldownActive ~= true and self.isBlocked ~= true then
        if self.categoryType == COLLECTIBLE_CATEGORY_TYPE_TROPHY then
            textEnum = SI_COLLECTIBLE_ACTION_USE
        elseif self.active then
            if self.categoryType == COLLECTIBLE_CATEGORY_TYPE_VANITY_PET or self.categoryType == COLLECTIBLE_CATEGORY_TYPE_ASSISTANT then
                textEnum = SI_COLLECTIBLE_ACTION_DISMISS
            else
                textEnum = SI_COLLECTIBLE_ACTION_PUT_AWAY
            end
        else
            textEnum = SI_COLLECTIBLE_ACTION_SET_ACTIVE
        end
    end
    return textEnum
end

function Collectible:ShowCollectibleMenu()
    local collectibleId = self.collectibleId
    if not collectibleId then
        return
    end

    ClearMenu()

    --Use
    if self.isUsable then
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
    if IsCollectibleRenameable(collectibleId) then
        AddMenuItem(GetString(SI_COLLECTIBLE_ACTION_RENAME), function() ZO_Dialogs_ShowDialog("COLLECTIONS_INVENTORY_RENAME_COLLECTIBLE", { collectibleId = collectibleId }) end)
    end

    ShowMenu(self.control)
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

    if self.isUsable then
        local textEnum = self:GetInteractionTextEnum()
        if textEnum then
            g_keybindUseCollectible.name = GetString(textEnum)
            g_keybindUseCollectible.callback = function() UseCollectible(self.collectibleId) end
            UpdateKeybind(g_keybindUseCollectible)
        end
    end

    if IsCollectibleRenameable(self.collectibleId) then
        g_keybindRenameCollectible.callback = function() ZO_Dialogs_ShowDialog("COLLECTIONS_INVENTORY_RENAME_COLLECTIBLE", { collectibleId = self.collectibleId }) end

        UpdateKeybind(g_keybindRenameCollectible)
    end
end

function Collectible:HideKeybinds()
    KEYBIND_STRIP:RemoveKeybindButton(g_keybindUseCollectible)
    KEYBIND_STRIP:RemoveKeybindButton(g_keybindRenameCollectible)
end

function Collectible:OnMouseEnter()
    if self.collectibleId then
        self:SetHighlightHidden(false)
        InitializeTooltip(ItemTooltip, self.control, RIGHT, -5, 0, LEFT)
        ItemTooltip:SetCollectible(self.collectibleId, true)
        self.isCurrentMouseTarget = true
        self:ShowKeybinds()
        if self.purchasable then
            self.cornerTag:SetHidden(false)
        end
    end
end

function Collectible:OnMouseExit()
    if self.collectibleId then
        self:SetHighlightHidden(true)
        ClearTooltip(ItemTooltip)
        self:HideKeybinds()
        self.isCurrentMouseTarget = false
        if self.purchasable then
            self.cornerTag:SetHidden(true)
        end

        if self.notificationId then
            RemoveCollectibleNotification(self.notificationId)
        end
    end
end

function Collectible:OnClicked(button)
    if(button == MOUSE_BUTTON_INDEX_RIGHT) then
        --TODO: Add open store bridge (if applicable)
        self:ShowCollectibleMenu()
    end
end

function Collectible:OnMouseDoubleClick(button)
    if(button == MOUSE_BUTTON_INDEX_LEFT) then
        if self.collectibleId and self.isUsable then
            UseCollectible(self.collectibleId)
        end
    end
end

function Collectible:OnEffectivelyHidden()
    self:HideKeybinds()
end

function Collectible:OnUpdate()
    if self.isUsable and self.isCooldownActive then
        self:UpdateCooldownEffect()
    end
end

function Collectible:OnUpdateCooldowns()
    if self.isUsable then
        local remaining, duration = GetCollectibleCooldownAndDuration(self.collectibleId)
        if remaining > 0 and duration > 0 then
            if self.isCooldownActive == false then
                self.cooldownDuration = duration
                self.cooldownStartTime = GetFrameTimeMilliseconds() - (duration - remaining)
                self:BeginCooldown()
            end
        elseif self.isCooldownActive == true then
           self:EndCooldown()
        end
    elseif self.isCooldownActive == true then
        self:EndCooldown()
    end
end

function Collectible:BeginCooldown()
    self.isCooldownActive = true
    self.cooldownIcon:SetHidden(false)
    self.cooldownIconDesaturated:SetHidden(false)
    self.cooldownTime:SetHidden(false)
    self.cooldownEdge:SetHidden(false)
    self:SetHighlightHidden(true)
    self:HideKeybinds()
end

function Collectible:EndCooldown()
    self.isCooldownActive = false
    self.cooldownIcon:SetTextureCoords(0, 1, 0, 1)
    self.cooldownIcon:SetHeight(self.maxIconHeight)
    self.cooldownIcon:SetHidden(true)
    self.cooldownIconDesaturated:SetHidden(true)
    self.cooldownTime:SetHidden(true)
    self.cooldownEdge:SetHidden(true)
    self.cooldownTime:SetText("")
    if self.isCurrentMouseTarget then
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

    self.cooldownIcon:SetHeight(height)
    self.cooldownIcon:SetTextureCoords(0, 1, textureCoord, 1)

    if not self.active then
        local secondsRemaining = cooldown / 1000
        if (secondsRemaining < 10) then
            self.cooldownTime:SetText(ZO_FormatTime(secondsRemaining, TIME_FORMAT_STYLE_DESCRIPTIVE_MINIMAL_SHOW_TENTHS_SECS, TIME_FORMAT_PRECISION_TENTHS, TIME_FORMAT_DIRECTION_DESCENDING))
        else
            self.cooldownTime:SetText(ZO_FormatTimeLargestTwo(secondsRemaining, TIME_FORMAT_STYLE_DESCRIPTIVE_MINIMAL))
        end
    else
        self.cooldownTime:SetText("")
    end
end

function Collectible:SetBlockedState(isBlocked)
    local desaturation = isBlocked and 1 or 0
    self.icon:SetDesaturation(desaturation)
    self.highlight:SetDesaturation(desaturation)
    self.isBlocked = isBlocked
end

--[[ Collection ]]--
--------------------
--[[ Initialization ]]--
------------------------
local CollectionsBook = ZO_JournalProgressBook_Common:Subclass()

function CollectionsBook:New(...)
    return ZO_JournalProgressBook_Common.New(self, ...)
end

do
    local filterData = 
    {
        SI_COLLECTIONS_BOOK_FILTER_SHOW_ALL,
        SI_COLLECTIONS_BOOK_FILTER_SHOW_LOCKED,
        SI_COLLECTIONS_BOOK_FILTER_SHOW_UNLOCKED,
    }

    function CollectionsBook:Initialize(control)
        ZO_JournalProgressBook_Common.Initialize(self, control)

        self.searchString = ""
        self.searchResults = {}

        self:InitializeSummary(control)
        self:InitializeFilters(filterData)
        self:InitializeStickerGrid(control)

        self.control:SetHandler("OnUpdate", function() self.refreshGroups:UpdateRefreshGroups() end)

        local collectionsBookScene = ZO_Scene:New("collectionsBook", SCENE_MANAGER)
        collectionsBookScene:RegisterCallback("StateChange",
            function(oldState, newState)
                if newState == SCENE_SHOWN then
                    ZO_Scroll_ResetToTop(self.contentList)
                end
            end)

        self:UpdateCollection()

        SYSTEMS:RegisterKeyboardObject(ZO_COLLECTIONS_SYSTEM_NAME, self)
    end
end

function CollectionsBook:InitializeControls()
    ZO_JournalProgressBook_Common.InitializeControls(self)

    self.contentSearch = self.contents:GetNamedChild("Search")
    self.scrollbar = self.contentList:GetNamedChild("ScrollBar")
    self.noMatches = self.contents:GetNamedChild("NoMatchMessage")
end

function CollectionsBook:InitializeEvents()
    ZO_JournalProgressBook_Common.InitializeEvents(self)

    local SEARCH_DATA_STRIDE = 3

    local function UpdateSearchResults(...)
        ZO_ClearTable(self.searchResults)
        for i = 1, select("#", ...), SEARCH_DATA_STRIDE do
            local categoryIndex, subcategoryIndex, collectibleIndex = select(i, ...)
            if not self.searchResults[categoryIndex] then
                self.searchResults[categoryIndex] = {}
            end
            local effectiveSubCategory = subcategoryIndex or "root"
            if not self.searchResults[categoryIndex][effectiveSubCategory] then
                self.searchResults[categoryIndex][effectiveSubCategory] = {}
            end

            self.searchResults[categoryIndex][effectiveSubCategory][collectibleIndex] = true
        end
    end

    local function OnSearchResultsReady()
        UpdateSearchResults(GetCollectiblesSearchResults())
        self:UpdateCollection()
        if NonContiguousCount(self.searchResults) > 0 then
            local data = self.categoryTree:GetSelectedData()
            self:UpdateCategoryLabels(data, DONT_RETAIN_SCROLL_POSITION)
        end
    end

    self.control:RegisterForEvent(EVENT_COLLECTIBLES_SEARCH_RESULTS_READY, OnSearchResultsReady)

    COLLECTIONS_BOOK_SINGLETON:RegisterCallback("OnCollectibleUpdated", function(...) self:OnCollectibleUpdated(...) end)
    COLLECTIONS_BOOK_SINGLETON:RegisterCallback("OnCollectionUpdated", function(...) self:OnCollectionUpdated(...) end)
    COLLECTIONS_BOOK_SINGLETON:RegisterCallback("OnCollectionNotificationRemoved", function(...) self:OnCollectionNotificationRemoved(...) end)

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

function CollectionsBook:InitializeCategoryTemplates()
    self.parentCategoryTemplate = "ZO_CollectibleIconHeader"
    self.childlessCategoryTemplate = "ZO_CollectibleChildlessCategory"
    self.subCategoryTemplate = "ZO_CollectibleSubCategory"
end

function CollectionsBook:InitializeSummary(control)
    ZO_JournalProgressBook_Common.InitializeSummary(self, control, GetString(SI_COLLECTIONS_BOOK_OVERALL))
end

function CollectionsBook:InitializeStickerGrid(control)
    local function CreateSticker(objectPool)
        local collectibleSticker = ZO_ObjectPool_CreateControl("ZO_CollectableSticker", objectPool, self.contentListScrollChild)
        collectibleSticker.owner = self
        return Collectible:New(collectibleSticker, { 1, 1 }) --TODO: Implement stickers of varied dimensions in defs
    end
    
    local function ResetSticker(collectibleSticker)
        collectibleSticker:Reset()
    end

    self.collectibleStickerPool = ZO_ObjectPool:New(CreateSticker, ResetSticker)
end

--[[ Summary ]]--
-----------------
function CollectionsBook:ShowSummary(categoryContentList)
    ZO_JournalProgressBook_Common.ShowSummary(self)
end

function CollectionsBook:UpdateSummary()
    self.summaryStatusBarPool:ReleaseAllObjects()

    self:UpdateStatusBar(self.summaryTotal, nil, GetUnlockedCollectiblesCount(), GetTotalCollectiblesCount(), 0, nil, true)
        
    local numCategories = zo_min(self:GetNumCategories(), MAX_SUMMARY_CATEGORIES)

    local yOffset = SUMMARY_CATEGORY_PADDING
    for i = 1, numCategories do
        local name, _, numCollectibles, unlockedCollectibles, totalCollectibles = self:GetCategoryInfo(i)

        local statusBar = self.summaryStatusBarPool:AcquireObject()
        self:UpdateStatusBar(statusBar, zo_strformat(SI_COLLECTIBLE_NAME_FORMATTER, name), unlockedCollectibles, totalCollectibles, numCollectibles, DONT_HIDE_LOCKED, FORCE_HIDE_PROGRESS_TEXT)
        statusBar:ClearAnchors()

        if i % 2 == 0 then
            statusBar:SetAnchor(TOPRIGHT, self.summaryTotal, BOTTOMRIGHT, 0, yOffset)
            yOffset = yOffset + SUMMARY_CATEGORY_PADDING + SUMMARY_CATEGORY_BAR_HEIGHT
        else
            statusBar:SetAnchor(TOPLEFT, self.summaryTotal, BOTTOMLEFT, 0, yOffset)
        end
    end
end

--[[ Categories ]]--
--------------------
function CollectionsBook:GetNumCategories()
    return GetNumCollectibleCategories()
end

function CollectionsBook:GetCategoryInfo(categoryIndex)
    return GetCollectibleCategoryInfo(categoryIndex)
end

function CollectionsBook:GetCategoryIcons(categoryIndex)
    return GetCollectibleCategoryKeyboardIcons(categoryIndex)
end

function CollectionsBook:GetSubCategoryInfo(categoryIndex, i)
    return GetCollectibleSubCategoryInfo(categoryIndex, i)
end

--[[ Refresh ]]--
-----------------
function CollectionsBook:BuildCategories()
    --Per a design call, we're (temporarily?) removing progress indicators, so no summary blade
    self.categoryTree:Reset()
    self.nodeLookupData = {}
        
    local function AddCategoryByCategoryIndex(categoryIndex)
        local name, numSubCategories, _, _, _, hidesUnearned, categoryType = self:GetCategoryInfo(categoryIndex)
        --DLC is handled by the DLC book now
        if categoryType ~= COLLECTIBLE_CATEGORY_TYPE_DLC then
            local normalIcon, pressedIcon, mouseoverIcon = self:GetCategoryIcons(categoryIndex)
            self:AddTopLevelCategory(categoryIndex, zo_strformat(SI_COLLECTIBLE_NAME_FORMATTER, name), numSubCategories, hidesUnearned, normalIcon, pressedIcon, mouseoverIcon)
        end
    end

    if self.searchString == "" then
        for categoryIndex = 1, self:GetNumCategories() do
            AddCategoryByCategoryIndex(categoryIndex)
        end
    else
        for categoryIndex, data in pairs(self.searchResults) do
            AddCategoryByCategoryIndex(categoryIndex)
        end
    end
    self.categoryTree:Commit()

    self:UpdateAllCategoryStatuses()
end

function CollectionsBook:AddTopLevelCategory(categoryIndex, name, numSubCategories, hidesUnearned, normalIcon, pressedIcon, mouseoverIcon)
    local parent
    if self.searchString == "" then
        parent = ZO_JournalProgressBook_Common.AddTopLevelCategory(self, categoryIndex, name, numSubCategories, hidesUnearned, normalIcon, pressedIcon, mouseoverIcon)
    else
        --Special search layout
        local tree = self.categoryTree
        local lookup = self.nodeLookupData

        local hasChildren = NonContiguousCount(self.searchResults[categoryIndex]) > 1 or self.searchResults[categoryIndex]["root"] == nil
        local nodeTemplate = hasChildren and self.parentCategoryTemplate or self.childlessCategoryTemplate

        parent = self:AddCategory(lookup, tree, nodeTemplate, nil, categoryIndex, name, hidesUnearned, normalIcon, pressedIcon, mouseoverIcon)

        --We only want to add a general subcategory if we have any subcategories and we have any collectibles in the main category
        --Otherwise we'd have an emtpy general category, or only a general subcategory which can just be a childless instead
        if(hasChildren and self.searchResults[categoryIndex]["root"]) then
            local isFakedSubcategory = true
            local isSummary = false
            self:AddCategory(lookup, tree, self.subCategoryTemplate, parent, categoryIndex, GetString(SI_JOURNAL_PROGRESS_CATEGORY_GENERAL), hidesUnearned, normalIcon, pressedIcon, mouseoverIcon, isSummary, isFakedSubcategory)
        end
        
        for subcategoryIndex, data in pairs(self.searchResults[categoryIndex]) do
            if subcategoryIndex ~= "root" then
                local subCategoryName, subCategoryEntries, _, _, hidesUnearned = self:GetSubCategoryInfo(categoryIndex, subcategoryIndex)
                self:AddCategory(lookup, tree, self.subCategoryTemplate, parent, subcategoryIndex, zo_strformat(SI_COLLECTIBLE_NAME_FORMATTER, subCategoryName), nil, normalIcon, pressedIcon, mouseoverIcon)
            end
        end
    end

    return parent
end

function CollectionsBook:UpdateCategoryStatus(categoryNode)
    local categoryData = categoryNode.data
    local categoryControl = categoryNode.control
    
    local categoryIndex
    local subcategoryIndex
    if categoryData.parentData then
        categoryIndex = categoryData.parentData.categoryIndex
        subcategoryIndex = categoryData.isFakedSubcategory and ZO_JOURNAL_PROGRESS_FAKED_SUBCATEGORY_INDEX or categoryData.categoryIndex
        self:UpdateCategoryStatus(categoryData.parentData.node)
    else
        categoryIndex = categoryData.categoryIndex
    end

    if not categoryControl.statusIcon then
        categoryControl.statusIcon = categoryControl:GetNamedChild("StatusIcon")
    end

    local showNewStatus = self:HasAnyNotifications(categoryIndex, subcategoryIndex)
    categoryControl.statusIcon:SetHidden(not showNewStatus)
end

function CollectionsBook:UpdateAllCategoryStatuses()
    for _, lookupData in pairs(self.nodeLookupData) do
        local categoryNode = lookupData.node
        if NonContiguousCount(lookupData.subCategories) == 0 then
            self:UpdateCategoryStatus(categoryNode)
        else
            for _, subcategoryNode in pairs(lookupData.subCategories) do
                self:UpdateCategoryStatus(subcategoryNode)
            end
        end
    end
end

function CollectionsBook:UpdateCategoryLabels(data, retainScrollPosition)
    ZO_JournalProgressBook_Common.UpdateCategoryLabels(self, data)

    --Per a design call, we're (temporarily?) removing progress indicators, so no category progress
    self.categoryProgress:SetHidden(true)
    self.categoryLabel:SetHidden(true)
    self:BuildContentList(data, retainScrollPosition)
end

    local function GetCategoryIndices(data, parentData)
        if not data.isFakedSubcategory and parentData then
            return parentData.categoryIndex, data.categoryIndex
        end
        
        return data.categoryIndex
    end

    function CollectionsBook:GetCollectibleIds(categoryIndex, subCategoryIndex, index, ...)
        if index >= 1 then
            if self.searchString ~= "" then
                local effectiveSubcategoryIndex = subCategoryIndex or "root"
                if not self.searchResults[categoryIndex][effectiveSubcategoryIndex][index] then
                    index = index - 1
                    return self:GetCollectibleIds(categoryIndex, subCategoryIndex, index, ...)
                end
            end
            local id = GetCollectibleId(categoryIndex, subCategoryIndex, index) 
            index = index - 1
            return self:GetCollectibleIds(categoryIndex, subCategoryIndex, index, id, ...)
        end
        return ...
    end

    function CollectionsBook:BuildContentList(data, retainScrollPosition)
        local parentData = data.parentData
        local categoryIndex, subCategoryIndex = GetCategoryIndices(data, parentData)
        local numCollectibles = self:GetCategoryInfoFromData(data, parentData)

        local position = self.scrollbar:GetValue()
        self:LayoutCollection(self:GetCollectibleIds(categoryIndex, subCategoryIndex, numCollectibles))
        
        if retainScrollPosition then
            self.scrollbar:SetValue(position)
        end
    end

do
    local function ShouldAddCollectible(filterType, id)
        local unlocked, _, _, _, _, isPlaceholder = select(5 , GetCollectibleInfo(id))
        if not isPlaceholder then
            if filterType == SI_COLLECTIONS_BOOK_FILTER_SHOW_ALL then
                return true 
            end

            if(unlocked) then
                return filterType == SI_COLLECTIONS_BOOK_FILTER_SHOW_UNLOCKED
            else
                return filterType == SI_COLLECTIONS_BOOK_FILTER_SHOW_LOCKED
            end
        else
            return false
        end
    end

    function CollectionsBook:LayoutCollection(...)
        self.collectibleStickerPool:ReleaseAllObjects()
        self.collectibles = {}
        ZO_Scroll_ResetToTop(self.contentList)

        local numStickersCreated = 0
        local previous
        for i=1, select("#", ...) do
            local id = select(i, ...)
            if(ShouldAddCollectible(self.categoryFilter.filterType, id)) then
                local collectible = self.collectibleStickerPool:AcquireObject()
                self.collectibles[id] = collectible
                collectible:Show(id, previous)
                previous = collectible
                numStickersCreated = numStickersCreated + 1
            end
        end
        --Fill out the rest of the grid
        local minRows = zo_floor(self.contentList:GetHeight() / (COLLECTIBLE_STICKER_SINGLE_HEIGHT + COLLECTIBLE_PADDING))
        local minStickers = minRows * COLLECTIBLE_STICKER_ROW_STRIDE
        if numStickersCreated > minStickers then
            --Round out the last row
            local remainder = numStickersCreated % COLLECTIBLE_STICKER_ROW_STRIDE
            if remainder > 0 then
                extra = COLLECTIBLE_STICKER_ROW_STRIDE - remainder
                minStickers = numStickersCreated + extra
            end
        end

        for i = numStickersCreated + 1, minStickers do
            local collectible = self.collectibleStickerPool:AcquireObject()
            collectible:ShowBlank(previous)
            previous = collectible
        end
    end
end

function CollectionsBook:OnCollectionUpdated()
    self:UpdateCollectionLater()
end

function CollectionsBook:UpdateCollectionLater()
    self.refreshGroups:RefreshAll("FullUpdate")
end

function CollectionsBook:UpdateCollection()
    self.collectibleStickerPool:ReleaseAllObjects()
    self.collectibles = {}
    self:BuildCategories()
    if self.searchString == "" or NonContiguousCount(self.searchResults) > 0 then
        self.categoryInset:SetHidden(false)
        self.noMatches:SetHidden(true)
        self:UpdateSummary()
    else
        self.categoryInset:SetHidden(true)
        self.noMatches:SetHidden(false)
        self.contentList:SetHidden(true)
        self.summaryInset:SetHidden(true)
    end
end

function CollectionsBook:OnCollectibleUpdated(collectibleId)
    self.refreshGroups:RefreshSingle("CollectibleUpdated", collectibleId)
    MAIN_MENU_KEYBOARD:RefreshCategoryBar()
    MAIN_MENU_KEYBOARD:UpdateSceneGroupButtons("collectionsSceneGroup")
end

function CollectionsBook:UpdateCollectible(collectibleId)
    local category, subcategory = GetCategoryInfoFromCollectibleId(collectibleId)
    local categoryNode = self:GetLookupNodeByCategory(category, subcategory)
    if categoryNode then
        self:UpdateCategoryStatus(categoryNode)

        if self:IsSummaryOpen() then
            self:UpdateSummary()
        else
            local data = self.categoryTree:GetSelectedData()
            if data.node == categoryNode then
                self:UpdateCategoryLabels(data, RETAIN_SCROLL_POSITION)
            end
        end
    end
end

function CollectionsBook:OnCollectionNotificationRemoved(notificationId, collectibleId)
    self.refreshGroups:RefreshSingle("CollectibleUpdated", collectibleId)
    MAIN_MENU_KEYBOARD:RefreshCategoryBar()
    MAIN_MENU_KEYBOARD:UpdateSceneGroupButtons("collectionsSceneGroup")
end

function CollectionsBook:BrowseToCollectible(collectibleId, categoryIndex, subcategoryIndex)
    self.refreshGroups:UpdateRefreshGroups() --In case we need to rebuild the categories before we select a category

    if DLC_BOOK_KEYBOARD:IsCategoryIndexDLC(categoryIndex) then
        DLC_BOOK_KEYBOARD:BrowseToCollectible(collectibleId)
    else
        --Select the category or subcategory of the collectible
        local categoryNode = self:GetLookupNodeByCategory(categoryIndex, subcategoryIndex)
        if categoryNode then
            self.categoryTree:SelectNode(categoryNode)
        end

        --TODO: Scroll the collectibles list to show the collectible

        SCENE_MANAGER:Show("collectionsBook")
    end
end

--[[Search]]--
--------------
function CollectionsBook:SearchStart(searchString)
    self.searchString = searchString
    StartCollectibleSearch(searchString)
end

function CollectionsBook:HasAnyNotifications(optionalCategoryIndexFilter, optionalSubcategoryIndexFilter)
    return NOTIFICATIONS_PROVIDER:HasAnyNotifications(optionalCategoryIndexFilter, optionalSubcategoryIndexFilter)
end

function CollectionsBook:GetNotificationIdForCollectible(collectibleId)
    return NOTIFICATIONS_PROVIDER:GetNotificationIdForCollectible(collectibleId)
end

--[[Global functions]]--
------------------------
function ZO_CollectionsBook_OnInitialize(control)
    COLLECTIONS_BOOK = CollectionsBook:New(control)
end

function ZO_CollectionsBook_BeginSearch(editBox)
    editBox:TakeFocus()
end

function ZO_CollectionsBook_EndSearch(editBox)
    editBox:LoseFocus()
end

function ZO_CollectionsBook_OnSearchTextChanged(editBox)
    COLLECTIONS_BOOK:SearchStart(editBox:GetText())
end

function ZO_CollectionsBook_OnSearchEnterKeyPressed(editBox)
    COLLECTIONS_BOOK:SearchStart(editBox:GetText())
    editBox:LoseFocus()
end
