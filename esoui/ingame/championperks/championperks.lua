local SKY_CLOUD_DEPTH = -0.3
local CLOSE_CLOUDS_DEPTH = 0
local STAR_SPIRAL_START_DEPTH = 1
local STAR_SPIRAL_END_DEPTH = 1.3
local MEDIUM_STAR_CLUSTER_DEPTH = 1.3
local LARGE_STAR_CLUSTER_DEPTH = 1.5
local SMALL_STAR_CLUSTER_DEPTH = 1.6
local CENTER_INFO_BG_DEPTH = 1.65
local CONSTELLATIONS_DEPTH = 1.69
local SMOKE_DEPTH = 1.7
local CLOUDS_DEPTH = 1.71
local CONSTELLATIONS_DARKNESS_DEPTH = 1.72
local COLOR_CLOUDS_DEPTH = 2.32
local SKY_DEPTH = 5

local ZOOMED_IN_CAMERA_Z = 0.9
local ZOOMED_IN_CAMERA_Y = 1035
local ZOOMED_OUT_CAMERA_Z = -1.2
--Champion computes all of its sizes off of a reference camera depth of -1 since it uses two camera levels. What the reference depth is doesn't really matter,
--it's just important that it stays constant so we can use one measurement system at both zoom levels.
ZO_CHAMPION_REFERENCE_CAMERA_Z = -1

do
    local ATTRIBUTE_TO_CONSTELLATION_GROUP_NAME =
    {
        [ATTRIBUTE_HEALTH] = zo_strformat(SI_CHAMPION_CONSTELLATION_GROUP_NAME_FORMAT, GetString(SI_CHAMPION_CONSTELLATION_GROUP_HEALTH_NAME)),
        [ATTRIBUTE_MAGICKA] = zo_strformat(SI_CHAMPION_CONSTELLATION_GROUP_NAME_FORMAT, GetString(SI_CHAMPION_CONSTELLATION_GROUP_MAGICKA_NAME)),
        [ATTRIBUTE_STAMINA] = zo_strformat(SI_CHAMPION_CONSTELLATION_GROUP_NAME_FORMAT, GetString(SI_CHAMPION_CONSTELLATION_GROUP_STAMINA_NAME)),
    }

    function ZO_Champion_GetConstellationGroupNameFromAttribute(attribute)
        return ATTRIBUTE_TO_CONSTELLATION_GROUP_NAME[attribute]
    end
end

do
    local ATTRIBUTE_TO_CONSTELLATION_GROUP_NAME =
    {
        [ATTRIBUTE_HEALTH] = GetString(SI_CHAMPION_CONSTELLATION_GROUP_HEALTH_NAME),
        [ATTRIBUTE_MAGICKA] = GetString(SI_CHAMPION_CONSTELLATION_GROUP_MAGICKA_NAME),
        [ATTRIBUTE_STAMINA] = GetString(SI_CHAMPION_CONSTELLATION_GROUP_STAMINA_NAME),
    }

    function ZO_Champion_GetUnformattedConstellationGroupNameFromAttribute(attribute)
        return ATTRIBUTE_TO_CONSTELLATION_GROUP_NAME[attribute]
    end
end

local CHAMPION_ATTRIBUTES = { ATTRIBUTE_HEALTH, ATTRIBUTE_STAMINA, ATTRIBUTE_MAGICKA }

--Champion Perks
----------------------

local ChampionPerks = ZO_Object:Subclass()

local STATE_ZOOMED_OUT = "zoomedOut"
local STATE_ZOOMED_IN = "zoomedIn"
local STATE_ZOOMING_IN = "zoomingIn"
local STATE_ZOOMING_OUT = "zoomingOut"
local STATE_ENTERING = "entering"

local VISUAL_STYLE_KEYBOARD = 1
local VISUAL_STYLE_GAMEPAD = 2

function ChampionPerks:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ChampionPerks:Initialize(control)
    self.control = control
    self.canvasControl = self.control:GetNamedChild("Canvas")

    self.initialized = false
    self.dirty = false
    self.isChampionSystemNew = false
    SetChampionMusicActive(false)
    SetShouldRenderWorld(true)
    self:SetupCustomConfirmDialog()

    --for menu indicators / conditional button showing
    self:RegisterEvents()
    self:RefreshUnspentPoints()

    self.starTextControlPool = ZO_ControlPool:New("ZO_ChampionStarText", self.canvasControl)
    self.starTextControlPool:SetCustomFactoryBehavior(function(control)
        control.pointsSpinner:SetSounds(SOUNDS.CHAMPION_SPINNER_UP, SOUNDS.CHAMPION_SPINNER_DOWN)
    end)
    self.starTextControlPool:SetCustomAcquireBehavior(function(control)
        local spinnerControl = control.pointsSpinner:GetControl()
        local increaseButton = spinnerControl:GetNamedChild("Increase")
        local decreaseButton = spinnerControl:GetNamedChild("Decrease")

        if SCENE_MANAGER:IsCurrentSceneGamepad() then
            control.nameLabel:SetFont("ZoFontGamepad34")
            control.pointsSpinner:SetFont("ZoFontGamepad42")
            spinnerControl:SetDimensions(120, 55)
        else
            control.nameLabel:SetFont("ZoFontWinH3")
            control.pointsSpinner:SetFont("ZoFontWinH2")
            spinnerControl:SetDimensions(100, 36)
        end
    end)
    --Pre-fill the pool because it take a long time to make these things
    --Three times the max numbers of stars in a constellation
    for i = 1, 3 * 8 do
        self.starTextControlPool:AcquireObject()
    end
    self.starTextControlPool:ReleaseAllObjects()

    self.inactiveAlert = self.control:GetNamedChild("InactiveAlert")

    self.chosenAttributeTypePointCounter = ZO_ChampionPerksChosenAttributePointCounter
    CHAMPION_PERKS_CHOSEN_ATTRIBUTE_TYPE_POINT_COUNTER_FRAGMENT = ZO_SimpleSceneFragment:New(self.chosenAttributeTypePointCounter)
    CHAMPION_PERKS_CHOSEN_ATTRIBUTE_TYPE_POINT_COUNTER_FRAGMENT:SetConditional(function()
        return self.state == STATE_ZOOMED_IN
    end)

    self.chosenAttributeTypeEarnedPointCounter = ZO_ChampionPerksChosenAttributeEarnedPointCounter
    CHAMPION_PERKS_CHOSEN_ATTRIBUTE_TYPE_EARNED_POINT_COUNTER_FRAGMENT = ZO_SimpleSceneFragment:New(self.chosenAttributeTypeEarnedPointCounter)
    CHAMPION_PERKS_CHOSEN_ATTRIBUTE_TYPE_EARNED_POINT_COUNTER_FRAGMENT:SetConditional(function()
        return self.state == STATE_ZOOMED_IN
    end)

    self.gamepadChosenConstellationControl = self.control:GetNamedChild("ChosenConstellationGamepad")
    local ALWAYS_ANIMATE = true
    self.gamepadChosenConstellationFragment = ZO_FadeSceneFragment:New(self.gamepadChosenConstellationControl, ALWAYS_ANIMATE)

    local function SharedStateChangeCallback(oldState, newState)
        if newState == SCENE_SHOWING then
            self.prevTimeSecs = nil
            self:PerformDeferredInitializationShared()
            self.ring:SetAngle(math.pi * 0.5)
            self:PlayEnterAnimation()
            SetShouldRenderWorld(false)
            self.centerAlphaInterpolator:SetCurrentValue(0)
            self.centerInfo:SetAlpha(0)
            self.radialSelectorTexture:SetAlpha(0)
            self:RefreshApplicableSharedKeybinds()

            self:SetChampionSystemNew(false)

            self.lastHealthValue = GetUnitPower("player", POWERTYPE_HEALTH)
            self.control:RegisterForEvent(EVENT_POWER_UPDATE, function(...) self:OnPowerUpdate(...) end)
        elseif newState == SCENE_SHOWN then
            SetChampionMusicActive(true)
            TriggerTutorial(TUTORIAL_TRIGGER_CHAMPION_UI_SHOWN)
        elseif newState == SCENE_HIDING then
            SetChampionMusicActive(false)
            SetShouldRenderWorld(true)
        elseif newState == SCENE_HIDDEN then
            if self:HasUnsavedChanges() and AreChampionPointsActive() then
                ZO_Alert(UI_ALERT_CATEGORY_ALERT, SOUNDS.NEGATIVE_CLICK, GetString(SI_CHAMPION_UNSAVED_CHANGES_EXIT_ALERT))
            end
            self:ResetToZoomedOut()
            self:RemoveSharedKeybinds()
            self:RemoveInputTypeKeybinds()
            KEYBIND_STRIP:PopKeybindGroupState()
            
            self:SetSelectedConstellation(nil)
            self.control:UnregisterForEvent(EVENT_POWER_UPDATE)
            self.lastHealthValue = nil
        end
    end

    CHAMPION_PERKS_SCENE = ZO_Scene:New("championPerks", SCENE_MANAGER)
    CHAMPION_PERKS_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        SharedStateChangeCallback(oldState, newState)
        if newState == SCENE_SHOWING then
            self:PerformDeferredInitializationKeyboard()
            self:ApplyKeyboardStyle()
            self:RefreshApplicableInputTypeKeybinds()
        elseif newState == SCENE_HIDDEN then
            WINDOW_MANAGER:SetMouseCursor(MOUSE_CURSOR_DO_NOT_CARE)
        end
    end)

    GAMEPAD_CHAMPION_PERKS_SCENE = ZO_Scene:New("gamepad_championPerks_root", SCENE_MANAGER)
    GAMEPAD_CHAMPION_PERKS_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        SharedStateChangeCallback(oldState, newState)
        if newState == SCENE_SHOWING then
            self:PerformDeferredInitializationGamepad()
            self:ApplyGamepadStyle()
            self:RefreshApplicableInputTypeKeybinds()
            DIRECTIONAL_INPUT:Activate(self, control)
        elseif newState == SCENE_HIDDEN then
            DIRECTIONAL_INPUT:Deactivate(self)
            self:SetSelectedConstellation(nil)
            self.gamepadChosenConstellationRightTooltip:ClearLines()
        end
    end)

    SYSTEMS:RegisterKeyboardRootScene("champion", CHAMPION_PERKS_SCENE)
    SYSTEMS:RegisterGamepadRootScene("champion", GAMEPAD_CHAMPION_PERKS_SCENE)
end

function ChampionPerks:IsChampionSystemNew()
    return self.isChampionSystemNew
end

function ChampionPerks:SetChampionSystemNew(isNew)
    if isNew ~= self.isChampionSystemNew then
        self.isChampionSystemNew = isNew
        self:RefreshMenus()
    end
end

function ChampionPerks:SetupCustomConfirmDialog()
    local customControl = ZO_ChampionRespecConfirmationDialog
    local gamepadData = {
        data1 =
        {
            value = 0,
            header = GetString(SI_CHAMPION_DIALOG_CONFIRMATION_BALANCE),
        },
        data2 = 
        {
            value = 0,
            header = GetString(SI_CHAMPION_DIALOG_CONFIRMATION_COST),
        }
    }

    ZO_Dialogs_RegisterCustomDialog("CHAMPION_CONFIRM_COST",
    {
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.BASIC,
        },
        customControl = customControl,
        title =
        {
            text = SI_CHAMPION_DIALOG_CONFIRM_CHANGES_TITLE,
        },
        mainText =
        {
            text = zo_strformat(SI_CHAMPION_DIALOG_CONFIRM_POINT_COST),
        },
        setup = function(dialog)
            if SCENE_MANAGER:IsCurrentSceneGamepad() then
                local gamepadGoldIconMarkup =  ZO_Currency_GetGamepadFormattedCurrencyIcon(CURT_MONEY)
                gamepadData.data1.value = zo_strformat(SI_CHAMPION_RESPEC_CURRENCY_FORMAT, ZO_CommaDelimitNumber(GetCurrencyAmount(CURT_MONEY, CURRENCY_LOCATION_CHARACTER)), gamepadGoldIconMarkup)
                gamepadData.data2.value = zo_strformat(SI_CHAMPION_RESPEC_CURRENCY_FORMAT, ZO_CommaDelimitNumber(GetChampionRespecCost()), gamepadGoldIconMarkup)
                dialog.setupFunc(dialog, gamepadData)
            else
                ZO_CurrencyControl_SetSimpleCurrency(customControl:GetNamedChild("BalanceAmount"), CURT_MONEY,  GetCurrencyAmount(CURT_MONEY, CURRENCY_LOCATION_CHARACTER))
                ZO_CurrencyControl_SetSimpleCurrency(customControl:GetNamedChild("RespecCost"), CURT_MONEY,  GetChampionRespecCost())
            end
        end,
        buttons =
        {
            {
                control = customControl:GetNamedChild("Confirm"),
                text = SI_DIALOG_CONFIRM,
                callback = function(dialog)
                                CHAMPION_PERKS:SpendPointsConfirmed(dialog.data.respecNeeded)
                            end,
            },
            {
                control = customControl:GetNamedChild("Cancel"),
                text = SI_DIALOG_CANCEL,
            }
        }
    })
