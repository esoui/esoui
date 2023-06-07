--Star
----------------------
ZO_CHAMPION_STAR_DEPTH = 1.68
ZO_CHAMPION_CLUSTER_STAR_DEPTH = 2.68

ZO_ChampionStar = ZO_InitializingObject:Subclass()

local HANDLED = true
local NOT_HANDLED = false

local KEYBOARD_ALLOCATE_POINTS_BUTTON_TEMPLATES = 
{
    SIZE = 26,
    DECREASE = {
        NORMAL = "EsoUI/Art/Buttons/pointsMinus_up.dds",
        PRESSED = "EsoUI/Art/Buttons/pointsMinus_down.dds",
        MOUSEOVER = "EsoUI/Art/Buttons/pointsMinus_over.dds",
        DISABLED = "EsoUI/Art/Buttons/pointsMinus_disabled.dds",
    },
    INCREASE = {
        NORMAL = "EsoUI/Art/Buttons/pointsPlus_up.dds",
        PRESSED = "EsoUI/Art/Buttons/pointsPlus_down.dds",
        MOUSEOVER = "EsoUI/Art/Buttons/pointsPlus_over.dds",
        DISABLED = "EsoUI/Art/Buttons/pointsPlus_disabled.dds",
    },
}

local GAMEPAD_ALLOCATE_POINTS_BUTTON_TEMPLATES = 
{
    SIZE = 32,
    DECREASE = {
        NORMAL = "EsoUI/Art/Buttons/Gamepad/gp_minus_dim3.dds",
        PRESSED = "EsoUI/Art/Buttons/Gamepad/gp_minus_dim3.dds",
        MOUSEOVER = "EsoUI/Art/Buttons/Gamepad/gp_minus_dim3.dds",
        DISABLED = "EsoUI/Art/Buttons/Gamepad/gp_minus_dim2.dds",
    },
    INCREASE = {
        NORMAL = "EsoUI/Art/Buttons/Gamepad/gp_plus_dim3.dds",
        PRESSED = "EsoUI/Art/Buttons/Gamepad/gp_plus_dim3.dds",
        MOUSEOVER = "EsoUI/Art/Buttons/Gamepad/gp_plus_dim3.dds",
        DISABLED = "EsoUI/Art/Buttons/Gamepad/gp_plus_dim2.dds",
    },
}

function ZO_ChampionStar:Initialize(constellation, parentCluster)
    self.constellation = constellation
    self.parentCluster = parentCluster
    self.sceneNode = parentCluster.node

    self.hidden = false
    self.active = false

    self.depth = parentCluster:IsRootCluster() and ZO_CHAMPION_STAR_DEPTH or ZO_CHAMPION_CLUSTER_STAR_DEPTH
    self.state = nil

    self.starScaleInterpolator = ZO_LerpInterpolator:New(1)

    self.oneShotAnimationOnReleaseCallback = function(texture)
        local currentAnimInfo = self.oneShotAnimationInfo

        self.oneShotAnimationTimeline = nil
        self.oneShotAnimationInfo = nil
        
        if currentAnimInfo.onComplete then
            currentAnimInfo.onComplete(self)
        end

        self.sceneNode:RemoveTexture(texture)
    end
end

function ZO_ChampionStar:AcquireTexture()
    local texture = CHAMPION_PERKS:AcquireStarTexture()
    texture.star = self
    self.texture = texture

    if not texture.mouseInputGroup then
        texture.mouseInputGroup = ZO_MouseInputGroup:New(texture)
    end

    self.visuals = ZO_ChampionStarVisuals:New(texture)
    self.sceneNode:AddTextureComposite(texture, 0, 0, 0)
    self.sceneNode:SetControlPosition(texture, self.x, self.y, self.depth)
    self.sceneNode:SetControlHidden(texture, self.hidden)
    self:RefreshState()
end

function ZO_ChampionStar:ReleaseTexture()
    if WINDOW_MANAGER:GetMouseOverControl() == self.texture then
        -- Protection against the case where a player hides a constellation
        -- while moused over it: by the time we call the mouse exit handler, the
        -- control has already been released to the pool, so we'll just do it now
        self:OnMouseExit()
    end
    self.sceneNode:RemoveTextureComposite(self.texture)
    CHAMPION_PERKS:ReleaseStarTexture(self.texture)
    self.texture.star = nil
    self.texture = nil
end

