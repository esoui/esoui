local SKY_CLOUD_DEPTH = -0.3
local CLOSE_CLOUDS_DEPTH = 0
local STAR_SPIRAL_START_DEPTH = 1
local STAR_SPIRAL_END_DEPTH = 1.3
local CENTER_INFO_BG_DEPTH = 1.65
local SMOKE_DEPTH = 1.7
local CLOUDS_DEPTH = 1.71
local CONSTELLATIONS_DARKNESS_DEPTH = 1.72
local SKY_DEPTH = 5
local ONE_SIXTH_PI = ZO_PI / 6

ZO_CHAMPION_GAMEPAD_ZOOMED_IN_CAMERA_Y = 1000
ZO_CHAMPION_GAMEPAD_ZOOMED_IN_CAMERA_Z = 1.3
ZO_CHAMPION_GAMEPAD_ZOOMED_IN_CLUSTER_CAMERA_Z = 2.3
ZO_CHAMPION_KEYBOARD_ZOOMED_IN_CAMERA_Y = 1035
ZO_CHAMPION_KEYBOARD_ZOOMED_IN_CAMERA_Z = 1.1
ZO_CHAMPION_KEYBOARD_ZOOMED_IN_CLUSTER_CAMERA_Z = 2.1
ZO_CHAMPION_ZOOMED_OUT_CAMERA_Y = 800
ZO_CHAMPION_ZOOMED_OUT_CAMERA_Z = 0
ZO_CHAMPION_INITIAL_CAMERA_Y = 800
ZO_CHAMPION_INITIAL_CAMERA_Z = -1
ZO_CHAMPION_CENTERED_CONSTELLATION_INDEX = 2
--Champion computes all of its sizes off of a reference camera depth of -1 since it uses two camera levels. What the reference depth is doesn't really matter,
--it's just important that it stays constant so we can use one measurement system at both zoom levels.
ZO_CHAMPION_REFERENCE_CAMERA_Z = -1

local KEYBIND_STATES =
{
    NONE = 0,
    OVERVIEW = 1,
    CONSTELLATION = 2,
    ACTION_BAR = 3,
    QUICK_MENU = 4,
}

local KEYBOARD_PLATFORM_STYLE =
{
    INACTIVE_ALERT =
    {
        modifyTextType = MODIFY_TEXT_TYPE_NONE,
        font = "ZoFontWinH1",
        offsetX = 10,
        offsetY = 20,
    },
}
local GAMEPAD_PLATFORM_STYLE =
{
    INACTIVE_ALERT =
    {
        modifyTextType = MODIFY_TEXT_TYPE_UPPERCASE,
        font = "ZoFontGamepad42",
        offsetX = 100,
        offsetY = 50,
    },
}

--Champion Perks
----------------------

local ChampionPerks = ZO_DeferredInitializingObject:Subclass()

function ChampionPerks:Initialize(control)
    self.control = control

    CHAMPION_PERKS_SCENE = ZO_Scene:New("championPerks", SCENE_MANAGER)
    CHAMPION_PERKS_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_HIDDEN then
            WINDOW_MANAGER:SetMouseCursor(MOUSE_CURSOR_DO_NOT_CARE)
        end
    end)

    GAMEPAD_CHAMPION_PERKS_SCENE = ZO_Scene:New("gamepad_championPerks_root", SCENE_MANAGER)
    GAMEPAD_CHAMPION_PERKS_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            DIRECTIONAL_INPUT:Activate(self, control)
        elseif newState == SCENE_SHOWN then
            CALLBACK_MANAGER:RegisterCallback("OnGamepadDialogShowing", self.OnGamepadDialogShowing)
        elseif newState == SCENE_HIDING then
            DIRECTIONAL_INPUT:Deactivate(self)
            self.gamepadStarTooltip.scrollTooltip:ClearLines()
            self.gamepadCursor:UpdateVisibility()
            CALLBACK_MANAGER:UnregisterCallback("OnGamepadDialogShowing", self.OnGamepadDialogShowing)
        end
    end)

    local championPerksSceneGroup = ZO_SceneGroup:New("championPerks", "gamepad_championPerks_root")

    ZO_DeferredInitializingObject.Initialize(self, championPerksSceneGroup)

    SYSTEMS:RegisterKeyboardRootScene("champion", CHAMPION_PERKS_SCENE)
    SYSTEMS:RegisterGamepadRootScene("champion", GAMEPAD_CHAMPION_PERKS_SCENE)

    self.refreshGroup = ZO_OrderedRefreshGroup:New(ZO_ORDERED_REFRESH_GROUP_AUTO_CLEAN_PER_FRAME)
    self.refreshGroup:SetActive(function() return SYSTEMS:IsShowing("champion") end)
    self.refreshGroup:AddDirtyState("AllData", function()
        self:RefreshConstellationStates()
        self:RefreshStarEditors()
        self:RefreshStatusInfo()
        self:RefreshSelectedConstellationInfo()
        self:RefreshSelectedStarTooltip()
        self:RefreshKeybinds()
    end)

    self.refreshGroup:AddDirtyState("ChosenConstellationData", function()
        self:RefreshChosenConstellationState()
        self:RefreshStarEditors()
        self:RefreshStatusInfo()
        self:RefreshSelectedConstellationInfo()
        self:RefreshSelectedStarTooltip()
        self:RefreshKeybinds()
    end)

    self.refreshGroup:AddDirtyState("Points", function()
        self:RefreshStatusInfo()
        self:RefreshSelectedConstellationInfo()
        self:RefreshSelectedStarTooltip()
        self:RefreshKeybinds()
    end)

    self.refreshGroup:AddDirtyState("SelectedStarData", function()
        self:RefreshSelectedStarTooltip()
        self:RefreshKeybinds()
    end)

    self.refreshGroup:AddDirtyState("KeybindStrip", function()
        self:RefreshKeybinds()
    end)

    self:RegisterForEvents()

    self:RefreshMenus()
end

function ChampionPerks:OnDeferredInitialize()
    self.canvasControl = self.control:GetNamedChild("Canvas")
    self.championBar = ZO_ChampionAssignableActionBar:New(self.control:GetNamedChild("ActionBar"))
    self.gamepadCursor = ZO_ChampionConstellationCursor_Gamepad:New(self.control:GetNamedChild("GamepadCursor"))

    self.isChampionSystemNew = false
    self.keybindState = KEYBIND_STATES.NONE
    self:SetupCustomConfirmDialog()

    --for menu indicators / conditional button showing
    self:InitializeStateMachine()
    self:DeferredRegisterForEvents()

    self.starTextureControlPool = ZO_ControlPool:New("ZO_ChampionStar", self.canvasControl, "Star")
    for i = 1, GetNumChampionNodesToPreallocate() do
        self.starTextureControlPool:AcquireObject()
    end
    self.starTextureControlPool:ReleaseAllObjects()

    self.starEditorPool = ZO_ObjectPool:New(ZO_ChampionStarEditor, ZO_ChampionStarEditor.Release)

    self.starLinkControlPool = ZO_ControlPool:New("ZO_ChampionStarLink", self.canvasControl, "Link")
    for i = 1, GetNumChampionLinksToPreallocate() do
        self.starLinkControlPool:AcquireObject()
    end
    self.starLinkControlPool:ReleaseAllObjects()

    self.clusterBackgroundControlPool = ZO_ControlPool:New("ZO_Cluster", self.canvasControl, "Cluster")

    self.starConfirmedTextureControlPool = ZO_ControlPool:New("ZO_ChampionStarConfirmAnimationTexture", self.canvasControl, "StarConfirmed")
    self.starConfirmedTextureControlPool:SetCustomFactoryBehavior(function(control)
        control.timeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_ChampionStarConfirmAnimation", control)
    end)

    self.inactiveAlert = self.control:GetNamedChild("InactiveAlert")

    self.keyboardConstellationViewControl = self.control:GetNamedChild("KeyboardConstellationView")

    self.gamepadChosenConstellationControl = self.control:GetNamedChild("ChosenConstellationGamepad")
    self.gamepadConstellationViewControl = self.control:GetNamedChild("GamepadConstellationView")
    self.gamepadStarTooltip = ChampionGamepadStarTooltip

    local ALWAYS_ANIMATE = true
    self.keyboardConstellationViewFragment = ZO_FadeSceneFragment:New(self.keyboardConstellationViewControl, ALWAYS_ANIMATE)
    self.gamepadConstellationViewFragment = ZO_FadeSceneFragment:New(self.gamepadConstellationViewControl, ALWAYS_ANIMATE)
    self.gamepadChosenConstellationFragment = ZO_FadeSceneFragment:New(self.gamepadChosenConstellationControl, ALWAYS_ANIMATE)

    self.OnGamepadDialogShowing = function()
        local editor = self:GetSelectedStarEditor()
        if editor then
            editor:StopChangingPoints()
        end
    end

    CHAMPION_DATA_MANAGER:RegisterCallback("DataChanged", function()
        self.constellationsInitialized = false
        if SYSTEMS:IsShowing("champion") then
            -- reset to top level view
            self:ResetToInactive()
            self:PerformDeferredInitializationConstellations()
            self.stateMachine:FireCallbacks("ON_DATA_RELOADED")
        end
    end)

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

    self.centerInfoControl = self.control:GetNamedChild("CenterInfo")
    self.centerInfoNameLabel = self.centerInfoControl:GetNamedChild("Name")
    self.centerInfoPointPoolLabel = self.centerInfoControl:GetNamedChild("PointPool")
    self.centerInfoAlphaInterpolator = ZO_LerpInterpolator:New(0)

    self.keyboardStatusControl = self.control:GetNamedChild("KeyboardStatus")
    self.keyboardStatusNameLabel = self.keyboardStatusControl:GetNamedChild("ConstellationName")
    self.keyboardStatusPointValueLabel = self.keyboardStatusControl:GetNamedChild("PointValue")
    self.keyboardStatusAlphaInterpolator = ZO_LerpInterpolator:New(0)
    self.keyboardStatusAlphaInterpolator:SetApproachFactor(0.2)

    self.selectedStarIndicatorTexture = self.control:GetNamedChild("SelectedStarIndicator")
    self.selectedStarIndicatorTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_SelectedStarIndicatorAnimation", self.selectedStarIndicatorTexture)
    self.selectedStarIndicatorTimeline:PlayForward()
    self.selectedStarIndicatorAppearTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_SelectedStarIndicatorAppearAnimation", self.selectedStarIndicatorTexture)

    self:CreateCloseCloudsAnimation()

    self.cameraRootX = 0
    self.cameraRootY = 0
    self.cameraRootZ = 0
    self.cameraAnimationOffsetX = 0
    self.cameraAnimationOffsetY = 0
    self.cameraAnimationOffsetZ = 0
    self.cameraPanX = 0
    self.cameraPanY = 0
    self.cameraPanZ = 0

    self.constellationInnerRadius = ZO_CHAMPION_CONSTELLATION_INNER_RADIUS
    self.constellationHeight = ZO_CHAMPION_CONSTELLATION_HEIGHT
    self.constellationOuterRadius = self.constellationInnerRadius + self.constellationHeight

    self.oneShotAnimationTexturePool = ZO_ControlPool:New("ZO_ChampionOneShotAnimationTexture", self.canvasControl)
    self.oneShotAnimationOnStopCallback = function(timeline)
        local texture = timeline:GetFirstAnimation():GetAnimatedControl()
        timeline.onReleaseCallback(texture)
        self.oneShotAnimationTexturePool:ReleaseObject(texture.key)
        timeline.pool:ReleaseObject(timeline.key)
    end

    self:InitializeKeybindStrips()
    self:BuildSceneGraph()
    self:RefreshStatusInfo()

    self.platformStyle = ZO_PlatformStyle:New(function(style) self:ApplyPlatformStyle(style) end, KEYBOARD_PLATFORM_STYLE, GAMEPAD_PLATFORM_STYLE)

    -- constellations use their own initialization flag
    self:PerformDeferredInitializationConstellations()
end

