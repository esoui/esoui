-- above all hex levels
ZO_SCRYING_FRAME_LEVEL = 10

-----------------
-- Scrying Hex --
-----------------
--[[
    Each scrying hex manages the state of each hexagonal tile in the game board.
]]--
ZO_ScryingHex = ZO_InitializingObject:Subclass()

do
    function ZO_ScryingHex:Initialize(board, control, hexIndex)
        self.board = board
        self.hexIndex = hexIndex
        self.row, self.column = GetScryingHexCoordinatesFromIndex(hexIndex)

        self.control = control
        self.control.hexObject = self
        self:InitializeControls()

        self.refreshTypeCallback = function()
            self:RefreshType()
        end
        self.idleLoop = SCRYING_HEX_ANIMATION_PROVIDER:AcquireIdleAnimation(self)

        self:ResetToCanonicalState()
    end

    ZO_SCRYING_HEX_DARKNESS_SURFACE = 1
    ZO_SCRYING_HEX_TYPE_SURFACE = 2
    ZO_SCRYING_HEX_FLASH_SURFACE = 3
    ZO_SCRYING_HEX_FOREGROUND_SURFACE = 4
    ZO_SCRYING_HEX_BORDER_SURFACE = 5

    ZO_SCRYING_HEX_TEXTURE_WIDTH = 210
    ZO_SCRYING_HEX_TEXTURE_HEIGHT = 182
    ZO_SCRYING_SURFACE_TEXTURE_WIDTH = 256
    ZO_SCRYING_SURFACE_TEXTURE_HEIGHT = 256
    function ZO_ScryingHex:InitializeControls()
        local boardControl = self.board:GetControl()

        local hexWidth, hexHeight = self.board:GetHexDimensions()
        local offsetX, offsetY = self.board:ConvertHexCoordinateToOffset(self.row, self.column)
        self.control:SetAnchor(CENTER, boardControl, BOTTOM, offsetX, offsetY)
        self.control:SetDimensions(hexWidth, hexHeight)

        local surfaceWidth = hexWidth * (ZO_SCRYING_SURFACE_TEXTURE_WIDTH / ZO_SCRYING_HEX_TEXTURE_WIDTH)
        local surfaceHeight = hexHeight * (ZO_SCRYING_SURFACE_TEXTURE_HEIGHT / ZO_SCRYING_HEX_TEXTURE_HEIGHT)

        local backgroundTexture = self.control:GetNamedChild("Background")
        backgroundTexture:SetDimensions(surfaceWidth, surfaceHeight)

        self.textureComposite = self.control:GetNamedChild("Textures")
        self.textureComposite:SetDimensions(surfaceWidth, surfaceHeight)

        self.polygon = self.control:GetNamedChild("Polygon")

        local radiusNumHexes = 8
        -- pre-computing multiple things:
        self.lightRadiusPixelsCoefficient = 1 / (radiusNumHexes * hexHeight) -- reciprocal to avoid divide in hot path
        self.lightRadiusPixelsCoefficient = self.lightRadiusPixelsCoefficient * self.lightRadiusPixelsCoefficient -- squaring to avoid sqrt in hot path
    end

    function ZO_ScryingHex:GetControl()
        return self.control
    end
    
    function ZO_ScryingHex:GetParentBoard()
        return self.board
    end
    
    function ZO_ScryingHex:GetCoordinates()
        return self.row, self.column
    end

    function ZO_ScryingHex:GetHexType()
        return self.hexType
    end

    function ZO_ScryingHex:GetGridRect()
        local hexWidth, hexHeight = self.board:GetHexDimensions()
        local halfWidth, halfHeight = hexWidth * 0.5, hexHeight * 0.5
        local offsetX, offsetY = self.board:ConvertHexCoordinateToOffset(self.row, self.column)
        local left = offsetX - halfWidth
        local right = offsetX + halfWidth
        local top = offsetY - halfHeight
        local bottom = offsetY + halfHeight
        return left, right, top, bottom
    end

    -- In other systems this would be a refresh function; however, since we
    -- want to intentionally desync game logic and visual presentation to support
    -- animations, this should be used sparingly
    function ZO_ScryingHex:ResetToCanonicalState()
        self.hexType = GetScryingHexType(self.hexIndex)
        self.state = GetScryingHexState(self.hexIndex)
        self.isGoal, self.hasGoalBeenPreviouslyAchieved = IsScryingHexGoal(self.hexIndex)

        self:RefreshType()
        self:SetBorderType(ZO_SCRYING_HEX_BORDER_NONE)
        self:RefreshGoal()
    end

    function ZO_ScryingHex:SetScale(scale)
        self.control:SetScale(scale)
    end

    function ZO_ScryingHex:SetAlpha(alpha)
        self.control:SetAlpha(alpha)
    end

    function ZO_ScryingHex:PlayChangeAnimation()
        local newHexType = GetScryingHexType(self.hexIndex)

        if self.hexType ~= newHexType then
            self.hexType = newHexType

            local epicenterHex = SCRYING:GetCurrentSkill() == SCRYING_ACTIVE_SKILL_LINE and self.board:GetLineStartHex() or self.board:GetTargetHex()

            -- delay animation based on distance from epicenter: this causes a nice "chain" effect
            local epicenterX, epicenterY = epicenterHex:GetControl():GetCenter()
            local currentX, currentY = self:GetControl():GetCenter()
            local delay = zo_distance(epicenterX, epicenterY, currentX, currentY) / self:GetControl():GetHeight()

            SCRYING_HEX_ANIMATION_PROVIDER:PlayFlashAnimation(self, delay * 50)
            local ANIMATION_PLAYED = true
            return ANIMATION_PLAYED
        end
        local ANIMATION_NOT_PLAYED = false
        return ANIMATION_NOT_PLAYED
    end

    local HEX_TYPE_TEXTURES =
    {
        [SCRYING_HEX_TYPE_ONE] = { left = 0.25, top = 0, right = 0.5, bottom = 0.25 },
        [SCRYING_HEX_TYPE_TWO] = { left = 0.5, top = 0, right = 0.75, bottom = 0.25 },
        [SCRYING_HEX_TYPE_THREE] = { left = 0.75, top = 0, right = 1, bottom = 0.25 },
        [SCRYING_HEX_TYPE_FOUR] = { left = 0, top = 0.25, right = 0.25, bottom = 0.5 },
        [SCRYING_HEX_TYPE_FIVE] = { left = 0.25, top = 0.25, right = 0.5, bottom = 0.5 },
        [SCRYING_HEX_TYPE_SIX] = { left = 0.5, top = 0.25, right = 0.75, bottom = 0.5 },
        [SCRYING_HEX_TYPE_SEVEN] = { left = 0.75, top = 0.25, right = 1, bottom = 0.5 },
        [SCRYING_HEX_TYPE_EIGHT] = { left = 0, top = 0.5, right = 0.25, bottom = 0.75 },
        [SCRYING_HEX_TYPE_OWNED] = { left = 0, top = 0, right = 0.25, bottom = 0.25 },
        [SCRYING_HEX_TYPE_GOAL] = false, -- no symbol
    }
    function ZO_ScryingHex:RefreshType()
        local coords = HEX_TYPE_TEXTURES[self.hexType]
        if coords then
            self.textureComposite:SetSurfaceHidden(ZO_SCRYING_HEX_TYPE_SURFACE, false)
            self.textureComposite:SetTextureCoords(ZO_SCRYING_HEX_TYPE_SURFACE, coords.left, coords.right, coords.top, coords.bottom)
        else
            self.textureComposite:SetSurfaceHidden(ZO_SCRYING_HEX_TYPE_SURFACE, true)
        end

        -- Update idle animation
        SCRYING_HEX_ANIMATION_PROVIDER:UpdateIdleAnimationParams(self.idleLoop, self)

        if self.goalObject and self.hexType == SCRYING_HEX_TYPE_OWNED then
            -- Update goal state
            self.goalObject:SetState(SO_SCRYING_GOAL_STATE_OWNING)
        end
    end

    function ZO_ScryingHex:GetRefreshTypeCallback()
        return self.refreshTypeCallback
    end

    ZO_SCRYING_HEX_BORDER_NONE = 0
    ZO_SCRYING_HEX_BORDER_TARGETED = 1
    ZO_SCRYING_HEX_BORDER_AFFECTED = 2
    local SELECTED_COLOR = ZO_WHITE
    local NOT_SELECTED_COLOR = ZO_ColorDef:New("FF00EFFF")
    function ZO_ScryingHex:SetBorderType(borderType)
        if borderType ~= self.borderType then
            self.borderType = borderType
            if borderType == ZO_SCRYING_HEX_BORDER_AFFECTED then
                self.polygon:SetBorderColor(SELECTED_COLOR:UnpackRGBA())
                self.polygon:SetBorderThickness(ZO_AFFECTED_HEX_BORDER_PIXELS, ZO_AFFECTED_HEX_BORDER_PIXELS, 0)
            elseif borderType == ZO_SCRYING_HEX_BORDER_TARGETED then
                self.polygon:SetBorderColor(SELECTED_COLOR:UnpackRGBA())
                self.polygon:SetBorderThickness(ZO_TARGETED_HEX_BORDER_PIXELS, ZO_TARGETED_HEX_BORDER_PIXELS, 0)
            else
                self.polygon:SetBorderColor(NOT_SELECTED_COLOR:UnpackRGBA())
                self.polygon:SetBorderThickness(ZO_NOT_SELECTED_HEX_BORDER_PIXELS, ZO_NOT_SELECTED_HEX_BORDER_PIXELS, 0)
            end
        end
    end

    function ZO_ScryingHex:GetBorderType()
        return self.borderType
    end

    function ZO_ScryingHex:RefreshGoal()
        if self.isGoal and not self.goalObject then
            self.goalObject, self.goalKey = SCRYING_HEX_ANIMATION_PROVIDER:AcquireGoal()
            self.goalObject:SetHex(self)
            if self.hexType == SCRYING_HEX_TYPE_OWNED then
                self.goalObject:SetState(ZO_SCRYING_GOAL_STATE_OWNED)
            elseif self.hasGoalBeenPreviouslyAchieved then
                self.goalObject:SetState(ZO_SCRYING_GOAL_STATE_PREVIOUSLY_OWNED)
            else
                self.goalObject:SetState(ZO_SCRYING_GOAL_STATE_UNOWNED)
            end
        elseif not self.isGoal and self.goalObject then
            self.board:ReleaseGoal(self.goalKey)
            self.goalObject, self.goalKey = nil, nil
        end
    end

    local Clamp = zo_clamp -- localizing for performance
    function ZO_ScryingHex:RefreshDistanceFromCursor(epicenterX, epicenterY)
        local alpha = 0
        if not self.isGoal and self.borderType == ZO_SCRYING_HEX_BORDER_NONE and self.hexType ~= SCRYING_HEX_TYPE_OWNED then
            local currentX, currentY = self.control:GetCenter()
            local dx, dy = epicenterX - currentX, epicenterY - currentY
            local distanceFromHexSquared = dx * dx + dy * dy

            alpha = Clamp(distanceFromHexSquared * self.lightRadiusPixelsCoefficient, 0, 1)

            -- EaseOutQuartic
            alpha = 1 - alpha
            alpha = 1 - (alpha * alpha * alpha * alpha)
        end
        self.textureComposite:SetSurfaceAlpha(ZO_SCRYING_HEX_DARKNESS_SURFACE, alpha)
    end

    function ZO_ScryingHex:DisableDarknessEffect()
        self.textureComposite:SetSurfaceAlpha(ZO_SCRYING_HEX_DARKNESS_SURFACE, 0)
    end

    function ZO_ScryingHex:OnMouseEnter()
        if self.board:IsMouseEnabled() then
            self.board:ChangeTargetHex(self)
        end
    end

    function ZO_ScryingHex:OnMouseExit()
        if self.board:IsMouseEnabled() then
            self.board:ChangeTargetHex(nil)
        end
    end

    function ZO_ScryingHex:OnMouseClicked()
        self.board:PerformActionOnHex(self)
    end

    function ZO_ScryingHex:OnMouseRightClicked()
        self.board:CancelLineAction()
    end

    function ZO_ScryingHex:OnDragStart()
        if SCRYING:GetCurrentSkill() == SCRYING_ACTIVE_SKILL_LINE then
            -- record line start target
            self.board:PerformActionOnHex(self)
        end
    end

    function ZO_ScryingHex:OnReceiveDrag()
        if SCRYING:GetCurrentSkill() == SCRYING_ACTIVE_SKILL_LINE and self.board:GetLineStartHex() ~= nil then
            -- record line end target
            self.board:PerformActionOnHex(self)
        end
    end

    function ZO_ScryingHex:OnEffectivelyShown()
        self.idleLoop:PlayFromStart()
    end

    function ZO_ScryingHex:OnEffectivelyHidden()
        self.idleLoop:Stop()
    end
