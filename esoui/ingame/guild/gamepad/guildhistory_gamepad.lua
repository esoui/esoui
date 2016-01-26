local REQUEST_NEWEST_TIME = 5 -- seconds.

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

    self.nextRequestNewestTime = 0
    control:SetHandler("OnUpdate",
        function(control, time)
            if time > self.nextRequestNewestTime then
                self.nextRequestNewestTime = time + REQUEST_NEWEST_TIME
                local targetData = self.categoryList:GetTargetData()
                if targetData and targetData.categoryId and self.guildId then
                    self:RequestNewest()
                end
            end
        end) 

    self.startIndex = 1
    self.requestCount = 0
    self.displayedItems = 0
    self.guildId = 1
    self.atEndOfList = true
    self.initialized = false
    self.guildEvents = {}

    self.tooltipHeaderData = {
        titleText = GetString(SI_GAMEPAD_GUILD_HISTORY_GUILD_EVENT_TITLE),
    }

    self.loading = control:GetNamedChild("Loading")

    self.footer = ZO_PagedListSetupFooter(control:GetNamedChild("Footer"))

    GUILD_HISTORY_GAMEPAD_FRAGMENT = ZO_FadeSceneFragment:New(self.control, true)

    GUILD_HISTORY_GAMEPAD_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            if not self.initialized then
                self.initialized = true
                self:InitializeActivityList()
                self:InitializeKeybindStripDescriptors()
            end

            self:InitializeEvents()
            self:PopulateCategories()
            self.categoryList:SetSelectedIndex(1)
            self:RequestNewest()
            self:SelectCategoryList()
        elseif newState == SCENE_HIDING then
            self:UninitializeEvents()
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
            self.keybindStripDescriptor = nil
            GAMEPAD_NAV_QUADRANT_1_BACKGROUND_FRAGMENT:TakeFocus()
            self.categoryList:Deactivate()
            self.activityList:Deactivate()
        end
    end)
end

function ZO_GuildHistory_Gamepad:OnTargetChanged(list, selectedData, oldSelectedData)
    self.startIndex = 1
    self.atEndOfList = true
    self.activityList:SetFocusToMatchingEntry(self.activityListItems[1])
    self:RequestNewest()
end

function ZO_GuildHistory_Gamepad:NextPage()
    if self.atEndOfList then
        return
    end
    self.activityList:SetFocusToMatchingEntry(self.activityListItems[1])
    self.startIndex = self.startIndex + self.itemsPerPage
    self:RequestOlder()
end

function ZO_GuildHistory_Gamepad:PreviousPage()
    if self.startIndex <= 1 then
        return
    end
    self.startIndex = self.startIndex - self.itemsPerPage
    if self.startIndex < 1 then
        self.startIndex = 1
    end
    self.activityList:SetFocusToMatchingEntry(self.activityListItems[#self.activityListItems])
    if self.startIndex < self.itemsPerPage then
        self:RequestNewest()
    else
        self:PopulateActivityList()
    end
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
                        canFocus = function(control) return not self.atEndOfList end,
                    })
end

function ZO_GuildHistory_Gamepad:InitializeEvents()
    self.control:RegisterForEvent(EVENT_GUILD_HISTORY_CATEGORY_UPDATED, function(_, guildId, category) self:OnGuildHistoryCategoryUpdated(guildId, category) end)
    self.control:RegisterForEvent(EVENT_GUILD_HISTORY_RESPONSE_RECEIVED, function() self:OnGuildHistoryResponseReceived() end)
end

function ZO_GuildHistory_Gamepad:UninitializeEvents()
    self.control:UnregisterForEvent(EVENT_GUILD_HISTORY_CATEGORY_UPDATED)
    self.control:UnregisterForEvent(EVENT_GUILD_HISTORY_RESPONSE_RECEIVED)
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
    self.logKeybindStripDescriptor = {}
    ZO_Gamepad_AddBackNavigationKeybindDescriptorsWithSound(self.logKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, function() self:SelectCategoryList() end)

    self.logKeybindStripDescriptor[#self.logKeybindStripDescriptor + 1] = {
        keybind = "UI_SHORTCUT_LEFT_TRIGGER",
        ethereal = true,
        sound = SOUNDS.GAMEPAD_PAGE_BACK,
        callback = function()
            self:PreviousPage()
        end,
    }
    self.logKeybindStripDescriptor[#self.logKeybindStripDescriptor + 1] = {
        keybind = "UI_SHORTCUT_RIGHT_TRIGGER",
        ethereal = true,
        sound = SOUNDS.GAMEPAD_PAGE_FORWARD,
        callback = function()
            self:NextPage()
        end,
    }
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
    self.guildId = guildId
    if not self.control:IsHidden() then
        self:PopulateCategories()
        self.categoryList:SetSelectedIndex(1)
        self:RequestNewest()
    end
end

function ZO_GuildHistory_Gamepad:RequestNewest()
    local targetData = self.categoryList:GetTargetData()
    local categoryId = targetData.categoryId

    if RequestGuildHistoryCategoryNewest(self.guildId, categoryId) then
        self:IncrementRequestCount()
    elseif self.requestCount == 0 then
        self:PopulateActivityList()
    end
end

function ZO_GuildHistory_Gamepad:RequestOlder()
    local targetData = self.categoryList:GetTargetData()
    local categoryId = targetData.categoryId

    if RequestGuildHistoryCategoryOlder(self.guildId, categoryId) then
        self:IncrementRequestCount()
    elseif self.requestCount == 0 then
        self:PopulateActivityList()
    end