function ChampionPerks:OnShowing()
    -- constellations use their own initialization flag
    self:PerformDeferredInitializationConstellations()

    --Hacky solution to get around the fact that we can potentially get here before the style gets set in ZO_GamepadKeybindStripFragment:Show
    --We need to make sure the style is properly set so PushKeybindGroupState can store the intended values 
    if IsInGamepadPreferredMode() then
        KEYBIND_STRIP:SetStyle(KEYBIND_STRIP_GAMEPAD_STYLE)
    end

    self.keybindStripId = KEYBIND_STRIP:PushKeybindGroupState()
    KEYBIND_STRIP:RemoveDefaultExit(self.keybindStripId)
    self:RefreshKeybinds()

    self.stateMachine:FireCallbacks("ON_SHOWING")
    SetShouldRenderWorld(false)
    self.control:RegisterForEvent(EVENT_GUI_UNLOADING, function()
        -- Failsafe
        SetShouldRenderWorld(true)
    end)
    self:SetChampionSystemNew(false)

    self.lastHealthValue = GetUnitPower("player", COMBAT_MECHANIC_FLAGS_HEALTH)
    self.control:RegisterForEvent(EVENT_POWER_UPDATE, function(...) self:OnPowerUpdate(...) end)
    self.refreshGroup:TryClean()

end

function ChampionPerks:OnShown()
    TriggerTutorial(TUTORIAL_TRIGGER_CHAMPION_UI_SHOWN)
end

function ChampionPerks:OnHiding()
    SetShouldRenderWorld(true)
    self.control:UnregisterForEvent(EVENT_GUI_UNLOADING)

    self:ResetToInactive()
    KEYBIND_STRIP:PopKeybindGroupState()
    self.keybindState = KEYBIND_STATES.NONE
    self.keybindStripId = nil

    self.control:UnregisterForEvent(EVENT_POWER_UPDATE)
    self.lastHealthValue = nil  
end

function ChampionPerks:OnHidden()
    if self:HasUnsavedChanges() and GetChampionPurchaseAvailability() == CHAMPION_PURCHASE_SUCCESS then
        ZO_Alert(UI_ALERT_CATEGORY_ALERT, SOUNDS.NEGATIVE_CLICK, GetString(SI_CHAMPION_UNSAVED_CHANGES_EXIT_ALERT))
    end
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
                ZO_CurrencyControl_SetSimpleCurrency(customControl:GetNamedChild("BalanceAmount"), CURT_MONEY, GetCurrencyAmount(CURT_MONEY, CURRENCY_LOCATION_CHARACTER))
                ZO_CurrencyControl_SetSimpleCurrency(customControl:GetNamedChild("RespecCost"), CURT_MONEY, GetChampionRespecCost())
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
        local editor = self:GetSelectedStarEditor()
        if editor then
            editor:StopChangingPoints()
        end
    end
    ZO_Dialogs_ShowPlatformDialog(name, data, textParams)
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

function ChampionPerks:PerformDeferredInitializationConstellations()
    if not self.constellationsInitialized then
        self.constellationsInitialized = true

        self.starTextureControlPool:ReleaseAllObjects()
        self.starEditorPool:ReleaseAllObjects()
        self.starLinkControlPool:ReleaseAllObjects()
        self.clusterBackgroundControlPool:ReleaseAllObjects()

        self.constellations = {}
        for disciplineIndex, disciplineData in CHAMPION_DATA_MANAGER:ChampionDisciplineDataIterator() do
            self.constellations[disciplineIndex] = ZO_ChampionConstellation:New(disciplineData, self.sceneGraph)
        end

        -- Adding two copies of each constellation to ring to get an endless circle where only half is visible at a time
        local numConstellations = #self.constellations
        for anchorIndex, ringAnchor in ipairs(self.ringAnchors) do
            local constellationIndex = (anchorIndex - 1) % numConstellations + 1 -- subtract and add to handle index-by-one
            local constellation = self.constellations[constellationIndex]
            if anchorIndex <= numConstellations then
                ringAnchor:SetConstellation(constellation)
                constellation:SetFirstRingAnchor(ringAnchor)
            else
                ringAnchor:SetConstellation(constellation)
                constellation:SetSecondRingAnchor(ringAnchor)
            end
        end

        self.starsToAnimateForConfirm = {}
        self.chosenConstellation = nil
        self.chosenRingNode = nil
        self.selectedConstellation = nil
        self.selectedRingNode = nil
        self.championBar:ResetAllSlots()
    end
end

function ChampionPerks:GetGamepadStarTooltip()
    return self.gamepadStarTooltip
end

function ChampionPerks:InitializeKeybindStrips()
    local function AlignLeftOnGamepadRightOnKeyboard()
        if IsInGamepadPreferredMode() then
            return KEYBIND_STRIP_ALIGN_LEFT
        else
            return KEYBIND_STRIP_ALIGN_RIGHT
        end
    end

    local function AlignRightOnGamepadCenterOnKeyboard()
        if IsInGamepadPreferredMode() then
            return KEYBIND_STRIP_ALIGN_RIGHT
        else
            return KEYBIND_STRIP_ALIGN_CENTER
        end
    end

    self.respecActionsKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,
        {
            name = function()
                if CHAMPION_DATA_MANAGER:IsRespecNeeded() then
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
                local result = GetChampionPurchaseAvailability()
                if result ~= CHAMPION_PURCHASE_SUCCESS then
                    return false, GetString("SI_CHAMPIONPURCHASERESULT", result), KEYBIND_STRIP_DISABLED_DIALOG
                end

                if CHAMPION_DATA_MANAGER:IsRespecNeeded() then
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
            gamepadPreferredKeybind = "UI_SHORTCUT_QUINARY",
            callback = function() self:ToggleRespecMode() end,
            visible = function()
                if not self:IsInRespecMode() then
                    return CHAMPION_DATA_MANAGER:HasAnySavedSpentPoints()
                else
                    return true
                end
            end,
            enabled = function()
                local result = GetChampionPurchaseAvailability()
                if result ~= CHAMPION_PURCHASE_SUCCESS then
                    return false, GetString("SI_CHAMPIONPURCHASERESULT", result), KEYBIND_STRIP_DISABLED_DIALOG
                end
            end,
        },
        {
            alignment = AlignRightOnGamepadCenterOnKeyboard,
            name = function() 
                return self:IsInRespecMode() and GetString(SI_CHAMPION_SYSTEM_CLEAR_POINTS) or GetString(SI_CHAMPION_SYSTEM_DISCARD_CHANGES)
            end,
            keybind = "UI_SHORTCUT_NEGATIVE",
            gamepadPreferredKeybind = "UI_SHORTCUT_RIGHT_STICK",
            callback = function()
                self:ClearUnsavedChanges()
                CHAMPION_DATA_MANAGER:ClearAllPoints()
            end,
            visible = function()
                return CHAMPION_DATA_MANAGER:HasPointsToClear() or self:HasUnsavedChanges()
            end,
            sound = SOUNDS.CHAMPION_PENDING_POINTS_CLEARED,
        }
    }

    self.overviewKeybindStripDescriptor =
    {
        alignment = AlignLeftOnGamepadRightOnKeyboard,
        {
            name = GetString(SI_CHAMPION_CONSTELLATION_ZOOM_IN),
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                self:ChooseConstellationNode(self.selectedRingNode)
            end,
            enabled = function() return not self:IsAnimating() and self.selectedConstellation ~= nil end,
        },
        {
            name = function()
                if IsInGamepadPreferredMode() then
                    return GetString(SI_GAMEPAD_BACK_OPTION)
                else
                    return GetString(SI_EXIT_BUTTON)
                end
            end,
            keybind = "UI_SHORTCUT_EXIT",
            order = -1000,
            gamepadPreferredKeybind = "UI_SHORTCUT_NEGATIVE",
            callback = function()
                SCENE_MANAGER:HideCurrentScene()
            end,
            enabled = function()
                return not self:IsAnimating()
            end,
        },
    }

    self.constellationKeybindStripDescriptor =
    {
        alignment = AlignLeftOnGamepadRightOnKeyboard,
        {
            name = GetString(SI_CHAMPION_CONSTELLATION_ZOOM_OUT),
            keybind = "UI_SHORTCUT_EXIT",
            order = -1000,
            gamepadPreferredKeybind = "UI_SHORTCUT_NEGATIVE",
            callback = function()
                self:ZoomOut()
            end,
            enabled = function()
                return not self:IsAnimating()
            end,
        },
    }

    -- gamepad specific
    self.gamepadEnterActionBarKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            name = GetString(SI_GAMEPAD_CHAMPION_ENTER_BAR),
            -- we are splitting up these into independent keybinds to convince the keybind system that this will never conflict with
            -- the toggle respec action: the keyboard quinary keybind in practice will not be used.
            keybind = "UI_SHORTCUT_QUINARY",
            gamepadPreferredKeybind = "UI_SHORTCUT_TERTIARY",
            enabled = function()
                local result = GetChampionPurchaseAvailability()
                if result ~= CHAMPION_PURCHASE_SUCCESS then
                    return false, GetString("SI_CHAMPIONPURCHASERESULT", result)
                end
            end,
            callback = function()
                --If we are opening the quick menu, make sure to deselect the current star (if there is one)
                if self.chosenConstellation then
                    self.chosenConstellation:SelectStar(nil)
                end
                local ALLOW_DISCIPLINE_SWAPPING = true
                self.championBar:GetGamepadEditor():FocusBar(ALLOW_DISCIPLINE_SWAPPING)
                GAMEPAD_CHAMPION_QUICK_MENU:Show()
            end,
        },
    }

    self.gamepadConstellationKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            name = function()
                return self:GetSelectedStar():GetPrimaryGamepadActionText()
            end,
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                self:GetSelectedStar():PerformPrimaryGamepadAction()
            end,
            visible = function()
                return self:GetSelectedStar() and self:GetSelectedStar():HasPrimaryGamepadAction()
            end,
            enabled = function()
                if self:IsAnimating() or self:GetSelectedStar() == nil then
                    return false
                end
                return self:GetSelectedStar():CanPerformPrimaryGamepadAction()
            end,
        },
        {
            --Ethereal binds show no text, the name field is used to help identify the keybind when debugging. This text does not have to be localized.
            name = "Champion Star Remove Points",
            ethereal = true,
            keybind = "UI_SHORTCUT_LEFT_TRIGGER",
            handlesKeyUp = true,
            enabled = function()
                local editor = self:GetSelectedStarEditor()
                return editor ~= nil and editor:CanRemovePoints()
            end,
            callback = function(up)
                if up and self.currentChangingEditor then
                    -- release
                    self.currentChangingEditor:StopChangingPoints()
                    self.currentChangingEditor = nil
                elseif not up then
                    -- press
                    -- saving editor to an independent variable so we can
                    -- always stop, even if the editor stops being selected while
                    -- the keybind is still being held
                    self.currentChangingEditor = self:GetSelectedStarEditor()
                    self.currentChangingEditor:StartRemovingPoints()
                end
                return true
            end,
        },
        {
            --Ethereal binds show no text, the name field is used to help identify the keybind when debugging. This text does not have to be localized.
            name = "Champion Star Add Points",
            ethereal = true,
            keybind = "UI_SHORTCUT_RIGHT_TRIGGER",
            handlesKeyUp = true,
            enabled = function()
                local editor = self:GetSelectedStarEditor()
                return editor ~= nil and editor:CanAddPoints()
            end,
            callback = function(up)
                if up and self.currentChangingEditor then
                    -- release
                    self.currentChangingEditor:StopChangingPoints()
                    self.currentChangingEditor = nil
                elseif not up then
                    -- press
                    -- saving editor to an independent variable so we can
                    -- always stop, even if the editor stops being selected while
                    -- the keybind is still being held
                    self.currentChangingEditor = self:GetSelectedStarEditor()
                    self.currentChangingEditor:StartAddingPoints()
                end
                return true
            end,
        },
        {
            --Ethereal binds show no text, the name field is used to help identify the keybind when debugging. This text does not have to be localized.
            name = "Champion Rotate Left",
            ethereal = true,
            keybind = "UI_SHORTCUT_LEFT_SHOULDER",
            callback = function()
                self:CycleToLeftNode()
            end,
        },
        {
            --Ethereal binds show no text, the name field is used to help identify the keybind when debugging. This text does not have to be localized.
            name = "Champion Rotate Right",
            ethereal = true,
            keybind = "UI_SHORTCUT_RIGHT_SHOULDER",
            callback = function()
                self:CycleToRightNode()
            end,
        },
    }

    self.gamepadActionBarKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            name = function()
                local editor = self.championBar:GetGamepadEditor()
                if editor:IsAssigningChampionSkill() then
                    return GetString(SI_GAMEPAD_CHAMPION_SLOT_SKILL)
                else
                    return GetString(SI_GAMEPAD_CHAMPION_QUICK_MENU)
                end
            end,
            keybind = "UI_SHORTCUT_PRIMARY",
            enabled = function()
                local editor = self.championBar:GetGamepadEditor()
                if editor:IsAssigningChampionSkill() then
                    local result = editor:GetExpectedAssignSkillResult()
                    return result == CHAMPION_PURCHASE_SUCCESS, GetString("SI_CHAMPIONPURCHASERESULT", result)
                else
                    return true
                end
            end,
            callback = function()
                local editor = self.championBar:GetGamepadEditor()
                if editor:IsAssigningChampionSkill() then
                    editor:FinishAssigningChampionSkill()
                else
                    GAMEPAD_CHAMPION_QUICK_MENU:Show()
                end
            end,
        },
        {
            name = GetString(SI_GAMEPAD_BACK_OPTION),
            -- we are splitting up these into independent keybinds to convince the keybind system that this will never conflict with
            -- the clear points action: the keyboard exit keybind in practice will not be used.
            keybind = "UI_SHORTCUT_EXIT",
            order = -1000,
            gamepadPreferredKeybind = "UI_SHORTCUT_NEGATIVE",
            callback = function()
                local editor = self.championBar:GetGamepadEditor()
                editor:UnfocusBar()
            end,
        },
    }
