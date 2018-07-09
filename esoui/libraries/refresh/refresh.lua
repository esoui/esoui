ZO_Refresh = ZO_Object:Subclass()

function ZO_Refresh:New()
    local object = ZO_Object.New(self)
    object.refreshGroups = {}
    object.currentlyRefreshing = false
    return object
end

function ZO_Refresh:AddRefreshGroup(refreshGroup, data)
    data.dirtySingles = {}
    data.wasShown = false
    self.refreshGroups[refreshGroup] = data
end

function ZO_Refresh:RefreshAll(refreshGroup)
    local refreshData = self.refreshGroups[refreshGroup]
    refreshData.allDirty = true
end

function ZO_Refresh:RefreshSingle(refreshGroup, ...)
    local refreshData = self.refreshGroups[refreshGroup]

    if(refreshData.allDirty) then
        return
    end

    local numInList = select("#", ...)
    for _, data in ipairs(refreshData.dirtySingles) do
        local alreadyHaveData = true
        for i = 1, numInList do
            if(data[i] ~= select(i, ...)) then
                alreadyHaveData = false
                break
            end
        end
        if(alreadyHaveData) then
            return
        end
    end

    table.insert(refreshData.dirtySingles, {...})
end

function ZO_Refresh:UpdateRefreshGroups()
    if self.currentlyRefreshing then return end
    self.currentlyRefreshing = true

    for refreshGroup, refreshData in pairs(self.refreshGroups) do
        if(refreshData.IsShown) then
            local dataShown = refreshData.IsShown()
            if(dataShown ~= refreshData.wasShown) then
                refreshData.wasShown = dataShown
                refreshData.RefreshAll()
                refreshData.allDirty = false
                ZO_ClearNumericallyIndexedTable(refreshData.dirtySingles)
            end
        end
        if(refreshData.allDirty or #refreshData.dirtySingles > 0) then
            if(refreshData.IsShown == nil or refreshData.IsShown()) then
                if(refreshData.allDirty) then
                    refreshData.RefreshAll()
                else
                    for _, singleData in ipairs(refreshData.dirtySingles) do
                        refreshData.RefreshSingle(unpack(singleData))
                    end
                end
                refreshData.allDirty = false
                ZO_ClearNumericallyIndexedTable(refreshData.dirtySingles)
            end
        end
    end

    self.currentlyRefreshing = false
end


--Represents a set of nested refresh operations. Each refresh operation should do what the one below it did plus some additional work. The main usecase for this is rebuilding an entire list from scratch vs. just refreshing visible controls.

ZO_OrderedRefreshGroupManager = ZO_Object:Subclass()

function ZO_OrderedRefreshGroupManager:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_OrderedRefreshGroupManager:Initialize()
    self.groupsWaitingForPerFrameClean = {}
    self.OnUpdateCallback = function() self:OnUpdate() end
end

function ZO_OrderedRefreshGroupManager:AddGroupForPerFrameClean(addGroup)
    if next(self.groupsWaitingForPerFrameClean) == nil then
        EVENT_MANAGER:RegisterForUpdate("ZO_OrderedRefreshGroupManager", 0, self.OnUpdateCallback)
    else
        for _, group in ipairs(self.groupsWaitingForPerFrameClean) do
            if group == addGroup then
                return
            end
        end
    end
    table.insert(self.groupsWaitingForPerFrameClean, addGroup)
end

function ZO_OrderedRefreshGroupManager:OnUpdate()
    for _, group in ipairs(self.groupsWaitingForPerFrameClean) do
        group:TryClean()
    end
    ZO_ClearNumericallyIndexedTable(self.groupsWaitingForPerFrameClean)
    EVENT_MANAGER:UnregisterForUpdate("ZO_OrderedRefreshGroupManager")
end

ORDERED_REFRESH_GROUP_MANAGER = ZO_OrderedRefreshGroupManager:New()


ZO_OrderedRefreshGroup = ZO_Object:Subclass()

ZO_ORDERED_REFRESH_GROUP_AUTO_CLEAN_IMMEDIATELY = "immediately"
ZO_ORDERED_REFRESH_GROUP_AUTO_CLEAN_PER_FRAME = "perFrame"
ZO_ORDERED_REFRESH_GROUP_AUTO_CLEAN_NEVER = "never"


function ZO_OrderedRefreshGroup:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_OrderedRefreshGroup:Initialize(autoCleanMode)
    self.activeOrActiveFunction = true
    self.dirtyStates = {}
    self.autoCleanMode = autoCleanMode or ZO_ORDERED_REFRESH_GROUP_AUTO_CLEAN_IMMEDIATELY
end

--Clean is only allowed to happen when the group is active
function ZO_OrderedRefreshGroup:SetActive(activeOrActiveFunction)
    if activeOrActiveFunction ~= self.activeOrActiveFunction then
        self.activeOrActiveFunction = activeOrActiveFunction
        self:TryScheduleClean()
    end
end

function ZO_OrderedRefreshGroup:IsActive()
    if type(self.activeOrActiveFunction) == "function" then
        return self.activeOrActiveFunction()
    else
        return self.activeOrActiveFunction
    end
end

--Order goes from 1 to N where 1 should be a full update and successive numbers are smaller and smaller updates
function ZO_OrderedRefreshGroup:AddDirtyState(name, cleanFunction)
    table.insert(self.dirtyStates,
    {
        name = name,
        order = #self.dirtyStates + 1,
        cleanFunction = cleanFunction,
    })
end

function ZO_OrderedRefreshGroup:IsDirty()
    return self.currentDirtyState ~= nil
end

--A function that prevents a state from being dirtied if the function returns false. Receives everything passed to MarkDirty after name. Can be used to filter out certain events.
function ZO_OrderedRefreshGroup:SetDirtyStateGuard(name, guardFunction)
    local dirtyState = self:GetDirtyState(name)
    dirtyState.guardFunction = guardFunction
end

function ZO_OrderedRefreshGroup:GetDirtyState(name)
    for _, dirtyState in ipairs(self.dirtyStates) do
        if dirtyState.name == name then
            return dirtyState
        end
    end
end

--Marks the state dirty and tries to clean it immediately
function ZO_OrderedRefreshGroup:MarkDirty(name, ...)
    local newDirtyState = self:GetDirtyState(name)

    if newDirtyState.guardFunction then
        if not newDirtyState.guardFunction(...) then
            return
        end
    end

    if self.currentDirtyState then
        --if we already have a dirty state that encompasses the new one then ignore it
        if newDirtyState.order < self.currentDirtyState.order then
            self.currentDirtyState = newDirtyState
        end
    else
        self.currentDirtyState = newDirtyState
    end

    self:TryScheduleClean()
end

function ZO_OrderedRefreshGroup:TryScheduleClean()
    if self:IsDirty() and self:IsActive() then
        if self.autoCleanMode == ZO_ORDERED_REFRESH_GROUP_AUTO_CLEAN_IMMEDIATELY then
            self:TryClean()
        elseif self.autoCleanMode == ZO_ORDERED_REFRESH_GROUP_AUTO_CLEAN_PER_FRAME then
            ORDERED_REFRESH_GROUP_MANAGER:AddGroupForPerFrameClean(self)
        end
    end
end

--This function can be called manually to clean dirty state that happended when the group wasn't active
function ZO_OrderedRefreshGroup:TryClean()
    if self:IsDirty() and self:IsActive() then
        self.currentDirtyState.cleanFunction()
        self.currentDirtyState = nil
    end
end