end

function ChampionPerks:ShowDialog(name, data, textParams)
    if not SCENE_MANAGER:IsCurrentSceneGamepad() then
        if self.chosenConstellation then
            self.chosenConstellation:SelectStar(nil)
        end
    else
        if self.chosenConstellation then
            local selectedStar = self.chosenConstellation:GetSelectedStar()
            if selectedStar then
                selectedStar:StopChangingPoints()
            end
        end
    end
    ZO_Dialogs_ShowPlatformDialog(name, data, textParams)
end

function ChampionPerks:PerformDeferredInitializationShared()
    if not self.initialized then
        self.initialized = true

        self.colorCloudsTexture = self.canvasControl:GetNamedChild("ColorClouds")
        self.cloudsTexture = self.canvasControl:GetNamedChild("Clouds")
        self.smokeTexture = self.canvasControl:GetNamedChild("Smoke")
        self.closeClouds1Texture = self.canvasControl:GetNamedChild("CloseClouds1")
        self.closeClouds2Texture = self.canvasControl:GetNamedChild("CloseClouds2")
        self.starClustersSmallTexture = self.canvasControl:GetNamedChild("StarClustersSmall")
        self.starClustersMediumTexture = self.canvasControl:GetNamedChild("StarClustersMedium")
        self.starClustersLargeTexture = self.canvasControl:GetNamedChild("StarClustersLarge")
        self.darknessRingTexture = self.canvasControl:GetNamedChild("DarknessRing")
        self.radialSelectorTexture = self.canvasControl:GetNamedChild("RadialSelector")
        self.centerInfoBGTexture = self.canvasControl:GetNamedChild("CenterInfoBG")

        self.centerInfo = self.control:GetNamedChild("CenterInfo")
        self.centerInfoTopRowControl= self.centerInfo:GetNamedChild("TopRow")
        self.centerInfoNameLabel = self.centerInfo:GetNamedChild("TopRowName")
        self.centerInfoSpentPointsLabel = self.centerInfo:GetNamedChild("TopRowSpentPoints")
        self.centerInfoDescriptionLabel = self.centerInfo:GetNamedChild("Description")
        self.centerInfoPointCountersControl = self.centerInfo:GetNamedChild("PointCounters")
        self.centerInfoPointCountersHeader = self.centerInfo:GetNamedChild("PointCountersHeader")
        self.centerAlphaInterpolator = ZO_LerpInterpolator:New(0)

        self.chosenConstellationContainer = self.control:GetNamedChild("ChosenConstellation")
        self.chosenConstellationNameLabel = self.chosenConstellationContainer:GetNamedChild("TopRowName")
        self.chosenConstellationSpentPointsLabel = self.chosenConstellationContainer:GetNamedChild("TopRowSpentPoints")
        self.chosenConstellationDescriptionLabel = self.chosenConstellationContainer:GetNamedChild("Description")
        self.chosenConstellationInfoAlphaInterpolator = ZO_LerpInterpolator:New(0)
        self.chosenConstellationInfoAlphaInterpolator:SetLerpRate(12)

        self.selectedStarIndicatorTexture = self.control:GetNamedChild("SelectedStarIndicator")
        self.selectedStarIndicatorTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_SelectedStarIndicatorAnimation", self.selectedStarIndicatorTexture)
        self.selectedStarIndicatorTimeline:PlayForward()
        self.selectedStarIndicatorAppearTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_SelectedStarIndicatorAppearAnimation", self.selectedStarIndicatorTexture)

        self:CreateCloseCloudsAnimation()

        self.cameraRootX = 0
        self.cameraRootY = 0
        self.cameraRootZ = 0
        self.cameraDeltaX = 0
        self.cameraDeltaY = 0
        self.cameraDeltaZ = 0

        self.constellationInnerRadius = 190
        self.constellationHeight = 425
        self.constellationOuterRadius = self.constellationInnerRadius + self.constellationHeight

        self.oneShotAnimationTexturePool = ZO_ControlPool:New("ZO_ChampionOneShotAnimationTexture", self.canvasControl)
        self.oneShotAnimationOnStopCallback = function(timeline)
            local texture = timeline:GetFirstAnimation():GetAnimatedControl()
            timeline.onReleaseCallback(texture)
            self.oneShotAnimationTexturePool:ReleaseObject(texture.key)
            timeline.pool:ReleaseObject(timeline.key)
        end
        self.starsToAnimateForConfirm = {}

        self:InitializeSharedKeybindStripDescriptors()
        self:BuildSceneGraph()
        self:BuildCenterInfoPointCounters()
        self:RefreshAvailablePointDisplays()
        self:RefreshUnspentPoints()
        self:BuildStyleTables()
    end
end

function ChampionPerks:CreateCloseCloudsAnimation()
    local CLOUD_LAYER_MAX_ALPHA = 0.22
    local CLOUD_LAYER_DEPTH_DELTA = 0.6
    local RAMP_RANGE = 0.4
    local ROTATION_DELTA = 0.3
    local function UpdateCloseClouds(node, textureControl, progress)
        if progress < RAMP_RANGE then
            textureControl:SetAlpha(progress * (1 / RAMP_RANGE) * CLOUD_LAYER_MAX_ALPHA)
        elseif progress < (1 - RAMP_RANGE) then
            textureControl:SetAlpha(CLOUD_LAYER_MAX_ALPHA)
        else
            textureControl:SetAlpha((1 - (progress - 1 + RAMP_RANGE) * (1 / RAMP_RANGE)) * CLOUD_LAYER_MAX_ALPHA)
        end 
        node:SetZ(CLOSE_CLOUDS_DEPTH + CLOUD_LAYER_DEPTH_DELTA * progress)
        node:SetRotation(progress * ROTATION_DELTA)
    end

    local PROGRESS_OFFSET = 0.25
    self.closeCloudsTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_ChampionCloseCloudsAnimation")
    self.closeCloudsTimeline:GetFirstAnimation():SetUpdateFunction(function(animation, progress)
        UpdateCloseClouds(self.closeClouds1Node, self.closeClouds1Texture, (progress + PROGRESS_OFFSET) % 1 )
        UpdateCloseClouds(self.closeClouds2Node, self.closeClouds2Texture, (progress + PROGRESS_OFFSET + 0.5) % 1)
    end)
end

function ChampionPerks:PerformDeferredInitializationKeyboard()
    if not self.initializedKeyboard then
        self.initializedKeyboard = true
        self:InitializeKeyboardKeybindStripDescriptors()
    end
end

function ChampionPerks:PerformDeferredInitializationGamepad()
    if not self.initializedGamepad then
        self.initializedGamepad = true
        self:InitializeGamepadKeybindStripDescriptors()
        self.gamepadChosenConstellationLeftTooltip = self.gamepadChosenConstellationControl:GetNamedChild("LeftTooltipContainerTip")
        self.gamepadChosenConstellationRightTooltip = self.gamepadChosenConstellationControl:GetNamedChild("RightTooltipContainerTip")
    end
end

function ChampionPerks:InitializeKeyboardKeybindStripDescriptors()
    self.keyboardSharedKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,
        {
            name = GetString(SI_CHAMPION_SYSTEM_CLEAR_POINTS),
            keybind = "UI_SHORTCUT_NEGATIVE",
            callback =  function()
                            self:SetPendingPointsToZero()
                        end,
            visible =   function()
                            return self:HasAnyPendingPoints()
                        end,
        },
    }

    self.keyboardZoomedInKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_RIGHT,
        {
            name = GetString(SI_CHAMPION_CONSTELLATION_ZOOM_OUT),
            keybind = "UI_SHORTCUT_EXIT",
            callback = function() self:ZoomOut() end,
            enabled = function() return not self:IsAnimating() end,
        },
    }
    self.keyboardZoomedOutKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_RIGHT,
        {
            name = GetString(SI_CHAMPION_CONSTELLATION_ZOOM_IN),
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                self:ZoomIn(self.selectedConstellation.node)
            end,
            enabled = function() return not self:IsAnimating() and self.selectedConstellation ~= nil end,
        },
    }
end

function ChampionPerks:InitializeSharedKeybindStripDescriptors()
    self.sharedKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,
        {
            name = function()
                if self:IsRespecNeeded() then
                    local cost = GetChampionRespecCost()
                    if GetCurrencyAmount(CURT_MONEY, CURRENCY_LOCATION_CHARACTER) < cost then
                        cost = ZO_ERROR_COLOR:Colorize(cost)
                    end
                    return zo_strformat(SI_CHAMPION_CONFIRM_SPEND_RESPEC_ACTION, cost, ZO_Currency_GetPlatformFormattedCurrencyIcon(CURT_MONEY))
                else
                    return GetString(SI_CHAMPION_CONFIRM_SPEND_POINTS_ACTION)
                end
            end,
            keybind = "UI_SHORTCUT_SECONDARY",
            callback = function() self:SpendPendingPoints() end,
            visible = function()
                return self:HasUnsavedChanges()
            end,
            enabled = function()
                local active, activeReason = AreChampionPointsActive()
                if not active then
                    return false, GetString("SI_CHAMPIONPOINTACTIVEREASON", activeReason), KEYBIND_STRIP_DISABLED_DIALOG
                end

                if self:IsRespecNeeded() then
                    return GetCurrencyAmount(CURT_MONEY, CURRENCY_LOCATION_CHARACTER) >= GetChampionRespecCost()
                else
                    return true
                end
            end,
        },
        {
            name = function()
                return self:IsInRespecMode() and GetString(SI_CHAMPION_CANCEL_RESPEC_POINTS) or GetString(SI_CHAMPION_RESPEC_POINTS)
            end,
            keybind = "UI_SHORTCUT_TERTIARY",
            callback = function() self:ToggleRespecMode() end,
            visible = function()
                if not self:IsInRespecMode() then
                    return self:HasAnyCommittedSpentPoints()
                else
                    return true
                end
            end,
            enabled = function()
                local active, activeReason = AreChampionPointsActive()
                if not active then
                    return false, GetString("SI_CHAMPIONPOINTACTIVEREASON", activeReason), KEYBIND_STRIP_DISABLED_DIALOG
                end
            end,
        },
        enabled = function() return not self:IsAnimating() end,
    }

    self.sharedZoomedInKeybindStripDescriptor =
    {

    }

    self.sharedZoomedOutKeybindStripDescriptor =
    {

    }
end

