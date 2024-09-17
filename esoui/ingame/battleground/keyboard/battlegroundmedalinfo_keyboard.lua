---------------------
-- Match Info Panel --
----------------------

ZO_BATTLEGROUND_MATCH_INFO_MEDAL_ANCHOR_PADDING_Y_KEYBOARD = 10

ZO_BattlegroundMatchInfo_Keyboard = ZO_BattlegroundMatchInfo_Shared:Subclass()

function ZO_BattlegroundMatchInfo_Keyboard:Initialize(...)
    ZO_BattlegroundMatchInfo_Shared.Initialize(self, ...)
    BATTLEGROUND_MATCH_INFO_KEYBOARD_FRAGMENT = self:GetFragment()
    SYSTEMS:RegisterKeyboardObject("matchInfo", self)
end

function ZO_BattlegroundMatchInfo_Keyboard_OnInitialize(...)
    BATTLEGROUND_MATCH_INFO_KEYBOARD = ZO_BattlegroundMatchInfo_Keyboard:New(...)
end