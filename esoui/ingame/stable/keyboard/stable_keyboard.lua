STABLES_KEYBOARD_SCENE_IDENTIFIER = "stables_keyboard"
----------------
--Initialization
----------------

ZO_Stable_Keyboard = ZO_Stable_Base:Subclass()

function ZO_Stable_Keyboard:New(...)
    return ZO_Stable_Base.New(self, ...)
end

function ZO_Stable_Keyboard:Initialize(control)
    ZO_Stable_Base.Initialize(self, control, "stables")

    self:InitializeTabs()
end

function ZO_Stable_Keyboard:InitializeControls()
    STABLES_FRAGMENT = ZO_FadeSceneFragment:New(self.stableControl)

    self.instructions = self.stableControl:GetNamedChild("Instructions")
    self.instructions:SetText(zo_strformat(SI_STABLE_INTRUCTIONS, ZO_Currency_FormatKeyboard(CURT_MONEY, GetTrainingCost(), ZO_CURRENCY_FORMAT_WHITE_AMOUNT_ICON)))

    self.noSkinWarning = self.stableControl:GetNamedChild("NoSkinWarning")
    self.skillHeader = self.stableControl:GetNamedChild("RidingSkillHeader")

    self:RefreshActiveMount()

    self.speedRow = self.stableControl:GetNamedChild("SpeedTrainRow")
    self:SetupRow(self.speedRow, RIDING_TRAIN_SPEED)

    self.staminaRow = self.stableControl:GetNamedChild("StaminaTrainRow")
    self:SetupRow(self.staminaRow, RIDING_TRAIN_STAMINA)

    self.carryRow = self.stableControl:GetNamedChild("CarryTrainRow")
    self:SetupRow(self.carryRow, RIDING_TRAIN_CARRYING_CAPACITY)

    self.timerControl = self.stableControl:GetNamedChild("Timer")
    self.timerOverlayControl = self.timerControl:GetNamedChild("Overlay")
    self.timerText = self.timerControl:GetNamedChild("Text")

    self.money = self.stableControl:GetNamedChild("InfoBarMoney")

    local function OnTimerUpdate()
        local timeUntilCanBeTrained = GetTimeUntilCanBeTrained()
        if timeUntilCanBeTrained == 0 then
            self:UpdateMountInfo()
        else
            local timeLeft = ZO_FormatTimeMilliseconds(timeUntilCanBeTrained, TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_TWELVE_HOUR)
            self.timerText:SetText(timeLeft)
            if self.timerControl.mouseInside then
                InformationTooltip:ClearLines()
                SetTooltipText(InformationTooltip, zo_strformat(SI_STABLE_NOT_TRAINABLE_TOOLTIP, timeLeft))
            end
        end
    end

    self.timerControl:SetHandler("OnUpdate", OnTimerUpdate)
end

function ZO_Stable_Keyboard:InitializeEvents()
    ZO_Stable_Base.InitializeEvents(self)

    local STABLES_INTERACTION =
    {
        type = "Stable",
        End =   function()
                    if not self:IsPreferredScreen() then
                        self:SetHidden(true)
                    end
                end,
        interactTypes = { INTERACTION_STABLE },
    }

    STABLES_SCENE = ZO_InteractScene:New("stables", SCENE_MANAGER, STABLES_INTERACTION)

    local function OnStateChanged(oldState, newState)
        if newState == SCENE_SHOWING then
            STORE_WINDOW:InitializeStore(ZO_STORE_WINDOW_MODE_STABLE)

            local initialFragment = HasMountSkin() and SI_STABLE_STABLES_TAB or SI_STORE_MODE_BUY
            self.modeBar:SelectFragment(initialFragment)

            self:RegisterUpdateEvents()
            self:UpdateMountInfo()
            self:UpdateStrips()
        elseif newState == SCENE_HIDDEN then
            self:UnregisterUpdateEvents()
            self.modeBar:Clear()

            if GetCursorContentType() == MOUSE_CONTENT_STORE_ITEM then 
                ClearCursor()
            end
        end
    end
    STABLES_SCENE:RegisterCallback("StateChange", OnStateChanged)
end

local NO_LEADING_EDGE = false
local FORCE_VALUE = true

