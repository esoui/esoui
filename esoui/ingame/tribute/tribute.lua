ZO_TRIBUTE_PLAYER_NAME_PADDING_X = 65
ZO_TRIBUTE_PLAYER_NAME_BACKDROP_MAX_WIDTH = 350
ZO_TRIBUTE_PLAYER_NAME_TEXT_MAX_WIDTH = ZO_TRIBUTE_PLAYER_NAME_BACKDROP_MAX_WIDTH - ZO_TRIBUTE_PLAYER_NAME_PADDING_X
ZO_TRIBUTE_TURN_COUNTDOWN_CSA_THRESHOLD_MS = 5500

local TRIBUTE_INTERACTION =
{
    type = "Tribute",
    interactTypes = { INTERACTION_TRIBUTE },
}

--[[
    TRIBUTE_TUTORIAL_LAYOUT_INFOS entries support the following attributes:
        type            Required    TUTORIAL_TYPE enum
        trigger         Required    TUTORIAL_TRIGGER enum
        fragment        Optional    Fragment reference      Defaults to TRIBUTE_FRAGMENT
        parentControl   Optional    Control reference       Defaults to TRIBUTE.control
        optionalParams  Optional    Table                   Defaults to nil
                                    ^ See ZO_PointerBoxTutorial:SetOptionalPointerBoxParams() for details

    Example:
        local TRIBUTE_TUTORIAL_LAYOUT_INFOS =
        {
            {
                type = TUTORIAL_TYPE_POINTER_BOX,
                trigger = TUTORIAL_TRIGGER_TRIBUTE_AGENT_PLAYED,
            },
            {
                type = TUTORIAL_TYPE_POINTER_BOX,
                trigger = TUTORIAL_TRIGGER_TRIBUTE_CULL_CARD_PLAYED,
            },
        }
]]

local TRIBUTE_TUTORIAL_LAYOUT_INFOS =
{
}

local TRIBUTE_PLAYER_NAME_FONT_INFO =
{
    KEYBOARD_INFO =
    {
        --This should match the first font in the fonts table
        fontObjectForWidthCalculation = ZoFontHeader3,
        fonts =
        {
            {
                font = "ZoFontHeader3",
                lineLimit = 1,
            },
            {
                font = "ZoFontHeader2",
                lineLimit = 1,
            },
            {
                font = "ZoFontHeader",
                lineLimit = 2,
            },
        },
    },
    GAMEPAD_INFO =
    {
        --This should match the first font in the fonts table
        fontObjectForWidthCalculation = ZoFontGamepad42,
        fonts =
        {
            {
                font = "ZoFontGamepad42",
                lineLimit = 1,
            },
            {
                font = "ZoFontGamepad34",
                lineLimit = 1,
            },
            {
                font = "ZoFontGamepad27",
                lineLimit = 2,
            },
        },
    },
}

ZO_Tribute = ZO_InitializingObject:Subclass()

function ZO_Tribute:Initialize(control)
    self.control = control
    
    TRIBUTE_SCENE = ZO_RemoteInteractScene:New("tribute", SCENE_MANAGER, TRIBUTE_INTERACTION)
    TRIBUTE_FRAGMENT = ZO_SimpleSceneFragment:New(control)

    local overlaySceneInfo =
    {
        systemFilters = { UI_SYSTEM_TRIBUTE },
        showOverlayConditionalFunction = function() return self.gameFlowState == TRIBUTE_GAME_FLOW_STATE_PLAYING end,
    }
    HELP_MANAGER:AddOverlayScene("tribute", overlaySceneInfo)

    self.gameFlowState = TRIBUTE_GAME_FLOW_STATE_INACTIVE
    self.showingCountdown = false

    self:InitializeControls()
    self:RegisterForEvents()
end

function ZO_Tribute:InitializeControls()
    local control = self.control

    self.playerInfoContainer = control:GetNamedChild("PlayerInfo")
    self.playerInfoDisplays = {}
    for perspective = TRIBUTE_PLAYER_PERSPECTIVE_ITERATION_BEGIN, TRIBUTE_PLAYER_PERSPECTIVE_ITERATION_END do
        self.playerInfoDisplays[perspective] = self.playerInfoContainer:GetNamedChild("Display" .. perspective)
    end

    self.playerInfoContainerTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_Tribute_HUDFade", self.playerInfoContainer)
