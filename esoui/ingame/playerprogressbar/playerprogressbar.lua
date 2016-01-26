--Bar Fragments

ZO_PlayerProgressBarFragment = ZO_SceneFragment:Subclass()

function ZO_PlayerProgressBarFragment:New(...)
    local fragment = ZO_SceneFragment.New(self)
    fragment:Initialize(...)
    return fragment
end

function ZO_PlayerProgressBarFragment:Initialize()
    self.suppressFadeTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_PlayerProgressBarSuppressFade")
    self.suppressFadeTimeline:SetHandler("OnStop", function(timeline, completed)
        if(completed) then
            if(timeline:IsPlayingBackward()) then
                self:OnHidden()
            else
                self:OnShown()
            end
        end
    end)
end

function ZO_PlayerProgressBarFragment:Show()
    self.suppressFadeTimeline:PlayForward()
end

function ZO_PlayerProgressBarFragment:Hide()
    local instant = self.sceneManager:GetCurrentScene() == self.sceneManager:GetBaseScene()
    ZO_Animation_PlayBackwardOrInstantlyToStart(self.suppressFadeTimeline, instant)
end

ZO_PlayerProgressBarCurrentFragment = ZO_SceneFragment:Subclass()

function ZO_PlayerProgressBarCurrentFragment:New(...)
    local fragment = ZO_SceneFragment.New(self)
    EVENT_MANAGER:RegisterForEvent("PlayerProgressBarCurrentFragment", EVENT_VETERAN_POINTS_UPDATE, function()
        fragment:RefreshBaseType()
    end)
    return fragment
end

function ZO_PlayerProgressBarCurrentFragment:RefreshBaseType()
    if(self:IsShowing()) then
        if(GetUnitVeteranRank("player") > 0) then
            PLAYER_PROGRESS_BAR:SetBaseType(PPB_VP)
        else
            PLAYER_PROGRESS_BAR:SetBaseType(PPB_XP)
        end
    else
        PLAYER_PROGRESS_BAR:ClearBaseType()
    end
end

function ZO_PlayerProgressBarCurrentFragment:Show()
    self:RefreshBaseType()
    self:OnShown()
end

function ZO_PlayerProgressBarCurrentFragment:Hide()
    self:RefreshBaseType()
    self:OnHidden()
end

-------------------------

ZO_PlayerProgressBarKeyboardTextureSwapFragment = ZO_SceneFragment:Subclass()

function ZO_PlayerProgressBarKeyboardTextureSwapFragment:New(progressBar)
    local fragment = ZO_SceneFragment.New(self)
    fragment.progressBar = progressBar
    fragment.progressBar.isInKeyboardMode = not IsInGamepadPreferredMode()
    return fragment
end

function ZO_PlayerProgressBarKeyboardTextureSwapFragment:Show()   
    if self.progressBar.isInKeyboardMode == false then    
        self.progressBar.isInKeyboardMode = true
        self.progressBar:RefreshTemplate()
    end
    self:OnShown()
end

-------------------------

ZO_PlayerProgressBarGamepadTextureSwapFragment = ZO_SceneFragment:Subclass()

function ZO_PlayerProgressBarGamepadTextureSwapFragment:New(progressBar)
    local fragment = ZO_SceneFragment.New(self)
    fragment.progressBar = progressBar
    fragment.progressBar.isInKeyboardMode = not IsInGamepadPreferredMode()
    return fragment
end

function ZO_PlayerProgressBarGamepadTextureSwapFragment:Show()   
    if self.progressBar.isInKeyboardMode == true then    
        self.progressBar.isInKeyboardMode = false    
        self.progressBar:RefreshTemplate()
    end
    self:OnShown()
end

--Bar Type

local PlayerProgressBarType = ZO_Object:Subclass()

function PlayerProgressBarType:New(barTypeClass, barTypeId, ...)
    local obj = ZO_Object.New(self)
    obj.barTypeClass = barTypeClass
    obj.params = {...}
    obj.barTypeId = barTypeId
    obj:Initialize(...)
    obj:InitializeLastValues()
    return obj
end

function PlayerProgressBarType:Initialize(...)
    
end

function PlayerProgressBarType:InitializeLastValues()
    self.lastLevel = self:GetLevel()
    self.lastCurrent = self:GetCurrent()
end

function PlayerProgressBarType:GetEnlightenedPool()
    return 0
end

function PlayerProgressBarType:GetEnlightenedTooltip()
    return nil
end

function PlayerProgressBarType:GetSecondaryBarType()
    return nil
end

