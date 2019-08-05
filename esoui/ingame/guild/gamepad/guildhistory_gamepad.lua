local ZO_GuildHistory_Gamepad = ZO_Object:Subclass()

function ZO_GuildHistory_Gamepad:New(...)
    local guildHistory = ZO_Object.New(self)
    guildHistory:Initialize(...)
    return guildHistory
end

function ZO_GuildHistory_Gamepad:SetMainList(list)
    self.categoryList = list
end

function ZO_GuildHistory_Gamepad:Initialize(control)
    self.control = control
    control.owner = self

    self.refreshGroup = ZO_OrderedRefreshGroup:New(ZO_ORDERED_REFRESH_GROUP_AUTO_CLEAN_IMMEDIATELY)
    self.refreshGroup:AddDirtyState("EventList", function()
        self:PopulateEventList()
    end)
    self.refreshGroup:SetActive(function()
        return self:IsShowing()
    end)

    control:RegisterForEvent(EVENT_GUILD_HISTORY_REFRESHED, function()
        if self:IsShowing() then
            self.categoryList:SetSelectedIndexWithoutAnimation(1)
            self:RequestInitialEvents()
        end
        self.refreshGroup:MarkDirty("EventList")
    end)

    control:SetHandler("OnUpdate", function()
        if self:IsTryingToGetMoreEvents() then
            self:ShowLoading()
        else
            self:HideLoading()
        end
    end)

    self.startIndex = 1
    self.displayedItems = 0
    self.guildId = 1
    self.initialized = false
    self.guildEvents = {}
    self.selectFirstIndexOnPage = false

    self.tooltipHeaderData = {
        titleText = GetString(SI_GAMEPAD_GUILD_HISTORY_GUILD_EVENT_TITLE),
    }

    self.loading = control:GetNamedChild("Loading")

    self.footer = ZO_PagedListSetupFooter(control:GetNamedChild("Footer"))

    GUILD_HISTORY_GAMEPAD_FRAGMENT = ZO_FadeSceneFragment:New(self.control, true)

    EVENT_MANAGER:RegisterForUpdate("ZO_GuildHistory_Gamepad", 60000, function()
        self.refreshGroup:MarkDirty("EventList")
    end)

    GUILD_HISTORY_GAMEPAD_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            self:InitializeGuildHistory()
            --The category list is shared among all the guild screens so it needs to be built each time screen shows
            self:PopulateCategoryList()
            self.categoryList:SetSelectedIndexWithoutAnimation(1)
            self:RequestInitialEvents()
            self:SelectCategoryList()
            self.refreshGroup:TryClean()
        elseif newState == SCENE_HIDING then
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
            self.keybindStripDescriptor = nil
            GAMEPAD_NAV_QUADRANT_1_BACKGROUND_FRAGMENT:TakeFocus()
            self.categoryList:Deactivate()
            self.activityList:Deactivate()
        end
    end)
end

function ZO_GuildHistory_Gamepad:InitializeGuildHistory()
    if not self.initialized then
        self.initialized = true
        self:InitializeActivityList()
        self:InitializeKeybindStripDescriptors()
        self:InitializeEvents()
    end
end

function ZO_GuildHistory_Gamepad:OnTargetChanged(list, selectedData, oldSelectedData)
    self.startIndex = 1
    self.activityList:SetFocusToMatchingEntry(self.activityListItems[1])
    self:RequestInitialEvents()
    self.refreshGroup:MarkDirty("EventList")
end

function ZO_GuildHistory_Gamepad:IsTryingToGetMoreEvents()
    local targetData = self.categoryList:GetTargetData()
    local categoryId = targetData.categoryId
    return DoesGuildHistoryCategoryHaveOutstandingRequest(self.guildId, categoryId) or IsGuildHistoryCategoryRequestQueued(self.guildId, categoryId)
end

function ZO_GuildHistory_Gamepad:CanPageLeft()
    return not (self.startIndex <= 1)
end

function ZO_GuildHistory_Gamepad:CanPageRight()
    local targetData = self.categoryList:GetTargetData()
    local categoryId = targetData.categoryId
    local numEvents = #self.guildEvents
    local nextStartIndex = self.startIndex + self.itemsPerPage
    if numEvents >= nextStartIndex then
        return true
    else
        return DoesGuildHistoryCategoryHaveMoreEvents(self.guildId, categoryId) and not self:IsTryingToGetMoreEvents()
    end
