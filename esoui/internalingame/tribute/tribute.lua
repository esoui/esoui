local ANIMATE_INSTANTLY = true
local ANY_ACTIVE_CARD = nil
local NO_CARD = 0
local NO_PATRON = nil
local NO_RESOURCE = nil

-------------
-- Tribute --
-------------

ZO_TRIBUTE_CARD_POPUP_TYPE =
{
    CARD = 1,
    MECHANIC = 2,
}

ZO_TRIBUTE_SHOW_CARD_POPUP_DELAY_SECONDS = 0
ZO_TRIBUTE_SHOW_CARD_TOOLTIP_DELAY_SECONDS = 0.35
ZO_TRIBUTE_SHOW_RESOURCE_TOOLTIP_DELAY_SECONDS = 0.5

ZO_TRIBUTE_PATRON_TOOLTIP_OFFSET_X = -40
ZO_TRIBUTE_PATRON_TOOLTIP_OFFSET_Y = 0

-- We want to cover 2 meters of board, but also the orient is scaled down since it houses labels.
-- So for the final result to cover the world area we want, we need to set its actual meters to 2 meters inversed by the scale we're going to apply
ZO_TRIBUTE_BOARD_ORIENT_DIMENSIONS = 2 / ZO_TRIBUTE_CARD_WORLD_SCALE

ZO_Tribute = ZO_InitializingObject:Subclass()

function ZO_Tribute:Initialize(control)
    self.control = control
    
    TRIBUTE_FRAGMENT = ZO_SimpleSceneFragment:New(control)
    TRIBUTE_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_HIDING then
            -- Due to the nature of UI controls plastered on models, a timing issue can occur where the UI can hide several frames
            -- before the game cleans up the models resulting in ESO-771856. So if the UI hides, just make sure the TributeState immediately gets us back to viewing the world.
            -- We also don't want to wait for the summary fragment to go away naturally, we want it gone immediately
            SCENE_MANAGER:RemoveFragmentImmediately(TRIBUTE_SUMMARY_FRAGMENT)
            SCENE_MANAGER:RemoveFragmentImmediately(UNIFORM_BLUR_FRAGMENT)
            OnTributeUIHiding()
        end
    end)

    TRIBUTE_SCENE = ZO_RemoteScene:New("tribute", SCENE_MANAGER)
    TRIBUTE_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            self:RefreshInputModeFragments()
            KEYBIND_STRIP:RemoveDefaultExit()
            self:SetupGame()
            --The UI cannot be toggled while a tribute match is ongoing, so make sure it isn't hidden when we start
            if GetGuiHidden("internal_ingame") then
                SetGuiHidden("internal_ingame", false)
            end
        elseif newState == SCENE_HIDING then
            ZO_TRIBUTE_PATRON_SELECTION_MANAGER:EndPatronSelection()
            ZO_TRIBUTE_PILE_VIEWER_MANAGER:SetViewingPile(nil)
            ZO_Dialogs_ReleaseAllDialogsOfName("CONFIRM_CONCEDE_TRIBUTE")
            ZO_Dialogs_ReleaseAllDialogsOfName("GAMEPAD_TRIBUTE_OPTIONS")
            ZO_Dialogs_ReleaseAllDialogsOfName("KEYBOARD_TRIBUTE_OPTIONS")
            if self.beginEndOfGameFanfareEventId then
                zo_removeCallLater(self.beginEndOfGameFanfareEventId)
                self.beginEndOfGameFanfareEventId = nil
            end

            self:ResetResourceTooltip()
            self:ResetDiscardCounters()
            self:ResetCardPopupAndTooltip(ANY_ACTIVE_CARD)
            self:RefreshInputState()
            KEYBIND_STRIP:RestoreDefaultExit()
        elseif newState == SCENE_HIDDEN then
            self.gamepadCursor:Reset()
            self:ResetPatrons()
            self.gameFlowState = TRIBUTE_GAME_FLOW_STATE_INACTIVE

            if self.showVictoryTutorial then
                self.showVictoryTutorial = false
                TUTORIAL_MANAGER:ShowTutorial(TUTORIAL_TRIGGER_TRIBUTE_PVP_VICTORY)
            end
        end
    end)

    self.gameFlowState = TRIBUTE_GAME_FLOW_STATE_INACTIVE

    control:RegisterForEvent(EVENT_TRIBUTE_GAME_FLOW_STATE_CHANGE, function(_, gameFlowState)
        local previousState = self.gameFlowState
        self.gameFlowState = gameFlowState
        if gameFlowState ~= TRIBUTE_GAME_FLOW_STATE_INACTIVE then
            if previousState == TRIBUTE_GAME_FLOW_STATE_INACTIVE then
                self:DeferredInitialize()
            elseif previousState == TRIBUTE_GAME_FLOW_STATE_PLAYING then
                self:ResetDiscardCounters()
            elseif previousState == TRIBUTE_GAME_FLOW_STATE_PATRON_DRAFT then
                --If we still have patronSelectionShowTime set, that means we are ending the drafting state before we actually began showing the selection screen.
                local forceEndSelection = self.patronSelectionShowTime ~= nil
                ZO_TRIBUTE_PATRON_SELECTION_MANAGER:EndPatronSelection(forceEndSelection)
                self.patronSelectionShowTime = nil
            end

            if gameFlowState == TRIBUTE_GAME_FLOW_STATE_INTRO then
                SCENE_MANAGER:Show("tribute")
                self.turnTimerTextLabelTimeline:PlayInstantlyToStart()
            elseif gameFlowState == TRIBUTE_GAME_FLOW_STATE_PATRON_DRAFT then
                self.patronSelectionShowTime = GetFrameTimeSeconds() + TRIBUTE_PATRON_SELECTION_DELAY_SECONDS
            elseif gameFlowState == TRIBUTE_GAME_FLOW_STATE_PLAYING then
                self:OnTributeReadyToPlay()
            elseif gameFlowState == TRIBUTE_GAME_FLOW_STATE_GAME_OVER then
                self:OnGameOver()
            end
            self:RefreshInputState()
        end
    end)

    local function OnAddOnLoaded(event, name)
        if name == "ZO_InternalIngame" then
            self:SetupSavedVars()
            self.control:UnregisterForEvent(EVENT_ADD_ON_LOADED)
        end
    end

    control:RegisterForEvent(EVENT_ADD_ON_LOADED, OnAddOnLoaded)
end