function ZO_ChampionStar:GetNormalizedCoordinates()
    return self.nx, self.ny
end

function ZO_ChampionStar:InitializeKeyboardTooltip(tooltip)
    local starCenterX, _ = self.texture:GetCenter()
    local screenCenterX, _ = GuiRoot:GetCenter()
    if starCenterX > screenCenterX then
        InitializeTooltip(tooltip, self.texture, RIGHT, -65, 0, CENTER)
    else
        InitializeTooltip(tooltip, self.texture, LEFT, 65, 0, CENTER)
    end
end

function ZO_ChampionStar:AnchorGamepadTooltipToStar(tooltipControl)
    local starCenterX, _ = self.texture:GetCenter()
    local screenCenterX, _ = GuiRoot:GetCenter()
    tooltipControl:ClearAnchors()
    if starCenterX > screenCenterX then
        tooltipControl:SetAnchor(RIGHT, self.texture, CENTER, -95)
    else
        tooltipControl:SetAnchor(LEFT, self.texture, CENTER, 95)
    end
end

function ZO_ChampionStar:SetNormalizedCoordinates(nx, ny)
    self.nx, self.ny = nx, ny
    self.x, self.y = ZO_Champion_ConvertNormalizedCoordinatesToNodeOffset(self.nx, self.ny)
    if self.texture then
        self.sceneNode:SetControlPosition(self.texture, self.x, self.y, self.depth)
    end
end

function ZO_ChampionStar:GetWorldSpaceCoordinates()
    local worldX, worldY = self.sceneNode:GetWorldSpaceCoordinates(self.x, self.y, self.depth)
    return worldX, worldY
end

do
    -- the node coordinate system works like the UI coordinate system: +x is right, +y is down, units are arbitrary.
    -- normalized coordinates use +x is right, +y is up, units are also arbitrary. this makes more sense for the data; which will always be growing up from the origin.
    -- normalized coordinates also define an origin that would be a good place for the root node to be: it's positionX/Y should be 0, 0.
    ZO_CHAMPION_STAR_COORDINATE_SCALE = 0.5
    ZO_CHAMPION_STAR_ROOT_OFFSET_Y = -450
    function ZO_Champion_ConvertNormalizedCoordinatesToNodeOffset(normalizedX, normalizedY)
        local x = normalizedX * ZO_CHAMPION_STAR_COORDINATE_SCALE
        local y = -normalizedY * ZO_CHAMPION_STAR_COORDINATE_SCALE + ZO_CHAMPION_STAR_ROOT_OFFSET_Y
        return x, y
    end

    function ZO_Champion_ConvertNodeOffsetToNormalizedCoordinates(x, y)
        local normalizedX = x / ZO_CHAMPION_STAR_COORDINATE_SCALE
        local normalizedY = -(y - ZO_CHAMPION_STAR_ROOT_OFFSET_Y) / ZO_CHAMPION_STAR_COORDINATE_SCALE
        return normalizedX, normalizedY
    end
end

function ZO_ChampionStar:GetTexture()
    return self.texture
end

function ZO_ChampionStar:RefreshStateFromSkillData(championSkillData)
    local disciplineData = championSkillData:GetChampionDisciplineData()
    if championSkillData:WouldBePurchased() then
        self.state = ZO_CHAMPION_STAR_STATE.PURCHASED
    elseif championSkillData:GetNumPendingPoints() > 0 or ((disciplineData:HasAnySavedUnspentPoints() or CHAMPION_PERKS:IsInRespecMode()) and championSkillData:CanBePurchased()) then
        self.state = ZO_CHAMPION_STAR_STATE.AVAILABLE
    else
        self.state = ZO_CHAMPION_STAR_STATE.LOCKED
    end

    if not self.active then
        if self.state == ZO_CHAMPION_STAR_STATE.AVAILABLE then
            self.state = ZO_CHAMPION_STAR_STATE.LOCKED
        end
    end

    self:RefreshTexture()
    self:RefreshEditor()
end

function ZO_ChampionStar:RefreshTexture()
    -- to be overridden
end

function ZO_ChampionStar:RefreshEditor()
    local shouldShowEditor = self.active and self.state ~= ZO_CHAMPION_STAR_STATE.LOCKED
    if shouldShowEditor then
        self:ShowEditor()
    else
        self:HideEditor()
    end
end

function ZO_ChampionStar:GetEditor()
    return self.editor
end

