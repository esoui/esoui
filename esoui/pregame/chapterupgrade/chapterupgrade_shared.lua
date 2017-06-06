ZO_PLATFORM_ALLOWS_CHAPTER_CODE_ENTRY =
{
    [PLATFORM_SERVICE_TYPE_ZOS] = true,
    [PLATFORM_SERVICE_TYPE_PSN] = true,
    [PLATFORM_SERVICE_TYPE_XBL] = true,
}

ZO_ChapterUpgrade_Shared = ZO_Object:Subclass()

function ZO_ChapterUpgrade_Shared:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_ChapterUpgrade_Shared:Initialize(control, sceneName)
    self.control = control
    self.sceneName = sceneName

    self.initialized = false

    self.backgroundImage = control:GetNamedChild("Image")
    self.logoTexture = control:GetNamedChild("Logo")

    local textContainer = control:GetNamedChild("TextContainer")
    self.registrationSummaryControl = textContainer:GetNamedChild("RegistrationSummary")
    self.codeEntryInstructionsControl = textContainer:GetNamedChild("CodeEntryContainerInstructions")
    self.digitalUpgradeInstructionsControl = textContainer:GetNamedChild("DigitalUpgradeContainerInstructions")

    local sceneFragment = ZO_FadeSceneFragment:New(control)
    local scene = ZO_Scene:New(sceneName, SCENE_MANAGER)
    scene:AddFragment(sceneFragment)

    local stateChangeHandlers = 
    {
        [SCENE_SHOWING] = self.OnShowing,
        [SCENE_SHOWN] = self.OnShown,
        [SCENE_HIDING] = self.OnHiding,
    }

    scene:RegisterCallback("StateChange", function(oldState, newState)
        local handler = stateChangeHandlers[newState]
        if handler then
            handler(self)
        end
    end)

    self.continueDialogData = 
    {
        finishedCallback = function(dialog)
            if dialog.data.continue then
                self:Hide()
            end
        end
    }

    control:RegisterForEvent(EVENT_SCREEN_RESIZED, function(...) self:ResizeBackground(...) end)
end

function ZO_ChapterUpgrade_Shared:PerformDeferredInitialize()
    if not self.initialized then
        local backgroundTexture, registrationSummary, codeEntryInstructions, digitalUpgradeInstructions = GetCurrentChapterRegistrationInfo()
        local logoTexture = GetCurrentChapterLargeLogoFileIndex()
        self.backgroundImage:SetTexture(backgroundTexture)
        self:ResizeBackground()
        self.logoTexture:SetTexture(logoTexture)
        self.registrationSummaryControl:SetText(registrationSummary)
        self.codeEntryInstructionsControl:SetText(codeEntryInstructions)
        self.digitalUpgradeInstructionsControl:SetText(digitalUpgradeInstructions)
        self.initialized = true
    end
end

function ZO_ChapterUpgrade_Shared:ResizeBackground()
    ZO_ResizeControlForBestScreenFit(self.backgroundImage)
end

function ZO_ChapterUpgrade_Shared:OnShowing()
    self:PerformDeferredInitialize()
end

function ZO_ChapterUpgrade_Shared:OnShown()
    local currentVersion = GetCurrentChapterVersion()
    SetCVar("ChapterUpgradeSeenVersion", currentVersion)
end

function ZO_ChapterUpgrade_Shared:OnHiding()
    -- intended to be overriden
end

function ZO_ChapterUpgrade_Shared:Hide()
    if SCENE_MANAGER:IsShowing(self.sceneName) then
        SCENE_MANAGER:Hide(self.sceneName)
        PregameStateManager_AdvanceState()
    end
end

function ZO_ChapterUpgrade_Shared:ShowContinueDialog()
    ZO_Dialogs_ShowPlatformDialog("CHAPTER_UPGRADE_CONTINUE", self.continueDialogData)
end

function ZO_ChapterUpgrade_ShouldShow()
    if HasCurrentChapter() then
        return false
    end

    local currentVersion = GetCurrentChapterVersion()
    local seenVersion = tonumber(GetCVar("ChapterUpgradeSeenVersion"))
    return currentVersion ~= seenVersion
end