function ZO_Tribute:InitializeControls()
    local control = self.control

    self.cardInstanceIdToCardObject = {}

    self.resourceDisplayControls = {}
    self.discardCounters = {}

    self.activeCardPopup = {}
    self.activeCardTooltip = {}
    self.queuedCardPopup = {}
    self.queuedCardTooltip = {}
    self.queuedResourceTooltip = {}
    self.activeBoardLocationPatronsTooltipCardObject = nil

    self.boardOrientControl = control:GetNamedChild("BoardOrient")

    for perspective = TRIBUTE_PLAYER_PERSPECTIVE_ITERATION_BEGIN, TRIBUTE_PLAYER_PERSPECTIVE_ITERATION_END do
        local discardCounter = CreateControlFromVirtual("$(parent)DiscardCountDisplay", self.boardOrientControl, "ZO_TributeDiscardCountDisplay_Control", perspective)
        self.discardCounters[perspective] = ZO_TributeDiscardCountDisplay:New(discardCounter, perspective)
        local perspectiveResourceDisplayControls = {}
        self.resourceDisplayControls[perspective] = perspectiveResourceDisplayControls
        for resource = TRIBUTE_RESOURCE_ITERATION_BEGIN, TRIBUTE_RESOURCE_ITERATION_END do
            local suffix = string.format("_%d_%d", perspective, resource)
            local resourceDisplayControl = CreateControlFromVirtual("$(parent)ResourceDisplay", self.boardOrientControl, "ZO_TributeResourceDisplay_Control", suffix)
            resourceDisplayControl:SetColor(GetInterfaceColor(INTERFACE_COLOR_TYPE_TRIBUTE_RESOURCE, resource))
            perspectiveResourceDisplayControls[resource] = resourceDisplayControl
        end
    end

    local confirmButtonDescriptor =
    {
        name = GetString(SI_TRIBUTE_TARGET_VIEWER_CONFIRM_ACTION),
        keybind = "UI_SHORTCUT_SECONDARY",
        callback = function()
            local canConfirm, expectedResult = CanConfirmTributeTargetSelection()
            if canConfirm then
                TributeConfirmTargetSelection()
            end
        end,
    }
    self.confirmButton = control:GetNamedChild("Confirm")
    --TODO Tribute: This is done to force the keybind button to be underneath the card popups visually. This should be revisited if we decide we want to move the keybind to world space
    self.confirmButton:SetTransformOffset(0, 0, 0)
    self.confirmButton:SetKeybindButtonDescriptor(confirmButtonDescriptor)
    self.confirmButton:GetNamedChild("Bg"):SetColor(ZO_BLACK:UnpackRGB())

    self.instruction = control:GetNamedChild("Instruction")
    -- ZoFontTributeAntique40 is a rarely used font, so defer loading it until it's actually becomes necessary
    self.instruction:SetFont("ZoFontTributeAntique40")
    self.instructionBackground = self.instruction:GetNamedChild("Background")

    local patronStalls = {}
    self.patronStalls = patronStalls
    for draftId = TRIBUTE_PATRON_DRAFT_ID_ITERATION_BEGIN, TRIBUTE_PATRON_DRAFT_ID_ITERATION_END do
        local patronStallControl = CreateControlFromVirtual("$(parent)PatronStall", self.boardOrientControl, "ZO_TributePatronStall_Control", draftId)
        patronStallControl.object:SetPatronDraftId(draftId)
        patronStalls[draftId] = patronStallControl.object
    end

    local gamepadCursorControl = control:GetNamedChild("GamepadCursor")
    self.gamepadCursorControl = gamepadCursorControl
    self.gamepadCursor = ZO_TributeCursor_Gamepad:New(gamepadCursorControl)

    self.turnTimerTextLabel = self.boardOrientControl:GetNamedChild("TurnTimerText")
    -- ZoFontTributeAntique40 is a rarely used font, so defer loading it until it's actually becomes necessary
    self.turnTimerTextLabel:SetFont("ZoFontTributeAntique40")
    self.turnTimerTextLabelTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_Tribute_HUDFade", self.turnTimerTextLabel)

    self.turnTimerTimeRemainingLabel = self.turnTimerTextLabel:GetNamedChild("TimeRemaining")
    -- ZoFontTributeAntique40 is a rarely used font, so defer loading it until it actually becomes necessary
    self.turnTimerTimeRemainingLabel:SetFont("ZoFontTributeAntique40")
end

function ZO_Tribute:DeferredInitialize()
    if not self.initialized then
        self:InitializeControls()
        self:RegisterForEvents()
        self:RegisterDialogs()

        self.keybindStripDescriptor =
        {
            {
                --Ethereal binds show no text, the name field is used to help identify the keybind when debugging. This text does not have to be localized.
                name = "Tribute Primary",
                keybind = "UI_SHORTCUT_PRIMARY",
                ethereal = true,
                enabled = function()
                    return self:IsInputStyleGamepad()
                end,
                callback = function()
                    local object, objectType = self.gamepadCursor:GetObjectUnderCursor()
                    if objectType == ZO_TRIBUTE_GAMEPAD_CURSOR_TARGET_TYPES.CARD then
                        InteractWithTributeCard(object:GetCardInstanceId())
                    else
                        InteractWithTributeBoard()
                    end
                end,
            },
            {
                --Ethereal binds show no text, the name field is used to help identify the keybind when debugging. This text does not have to be localized.
                name = "Confirm Targets",
                keybind = "UI_SHORTCUT_SECONDARY",
                ethereal = true,
                callback = function()
                    local canConfirm, expectedResult = CanConfirmTributeTargetSelection()
                    if canConfirm then
                        TributeConfirmTargetSelection()
                    else
                        local alertText = GetString("SI_TRIBUTETARGETSELECTIONCONFIRMATIONRESULT", expectedResult)
                        if alertText ~= "" then
                            RequestAlert(UI_ALERT_CATEGORY_ALERT, SOUNDS.GENERAL_ALERT_ERROR,  alertText)
                        end
                    end
                end,
                enabled = function()
                    return self:IsInputStyleMouse() or self:IsInputStyleGamepad()
                end,
            },
            {
                --Ethereal binds show no text, the name field is used to help identify the keybind when debugging. This text does not have to be localized.
                name = "Tribute Negative",
                keybind = "UI_SHORTCUT_NEGATIVE",
                ethereal = true,
                enabled = function()
                    return self:IsInputStyleMouse() or self:IsInputStyleGamepad()
                end,
                callback = function()
                    -- Check whether the current move can be cancelled here rather than in enabled()
                    -- because we may not update the descriptor with every relevant action.
                    if TributeCanCancelCurrentMove() then
                        TributeCancelCurrentMove()
                    end
                end,
            },
        }

        ZO_PlatformStyle:New(function(...) self:ApplyPlatformStyle(...) end)

        self.initialized = true
    end
end

function ZO_Tribute:SetupSavedVars()
    local defaults =
    {
        autoPlayChecked = false,
    }
    self.savedVars = ZO_SavedVars:NewAccountWide("ZO_InternalIngame_SavedVariables", 1, "Tribute", defaults)
end