end

function ChampionPerks:RemoveKeybindStrips()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.respecActionsKeybindStripDescriptor, self.keybindStripId)
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.overviewKeybindStripDescriptor, self.keybindStripId)
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.constellationKeybindStripDescriptor, self.keybindStripId)

    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.gamepadEnterActionBarKeybindStripDescriptor, self.keybindStripId)
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.gamepadConstellationKeybindStripDescriptor, self.keybindStripId)
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.gamepadActionBarKeybindStripDescriptor, self.keybindStripId)

    GAMEPAD_CHAMPION_QUICK_MENU:RemoveKeybindStrips(self.keybindStripId)
end

function ChampionPerks:AddKeybindStrips()
    self:RemoveKeybindStrips()

    if self.keybindState == KEYBIND_STATES.OVERVIEW then
        KEYBIND_STRIP:AddKeybindButtonGroup(self.respecActionsKeybindStripDescriptor, self.keybindStripId)
        KEYBIND_STRIP:AddKeybindButtonGroup(self.overviewKeybindStripDescriptor, self.keybindStripId)
        if SCENE_MANAGER:IsCurrentSceneGamepad() then
            KEYBIND_STRIP:AddKeybindButtonGroup(self.gamepadEnterActionBarKeybindStripDescriptor, self.keybindStripId)
        end
    elseif self.keybindState == KEYBIND_STATES.CONSTELLATION then
        KEYBIND_STRIP:AddKeybindButtonGroup(self.respecActionsKeybindStripDescriptor, self.keybindStripId)
        KEYBIND_STRIP:AddKeybindButtonGroup(self.constellationKeybindStripDescriptor, self.keybindStripId)
        if SCENE_MANAGER:IsCurrentSceneGamepad() then
            KEYBIND_STRIP:AddKeybindButtonGroup(self.gamepadEnterActionBarKeybindStripDescriptor, self.keybindStripId)
            KEYBIND_STRIP:AddKeybindButtonGroup(self.gamepadConstellationKeybindStripDescriptor, self.keybindStripId)
        end
    elseif self.keybindState == KEYBIND_STATES.ACTION_BAR then
        -- always gamepad
        KEYBIND_STRIP:AddKeybindButtonGroup(self.gamepadActionBarKeybindStripDescriptor, self.keybindStripId)
    elseif self.keybindState == KEYBIND_STATES.QUICK_MENU then
        GAMEPAD_CHAMPION_QUICK_MENU:AddKeybindStrips(self.keybindStripId)
    end
end

function ChampionPerks:RefreshKeybinds()   
    --If we don't have a keybind strip id we shouldn't be manipulating the keybind strip, so just return early
    if not self.keybindStripId then
        return
    end

    local nextState
    if GAMEPAD_CHAMPION_QUICK_MENU:IsShowing() then
        nextState = KEYBIND_STATES.QUICK_MENU
    elseif self.championBar:GetGamepadEditor():IsFocused() then
        nextState = KEYBIND_STATES.ACTION_BAR
    elseif self:HasChosenConstellation() then
        nextState = KEYBIND_STATES.CONSTELLATION
    else
        nextState = KEYBIND_STATES.OVERVIEW
    end

    if nextState ~= self.keybindState then
        self.keybindState = nextState
        self:RemoveKeybindStrips()
        self:AddKeybindStrips()
    end

    KEYBIND_STRIP:UpdateCurrentKeybindButtonGroups(self.keybindStripId)
end

function ChampionPerks:BuildStarSpirals()
    local timeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_StarSpiralAnimation")
    self.starSpirals = {}
    for i = 1, 2 do
        local texture = CreateControlFromVirtual("$(parent)StarSpiral", self.canvasControl, "ZO_ConstellationStarSpiral", i)
        local spiralNode = self.sceneGraph:CreateNode("starSpiral"..i)
        spiralNode:SetParent(self.rootNode)
        texture:SetDimensions(spiralNode:ComputeSizeForDepth(4000, 4000, STAR_SPIRAL_START_DEPTH, ZO_CHAMPION_REFERENCE_CAMERA_Z))
        spiralNode:AddTexture(texture, 0, 0, STAR_SPIRAL_START_DEPTH)
        self.starSpirals[i] = texture
        texture.node = spiralNode
    end

    timeline:PlayFromStart()
end

local NUM_CLOUDS = 4
local SKY_CLOUD_MIN_OFFSET_Y = 800
local SKY_CLOUD_MAX_OFFSET_Y = 1100
function ChampionPerks:BuildClouds()
    for cloudIndex = 0, NUM_CLOUDS - 1 do
        local skyCloudTemplate
        if cloudIndex < 2 then
            -- nodes 0-1
            skyCloudTemplate = "ZO_ConstellationSkyCloudInner"
        else
            -- nodes 2-3
            skyCloudTemplate = "ZO_ConstellationSkyCloudOuter"
        end
        local skyCloudTexture = CreateControlFromVirtual("$(parent)SkyCloud", self.canvasControl, skyCloudTemplate, cloudIndex)
        local skyCloudNode = self.sceneGraph:CreateNode("skyCloud" .. cloudIndex)
        skyCloudNode:SetParent(self.skyCloudsNode)
        skyCloudTexture:SetDimensions(skyCloudNode:ComputeSizeForDepth(512, 256, SKY_CLOUD_DEPTH, ZO_CHAMPION_REFERENCE_CAMERA_Z))
        local indexLerpValue = zo_percentBetween(0, NUM_CLOUDS - 1, cloudIndex)
        local offsetY = zo_lerp(SKY_CLOUD_MIN_OFFSET_Y, SKY_CLOUD_MAX_OFFSET_Y, indexLerpValue)
        skyCloudNode:AddTexture(skyCloudTexture, 0, offsetY, SKY_CLOUD_DEPTH)
        skyCloudNode:SetRotation(zo_lerp(0, ZO_TWO_PI, indexLerpValue))
    end
end

function ChampionPerks:BuildSceneGraph()
    self.sceneGraph = ZO_SceneGraph:New(self.canvasControl)
    self.cameraNode = self.sceneGraph:GetCameraNode()

    self.rootNode = self.sceneGraph:CreateNode("root")
    self.rootNode:SetParent(self.cameraNode)

    self.skyCloudsNode = self.sceneGraph:CreateNode("skyClouds")
    self.skyCloudsNode:SetParent(self.rootNode)

    self.closeClouds1Node = self.sceneGraph:CreateNode("closeClouds1")
    self.closeClouds1Node:SetParent(self.rootNode)
    self.closeClouds1Texture:SetDimensions(self.closeClouds1Node:ComputeSizeForDepth(4500, 4500, CLOSE_CLOUDS_DEPTH, ZO_CHAMPION_REFERENCE_CAMERA_Z))
    self.closeClouds1Node:AddTexture(self.closeClouds1Texture, 0, 0, CLOSE_CLOUDS_DEPTH)

    self.closeClouds2Node = self.sceneGraph:CreateNode("closeClouds2")
    self.closeClouds2Node:SetParent(self.rootNode)
    self.closeClouds2Texture:SetDimensions(self.closeClouds2Node:ComputeSizeForDepth(4500, 4500, CLOSE_CLOUDS_DEPTH, ZO_CHAMPION_REFERENCE_CAMERA_Z))
    self.closeClouds2Node:AddTexture(self.closeClouds2Texture, 0, 0, CLOSE_CLOUDS_DEPTH)

    self:BuildClouds()

    self:BuildStarSpirals()

    self.cloudsNode = self.sceneGraph:CreateNode("clouds")
    self.cloudsNode:SetParent(self.rootNode)
    self.cloudsTexture:SetDimensions(self.cloudsNode:ComputeSizeForDepth(1300, 1300, CLOUDS_DEPTH, ZO_CHAMPION_REFERENCE_CAMERA_Z))
    self.cloudsNode:AddTexture(self.cloudsTexture, 0, 0, CLOUDS_DEPTH)

    self.smokeNode = self.sceneGraph:CreateNode("smoke")
    self.smokeNode:SetParent(self.rootNode)
    self.smokeTexture:SetDimensions(self.smokeNode:ComputeSizeForDepth(1300, 1300, SMOKE_DEPTH, ZO_CHAMPION_REFERENCE_CAMERA_Z))
    self.smokeNode:AddTexture(self.smokeTexture, 0, 0, SMOKE_DEPTH)

    self.skyNode = self.sceneGraph:CreateNode("sky")
    self.skyNode:SetParent(self.rootNode)
    local skyTexture = self.canvasControl:GetNamedChild("Sky")
    skyTexture:SetDimensions(self.skyNode:ComputeSizeForDepth(9000, 9000, SKY_DEPTH, ZO_CHAMPION_REFERENCE_CAMERA_Z))
    self.skyNode:AddTexture(skyTexture, 0, 0, SKY_DEPTH)

    self.darknessRingNode = self.sceneGraph:CreateNode("darknessRing")
    self.darknessRingNode:SetParent(self.rootNode)
    self.darknessRingTexture:SetDimensions(self.darknessRingNode:ComputeSizeForDepth(1400, 1400, CONSTELLATIONS_DARKNESS_DEPTH, ZO_CHAMPION_REFERENCE_CAMERA_Z))
    self.darknessRingNode:AddTexture(self.darknessRingTexture, 0, 0, CONSTELLATIONS_DARKNESS_DEPTH)
    self.darknessRingNode:SetRotation(6.11)

    self.radialSelectorNode = self.sceneGraph:CreateNode("radialSelector")
    self.radialSelectorNode:SetParent(self.cameraNode)
    self.radialSelectorTexture:SetDimensions(self.radialSelectorNode:ComputeSizeForDepth(512, 128, ZO_CHAMPION_CONSTELLATION_DEPTH, ZO_CHAMPION_REFERENCE_CAMERA_Z))
    self.radialSelectorNode:AddTexture(self.radialSelectorTexture, 0, -580, ZO_CHAMPION_CONSTELLATION_DEPTH)

    self.centerInfoBGNode = self.sceneGraph:CreateNode("centerInfoBG")
    self.centerInfoBGNode:SetParent(self.rootNode)
    self.centerInfoBGTexture:SetDimensions(self.centerInfoBGNode:ComputeSizeForDepth(512, 512, CENTER_INFO_BG_DEPTH, ZO_CHAMPION_REFERENCE_CAMERA_Z))
    self.centerInfoBGNode:AddTexture(self.centerInfoBGTexture, 0, 0, CENTER_INFO_BG_DEPTH)

    self.ring = ZO_SceneNodeRing:New(self.rootNode)
    self.ring:SetRadius(self.rootNode:ComputeSizeForDepth(self.constellationInnerRadius, self.constellationInnerRadius, ZO_CHAMPION_CONSTELLATION_DEPTH, ZO_CHAMPION_REFERENCE_CAMERA_Z))

    -- we need two anchors per constellation to get an endless circle where only half of the ring is visible at a time
    self.ringAnchors = {}
    for anchorIndex = 1, GetNumChampionDisciplines() * 2 do
        local ringAnchor = ZO_ChampionConstellationRingAnchor:New(self.sceneGraph, anchorIndex)
        self.ringAnchors[anchorIndex] = ringAnchor
        self.ring:AddNode(ringAnchor:GetNode())
    end
