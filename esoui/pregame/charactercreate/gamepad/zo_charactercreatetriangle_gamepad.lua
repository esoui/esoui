ZO_CharacterCreateTriangle_Gamepad = ZO_CharacterCreateTriangle_Base:Subclass()

function ZO_CharacterCreateTriangle_Gamepad:New(triangleControl, setterFn, updaterFn, triangleStringId, topStringId, leftStringId, rightStringId)
    local triangle = ZO_CharacterCreateTriangle_Base.New(self, triangleControl, setterFn, updaterFn, triangleStringId, topStringId, leftStringId, rightStringId)

    -- Prevent the Focus Movement Controller from interfering with the triangle movement
    triangle.disableFocusMovementController = true

    return triangle
end

function ZO_CharacterCreateTriangle_Gamepad:UpdateDirectionalInput()
    if self:IsLocked() then
        return
    end

    local x, y = self.picker:GetThumbPosition()
    x = x / self.width
    y = y / self.height

    local mx, my = DIRECTIONAL_INPUT:GetXY(ZO_DI_LEFT_STICK, ZO_DI_DPAD)

    local deadZone = 0.0
    local scale = 0.02

    local changed = false
    if math.abs(mx) > deadZone then
        x = x + mx * scale
        changed = true
    end

    if math.abs(my) > deadZone then
        y = y - my * scale
        changed = true
    end

    if changed then
        self:SetValue(self.width * x, self.height * y)
        self:Update()
    end
end

function ZO_CharacterCreateTriangle_Gamepad:EnableFocus(enabled)
    if enabled then
        DIRECTIONAL_INPUT:Activate(self, self.control)
    else
        DIRECTIONAL_INPUT:Deactivate(self)
    end
end