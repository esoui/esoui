ZO_GUILD_HISTORY_GAMEPAD_ROW_HEIGHT = 70

ZO_GuildHistory_Gamepad = ZO_GuildHistory_Shared:MultiSubclass(ZO_SortFilterList_Gamepad)

function ZO_GuildHistory_Gamepad:Initialize(control)
    local ALWAYS_ANIMATE = true
    ZO_GuildHistory_Shared.Initialize(self, control, ALWAYS_ANIMATE)
    GUILD_HISTORY_GAMEPAD_FRAGMENT = self:GetFragment()
end

function ZO_GuildHistory_Gamepad:OnDeferredInitialize()
    ZO_SortFilterList_Gamepad.Initialize(self, self.control)
    ZO_GuildHistory_Shared.OnDeferredInitialize(self)

    -- TODO Guild History: Implement
end

function ZO_GuildHistory_Gamepad:InitializeSortFilterList(...)
    ZO_SortFilterList_Gamepad.InitializeSortFilterList(self, ...)
    ZO_GuildHistory_Shared.InitializeSortFilterList(self, "ZO_GuildHistoryRow_Gamepad", ZO_GUILD_HISTORY_GAMEPAD_ROW_HEIGHT)
end

function ZO_GuildHistory_Gamepad:InitializeKeybindDescriptors()
    -- The keybind descriptor for when focus is on the category list.
    self.categoryKeybindStripDescriptor = {}

    local DEFAULT_NAME = nil
    local ALWAYS_VISIBLE = nil
    local function IsForwardNavigationEnabled()
        return self:HasEntries()
    end
    ZO_Gamepad_AddForwardNavigationKeybindDescriptorsWithSound(self.categoryKeybindStripDescriptor,
        GAME_NAVIGATION_TYPE_BUTTON,
        function() self:FocusEventsList() end,
        DEFAULT_NAME,
        ALWAYS_VISIBLE,
        IsForwardNavigationEnabled
    )
    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.categoryKeybindStripDescriptor,
        GAME_NAVIGATION_TYPE_BUTTON, 
        function()
            GAMEPAD_GUILD_HUB:SetEnterInSingleGuildList(true)
            SCENE_MANAGER:HideCurrentScene()
        end
    )
    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.categoryKeybindStripDescriptor, self.categoryList)

    local function ShouldNarrateKeybinds()
        return (self.currentPage > 1) or self.hasNextPage
    end

    -- The keybind descriptor for when focus is on the events list.
    self.eventsKeybindStripDescriptor =
    {
        {
            --Even though this is an ethereal keybind, the name will still be read during screen narration
            name = GetString(SI_GAMEPAD_PAGED_LIST_PAGE_LEFT_NARRATION),
            keybind = "UI_SHORTCUT_LEFT_TRIGGER",
            ethereal = true,
            narrateEthereal = ShouldNarrateKeybinds,
            etherealNarrationOrder = 1,
            sound = SOUNDS.GAMEPAD_PAGE_BACK,
            enabled = function()
                return self.currentPage > 1
            end,
            callback = function()
                self:ShowPreviousPage()
            end,
        },
        {
            --Even though this is an ethereal keybind, the name will still be read during screen narration
            name = GetString(SI_GAMEPAD_PAGED_LIST_PAGE_RIGHT_NARRATION),
            keybind = "UI_SHORTCUT_RIGHT_TRIGGER",
            ethereal = true,
            narrateEthereal = ShouldNarrateKeybinds,
            etherealNarrationOrder = 2,
            sound = SOUNDS.GAMEPAD_PAGE_FORWARD,
            enabled = function()
                return self.hasNextPage
            end,
            callback = function()
                self:ShowNextPage()
            end,
        },
        {
            alignment = KEYBIND_STRIP_ALIGN_CENTER,
            name = GetString(SI_GUILD_HISTORY_SHOW_MORE),
            keybind = "UI_SHORTCUT_SECONDARY",
            visible = function()
                return self:CanShowMore()
            end,
            callback = function()
                self:TryShowMore()
            end,
        }
    }
    ZO_Gamepad_AddBackNavigationKeybindDescriptorsWithSound(self.eventsKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, function() self:FocusCategoryList() end)
end

function ZO_GuildHistory_Gamepad:SetMainList(list)
    self.categoryList = list
end

function ZO_GuildHistory_Gamepad:OnShowing()
    ZO_GuildHistory_Shared.OnShowing(self)

    self:PopulateCategoryList()
    self:FocusCategoryList()
end

function ZO_GuildHistory_Gamepad:OnHiding()
    ZO_GuildHistory_Shared.OnHiding(self)
    
    self:Deactivate()
    self.categoryList:Deactivate()
    GAMEPAD_NAV_QUADRANT_1_BACKGROUND_FRAGMENT:TakeFocus()
    self.keybindStripDescriptor = nil
end

-- Called from GuildHome when category changes
function ZO_GuildHistory_Gamepad:OnTargetChanged(list, selectedData, oldSelectedData)
    self:SetSelectedEventCategory(selectedData.eventCategory, selectedData.subcategoryIndex)
end

--Called when the selection in the event list changes
function ZO_GuildHistory_Gamepad:OnSelectionChanged(oldData, newData)
    ZO_SortFilterList_Gamepad.OnSelectionChanged(self, oldData, newData)
    self:UpdateTooltip()
end

function ZO_GuildHistory_Gamepad:UpdateTooltip()
    if self:IsShowing() then
        GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
        local selectedData = self:GetSelectedData()
        if selectedData then
            local eventData = selectedData.data:GetDataSource()
            if eventData then
                GAMEPAD_TOOLTIPS:LayoutGuildHistoryEvent(GAMEPAD_RIGHT_TOOLTIP, eventData)
            end
        end
    end
