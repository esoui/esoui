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
    ZO_GamepadStoreListComponent.Initialize(self, STORE_WINDOW_GAMEPAD, ZO_MODE_STORE_STABLE, GetString(SI_STABLE_STABLES_TAB), "ZO_StableTrainingRow_Gamepad", ZO_ParametricScrollList_DefaultMenuEntryWithHeaderSetup)
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
    self:CreateModeData(SI_STABLE_STABLES_TAB, ZO_MODE_STORE_STABLE, "EsoUI/Art/Vendor/tabIcon_mounts_up.dds", fragment, self.keybindStripDescriptor)
end

function ZO_Stable_Gamepad:InitializeControls()
    ZO_Stable_Base.InitializeControls(self)

    self.notifications = self.stableControl:GetNamedChild("Notifications")
    self.trainableHeader = self.notifications:GetNamedChild("TrainableHeader")
    self.trainableReady = self.notifications:GetNamedChild("TrainableReady")
    self.timerText = self.notifications:GetNamedChild("TrainableTimer")
    self.warning = self.notifications:GetNamedChild("NoSkinWarning")
    local listControl = self.list:GetControl()
    listControl:SetAnchor(TOPLEFT, self.notifications, BOTTOMLEFT)

    local function OnTimerUpdate()
        local timeUntilCanBeTrained = GetTimeUntilCanBeTrained()
        if timeUntilCanBeTrained == 0 then
            self:UpdateMountInfo()
        else
            self.timerText:SetText(ZO_FormatTimeMilliseconds(timeUntilCanBeTrained, TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_TWELVE_HOUR))
        end
    end

    self.timerText:SetHandler("OnUpdate", OnTimerUpdate)
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

-----------------
--Class Functions
-----------------
function ZO_Stable_Gamepad:UpdateMountInfo()
    local ridingSkillMaxedOut = STABLE_MANAGER:IsRidingSkillMaxedOut()
    local hideTimer = GetTimeUntilCanBeTrained() == 0
    self.trainableHeader:SetHidden(ridingSkillMaxedOut)
    self.timerText:SetHidden(ridingSkillMaxedOut or hideTimer)
    self.trainableReady:SetHidden(ridingSkillMaxedOut or not hideTimer)
    self:RefreshActiveMount()
    self.list:UpdateList()
    KEYBIND_STRIP:UpdateCurrentKeybindButtonGroups()
end

function ZO_Stable_Gamepad:RefreshActiveMount()
    self.warning:SetHidden(HasMountSkin())
end

function ZO_Stable_Gamepad:CanTrainSelected()
    local selectedData = self.list:GetTargetData()
    return selectedData and selectedData.data.isSkillTrainable
end

function ZO_Stable_Gamepad:TrainSelected()
    local targetControl = self.list:GetTargetControl()
    if targetControl then
        ZO_Stable_TrainButtonClicked(targetControl)
    end
end

local FORCE_VALUE = true
function ZO_Stable_Gamepad:SetupEntry(control, data, selected, selectedDuringRebuild, enabled, activated)
    data.isSkillTrainable = data.data.isSkillTrainable
    ZO_SharedGamepadEntry_OnSetup(control, data, selected, selectedDuringRebuild, enabled, activated)
    
    local trainData = data.data
    self:SetupRow(control, trainData.trainingType)
    local bonusLabel = trainData.bonus
    if trainData.trainingType == RIDING_TRAIN_SPEED then
        bonusLabel = zo_strformat(SI_MOUNT_ATTRIBUTE_SPEED_FORMAT, trainData.bonus)
    end
    control.value:SetText(bonusLabel)
    ZO_StatusBar_SmoothTransition(control.bar, trainData.bonus, trainData.maxBonus, FORCE_VALUE)
end

function ZO_Stable_Gamepad:OnSelectedItemChanged(data)
    GAMEPAD_TOOLTIPS:ClearLines(GAMEPAD_LEFT_TOOLTIP)
    if data then
        local trainData = data.data
        GAMEPAD_TOOLTIPS:LayoutRidingSkill(GAMEPAD_LEFT_TOOLTIP, trainData.trainingType, trainData.bonus, trainData.maxBonus)
    end
    KEYBIND_STRIP:UpdateCurrentKeybindButtonGroups()
end

function ZO_Stable_Gamepad:IsPreferredScreen()
    return IsInGamepadPreferredMode()
end

function ZO_Stable_Gamepad:SetHidden(hidden)
    if not hidden and STABLE_GAMEPAD then
        local componentTable = {ZO_MODE_STORE_BUY, ZO_MODE_STORE_STABLE}
        STORE_WINDOW_GAMEPAD:SetActiveComponents(componentTable)
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