end

function ChampionPerks:InitializeStateMachine()
    self.stateMachine = ZO_StateMachine_Base:New("CHAMPION_STATE_MACHINE")

    self.stateMachine:AddState("INACTIVE")

    do
        local state = self.stateMachine:AddState("ENTERING")
        local ENTER_ANIMATION =
        {
            duration = 0.85,
            targetCameraX = 0,
            targetCameraY = ZO_CHAMPION_ZOOMED_OUT_CAMERA_Y,
            targetCameraZ = ZO_CHAMPION_ZOOMED_OUT_CAMERA_Z,
            easingFunction = ZO_EaseOutQuadratic,
        }

        state:RegisterCallback("OnActivated", function()
            local targetNode = self.constellations[ZO_CHAMPION_CENTERED_CONSTELLATION_INDEX]:GetFirstRingNode()

            self.ring:SetAngle(ZO_PI - ONE_SIXTH_PI)
            self.centerInfoAlphaInterpolator:SetCurrentValue(0)
            self.centerInfoControl:SetAlpha(0)
            self.radialSelectorTexture:SetAlpha(0)
            self:AttachConstellationsAroundNode(targetNode)

            self:SetRootCameraX(0)
            self:SetRootCameraY(ZO_CHAMPION_INITIAL_CAMERA_Y)
            self:SetRootCameraZ(ZO_CHAMPION_INITIAL_CAMERA_Z)
            self:SetAnimation(ENTER_ANIMATION)
        end)
    end

    do
        local state = self.stateMachine:AddState("RING")
        state:RegisterCallback("OnActivated", function()
            if IsInGamepadPreferredMode() then
                self:ResetConstellationSelectorToTop()
            end

            self.centerInfoAlphaInterpolator:SetTargetBase(1)
            local result = GetChampionPurchaseAvailability()
            if result == CHAMPION_PURCHASE_SUCCESS then
                self.inactiveAlert.messageLabel:SetHidden(true)
            else
                self.inactiveAlert.messageLabel:SetHidden(false)
                self:RefreshInactiveAlertMessage()
            end
        end)
        state:RegisterCallback("OnDeactivated", function()
            self.centerInfoAlphaInterpolator:SetCurrentValue(0)
            self.centerInfoAlphaInterpolator:SetTargetBase(0)
            self.centerInfoControl:SetAlpha(0)
            self.radialSelectorTexture:SetAlpha(0)
            self.inactiveAlert.messageLabel:SetHidden(true)
        end)
    end

    do
        local state = self.stateMachine:AddState("CONSTELLATION_IN")
        local zoomInAnimation =
        {
            targetCameraX = 0,
            targetCameraY = ZOOMED_IN_CAMERA_Y,
            targetCameraZ = ZOOMED_IN_CAMERA_Z,
            targetNodeDurationBase = 0.75,
            targetNodeDurationMultiplier = 0.5 / ZO_PI,
            nodePadding = {},
            chooseTargetNode = true,
            chooseTargetNodeAtDurationPercent = 1,
            easingFunction = ZO_EaseOutQuadratic,
        }

        state:RegisterCallback("OnActivated", function()
            -- trigger should set nextTargetNode
            if IsInGamepadPreferredMode() then
                zoomInAnimation.targetCameraY = ZO_CHAMPION_GAMEPAD_ZOOMED_IN_CAMERA_Y
                zoomInAnimation.targetCameraZ = ZO_CHAMPION_GAMEPAD_ZOOMED_IN_CAMERA_Z
            else
                zoomInAnimation.targetCameraY = ZO_CHAMPION_KEYBOARD_ZOOMED_IN_CAMERA_Y
                zoomInAnimation.targetCameraZ = ZO_CHAMPION_KEYBOARD_ZOOMED_IN_CAMERA_Z
            end

            local node = self.nextTargetNode
            zoomInAnimation.targetNode = node
            ZO_ClearTable(zoomInAnimation.nodePadding)
            zoomInAnimation.nodePadding[node] = 0

            self:SetAnimation(zoomInAnimation)
            PlaySound(SOUNDS.CHAMPION_ZOOM_IN)
            self.nextTargetNode = nil
        end)

        state:RegisterCallback("OnDeactivated", function()
            self:SelectConstellationNodeInternal(nil)
        end)
    end

    do
        local state = self.stateMachine:AddState("CONSTELLATION_OUT")
        local zoomOutAnimation =
        {
            targetCameraX = 0,
            targetCameraY = ZO_CHAMPION_ZOOMED_OUT_CAMERA_Y,
            targetCameraZ = ZO_CHAMPION_ZOOMED_OUT_CAMERA_Z,
            duration = 0.75,
            nodePadding = {},
            easingFunction = ZO_EaseOutQuadratic,
            unchooseNode = true,
            unchooseInstantly = true,
            gamepadSelectNode = true,
        }

        state:RegisterCallback("OnActivated", function()
            zoomOutAnimation.targetCameraY = ZO_CHAMPION_ZOOMED_OUT_CAMERA_Y
            zoomOutAnimation.targetCameraZ = ZO_CHAMPION_ZOOMED_OUT_CAMERA_Z
            local targetNode = self.constellations[ZO_CHAMPION_CENTERED_CONSTELLATION_INDEX]:GetNodeInSameHemisphereAsOtherNode(self.chosenRingNode)
            zoomOutAnimation.targetNode = targetNode
            self:AttachConstellationsAroundNode(targetNode)
            ZO_ClearTable(zoomOutAnimation.nodePadding)
            ClearCursor()
            for _, node in self.ring:NodeIterator() do
                zoomOutAnimation.nodePadding[node] = 0
            end
            PlaySound(SOUNDS.CHAMPION_ZOOM_OUT)
            self:SetAnimation(zoomOutAnimation)

            if self.currentChangingEditor then
                -- release
                self.currentChangingEditor:StopChangingPoints()
                self.currentChangingEditor = nil
            end

            self.refreshGroup:MarkDirty("AllData")
        end)
    end

    do
        local zoomedInCycleAnimation =
        {
            duration = 0.5,
            nodePadding = {},
            chooseTargetNode = true,
            chooseTargetNodeAtDurationPercent = 0.5,
            easingFunction = ZO_EaseOutQuadratic,
        }

        local state = self.stateMachine:AddState("CONSTELLATION_CYCLE")
        state:RegisterCallback("OnActivated", function()
            zoomedInCycleAnimation.targetNode = self.nextTargetNode
            self.nextTargetNode.constellation:PlayOnCycledToSound()
            self:SetAnimation(zoomedInCycleAnimation)
            self.nextTargetNode = nil
            ClearCursor()

           if self.currentChangingEditor then
                -- release
                self.currentChangingEditor:StopChangingPoints()
                self.currentChangingEditor = nil
           end
        end)
    end

    self.stateMachine:AddState("CONSTELLATION")

    do
        local zoomInClusterAnimation =
        {
            duration = 0.75,
            easingFunction = ZO_EaseOutQuadratic
        }
        local state = self.stateMachine:AddState("CLUSTER_IN")
        state:RegisterCallback("OnActivated", function()
            SCENE_MANAGER:RemoveFragment(self.keyboardConstellationViewFragment)
            SCENE_MANAGER:RemoveFragment(self.gamepadConstellationViewFragment)
            zoomInClusterAnimation.targetCluster = self.chosenConstellation:GetClusterByClusterData(self.nextTargetClusterData)
            zoomInClusterAnimation.targetClusterData = self.nextTargetClusterData
            zoomInClusterAnimation.startingCluster = self.chosenConstellation:GetCurrentCluster()

            if IsInGamepadPreferredMode() then
                zoomInClusterAnimation.targetCameraX = nil
                zoomInClusterAnimation.targetCameraY = nil
            else
                local worldX, worldY = zoomInClusterAnimation.targetCluster:GetWorldSpaceCoordinates()
                zoomInClusterAnimation.targetCameraX = worldX
                zoomInClusterAnimation.targetCameraY = -worldY
            end
            zoomInClusterAnimation.targetCameraZ = IsInGamepadPreferredMode() and ZO_CHAMPION_GAMEPAD_ZOOMED_IN_CLUSTER_CAMERA_Z or ZO_CHAMPION_KEYBOARD_ZOOMED_IN_CLUSTER_CAMERA_Z 
            self:SetAnimation(zoomInClusterAnimation)
            PlaySound(SOUNDS.CHAMPION_ZOOM_IN)
        end)
        state:RegisterCallback("OnDeactivated", function()
            self.chosenConstellation:ChangeCurrentCluster(self.nextTargetClusterData)
            self.nextTargetClusterData = nil
        end)
    end

    do
        local zoomOutClusterAnimation =
        {
            duration = 0.75,
            startingFadeDuration = 0.1,
            easingFunction = ZO_EaseOutQuadratic
        }
        local state = self.stateMachine:AddState("CLUSTER_OUT")
        state:RegisterCallback("OnActivated", function()
            zoomOutClusterAnimation.targetCluster = self.chosenConstellation:GetClusterByClusterData(self.nextTargetClusterData)
            zoomOutClusterAnimation.targetClusterData = self.nextTargetClusterData
            zoomOutClusterAnimation.startingCluster = self.chosenConstellation:GetCurrentCluster()
            if IsInGamepadPreferredMode() then
                zoomOutClusterAnimation.targetCameraX = nil
                zoomOutClusterAnimation.targetCameraY = nil
            else
                zoomOutClusterAnimation.targetCameraX = 0
                zoomOutClusterAnimation.targetCameraY = ZO_CHAMPION_KEYBOARD_ZOOMED_IN_CAMERA_Y
            end
            zoomOutClusterAnimation.targetCameraZ = IsInGamepadPreferredMode() and ZO_CHAMPION_GAMEPAD_ZOOMED_IN_CAMERA_Z or ZO_CHAMPION_KEYBOARD_ZOOMED_IN_CAMERA_Z 
            self:SetAnimation(zoomOutClusterAnimation)
            PlaySound(SOUNDS.CHAMPION_ZOOM_OUT)

           if self.currentChangingEditor then
                -- release
                self.currentChangingEditor:StopChangingPoints()
                self.currentChangingEditor = nil
           end
        end)
        state:RegisterCallback("OnDeactivated", function()
            if IsInGamepadPreferredMode() then
                SCENE_MANAGER:AddFragment(self.gamepadConstellationViewFragment)
            else
                SCENE_MANAGER:AddFragment(self.keyboardConstellationViewFragment)
            end
            self.chosenConstellation:ChangeCurrentCluster(self.nextTargetClusterData)
            self.nextTargetClusterData = nil
        end)
    end

    self.stateMachine:AddState("CLUSTER")

    self.stateMachine:AddTrigger("ON_SHOWING", ZO_StateMachine_TriggerStateCallback, "ON_SHOWING")
    self.stateMachine:AddTrigger("ON_DATA_RELOADED", ZO_StateMachine_TriggerStateCallback, "ON_DATA_RELOADED")
    self.stateMachine:AddTrigger("ZOOM_IN", ZO_StateMachine_TriggerStateCallback, "ZOOM_IN")
    self.stateMachine:AddTrigger("ZOOM_OUT", ZO_StateMachine_TriggerStateCallback, "ZOOM_OUT")
    self.stateMachine:AddTrigger("CYCLE", ZO_StateMachine_TriggerStateCallback, "CYCLE")
    self.stateMachine:AddTrigger("ANIMATION_COMPLETE", ZO_StateMachine_TriggerStateCallback, "ANIMATION_COMPLETE")

    -- ring states: ring is entered at the start, and can be zoomed out to
    self.stateMachine:AddEdgeAutoName("INACTIVE", "ENTERING")
    self.stateMachine:AddTriggerToEdge("ON_SHOWING", "INACTIVE_TO_ENTERING")
    self.stateMachine:AddTriggerToEdge("ON_DATA_RELOADED", "INACTIVE_TO_ENTERING")
    self.stateMachine:AddEdgeAutoName("ENTERING", "RING")
    self.stateMachine:AddTriggerToEdge("ANIMATION_COMPLETE", "ENTERING_TO_RING")
    self.stateMachine:AddEdgeAutoName("CONSTELLATION_OUT", "RING")
    self.stateMachine:AddTriggerToEdge("ANIMATION_COMPLETE", "CONSTELLATION_OUT_TO_RING")
    self.stateMachine:AddEdgeAutoName("RING", "CONSTELLATION_IN")
    self.stateMachine:AddTriggerToEdge("ZOOM_IN", "RING_TO_CONSTELLATION_IN")

    -- constellation states: constellations can be zoomed into from the ring, and zoomed out from a cluster.
    self.stateMachine:AddEdgeAutoName("CONSTELLATION_IN", "CONSTELLATION")
    self.stateMachine:AddTriggerToEdge("ANIMATION_COMPLETE", "CONSTELLATION_IN_TO_CONSTELLATION")
    self.stateMachine:AddEdgeAutoName("CLUSTER_OUT", "CONSTELLATION")
    self.stateMachine:AddTriggerToEdge("ANIMATION_COMPLETE", "CLUSTER_OUT_TO_CONSTELLATION")
    self.stateMachine:AddEdgeAutoName("CONSTELLATION", "CONSTELLATION_OUT")
    self.stateMachine:AddTriggerToEdge("ZOOM_OUT", "CONSTELLATION_TO_CONSTELLATION_OUT")
    self.stateMachine:AddEdgeAutoName("CONSTELLATION", "CLUSTER_IN")
    self.stateMachine:AddTriggerToEdge("ZOOM_IN", "CONSTELLATION_TO_CLUSTER_IN")

    -- you can also cycle between constellations
    self.stateMachine:AddEdgeAutoName("CONSTELLATION", "CONSTELLATION_CYCLE")
    self.stateMachine:AddTriggerToEdge("CYCLE", "CONSTELLATION_TO_CONSTELLATION_CYCLE")
    self.stateMachine:AddEdgeAutoName("CONSTELLATION_CYCLE", "CONSTELLATION")
    self.stateMachine:AddTriggerToEdge("ANIMATION_COMPLETE", "CONSTELLATION_CYCLE_TO_CONSTELLATION")

    -- clusters are only zoomed in from their constellation
    self.stateMachine:AddEdgeAutoName("CLUSTER_IN", "CLUSTER")
    self.stateMachine:AddTriggerToEdge("ANIMATION_COMPLETE", "CLUSTER_IN_TO_CLUSTER")
    self.stateMachine:AddEdgeAutoName("CLUSTER", "CLUSTER_OUT")
    self.stateMachine:AddTriggerToEdge("ZOOM_OUT", "CLUSTER_TO_CLUSTER_OUT")

    self.stateMachine:SetCurrentState("INACTIVE")