function PlayerProgressBarType:Equals(barTypeClass, ...)
    if(self.barTypeClass == barTypeClass) then
        for i = 1, select("#", ...) do
            local param = select(i, ...)
            if(param ~= self.params[i]) then
                return false
            end
        end
        return true
    end
    return false
end

function PlayerProgressBarType:GetBarGradient()
    return self.barGradient
end

function PlayerProgressBarType:GetIcon()
    return self.icon
end

function PlayerProgressBarType:GetLevelTypeText()
    return self.levelTypeText
end

-- XP Bar Type

local XPBarType = PlayerProgressBarType:Subclass()

function XPBarType:New(barTypeId)
    return PlayerProgressBarType.New(self, PPB_CLASS_XP, barTypeId)
end

function XPBarType:Initialize()
    self.barGradient = ZO_XP_BAR_GRADIENT_COLORS
    self.barGlowColor = ZO_XP_BAR_GLOW_COLOR
    self.levelTypeText = GetString(SI_EXPERIENCE_LEVEL_LABEL)
    self.tooltipCurrentMaxFormat = SI_EXPERIENCE_CURRENT_MAX
end

function XPBarType:GetLevelSize(rank)
    return GetNumExperiencePointsInLevel(rank)
end
            
function XPBarType:GetLevel()
    return GetUnitLevel("player")
end
            
function XPBarType:GetCurrent()
    return GetUnitXP("player")
end

function XPBarType:GetLevelTypeText()
    if not IsInGamepadPreferredMode() then
        return self.levelTypeText
    end
end

--VP Bar Type

local VPBarType = PlayerProgressBarType:Subclass()

function VPBarType:New(barTypeId)
    return PlayerProgressBarType.New(self, PPB_CLASS_VP, barTypeId)
end

function VPBarType:Initialize()
    self.barGradient = ZO_VP_BAR_GRADIENT_COLORS
    self.barGlowColor = ZO_VP_BAR_GLOW_COLOR
    self.tooltipCurrentMaxFormat = SI_VETERAN_POINTS_CURRENT_MAX
    
end

function VPBarType:GetEnlightenedPool()
    return 0
end

function VPBarType:GetSecondaryBarType()
    return PPB_CLASS_CP
end

function VPBarType:GetLevelSize(rank)
    return GetNumVeteranPointsInRank(rank)
end

function VPBarType:GetLevel()
    return GetUnitVeteranRank("player")
end
            
function VPBarType:GetCurrent()
    return GetUnitVeteranPoints("player")
end

function VPBarType:GetLevelTypeText()
    if not IsInGamepadPreferredMode() then
        return GetString(SI_EXPERIENCE_VETERAN_RANK_LABEL) 
    end
end

function VPBarType:GetIcon()
    if not IsInGamepadPreferredMode() then
        return "EsoUI/Art/Progression/veteranIcon_small.dds"
    else 
        return GetGamepadVeteranRankIcon()
    end
end
-- Champion Bar Type

local CPBarType = PlayerProgressBarType:Subclass()

function CPBarType:New(barTypeId)
    return PlayerProgressBarType.New(self, PPB_CLASS_CP, barTypeId)
end

function CPBarType:Initialize()
    self.levelTypeText = GetString(SI_EXPERIENCE_CHAMPION_RANK_LABEL)
    self.tooltipCurrentMaxFormat = SI_CHAMPION_POINTS_CURRENT_MAX
end

-- The champion bar shows the progress for the next point that you will gain, if you're maxed, just leave it at the last point earned.
function CPBarType:GetShownAttribute()
    local level = self:GetLevel()
    if self:GetLevelSize(level) ~= nil then
        level = level + 1
    end
    return GetChampionPointAttributeForRank(level)
end

function CPBarType:GetBarGradient()
    return ZO_CP_BAR_GRADIENT_COLORS[self:GetShownAttribute()]
end

local CHAMPION_ATTRIBUTE_HUD_ICONS = 
{
    [ATTRIBUTE_HEALTH] = "EsoUI/Art/Champion/champion_points_health_icon-HUD-32.dds",
    [ATTRIBUTE_MAGICKA] = "EsoUI/Art/Champion/champion_points_magicka_icon-HUD-32.dds",
    [ATTRIBUTE_STAMINA] = "EsoUI/Art/Champion/champion_points_stamina_icon-HUD-32.dds",
}

function CPBarType:GetIcon()
    return CHAMPION_ATTRIBUTE_HUD_ICONS[self:GetShownAttribute()]
end

