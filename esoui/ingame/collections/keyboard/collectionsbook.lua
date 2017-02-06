ZO_COLLECTIBLE_PADDING = 10
ZO_COLLECTIBLE_STICKER_SINGLE_WIDTH = 175
ZO_COLLECTIBLE_STICKER_SINGLE_HEIGHT = 125
local COLLECTIBLE_STICKER_ROW_STRIDE = 3
ZO_COLLECTIBLE_STICKER_ROW_WIDTH = (ZO_COLLECTIBLE_STICKER_SINGLE_WIDTH + ZO_COLLECTIBLE_PADDING) * COLLECTIBLE_STICKER_ROW_STRIDE
ZO_COLLECTIBLE_STICKER_ROW_HEIGHT = ZO_COLLECTIBLE_STICKER_SINGLE_HEIGHT + ZO_COLLECTIBLE_PADDING
local RETAIN_SCROLL_POSITION = true
local DONT_RETAIN_SCROLL_POSITION = false
local ACTIVE_ICON = "EsoUI/Art/Inventory/inventory_icon_equipped.dds"
local HIDDEN_ICON = "EsoUI/Art/Inventory/inventory_icon_hiddenBy.dds"
local VISIBLE_ICON = "EsoUI/Art/Inventory/inventory_icon_visible.dds"
local NOTIFICATIONS_PROVIDER = NOTIFICATIONS:GetCollectionsProvider()
local STICKER_ROW_DATA = 1

--Descriptive defaults for readibility in function calls
local FORCE_HIDE_PROGRESS_TEXT = true
local DONT_HIDE_LOCKED = false
local DONT_ANIMATE = true

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
    self.collectibleId = collectibleId
    self.isUsable = false
    self.isCooldownActive = false
    self.cooldownDuration = 0
    self.cooldownStartTime = 0

    if collectibleId then
        local name, description, icon, lockedIcon, unlocked, purchasable, isActive, categoryType = self:GetCollectibleInfo()

        self.name = zo_strformat(SI_COLLECTIBLE_NAME_FORMATTER, name)
        self.unlockedIcon = icon
        self.lockedIcon = lockedIcon
        self.unlocked = unlocked
        self.purchasable = purchasable
        self.active = isActive
        self.categoryType = categoryType

        COLLECTIONS_BOOK_SINGLETON:RegisterCallback("OnUpdateCooldowns",
                                                    function(...)
                                                        -- don't try to update the control if we aren't the current collectible it's showing
                                                        if self.control and self.control.collectible == self then
                                                            self:OnUpdateCooldowns(...)
                                                        end
                                                    end)
    end
end

function Collectible:RefreshInfo()
    local unlocked, _, isActive = select(5, self:GetCollectibleInfo())
    self.unlocked = unlocked
    self.active = isActive
    self.isUsable = IsCollectibleUsable(self.collectibleId)
end

function Collectible:Show(control)
    self.control = control
    if self.collectibleId then
        control.collectible = self

        self:RefreshInfo()

        self.maxIconHeight = control.icon:GetHeight()

        control.title:SetText(self.name)
        local effectiveIcon = self.unlocked and self.unlockedIcon or self.lockedIcon
        control.icon:SetTexture(effectiveIcon)
        ApplyTextColorToLabel(control.title, self.unlocked, ZO_NORMAL_TEXT, ZO_DISABLED_TEXT)

        control.cooldownIcon:SetTexture(effectiveIcon)
        control.cooldownIconDesaturated:SetTexture(effectiveIcon)
        control.cooldownIconDesaturated:SetDesaturation(1)
        control.cooldownTime:SetText("")

        control.title:SetHidden(false)
        control.icon:SetHidden(false)

        self:RefreshVisualLayer()
        self:SetBlockedState(IsCollectibleBlocked(self.collectibleId))

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

    if self.active then
        control.multiIcon:AddIcon(ACTIVE_ICON)

        if WouldCollectibleBeHidden(self.collectibleId) then
            control.multiIcon:AddIcon(HIDDEN_ICON)
        end
    end

    self.notificationId = NOTIFICATIONS_PROVIDER:GetNotificationIdForCollectible(self.collectibleId)
    self.isNew = IsCollectibleNew(self.collectibleId)
    if self.isNew then
        control.multiIcon:AddIcon(ZO_KEYBOARD_NEW_ICON)
    end

    control.multiIcon:Show()
