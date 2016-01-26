GroupMembersManager_Shared = ZO_Object:Subclass()

function GroupMembersManager_Shared:New(...)
    local manager = ZO_Object.New(self)
    manager:Initialize(...)
    return manager
end

function GroupMembersManager_Shared:Initialize(control)
    self.control = control

    local function OnGroupChanged()
        self:Update()
    end
    control:RegisterForEvent(EVENT_GROUP_MEMBER_LEFT, OnGroupChanged)
    control:RegisterForEvent(EVENT_GROUP_MEMBER_JOINED, OnGroupChanged)
    control:RegisterForEvent(EVENT_GROUP_UPDATE, OnGroupChanged)
end

function GroupMembersManager_Shared:GetGroupSizeText()
    local groupSize = GetGroupSize()
    local maxGroupSize = (groupSize > SMALL_GROUP_SIZE_THRESHOLD) and GROUP_SIZE_MAX or SMALL_GROUP_SIZE_THRESHOLD

    return zo_strformat(SI_GROUP_LIST_PANEL_GROUP_MEMBERS_COUNT, groupSize, maxGroupSize)
end

function GroupMembersManager_Shared:Update()
    assert(false) --this function must be overridden in a sub-class
end