local PlatformStyleManager = ZO_InitializingObject:Subclass()

function PlatformStyleManager:Initialize()
    self.objects = {}
    EVENT_MANAGER:RegisterForEvent("ZO_PlatformStyleManager", EVENT_GAMEPAD_PREFERRED_MODE_CHANGED, function() self:OnGamepadPreferredModeChanged() end)
end

function PlatformStyleManager:Add(object)
    table.insert(self.objects, object)
end

function PlatformStyleManager:OnGamepadPreferredModeChanged()
    for _, object in ipairs(self.objects) do
        object:Apply()
    end
end

local PLATFORM_STYLE_MANAGER = PlatformStyleManager:New()


ZO_PlatformStyle = ZO_InitializingObject:Subclass()

function ZO_PlatformStyle:Initialize(applyFunction, keyboardStyle, gamepadStyle)
    self.applyFunction = applyFunction
    self.keyboardStyle = keyboardStyle
    self.gamepadStyle = gamepadStyle
    self:Apply()
    PLATFORM_STYLE_MANAGER:Add(self)
end

function ZO_PlatformStyle:Apply()
    local style = self:GetStyle()
    self.applyFunction(style)
end

function ZO_PlatformStyle:GetStyle()
    if IsInGamepadPreferredMode() then
        return self.gamepadStyle
    else
        return self.keyboardStyle
    end
end