local ACCEPT = true
local REJECT = false

local ANTIQUITY_DIGGING_FANFARE_LONG_DELAY_MS = 2000
local ANTIQUITY_DIGGING_FANFARE_SHORT_DELAY_MS = 500

ZO_Dialogs_RegisterCustomDialog("CONFIRM_STOP_ANTIQUITY_DIGGING",
{
    mustChoose = true,
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_ANTIQUITY_DIGGING_CONFIRM_EXIT_DIALOG_TITLE
    },
    mainText =
    {
        text = function()
            if IsDiggingAntiquityUnearthed() then
                return GetString(SI_ANTIQUITY_DIGGING_CONFIRM_EXIT_DIALOG_VICTORY_DESCRIPTION)
            else
                return GetString(SI_ANTIQUITY_DIGGING_CONFIRM_EXIT_DIALOG_ABORT_DESCRIPTION)
            end
        end
    },
    setup = function()
        ANTIQUITY_DIGGING:RefreshInputState()
    end,
    finishedCallback = function()
        ANTIQUITY_DIGGING:RefreshInputState()
    end,
    buttons =
    {
        {
            text = SI_DIALOG_ACCEPT,
            callback = function()
                if IsDiggingAntiquityUnearthed() then
                    AntiquityDiggingExitResponse(REJECT)
                    FinishAntiquityDiggingEarly()
                else
                    AntiquityDiggingExitResponse(ACCEPT)
                end
            end
        },
        {
            text = SI_DIALOG_DECLINE,
            callback = function()
                AntiquityDiggingExitResponse(REJECT)
            end
        },
    }
})

----------------------
-- Antiquity Digging --
----------------------

local KEYBOARD_STYLE =
{
    keybindLabelFont = "ZoFontWinH2",
}

local GAMEPAD_STYLE =
{
    keybindLabelFont = "ZoFontGamepad22",
}

ZO_AntiquityDigging = ZO_Object:Subclass()

