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
        --Re-narrate when the value changes
        GAMEPAD_BUCKET_MANAGER:NarrateCurrentBucket()
    end
end

function ZO_CharacterCreateTriangle_Gamepad:EnableFocus(enabled)
    if enabled then
        DIRECTIONAL_INPUT:Activate(self, self.control)
    else
        DIRECTIONAL_INPUT:Deactivate(self)
    end
end

function ZO_CharacterCreateTriangle_Gamepad:GetNarrationText()
    local narrations = {}
    local left, right, top = self.picker:GetBarycentricCoordinates()
    ZO_AppendNarration(narrations, ZO_GetTrianglePickerVertexNarrationText(self.topText, top))
    ZO_AppendNarration(narrations, ZO_GetTrianglePickerVertexNarrationText(self.leftText, left))
    ZO_AppendNarration(narrations, ZO_GetTrianglePickerVertexNarrationText(self.rightText, right))
    if self:IsLocked() then
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_SCREEN_NARRATION_LOCKED_ICON_NARRATION)))
    end
    return narrations
end