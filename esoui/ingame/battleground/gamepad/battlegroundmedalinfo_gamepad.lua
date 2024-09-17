---------------------
-- Match Info Panel --
----------------------

ZO_BATTLEGROUND_MATCH_INFO_MEDAL_ANCHOR_PADDING_Y_GAMEPAD = 20

ZO_BattlegroundMatchInfo_Gamepad = ZO_BattlegroundMatchInfo_Shared:Subclass()

function ZO_BattlegroundMatchInfo_Gamepad:Initialize(...)
    ZO_BattlegroundMatchInfo_Shared.Initialize(self, ...)
    BATTLEGROUND_MATCH_INFO_GAMEPAD_FRAGMENT = self:GetFragment()
    SYSTEMS:RegisterGamepadObject("matchInfo", self)
end

function ZO_BattlegroundMatchInfo_Gamepad_OnInitialize(...)
    BATTLEGROUND_MATCH_INFO_GAMEPAD = ZO_BattlegroundMatchInfo_Gamepad:New(...)
end