ZO_GAMEPAD_LOOT_HISTORY_ENTRY_SPACING_Y = -1
local GAMEPAD_LOOT_HISTORY_ENTRY_TEMPLATE = "ZO_LootHistory_GamepadEntry"

local ZO_LootHistory_Gamepad = ZO_LootHistory_Shared:Subclass()

function ZO_LootHistory_Gamepad:New(...)
    return ZO_LootHistory_Shared.New(self, ...)
end

function ZO_LootHistory_Gamepad:Initialize(control)
    ZO_LootHistory_Shared.Initialize(self, control)
end

function ZO_LootHistory_Gamepad:InitializeFragment()
    GAMEPAD_LOOT_HISTORY_FRAGMENT = ZO_HUDFadeSceneFragment:New(ZO_LootHistoryControl_Gamepad)
    GAMEPAD_LOOT_HISTORY_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWN then
            self:DisplayLootQueue()
        elseif newState == SCENE_FRAGMENT_HIDING then
            self:HideLootQueue()
        end
    end)

    SCENE_MANAGER:GetScene("lootGamepad"):AddFragment(GAMEPAD_LOOT_HISTORY_FRAGMENT)
end

function ZO_LootHistory_Gamepad:InitializeFadingControlBuffer(control)
    local HORIZ_OFFSET = 0
    local VERTICAL_OFFSET = -120
    local anchor = ZO_Anchor:New(BOTTOMLEFT, GuiRoot, BOTTOMLEFT, HORIZ_OFFSET, VERTICAL_OFFSET)
    local MAX_ENTRIES = 5
    local CONTAINER_SHOW_TIME_MS = self:GetContainerShowTime()
    local PERSISTENT_CONTAINER_SHOW_TIME_MS = self:GetPersistentContainerShowTime()

    self.lootStreamPersistent = self:CreateFadingStationaryControlBuffer(control:GetNamedChild("PersistentContainer"), "ZO_LootHistory_FadeShared", "ZO_LootHistory_IconEntranceShared", "ZO_LootHistory_ContainerFadeShared", anchor, MAX_ENTRIES, PERSISTENT_CONTAINER_SHOW_TIME_MS, "GamepadPersistent")
    self.lootStream = self:CreateFadingStationaryControlBuffer(control:GetNamedChild("Container"), "ZO_LootHistory_FadeShared", "ZO_LootHistory_IconEntranceShared", "ZO_LootHistory_ContainerFadeShared", anchor, MAX_ENTRIES, CONTAINER_SHOW_TIME_MS, "Gamepad")

    self.lootStreamPersistent:SetAdditionalEntrySpacingY(ZO_GAMEPAD_LOOT_HISTORY_ENTRY_SPACING_Y)
    self.lootStream:SetAdditionalEntrySpacingY(ZO_GAMEPAD_LOOT_HISTORY_ENTRY_SPACING_Y)
end

function ZO_LootHistory_Gamepad:SetEntryTemplate()
    self.entryTemplate = GAMEPAD_LOOT_HISTORY_ENTRY_TEMPLATE
end

do
    local SUPPORTED_SCENES =
    {
        ["gamepadInteract"] = true,
        ["gamepad_inventory_root"] = true,
        ["crownCrateGamepad"] = true,
        ["gamepadTrade"] = true,
        ["gamepad_stats_root"] = true,
        ["LevelUpRewardsClaimGamepad"] = true,
        ["giftInventoryViewGamepad"] = true,
        ["playerSubmenu"] = true, -- Need this for daily login since this is the scene it exists in
        ["mailManagerGamepad"] = true,
        ["gamepad_market_purchase"] = true,
    }
    function ZO_LootHistory_Gamepad:CanShowItemsInHistory()
        local currentSceneName = SCENE_MANAGER:GetCurrentSceneName()
        return not self.hidden or SUPPORTED_SCENES[currentSceneName] or SCENE_MANAGER:IsSceneOnStack("gamepad_inventory_root")
    end
end

function ZO_LootHistory_Gamepad:GetCraftBagIcon()
    return "EsoUI/Art/HUD/Gamepad/gp_lootHistory_icon_craftBag.dds"
end

function ZO_LootHistory_Gamepad:GetStolenIcon()
    return "EsoUI/Art/Inventory/GamePad/gp_inventory_icon_stolenItem.dds"
end

function ZO_LootHistory_Gamepad:GetCraftBagHighlight()
    return "EsoUI/Art/HUD/Gamepad/gp_lootHistory_highlight.dds"
end

function ZO_LootHistory_Gamepad:GetStolenHighlight()
    return "EsoUI/Art/HUD/Gamepad/gp_lootHistory_highlight_stolen.dds"
end

function ZO_LootHistory_Gamepad_OnInitialized(control)
    LOOT_HISTORY_GAMEPAD = ZO_LootHistory_Gamepad:New(control)
    SYSTEMS:RegisterGamepadObject(ZO_LOOT_HISTORY_NAME, LOOT_HISTORY_GAMEPAD)
end