end

function Collectible:GetId()
    return self.collectibleId
end

function Collectible:GetCollectibleInfo()
    return GetCollectibleInfo(self.collectibleId)
end

function Collectible:GetControl()
    return self.control
end

function Collectible:SetHighlightHidden(hidden, dontAnimate)
    local control = self.control
    control.highlight:SetHidden(false) -- let alpha take care of the actual hiding
    if not control.highlightAnimation then
        control.highlightAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("JournalProgressHighlightAnimation", control.highlight)
    end

    if hidden then
        ApplyTextColorToLabel(control.title, self.unlocked, ZO_NORMAL_TEXT, ZO_DISABLED_TEXT)
        if dontAnimate then
            control.iconAnimation:PlayInstantlyToStart()
            control.highlightAnimation:PlayInstantlyToStart()
        else
            control.iconAnimation:PlayBackward()
            control.highlightAnimation:PlayBackward()
        end
    else
        ApplyTextColorToLabel(control.title, self.unlocked, ZO_HIGHLIGHT_TEXT, ZO_SELECTED_TEXT)
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
    if self.active then
        if self.categoryType == COLLECTIBLE_CATEGORY_TYPE_VANITY_PET or self.categoryType == COLLECTIBLE_CATEGORY_TYPE_ASSISTANT then
            textEnum = SI_COLLECTIBLE_ACTION_DISMISS
        else
            textEnum = SI_COLLECTIBLE_ACTION_PUT_AWAY
        end
    elseif self.isCooldownActive ~= true and self.isBlocked ~= true then
        if self.categoryType == COLLECTIBLE_CATEGORY_TYPE_MEMENTO then
            textEnum = SI_COLLECTIBLE_ACTION_USE
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

do
    local SHOW_NICKNAME, SHOW_HINT, SHOW_BLOCK_REASON = true, true, true
    function Collectible:OnMouseEnter()
        if self.collectibleId then
            InitializeTooltip(ItemTooltip, self.control.parent, RIGHT, -5, 0, LEFT)
            ItemTooltip:SetCollectible(self.collectibleId, SHOW_NICKNAME, SHOW_HINT, SHOW_BLOCK_REASON)
            g_currentMouseTarget = self
            self:ShowKeybinds()
            self:RefreshMouseoverVisuals()
        end
    end

    function Collectible:RefreshTooltip()
        if self:IsCurrentMouseTarget() then
            ClearTooltip(ItemTooltip)
            InitializeTooltip(ItemTooltip, self.parentRow, RIGHT, -5, 0, LEFT)
            ItemTooltip:SetCollectible(self.collectibleId, SHOW_NICKNAME, SHOW_HINT, SHOW_BLOCK_REASON)
        end
    end
end

function Collectible:OnMouseExit()
    if self.collectibleId then
        ClearTooltip(ItemTooltip)
        self:HideKeybinds()
        g_currentMouseTarget = nil
        self:RefreshMouseoverVisuals()

        if self.notificationId then
            RemoveCollectibleNotification(self.notificationId)
        end

        if self.isNew then
            ClearCollectibleNewStatus(self.collectibleId)
        end
    end
end

function Collectible:RefreshMouseoverVisuals(dontAnimate)
    local areVisualsHidden = not self:IsCurrentMouseTarget()
    self:SetHighlightHidden(areVisualsHidden, dontAnimate)
    if self.purchasable then
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

    if not self.active then
        local secondsRemaining = cooldown / 1000
        control.cooldownTime:SetText(ZO_FormatTimeAsDecimalWhenBelowThreshold(secondsRemaining))
    else
        control.cooldownTime:SetText("")
    end