function ZO_ChampionStar:HideEditor()
    local isShowingEditor = self.editor ~= nil
    if isShowingEditor then
        CHAMPION_PERKS:ReleaseStarEditor(self.editorKey)
        self.editor, self.editorKey = nil, nil
    end
end

function ZO_ChampionStar:ShowEditor()
    local isShowingEditor = self.editor ~= nil
    if not isShowingEditor then
        self.editor, self.editorKey = CHAMPION_PERKS:AcquireStarEditor()
        self.editor:AttachToStar(self)
    end
end

function ZO_ChampionStar:OnSelected()
    if self.editor then
        self.editor:OnSelected()
    end
end

function ZO_ChampionStar:OnDeselected()
    if self.editor then
        self.editor:OnDeselected()
    end
end


local STAR_SCALE_UNSELECTED = 1
local STAR_SCALE_SELECTED = 1.7

function ZO_ChampionStar:UpdateVisuals(timeSecs, newStarAlpha)
    self.visuals:Update(timeSecs)

    local isSelected = self == self.constellation:GetSelectedStar()

    if isSelected then
        self.starScaleInterpolator:SetTargetBase(STAR_SCALE_SELECTED)
    else
        self.starScaleInterpolator:SetTargetBase(STAR_SCALE_UNSELECTED)
    end
    local starScale = self.starScaleInterpolator:Update(timeSecs)
    self.sceneNode:SetControlScale(self.texture, starScale)
    self.texture:SetAlpha(newStarAlpha)
end

function ZO_ChampionStar:SetHidden(hidden)
    if self.hidden ~= hidden then
        self.sceneNode:SetControlHidden(self.texture, hidden)
        self.hidden = hidden
    end
end

function ZO_ChampionStar:SetActive(active)
    if self.active ~= active then
        self.active = active
        self:RefreshState()
    end
end
    
function ZO_ChampionStar:GetConstellation()
    return self.constellation
end

function ZO_ChampionStar:OnMouseEnter()
    self.constellation:SelectStar(self)
end

function ZO_ChampionStar:OnMouseExit()
    self.constellation:SelectStar(nil)
end

function ZO_ChampionStar:OnMouseWheel()
    -- to be overridden
end

function ZO_ChampionStar:GetConstellation()
    return self.constellation
end

function ZO_ChampionStar:IsSkillStar()
    return false
end

function ZO_ChampionStar:IsClusterPortalStar()
    return false
end

ZO_ChampionStar.OnClicked = ZO_ChampionStar:MUST_IMPLEMENT()
ZO_ChampionStar.OnDragStart = ZO_ChampionStar:MUST_IMPLEMENT()

function ZO_ChampionStar:ShowPlatformTooltip()
    if IsInGamepadPreferredMode() then
        self:ShowGamepadTooltip()
    elseif GetCursorContentType() == MOUSE_CONTENT_EMPTY then
        self:ShowKeyboardTooltip()
    end
end

ZO_ChampionStar.ShowKeyboardTooltip = ZO_ChampionStar:MUST_IMPLEMENT()
ZO_ChampionStar.ShowGamepadTooltip = ZO_ChampionStar:MUST_IMPLEMENT()
ZO_ChampionStar.ClearTooltip = ZO_ChampionStar:MUST_IMPLEMENT()
ZO_ChampionStar.HasPrimaryGamepadAction = ZO_ChampionStar:MUST_IMPLEMENT()
ZO_ChampionStar.CanPerformPrimaryGamepadAction = ZO_ChampionStar:MUST_IMPLEMENT()
ZO_ChampionStar.PerformPrimaryGamepadAction = ZO_ChampionStar:MUST_IMPLEMENT()
ZO_ChampionStar.GetPrimaryGamepadActionText = ZO_ChampionStar:MUST_IMPLEMENT()

ZO_ChampionSkillStar = ZO_ChampionStar:Subclass()

function ZO_ChampionSkillStar:Initialize(championSkillData, constellation, parentCluster)
    ZO_ChampionStar.Initialize(self, constellation, parentCluster)
    self.championSkillData = championSkillData
    self:SetNormalizedCoordinates(self.championSkillData:GetPosition())
end

function ZO_ChampionSkillStar:IsSkillStar()
    return true
end

function ZO_ChampionSkillStar:GetChampionSkillData()
    return self.championSkillData
end

function ZO_ChampionSkillStar:RefreshState()
    self:RefreshStateFromSkillData(self.championSkillData)
end