end

--[[
    Each action button represents the state of a scrying active skill, and the keybind you use to activate it
]]--
ZO_ScryingActionButton = ZO_InitializingObject:Subclass()

function ZO_ScryingActionButton:Initialize(control, skill, actionName)
    self.control = control
    self.abilitySlot = control:GetNamedChild("AbilitySlot")
    self.icon = self.abilitySlot:GetNamedChild("Icon")
    self.activeSkill = skill
    self.actionName = actionName
    self.keybindLabel = control:GetNamedChild("Keybind")
    ZO_Keybindings_RegisterLabelForBindingUpdate(self.keybindLabel, actionName)
    
    self.abilitySlot:SetHandler("OnMouseEnter", function()
        InitializeTooltip(AbilityTooltip, self.icon, TOPLEFT, 5, -5, TOPRIGHT)
        AbilityTooltip:SetAbilityId(self.abilityId)
    end)
    self.abilitySlot:SetHandler("OnMouseExit", function()
        ClearTooltip(AbilityTooltip)
    end)
    self.abilitySlot:SetHandler("OnMouseUp", function(_, button, upInside)
        if button == MOUSE_BUTTON_INDEX_LEFT and upInside then
            SCRYING:TrySetCurrentSkill(self.activeSkill)
        end
    end)
    self:UpdatePlatformStyle()
end

do
    local SCRYING_ACTION_ACTIVE_COLOR = ZO_DEFAULT_ENABLED_COLOR
    local SCRYING_ACTION_INACTIVE_COLOR = ZO_ColorDef:New(.7, .7, .7)
    local SCRYING_ACTION_DISABLED_COLOR = ZO_DEFAULT_DISABLED_COLOR
    function ZO_ScryingActionButton:Refresh()
        if not IsScryingActiveSkillUnlocked(self.activeSkill) then
            self.control:SetHidden(true)
            return
        else
            self.control:SetHidden(false)
        end

        self.abilityId = GetScryingActiveSkillAbilityId(self.activeSkill)
        self.icon:SetTexture(GetAbilityIcon(self.abilityId))

        if SCRYING:GetCurrentSkill() == self.activeSkill then
            self.icon:SetColor(SCRYING_ACTION_ACTIVE_COLOR:UnpackRGBA())
        elseif IsScryingActiveSkillUsable(self.activeSkill) == SCRYING_ACTIVE_SKILL_USE_RESULT_SUCCESS then
            self.icon:SetColor(SCRYING_ACTION_INACTIVE_COLOR:UnpackRGBA())
        else
            self.icon:SetColor(SCRYING_ACTION_DISABLED_COLOR:UnpackRGBA())
        end
    end
end

do
    local KEYBOARD_BINDING_FONT = "ZoFontWinH3"
    local GAMEPAD_BINDING_FONT = "ZoFontGamepad18"
    function ZO_ScryingActionButton:UpdatePlatformStyle()
        self.keybindLabel:SetFont(IsInGamepadPreferredMode() and GAMEPAD_BINDING_FONT or KEYBOARD_BINDING_FONT)
    end
end

----------------------------------
-- Scrying Normal Actions Meter --
----------------------------------
--[[
    This object replicates the StatusBarControl API for the normal actions meter, so we can reuse the existing status bar animations.
]]--
ZO_ScryingNormalActionsMeter = ZO_InitializingObject:Subclass()

function ZO_ScryingNormalActionsMeter:Initialize(control)
    self.control = control
    self.activatedMask = control:GetNamedChild("ActivatedMask")
    self.edgeTexture = control:GetNamedChild("Edge")
    self.valueText = control:GetNamedChild("EdgeText")
    self.crossfadeAnim = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_ScryingNormalActionMeter_Crossfade", self.control)
    self.idleLoop = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_ScryingNormalActionMeter_Idle", self.control)
    self.value = 0
    self.min = 0
    self.max = 1
    self.isTextVisible = false

    self.maskBaseHeight = self.control:GetHeight()

    self.edgeBaseWidth = self.edgeTexture:GetWidth()
    self.edgeBaseHeight = self.edgeTexture:GetHeight()

    self:SetValue(0)
    self:UpdatePlatformStyle()
    self.idleLoop:PlayFromStart()
end

function ZO_ScryingNormalActionsMeter:SetValue(value)
    self.value = value
    local min, max = self.min, self.max
    local progress = (value - min) / (max - min)

    -- set % masked based on value
    self.activatedMask:SetHeight(progress * self.maskBaseHeight)

    -- taper off edge height near top/bottom
    local distanceFromEdge = progress > 0.5 and 1 - progress or progress -- linear ramp from 0 -> .5 -> 0
    local taperHeight = math.min(0.1, distanceFromEdge) * 10
    self.edgeTexture:SetHeight(taperHeight * self.edgeBaseHeight)

    -- taper off edge width near top
    local taperWidth = math.min(1 / 3, progress) * 3
    self.edgeTexture:SetWidth(taperWidth * self.edgeBaseWidth)
end

function ZO_ScryingNormalActionsMeter:GetValue()
    return self.value
end

function ZO_ScryingNormalActionsMeter:SetMinMax(min, max)
    self.min = min
    self.max = max
end

do
    local TURNS_UNTIL_SHOW_TEXT = 3
    function ZO_ScryingNormalActionsMeter:SmoothTransition(value, max, forceInit)
        ZO_StatusBar_SmoothTransition(self, value, max, forceInit)
        local shouldTextBeVisible = value <= TURNS_UNTIL_SHOW_TEXT
        if shouldTextBeVisible ~= self.isTextVisible then
            self.isTextVisible = shouldTextBeVisible
            if shouldTextBeVisible then
                if forceInit then
                    self.crossfadeAnim:PlayInstantlyToEnd()
                else
                    self.crossfadeAnim:PlayFromStart()
                end
            else
                if forceInit then
                    self.crossfadeAnim:PlayInstantlyToStart()
                else
                    self.crossfadeAnim:PlayFromEnd()
                end
            end
        end

        if shouldTextBeVisible then
            self.valueText:SetText(tostring(value))
        end
    end
end

do
    local KEYBOARD_VALUE_FONT =  "ZoFontKeyboard18ThickOutline"
    local GAMEPAD_VALUE_FONT = "ZoFontGamepad36ThickOutline" 
    function ZO_ScryingNormalActionsMeter:UpdatePlatformStyle()
        self.valueText:SetFont(IsInGamepadPreferredMode() and GAMEPAD_VALUE_FONT or KEYBOARD_VALUE_FONT)
    end
end

function ZO_ScryingNormalActionsMeter:OnShowing()
    self.control:SetAlpha(1)
end

function ZO_ScryingNormalActionsMeter:OnEndOfGameTimelineUpdate(animation, progress)
    local alpha = zo_lerp(1, 0, progress)
    self.control:SetAlpha(alpha)
end

----------------------------------
-- Scrying Special Actions Meter --
----------------------------------
--[[
    Unlike the normal actions meter, which is fairly statusbar-like, the special actions meter is special in that the valid number of steps is fixed.
    The special actions meter crossfades between two well-defined textures for each step.
]]--
ZO_ScryingSpecialActionsMeter = ZO_InitializingObject:Subclass()

