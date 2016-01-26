local Crossfade = ZO_Object:Subclass()

function Crossfade:New(...)
    local crossfade = ZO_Object.New(self)
    crossfade:Initialize(...)
    return crossfade
end

function Crossfade:Initialize(control)
    control.m_object = self
    self.m_control = control

    local function ResizeBG()
        ZO_ResizeControlForBestScreenFit(control:GetNamedChild("1"))
        ZO_ResizeControlForBestScreenFit(control:GetNamedChild("2"))
    end

    control:RegisterForEvent(EVENT_SCREEN_RESIZED, ResizeBG)
    ResizeBG()
end

function Crossfade:InitializeBuffer(control, startingTexture, initialDrawLevel)
    if(control.m_timeline == nil) then
        control.m_timeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_CrossfadeAnimation", control)
        control.m_timeline.m_crossFade = self
    else
        control.m_timeline:Stop()
    end

    control:SetTexture(startingTexture)
    control:SetDrawLevel(initialDrawLevel)
    control:SetAlpha(1)
    control:SetHidden(false)
    return control
end

function Crossfade:OnComplete()
    self.m_backBuffer:SetDrawLevel(self.m_backBuffer:GetDrawLevel() + 1)
    self.m_frontBuffer:SetDrawLevel(self.m_frontBuffer:GetDrawLevel() - 1)

    self.m_frontBuffer, self.m_backBuffer = self.m_backBuffer, self.m_frontBuffer
end

function Crossfade:InitializeBufferImages(frontBufferImage, backBufferImage)
    self.m_frontBuffer = self:InitializeBuffer(self.m_control:GetNamedChild("1"), frontBufferImage, 1)
    self.m_backBuffer = self:InitializeBuffer(self.m_control:GetNamedChild("2"), backBufferImage, 0)
end

function Crossfade:DoCrossfade(newBG)
    self.m_frontBuffer.m_timeline:PlayFromStart()
    self.m_backBuffer:SetTexture(newBG)    
    self.m_backBuffer.m_textureFile = newBG
    self.m_backBuffer:SetAlpha(1)
end

function Crossfade:PlaySlideShow(delay, ...)
    if(self.m_slideShowIsPlaying) then return end

    local currentImageIndex = 2 -- start with the second image, the first is shown automatically...don't want to crossfade into an identical image
    local imageData = { ... }
    local function SlideShowCallback()
        self:DoCrossfade(imageData[currentImageIndex])
        currentImageIndex = currentImageIndex + 1
        if(currentImageIndex > #imageData) then currentImageIndex = 1 end
    end

    self:InitializeBufferImages(imageData[1], imageData[2])
    self.m_slideShowEventName = self.m_control:GetName().."SlideShowEvent"
    EVENT_MANAGER:RegisterForUpdate(self.m_slideShowEventName, delay, SlideShowCallback)
    self.m_slideShowIsPlaying = true
end

function Crossfade:StopSlideShow()
    -- You should have started the show before calling this...
    if(not self.m_slideShowIsPlaying) then return end
    EVENT_MANAGER:UnregisterForUpdate(self.m_slideShowEventName)
    self.m_slideShowEventName = nil
    self.m_slideShowIsPlaying = nil
end

--[[
    Global API
--]]

function ZO_CrossfadeBG_OnInitialized(self)
    self.m_object = Crossfade:New(self)
end

function ZO_CrossfadeBG_GetObject(control)
    return control.m_object
end

function ZO_CrossfadeBG_OnCrossfadeComplete(timeline, completedPlaying)
    if(completedPlaying) then
        timeline.m_crossFade:OnComplete()
    end
end