function ZO_AntiquityDigging:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_AntiquityDigging:Initialize(control)
    self.control = control
    self.keybindContainer = control:GetNamedChild("KeybindContainer")

    self.keybindContainerTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_AntiquityDiggingHUDFade", self.keybindContainer)
    self.keybindContainerFastTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_AntiquityDiggingHUDFastFade", self.keybindContainer)

    self.keybindLabels = {} -- will be populated on EVENT_KEYBINDINGS_LOADED

    self.areGamepadControlsEnabled = false

    ANTIQUITY_DIGGING_FRAGMENT = ZO_FadeSceneFragment:New(control)

    -- (ESO-670681) When a remote scene is about to change via ZO_SceneManager_Follower:OnLeaderToFollowerSync, the next scene is established before the current scene is hidden
    -- When the next scene is set, the fragments are refreshed and, since there is a next scene, the fragments hide.  Because of this order of operations, 
    -- the fragment can be hiding while the scene is still considered "showing."  Therefore, we can rely on the state of the scene or the state of the fragment, but not both in unison.
    ANTIQUITY_DIGGING_SCENE = ZO_RemoteScene:New("antiquityDigging", SCENE_MANAGER)
    ANTIQUITY_DIGGING_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            self.isReadyToPlay = false
            self.selectedRow = nil
            self.selectedColumn = nil
            control:RegisterForEvent(EVENT_ANTIQUITY_DIGGING_READY_TO_PLAY, function() self:OnAntiquityDiggingReadyToPlay() end)
            self:RefreshActiveToolKeybinds()
        elseif newState == SCENE_HIDING then
            control:UnregisterForEvent(EVENT_ANTIQUITY_DIGGING_READY_TO_PLAY)
            control:SetHandler("OnUpdate", nil)
            --clear the current tutorial when hiding so we don't push an extra action layer
            self:RefreshInputState()
            ZO_Dialogs_ReleaseAllDialogsOfName("CONFIRM_STOP_ANTIQUITY_DIGGING")
        elseif newState == SCENE_HIDDEN then
            self.keybindContainerTimeline:PlayInstantlyToStart()
            if self.beginEndOfGameFanfareEventId  then
                EVENT_MANAGER:UnregisterForUpdate(self.beginEndOfGameFanfareEventId)
                self.beginEndOfGameFanfareEventId = nil
            end
        end
    end)

    ANTIQUITY_DIGGING_SUMMARY_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        -- When the end of game summary fragment comes in, we want to get rid of the keybinds
        -- and tone down the bars so they don't feel like they're part of the summary but can still be referenced
        if ANTIQUITY_DIGGING_SCENE:IsShowing() then
            if newState == SCENE_FRAGMENT_SHOWING then
                self.keybindContainerFastTimeline:PlayFromEnd()
            elseif newState == SCENE_FRAGMENT_HIDDEN then
                -- This is only here in cases where we hide the fragment while the game is still going (i.e. debug)
                self.keybindContainerFastTimeline:PlayFromStart()
            end
        end
    end)

    control:RegisterForEvent(EVENT_START_ANTIQUITY_DIGGING, function()
        SCENE_MANAGER:Show("antiquityDigging")
    end)

    control:RegisterForEvent(EVENT_KEYBINDINGS_LOADED, function()
        self:BuildKeybindLabels()
        control:UnregisterForEvent(EVENT_KEYBINDINGS_LOADED)
    end)

    control:RegisterForEvent(EVENT_ANTIQUITY_DIGGING_ACTIVE_SKILL_CHANGED, function()
        self:RefreshKeybindAlpha()
    end)

    control:RegisterForEvent(EVENT_REQUEST_ANTIQUITY_DIGGING_EXIT, function()
        if ANTIQUITY_DIGGING_SUMMARY_FRAGMENT:IsHidden() then
            ZO_Dialogs_ShowPlatformDialog("CONFIRM_STOP_ANTIQUITY_DIGGING")
        end
    end)

    control:RegisterForEvent(EVENT_ANTIQUITY_DIGGING_GAME_OVER, function(eventId, gameOverFlags)
        local fanfareDelayMs = PlayerLeftDiggingEarly() and ANTIQUITY_DIGGING_FANFARE_SHORT_DELAY_MS or ANTIQUITY_DIGGING_FANFARE_LONG_DELAY_MS
        self.beginEndOfGameFanfareEventId = zo_callLater(function()
            self.beginEndOfGameFanfareEventId = nil
            ANTIQUITY_DIGGING_SUMMARY:BeginEndOfGameFanfare(gameOverFlags)
        end, fanfareDelayMs)
    end)

    control:RegisterForEvent(EVENT_ANTIQUITY_DIGGING_ANTIQUITY_UNEARTHED, function()
        TUTORIAL_MANAGER:ShowTutorial(TUTORIAL_TRIGGER_ANTIQUITY_DIGGING_ANTIQUITY_UNEARTHED)
    end)

    control:RegisterForEvent(EVENT_ANTIQUITY_DIGGING_BONUS_LOOT_UNEARTHED, function()
        TUTORIAL_MANAGER:ShowTutorial(TUTORIAL_TRIGGER_ANTIQUITY_DIGGING_BONUS_LOOT_UNEARTHED)
    end)

    control:RegisterForEvent(EVENT_ANTIQUITY_DIG_SPOT_DURABILITY_CHANGED, function(_, newDurability)
        TUTORIAL_MANAGER:ShowTutorial(TUTORIAL_TRIGGER_ANTIQUITY_DIGGING_ANTIQUITY_DAMAGED)
        if newDurability == 0 then
            TUTORIAL_MANAGER:ShowTutorial(TUTORIAL_TRIGGER_ANTIQUITY_DIGGING_ANTIQUITY_DESTROYED)
        end
    end)

    local function RefreshInputState()
        self:RefreshInputState()
    end

    ZO_HELP_OVERLAY_SYNC_OBJECT:SetHandler("OnShown", RefreshInputState, "antiquityDigging")
    ZO_HELP_OVERLAY_SYNC_OBJECT:SetHandler("OnHidden", RefreshInputState, "antiquityDigging")

    ZO_DIALOG_SYNC_OBJECT:SetHandler("OnShown", RefreshInputState, "antiquityDigging")
    ZO_DIALOG_SYNC_OBJECT:SetHandler("OnHidden", RefreshInputState, "antiquityDigging")
    
    control:RegisterForEvent(EVENT_GAMEPAD_PREFERRED_MODE_CHANGED, RefreshInputState)

    self.platformStyle = ZO_PlatformStyle:New(function(style) self:ApplyPlatformStyle(style) end, KEYBOARD_STYLE, GAMEPAD_STYLE)