function ZO_ScryingSpecialActionsMeter:Initialize(control)
    self.control = control
    self.activeTexture = self.control:GetNamedChild("ActiveTexture")
    self.lastTexture = self.control:GetNamedChild("LastTexture")
    self.crossfadeAnim = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_ScryingSpecialActionMeter_Crossfade", self.control)
    local INSTANT = true
    self:SmoothTransition(0, INSTANT)
end

do
    local FULL_METER_TEXTURES =
    {
        [0] = { left = 0, top = 0, right = 0, bottom = 0 }, -- A single transparent pixel in the top-left
        [1] = { left = 0.5, top = 0, right = 1, bottom = 0.25 },
        [2] = { left = 0.5, top = 0.25, right = 1, bottom = 0.5 },
        [3] = { left = 0.5, top = 0.5, right = 1, bottom = 0.75 },
    }
    local PARTIAL_METER_TEXTURES =
    {
        [0] = { left = 0, top = 0, right = 0.5, bottom = 0.25 },
        [1] = { left = 0, top = 0.25, right = 0.5, bottom = 0.5 },
        [2] = { left = 0, top = 0.5, right = 0.5, bottom = 0.75 },
    }
    function ZO_ScryingSpecialActionsMeter:SmoothTransition(numGems, shouldFillPartialGem, shouldAnimateInstantly)
        local coords
        if shouldFillPartialGem then
            coords = PARTIAL_METER_TEXTURES[numGems]
        else
            coords = FULL_METER_TEXTURES[numGems]
        end

        self.lastTexture:SetTextureCoords(self.activeTexture:GetTextureCoords())
        self.activeTexture:SetTextureCoords(coords.left, coords.right, coords.top, coords.bottom)

        if shouldAnimateInstantly then
            self.crossfadeAnim:PlayInstantlyToEnd()
        else
            self.crossfadeAnim:PlayFromStart()
        end
    end
end

--------------------------
-- Scrying Modal Cursor --
--------------------------
--[[
    The Scrying modal cursor handles a few cursor-like things:
    * for gamepad, it helps the players know which hex they currently have targeted
    * on both platforms, it will add extra context to each special ability
]]--
ZO_ScryingModalCursor = ZO_InitializingObject:Subclass()

function ZO_ScryingModalCursor:Initialize(board, control)
    self.board = board
    self.control = control
    self.gamepadCursorEnabled = false
    local function GetStickMagnitude(direction)
        --When using a movement controller on the slightest input in a direction it will move in that direction and then start accumulating to do the following move. This is important for responsiveness.
        --However it means that it's super touchy when using both X and Y. Pressing the stick at 89 degress will cause a movement to the right. So we apply these thresholds to get rid of those weird moves.
        if direction == MOVEMENT_CONTROLLER_DIRECTION_VERTICAL then
            return zo_abs(self.gamepadY) > 0.4 and self.gamepadY or 0
        end
        return zo_abs(self.gamepadX) > 0.4 and -self.gamepadX or 0
    end
    self.verticalMovementController = ZO_MovementController:New(MOVEMENT_CONTROLLER_DIRECTION_VERTICAL, 8, GetStickMagnitude)
    self.horizontalMovementController = ZO_MovementController:New(MOVEMENT_CONTROLLER_DIRECTION_HORIZONTAL, 8, GetStickMagnitude)

    self.gamepadTargetControl = self.control:GetNamedChild("GamepadTarget")
    self.lineStartControl = self.control:GetNamedChild("LineStart")
    self.lineEndControl = self.control:GetNamedChild("LineEnd")

    self.coOptControl = self.control:GetNamedChild("CoOpt")
    self.coOptControl.translationAnimation:SetTranslateOffsets(0, -10, 0, 0)

    self.bombControl = self.control:GetNamedChild("Bomb")
    self:CreateBombCursorPetals()

    self.gamepadTargetIdleLoop = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_ScryingGamepadTargetCursor_Idle", self.gamepadTargetControl)
    self.gamepadTargetIdleLoop:PlayFromStart()
end

function ZO_ScryingModalCursor:CreateBombCursorPetals()
    self.bombCursorPetalControls = {}
    for direction = SCRYING_GRID_DIRECTION_UP, SCRYING_GRID_DIRECTION_UP_LEFT do
        local petal  = CreateControlFromVirtual("$(parent)Petal" .. direction, self.bombControl, "ZO_ScryingBombCursor_Petal")

        local angle = GetAngleFromUpForScryingGridDirection(direction)
        petal:SetTextureRotation(angle)

        local DELAY_PER_PETAL_MS = 30
        petal.fadeInTimeline:SetAllAnimationOffsets((direction - SCRYING_GRID_DIRECTION_UP) * DELAY_PER_PETAL_MS)
        local INITIAL_DISTANCE = 30
        local startX, startY = ZO_Rotate2D(-angle, 0, INITIAL_DISTANCE)
        petal.translationAnimation:SetTranslateOffsets(startX, startY, 0, 0)
        table.insert(self.bombCursorPetalControls, petal)
    end
end

ZO_SCRYING_GAMEPAD_CURSOR_HEIGHT = 64
ZO_SCRYING_GAMEPAD_CURSOR_WIDTH = 64
ZO_SCRYING_LINE_CURSOR_WIDTH = 256 * 1.5
ZO_SCRYING_LINE_CURSOR_HEIGHT = 256 * 1.5
ZO_SCRYING_CO_OPT_CURSOR_WIDTH = 128 * 1.75
ZO_SCRYING_CO_OPT_CURSOR_HEIGHT = 128 * 1.75
ZO_SCRYING_BOMB_PETAL_WIDTH = 256 * 1.5
ZO_SCRYING_BOMB_PETAL_HEIGHT = 256 * 1.5
function ZO_ScryingModalCursor:ResizeToMatchHexSize(hexWidth, hexHeight)
    local hexScaleX = hexWidth / ZO_SCRYING_HEX_TEXTURE_WIDTH
    local hexScaleY = hexWidth / ZO_SCRYING_HEX_TEXTURE_HEIGHT
    self.gamepadTargetControl:SetDimensions(ZO_SCRYING_GAMEPAD_CURSOR_WIDTH * hexScaleX, ZO_SCRYING_GAMEPAD_CURSOR_HEIGHT * hexScaleY)

    self.lineStartControl:SetDimensions(ZO_SCRYING_LINE_CURSOR_WIDTH * hexScaleX, ZO_SCRYING_LINE_CURSOR_HEIGHT * hexScaleY)
    self.lineEndControl:SetDimensions(ZO_SCRYING_LINE_CURSOR_WIDTH * hexScaleX, ZO_SCRYING_LINE_CURSOR_HEIGHT * hexScaleY)

    self.coOptControl:SetDimensions(ZO_SCRYING_CO_OPT_CURSOR_WIDTH * hexScaleX, ZO_SCRYING_CO_OPT_CURSOR_HEIGHT * hexScaleY)

    for _, petal in ipairs(self.bombCursorPetalControls) do
        petal:SetDimensions(ZO_SCRYING_BOMB_PETAL_WIDTH * hexScaleX, ZO_SCRYING_BOMB_PETAL_HEIGHT * hexScaleY)
    end
end

do
    local function AnchorToHex(control, hex)
        control:ClearAnchors()
        control:SetAnchor(CENTER, hex:GetControl(), CENTER)
    end

    function ZO_ScryingModalCursor:UpdateModalAction()
        local targetHex = self.board:GetTargetHex()
        if not targetHex then
            self.control:SetHidden(true)
            return
        end
        self.control:SetHidden(false)

        local currentActiveSkill = SCRYING:GetCurrentSkill()
        self.lineStartControl:SetHidden(currentActiveSkill ~= SCRYING_ACTIVE_SKILL_LINE)
        self.lineEndControl:SetHidden(currentActiveSkill ~= SCRYING_ACTIVE_SKILL_LINE)
        self.coOptControl:SetHidden(currentActiveSkill ~= SCRYING_ACTIVE_SKILL_CO_OPT)
        self.bombControl:SetHidden(currentActiveSkill ~= SCRYING_ACTIVE_SKILL_BOMB)

        -- every cursor except line start points at the target hex, so this will recursively hit all of them
        AnchorToHex(self.control, targetHex)

        if currentActiveSkill == SCRYING_ACTIVE_SKILL_LINE then
            local lineStartHex = self.board:GetLineStartHex()
            if lineStartHex and lineStartHex ~= targetHex then
                local direction, endHexIndex = GetScryingLastAffectedLineActionInfo()
                local angle = GetAngleFromUpForScryingGridDirection(direction)
                local lineEndHex = endHexIndex and self.board:GetHexByIndex(endHexIndex)

                AnchorToHex(self.lineStartControl, lineStartHex)
                self.lineStartControl:SetTextureRotation(angle + ZO_PI)

                if lineEndHex then
                    self.lineEndControl:SetHidden(false)
                    AnchorToHex(self.lineEndControl, lineEndHex)
                    self.lineEndControl:SetTextureRotation(angle)
                else
                    self.lineEndControl:SetHidden(true)
                end
            else
                AnchorToHex(self.lineStartControl, targetHex)
                self.lineStartControl:SetTextureRotation(ZO_PI)

                self.lineEndControl:SetHidden(false)
                AnchorToHex(self.lineEndControl, targetHex)
                self.lineEndControl:SetTextureRotation(0)
            end
        end
    end
end

function ZO_ScryingModalCursor:SetGamepadVirtualCursorEnabled(enabled)
    if self.gamepadCursorEnabled ~= enabled then
        self.gamepadCursorEnabled = enabled
        self.gamepadTargetControl:SetHidden(not enabled)
        if enabled then
            DIRECTIONAL_INPUT:Activate(self, self.control)
        else
            DIRECTIONAL_INPUT:Deactivate(self)
        end
    end
end

function ZO_ScryingModalCursor:IsGamepadVirtualCursorEnabled()
    return self.gamepadCursorEnabled
end