end

function ChampionPerks:UpdateRingRadius()
    self.constellationInnerRadius = ZO_CHAMPION_CONSTELLATION_INNER_RADIUS
    self.ring:SetRadius(self.rootNode:ComputeSizeForDepth(self.constellationInnerRadius, self.constellationInnerRadius, ZO_CHAMPION_CONSTELLATION_DEPTH, ZO_CHAMPION_REFERENCE_CAMERA_Z))
end

function ChampionPerks:GetChampionCanvas()
    return self.canvasControl
end

function ChampionPerks:GetNumConstellations()
    return #self.constellations
end

function ChampionPerks:RegisterForEvents()
    self.control:RegisterForEvent(EVENT_CHAMPION_POINT_GAINED, function() self:OnChampionPointGained() end)
    self.control:RegisterForEvent(EVENT_CHAMPION_SYSTEM_UNLOCKED, function() self:OnChampionSystemUnlocked() end)
    self.control:RegisterForEvent(EVENT_UNSPENT_CHAMPION_POINTS_CHANGED, function() self:OnUnspentChampionPointsChanged() end)
    self.control:RegisterForEvent(EVENT_PLAYER_ACTIVATED, function() self:OnPlayerActivated() end)

    --Refresh and clear unsaved changes if we successfully finished equipping an armory build
    self.control:RegisterForEvent(EVENT_ARMORY_BUILD_RESTORE_RESPONSE, function(_, result, buildIndex)
        if result == ARMORY_BUILD_RESTORE_RESULT_SUCCESS then
            self.isInRespecMode = false
            self:ClearUnsavedChanges()
            self.refreshGroup:MarkDirty("AllData")
        end
    end)
end

function ChampionPerks:DeferredRegisterForEvents()
    self.control:SetHandler("OnUpdate", function(_, timeSecs) self:OnUpdate(timeSecs) end)
    self.control:RegisterForEvent(EVENT_CHAMPION_PURCHASE_RESULT, function(_, result) self:OnChampionPurchaseResult(result) end)
    self.control:RegisterForEvent(EVENT_MONEY_UPDATE, function() self:OnMoneyChanged() end)

    -- Refresh Champion purchase availability
    self.control:RegisterForEvent(EVENT_PLAYER_COMBAT_STATE, function()
        self.refreshGroup:MarkDirty("ChosenConstellationData")
    end)

    self.control:RegisterForEvent(EVENT_ZONE_CHANGED, function()
        self.refreshGroup:MarkDirty("ChosenConstellationData")
    end)

    CHAMPION_DATA_MANAGER:RegisterCallback("AllPointsChanged", function()
        self.refreshGroup:MarkDirty("AllData")
    end)

    CHAMPION_DATA_MANAGER:RegisterCallback("ChampionSkillPendingPointsChanged", function(championSkillData, wasUnlocked, isUnlocked)
        if championSkillData:IsTypeSlottable() and isUnlocked and not wasUnlocked then
            TriggerTutorial(TUTORIAL_TRIGGER_CHAMPION_SLOTTABLE_STAR_PURCHASED)
        end

        if self.chosenConstellation and self.chosenConstellation:GetChampionDisciplineData() == championSkillData:GetChampionDisciplineData() then
            self.refreshGroup:MarkDirty("ChosenConstellationData")
        else
            self.refreshGroup:MarkDirty("AllData")
        end
    end)

    self.championBar:RegisterCallback("SlotChanged", function(slotAssigned)
        -- we need to refresh the star that has been slotted and the star that
        -- has been unslotted. we don't have an easy way to express that so we'll
        -- just refresh everything
        self.refreshGroup:MarkDirty("AllData")
    end)

    self.championBar:RegisterCallback("GamepadFocusChanged", function()
        self.refreshGroup:MarkDirty("SelectedStarData")
        self.refreshGroup:TryClean()
    end)
end

function ChampionPerks:RefreshInactiveAlertMessage()
    local result = GetChampionPurchaseAvailability()
    if result ~= CHAMPION_PURCHASE_SUCCESS then
        self.inactiveAlert.messageLabel:SetText(GetString("SI_CHAMPIONPURCHASERESULT", result))
    end
end

function ChampionPerks:ApplyInactiveAlertPlatformStyle(inactiveAlertConstants)
    self.inactiveAlert.messageLabel:SetFont(inactiveAlertConstants.font)
    self.inactiveAlert.messageLabel:SetModifyTextType(inactiveAlertConstants.modifyTextType)
    self:RefreshInactiveAlertMessage()
    self.inactiveAlert:ClearAnchors()
    self.inactiveAlert:SetAnchor(TOPLEFT, nil, TOPLEFT, inactiveAlertConstants.offsetX, inactiveAlertConstants.offsetY)
end

function ChampionPerks:ApplyPlatformStyle(constants)
    self:ApplyInactiveAlertPlatformStyle(constants.INACTIVE_ALERT)
    ApplyTemplateToControl(self.centerInfoControl, ZO_GetPlatformTemplate("ZO_ChampionCenterInfo"))
    self.keyboardStatusControl:SetHidden(IsInGamepadPreferredMode())
end

--Constellations

function ChampionPerks:GetGamepadCursor()
    return self.gamepadCursor
end

function ChampionPerks:AcquireStarEditor()
    return self.starEditorPool:AcquireObject()
end

function ChampionPerks:ReleaseStarEditor(editorKey)
    self.starEditorPool:ReleaseObject(editorKey)
end

function ChampionPerks:AcquireStarTexture()
    local starTexture, linkKey = self.starTextureControlPool:AcquireObject()
    starTexture.key = linkKey
    return starTexture
end

function ChampionPerks:ReleaseStarTexture(starTexture)
    self.starTextureControlPool:ReleaseObject(starTexture.key)
    starTexture.key = nil
end

function ChampionPerks:AcquireStarConfirmedTexture()
    local starConfirmedTexture, linkKey = self.starConfirmedTextureControlPool:AcquireObject()
    starConfirmedTexture.key = linkKey
    return starConfirmedTexture
end

function ChampionPerks:ReleaseStarConfirmedTexture(starConfirmedTexture)
    self.starConfirmedTextureControlPool:ReleaseObject(starConfirmedTexture.key)
    starConfirmedTexture.key = nil
end

function ChampionPerks:AcquireClusterTexture()
    local clusterTexture, linkKey = self.clusterBackgroundControlPool:AcquireObject()
    clusterTexture.key = linkKey
    return clusterTexture
end

function ChampionPerks:ReleaseClusterTexture(clusterTexture)
    self.clusterBackgroundControlPool:ReleaseObject(clusterTexture.key)
    clusterTexture.key = nil
end

function ChampionPerks:AcquireLinkControl()
    local linkControl, linkKey = self.starLinkControlPool:AcquireObject()
    linkControl.key = linkKey
    return linkControl
end

function ChampionPerks:ReleaseLinkControl(linkControl)
    self.starLinkControlPool:ReleaseObject(linkControl.key)
    linkControl.key = nil
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

function ChampionPerks:GetChosenConstellation()
    return self.chosenConstellation
end

function ChampionPerks:GetSelectedStar()
    if self.chosenConstellation then
        return self.chosenConstellation:GetSelectedStar()
    end
end

function ChampionPerks:GetSelectedStarEditor()
    local selectedStar = self:GetSelectedStar()
    return selectedStar and selectedStar:GetEditor()
end

function ChampionPerks:GetChampionBar()
    return self.championBar
end

function ChampionPerks:IsChampionSkillDataSlotted(championSkillData)
    if not championSkillData:CanBeSlotted() then
        return false
    end

    local slot = self.championBar:FindSlotMatchingChampionSkill(championSkillData)
    return slot ~= nil
end

function ChampionPerks:AttachConstellationsAroundNode(node)
    node.ringAnchor:AttachToConstellation()
    local leftNode = self.ring:GetPreviousNode(node)
    leftNode.ringAnchor:AttachToConstellation()
    local rightNode = self.ring:GetNextNode(node)
    rightNode.ringAnchor:AttachToConstellation()
end

function ChampionPerks:OnConstellationChosen()
    if IsInGamepadPreferredMode() then
        SCENE_MANAGER:AddFragment(self.gamepadChosenConstellationFragment)
        SCENE_MANAGER:AddFragment(self.gamepadConstellationViewFragment)
        self.gamepadCursor:OnZoomIn()
    else
        self.keyboardStatusAlphaInterpolator:SetTargetBase(1)
        SCENE_MANAGER:AddFragment(self.keyboardConstellationViewFragment)
    end
end

function ChampionPerks:OnChosenConstellationCleared()
    if IsInGamepadPreferredMode() then
        self.gamepadStarTooltip.scrollTooltip:ClearLines()
        self.gamepadCursor:OnZoomOut()
        self:ResetCameraPan()
    end
    self.keyboardStatusAlphaInterpolator:SetTargetBase(0)
    self.keyboardStatusAlphaInterpolator:SetCurrentValue(0)
    SCENE_MANAGER:RemoveFragment(self.gamepadChosenConstellationFragment)
    SCENE_MANAGER:RemoveFragment(self.gamepadConstellationViewFragment)
    SCENE_MANAGER:RemoveFragment(self.keyboardConstellationViewFragment)
end

function ChampionPerks:SetChosenConstellationNodeInternal(node, unchooseInstantly)
    if self.chosenRingNode ~= node then
        if self.chosenConstellation then
            self.chosenConstellation:SetActive(false, unchooseInstantly)
        end
        local lastChosenConstellation = self.chosenConstellation

        self.chosenRingNode = node
        self.chosenConstellation = node and node.constellation

        if self.chosenConstellation ~= nil then
            self.chosenConstellation:SetActive(true)
            self:AttachConstellationsAroundNode(node)
        end

        if self.chosenConstellation and not lastChosenConstellation then
            self:OnConstellationChosen()
        elseif not self.chosenConstellation and lastChosenConstellation then
            self:OnChosenConstellationCleared()
        end

        self.refreshGroup:MarkDirty("ChosenConstellationData")
    end
end

