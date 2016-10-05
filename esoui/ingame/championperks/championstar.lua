--Star
----------------------

ZO_ChampionStar = ZO_Object:Subclass()

function ZO_ChampionStar:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

local STAR_TEXTURE_ANIMATION_CELLS_WIDE = 8
local STAR_TEXTURE_ANIMATION_CELLS_HIGH = 8
local STAR_TEXTURE_ANIMATION_BASE_DURATION = 800
local STAR_TEXTURE_ANIMATION_VARIABLE_DURATION = 400

local STAR_ALPHA_SELECTED = 1
local STAR_ALPHA_UNSELECTED = 1
local STAR_ALPHA_DISABLED = 0
local STAR_TEXT_COLOR_SELECTED = ZO_ColorDef:New(1, 1, 1)
local STAR_TEXT_COLOR_UNSELECTED_KEYBOARD = ZO_NORMAL_TEXT
local STAR_TEXT_COLOR_UNSELECTED_GAMEPAD = ZO_DISABLED_TEXT
local STAR_SPINNER_ALPHA_SELECTED = 1
local STAR_SPINNER_ALPHA_UNSELECTED = 0.5

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
        NORMAL = "EsoUI/Art/Buttons/Gamepad/gp_minus.dds",
        PRESSED = "EsoUI/Art/Buttons/Gamepad/gp_minus.dds",
        MOUSEOVER = "EsoUI/Art/Buttons/Gamepad/gp_minus.dds",
        DISABLED = "EsoUI/Art/Buttons/Gamepad/gp_minus_dim.dds",
    },
    INCREASE = {
        NORMAL = "EsoUI/Art/Buttons/Gamepad/gp_plus.dds",
        PRESSED = "EsoUI/Art/Buttons/Gamepad/gp_plus.dds",
        MOUSEOVER = "EsoUI/Art/Buttons/Gamepad/gp_plus.dds",
        DISABLED = "EsoUI/Art/Buttons/Gamepad/gp_plus_dim.dds",
    },
}

local GAMEPAD_TRIGGER_ALLOCATE_POINTS_BUTTON_TEMPLATES = 
{
    SIZE = 55,
    DECREASE = {
        NORMAL = GetGamepadIconPathForKeyCode(KEY_GAMEPAD_LEFT_TRIGGER),
        PRESSED = GetGamepadIconPathForKeyCode(KEY_GAMEPAD_LEFT_TRIGGER),
        MOUSEOVER = GetGamepadIconPathForKeyCode(KEY_GAMEPAD_LEFT_TRIGGER),
        DISABLED = ZO_GAMEPAD_LEFT_TRIGGER_DISABLED,
    },
    INCREASE = {
        NORMAL = GetGamepadIconPathForKeyCode(KEY_GAMEPAD_RIGHT_TRIGGER),
        PRESSED = GetGamepadIconPathForKeyCode(KEY_GAMEPAD_RIGHT_TRIGGER),
        MOUSEOVER = GetGamepadIconPathForKeyCode(KEY_GAMEPAD_RIGHT_TRIGGER),
        DISABLED = ZO_GAMEPAD_RIGHT_TRIGGER_DISABLED,
    },
}