function ZO_ScryingModalCursor:UpdateDirectionalInput()
    self.gamepadX, self.gamepadY = DIRECTIONAL_INPUT:GetXY(ZO_DI_LEFT_STICK, ZO_DI_DPAD)
    local dx, dy = self.gamepadX, self.gamepadY

    local targetHex = self.board:GetTargetHex()
    if internalassert(targetHex, "targetHex is nil") then
        local row, column = targetHex:GetCoordinates()
        local newRow, newColumn = row, column

        local verticalMove, horizontalMove
        if self.board:GetLineStartHex() then
            -- line drawing mode
            local lineStartHex = self.board:GetLineStartHex()
            dy = -dy -- flip such that +1 is down
            local DEADZONE = 0.4
            if math.sqrt(dx * dx + dy * dy) > DEADZONE then
                local angleTurns = math.atan2(dy, dx) / ZO_TWO_PI
                -- recenter such that the top sixth of of the circle is centered around 0 and the bottom sixth around 3
                local angleTurnsNormalized = (angleTurns + 5 / 16) % 1
                local angleDirection = math.floor(angleTurnsNormalized * 6)
                local rowOffset, columnOffset = GetHexOffsetsForScryingGridDirection(angleDirection)
                local rowStart, columnStart = lineStartHex:GetCoordinates()
                newRow = rowStart + rowOffset
                newColumn = columnStart + columnOffset
            end
        else
            -- vertical movement
            verticalMove = self.verticalMovementController:CheckMovement()
            if verticalMove == MOVEMENT_CONTROLLER_MOVE_NEXT then
                newRow = row + 2
            elseif verticalMove == MOVEMENT_CONTROLLER_MOVE_PREVIOUS then
                newRow = row - 2
            end

            -- horizontal movement
            horizontalMove = self.horizontalMovementController:CheckMovement()
            if horizontalMove == MOVEMENT_CONTROLLER_MOVE_NEXT then
                newColumn = column + 1
                newRow = (newColumn % 2 == 0) and (row - 1) or (row + 1)
            elseif horizontalMove == MOVEMENT_CONTROLLER_MOVE_PREVIOUS then
                newColumn = column - 1
                newRow = (newColumn % 2 == 0) and (row - 1) or (row + 1)
            end
        end

        -- apply movement
        local newTargetHex = self.board:GetHex(newRow, newColumn)

        if not newTargetHex then
            -- on the very last row, the usual up/down pattern we apply to
            -- navigate between rows may not exist. to handle this let's try again
            -- by only shifting columns, not rows
            if horizontalMove == MOVEMENT_CONTROLLER_MOVE_NEXT then
                newColumn = column + 2
                newRow = row
                newTargetHex = self.board:GetHex(newRow, newColumn)
            elseif horizontalMove == MOVEMENT_CONTROLLER_MOVE_PREVIOUS then
                newColumn = column - 2
                newRow = row
                newTargetHex = self.board:GetHex(newRow, newColumn)
            end
        end

        if newTargetHex and self.targetHex ~= newTargetHex then
            self.board:ChangeTargetHex(newTargetHex)
        end
    end
end

-------------------
-- Scrying Board --
-------------------
--[[
    The scrying board maintains the state of each hex, and any extra data about the game such as turns left
]]--
ZO_ScryingBoard = ZO_InitializingObject:Subclass()

function ZO_ScryingBoard:Initialize(gameControl)
    self.gameControl = gameControl
    self.boardControl = self.gameControl:GetNamedChild("SafeArea")
    self.boardMask = self.gameControl:GetNamedChild("EyeBackgroundMask")
    self.hexList = {}
    self.lastBorderVisibleHexes = {}
    self.borderVisibleHexes = {}
    self.targetHex = nil

    self.hexControlPool = ZO_ControlPool:New("ZO_ScryingHex", self.boardControl, "Hex")
    local function ResetHexControl(hexControl)
        hexControl.hexObject = nil
        hexControl:SetScale(1)
        hexControl:SetAlpha(1)
    end
    self.hexControlPool:SetCustomResetBehavior(ResetHexControl)
    local function HexAcquire(hexControl, hexIndex)
        ZO_ScryingHex:New(self, hexControl, hexIndex)
    end
    self.hexControlPool:SetCustomAcquireBehavior(HexAcquire)

    self.fakeHexPool = ZO_ControlPool:New("ZO_ScryingFakeHex", self.boardControl, "FakeHex")

    self.goalControlPool = ZO_ControlPool:New("ZO_ScryingGoal", self.boardControl, "Goal")

    self.modalCursor = ZO_ScryingModalCursor:New(self, self.boardControl:GetNamedChild("ModalCursor"))
end

function ZO_ScryingBoard:OnShowing()
    ZO_ClearNumericallyIndexedTable(self.hexList)
    self.hexControlPool:ReleaseAllObjects()
    SCRYING_HEX_ANIMATION_PROVIDER:ReleaseAllAnimations()
    self.targetHex = nil
    self.rootHexRow, self.rootHexColumn = GetScryingHexCoordinatesFromIndex(GetRootScryingHexIndex())

    self:RecalculateHexSize()

    for hexIndex = 1, GetNumTotalScryingHexes() do
        local hexControl = self.hexControlPool:AcquireObject(hexIndex)
        self.hexList[hexIndex] = hexControl.hexObject
    end

    self:SetupFakeHexBackground()

    EVENT_MANAGER:RegisterForUpdate("ZO_ScryingBoard", 0, function() self:OnUpdate() end)
end

function ZO_ScryingBoard:OnHidden()
    EVENT_MANAGER:UnregisterForUpdate("ZO_ScryingBoard")
end

function ZO_ScryingBoard:RecalculateHexSize()
    local targetBoardWidth, targetBoardHeight = self.boardControl:GetDimensions()
    local numRows, numColumns = GetScryingBoardSize()
    numRows = numRows - 1 -- exclude root hex, we want it to overlap
    local maxRow, maxColumn = numRows + 1, numColumns + (1/3) -- add 1 (or 1/3) to calculate the bottom-right point of the bottom-right hex, and not the top-left

    local targetHexWidthHorizontal = targetBoardWidth / (maxColumn * 0.75) -- This is the ConvertHexCoordinateToOffset math, but reversed
    local targetHexHeightHorizontal = targetHexWidthHorizontal * ZO_SCRYING_HEX_TEXTURE_HEIGHT / ZO_SCRYING_HEX_TEXTURE_WIDTH -- match ratio of source texture

    -- repeat, but treat the vertical axis as the constraining axis
    local targetHexHeightVertical = targetBoardHeight / (maxRow * 0.5)
    local targetHexWidthVertical = targetHexHeightVertical * ZO_SCRYING_HEX_TEXTURE_WIDTH / ZO_SCRYING_HEX_TEXTURE_HEIGHT

    -- pick the axis that results in smaller overall hexes, the other axis would go outside of the safe area
    if targetHexWidthHorizontal < targetHexWidthVertical then
        self.hexWidth, self.hexHeight = targetHexWidthHorizontal, targetHexHeightHorizontal
    else
        self.hexWidth, self.hexHeight = targetHexWidthVertical, targetHexHeightVertical
    end

    self.modalCursor:ResizeToMatchHexSize(self.hexWidth, self.hexHeight)
end

do
    local BOARD_CENTER_OFFSET_Y = 10
    local BORDER_COLOR = ZO_ColorDef:New("AA00EFFF")
    local MAX_HEX_SCALE = 0.75
    local MIN_HEX_SCALE = 0.35
    local MAX_HEX_RADIUS_X = 520
    local MAX_HEX_RADIUS_Y = 400

    function ZO_ScryingBoard:CreateFakeHex(row, column, distance)
        if (row + column) % 2 == 0 and not self:GetHex(row, column) then
            local offsetX, offsetY = self:ConvertHexCoordinateToOffset(row, column)
            local boardBottomY = self.boardControl:GetBottom()
            local boardCenterX, boardCenterY = self.boardControl:GetCenter()
            local expectedCenterX, expectedCenterY = boardCenterX + offsetX, boardBottomY + offsetY

            -- Calculate hexagon's normalized elliptical distance from the board's origin
            -- and derive an eased alpha for the control.
            local centerOffsetX, centerOffsetY = expectedCenterX - boardCenterX, expectedCenterY - (boardCenterY + BOARD_CENTER_OFFSET_Y)
            local angleRadians = math.atan2(centerOffsetX, centerOffsetY)
            local a = math.abs(math.sin(angleRadians) * (centerOffsetX / MAX_HEX_RADIUS_X))
            local b = math.abs(math.cos(angleRadians) * (centerOffsetY / MAX_HEX_RADIUS_Y))
            local normalizedDistance = 1 - (a + b)
            if normalizedDistance <= 0 then
                return
            end
            local easedDistance = normalizedDistance > 0.25 and 1 or ZO_EaseOutCubic(zo_lerp(0, 4, normalizedDistance))

            -- Before creating the object, test if it will overlap anything we don't want it to
            local scale = zo_lerp(MIN_HEX_SCALE, MAX_HEX_SCALE, easedDistance)
            local surfaceWidth = self.hexWidth * scale
            local surfaceHeight = self.hexHeight * scale

            -- testing top and bottom to have more precise testing against lattice work
            -- we don't need this precision on the X axis
            local expectedTopY = expectedCenterY - (surfaceWidth * 0.5)
            local expectedBottomY = expectedCenterY + (surfaceWidth * 0.5)
            if not self.boardMask:IsPointInside(expectedCenterX, expectedTopY) or not self.boardMask:IsPointInside(expectedCenterX, expectedBottomY) then
                return
            end

            local fakeControl, fakeControlKey = self.fakeHexPool:AcquireObject()
            fakeControl.centerOffsetAngleRadians = angleRadians
            fakeControl:ClearAnchors()
            fakeControl:SetAnchor(CENTER, self.boardControl, BOTTOM, offsetX, offsetY)

            fakeControl:SetDimensions(surfaceWidth, surfaceHeight)

            -- Remove margin around center texture
            local halfTextureRatioX = ZO_SCRYING_HEX_TEXTURE_WIDTH / ZO_SCRYING_SURFACE_TEXTURE_WIDTH / 2
            local halfTextureRatioY = ZO_SCRYING_HEX_TEXTURE_HEIGHT / ZO_SCRYING_SURFACE_TEXTURE_HEIGHT / 2
            fakeControl:SetCenterTextureCoords(1 - halfTextureRatioX, halfTextureRatioX, 1 - halfTextureRatioY, halfTextureRatioY)

            local r, g, b = BORDER_COLOR:UnpackRGB()
            local a = easedDistance
            fakeControl:SetBorderColor(r, g, b, a)
        end
    end