end

function Collectible:SetBlockedState(isBlocked)
    local desaturation = isBlocked and 1 or 0
    self.control.icon:SetDesaturation(desaturation)
    self.control.highlight:SetDesaturation(desaturation)
    self.isBlocked = isBlocked
end


--[[ Collection ]]--
--------------------
--[[ Initialization ]]--
------------------------
local CollectionsBook = ZO_Object.MultiSubclass(ZO_JournalProgressBook_Common, ZO_SortFilterList)

function CollectionsBook:New(...)
    return ZO_JournalProgressBook_Common.New(self, ...)
end

do
    local filterData = 
    {
        SI_COLLECTIONS_BOOK_FILTER_SHOW_ALL,
        SI_COLLECTIONS_BOOK_FILTER_SHOW_LOCKED,
        SI_COLLECTIONS_BOOK_FILTER_SHOW_USABLE,
        SI_COLLECTIONS_BOOK_FILTER_SHOW_UNLOCKED,
    }

    function CollectionsBook:Initialize(control)
        ZO_SortFilterList.Initialize(self, control)
        ZO_JournalProgressBook_Common.Initialize(self, control)

        self.searchString = ""
        self.searchResults = {}
        self.blankCollectibleObject = Collectible:New() --Used to blank out tile controls with no collectibleId
        self.collectibleObjectList = {}

        self:InitializeSummary(control)
        self:InitializeFilters(filterData)
        self:InitializeStickerGrid(control)

        self.control:SetHandler("OnUpdate", function() self.refreshGroups:UpdateRefreshGroups() end)

        local collectionsBookScene = ZO_Scene:New("collectionsBook", SCENE_MANAGER)
        collectionsBookScene:RegisterCallback("StateChange",
            function(oldState, newState)
                if newState == SCENE_SHOWING then
                    ZO_Scroll_ResetToTop(self.list)
                    self:UpdateCollectionVisualLayer()
                end
            end)

        self:UpdateCollection()

        SYSTEMS:RegisterKeyboardObject(ZO_COLLECTIONS_SYSTEM_NAME, self)
    end
end

function CollectionsBook:InitializeControls()
    ZO_JournalProgressBook_Common.InitializeControls(self)

    self.contentSearch = self.contents:GetNamedChild("Search")
    self.scrollbar = self.list:GetNamedChild("ScrollBar")
    self.noMatches = self.contents:GetNamedChild("NoMatchMessage")
end

function CollectionsBook:InitializeEvents()
    ZO_JournalProgressBook_Common.InitializeEvents(self)

    local function UpdateSearchResults()
        ZO_ClearTable(self.searchResults)

        local numResults = GetNumCollectiblesSearchResults()
        for i = 1, numResults do
            local categoryIndex, subcategoryIndex, collectibleIndex = GetCollectiblesSearchResult(i)
            if self:IsStandardCategory(categoryIndex) then
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
    end

    local function OnSearchResultsReady()
        UpdateSearchResults()
        self:UpdateCollection()
        if NonContiguousCount(self.searchResults) > 0 then
            local data = self.categoryTree:GetSelectedData()
            self:UpdateCategoryLabels(data, DONT_RETAIN_SCROLL_POSITION)
        end
    end

    self.control:RegisterForEvent(EVENT_COLLECTIBLES_SEARCH_RESULTS_READY, OnSearchResultsReady)
    self.control:RegisterForEvent(EVENT_VISUAL_LAYER_CHANGED, function() self:UpdateCollectionVisualLayer() end)

    COLLECTIONS_BOOK_SINGLETON:RegisterCallback("OnCollectibleUpdated", function(...) self:OnCollectibleUpdated(...) end)
    COLLECTIONS_BOOK_SINGLETON:RegisterCallback("OnCollectionUpdated", function() self:OnCollectionUpdated() end)
    COLLECTIONS_BOOK_SINGLETON:RegisterCallback("OnCollectiblesUpdated", function() self:OnCollectionUpdated() end)
    COLLECTIONS_BOOK_SINGLETON:RegisterCallback("OnCollectionNotificationRemoved", function(...) self:OnCollectionNotificationRemoved(...) end)
    COLLECTIONS_BOOK_SINGLETON:RegisterCallback("OnCollectibleNewStatusRemoved", function(...) self:OnCollectionNewStatusRemoved(...) end)

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

    -- cache our GetCollectibleIds function so we don't have to make it everytime we check for new collectibles
    self.getCollectiblesFunction = function(...) return self:GetCollectibleIds(...) end