function ZO_Tribute:RegisterDialogs()
    local GAMEPAD_TRIBUTE_AUTO_PLAY_ENTRY =
    {
        template = "ZO_CheckBoxTemplate_WithoutIndent_Gamepad",
        text = GetString(SI_TRIBUTE_SETTINGS_DIALOG_AUTO_PLAY),
        templateData =
        {
            -- Called when the checkbox is toggled
            setChecked = function(checkBox, checked)
                checkBox.dialog.autoPlay = checked
            end,

            --Used during setup to determine if the data should be setup checked or unchecked
            checked = function(data)
                return data.dialog.autoPlay
            end,

            setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                control.checkBox.dialog = data.dialog
                ZO_GamepadCheckBoxTemplate_Setup(control, data, selected, reselectingDuringRebuild, enabled, active)
            end,

            callback = function(dialog)
                local targetControl = dialog.entryList:GetTargetControl()
                ZO_GamepadCheckBoxTemplate_OnClicked(targetControl)
            end,
        },
    }

    local GAMEPAD_TRIBUTE_CONCEDE_ENTRY =
    {
        template = "ZO_GamepadFullWidthLeftLabelEntryTemplate",
        templateData =
        {
            text = GetString(SI_TRIBUTE_SETTINGS_DIALOG_CONCEDE_MATCH),
            setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                data:SetNameColors(ZO_ERROR_COLOR, ZO_ERROR_COLOR:GetDim())
                ZO_SharedGamepadEntry_OnSetup(control, data, selected, reselectingDuringRebuild, enabled, active)
            end,
            callback = function(dialog)
                ZO_Dialogs_ReleaseDialogOnButtonPress("GAMEPAD_TRIBUTE_OPTIONS")
                ZO_Dialogs_ShowGamepadDialog("CONFIRM_CONCEDE_TRIBUTE")
            end,
            updateFn = function(dialog)
                if WillConcedeCausePenalty() then
                    local forfeitPenaltyMs = GetTributeForfeitPenaltyDurationMs()
                    local formattedTimeText = ZO_FormatTimeMilliseconds(forfeitPenaltyMs, TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_TWELVE_HOUR)
                    local concedeWarningText = zo_strformat(SI_TRIBUTE_SETTINGS_DIALOG_CONCEDE_WARNING, formattedTimeText)
                    GAMEPAD_TOOLTIPS:LayoutTextBlockTooltip(GAMEPAD_LEFT_DIALOG_TOOLTIP, concedeWarningText)
                    ZO_GenericGamepadDialog_ShowTooltip(dialog)
                else
                    ZO_GenericGamepadDialog_HideTooltip(dialog)
                end
            end,
        },
    }

    local GAMEPAD_TRIBUTE_SHOW_GAMER_CARD_ENTRY =
    {
        template = "ZO_GamepadFullWidthLeftLabelEntryTemplate",
        templateData =
        {
            text = GetString(GetGamerCardStringId()),
            setup = ZO_SharedGamepadEntry_OnSetup,
            callback = function(dialog)
                ZO_ShowGamerCardFromDisplayName(dialog.data.opponentName)
                ZO_Dialogs_ReleaseDialogOnButtonPress("GAMEPAD_TRIBUTE_OPTIONS")
            end,
        },
    }

    ZO_Dialogs_RegisterCustomDialog("GAMEPAD_TRIBUTE_OPTIONS",
    {
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
            dialogFragmentGroup = ZO_GAMEPAD_KEYBINDS_FRAGMENT_GROUP,
        },
        setup = function(dialog, data)
            local parametricList = dialog.info.parametricList
            ZO_ClearNumericallyIndexedTable(parametricList)
            table.insert(parametricList, GAMEPAD_TRIBUTE_AUTO_PLAY_ENTRY)
            if IsConsoleUI() and (data.opponentPlayerType == TRIBUTE_PLAYER_TYPE_REMOTE_PLAYER or data.opponentPlayerType == TRIBUTE_PLAYER_TYPE_PLAYER) then
                table.insert(parametricList, GAMEPAD_TRIBUTE_SHOW_GAMER_CARD_ENTRY)
            end
            table.insert(parametricList, GAMEPAD_TRIBUTE_CONCEDE_ENTRY)
            ZO_GenericGamepadDialog_RefreshText(dialog, GetString(SI_TRIBUTE_SETTINGS_DIALOG_TITLE))
            dialog.autoPlay = data.autoPlay
            dialog:setupFunc()
        end,
        updateFn = function(dialog)
            local targetData = dialog.entryList:GetTargetData()
            if targetData and targetData.updateFn then
                targetData.updateFn(dialog)
            end
        end,
        parametricList = {}, -- Added Dynamically
        blockDialogReleaseOnPress = true,
        finishedCallback = function(dialog)
            TRIBUTE:OnSettingsChanged(dialog.autoPlay)
            TRIBUTE:RefreshInputState()
        end,
        buttons =
        {
            {
                keybind = "DIALOG_PRIMARY",
                text = SI_GAMEPAD_SELECT_OPTION,
                callback = function(dialog)
                    local targetData = dialog.entryList:GetTargetData()
                    if targetData and targetData.callback then
                        targetData.callback(dialog)
                    end
                end,
            },
            {
                keybind = "DIALOG_NEGATIVE",
                text = SI_DIALOG_CLOSE,
                callback = function()
                    ZO_Dialogs_ReleaseDialogOnButtonPress("GAMEPAD_TRIBUTE_OPTIONS")
                end
            },
        },
    })

    ZO_Dialogs_RegisterCustomDialog("CONFIRM_CONCEDE_TRIBUTE",
    {
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.BASIC,
            dialogFragmentGroup = ZO_GAMEPAD_KEYBINDS_FRAGMENT_GROUP,
        },
        title =
        {
            text = SI_TRIBUTE_CONFIRM_CONCEDE_DIALOG_TITLE
        },
        mainText =
        {
            text = SI_TRIBUTE_CONFIRM_CONCEDE_DIALOG_DESCRIPTION
        },
        finishedCallback = function()
            TRIBUTE:RefreshInputState()
        end,
        canQueue = true,
        buttons =
        {
            {
                text = SI_DIALOG_ACCEPT,
                callback = function()
                    TributeConcede()
                end
            },
            {
                text = SI_DIALOG_DECLINE,
                -- Nothing to do but close the dialog, since we've already rejected the exit request
            },
        }
    })
end

