--Pointer Box
-------------------

ZO_POINTER_BOX_ARROW_SIZE = 64
ZO_POINTER_BOX_ARROW_CENTER_TO_TIP_DISTANCE = 15
ZO_POINTER_BOX_ARROW_CENTER_OFFSET_FROM_BOX_SIDE = 2
ZO_POINTER_BOX_TRANSLATE_DISTANCE = 60
ZO_POINTER_BOX_ANIMATION_DURATION_MS = 350
ZO_POINTER_BOX_DEFAULT_PADDING = 20

ZO_PointerBox_Keyboard = ZO_Object:Subclass()

function ZO_PointerBox_Keyboard:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_PointerBox_Keyboard:Initialize(control)
    self.control = control
    self.showAnimationTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_PointerBox_KeyboardShow", self.control)
    self.showAnimationTimeline:SetHandler("OnStop", function(timeline, completedPlaying)
        if completedPlaying and timeline:IsPlayingBackward() then
            self.control:SetHidden(true)
            self.contentsControl:SetHidden(true)

            if self.onHiddenCallback then
                self:onHiddenCallback()
            end

            if self.releaseOnHidden then
                self:Release()
            end
        end
    end)
    
    control:SetHandler("OnMouseUp", function(control, button, upInside)
        if upInside and self.closeable then
            local ANIMATE = false
            self:Hide(ANIMATE)
        end
    end)
    self:Reset()
end

function ZO_PointerBox_Keyboard:GetPoolKey()
    return self.poolKey
end

function ZO_PointerBox_Keyboard:SetPoolKey(poolKey)
    self.poolKey = poolKey
end

-- Hiding can release the object (resetting it), so we should never rely on Reset to hide the object
function ZO_PointerBox_Keyboard:Reset()
    self.poolKey = nil
    self.padding = ZO_POINTER_BOX_DEFAULT_PADDING
    self.closeable = true
    self.contentsControl = nil
    self.releaseOnHidden = false
    self.onHiddenCallback = nil
    if self.hideWithFragment then
        self.hideWithFragment:UnregisterCallback("StateChange", self.hideWithFragmentFunction)
        self.hideWithFragment = nil
        self.hideWithFragmentFunction = nil
    end
    self:ClearAnchors()
end

function ZO_PointerBox_Keyboard:SetCloseable(closeable)
    self.closeable = closeable
end

function ZO_PointerBox_Keyboard:SetContentsControl(contentsControl)
    self.contentsControl = contentsControl
    self.contentsControl:SetParent(self.control)
    local translateAnimation = self.showAnimationTimeline:GetAnimation(2)
    translateAnimation:SetAnimatedControl(contentsControl)
end

function ZO_PointerBox_Keyboard:SetParent(parent)
    self.control:SetParent(parent)
end

function ZO_PointerBox_Keyboard:SetHideWithFragment(fragment)
    local function OnFragmentStateChange(oldState, newState)
        if newState == SCENE_FRAGMENT_HIDING then
            self:Hide()
        end
    end
    fragment:RegisterCallback("StateChange", OnFragmentStateChange)

    self.hideWithFragment = fragment
    self.hideWithFragmentFunction = OnFragmentStateChange
end

function ZO_PointerBox_Keyboard:SetPadding(padding)
    self.padding = padding
end

--Anchored from the arrow tip
function ZO_PointerBox_Keyboard:SetAnchor(point, relativeTo, relativePoint, offsetX, offsetY)
    self.point = point
    self.relativeTo = relativeTo
    self.relativePoint = relativePoint
    self.offsetX = offsetX
    self.offsetY = offsetY
end

function ZO_PointerBox_Keyboard:ClearAnchors()
    self.point = nil
    self.relativeTo = nil
    self.relativePoint = nil
    self.offsetX = nil
    self.offsetY = nil
end

function ZO_PointerBox_Keyboard:SetReleaseOnHidden(releaseOnHidden)
    self.releaseOnHidden = releaseOnHidden
end

function ZO_PointerBox_Keyboard:SetOnHiddenCallback(callback)
    self.onHiddenCallback = callback
end

function ZO_PointerBox_Keyboard:Commit()
    self:RefreshLayout()
    self:RefreshArrow()
end

function ZO_PointerBox_Keyboard:RefreshLayout()
    if self.contentsControl then
        self.control:ClearAnchors()
        self.control:SetAnchor(TOPLEFT, self.contentsControl, TOPLEFT, -self.padding, -self.padding)
        self.control:SetAnchor(BOTTOMRIGHT, self.contentsControl, BOTTOMRIGHT, self.padding, self.padding)
    end
end

function ZO_PointerBox_Keyboard:RefreshArrow()
    if self.point then
        local arrowTexture = self.control:GetNamedChild("Arrow")
        arrowTexture:ClearAnchors()

        if self.point == LEFT then
            arrowTexture:SetAnchor(CENTER, nil, LEFT, -ZO_POINTER_BOX_ARROW_CENTER_OFFSET_FROM_BOX_SIDE, 0)
            arrowTexture:SetTextureCoordsRotation(0)
        elseif self.point == RIGHT then
            arrowTexture:SetAnchor(CENTER, nil, RIGHT, ZO_POINTER_BOX_ARROW_CENTER_OFFSET_FROM_BOX_SIDE, 0)
            arrowTexture:SetTextureCoordsRotation(math.pi)
        elseif self.point == TOP then
            arrowTexture:SetAnchor(CENTER, nil, TOP, 0, -ZO_POINTER_BOX_ARROW_CENTER_OFFSET_FROM_BOX_SIDE)
            arrowTexture:SetTextureCoordsRotation(1.5 * math.pi)
        else
            arrowTexture:SetAnchor(CENTER, nil, BOTTOM, 0, ZO_POINTER_BOX_ARROW_CENTER_OFFSET_FROM_BOX_SIDE)
            arrowTexture:SetTextureCoordsRotation(0.5 * math.pi)
        end
    end
