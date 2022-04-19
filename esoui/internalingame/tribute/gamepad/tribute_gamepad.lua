ZO_TRIBUTE_GAMEPAD_CURSOR_TARGET_TYPES =
{
    NONE = 0,
    CARD = 1,
    PATRON_STALL = 2,
    TURN_TIMER = 3,
}

ZO_TRIBUTE_GAMEPAD_CURSOR_FRICTION_FACTORS =
{
    [ZO_TRIBUTE_GAMEPAD_CURSOR_TARGET_TYPES.NONE] = 1,
    [ZO_TRIBUTE_GAMEPAD_CURSOR_TARGET_TYPES.CARD] = 0.5,
    [ZO_TRIBUTE_GAMEPAD_CURSOR_TARGET_TYPES.PATRON_STALL] = 0.5,
    [ZO_TRIBUTE_GAMEPAD_CURSOR_TARGET_TYPES.TURN_TIMER] = 0.5,
}

ZO_TRIBUTE_GAMEPAD_CURSOR_SPEED = 20
ZO_TRIBUTE_GAMEPAD_CURSOR_FRICTION_INTERPOLATION_RATE = 1

----------------------------
-- Tribute Cursor Gamepad --
----------------------------

ZO_TributeCursor_Gamepad = ZO_InitializingCallbackObject:Subclass()

function ZO_TributeCursor_Gamepad:Initialize(control)
    self.control = control
    self:Reset()
end

function ZO_TributeCursor_Gamepad:Reset()
    self.x, self.y = GuiRoot:GetCenter()
    self.frictionInterpolationFactor = 1

    if self.objectTypeUnderCursor then
        -- Handle potential ObjectUnderCursorChanged callback.
        self:ResetObjectUnderCursor()
    else
        -- Initial setup.
        self.objectTypeUnderCursor = ZO_TRIBUTE_GAMEPAD_CURSOR_TARGET_TYPES.NONE
        self.objectUnderCursor = nil
    end

    self.control:SetAnchor(CENTER, GuiRoot, TOPLEFT, self.x, self.y)
    self.control:SetHidden(true)
    self:RefreshObjectUnderCursor()
end

function ZO_TributeCursor_Gamepad:UpdateDirectionalInput()
    local dx, dy = DIRECTIONAL_INPUT:GetXY(ZO_DI_LEFT_STICK, ZO_DI_DPAD)
    if dx ~= 0 or dy ~= 0 then
        dx, dy = zo_clampLength2D(dx, dy, 1.0) -- clamp dpad output
        local frameDelta = GetFrameDeltaNormalizedForTargetFramerate()
        local magnitude = frameDelta * self.frictionInterpolationFactor * ZO_TRIBUTE_GAMEPAD_CURSOR_SPEED
        dx = dx * magnitude
        dy = -dy * magnitude

        self.control:SetAnchor(CENTER, GuiRoot, TOPLEFT, self.x + dx, self.y + dy)
        self.x, self.y = self.control:GetCenter() -- store clamped values
    end

    self:RefreshObjectUnderCursor()
    local targetFriction = ZO_TRIBUTE_GAMEPAD_CURSOR_FRICTION_FACTORS[self.objectTypeUnderCursor]
    self.frictionInterpolationFactor = zo_deltaNormalizedLerp(self.frictionInterpolationFactor, targetFriction, ZO_TRIBUTE_GAMEPAD_CURSOR_FRICTION_INTERPOLATION_RATE)
end

function ZO_TributeCursor_Gamepad:SetActive(active)
    self.control:SetHidden(not active)
    if active then
        DIRECTIONAL_INPUT:Activate(self, self.control)
    else
        DIRECTIONAL_INPUT:Deactivate(self)
    end
    self:RefreshObjectUnderCursor()
end

function ZO_TributeCursor_Gamepad:RefreshObjectUnderCursor()
    if self.control:IsHidden() then
        local NO_TARGET = nil
        self:ResetObjectUnderCursor(NO_TARGET)
        return
    end

    -- TODO Tribute: Evaluate whether a more efficient solution is needed.
    local targetControl = WINDOW_MANAGER:GetControlAtPoint(self.x, self.y)
    local targetObject = targetControl and targetControl.object
    local isUnderCursor = targetObject and targetObject:IsInstanceOf(ZO_TributeCard) and targetObject:IsWorldCard()
    if not isUnderCursor then
        targetObject = nil
    end
    self:SetObjectUnderCursor(targetObject, ZO_TRIBUTE_GAMEPAD_CURSOR_TARGET_TYPES.CARD, isUnderCursor)
end