function ZO_ChampionStar:Initialize(constellation, texture, sceneNode, skillIndex, constellationWidth, constellationHeight, starDepth)
    self.constellation = constellation
    self.texture = texture
    self.sceneNode = sceneNode
    self.skillIndex = skillIndex
    self.disciplineIndex = constellation:GetDisciplineIndex()
    texture.star = self
    self.enabled = false
    self.onValueChangedCallback = function() self:OnValueChanged() end
    self.onValueChangedEnabled = true
    self.depth = starDepth
    self.state = nil
    self.stateLocked = false

    self.nx, self.ny = GetChampionSkillPosition(self.disciplineIndex, self.skillIndex)
    self.x = (self.nx - 0.5) * constellationWidth
    self.y = (self.ny - 1) * constellationHeight
    sceneNode:AddControl(texture, self.x, self.y, starDepth)
    sceneNode:SetControlUseRotation(texture, false)

    self.pulseTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_StarPulseAnimation", texture)

    self.name = GetChampionSkillName(self.disciplineIndex, self.skillIndex)
    self.unlockLevel = GetChampionSkillUnlockLevel(self.disciplineIndex, self.skillIndex)
    
    self.textControlAlphaInterpolator = ZO_LerpInterpolator:New(STAR_ALPHA_DISABLED)
    self.textControlSelectedInterpolator = ZO_LerpInterpolator:New(0)
    self.starScaleInterpolator = ZO_LerpInterpolator:New(1)

    self.oneShotAnimationOnReleaseCallback = function(texture)
        local currentAnimInfo = self.oneShotAnimationInfo

        self.oneShotAnimationTimeline = nil
        self.oneShotAnimationInfo = nil
        
        if currentAnimInfo.onComplete then
            currentAnimInfo.onComplete(self)
        end

        self.sceneNode:RemoveControl(texture)
    end

    self:RefreshState()
end

function ZO_ChampionStar:GetNormalizedCoordinates()
    return self.nx, self.ny
end

function ZO_ChampionStar:ResetPendingPoints()
    if self:CanSpendPoints() then
        local pendingPoints = 0
        if CHAMPION_PERKS:IsInRespecMode() then
            pendingPoints = self:CanSpendPoints() and self:GetNumCommittedSpentPoints() or 0
        end
        self:SetNumPendingPoints(pendingPoints)
    end
end

function ZO_ChampionStar:SetPendingPointsToZero()
    if self:CanSpendPoints() then
        self:SetNumPendingPoints(0)
    end
end

function ZO_ChampionStar:InitializePointSpending()
    if self:CanSpendPoints() then
        self:RefreshPointsMinMax()
    end
end

function ZO_ChampionStar:RefreshPointsMinMax()
    if self:CanSpendPoints() then
        self.spentPoints = self:GetNumSpentPoints()
        if self.textControl then
            local attributeType = self.constellation:GetAttributeType()
            local numAvailablePoints = CHAMPION_PERKS:GetNumAvailablePoints(attributeType)
            local maxPossiblePointsInSkill = GetMaxPossiblePointsInChampionSkill()

            --there is a limit to the number of points that can be spent across all perks in an attribute type
            local numAvailablePointsUntilMaxSpendableCap = CHAMPION_PERKS:GetNumAvailablePointsUntilMaxSpendableCap(attributeType)
            --include the number of points that we have pending or spent in the amount we can spend of the cap
            if CHAMPION_PERKS:IsInRespecMode() then
                numAvailablePointsUntilMaxSpendableCap = numAvailablePointsUntilMaxSpendableCap + self:GetNumPendingPoints()
            else
                numAvailablePointsUntilMaxSpendableCap = numAvailablePointsUntilMaxSpendableCap + self:GetNumPendingPoints() + self.spentPoints
            end

            local maxPossiblePoints = zo_min(maxPossiblePointsInSkill, numAvailablePointsUntilMaxSpendableCap)

            self.onValueChangedEnabled = false
            if CHAMPION_PERKS:IsInRespecMode() then
                self.pointsSpinner:SetMinMax(0, zo_min(numAvailablePoints + self:GetNumPendingPoints(), maxPossiblePoints))
                self.pointsSpinner:SetValue(self:GetNumPendingPoints() + self.pointsSpinner:GetMin())
            else
                self.pointsSpinner:SetMinMax(self.spentPoints, zo_min(self.spentPoints + numAvailablePoints + self:GetNumPendingPoints(), maxPossiblePoints))
                self.pointsSpinner:SetValue(self:GetNumPendingPoints() + self.pointsSpinner:GetMin())
            end
            self.onValueChangedEnabled = true

            if self.pointsSpinner:GetValue() - self.pointsSpinner:GetMin() ~= currentPendingPoints then
                self:OnValueChanged()
            end
        end
    end
end