end

function ZO_GuildHistory_Gamepad:NextPage()
    if not self:CanPageRight() then
        return
    end
    self.activityList:SetFocusToMatchingEntry(self.activityListItems[1])
    self.startIndex = self.startIndex + self.itemsPerPage

    local targetData = self.categoryList:GetTargetData()
    local categoryId = targetData.categoryId
    local numEvents = #self.guildEvents
    local numEventsRequiredToFillPage = self.startIndex + self.itemsPerPage
    --If we have enough events to fill the next page already or there are no more events to fetch then just show the next page, otherwise request more events.
    if numEvents >= numEventsRequiredToFillPage or not DoesGuildHistoryCategoryHaveMoreEvents(self.guildId, categoryId) then
        self.refreshGroup:MarkDirty("EventList")
    else
        self:RequestMoreEvents()
    end
end

function ZO_GuildHistory_Gamepad:PreviousPage()
    if not self:CanPageLeft() then
        return
    end
    self.startIndex = self.startIndex - self.itemsPerPage
    if self.startIndex < 1 then
        self.startIndex = 1
    end
    local selectItemIndex = self.selectFirstIndexOnPage and 1 or #self.activityListItems
    self.activityList:SetFocusToMatchingEntry(self.activityListItems[selectItemIndex])
    self.refreshGroup:MarkDirty("EventList")
    self.selectFirstIndexOnPage = false
end

local function CreateActivityItem(parent, previous, index)
    local PADDING = 0

    local newControl = CreateControlFromVirtual("$(parent)ActivityItem", parent, "ZO_GuildHistory_Gamepad_ActivityItem", index)
    newControl:SetAnchor(TOPLEFT, previous, BOTTOMLEFT, 0, PADDING)
    newControl:SetAnchor(TOPRIGHT, previous, BOTTOMRIGHT, 0, PADDING)

    return newControl
end

function ZO_GuildHistory_Gamepad:OnActivityTargetChanged(focusedItem)
    if(focusedItem ~= nil and focusedItem.control.description ~= nil) then
        self.tooltipHeaderData.messageText = focusedItem.control.description

        GAMEPAD_TOOLTIPS:ShowGenericHeader(GAMEPAD_RIGHT_TOOLTIP, self.tooltipHeaderData)

        GAMEPAD_TOOLTIPS:SetBgType(GAMEPAD_RIGHT_TOOLTIP, GAMEPAD_TOOLTIP_NORMAL_BG)
        GAMEPAD_TOOLTIPS:ShowBg(GAMEPAD_RIGHT_TOOLTIP)
    else
        GAMEPAD_TOOLTIPS:HideBg(GAMEPAD_RIGHT_TOOLTIP)
        GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
        GAMEPAD_TOOLTIPS:Reset(GAMEPAD_RIGHT_TOOLTIP)
    end
end

function ZO_GuildHistory_Gamepad:InitializeActivityList()
    self.activityList = ZO_GamepadFocus:New(self.control)
    local function OnTargetChanged(...)
        self:OnActivityTargetChanged(...)
    end
    self.activityList:SetFocusChangedCallback(OnTargetChanged)
    self.activityListItems = {}

    -- Add the hidden "previous page" item.
    self.activityList:AddEntry({
                        activate = function() self:PreviousPage() end,
                        canFocus = function(control) return self.startIndex ~= 1 end,
                })

    -- Add the main items.
    local parent = self.control:GetNamedChild("ActivityLog")
    local previous = parent:GetNamedChild("ActivityItemListTopAnchor")
    local containerBottom = parent:GetBottom()
    local itemIndex = 0
    while (previous:GetBottom() + previous:GetHeight()) < containerBottom do -- We know all items have a uniform height, so add the height to the bottom to ensure we have enough room for another item.
        itemIndex = itemIndex + 1
        local control = CreateActivityItem(parent, previous, itemIndex)
        table.insert(self.activityListItems, control)
        previous = control

        local itemIndexInternal = itemIndex -- Needs to be local to the loop for the capture just below.
        self.activityList:AddEntry({
                                        control = control,
                                        highlight = control:GetNamedChild("Highlight"),
                                        canFocus = function(control) return itemIndexInternal <= self.displayedItems end,
                                  })
    end
    self.itemsPerPage = itemIndex

    -- Add the hidden "next page" item.
    self.activityList:AddEntry({
                        activate = function() self:NextPage() end,
                        canFocus = function(control) return self:CanPageRight() end,
                    })