function ZO_TributeCursor_Gamepad:SetObjectUnderCursor(object, objectType, isUnderCursor)
    -- Consider any request that has a valid target or for which the object type matches the current target object type;
    -- the target type NONE may also be used to reset the state.
    local previousObjectType = self.objectTypeUnderCursor
    if isUnderCursor or objectType == previousObjectType or objectType == ZO_TRIBUTE_GAMEPAD_CURSOR_TARGET_TYPES.NONE then
        -- Process any request that clears the current target object type or that reassigns the target to a different object.
        local previousObject = self.objectUnderCursor
        if (not isUnderCursor) or object ~= previousObject then
            if isUnderCursor then
                self.objectUnderCursor = object
                self.objectTypeUnderCursor = objectType
            else
                self.objectUnderCursor = nil
                self.objectTypeUnderCursor = ZO_TRIBUTE_GAMEPAD_CURSOR_TARGET_TYPES.NONE
            end

            self:FireCallbacks("ObjectUnderCursorChanged", self.objectUnderCursor, self.objectTypeUnderCursor, previousObject, previousObjectType)
        end
    end
end

function ZO_TributeCursor_Gamepad:ResetObjectUnderCursor()
    local IS_NOT_UNDER_CURSOR = false
    local NO_TARGET = nil
    self:SetObjectUnderCursor(NO_TARGET, ZO_TRIBUTE_GAMEPAD_CURSOR_TARGET_TYPES.NONE, IS_NOT_UNDER_CURSOR)
end

function ZO_TributeCursor_Gamepad:GetObjectUnderCursor()
    if self.control:IsHidden() then
        return nil, ZO_TRIBUTE_GAMEPAD_CURSOR_TARGET_TYPES.NONE
    end
    return self.objectUnderCursor, self.objectTypeUnderCursor
end

function ZO_TributeCursor_Gamepad:IsObjectUnderCursor()
    local object, objectType = self:GetObjectUnderCursor()
    return objectType ~= ZO_TRIBUTE_GAMEPAD_CURSOR_TARGET_TYPES.NONE
end

function ZO_TributeCursor_Gamepad:RefreshInsets()
    if ZO_TRIBUTE_TARGET_VIEWER_MANAGER:IsViewingTargets() then
        self.control:SetClampedToScreenInsets(0, 0, 0, ZO_KEYBIND_STRIP_GAMEPAD_VISUAL_HEIGHT)
    else
        self.control:SetClampedToScreenInsets(0, 0, 0, 0)
    end
end

----------------------------------
-- Tribute Card Tooltip Gamepad --
----------------------------------

local g_cardTooltipControl

function ZO_TributeCardTooltip_Gamepad_Hide()
    local control = g_cardTooltipControl
    if not internalassert(control, "ZO_TributeCardTooltip_Gamepad failed to initialize.") then
        return false
    end

    control:SetHidden(true)
    control:ClearAnchors()
    control.scrollTooltip:ClearLines()
    control.cardObject = nil
    return true
end

function ZO_TributeCardTooltip_Gamepad_Show(cardObject, anchorPoint, anchorControl, anchorRelativePoint, anchorOffsetX, anchorOffsetY)
    if not ZO_TributeCardTooltip_Gamepad_Hide() then
        return
    end

    if cardObject then
        -- Order matters
        local control = g_cardTooltipControl
        control.cardObject = cardObject
        control.tip:LayoutTributeCard(cardObject)
        control:ClearAnchors()
        if anchorPoint then
            control:SetAnchor(anchorPoint, anchorControl, anchorRelativePoint, anchorOffsetX, anchorOffsetY)
        end

        if ZO_TRIBUTE_TARGET_VIEWER_MANAGER:IsViewingBoard() then
            control:SetClampedToScreenInsets(0, -25, 0, ZO_KEYBIND_STRIP_GAMEPAD_VISUAL_HEIGHT)
        else
            control:SetClampedToScreenInsets(0, -25, 0, 25)
        end
		control:SetHidden(false)
    end
end

function ZO_TributeCardTooltip_Gamepad_GetControl()
    return g_cardTooltipControl
end

function ZO_TributeCardTooltip_Gamepad_Initialize(tooltipControl)
    g_cardTooltipControl = tooltipControl

    local function ScreenResizeHandler(control)
        local maxHeight = GuiRoot:GetHeight() - (ZO_GAMEPAD_PANEL_FLOATING_HEIGHT_DISCOUNT * 2)
        control:SetDimensionConstraints(0, 0, 0, maxHeight)
    end

    local DEFAULT_TOOLTIP_STYLES = nil
    ZO_ResizingFloatingScrollTooltip_Gamepad_OnInitialized(g_cardTooltipControl, DEFAULT_TOOLTIP_STYLES, ScreenResizeHandler, LEFT)
    ScreenResizeHandler(g_cardTooltipControl)
end

