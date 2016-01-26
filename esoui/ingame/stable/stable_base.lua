
----------------
--Initialization
----------------

ZO_Stable_Base = ZO_Object:Subclass()

function ZO_Stable_Base:New(...)
    local stables = ZO_Object.New(self)
    stables:Initialize(...)
    return stables
end

function ZO_Stable_Base:Initialize(control, sceneIdentifier)
    self.stableControl = control
    self.sceneIdentifier = sceneIdentifier

    self:InitializeControls()
    self:InitializeEvents()
end

function ZO_Stable_Base:InitializeControls()
    --Stubbed; to be overriden
end

function ZO_Stable_Base:InitializeEvents()
    STABLE_MANAGER:RegisterCallback("StableInteractStart", function() self:OnStablesInteractStart() end)
    STABLE_MANAGER:RegisterCallback("StableInteractEnd", function() self:OnStablesInteractEnd() end)
    STABLE_MANAGER:RegisterCallback("StableMountInfoUpdated", function() self:OnMountInfoUpdate() end)
    STABLE_MANAGER:RegisterCallback("ActiveMountChanged", function() self:OnActiveMountChanged() end)
end

function ZO_Stable_Base:RegisterUpdateEvents()
    STABLE_MANAGER:RegisterCallback("StableMoneyUpdate", function() self:OnMoneyUpdated() end)
end

function ZO_Stable_Base:UnregisterUpdateEvents()
    STABLE_MANAGER:UnregisterCallback("StableMoneyUpdate")
end

-----------------
--Events Handlers
-----------------

function ZO_Stable_Base:OnStablesInteractStart()
    if self:IsPreferredScreen() then
        self:SetHidden(false)
        self:UpdateMountInfo()
    end
end

function ZO_Stable_Base:OnStablesInteractEnd()
    self:SetHidden(true)
end

function ZO_Stable_Base:OnMoneyUpdated()
    self:UpdateMountInfo()
    self:UpdateStrips()
end

function ZO_Stable_Base:OnMountInfoUpdate()
    self:UpdateMountInfo()
end

function ZO_Stable_Base:OnActiveMountChanged()
    self:RefreshActiveMount()
end
--------------------
--Instance Methods--
--------------------

function ZO_Stable_Base:UpdateMountInfo()
    --Stubbed; to be overriden
end

function ZO_Stable_Base:UpdateStrips()
    --Stubbed; to be overriden
end

function ZO_Stable_Base:IsPreferredScreen()
    --Stubbed; to be overriden
end

function ZO_Stable_Base:RefreshActiveMount()
    --Stubbed; to be overriden
end

function ZO_Stable_Base:SetHidden(hidden)
    if self.sceneIdentifier then
        if hidden then
            SCENE_MANAGER:Hide(self.sceneIdentifier)
        else
            SCENE_MANAGER:Show(self.sceneIdentifier)
        end
    end
end

function ZO_Stable_Base:SetupRow(control, trainingType)
    control.trainingType = trainingType
    control.trainingSound = STABLE_TRAINING_SOUNDS[trainingType]
    if control.trainButton then
        control.trainButton.trainingType = trainingType
        control.trainButton.trainingSound = control.trainingSound
    end
    control.label:SetText(GetString("SI_RIDINGTRAINTYPE", trainingType))
    ZO_StatusBar_SetGradientColor(control.bar, ZO_XP_BAR_GRADIENT_COLORS)
end

--------------------
--Global Functions--
--------------------

function ZO_StablesTrainButton_Refresh(control, canTypeBeTrained)
    local timeUntilCanBeTrained = GetTimeUntilCanBeTrained()
    control:SetHidden(not (canTypeBeTrained and timeUntilCanBeTrained == 0 and STABLE_MANAGER:CanAffordTraining()))
end

function ZO_Stable_TrainButtonClicked(control)
    PlaySound(control.trainingSound)
    TrainRiding(control.trainingType)
end

function ZO_StableTrainingRow_Init(control)
    control.label = control:GetNamedChild("Label")
    control.trainButton = control:GetNamedChild("TrainButton")
    control.icon = control:GetNamedChild("Icon")
    local barContainer = control:GetNamedChild("BarContainer")
    control.bar = barContainer:GetNamedChild("StatusBar"):GetNamedChild("Bar")
    control.value = barContainer:GetNamedChild("Value")
end