function ChampionPerks:InitializeGamepadKeybindStripDescriptors()
    self.gamepadSharedKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,

        {
            name = GetString(SI_CHAMPION_SYSTEM_CLEAR_POINTS),
            keybind = "UI_SHORTCUT_RIGHT_STICK",
            callback =  function()
                            self:SetPendingPointsToZero()
                        end,
            visible =   function()
                            return self:HasAnyPendingPoints()
                        end,
        },
    }

    self.gamepadZoomedOutKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        --Zoomed Out Binds
        {
            name = GetString(SI_CHAMPION_CONSTELLATION_ZOOM_IN),
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                self:ZoomIn(self.selectedConstellation.node)
            end,
            enabled = function() return not self:IsAnimating() and self.selectedConstellation ~= nil end,
        },
        {
            name = GetString(SI_GAMEPAD_BACK_OPTION),
            keybind = "UI_SHORTCUT_NEGATIVE",
            order = -1000,
            callback = function() SCENE_MANAGER:HideCurrentScene() end,
            enabled = function() return not self:IsAnimating() end,
        },
    }

    self.gamepadZoomedInKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        --Zoomed In Binds
        {
            name = GetString(SI_CHAMPION_CONSTELLATION_ZOOM_OUT),
            keybind = "UI_SHORTCUT_NEGATIVE",
            order = -1000,
            callback = function() self:ZoomOut() end,
            enabled = function() return not self:IsAnimating() end,
        },
        {
            --Ethereal binds show no text, the name field is used to help identify the keybind when debugging. This text does not have to be localized.
            name = "Champion Star Remove Points",
            ethereal = true,
            keybind = "UI_SHORTCUT_LEFT_TRIGGER",
            handlesKeyUp = true,
            enabled = function()
                if self.chosenConstellation then
                    local selectedStar = self.chosenConstellation:GetSelectedStar()
                    if selectedStar then
                        return selectedStar:CanRemovePoints()
                    end
                end
                return false
            end,
            callback = function(up)
                --the up can be called when there is no chosen star if the constellations rotate while the trigger is held
                if self.chosenConstellation then
                    local selectedStar = self.chosenConstellation:GetSelectedStar()
                    if selectedStar then
                        if up then
                            selectedStar:StopChangingPoints()
                        else
                            selectedStar:StartRemovingPoints()
                        end
                        return true
                    end
                end
                return false
            end,
        },
        {
            --Ethereal binds show no text, the name field is used to help identify the keybind when debugging. This text does not have to be localized.
            name = "Champion Star Add Points",
            ethereal = true,
            keybind = "UI_SHORTCUT_RIGHT_TRIGGER",
            handlesKeyUp = true,
            enabled = function()
                if self.chosenConstellation then
                    local selectedStar = self.chosenConstellation:GetSelectedStar()
                    if selectedStar then
                        return selectedStar:CanAddPoints()
                    end
                end
                return false
            end,
            callback = function(up)
                --the up can be called when there is no chosen star if the constellations rotate while the trigger is held
                if self.chosenConstellation then
                    local selectedStar = self.chosenConstellation:GetSelectedStar()
                    if selectedStar then
                        if up then
                            selectedStar:StopChangingPoints()
                        else
                            selectedStar:StartAddingPoints()
                        end
                        return true
                    end
                end
                return false
            end,
        },
        {
            --Ethereal binds show no text, the name field is used to help identify the keybind when debugging. This text does not have to be localized.
            name = "Champion Rotate Left",
            ethereal = true,
            keybind = "UI_SHORTCUT_LEFT_SHOULDER",
            callback = function()
                if self.chosenConstellation then
                    self:ZoomedInRotate(self.leftOfChosenConstellation.node)
                end
            end,
        },
        {
            --Ethereal binds show no text, the name field is used to help identify the keybind when debugging. This text does not have to be localized.
            name = "Champion Rotate Right",
            ethereal = true,
            keybind = "UI_SHORTCUT_RIGHT_SHOULDER",
            callback = function()
                if self.chosenConstellation then
                    self:ZoomedInRotate(self.rightOfChosenConstellation.node)
                end
            end,
        },
    }
end

function ChampionPerks:RefreshApplicableSharedKeybinds()
    if self.initialized then
        self:RemoveSharedKeybinds()
        KEYBIND_STRIP:AddKeybindButtonGroup(self.sharedKeybindStripDescriptor)
        if self:IsZoomedIn() then
            KEYBIND_STRIP:AddKeybindButtonGroup(self.sharedZoomedInKeybindStripDescriptor)
        else
            KEYBIND_STRIP:AddKeybindButtonGroup(self.sharedZoomedOutKeybindStripDescriptor)
        end
    end
end

function ChampionPerks:RemoveSharedKeybinds()
    if self.initialized then
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.sharedKeybindStripDescriptor)
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.sharedZoomedInKeybindStripDescriptor)
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.sharedZoomedOutKeybindStripDescriptor)
    end
end

function ChampionPerks:RefreshApplicableInputTypeKeybinds()
    self:RemoveInputTypeKeybinds()
    if self.initializedGamepad and SCENE_MANAGER:IsCurrentSceneGamepad() then
        if SCENE_MANAGER:IsShowing("gamepad_championPerks_root") then
            KEYBIND_STRIP:AddKeybindButtonGroup(self.gamepadSharedKeybindStripDescriptor)
            if self:IsZoomedIn() then
                KEYBIND_STRIP:AddKeybindButtonGroup(self.gamepadZoomedInKeybindStripDescriptor)
            else
                KEYBIND_STRIP:AddKeybindButtonGroup(self.gamepadZoomedOutKeybindStripDescriptor)
            end
        end
    elseif self.initializedKeyboard then
        KEYBIND_STRIP:RemoveDefaultExit()
        KEYBIND_STRIP:AddKeybindButtonGroup(self.keyboardSharedKeybindStripDescriptor)
        if self:IsZoomedIn() then
            KEYBIND_STRIP:AddKeybindButtonGroup(self.keyboardZoomedInKeybindStripDescriptor)
        else
            KEYBIND_STRIP:RestoreDefaultExit()
            KEYBIND_STRIP:AddKeybindButtonGroup(self.keyboardZoomedOutKeybindStripDescriptor)
        end
    end
end

function ChampionPerks:RemoveInputTypeKeybinds()
    if self.initializedGamepad and SCENE_MANAGER:IsCurrentSceneGamepad() then
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.gamepadSharedKeybindStripDescriptor)
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.gamepadZoomedInKeybindStripDescriptor)
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.gamepadZoomedOutKeybindStripDescriptor)
    elseif self.initializedKeyboard then
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keyboardSharedKeybindStripDescriptor)
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keyboardZoomedInKeybindStripDescriptor)
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keyboardZoomedOutKeybindStripDescriptor)
    end
end

function ChampionPerks:BuildStarSpirals()
    local timeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_StarSpiralAnimation")
    self.starSpiralNodes = {}
    for i = 1, 2 do
        local texture = CreateControlFromVirtual(self.canvasControl:GetName().."StarSpiral", self.canvasControl, "ZO_ConstellationStarSpiral", i)
        local spiralNode = self.sceneGraph:CreateNode("starSpiral"..i)
        spiralNode:SetParent(self.rootNode)
        texture:SetDimensions(spiralNode:ComputeSizeForDepth(4000, 4000, STAR_SPIRAL_START_DEPTH, ZO_CHAMPION_REFERENCE_CAMERA_Z))
        spiralNode:AddControl(texture, 0, 0, STAR_SPIRAL_START_DEPTH)
        self.starSpiralNodes[i] = spiralNode
    end

    timeline:PlayFromStart()
end

local NUM_CLOUDS = 4
function ChampionPerks:BuildClouds()
    for i = 1, NUM_CLOUDS do
        local skyCloudTemplate
        if i <= 2 then
            skyCloudTemplate = "ZO_ConstellationSkyCloud1"
        else
            skyCloudTemplate = "ZO_ConstellationSkyCloud2"
        end
        local skyCloudTexture = CreateControlFromVirtual(self.canvasControl:GetName().."SkyCloud", self.canvasControl, skyCloudTemplate, i)
        local skyCloudNode = self.sceneGraph:CreateNode("skyCloud"..i)
        skyCloudNode:SetParent(self.skyCloudsNode)
        skyCloudTexture:SetDimensions(skyCloudNode:ComputeSizeForDepth(512, 256, SKY_CLOUD_DEPTH, ZO_CHAMPION_REFERENCE_CAMERA_Z))
        skyCloudNode:AddControl(skyCloudTexture, 0, 800 + (i % 3) * 75, SKY_CLOUD_DEPTH)
        skyCloudNode:SetRotation(((i - 1) / NUM_CLOUDS) * 2 * math.pi)
    end
end

function ChampionPerks:BuildSceneGraph()
    self.sceneGraph = ZO_SceneGraph:New(self.canvasControl)

    self.rootNode = self.sceneGraph:CreateNode("root")
    self.rootNode:SetParent(self.sceneGraph:GetCameraNode())

    self.skyCloudsNode = self.sceneGraph:CreateNode("skyClouds")
    self.skyCloudsNode:SetParent(self.rootNode)

    self.closeClouds1Node = self.sceneGraph:CreateNode("closeClouds1")
    self.closeClouds1Node:SetParent(self.rootNode)
    self.closeClouds1Texture:SetDimensions(self.closeClouds1Node:ComputeSizeForDepth(4500, 4500, CLOSE_CLOUDS_DEPTH, ZO_CHAMPION_REFERENCE_CAMERA_Z))
    self.closeClouds1Node:AddControl(self.closeClouds1Texture, 0, 0, CLOSE_CLOUDS_DEPTH)

    self.closeClouds2Node = self.sceneGraph:CreateNode("closeClouds2")
    self.closeClouds2Node:SetParent(self.rootNode)
    self.closeClouds2Texture:SetDimensions(self.closeClouds2Node:ComputeSizeForDepth(4500, 4500, CLOSE_CLOUDS_DEPTH, ZO_CHAMPION_REFERENCE_CAMERA_Z))
    self.closeClouds2Node:AddControl(self.closeClouds2Texture, 0, 0, CLOSE_CLOUDS_DEPTH)

    self:BuildClouds()

    self:BuildStarSpirals()

    self.colorCloudsNode = self.sceneGraph:CreateNode("colorClouds")
    self.colorCloudsNode:SetParent(self.rootNode)
    self.colorCloudsNode:SetRotation(6.11)
    self.colorCloudsTexture:SetDimensions(self.colorCloudsNode:ComputeSizeForDepth(1300, 1300, COLOR_CLOUDS_DEPTH, ZO_CHAMPION_REFERENCE_CAMERA_Z))
    self.colorCloudsNode:AddControl(self.colorCloudsTexture, 0, 0, COLOR_CLOUDS_DEPTH)

    self.cloudsNode = self.sceneGraph:CreateNode("clouds")
    self.cloudsNode:SetParent(self.rootNode)
    self.cloudsTexture:SetDimensions(self.cloudsNode:ComputeSizeForDepth(1300, 1300, CLOUDS_DEPTH, ZO_CHAMPION_REFERENCE_CAMERA_Z))
    self.cloudsNode:AddControl(self.cloudsTexture, 0, 0, CLOUDS_DEPTH)

    self.smokeNode = self.sceneGraph:CreateNode("smoke")
    self.smokeNode:SetParent(self.rootNode)
    self.smokeTexture:SetDimensions(self.smokeNode:ComputeSizeForDepth(1300, 1300, SMOKE_DEPTH, ZO_CHAMPION_REFERENCE_CAMERA_Z))
    self.smokeNode:AddControl(self.smokeTexture, 0, 0, SMOKE_DEPTH)

    self.skyNode = self.sceneGraph:CreateNode("sky")
    self.skyNode:SetParent(self.rootNode)
    local skyTexture = self.canvasControl:GetNamedChild("Sky")
    skyTexture:SetDimensions(self.skyNode:ComputeSizeForDepth(9000, 9000, SKY_DEPTH, ZO_CHAMPION_REFERENCE_CAMERA_Z))
    self.skyNode:AddControl(skyTexture, 0, 0, SKY_DEPTH)

    self.darknessRingNode = self.sceneGraph:CreateNode("darknessRing")
    self.darknessRingNode:SetParent(self.rootNode)
    self.darknessRingTexture:SetDimensions(self.darknessRingNode:ComputeSizeForDepth(1400, 1400, CONSTELLATIONS_DARKNESS_DEPTH, ZO_CHAMPION_REFERENCE_CAMERA_Z))
    self.darknessRingNode:AddControl(self.darknessRingTexture, 0, 0, CONSTELLATIONS_DARKNESS_DEPTH)
    self.darknessRingNode:SetRotation(6.11)

    self.radialSelectorNode = self.sceneGraph:CreateNode("radialSelector")
    self.radialSelectorNode:SetParent(self.sceneGraph:GetCameraNode())
    self.radialSelectorTexture:SetDimensions(self.radialSelectorNode:ComputeSizeForDepth(512, 128, CONSTELLATIONS_DEPTH, ZO_CHAMPION_REFERENCE_CAMERA_Z))
    self.radialSelectorNode:AddControl(self.radialSelectorTexture, 0, -580, CONSTELLATIONS_DEPTH)

    self.centerInfoBGNode = self.sceneGraph:CreateNode("centerInfoBG")
    self.centerInfoBGNode:SetParent(self.rootNode)
    self.centerInfoBGTexture:SetDimensions(self.centerInfoBGNode:ComputeSizeForDepth(512, 512, CENTER_INFO_BG_DEPTH, ZO_CHAMPION_REFERENCE_CAMERA_Z))
    self.centerInfoBGNode:AddControl(self.centerInfoBGTexture, 0, 0, CENTER_INFO_BG_DEPTH)

    self.ring = ZO_SceneNodeRing:New(self.rootNode)
    self.ring:SetRadius(self.rootNode:ComputeSizeForDepth(self.constellationInnerRadius, self.constellationInnerRadius, CONSTELLATIONS_DEPTH, ZO_CHAMPION_REFERENCE_CAMERA_Z))
    self.constellations = {}

    for i = 1, GetNumChampionDisciplines() do
        local node = self.sceneGraph:CreateNode(string.format("constellationNode%d", i))
        node:SetParent(self.rootNode)
        self.ring:AddNode(node)

        local constellation = ZO_ChampionConstellation:New(self.sceneGraph, node, i, CONSTELLATIONS_DEPTH)
        self.constellations[i] = constellation
        node.constellation = constellation
    end
