local GroupMembersManager = GroupMembersManager_Shared:Subclass()

function GroupMembersManager:New(...)
    return GroupMembersManager_Shared.New(self, ...)
end

function GroupMembersManager:Initialize(control)
    GroupMembersManager_Shared.Initialize(self, control)

    self.groupSizeControl = control:GetNamedChild("Count")
    self:Update()
end

function GroupMembersManager_Shared:Update()
    self.groupSizeControl:SetText(self:GetGroupSizeText())
end

function ZO_GroupMembers_OnInitialized(self)
    GROUP_MEMBERS = GroupMembersManager:New(self)
end