do
    local ACCEPT = true
    local REJECT = false

    function ZO_Tribute:RegisterForEvents()
        local control = self.control
        
        local cardsContainer = self.control:GetNamedChild("Cards")
        control:RegisterForEvent(EVENT_TRIBUTE_CARD_ADDED, function(_, cardInstanceId)
            local cardObject = TRIBUTE_POOL_MANAGER:AcquireCardByInstanceId(cardInstanceId, cardsContainer, SPACE_WORLD)
            self.cardInstanceIdToCardObject[cardInstanceId] = cardObject
        end)

        control:RegisterForEvent(EVENT_TRIBUTE_CARD_REMOVED, function(_, cardInstanceId)
            local cardObject = self.cardInstanceIdToCardObject[cardInstanceId]
            if cardObject then
                self:ResetCardPopupAndTooltip(cardObject)
                cardObject:ReleaseObject()
                self.cardInstanceIdToCardObject[cardInstanceId] = nil
            end
        end)

        control:RegisterForEvent(EVENT_TRIBUTE_CLEAR_BOARD_CARDS, function()
            self:ResetCardPopupAndTooltip(ANY_ACTIVE_CARD)
            for _, cardObject in pairs(self.cardInstanceIdToCardObject) do
                cardObject:ReleaseObject()
            end
            ZO_ClearTable(self.cardInstanceIdToCardObject)
        end)

        control:RegisterForEvent(EVENT_TRIBUTE_RESOURCE_CHANGED, function(_, perspective, resource, newAmount, delta)
            local perspectiveResourceDisplayControls = self.resourceDisplayControls[perspective]
            if perspectiveResourceDisplayControls then
                local resourceDisplayControl = perspectiveResourceDisplayControls[resource]
                if resourceDisplayControl then
                    resourceDisplayControl:SetText(newAmount)
                end
            end
        end)

        control:RegisterForEvent(EVENT_TRIBUTE_RESOURCE_TOKEN_HIGHLIGHTED, function(_, perspective, resource)
            if perspective and resource then
                self:QueueResourceTooltip(perspective, resource)
                self.gamepadCursor:SetObjectUnderCursor(resource, ZO_TRIBUTE_GAMEPAD_CURSOR_TARGET_TYPES.RESOURCE_TOKEN, true)
            else
                self:ResetResourceTooltip()
                self.gamepadCursor:ResetObjectUnderCursor()
            end
        end)

        control:RegisterForEvent(EVENT_TRIBUTE_BEGIN_TARGET_SELECTION, function(_, needsTargetViewer)
            if not needsTargetViewer then
                --Anchor to the right of the resources area
                self.confirmButton:ClearAnchors()
                local powerResourceDisplayControl = self.resourceDisplayControls[TRIBUTE_PLAYER_PERSPECTIVE_SELF][TRIBUTE_RESOURCE_POWER]
                local screenX, screenY = powerResourceDisplayControl:ProjectRectToScreenAndComputeAABBPoint(RIGHT)
                local CONFIRM_OFFSET_X = 150
                self.confirmButton:SetAnchor(LEFT, GuiRoot, TOPLEFT, screenX + CONFIRM_OFFSET_X, screenY)
                --Only show the confirm button if we actually need one
                if not IsTributeTargetSelectionAutoComplete() then
                    self.confirmButton:SetHidden(false)
                    local canConfirm, expectedResult = CanConfirmTributeTargetSelection()
                    self.confirmButton:SetEnabled(canConfirm)
                end

                local SHOW_INSTRUCTION = true
                self:RefreshInstruction(SHOW_INSTRUCTION)
            end
        end)

        control:RegisterForEvent(EVENT_TRIBUTE_END_TARGET_SELECTION, function()
            self.confirmButton:SetHidden(true)
            local HIDE_INSTRUCTION = false
            self:RefreshInstruction(HIDE_INSTRUCTION)
        end)

        control:RegisterForEvent(EVENT_TRIBUTE_CARD_STATE_FLAGS_CHANGED, function(_, cardInstanceId, stateFlags)
            local cardObject = self.cardInstanceIdToCardObject[cardInstanceId]
            if cardObject then
                local wasHighlighted = cardObject:IsHighlighted()
                local wasTargeted = cardObject:IsTargeted()

                cardObject:OnStateFlagsChanged(stateFlags)

                local isHighlighted = cardObject:IsHighlighted()
                local isTargeted = cardObject:IsTargeted()
                if wasHighlighted ~= isHighlighted then
                    if isHighlighted then
                        self:QueueCardPopupAndTooltip(cardObject)
                    else
                        self:ResetCardPopupAndTooltip(cardObject)
                    end
                elseif isHighlighted then
                    local popupObject = self.activeCardPopup.popupObject
                    if popupObject and popupObject:GetCardInstanceId() == cardInstanceId then
                        -- A popup instance of this card is currently showing; notify that instance as well.
                        popupObject:OnStateFlagsChanged(stateFlags)
                    end
                end

                if wasTargeted ~= isTargeted then
                    if isTargeted then
                        PlaySound(SOUNDS.TRIBUTE_CARD_TARGETED)
                    else
                        PlaySound(SOUNDS.TRIBUTE_CARD_UNTARGETED)
                    end
                    local canConfirm, expectedResult = CanConfirmTributeTargetSelection()
                    self.confirmButton:SetEnabled(canConfirm)
                end
            end
        end)
        
        control:RegisterForEvent(EVENT_TRIBUTE_AGENT_DEFEAT_COST_CHANGED, function(_, cardInstanceId, delta, newDefeatCost, shouldPlayFx)
            local cardObject = self.cardInstanceIdToCardObject[cardInstanceId]
            if cardObject then
                self:ResetCardPopupAndTooltip(ANY_ACTIVE_CARD)

                if shouldPlayFx then
                    cardObject:UpdateDefeatCost(newDefeatCost, delta)
                else
                    cardObject:RefreshDefeatCost()
                end
            end
        end)

        control:RegisterForEvent(EVENT_TRIBUTE_PATRON_STATE_FLAGS_CHANGED, function(_, patronDraftId, stateFlags)
            local patronStallObject = self.patronStalls[patronDraftId]
            local isUnderCursor = ZO_MaskHasFlag(stateFlags, TRIBUTE_PATRON_STATE_FLAGS_HIGHLIGHTED)
            self.gamepadCursor:SetObjectUnderCursor(patronStallObject, ZO_TRIBUTE_GAMEPAD_CURSOR_TARGET_TYPES.PATRON_STALL, isUnderCursor)
        end)

        self.handAndDocksTutorialPiles =
        {
            [TRIBUTE_BOARD_LOCATION_PLAYER_HAND] = ZO_TributePileData:New(TRIBUTE_BOARD_LOCATION_PLAYER_HAND),
            [TRIBUTE_BOARD_LOCATION_DOCKS] = ZO_TributePileData:New(TRIBUTE_BOARD_LOCATION_DOCKS),
        }

        self.deckAndCooldownTutorialPiles =
        {
            [TRIBUTE_BOARD_LOCATION_PLAYER_DECK] = ZO_TributePileData:New(TRIBUTE_BOARD_LOCATION_PLAYER_DECK),
            [TRIBUTE_BOARD_LOCATION_PLAYER_COOLDOWN] = ZO_TributePileData:New(TRIBUTE_BOARD_LOCATION_PLAYER_COOLDOWN),
        }

        control:RegisterForEvent(EVENT_TRIBUTE_PILE_UPDATED, function(_, boardLocation)
            local pileData = self.handAndDocksTutorialPiles[boardLocation]
            if pileData then
                pileData:MarkDirty()
                pileData:TryTriggerHandAndDocksTutorials()
            end

            pileData = self.deckAndCooldownTutorialPiles[boardLocation]
            if pileData then
                pileData:MarkDirty()
                pileData:TryTriggerDeckAndCooldownTutorials()
            end
        end)

        control:RegisterForEvent(EVENT_TRIBUTE_PLAYER_TURN_STARTED, function(_, isLocalPlayer)
            if isLocalPlayer then
                self.turnTimerTextLabelTimeline:PlayForward()
            else
                self.turnTimerTextLabelTimeline:PlayBackward()
            end
        end)

        local function RefreshInputState()
            self:RefreshInputState()
        end

        local function OnGamepadPreferredModeChanged()
            self:RefreshInputModeFragments()
            self:RefreshInputState()
        end

        HELP_MANAGER:RegisterCallback("OverlayVisibilityChanged", RefreshInputState)

        TUTORIAL_MANAGER:RegisterCallback("TriggeredTutorialChanged", RefreshInputState)
    
        control:RegisterForEvent(EVENT_GAMEPAD_PREFERRED_MODE_CHANGED, OnGamepadPreferredModeChanged)

        local function PileViewerStateChanged(oldState, newState)
            if newState == SCENE_FRAGMENT_SHOWING then
                self:RefreshInputState()
            elseif newState == SCENE_FRAGMENT_HIDDEN then
                self:RefreshInputState()
            end
        end

        if not IsConsoleUI() then
            TRIBUTE_PILE_VIEWER_KEYBOARD_FRAGMENT:RegisterCallback("StateChange", PileViewerStateChanged)
        end
        TRIBUTE_PILE_VIEWER_GAMEPAD_FRAGMENT:RegisterCallback("StateChange", PileViewerStateChanged)

        local function TargetViewerStateChanged(oldState, newState)
            if newState == SCENE_FRAGMENT_SHOWING then
                self:RefreshInputState()
            elseif newState == SCENE_FRAGMENT_HIDDEN then
                self:RefreshInputState()
            end
        end

        if not IsConsoleUI() then
            TRIBUTE_TARGET_VIEWER_KEYBOARD_FRAGMENT:RegisterCallback("StateChange", TargetViewerStateChanged)
        end
        TRIBUTE_TARGET_VIEWER_GAMEPAD_FRAGMENT:RegisterCallback("StateChange", TargetViewerStateChanged)

        ZO_TRIBUTE_TARGET_VIEWER_MANAGER:RegisterCallback("ViewingTargetsChanged", function(hasTargets)
            if not hasTargets then
                self:RefreshInputState()
            end
            self.gamepadCursor:RefreshInsets()
        end)

        local function MechanicSelectorStateChanged(oldState, newState)
            if newState == SCENE_FRAGMENT_SHOWING then
                self:RefreshInputState()
            elseif newState == SCENE_FRAGMENT_HIDDEN then
                self:RefreshInputState()
            end
        end
        TRIBUTE_MECHANIC_SELECTOR_FRAGMENT:RegisterCallback("StateChange", MechanicSelectorStateChanged)

        local function PatronSelectionStateChanged(oldState, newState)
            if newState == SCENE_FRAGMENT_SHOWING then
                self:RefreshInputState()
            elseif newState == SCENE_FRAGMENT_HIDDEN then
                self:RefreshInputState()
            end
        end
        if not IsConsoleUI() then
            TRIBUTE_PATRON_SELECTION_KEYBOARD_FRAGMENT:RegisterCallback("StateChange", PatronSelectionStateChanged)
        end
        TRIBUTE_PATRON_SELECTION_GAMEPAD_FRAGMENT:RegisterCallback("StateChange", PatronSelectionStateChanged)

        control:RegisterForEvent(EVENT_REQUEST_TRIBUTE_EXIT, function(_, isInterceptingCloseAction)
            if not TRIBUTE_SUMMARY_FRAGMENT:IsHidden() then
                -- The game over display is up and we got here, just leave immediately
                -- Typically ingame already knows if we're in GAME_OVER, so this should only happen if we manually brought up the summary with dev tools
                TributeExitResponse(ACCEPT)
                return
            end

            -- The game isn't over, so either close whatever is open, or attempt to concede the match
            TributeExitResponse(REJECT)

            local closedMenu = false
            if isInterceptingCloseAction then
                -- Only close whatever is up, and don't concede is something was up
                if ZO_TRIBUTE_PILE_VIEWER_MANAGER:IsViewingPile() then
                    ZO_TRIBUTE_PILE_VIEWER_MANAGER:SetViewingPile(nil)
                    closedMenu = true
                elseif ZO_TRIBUTE_TARGET_VIEWER_MANAGER:IsViewingTargets() or TRIBUTE_MECHANIC_SELECTOR:IsSelectingMechanic() then
                    if TributeCanCancelCurrentMove() then
                        TributeCancelCurrentMove()
                    end
                    closedMenu = true
                end
            end

            if not closedMenu then
                local opponentName, opponentPlayerType = GetTributePlayerInfo(TRIBUTE_PLAYER_PERSPECTIVE_OPPONENT)
                local dialogData =
                {
                    autoPlay = self:IsAutoPlayChecked(),
                    opponentName = opponentName,
                    opponentPlayerType = opponentPlayerType,
                }

                if IsInGamepadPreferredMode() then
                    ZO_Dialogs_ShowGamepadDialog("GAMEPAD_TRIBUTE_OPTIONS", dialogData)
                else
                    ZO_Dialogs_ShowDialog("KEYBOARD_TRIBUTE_OPTIONS", dialogData)
                end
                self:RefreshInputState()
            end
        end)

        self.gamepadCursor:RegisterCallback("ObjectUnderCursorChanged", function(object, objectType, previousObject, previousObjectType)
            if previousObjectType == ZO_TRIBUTE_GAMEPAD_CURSOR_TARGET_TYPES.CARD or previousObjectType == ZO_TRIBUTE_GAMEPAD_CURSOR_TARGET_TYPES.MECHANIC_TILE or previousObjectType == ZO_TRIBUTE_GAMEPAD_CURSOR_TARGET_TYPES.DISCARD_COUNTER then
                previousObject:OnCursorExit()
            end

            if objectType == ZO_TRIBUTE_GAMEPAD_CURSOR_TARGET_TYPES.CARD or objectType == ZO_TRIBUTE_GAMEPAD_CURSOR_TARGET_TYPES.MECHANIC_TILE or objectType == ZO_TRIBUTE_GAMEPAD_CURSOR_TARGET_TYPES.DISCARD_COUNTER then
                object:OnCursorEnter()
            end
        end)

        self.gamepadCursor:RegisterCallback("CursorPositionChanged", function(x, y)
            TRIBUTE_MECHANIC_MANAGER:OnGamepadCursorPositionChanged(x, y)
        end)

        self.gamepadCursor:RegisterCallback("CursorStateChanged", function(active)
            TRIBUTE_MECHANIC_MANAGER:OnGamepadCursorStateChanged(active)
        end)

        local function OnUpdate(_, frameTimeSeconds)
            self:OnUpdate(frameTimeSeconds)
        end

        control:SetHandler("OnUpdate", OnUpdate)
    end
