--Constants
ZO_SCALABLE_BACKGROUND_WIDTH = 512
ZO_SCALABLE_BACKGROUND_HEIGHT = 128
ZO_SCALABLE_BACKGROUND_GRUNGE_CAP_HEIGHT = 45
ZO_SCALABLE_BACKGROUND_CENTER_TEXTURE_TOP_COORD = ZO_SCALABLE_BACKGROUND_GRUNGE_CAP_HEIGHT / ZO_SCALABLE_BACKGROUND_HEIGHT
ZO_SCALABLE_BACKGROUND_CENTER_TEXTURE_BOTTOM_COORD = (ZO_SCALABLE_BACKGROUND_HEIGHT - ZO_SCALABLE_BACKGROUND_GRUNGE_CAP_HEIGHT) / ZO_SCALABLE_BACKGROUND_HEIGHT

ZO_SCENE_MENU_HEIGHT = 45

ZO_DEFAULT_BACKDROP_ANCHOR_OFFSET = 8
  
function ZO_SelectionHighlight_SetColor(highlight, r, g, b)
    highlight:SetCenterColor(r, g, b, 1)
    highlight:SetEdgeColor(r, g, b, 1)
end

function ZO_SelectionHighlight_Highlight(highlight, control, leftOffset, topOffset, rightOffset, bottomOffset)
    highlight:SetHidden(control == nil)
    
    if(control)
    then
        highlight:ClearAnchors()
        
        if(leftOffset == nil)
        then
            highlight:SetAnchorFill(control)
        else
            highlight:SetAnchor(TOPLEFT, control, TOPLEFT, leftOffset, topOffset)
            highlight:SetAnchor(BOTTOMRIGHT, control, BOTTOMRIGHT, rightOffset, bottomOffset)
        end
    end
end

function ZO_CreateSparkleAnimation(slotControl)
    local icon = slotControl:GetNamedChild("Icon")
    local sparkle = slotControl:GetNamedChild("Sparkle")
    local sparkleCCW = sparkle:GetNamedChild("CCW")

    local animData = 
    { 
        sparkle = sparkle,
        translateTimeLine = ANIMATION_MANAGER:CreateTimelineFromVirtual("SparkleTranslateAnim", icon),
        sparkleTimeLine = ANIMATION_MANAGER:CreateTimelineFromVirtual("SparkleStarburstAnim", sparkle),
    }

    local ccwAnim = animData.sparkleTimeLine:GetAnimation(2)
    ccwAnim:SetAnimatedControl(sparkleCCW)

    if(slotControl.CustomOnStopCallback) then
        animData.sparkleTimeLine:SetHandler("OnStop", function() slotControl:CustomOnStopCallback() end)
    end

    icon.animData = animData
end

function ZO_PlaySparkleAnimation(slotControl)
    local animData = slotControl:GetNamedChild("Icon").animData

    if(slotControl.SetMouseOverTexture) then
        slotControl:SetMouseOverTexture(nil) -- Disable mouseover texture, we don't want to show it during motion animation
        slotControl:SetPressedMouseOverTexture(nil)
    end
    
    animData.translateTimeLine:PlayFromStart()
    animData.sparkleTimeLine:PlayFromStart()
    animData.sparkle:SetHidden(false)
end

function ZO_SetupSelectableItemRadialMenuEntryTemplate(template, selected, itemCount)
    if(itemCount) then
        template.count:SetHidden(false)
        template.count:SetText(itemCount)

        if itemCount == 0 then
            template.icon:SetDesaturation(1)
        else
            template.icon:SetDesaturation(0)
        end
    else
        template.count:SetHidden(true)
        template.icon:SetDesaturation(0)
    end

    if selected then
        if template.glow then
            template.glow:SetAlpha(1)
        end
        template.animation:GetLastAnimation():SetAnimatedControl(nil)
    else
        if template.glow then
            template.glow:SetAlpha(0)
        end
        template.animation:GetLastAnimation():SetAnimatedControl(template.glow)
    end
end

