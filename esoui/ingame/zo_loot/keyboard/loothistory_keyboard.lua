ZO_KEYBOARD_LOOT_HISTORY_ENTRY_SPACING_Y = -1
local KEYBOARD_LOOT_HISTORY_ENTRY_TEMPLATE = "ZO_LootHistory_KeyboardEntry"

local ZO_LootHistory_Keyboard = ZO_LootHistory_Shared:Subclass()

function ZO_LootHistory_Keyboard:New(...)
    return ZO_LootHistory_Shared.New(self, ...)
end

function ZO_LootHistory_Keyboard:Initialize(control)
    self.control = control

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

do
    local SUPPORTED_SCENES =
    {
        ["inventory"] = true,
        ["interact"] = true,
        ["crownCrateKeyboard"] = true,
        ["trade"] = true,
        ["stats"] = true,
        ["giftInventoryViewKeyboard"] = true,
        ["dailyLoginRewards"] = true,
        ["mailInbox"] = true,
        ["market"] = true,
    }
    function ZO_LootHistory_Keyboard:CanShowItemsInHistory()
        local currentSceneName = SCENE_MANAGER:GetCurrentSceneName()
        return not self.hidden or SUPPORTED_SCENES[currentSceneName] or LOOT_WINDOW.returnScene == "inventory"
    end
end

do
    local STATUS_ICONS =
    {
        [ZO_LOOT_HISTORY_DISPLAY_TYPE_CRAFT_BAG] = "EsoUI/Art/HUD/lootHistory_icon_craftBag.dds",
        [ZO_LOOT_HISTORY_DISPLAY_TYPE_STOLEN] = "EsoUI/Art/Inventory/inventory_stolenItem_icon.dds",
        [ZO_LOOT_HISTORY_DISPLAY_TYPE_COLLECTIONS] = "EsoUI/Art/HUD/Keyboard/lootHistory_icon_collections.dds",
        [ZO_LOOT_HISTORY_DISPLAY_TYPE_ANTIQUITIES] = "EsoUI/Art/HUD/Keyboard/lootHistory_icon_antiquities.dds",
        [ZO_LOOT_HISTORY_DISPLAY_TYPE_CROWN_CRATE] = "EsoUI/Art/HUD/Keyboard/lootHistory_icon_crownCrates.dds",
    }

    function ZO_LootHistory_Keyboard:GetStatusIcon(displayType)
        return STATUS_ICONS[displayType]
    end
end

do
    local HIGHLIGHTS =
    {
        [ZO_LOOT_HISTORY_DISPLAY_TYPE_CRAFT_BAG] = "EsoUI/Art/HUD/lootHistory_highlight.dds",
        [ZO_LOOT_HISTORY_DISPLAY_TYPE_STOLEN] = "EsoUI/Art/HUD/lootHistory_highlight_stolen.dds",
        [ZO_LOOT_HISTORY_DISPLAY_TYPE_COLLECTIONS] = "EsoUI/Art/HUD/lootHistory_highlight.dds",
        [ZO_LOOT_HISTORY_DISPLAY_TYPE_ANTIQUITIES] = "EsoUI/Art/HUD/lootHistory_highlight.dds",
        [ZO_LOOT_HISTORY_DISPLAY_TYPE_CROWN_CRATE] = "EsoUI/Art/HUD/lootHistory_highlight.dds",
    }

    function ZO_LootHistory_Keyboard:GetHighlight(displayType)
        return HIGHLIGHTS[displayType]
    end
end

function ZO_LootHistory_Keyboard_OnInitialized(control)
    LOOT_HISTORY_KEYBOARD = ZO_LootHistory_Keyboard:New(control)
    SYSTEMS:RegisterKeyboardObject(ZO_LOOT_HISTORY_NAME, LOOT_HISTORY_KEYBOARD)
end