end

function ZO_Tribute:ApplyPlatformStyle()
    ApplyTemplateToControl(self.confirmButton, ZO_GetPlatformTemplate("ZO_KeybindButton"))
    --Reset the text here to handle the force uppercase on gamepad
    self.confirmButton:SetText(GetString(SI_TRIBUTE_TARGET_VIEWER_CONFIRM_ACTION))
    self.confirmButton:UpdateEnabledState()
    local FORCE_UPDATE = true
    self:RefreshInstruction(self.showTargetInstructions, FORCE_UPDATE)
end

function ZO_Tribute:OnUpdate(frameTimeSeconds)
    local popupCardObject = self.queuedCardPopup.cardObject
    if popupCardObject and self.queuedCardPopup.showTimeSeconds <= frameTimeSeconds then
        -- Process and reset queued card popup.
        self.queuedCardPopup.cardObject = nil
        self.queuedCardPopup.showTimeSeconds = nil
        self:ShowCardPopup(popupCardObject)
    end

    local tooltipCardObject = self.queuedCardTooltip.cardObject
    if tooltipCardObject and self.queuedCardTooltip.showTimeSeconds <= frameTimeSeconds then
        -- Process and reset queued card tooltip.
        self.queuedCardTooltip.cardObject = nil
        self.queuedCardTooltip.showTimeSeconds = nil
        self:ShowCardTooltip(tooltipCardObject)
    end

    if self.queuedResourceTooltip.showTimeSeconds and self.queuedResourceTooltip.showTimeSeconds <= frameTimeSeconds then
        local perspective = self.queuedResourceTooltip.perspective
        local resource = self.queuedResourceTooltip.resource
        self.queuedResourceTooltip.perspective = nil
        self.queuedResourceTooltip.resource = nil
        self.queuedResourceTooltip.showTimeSeconds = nil
        self:ShowResourceTooltip(perspective, resource)
    end

    if self.patronSelectionShowTime and self.patronSelectionShowTime <= frameTimeSeconds then
        self.patronSelectionShowTime = nil
        ZO_TRIBUTE_PATRON_SELECTION_MANAGER:BeginPatronSelection()
    end

    local showTurnTimeRemaining = false
    if GetActiveTributePlayerPerspective() == TRIBUTE_PLAYER_PERSPECTIVE_SELF then
        local timeLeftMs = GetTributeRemainingTimeForTurn()
        if timeLeftMs and timeLeftMs <= self.turnTimerWarningThresholdMs then
            local formattedTimeLeft = ZO_FormatTimeMilliseconds(timeLeftMs, TIME_FORMAT_STYLE_DESCRIPTIVE_MINIMAL_HIDE_ZEROES, TIME_FORMAT_PRECISION_SECONDS)
            self.turnTimerTimeRemainingLabel:SetText(formattedTimeLeft)
            showTurnTimeRemaining = true
        end
    end
    self.turnTimerTimeRemainingLabel:SetHidden(not showTurnTimeRemaining)
end

function ZO_Tribute:TryTriggerInitialTutorials()
    -- TODO Tribute: Add tutorials
end