end

local function ExclusiveRangeIterator(stopValue, iterValue)
    iterValue = iterValue + 1
    if iterValue < stopValue then
      return iterValue
    end
end

-- this matches `for(i = startValue; i < stopValue; ++i) {}`
local function ExclusiveRange(startValue, stopValue)
  return ExclusiveRangeIterator, stopValue, startValue - 1
end

function ZO_ScryingBoard:SetupFakeHexBackground()
    self.fakeHexPool:ReleaseAllObjects()
    local numRows, numColumns = GetScryingBoardSize()

    -- left
    local COLUMNS_LEFT = 10
    for row in ExclusiveRange(0, numRows - 1) do
        for column in ExclusiveRange(1 - COLUMNS_LEFT, 1) do
            local distance = 1 - column
            self:CreateFakeHex(row, column, distance)
        end
    end

    -- right
    local COLUMNS_RIGHT = 10
    for row in ExclusiveRange(0, numRows - 1) do
        for column in ExclusiveRange(numColumns + 1, numColumns + COLUMNS_RIGHT) do
            local distance = column - numColumns
            self:CreateFakeHex(row, column, distance)
        end
    end

    -- down
    local ROWS_DOWN = 10
    for column in ExclusiveRange(1 - COLUMNS_LEFT, numColumns + COLUMNS_RIGHT) do
        for row in ExclusiveRange(numRows - 1, numRows + ROWS_DOWN) do -- also generate background hexes for the last row, which has only the root hex in it
            local downDistance = zo_floor((3 + row - numRows) * 0.5) -- halving then flooring to treat every two rows as the same row: this creates a nice visual band of hexes
            local leftDistance = 1 - column
            local rightDistance = column - numColumns
            local distance = zo_max(downDistance, leftDistance, rightDistance) -- Pick between the distance functions for down, left, and right to create a rectangular gradient
            self:CreateFakeHex(row, column, distance)
        end
    end

    -- up
    local ROWS_UP = 10
    for column in ExclusiveRange(1 - COLUMNS_LEFT, numColumns + COLUMNS_RIGHT) do
        for row in ExclusiveRange(-ROWS_UP, 0) do
            local upDistance = zo_floor((1 - row) * 0.5) -- halving then flooring to treat every two rows as the same row: this creates a nice visual band of hexes
            local leftDistance = 1 - column
            local rightDistance = column - numColumns
            local distance = zo_max(upDistance, leftDistance, rightDistance) -- Pick between the distance functions for up, left, and right to create a rectangular gradient
            self:CreateFakeHex(row, column, distance)
        end
    end
end

function ZO_ScryingBoard:GetHexDimensions()
    return self.hexWidth, self.hexHeight
end

-- All hex math assuming each hexagon is oriented to be flat on the top and bottom, with doubled coordinates
function ZO_ScryingBoard:ConvertHexCoordinateToOffset(row, column)
    -- Reminder, with doubled coordinates:
    -- the hexagon directly underneath the current hexagon is row+2, col
    -- the hexagon underneath and to the right of the current hexagon is row+1, col+1
    -- the hexagon to the right of the current hexagon is row, col+2

    -- The root hex should always have an offset of 0, 0
    column = column - self.rootHexColumn
    row = row - self.rootHexRow

    -- The leftmost point of the hexagon one column to the right should be flush with the bottom-right point of the current hexagon
    local offsetX = column * self.hexWidth * 0.75
    -- The center of the hexagon one row down should be flush with the bottom of the current hexagon
    local offsetY = row * self.hexHeight * 0.5

    return offsetX, offsetY
end

function ZO_ScryingBoard:GetBoardDimensions()
    return self.boardControl:GetDimensions()
end

function ZO_ScryingBoard:EnableVirtualCursor()
    self.modalCursor:SetGamepadVirtualCursorEnabled(true)

    if not self:GetTargetHex() then
        local rootHex = self:GetRootHex()
        local NO_SOUND = true
        self:ChangeTargetHex(rootHex, NO_SOUND)
    end
end

function ZO_ScryingBoard:DisableVirtualCursor()
    self.modalCursor:SetGamepadVirtualCursorEnabled(false)
end

function ZO_ScryingBoard:IsVirtualCursorEnabled()
    return self.modalCursor:IsGamepadVirtualCursorEnabled()
end

function ZO_ScryingBoard:IsMouseEnabled()
    return SCRYING:IsPlayerInputEnabled() and not self.modalCursor:IsGamepadVirtualCursorEnabled()
end

function ZO_ScryingBoard:GetHex(row, column)
    local hexIndex = GetScryingHexIndexFromCoordinates(row, column)
    return self.hexList[hexIndex]
end

function ZO_ScryingBoard:GetHexByIndex(hexIndex)
    return self.hexList[hexIndex]
end

function ZO_ScryingBoard:GetRootHex()
    return self.hexList[GetRootScryingHexIndex()]
end

function ZO_ScryingBoard:ResetAllHexes()
    for _, hex in ipairs(self.hexList) do
        hex:ResetToCanonicalState()
    end
end

function ZO_ScryingBoard:PlayHexChangeAnimations()
    local numChangedHexes = 0
    for _, hex in ipairs(self.hexList) do
        if hex:PlayChangeAnimation() then
            numChangedHexes = numChangedHexes + 1
        end
    end

    local activeSkill = SCRYING:GetCurrentSkill()
    if activeSkill == SCRYING_ACTIVE_SKILL_NORMAL then
        if numChangedHexes <= 3 then
            PlaySound(SOUNDS.SCRYING_CAPTURE_HEX_SMALL)
        elseif numChangedHexes <= 6 then
            PlaySound(SOUNDS.SCRYING_CAPTURE_HEX_MEDIUM)
        else
            PlaySound(SOUNDS.SCRYING_CAPTURE_HEX_LARGE)
        end
    elseif activeSkill == SCRYING_ACTIVE_SKILL_CO_OPT then
        if numChangedHexes <= 3 then
            PlaySound(SOUNDS.SCRYING_CO_OPT_HEX_SMALL)
        elseif numChangedHexes <= 6 then
            PlaySound(SOUNDS.SCRYING_CO_OPT_HEX_MEDIUM)
        else
            PlaySound(SOUNDS.SCRYING_CO_OPT_HEX_LARGE)
        end
    elseif activeSkill == SCRYING_ACTIVE_SKILL_BOMB then
        PlaySound(SOUNDS.SCRYING_ACTIVATE_BOMB)
    elseif activeSkill == SCRYING_ACTIVE_SKILL_LINE then
        PlaySound(SOUNDS.SCRYING_ACTIVATE_LINE)
    end
end

function ZO_ScryingBoard:GetTargetHex()
    return self.targetHex
end

function ZO_ScryingBoard:GetScryingActionParameters()
    local currentSkill = SCRYING:GetCurrentSkill()
    if not self.targetHex then
        return SCRYING_ACTIVE_SKILL_INVALID -- all skills need a target hex
    elseif self.lineStartHex then
        local lineStartRow, lineStartColumn = self.lineStartHex:GetCoordinates()
        local lineEndRow, lineEndColumn = self.targetHex:GetCoordinates()
        return currentSkill, lineStartRow, lineStartColumn, lineEndRow, lineEndColumn
    else
        local targetRow, targetColumn = self.targetHex:GetCoordinates()
        return currentSkill, targetRow, targetColumn
    end
end

do
    local function SortByHexIndex(leftHex, rightHex)
        return leftHex.hexIndex < rightHex.hexIndex
    end

    local function HaveBorderVisibleHexesChanged(lastBorderVisibleHexes, borderVisibleHexes)
        if #lastBorderVisibleHexes ~= #borderVisibleHexes then
            return true
        end

        -- assumes hex list is sorted, which it should be
        for index, hex in ipairs(lastBorderVisibleHexes) do
            if hex ~= borderVisibleHexes[index] then
                return true
            end
        end

        return false
    end

    function ZO_ScryingBoard:DirtySimulatedActionState(shouldPlaySound)
        -- simulated action state is a once per frame dirty flag. this is so we
        -- can process multiple changed target hexes per frame without doubling up
        -- on sfx or breaking the logic that detects if we've left an affected hex island or not
        self.simulatedActionStateDirty = true

        if not self.playActionStateSound then
            self.playActionStateSound = shouldPlaySound == true -- coerce to bool
        end
    end

    local HEX_NEIGHBORS =
    {
        {-2, 0},
        {-1, 1},
        {1, 1},
        {2, 0},
        {1, -1},
        {-1, -1},
    }

    local function FindAdjacentIslandForHex(board, hexToIslandMap, hex)
        local row, column = hex:GetCoordinates()
        for _, neighborOffset in ipairs(HEX_NEIGHBORS) do
            local rowOffset, columnOffset = unpack(neighborOffset)
            local neighborRow, neighborColumn = row + rowOffset, column + columnOffset
            local neighborHex = board:GetHex(neighborRow, neighborColumn)

            if hexToIslandMap[neighborHex] then
                return hexToIslandMap[neighborHex]
            end
        end
    end

    function ZO_ScryingBoard:RefreshSimulatedAction()
        local lastBorderVisibleHexes = self.borderVisibleHexes
        local borderVisibleHexes = self.lastBorderVisibleHexes -- reusing to avoid garbage
        ZO_ClearNumericallyIndexedTable(borderVisibleHexes)

        local canPreviewAction = CanPreviewScryingAction(self:GetScryingActionParameters()) == SCRYING_ACTIVE_SKILL_USE_RESULT_SUCCESS

        for _, hex in ipairs(lastBorderVisibleHexes) do
            hex:SetBorderType(ZO_SCRYING_HEX_BORDER_NONE)
        end

        SCRYING_HEX_ANIMATION_PROVIDER:ReleaseBorderHexIslands()
        if self.targetHex then
            self.targetHex:SetBorderType(ZO_SCRYING_HEX_BORDER_NONE)

            if canPreviewAction then
                -- Highlight affected hexes
                for index = 1, GetNumAffectedScryingHexes(self:GetScryingActionParameters()) do
                    local hex = self.hexList[GetAffectedScryingHex(index, self:GetScryingActionParameters())]
                    hex:SetBorderType(ZO_SCRYING_HEX_BORDER_AFFECTED)
                    table.insert(borderVisibleHexes, hex)
                end
            else
                -- only highlight target hex
                self.targetHex:SetBorderType(ZO_SCRYING_HEX_BORDER_TARGETED)
                table.insert(borderVisibleHexes, self.targetHex)
            end

            table.sort(borderVisibleHexes, SortByHexIndex)

            -- find islands
            local islands = {}
            local hexToIslandMap = {}
            for _, hex in ipairs(borderVisibleHexes) do
                local island = FindAdjacentIslandForHex(self, hexToIslandMap, hex)
                if not island then
                    island = { firstHex = hex }
                    table.insert(islands, island)
                end
                hexToIslandMap[hex] = island
            end

            -- Add outlines to all affected hexes
            for _, island in ipairs(islands) do
                local hex = island.firstHex
                SCRYING_HEX_ANIMATION_PROVIDER:TraceBorderHexIsland(hex)
            end

            -- play sound to suggest that the previewed action has changed
            if self.playActionStateSound and self.targetHex:GetHexType() ~= SCRYING_HEX_TYPE_OWNED then
                if not canPreviewAction then
                    PlaySound(SOUNDS.SCRYING_TARGET_UNAFFECTED_HEX)
                elseif HaveBorderVisibleHexesChanged(lastBorderVisibleHexes, borderVisibleHexes) then
                    if SCRYING:GetCurrentSkill() == SCRYING_ACTIVE_SKILL_BOMB then
                        PlaySound(SOUNDS.SCRYING_TARGET_HEX_WITH_BOMB)
                    elseif SCRYING:GetCurrentSkill() == SCRYING_ACTIVE_SKILL_LINE then
                        PlaySound(SOUNDS.SCRYING_TARGET_HEX_WITH_LINE)
                    else
                        PlaySound(SOUNDS.SCRYING_TARGET_AFFECTED_HEX)
                    end
                end
            end
        end
        self.modalCursor:UpdateModalAction()
        self.simulatedActionStateDirty = false
        self.playActionStateSound = false
        self.lastBorderVisibleHexes = lastBorderVisibleHexes
        self.borderVisibleHexes = borderVisibleHexes
    end