end

function ZO_GuildHistory_Gamepad:InitializeEvents()
    self.control:RegisterForEvent(EVENT_GUILD_HISTORY_CATEGORY_UPDATED, function(_, guildId, category) self:OnGuildHistoryCategoryUpdated(guildId, category) end)
    self.control:RegisterForEvent(EVENT_GUILD_HISTORY_RESPONSE_RECEIVED, function() self:OnGuildHistoryResponseReceived() end)
end

function ZO_GuildHistory_Gamepad:InitializeKeybindStripDescriptors()
    -- The keybind descriptor for when focus is on the category list.
    self.categoryKeybindStripDescriptor = {}

    ZO_Gamepad_AddForwardNavigationKeybindDescriptorsWithSound(self.categoryKeybindStripDescriptor,
                                                      GAME_NAVIGATION_TYPE_BUTTON,
                                                      function() self:SelectLogList() end,
                                                      nil, -- default name
                                                      nil, -- always visible
                                                      function() return #self.guildEvents > 0 end -- Potentially disabled
                                                    )
    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.categoryKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, function()
        GAMEPAD_GUILD_HUB:SetEnterInSingleGuildList(true)
        SCENE_MANAGER:HideCurrentScene()
    end)
    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.categoryKeybindStripDescriptor, self.categoryList)

    -- The keybind descriptor for when focus is on the activity log list.
    self.logKeybindStripDescriptor = {
        {
            --Ethereal binds show no text, the name field is used to help identify the keybind when debugging. This text does not have to be localized.
            name = "Gamepad Guild History Previous Page",
            keybind = "UI_SHORTCUT_LEFT_TRIGGER",
            ethereal = true,
            sound = SOUNDS.GAMEPAD_PAGE_BACK,
            enabled = function()
                return self:CanPageLeft()
            end,
            callback = function()
                -- The shown page shows the items in self.activityList.data starting from the 2nd to the 2nd to last index.
                -- By selecting the first index a transition to the previous page will be initiated, this transition will ultimately call PreviousPage() when it calls the activate function on this entry 
                -- The member variable selectFirstIndexOnPage is set to jump to the first item in the list on the previous page, otherwise PreviousPage() will select the last be default 
                self.selectFirstIndexOnPage = true
                self.activityList:SetFocusByIndex(1)
            end,
        },
        {
            --Ethereal binds show no text, the name field is used to help identify the keybind when debugging. This text does not have to be localized.
            name = "Gamepad Guild History Next Page",
            keybind = "UI_SHORTCUT_RIGHT_TRIGGER",
            ethereal = true,
            sound = SOUNDS.GAMEPAD_PAGE_FORWARD,
            enabled = function()
                return self:CanPageRight()
            end,
            callback = function()
                -- The shown page shows the items in self.activityList.data starting from the 2nd to the 2nd to last index.
                -- By selecting the last index a transition to the next page will be initiated, this transition will ultimately call NextPage() when it calls the activate function on this entry
                self.activityList:SetFocusByIndex(#self.activityList.data)
            end,
        }
    }
    ZO_Gamepad_AddBackNavigationKeybindDescriptorsWithSound(self.logKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, function() self:SelectCategoryList() end)
end

function ZO_GuildHistory_Gamepad:RefreshKeybinds()
    if self.keybindStripDescriptor then
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    end
end

function ZO_GuildHistory_Gamepad:UpdateLogTriggerButtons()
    if self.keybindStripDescriptor ~= self.logKeybindStripDescriptor then
         -- We are not showing the log, the buttons are hidden.
        self.footer.control:SetHidden(true)
    else -- We are showing the log, buttons depend on page state.
        self:RefreshFooter()
    end
end

function ZO_GuildHistory_Gamepad:SelectCategoryList()
    if self.keybindStripDescriptor then
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
    end

    self.keybindStripDescriptor = self.categoryKeybindStripDescriptor
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)

    self:UpdateLogTriggerButtons()
    
    GAMEPAD_NAV_QUADRANT_1_BACKGROUND_FRAGMENT:TakeFocus()
    self.activityList:Deactivate()
    self.categoryList:Activate()
end