-- these don't have a 1:1 relationship with UI units, the 3d space can zoom further into or away from these controls
local STAR_CONTROL_SIZES_FOR_STATE = {
    [ZO_CHAMPION_STAR_STATE.LOCKED] = 16,
    [ZO_CHAMPION_STAR_STATE.AVAILABLE] = 16,
    [ZO_CHAMPION_STAR_STATE.PURCHASED] = 26,
}

function ZO_ChampionSkillStar:RefreshTexture()
    if not self.texture then
        -- texture released, we will refresh the next time we acquire
        return
    end

    local state = self.state or ZO_CHAMPION_STAR_STATE.LOCKED
    local type = self.championSkillData:GetType()
    if type == CHAMPION_SKILL_TYPE_NORMAL then
        self.visuals:Setup(ZO_CHAMPION_STAR_VISUAL_TYPE.NORMAL, state)
    elseif type == CHAMPION_SKILL_TYPE_NORMAL_SLOTTABLE or type == CHAMPION_SKILL_TYPE_STAT_POOL_SLOTTABLE then
        local disciplineType = self.championSkillData:GetChampionDisciplineData():GetType()
        local isSlotted = CHAMPION_PERKS:IsChampionSkillDataSlotted(self.championSkillData)
        self.visuals:Setup(ZO_CHAMPION_STAR_VISUAL_TYPE.SLOTTABLE, state, disciplineType, isSlotted)
    else
        internalassert(false, "missing star visuals")
    end

    local size = STAR_CONTROL_SIZES_FOR_STATE[state]
    self.texture:SetDimensions(self.sceneNode:ComputeSizeForDepth(size, size, self.depth, ZO_CHAMPION_REFERENCE_CAMERA_Z))
    self.texture:SetMouseEnabled(self.active)
end

function ZO_ChampionSkillStar:ShowKeyboardTooltip()
    local championSkillData = self:GetChampionSkillData()

    self:InitializeKeyboardTooltip(ChampionSkillTooltip)
    local pendingPoints = championSkillData:GetNumPendingPoints()
    ChampionSkillTooltip:SetChampionSkill(championSkillData:GetId(), pendingPoints, championSkillData:GetNextJumpPoint(pendingPoints), CHAMPION_PERKS:IsChampionSkillDataSlotted(championSkillData))
end

function ZO_ChampionSkillStar:ShowGamepadTooltip()
    local starTooltip = CHAMPION_PERKS:GetGamepadStarTooltip()
    self:AnchorGamepadTooltipToStar(starTooltip)
    starTooltip.scrollTooltip:ClearLines()
    starTooltip.tip:LayoutChampionSkill(self:GetChampionSkillData())
    starTooltip:SetHidden(false)
end

function ZO_ChampionSkillStar:ClearTooltip()
    ClearTooltip(ChampionSkillTooltip)
    local gamepadStarTooltip = CHAMPION_PERKS:GetGamepadStarTooltip()
    gamepadStarTooltip:SetHidden(true)
    gamepadStarTooltip.scrollTooltip:ClearLines()
end

function ZO_ChampionSkillStar:OnMouseWheel(delta)
    if not IsInGamepadPreferredMode() and self.editor then
        self.editor:OnMouseWheel(delta)
    end
end

function ZO_ChampionSkillStar:OnClicked(button, upInside)
    if upInside and self.editor then
        local increment = IsShiftKeyDown() and ZO_SPINNER_LARGE_INCREMENT or ZO_SPINNER_SMALL_INCREMENT
        if button == MOUSE_BUTTON_INDEX_LEFT and self.editor:CanAddPoints() then
            self.editor:AddOrRemovePoints(increment)
            return HANDLED
        elseif button == MOUSE_BUTTON_INDEX_RIGHT and self.editor:CanRemovePoints() then
            self.editor:AddOrRemovePoints(-increment)
            return HANDLED
        end
    end
    return NOT_HANDLED
end

function ZO_ChampionSkillStar:OnDragStart()
    local result = GetChampionPurchaseAvailability()
    if result ~= CHAMPION_PURCHASE_SUCCESS then
        ZO_AlertEvent(EVENT_CHAMPION_PURCHASE_RESULT, result)
        return NOT_HANDLED
    end

    local championSkillData = self:GetChampionSkillData()
    if championSkillData:TryCursorPickup() then
        PlaySound(SOUNDS.CHAMPION_STAR_PICKED_UP)
        return HANDLED
    end
    return NOT_HANDLED
