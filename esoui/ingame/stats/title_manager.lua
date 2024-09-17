ZO_Title_Manager = ZO_InitializingCallbackObject:Subclass()

function ZO_Title_Manager:Initialize()
    EVENT_MANAGER:RegisterForEvent("ZO_Title_Manager", EVENT_PLAYER_TITLES_UPDATE, function(_, ...) self:UpdateTitles() end)
    EVENT_MANAGER:RegisterForEvent("ZO_Title_Manager", EVENT_PLAYER_ACTIVATED, function(_, ...) self:UpdateTitles() end)
end 

function ZO_Title_Manager:UpdateTitles()
    if self.titles then
        -- Handle the delta
        local titles = {}
        local newUnlockedTitles = {}
        for i = 1, GetNumTitles() do
            local name = GetTitle(i)
            local titleInfo = self.titles[name]
            if titleInfo then
                titleInfo.index = i
            else
                titleInfo =
                {
                    index = i,
                    name = name,
                    isNew = true,
                }
                table.insert(newUnlockedTitles, titleInfo)
            end
            titles[name] = titleInfo
        end
        self.titles = titles
        self:FireCallbacks("UpdateTitlesData", newUnlockedTitles)
    else
        self.titles = {}
        for i = 1, GetNumTitles() do
            local name = GetTitle(i)
            local titleInfo =
            {
                index = i,
                name = name,
            }
            self.titles[name] = titleInfo
        end
        self:FireCallbacks("UpdateTitlesData")
    end
end

function ZO_Title_Manager:ClearTitleNew(titleName)
    if self.titles then
        local titleInfo = self.titles[titleName]
        if titleInfo and titleInfo.isNew then
            titleInfo.isNew = false
            self:FireCallbacks("TitleClearedNew", titleInfo)
        end
    end
end

function ZO_Title_Manager:GetTitles()
    return self.titles
end

function ZO_Title_Manager:GetSortedTitles(sortKeys, sortOrder)
    local sortedTitles = {}
    local titles = self:GetTitles()
    sortedTitles = ZO_CreateSortableTableFromValues(titles)
    local function CompareTitleItems(item1, item2) 
        return ZO_TableOrderingFunction(item1, item2, "name", sortKeys , sortOrder) 
    end
    table.sort(sortedTitles, CompareTitleItems)
    return sortedTitles
end

function ZO_Title_Manager:HasNewTitle()
    for _, titleInfo in pairs(self.titles) do
        if titleInfo.isNew then 
            return true
        end
    end
    return false
end

TITLE_MANAGER = ZO_Title_Manager:New()