function CPBarType:GetEnlightenedPool()
    if IsEnlightenedAvailableForCharacter() then
        return GetEnlightenedPool() * (GetEnlightenedMultiplier() + 1)
    else
        return 0
    end
end

function CPBarType:GetEnlightenedTooltip()
    local level = self:GetLevel()
    local levelSize = self:GetLevelSize(level)
    if levelSize then
        local poolSize = self:GetEnlightenedPool()
        local current = self:GetCurrent()
        local nextPoint = GetChampionPointAttributeForRank(level + 1)
        local pointName = ZO_Champion_GetConstellationGroupNameFromAttribute(nextPoint)
        if poolSize + current > levelSize then
            return zo_strformat(SI_EXPERIENCE_CHAMPION_ENLIGHTENED_TOOLTIP_OVERRUN, pointName)
        else
            return zo_strformat(SI_EXPERIENCE_CHAMPION_ENLIGHTENED_TOOLTIP, pointName, ZO_CommaDelimitNumber(current + poolSize))
        end
    else
        return GetString(SI_EXPERIENCE_CHAMPION_ENLIGHTENED_TOOLTIP_MAXED)
    end
end

function CPBarType:GetLevelSize(rank)
    return GetChampionXPInRank(rank)
end

function CPBarType:GetLevel()
    return GetPlayerChampionPointsEarned()
end

function CPBarType:GetCurrent()
    return GetPlayerChampionXP()
end

--Skill Bar Type

local SkillBarType = PlayerProgressBarType:Subclass()

function SkillBarType:New(barTypeId, ...)
    return PlayerProgressBarType.New(self, PPB_CLASS_SKILL, barTypeId, ...)
end

function SkillBarType:Initialize(skillType, skillIndex)
    self.skillType = skillType
    self.skillIndex = skillIndex
    self.barGradient = ZO_SKILL_XP_BAR_GRADIENT_COLORS
    self.barGlowColor = ZO_SKILL_XP_BAR_GLOW_COLOR
    local name = GetSkillLineInfo(skillType, skillIndex)
    self.levelTypeText = name
    self.tooltipCurrentMaxFormat = SI_EXPERIENCE_CURRENT_MAX 
end

function SkillBarType:GetLevelSize(rank)
    local startXP, nextRankStartXP = GetSkillLineRankXPExtents(self.skillType, self.skillIndex, rank)
    if(startXP ~= nil and nextRankStartXP ~= nil) then
        return nextRankStartXP - startXP
    else
        return nil
    end
end
            
function SkillBarType:GetLevel()
    local name, rank = GetSkillLineInfo(self.skillType, self.skillIndex)
    return rank
end
            
function SkillBarType:GetCurrent()
    local lastRankXP, nextRankXP, currentXP = GetSkillLineXPInfo(self.skillType, self.skillIndex)
    return currentXP - lastRankXP
end

--Bar

local PlayerProgressBar = ZO_CallbackObject:Subclass()

local FADE_DURATION_MS = 200
local WAIT_BEFORE_FILL_DURATION_MS = 1500
local MIN_GLOW_DURATION_MS = 1000
local MIN_WAIT_BEFORE_HIDE_MS = 1000
local TIME_BETWEEN_ENLIGHTENED_ANIMATIONS_SECS = 6

PPB_CLASS_XP = 1
PPB_CLASS_VP = 2
PPB_CLASS_CP = 3
PPB_CLASS_SKILL = 4

local PPB_MODE_INCREASE = 1
local PPB_MODE_CURRENT = 2
local PPB_MODE_WAITING_FOR_INCREASE = 3

local PPB_STATE_SHOWING = "showing"
local PPB_STATE_SHOWN = "shown"
local PPB_STATE_HIDING = "hiding"
local PPB_STATE_HIDDEN = "hidden"

local PROGRESS_BAR_KEYBOARD_STYLE = 
{
    template = "ZO_PlayerProgressTemplate",
}

local PROGRESS_BAR_GAMEPAD_STYLE = 
{
    template = "ZO_GamepadPlayerProgressTemplate",
}

function PlayerProgressBar:New(...)
    local object = ZO_CallbackObject.New(self)
    object:Initialize(...)
    return object
end