end

function ZO_ScryingBoard:OnUpdate()
    -- update hex distances
    if not IsInGamepadPreferredMode() then
        local cursorX, cursorY = GetUIMousePosition()
        for _, hex in ipairs(self.hexList) do
            hex:RefreshDistanceFromCursor(cursorX, cursorY)
        end
        self.darknessDisabled = false
    elseif not self.darknessDisabled then
        for _, hex in ipairs(self.hexList) do
            hex:DisableDarknessEffect()
        end
        self.darknessDisabled = true
    end

    -- update simulated action
    if self.simulatedActionStateDirty then
        self:RefreshSimulatedAction()
    end
end

function ZO_ScryingBoard:ChangeTargetHex(newTargetHex, shouldSupressSound)
    if self.targetHex ~= newTargetHex then
        self.targetHex = newTargetHex
        local shouldPlaySound = not shouldSupressSound
        self:DirtySimulatedActionState(shouldPlaySound)
    end
end

function ZO_ScryingBoard:PerformActionOnHex(hex)
    self.targetHex = hex -- skip refreshing cells/audio
    self:PerformActionOnTargetHex()
end

function ZO_ScryingBoard:PerformActionOnTargetHex()
    local targetHex = self.targetHex
    if not targetHex then
        return
    end

    local currentSkill = SCRYING:GetCurrentSkill()

    if currentSkill == SCRYING_ACTIVE_SKILL_LINE and self.lineStartHex == nil then
        local result = CanPreviewScryingAction(self:GetScryingActionParameters())
        if result ~= SCRYING_ACTIVE_SKILL_USE_RESULT_SUCCESS then
            DisplayScryingActiveSkillUseResult(result)
            return
        end
        self.lineStartHex = targetHex
        PlaySound(SOUNDS.SCRYING_START_LINE)
    elseif currentSkill == SCRYING_ACTIVE_SKILL_LINE and self.lineStartHex == targetHex then
        self:CancelLineAction()
        return
    else
        local result = CanPerformScryingAction(self:GetScryingActionParameters())
        if result ~= SCRYING_ACTIVE_SKILL_USE_RESULT_SUCCESS then
            DisplayScryingActiveSkillUseResult(result)
            return
        end

        HandleScryingAction(self:GetScryingActionParameters())
        self:PlayHexChangeAnimations()
        local NO_SOUND = true
        SCRYING:TrySetCurrentSkill(SCRYING_ACTIVE_SKILL_NORMAL, NO_SOUND)
    end

    self:DirtySimulatedActionState()
    SCRYING:RefreshNormalActionMeter()
    SCRYING:RefreshSpecialActionMeter()
    SCRYING:RefreshActionButtons()
    SCRYING:RefreshEyeAnimations()

    if GetNumScryingGoalsAchieved() > 0 then
        TUTORIAL_MANAGER:ShowTutorial(TUTORIAL_TRIGGER_ANTIQUITY_SCRYING_GOAL_CAPTURED)
    end
end

do
    local MIN_SCALE = 0.75
    local MIN_ALPHA = 0.4
    function ZO_ScryingBoard:OnEndOfGameTimelineUpdate(animation, progress)
        local scale = zo_lerp(1, MIN_SCALE, progress)
        local alpha = zo_lerp(1, MIN_ALPHA, progress)
        for _, hex in ipairs(self.hexList) do
            if hex:GetHexType() ~= SCRYING_HEX_TYPE_OWNED then
                hex:SetScale(scale)
                hex:SetAlpha(alpha)
            end
        end
    end
end

function ZO_ScryingBoard:GetLineStartHex()
    return self.lineStartHex
end

function ZO_ScryingBoard:HasInProgressLineAction()
    return self.lineStartHex ~= nil
end

function ZO_ScryingBoard:CancelLineAction()
    if self:HasInProgressLineAction() then
        self.lineStartHex = nil
        self:DirtySimulatedActionState()
    end
end

function ZO_ScryingBoard:OnChangeCurrentSkill()
    self:CancelLineAction()
    self:DirtySimulatedActionState()
end

function ZO_ScryingBoard:GetControl()
    return self.boardControl
end

----------------------
-- Scrying Minigame --
----------------------

ZO_Scrying = ZO_InitializingObject:Subclass()

function ZO_Scrying:Initialize(control)
    self.control = control
    self.board = ZO_ScryingBoard:New(control:GetNamedChild("Game"))

    self.isScryingReady = false
    self.waitingForScryingResult = false
    self.waitingToCompleteScrying = false
    self.lastScryingResult = nil

    local frameElements = control:GetNamedChild("GameFrame")
    self.normalActionMeter = ZO_ScryingNormalActionsMeter:New(frameElements:GetNamedChild("NormalActionMeter"))
    self.specialActionMeter = ZO_ScryingSpecialActionsMeter:New(frameElements:GetNamedChild("SpecialActionMeter"))

    self.actionButtons =
    {
        ZO_ScryingActionButton:New(frameElements:GetNamedChild("NormalAction"), SCRYING_ACTIVE_SKILL_NORMAL, "SCRYING_TOGGLE_NORMAL_ACTION"),
        ZO_ScryingActionButton:New(frameElements:GetNamedChild("SpecialAction1"), SCRYING_ACTIVE_SKILL_BOMB, "SCRYING_TOGGLE_SPECIAL_ACTION_1"),
        ZO_ScryingActionButton:New(frameElements:GetNamedChild("SpecialAction2"), SCRYING_ACTIVE_SKILL_CO_OPT, "SCRYING_TOGGLE_SPECIAL_ACTION_2"),
        ZO_ScryingActionButton:New(frameElements:GetNamedChild("SpecialAction3"), SCRYING_ACTIVE_SKILL_LINE, "SCRYING_TOGGLE_SPECIAL_ACTION_3"),
    }

    self.moreInfoButton = frameElements:GetNamedChild("MoreInfoKeybindButton")
    self.moreInfoButton:SetText(GetString(SI_SCRYING_MORE_INFO))
    local DEFAULT_SHOW_UNBOUND = nil
    local DEFAULT_GAMEPAD_PREFERRED_KEYBIND = nil
    local DEFAULT_ALWAYS_PREFER_GAMEPAD_MODE = nil
    local SHOW_AS_HOLD = true
    self.moreInfoButton:SetKeybind("SCRYING_MORE_INFO", DEFAULT_SHOW_UNBOUND, DEFAULT_GAMEPAD_PREFERRED_KEYBIND, DEFAULT_ALWAYS_PREFER_GAMEPAD_MODE, SHOW_AS_HOLD)
    ApplyTemplateToControl(self.moreInfoButton, "ZO_KeybindButton_Gamepad_Template")

    SCRYING_SCENE = ZO_RemoteScene:New("Scrying", SCENE_MANAGER)
    SCRYING_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        local NO_SOUND = true
        local ANIMATE_INSTANTLY = true
        if newState == SCENE_SHOWING then
            self.isScryingReady = false
            self.startedOutro = false
            self.startedEndOfGame = false
            self:TrySetCurrentSkill(SCRYING_ACTIVE_SKILL_NORMAL, NO_SOUND)
            self.board:OnShowing()
            self.normalActionMeter:OnShowing()
            self:RefreshNormalActionMeter(ANIMATE_INSTANTLY)
            self:RefreshSpecialActionMeter(ANIMATE_INSTANTLY)
            self:RefreshActionButtons()
            self:RefreshEyeAnimations()
            self:RefreshMoreInfoButton()
            self:RefreshInputState()
            PlaySound(SOUNDS.SCRYING_START_INTRO)
        elseif newState == SCENE_HIDING then
            --clear the current tutorial when hiding so we don't push an extra action layer
            self:RefreshInputState()
            ZO_Dialogs_ReleaseAllDialogsOfName("CONFIRM_EXIT_SCRYING")
        elseif newState == SCENE_HIDDEN then
            self.board:OnHidden()
            -- on the off chance that we are asked to hide while the outro is still in progress, clear out all that state
            self:ResetScryingPostGameElements()
        end
    end)

    control:RegisterForEvent(EVENT_SCRYING_INTRO_COMPLETE, function()
        self.isScryingReady = true
        self:TryTriggerInitialTutorials()
    end)

    control:RegisterForEvent(EVENT_SCRYING_OUTRO_COMPLETE, function()
        self.waitingForOutro = false
        self:TryCompleteScrying()
    end)

    control:RegisterForEvent(EVENT_GAMEPAD_PREFERRED_MODE_CHANGED, function()
        if SCRYING_SCENE:IsShowing() then
            self:RefreshInputState()
            self:RefreshActionButtons()
            self:RefreshMoreInfoButton()
        end
    end)

    control:RegisterForEvent(EVENT_START_SCRYING, function()
        SCENE_MANAGER:Show("Scrying")
    end)

    control:RegisterForEvent(EVENT_REQUEST_SCRYING_EXIT, function()
        self:HideMoreInfo()
        ZO_Dialogs_ShowPlatformDialog("CONFIRM_EXIT_SCRYING")
    end)

    control:RegisterForEvent(EVENT_SCRYING_GAME_OVER, function()
        self.waitingForScryingResult = true
        self.waitingToCompleteScrying = true
        self:TryCompleteScrying()
    end)

    control:RegisterForEvent(EVENT_ANTIQUITY_SCRYING_RESULT, function(_, result)
        self.lastScryingResult = result
        if self.waitingForScryingResult then
            self.waitingForScryingResult = false
            self:TryCompleteScrying()
        end
    end)

    local function RefreshInputState()
        self:RefreshInputState()
    end
    
    ZO_HELP_OVERLAY_SYNC_OBJECT:SetHandler("OnShown", RefreshInputState, "Scrying")
    ZO_HELP_OVERLAY_SYNC_OBJECT:SetHandler("OnHidden", RefreshInputState, "Scrying")

    ZO_DIALOG_SYNC_OBJECT:SetHandler("OnShown", RefreshInputState, "Scrying")
    ZO_DIALOG_SYNC_OBJECT:SetHandler("OnHidden", function()
        self:RefreshInputState()
        if self.waitingOnDialogToEndGame then
            self:TryCompleteScrying()
            self.waitingOnDialogToEndGame = false
        end
    end, "Scrying")

    SCRYING_HEX_ANIMATION_PROVIDER:RegisterCallback("BlockingAnimationsCompleted", function()
        self:TryCompleteScrying()
    end)

    self.endOfGameTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_ScryingHex_EndOfGame")
    self.endOfGameTimeline:GetFirstAnimation():SetUpdateFunction(function(...)
        self.board:OnEndOfGameTimelineUpdate(...)
        self.normalActionMeter:OnEndOfGameTimelineUpdate(...)
    end)

    self.platformStyle = ZO_PlatformStyle:New(function(style) self:ApplyPlatformStyle(style) end)
