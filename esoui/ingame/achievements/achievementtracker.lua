------------------
--Initialization--
------------------

ZO_AchievementTracker = ZO_HUDTracker_Base:Subclass()

function ZO_AchievementTracker:Initialize(control)
    ZO_HUDTracker_Base.Initialize(self, control)

    self.headerIcon = self.headerLabel:GetNamedChild("Icon")
    self.assistedKeybindButton = self.container:GetNamedChild("HeaderAssisted")
    
    self.criteriaLabelPool = ZO_ControlPool:New("ZO_AchievementTracker_Criteria", self.container, "Criteria")
    self.criteriaLabelPool:SetCustomFactoryBehavior(function(label)
        label:SetFont(self.currentStyle.FONT_CRITERIA_LABEL)
    end)
    self.criteriaProgressPool = ZO_ControlPool:New("ZO_ProgressBarWithGloss_Template_Base", self.container, "Progress")
    self.criteriaProgressPool:SetCustomFactoryBehavior(function(progressBar)
        ZO_ApplyPlatformTemplateToControl(progressBar, "ZO_HUDTracker_Base_ProgressBar")
        ZO_StatusBar_SetGradientColor(progressBar, ZO_XP_BAR_GRADIENT_COLORS)
    end)

    local HIDE_UNBOUND = false
    local DONT_PREFER_GAMEPAD = false
    local SHOW_AS_HOLD =
    {
        keyboard = true,
        gamepad = false,
    }
    self.assistedKeybindButton:SetKeybind("ASSIST_NEXT_TRACKED_QUEST", HIDE_UNBOUND, "GAMEPAD_CYCLE_PINNED_HUD_ACTION", DONT_PREFER_GAMEPAD, SHOW_AS_HOLD)

    self:SetHeaderText(GetString(SI_ACHIEVEMENT_HUD_TRACKER_TITLE))

    ACHIEVEMENT_TRACKER_FRAGMENT = self:GetFragment()
end

function ZO_AchievementTracker:InitializeStyles()
    self.styles =
    {
        keyboard =
        {
            HEADER_ICON_SIZE = 25,
            HEADER_ICON_OFFSET = -2,
            FONT_SUBLABEL = "ZoFontWinH4",
            FONT_CRITERIA_LABEL = "ZoFontGameShadow",
            CRITERIA_LABEL_PADDING = 2,
        },
        gamepad =
        {
            HEADER_ICON_SIZE = 48,
            HEADER_ICON_OFFSET = -10,
            FONT_SUBLABEL = "ZoFontGamepadBold27",
            FONT_CRITERIA_LABEL = "ZoFontGamepad34",
            CRITERIA_LABEL_PADDING = 5,
        }
    }

    ZO_HUDTracker_Base.InitializeStyles(self)
end

function ZO_AchievementTracker:GetHUDElementInfo()
    local DISPLAY_NAME = nil -- Will be controlled via TimedActivityTracker
    return DISPLAY_NAME
end

function ZO_AchievementTracker:GetHUDElementOptionKeys()
    local KEY = nil -- Will be controlled via TimedActivityTracker
    return KEY
end

function ZO_AchievementTracker:GetParentTracker()
    return TIMED_ACTIVITY_TRACKER
end

function ZO_AchievementTracker:RegisterEvents()
    ZO_HUDTracker_Base.RegisterEvents(self)

    local function Update()
        self:Update()
    end

    HUD_TRACKER_MANAGER:RegisterCallback("AssistedAspirationChanged", Update)
    self.control:RegisterForEvent(EVENT_ACHIEVEMENT_UPDATED, Update)
end

function ZO_AchievementTracker:Update()
    local isTracked = false
    local isAssisted = false

    local achievementId, criterionIndex = GetTrackedAchievement()
    if achievementId > 0 then
        local achievementName = GetAchievementName(achievementId)
        self:SetSubLabelText(zo_strformat(achievementName))
        isTracked = true
        local assistedAspiration = HUD_TRACKER_MANAGER:GetAssistedAspiration()
        if assistedAspiration == ZO_HUD_TRACKER_ASPIRATION.ACHIEVEMENT then
            isAssisted = true
        end

        self.achievementId = achievementId
        self.criterionIndex = criterionIndex

        self:UpdateCriteria()
        self.assistedKeybindButton:SetHidden(not TIMED_ACTIVITY_TRACKER:IsAnythingTracked())
    end

    local fragment = self:GetFragment()
    local FADE_INSTANT_MS = 0
    fragment:SetHiddenForReason("NotAssisted", not isAssisted, FADE_INSTANT_MS, FADE_INSTANT_MS)
    fragment:SetHiddenForReason("NoTrackedAchievement", not isTracked, DEFAULT_HUD_DURATION, DEFAULT_HUD_DURATION)

    self:RefreshAnchors()

    ZO_HUDTracker_Base.Update(self)
end