function ZO_ChampionStar:HasUnsavedChanges()
    if self:CanSpendPoints() then
        if CHAMPION_PERKS:IsInRespecMode() then
            -- All points are considered pending while respeccing
            return self:GetNumPendingPoints() ~= self:GetNumCommittedSpentPoints()
        else
            return self:GetNumPendingPoints() > 0
        end
    end
    return false
end

function ZO_ChampionStar:OnValueChanged()
    if self.onValueChangedEnabled then
        self:SetNumPendingPoints(self.pointsSpinner:GetValue() - self.pointsSpinner:GetMin())
        self:RefreshState()
        self.constellation:OnStarPendingPointsChanged(self)
    end
end

function ZO_ChampionStar:SpendPoints(points)
    if self:CanSpendPoints() then
        self.pointsSpinner:ModifyValue(points)
    end
end

function ZO_ChampionStar:RemovePoints(points)
    if self:CanSpendPoints() then
        self.pointsSpinner:ModifyValue(-points)
    end
end

function ZO_ChampionStar:GetTexture()
    return self.texture
end

function ZO_ChampionStar:SetNumPendingPoints(numPoints)
    if numPoints ~= self:GetNumPendingPoints() then
        SetNumPendingChampionPoints(self.disciplineIndex, self.skillIndex, numPoints)
        CHAMPION_PERKS:MarkDirty()
    end
end

function ZO_ChampionStar:GetNumPendingPoints()
    return GetNumPendingChampionPoints(self.disciplineIndex, self.skillIndex)
end

function ZO_ChampionStar:GetNumSpentPoints()
    if CHAMPION_PERKS:IsInRespecMode() then
        return 0
    else
        return self:GetNumCommittedSpentPoints()
    end
end

function ZO_ChampionStar:GetNumCommittedSpentPoints()
    return GetNumPointsSpentOnChampionSkill(self.disciplineIndex, self.skillIndex)
end

function ZO_ChampionStar:GetNumPointsThatWillBeSpent()
    return self:GetNumSpentPoints() + self:GetNumPendingPoints()
end

function ZO_ChampionStar:CanSpendPoints()
    return self.unlockLevel == nil
end

function ZO_ChampionStar:IsPurchased()
    if self:CanSpendPoints() then
        return self:GetNumSpentPoints() > 0
    else
        return self.constellation:GetNumSpentPoints() >= self.unlockLevel
    end
end

function ZO_ChampionStar:WouldBePurchased()
    if self:CanSpendPoints() then
        return self:GetNumPendingPoints() > 0
    else
        return self.constellation:GetNumSpentPoints() < self.unlockLevel and self.constellation:GetNumPointsThatWillBeSpent() >= self.unlockLevel
    end
end

local ATTRIBUTE_COLORS =
{
    [ATTRIBUTE_HEALTH] = ZO_ColorDef:New(1, 1, 0),
    [ATTRIBUTE_MAGICKA] = ZO_ColorDef:New(0.7, 0.7, 1),
    [ATTRIBUTE_STAMINA] = ZO_ColorDef:New(0.5, 1, 0),
}

local STATE_UNLOCKED = "unlocked"
local STATE_LOCKED = "locked"
local STATE_UNLOCK_PENDING = "unlock_pending"
local STATE_AVAILABLE = "available"

function ZO_ChampionStar:SetStateLocked(locked)
    if locked ~= self.stateLocked then
        self.stateLocked = locked
        if not locked then
            self:RefreshState()
        end
    end
end