end

function ZO_Scrying:CanFireActions()
    return self.isScryingReady
end

function ZO_Scrying:RefreshInputState()
    local allowPlayerInput = SCRYING_SCENE:IsShowing() and not ZO_HELP_OVERLAY_SYNC_OBJECT:IsShown() and not ZO_DIALOG_SYNC_OBJECT:IsShown()
    if self.isPlayerInputEnabled ~= allowPlayerInput then
        if allowPlayerInput then
            PushActionLayerByName("ScryingActions")
            self.isPlayerInputEnabled = true
        else
            RemoveActionLayerByName("ScryingActions")
            self.isPlayerInputEnabled = false
        end
    end

    local useVirtualCursor = allowPlayerInput and IsInGamepadPreferredMode()
    if self.board:IsVirtualCursorEnabled() ~= useVirtualCursor then
        if useVirtualCursor then
            self.board:EnableVirtualCursor()
        else
            -- with input mode switching we can get into a situation where the hide more info release callback never gets triggered
            -- manually hide here to deal with that
            self:HideMoreInfo()
            self.board:DisableVirtualCursor()
        end
    end
end

function ZO_Scrying:RefreshMoreInfoButton()
    self.moreInfoButton:SetHidden(not IsInGamepadPreferredMode())
end

function ZO_Scrying:ApplyPlatformStyle(style)
    self.normalActionMeter:UpdatePlatformStyle()
    for _, actionButton in ipairs(self.actionButtons) do
        actionButton:UpdatePlatformStyle()
    end
end

function ZO_Scrying:IsPlayerInputEnabled()
    return self.isPlayerInputEnabled
end

do
    local ABILITY_TUTORIALS =
    {
        [SCRYING_ACTIVE_SKILL_BOMB] = TUTORIAL_TRIGGER_ANTIQUITY_SCRYING_UNITE_UNLOCKED,
        [SCRYING_ACTIVE_SKILL_CO_OPT] = TUTORIAL_TRIGGER_ANTIQUITY_SCRYING_CO_OPT_UNLOCKED,
        [SCRYING_ACTIVE_SKILL_LINE] = TUTORIAL_TRIGGER_ANTIQUITY_SCRYING_EXTEND_UNLOCKED,
    }

    local ABILITY_UPGRADED_TUTORIALS =
    {
        [SCRYING_ACTIVE_SKILL_BOMB] = TUTORIAL_TRIGGER_ANTIQUITY_SCRYING_UNITE_UPGRADED,
        [SCRYING_ACTIVE_SKILL_CO_OPT] = TUTORIAL_TRIGGER_ANTIQUITY_SCRYING_CO_OPT_UPGRADED,
        [SCRYING_ACTIVE_SKILL_LINE] = TUTORIAL_TRIGGER_ANTIQUITY_SCRYING_EXTEND_UPGRADED,
    }

    function ZO_Scrying:TryTriggerInitialTutorials()
        TUTORIAL_MANAGER:ShowTutorial(TUTORIAL_TRIGGER_ANTIQUITY_SCRYING_OPENED)

        for skill = SCRYING_ACTIVE_SKILL_ITERATION_BEGIN, SCRYING_ACTIVE_SKILL_ITERATION_END do
            if IsScryingActiveSkillUnlocked(skill) then
                local abilityTutorial = ABILITY_TUTORIALS[skill]
                if abilityTutorial then
                    TUTORIAL_MANAGER:ShowTutorial(abilityTutorial)
                end
                if IsScryingActiveSkillUpgraded(skill) then
                    local upgradedAbilityTutorial = ABILITY_UPGRADED_TUTORIALS[skill]
                    if upgradedAbilityTutorial then
                        TUTORIAL_MANAGER:ShowTutorial(upgradedAbilityTutorial)
                    end
                end
            end
        end
    end
end

function ZO_Scrying:ResetScryingPostGameElements()
    self.waitingToCompleteScrying = false
    self.waitingForScryingResult = false
    self:CancelEndOfGame()
    self.startedOutro = false
    self.waitingForOutro = false
end

function ZO_Scrying:TryCompleteScrying()
    if not self.waitingToCompleteScrying then
        return
    end

    if self.waitingForScryingResult then
        -- wait until server provides a scrying result
        return
    end

    if SCRYING_HEX_ANIMATION_PROVIDER:AreBlockingAnimationsPlaying() then
        -- wait until existing animations are complete
        return
    end

    if ZO_DIALOG_SYNC_OBJECT:IsShown() then
        -- Wait until the user closes the tutorial
        self.waitingOnDialogToEndGame = true
        return
    end

    if not self.startedEndOfGame then
        self:StartEndOfGame()
    end
    if self.waitingForEndOfGame then
        return
    end

    if not self.startedOutro then
        self.startedOutro = true
        StartScryingOutro()
        self.waitingForOutro = true
    end
    if self.waitingForOutro then
        return
    end

    self.waitingToCompleteScrying = false
    SCENE_MANAGER:Hide("Scrying")

    if self.lastScryingResult == ANTIQUITY_SCRYING_RESULT_SUCCESS then
        RequestRevealAntiquityDigSitesOnMap(GetScryingCurrentAntiquityId())
    end
end

function ZO_Scrying:GetScryingBoard()
    return self.board
end

function ZO_Scrying:TrySetCurrentSkill(scryingActiveSkill, shouldSupressSound)
    if self.currentActiveSkill ~= scryingActiveSkill then
        local useResult = IsScryingActiveSkillUsable(scryingActiveSkill)
        if useResult ~= SCRYING_ACTIVE_SKILL_USE_RESULT_SUCCESS then
            DisplayScryingActiveSkillUseResult(useResult)
            return
        end

        self.currentActiveSkill = scryingActiveSkill
        if not shouldSupressSound then
            PlaySound(SOUNDS.SCRYING_CHOOSE_SKILL)
        end
        self.board:OnChangeCurrentSkill()
        self:RefreshActionButtons()
    end
end

function ZO_Scrying:TryToggleCurrentSkill(scryingActiveSkill, shouldSupressSound)
    if not self:CanFireActions() then
        return
    end
    if self.currentActiveSkill == scryingActiveSkill then
        -- toggle back to normal mode. if we were going to normal mode anwyays, this has no effect
        scryingActiveSkill = SCRYING_ACTIVE_SKILL_NORMAL
    end
    self:TrySetCurrentSkill(scryingActiveSkill, shouldSupressSound)
end

function ZO_Scrying:GetCurrentSkill()
    return self.currentActiveSkill
end

function ZO_Scrying:PerformAction()
    if not self:CanFireActions() then
        return
    end
    self.board:PerformActionOnTargetHex()
end

function ZO_Scrying:RefreshNormalActionMeter(shouldAnimateInstantly)
    self.normalActionMeter:SmoothTransition(GetNumScryingNormalActions(), GetNumScryingNormalActionsLimit(), shouldAnimateInstantly)
end

function ZO_Scrying:RefreshSpecialActionMeter(shouldAnimateInstantly)
    local specialActions, partialSpecialActions = GetNumScryingSpecialActions()
    local shouldFillPartialGem = partialSpecialActions > 0
    self.specialActionMeter:SmoothTransition(specialActions, shouldFillPartialGem, shouldAnimateInstantly)
