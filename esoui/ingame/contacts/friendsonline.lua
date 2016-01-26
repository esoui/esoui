local FriendsOnlineManager = ZO_Object:Subclass()

function FriendsOnlineManager:New(control)
    local manager = ZO_Object.New(self)
    manager.control = control
    manager:Update()
    return manager
end

function FriendsOnlineManager:Update()
    GetControl(self.control, "NumOnline"):SetText(zo_strformat(SI_FRIENDS_LIST_PANEL_NUM_ONLINE, FRIENDS_LIST_MANAGER:GetNumOnline(), GetNumFriends()))
end

function ZO_FriendsOnline_OnInitialized(self)
    FRIENDS_ONLINE = FriendsOnlineManager:New(self)
end