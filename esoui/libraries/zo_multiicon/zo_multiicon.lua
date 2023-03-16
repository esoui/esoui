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
    local index = (self.cycle % #multiIcon.iconData) + 1
    multiIcon:SetTexture(multiIcon.iconData[index].iconTexture)
    if multiIcon.iconData[index].iconTint then
        multiIcon:SetColor(multiIcon.iconData[index].iconTint:UnpackRGBA())
    else
        multiIcon:SetColor(ZO_WHITE:UnpackRGBA())
    end
end

function MultiIconTimer:AddMultiIcon(multiIcon)
    table.insert(self.multiIcons, multiIcon)
    self:SetupMultiIconTexture(multiIcon)
    multiIcon:SetAlpha(self.alpha * (multiIcon.maxAlpha or 1))
end

function MultiIconTimer:RemoveMultiIcon(multiIcon)
    for i = 1, #self.multiIcons do
        if self.multiIcons[i] == multiIcon then
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
    if timeline:GetProgress() == 1 then
        timeline.object:OnAnimationComplete()
    end
end

do
    local MULTI_ICON_TIMER
    
    local function Show(self)
        if self:IsHidden() and self.iconData and #self.iconData > 0 then
            self:SetHidden(false)
        end
    end

    local function Hide(self)
        self:SetHidden(true)
    end

    local function ClearIcons(self)
        if self.iconData then
            Hide(self)
            ZO_ClearNumericallyIndexedTable(self.iconData)
        end
    end

    local function HasIcon(self, iconTexture)
        if self.iconData then
            for _, existingIconTexture in ipairs(self.iconData) do
                if existingIconTexture.iconTexture == iconTexture then
                    return true
                end
            end
        end
        return false
    end

    local function AddIcon(self, iconTexture, iconTint, iconNarration)
        if iconTexture then
            if not self.iconData then
                self.iconData = {}
            end

            local iconData =
            {
                iconTexture = iconTexture,
                iconTint = iconTint,
                iconNarration = iconNarration,
            }
            table.insert(self.iconData, iconData)
        end
    end

    local function GetNarrationText(self)
        local narrations = {}
        if self.iconData then
            for _, iconData in ipairs(self.iconData) do
                table.insert(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(iconData.iconNarration))
            end
        end
        return narrations
    end

    local function SetMaxAlpha(self, maxAlpha)
        self.maxAlpha = maxAlpha
    end

    function ZO_MultiIcon_OnShow(self)
        if self.iconData then
            if #self.iconData > 1 then
                MULTI_ICON_TIMER:AddMultiIcon(self)
            else
                self:SetTexture(self.iconData[1].iconTexture)
                if self.iconData[1].iconTint then
                    self:SetColor(self.iconData[1].iconTint:UnpackRGBA())
                else
                    self:SetColor(ZO_WHITE:UnpackRGBA())
                end
                self:SetAlpha(self.maxAlpha or 1)
            end
        end
    end

    function ZO_MultiIcon_OnHide(self)
        if self.iconData then
            if #self.iconData > 1 then
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
        self.HasIcon = HasIcon
        self.GetNarrationText = GetNarrationText
        self.Show = Show
        self.Hide = Hide
        self.SetMaxAlpha = SetMaxAlpha
    end
end