function ZO_GuildHistory_Gamepad:SelectLogList()
    if self.keybindStripDescriptor then
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
    end

    self.keybindStripDescriptor = self.logKeybindStripDescriptor
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)

    self:UpdateLogTriggerButtons()

    self.categoryList:Deactivate()
    self.activityList:Activate()
    GAMEPAD_NAV_QUADRANT_1_BACKGROUND_FRAGMENT:ClearFocus()
end

function ZO_GuildHistory_Gamepad:SetGuildId(guildId)
    if guildId ~= self.guildId then 
        self.guildId = guildId
        if self:IsShowing() then
            self.categoryList:SetSelectedIndexWithoutAnimation(1)
            self:RequestInitialEvents()
        end
        self.refreshGroup:MarkDirty("EventList")
    end
end

function ZO_GuildHistory_Gamepad:RequestInitialEvents()
    local targetData = self.categoryList:GetTargetData()
    local categoryId = targetData.categoryId

    if not HasGuildHistoryCategoryEverBeenRequested(self.guildId, categoryId) then
        self:RequestMoreEvents()
    end
end

function ZO_GuildHistory_Gamepad:RequestMoreEvents()
    if GUILD_HISTORY_GAMEPAD_FRAGMENT:IsShowing() then
        local targetData = self.categoryList:GetTargetData()
        local categoryId = targetData.categoryId
        if DoesGuildHistoryCategoryHaveMoreEvents(self.guildId, categoryId) or not HasGuildHistoryCategoryEverBeenRequested(self.guildId, categoryId) then
            local QUEUE_REQUEST_IF_ON_COOLDOWN = true
            RequestMoreGuildHistoryCategoryEvents(self.guildId, categoryId, QUEUE_REQUEST_IF_ON_COOLDOWN)
            self:RefreshKeybinds()
            self:UpdateLogTriggerButtons()
        end
    end
end

function ZO_GuildHistory_Gamepad:ShowLoading()
    self.loading:SetHidden(false)
end

function ZO_GuildHistory_Gamepad:HideLoading()
    self.loading:SetHidden(true)
end

function ZO_GuildHistory_Gamepad:IsShowing()
    return GUILD_HISTORY_GAMEPAD_FRAGMENT and GUILD_HISTORY_GAMEPAD_FRAGMENT:IsShowing()
end

function ZO_GuildHistory_Gamepad:OnGuildHistoryCategoryUpdated(guildId, category)
    if self.guildId == guildId then
        if self:IsShowing() then
            local targetData = self.categoryList:GetTargetData()
            if targetData.categoryId == category then
                self:RefreshKeybinds()
                self.refreshGroup:MarkDirty("EventList")
            end
        else
            --Technically we only need to mark a specific category dirty, but that level of granularity only prevents rebuilding the general category first page on show which probably isn't worth the complexity.
            self.refreshGroup:MarkDirty("EventList")
        end
    end
end

function ZO_GuildHistory_Gamepad:OnGuildHistoryResponseReceived()
    self:RefreshKeybinds()
    self:UpdateLogTriggerButtons()
end

