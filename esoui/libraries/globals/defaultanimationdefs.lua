DEFAULT_SCENE_TRANSITION_TIME = 200
ZO_CONVEYOR_TRANSITION_TIME = 100

--Persist the offsets on the control because once we start animating it, the offsets can no longer be computed (it will have moved from its original position)
local function SetOffsetsFromControl(animation, animatingControl, index)
    if animatingControl.translate and animatingControl.translate[index] then
        animation:SetStartOffsetX(animatingControl.translate[index].startX)
        animation:SetEndOffsetX(animatingControl.translate[index].endX)
        animation:SetStartOffsetY(animatingControl.translate[index].startY)
        animation:SetEndOffsetY(animatingControl.translate[index].endY)
    end
end

local function SetOffsetsOnControl(animatingControl, index, startX, endX, startY, endY)
    if not animatingControl.translate then
        animatingControl.translate = {}
    end
    local translate = animatingControl.translate
    if not translate[index] then
        translate[index] = {}
    end
    local translateAnchorInfo = translate[index]
    translateAnchorInfo.startX = startX
    translateAnchorInfo.endX = endX
    translateAnchorInfo.startY = startY
    translateAnchorInfo.endY = endY
end

function ZO_TranslateFromLeftSceneAnimation_OnPlay(self, animatingControl)
    local anchorIndex = self:GetAnchorIndex()
    if not animatingControl.translate or not animatingControl.translate[anchorIndex] then
        local isValid, point, relTo, relPoint, offsetX, offsetY = animatingControl:GetAnchor(anchorIndex)
        if isValid then
            local width = animatingControl:GetWidth()
            SetOffsetsOnControl(animatingControl, anchorIndex, offsetX - width, offsetX, offsetY, offsetY)
        end
    end
    SetOffsetsFromControl(self, animatingControl, anchorIndex)
end

function ZO_TranslateFromRightSceneAnimation_OnPlay(self, animatingControl)
    local anchorIndex = self:GetAnchorIndex()
    if not animatingControl.translate or not animatingControl.translate[anchorIndex] then
        local isValid, point, relTo, relPoint, offsetX, offsetY = animatingControl:GetAnchor(anchorIndex)
        if isValid then
            local width = animatingControl:GetWidth()
            SetOffsetsOnControl(animatingControl, anchorIndex, offsetX + width, offsetX, offsetY, offsetY)
        end
    end
    SetOffsetsFromControl(self, animatingControl, anchorIndex)
end

function ZO_TranslateFromBottomSceneAnimation_OnPlay(self, animatingControl)
    local anchorIndex = self:GetAnchorIndex()
    if not animatingControl.translate or not animatingControl.translate[anchorIndex] then
        local isValid, point, relTo, relPoint, offsetX, offsetY = animatingControl:GetAnchor(anchorIndex)
        if isValid then
            local height = animatingControl:GetHeight()
            SetOffsetsOnControl(animatingControl, anchorIndex, offsetX, offsetX, offsetY + height, offsetY)
        end
    end
    SetOffsetsFromControl(self, animatingControl, anchorIndex)
end

function ZO_TranslateFromTopSceneAnimation_OnPlay(self, animatingControl)
    local anchorIndex = self:GetAnchorIndex()
    if not animatingControl.translate or not animatingControl.translate[anchorIndex] then
        local isValid, point, relTo, relPoint, offsetX, offsetY = animatingControl:GetAnchor(anchorIndex)
        if isValid then
            local height = animatingControl:GetHeight()
            SetOffsetsOnControl(animatingControl, anchorIndex, offsetX, offsetX, offsetY - height, offsetY)
        end
    end
    SetOffsetsFromControl(self, animatingControl, anchorIndex)
end