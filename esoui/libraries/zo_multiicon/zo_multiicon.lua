local MultiIconTimer = ZO_Object:Subclass()

function MultiIconTimer:New()
    local timer = ZO_Object.New(self)
    timer.alpha = 0
    timer.cycle = 0
    timer.multiIcons = {}

    timer.timeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("MultiIconAnimation")
    timer.timeline.object = timer
    timer.timeline:PlayFromStart()

    return timer
end

function MultiIconTimer:SetupMultiIconTexture(multiIcon)
    local index = (self.cycle % #multiIcon.iconTextures) + 1
    multiIcon:SetTexture(multiIcon.iconTextures[index])
end

function MultiIconTimer:AddMultiIcon(multiIcon)
    table.insert(self.multiIcons, multiIcon)
    self:SetupMultiIconTexture(multiIcon)
    multiIcon:SetAlpha(self.alpha * (multiIcon.maxAlpha or 1)) 
end

function MultiIconTimer:RemoveMultiIcon(multiIcon)
    for i = 1, #self.multiIcons do
        if(self.multiIcons[i] == multiIcon) then
            table.remove(self.multiIcons, i)
            break
        end
    end
end

function MultiIconTimer:SetAlphas(alpha)
    self.alpha = alpha
    for i = 1, #self.multiIcons do
        self.multiIcons[i]:SetAlpha(alpha)
    end
end

function MultiIconTimer:OnAnimationComplete()
    self.cycle = (self.cycle + 1) % 100
    for i = 1, #self.multiIcons do
        self:SetupMultiIconTexture(self.multiIcons[i])
    end
    self.timeline:PlayFromStart()
end

--Global XML

function ZO_MultiIconAnimation_SetAlpha(animation, alpha)
    animation:GetTimeline().object:SetAlphas(alpha)
end

function ZO_MultiIconAnimation_OnStop(timeline)
    if(timeline:GetProgress() == 1) then
        timeline.object:OnAnimationComplete()
    end
end

do
    local MULTI_ICON_TIMER
    
    local function Show(self)
        if(self:IsHidden() and self.iconTextures and #self.iconTextures > 0) then
            self:SetHidden(false)            
        end
    end

    local function Hide(self)
        self:SetHidden(true)        
    end

    local function ClearIcons(self)
        if(self.iconTextures) then
            Hide(self)
            ZO_ClearNumericallyIndexedTable(self.iconTextures)
        end
    end

    local function AddIcon(self, iconTexture)
        if(not self.iconTextures) then
            self.iconTextures = {}
        end
        table.insert(self.iconTextures, iconTexture)
    end

    local function SetMaxAlpha(self, maxAlpha)
        self.maxAlpha = maxAlpha
    end

    function ZO_MultiIcon_OnShow(self)
        if(self.iconTextures) then
            if(#self.iconTextures > 1) then
                MULTI_ICON_TIMER:AddMultiIcon(self)
            else
                self:SetTexture(self.iconTextures[1])
                self:SetAlpha(self.maxAlpha or 1)
            end
        end
    end

    function ZO_MultiIcon_OnHide(self)
        if(self.iconTextures) then
            if(#self.iconTextures > 1) then
                MULTI_ICON_TIMER:RemoveMultiIcon(self)
            end
        end
    end

    function ZO_MultiIcon_Initialize(self)
        if not MULTI_ICON_TIMER then
            MULTI_ICON_TIMER = MultiIconTimer:New()
        end

        self.ClearIcons = ClearIcons
        self.AddIcon = AddIcon
        self.Show = Show
        self.Hide = Hide
        self.SetMaxAlpha = SetMaxAlpha
    end
end