end

CENTER_INFO_POINT_COUNTER_PADDING = 40
function ChampionPerks:BuildCenterInfoPointCounters()
    self.centerInfoPointCounters = {}
    local counterWidth
    for i, attribute in ipairs(CHAMPION_ATTRIBUTES) do
        local pointCounter = CreateControlFromVirtual(self.centerInfoPointCountersControl:GetName().."CenterInfoPointCounter", self.centerInfoPointCountersControl, "ZO_ChampionCenterInfoPointCounter", i)

        --Preload the textures
        pointCounter.iconTexture:SetTexture(GetChampionPointAttributeIcon(attribute))
        pointCounter.iconTexture:SetTexture(GetChampionPointAttributeActiveIcon(attribute))

        counterWidth = counterWidth or pointCounter:GetWidth()
        pointCounter:SetAnchor(TOP, nil, TOPLEFT, pointCounter:GetWidth() * 0.5 + (i - 1) * (counterWidth + CENTER_INFO_POINT_COUNTER_PADDING))
        self.centerInfoPointCounters[i] = pointCounter
        pointCounter.interpolator = ZO_LerpInterpolator:New(0)
        pointCounter.interpolator:SetLerpRate(15)
    end
    self.centerInfoPointCountersControl:SetWidth(#self.centerInfoPointCounters * counterWidth + (#self.centerInfoPointCounters - 1) * CENTER_INFO_POINT_COUNTER_PADDING)
end

function ChampionPerks:RegisterEvents()
    self.control:SetHandler("OnUpdate", function(_, timeSecs) self:OnUpdate(timeSecs) end)
    self.control:RegisterForEvent(EVENT_CHAMPION_POINT_GAINED, function() self:OnChampionPointGained() end)
    self.control:RegisterForEvent(EVENT_CHAMPION_SYSTEM_UNLOCKED, function() self:OnChampionSystemUnlocked() end)
    self.control:RegisterForEvent(EVENT_UNSPENT_CHAMPION_POINTS_CHANGED, function() self:OnUnspentChampionPointsChanged() end)
    self.control:RegisterForEvent(EVENT_CHAMPION_PURCHASE_RESULT, function(_, result) self:OnChampionPurchaseResult(result) end)
    self.control:RegisterForEvent(EVENT_MONEY_UPDATE, function() self:OnMoneyChanged() end)
    self.control:RegisterForEvent(EVENT_PLAYER_ACTIVATED, function() self:OnPlayerActivated() end)
end

local KEYBOARD_CONSTANTS, GAMEPAD_CONSTANTS
function ChampionPerks:BuildStyleTables()
    KEYBOARD_CONSTANTS =
    {
        CONSTELLATION_NAME_LABEL_OFFSET_Y = 0,
        CONSTELLATION_DESCRIPTION_WIDTH = 360,
        AVAILABLE_POINTS_COUNTERS_OFFSET_Y = 265,
        RADIAL_SELECTOR_Y = -580,

        NAME_FONT = "ZoFontWinH1",
        POINTS_FONT = "ZoFontCallout3",
        DESCRIPTION_FONT = "ZoFontWinH3",

        EARNED_POINTS_ANCHOR = ZO_Anchor:New(BOTTOMLEFT, nil, BOTTOMLEFT, 32, -4),
        EARNED_POINTS_HEADER_FONT = "ZoFontKeybindStripDescription",
        EARNED_POINTS_POINTS_FONT = "ZoFontKeybindStripDescription",
        EARNED_POINTS_MODIFY_TEXT_TYPE = MODIFY_TEXT_TYPE_NONE,

        INACTIVE_ALERT_MODIFY_TEXT_TYPE = MODIFY_TEXT_TYPE_NONE,
        INACTIVE_ALERT_FONT = "ZoFontWinH1",
        INACTIVE_ALERT_OFFSETX = 10,
        INACTIVE_ALERT_OFFSETY = 20,
    }

    GAMEPAD_CONSTANTS =
    {
        CONSTELLATION_NAME_LABEL_OFFSET_Y = -30,
        CONSTELLATION_DESCRIPTION_WIDTH = 434,
        AVAILABLE_POINTS_COUNTERS_OFFSET_Y = 275,
        RADIAL_SELECTOR_Y = -612,

        NAME_FONT = "ZoFontGamepad42",
        POINTS_FONT = "ZoFontGamepad61",
        DESCRIPTION_FONT = "ZoFontGamepad42",

        EARNED_POINTS_ANCHOR = ZO_Anchor:New(BOTTOMRIGHT, nil, BOTTOMRIGHT, -ZO_GAMEPAD_SAFE_ZONE_INSET_X, -ZO_GAMEPAD_SAFE_ZONE_INSET_Y - 2),
        EARNED_POINTS_HEADER_FONT = "ZoFontGamepad34",
        EARNED_POINTS_POINTS_FONT = "ZoFontGamepad34",
        EARNED_POINTS_MODIFY_TEXT_TYPE = MODIFY_TEXT_TYPE_UPPERCASE,

        INACTIVE_ALERT_MODIFY_TEXT_TYPE = MODIFY_TEXT_TYPE_UPPERCASE,
        INACTIVE_ALERT_FONT = "ZoFontGamepad42",
        INACTIVE_ALERT_OFFSETX = 100,
        INACTIVE_ALERT_OFFSETY = 50,
    }
end

function ChampionPerks:SetupDescriptionLabels(constants, nameLabel, spentPointsLabel, descriptionLabel)
    nameLabel:SetFont(constants.NAME_FONT)
    spentPointsLabel:SetFont(constants.POINTS_FONT)
    if descriptionLabel then
        descriptionLabel:SetFont(constants.DESCRIPTION_FONT)
    end
end

function ChampionPerks:SetupEarnedPointCounter(constants, control)
    control:ClearAnchors()
    control.pointsLabel:SetFont(constants.EARNED_POINTS_POINTS_FONT)
    control.pointsHeaderLabel:SetFont(constants.EARNED_POINTS_HEADER_FONT)
    control.pointsHeaderLabel:SetModifyTextType(constants.EARNED_POINTS_MODIFY_TEXT_TYPE)
    control.pointsHeaderLabel:SetText(GetString(SI_CHAMPION_EARNED_POINTS_HEADER))
    constants.EARNED_POINTS_ANCHOR:Set(control)
end

local function SetAnchorOffsetY(control, offsetY)
    control:ClearAnchors()
    control:SetAnchor(TOP, nil, TOP, 0, offsetY)
end

function ChampionPerks:ApplyCenterInfoStyle(constants)
    SetAnchorOffsetY(self.centerInfoTopRowControl, constants.CONSTELLATION_NAME_LABEL_OFFSET_Y)
    self.centerInfoDescriptionLabel:SetWidth(constants.CONSTELLATION_DESCRIPTION_WIDTH)
    SetAnchorOffsetY(self.centerInfoPointCountersControl, constants.AVAILABLE_POINTS_COUNTERS_OFFSET_Y)

    self.radialSelectorNode:SetControlPosition(self.radialSelectorTexture, 0, constants.RADIAL_SELECTOR_Y, CONSTELLATIONS_DEPTH)
end

function ChampionPerks:RefreshInactiveAlertMessage()
    local active, activeReason = AreChampionPointsActive()
    if not active then
        self.inactiveAlert.messageLabel:SetText(GetString("SI_CHAMPIONPOINTACTIVEREASON", activeReason))
    end
end

function ChampionPerks:ApplyInactiveAlertStyle(constants, control)
    control.messageLabel:SetFont(constants.INACTIVE_ALERT_FONT)
    control.messageLabel:SetModifyTextType(constants.INACTIVE_ALERT_MODIFY_TEXT_TYPE)
    self:RefreshInactiveAlertMessage()
    control:ClearAnchors()
    control:SetAnchor(TOPLEFT, nil, TOPLEFT, constants.INACTIVE_ALERT_OFFSETX, constants.INACTIVE_ALERT_OFFSETY)
end

function ChampionPerks:ApplyKeyboardStyle()
    if self.visualStyle ~= VISUAL_STYLE_KEYBOARD then
        self.visualStyle = VISUAL_STYLE_KEYBOARD

        --Center Info
        self:SetupDescriptionLabels(KEYBOARD_CONSTANTS, self.centerInfoNameLabel, self.centerInfoSpentPointsLabel)
        self.centerInfoPointCountersHeader:SetFont("ZoFontWinH2")

        for i, centerInfoPointCounter in ipairs(self.centerInfoPointCounters) do
            centerInfoPointCounter.pointsLabel:SetFont("ZoFontWinH1")
        end

        self:ApplyCenterInfoStyle(KEYBOARD_CONSTANTS)

        --Champion Points Inactive Notification
        self:ApplyInactiveAlertStyle(KEYBOARD_CONSTANTS, self.inactiveAlert)
        
        --Chosen Info
        self:SetupDescriptionLabels(KEYBOARD_CONSTANTS, self.chosenConstellationNameLabel, self.chosenConstellationSpentPointsLabel, self.chosenConstellationDescriptionLabel)

        --Earned Points Counter
        self:SetupEarnedPointCounter(KEYBOARD_CONSTANTS, self.chosenAttributeTypeEarnedPointCounter)
    end
end

function ChampionPerks:ApplyGamepadStyle()
    if self.visualStyle ~= VISUAL_STYLE_GAMEPAD then
        self.visualStyle = VISUAL_STYLE_GAMEPAD

        --Center Info
        self:SetupDescriptionLabels(GAMEPAD_CONSTANTS, self.centerInfoNameLabel, self.centerInfoSpentPointsLabel)
        self.centerInfoPointCountersHeader:SetFont("ZoFontGamepad34")

        for i, centerInfoPointCounter in ipairs(self.centerInfoPointCounters) do
            centerInfoPointCounter.pointsLabel:SetFont("ZoFontGamepad42")
        end

        self:ApplyCenterInfoStyle(GAMEPAD_CONSTANTS)

        --Champion Points Inactive Notification
        self:ApplyInactiveAlertStyle(GAMEPAD_CONSTANTS, self.inactiveAlert)

        --Chosen Info
        self:SetupDescriptionLabels(GAMEPAD_CONSTANTS, self.chosenConstellationNameLabel, self.chosenConstellationSpentPointsLabel, self.chosenConstellationDescriptionLabel)

        --Earned Points Counter
        self:SetupEarnedPointCounter(GAMEPAD_CONSTANTS, self.chosenAttributeTypeEarnedPointCounter)
    end
end

--Constellations

function ChampionPerks:GetStarTextControlPool()
    return self.starTextControlPool
end

function ChampionPerks:AcquireSelectedStarIndicatorTexture()
    self.selectedStarIndicatorTexture:SetHidden(false)
    self.selectedStarIndicatorAppearTimeline:PlayFromStart()
    return self.selectedStarIndicatorTexture
end

function ChampionPerks:ReleaseSelectedStarIndicatorTexture()
    self.selectedStarIndicatorTexture:ClearAnchors()
    self.selectedStarIndicatorTexture:SetHidden(true)
    self.selectedStarIndicatorAppearTimeline:Stop()
end

function ChampionPerks:IsMouseOverConstellationDisc()
    local mx, my = GetUIMousePosition()
    local canvasLeft, canvasTop, canvasRight, canvasBottom = self.canvasControl:GetScreenRect()
    local cx, cy = (canvasRight - canvasLeft) / 2, (canvasBottom - canvasTop) / 2
    local dx = mx - cx
    local dy = my - cy
    local distanceFromCenterSq = dx * dx + dy * dy

    return distanceFromCenterSq >= self.constellationInnerRadius * self.constellationInnerRadius and distanceFromCenterSq <= self.constellationOuterRadius * self.constellationOuterRadius
end

local ZOOMED_IN_MOUSEOVER_STATE_NONE = 1
local ZOOMED_IN_MOUSEOVER_STATE_LEFT = 2
local ZOOMED_IN_MOUSEOVER_STATE_RIGHT = 3

function ChampionPerks:IsMouseOverLeftConstellation()
    return self.zoomedInMouseoverState == ZOOMED_IN_MOUSEOVER_STATE_LEFT
end

function ChampionPerks:IsMouseOverRightConstellation()
    return self.zoomedInMouseoverState == ZOOMED_IN_MOUSEOVER_STATE_RIGHT
end

function ChampionPerks:UpdateZoomedInMouseoverPositions()
    local oldMouseoverState = self.zoomedInMouseoverState
    if self:IsZoomedIn() then
        -- Uses the darkness ring because it's at the center of the world coordinate system
        local centerX, centerY = self.darknessRingTexture:GetCenter()
        local mouseX, mouseY = GetUIMousePosition()
        local mouseAngle = math.atan2(mouseX - centerX, mouseY - centerY)

        local UPPER_BOUND = 2.75
        local LOWER_BOUND = math.pi / 2

        if WINDOW_MANAGER:GetMouseOverControl():GetOwningWindow() ~= self.control then
            self.zoomedInMouseoverState = ZOOMED_IN_MOUSEOVER_STATE_NONE
        elseif mouseAngle > -UPPER_BOUND and mouseAngle < -LOWER_BOUND then
            self.zoomedInMouseoverState = ZOOMED_IN_MOUSEOVER_STATE_LEFT
        elseif mouseAngle < UPPER_BOUND and mouseAngle > LOWER_BOUND  then
            self.zoomedInMouseoverState = ZOOMED_IN_MOUSEOVER_STATE_RIGHT
        else
            self.zoomedInMouseoverState = ZOOMED_IN_MOUSEOVER_STATE_NONE
        end
    else
        self.zoomedInMouseoverState = ZOOMED_IN_MOUSEOVER_STATE_NONE
    end

    if self.zoomedInMouseoverState ~= oldMouseoverState then
        self:RefreshCursorAndPlayMouseover()
    end
end

local MOUSEOVER_SOUNDS = {
    [ATTRIBUTE_HEALTH] = SOUNDS.CHAMPION_WARRIOR_MOUSEOVER,
    [ATTRIBUTE_MAGICKA] = SOUNDS.CHAMPION_MAGE_MOUSEOVER,
    [ATTRIBUTE_STAMINA] = SOUNDS.CHAMPION_THIEF_MOUSEOVER,
}

function ChampionPerks:RefreshCursorAndPlayMouseover()
    local newCursor = MOUSE_CURSOR_DO_NOT_CARE
    local attributeType = ATTRIBUTE_NONE
    if self.zoomedInMouseoverState == ZOOMED_IN_MOUSEOVER_STATE_LEFT then
        newCursor = MOUSE_CURSOR_NEXT_LEFT
        if self.leftOfChosenConstellation then
            attributeType = self.leftOfChosenConstellation.node.constellation:GetAttributeType()
        end
    elseif self.zoomedInMouseoverState == ZOOMED_IN_MOUSEOVER_STATE_RIGHT then
        newCursor = MOUSE_CURSOR_NEXT_RIGHT
        if self.rightOfChosenConstellation then
            attributeType = self.rightOfChosenConstellation.node.constellation:GetAttributeType()
        end
    end
    PlaySound(MOUSEOVER_SOUNDS[attributeType])
    WINDOW_MANAGER:SetMouseCursor(newCursor)
end

function ChampionPerks:GetConstellationInfo(constellation)
    local spentPoints = 0
    if self:IsInRespecMode() then
        spentPoints = constellation:GetNumPendingPoints()
    else
        spentPoints = constellation:GetNumCommittedSpentPoints() + constellation:GetNumPendingPoints()
    end
    return constellation:GetName(), spentPoints, constellation:GetDescription()
end

function ChampionPerks:RefreshConstellationInfo(constellation, nameLabel, spentPointsLabel, descriptionLabel)
    local name, spentPoints, description = self:GetConstellationInfo(constellation)
    nameLabel:SetText(name)
    spentPointsLabel:SetText(spentPoints)
    descriptionLabel:SetText(description)
end

function ChampionPerks:RefreshChosenConstellationInfo()
    if self.chosenConstellation then
        if SCENE_MANAGER:IsCurrentSceneGamepad() then
            local constellationName, numSpentPoints, description = self:GetConstellationInfo(self.chosenConstellation)
            local chosenAttributeType = self.chosenConstellation:GetAttributeType()
            local attributeIcon = GetChampionPointAttributeIcon(chosenAttributeType)
            local attributeName = ZO_Champion_GetConstellationGroupNameFromAttribute(chosenAttributeType)

            self.gamepadChosenConstellationLeftTooltip:ClearLines()
            self.gamepadChosenConstellationLeftTooltip.tooltip:LayoutChampionConstellation(attributeName, attributeIcon, constellationName, description, self:GetNumAvailablePointsThatCanBeSpent(chosenAttributeType), numSpentPoints)
        else
            self:RefreshConstellationInfo(self.chosenConstellation, self.chosenConstellationNameLabel, self.chosenConstellationSpentPointsLabel, self.chosenConstellationDescriptionLabel)
        end
    end
end

function ChampionPerks:GetChosenConstellation()
    return self.chosenConstellation
end

function ChampionPerks:SetChosenConstellation(constellation, unchooseInstantly)
    if self.chosenConstellation ~= constellation then
        if self.chosenConstellation then
            self.chosenConstellation:ClearChosen(unchooseInstantly)
            self.lastChosenConstellation = self.chosenConstellation
        end

        self.chosenConstellation = constellation

        if self.chosenConstellation ~= nil then
            self.chosenConstellation:MakeChosen()
            self:RefreshChosenConstellationInfo()
            self:RefreshChosenAttributePointCounter()
            self:RefreshChosenAttributeEarnedPointCounter()
            self.leftOfChosenConstellation = self.ring:GetNextNode(self.chosenConstellation.node).constellation
            self.rightOfChosenConstellation = self.ring:GetPreviousNode(self.chosenConstellation.node).constellation
        else
            self.leftOfChosenConstellation = nil
            self.rightOfChosenConstellation = nil
        end

        self:RefreshCursorAndPlayMouseover()
    end
end


function ChampionPerks:RefreshSelectedConstellationInfo()
    if self.selectedConstellation ~= nil then
        self:RefreshConstellationInfo(self.selectedConstellation, self.centerInfoNameLabel, self.centerInfoSpentPointsLabel, self.centerInfoDescriptionLabel)
        local constellationAttribute = self.selectedConstellation:GetAttributeType()
        if constellationAttribute ~= ATTRIBUTE_NONE then
            for i, attribute in ipairs(CHAMPION_ATTRIBUTES) do
                if constellationAttribute == attribute then
                    local centerInfoPointCounter = self.centerInfoPointCounters[i]
                    centerInfoPointCounter.interpolator:SetTargetBase(1)
                end
            end
        end
    else
        self.centerInfoNameLabel:SetText("")
        self.centerInfoSpentPointsLabel:SetText("")
        self.centerInfoDescriptionLabel:SetText("")
    end
end

function ChampionPerks:SetSelectedConstellation(constellation)
    if self.selectedConstellation ~= constellation then
        self.selectedConstellation = constellation
        KEYBIND_STRIP:UpdateCurrentKeybindButtonGroups()
        for i, centerInfoPointCounter in ipairs(self.centerInfoPointCounters) do
            centerInfoPointCounter.interpolator:SetTargetBase(0)
        end
        if self.selectedConstellation then
            self:RefreshSelectedConstellationInfo()
            local constellationAttribute = self.selectedConstellation:GetAttributeType()
            if constellationAttribute ~= ATTRIBUTE_NONE then
                PlaySound(MOUSEOVER_SOUNDS[constellationAttribute])
            end
        end
    end
end

--Tooltips

function ChampionPerks:LayoutRightTooltipChampionSkillAbility(disciplineIndex, skillIndex, pendingPoints)
    self.gamepadChosenConstellationRightTooltip:ClearLines()
    self.gamepadChosenConstellationRightTooltip.tooltip:LayoutChampionSkillAbility(disciplineIndex, skillIndex, pendingPoints)
end

--Points

function ChampionPerks:GetNumPendingPoints(attributeType)
    local numPendingPoints = 0
    if self.constellations then
        for i, constellation in ipairs(self.constellations) do
            if not attributeType or constellation:GetAttributeType() == attributeType then
                numPendingPoints = numPendingPoints + constellation:GetNumPendingPoints()
            end
        end
    end
    return numPendingPoints
end

function ChampionPerks:HasAnyPendingPoints()
    for _, constellation in ipairs(self.constellations) do
        for _, star in ipairs(self.constellations) do
            if star:GetNumPendingPoints() > 0 then
                return true
            end
        end
    end
    return false
end

function ChampionPerks:HasAnyCommittedSpentPoints(attributeType)
    if attributeType then
        return self:GetNumCommittedSpentPoints(attributeType) > 0
    else
        for i, attributeType in ipairs(CHAMPION_ATTRIBUTES) do
            if self:GetNumCommittedSpentPoints(attributeType) > 0 then
                return true
            end
        end
    end
    return false
end

function ChampionPerks:GetNumCommittedSpentPoints(attributeType)
    return GetNumSpentChampionPoints(attributeType)
end

function ChampionPerks:GetNumAvailablePoints(attributeType)
    local numUnspent = GetNumUnspentChampionPoints(attributeType)
    local numPending = self:GetNumPendingPoints(attributeType)

    if self:IsInRespecMode() then
        --In respec mode, spent points are available
        local numSpent = self:GetNumCommittedSpentPoints(attributeType)
        return numUnspent - numPending + numSpent
    else
        return numUnspent - numPending
    end
end

function ChampionPerks:GetNumAvailablePointsUntilMaxSpendableCap(attributeType)
    local total = 0
    local numPending = self:GetNumPendingPoints(attributeType)
    if self:IsInRespecMode() then
        --In respec mode, spent points are available
        total = total + numPending
    else
        local numSpent = self:GetNumCommittedSpentPoints(attributeType)
        total = total + numPending + numSpent
    end
    return GetMaxSpendableChampionPointsInAttribute() - total
end

--We may be at the spending cap, meaning we can't spend the points even if we have them
function ChampionPerks:GetNumAvailablePointsThatCanBeSpent(attributeType)
    local numAvailablePoints = self:GetNumAvailablePoints(attributeType)
    local numAvailablePointsUntilMaxSpendableCap = self:GetNumAvailablePointsUntilMaxSpendableCap(attributeType)
    return zo_min(numAvailablePoints, numAvailablePointsUntilMaxSpendableCap)
end

function ChampionPerks:RefreshUnspentPoints()
    self.unspentPoints = {}
    for i = 1, #CHAMPION_ATTRIBUTES do
        self.unspentPoints[i] = GetNumUnspentChampionPoints(i)
    end
end

function ChampionPerks:HasAnyUnspentPoints(attributeType)
    if attributeType then
        return self.unspentPoints[attributeType] > 0
    else
        for attribute, numUnspentPoints in ipairs(self.unspentPoints) do
            if numUnspentPoints > 0 then
                return true
            end
        end
    end
    return false
end

function ChampionPerks:HasAnySpendableUnspentPoints(attributeType)
    if self:HasAnyUnspentPoints(attributeType) then
        if attributeType then
            return self:GetNumAvailablePointsUntilMaxSpendableCap(attributeType) > 0
        else
            for i, attribute in ipairs(CHAMPION_ATTRIBUTES) do
                if self:GetNumAvailablePointsUntilMaxSpendableCap(attribute) > 0 then
                    return true
                end
            end
        end
    end
    return false
end

function ChampionPerks:RefreshChosenAttributePointCounter()
    if self.chosenConstellation then
        local chosenAttributeType = self.chosenConstellation:GetAttributeType()
        self.chosenAttributeTypePointCounter.pointsLabel:SetText(self:GetNumAvailablePointsThatCanBeSpent(chosenAttributeType))
        self.chosenAttributeTypePointCounter.iconTexture:SetTexture(GetChampionPointAttributeIcon(chosenAttributeType))
    end
end

function ChampionPerks:RefreshChosenAttributeEarnedPointCounter()
    if self.chosenConstellation then
        local chosenAttributeType = self.chosenConstellation:GetAttributeType()
        local earnedPoints = GetNumUnspentChampionPoints(chosenAttributeType) + GetNumSpentChampionPoints(chosenAttributeType)
        local maxSpendable = GetMaxSpendableChampionPointsInAttribute(chosenAttributeType)
        self.chosenAttributeTypeEarnedPointCounter.pointsLabel:SetText(zo_strformat(SI_CHAMPION_EARNED_POINTS_FORMAT, earnedPoints, maxSpendable))
        local pointsColor
        if earnedPoints > maxSpendable then
            pointsColor = ZO_ERROR_COLOR
        else
            pointsColor = ZO_DEFAULT_ENABLED_COLOR
        end
        self.chosenAttributeTypeEarnedPointCounter.pointsLabel:SetColor(pointsColor:UnpackRGB())
        self.chosenAttributeTypeEarnedPointCounter.iconTexture:SetTexture(GetChampionPointAttributeIcon(chosenAttributeType))
    end
end

function ChampionPerks:RefreshAvailablePointDisplays()
    for i, attribute in ipairs(CHAMPION_ATTRIBUTES) do
        local centerInfoPointCounter = self.centerInfoPointCounters[i]
        centerInfoPointCounter.pointsLabel:SetText(self:GetNumAvailablePointsThatCanBeSpent(attribute))
    end
    self:RefreshChosenAttributePointCounter()
end

function ChampionPerks:ResetPendingPoints()
    for i, constellation in ipairs(self.constellations) do
        constellation:ResetPendingPoints()
    end
    self:MarkDirty()
end

function ChampionPerks:SetPendingPointsToZero()
    PlaySound(SOUNDS.CHAMPION_PENDING_POINTS_CLEARED)
    for _, constellation in ipairs(self.constellations) do
        for _, star in ipairs(constellation:GetStars()) do
            star:SetPendingPointsToZero()
        end
    end
    self:MarkDirty()
end

function ChampionPerks:SpendPointsConfirmed(respecNeeded)
    if SpendPendingChampionPoints(respecNeeded) then
        local confirmationSound
        if respecNeeded then
            confirmationSound = SOUNDS.CHAMPION_RESPEC_ACCEPT
        else
            confirmationSound = SOUNDS.CHAMPION_POINTS_COMMITTED
        end
        PlaySound(confirmationSound)
        self.awaitingSpendPointsResponse = true
    end
end

function ChampionPerks:SpendPendingPoints()
    local respecNeeded = self:IsRespecNeeded()
    local dialogName
    if respecNeeded then
        dialogName = "CHAMPION_CONFIRM_COST"
    else
        dialogName = "CHAMPION_CONFIRM_CHANGES"
    end
    self:ShowDialog(dialogName, { respecNeeded = respecNeeded })
end

function ChampionPerks:RefreshConstellationStarStates()
    for i, constellation in ipairs(self.constellations) do
        constellation:RefreshAllStarStates()
    end
end

function ChampionPerks:RefreshConstellationSpentPoints()
    for i, constellation in ipairs(self.constellations) do
        constellation:RefreshSpentPoints()
    end
end

function ChampionPerks:RefreshChosenConstellationStarMinMax()
    if self.chosenConstellation then
        self.chosenConstellation:RefreshAllStarMinMax()
    end
end

function ChampionPerks:HasUnsavedChanges()
    for i, constellation in ipairs(self.constellations) do
        if constellation:HasUnsavedChanges() then
            return true
        end
    end
    return false
end

function ChampionPerks:ToggleRespecMode()
    local isInRespecMode = self:IsInRespecMode()
    if isInRespecMode and self:HasUnsavedChanges() then
        self:ShowDialog("CHAMPION_CONFIRM_CANCEL_RESPEC")
    elseif not isInRespecMode then
        self:ShowDialog("CHAMPION_CONFIRM_ENTER_RESPEC", nil, { mainTextParams = { GetChampionRespecCost(), ZO_Currency_GetPlatformFormattedCurrencyIcon(CURT_MONEY) } })
    else
        self:SetInRespecMode(not isInRespecMode)
    end
end

function ChampionPerks:SetInRespecMode(inRespecMode)
    if self:IsInRespecMode() ~= inRespecMode then
        PlaySound(SOUNDS.CHAMPION_RESPEC_TOGGLED)
        SetChampionIsInRespecMode(inRespecMode)
        self:ResetPendingPoints()
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.sharedKeybindStripDescriptor)
    end
