local GuildHistoryManager = ZO_SortFilterList:Subclass()

local GUILD_EVENT_DATA = 1
local GUILD_EVENT_TWO_LINES_DATA = 2
local REQUEST_NEWEST_TIME = 5
local LOAD_CONTROL_TRIGGER_TIME = .5

function GuildHistoryManager:New(control)
    return ZO_SortFilterList.New(self, control)
end

function GuildHistoryManager:Initialize(control)
    ZO_SortFilterList.Initialize(self, control)

    self.noEntriesMessageLabel = GetControl(control, "NoEntriesMessage")
    self.control = control
    self.loading = GetControl(control, "Loading")
    self.requestCount = 0
    self.masterList = {}
    
    ZO_ScrollList_AddDataType(self.list, GUILD_EVENT_DATA, "ZO_GuildHistoryRow", 45, function(control, data) self:SetupGuildEvent(control, data) end)
    ZO_ScrollList_AddDataType(self.list, GUILD_EVENT_TWO_LINES_DATA, "ZO_GuildHistoryRowTwoLines", 60, function(control, data) self:SetupGuildEvent(control, data) end)

    self.dummyRowControl = CreateControlFromVirtual("ZO_GuildHistory_TempRowElement", GuiRoot, "ZO_GuildHistoryRow")
    self.dummyRowControl:SetHidden(true)
    self.dummyRowControl:SetAnchor(TOPLEFT)

    self.sortFunction = function(listEntry1, listEntry2) return self:CompareGuildEvents(listEntry1, listEntry2) end
    self.nextRequestNewestTime = 0

    self.updateFunction = function(control, time)
            local forceUpdate = not time
            time = time or GetFrameTimeSeconds()
            if forceUpdate or time > self.nextRequestNewestTime then
                self.nextRequestNewestTime = time + REQUEST_NEWEST_TIME
                if forceUpdate then
                    self.selectedSubcategory = nil
                    self:RefreshData()   
                end     
                if self.selectedCategory and self.guildId then
                    self:RequestNewest(forceUpdate)
                end
            end
            if self.requestCount > 0 then
                if not self.nextLoadControlTrigger then
                    self.nextLoadControlTrigger = time + LOAD_CONTROL_TRIGGER_TIME
                elseif time > self.nextLoadControlTrigger then
                    self.loading:Show()
                end
            end
        end

    control:SetHandler("OnUpdate", self.updateFunction)
    self:SetUpdateInterval(60)

    self:InitializeKeybindDescriptors()
    self:CreateCategoryTree()
    
    control:RegisterForEvent(EVENT_GUILD_HISTORY_CATEGORY_UPDATED, function(_, guildId, category) self:OnGuildHistoryCategoryUpdated(guildId, category) end)
    control:RegisterForEvent(EVENT_GUILD_HISTORY_RESPONSE_RECEIVED, function() self:OnGuildHistoryResponseReceived() end)
    control:RegisterForEvent(EVENT_GUILD_HISTORY_REFRESHED, function() self.updateFunction() end)
    control:RegisterForEvent(EVENT_GUILD_RANK_CHANGED, function() self.updateFunction() end)

    GUILD_HISTORY_SCENE = ZO_Scene:New("guildHistory", SCENE_MANAGER)
    GUILD_HISTORY_SCENE:RegisterCallback("StateChange",     function(oldState, state)
                                                                if(state == SCENE_SHOWING) then
                                                                    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
                                                                elseif(state == SCENE_HIDDEN) then
                                                                    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
                                                                end
                                                            end)
end

function GuildHistoryManager:InitializeKeybindDescriptors()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_RIGHT,

        -- Show More
        {
            name = GetString(SI_GUILD_HISTORY_SHOW_MORE),
            keybind = "UI_SHORTCUT_PRIMARY",

            visible = function()
                return self.selectedCategory ~= nil and self.selectedSubcategory == nil and DoesGuildHistoryCategoryHaveMoreEvents(self.guildId, self.selectedCategory)
            end,
        
            callback = function()
                self:RequestOlder()
            end,
        },
    }
end