do
    internalassert(TRIBUTE_GAME_FLOW_STATE_ITERATION_END == 5, "New Tribute game flow state, check INPUT_ENABLED_GAME_FLOW_STATES")
    local INPUT_ENABLED_GAME_FLOW_STATES =
    {
        [TRIBUTE_GAME_FLOW_STATE_PLAYING] = true,
    }

    function ZO_Tribute:RefreshInputModeFragments()
        if IsInGamepadPreferredMode() then
            TRIBUTE_SCENE:RemoveFragment(KEYBIND_STRIP_FADE_FRAGMENT)
            TRIBUTE_SCENE:AddFragment(KEYBIND_STRIP_GAMEPAD_FRAGMENT)
        else
            TRIBUTE_SCENE:RemoveFragment(KEYBIND_STRIP_GAMEPAD_FRAGMENT)
            TRIBUTE_SCENE:AddFragment(KEYBIND_STRIP_FADE_FRAGMENT)
        end
    end

    function ZO_Tribute:RefreshInputState()
        local allowPlayerInput = TRIBUTE_SCENE:IsShowing() and INPUT_ENABLED_GAME_FLOW_STATES[self.gameFlowState]
        local resetTargetObjects = true
        local refreshEffectiveCardStates = false

        local isShowingDialog = ZO_Dialogs_IsShowingDialog()
        local isUsingViewer = ZO_TRIBUTE_PILE_VIEWER_MANAGER:IsViewingPile() or ZO_TRIBUTE_TARGET_VIEWER_MANAGER:IsViewingTargets() or TRIBUTE_MECHANIC_SELECTOR:IsSelectingMechanic()
        if isShowingDialog or isUsingViewer or TUTORIAL_MANAGER:IsTutorialTriggered() or HELP_MANAGER:IsHelpOverlayVisible() then
            allowPlayerInput = false
            resetTargetObjects = false
        end

        if self.isPlayerInputEnabled ~= allowPlayerInput then
            if allowPlayerInput then
                KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
            else
                KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
            end
            self.isPlayerInputEnabled = allowPlayerInput
            refreshEffectiveCardStates = true
        end

        local inputStyle = TRIBUTE_INPUT_STYLE_NONE
        if allowPlayerInput or ZO_TRIBUTE_TARGET_VIEWER_MANAGER:IsViewingBoard() then
            inputStyle = IsInGamepadPreferredMode() and TRIBUTE_INPUT_STYLE_GAMEPAD or TRIBUTE_INPUT_STYLE_MOUSE
        end

        if self.gameFlowState == TRIBUTE_GAME_FLOW_STATE_PATRON_DRAFT and not isShowingDialog then
            inputStyle = IsInGamepadPreferredMode() and TRIBUTE_INPUT_STYLE_NONE or TRIBUTE_INPUT_STYLE_MOUSE
        end

        if self.inputStyle ~= inputStyle then
            refreshEffectiveCardStates = true
            resetTargetObjects = false

            local oldInputStyle = self.inputStyle
            self.inputStyle = inputStyle
            SetTributeInputStyle(inputStyle)
        
            local wasMouseStyle = oldInputStyle == TRIBUTE_INPUT_STYLE_MOUSE
            local isMouseStyle = inputStyle == TRIBUTE_INPUT_STYLE_MOUSE
            if wasMouseStyle or isMouseStyle then
                self:SetMouseControlsEnabled(isMouseStyle)
            end
        
            local wasGamepadStyle = oldInputStyle == TRIBUTE_INPUT_STYLE_GAMEPAD
            local isGamepadStyle = inputStyle == TRIBUTE_INPUT_STYLE_GAMEPAD
            if wasGamepadStyle or isGamepadStyle then
                self:SetGamepadControlsEnabled(isGamepadStyle)
            end
        end

        if self.isPlayerInputEnabled then
            -- Perform the update after any potential change to the input style.
            KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
        end

        if refreshEffectiveCardStates then
            self:RefreshEffectiveCardStates()
        end

        if not resetTargetObjects then
            SetHighlightedTributeCard(NO_CARD)
            SetHighlightedTributePatron(NO_PATRON)
            SetHighlightedTributeResource(NO_RESOURCE)
        end
    end
end

function ZO_Tribute:RefreshInstruction(showTargetInstructions, forceRefresh)
    if self.showTargetInstructions ~= showTargetInstructions or forceRefresh then
        self.instruction:SetHidden(not showTargetInstructions)
        self.instruction:ClearAnchors()
        self.instruction:SetHandler("OnUpdate", nil)

        if showTargetInstructions then
            local OFFSET_Y = -20
            if IsInGamepadPreferredMode() then
                self.instruction:SetAnchor(BOTTOM, self.gamepadCursorControl, TOP, 0, OFFSET_Y)
            else
                local updatePositionCallback = function(_, timeSeconds)
                    local mousePositionX, mousePositionY = GetUIMousePosition()
                    self.instruction:SetAnchor(BOTTOM, GuiRoot, TOPLEFT, mousePositionX, mousePositionY + OFFSET_Y)
                end
                self.instruction:SetHandler("OnUpdate", updatePositionCallback)
                local NOT_USED = nil
                updatePositionCallback(NOT_USED, GetFrameTimeSeconds())
            end

            local instructionText = ZO_TRIBUTE_TARGET_VIEWER_MANAGER:GetInstructionText()
            self.instruction:SetText(instructionText)
        end

        self.showTargetInstructions = showTargetInstructions
    end
end

function ZO_Tribute:SetMouseControlsEnabled(enabled)
    if not enabled then
        self:ResetDiscardCounterTooltips()
    end
end

function ZO_Tribute:IsInputStyleMouse()
    return self.inputStyle == TRIBUTE_INPUT_STYLE_MOUSE
end

function ZO_Tribute:SetGamepadControlsEnabled(enabled)
    self.gamepadCursor:SetActive(enabled)
end

function ZO_Tribute:IsInputStyleGamepad()
    return self.inputStyle == TRIBUTE_INPUT_STYLE_GAMEPAD
end

function ZO_Tribute:CanInteractWithCards()
    if ZO_TRIBUTE_TARGET_VIEWER_MANAGER:IsViewingTargets() and not ZO_TRIBUTE_TARGET_VIEWER_MANAGER:IsViewingBoard() then
        return false
    end
    local isViewerOpen = ZO_TRIBUTE_PILE_VIEWER_MANAGER:IsViewingPile() or TRIBUTE_MECHANIC_SELECTOR:IsSelectingMechanic()
    return not isViewerOpen
end

function ZO_Tribute:IsAutoPlayChecked()
    return self.savedVars.autoPlayChecked
end

function ZO_Tribute:OnSettingsChanged(autoPlayChecked)
    if self.savedVars.autoPlayChecked ~= autoPlayChecked then
        self.savedVars.autoPlayChecked = autoPlayChecked
        SetTributeAutoPlayEnabled(autoPlayChecked)
        ZO_SavePlayerConsoleProfile()
    end
end

function ZO_Tribute:OnBoardClicked(button, upInside)
    if self:IsInputStyleMouse() and upInside then
        --Disallow interacting with the board while the target viewer is up
        if ZO_TRIBUTE_TARGET_VIEWER_MANAGER:IsViewingTargets() then
            return
        end

        if button == MOUSE_BUTTON_INDEX_LEFT then
            InteractWithTributeBoard()
        elseif button == MOUSE_BUTTON_INDEX_RIGHT then
            if TributeCanCancelCurrentMove() then
                TributeCancelCurrentMove()
            end
        end
    end
end

function ZO_Tribute:SetupGame()
    self:LayoutBoard()
    self:ResetPatrons()
    SetTributeAutoPlayEnabled(self.savedVars.autoPlayChecked)
    SetTributeGamepadCursorControl(self.gamepadCursorControl)
    --This value can change depending on the arena def, so regrab this value any time we start a match
    self.turnTimerWarningThresholdMs = GetTributeTurnTimerWarningThreshold()

    for _, perspectiveResourceDisplayControls in pairs(self.resourceDisplayControls) do
        for _, resourceDisplayControl in pairs(perspectiveResourceDisplayControls) do
            resourceDisplayControl:SetText("0")
        end
    end
end

function ZO_Tribute:OnTributeReadyToPlay()
    self:TryTriggerInitialTutorials()
    if GetActiveTributePlayerPerspective() == TRIBUTE_PLAYER_PERSPECTIVE_SELF then
        self.turnTimerTextLabelTimeline:PlayForward()
    end
end

function ZO_Tribute:OnGameOver()
    ZO_Dialogs_ReleaseAllDialogsOfName("CONFIRM_CONCEDE_TRIBUTE")
    ZO_Dialogs_ReleaseAllDialogsOfName("GAMEPAD_TRIBUTE_OPTIONS")
    ZO_Dialogs_ReleaseAllDialogsOfName("KEYBOARD_TRIBUTE_OPTIONS")
    -- Give a bit of time for any other animations to play out a bit before going straight to the summary
    local FANFARE_DELAY_MS = 500
    self.beginEndOfGameFanfareEventId = zo_callLater(function(callId)
        if self.beginEndOfGameFanfareEventId == callId then
            self.beginEndOfGameFanfareEventId = nil
            TRIBUTE_SUMMARY:BeginEndOfGameFanfare()
        end
    end, FANFARE_DELAY_MS)

    self.turnTimerTextLabelTimeline:PlayBackward()
end