function ChampionPerks:RefreshSelectedConstellationInfo()
    if self.selectedConstellation then
        local disciplineData = self.selectedConstellation:GetChampionDisciplineData()

        self.centerInfoControl:SetHidden(false)
        self.centerInfoNameLabel:SetText(disciplineData:GetFormattedName())
        local pointPoolText = zo_iconTextFormat(disciplineData:GetPointPoolIcon(), "100%", "100%", disciplineData:GetNumAvailablePoints())
        self.centerInfoPointPoolLabel:SetText(pointPoolText)
    else
        self.centerInfoControl:SetHidden(true)
    end
end

function ChampionPerks:RefreshStatusInfo()
    if self.chosenConstellation then
        local disciplineData = self.chosenConstellation:GetChampionDisciplineData()

        local constellationNameText = disciplineData:GetFormattedName()
        local pointValueText = zo_iconTextFormat(disciplineData:GetPointPoolIcon(), "100%", "100%", disciplineData:GetNumAvailablePoints())

        if IsInGamepadPreferredMode() then
            GAMEPAD_CHAMPION_PERKS_SCENE:AddFragment(GAMEPAD_GENERIC_FOOTER_FRAGMENT)
            KEYBIND_STRIP:SetStyle(KEYBIND_STRIP_WITH_GENERIC_FOOTER_GAMEPAD_STYLE)
            local data =
            {
                data1HeaderText = GetString(SI_GAMEPAD_CHAMPION_POINTS_AVAILABLE),
                data1Text = pointValueText,
            }
            GAMEPAD_GENERIC_FOOTER:Refresh(data)
        else
            self.keyboardStatusNameLabel:SetText(constellationNameText)
            self.keyboardStatusPointValueLabel:SetText(pointValueText)
        end
    else
        GAMEPAD_CHAMPION_PERKS_SCENE:RemoveFragment(GAMEPAD_GENERIC_FOOTER_FRAGMENT)
        if IsInGamepadPreferredMode() then
            KEYBIND_STRIP:SetStyle(KEYBIND_STRIP_GAMEPAD_STYLE)
        end
    end
end

function ChampionPerks:SelectConstellationNodeInternal(ringNode)
    if self.selectedRingNode ~= ringNode then
        self.selectedRingNode = ringNode
        self.selectedConstellation = ringNode and ringNode.constellation
        self:RefreshKeybinds()
        self:RefreshSelectedConstellationInfo()
        return true
    end
    return false
end

function ChampionPerks:GetSelectedConstellation()
    return self.selectedConstellation
end

function ChampionPerks:HasUnsavedChanges()
    return CHAMPION_DATA_MANAGER:HasUnsavedChanges() or self.championBar:HasUnsavedChanges()
end

function ChampionPerks:ClearUnsavedChanges()
    CHAMPION_DATA_MANAGER:ClearChanges()
    if self.championBar then
        self.championBar:ResetAllSlots()
    end
end

function ChampionPerks:SpendPendingPoints()
    local respecNeeded = CHAMPION_DATA_MANAGER:IsRespecNeeded()
    PrepareChampionPurchaseRequest(respecNeeded)
    CHAMPION_DATA_MANAGER:CollectUnsavedChanges()
    self.championBar:CollectUnsavedChanges()
    local result = GetExpectedResultForChampionPurchaseRequest()
    if result ~= CHAMPION_PURCHASE_SUCCESS then
        ZO_AlertEvent(EVENT_CHAMPION_PURCHASE_RESULT, result)
        return
    end

    local dialogName
    if respecNeeded then
        dialogName = "CHAMPION_CONFIRM_COST"
    else
        dialogName = "CHAMPION_CONFIRM_CHANGES"
    end
    self:ShowDialog(dialogName, { respecNeeded = respecNeeded })
end

function ChampionPerks:SpendPointsConfirmed(respecNeeded)
    -- save off changed stars so we can animate them after the change is applied
    self:PrepareStarConfirmAnimation()
    SendChampionPurchaseRequest()
    local confirmationSound
    if respecNeeded then
        confirmationSound = SOUNDS.CHAMPION_RESPEC_ACCEPT
    else
        confirmationSound = SOUNDS.CHAMPION_POINTS_COMMITTED
    end
    PlaySound(confirmationSound)
    self.awaitingSpendPointsResponse = true
end

function ChampionPerks:RefreshConstellationStates()
    for i, constellation in ipairs(self.constellations) do
        constellation:RefreshState()
    end
end

function ChampionPerks:RefreshChosenConstellationState()
    if self.chosenConstellation then
        self.chosenConstellation:RefreshState()
    end
end

function ChampionPerks:RefreshSelectedStarTooltip()
    if self.chosenConstellation then
        self.chosenConstellation:RefreshSelectedStarTooltip()
    end
end

function ChampionPerks:DirtySelectedStar()
    self.refreshGroup:MarkDirty("SelectedStarData")
end

function ChampionPerks:RefreshStarEditors()
    for _, starEditor in self.starEditorPool:ActiveObjectIterator() do
        starEditor:RefreshPointsMinMax()
        starEditor:RefreshEnabledState()
    end
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
        self.isInRespecMode = inRespecMode
        self:ClearUnsavedChanges()
        self:RefreshKeybinds()
    end
end

function ChampionPerks:IsInRespecMode()
    return self.isInRespecMode
end

--One Shot Animations

ZO_CHAMPION_STAR_CONFIRMATION_DELAY_MS = 50


local function SortConfirmStars(left, right)
    local chosenConstellation = CHAMPION_PERKS:GetChosenConstellation()
    local isLeftConstellationChosen = left:GetConstellation() == chosenConstellation
    local isRightConstellationChosen = right:GetConstellation() == chosenConstellation
    --Show animations for the shown constellation first
    if isLeftConstellationChosen ~= isRightConstellationChosen then
        return isLeftConstellationChosen
    end

    local leftDisciplineIndex, leftSkillIndex
    if left:IsSkillStar() then
        leftDisciplineIndex, leftSkillIndex = left:GetChampionSkillData():GetSkillIndices()
    else
        leftDisciplineIndex, leftSkillIndex = left:GetRootChampionSkillData():GetSkillIndices()
    end

    local rightDisciplineIndex, rightSkillIndex
    if right:IsSkillStar() then
        rightDisciplineIndex, rightSkillIndex = right:GetChampionSkillData():GetSkillIndices()
    else
        rightDisciplineIndex, rightSkillIndex = right:GetRootChampionSkillData():GetSkillIndices()
    end

    -- taking advantage of the fact that discipline indices are pre-sorted left-to-right in the top level view
    if leftDisciplineIndex ~= rightDisciplineIndex then
        return leftDisciplineIndex < rightDisciplineIndex
    end

    -- taking advantage of the fact that skill indices are pre-sorted by their depth-first location in the skill tree
    return leftSkillIndex < rightSkillIndex
end

function ChampionPerks:PrepareStarConfirmAnimation()
    ZO_ClearNumericallyIndexedTable(self.starsToAnimateForConfirm)
    for _, constellation in ipairs(self.constellations) do
        constellation:CollectStarsToAnimateForConfirm(self.starsToAnimateForConfirm)
    end

    table.sort(self.starsToAnimateForConfirm, SortConfirmStars)

    if not self.confirmCameraTimeline then
        self.confirmCameraTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_ChampionConfirmCameraAnimation")
        self.confirmCameraPrepTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_ChampionConfirmCameraPrepAnimation")
    end
    self.confirmAnimationPlaying = false
end

function ChampionPerks:StartStarConfirmAnimation()
    self.nextConfirmAnimationTime = (GetGameTimeMilliseconds() + ZO_CHAMPION_STAR_CONFIRMATION_DELAY_MS) / 1000
    self.firstStarConfirm = true
    self.confirmAnimationPlaying = true
end

local CAMERA_SHAKE_MAGNITUDE_X = 1.5
local CAMERA_SHAKE_MAGNITUDE_Y = 0.75

function ChampionPerks:OnConfirmCameraShakeUpdate(timeline, progress)
    local offsetX = math.sin(progress * ZO_TWO_PI) * CAMERA_SHAKE_MAGNITUDE_X
    local offsetY = math.sin(progress * ZO_TWO_PI * 2) * CAMERA_SHAKE_MAGNITUDE_Y
    self:SetCameraAnimationOffsetXY(offsetX, offsetY)
end

local CAMERA_PREP_MAGNITUDE_Z = 0.005

function ChampionPerks:OnConfirmCameraPrepUpdate(timeline, progress)
    self:SetCameraAnimationOffsetZ(progress * CAMERA_PREP_MAGNITUDE_Z)
end

function ChampionPerks:OnConfirmCameraPrepStop()
    self:SetCameraAnimationOffsetZ(0)
end

--Animation

function ChampionPerks:ZoomOut()
    self.stateMachine:FireCallbacks("ZOOM_OUT")
end

function ChampionPerks:ChooseConstellationNode(node)
    self.nextTargetNode = node
    self.stateMachine:FireCallbacks("ZOOM_IN")
end

function ChampionPerks:ChooseClusterData(championClusterData)
    self.nextTargetClusterData = championClusterData
    self.stateMachine:FireCallbacks("ZOOM_IN")
end

function ChampionPerks:CycleToTargetNode(targetNode)
    if self.stateMachine:IsCurrentState("CONSTELLATION_CYCLE") then
        -- completing the animation will put us back into the constellation state, where we can queue another cycle
        self:CompleteAnimation()
    end

    self.nextTargetNode = targetNode
    self.stateMachine:FireCallbacks("CYCLE")
end

function ChampionPerks:CycleToLeftNode()
    if self.chosenRingNode then
        self:CycleToTargetNode(self.ring:GetPreviousNode(self.chosenRingNode))
    end
end

function ChampionPerks:CycleToRightNode()
    if self.chosenRingNode then
        self:CycleToTargetNode(self.ring:GetNextNode(self.chosenRingNode))
    end
end

function ChampionPerks:SelectOrChooseNodeForDisciplineId(disciplineId)
    local constellationForDiscipline = nil
    for disciplineIndex, constellation in ipairs(self.constellations) do
        if constellation:GetChampionDisciplineData():GetId() == disciplineId then
            constellationForDiscipline = constellation
            break
        end
    end

    if constellationForDiscipline then
        --We want to do different things depending on whether we are zoomed in or out
        if self:HasChosenConstellation() then
            local mostRecentNode = self.chosenRingNode
            local targetNode = constellationForDiscipline:GetNodeInSameHemisphereAsOtherNode(mostRecentNode)
            self:CycleToTargetNode(targetNode)
        elseif self:IsViewingRing() then
            local targetNode = constellationForDiscipline:GetNodeInSameHemisphereAsOtherNode(self.selectedRingNode)
            self:MoveConstellationSelectorToAngleInternal(targetNode.finalRotation)
        end
    end
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

function ChampionPerks:GetCameraPanXY()
    return self.cameraPanX, self.cameraPanY
end

function ChampionPerks:SetCameraPanXY(x, y)
    self.cameraPanX = x
    self.cameraPanY = y
    self:RefreshCameraPosition()
end

function ChampionPerks:ResetCameraPan()
    self.cameraPanX = 0
    self.cameraPanY = 0
    self.cameraPanZ = 0
    self:RefreshCameraPosition()
end

function ChampionPerks:SetCameraAnimationOffsetXY(x, y)
    self.cameraAnimationOffsetX = x
    self.cameraAnimationOffsetY = y
    self:RefreshCameraPosition()
end

function ChampionPerks:SetCameraAnimationOffsetZ(z)
    self.cameraAnimationOffsetZ = z
    self:RefreshCameraPosition()
end

function ChampionPerks:RefreshCameraPosition()
    self.sceneGraph:SetCameraX(self.cameraRootX + self.cameraAnimationOffsetX + self.cameraPanX)
    self.sceneGraph:SetCameraY(self.cameraRootY + self.cameraAnimationOffsetY + self.cameraPanY)
    self.sceneGraph:SetCameraZ(self.cameraRootZ + self.cameraAnimationOffsetZ + self.cameraPanZ)
end