end

function ZO_GuildHistory_Gamepad:IncrementRequestCount()
    self:ShowLoading()
    self.requestCount = self.requestCount + 1
end

function ZO_GuildHistory_Gamepad:DecrementRequestCount()
    self.requestCount = self.requestCount - 1
    if(self.requestCount == 0) then
        self:HideLoading()
        self.nextLoadControlTrigger = nil
    end
end

function ZO_GuildHistory_Gamepad:ShowLoading()
    self.loading:SetHidden(false)
end

function ZO_GuildHistory_Gamepad:HideLoading()
    self.loading:SetHidden(true)
end

function ZO_GuildHistory_Gamepad:OnGuildHistoryCategoryUpdated(guildId, category)
    if self.guildId == guildId then
        local targetData = self.categoryList:GetTargetData()
        if targetData and (targetData.categoryId == category) then
            KEYBIND_STRIP:UpdateKeybindButtonGroup(self.categoryKeybindStripDescriptor)
            self:PopulateActivityList()
        end
    end
end

function ZO_GuildHistory_Gamepad:OnGuildHistoryResponseReceived()
    self:DecrementRequestCount()
    self:PopulateActivityList()
end

function ZO_GuildHistory_Gamepad:PopulateActivityList()
    local targetData = self.categoryList:GetTargetData()
    local categoryId = targetData.categoryId
    local subcategoryId = targetData.subcategoryId

    self.currPageNum = math.floor((self.startIndex / self.itemsPerPage) + 1)

    -- Build and filter the event list.
    ZO_ClearNumericallyIndexedTable(self.guildEvents)
    for eventIndex = 1, GetNumGuildEvents(self.guildId, categoryId) do
        local eventType, secsSinceEvent, param1, param2, param3, param4, param5, param6 = GetGuildEventInfo(self.guildId, categoryId, eventIndex)
        local eventSubcategoryID = ComputeGuildHistoryEventSubcategory(eventType, categoryId)

        if (subcategoryId == nil) or (subcategoryId == eventSubcategoryID) then
            local formatFunction = GUILD_EVENT_EVENT_FORMAT[eventType]
            if formatFunction then
                local eventData = {
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

    table.sort(self.guildEvents, function(event1, event2) return event1.secsSinceEvent < event2.secsSinceEvent end)

    -- Show the filtered entry list.
    local skipIndexes = self.startIndex - 1
    local displayIndex = 1
    for eventIndex = 1, #self.guildEvents do
        if displayIndex > self.itemsPerPage then
            break
        end

        if skipIndexes > 0 then
            skipIndexes = skipIndexes - 1
        else
            local eventData = self.guildEvents[eventIndex]

            local description = eventData.formatFunction(eventData.eventType, eventData.param1, eventData.param2, eventData.param3, eventData.param4, eventData.param5, eventData.param6)
            local time = ZO_FormatDurationAgo(eventData.secsSinceEvent)

            local displayItem = self.activityListItems[displayIndex]
            displayItem:SetHidden(false)
            displayItem.text:SetText(description)
            displayItem.time:SetText(time)
            displayItem.description = description

            displayIndex = displayIndex + 1
        end
    end

    -- Update the number of displayed items here. We do not want to include the "no items" item
    --  added just below.
    self.displayedItems = (displayIndex - 1)

    if displayIndex == 1 then
        if self.startIndex == 1 then
            -- Display a "no items" item if there are truly no items.
            local displayItem = self.activityListItems[displayIndex]
            displayItem:SetHidden(false)
            displayItem.text:SetText(GetString(SI_GAMEPAD_GUILD_HISTORY_FINAL_ITEM))
            displayItem.time:SetText("")
            displayItem.description = nil
            displayIndex = displayIndex + 1
            self.atEndOfList = true
        else
            -- If there are items, but the final page is blank, go back a page and hide
            --  the next page button.
            self.startIndex = self.startIndex - self.itemsPerPage
            if self.startIndex < 1 then
                self.startIndex = 1
            end
            self:PopulateActivityList()
            self.activityList:SetFocusToMatchingEntry(self.activityListItems[self.displayedItems])
            self.atEndOfList = true
            self:UpdateLogTriggerButtons()
            return
        end
    else
        self.atEndOfList = (self.displayedItems < self.itemsPerPage)
    end

    -- Hide any unused items.
    for i = displayIndex, self.itemsPerPage do
        local displayItem = self.activityListItems[i]
        displayItem:SetHidden(true)
    end

    --Update keybinds
    self:RefreshKeybinds()

    -- Update the trigger buttons.
    self:UpdateLogTriggerButtons()
end

function ZO_GuildHistory_Gamepad:PopulateCategories()
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

    local enablePrevious = currPageNum > 1
    self.footer.previousButton:SetEnabled(enablePrevious)

    local enableNext = not self.atEndOfList
    self.footer.nextButton:SetEnabled(enableNext)

    local pageNumberText = zo_strformat(SI_GAMEPAD_PAGED_LIST_PAGE_NUMBER, currPageNum)
    self.footer.pageNumberLabel:SetText(pageNumberText)

    self.footer.control:SetHidden((not enablePrevious) and (not enableNext))
end

function ZO_GuildHistory_Gamepad_Initialize(control)
    GUILD_HISTORY_GAMEPAD = ZO_GuildHistory_Gamepad:New(control)
end