function PlayerProgressBar:Initialize(control)
    self.control = control
    self.barControl = control:GetNamedChild("Bar")
    self.secondaryBarControl = control:GetNamedChild("SecondaryBar")
    self.enlightenedBarControl = self.secondaryBarControl:GetNamedChild("EnlightenedBar")
    self.secondaryBarLevelTypeLabel = control:GetNamedChild("SecondaryLevelType")
    self.secondaryBarLevelTypeIcon = control:GetNamedChild("SecondaryLevelTypeIcon")
    self.levelLabel = control:GetNamedChild("Level")
    self.levelTypeLabel = control:GetNamedChild("LevelType")
    self.levelTypeIcon = control:GetNamedChild("LevelTypeIcon")
    self.glowContainer = self.barControl:GetNamedChild("GlowContainer")
    self.glowTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_PlayerProgressBarGlow", self.glowContainer)
    self.glowFadeOutTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_PlayerProgressBarGlowFadeOut", self.glowContainer)

    self.barState = PPB_STATE_HIDDEN
    self.fadeAlpha = 0
    self.suppressAlpha = 0
    self.nextBarType = 1
    self:RefreshAlpha()

    self.bar = ZO_WrappingStatusBar:New(self.barControl)
    self.bar:SetOnLevelChangeCallback(function(_, level)
        self:OnBarLevelChange(level)
    end)
    self.bar:SetOnCompleteCallback(function()
        self:OnFillComplete()
    end)

    self.fadeTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_PlayerProgressBarFade")
    self.fadeTimeline:SetHandler("OnStop", function(timeline, completed)
        if(completed) then
            if(timeline:IsPlayingBackward()) then
                self:OnFadeOutComplete()
            else
                self:OnFadeInComplete()
            end
        end
    end)

    local barWidth = self.barControl:GetWidth()
    self.enlightenedTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_PlayerProgressBarEnlightenedAnimation", self.enlightenedBarControl)

    self.fillCompleteCallback = function()
        self:OnFillComplete()
    end
    self.waitBeforeHideCompleteCallback = function()
        self:OnWaitBeforeHideComplete()
    end
    self.waitBeforeShowCompleteCallback = function()
        self:OnWaitBeforeShowComplete()
    end
    self.waitBeforeFillCompleteCallback = function()
        self:OnWaitBeforeFillComplete()
    end
    self.waitBeforeStopGlowingCompleteCallback = function()
        self:OnWaitBeforeStopGlowingComplete()
    end

    control:RegisterForEvent(EVENT_EXPERIENCE_UPDATE, function()
        self:RefreshCurrentTypeLater(PPB_XP)
    end)
    control:RegisterForEvent(EVENT_VETERAN_POINTS_UPDATE, function()
        self:RefreshCurrentTypeLater(PPB_VP)
    end)
    control:RegisterForEvent(EVENT_PLAYER_ACTIVATED, function()
        self:InitializeLastValues()
    end)

    control:SetHandler("OnUpdate", function(_, timeSecs)
        self:OnUpdate(timeSecs)
    end)

    self:InitializeBarTypeClasses()
    self:InitializeBarTypes()
    
    ZO_PlatformStyle:New(function(style) self:ApplyStyle(style) end, PROGRESS_BAR_KEYBOARD_STYLE, PROGRESS_BAR_GAMEPAD_STYLE)
end

--Bar Type Interfacing

function PlayerProgressBar:InstantiateBarType(barTypeClass, ...)
    local barTypeClassDef = self.barTypeClasses[barTypeClass]
    local barType = self.nextBarType
    local barTypeObject = barTypeClassDef:New(self.nextBarType, ...)
    self.nextBarType = self.nextBarType + 1
    self.barTypes[barType] = barTypeObject
    return barType
end

function PlayerProgressBar:InitializeBarTypeClasses()
    self.barTypeClasses =
    {
        [PPB_CLASS_XP] = XPBarType,
        [PPB_CLASS_VP] = VPBarType,
        [PPB_CLASS_SKILL] = SkillBarType,
        [PPB_CLASS_CP] = CPBarType,
    }
end

function PlayerProgressBar:GetBarType(barTypeClass, ...)
    for barType, barTypeInfo in ipairs(self.barTypes) do
        if(barTypeInfo:Equals(barTypeClass, ...)) then
            return barType
        end
    end
    local barType = self:InstantiateBarType(barTypeClass, ...)
    return barType
end

function PlayerProgressBar:InitializeBarTypes()
    self.barTypes = {}
    PPB_XP = self:InstantiateBarType(PPB_CLASS_XP)
    PPB_VP = self:InstantiateBarType(PPB_CLASS_VP)
    PPB_CP = self:InstantiateBarType(PPB_CLASS_CP)
end

function PlayerProgressBar:InitializeLastValues()
    for i = 1, #self.barTypes do
        local barTypeInfo = self.barTypes[i]
        barTypeInfo:InitializeLastValues()
    end
