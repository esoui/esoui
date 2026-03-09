------------------------------
-- Adventure Zone Boss Tree --
------------------------------

ZO_AdventureZoneBossTree_Shared = ZO_DeferredInitializingObject:Subclass()

function ZO_AdventureZoneBossTree_Shared:Initialize(control)
    self.control = control
    control.object = self

    local scene = ZO_Scene:New(self:GetSceneName(), SCENE_MANAGER)
    self.scene = scene
    self.fragment = ZO_FadeSceneFragment:New(control)
    scene:AddFragment(self.fragment)

    self.bossContainer = self.control:GetNamedChild("BossContainer")
    self.easyContainer = self.bossContainer:GetNamedChild("EasyContainer")
    self.mediumContainer = self.bossContainer:GetNamedChild("MediumContainer")
    self.hardContainer = self.bossContainer:GetNamedChild("HardContainer")

    self.bossControls =
    {
        [ADVENTURE_ZONE_BOSS_SKITTERING_WORLD_BOSS_1] = self.easyContainer:GetNamedChild("BossEasy1"),

        [ADVENTURE_ZONE_BOSS_SKITTERING_WORLD_BOSS_2] = self.easyContainer:GetNamedChild("BossEasy2"),

        [ADVENTURE_ZONE_BOSS_SORROWS_FRIEND_WORLD_BOSS_1] = self.easyContainer:GetNamedChild("BossEasy3"),

        [ADVENTURE_ZONE_BOSS_SORROWS_FRIEND_WORLD_BOSS_2] = self.easyContainer:GetNamedChild("BossEasy4"),

        [ADVENTURE_ZONE_BOSS_PARCH_WORLD_BOSS_1] = self.easyContainer:GetNamedChild("BossEasy5"),

        [ADVENTURE_ZONE_BOSS_PARCH_WORLD_BOSS_2] = self.easyContainer:GetNamedChild("BossEasy6"),

        [ADVENTURE_ZONE_BOSS_SKITTERING_INSTANCE_BOSS] = self.mediumContainer:GetNamedChild("BossMedium1"),

        [ADVENTURE_ZONE_BOSS_SORROWS_FRIEND_INSTANCE_BOSS] = self.mediumContainer:GetNamedChild("BossMedium2"),

        [ADVENTURE_ZONE_BOSS_PARCH_INSTANCE_BOSS] = self.mediumContainer:GetNamedChild("BossMedium3"),

        [ADVENTURE_ZONE_BOSS_TRIAL_BOSS] = self.hardContainer:GetNamedChild("BossHard"),
    }

    for boss, bossControl in pairs(self.bossControls) do
        bossControl.boss = boss
    end

    ZO_DeferredInitializingObject.Initialize(self, scene)
end

function ZO_AdventureZoneBossTree_Shared:OnDeferredInitialize()
    self:InitializeKeybindStripDescriptor()

    for boss, bossControl in pairs(self.bossControls) do
        bossControl.highlightTexture = bossControl:GetNamedChild("Highlight")
        bossControl.highlightAnimation = GetAnimationManager():CreateTimelineFromVirtual("ZO_AdvZone_HighlightFadeAnimation")
        bossControl.highlightAnimation:ApplyAllAnimationsToControl(bossControl.highlightTexture)
    end
end

function ZO_AdventureZoneBossTree_Shared:InitializeKeybindStripDescriptor()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,
        {
            name = GetString(SI_ADVENTURE_ZONE_VIEW_OVERVIEW_PANEL),
            keybind = "UI_SHORTCUT_TERTIARY",
            callback = function()
                SYSTEMS:ShowScene("adventureZoneOverview")
            end,
        },

        {
            name = GetString(SI_ADVENTURE_ZONE_VIEW_SHOW_ON_MAP),
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                ShowAdventureZoneBossOnMap(self.selectedBoss)
            end,
            visible = function()
                return self.selectedBoss and GetAdventureZoneBossState(self.selectedBoss) == ADVENTURE_ZONE_BOSS_STATE_AVAILABLE
            end,
        },

        {
            name = GetString(SI_DIALOG_CLOSE),
            keybind = "TOGGLE_ACTIVITY_HUD_TRACKER",
        },
    }
end

function ZO_AdventureZoneBossTree_Shared:OnShowing()
    self:RefreshBosses()

    PlaySound(SOUNDS.ADVENTURE_ZONE_BOSS_TREE_OPENED)
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
    KEYBIND_STRIP:RemoveDefaultExit()

    ADVENTURE_ZONE_MANAGER:SetPanelToOpen(ZO_ADVENTURE_ZONE_PANELS.BOSS_TREE)
end

function ZO_AdventureZoneBossTree_Shared:OnHiding()
    PlaySound(SOUNDS.ADVENTURE_ZONE_BOSS_TREE_CLOSED)
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_AdventureZoneBossTree_Shared:OnHidden()
    KEYBIND_STRIP:RestoreDefaultExit()
end

function ZO_AdventureZoneBossTree_Shared:IsShowing()
    return self.scene:IsShowing()
end

function ZO_AdventureZoneBossTree_Shared:RefreshBosses()
    for boss, bossControl in pairs(self.bossControls) do
        local bossState = GetAdventureZoneBossState(boss)
        local bossIcon = bossState == ADVENTURE_ZONE_BOSS_STATE_DEFEATED and GetAdventureZoneBossKeyFragmentIconFileIndex(boss) or GetAdventureZoneBossIconFileIndex(boss)
        local desaturation = ZO_AdventureZoneBossTree_Shared.HasBossBeenBeaten(boss) and 0 or 1
        local bossIconControl = bossControl:GetNamedChild("Icon")
        bossIconControl:SetTexture(bossIcon)
        bossIconControl:SetDesaturation(desaturation)
        local isBossAvailable = bossState == ADVENTURE_ZONE_BOSS_STATE_AVAILABLE
        if isBossAvailable then
            bossControl.highlightAnimation:PlayFromStart()
        else
            bossControl.highlightAnimation:PlayInstantlyToEnd()
        end
        bossControl.highlightTexture:SetHidden(not isBossAvailable)

        -- This should only matter for values greater than ADVENTURE_ZONE_BOSS_PARCH_WORLD_BOSS_2
        -- but base it on the presence of the control in case enums change their order for some reason.
        local keyIcon = bossControl:GetNamedChild("KeyIcon")
        if keyIcon then
            keyIcon:SetTexture(GetAdventureZoneBossKeyIconFileIndex(boss))
            keyIcon:SetHidden(bossState ~= ADVENTURE_ZONE_BOSS_STATE_AVAILABLE)
        end
    end
end

function ZO_AdventureZoneBossTree_Shared:UpdateKeybinds()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_AdventureZoneBossTree_Shared.HasBossBeenBeaten(boss)
    local achievementId, criterionIndex = GetAdventureZoneBossAchievementInfo(boss)
    if achievementId > 0 then
        local _, numCompleted, numRequired = GetAchievementCriterion(achievementId, criterionIndex)
        return numCompleted == numRequired
    end
    return false
end

ZO_AdventureZoneBossTree_Shared:MUST_IMPLEMENT("GetSceneName")