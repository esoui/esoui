ZO_EndlessDungeonSummary = ZO_DeferredInitializingObject:Subclass()

function ZO_EndlessDungeonSummary:Initialize(control)
    self.control = control
    control.object = self

    local scene = ZO_Scene:New("endlessDungeonSummary", SCENE_MANAGER)
    ZO_DeferredInitializingObject.Initialize(self, scene)
    ENDLESS_DUNGEON_SUMMARY_SCENE = scene

    ENDLESS_DUNGEON_SUMMARY_FRAGMENT = ZO_FadeSceneFragment:New(control)

    ENDLESS_DUNGEON_MANAGER:RegisterCallback("StateChanged", ZO_GetCallbackForwardingFunction(self, self.OnEndlessDungeonStateChanged))
end

function ZO_EndlessDungeonSummary:OnDeferredInitialize()
    self:InitializeControls()
    self:InitializeKeybindStripDescriptor()
    self:InitializeNarrationInfo()
end

function ZO_EndlessDungeonSummary:InitializeControls()
    local control = self.control
    self.stageValueLabel = control:GetNamedChild("StageValue")
    self.scoreValueLabel = control:GetNamedChild("ScoreValue")
    self.versesValueLabel = control:GetNamedChild("VersesValue")
    self.visionsValueLabel = control:GetNamedChild("VisionsValue")
    self.avatarVisionsValueLabel = control:GetNamedChild("AvatarVisionsValue")

    local keybindContainer = control:GetNamedChild("KeybindContainer")
    self.switchToBuffsKeybindButton = keybindContainer:GetNamedChild("SwitchToBuffs")
    self.closeToBuffsKeybindButton = keybindContainer:GetNamedChild("Close")

    ZO_PlatformStyle:New(ZO_GetCallbackForwardingFunction(self, self.OnPlatformStyleChanged))
end

function ZO_EndlessDungeonSummary:InitializeKeybindStripDescriptor()
    local switchToBuffsKeybindDescriptor =
    {
        --Even though this is an ethereal keybind, the name will still be read during screen narration
        name = GetString(SI_ENDLESS_DUNGEON_SUMMARY_SWITCH_TO_BUFFS_KEYBIND),
        keybind = "UI_SHORTCUT_TERTIARY",
        ethereal = true,
        narrateEthereal = true,
        etherealNarrationOrder = 1,
        callback = function()
            SYSTEMS:ShowScene("endlessDungeonBuffTracker")
        end,
    }

    local closeDescriptor =
    {
        --Even though this is an ethereal keybind, the name will still be read during screen narration
        name = GetString(SI_DIALOG_CLOSE),
        keybind = "TOGGLE_ENDLESS_DUNGEON_BUFF_TRACKER",
        ethereal = true,
        narrateEthereal = true,
        etherealNarrationOrder = 2,
        callback = function()
            -- For when the user clicks the button
            SCENE_MANAGER:HideCurrentScene()
        end
    }

    self.switchToBuffsKeybindButton:SetKeybindButtonDescriptor(switchToBuffsKeybindDescriptor)
    self.closeToBuffsKeybindButton:SetKeybindButtonDescriptor(closeDescriptor)

    local backKeybindDescriptor = ZO_DeepTableCopy(KEYBIND_STRIP:GetDefaultGamepadBackButtonDescriptor())
    backKeybindDescriptor.ethereal = true
    backKeybindDescriptor.narrateEthereal = false

    self.keybindStripDescriptor =
    {
        -- Switch To Tracker
        switchToBuffsKeybindDescriptor,
        -- Close (For narration only)
        closeDescriptor,
        -- Back Button (Hidden)
        backKeybindDescriptor,
    }
end

function ZO_EndlessDungeonSummary:InitializeNarrationInfo()
    local narrationInfo =
    {
        canNarrate = function()
            return self:IsShowing()
        end,
        selectedNarrationFunction = function()
            local narrations = {}
            local endlessDungeonManager = ENDLESS_DUNGEON_MANAGER

            -- Title
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_ENDLESS_DUNGEON_SUMMARY_TITLE)))
            -- Progress Header
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_ENDLESS_DUNGEON_SUMMARY_PROGRESS_HEADER)))

            --Arc/Cycle/Stage
            local stageNarration, cycleNarration, arcNarration = endlessDungeonManager:GetCurrentProgressionNarrationDescriptions()
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_ENDLESS_DUNGEON_SUMMARY_STAGE_HEADER)))
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(arcNarration))
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(cycleNarration))
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(stageNarration))

            -- Score
            local scoreNarration = zo_strformat(SI_ENDLESS_DUNGEON_SUMMARY_STAT_VALUE_NARRATION, GetString(SI_ENDLESS_DUNGEON_SUMMARY_SCORE_HEADER), endlessDungeonManager:GetScore())
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(scoreNarration))

            -- Buffs Header
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_ENDLESS_DUNGEON_SUMMARY_BUFFS_HEADER)))

            -- Verses/Visions/Avatar Visions
            local numVerses, numNonAvatarVisions, numAvatarVisions = endlessDungeonManager:GetNumLifetimeVerseAndVisionStackCounts()
            local versesNarration = zo_strformat(SI_ENDLESS_DUNGEON_SUMMARY_STAT_VALUE_NARRATION, GetString(SI_ENDLESS_DUNGEON_SUMMARY_VERSES_HEADER), numVerses)
            local nonAvatarVisionsNarration = zo_strformat(SI_ENDLESS_DUNGEON_SUMMARY_STAT_VALUE_NARRATION, GetString(SI_ENDLESS_DUNGEON_SUMMARY_VISIONS_HEADER), numNonAvatarVisions)
            local avatarVisionsNarration = zo_strformat(SI_ENDLESS_DUNGEON_SUMMARY_STAT_VALUE_NARRATION, GetString(SI_ENDLESS_DUNGEON_SUMMARY_AVATAR_VISIONS_HEADER), numAvatarVisions)
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(versesNarration))
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(nonAvatarVisionsNarration))
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(avatarVisionsNarration))

            return narrations
        end,
    }
    SCREEN_NARRATION_MANAGER:RegisterCustomObject("EndlessDungeonSummary", narrationInfo)