end

function ZO_PointerBox_Keyboard:RefreshAnchor()
    if self.contentsControl and self.point then
        self.contentsControl:ClearAnchors()
        if self.point == LEFT or self.point == RIGHT then
            local boxCenterY = self.control:GetHeight() * 0.5
            local contentsCenterY = self.contentsControl:GetHeight() * 0.5 + self.padding
            --The arrow is anchored to the box, but we anchor the contents control. This is the difference between the Y centers of the two to compensate for that
            local offsetY = contentsCenterY - boxCenterY

            if self.point == LEFT then
                --Assumes that relative point is one of the right side anchors
                self.contentsControl:SetAnchor(LEFT, self.relativeTo, self.relativePoint, self.offsetX + ZO_POINTER_BOX_ARROW_CENTER_TO_TIP_DISTANCE + ZO_POINTER_BOX_ARROW_CENTER_OFFSET_FROM_BOX_SIDE + self.padding, offsetY + self.offsetY)
            else
                 --Assumes that relative point is one of the left side anchors
                self.contentsControl:SetAnchor(RIGHT, self.relativeTo, self.relativePoint, self.offsetX - (ZO_POINTER_BOX_ARROW_CENTER_TO_TIP_DISTANCE + ZO_POINTER_BOX_ARROW_CENTER_OFFSET_FROM_BOX_SIDE + self.padding), offsetY + self.offsetY)
            end
        elseif self.point == TOP or self.point == BOTTOM then
            local boxCenterX = self.control:GetWidth() * 0.5
            local contentsCenterX = self.contentsControl:GetWidth() * 0.5 + self.padding
            --The arrow is anchored to the box, but we anchor the contents control. This is the difference between the X centers of the two to compensate for that
            local offsetX = contentsCenterX - boxCenterX

            if self.point == TOP then
               --Assumes that relative point is one of the bottom side anchors
                self.contentsControl:SetAnchor(TOP, self.relativeTo, self.relativePoint, offsetX + self.offsetX, self.offsetY + ZO_POINTER_BOX_ARROW_CENTER_TO_TIP_DISTANCE + ZO_POINTER_BOX_ARROW_CENTER_OFFSET_FROM_BOX_SIDE + self.padding)
            else
                --Assumes that relative point is one of the top side anchors
                self.contentsControl:SetAnchor(BOTTOM, self.relativeTo, self.relativePoint, offsetX + self.offsetX, self.offsetY - (ZO_POINTER_BOX_ARROW_CENTER_TO_TIP_DISTANCE + ZO_POINTER_BOX_ARROW_CENTER_OFFSET_FROM_BOX_SIDE + self.padding))
            end
        end
    end
end

function ZO_PointerBox_Keyboard:Show(skipAnimation)
    if self.contentsControl then
        if self.contentsControl:IsHidden() == true then
            self.control:SetHidden(false)
            self.contentsControl:SetHidden(false)

            --Reset the anchor to the starting position on show
            self:RefreshAnchor()

            local translateAnimation = self.showAnimationTimeline:GetAnimation(2)
            local offsetX = 0
            local offsetY = 0
            if self.point == LEFT then
                offsetX = -ZO_POINTER_BOX_TRANSLATE_DISTANCE
            elseif self.point == RIGHT then
                offsetX = ZO_POINTER_BOX_TRANSLATE_DISTANCE
            elseif self.point == TOP then
                offsetY = -ZO_POINTER_BOX_TRANSLATE_DISTANCE
            else
                offsetY = ZO_POINTER_BOX_TRANSLATE_DISTANCE
            end
            translateAnimation:SetDeltaOffsetX(offsetX, TRANSLATE_ANIMATION_DELTA_TYPE_FROM_END)
            translateAnimation:SetDeltaOffsetY(offsetY, TRANSLATE_ANIMATION_DELTA_TYPE_FROM_END)
        end
        if skipAnimation then
            self.showAnimationTimeline:PlayInstantlyToEnd()
        else
            self.showAnimationTimeline:PlayForward()
        end
    end
end

function ZO_PointerBox_Keyboard:Hide(skipAnimation)
    if self.contentsControl then
        if skipAnimation then
            self.showAnimationTimeline:PlayInstantlyToStart()
        else
            self.showAnimationTimeline:PlayBackward()
        end
    end
end

function ZO_PointerBox_Keyboard:Release()
    POINTER_BOXES:Release(self)
end

--Pointer Box Manager
---------------------------

ZO_PointerBoxManager = ZO_Object:Subclass()

function ZO_PointerBoxManager:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_PointerBoxManager:Initialize()
    local factory = function(pool)
        local control = ZO_ObjectPool_CreateNamedControl("ZO_PointerBox_KeyboardControl", "ZO_PointerBox_KeyboardControl", pool, GuiRoot)
        return ZO_PointerBox_Keyboard:New(control)
    end
    local reset = function(pointerBox)
        pointerBox:Reset()
    end
    self.pool = ZO_ObjectPool:New(factory, reset)
end

function ZO_PointerBoxManager:Acquire()
    local pointerBox, poolKey = self.pool:AcquireObject()
    pointerBox:SetPoolKey(poolKey)
    return pointerBox
end

function ZO_PointerBoxManager:Release(pointerBox)
    self.pool:ReleaseObject(pointerBox:GetPoolKey())
end

POINTER_BOXES = ZO_PointerBoxManager:New()