function ZO_ChampionStar:RefreshState()
    if not self.stateLocked then
        local attributeType = self.constellation:GetAttributeType()
        local numSpendablePoints = CHAMPION_PERKS:GetNumAvailablePointsThatCanBeSpent(attributeType)

        local oldState = self.state
        if self:WouldBePurchased() then
            self.state = STATE_UNLOCK_PENDING
        elseif numSpendablePoints > 0 and self:CanSpendPoints() then
            self.state = STATE_AVAILABLE
        elseif self:IsPurchased() and (not self:CanSpendPoints() or numSpendablePoints == 0) then
            self.state = STATE_UNLOCKED
        else
            self.state = STATE_LOCKED
        end

        if oldState ~= self.state then
            self:RefreshTexture()
            if self.state == STATE_UNLOCK_PENDING and oldState == STATE_LOCKED then
                PlaySound(SOUNDS.CHAMPION_STAR_UNLOCKED)
                self:PlayOneShotAnimation(ZO_CHAMPION_ONE_SHOT_ANIMATION_UNLOCKED_PENDING)
            elseif self.state == STATE_LOCKED and oldState == STATE_UNLOCK_PENDING then
                PlaySound(SOUNDS.CHAMPION_STAR_LOCKED)
                self:PlayOneShotAnimation(ZO_CHAMPION_ONE_SHOT_ANIMATION_LOCKED_PENDING)
            end
        end
    end
end

local STAR_SIZE_ACTIVATED = 32
local STAR_SIZE_LOCKED = 16
local STAR_SIZE_AVAILABLE = 16
local STAR_SIZE_PENDING_POINTS = 26

local STAR_TEXTURE_INFO = {
    [STATE_UNLOCKED] = {
        texture = "EsoUI/Art/Champion/champion_star_activated.dds",
        size = STAR_SIZE_ACTIVATED,
        animationCellsSize = 8,
    },
    [STATE_LOCKED] = {
        texture = "EsoUI/Art/Champion/champion_star_locked.dds",
        size = STAR_SIZE_LOCKED,
        animationCellsSize = 8,
    },
    [STATE_UNLOCK_PENDING] = {
        texture = "EsoUI/Art/Champion/champion_star_pendingPoints.dds",
        size = STAR_SIZE_PENDING_POINTS,
        animationCellsSize = 4,
    },
    [STATE_AVAILABLE] = {
        texture = "EsoUI/Art/Champion/champion_star_available.dds",
        size = STAR_SIZE_AVAILABLE,
        animationCellsSize = 8,
    },
}

function ZO_ChampionStar:RefreshTexture()
    local attributeType = self.constellation:GetAttributeType()

    local textureInfo = STAR_TEXTURE_INFO[self.state or STATE_LOCKED]
    self.texture:SetTexture(textureInfo.texture)

    local size = textureInfo.size
    local animationCellsSize = textureInfo.animationCellsSize

    self.pulseTimeline:Stop()
    self.texture:SetDimensions(self.sceneNode:ComputeSizeForDepth(size, size, self.depth, ZO_CHAMPION_REFERENCE_CAMERA_Z))
    self.texture:SetTextureCoords(0, 1 / animationCellsSize, 0, 1 / animationCellsSize)
    local textureAnimation = self.pulseTimeline:GetFirstAnimation()
    textureAnimation:SetImageData(animationCellsSize, animationCellsSize)
    textureAnimation:SetDuration(STAR_TEXTURE_ANIMATION_BASE_DURATION + math.random(STAR_TEXTURE_ANIMATION_VARIABLE_DURATION))
    self.pulseTimeline:PlayForward()

    if self:CanSpendPoints() then
        self.texture:SetColor(1, 1, 1, self.texture:GetAlpha())
    else
        local r, g, b = ATTRIBUTE_COLORS[attributeType]:UnpackRGB()
        local a = self.texture:GetAlpha()
        self.texture:SetColor(r, g, b, a)
    end
end

local STAR_SCALE_UNSELECTED = 1
local STAR_SCALE_SELECTED = 1.7

function ZO_ChampionStar:GetStarTextColorUnselected()
    if IsInGamepadPreferredMode() then
        return STAR_TEXT_COLOR_UNSELECTED_GAMEPAD
    else
        return STAR_TEXT_COLOR_UNSELECTED_KEYBOARD
    end
end