end

function ZO_AntiquityDigging:ApplyPlatformStyle(style)
    for _, keybindLabel in pairs(self.keybindLabels) do
        keybindLabel:SetFont(style.keybindLabelFont)
    end
end

function ZO_AntiquityDigging:SetKeyboardControlsEnabled(enabled)
    if enabled then
        self.control:SetHandler("OnMouseDown", function(...) self:OnMouseDown(...) end)
    else
        self.control:SetHandler("OnMouseDown", nil)
    end
end

function ZO_AntiquityDigging:SetGamepadControlsEnabled(enabled)
    if self.areGamepadControlsEnabled == enabled then
        return
    end
    self.areGamepadControlsEnabled = enabled

    if enabled then
        if not self.horizontalMovementController then
            local function GetStickMagnitude(direction)
                --When using a movement controller on the slightest input in a direction it will move in that direction and then start accumulating to do the following move. This is important for responsiveness.
                --However it means that it's super touchy when using both X and Y. Pressing the stick at 89 degress will cause a movement to the right. So we apply these thresholds to get rid of those weird moves.
                if direction == MOVEMENT_CONTROLLER_DIRECTION_VERTICAL then
                    return zo_abs(self.gamepadY) > 0.4 and self.gamepadY or 0
                end
                return zo_abs(self.gamepadX) > 0.4 and -self.gamepadX or 0
            end
            self.horizontalMovementController = ZO_MovementController:New(MOVEMENT_CONTROLLER_DIRECTION_HORIZONTAL, 8, GetStickMagnitude)
            self.verticalMovementController = ZO_MovementController:New(MOVEMENT_CONTROLLER_DIRECTION_VERTICAL, 8, GetStickMagnitude)
        end
        self.numRows, self.numColumns = GetDigSpotDimensions()
        if not self.selectedRow then
            self.selectedRow = zo_floor(self.numRows * 0.5)
            self.selectedColumn = zo_floor(self.numColumns * 0.5)
        end
        DIRECTIONAL_INPUT:Activate(self, self.control)
    else
        DIRECTIONAL_INPUT:Deactivate(self)
    end
end

function ZO_AntiquityDigging:OnMouseDown(control, button)
    if button == MOUSE_BUTTON_INDEX_LEFT then
        local mouseOverSkill = GetMouseOverDiggingActiveSkill()
        if mouseOverSkill then
            SetSelectedDiggingActiveSkill(mouseOverSkill)
        else
            local selectedSkill = GetSelectedDiggingActiveSkill()
            local selectedRow, selectedColumn = GetSelectedDigCell()
            if selectedSkill and selectedRow and selectedColumn then
                UseDiggingActiveSkillOnSelectedCell(selectedSkill)
            else
                PlayDiggingMouseClickEffect()
            end
        end
    end
end

function ZO_AntiquityDigging:OnAntiquityDiggingReadyToPlay()
    self.keybindContainerTimeline:PlayForward()

    self:TryTriggerInitialTutorials()

    self.isReadyToPlay = true

    self:RefreshInputState()

    self.control:SetHandler("OnUpdate", function()
        self:OnUpdate()
    end)
end

function ZO_AntiquityDigging:IsReadyToPlay()
    return ANTIQUITY_DIGGING_SCENE:IsShowing() and self.isReadyToPlay
end

function ZO_AntiquityDigging:OnUpdate()
    self:RefreshKeybindAnchors()
    if not IsInGamepadPreferredMode() then
        SetSelectedDigCell(GetMouseOverDigCell())
        SetHighlightedDiggingActiveSkill(GetMouseOverDiggingActiveSkill())
    end
end

function ZO_AntiquityDigging:CreateKeybindLabel(skill, bindingName)
    local label = CreateControlFromVirtual("$(parent)", self.keybindContainer, "ZO_AntiquityDiggingKeybindLabel", skill)
    ZO_Keybindings_RegisterLabelForBindingUpdate(label, bindingName)
    self.keybindLabels[skill] = label