end

function ChampionPerks:IsInRespecMode()
    return IsChampionInRespecMode()
end

--One Shot Animations

ZO_CHAMPION_ONE_SHOT_ANIMATION_CONFIRM =
{
    template = "ZO_ChampionStarConfirmAnimation",
    setup = function(texture)
        texture:SetTextureCoords(0, 1/8, 0, 1/4)
        texture:SetTexture("EsoUI/Art/Champion/champion_star_committed.dds")
        texture:SetBlendMode(TEX_BLEND_MODE_COLOR_DODGE)
    end,
    onComplete = function(star)
        star:SetStateLocked(false)
    end
}

ZO_CHAMPION_ONE_SHOT_ANIMATION_UNLOCKED_CONFIRM =
{
    template = "ZO_ChampionStarUnlockedConfirmAnimation",
    setup = function(texture)
        texture:SetTextureCoords(0, 1/8, 0, 1/8)
        texture:SetTexture("EsoUI/Art/Champion/champion_star_unlockedConfirm.dds")
        texture:SetBlendMode(TEX_BLEND_MODE_COLOR_DODGE)
    end,
    onComplete = function(star)
        star:SetStateLocked(false)
    end
}

ZO_CHAMPION_ONE_SHOT_ANIMATION_UNLOCKED_PENDING =
{
    template = "ZO_ChampionStarUnlockedPendingAnimation",
    setup = function(texture)
        texture:SetTextureCoords(0, 1/8, 0, 1/4)
        texture:SetTexture("EsoUI/Art/Champion/champion_star_unlockedPending.dds")
        texture:SetBlendMode(TEX_BLEND_MODE_COLOR_DODGE)
    end,
}