end

function PlayerProgressBar:GetLevelSize(level)
    return self:GetBarTypeInfo() and self:GetBarTypeInfo():GetLevelSize(level)
end

function PlayerProgressBar:GetBarTypeInfo()
    return self.barTypes[self.barType]
end

function PlayerProgressBar:GetSecondaryBarInfo()
    local barTypeInfo = self:GetBarTypeInfo()
    if barTypeInfo then
        return self.barTypes[barTypeInfo:GetSecondaryBarType()]
    end
end

function PlayerProgressBar:GetCurrentInfo()
    local barTypeInfo = self:GetBarTypeInfo()
    local level = barTypeInfo:GetLevel()
    local levelSize = barTypeInfo:GetLevelSize(level)

    if(levelSize ~= nil) then
        local current = barTypeInfo:GetCurrent()
        return level, current, levelSize
    else
        return level, 1, 1
    end
end

function PlayerProgressBar:GetMostRecentlyShownInfo()
    --dont update the bar while announcements that will show that bar type increasing are in queue
    if(not CENTER_SCREEN_ANNOUNCE:HasBarTypeInQueue(self.barType)) then
        return self:GetCurrentInfo()
    else
        local barTypeInfo = self:GetBarTypeInfo()
        return barTypeInfo.lastLevel, barTypeInfo.lastCurrent, barTypeInfo:GetLevelSize(barTypeInfo.lastLevel)
    end
end

-- Alpha Control

function PlayerProgressBar:SetFadeAlpha(alpha)
    self.fadeAlpha = alpha
    self:RefreshAlpha()
end

function PlayerProgressBar:SetSuppressAlpha(alpha)
    self.suppressAlpha = alpha
    self:RefreshAlpha()
end

function PlayerProgressBar:RefreshAlpha()
    self.control:SetAlpha(zo_min(self.suppressAlpha, self.fadeAlpha))
end

--Bar Control

function PlayerProgressBar:SetBarValue(level, current)
    local levelSize = self:GetLevelSize(level)
    if(levelSize == nil) then
        current = 1
        levelSize = 1
    end
    self.bar:SetValue(level, current, levelSize)
    
    local barTypeInfo = self:GetBarTypeInfo()
    barTypeInfo.lastLevel = level
    barTypeInfo.lastCurrent = current
end

function PlayerProgressBar:SetBarState(state)
    self.barState = state
end

function PlayerProgressBar:SetBarMode(mode)
    self.barMode = mode
end

function PlayerProgressBar:GetOwner()
    return self.increaseOwner
end

--Base Type

function PlayerProgressBar:SetBaseType(newBaseType)
    if(self.baseType ~= newBaseType) then
        self.baseType = newBaseType
        if(not self.pendingShowIncrease) then
            if(self.barMode == PPB_MODE_CURRENT) then
                if(self.baseType ~= self.barType) then
                    if(self.barState == PPB_STATE_HIDDEN) then
                        if(self.baseType ~= nil) then
                            self:ShowCurrent(self.baseType)
                        end
                    else
                        self:Hide()
                    end
                else
                    if(self.barState == PPB_STATE_HIDING) then
                        self:ShowCurrent(self.baseType)
                    end
                end
            elseif(self.barMode == nil) then
                if(self.baseType ~= nil) then
                    self:ShowCurrent(self.baseType)
                end
            end
        end
    end
end

function PlayerProgressBar:ClearBaseType()
    self:SetBaseType(nil)
end

--Show

function PlayerProgressBar:Show()
    self:SetBarState(PPB_STATE_SHOWING)

    local barTypeInfo = self:GetBarTypeInfo()
    ZO_StatusBar_SetGradientColor(self.barControl, barTypeInfo:GetBarGradient())
    
    self:RefreshSecondaryBar()

    for i = 1, self.glowContainer:GetNumChildren() do
        local glowTexture = self.glowContainer:GetChild(i)
        glowTexture:SetColor(barTypeInfo.barGlowColor:UnpackRGB())
    end

    local levelTypeText = barTypeInfo:GetLevelTypeText()
    if levelTypeText then
        self.levelTypeLabel:SetText(zo_strformat(SI_LEVEL_BAR_LABEL, levelTypeText))
        self.levelTypeLabel:SetHidden(false)
    else
        self.levelTypeLabel:SetHidden(true)
        self.levelTypeLabel:SetText("")
    end

    if(barTypeInfo:GetIcon() ~= nil) then
        self.levelTypeIcon:SetHidden(false)
        self.levelTypeIcon:SetTexture(barTypeInfo:GetIcon())
    else
        self.levelTypeIcon:SetHidden(true)
    end
    
    self.control:SetHidden(false)
    self.fadeTimeline:PlayForward()
    CALLBACK_MANAGER:FireCallbacks("PlayerProgressBarFadingIn")