function ZO_Stable_Keyboard:InitializeTabs()
    local function CreateButtonData(normal, pressed, highlight, clickSound, tutorialTrigger)
        return {
            normal = normal,
            pressed = pressed,
            highlight = highlight,
            clickSound = clickSound,
            callback = function()
                TriggerTutorial(tutorialTrigger)
            end
        }
    end
    
    self.modeBar = ZO_SceneFragmentBar:New(ZO_StableWindowMenuBar)

    --Buy Button
    local buyButtonData = CreateButtonData("EsoUI/Art/Vendor/vendor_tabIcon_buy_up.dds",
                                            "EsoUI/Art/Vendor/vendor_tabIcon_buy_down.dds",
                                            "EsoUI/Art/Vendor/vendor_tabIcon_buy_over.dds",
                                            SOUNDS.STABLE_WINDOW_BUY_CLICKED,
                                            TUTORIAL_TRIGGER_STORE_OPENED)
    self.modeBar:Add(SI_STORE_MODE_BUY, { STORE_FRAGMENT }, buyButtonData)

    --Stables Button
    local stablesButtonData = CreateButtonData("EsoUI/Art/Mounts/tabIcon_ridingSkills_up.dds",
                                               "EsoUI/Art/Mounts/tabIcon_ridingSkills_down.dds",
                                               "EsoUI/Art/Mounts/tabIcon_ridingSkills_over.dds",
                                               SOUNDS.STABLE_WINDOW_MANAGE_CLICKED,
                                               TUTORIAL_TRIGGER_RIDING_SKILL_MANAGEMENT_OPENED)
    self.modeBar:Add(SI_STABLE_STABLES_TAB, { STABLES_FRAGMENT }, stablesButtonData)
end

-----------------
--Class Functions
-----------------

function ZO_Stable_Keyboard:RefreshActiveMount()
    local currentSkinId = GetMountSkinId()
    local hadSkin = self.currentSkinId and self.currentSkinId > 0
    local hasSkin = currentSkinId > 0
    --If you have a skin, the warning control should be hidden
    if hadSkin ~= hasSkin then
        self.currentSkinId = currentSkinId
        self.noSkinWarning:SetHidden(hasSkin)
        properAnchorControl = hasSkin and self.instructions or self.noSkinWarning
        self.skillHeader:ClearAnchors()
        self.skillHeader:SetAnchor(TOPLEFT, properAnchorControl, BOTTOMLEFT, 0, 20)
        self.skillHeader:SetAnchor(TOPRIGHT, properAnchorControl, BOTTOMRIGHT, 0, 20)
    end
end

function ZO_Stable_Keyboard:UpdateMountInfo()
    local speedBonus, maxSpeedBonus, staminaBonus, maxStaminaBonus, inventoryBonus, maxInventoryBonus = STABLE_MANAGER:GetStats()
    
    self.speedRow.value:SetText(zo_strformat(SI_MOUNT_ATTRIBUTE_SPEED_FORMAT, speedBonus))
    ZO_StatusBar_SmoothTransition(self.speedRow.bar, speedBonus, maxSpeedBonus, FORCE_VALUE)

    self.staminaRow.value:SetText(staminaBonus)
    ZO_StatusBar_SmoothTransition(self.staminaRow.bar, staminaBonus, maxStaminaBonus, FORCE_VALUE)

    self.carryRow.value:SetText(inventoryBonus)
    ZO_StatusBar_SmoothTransition(self.carryRow.bar, inventoryBonus, maxInventoryBonus, FORCE_VALUE)

    ZO_StablesTrainButton_Refresh(self.speedRow.trainButton, (speedBonus < maxSpeedBonus))
    ZO_StablesTrainButton_Refresh(self.staminaRow.trainButton, (staminaBonus < maxStaminaBonus))
    ZO_StablesTrainButton_Refresh(self.carryRow.trainButton, (inventoryBonus < maxInventoryBonus))
    
    local timeUntilCanBeTrained, totalTrainWaitDuration = GetTimeUntilCanBeTrained()
    if timeUntilCanBeTrained == 0 or STABLE_MANAGER:IsRidingSkillMaxedOut() then
        self.timerControl:SetHidden(true)
    else
        self.timerControl:SetHidden(false)
        self.timerOverlayControl:StartCooldown(timeUntilCanBeTrained, totalTrainWaitDuration, CD_TYPE_RADIAL, CD_TIME_TYPE_TIME_UNTIL, NO_LEADING_EDGE)
    end
end

function ZO_Stable_Keyboard:UpdateStrips()
    ZO_CurrencyControl_SetSimpleCurrency(self.money, CURT_MONEY, STABLE_MANAGER.currentMoney, ZO_KEYBOARD_CURRENCY_OPTIONS, nil, not STABLE_MANAGER:CanAffordTraining())
end

function ZO_Stable_Keyboard:IsPreferredScreen()
    return not IsInGamepadPreferredMode()
end

function ZO_Stable_Keyboard:SetupRow(control, trainingType)
    ZO_Stable_Base.SetupRow(self, control, trainingType)

    if control.trainButton then
        local texture = STABLE_TRAINING_TEXTURES[trainingType]
        control.icon:SetTexture(texture)
    end
end

------------------
--Global Functions
------------------

function ZO_Stable_Keyboard_Initialize(control)
    STABLE = ZO_Stable_Keyboard:New(control)
end