ZO_CHAMPION_ONE_SHOT_ANIMATION_LOCKED_PENDING =
{
    template = "ZO_ChampionStarLockedPendingAnimation",
    setup = function(texture)
        texture:SetTextureCoords(0, 1/8, 0, 1/4)
        texture:SetTexture("EsoUI/Art/Champion/champion_star_unlockedPending.dds")
        texture:SetBlendMode(TEX_BLEND_MODE_COLOR_DODGE)
    end,
    reverse = true,
}

function ChampionPerks:AcquireOneShotAnimation(animationInfo, onReleaseCallback)
    if not animationInfo.pool then
        animationInfo.pool = ZO_AnimationPool:New(animationInfo.template)
    end

    local timeline, timelineKey = animationInfo.pool:AcquireObject()
    timeline.onReleaseCallback = onReleaseCallback
    timeline.key = timelineKey
    timeline.pool = animationInfo.pool
    timeline:SetHandler("OnStop", self.oneShotAnimationOnStopCallback)

    local texture, textureKey = self.oneShotAnimationTexturePool:AcquireObject()
    texture.key = textureKey
    if animationInfo.setup then
        animationInfo.setup(texture)
    end
    timeline:ApplyAllAnimationsToControl(texture)

    return timeline, texture
end

ZO_CHAMPION_STAR_CONFIRMATION_DELAY_MS = 50

local function SortConfirmStars(starA, starB)
    return CHAMPION_PERKS:SortConfirmStars(starA, starB)
end

function ChampionPerks:SortConfirmStars(starA, starB)
    local aScore = 0
    local bScore = 0
    --Show animations for the shown constellation first
    if self.chosenConstellation then
        local aShownScore = starA:GetConstellation() == self.chosenConstellation and 10 or 0
        local bShownScore = starB:GetConstellation() == self.chosenConstellation and 10 or 0
        aScore = aScore + aShownScore
        bScore = bScore + bShownScore
    end
    --Show animation on stars you can spend points in before ones you unlock automatically.
    local aCanSpendPointsScore = starA:CanSpendPoints() and 1 or 0
    local bCanSpendPointsScore = starB:CanSpendPoints() and 1 or 0

    aScore = aScore + aCanSpendPointsScore
    bScore = bScore + bCanSpendPointsScore

    return aScore > bScore
end

function ChampionPerks:PlayStarConfirmAnimations()
    for i = #self.starsToAnimateForConfirm, 1, -1 do
        local star = table.remove(self.starsToAnimateForConfirm, i)
        star:SetStateLocked(false)
    end

    self.nextConfirmAnimationTime = (GetGameTimeMilliseconds() + ZO_CHAMPION_STAR_CONFIRMATION_DELAY_MS) / 1000
    self.firstStarConfirm = true

    for _, constellation in ipairs(self.constellations) do
        for _, star in ipairs(constellation:GetStars()) do
            local animateStar = false
            if star:CanSpendPoints() then
                animateStar = star:GetNumPendingPoints() > 0
            else
                animateStar = star:WouldBePurchased()
            end
            if animateStar then
                star:SetStateLocked(true)
                table.insert(self.starsToAnimateForConfirm, star)
            end
        end
    end

    table.sort(self.starsToAnimateForConfirm, SortConfirmStars)

    if not self.confirmCameraTimeline then
        self.confirmCameraTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_ChampionConfirmCameraAnimation")
        self.confirmCameraPrepTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_ChampionConfirmCameraPrepAnimation")
    end
end

local CAMERA_SHAKE_MAGNITUDE_X = 1.5
local CAMERA_SHAKE_MAGNITUDE_Y = 0.75

function ChampionPerks:OnConfirmCameraShakeUpdate(timeline, progress)
    self:SetDeltaCameraX(math.sin(progress * math.pi * 2) * CAMERA_SHAKE_MAGNITUDE_X)
    self:SetDeltaCameraY(math.sin(progress * math.pi * 2 * 2) * CAMERA_SHAKE_MAGNITUDE_Y)
end

local CAMERA_PREP_MAGNITUDE_Z = 0.005

function ChampionPerks:OnConfirmCameraPrepUpdate(timeline, progress)
    self:SetDeltaCameraZ(progress * CAMERA_PREP_MAGNITUDE_Z)
end

function ChampionPerks:OnConfirmCameraPrepStop()
    self:SetDeltaCameraZ(0)
end

function ChampionPerks:IsRespecNeeded()
    return IsChampionRespecNeeded()
end

--Animation

local ZOOM_OUT_ANIMATION =
{
    targetCameraX = 0,
    targetCameraY = 0,
    targetCameraZ = ZOOMED_OUT_CAMERA_Z,
    startState = STATE_ZOOMING_OUT,
    endState = STATE_ZOOMED_OUT,
    duration = 0.75,
    nodePadding = {},
    easingFunction = ZO_EaseOutQuadratic,
    unchooseInstantly = true,
}

function ChampionPerks:ZoomOut()
    if self:IsZoomedIn() and not self:IsAnimating() then
        ZO_ClearTable(ZOOM_OUT_ANIMATION.nodePadding)
        for i, constellation in ipairs(self.constellations) do
            ZOOM_OUT_ANIMATION.nodePadding[constellation.node] = 0
        end
        PlaySound(SOUNDS.CHAMPION_ZOOM_OUT)
        self:SetAnimation(ZOOM_OUT_ANIMATION)
    end
end

local ZOOM_IN_ANIMATION =
{
    targetCameraX = 0,
    targetCameraY = ZOOMED_IN_CAMERA_Y,
    targetCameraZ = ZOOMED_IN_CAMERA_Z,
    targetNodeDurationBase = 0.75,
    targetNodeDurationMultiplier = 0.5 / math.pi,
    startState = STATE_ZOOMING_IN,
    endState = STATE_ZOOMED_IN,
    nodePadding = {},
    selectTargetNode = true,
    targetNodeSelectionPercentage = 1,
    easingFunction = ZO_EaseOutQuadratic,
}

function ChampionPerks:ZoomIn(node)
    if not self:IsZoomedIn() and not self:IsAnimating() then
        PlaySound(SOUNDS.CHAMPION_ZOOM_IN)
        ZOOM_IN_ANIMATION.targetNode = node
        ZO_ClearTable(ZOOM_IN_ANIMATION.nodePadding)
        ZOOM_IN_ANIMATION.nodePadding[node] = 0
        self:SetAnimation(ZOOM_IN_ANIMATION)
    end
end

local ZOOMED_IN_ROTATE_ANIMATION =
{
    duration = 0.5,
    nodePadding = {},
    selectTargetNode = true,
    targetNodeSelectionPercentage = 0.5,
    easingFunction = ZO_EaseOutQuadratic,
}

local CYCLE_SOUNDS = {
    [ATTRIBUTE_HEALTH] = SOUNDS.CHAMPION_CYCLED_TO_WARRIOR,
    [ATTRIBUTE_MAGICKA] = SOUNDS.CHAMPION_CYCLED_TO_MAGE,
    [ATTRIBUTE_STAMINA] = SOUNDS.CHAMPION_CYCLED_TO_THIEF,
}

function ChampionPerks:ZoomedInRotate(node)
    self:ClearAnimation()
    ZOOMED_IN_ROTATE_ANIMATION.targetNode = node
    self:SetAnimation(ZOOMED_IN_ROTATE_ANIMATION)
    PlaySound(CYCLE_SOUNDS[node.constellation:GetAttributeType()])
end

local ZOOMED_OUT_ROTATE_ANIMATION =
{
    duration = 0.5,
    easingFunction = ZO_EaseOutQuadratic,
}