end

function PlayerProgressBar:Hide()
    if(self.barState ~= PPB_STATE_HIDDEN and self.barState ~= PPB_STATE_HIDING) then
        self.fadeTimeline:PlayBackward()
        CALLBACK_MANAGER:FireCallbacks("PlayerProgressBarFadingOut")
        self:SetBarState(PPB_STATE_HIDING)
    end
end

function PlayerProgressBar:ShowIncrease(barType, startLevel, start, stop, increaseSound, waitBeforeShowMS, owner)
    if(self.barMode ~= PPB_MODE_INCREASE) then
        if(self.barType and self.barType ~= barType) then
            waitBeforeShowMS = zo_max(FADE_DURATION_MS, waitBeforeShowMS)
            self:Hide()
        end

        self.pendingShowIncrease = { barType, startLevel, start, stop, increaseSound, owner }
        self:WaitBeforeShow(waitBeforeShowMS)
    end
end

function PlayerProgressBar:ShowCurrent(barType)
    self.barType = barType
    self:SetBarMode(PPB_MODE_CURRENT)
    self:RefreshCurrentBar()
    self:Show()
    self:FireCallbacks("Show")
end

--Allow time for other systems to submit increase requests before updating to current
function PlayerProgressBar:RefreshCurrentTypeLater(barType)
    zo_callLater(function()
        self:RefreshCurrentType(barType)
    end, 2000)
end

function PlayerProgressBar:RefreshCurrentType(barType)
    if(self.barType == barType) then
        self:RefreshCurrentBar()
    end
end

function PlayerProgressBar:RefreshCurrentBar()
    if(self.barMode == PPB_MODE_CURRENT and self.barState ~= PPB_STATE_HIDING) then
        self.bar:Reset()
        local level, current, max = self:GetMostRecentlyShownInfo()
        self:SetBarValue(level, current, max)
        self.levelLabel:SetText(level)
        self:RefreshSecondaryBar()
    end
end

function PlayerProgressBar:RefreshSecondaryBar()
    local secondaryBarInfo = self:GetSecondaryBarInfo()
    local hasSecondaryBar = secondaryBarInfo ~= nil
    if hasSecondaryBar then
        local current = secondaryBarInfo:GetCurrent()
        local max = secondaryBarInfo:GetLevelSize(secondaryBarInfo:GetLevel())
        if max == nil then
            current = 1
            max = 1
        end
        self.secondaryBarControl:SetMinMax(0, max)
        self.secondaryBarControl:SetValue(current)
        local gradient = secondaryBarInfo:GetBarGradient()
        ZO_StatusBar_SetGradientColor(self.secondaryBarControl, gradient)
        ZO_StatusBar_SetGradientColor(self.enlightenedBarControl, gradient)
        self.secondaryBarLevelTypeIcon:SetTexture(secondaryBarInfo:GetIcon())
    end
    self.secondaryBarLevelTypeIcon:SetHidden(not hasSecondaryBar)
    self.secondaryBarControl:SetHidden(not hasSecondaryBar)
end

function PlayerProgressBar:OnUpdate(timeSecs)
    self:RefreshEnlightened(timeSecs)
end

function PlayerProgressBar:RefreshEnlightened(timeSecs)    
    if not self.nextEnlightenedUpdate or timeSecs > self.nextEnlightenedUpdate then
        self.nextEnlightenedUpdate = timeSecs + 1

        local barTypeInfo = self:GetSecondaryBarInfo()
        local poolSize = barTypeInfo and barTypeInfo:GetEnlightenedPool()

        if poolSize and poolSize > 0 then
            if not self.enlightenedTimeline:IsPlaying() then
                self.enlightenedTimeline:PlayFromStart()
            end

            local current = barTypeInfo:GetCurrent()
            local max = barTypeInfo:GetLevelSize(barTypeInfo:GetLevel())
            if max then
                self.enlightenedBarControl:SetHidden(false)
                self.enlightenedBarControl:SetMinMax(0, max)
                self.enlightenedBarControl:SetValue(zo_min(max, current + poolSize))
            else
                self.enlightenedBarControl:SetHidden(true)
            end
        else
            self.enlightenedTimeline:Stop()
            self.enlightenedBarControl:SetHidden(true)
        end
    end