end

function ZO_AntiquityDigging:BuildKeybindLabels()
    self:CreateKeybindLabel(DIGGING_ACTIVE_SKILL_BASIC_EXCAVATION, "ANTIQUITY_DIGGING_SELECT_BASIC_EXCAVATION")
    self:CreateKeybindLabel(DIGGING_ACTIVE_SKILL_RADAR_SENSE, "ANTIQUITY_DIGGING_SELECT_RADAR_SENSE")
    self:CreateKeybindLabel(DIGGING_ACTIVE_SKILL_HEAVY_SHOVEL, "ANTIQUITY_DIGGING_SELECT_HEAVY_SHOVEL")
    self:CreateKeybindLabel(DIGGING_ACTIVE_SKILL_CAREFUL_TOUCH, "ANTIQUITY_DIGGING_SELECT_CAREFUL_TOUCH")
    self.platformStyle:Apply()
end

function ZO_AntiquityDigging:RefreshKeybindAnchors()
    for skill = DIGGING_ACTIVE_SKILL_ITERATION_BEGIN, DIGGING_ACTIVE_SKILL_ITERATION_END do
        local x, y = GetDigToolUIKeybindPosition(skill)
        local label = self.keybindLabels[skill]
        label:ClearAnchors()
        label:SetAnchor(TOP, GuiRoot, TOPLEFT, x, y)
    end
end

function ZO_AntiquityDigging:RefreshKeybindAlpha()
    local activeSkill = GetSelectedDiggingActiveSkill()
    for skill = DIGGING_ACTIVE_SKILL_ITERATION_BEGIN, DIGGING_ACTIVE_SKILL_ITERATION_END do
        local label = self.keybindLabels[skill]
        if skill == activeSkill then
            label:SetAlpha(1)
        else
            label:SetAlpha(0.3)
        end
    end
end

function ZO_AntiquityDigging:RefreshActiveToolKeybinds()
    for skill = DIGGING_ACTIVE_SKILL_ITERATION_BEGIN, DIGGING_ACTIVE_SKILL_ITERATION_END do
        local label = self.keybindLabels[skill]
        label:SetHidden(not IsDiggingActiveSkillUnlocked(skill))
    end
end

function ZO_AntiquityDigging:RefreshInputState()
    local allowPlayerInput = self:IsReadyToPlay() and not ZO_HELP_OVERLAY_SYNC_OBJECT:IsShown() and not ZO_DIALOG_SYNC_OBJECT:IsShown()
    if self.isPlayerInputEnabled ~= allowPlayerInput then
        if allowPlayerInput then
            PushActionLayerByName("AntiquityDiggingActions")
            self.isPlayerInputEnabled = true
        else
            RemoveActionLayerByName("AntiquityDiggingActions")
            self.isPlayerInputEnabled = false
        end
    end

    local isGamepad = IsInGamepadPreferredMode()
    local keyboardEnabled = allowPlayerInput and not isGamepad
    local gamepadEnabled = allowPlayerInput and isGamepad
    self:SetKeyboardControlsEnabled(keyboardEnabled)
    self:SetGamepadControlsEnabled(gamepadEnabled)
end