end

function ZO_ChampionSkillStar:HasPrimaryGamepadAction()
    return self:GetChampionSkillData():IsTypeSlottable()
end

function ZO_ChampionSkillStar:CanPerformPrimaryGamepadAction()
    local result = GetChampionPurchaseAvailability()
    if result ~= CHAMPION_PURCHASE_SUCCESS then
        return false, GetString("SI_CHAMPIONPURCHASERESULT", result)
    end
    return self:GetChampionSkillData():CanBeSlotted()
end

function ZO_ChampionSkillStar:PerformPrimaryGamepadAction()
    CHAMPION_PERKS:GetChampionBar():GetGamepadEditor():StartAssigningChampionSkill(self:GetChampionSkillData())
end

function ZO_ChampionSkillStar:GetPrimaryGamepadActionText()
    return GetString(SI_GAMEPAD_CHAMPION_SLOT_SKILL)
end

ZO_ChampionClusterPortalStar = ZO_ChampionStar:Subclass()

function ZO_ChampionClusterPortalStar:Initialize(championClusterData, constellation, parentCluster)
    ZO_ChampionStar.Initialize(self, constellation, parentCluster)
    self.championClusterData = championClusterData
    self:SetNormalizedCoordinates(self:GetRootChampionSkillData():GetPositionNoClusterOffset())
end

function ZO_ChampionClusterPortalStar:IsClusterPortalStar()
    return true
end

function ZO_ChampionClusterPortalStar:GetChampionClusterData()
    return self.championClusterData
end

function ZO_ChampionClusterPortalStar:GetRootChampionSkillData()
    return self.championClusterData:GetRootChampionSkillData()
end

function ZO_ChampionClusterPortalStar:RefreshState()
    self:RefreshStateFromSkillData(self:GetRootChampionSkillData())
end

function ZO_ChampionClusterPortalStar:RefreshTexture()
    if not self.texture then
        -- texture released, we will refresh the next time we acquire
        return
    end

    local state = self.state or ZO_CHAMPION_STAR_STATE.LOCKED
    self.visuals:Setup(ZO_CHAMPION_STAR_VISUAL_TYPE.CLUSTER, state)

    local size = STAR_CONTROL_SIZES_FOR_STATE[state]
    self.texture:SetDimensions(self.sceneNode:ComputeSizeForDepth(size, size, self.depth, ZO_CHAMPION_REFERENCE_CAMERA_Z))
    self.texture:SetMouseEnabled(self.active)
end

function ZO_ChampionClusterPortalStar:OnMouseEnter()
    ZO_ChampionStar.OnMouseEnter(self)
    WINDOW_MANAGER:SetMouseCursor(MOUSE_CURSOR_PREVIEW)
end

function ZO_ChampionClusterPortalStar:OnMouseExit()
    ZO_ChampionStar.OnMouseExit(self)
    WINDOW_MANAGER:SetMouseCursor(MOUSE_CURSOR_DO_NOT_CARE)
end

function ZO_ChampionClusterPortalStar:OnClicked(button, upInside)
    if button == MOUSE_BUTTON_INDEX_LEFT and upInside then
        CHAMPION_PERKS:ChooseClusterData(self.championClusterData)
        return HANDLED
    end
    return NOT_HANDLED
end

function ZO_ChampionClusterPortalStar:OnDragStart()
    return NOT_HANDLED
end

function ZO_ChampionClusterPortalStar:ShowGamepadTooltip()
    local starTooltip = CHAMPION_PERKS:GetGamepadStarTooltip()
    self:AnchorGamepadTooltipToStar(starTooltip)
    starTooltip.scrollTooltip:ClearLines()
    starTooltip.tip:LayoutChampionCluster(self.championClusterData)
    starTooltip:SetHidden(false)
end

function ZO_ChampionClusterPortalStar:ShowKeyboardTooltip()
    self:InitializeKeyboardTooltip(InformationTooltip)
    InformationTooltip:AddLine(self.championClusterData:GetFormattedName(), "ZoFontWinH2")
    ZO_Tooltip_AddDivider(InformationTooltip)
    for _, clusterChild in ipairs(self.championClusterData:GetClusterChildren()) do
        local formattedName = ZO_NORMAL_TEXT:Colorize(clusterChild:GetFormattedName())
        InformationTooltip:AddLine(zo_strformat(SI_CHAMPION_TOOLTIP_CLUSTER_CHILD_FORMAT, formattedName, clusterChild:GetNumPendingPoints(), clusterChild:GetMaxPossiblePoints()), "", ZO_SELECTED_TEXT:UnpackRGBA())
    end