function ZO_Tribute:LayoutBoard()
    --Don't layout the board if we haven't initialized yet
    if not self.initialized then
        return
    end

    local renderPositionX, renderPositionY, renderPositionZ, rotationXRadians, rotationYRadians, rotationZRadians = GetTributeBoardSurfaceTransform()
    self.boardOrientControl:SetTransformOffset(renderPositionX, renderPositionY, renderPositionZ)
    self.boardOrientControl:SetTransformRotation(rotationXRadians, rotationYRadians, rotationZRadians)

    for perspective, perspectiveResourceDisplayControls in pairs(self.resourceDisplayControls) do
        for resource, resourceDisplayControl in pairs(perspectiveResourceDisplayControls) do
            renderPositionX, renderPositionY, renderPositionZ, rotationXRadians, rotationYRadians, rotationZRadians = GetTributeResourceDisplayTransformInfo(perspective, resource)
            resourceDisplayControl:SetTransformOffset(renderPositionX, renderPositionY, renderPositionZ)
            resourceDisplayControl:SetTransformRotation(rotationXRadians, rotationYRadians, rotationZRadians)
        end
    end

    renderPositionX, renderPositionY, renderPositionZ, rotationXRadians, rotationYRadians, rotationZRadians = GetTributeTurnTimerLabelTransformInfo()
    self.turnTimerTextLabel:SetTransformOffset(renderPositionX, renderPositionY, renderPositionZ)
    self.turnTimerTextLabel:SetTransformRotation(rotationXRadians, rotationYRadians, rotationZRadians)

    for _, discardCounter in pairs(self.discardCounters) do
        discardCounter:UpdateTransform()
    end

    for _, patronStall in pairs(self.patronStalls) do
        patronStall:RefreshLayout()
    end
end

function ZO_Tribute:ResetPatrons()
    for _, patronStall in pairs(self.patronStalls) do
        patronStall:Reset()
    end
end

function ZO_Tribute:RefreshEffectiveCardStates()
    -- Refresh all card instances' effective card states in order to reflect the new pile viewer state.
    for _, cardObject in pairs(self.cardInstanceIdToCardObject) do
        cardObject:RefreshStateFlags()
    end
end

function ZO_Tribute:ResetCardPopupAndTooltip(cardObject)
    -- Reset a popup queued for the specified card.
    if not cardObject or self.queuedCardPopup.cardObject == cardObject then
        self.queuedCardPopup.cardObject = nil
        self.queuedCardPopup.showTimeSeconds = nil
    end

    -- Reset a tooltip queued for the specified card.
    if not cardObject or self.queuedCardTooltip.cardObject == cardObject then
        self.queuedCardTooltip.cardObject = nil
        self.queuedCardTooltip.showTimeSeconds = nil
    end

    self:HideCardPopup(cardObject)
    self:HideCardTooltip(cardObject)
end

function ZO_Tribute:HideCardPopup(cardObject)
    local activeCardPopup = self.activeCardPopup
    if cardObject and cardObject ~= activeCardPopup.cardObject then
        return
    end

    local activeCardObject = activeCardPopup.cardObject
    local popupObject = activeCardPopup.popupObject
    activeCardPopup.cardObject = nil
    activeCardPopup.popupObject = nil

    if popupObject then
        local PLAY_FORWARD = true
        activeCardObject:PlayAlphaAnimation(PLAY_FORWARD, ANIMATE_INSTANTLY)
        popupObject:ReleaseObject()
    end
end

function ZO_Tribute:HideCardTooltip(cardObject)
    local activeBoardLocationPatronsTooltipCardObject = self.activeBoardLocationPatronsTooltipCardObject
    if activeBoardLocationPatronsTooltipCardObject and (not cardObject or activeBoardLocationPatronsTooltipCardObject == cardObject) then
        activeBoardLocationPatronsTooltipCardObject:HideBoardLocationPatronsTooltip()
        self.activeBoardLocationPatronsTooltipCardObject = nil
    end

    local activeCardTooltip = self.activeCardTooltip
    if cardObject and cardObject ~= activeCardTooltip.cardObject then
        return
    end

    local keyboardControl = activeCardTooltip.keyboardControl
    local gamepadControl = activeCardTooltip.gamepadControl
    activeCardTooltip.cardObject = nil
    activeCardTooltip.keyboardControl = nil
    activeCardTooltip.gamepadControl = nil

    if keyboardControl then
        ClearTooltipImmediately(keyboardControl)
    end
    if gamepadControl then
        ZO_TributeCardTooltip_Gamepad_Hide()
    end
end

function ZO_Tribute:QueueCardPopupAndTooltip(cardObject)
    if not self:CanInteractWithCards() then
        return
    end

    if cardObject:IsStacked() then
        if cardObject:ShowBoardLocationPatronsTooltip(self.cardInstanceId) then
            self.activeBoardLocationPatronsTooltipCardObject = cardObject
        end
        return
    end

    local currentTimeSeconds = GetFrameTimeSeconds()
    self.queuedCardPopup.cardObject = cardObject
    self.queuedCardPopup.showTimeSeconds = currentTimeSeconds + ZO_TRIBUTE_SHOW_CARD_POPUP_DELAY_SECONDS
    self.queuedCardTooltip.cardObject = cardObject
    self.queuedCardTooltip.showTimeSeconds = currentTimeSeconds + ZO_TRIBUTE_SHOW_CARD_TOOLTIP_DELAY_SECONDS
end

-- Anchors popup to the center of the cardObject if centerX/Y is omitted.
function ZO_Tribute:ShowCardPopup(cardObject, centerX, centerY)
    self:HideCardPopup(ANY_ACTIVE_CARD)

    if not self:CanInteractWithCards() then
        return
    end

    if not (cardObject and cardObject:IsWorldCard() and cardObject:IsRevealed()) then
        return
    end

    local popupCardObject = TRIBUTE_POOL_MANAGER:AcquireCardByInstanceId(cardObject:GetCardInstanceId(), self.control, SPACE_INTERFACE)
    if not popupCardObject then
        return
    end
    if not (centerX and centerY) then
        -- Fallback to the Screen space center of the World space version of this card.
        centerX, centerY = cardObject:GetScreenCenter()
    end

    self.activeCardPopup.cardObject = cardObject
    self.activeCardPopup.popupObject = popupCardObject
    popupCardObject:ShowAsPopup(centerX, centerY, ZO_TRIBUTE_CARD_POPUP_TYPE.CARD)

    local PLAY_BACKWARD = false
    cardObject:PlayAlphaAnimation(PLAY_BACKWARD, ANIMATE_INSTANTLY)
end

-- Anchors tooltip to the active card popup if anchor details are omitted.
function ZO_Tribute:ShowCardTooltip(cardObject, anchorPoint, anchorControl, anchorRelativePoint, anchorOffsetX, anchorOffsetY)
    self:HideCardTooltip(ANY_ACTIVE_CARD)

    if not self:CanInteractWithCards() then
        return
    end

    if not (cardObject and cardObject:IsWorldCard() and cardObject:IsRevealed()) then
        return
    end

    if not (anchorPoint and anchorControl and anchorRelativePoint) then
        -- Fall back to anchoring to the right of the active card popup,
        -- if a popup is active and associated with the same card.
        local activeCardPopup = self.activeCardPopup
        if activeCardPopup.cardObject ~= cardObject or not activeCardPopup.popupObject then
            return
        end
        anchorControl = activeCardPopup.popupObject.control
        if not anchorControl then
            return
        end

        anchorPoint, anchorRelativePoint = LEFT, RIGHT
        anchorOffsetX, anchorOffsetY = 20, 0
    end

    self.activeCardTooltip.cardObject = cardObject

    if self:IsInputStyleMouse() then
        local tooltipControl = ItemTooltip
        InitializeTooltip(tooltipControl, anchorControl, anchorPoint, anchorOffsetX, anchorOffsetY, anchorRelativePoint)
        tooltipControl:SetTributeCard(cardObject:GetPatronDefId(), cardObject:GetCardDefId())
        self.activeCardTooltip.keyboardControl = tooltipControl
    elseif self:IsInputStyleGamepad() then
        local tooltipControl = ZO_TributeCardTooltip_Gamepad_GetControl()
        ZO_TributeCardTooltip_Gamepad_Show(cardObject, anchorPoint, anchorControl, anchorRelativePoint, anchorOffsetX, anchorOffsetY)
        self.activeCardTooltip.gamepadControl = tooltipControl
    end
end