do
    ZO_RequiredTextFields = ZO_Object:Subclass()

    function ZO_RequiredTextFields:New()
        local obj = ZO_Object.New(self)
        obj.buttons = {}
        obj.editControls = {}
        obj.booleans = {}
        obj.OnTextChanged = function() obj:UpdateButtonEnabled() end

        return obj
    end

    function ZO_RequiredTextFields:AddButton(button)
        table.insert(self.buttons, button)
        self:UpdateButtonEnabled()
    end

    function ZO_RequiredTextFields:SetBoolean(name, value)
        self.booleans[name] = value
        self:UpdateButtonEnabled()
    end

    function ZO_RequiredTextFields:ClearButtons()
        self:SetButtonsEnabled(true)
        self.buttons = {}
    end

	function ZO_RequiredTextFields:SetMatchingString(string)
		self.matchingString = string
		self:UpdateButtonEnabled()
	end

    function ZO_RequiredTextFields:AddTextField(editControl)
        table.insert(self.editControls, editControl)
        ZO_PreHookHandler(editControl, "OnTextChanged", self.OnTextChanged)
        self:UpdateButtonEnabled()
    end

    function ZO_RequiredTextFields:SetButtonsEnabled(enabled)
        local state = enabled and BSTATE_NORMAL or BSTATE_DISABLED
        local locked = not enabled
        for i = 1, #self.buttons do
            self.buttons[i]:SetState(state, locked)
        end
    end

    function ZO_RequiredTextFields:UpdateButtonEnabled()
        if(#self.buttons > 0) then
            for _, value in pairs(self.booleans) do
                if(not value) then
                    self:SetButtonsEnabled(false)
					return
                end
            end

            for i = 1, #self.editControls do
			    local editText = self.editControls[i]:GetText()
				if(self.matchingString) then
					if(self.matchingString ~= editText) then
						self:SetButtonsEnabled(false)
						return
					end
				else 
					if(editText == "") then
						self:SetButtonsEnabled(false)
						return
					end
                end
            end

            self:SetButtonsEnabled(true)
        end
    end
end

do
    local KEYBOARD_STYLES = {
        loadingIconTemplate = "ZO_LoadingIcon_Keyboard_Template",
    }

    local GAMEPAD_STYLES =  {
        loadingIconTemplate = "ZO_LoadingIcon_Gamepad_Template",
    }

    local function Show(self)
        if not self.createdIcon then
            self.loadingIcon = CreateControlFromVirtual("$(parent)Icon", self, "ZO_LoadingIcon_Common")

            local function UpdatePlatformStyles(styleTable)
                ApplyTemplateToControl(self.loadingIcon, styleTable.loadingIconTemplate)
            end

            ZO_PlatformStyle:New(UpdatePlatformStyles, KEYBOARD_STYLES, GAMEPAD_STYLES)

            self.createdIcon = true
        end
        self:SetHidden(false)

        if not self.animation then
            self.animation = ANIMATION_MANAGER:CreateTimelineFromVirtual("LoadIconAnimation", GetControl(self, "Icon"))
        end
        
        if(self.text) then
            if(not self.label) then
                self.label = CreateControlFromVirtual("$(parent)Text", self, self.labelTemplate)
            end

            self.label:SetText(self.text)
        end

        if self.animation then
            self.animation:PlayForward()
        end
    end

    local function Hide(self)
        self:SetHidden(true)
        if(self.animation) then
            self.animation:Stop()
        end
    end

    local function SetText(self, text)
        local textControl = GetControl(self, "Text")
        if(textControl) then
            textControl:SetText(text)
        else
            self.text = text
        end
    end

    local function ApplyTemplateToLabel(self, labelTemplate)
        if(not self.label) then
            self.label = CreateControlFromVirtual("$(parent)Text", self, self.labelTemplate)
        end
        ApplyTemplateToControl(self.label, labelTemplate)
    end

    function ZO_Loading_Initialize(self, loadText, labelTemplate)
        self.Show = Show
        self.Hide = Hide
        self.SetText = SetText
        self.ApplyTemplateToLabel = ApplyTemplateToLabel

        self.text = loadText
        self.labelTemplate = labelTemplate or "ZO_LoadingText"

        self.createdIcon = false
    end
end

do
    function ZO_HelpIcon_OnMouseEnter(self)
        InitializeTooltip(InformationTooltip, self, self.side, 0, 0)
        SetTooltipText(InformationTooltip, self.helpMessage)
    end

    function ZO_HelpIcon_OnMouseExit(self)
        ClearTooltip(InformationTooltip)
    end

    function ZO_HelpIcon_Initialize(self, helpMessage, side)
        self.helpMessage = helpMessage
        self.side = side
    end
end

do
    local function Start(self, remainingTimeMs)
        self:StartCooldown(remainingTimeMs, remainingTimeMs, CD_TYPE_RADIAL, CD_TIME_TYPE_TIME_UNTIL, NO_LEADING_EDGE)
        local nowS = GetFrameTimeSeconds()
        self.endTimeS = nowS + (remainingTimeMs / 1000)
        self.lastUpdateS = nowS

        if(self.numWarningSounds > 0) then
            EVENT_MANAGER:RegisterForUpdate(self:GetName(), 20, function(timeMS)
                local timeS = timeMS / 1000
                if(timeS < self.endTimeS and timeS >= self.endTimeS - self.numWarningSounds) then
                    local lastUpdateSecPart = zo_floor(self.lastUpdateS)
                    local nowSecPart = zo_floor(timeS)
                    if(lastUpdateSecPart ~= nowSecPart) then
                        PlaySound(SOUNDS.COUNTDOWN_WARNING)
                        if(not self.pulseTimeline) then
                            self.pulseTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_RadialCountdownTimerPulse", self)
                        end
                        self.pulseTimeline:PlayFromStart()
                    end
                end
                self.lastUpdateS = timeS
            end)
        end
    end

    local function Stop(self)
        self:ResetCooldown()
        self.lastUpdateS = nil
        self.endTimeS = nil
        EVENT_MANAGER:UnregisterForUpdate(self:GetName())
    end

    local function SetNumWarningSounds(self, numWarningSounds)
        self.numWarningSounds = numWarningSounds
    end

    function ZO_RadialCountdownTimer_OnInitialized(self)
        self.numWarningSounds = 0
        self.Start = Start
        self.Stop = Stop
        self.SetNumWarningSounds = SetNumWarningSounds
    end
end

ZO_SimpleControlScaleInterpolator = ZO_Object:Subclass()

function ZO_SimpleControlScaleInterpolator:New(...)
    local interpolator = ZO_Object.New(self)
    interpolator:Initialize(...)
    return interpolator
end

function ZO_SimpleControlScaleInterpolator:Initialize(minScale, maxScale)
    self.minScale = minScale
    self.maxScale = maxScale
end

function ZO_SimpleControlScaleInterpolator:ScaleUp(control)
    if not self.controlsToTarget then
        self.controlsToTarget = {}
    end
    self.controlsToTarget[control] = self.maxScale
    self:RefreshUpdateHandlerRegistration()
end

function ZO_SimpleControlScaleInterpolator:ScaleDown(control)
    if not self.controlsToTarget then
        self.controlsToTarget = {}
    end
    self.controlsToTarget[control] = self.minScale
    self:RefreshUpdateHandlerRegistration()
end

function ZO_SimpleControlScaleInterpolator:ResetToMax(control)
    control:SetScale(self.maxScale)
    if self.controlsToTarget then
        self.controlsToTarget[control] = nil
        self:RefreshUpdateHandlerRegistration()
    end
end

function ZO_SimpleControlScaleInterpolator:ResetToMin(control)
    control:SetScale(self.minScale)
    if self.controlsToTarget then
        self.controlsToTarget[control] = nil
        self:RefreshUpdateHandlerRegistration()
    end
end

function ZO_SimpleControlScaleInterpolator:RefreshUpdateHandlerRegistration()
    local shouldBeRegisteredForUpdate = self.controlsToTarget ~= nil and next(self.controlsToTarget) ~= nil
    if self.registeredForUpdate ~= shouldBeRegisteredForUpdate then
        self.registeredForUpdate = shouldBeRegisteredForUpdate
        if shouldBeRegisteredForUpdate then
            EVENT_MANAGER:RegisterForUpdate(tostring(self), 0, function() self:OnUpdate() end)
        else
            EVENT_MANAGER:UnregisterForUpdate(tostring(self))
        end
    end
end

function ZO_SimpleControlScaleInterpolator:ResetAll()
    if self.controlsToTarget then
        for control, target in pairs(self.controlsToTarget) do
            self:ResetToMin(control)
        end
    end
end

function ZO_SimpleControlScaleInterpolator:OnUpdate()
    if self.controlsToTarget then
        for control, target in pairs(self.controlsToTarget) do
            local delta = target - control:GetScale()
            if zo_abs(delta) < .0025 then
                control:SetScale(target)
                self.controlsToTarget[control] = nil
                self:RefreshUpdateHandlerRegistration()
            else
                control:SetScale(zo_deltaNormalizedLerp(control:GetScale(), target, .2))
            end
        end
    end
end

function ZO_SelectableItemRadialMenuEntryTemplate_OnInitialized(self)
    self.glow = self:GetNamedChild("Glow")
    self.icon = self:GetNamedChild("Icon")
    self.count = self:GetNamedChild("CountText")
    self.cooldown = self:GetNamedChild("Cooldown")
end

function ZO_ScalableBackgroundWithEdge_SetSize(background, width, height)
    local textureCoordLeft = (ZO_SCALABLE_BACKGROUND_WIDTH - width) / ZO_SCALABLE_BACKGROUND_WIDTH
    background:SetDimensions(width, height + 2 * ZO_SCALABLE_BACKGROUND_GRUNGE_CAP_HEIGHT)

    background.top:SetTextureCoords(textureCoordLeft, 1, 0, ZO_SCALABLE_BACKGROUND_CENTER_TEXTURE_TOP_COORD)
    background.bottom:SetTextureCoords(textureCoordLeft, 1, ZO_SCALABLE_BACKGROUND_CENTER_TEXTURE_BOTTOM_COORD, 1)
    background.center:SetTextureCoords(textureCoordLeft, 1, ZO_SCALABLE_BACKGROUND_CENTER_TEXTURE_TOP_COORD, ZO_SCALABLE_BACKGROUND_CENTER_TEXTURE_BOTTOM_COORD)
end