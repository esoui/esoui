ZO_GAMEPAD_LOADING_ICON_DEFAULT_SIZE = 90
ZO_GAMEPAD_LOADING_ICON_FOOTER_SIZE = 64

-- Loading Icon

local TARGET_FRAMERATE = 60
local MAX_FRAMES_PER_UPDATE = 5
local MAX_ROTATION = math.pi * 2
local ROTATION_PER_FRAME = -math.pi * .02

function ZO_LoadingIcon_Gamepad_Initialize(self)
    self.animation = self:GetNamedChild("Animation")
    self.currentRotation = 0
    self.lastAnimationUpdate = 0
end

function ZO_LoadingIcon_Gamepad_OnUpdate(self)
    local now = GetFrameTimeMilliseconds()
    local delta = now - self.lastAnimationUpdate
    
    local numFramesToIncrease = delta / TARGET_FRAMERATE
    if numFramesToIncrease == 0 then
        return
    elseif numFramesToIncrease > MAX_FRAMES_PER_UPDATE then
        numFramesToIncrease = MAX_FRAMES_PER_UPDATE
    end

    self.lastAnimationUpdate = now
    self.currentRotation = (self.currentRotation + numFramesToIncrease * ROTATION_PER_FRAME) % MAX_ROTATION

    self.animation:SetTextureRotation(self.currentRotation)
end