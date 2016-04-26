--[[
---- Lifecycle
--]]

ZO_Fence_Gamepad = ZO_Fence_Base:Subclass()

function ZO_Fence_Gamepad:New(...)
    return ZO_Fence_Base.New(self, ...)
end

function ZO_Fence_Gamepad:Initialize(control)
    self.sceneName = GAMEPAD_STORE_SCENE_NAME

    -- Call base initialize
    ZO_Fence_Base.Initialize(self, control)
    SYSTEMS:RegisterGamepadObject("fence", self)

    local function StateChanged(oldState, newState)
        local mode = STORE_WINDOW_GAMEPAD:GetCurrentMode()
        if newState == SCENE_SHOWN and (mode == ZO_MODE_STORE_LAUNDER or mode == ZO_MODE_STORE_SELL_STOLEN) then
            TriggerTutorial(TUTORIAL_TRIGGER_FENCE_OPENED)
        end
    end

    local storeScene = SCENE_MANAGER:GetScene(GAMEPAD_STORE_SCENE_NAME, SCENE_MANAGER)
    storeScene:RegisterCallback("StateChange", StateChanged)
end

--[[
---- Callbacks
--]]

function ZO_Fence_Gamepad:OnOpened(enableSell, enableLaunder)
    if IsInGamepadPreferredMode() then
        local componentTable = {}
        if enableSell then
            table.insert(componentTable, ZO_MODE_STORE_SELL_STOLEN)
        end

        if enableLaunder then
            table.insert(componentTable, ZO_MODE_STORE_LAUNDER)
        end

        STORE_WINDOW_GAMEPAD:SetActiveComponents(componentTable)

        SCENE_MANAGER:Show(self.sceneName)
    end
end

function ZO_Fence_Gamepad:OnSellSuccess()
    FENCE_SELL_GAMEPAD:OnSuccess()
end

function ZO_Fence_Gamepad:OnLaunderSuccess()
    FENCE_LAUNDER_GAMEPAD:OnSuccess()
end

function ZO_Fence_Gamepad:IsLaundering()
    local currentMode = STORE_WINDOW_GAMEPAD:GetCurrentMode()
    return currentMode == ZO_MODE_STORE_LAUNDER
end

function ZO_Fence_Gamepad:IsSellingStolenItems()
    local currentMode = STORE_WINDOW_GAMEPAD:GetCurrentMode()
    return currentMode == ZO_MODE_STORE_SELL_STOLEN
end

--[[ 
---- Global
--]]

function ZO_Fence_Gamepad_Initialize(control)
    FENCE_GAMEPAD = ZO_Fence_Gamepad:New(control)
    ZO_GamepadFenceLaunder_Initialize()
    ZO_GamepadFenceSell_Initialize()
end