end

function CollectionsBook:InitializeCategoryTemplates()
    self.parentCategoryTemplate = "ZO_CollectibleIconHeader"
    self.childlessCategoryTemplate = "ZO_CollectibleChildlessCategory"
    self.subCategoryTemplate = "ZO_CollectibleSubCategory"
end

function CollectionsBook:InitializeChildIndentAndSpacing()
    self.childIndent = 76 -- Accounting for the extra space of the status icon (adding half of the width of the icon)
    self.childSpacing = 0
end

function CollectionsBook:InitializeStickerGrid(control)
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

--[[ Summary ]]--
--------------------
function CollectionsBook:HideSummary()
    --Collections doesn't use the content list, so override here so the base doesn't try to show it
    self.summaryInset:SetHidden(true)
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

function CollectionsBook:IsStandardCategory(categoryIndex)
    return GetCollectibleCategorySpecialization(categoryIndex) == COLLECTIBLE_CATEGORY_SPECIALIZATION_NONE
end

--[[ Refresh ]]--
-----------------
function CollectionsBook:BuildCategories()
    --Per a design call, we're (temporarily?) removing progress indicators, so no summary blade
    self.categoryTree:Reset()
    self.nodeLookupData = {}
        
    local function AddCategoryByCategoryIndex(categoryIndex)
        local name, numSubCategories, _, _, _, hidesUnearned = self:GetCategoryInfo(categoryIndex)
        --Some categories are handled by specialized scenes.
        if self:IsStandardCategory(categoryIndex) then
            local normalIcon, pressedIcon, mouseoverIcon = self:GetCategoryIcons(categoryIndex)
            self:AddTopLevelCategory(categoryIndex, zo_strformat(SI_JOURNAL_PROGRESS_CATEGORY, name), numSubCategories, hidesUnearned, normalIcon, pressedIcon, mouseoverIcon)
        end
    end

    if not self:HasValidSearchString() then
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
    if not self:HasValidSearchString() then
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
                self:AddCategory(lookup, tree, self.subCategoryTemplate, parent, subcategoryIndex, zo_strformat(SI_JOURNAL_PROGRESS_CATEGORY, subCategoryName), nil, normalIcon, pressedIcon, mouseoverIcon)
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
    
    self:UpdateCategoryStatusIcon(categoryNode)
end

function CollectionsBook:UpdateAllCategoryStatusIcons()
    for _, lookupData in pairs(self.nodeLookupData) do
        local categoryNode = lookupData.node
        if NonContiguousCount(lookupData.subCategories) == 0 then
            self:UpdateCategoryStatusIcon(categoryNode)
        else
            for _, subcategoryNode in pairs(lookupData.subCategories) do
                self:UpdateCategoryStatusIcon(subcategoryNode)
            end
        end
    end
end