function ZO_Tribute:QueueResourceTooltip(perspective, resource)
    local currentTimeSeconds = GetFrameTimeSeconds()
    self.queuedResourceTooltip.perspective = perspective
    self.queuedResourceTooltip.resource = resource
    self.queuedResourceTooltip.showTimeSeconds = currentTimeSeconds + ZO_TRIBUTE_SHOW_RESOURCE_TOOLTIP_DELAY_SECONDS
end

function ZO_Tribute:ResetResourceTooltip()
    self.queuedResourceTooltip.perspective = nil
    self.queuedResourceTooltip.resource = nil
    self.queuedResourceTooltip.showTimeSeconds = nil
    self:HideResourceTooltip()
end

function ZO_Tribute:HideResourceTooltip()
    ClearTooltip(InformationTooltip)
    ZO_TributeResourceTooltip_Gamepad_Hide()
end

function ZO_Tribute:ShowResourceTooltip(perspective, resource)
    self:HideResourceTooltip()
    local perspectiveResourceDisplayControls = self.resourceDisplayControls[perspective]
    if perspectiveResourceDisplayControls then
        local resourceDisplayControl = perspectiveResourceDisplayControls[resource]
        if resourceDisplayControl then
            local offsetX, offsetY
            local anchorPoint
            if resource == TRIBUTE_RESOURCE_POWER then
                offsetX, offsetY = resourceDisplayControl:ProjectRectToScreenAndComputeAABBPoint(LEFT)
                offsetX = offsetX - 30
                anchorPoint = RIGHT
            else
                offsetX, offsetY = resourceDisplayControl:ProjectRectToScreenAndComputeAABBPoint(RIGHT)
                offsetX = offsetX + 30
                anchorPoint = LEFT
            end

            if IsInGamepadPreferredMode() then
                ZO_TributeResourceTooltip_Gamepad_Show(resource, anchorPoint, GuiRoot, TOPLEFT, offsetX, offsetY)
            else
                InitializeTooltip(InformationTooltip, GuiRoot, anchorPoint, offsetX, offsetY, TOPLEFT)
                InformationTooltip:AddLine(zo_strformat(SI_TRIBUTE_RESOURCE_NAME_FORMATTER, GetString("SI_TRIBUTERESOURCE", resource)), "", ZO_NORMAL_TEXT:UnpackRGBA())
                InformationTooltip:AddLine(GetString("SI_TRIBUTERESOURCE_TOOLTIP", resource))
            end
        end
    end
end

function ZO_Tribute:ResetDiscardCounterTooltips()
    for _, discardCounter in pairs(self.discardCounters) do
        discardCounter:HideTooltip()
    end
end

function ZO_Tribute:ResetDiscardCounters()
    for _, discardCounter in pairs(self.discardCounters) do
        discardCounter:Reset()
    end
end

function ZO_Tribute:RemoveTutorial(tutorialTrigger)
    TUTORIAL_MANAGER:RemoveTutorialByTrigger(tutorialTrigger)
end

function ZO_Tribute:ShowCardTutorial(tutorialTrigger, cardObject, anchorPoint, relativePoint)
    if TUTORIAL_MANAGER:CanTutorialTriggerFire(tutorialTrigger) then
        local screenX, screenY = cardObject:GetScreenAnchorPosition(relativePoint)
        TUTORIAL_MANAGER:ShowTutorialWithPosition(tutorialTrigger, anchorPoint, screenX, screenY)
    end
end

function ZO_Tribute:ShowPatronStallTutorial(tutorialTrigger, patronStallObject, anchorPoint, relativePoint)
    if TUTORIAL_MANAGER:CanTutorialTriggerFire(tutorialTrigger) then
        local screenX, screenY = patronStallObject:GetScreenAnchorPosition(relativePoint)
        TUTORIAL_MANAGER:ShowTutorialWithPosition(tutorialTrigger, anchorPoint, screenX, screenY)
    end
end

function ZO_Tribute:GetGameFlowState()
    return self.gameFlowState
end

function ZO_Tribute:GetPatronStalls()
    return self.patronStalls
end

function ZO_Tribute:GetPatronStallByPatronId(patronId)
    for _, patronStall in pairs(self.patronStalls) do
        if patronStall.GetId and patronStall:GetId() == patronId then
            return patronStall
        end
    end

    return nil
end

function ZO_Tribute:QueueVictoryTutorial()
    self.showVictoryTutorial = true
end

function ZO_Tribute:GetCardByInstanceId(cardInstanceId)
    return self.cardInstanceIdToCardObject[cardInstanceId]
end

-----------------------------------
-- Tribute Discard Count Display --
-----------------------------------

ZO_TributeDiscardCountDisplay = ZO_InitializingObject:Subclass()

function ZO_TributeDiscardCountDisplay:Initialize(control, perspective)
    self.control = control
    self.control.object = self
    self.text = self.control:GetNamedChild("Text")
    self.perspective = perspective

    -- ZoFontTributeAntique52 is a rarely used font, so defer loading it until it actually becomes necessary
    self.text:SetFont("ZoFontTributeAntique52")
    self.count = 0

    self.control:RegisterForEvent(EVENT_TRIBUTE_FORCE_DISCARD_COUNT_CHANGED, function(_, perspective, newCount)
        if perspective == self.perspective then
            self:SetCount(newCount)
        end
    end)
end

function ZO_TributeDiscardCountDisplay:UpdateTransform()
    local renderPositionX, renderPositionY, renderPositionZ, rotationXRadians, rotationYRadians, rotationZRadians = GetTributeDiscardCountTransformInfo(self.perspective)
    self.control:SetTransformOffset(renderPositionX, renderPositionY, renderPositionZ)
    self.control:SetTransformRotation(rotationXRadians, rotationYRadians, rotationZRadians)
end

function ZO_TributeDiscardCountDisplay:SetCount(newCount)
    if newCount > 0 then
        self.text:SetText(newCount)
        self.control:SetHidden(false)
    else
        self.control:SetHidden(true)
    end
end

function ZO_TributeDiscardCountDisplay:Reset()
    self:SetCount(0)
    self:HideTooltip()
end

function ZO_TributeDiscardCountDisplay:HideTooltip()
    ClearTooltip(InformationTooltip)
    ZO_TributeDiscardCounterTooltip_Gamepad_Hide()
end

function ZO_TributeDiscardCountDisplay:ShowTooltip()
    self:HideTooltip()
    local offsetX, offsetY = self.control:ProjectRectToScreenAndComputeAABBPoint(LEFT)
    offsetX = offsetX - 30

    if IsInGamepadPreferredMode() then
        ZO_TributeDiscardCounterTooltip_Gamepad_Show(RIGHT, GuiRoot, TOPLEFT, offsetX, offsetY)
    else
        InitializeTooltip(InformationTooltip, GuiRoot, RIGHT, offsetX, offsetY, TOPLEFT)
        InformationTooltip:AddLine(GetString(SI_TRIBUTE_DISCARD_COUNTER_TOOLTIP_TITLE), "", ZO_NORMAL_TEXT:UnpackRGBA())
        InformationTooltip:AddLine(GetString(SI_TRIBUTE_DISCARD_COUNTER_TOOLTIP_DESCRIPTION))
    end
end

function ZO_TributeDiscardCountDisplay:OnCursorEnter()
    self:ShowTooltip()
end

function ZO_TributeDiscardCountDisplay:OnCursorExit()
    self:HideTooltip()
end

function ZO_TributeDiscardCountDisplay:OnMouseEnter()
    if not IsInGamepadPreferredMode() then
        self:ShowTooltip()
    end
end

-----------------------------
-- Global Functions
-----------------------------

function ZO_Tribute_OnInitialized(control)
    TRIBUTE = ZO_Tribute:New(control)
end

function ZO_GetNextTributeCardWithStateFlagMask(stateFlagMask)
    return function(state, lastCardInstanceId)
        return GetNextTributeCardWithStateFlagsMask(stateFlagMask, lastCardInstanceId)
    end
end