end

function ZO_ChampionClusterPortalStar:ClearTooltip()
    ClearTooltip(InformationTooltip)
    local gamepadStarTooltip = CHAMPION_PERKS:GetGamepadStarTooltip()
    gamepadStarTooltip:SetHidden(true)
    gamepadStarTooltip.scrollTooltip:ClearLines()
end

function ZO_ChampionClusterPortalStar:HasPrimaryGamepadAction()
    return true
end

function ZO_ChampionClusterPortalStar:CanPerformPrimaryGamepadAction()
    return true
end

function ZO_ChampionClusterPortalStar:PerformPrimaryGamepadAction()
    CHAMPION_PERKS:ChooseClusterData(self.championClusterData)
end

function ZO_ChampionClusterPortalStar:GetPrimaryGamepadActionText()
    return GetString(SI_GAMEPAD_CHAMPION_CLUSTER_ZOOM_IN)
end

ZO_ChampionStarEditor = ZO_InitializingObject:Subclass()

function ZO_ChampionStarEditor:Initialize(pool)
    self.control = ZO_ObjectPool_CreateControl("ZO_ChampionStarEditor", pool, CHAMPION_PERKS:GetChampionCanvas())
    self.fadeIn = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_ChampionStarEditorFade", self.control)
    local DEFAULT_MIN = nil
    local DEFAULT_MAX = nil
    local DEFAULT_INPUT_MODE = nil
    local DEFAULT_SPINNER_MODE = nil
    local ACCELERATION_TIME_MS = 50
    self.pointsSpinner = ZO_SpinnerWithLabels:New(self.control, DEFAULT_MIN, DEFAULT_MAX, DEFAULT_INPUT_MODE, DEFAULT_SPINNER_MODE, ACCELERATION_TIME_MS)
    self.pointsSpinner:SetPlaySoundFunction(function(spinner, currentValue, oldValue)
        local championSkillData = self.star:GetChampionSkillData()
        local currentJumpPoint = championSkillData:GetJumpPointForValue(currentValue)
        local oldJumpPoint = championSkillData:GetJumpPointForValue(oldValue)
        local isUnlocked = championSkillData:WouldBeUnlockedNodeAtValue(currentValue)
        local wasUnlocked = championSkillData:WouldBeUnlockedNodeAtValue(oldValue)
        if currentValue > oldValue then
            if not wasUnlocked and isUnlocked then
                PlaySound(SOUNDS.CHAMPION_STAR_UNLOCKED)
            elseif championSkillData:HasJumpPoints() and currentJumpPoint > oldJumpPoint then
                PlaySound(SOUNDS.CHAMPION_STAR_STAGE_UP)
            else
                PlaySound(SOUNDS.CHAMPION_SPINNER_UP)
            end
        else
            if wasUnlocked and not isUnlocked then
                PlaySound(SOUNDS.CHAMPION_STAR_LOCKED)
            elseif championSkillData:HasJumpPoints() and currentJumpPoint < oldJumpPoint then
                PlaySound(SOUNDS.CHAMPION_STAR_STAGE_DOWN)
            else
                PlaySound(SOUNDS.CHAMPION_SPINNER_DOWN)
            end
        end
    end)
    self.pointsSpinner:RegisterCallback("OnValueChanged", function(newValue)
        if self:IsAttached() and self.star:IsSkillStar() then
            self.star:GetChampionSkillData():SetNumPendingPoints(newValue)
        end
    end)
    self.pointsSpinner:SetValidValuesFunction(function(oldValue, delta)
        if self.star:IsSkillStar() then
            local championSkillData = self.star:GetChampionSkillData()
            if championSkillData:HasJumpPoints() then
                if delta == ZO_SPINNER_LARGE_INCREMENT then
                    local nextJumpPoint = championSkillData:GetNextJumpPoint(oldValue)
                    return zo_min(championSkillData:GetMaxPendingPoints(), nextJumpPoint)
                elseif delta == -ZO_SPINNER_LARGE_INCREMENT then
                    local previousJumpPoint = championSkillData:GetPreviousJumpPoint(oldValue)
                    return zo_max(championSkillData:GetMinPendingPoints(), previousJumpPoint)
                end
            end
        end

        return oldValue + delta
    end)
