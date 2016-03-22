-----------------
-- Base Leaderboard Object
-----------------

ZO_LeaderboardBase_Shared = ZO_Object:Subclass()

function ZO_LeaderboardBase_Shared:New(...)
    local manager = ZO_Object.New(self)
    manager:Initialize(...)
    return manager
end

function ZO_LeaderboardBase_Shared:Initialize(control, leaderboardSystem, leaderboardScene, fragment)
    self.control = control
    self.leaderboardSystem = leaderboardSystem
    self.leaderboardScene = leaderboardScene
    self.fragment = fragment
    self.scoringInfoText = ""
    self.timerLabelIdentifier = nil
    self.currentScoreData = nil
    self.currentRankData = nil
    self.timerLabelData = nil   
end

function ZO_LeaderboardBase_Shared:OnDataChanged()
    self.leaderboardSystem:UpdateCategories()
    self.leaderboardSystem:OnLeaderboardDataChanged(self)
end

function ZO_LeaderboardBase_Shared:OnSelected()
    self.leaderboardScene:AddFragment(self.fragment)
end

function ZO_LeaderboardBase_Shared:OnUnselected()
    self.leaderboardScene:RemoveFragment(self.fragment)
end

function ZO_LeaderboardBase_Shared:OnSubtypeSelected(subType)
    self.selectedSubType = subType
end

function ZO_LeaderboardBase_Shared:TryAddKeybind()
    if self.keybind then
        KEYBIND_STRIP:AddKeybindButton(self.keybind)
    end
end

function ZO_LeaderboardBase_Shared:TryRemoveKeybind()
    if self.keybind then
        KEYBIND_STRIP:RemoveKeybindButton(self.keybind)
    end
end