end

function ZO_Tribute:RegisterForEvents()
    local control = self.control

    local function OnInterceptCloseAction(...)
        return self:OnInterceptCloseAction(...)
    end

    TRIBUTE_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
            CLOSE_ACTIONS_INTERCEPT_LAYER_FRAGMENT:RegisterCallback("InterceptCloseAction", OnInterceptCloseAction)
            self:RefreshPlayerInfo()
            self:RefreshInputModeFragments()
            --The UI cannot be toggled while a tribute match is ongoing, so make sure it isn't hidden when we start
            if GetGuiHidden("ingame") then
                SetGuiHidden("ingame", false)
            end
        elseif newState == SCENE_FRAGMENT_HIDING then
            CLOSE_ACTIONS_INTERCEPT_LAYER_FRAGMENT:UnregisterCallback("InterceptCloseAction", OnInterceptCloseAction)
        elseif newState == SCENE_FRAGMENT_HIDDEN then
            self.gameFlowState = TRIBUTE_GAME_FLOW_STATE_INACTIVE
        end
    end)

    -- Fixing ESO-771856 required sending the GameCameraActive event earlier than we typically expect it. Whereas we
    -- would normally receive that event when the base scene is being shown, that fix sends it when the Tribute scene
    -- is hiding, which prevents the Scene Manager from exiting UI mode in the same way it does in other comperable
    -- situations. Therfore, to fix ESO-780072, we have to exit UI mode ourselves here. The Scene Manager is supposed
    -- to handle this on its own; it's only because the ESO-771856 fix broke its assumptions that we're doing this.
    -- Don't cite this as an example of standard procedure!
    TRIBUTE_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_HIDDEN then
            if SCENE_MANAGER:IsInUIMode() and SCENE_MANAGER:IsShowingBaseSceneNext() then
                local IS_SHOWING_HUDUI = true
                SCENE_MANAGER:ConsiderExitingUIMode(IS_SHOWING_HUDUI)
            end
        end
    end)

    control:RegisterForEvent(EVENT_TRIBUTE_GAME_FLOW_STATE_CHANGE, function(_, gameFlowState)
        --Clear the turn timer countdown CSA if the game flow state changes
        self.showingCountdown = false
        CENTER_SCREEN_ANNOUNCE:RemoveAllCSAsOfAnnounceType(CENTER_SCREEN_ANNOUNCE_TYPE_COUNTDOWN)

        self.gameFlowState = gameFlowState
        if gameFlowState == TRIBUTE_GAME_FLOW_STATE_INACTIVE then
            if TRIBUTE_SCENE:IsShowing() then
                SCENE_MANAGER:RequestShowLeaderBaseScene(ZO_BHSCR_INTERACT_ENDED)
            end
        else
            self:DeferredInitialize()
            if gameFlowState == TRIBUTE_GAME_FLOW_STATE_INTRO then
                self.playerInfoContainerTimeline:PlayInstantlyToStart()
            elseif gameFlowState == TRIBUTE_GAME_FLOW_STATE_PLAYING then
                self.playerInfoContainerTimeline:PlayForward()
            elseif gameFlowState == TRIBUTE_GAME_FLOW_STATE_GAME_OVER then
                self.playerInfoContainerTimeline:PlayBackward()
            end
            self:RefreshInputModeFragments()
        end
    end)

    control:RegisterForEvent(EVENT_TRIBUTE_EXIT_RESPONSE, function(_, accept)
        self:OnTributeExitResponse(accept)
    end)

    control:RegisterForEvent(EVENT_TRIBUTE_PLAYER_TURN_STARTED, function(_, isLocalPlayer)
        self.showingCountdown = false
        CENTER_SCREEN_ANNOUNCE:RemoveAllCSAsOfAnnounceType(CENTER_SCREEN_ANNOUNCE_TYPE_COUNTDOWN)
    end)

    local function OnUpdate(_, frameTimeSeconds)
        self:OnUpdate(frameTimeSeconds)
    end

    control:SetHandler("OnUpdate", OnUpdate)

    TRIBUTE_SCENE:SetHideSceneConfirmationCallback(function(...) self:OnConfirmHideScene(...) end)
    TRIBUTE_SCENE:SetHandleGamepadPreferredModeChangedCallback(function(...) return self:HandleGamepadPreferredModeChanged(...) end)