do
    local TOOL_TUTORIALS =
    {
        [DIGGING_ACTIVE_SKILL_CAREFUL_TOUCH] = TUTORIAL_TRIGGER_ANTIQUITY_DIGGING_CAREFUL_TOUCH_UNLOCKED,
        [DIGGING_ACTIVE_SKILL_BASIC_EXCAVATION] = TUTORIAL_TRIGGER_ANTIQUITY_DIGGING_BASIC_EXCAVATION_UNLOCKED,
        [DIGGING_ACTIVE_SKILL_RADAR_SENSE] = TUTORIAL_TRIGGER_ANTIQUITY_DIGGING_RADAR_SENSE_UNLOCKED,
        [DIGGING_ACTIVE_SKILL_HEAVY_SHOVEL] = TUTORIAL_TRIGGER_ANTIQUITY_DIGGING_HEAVY_SHOVEL_UNLOCKED,
    }

    local UPGRADED_TOOL_TUTORIALS =
    {
        [DIGGING_ACTIVE_SKILL_CAREFUL_TOUCH] = TUTORIAL_TRIGGER_ANTIQUITY_DIGGING_CAREFUL_TOUCH_UPGRADED,
        [DIGGING_ACTIVE_SKILL_BASIC_EXCAVATION] = TUTORIAL_TRIGGER_ANTIQUITY_DIGGING_BASIC_EXCAVATION_UPGRADED,
        [DIGGING_ACTIVE_SKILL_RADAR_SENSE] = TUTORIAL_TRIGGER_ANTIQUITY_DIGGING_RADAR_SENSE_UPGRADED,
        [DIGGING_ACTIVE_SKILL_HEAVY_SHOVEL] = TUTORIAL_TRIGGER_ANTIQUITY_DIGGING_HEAVY_SHOVEL_UPGRADED,
    }

    function ZO_AntiquityDigging:TryTriggerInitialTutorials()
        TUTORIAL_MANAGER:ShowTutorial(TUTORIAL_TRIGGER_ANTIQUITY_DIGGING_OPENED)
        for skill = DIGGING_ACTIVE_SKILL_ITERATION_BEGIN, DIGGING_ACTIVE_SKILL_ITERATION_END do
            if IsDiggingActiveSkillUnlocked(skill) then
                TUTORIAL_MANAGER:ShowTutorial(TOOL_TUTORIALS[skill])
                if IsDiggingActiveSkillUpgraded(skill) then
                    TUTORIAL_MANAGER:ShowTutorial(UPGRADED_TOOL_TUTORIALS[skill])
                end
            end
        end
        if DidDigSpotSpawnWithFissures() then
            TUTORIAL_MANAGER:ShowTutorial(TUTORIAL_TRIGGER_ANTIQUITY_DIGGING_FISSURE_SPAWNED)
        end
    end
end

-- Begin Gamepad Actions --

function ZO_AntiquityDigging:UpdateDirectionalInput()
    self.gamepadX, self.gamepadY = DIRECTIONAL_INPUT:GetXY(ZO_DI_LEFT_STICK, ZO_DI_DPAD)
    local moveX = self.horizontalMovementController:CheckMovement()
    local moveY = self.verticalMovementController:CheckMovement()
    local deltaX = moveX == MOVEMENT_CONTROLLER_MOVE_PREVIOUS and -1 or moveX == MOVEMENT_CONTROLLER_MOVE_NEXT and 1 or 0
    local deltaY = moveY == MOVEMENT_CONTROLLER_MOVE_PREVIOUS and -1 or moveY == MOVEMENT_CONTROLLER_MOVE_NEXT and 1 or 0
    self.selectedColumn = zo_clamp(self.selectedColumn + deltaX, 1, self.numColumns)
    self.selectedRow = zo_clamp(self.selectedRow + deltaY, 1, self.numRows)
    SetSelectedDigCell(self.selectedRow, self.selectedColumn)
end

function ZO_AntiquityDigging:UsePrimaryAction()
    if ANTIQUITY_DIGGING_SUMMARY_FRAGMENT:IsHidden() then
        UseDiggingActiveSkillOnSelectedCell(GetSelectedDiggingActiveSkill())
    else
        ANTIQUITY_DIGGING_SUMMARY:OnUsePrimaryAction()
    end
end

function ZO_AntiquityDigging:UseCodex()
    if not ANTIQUITY_DIGGING_SUMMARY_FRAGMENT:IsHidden() then
        ANTIQUITY_DIGGING_SUMMARY:OnUseCodex()
    end
end

function ZO_AntiquityDigging:SelectTool(activeSkill)
    SetSelectedDiggingActiveSkill(activeSkill)
    OnSelectedDigToolChanged()
end

function ZO_AntiquityDigging:TryCancel()
    SCENE_MANAGER:Hide("antiquityDigging")
end

-- End Gamepad Actions --

-- Global / XML --

function ZO_AntiquityDigging_OnInitialized(control)
    ANTIQUITY_DIGGING = ZO_AntiquityDigging:New(control)
end