function ChampionPerks:ResetToInactive()
    if self.currentChangingEditor then
        -- release
        self.currentChangingEditor:StopChangingPoints()
        self.currentChangingEditor = nil
    end
    self:CompleteAnimation()
    GAMEPAD_CHAMPION_QUICK_MENU:Hide()
    self.championBar:GetGamepadEditor():UnfocusBar()
    -- skipping the edge graph, every state should be able to transition to inactive and not leave us in a bad state
    self.stateMachine:SetCurrentState("INACTIVE")
    self:SelectConstellationNodeInternal(nil)
    local UNCHOOSE_INSTANTLY = true
    self:SetChosenConstellationNodeInternal(nil, UNCHOOSE_INSTANTLY)
    self.ring:SetAllNodesPadding(0)
    self:ResetCameraPan()
end

function ChampionPerks:SetAnimation(animation)
    if not self:IsAnimating() then
        self.currentAnimation = animation
        self.t = 0
        self.startCameraX = self.sceneGraph:GetCameraX()
        self.startCameraY = self.sceneGraph:GetCameraY()
        self.startCameraZ = self.sceneGraph:GetCameraZ()
        self.startAngle = self.ring:GetAngle()
        self:RefreshKeybinds()
    end
end

function ChampionPerks:CompleteAnimation()
    if self.currentAnimation then
        self.currentAnimation = nil
        self.animationVisualInfo = nil
        self:RefreshKeybinds()
        self.stateMachine:FireCallbacks("ANIMATION_COMPLETE")
    end
end

function ChampionPerks:IsAnimating()
    return self.currentAnimation ~= nil
end

function ChampionPerks:IsViewingConstellationOrCluster()
    return self.stateMachine:IsCurrentState("CONSTELLATION") or self.stateMachine:IsCurrentState("CLUSTER")
end

function ChampionPerks:IsViewingRing()
    return self.stateMachine:IsCurrentState("RING")
end

function ChampionPerks:HasChosenConstellation()
    return self.chosenConstellation ~= nil
end

function ChampionPerks:UpdateAnimations(frameDeltaSecs)
    if self.currentAnimation then
        local anim = self.currentAnimation

        if self.t == 0 then
            if anim.targetNode then
                --setup the final state to determine our target angle
                if anim.nodePadding then
                    for node, targetPadding in pairs(anim.nodePadding) do
                        node.ringPreviousPadding = self.ring:GetNodePadding(node)
                        self.ring:SetNodePadding(node, targetPadding)
                    end
                    self.ring:RefreshNodePositions()
                end

                anim.targetAngle = (-anim.targetNode:GetRotation() + ZO_HALF_PI) % ZO_TWO_PI

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

            if anim.unchooseNode then
                self:SetChosenConstellationNodeInternal(nil, anim.unchooseInstantly or UNCHOOSE_SMOOTHLY)
            end

            if anim.targetCluster then
                self.chosenConstellation:SelectStar(nil)
                anim.targetCluster:SetHidden(false)
                anim.startingCluster:SetActive(false)
                
                 self.animationVisualInfo = 
                 {
                    constellationZoomedInBackgroundAlpha =
                    {
                        fluxMin = 0.6,
                        fluxMax = 1.0,
                        fluxPeriodSeconds = 3,
                    },
                    starAlpha = {},
                    childStarAlpha = {},
                 }
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
            if anim.chooseTargetNode and self.t >= anim.duration * anim.chooseTargetNodeAtDurationPercent then
                local UNCHOOSE_SMOOTHLY = false
                self:SetChosenConstellationNodeInternal(anim.targetNode, UNCHOOSE_SMOOTHLY)
            end
        end

        --Fade in the target cluster
        if anim.targetCluster then
            if anim.targetCluster:IsRootCluster() then
                self.animationVisualInfo.starAlpha.base = animProgress
            else
                self.animationVisualInfo.childStarAlpha.base = animProgress
            end
        end

        --Fade out the starting cluster
        if anim.startingCluster then
            local fadeProgress = animProgress
            if anim.startingFadeDuration then
                fadeProgress = self.t / anim.startingFadeDuration

                if fadeProgress > 1 then
                    fadeProgress  = 1
                end

                if anim.easingFunction then
                    fadeProgress = anim.easingFunction(fadeProgress)
                end
            end

            if anim.startingCluster:IsRootCluster() then
                self.animationVisualInfo.starAlpha.base = 1 - fadeProgress
            else
                self.animationVisualInfo.childStarAlpha.base = 1 - fadeProgress
            end
        end

        if self.t == anim.duration then
            self:CompleteAnimation()
        else
            self.t = self.t + frameDeltaSecs
        end
    end
end

function ChampionPerks:UpdateCenterAlpha(timeSecs, frameDeltaSecs)
    local centerAlpha = self.centerInfoAlphaInterpolator:Update(timeSecs, frameDeltaSecs)
    self.centerInfoControl:SetAlpha(centerAlpha)
    self.radialSelectorTexture:SetAlpha(centerAlpha)
end

--Gamepad Input

local numDisciplines = GetNumChampionDisciplines()
-- clamp to the center of the first and last constellations within the half circle
local RADIAL_SELECTOR_ANGLE_MIN = ZO_HALF_PI / numDisciplines
local RADIAL_SELECTOR_ANGLE_MAX = ZO_PI * (numDisciplines - 0.5) / numDisciplines
local function ClampRadialSelectorAngle(angle)
    if angle > RADIAL_SELECTOR_ANGLE_MIN and angle < RADIAL_SELECTOR_ANGLE_MAX then
        return angle
    end
    local distanceToMin = zo_arcSize(angle, RADIAL_SELECTOR_ANGLE_MIN)
    local distanceToMax = zo_arcSize(angle, RADIAL_SELECTOR_ANGLE_MAX)
    if distanceToMin < distanceToMax then
        return RADIAL_SELECTOR_ANGLE_MIN
    else
        return RADIAL_SELECTOR_ANGLE_MAX
    end
end

function ChampionPerks:UpdateKeyboardSelectedConstellation()
    local mx, my = GetUIMousePosition()
    local cx, cy = self.radialSelectorNode:TransformPoint(0, 0, ZO_CHAMPION_STAR_DEPTH)
    local dx = mx - cx
    local dy = my - cy
    local angle = ClampRadialSelectorAngle(math.atan2(-dy, dx)) -- atan2 assumes +y = up
    self:MoveConstellationSelectorToAngle(angle)
end

function ChampionPerks:UpdateGamepadSelectedConstellation()
    -- this math assumes +y = up
    local dx, dy = DIRECTIONAL_INPUT:GetXY(ZO_DI_LEFT_STICK, ZO_DI_DPAD)
    local magSq = dx * dx + dy * dy
    if magSq > 0.04 and (self.radialSelectorLastMagSq == nil or magSq + 0.01 >= self.radialSelectorLastMagSq) then
        local angle = ClampRadialSelectorAngle(math.atan2(dy, dx))
        self:MoveConstellationSelectorToAngle(angle)
    end
    self.radialSelectorLastMagSq = zo_min(0.85, magSq)
end

function ChampionPerks:ResetConstellationSelectorToTop()
    self:MoveConstellationSelectorToAngleInternal(ZO_HALF_PI)
end

function ChampionPerks:MoveConstellationSelectorToAngleInternal(angle)
    self.radialSelectorNode:SetRotation(angle - ZO_HALF_PI)
    local closestNodeToAngle = self.ring:GetNodeAtAngle(angle)
    return self:SelectConstellationNodeInternal(closestNodeToAngle)
end

function ChampionPerks:MoveConstellationSelectorToAngle(angle)
    if self:MoveConstellationSelectorToAngleInternal(angle) and self.selectedConstellation ~= nil then
        self.selectedConstellation:PlayOnSelectedSound()
    end
end

function ChampionPerks:UpdateDirectionalInput()
    local barEditor = self.championBar:GetGamepadEditor()
    if barEditor:IsFocused() then
        -- pick a slot on the champion bar
        barEditor:UpdateDirectionalInput()
    elseif self:IsViewingConstellationOrCluster() then
        -- pick a star
        self.gamepadCursor:UpdateDirectionalInput()
    elseif self:IsViewingRing() then
        -- pick a constellation
        self:UpdateGamepadSelectedConstellation()
    end
end

local CONSTELLATION_VISUALS =
{
    ZOOMED_OUT =
    {
        starAlpha =
        {
            base = 0.3,
        },
    },
    ZOOMED_OUT_SELECTED =
    {
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
        childStarAlpha =
        {
            base = 0,
        },
    },
    ZOOMED_IN_CLUSTER =
    {
        starAlpha =
        {
            base = 0,
        },        
        childStarAlpha =
        {
            base = 1,
        },
    },
    ZOOMED_IN_CHOSEN = { },
    ZOOMED_IN_NOT_SHOWN =
    {
        starAlpha =
        {
            base = 0.3,
        },
    },
}

local RING_ANCHOR_VISUALS =
{
    ZOOMED_OUT =
    {
        constellationBaseAlpha =
        {
            base = 0.5
        },
        constellationZoomedInBackgroundAlpha =
        {
            fluxMin = 0.0,
            fluxMax = 0.1,
            fluxPeriodSeconds = 3,
        },
        linkAlpha =
        {
            base = 0.2,
        }
    },
    ZOOMED_OUT_SELECTED =
    {
        constellationBaseAlpha =
        {
            base = 0.5
        },
        constellationSelectedAlpha =
        {
            fluxMin = 0.5,
            fluxMax = 0.8,
            fluxPeriodSeconds = 3,
        },
        linkAlpha =
        {
            base = 0.2,
        }
    },
    ZOOMED_OUT_SELECTED_ZOOMING_IN =
    {
        constellationBaseAlpha =
        {
            fluxMin = 0.0,
            fluxMax = 0.2,
            fluxPeriodSeconds = 3,
        },
        constellationZoomedInBackgroundAlpha =
        {
            base = 0.7,
        },
        linkAlpha =
        {
            base = 1,
        }
    },
    ZOOMED_IN_CLUSTER =
    {
        constellationBaseAlpha =
        {
            base = 0,
        },
        constellationZoomedInBackgroundAlpha =
        {
            base = 0,
        },
        linkAlpha =
        {
            fluxMin = 0.8,
            fluxMax = 1,
            fluxPeriodSeconds = 6,
        }
    },
    ZOOMED_IN_CHOSEN =
    {
        constellationBaseAlpha =
        {
            fluxMin = 0.0,
            fluxMax = 0.3,
            fluxPeriodSeconds = 6,
        },
        constellationZoomedInBackgroundAlpha =
        {
            base = 0.7,
        },
        linkAlpha =
        {
            fluxMin = 0.6,
            fluxMax = 1,
            fluxPeriodSeconds = 4,
        }
    },
    ZOOMED_IN_NOT_SHOWN =
    {
        constellationBaseAlpha =
        {
            fluxMin = 0.0,
            fluxMax = 0.2,
            fluxPeriodSeconds = 3,
        },
        constellationZoomedInBackgroundAlpha =
        {
            base = 0.7,
        },
        linkAlpha =
        {
            base = 0.4,
        }
    },
}

local CONFIRM_ANIMATION_SPACING = 0.3