end

function ZO_Tribute:DeferredInitialize()
    if not self.initialized then
        self.initialized = true
        self:InitializeTutorials()
    end
end

function ZO_Tribute:InitializeTutorials()
    local anchor = ZO_Anchor:New(LEFT, GuiRoot, TOPLEFT, 0, 0, ANCHOR_CONSTRAINS_XY)
    local DEFAULT_FRAGMENT = TRIBUTE_FRAGMENT
    local DEFAULT_PARENT = self.control

    for _, layoutInfo in ipairs(TRIBUTE_TUTORIAL_LAYOUT_INFOS) do
        local fragment = layoutInfo.fragment or DEFAULT_FRAGMENT
        local parentControl = layoutInfo.parentControl or DEFAULT_PARENT
        TUTORIAL_SYSTEM:RegisterTriggerLayoutInfo(layoutInfo.type, layoutInfo.trigger, parentControl, fragment, anchor, layoutInfo.optionalParams)
    end
end

function ZO_Tribute:RefreshPlayerInfo()
    local longestNameWidth = 0
    local nameFont = IsInGamepadPreferredMode() and TRIBUTE_PLAYER_NAME_FONT_INFO.GAMEPAD_INFO.fontObjectForWidthCalculation or TRIBUTE_PLAYER_NAME_FONT_INFO.KEYBOARD_INFO.fontObjectForWidthCalculation
    for perspective = TRIBUTE_PLAYER_PERSPECTIVE_ITERATION_BEGIN, TRIBUTE_PLAYER_PERSPECTIVE_ITERATION_END do
        local playerInfoDisplay = self.playerInfoDisplays[perspective]
        local name, playerType = GetTributePlayerInfo(perspective)
        name = playerType ~= TRIBUTE_PLAYER_TYPE_NPC and ZO_FormatUserFacingDisplayName(name) or name
        local nameWidth = GetStringWidthScaled(nameFont, name, 1, SPACE_INTERFACE)
        if nameWidth > longestNameWidth then
            longestNameWidth = nameWidth
        end
        playerInfoDisplay.nameLabel:SetText(name)
    end

    --After determining the width of the longest name, go and set all of the controls to that
    for perspective = TRIBUTE_PLAYER_PERSPECTIVE_ITERATION_BEGIN, TRIBUTE_PLAYER_PERSPECTIVE_ITERATION_END do
        local playerInfoDisplay = self.playerInfoDisplays[perspective]
        playerInfoDisplay:SetWidth(longestNameWidth + ZO_TRIBUTE_PLAYER_NAME_PADDING_X)
    end
end

function ZO_Tribute:HandleGamepadPreferredModeChanged(isGamepadPreferred)
    -- We don't want to hide the scene.  The internal version will update the styles
    self:RefreshInputModeFragments()
    self:RefreshPlayerInfo()

    local HANDLED = true
    return HANDLED
end

function ZO_Tribute:OnInterceptCloseAction()
    -- If there's an ingame overlay, don't do anything, because they're going to consume the intercept
    if not (HELP_TUTORIALS_FRAGMENT and HELP_TUTORIALS_FRAGMENT:IsShowing()) then
        -- Otherwise nothing else will consume the intercept, so pass we'll be passing it along to the internal GUI
        self.isInterceptingCloseAction = true
    end
    
    -- The regular OnConfirmHideScene flow will manage the communication between ingame and internalingame,
    -- So we don't want to consider it intercepted yet
    local NOT_HANDLED = false
    return NOT_HANDLED
end