function CollectionsBook:UpdateCategoryStatusIcon(categoryNode)
    local categoryData = categoryNode.data
    local categoryControl = categoryNode.control

    local categoryIndex
    local subcategoryIndex
    if categoryData.parentData then
        categoryIndex = categoryData.parentData.categoryIndex
        subcategoryIndex = categoryData.isFakedSubcategory and ZO_JOURNAL_PROGRESS_FAKED_SUBCATEGORY_INDEX or categoryData.categoryIndex
    else
        categoryIndex = categoryData.categoryIndex
    end

    if not categoryControl.statusIcon then
        categoryControl.statusIcon = categoryControl:GetNamedChild("StatusIcon")
    end

    categoryControl.statusIcon:ClearIcons()

    if self:DoesCategoryHaveAnyNewCollectibles(categoryIndex, subcategoryIndex) then
        categoryControl.statusIcon:AddIcon(ZO_KEYBOARD_NEW_ICON)
    end

    local numCollectbles = self:GetCategoryInfoFromData(categoryData, categoryData.parentData)
    if COLLECTIONS_BOOK_SINGLETON.DoesCollectibleListHaveVisibleCollectible(self:GetCollectibleIds(categoryIndex, subcategoryIndex, numCollectbles)) then
        categoryControl.statusIcon:AddIcon(VISIBLE_ICON)
    end

    categoryControl.statusIcon:Show()
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

function CollectionsBook:GetCollectibleIds(categoryIndex, subCategoryIndex, index, ...)
    if self:IsStandardCategory(categoryIndex) then -- we ignore the categories that have a special tab when viewing the standard collections window
        if index >= 1 then
            if self:HasValidSearchString() then
                local inSearchResults = false
                local categoryResults = self.searchResults[categoryIndex]
                if categoryResults then
                    local effectiveSubcategoryIndex = subCategoryIndex or "root"
                    local subcategoryResults = categoryResults[effectiveSubcategoryIndex]
                    if subcategoryResults and subcategoryResults[index] then
                        inSearchResults = true
                    end
                end

                if not inSearchResults then
                    index = index - 1
                    return self:GetCollectibleIds(categoryIndex, subCategoryIndex, index, ...)
                end
            end
            local id = GetCollectibleId(categoryIndex, subCategoryIndex, index) 
            index = index - 1
            return self:GetCollectibleIds(categoryIndex, subCategoryIndex, index, id, ...)
        end
    end
    return ...
end

function CollectionsBook:BuildContentList(data, retainScrollPosition)
    local parentData = data.parentData
    local categoryIndex, subCategoryIndex = self:GetCategoryIndicesFromData(data)
    local numCollectibles = self:GetCategoryInfoFromData(data, parentData)

    local position = self.scrollbar:GetValue()
    self:LayoutCollection(self:GetCollectibleIds(categoryIndex, subCategoryIndex, numCollectibles))
        
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
    local function ShouldAddCollectible(filterType, id)
        local unlocked, _, _, _, _, isPlaceholder = select(5 , GetCollectibleInfo(id))
        if not isPlaceholder then
            if filterType == SI_COLLECTIONS_BOOK_FILTER_SHOW_ALL then
                return true
            end

            if unlocked then
                if filterType == SI_COLLECTIONS_BOOK_FILTER_SHOW_UNLOCKED then
                    return true
                elseif filterType == SI_COLLECTIONS_BOOK_FILTER_SHOW_USABLE then
                    return IsCollectibleValidForPlayer(id)
                else
                    return false
                end
            else
                return filterType == SI_COLLECTIONS_BOOK_FILTER_SHOW_LOCKED
            end
        else
            return false
        end
    end

    function CollectionsBook:LayoutCollection(...)
        ZO_Scroll_ResetToTop(self.list)
        local scrollData = ZO_ScrollList_GetDataList(self.list)
        ZO_ClearNumericallyIndexedTable(scrollData)

        local rowData = {}
        for currentIndex = 1, select("#", ...) do
            local id = select(currentIndex, ...)
            if ShouldAddCollectible(self.categoryFilter.filterType, id) then
                table.insert(rowData, id)
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

function CollectionsBook:OnCollectionUpdated()
    self:UpdateCollectionLater()
end

function CollectionsBook:UpdateCollectionLater()
    self.refreshGroups:RefreshAll("FullUpdate")
end

