local ZO_PlatformStyleManager = ZO_Object:Subclass()

function ZO_PlatformStyleManager:New()
    local obj = ZO_Object.New(self)
    obj:Initialize()
    return obj
end

function ZO_PlatformStyleManager:Initialize()
    self.objects = {}
    EVENT_MANAGER:RegisterForEvent("ZO_PlatformStyleManager", EVENT_GAMEPAD_PREFERRED_MODE_CHANGED, function() self:OnGamepadPreferredModeChanged() end)
end

function ZO_PlatformStyleManager:Add(object)
    table.insert(self.objects, object)
end

function ZO_PlatformStyleManager:OnGamepadPreferredModeChanged()
    for _, object in ipairs(self.objects) do
        object:Apply()
    end
end

local PLATFORM_STYLE_MANAGER = ZO_PlatformStyleManager:New()


ZO_PlatformStyle = ZO_Object:Subclass()

function ZO_PlatformStyle:New(...)
    local obj = ZO_Object.New(self)
    obj:Initialize(...)
    return obj
end

function ZO_PlatformStyle:Initialize(applyFunction, keyboardStyle, gamepadStyle)
    self.applyFunction = applyFunction
    self.keyboardStyle = keyboardStyle
    self.gamepadStyle = gamepadStyle
    self:Apply()
    PLATFORM_STYLE_MANAGER:Add(self)
end

function ZO_PlatformStyle:Apply()
    local style
    if IsInGamepadPreferredMode() then
        style = self.gamepadStyle
    else
        style = self.keyboardStyle
    end
    self.applyFunction(style)
end