end

function PlayerProgressBar:ApplyStyle(style)
    ApplyTemplateToControl(self.control, style.template)
    self:RefreshTemplate()
end

function PlayerProgressBar:RefreshTemplate()
    local template
    local barTypeInfo = self:GetBarTypeInfo()
    local secondaryBarTypeInfo = barTypeInfo and barTypeInfo:GetSecondaryBarType()
    if not IsInGamepadPreferredMode() then
        if secondaryBarTypeInfo == nil then
            template = "ZO_PlayerProgressBarTemplate"
        else
            template = "ZO_PlayerProgressDualBarTemplate"
        end
        self.secondaryBarLevelTypeLabel:SetHidden(secondaryBarTypeInfo == nil)
    else
        if secondaryBarTypeInfo == nil then
            template = "ZO_GamepadPlayerProgressBarTemplate"
        else
            template = "ZO_GamepadPlayerProgressDualBarTemplate"
        end
        self.secondaryBarLevelTypeLabel:SetHidden(true)
    end
    ApplyTemplateToControl(self.barControl, template)
end

--Show Increase Animation Parts

function PlayerProgressBar:WaitBeforeShow(waitBeforeShowMS)
    zo_callLater(self.waitBeforeShowCompleteCallback, waitBeforeShowMS)
end

function PlayerProgressBar:OnWaitBeforeShowComplete()
    local barType, startLevel, start, stop, sound, owner = unpack(self.pendingShowIncrease)
    self.pendingShowIncrease = nil

    local needsShow = self.barType ~= barType
    self.barType = barType
    self.barMode = PPB_MODE_INCREASE

    self.increaseStartLevel = startLevel
    self.increaseStart = start
    self.increaseStop = stop
    self.increaseSound = sound
    self.increaseOwner = owner
    
    self.bar:Reset()
    self:SetBarValue(startLevel, start)
    self:RefreshSecondaryBar()
    self.levelLabel:SetText(startLevel)

    if(needsShow) then
        self:Show()
    else
        self:WaitBeforeFill()
    end

    self:FireCallbacks("Show")
end

function PlayerProgressBar:WaitBeforeFill()
    zo_callLater(self.waitBeforeFillCompleteCallback, WAIT_BEFORE_FILL_DURATION_MS)
end

function PlayerProgressBar:OnWaitBeforeFillComplete()
    self:AnimateFillIncrease()
end

function PlayerProgressBar:AnimateFillIncrease()
    local finalLevel = self.increaseStartLevel
    local finalLevelSize = self:GetLevelSize(self.increaseStartLevel)
    local finalStop = self.increaseStop
    
    while(finalLevelSize ~= nil and finalStop >= finalLevelSize) do
        finalStop = finalStop - finalLevelSize
        finalLevel = finalLevel + 1
        finalLevelSize = self:GetLevelSize(finalLevel)
    end

    if(self.increaseSound) then
        PlaySound(self.increaseSound)
    end
    self:SetBarValue(finalLevel, finalStop)
    self.glowContainer:SetHidden(false)
    self.glowTimeline:PlayFromStart()
    self.increaseGlowStartMS = GetFrameTimeMilliseconds()
end

function PlayerProgressBar:OnFillComplete()
    self:WaitBeforeStopGlowing()
end

function PlayerProgressBar:WaitBeforeStopGlowing()
    local glowDuration = GetFrameTimeMilliseconds() - self.increaseGlowStartMS
    if(glowDuration < MIN_GLOW_DURATION_MS) then
        zo_callLater(self.waitBeforeStopGlowingCompleteCallback, MIN_GLOW_DURATION_MS - glowDuration)
    else
        self:OnWaitBeforeStopGlowingComplete()
    end
end

function PlayerProgressBar:OnWaitBeforeStopGlowingComplete()
    self.glowTimeline:Stop()
    self.glowFadeOutTimeline:PlayFromStart()
    self:WaitBeforeHide()
end

function PlayerProgressBar:WaitBeforeHide()
    zo_callLater(self.waitBeforeHideCompleteCallback, MIN_WAIT_BEFORE_HIDE_MS)
end

function PlayerProgressBar:OnWaitBeforeHideComplete()
    self.increaseReadyToHide = true
    self.glowFadeOutTimeline:Stop()
    self.glowContainer:SetHidden(true)
    self:RefreshDoneShowing()
end

function PlayerProgressBar:SetHoldBeforeFadeOut(holdBeforeFadeOut)
    self.increaseHoldBeforeFadeOut = holdBeforeFadeOut
    self:RefreshDoneShowing()