function ChampionPerks:ZoomedOutRotate(node)
    if not self:IsAnimating() then
        ZOOMED_OUT_ROTATE_ANIMATION.targetNode = node
        self:SetAnimation(ZOOMED_OUT_ROTATE_ANIMATION)
    end
end

local ENTER_ANIMATION =
{
    duration = 0.85,
    targetCameraX = 0,
    targetCameraY = 0,
    targetCameraZ = ZOOMED_OUT_CAMERA_Z,
    easingFunction = ZO_EaseOutQuadratic,
    startState = STATE_ENTERING,
    endState = STATE_ZOOMED_OUT,
}

function ChampionPerks:PlayEnterAnimation()
    self:SetRootCameraX(0)
    self:SetRootCameraY(-800)
    self:SetRootCameraZ(-1.8)
    self:SetAnimation(ENTER_ANIMATION)
end

function ChampionPerks:SetRootCameraX(x)
    self.cameraRootX = x
    self:RefreshCameraPosition()
end

function ChampionPerks:SetRootCameraY(y)
    self.cameraRootY = y
    self:RefreshCameraPosition()
end

function ChampionPerks:SetRootCameraZ(z)
    self.cameraRootZ = z
    self:RefreshCameraPosition()
end

function ChampionPerks:SetDeltaCameraX(x)
    self.cameraDeltaX = x
    self:RefreshCameraPosition()
end

function ChampionPerks:SetDeltaCameraY(y)
    self.cameraDeltaY = y
    self:RefreshCameraPosition()
end

function ChampionPerks:SetDeltaCameraZ(z)
    self.cameraDeltaZ = z
    self:RefreshCameraPosition()
end

function ChampionPerks:RefreshCameraPosition()
    self.sceneGraph:SetCameraX(self.cameraRootX + self.cameraDeltaX)
    self.sceneGraph:SetCameraY(self.cameraRootY + self.cameraDeltaY)
    self.sceneGraph:SetCameraZ(self.cameraRootZ + self.cameraDeltaZ)
end

function ChampionPerks:ResetToZoomedOut()
    self.currentAnimation = nil
    self:SetState(STATE_ZOOMED_OUT)
    local UNCHOOSE_INSTANTLY = true
    self:SetChosenConstellation(nil, UNCHOOSE_INSTANTLY)
    for i, constellation in ipairs(self.constellations) do
        self.ring:SetNodePadding(constellation.node, 0)
    end
end

function ChampionPerks:SetAnimation(animation)
    if not self:IsAnimating() then
        self.currentAnimation = animation
        self.t = 0
        self.startCameraX = self.sceneGraph:GetCameraX()
        self.startCameraY = self.sceneGraph:GetCameraY()
        self.startCameraZ = self.sceneGraph:GetCameraZ()
        self.startAngle = self.ring:GetAngle()
        KEYBIND_STRIP:UpdateCurrentKeybindButtonGroups()
    end
end

function ChampionPerks:ClearAnimation()
    self.currentAnimation = nil
    KEYBIND_STRIP:UpdateCurrentKeybindButtonGroups()
end

function ChampionPerks:IsAnimating()
    return self.currentAnimation ~= nil
end

function ChampionPerks:SetState(state)
    if self.state ~= state then
        local lastState = self.state
        self.state = state
        self:RefreshApplicableInputTypeKeybinds()
        self:RefreshApplicableSharedKeybinds()
        if SCENE_MANAGER:IsCurrentSceneGamepad() then
            if state == STATE_ZOOMED_OUT then
                if self.lastChosenConstellation then
                    self:SetSelectedConstellation(self.lastChosenConstellation)
                end
            elseif state == STATE_ZOOMING_IN then
                self.radialSelectorNode:SetRotation(0)
            end
            if lastState == STATE_ENTERING then
                self.radialSelectorNode:SetRotation(0)
                self:SetSelectedConstellation(self.constellations[1])
            end
            if state == STATE_ZOOMED_IN then
                SCENE_MANAGER:AddFragment(self.gamepadChosenConstellationFragment)
            else
                self.gamepadChosenConstellationRightTooltip:ClearLines()
                SCENE_MANAGER:RemoveFragment(self.gamepadChosenConstellationFragment)
            end
        else
            if state == STATE_ZOOMED_IN then
                self.chosenConstellationInfoAlphaInterpolator:SetTargetBase(1)
            else
                self.chosenConstellationInfoAlphaInterpolator:SetTargetBase(0)
                self.chosenConstellationInfoAlphaInterpolator:SetCurrentValue(0)
            end
        end

        if state == STATE_ZOOMED_OUT then
            self.centerAlphaInterpolator:SetTargetBase(1)
            local active = AreChampionPointsActive()
            if not active then
                self.inactiveAlert.messageLabel:SetHidden(false)
                self:RefreshInactiveAlertMessage()
            else
                self.inactiveAlert.messageLabel:SetHidden(true)
            end
        else
            self.centerAlphaInterpolator:SetCurrentValue(0)
            self.centerAlphaInterpolator:SetTargetBase(0)
            self.centerInfo:SetAlpha(0)
            self.radialSelectorTexture:SetAlpha(0)
            self.inactiveAlert.messageLabel:SetHidden(true)
        end

        CHAMPION_PERKS_CHOSEN_ATTRIBUTE_TYPE_POINT_COUNTER_FRAGMENT:Refresh()
        CHAMPION_PERKS_CHOSEN_ATTRIBUTE_TYPE_EARNED_POINT_COUNTER_FRAGMENT:Refresh()
    end
end

function ChampionPerks:IsZoomedIn()
    return self.state == STATE_ZOOMED_IN
end

function ChampionPerks:UpdateAnimations(frameDeltaSecs)
    if self.currentAnimation then
        local anim = self.currentAnimation

        if self.t == 0 then
            if anim.startState then
                self:SetState(anim.startState)
            end

            local UNCHOOSE_SMOOTHLY = false
            self:SetChosenConstellation(nil, anim.unchooseInstantly or UNCHOOSE_SMOOTHLY)

            if anim.targetNode then
                --setup the final state to determine our target angle
                if anim.nodePadding then
                    for node, targetPadding in pairs(anim.nodePadding) do
                        node.ringPreviousPadding = self.ring:GetNodePadding(node)
                        self.ring:SetNodePadding(node, targetPadding)
                    end
                    self.ring:RefreshNodePositions()
                end

                anim.targetAngle = (-anim.targetNode:GetRotation() + math.pi * 0.5) % (2 * math.pi)

                if anim.nodePadding then
                    for node, targetPadding in pairs(anim.nodePadding) do
                        self.ring:SetNodePadding(node, node.ringPreviousPadding)
                        node.ringPreviousPadding = nil
                    end
                    self.ring:RefreshNodePositions()
                end

                local positiveFullDistance = zo_forwardArcSize(self.startAngle, anim.targetAngle)
                local negativeFullDistance = zo_backwardArcSize(self.startAngle, anim.targetAngle)
                if positiveFullDistance < negativeFullDistance then
                    anim.targetAngleDistance = positiveFullDistance
                    anim.targetAngleDirection = 1
                else
                    anim.targetAngleDistance = negativeFullDistance
                    anim.targetAngleDirection = -1
                end

                --compute duration based on distance travelled
                if anim.targetNodeDurationBase and anim.targetNodeDurationMultiplier then
                    anim.duration = anim.targetNodeDurationBase + anim.targetNodeDurationMultiplier * anim.targetAngleDistance
                end
            end
        end

        if self.t > anim.duration then
            self.t = anim.duration
        end

        local animProgress = self.t / anim.duration
        if anim.easingFunction then
            animProgress = anim.easingFunction(animProgress)
        end

        if anim.targetCameraX then
            self:SetRootCameraX(zo_lerp(self.startCameraX, anim.targetCameraX, animProgress))
        end
        if anim.targetCameraY then
            self:SetRootCameraY(zo_lerp(self.startCameraY, anim.targetCameraY, animProgress))
        end
        if anim.targetCameraZ then
            self:SetRootCameraZ(zo_lerp(self.startCameraZ, anim.targetCameraZ, animProgress))
        end

        if anim.nodePadding then
            for node, targetPadding in pairs(anim.nodePadding) do
                if animProgress == 0 then
                    node.startPadding = self.ring:GetNodePadding(node)
                else
                    local currentPadding = zo_lerp(node.startPadding, targetPadding, animProgress)
                    self.ring:SetNodePadding(node, currentPadding)
                end
            end
        end

        if anim.targetAngle then
            local currentAngle = self.startAngle + anim.targetAngleDirection * anim.targetAngleDistance * animProgress
            self.ring:SetAngle(currentAngle)
        end

        if anim.targetNode then
            if anim.selectTargetNode and self.t >= anim.duration * anim.targetNodeSelectionPercentage then
                local UNCHOOSE_SMOOTHLY = false
                self:SetChosenConstellation(anim.targetNode.constellation, UNCHOOSE_SMOOTHLY)
            end
        end

        if self.t == anim.duration then
            if anim.endState then
                self:SetState(anim.endState)
            end

            self:ClearAnimation()
        else
            self.t = self.t + frameDeltaSecs
        end
    end
end

function ChampionPerks:UpdateCenterAlpha(timeSecs, frameDeltaSecs)
    local centerAlpha = self.centerAlphaInterpolator:Update(timeSecs, frameDeltaSecs)
    self.centerInfo:SetAlpha(centerAlpha)
    self.radialSelectorTexture:SetAlpha(centerAlpha)
end

--Gamepad Input

function ChampionPerks:UpdateDirectionalInput()
    if not (self:IsZoomedIn() or self.state == STATE_ENTERING) then
        local dx, dy = DIRECTIONAL_INPUT:GetXY(ZO_DI_LEFT_STICK)
        local magSq = dx * dx + dy * dy
        if magSq > 0.04 and (self.radialSelectorLastMagSq == nil or magSq + 0.01 >= self.radialSelectorLastMagSq) then
            local angle = math.atan2(dy, dx)
            local closestNodeToGamepadDirection = self.ring:GetNodeAtAngle(angle)
            self:SetSelectedConstellation(closestNodeToGamepadDirection.constellation)
            self.radialSelectorNode:SetRotation(angle - math.pi * 0.5)
        end
        self.radialSelectorLastMagSq = zo_min(0.85, magSq)
    end
end

--Setup

function ChampionPerks:DumpNormalizedCoordinates()
    if self.chosenConstellation then
        d(NormalizeMousePositionToControl(self.chosenConstellation.rotatedNode:GetControl(1)))
    else
        d("Select a constellation first.")
    end
end

--Events

local VISUALS =
{
    ZOOMED_OUT =
    {
        glowAlpha =
        {
            base = 0.25,
            fluxMagnitude = 0.25,
            fluxRate = 2,
        },
        starAlpha =
        {
            base = 0.3,
        },
    },
    ZOOMED_OUT_SELECTED =
    {
        mouseoverScale =
        {
            base = 2,
        },
        mouseoverAlpha =
        {
            base = 0.85,
            fluxMagnitude = 0.15,
            fluxRate = 1,
        },
        starAlpha =
        {
            base = 1,
        },
    },
    ZOOMED_OUT_SELECTED_ZOOMING_IN =
    {
        starAlpha =
        {
            base = 1,
        },
        glowAlpha =
        {
            base = 0.8,
        },
    },
    ZOOMED_IN_CHOSEN =
    {
        glowAlpha =
        {
            base = 0.8,
            fluxMagnitude = 0.2,
            fluxRate = 2,
        },
    },
    ZOOMED_IN_NEXT_OVER =
    {
        starAlpha =
        {
            base = 0.7,
        },
    },
    ZOOMED_IN_NEXT =
    {
        glowAlpha =
        {
            base = 0,
        },
        constellationAlpha =
        {
            base = 1,
        },
        starAlpha =
        {
            base = 0.3,
        },
    },
    ZOOMED_IN_NOT_SHOWN =
    {
        glowAlpha =
        {
            base = 0,
        },
        constellationAlpha =
        {
            base = 1,
        },
        starAlpha =
        {
            base = 0,
        },
    },
}

local CENTER_INFO_POINT_COUNTER_ALPHA_UP = 0.5
local CENTER_INFO_POINT_COUNTER_SCALE_UP = 0.2
local CONFIRM_ANIMATION_SPACING = 0.3