function GuildHistoryManager:CreateCategoryTree()
    self.categoryTree = ZO_Tree:New(GetControl(self.control, "Categories"), 60, -10, 220)

    --Category Header

    local function CategoryHeaderSetup(node, control, categoryId, open)
        control.text:SetModifyTextType(MODIFY_TEXT_TYPE_UPPERCASE)
        control.text:SetText(GetString("SI_GUILDHISTORYCATEGORY", categoryId))

        local categoryData = GUILD_HISTORY_CATEGORIES[categoryId]
        control.icon:SetTexture(open and categoryData.down or categoryData.up)
        control.iconHighlight:SetTexture(categoryData.over)
     
        ZO_IconHeader_Setup(control, open)

        if(open) then
            self.categoryTree:SelectFirstChild(node)
        end
    end

    --Subcategory Entry

    self.categoryTree:AddTemplate("ZO_IconHeader", CategoryHeaderSetup, nil, nil, nil, 0)

    local function SubcategoryEntrySetup(node, control, data, open)
        control:SetSelected(false)
        control:SetText(data.name)
    end

    local function SubcategoryEntrySelected(control, data, selected, reselectingDuringRebuild)
        control:SetSelected(selected)
        if(selected) then
            local oldSelectedCategory = self.selectedCategory
            self.selectedCategory = data.categoryId
            self.selectedSubcategory = data.subcategoryId

            --if it's the same category we can just mess with the filter instead of rebuilding the whole list
            if(oldSelectedCategory == self.selectedCategory) then
                self:RefreshFilters()
            else
                self:RequestNewest()
                self:RefreshData()
            end
            ZO_ScrollList_ResetToTop(self.list)
            KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
        end
    end

    self.categoryTree:AddTemplate("ZO_GuildHistorySubcategoryEntry", SubcategoryEntrySetup, SubcategoryEntrySelected)

    --Build Tree
        
    for i = 1, GetNumGuildHistoryCategories() do
        local categoryData = GUILD_HISTORY_CATEGORIES[i]
        if(categoryData) then        
            local categoryNode = self.categoryTree:AddNode("ZO_IconHeader", i, nil, SOUNDS.GUILD_HISTORY_BLADE_SELECTED)
           --All
            self.categoryTree:AddNode("ZO_GuildHistorySubcategoryEntry", {categoryId = i, name = GetString(SI_GUILD_HISTORY_SUBCATEGORY_ALL)}, categoryNode, SOUNDS.GUILD_HISTORY_ENTRY_SELECTED)
            
            if(categoryData.subcategories) then
                for subcategoryId, _ in pairs(categoryData.subcategories) do
                    self.categoryTree:AddNode("ZO_GuildHistorySubcategoryEntry", {categoryId = i, subcategoryId = subcategoryId, name = GetString(categoryData.subcategoryEnumName, subcategoryId)}, categoryNode, SOUNDS.GUILD_HISTORY_ENTRY_SELECTED)
                end
            end
        end
    end

    self.categoryTree:SetExclusive(true)
    self.categoryTree:SetOpenAnimation("ZO_TreeOpenAnimation")
    self.categoryTree:Commit()
end

function GuildHistoryManager:SetGuildId(guildId)
    self.guildId = guildId
    if(self.selectedCategory) then
        self:RequestNewest()
    end
    self:RefreshData()
end

function GuildHistoryManager:SetupGuildEvent(control, data)
    local bg = GetControl(control, "BG")
    local hidden = data.sortIndex and (data.sortIndex % 2) == 0
    bg:SetHidden(hidden)

    if data.description == nil then
        data.description = self:FormatEvent(data.eventType, data.param1, data.param2, data.param3, data.param4, data.param5, data.param6)
    end
    if data.formattedTime == nil then
        data.formattedTime = ZO_FormatDurationAgo(data.secsSinceEvent)
    end
    GetControl(control, "Description"):SetText(data.description)
    GetControl(control, "Time"):SetText(data.formattedTime)
end

function GuildHistoryManager:FormatEvent(eventType, ...)
    local format = GUILD_EVENT_EVENT_FORMAT[eventType]
    if(format) then
        return format(eventType, ...)
    end
end

function GuildHistoryManager:ShouldShowEventType(eventType)
    return GUILD_EVENT_EVENT_FORMAT[eventType] ~= nil
end