end

function PlayerProgressBar:RefreshDoneShowing()
    if(self.barState == PPB_STATE_SHOWN) then
        if(self:IsDoneShowing()) then
            self:OnDoneShowing()
        end
    end
end

function PlayerProgressBar:IsDoneShowing()
    return not self.increaseHoldBeforeFadeOut and self.increaseReadyToHide
end

function PlayerProgressBar:OnComplete()
    self:ClearIncreaseData()
    self:FireCallbacks("Complete")
end

function PlayerProgressBar:OnDoneShowing()
    if(CENTER_SCREEN_ANNOUNCE:DoesNextEventHaveBarType(self.barType)) then
        self:SetBarMode(PPB_MODE_WAITING_FOR_INCREASE)
        self:OnComplete()
    elseif(not CENTER_SCREEN_ANNOUNCE:DoesNextEventHaveBar() and self.baseType == self.barType) then
        self:SetBarMode(PPB_MODE_CURRENT)
        self:RefreshCurrentBar()
        self:OnComplete()
    else
        self:Hide()
    end
end

function PlayerProgressBar:ClearIncreaseData()
    self.increaseReadyToHide = nil
    self.increaseHoldBeforeFadeOut = nil
    self.increaseStartLevel = nil
    self.increaseStart = nil
    self.increaseStop = nil
    self.increaseSound = nil
    self.increaseOwner = nil
    self.increaseGlowStartMS = nil
end

function PlayerProgressBar:OnBarLevelChange(level)
    self.levelLabel:SetText(level)
    self:RefreshTemplate()
end

--General Events

function PlayerProgressBar:OnFadeInComplete()
    self:SetBarState(PPB_STATE_SHOWN)

    if(self.barMode == PPB_MODE_INCREASE) then
        self:WaitBeforeFill()
    end
end

function PlayerProgressBar:OnFadeOutComplete()
    local oldBarMode = self.barMode
    
    self:SetBarMode(nil)
    self.barType = nil
   
    self:SetBarState(PPB_STATE_HIDDEN)
    self.control:SetHidden(true)

    local nextAnnouncementHasBar = CENTER_SCREEN_ANNOUNCE:DoesNextEventHaveBar()

    if(oldBarMode == PPB_MODE_INCREASE) then
        self:OnComplete()
    end

    if(self.baseType and not nextAnnouncementHasBar and not self.pendingShowIncrease) then
        self:ShowCurrent(self.baseType)
    end
    
    self:FireCallbacks("FadeOutComplete")
end

--Local XML

function PlayerProgressBar:Bar_OnMouseEnter(bar)
    local barTypeInfo = nil
    local level = 0
    local current = 0
    local levelSize = 0
    if bar == self.secondaryBarControl then
        barTypeInfo = self:GetSecondaryBarInfo()
        level = barTypeInfo:GetLevel()
        current = barTypeInfo:GetCurrent()
        levelSize = barTypeInfo:GetLevelSize(level)
    else
        barTypeInfo = self:GetBarTypeInfo()
        level, current = self:GetMostRecentlyShownInfo()
        levelSize = self:GetLevelSize(level)
    end
    
    if(barTypeInfo) then
        InitializeTooltip(InformationTooltip, bar, TOP, 0, 10)
        SetTooltipText(InformationTooltip, zo_strformat(SI_LEVEL_DISPLAY, barTypeInfo:GetLevelTypeText(), level))

        if(levelSize) then
            InformationTooltip:AddLine(zo_strformat(barTypeInfo.tooltipCurrentMaxFormat, ZO_CommaDelimitNumber(current), ZO_CommaDelimitNumber(levelSize)))
        end

        local enlightenedPool = barTypeInfo:GetEnlightenedPool()
        if enlightenedPool > 0 then
            local enlightenedTooltip = barTypeInfo:GetEnlightenedTooltip()
            InformationTooltip:AddLine(enlightenedTooltip)
        end
    end
end

function PlayerProgressBar:Bar_OnMouseExit(self)
    ClearTooltip(InformationTooltip)
end

--Global XML

function ZO_PlayerProgressBar_OnMouseEnter(self)
    PLAYER_PROGRESS_BAR:Bar_OnMouseEnter(self)
end

function ZO_PlayerProgressBar_OnMouseExit(self)
    PLAYER_PROGRESS_BAR:Bar_OnMouseExit(self)
end

function ZO_PlayerProgress_OnInitialized(self)
    PLAYER_PROGRESS_BAR = PlayerProgressBar:New(self)
end