function ZO_Tribute:OnConfirmHideScene(scene, nextSceneName, bypassHideSceneConfirmationReason)
    if bypassHideSceneConfirmationReason == nil and self.gameFlowState ~= TRIBUTE_GAME_FLOW_STATE_GAME_OVER then
        RequestTributeExit(self.isInterceptingCloseAction)
    else
        scene:AcceptHideScene()
    end
    self.isInterceptingCloseAction = nil
end

function ZO_Tribute:OnTributeExitResponse(accept)
    if accept then
        TRIBUTE_SCENE:AcceptHideScene()
    else
        TRIBUTE_SCENE:RejectHideScene()
    end
end

function ZO_Tribute:RefreshInputModeFragments()
    --Remove the action fragments so they can be on top of the gamepad UI mode fragment
    --TODO Tribute: Remove ingame tribute actions, if applicable
    if SPECIAL_TOGGLE_HELP_ACTION_LAYER_FRAGMENT:IsShowing() then
        TRIBUTE_SCENE:RemoveFragment(SPECIAL_TOGGLE_HELP_ACTION_LAYER_FRAGMENT)
    end

    if CLOSE_ACTIONS_INTERCEPT_LAYER_FRAGMENT:IsShowing() then
        TRIBUTE_SCENE:RemoveFragment(CLOSE_ACTIONS_INTERCEPT_LAYER_FRAGMENT)
    end
    
    -- Add input mode appropriate fragments
    if IsInGamepadPreferredMode() then
        TRIBUTE_SCENE:AddFragment(GAMEPAD_UI_MODE_FRAGMENT)
        TRIBUTE_SCENE:AddFragment(HIDE_MOUSE_FRAGMENT)
    else
        TRIBUTE_SCENE:RemoveFragment(GAMEPAD_UI_MODE_FRAGMENT)
        TRIBUTE_SCENE:RemoveFragment(HIDE_MOUSE_FRAGMENT)
    end

    -- Re-add the action fragments so they can be on top of the gamepad UI mode fragment
    --TODO Tribute: Add ingame tribute actions, if applicable
    if self.gameFlowState == TRIBUTE_GAME_FLOW_STATE_PLAYING then
        TRIBUTE_SCENE:AddFragment(SPECIAL_TOGGLE_HELP_ACTION_LAYER_FRAGMENT)
    end

    if self.gameFlowState ~= TRIBUTE_GAME_FLOW_STATE_INACTIVE and self.gameFlowState ~= TRIBUTE_GAME_FLOW_STATE_GAME_OVER then
        TRIBUTE_SCENE:AddFragment(CLOSE_ACTIONS_INTERCEPT_LAYER_FRAGMENT)
    end
end

function ZO_Tribute:OnUpdate(frameTimeSeconds)
    if self.gameFlowState == TRIBUTE_GAME_FLOW_STATE_PLAYING then
        if not self.showingCountdown and GetActiveTributePlayerPerspective() == TRIBUTE_PLAYER_PERSPECTIVE_SELF then
            local timeLeftMs = GetTributeRemainingTimeForTurn()
            if timeLeftMs and timeLeftMs <= ZO_TRIBUTE_TURN_COUNTDOWN_CSA_THRESHOLD_MS then
                self.showingCountdown = true
                local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_COUNTDOWN_TEXT)
                messageParams:SetLifespanMS(timeLeftMs)
                messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_COUNTDOWN)
                CENTER_SCREEN_ANNOUNCE:AddMessageWithParams(messageParams)
            end
        end
    end
end

function ZO_Tribute_OnInitialized(control)
    TRIBUTE = ZO_Tribute:New(control)
end

function ZO_Tribute_PlayerInfoDisplay_OnInitialized(control)
    control.nameLabel = control:GetNamedChild("Name")
    control.background = control:GetNamedChild("Bg")
    control.background:SetColor(ZO_BLACK:UnpackRGB())

    ZO_PlatformStyleFontAdjustingWrapLabel_OnInitialized(control.nameLabel, TRIBUTE_PLAYER_NAME_FONT_INFO.KEYBOARD_INFO.fonts, TRIBUTE_PLAYER_NAME_FONT_INFO.GAMEPAD_INFO.fonts, TEXT_WRAP_MODE_ELLIPSIS)
end