function ChampionPerks:OnUpdate(timeSecs)
    if not self.prevTimeSecs then
        self.prevTimeSecs = timeSecs
    end

    local frameDeltaSecs = zo_min(timeSecs - self.prevTimeSecs, 0.25)

    if not SCENE_MANAGER:IsCurrentSceneGamepad() then
        self:UpdateZoomedInMouseoverPositions()
        if self.state == STATE_ZOOMING_IN then
            --Maintain the selection while zooming in
        elseif self.state == STATE_ZOOMED_OUT then
            local mx, my = GetUIMousePosition()
            local cx, cy = self.canvasControl:GetCenter()
            local dx = mx - cx
            local dy = my - cy
            local angle = math.atan2(-dy, dx)
            local closestNodeToMouse = self.ring:GetNodeAtAngle(angle)
            if closestNodeToMouse then
                self:SetSelectedConstellation(closestNodeToMouse.constellation)
            else
                self:SetSelectedConstellation(nil)
            end
            self.radialSelectorNode:SetRotation(angle - math.pi * 0.5)
        else
            self:SetSelectedConstellation(nil)
        end
    end

    --Visual State
    for i, constellation in ipairs(self.constellations) do
        local visualInfo
        if self:IsZoomedIn() then
            if constellation == self.chosenConstellation then
                visualInfo = VISUALS.ZOOMED_IN_CHOSEN
            elseif constellation == self.leftOfChosenConstellation then
                if self:IsMouseOverLeftConstellation() and not SCENE_MANAGER:IsCurrentSceneGamepad() then
                    visualInfo = VISUALS.ZOOMED_IN_NEXT_OVER
                else
                    visualInfo = VISUALS.ZOOMED_IN_NEXT
                end
            elseif constellation == self.rightOfChosenConstellation then
                if self:IsMouseOverRightConstellation() and not SCENE_MANAGER:IsCurrentSceneGamepad() then
                    visualInfo = VISUALS.ZOOMED_IN_NEXT_OVER
                else
                    visualInfo = VISUALS.ZOOMED_IN_NEXT
                end
            else
                visualInfo = VISUALS.ZOOMED_IN_NOT_SHOWN
            end
        else
            if constellation == self.selectedConstellation then
                if self.state == STATE_ZOOMING_IN then
                    visualInfo = VISUALS.ZOOMED_OUT_SELECTED_ZOOMING_IN
                else
                    visualInfo = VISUALS.ZOOMED_OUT_SELECTED
                end
            else
                visualInfo = VISUALS.ZOOMED_OUT
            end
        end

        constellation:SetVisualInfo(visualInfo)
        constellation:UpdateVisuals(timeSecs, frameDeltaSecs)
    end

    --Cloud Rotation
    self.cloudsNode:SetRotation(self.cloudsNode:GetRotation() + 0.03 * frameDeltaSecs)
    self.skyCloudsNode:SetRotation(self.skyCloudsNode:GetRotation() + 0.01 * frameDeltaSecs)
    self.smokeNode:SetRotation(self.smokeNode:GetRotation() + 0.05 * frameDeltaSecs)    
    
    if self.state == STATE_ZOOMED_IN then
        if not self.enteredZoomedInAt then
            self.enteredZoomedInAt = timeSecs
        end
        local timeSinceAnimStart = timeSecs - self.enteredZoomedInAt
        self.smokeTexture:SetAlpha(zo_min(1, timeSinceAnimStart * 0.5))
    else
        self.enteredZoomedInAt = nil
        self.smokeTexture:SetAlpha(0)
    end

    self.chosenConstellationContainer:SetAlpha(self.chosenConstellationInfoAlphaInterpolator:Update(timeSecs, frameDeltaSecs))

    self:UpdateCenterAlpha(timeSecs, frameDeltaSecs)
    self:UpdateAnimations(frameDeltaSecs)
    self.ring:Update(frameDeltaSecs)

    --Center Point Counter Scaling
    for i, centerInfoPointCounter in ipairs(self.centerInfoPointCounters) do
        local attribute = CHAMPION_ATTRIBUTES[i]
        local selectedness = centerInfoPointCounter.interpolator:Update(timeSecs, frameDeltaSecs)
        centerInfoPointCounter.iconTexture:SetScale(1 + selectedness * CENTER_INFO_POINT_COUNTER_SCALE_UP)
        centerInfoPointCounter:SetAlpha(selectedness * CENTER_INFO_POINT_COUNTER_ALPHA_UP + (1 - CENTER_INFO_POINT_COUNTER_ALPHA_UP))
        local texture
        if selectedness > 0.2 then
            texture = GetChampionPointAttributeActiveIcon(attribute)
        else
            texture = GetChampionPointAttributeIcon(attribute)
        end
        centerInfoPointCounter.iconTexture:SetTexture(texture)
    end

    --Close Cloud Breathing
    if self.state == STATE_ZOOMED_OUT or self.state == STATE_ENTERING then
        if not self.closeCloudsTimeline:IsPlaying() then
            self.closeCloudsTimeline:PlayFromStart()
        end
    else
        self.closeCloudsTimeline:PlayInstantlyToStart()
        self.closeCloudsTimeline:Stop()
    end

    local zoomedness = 1 - (self.sceneGraph:GetCameraZ() - ZOOMED_OUT_CAMERA_Z) / (ZOOMED_IN_CAMERA_Z - ZOOMED_OUT_CAMERA_Z)
    local minAlpha = 0.2
    self.colorCloudsTexture:SetAlpha(minAlpha + (1 - minAlpha) * zoomedness)

    --Star Confirm Animations
    if #self.starsToAnimateForConfirm > 0 and timeSecs > self.nextConfirmAnimationTime then
        self.nextConfirmAnimationTime = timeSecs + CONFIRM_ANIMATION_SPACING
        local star = table.remove(self.starsToAnimateForConfirm, 1)
        if star:CanSpendPoints() then
            star:PlayOneShotAnimation(ZO_CHAMPION_ONE_SHOT_ANIMATION_CONFIRM)
        else
            star:PlayOneShotAnimation(ZO_CHAMPION_ONE_SHOT_ANIMATION_UNLOCKED_CONFIRM)
        end
        if self.firstStarConfirm then
            self.firstStarConfirm = false
            self.confirmCameraPrepTimeline:PlayFromStart()
            self.confirmCameraTimeline:PlayFromStart()
        end
    end

    self:CleanDirty()

    self.prevTimeSecs = timeSecs
end

local SPIRAL_STAR_MAX_ALPHA = 0.5
local SPIRAL_STAR_ANGLE_DISTANCE = math.pi * 0.25

function ChampionPerks:OnSpiralUpdate(animation, progress)
    local progressDelta = 1 / #self.starSpiralNodes
    for i, node in ipairs(self.starSpiralNodes) do
        local adjustedProgress = (progress + (i - 1) * progressDelta) % 1
        node:SetZ(STAR_SPIRAL_START_DEPTH + adjustedProgress * (STAR_SPIRAL_END_DEPTH - STAR_SPIRAL_START_DEPTH))
        local textureControl = node:GetControl(1)
        if adjustedProgress < 0.1 then
            textureControl:SetAlpha(adjustedProgress * 10 * SPIRAL_STAR_MAX_ALPHA)
        elseif adjustedProgress < 0.9 then
            textureControl:SetAlpha(SPIRAL_STAR_MAX_ALPHA)
        else
            textureControl:SetAlpha((1 - (adjustedProgress - 0.9) * 10) * SPIRAL_STAR_MAX_ALPHA)
        end
        node:SetControlScale(textureControl, 0.5 * (1 - adjustedProgress) + 0.5)
        node:SetRotation(adjustedProgress * SPIRAL_STAR_ANGLE_DISTANCE)
    end
end

function ChampionPerks:OnSpiralStop(timeline)
    timeline:PlayFromStart()
end

function ChampionPerks:OnChampionPointGained()
    TriggerTutorial(TUTORIAL_TRIGGER_CHAMPION_POINT_GAINED)
    self:RefreshChosenAttributeEarnedPointCounter()
end

function ChampionPerks:OnChampionSystemUnlocked()
    TriggerTutorial(TUTORIAL_TRIGGER_CHAMPION_SYSTEM_UNLOCKED)
    self:SetChampionSystemNew(true)
end

function ChampionPerks:OnUnspentChampionPointsChanged()
    if self.initialized then
        if not self.awaitingSpendPointsResponse then
            self:RefreshUnspentPoints()
            self:RefreshMenuIndicators()
            self:MarkDirty()
        end
    else
        --update menus even before the system is initialized
        self:RefreshUnspentPoints()
        self:RefreshMenuIndicators()
    end
end

function ChampionPerks:MarkDirty()
    self.dirty = true
end

function ChampionPerks:CleanDirty()
    if self.dirty then
        self:RefreshAvailablePointDisplays()
        self:RefreshConstellationStarStates()
        self:RefreshChosenConstellationStarMinMax()
        self:RefreshChosenConstellationInfo()
        self:RefreshSelectedConstellationInfo()
        KEYBIND_STRIP:UpdateCurrentKeybindButtonGroups()
        self.hasUnsavedChanges = self:HasUnsavedChanges()
        self.dirty = false
    end
end

function ChampionPerks:OnChampionPurchaseResult(result)
    self.awaitingSpendPointsResponse = false

    if result == CHAMPION_PURCHASE_SUCCESS then
        --depends on the pending points and respec mode not being reset yet
        self:PlayStarConfirmAnimations()
    end

    SetChampionIsInRespecMode(false)
    self:ResetPendingPoints()
    self:RefreshConstellationSpentPoints()

    --depends on pending and spent points being updated
    self:RefreshConstellationStarStates()

    self:RefreshUnspentPoints()
    self:RefreshAvailablePointDisplays()
    self:RefreshChosenConstellationInfo()
    self:RefreshMenuIndicators()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.sharedKeybindStripDescriptor)
end

function ChampionPerks:OnSelectedStarChanged()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.gamepadZoomedInKeybindStripDescriptor)
end

function ChampionPerks:OnMoneyChanged()
    if self:IsInRespecMode() then
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.sharedKeybindStripDescriptor)
    end
end

function ChampionPerks:OnPlayerActivated()
    if SYSTEMS:IsShowing("champion") then
        --Refresh confirm and redistribute keybinds (which can be disabled by being in an AvA campaign) on loading into a new zone
        self:RefreshApplicableSharedKeybinds()
    end
    --If we jumped somewhere just reset everything to zero since the backend was destroyed which means C++ thinks we have no pending points.
    --If the system isn't initialized this means that the UI was reloaded so we don't clear in that case.
    if self.initialized and self.hasUnsavedChanges then
        self:ResetPendingPoints()
        self:MarkDirty()
        ZO_Alert(UI_ALERT_CATEGORY_ALERT, SOUNDS.NEGATIVE_CLICK, GetString(SI_CHAMPION_UNSAVED_CHANGES_RESET_ALERT))
    end
end

function ChampionPerks:OnPowerUpdate(eventCode, unitTag, powerIndex, powerType, value, max, effectiveMax)
    if unitTag == "player" and powerType == POWERTYPE_HEALTH then
        if IsUnitInCombat("player") and value < self.lastHealthValue then
             PlaySound(SOUNDS.CHAMPION_DAMAGE_TAKEN)
        end
        self.lastHealthValue = value
    end
end

--Menu Bar

function ChampionPerks:RefreshMenuIndicators()
    MAIN_MENU_GAMEPAD:RefreshLists()
    if not IsConsoleUI() then
        MAIN_MENU_KEYBOARD:RefreshCategoryIndicators()
    end
end

function ChampionPerks:RefreshMenus()
    MAIN_MENU_GAMEPAD:RefreshLists()
    if not IsConsoleUI() then
        MAIN_MENU_KEYBOARD:RefreshCategoryBar()
    end
end

--Local XML Handlers

function ChampionPerks:Canvas_OnMouseUp(button)
    if button == MOUSE_BUTTON_INDEX_LEFT then
        if self:IsZoomedIn() then
            if self.chosenConstellation then
                if self:IsMouseOverLeftConstellation() then
                    self:ZoomedInRotate(self.leftOfChosenConstellation.node)
                elseif self:IsMouseOverRightConstellation() then
                    self:ZoomedInRotate(self.rightOfChosenConstellation.node)
                end
            end
        else
            if self.selectedConstellation then
                self:ZoomIn(self.selectedConstellation.node)
            end
        end
    elseif button == MOUSE_BUTTON_INDEX_RIGHT then
        if self:IsZoomedIn() then
            self:ZoomOut()
        end
    end
end

--Global XML Handlers

function ZO_ChampionPerksGamepad_TooltipResizeHandler(control)
    local maxHeight = 540
    control:SetDimensionConstraints(0, 0, 0, maxHeight)
end

function ZO_ChampionPerksCanvas_OnMouseUp(button)
    CHAMPION_PERKS:Canvas_OnMouseUp(button)
end

function ZO_ChampionPerks_OnInitialized(self)
    CHAMPION_PERKS = ChampionPerks:New(self)
    CHAMPION_PERKS:RefreshMenus()
end