function GuildHistoryManager:BuildMasterList()
    if(self.guildId and self.selectedCategory) then
        ZO_ClearNumericallyIndexedTable(self.masterList)
        
        for i = 1, GetNumGuildEvents(self.guildId, self.selectedCategory) do
            local eventType, secsSinceEvent, param1, param2, param3, param4, param5, param6 = GetGuildEventInfo(self.guildId, self.selectedCategory, i)
            if(self:ShouldShowEventType(eventType)) then
                table.insert(self.masterList,   {
                                                    eventType = eventType,
                                                    param1 = param1,
                                                    param2 = param2,
                                                    param3 = param3,
                                                    param4 = param4,
                                                    param5 = param5,  
													param6 = param6,                                                  
                                                    secsSinceEvent = secsSinceEvent,
                                                    subcategoryId = ComputeGuildHistoryEventSubcategory(eventType, self.selectedCategory),
                                                    timeStamp = GetFrameTimeSeconds(),
                                                })
            end
        end
    end
end

function GuildHistoryManager:FilterScrollList()
    local scrollData = ZO_ScrollList_GetDataList(self.list)
    local listWidth = self.list:GetNamedChild("Contents"):GetWidth()
    local descriptionControl = self.dummyRowControl:GetNamedChild("Description")
    
    self.dummyRowControl:SetWidth(listWidth)

    ZO_ClearNumericallyIndexedTable(scrollData)

    for i = 1, #self.masterList do
        local data = self.masterList[i]
        if self.selectedSubcategory == nil or self.selectedSubcategory == data.subcategoryId then
            self:SetupGuildEvent(self.dummyRowControl, data)

            --[[ The dimensions of the description depend on the time label text being rendered 
                 due to the anchoring scheme. The normal immediate anchor update that happens 
                 when calling a function that depends on the text being rendered will not trigger 
                 the time label to render, so we do it manually using Clean. Once that is done, 
                 the immediate anchor update on the description label will succeed and we can 
                 do the GetNumLines call.]]--
            for anchorIndex = 0, MAX_ANCHORS do
               local isValid, point, relTo, relPoint, offsetX = descriptionControl:GetAnchor(anchorIndex)
               if isValid and relTo:GetType() == CT_LABEL then
                    relTo:Clean()
               end
            end
            
            local numLines = descriptionControl:GetNumLines()
            if numLines > 1 then
                table.insert(scrollData, ZO_ScrollList_CreateDataEntry(GUILD_EVENT_TWO_LINES_DATA, data))
            else 
                table.insert(scrollData, ZO_ScrollList_CreateDataEntry(GUILD_EVENT_DATA, data))
            end
        end
    end

    local hasEntries = #scrollData > 0 
    self.noEntriesMessageLabel:SetHidden(hasEntries)
    if not hasEntries then
        self.noEntriesMessageLabel:SetText(ZO_GuildHistory_GetNoEntriesText(self.selectedCategory, self.selectedSubcategory, self.guildId))
    end
end

function GuildHistoryManager:CompareGuildEvents(listEntry1, listEntry2)
    return listEntry1.data.secsSinceEvent < listEntry2.data.secsSinceEvent
end

function GuildHistoryManager:SortScrollList()
    local scrollData = ZO_ScrollList_GetDataList(self.list)
    if(#scrollData > 1) then
        table.sort(scrollData, self.sortFunction)
    end
end

function GuildHistoryManager:RequestNewest(forceUpdate)
    if (GUILD_HISTORY_SCENE and GUILD_HISTORY_SCENE:IsShowing()) or forceUpdate then
        if RequestGuildHistoryCategoryNewest(self.guildId, self.selectedCategory) then
            self:IncrementRequestCount()
        end
    end
end

function GuildHistoryManager:RequestOlder(forceUpdate)
    if (GUILD_HISTORY_SCENE and GUILD_HISTORY_SCENE:IsShowing()) or forceUpdate then
        if(RequestGuildHistoryCategoryOlder(self.guildId, self.selectedCategory)) then
            self:IncrementRequestCount()
        end
    end
end

function GuildHistoryManager:IncrementRequestCount()
    self.requestCount = self.requestCount + 1
end

function GuildHistoryManager:DecrementRequestCount()
    self.requestCount = self.requestCount - 1
    if(self.requestCount == 0) then
        self.loading:Hide()
        self.nextLoadControlTrigger = nil
    end
end

--Events

function GuildHistoryManager:OnGuildHistoryCategoryUpdated(guildId, category)
    if(self.guildId == guildId and self.selectedCategory == category) then
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
        self:RefreshData()
    end
end

function GuildHistoryManager:OnGuildHistoryResponseReceived()
    self:DecrementRequestCount()
end

--Global XML

function ZO_GuildHistory_OnInitialized(self)
    GUILD_HISTORY = GuildHistoryManager:New(self)
end