end

function ZO_Scrying:RefreshActionButtons()
    for _, actionButton in ipairs(self.actionButtons) do
        actionButton:Refresh()
    end
end

function ZO_Scrying:RefreshEyeAnimations()
    if not self.eyeBackdropLoop then
        local backgroundElements = self.control:GetNamedChild("GameEyeBackground")
        self.eyeBackdropLoop = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_ScryingBackdrop_TextureScroll", backgroundElements:GetNamedChild("Scroll"))
        self.eyeBackdropLoop:PlayFromStart()

        self.eyeBackdropLeftSpinLoop = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_ScryingBackdrop_SpinCW", backgroundElements:GetNamedChild("LeftSpin"))
        self.eyeBackdropLeftSpinLoop:PlayFromStart()

        self.eyeBackdropRightSpinLoop = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_ScryingBackdrop_SpinCW", backgroundElements:GetNamedChild("RightSpin"))
        self.eyeBackdropRightSpinLoop:PlayFromEnd() -- reverse for counterclockwise rotation

        local frameElements = self.control:GetNamedChild("GameFrame")
        self.eyeFrameGlowLoop = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_ScryingFrame_GlowLoop", frameElements:GetNamedChild("Glow"))
        self.eyeFrameGlowLoop:PlayFromStart()
    end
end

function ZO_Scrying:OnUnhandledMouseUp()
    self.board:CancelLineAction()
end

function ZO_Scrying:OnUnhandledReceiveDrag()
    self.board:CancelLineAction()
end

function ZO_Scrying:TryCancel()
    if not self:CanFireActions() then
        return
    end
    if self.board:HasInProgressLineAction() then
        self.board:CancelLineAction()
    else
        SCENE_MANAGER:Hide("Scrying")
    end
end

function ZO_Scrying:StartEndOfGame()
    self.startedEndOfGame = true

    self.completedEndOfGameCallLaterId = zo_callLater(function()
        self.completedEndOfGameCallLaterId = nil
        self.waitingForEndOfGame = false
        self:TryCompleteScrying()
    end, 2000)

    self.endOfGameTimeline:PlayFromStart()
    PlaySound(SOUNDS.SCRYING_START_END_OF_GAME)

    self.waitingForEndOfGame = true
end

function ZO_Scrying:CancelEndOfGame()
    if self.completedEndOfGameCallLaterId then
        zo_removeCallLater(self.completedEndOfGameCallLaterId)
        self.completedEndOfGameCallLaterId = nil
        self.endOfGameTimeline:Stop()
    end
end

function ZO_Scrying:ShowMoreInfo()
    if not self:CanFireActions() then
        return
    end
    local abilityId = GetScryingActiveSkillAbilityId(self:GetCurrentSkill())
    GAMEPAD_TOOLTIPS:LayoutSimpleAbility(GAMEPAD_RIGHT_TOOLTIP, abilityId)
end

function ZO_Scrying:HideMoreInfo()
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
end

do
    local ACCEPT = true
    local REJECT = false
    ZO_Dialogs_RegisterCustomDialog("CONFIRM_EXIT_SCRYING",
    {
        mustChoose = true,
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.BASIC,
        },
        title =
        {
            text = SI_SCRYING_CONFIRM_EXIT_DIALOG_TITLE
        },
        mainText =
        {
            text = SI_SCRYING_CONFIRM_EXIT_DIALOG_DESCRIPTION
        },
        setup = function()
            SCRYING:RefreshInputState()
        end,
        finishedCallback = function()
            SCRYING:RefreshInputState()
        end,
        buttons =
        {
            {
                text = SI_DIALOG_ACCEPT,
                callback = function()
                    RequestRespondToScryingExit(ACCEPT)
                end
            },
            {
                text = SI_DIALOG_DECLINE,
                callback = function()
                    RequestRespondToScryingExit(REJECT)
                end
            },
        }
    })
end

-- XML

function ZO_Scrying_OnInitialized(control)
    SCRYING = ZO_Scrying:New(control)
end

do
    local UNIT_HEX_RADIUS_X = 1 -- the rightmost point of the hexagon is already at 1
    local UNIT_HEX_RADIUS_Y = 2 / math.sqrt(3) -- AKA 1 / sin(60deg), this will take the top/bottom of the hexagon at sin(60deg) and stretch it up to 1

    function ZO_Scrying_CalculateHexPoint(angleDegrees)
        local angleRadians = math.rad(angleDegrees)
        -- Step 1. multiply by the unit hex radius. This will create a "circle" with value range [-1, 1]
        local scaledX = math.cos(angleRadians) * UNIT_HEX_RADIUS_X
        local scaledY = math.sin(angleRadians) * UNIT_HEX_RADIUS_Y
        -- Step 2. convert [-1, 1] values from unit circle to [0, 1]
        local normalizedX = (scaledX + 1) * 0.5
        local normalizedY = (scaledY + 1) * 0.5
        internalassert(normalizedX >= 0 and normalizedX <= 1)
        internalassert(normalizedY >= 0 and normalizedY <= 1)
        return normalizedX, normalizedY
    end

    function ZO_ScryingHexPolygon_OnInitialized(polygon)
        -- Create hexagon from points
        for angleDegrees = 0, 300, 60 do
            polygon:AddPoint(ZO_Scrying_CalculateHexPoint(angleDegrees))
        end
    end

    function ZO_FramePolygon_OnInitialized(polygon)
        -- This is a shape that outlines the "window" into the antiquarian's eye. It traces the edge of the window fairly precisely.
        polygon:AddPoint(0.819490, 0.501118)
        polygon:AddPoint(0.777049, 0.633015)
        polygon:AddPoint(0.729892, 0.735502)
        polygon:AddPoint(0.676250, 0.820165)
        polygon:AddPoint(0.623788, 0.870963)
        polygon:AddPoint(0.572504, 0.872745)
        polygon:AddPoint(0.548336, 0.861160)
        polygon:AddPoint(0.532421, 0.882548)
        polygon:AddPoint(0.524758, 0.869180)
        polygon:AddPoint(0.524168, 0.809471)
        polygon:AddPoint(0.511200, 0.765802)
        polygon:AddPoint(0.500000, 0.745305)
        polygon:AddPoint(0.481727, 0.785408)
        polygon:AddPoint(0.475832, 0.814818)
        polygon:AddPoint(0.476421, 0.871854)
        polygon:AddPoint(0.468758, 0.883440)
        polygon:AddPoint(0.451074, 0.860269)
        polygon:AddPoint(0.429854, 0.872745)
        polygon:AddPoint(0.377391, 0.875419)
        polygon:AddPoint(0.320802, 0.815709)
        polygon:AddPoint(0.269519, 0.739958)
        polygon:AddPoint(0.228256, 0.650838)
        polygon:AddPoint(0.201730, 0.577761)
        polygon:AddPoint(0.179920, 0.502901)
        polygon:AddPoint(0.212930, 0.386154)
        polygon:AddPoint(0.244172, 0.312185)
        polygon:AddPoint(0.306066, 0.200786)
        polygon:AddPoint(0.372675, 0.125926)
        polygon:AddPoint(0.477011, 0.125035)
        polygon:AddPoint(0.500589, 0.160683)
        polygon:AddPoint(0.521221, 0.127709)
        polygon:AddPoint(0.624967, 0.127709)
        polygon:AddPoint(0.676250, 0.181180)
        polygon:AddPoint(0.731071, 0.268517)
        polygon:AddPoint(0.782943, 0.379916)
    end

    function ZO_HexMaskPolygon_OnInitialized(polygon)
        -- defines a smaller mask that avoids the extra lattice work at the top and bottom of the window
        polygon:AddPoint(0.785301, 0.413781)
        polygon:AddPoint(0.792375, 0.506465)
        polygon:AddPoint(0.768796, 0.623211)
        polygon:AddPoint(0.723997, 0.732828)
        polygon:AddPoint(0.675661, 0.789864)
        polygon:AddPoint(0.617893, 0.816600)
        polygon:AddPoint(0.558357, 0.791647)
        polygon:AddPoint(0.540673, 0.805906)
        polygon:AddPoint(0.521221, 0.786300)
        polygon:AddPoint(0.501768, 0.742631)
        polygon:AddPoint(0.477600, 0.786300)
        polygon:AddPoint(0.458737, 0.803232)
        polygon:AddPoint(0.439285, 0.789864)
        polygon:AddPoint(0.380338, 0.811253)
        polygon:AddPoint(0.317266, 0.784517)
        polygon:AddPoint(0.278950, 0.736393)
        polygon:AddPoint(0.234151, 0.639253)
        polygon:AddPoint(0.220593, 0.577761)
        polygon:AddPoint(0.212341, 0.450320)
        polygon:AddPoint(0.222362, 0.388828)
        polygon:AddPoint(0.247119, 0.316641)
        polygon:AddPoint(0.297224, 0.224176)
        polygon:AddPoint(0.329055, 0.223285)
        polygon:AddPoint(0.415117, 0.216155)
        polygon:AddPoint(0.434569, 0.206352)
        polygon:AddPoint(0.456380, 0.231306)
        polygon:AddPoint(0.476421, 0.216155)
        polygon:AddPoint(0.500000, 0.250021)
        polygon:AddPoint(0.522400, 0.215264)
        polygon:AddPoint(0.544799, 0.232197)
        polygon:AddPoint(0.565431, 0.207243)
        polygon:AddPoint(0.600799, 0.219720)
        polygon:AddPoint(0.695703, 0.221502)
        polygon:AddPoint(0.732839, 0.284558)
    end
end

function ZO_Scrying_FadeInCursor_OnInitialized(cursor)
    cursor.fadeInTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_ScryingModalCursor_FadeIn", cursor)
    cursor.translationAnimation = cursor.fadeInTimeline:GetFirstAnimation()
    -- every control that inherits from this should set the translationAnimation's offsets
end

function ZO_Scrying_FadeInCursor_OnEffectivelyShown(cursor)
    cursor:SetAlpha(0)
    cursor.fadeInTimeline:PlayFromStart()
end