function ZO_GuildHistory_Gamepad:PopulateEventList()
    local targetData = self.categoryList:GetTargetData()
    local categoryId = targetData.categoryId
    local subcategoryId = targetData.subcategoryId

    -- Build and filter the event list.
    ZO_ClearNumericallyIndexedTable(self.guildEvents)
    for eventIndex = 1, GetNumGuildEvents(self.guildId, categoryId) do
        local eventType, secsSinceEvent, param1, param2, param3, param4, param5, param6, eventId = GetGuildEventInfo(self.guildId, categoryId, eventIndex)
        local eventSubcategoryID = ComputeGuildHistoryEventSubcategory(eventType, categoryId)

        if (subcategoryId == nil) or (subcategoryId == eventSubcategoryID) then
            local formatFunction = GUILD_EVENT_EVENT_FORMAT[eventType]
            if formatFunction then
                local eventData = {
                        eventId = eventId,
                        eventType = eventType,
                        formatFunction = formatFunction,
                        secsSinceEvent = secsSinceEvent,
                        param1 = param1,
                        param2 = param2,
                        param3 = param3,
                        param4 = param4,
                        param5 = param5,
                        param6 = param6,
                    }
                table.insert(self.guildEvents, eventData)
            end
        end
    end

    self.currPageNum = math.floor((self.startIndex / self.itemsPerPage) + 1)
    self.displayedItems = zo_min(#self.guildEvents - self.startIndex + 1, self.itemsPerPage)

    for eventIndex = 1, self.itemsPerPage do
        self.activityListItems[eventIndex]:SetHidden(true)
    end

    --Update keybinds
    self:RefreshKeybinds()

    -- Update the trigger buttons.
    self:UpdateLogTriggerButtons()

    --If this page isn't full then we may not have gotten enough new events in this category to fill it...
    if self.displayedItems < self.itemsPerPage and not self:IsTryingToGetMoreEvents() then
        if DoesGuildHistoryCategoryHaveMoreEvents(self.guildId, categoryId) then
            --if we can request more then try that
            return self:RequestMoreEvents()
        else
            --if we can't request more then we need to go back to the previous page since if this page is empty because there will be nothing to fill it
            if self.displayedItems == 0 and self.startIndex ~= 1 then
                return self:PreviousPage()
            end
        end
    end

    table.sort(self.guildEvents, function(event1, event2) return event1.eventId > event2.eventId end)

    for eventIndex = 1, self.displayedItems do
        local displayItem = self.activityListItems[eventIndex]
        local eventData = self.guildEvents[self.startIndex + eventIndex - 1]
        local description = eventData.formatFunction(eventData.eventType, eventData.param1, eventData.param2, eventData.param3, eventData.param4, eventData.param5, eventData.param6)
        local time = ZO_FormatDurationAgo(eventData.secsSinceEvent)

        displayItem:SetHidden(false)
        displayItem.text:SetText(description)
        displayItem.time:SetText(time)
        displayItem.description = description
    end

    if self.displayedItems == 0 and self.startIndex == 1 and not self:IsTryingToGetMoreEvents() then
        -- Display a "no items" item if there are truly no items.
        local displayItem = self.activityListItems[1]
        displayItem:SetHidden(false)
        local noEntriesText = ZO_GuildHistory_GetNoEntriesText(categoryId, subcategoryId, self.guildId)
        displayItem.text:SetText(noEntriesText)
        displayItem.time:SetText("")
        displayItem.description = nil
    end
end

function ZO_GuildHistory_Gamepad:PopulateCategoryList()
    self.categoryList:Clear()

    for categoryId = 1, GetNumGuildHistoryCategories() do
        local categoryData = GUILD_HISTORY_CATEGORIES[categoryId]
        if categoryData then
            local entryData = ZO_GamepadEntryData:New(GetString(SI_GAMEPAD_GUILD_HISTORY_SUBCATEGORY_ALL), "EsoUI/Art/Guild/gamepad/gp_guild_menuIcon_showAll.dds")
            entryData.categoryId = categoryId
            entryData:SetHeader(GetString("SI_GUILDHISTORYCATEGORY", categoryId))
            entryData:SetIconTintOnSelection(true)
            self.categoryList:AddEntry("ZO_GamepadMenuEntryTemplateWithHeader", entryData)

            if categoryData.subcategories then
                local index = 1
                for subcategoryId, data in pairs(categoryData.subcategories) do
                    local entryData = ZO_GamepadEntryData:New(GetString(categoryData.subcategoryEnumName, subcategoryId), data.gamepadIcon)
                    entryData:SetIconTintOnSelection(true)
                    entryData.categoryId = categoryId
                    entryData.subcategoryId = subcategoryId

                    self.categoryList:AddEntry("ZO_GamepadMenuEntryTemplate", entryData)

                    index = index + 1
                end
            end
        end
    end

    self.categoryList:Commit()
end

function ZO_GuildHistory_Gamepad:RefreshFooter()
    local currPageNum
    if self.currPageNum then
        currPageNum = self.currPageNum
    else
        currPageNum = 1
    end

    local pageNumberText = zo_strformat(SI_GAMEPAD_PAGED_LIST_PAGE_NUMBER, currPageNum)
    self.footer.pageNumberLabel:SetText(pageNumberText)

    local enablePrevious = self:CanPageLeft()
    local enableNext = self:CanPageRight()
    self.footer.previousButton:SetEnabled(enablePrevious)
    self.footer.nextButton:SetEnabled(enableNext)

    self.footer.control:SetHidden((not enablePrevious) and (not enableNext))
end

function ZO_GuildHistory_Gamepad_Initialize(control)
    GUILD_HISTORY_GAMEPAD = ZO_GuildHistory_Gamepad:New(control)
end