end

function ZO_GuildHistory_Gamepad:PopulateCategoryList()
    self.categoryList:Clear()

    for eventCategory = GUILD_HISTORY_EVENT_CATEGORY_ITERATION_BEGIN, GUILD_HISTORY_EVENT_CATEGORY_ITERATION_END do
        local categoryInfo = ZO_GuildHistory_Manager.GetEventCategoryInfo(eventCategory)
        if categoryInfo then
            local categoryString = GetString("SI_GUILDHISTORYEVENTCATEGORY", eventCategory)
            local firstEntry = true
            for subcategoryIndex, subcategoryInfo in ipairs(categoryInfo.subcategories) do
                
                local subcategoryName
                if subcategoryInfo.subcategoryType == GUILD_HISTORY_EVENT_SUBCATEGORY_ALL then
                    subcategoryName = categoryString
                else
                    subcategoryName = GetString("SI_GUILDHISTORYEVENTSUBCATEGORY", subcategoryInfo.subcategoryType)
                end
                local entryData = ZO_GamepadEntryData:New(subcategoryName, subcategoryInfo.gamepadIcon)
                entryData:SetIconTintOnSelection(true)
                entryData.eventCategory = eventCategory
                entryData.subcategoryIndex = subcategoryIndex

                if firstEntry then
                    entryData:SetHeader(categoryString)
                    self.categoryList:AddEntry("ZO_GamepadMenuEntryTemplateWithHeader", entryData)
                    firstEntry = false
                else
                    self.categoryList:AddEntry("ZO_GamepadMenuEntryTemplate", entryData)
                end
            end
        end
    end

    self.categoryList:Commit()
end

function ZO_GuildHistory_Gamepad:SetupEventRow(control, eventData)
    local IS_GAMEPAD = true
    ZO_GuildHistory_Shared.SetupEventRow(self, control, eventData, IS_GAMEPAD)
end

function ZO_GuildHistory_Gamepad:SetCurrentPage(newCurrentPage, suppressRefresh)
    --Order matters, do this before calling the base class
    if self.currentPage ~= newCurrentPage and self:IsActivated() then
        --Re-narrate when changing pages
        local NARRATE_HEADER = true
        SCREEN_NARRATION_MANAGER:QueueSortFilterListEntry(self, NARRATE_HEADER)
    end
    ZO_GuildHistory_Shared.SetCurrentPage(self, newCurrentPage, suppressRefresh)
end

function ZO_GuildHistory_Gamepad:ResetToTop()
    local NO_CALLBACK = nil
    local ANIMATE_INSTANTLY = true
    ZO_SortFilterList_Gamepad.ResetToTop(self, NO_CALLBACK, ANIMATE_INSTANTLY)
end

function ZO_GuildHistory_Gamepad:FilterScrollList()
    ZO_GuildHistory_Shared.FilterScrollList(self)
    local footerVisibilityChanged = self:RefreshFooter()
    self:UpdateKeybinds()
    self:UpdateTooltip()
    if self:IsActivated() then
        --The keybinds or tooltip may have changed, so re-narrate
        --If the visibility of the page number footer changed, re-narrate the header too
        SCREEN_NARRATION_MANAGER:QueueSortFilterListEntry(self, footerVisibilityChanged)
    end
end

function ZO_GuildHistory_Gamepad:RefreshFooter()
    local wasHidden = self.footer:IsHidden()

    if self:IsActivated() then
        local enablePrevious = self.currentPage > 1
        local enableNext = self.hasNextPage
        self.footer.previousButton:SetEnabled(enablePrevious)
        self.footer.nextButton:SetEnabled(enableNext)

        self.footer:SetHidden(not (enablePrevious or enableNext))
    else
        self.footer:SetHidden(true)
    end

    local isHidden = self.footer:IsHidden()
    return wasHidden ~= isHidden
end

function ZO_GuildHistory_Gamepad:FocusCategoryList()
    self:SetKeybindStripDescriptor(self.categoryKeybindStripDescriptor)
    self:AddKeybinds()

    GAMEPAD_NAV_QUADRANT_1_BACKGROUND_FRAGMENT:TakeFocus()
    self:Deactivate()
    self.categoryList:Activate()

    self:RefreshFooter()
end

function ZO_GuildHistory_Gamepad:FocusEventsList()
    self:SetKeybindStripDescriptor(self.eventsKeybindStripDescriptor)
    self:AddKeybinds()

    GAMEPAD_NAV_QUADRANT_1_BACKGROUND_FRAGMENT:ClearFocus()
    self.categoryList:Deactivate()
    self:Activate()

    self:RefreshFooter()
end

function ZO_GuildHistory_Gamepad:SetShowLoadingSpinner(showLoadingSpinner, isTargetingEvents)
    self.loadingIcon:SetHidden(not showLoadingSpinner)
end

function ZO_GuildHistory_Gamepad:GetHeaderNarration()
    local narrations = {}
    ZO_AppendNarration(narrations, GAMEPAD_GUILD_HOME:GetContentHeaderNarrationText())
    --Include the page number in the narration if visible
    if self.hasNextPage or self.currentPage > 1 then
        local pageNarration = SCREEN_NARRATION_MANAGER:CreateNarratableObject(zo_strformat(SI_GAMEPAD_PAGED_LIST_PAGE_NUMBER_NARRATION, self.currentPage))
        ZO_AppendNarration(narrations, pageNarration)
    end
    return narrations
end

function ZO_GuildHistory_Gamepad.OnControlInitialized(control)
    GUILD_HISTORY_GAMEPAD = ZO_GuildHistory_Gamepad:New(control)
end