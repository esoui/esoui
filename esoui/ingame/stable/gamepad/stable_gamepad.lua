------------------
--Initialization--
------------------

ZO_Stable_Gamepad = ZO_Object.MultiSubclass(ZO_Stable_Base, ZO_GamepadStoreListComponent)

function ZO_Stable_Gamepad:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_Stable_Gamepad:Initialize(control)
    ZO_GamepadStoreListComponent.Initialize(self, STORE_WINDOW_GAMEPAD, ZO_MODE_STORE_STABLE, GetString(SI_STABLE_STABLES_TAB), "ZO_StableTrainingRow_Gamepad", ZO_ParametricScrollList_DefaultMenuEntryWithHeaderSetup, "StableRow", "StableRowHeader")
    ZO_Stable_Base.Initialize(self, control, GAMEPAD_STORE_SCENE_NAME)

    self.fragment:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            self:RegisterUpdateEvents()
            self:UpdateMountInfo()
            self.stableControl:SetHidden(false)
            TriggerTutorial(TUTORIAL_TRIGGER_RIDING_SKILL_MANAGEMENT_OPENED)
        elseif newState == SCENE_HIDING then
            self:UnregisterUpdateEvents()
            self.stableControl:SetHidden(true)
            GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
        end
    end)

    self:InitializeKeybindStrip()
    self:CreateModeData(SI_STABLE_STABLES_TAB, ZO_MODE_STORE_STABLE, "EsoUI/Art/Vendor/tabIcon_mounts_up.dds", self.fragment, self.keybindStripDescriptor)
end

function ZO_Stable_Gamepad:InitializeControls()
    ZO_Stable_Base.InitializeControls(self)

    self.notifications = self.stableControl:GetNamedChild("Notifications")
    self.warning = self.notifications:GetNamedChild("NoSkinWarning")
    local listControl = self.list:GetControl()
    listControl:SetAnchor(TOPLEFT, self.notifications, BOTTOMLEFT)
end

function ZO_Stable_Gamepad:InitializeKeybindStrip()
    -- Riding skill train screen keybind
    self.keybindStripDescriptor = {}

    ZO_Gamepad_AddForwardNavigationKeybindDescriptors(self.keybindStripDescriptor,
                                                    GAME_NAVIGATION_TYPE_BUTTON,
                                                    function() self:TrainSelected() end, --callback
                                                    GetString(SI_GAMEPAD_STABLE_TRAIN), --name
                                                    function() return self:CanTrainSelected() end) --visible

    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON)
end

function ZO_Stable_Gamepad:HeaderMessageNarration()
    if not HasMountSkin() then
        return GetString(SI_STABLE_NO_ACTIVE_MOUNT_WARNING)
    else
        return ""
    end
end

-----------------
--Class Functions
-----------------
function ZO_Stable_Gamepad:UpdateMountInfo()
    self:RefreshActiveMount()
    self.list:UpdateList()
    KEYBIND_STRIP:UpdateCurrentKeybindButtonGroups()
end

function ZO_Stable_Gamepad:RefreshActiveMount()
    self.warning:SetHidden(HasMountSkin())
end

function ZO_Stable_Gamepad:CanTrainSelected()
    local selectedData = self.list:GetTargetData()
    return selectedData and selectedData.trainingData.isSkillTrainable
end

function ZO_Stable_Gamepad:TrainSelected()
    local targetControl = self.list:GetTargetControl()
    if targetControl then
        ZO_Stable_TrainButtonClicked(targetControl)

        local NARRATE_HEADER = true
        SCREEN_NARRATION_MANAGER:QueueParametricListEntry(self.list, NARRATE_HEADER)
    end
end

function ZO_Stable_Gamepad:SetupEntry(control, data, selected, selectedDuringRebuild, enabled, activated)
    local trainingData = data.trainingData

    data.isSkillTrainable = trainingData.isSkillTrainable
    ZO_SharedGamepadEntry_OnSetup(control, data, selected, selectedDuringRebuild, enabled, activated)

    self:SetupRow(control, trainingData.trainingType)
    local bonusLabelFormat = SI_MOUNT_ATTRIBUTE_SIMPLE_FORMAT
    if trainingData.trainingType == RIDING_TRAIN_SPEED then
        bonusLabelFormat = SI_MOUNT_ATTRIBUTE_SPEED_FORMAT
    end
    control.value:SetText(zo_strformat(bonusLabelFormat, trainingData.bonus))
end

function ZO_Stable_Gamepad:OnSelectedItemChanged(data)
    GAMEPAD_TOOLTIPS:ClearLines(GAMEPAD_LEFT_TOOLTIP)
    if data then
        local trainingData = data.trainingData
        GAMEPAD_TOOLTIPS:LayoutRidingSkill(GAMEPAD_LEFT_TOOLTIP, trainingData.trainingType, trainingData.bonus, trainingData.maxBonus)
    end
    KEYBIND_STRIP:UpdateCurrentKeybindButtonGroups()
end

function ZO_Stable_Gamepad:IsPreferredScreen()
    return IsInGamepadPreferredMode()
end

function ZO_Stable_Gamepad:SetHidden(hidden)
    if not hidden and STABLE_GAMEPAD then
        local componentTable = { ZO_MODE_STORE_BUY, ZO_MODE_STORE_STABLE }
        STORE_WINDOW_GAMEPAD:SetActiveComponents(componentTable, "storeTextSearch")
        if HasMountSkin() then
            STORE_WINDOW_GAMEPAD:SetDeferredStartingMode(ZO_MODE_STORE_STABLE)
        end
    end
    ZO_Stable_Base.SetHidden(self, hidden)
end

function ZO_Stable_Gamepad:SetupRow(control, trainingType)
    ZO_Stable_Base.SetupRow(self, control, trainingType)

    if control.trainButton then
        local texture = STABLE_TRAINING_TEXTURES_GAMEPAD[trainingType]
        control.icon:SetTexture(texture)
    end
end

------------------
--Global Functions
------------------

function ZO_Stable_Gamepad_Initialize(control)
    STABLE_GAMEPAD = ZO_Stable_Gamepad:New(control)
    STORE_WINDOW_GAMEPAD:AddComponent(STABLE_GAMEPAD)
end