------------------------------------
-- Tribute Patron Tooltip Gamepad --
------------------------------------

local g_patronTooltipControl

function ZO_TributePatronTooltip_Gamepad_Hide()
    local control = g_patronTooltipControl
    if not internalassert(control, "ZO_TributePatronTooltip_Gamepad failed to initialize.") then
        return false
    end

    control:SetHidden(true)
    control:ClearAnchors()
    control.scrollTooltip:ClearLines()
    control.patronData = nil
    return true
end

function ZO_TributePatronTooltip_Gamepad_Show(patronData, anchorPoint, anchorControl, anchorRelativePoint, anchorOffsetX, anchorOffsetY)
    if not ZO_TributePatronTooltip_Gamepad_Hide() then
        return
    end

    if patronData then
        -- Order matters
        local control = g_patronTooltipControl
        control.patronData = patronData
        control.tip:LayoutTributePatron(patronData)
        control:ClearAnchors()
        if anchorPoint then
            control:SetAnchor(anchorPoint, anchorControl, anchorRelativePoint, anchorOffsetX, anchorOffsetY)
        end
        control:SetHidden(false)
    end
end

function ZO_TributePatronTooltip_Gamepad_GetControl()
    return g_patronTooltipControl
end

function ZO_TributePatronTooltip_Gamepad_Initialize(tooltipControl)
    g_patronTooltipControl = tooltipControl

    local function ScreenResizeHandler(control)
        local maxHeight = GuiRoot:GetHeight() - (ZO_GAMEPAD_PANEL_FLOATING_HEIGHT_DISCOUNT * 2)
        control:SetDimensionConstraints(0, 0, 0, maxHeight)
    end

    local DEFAULT_TOOLTIP_STYLES = nil
    ZO_ResizingFloatingScrollTooltip_Gamepad_OnInitialized(g_patronTooltipControl, DEFAULT_TOOLTIP_STYLES, ScreenResizeHandler, LEFT)
    ScreenResizeHandler(g_patronTooltipControl)
end

----------------------------------------------------
-- Tribute Board Location Patrons Tooltip Gamepad --
----------------------------------------------------

local g_boardLocationPatronsTooltipControl

function ZO_TributeBoardLocationPatronsTooltip_Gamepad_GetControl()
    return g_boardLocationPatronsTooltipControl
end

function ZO_TributeBoardLocationPatronsTooltip_Gamepad_Hide()
    local control = g_boardLocationPatronsTooltipControl
    control:SetHidden(true)
    control:ClearAnchors()
    control.scrollTooltip:ClearLines()
    control.boardLocation = nil
end

function ZO_TributeBoardLocationPatronsTooltip_Gamepad_Show(boardLocation, anchorPoint, anchorControl, anchorRelativePoint, anchorOffsetX, anchorOffsetY)
    ZO_TributeBoardLocationPatronsTooltip_Gamepad_Hide()

    if boardLocation then
        local control = g_boardLocationPatronsTooltipControl
        control.boardLocation = boardLocation

        local boardLocationData = ZO_TRIBUTE_PILE_VIEWER_MANAGER:GetCompositePileData(boardLocation) or ZO_TRIBUTE_PILE_VIEWER_MANAGER:GetPileData(boardLocation)
        control.tip:LayoutTributeBoardLocationPatrons(boardLocationData)

        control:ClearAnchors()
        if anchorPoint then
            control:SetAnchor(anchorPoint, anchorControl, anchorRelativePoint, anchorOffsetX, anchorOffsetY)
        end

        if ZO_TRIBUTE_TARGET_VIEWER_MANAGER:IsViewingBoard() then
            control:SetClampedToScreenInsets(0, -25, 0, ZO_KEYBIND_STRIP_GAMEPAD_VISUAL_HEIGHT)
        else
            control:SetClampedToScreenInsets(0, -25, 0, 25)
        end
        control:SetHidden(false)
    end
end

function ZO_TributeBoardLocationPatronsTooltip_Gamepad_Initialize(tooltipControl)
    g_boardLocationPatronsTooltipControl = tooltipControl

    local function ScreenResizeHandler(control)
        local maxHeight = GuiRoot:GetHeight() - (ZO_GAMEPAD_PANEL_FLOATING_HEIGHT_DISCOUNT * 2)
        control:SetDimensionConstraints(0, 0, 0, maxHeight)
    end

    local DEFAULT_TOOLTIP_STYLES = nil
    ZO_ResizingFloatingScrollTooltip_Gamepad_OnInitialized(g_boardLocationPatronsTooltipControl, DEFAULT_TOOLTIP_STYLES, ScreenResizeHandler, LEFT)
    ScreenResizeHandler(g_boardLocationPatronsTooltipControl)
end