end

function ZO_ChampionStarEditor:AttachToStar(selectedStar)
    self.star = selectedStar
    local spinnerControl = self.pointsSpinner:GetControl()

    if SCENE_MANAGER:IsCurrentSceneGamepad() then
        self.pointsSpinner:SetFont("ZoFontGamepad42")
        spinnerControl:SetDimensions(120, 55)
        self:ApplyButtonTemplatesToSpinner(GAMEPAD_ALLOCATE_POINTS_BUTTON_TEMPLATES)
    else
        self.pointsSpinner:SetFont("ZoFontWinH2")
        spinnerControl:SetDimensions(100, 36)
        self:ApplyButtonTemplatesToSpinner(KEYBOARD_ALLOCATE_POINTS_BUTTON_TEMPLATES)
    end

    if self.star:IsSkillStar() then
        self.pointsSpinner:SetMouseEnabled(not IsInGamepadPreferredMode())
        self.pointsSpinner:SetButtonsHidden(false)
    elseif self.star:IsClusterPortalStar() then
        self.pointsSpinner:SetMouseEnabled(false)
        self.pointsSpinner:SetButtonsHidden(true)
    end
    self.control:SetHidden(false)
    self.fadeIn:PlayFromStart()

    local parentControl = self.star:GetTexture()
    self.control:ClearAnchors()
    self.control:SetAnchor(TOP, parentControl, CENTER, 0, 15)
    self.pointsSpinner:AddToMouseInputGroup(parentControl.mouseInputGroup, ZO_MOUSE_INPUT_GROUP_MOUSE_OVER)
    self:RefreshPointsMinMax()
    self:RefreshEnabledState()
end

function ZO_ChampionStarEditor:OnSelected()
    if IsInGamepadPreferredMode() then
        self.pointsSpinner.decreaseButton:SetHidden(true)
        self.pointsSpinner.increaseButton:SetHidden(true)
        if not self.star:IsClusterPortalStar() then
            self.pointsSpinner.decreaseKeyLabel:SetHidden(false)
            self.pointsSpinner.increaseKeyLabel:SetHidden(false)
        end
    end
end

function ZO_ChampionStarEditor:OnDeselected()
    if IsInGamepadPreferredMode() then
        if not self.star:IsClusterPortalStar() then
            self.pointsSpinner.decreaseButton:SetHidden(false)
            self.pointsSpinner.increaseButton:SetHidden(false)
        end
        self.pointsSpinner.decreaseKeyLabel:SetHidden(true)
        self.pointsSpinner.increaseKeyLabel:SetHidden(true)
    end
end

function ZO_ChampionStarEditor:Release()
    local starTexture = self.star:GetTexture()
    if starTexture then
        starTexture.mouseInputGroup:RemoveAll(ZO_MOUSE_INPUT_GROUP_MOUSE_OVER)
    end
    self.control:SetHidden(true)
    self.pointsSpinner.decreaseKeyLabel:SetHidden(true)
    self.pointsSpinner.increaseKeyLabel:SetHidden(true)
    self.fadeIn:PlayInstantlyToStart()
    self.star = nil
end

function ZO_ChampionStarEditor:IsAttached()
    return self.star ~= nil
end

function ZO_ChampionStarEditor:CanRemovePoints()
    if self:IsAttached() and self:IsEnabled() then
        return self.pointsSpinner:GetValue() > self.pointsSpinner:GetMin()
    end

    return false
end

function ZO_ChampionStarEditor:StartRemovingPoints()
    if self:IsAttached() then
        self.pointsSpinner:OnButtonDown(-1)
    end
end

function ZO_ChampionStarEditor:CanAddPoints()
    if self:IsAttached() and self:IsEnabled() then
        return self.pointsSpinner:GetValue() < self.pointsSpinner:GetMax()
    end

    return false
end

function ZO_ChampionStarEditor:StartAddingPoints()
    if self:IsAttached() then
        self.pointsSpinner:OnButtonDown(1)
    end
end

function ZO_ChampionStarEditor:StopChangingPoints()
    if self:IsAttached() then
        self.pointsSpinner:OnButtonUp()
    end
end

function ZO_ChampionStarEditor:AddOrRemovePoints(points)
    self.pointsSpinner:ModifyValue(points)
end

