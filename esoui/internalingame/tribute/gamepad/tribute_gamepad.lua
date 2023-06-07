ZO_TRIBUTE_GAMEPAD_CURSOR_TARGET_TYPES =
{
    NONE = 0,
    CARD = 1,
    MECHANIC_TILE = 2,
    PATRON_STALL = 3,
    TURN_TIMER = 4,
    RESOURCE_TOKEN = 5,
    DISCARD_COUNTER = 6,
    PATRON_USAGE_COUNTER = 7,
}

ZO_TRIBUTE_GAMEPAD_CURSOR_FRICTION_FACTORS =
{
    [ZO_TRIBUTE_GAMEPAD_CURSOR_TARGET_TYPES.NONE] = 1,
    [ZO_TRIBUTE_GAMEPAD_CURSOR_TARGET_TYPES.CARD] = 0.5,
    [ZO_TRIBUTE_GAMEPAD_CURSOR_TARGET_TYPES.MECHANIC_TILE] = 0.4,
    [ZO_TRIBUTE_GAMEPAD_CURSOR_TARGET_TYPES.PATRON_STALL] = 0.5,
    --TODO Tribute: Turn timer target type is not currently hooked up to anything
    [ZO_TRIBUTE_GAMEPAD_CURSOR_TARGET_TYPES.TURN_TIMER] = 0.5,
    [ZO_TRIBUTE_GAMEPAD_CURSOR_TARGET_TYPES.RESOURCE_TOKEN] = 0.25,
    [ZO_TRIBUTE_GAMEPAD_CURSOR_TARGET_TYPES.DISCARD_COUNTER] = 0.5,
    [ZO_TRIBUTE_GAMEPAD_CURSOR_TARGET_TYPES.PATRON_USAGE_COUNTER] = 0.25,
}