function ZO_ChampionStar:UpdateVisuals(timeSecs, frameDeltaSecs)
    local isSelected = self == self.constellation:GetSelectedStar()

    if isSelected then
        self.starScaleInterpolator:SetTargetBase(STAR_SCALE_SELECTED)
    else
        self.starScaleInterpolator:SetTargetBase(STAR_SCALE_UNSELECTED)
    end
    local starScale = self.starScaleInterpolator:Update(timeSecs, frameDeltaSecs)
    self.sceneNode:SetControlScale(self.texture, starScale)

    if self.textControl then
        if self.enabled then
            if isSelected then
                self.textControlAlphaInterpolator:SetTargetBase(STAR_ALPHA_SELECTED)
                self.textControlSelectedInterpolator:SetTargetBase(1)
            else
                self.textControlAlphaInterpolator:SetTargetBase(STAR_ALPHA_UNSELECTED)
                self.textControlSelectedInterpolator:SetTargetBase(0)
            end
        else
            self.textControlAlphaInterpolator:SetTargetBase(STAR_ALPHA_DISABLED)
            self.textControlSelectedInterpolator:SetTargetBase(0)
        end

        local textControlAlpha = self.textControlAlphaInterpolator:Update(timeSecs, frameDeltaSecs)
        self.textControl:SetAlpha(textControlAlpha)
        local textControlSelectedPercent = self.textControlSelectedInterpolator:Update(timeSecs, frameDeltaSecs)

        local starTextColorUnselected = self:GetStarTextColorUnselected()
        local r = zo_lerp(starTextColorUnselected.r, STAR_TEXT_COLOR_SELECTED.r, textControlSelectedPercent)
        local g = zo_lerp(starTextColorUnselected.g, STAR_TEXT_COLOR_SELECTED.g, textControlSelectedPercent)
        local b = zo_lerp(starTextColorUnselected.b, STAR_TEXT_COLOR_SELECTED.b, textControlSelectedPercent)
        self.nameLabel:SetColor(r, g, b)

        if self:CanSpendPoints() then
            local alpha
            --don't show the spinner +/- if we have no points to spend in this constellation
            if not self:ArePointsAvailableToSpend() then
                alpha = 0
            else
                alpha = zo_lerp(STAR_SPINNER_ALPHA_UNSELECTED, STAR_SPINNER_ALPHA_SELECTED, textControlSelectedPercent)
            end

            local pointsSpinnerControl = self.pointsSpinner:GetControl()
            pointsSpinnerControl:GetNamedChild("Increase"):SetAlpha(alpha)
            pointsSpinnerControl:GetNamedChild("Decrease"):SetAlpha(alpha)
        end

        --If the name is faded out entirely and the star is disabled we can release the label to the pool
        if textControlAlpha == STAR_ALPHA_DISABLED and not self.enabled then
            self:ReleaseTextControl()
        end
    end
end

function ZO_ChampionStar:ArePointsAvailableToSpend()
    local attributeType = self.constellation:GetAttributeType()
    if CHAMPION_PERKS:IsInRespecMode() then
        return CHAMPION_PERKS:HasAnyUnspentPoints(attributeType) or CHAMPION_PERKS:HasAnyCommittedSpentPoints(attributeType)
    else
        return CHAMPION_PERKS:HasAnyUnspentPoints(attributeType) and CHAMPION_PERKS:GetNumCommittedSpentPoints(attributeType) < GetMaxSpendableChampionPointsInAttribute(attributeType)
    end
end

function ZO_ChampionStar:ReleaseTextControl()
    self.textControl:SetAlpha(0)
    local textControlPool = CHAMPION_PERKS:GetStarTextControlPool()
    self.textControl.star = nil
    self.nameLabel = nil
    if self.pointsSpinner then
        self.pointsSpinner:UnregisterCallback("OnValueChanged", self.onValueChangedCallback)
        self.pointsSpinner = nil
    end
    textControlPool:ReleaseObject(self.textControlKey)
    self.textControlKey = nil
    self.textControl = nil
end