function ZO_ChampionStarEditor:RefreshPointsMinMax()
    if self:IsAttached() then
        if self.star:IsSkillStar() then
            local championSkillData = self.star:GetChampionSkillData()
            local min = championSkillData:GetMinPendingPoints()
            local max = championSkillData:GetMaxPendingPoints()
            local currentPendingPoints = championSkillData:GetNumPendingPoints()

            self.pointsSpinner:SetValueMinAndMax(currentPendingPoints, min, max)
        else
            local totalPointsInCluster = self.star:GetChampionClusterData():CalculateTotalPendingPoints()
            self.pointsSpinner:SetValueMinAndMax(totalPointsInCluster, totalPointsInCluster, totalPointsInCluster)
        end
    end
end

function ZO_ChampionStarEditor:IsEnabled()
    return self.pointsSpinner:IsEnabled()
end

function ZO_ChampionStarEditor:RefreshEnabledState()
    if self:IsAttached() then
        local result = GetChampionPurchaseAvailability()
        self.pointsSpinner:SetEnabled(result == CHAMPION_PURCHASE_SUCCESS)
    end
end

do
    local function SetButtonTextures(btn, textures)
        if textures.KEY_CODE then
            btn:SetKeyCode(textures.KEY_CODE)
        else
            btn:SetKeyCode(nil)
            btn:SetNormalTexture(textures.NORMAL)
            btn:SetPressedTexture(textures.PRESSED)
            btn:SetMouseOverTexture(textures.MOUSEOVER)
            btn:SetDisabledTexture(textures.DISABLED)
        end
    end

    function ZO_ChampionStarEditor:ApplyButtonTemplatesToSpinner(template)
        local decreaseBtn = self.pointsSpinner.decreaseButton
        local increaseBtn = self.pointsSpinner.increaseButton
        
        decreaseBtn:SetDimensions(template.SIZE, template.SIZE)
        increaseBtn:SetDimensions(template.SIZE, template.SIZE)
        SetButtonTextures(decreaseBtn, template.DECREASE)
        SetButtonTextures(increaseBtn, template.INCREASE)
    end
end

function ZO_ChampionStarEditor:OnMouseWheel(delta)
    if not IsInGamepadPreferredMode() then
        self.pointsSpinner:OnMouseWheel(delta)
    end
end

function ZO_ChampionStar:PlayPurchaseConfirmAnimation()
    local STAR_ONE_SHOT_ANIMATION_SIZE = 30
    local confirmedTexture = CHAMPION_PERKS:AcquireStarConfirmedTexture()
    self.sceneNode:AddTexture(confirmedTexture, self.x, self.y, self.depth)
    confirmedTexture:SetDimensions(self.sceneNode:ComputeSizeForDepth(STAR_ONE_SHOT_ANIMATION_SIZE, STAR_ONE_SHOT_ANIMATION_SIZE, self.depth, ZO_CHAMPION_REFERENCE_CAMERA_Z))
    confirmedTexture.timeline:SetHandler("OnStop", function()
        self.sceneNode:RemoveTexture(confirmedTexture)
        CHAMPION_PERKS:ReleaseStarConfirmedTexture(confirmedTexture)
    end)
    confirmedTexture.timeline:PlayFromStart()
end

--Global XML Handlers

function ZO_ChampionStar_OnMouseEnter(control)
    if not IsInGamepadPreferredMode() then
        control.star:OnMouseEnter()
    end
end

function ZO_ChampionStar_OnMouseExit(control)
    if not control.star or IsInGamepadPreferredMode() then
        -- Protection against the case where a player hides a constellation
        -- while moused over it: by the time we call the mouse exit handler, the
        -- control has already been released to the pool, so we'll call it in advance
        return
    end
    control.star:OnMouseExit()
end

function ZO_ChampionStar_OnMouseWheel(control, delta)
    if not IsInGamepadPreferredMode() then
        control.star:OnMouseWheel(delta)
    end
end

function ZO_ChampionStar_OnMouseUp(control, button, upInside)
    if not control.star or IsInGamepadPreferredMode() or control.star:OnClicked(button, upInside) == HANDLED then
        return
    end
    CHAMPION_PERKS:OnCanvasMouseUp(button)
end

function ZO_ChampionStar_OnDragStart(control, button)
    if control.star and not IsInGamepadPreferredMode() and button == MOUSE_BUTTON_INDEX_LEFT and GetCursorContentType() == MOUSE_CONTENT_EMPTY then
        control.star:OnDragStart()
    end
end
