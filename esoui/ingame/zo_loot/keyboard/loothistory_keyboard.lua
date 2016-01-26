local KEYBOARD_LOOT_HISTORY_ENTRY_TEMPLATE = "ZO_LootHistory_KeyboardEntry"

local ZO_LootHistory_Keyboard = ZO_LootHistory_Shared:Subclass()

function ZO_LootHistory_Keyboard:New(...)
    return ZO_LootHistory_Shared.New(self, ...)
end

function ZO_LootHistory_Keyboard:Initialize(control)
    ZO_LootHistory_Shared.Initialize(self, control)
end

function ZO_LootHistory_Keyboard:InitializeFragment()
    KEYBOARD_LOOT_HISTORY_FRAGMENT = ZO_HUDFadeSceneFragment:New(ZO_LootHistoryControl_Keyboard)
    KEYBOARD_LOOT_HISTORY_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWN then
            self:DisplayLootQueue()
        elseif newState == SCENE_FRAGMENT_HIDING then
            self:HideLootQueue()
        end
    end)

    SCENE_MANAGER:GetScene("loot"):AddFragment(KEYBOARD_LOOT_HISTORY_FRAGMENT)
end

function ZO_LootHistory_Keyboard:InitializeFadingControlBuffer(control)
    local HORIZ_OFFSET = 0
    local VERTICAL_OFFSET = -84
    local MAX_ENTRIES = 8
    local CONTAINER_SHOW_TIME_MS = 3600
    local anchor = ZO_Anchor:New(BOTTOMRIGHT, GuiRoot, BOTTOMRIGHT, HORIZ_OFFSET, VERTICAL_OFFSET)

    self.lootStream = self:CreateFadingStationaryControlBuffer(control, "ZO_LootHistory_FadeShared", "ZO_LootHistory_IconEntranceShared", "ZO_LootHistory_ContainerFadeShared", anchor, MAX_ENTRIES, CONTAINER_SHOW_TIME_MS, "Keyboard")
end

function ZO_LootHistory_Keyboard:SetEntryTemplate()
    self.entryTemplate = KEYBOARD_LOOT_HISTORY_ENTRY_TEMPLATE
end

local function IsLootFromInventory()
    -- TODO: Figure out a better way to determing if it's from a container in inventory
    return LOOT_WINDOW.returnScene == "inventory" or SCENE_MANAGER:IsShowing("inventory")
end

function ZO_LootHistory_Keyboard:OnLootReceived(...)
    if not IsLootFromInventory() then
        ZO_LootHistory_Shared.OnLootReceived(self, ...)
    end
end

function ZO_LootHistory_Keyboard:OnGoldUpdate(...)
    if not IsLootFromInventory() then
        ZO_LootHistory_Shared.OnGoldUpdate(self, ...)
    end
end

function ZO_LootHistory_Keyboard:OnTelvarStoneUpdate(...)
    if not IsLootFromInventory() then
        ZO_LootHistory_Shared.OnTelvarStoneUpdate(self, ...)
    end
end

function ZO_LootHistory_Keyboard_OnInitialized(control)
    LOOT_HISTORY_KEYBOARD = ZO_LootHistory_Keyboard:New(control)
    SYSTEMS:RegisterKeyboardObject(ZO_LOOT_HISTORY_NAME, LOOT_HISTORY_KEYBOARD)
end