function ZO_ChampionStar:ResetTextControl()
    self.textControl:SetAlpha(STAR_ALPHA_DISABLED)
    self.textControlAlphaInterpolator:SetCurrentValue(STAR_ALPHA_DISABLED)
    self.textControlAlphaInterpolator:SetTargetBase(STAR_ALPHA_UNSELECTED)

    local starTextColorUnselected = self:GetStarTextColorUnselected()
    self.nameLabel:SetColor(starTextColorUnselected:UnpackRGB())
    if self:CanSpendPoints() then
        local pointsSpinnerControl = self.pointsSpinner:GetControl()
        pointsSpinnerControl:GetNamedChild("Increase"):SetAlpha(STAR_SPINNER_ALPHA_UNSELECTED)
        pointsSpinnerControl:GetNamedChild("Decrease"):SetAlpha(STAR_SPINNER_ALPHA_UNSELECTED)
    end
    self.textControlSelectedInterpolator:SetCurrentValue(0)
    self.textControlSelectedInterpolator:SetTargetBase(0)

    self:RefreshText()
end

function ZO_ChampionStar:SetEnabled(enabled, instantly)
    local textControlPool = CHAMPION_PERKS:GetStarTextControlPool()
    local mouseEnabled = enabled and not IsInGamepadPreferredMode()
    self.texture:SetMouseEnabled(mouseEnabled)
    
    if self.enabled ~= enabled then
        self.enabled = enabled
        if enabled then
            if not self.textControl then
                local textControl, textControlKey = textControlPool:AcquireObject()
                --The name offset is done in the text control container itself for mouse behavior reasons
                textControl:SetAnchor(TOP, self.texture, CENTER, 0, -60)
                self.textControl = textControl
                textControl.star = self
                self:ApplyButtonTemplatesToTextControl(IsInGamepadPreferredMode() and GAMEPAD_ALLOCATE_POINTS_BUTTON_TEMPLATES or KEYBOARD_ALLOCATE_POINTS_BUTTON_TEMPLATES)
                self.textControlKey = textControlKey
                self.nameLabel = self.textControl.nameLabel
                if self:CanSpendPoints() then
                    self.pointsSpinner = self.textControl.pointsSpinner
                    self.pointsSpinner:RegisterCallback("OnValueChanged", self.onValueChangedCallback)
                    self:InitializePointSpending()
                    self.pointsSpinner:GetControl():SetHidden(false)
                else
                    self.textControl.pointsSpinner.control:SetHidden(true)
                end
            end
            self:ResetTextControl()
        end

        if self.textControl then
            self.textControl:SetMouseEnabled(mouseEnabled)
            if self:CanSpendPoints() then
                self.pointsSpinner:SetMouseEnabled(mouseEnabled)
            end

            --We don't release the label until it's entirely faded out unless instantly is true. Otherwise we disable it and let it fade out.
            if not enabled and instantly then
                self:ReleaseTextControl()
            end
        end
    end
end

function ZO_ChampionStar:RefreshText()
    if self.textControl then
        self.nameLabel:SetText(zo_strformat(SI_CHAMPION_STAR_NAME, self.name))
    end
end

function ZO_ChampionStar:CanAddPoints()
    if self:CanSpendPoints() then
        return self.pointsSpinner:GetValue() < self.pointsSpinner:GetMax()
    else
        return false
    end
end

function ZO_ChampionStar:StartAddingPoints()
    self.pointsSpinner:OnButtonDown(1)
end

function ZO_ChampionStar:StopChangingPoints()
    if self.pointsSpinner then
        self.pointsSpinner:OnButtonUp()
    end
end

function ZO_ChampionStar:CanRemovePoints()
    if self:CanSpendPoints() then
        return self.pointsSpinner:GetValue() > self.pointsSpinner:GetMin()
    else
        return false
    end
end

function ZO_ChampionStar:StartRemovingPoints()
    self.pointsSpinner:OnButtonDown(-1)
end

function ZO_ChampionStar:GetConstellation()
    return self.constellation
end