function ZO_AchievementTracker:UpdateCriteria()
    -- TODO Achievement: Handle specific criterion tracking?
    self.criteriaLabelPool:ReleaseAllObjects()
    self.criteriaProgressPool:ReleaseAllObjects()
    self.nextCriteriaAnchorRelativeTo = self.subLabel

    local achievementId = self.achievementId
    local numCriteria = GetAchievementNumCriteria(achievementId)
    local hasMultipleCriteria = numCriteria > 1
    local incompleteCriteria = {}
    for i = 1, numCriteria do
        local description, numCompleted, numRequired = GetAchievementCriterion(achievementId, i)

        if numCompleted < numRequired then
            if numRequired > 1 or (hasMultipleCriteria and description) then
                table.insert(incompleteCriteria,
                {
                    description = description,
                    numCompleted = numCompleted,
                    numRequired = numRequired,
                })
            end
        end
    end
    
    local CRITERIA_DISPLAY_LIMIT = 3
    local _, achievementDescription = GetAchievementInfo(achievementId)
    local excessiveCriteria = #incompleteCriteria > CRITERIA_DISPLAY_LIMIT
    if excessiveCriteria then
        achievementDescription = string.format("%s (%d)", achievementDescription, #incompleteCriteria)
    end

    self:AddCriteria(zo_strformat(achievementDescription))

    for i, criterion in ipairs(incompleteCriteria) do
        if criterion.numRequired > 1 then
            local progressBarDescription = hasMultipleCriteria and criterion.description or nil
            self:AddProgressBar(criterion.numCompleted, criterion.numRequired, progressBarDescription)
        elseif hasMultipleCriteria then
            self:AddBulletedDescription(criterion.description)
        end

        if i == CRITERIA_DISPLAY_LIMIT then
            break
        end
    end

    if excessiveCriteria then
        self:AddCriteria("...")
    end
end

function ZO_AchievementTracker:AddCriteria(text, addBullet)
    local criteriaDescriptionLabel = self.criteriaLabelPool:AcquireObject()
    if addBullet then
        zo_bulletFormat(criteriaDescriptionLabel, text)
    else
        criteriaDescriptionLabel:SetText(text)
    end
    criteriaDescriptionLabel:SetAnchor(TOPRIGHT, self.nextCriteriaAnchorRelativeTo, BOTTOMRIGHT, 0, self.currentStyle.CRITERIA_LABEL_PADDING)
    self.nextCriteriaAnchorRelativeTo = criteriaDescriptionLabel
end

do
    local USE_LOWERCASE_NUMBER_SUFFIXES = false
    local ROUND_TO_ZERO = true
    function ZO_AchievementTracker:AddProgressBar(numCompleted, numRequired, description)
        self:AddBulletedDescription(description)

        local criteriaProgressBar = self.criteriaProgressPool:AcquireObject()
        criteriaProgressBar:SetMinMax(0, numRequired)
        criteriaProgressBar:SetValue(numCompleted)
        local numCompletedAbbreviated = ZO_AbbreviateAndLocalizeNumber(numCompleted, NUMBER_ABBREVIATION_PRECISION_TENTHS, USE_LOWERCASE_NUMBER_SUFFIXES, ROUND_TO_ZERO)
        local numRequiredAbbreviated = ZO_AbbreviateAndLocalizeNumber(numRequired, NUMBER_ABBREVIATION_PRECISION_TENTHS, USE_LOWERCASE_NUMBER_SUFFIXES, ROUND_TO_ZERO)
        criteriaProgressBar.progressBarLabel:SetText(zo_strformat(SI_CURRENT_AND_MAX_VALUES_FORMATTER, numCompletedAbbreviated, numRequiredAbbreviated))
        criteriaProgressBar:SetAnchor(TOPRIGHT, self.nextCriteriaAnchorRelativeTo, BOTTOMRIGHT, 0, self.currentStyle.CRITERIA_LABEL_PADDING)
        self.nextCriteriaAnchorRelativeTo = criteriaProgressBar

        return true
    end
end

function ZO_AchievementTracker:AddBulletedDescription(description)
    if description then
        local ADD_BULLET = true
        self:AddCriteria(description, ADD_BULLET)
        return true
    end
    return false
end

function ZO_AchievementTracker:ApplyPlatformStyle(style)
    ZO_HUDTracker_Base.ApplyPlatformStyle(self, style)

    self.headerIcon:SetDimensions(style.HEADER_ICON_SIZE, style.HEADER_ICON_SIZE)
    self.headerIcon:SetAnchor(RIGHT, nil, LEFT, style.HEADER_ICON_OFFSET)
    ApplyTemplateToControl(self.assistedKeybindButton, ZO_GetPlatformTemplate("ZO_KeybindButton"))

    for _, criteriaLabel in self.criteriaLabelPool:ActiveAndFreeObjectIterator() do
        criteriaLabel:SetFont(style.FONT_CRITERIA_LABEL)
    end

    for _, criteriaProgressBar in self.criteriaProgressPool:ActiveAndFreeObjectIterator() do
        ZO_ApplyPlatformTemplateToControl(criteriaProgressBar, "ZO_HUDTracker_Base_ProgressBar")
    end
end

function ZO_AchievementTracker:GetPriority()
    return ZO_HUD_TRACKER_PRIORITY.ACHIEVEMENT
end

function ZO_AchievementTracker.OnControlInitialized(control)
    ACHIEVEMENT_TRACKER = ZO_AchievementTracker:New(control)
end

HUD_TRACKER_MANAGER:RegisterTracker("ZO_AchievementTracker_Template", "ZO_AchievementTracker_TL")