end

function ZO_EndlessDungeonSummary:OnEndlessDungeonStateChanged(newState, oldState)
    -- Expectation: The first time we are inside an Endless Dungeon while it's complete after having been present for it ending and not being dead, we will force show the summary
    local wasActive = oldState == ZO_ENDLESS_DUNGEON_STATES.ACTIVE
    local isActive = newState == ZO_ENDLESS_DUNGEON_STATES.ACTIVE
    local isComplete = newState == ZO_ENDLESS_DUNGEON_STATES.COMPLETED

    if not isComplete then
        -- If we were planning on showing the summary, but managed to get into a new run, don't try to show the summary
        self.shouldShowSummary = false
    elseif wasActive and isComplete then
        -- If we are in a run and it goes from active to complete, intend to show the summary at first valid opportunity (not dead)
        self.shouldShowSummary = true
    elseif not isComplete and self:IsShowing() then
        SCENE_MANAGER:HideCurrentScene()
    end

    if self.shouldShowSummary then
        -- Don't try to show the summary until we're back to life
        if IsUnitDead("player") then
            self.control:RegisterForEvent(EVENT_PLAYER_ALIVE, ZO_GetEventForwardingFunction(self, self.OnPlayerAlive))
        else
            local PLAY_RUN_COMPLETE_SOUND = true
            self:Show(PLAY_RUN_COMPLETE_SOUND)
        end
    end
end

function ZO_EndlessDungeonSummary:OnPlatformStyleChanged()
    ZO_ApplyPlatformTemplateToControl(self.control, "ZO_EndDunSummary")

    ENDLESS_DUNGEON_SUMMARY_SCENE:RemoveFragmentGroup(FRAGMENT_GROUP.MOUSE_DRIVEN_UI_WINDOW_NO_KEYBIND_BACKGROUND_WINDOW)
    ENDLESS_DUNGEON_SUMMARY_SCENE:RemoveFragmentGroup(FRAGMENT_GROUP.GAMEPAD_DRIVEN_UI_NO_KEYBIND_BACKGROUND_WINDOW)

    if IsInGamepadPreferredMode() then
        ENDLESS_DUNGEON_SUMMARY_SCENE:AddFragmentGroup(FRAGMENT_GROUP.GAMEPAD_DRIVEN_UI_NO_KEYBIND_BACKGROUND_WINDOW)
    else
        ENDLESS_DUNGEON_SUMMARY_SCENE:AddFragmentGroup(FRAGMENT_GROUP.MOUSE_DRIVEN_UI_WINDOW_NO_KEYBIND_BACKGROUND_WINDOW)
    end
end

function ZO_EndlessDungeonSummary:OnPlayerAlive()
    -- If we became alive and had intended to show the summary and we're still inside the dungeon, show it
    if self.shouldShowSummary and ENDLESS_DUNGEON_MANAGER:GetState() == ZO_ENDLESS_DUNGEON_STATES.COMPLETED then
        local PLAY_RUN_COMPLETE_SOUND = true
        self:Show(PLAY_RUN_COMPLETE_SOUND)
    end
    self.control:UnregisterForEvent(EVENT_PLAYER_ALIVE)
end

function ZO_EndlessDungeonSummary:Show(playRunCompleteSound)
    SCENE_MANAGER:ShowSceneOrQueueForLoadingScreenDrop("endlessDungeonSummary")
    self.shouldShowSummary = false
    if playRunCompleteSound then
        PlaySound(SOUNDS.ENDLESS_DUNGEON_RUN_COMPLETE)
    end
end

function ZO_EndlessDungeonSummary:OnShowing()
    local endlessDungeonManager = ENDLESS_DUNGEON_MANAGER
    self.stageValueLabel:SetText(endlessDungeonManager:GetCurrentProgressionText())
    self.scoreValueLabel:SetText(endlessDungeonManager:GetScore())
    local numVerses, numNonAvatarVisions, numAvatarVisions = endlessDungeonManager:GetNumLifetimeVerseAndVisionStackCounts()
    self.versesValueLabel:SetText(numVerses)
    self.visionsValueLabel:SetText(numNonAvatarVisions)
    self.avatarVisionsValueLabel:SetText(numAvatarVisions)

    KEYBIND_STRIP:RemoveDefaultExit()
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)

    SCREEN_NARRATION_MANAGER:QueueCustomEntry("EndlessDungeonSummary")
end

function ZO_EndlessDungeonSummary:OnHiding()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
    KEYBIND_STRIP:RestoreDefaultExit()
end

function ZO_EndlessDungeonSummary.OnControlInitialized(control)
    ENDLESS_DUNGEON_SUMMARY = ZO_EndlessDungeonSummary:New(control)
end