local function SetButtonTextures(btn, textures)
    btn:SetNormalTexture(textures.NORMAL)
    btn:SetPressedTexture(textures.PRESSED)
    btn:SetMouseOverTexture(textures.MOUSEOVER)
    btn:SetDisabledTexture(textures.DISABLED)
end

function ZO_ChampionStar:ApplyButtonTemplatesToTextControl(template)
    if self.textControl then
        local pointsSpinner = self.textControl.pointsSpinner
        local decreaseBtn = pointsSpinner.decreaseButton
        local increaseBtn = pointsSpinner.increaseButton
        
        decreaseBtn:SetDimensions(template.SIZE, template.SIZE)
        increaseBtn:SetDimensions(template.SIZE, template.SIZE)
        SetButtonTextures(decreaseBtn, template.DECREASE)
        SetButtonTextures(increaseBtn, template.INCREASE)
    end
end

function ZO_ChampionStar:ApplyGamepadButtonTemplatesToTextControl()
    self:ApplyButtonTemplatesToTextControl(GAMEPAD_ALLOCATE_POINTS_BUTTON_TEMPLATES)
end

function ZO_ChampionStar:ApplyGamepadTriggerButtonTemplatesToTextControl()
    self:ApplyButtonTemplatesToTextControl(GAMEPAD_TRIGGER_ALLOCATE_POINTS_BUTTON_TEMPLATES)
end

--Animation

local STAR_ONE_SHOT_ANIMATION_SIZE = 60

function ZO_ChampionStar:PlayOneShotAnimation(animationInfo)
    if self.oneShotAnimationTimeline ~= nil then
        self.oneShotAnimationTimeline:Stop()
    end

    local timeline, texture = CHAMPION_PERKS:AcquireOneShotAnimation(animationInfo, self.oneShotAnimationOnReleaseCallback)
    self.sceneNode:AddControl(texture, self.x, self.y, self.depth)
    texture:SetDimensions(self.sceneNode:ComputeSizeForDepth(STAR_ONE_SHOT_ANIMATION_SIZE, STAR_ONE_SHOT_ANIMATION_SIZE, self.depth + 0.01, ZO_CHAMPION_REFERENCE_CAMERA_Z))
    self.oneShotAnimationTimeline = timeline
    self.oneShotAnimationInfo = animationInfo
    if animationInfo.reverse then
        timeline:PlayFromEnd()
    else
        timeline:PlayFromStart()
    end
end

--Local XML Handlers

function ZO_ChampionStar:OnMouseUp(control, button, upInside)
    if upInside and self:CanSpendPoints() and CHAMPION_PERKS:HasAnySpendableUnspentPoints(self.constellation:GetAttributeType()) then
        if button == MOUSE_BUTTON_INDEX_LEFT then
            self:SpendPoints(1)
        elseif button == MOUSE_BUTTON_INDEX_RIGHT then
            self:RemovePoints(1)
        end
    else
        if button == MOUSE_BUTTON_INDEX_RIGHT then
            CHAMPION_PERKS:ZoomOut()
        end
    end
end

function ZO_ChampionStar:OnMouseEnter(control)
    self.constellation:SelectStar(self)
end

function ZO_ChampionStar:OnMouseExit(control)
    self.constellation:SelectStar(nil)
end

function ZO_ChampionStar:OnMouseWheel(control, delta)
    if self.pointsSpinner then
        self.pointsSpinner:OnMouseWheel(delta)
    end
end

--Global XML Handlers

function ZO_ConstellationStarComponent_OnMouseEnter(self)
    if self.star then
        self.star:OnMouseEnter(self)
    end
end

function ZO_ConstellationStarComponent_OnMouseExit(self)
    if self.star then
        self.star:OnMouseExit(self)
    end
end

function ZO_ConstellationStarComponent_OnMouseUp(self, button, upInside)
    if self.star then
        self.star:OnMouseUp(self, button, upInside)
    end
end

function ZO_ConstellationStarComponent_OnMouseWheel(self, delta)
    if self.star then
        self.star:OnMouseWheel(self, delta)
    end
end