function ChampionPerks:OnUpdate(timeSecs)
    local frameDeltaSecs = zo_min(GetFrameDeltaSeconds(), 0.25)

    local isEnteringConstellation = self.stateMachine:IsCurrentState("CONSTELLATION_IN")

    if not IsInGamepadPreferredMode()  and not isEnteringConstellation then
        if self:IsViewingRing() then
            self:UpdateKeyboardSelectedConstellation()
        else
            self:SelectConstellationNodeInternal(nil)
        end
    end

    --This needs to happen before UpdateVisuals is run so the visual state changes that can happen here don't happen a frame late
    self:UpdateAnimations(frameDeltaSecs)

    --Visual State
    for _, constellation in ipairs(self.constellations) do
        local visualInfo
        if self.chosenConstellation then
            if constellation == self.chosenConstellation then
                if self.chosenConstellation.currentCluster:IsRootCluster() then
                    visualInfo = CONSTELLATION_VISUALS.ZOOMED_IN_CHOSEN
                else
                    visualInfo = CONSTELLATION_VISUALS.ZOOMED_IN_CLUSTER
                end
            else
                visualInfo = CONSTELLATION_VISUALS.ZOOMED_IN_NOT_SHOWN
            end
        else
            if constellation == self.selectedConstellation then
                if self.stateMachine:IsCurrentState("CONSTELLATION_IN") then
                    visualInfo = CONSTELLATION_VISUALS.ZOOMED_OUT_SELECTED_ZOOMING_IN
                else
                    visualInfo = CONSTELLATION_VISUALS.ZOOMED_OUT_SELECTED
                end
            else
                visualInfo = CONSTELLATION_VISUALS.ZOOMED_OUT
            end
        end

        if self.animationVisualInfo then
            constellation:SetVisualInfo(self.animationVisualInfo)
        else
            constellation:SetVisualInfo(visualInfo)
        end
        constellation:UpdateVisuals(timeSecs, frameDeltaSecs)
    end

    for _, ringAnchor in ipairs(self.ringAnchors) do
        local ringNode = ringAnchor:GetNode()
        local visualInfo
        if self.chosenConstellation then
            if ringNode == self.chosenRingNode then
                if self.chosenConstellation.currentCluster:IsRootCluster() then
                    visualInfo = RING_ANCHOR_VISUALS.ZOOMED_IN_CHOSEN
                else
                    visualInfo = RING_ANCHOR_VISUALS.ZOOMED_IN_CLUSTER
                end
            else
                visualInfo = RING_ANCHOR_VISUALS.ZOOMED_IN_NOT_SHOWN
            end
        else
            if ringNode == self.selectedRingNode then
                if self.stateMachine:IsCurrentState("CONSTELLATION_IN") then
                    visualInfo = RING_ANCHOR_VISUALS.ZOOMED_OUT_SELECTED_ZOOMING_IN
                else
                    visualInfo = RING_ANCHOR_VISUALS.ZOOMED_OUT_SELECTED
                end
            else
                visualInfo = RING_ANCHOR_VISUALS.ZOOMED_OUT
            end
        end

        if self.animationVisualInfo then
            ringAnchor:SetVisualInfo(self.animationVisualInfo)
        else
            ringAnchor:SetVisualInfo(visualInfo)
        end
        ringAnchor:UpdateVisuals(timeSecs, frameDeltaSecs)
    end

    --Cloud Rotation
    self.cloudsNode:SetRotation(self.cloudsNode:GetRotation() + 0.03 * frameDeltaSecs)
    self.skyCloudsNode:SetRotation(self.skyCloudsNode:GetRotation() + 0.01 * frameDeltaSecs)
    self.smokeNode:SetRotation(self.smokeNode:GetRotation() + 0.05 * frameDeltaSecs)    
    
    if isEnteringConstellation then
        if not self.enteredZoomedInAt then
            self.enteredZoomedInAt = timeSecs
        end
        local timeSinceAnimStart = timeSecs - self.enteredZoomedInAt
        self.smokeTexture:SetAlpha(zo_min(1, timeSinceAnimStart * 0.5))
    else
        self.enteredZoomedInAt = nil
        self.smokeTexture:SetAlpha(0)
    end

    self.keyboardStatusControl:SetAlpha(self.keyboardStatusAlphaInterpolator:Update(timeSecs))

    self:UpdateCenterAlpha(timeSecs, frameDeltaSecs)
    self.ring:Update(frameDeltaSecs)

    --Close Cloud Breathing
    -- only play close clouds while zoomed out
    if self.sceneGraph:GetCameraZ() <= ZO_CHAMPION_ZOOMED_OUT_CAMERA_Z then
        if not self.closeCloudsTimeline:IsPlaying() then
            self.closeCloudsTimeline:PlayFromStart()
        end
    else
        self.closeCloudsTimeline:PlayInstantlyToStart()
        self.closeCloudsTimeline:Stop()
    end

    --Star Confirm Animations
    if self.confirmAnimationPlaying then
        if timeSecs > self.nextConfirmAnimationTime then
            self.nextConfirmAnimationTime = timeSecs + CONFIRM_ANIMATION_SPACING
            local star = table.remove(self.starsToAnimateForConfirm, 1)
            if star then
                star:PlayPurchaseConfirmAnimation()
            end
            if self.firstStarConfirm then
                self.firstStarConfirm = false
                self.confirmCameraPrepTimeline:PlayFromStart()
                self.confirmCameraTimeline:PlayFromStart()
            end
            if #self.starsToAnimateForConfirm == 0 then
                self.confirmAnimationPlaying = false
            end
        end
    end
end

local SPIRAL_STAR_MAX_ALPHA = 0.5
local SPIRAL_STAR_ANGLE_DISTANCE = ZO_PI * 0.25

function ChampionPerks:OnSpiralUpdate(animation, progress)
    local progressDelta = 1 / #self.starSpirals
    for i, textureControl in ipairs(self.starSpirals) do
        local node = textureControl.node
        local adjustedProgress = (progress + (i - 1) * progressDelta) % 1
        node:SetZ(STAR_SPIRAL_START_DEPTH + adjustedProgress * (STAR_SPIRAL_END_DEPTH - STAR_SPIRAL_START_DEPTH))
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
    self.refreshGroup:MarkDirty("Points")
end

function ChampionPerks:OnChampionSystemUnlocked()
    TriggerTutorial(TUTORIAL_TRIGGER_CHAMPION_SYSTEM_UNLOCKED)
    self:SetChampionSystemNew(true)
end

function ChampionPerks:OnUnspentChampionPointsChanged()
    if self.initialized then
        if not self.awaitingSpendPointsResponse then
            self:RefreshMenuIndicators()
            self.refreshGroup:MarkDirty("Points")
        end
    else
        --update menus even before the system is initialized
        self:RefreshMenuIndicators()
    end
end

function ChampionPerks:OnChampionPurchaseResult(result)
    if self.awaitingSpendPointsResponse then
        self.awaitingSpendPointsResponse = false

        if result == CHAMPION_PURCHASE_SUCCESS then
            self:StartStarConfirmAnimation()
        end
    end

    self.isInRespecMode = false
    self:ClearUnsavedChanges()

    self.refreshGroup:MarkDirty("AllData")
end

function ChampionPerks:OnSelectedStarChanged(oldSelectedStar, newSelectedStar)
    self:RefreshKeybinds()
end

function ChampionPerks:OnMoneyChanged()
    if self:IsInRespecMode() then
        self.refreshGroup:MarkDirty("KeybindStrip")
    end
end

function ChampionPerks:OnPlayerActivated()
    self.refreshGroup:MarkDirty("KeybindStrip")
    if CHAMPION_DATA_MANAGER:HasAnySavedUnspentPoints() then
        TriggerTutorial(TUTORIAL_TRIGGER_CHAMPION_POINTS_UNSPENT)
    end
end

function ChampionPerks:OnPowerUpdate(eventCode, unitTag, powerIndex, powerType, value, max, effectiveMax)
    if unitTag == "player" and powerType == COMBAT_MECHANIC_FLAGS_HEALTH then
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

function ChampionPerks:OnCanvasMouseUp(button, upInside)
    if self.keybindState == KEYBIND_STATES.QUICK_MENU or self.keybindState == KEYBIND_STATES.ACTION_BAR then
        return
    end

    if button == MOUSE_BUTTON_INDEX_LEFT then
        if self:GetSelectedStar() ~= nil then
            self.chosenConstellation:SelectStar(nil)
        elseif self.selectedConstellation then
            self:ChooseConstellationNode(self.selectedRingNode)
        end
    elseif button == MOUSE_BUTTON_INDEX_RIGHT then
        if GetCursorContentType() ~= MOUSE_CONTENT_EMPTY then
            ClearCursor()
        elseif self.chosenConstellation then
            self:ZoomOut()
        end
    end
end

ZO_CHAMPION_CURSOR_DEPTH = ZO_CHAMPION_STAR_DEPTH - .01
ZO_CHAMPION_CURSOR_SIZE = 32
ZO_ChampionConstellationCursor_Gamepad = ZO_InitializingObject:Subclass()

function ZO_ChampionConstellationCursor_Gamepad:Initialize(control)
    self.control = control
    self.control:SetHidden(true)
    self.depth = ZO_CHAMPION_CURSOR_DEPTH
end

function ZO_ChampionConstellationCursor_Gamepad:OnZoomIn()
    self.x, self.y = GuiRoot:GetCenter()
    self.initialX, self.initialY = self.x, self.y
    self.sensitivityFactor = 1
    self.control:SetAnchor(CENTER, GuiRoot, TOPLEFT)
    self:UpdateVisibility()
end

function ZO_ChampionConstellationCursor_Gamepad:OnZoomOut()
    self:UpdateVisibility()
end

ZO_CHAMPION_CURSOR_SPEED = 10
ZO_CHAMPION_COUNTERSCROLL_FACTOR_X = 0.35
ZO_CHAMPION_COUNTERSCROLL_FACTOR_Y = 0.35
ZO_CHAMPION_SELECTING_STAR_SENSITIVITY = .5
ZO_CHAMPION_SENSITIVITY_APPROACH = 1
function ZO_ChampionConstellationCursor_Gamepad:UpdateDirectionalInput()
    local dx, dy = DIRECTIONAL_INPUT:GetXY(ZO_DI_LEFT_STICK, ZO_DI_DPAD)
    dx, dy = zo_clampLength2D(dx, dy, 1.0) -- clamp dpad output
    local frameDelta = GetFrameDeltaNormalizedForTargetFramerate()
    dx = dx * frameDelta * ZO_CHAMPION_CURSOR_SPEED * self.sensitivityFactor
    dy = -dy * frameDelta * ZO_CHAMPION_CURSOR_SPEED * self.sensitivityFactor

    self.control:SetAnchor(CENTER, GuiRoot, TOPLEFT, self.x + dx, self.y + dy)
    self.x, self.y = self.control:GetCenter() -- store clamped values

    local counterScrollX = (self.x - self.initialX) * ZO_CHAMPION_COUNTERSCROLL_FACTOR_X
    local counterScrollY = (self.y - self.initialY) * -ZO_CHAMPION_COUNTERSCROLL_FACTOR_Y

    CHAMPION_PERKS:SetCameraPanXY(counterScrollX, counterScrollY)

    local constellation = CHAMPION_PERKS:GetChosenConstellation()

    WINDOW_MANAGER:UpdateCursorPosition(self.cursorId, self.x, self.y)
    local mouseOverControl = WINDOW_MANAGER:GetControlAtCursor(self.cursorId) 
    self.mouseOverControl = mouseOverControl
    
    local targetSensitivity
    if mouseOverControl and mouseOverControl.star then
        constellation:SelectStar(mouseOverControl.star)
        targetSensitivity = ZO_CHAMPION_SELECTING_STAR_SENSITIVITY
    else
        constellation:SelectStar(nil)
        targetSensitivity = 1
    end
    self.sensitivityFactor = zo_deltaNormalizedLerp(self.sensitivityFactor, targetSensitivity, ZO_CHAMPION_SENSITIVITY_APPROACH)
end

function ZO_ChampionConstellationCursor_Gamepad:UpdateVisibility()
    local show
    if IsInGamepadPreferredMode() and CHAMPION_PERKS:HasChosenConstellation() then
        if CHAMPION_PERKS:GetChampionBar():GetGamepadEditor():IsFocused() then
            show = false
        else
            show = true
        end
    else
        show = false
    end

    self.control:SetHidden(not show)

    if show then
        if not self.cursorId then
            self.cursorId = WINDOW_MANAGER:CreateCursor(self.x, self.y)
        end
    else
        if self.cursorId then
            WINDOW_MANAGER:DestroyCursor(self.cursorId)
            self.cursorId = nil
        end
    end

    if not show then
        self.mouseOverControl = nil
    end 
end

function ZO_ChampionConstellationCursor_Gamepad:GetLastSelectedStar()
    if self.mouseOverControl and self.mouseOverControl.star then
        return self.mouseOverControl.star
    else
        return nil
    end
end

--Global XML Handlers

function ZO_ChampionPerksCanvas_OnMouseUp(button, upInside)
    CHAMPION_PERKS:OnCanvasMouseUp(button, upInside)
end

function ZO_ChampionPerks_OnInitialized(self)
    CHAMPION_PERKS = ChampionPerks:New(self)
end

function ZO_ChampionPerks_StarTooltip_Gamepad_Initialize(tooltipControl)
    local function BottomScreenResizeHandler(control)
        local maxHeight = GuiRoot:GetHeight() - (ZO_GAMEPAD_PANEL_FLOATING_HEIGHT_DISCOUNT * 2)
        control:SetDimensionConstraints(0, 0, 0, maxHeight)
    end
    local DEFAULT_TOOLTIP_STYLES = nil
    ZO_ResizingFloatingScrollTooltip_Gamepad_OnInitialized(tooltipControl, DEFAULT_TOOLTIP_STYLES, BottomScreenResizeHandler, LEFT)
end