function CollectionsBook:UpdateCollection()
    self:BuildCategories()
    local foundNoMatches = self:HasValidSearchString() and NonContiguousCount(self.searchResults) == 0
    self.categoryInset:SetHidden(foundNoMatches)
    self.noMatches:SetHidden(not foundNoMatches)
    self.list:SetHidden(foundNoMatches)
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

        local data = self.categoryTree:GetSelectedData()
        if data.node == categoryNode then
            self:UpdateCategoryLabels(data, RETAIN_SCROLL_POSITION)
        end
    end
end

function CollectionsBook:OnCollectibleStatusUpdated(collectibleId)
    self.refreshGroups:RefreshSingle("CollectibleUpdated", collectibleId)
    MAIN_MENU_KEYBOARD:RefreshCategoryBar()
    MAIN_MENU_KEYBOARD:UpdateSceneGroupButtons("collectionsSceneGroup")
end

function CollectionsBook:OnCollectionNotificationRemoved(notificationId, collectibleId)
    self:OnCollectibleStatusUpdated(collectibleId)
end

function CollectionsBook:OnCollectionNewStatusRemoved(collectibleId)
    self:OnCollectibleStatusUpdated(collectibleId)
end

function CollectionsBook:BrowseToCollectible(collectibleId, categoryIndex, subcategoryIndex)
    self.refreshGroups:UpdateRefreshGroups() --In case we need to rebuild the categories before we select a category

    if COLLECTIONS_BOOK_SINGLETON:IsCategoryIndexDLC(categoryIndex) then
        DLC_BOOK_KEYBOARD:BrowseToCollectible(collectibleId)
    elseif COLLECTIONS_BOOK_SINGLETON:IsCategoryIndexHousing(categoryIndex) then
        HOUSING_BOOK_KEYBOARD:BrowseToCollectible(collectibleId)
    else
        --Select the category or subcategory of the collectible
        local categoryNode = self:GetLookupNodeByCategory(categoryIndex, subcategoryIndex)
        if categoryNode then
            self.categoryTree:SelectNode(categoryNode)
        end

        --TODO: Scroll the collectibles list to show the collectible

        MAIN_MENU_KEYBOARD:ToggleSceneGroup("collectionsSceneGroup", "collectionsBook")
    end
end

function CollectionsBook:UpdateCollectionVisualLayer()
    self:RefreshVisible()
    self:UpdateAllCategoryStatusIcons()
end

--[[Search]]--
--------------
function CollectionsBook:SearchStart(searchString)
    self.searchString = searchString
    StartCollectibleSearch(searchString)
end

function CollectionsBook:HasValidSearchString()
    return zo_strlen(self.searchString) > 1
end

function CollectionsBook:HasAnyNotifications(optionalCategoryIndexFilter, optionalSubcategoryIndexFilter)
    return NOTIFICATIONS_PROVIDER:HasAnyNotifications(optionalCategoryIndexFilter, optionalSubcategoryIndexFilter)
end

function CollectionsBook:DoesCategoryHaveAnyNewCollectibles(categoryIndex, subcategoryIndex)
    return COLLECTIONS_BOOK_SINGLETON.DoesCategoryHaveAnyNewCollectibles(categoryIndex, subcategoryIndex, self.getCollectiblesFunction)
end

function CollectionsBook:HasAnyNewCollectibles()
    return COLLECTIONS_BOOK_SINGLETON.HasAnyNewCollectibles()
end

function CollectionsBook:GetNotificationIdForCollectible(collectibleId)
    return NOTIFICATIONS_PROVIDER:GetNotificationIdForCollectible(collectibleId)
end

--[[Global functions]]--
------------------------
function ZO_CollectionsBook_OnInitialize(control)
    COLLECTIONS_BOOK = CollectionsBook:New(control)
end

function ZO_CollectionsBook_OnSearchTextChanged(editBox)
    ZO_EditDefaultText_OnTextChanged(editBox)
    COLLECTIONS_BOOK:SearchStart(editBox:GetText())
end

function ZO_CollectionsBook_OnSearchEnterKeyPressed(editBox)
    COLLECTIONS_BOOK:SearchStart(editBox:GetText())
    editBox:LoseFocus()
end
