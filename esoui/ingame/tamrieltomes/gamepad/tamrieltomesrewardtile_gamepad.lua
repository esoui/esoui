---------------------------------------
-- Tamriel Tomes Reward Tile Gamepad --
---------------------------------------

ZO_TamrielTomes_RewardTile_Gamepad = ZO_Object.MultiSubclass(ZO_Tile_Gamepad, ZO_TamrielTomes_RewardTile_Shared)

function ZO_TamrielTomes_RewardTile_Gamepad:New(...)
    return ZO_TamrielTomes_RewardTile_Shared.New(self, ...)
end

function ZO_TamrielTomes_RewardTile_Gamepad:Initialize(control)
    ZO_TamrielTomes_RewardTile_Shared.Initialize(self, control)
end

function ZO_TamrielTomes_RewardTile_Gamepad:Layout(data)
    ZO_TamrielTomes_RewardTile_Shared.Layout(self, data)

    self.rewardControl.object.highlightTexture:SetHidden(data ~= TAMRIEL_TOMES_SCREEN_GAMEPAD:GetSelectedTamrielTomesRewardData())
end

function ZO_TamrielTomes_RewardTile_Gamepad.OnControlInitialized(control)
    ZO_TamrielTomes_RewardTile_Gamepad:New(control)
end

----------------------------------
-- Tamriel Tomes Reward Gamepad --
----------------------------------

ZO_TamrielTomesReward_Gamepad = ZO_TamrielTomesReward_Shared:Subclass()

function ZO_TamrielTomesReward_Gamepad:Initialize(control)
    ZO_TamrielTomesReward_Shared.Initialize(self, control)

    self.currencyOptions = ZO_ShallowTableCopy(ZO_GAMEPAD_CURRENCY_OPTIONS)
    self.currencyOptions.font = "ZoFontGamepad25"
    self.highlightTexture = control:GetNamedChild("Highlight")
end

function ZO_TamrielTomesReward_Gamepad.OnControlInitialized(control)
    ZO_TamrielTomesReward_Gamepad:New(control)
end