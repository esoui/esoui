ZO_KEYBOARD_LOOT_HISTORY_ENTRY_SPACING_Y = -1
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
    local MAX_ENTRIES = 6
    local CONTAINER_SHOW_TIME_MS = self:GetContainerShowTime()
    local PERSISTENT_CONTAINER_SHOW_TIME_MS = self:GetPersistentContainerShowTime()
    local anchor = ZO_Anchor:New(BOTTOMRIGHT, GuiRoot, BOTTOMRIGHT, HORIZ_OFFSET, VERTICAL_OFFSET)

    self.lootStreamPersistent = self:CreateFadingStationaryControlBuffer(control:GetNamedChild("PersistentContainer"), "ZO_LootHistory_FadeShared", "ZO_LootHistory_IconEntranceShared", "ZO_LootHistory_ContainerFadeShared", anchor, MAX_ENTRIES, PERSISTENT_CONTAINER_SHOW_TIME_MS, "KeyboardPersistent")
    self.lootStream = self:CreateFadingStationaryControlBuffer(control:GetNamedChild("Container"), "ZO_LootHistory_FadeShared", "ZO_LootHistory_IconEntranceShared", "ZO_LootHistory_ContainerFadeShared", anchor, MAX_ENTRIES, CONTAINER_SHOW_TIME_MS, "Keyboard")

    self.lootStreamPersistent:SetAdditionalEntrySpacingY(ZO_KEYBOARD_LOOT_HISTORY_ENTRY_SPACING_Y)
    self.lootStream:SetAdditionalEntrySpacingY(ZO_KEYBOARD_LOOT_HISTORY_ENTRY_SPACING_Y)
end

function ZO_LootHistory_Keyboard:SetEntryTemplate()
    self.entryTemplate = KEYBOARD_LOOT_HISTORY_ENTRY_TEMPLATE
end

function ZO_LootHistory_Shared:CanShowItemsInHistory()
    local currentSceneName = SCENE_MANAGER:GetCurrentSceneName()
    return currentSceneName == "inventory" or currentSceneName == "interact" or currentSceneName == "crownCrateKeyboard" or LOOT_WINDOW.returnScene == "inventory"
end

function ZO_LootHistory_Keyboard_OnInitialized(control)
    LOOT_HISTORY_KEYBOARD = ZO_LootHistory_Keyboard:New(control)
    SYSTEMS:RegisterKeyboardObject(ZO_LOOT_HISTORY_NAME, LOOT_HISTORY_KEYBOARD)
end