ZO_TRIBUTE_GAMEPAD_CURSOR_MANUAL_TARGET_TYPES =
{
    [ZO_TRIBUTE_GAMEPAD_CURSOR_TARGET_TYPES.PATRON_STALL] = true,
    [ZO_TRIBUTE_GAMEPAD_CURSOR_TARGET_TYPES.RESOURCE_TOKEN] = true,
    [ZO_TRIBUTE_GAMEPAD_CURSOR_TARGET_TYPES.PATRON_USAGE_COUNTER] = true,
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
    local cursorMoved = false
    local dx, dy = DIRECTIONAL_INPUT:GetXY(ZO_DI_LEFT_STICK, ZO_DI_DPAD)
    if dx ~= 0 or dy ~= 0 then
        dx, dy = zo_clampLength2D(dx, dy, 1.0) -- Clamp dpad output
        local frameDelta = GetFrameDeltaNormalizedForTargetFramerate()
        local magnitude = frameDelta * self.frictionInterpolationFactor * ZO_TRIBUTE_GAMEPAD_CURSOR_SPEED
        dx = dx * magnitude
        dy = -dy * magnitude

        self.control:SetAnchor(CENTER, GuiRoot, TOPLEFT, self.x + dx, self.y + dy)
        local clampedX, clampedY = self.control:GetCenter()
        if clampedX ~= self.x or clampedY ~= self.y then
            self.x, self.y = clampedX, clampedY
            cursorMoved = true
        end
    end

    self:RefreshObjectUnderCursor()
    local targetFriction = ZO_TRIBUTE_GAMEPAD_CURSOR_FRICTION_FACTORS[self.objectTypeUnderCursor]
    self.frictionInterpolationFactor = zo_deltaNormalizedLerp(self.frictionInterpolationFactor, targetFriction, ZO_TRIBUTE_GAMEPAD_CURSOR_FRICTION_INTERPOLATION_RATE)

    if cursorMoved then
        -- Defer firing of this callback until after the object under the cursor has been evaluated in order to ensure
        -- that any potential call to GetObjectUnderCursor() from a callback handler will provide a valid response.
        self:OnCursorPositionChanged()
    end
end

function ZO_TributeCursor_Gamepad:OnCursorPositionChanged()
    self:FireCallbacks("CursorPositionChanged", self.x, self.y)
end

function ZO_TributeCursor_Gamepad:SetActive(active)
    self.control:SetHidden(not active)
    if active then
        DIRECTIONAL_INPUT:Activate(self, self.control)
    else
        DIRECTIONAL_INPUT:Deactivate(self)
    end

    if WINDOW_MANAGER:AreCustomCursorsEnabled() then
        if active then
            if not self.cursorId then
                self.cursorId = WINDOW_MANAGER:CreateCursor(self.x, self.y)
            end
        else
            if self.cursorId then
                WINDOW_MANAGER:DestroyCursor(self.cursorId)
                self.cursorId = nil
            end
        end
    end

    -- Order matters
    self:RefreshObjectUnderCursor()
    self:FireCallbacks("CursorStateChanged", active)
    if active then
        -- Fire this callback upon activation in order to ensure that registered handlers are immediately
        -- aware of the current cursor position without requiring subsequent motion.
        -- Note:
        -- Firing of this callback is deferred until after CursorStateChanged is fired so that handlers
        -- are aware of the new cursor state when receiving the CursorPositionChanged callback.
        self:OnCursorPositionChanged()
    end
end

function ZO_TributeCursor_Gamepad:RefreshObjectUnderCursor()
    if self.control:IsHidden() then
        local NO_TARGET = nil
        self:ResetObjectUnderCursor(NO_TARGET)
        return
    end

    -- TODO Tribute: Evaluate whether a more efficient solution is needed.
    local targetControl
    if WINDOW_MANAGER:AreCustomCursorsEnabled() then
        WINDOW_MANAGER:UpdateCursorPosition(self.cursorId, self.x, self.y)
        targetControl = WINDOW_MANAGER:GetControlAtCursor(self.cursorId) 
    else
        targetControl = WINDOW_MANAGER:GetControlAtPoint(self.x, self.y)
    end

    local targetObject = targetControl and targetControl.object
    local objectType = ZO_TRIBUTE_GAMEPAD_CURSOR_TARGET_TYPES.NONE
    local isUnderCursor = false

    if targetObject then
        if targetObject:IsInstanceOf(ZO_TributeCard) and targetObject:IsWorldCard() then
            objectType = ZO_TRIBUTE_GAMEPAD_CURSOR_TARGET_TYPES.CARD
            isUnderCursor = true
        elseif targetObject:IsInstanceOf(ZO_TributeDiscardCountDisplay) then
            objectType = ZO_TRIBUTE_GAMEPAD_CURSOR_TARGET_TYPES.DISCARD_COUNTER
            isUnderCursor = true
        elseif targetObject:IsInstanceOf(ZO_TributeMechanicTile) then
            objectType = ZO_TRIBUTE_GAMEPAD_CURSOR_TARGET_TYPES.MECHANIC_TILE
            isUnderCursor = true
        end
    end

    if not ZO_TRIBUTE_GAMEPAD_CURSOR_MANUAL_TARGET_TYPES[self.objectTypeUnderCursor] then
        self:SetObjectUnderCursor(targetObject, objectType, isUnderCursor)
    end
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
    --If there is a viewer up, check to see if we need to adjust the insets to account for a keybind strip
    local activeViewer = TRIBUTE:GetActiveViewer()
    if activeViewer and activeViewer:IsKeybindStripVisible() then
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

function ZO_TributePatronTooltip_Gamepad_Show(patronData, optionalArgs, anchorPoint, anchorControl, anchorRelativePoint, anchorOffsetX, anchorOffsetY)
    if not ZO_TributePatronTooltip_Gamepad_Hide() then
        return
    end

    if patronData then
        -- Order matters
        local control = g_patronTooltipControl
        control.patronData = patronData
        control.tip:LayoutTributePatron(patronData, optionalArgs)
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

---------------------------------------
-- Tribute Patron Usage Tooltip Gamepad --
---------------------------------------

local g_patronUsageTooltipControl

function ZO_TributePatronUsageTooltip_Gamepad_Hide()
    local control = g_patronUsageTooltipControl
    if not internalassert(control, "ZO_TributePatronUsageTooltip_Gamepad failed to initialize.") then
        return false
    end

    control:SetHidden(true)
    control:ClearAnchors()
    control.scrollTooltip:ClearLines()
    return true
end

function ZO_TributePatronUsageTooltip_Gamepad_Show(anchorPoint, anchorControl, anchorRelativePoint, anchorOffsetX, anchorOffsetY)
    if not ZO_TributePatronUsageTooltip_Gamepad_Hide() then
        return
    end

    -- Order matters
    local control = g_patronUsageTooltipControl
    control.tip:LayoutTributePatronUsage()
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

function ZO_TributePatronUsageTooltip_Gamepad_GetControl()
    return g_patronUsageTooltipControl
end

function ZO_TributePatronUsageTooltip_Gamepad_Initialize(tooltipControl)
    g_patronUsageTooltipControl = tooltipControl

    local function ScreenResizeHandler(control)
        local maxHeight = GuiRoot:GetHeight() - (ZO_GAMEPAD_PANEL_FLOATING_HEIGHT_DISCOUNT * 2)
        control:SetDimensionConstraints(0, 0, 0, maxHeight)
    end

    local DEFAULT_TOOLTIP_STYLES = nil
    ZO_ResizingFloatingScrollTooltip_Gamepad_OnInitialized(g_patronUsageTooltipControl, DEFAULT_TOOLTIP_STYLES, ScreenResizeHandler, LEFT)
    ScreenResizeHandler(g_patronUsageTooltipControl)
end

----------------------------------
-- Tribute Resource Tooltip Gamepad --
----------------------------------

local g_resourceTooltipControl

function ZO_TributeResourceTooltip_Gamepad_Hide()
    local control = g_resourceTooltipControl
    if not internalassert(control, "ZO_TributeResourceTooltip_Gamepad failed to initialize.") then
        return false
    end

    control:SetHidden(true)
    control:ClearAnchors()
    control.scrollTooltip:ClearLines()
    control.resource = nil
    return true
end

function ZO_TributeResourceTooltip_Gamepad_Show(resource, anchorPoint, anchorControl, anchorRelativePoint, anchorOffsetX, anchorOffsetY)
    if not ZO_TributeResourceTooltip_Gamepad_Hide() then
        return
    end

    if resource then
        -- Order matters
        local control = g_resourceTooltipControl
        control.resource = resource
        control.tip:LayoutTributeResource(resource)
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

function ZO_TributeResourceTooltip_Gamepad_GetControl()
    return g_resourceTooltipControl
end

function ZO_TributeResourceTooltip_Gamepad_Initialize(tooltipControl)
    g_resourceTooltipControl = tooltipControl

    local function ScreenResizeHandler(control)
        local maxHeight = GuiRoot:GetHeight() - (ZO_GAMEPAD_PANEL_FLOATING_HEIGHT_DISCOUNT * 2)
        control:SetDimensionConstraints(0, 0, 0, maxHeight)
    end

    local DEFAULT_TOOLTIP_STYLES = nil
    ZO_ResizingFloatingScrollTooltip_Gamepad_OnInitialized(g_resourceTooltipControl, DEFAULT_TOOLTIP_STYLES, ScreenResizeHandler, LEFT)
    ScreenResizeHandler(g_resourceTooltipControl)
end

---------------------------------------------
-- Tribute Discard Counter Tooltip Gamepad --
---------------------------------------------

local g_discardCounterTooltipControl

function ZO_TributeDiscardCounterTooltip_Gamepad_Hide()
    local control = g_discardCounterTooltipControl
    if not internalassert(control, "ZO_TributeDiscardCounterTooltip_Gamepad failed to initialize.") then
        return false
    end

    control:SetHidden(true)
    control:ClearAnchors()
    control.scrollTooltip:ClearLines()
    return true
end

function ZO_TributeDiscardCounterTooltip_Gamepad_Show(anchorPoint, anchorControl, anchorRelativePoint, anchorOffsetX, anchorOffsetY)
    if not ZO_TributeDiscardCounterTooltip_Gamepad_Hide() then
        return
    end

    -- Order matters
    local control = g_discardCounterTooltipControl
    control.tip:LayoutTributeDiscardCounter()
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

function ZO_TributeDiscardCounterTooltip_Gamepad_GetControl()
    return g_discardCounterTooltipControl
end

function ZO_TributeDiscardCounterTooltip_Gamepad_Initialize(tooltipControl)
    g_discardCounterTooltipControl = tooltipControl

    local function ScreenResizeHandler(control)
        local maxHeight = GuiRoot:GetHeight() - (ZO_GAMEPAD_PANEL_FLOATING_HEIGHT_DISCOUNT * 2)
        control:SetDimensionConstraints(0, 0, 0, maxHeight)
    end

    local DEFAULT_TOOLTIP_STYLES = nil
    ZO_ResizingFloatingScrollTooltip_Gamepad_OnInitialized(g_discardCounterTooltipControl, DEFAULT_TOOLTIP_STYLES, ScreenResizeHandler, LEFT)
    ScreenResizeHandler(g_discardCounterTooltipControl)
end