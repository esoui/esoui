local gamepadKeybindStripDescriptor = nil

local function OnGamepadSceneStateChange(oldState, newState)
    if newState == SCENE_SHOWING then
        if gamepadKeybindStripDescriptor == nil then
            gamepadKeybindStripDescriptor = {
                    alignment = KEYBIND_STRIP_ALIGN_LEFT,
                    KEYBIND_STRIP:GetDefaultGamepadBackButtonDescriptor(),
                }
        end

        KEYBIND_STRIP:AddKeybindButtonGroup(gamepadKeybindStripDescriptor)

    elseif newState == SCENE_HIDDEN then
        KEYBIND_STRIP:RemoveKeybindButtonGroup(gamepadKeybindStripDescriptor)
    end
end

local TreasureMap = ZO_Object:Subclass()

function TreasureMap:New(...)
    local treasureMap = ZO_Object.New(self)
    treasureMap:Initialize(...)
    
    return treasureMap
end

function TreasureMap:Initialize(control)
    self.image = control:GetNamedChild("Image")

    control:RegisterForEvent(EVENT_SHOW_TREASURE_MAP, function(...) self:OnShowTreasureMap(...) end)

    TREASURE_MAP_INVENTORY_SCENE = ZO_Scene:New("treasureMapInventory", SCENE_MANAGER)
    SYSTEMS:RegisterKeyboardRootScene("treasureMapInventory", TREASURE_MAP_INVENTORY_SCENE)

    TREASURE_MAP_QUICK_SLOT_SCENE = ZO_Scene:New("treasureMapQuickSlot", SCENE_MANAGER)
    SYSTEMS:RegisterKeyboardRootScene("treasureMapQuickSlot", TREASURE_MAP_QUICK_SLOT_SCENE)

    GAMEPAD_TREASURE_MAP_INVENTORY_SCENE = ZO_Scene:New("treasureMapInventoryGamepad", SCENE_MANAGER)
    GAMEPAD_TREASURE_MAP_INVENTORY_SCENE:RegisterCallback("StateChange", OnGamepadSceneStateChange)
    SYSTEMS:RegisterGamepadRootScene("treasureMapInventory", GAMEPAD_TREASURE_MAP_INVENTORY_SCENE)

    GAMEPAD_TREASURE_MAP_QUICK_SLOT_SCENE = ZO_Scene:New("treasureMapQuickSlotGamepad", SCENE_MANAGER)
    GAMEPAD_TREASURE_MAP_QUICK_SLOT_SCENE:RegisterCallback("StateChange", OnGamepadSceneStateChange)
    SYSTEMS:RegisterGamepadRootScene("treasureMapQuickSlot", GAMEPAD_TREASURE_MAP_QUICK_SLOT_SCENE)
end

function TreasureMap:OnShowTreasureMap(eventCode, treasureMapIndex)
    local name, imagePath = GetTreasureMapInfo(treasureMapIndex)
    self.image:SetTexture(imagePath)

    if SCENE_MANAGER:IsShowingBaseScene() then
        SYSTEMS:ShowScene("treasureMapQuickSlot")
    else
        SYSTEMS:PushScene("treasureMapInventory")
    end
end

function ZO_TreasureMap_OnInitialize(control)
    TREASURE_MAP = TreasureMap:New(control)
end
