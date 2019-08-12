DEFAULT_BUTTON_HEIGHT = 28

ZO_TREE_BUTTON_STATE_EXPANDED   = true
ZO_TREE_BUTTON_STATE_COLLAPSED  = false

TOGGLE_BUTTON_OPEN = true
TOGGLE_BUTTON_CLOSED = false

TOGGLE_BUTTON_TYPE_BLADE = 1
TOGGLE_BUTTON_TYPE_TREE = 2
TOGGLE_BUTTON_TYPE_MIN_MAX = 3
TOGGLE_BUTTON_TYPE_LEFT_RIGHT = 4
TOGGLE_BUTTON_TYPE_MINIMAP = 5
TOGGLE_BUTTON_TYPE_PADLOCK = 6
TOGGLE_BUTTON_TYPE_PADLOCK_GAMEPAD = 7

local NORMAL = 1
local OVER = 2
local PRESSED = 3
local DISABLED = 4

local TOGGLE_BUTTON_TEXTURES =
{
    [TOGGLE_BUTTON_TYPE_BLADE] =
    {
        [TOGGLE_BUTTON_OPEN] =
        {
            [NORMAL] = "EsoUI/Art/Buttons/blade_open_up.dds",
            [PRESSED] = "EsoUI/Art/Buttons/blade_open_down.dds",
            [OVER] = "EsoUI/Art/Buttons/blade_mouseOver.dds",
        },
        [TOGGLE_BUTTON_CLOSED] =
        {
            [NORMAL] = "EsoUI/Art/Buttons/blade_closed_up.dds",
            [PRESSED] = "EsoUI/Art/Buttons/blade_closed_down.dds",
            [OVER] = "EsoUI/Art/Buttons/blade_mouseOver.dds",
        }
    },
    [TOGGLE_BUTTON_TYPE_TREE] =
    {
        [TOGGLE_BUTTON_OPEN] =
        {
            [NORMAL] = "EsoUI/Art/Buttons/tree_open_up.dds",
            [OVER] = "EsoUI/Art/Buttons/tree_open_over.dds",
            [PRESSED] = "EsoUI/Art/Buttons/tree_open_down.dds",
            [DISABLED] = "EsoUI/Art/Buttons/tree_open_disabled.dds",
        },
        [TOGGLE_BUTTON_CLOSED] =
        {
            [NORMAL] = "EsoUI/Art/Buttons/tree_closed_up.dds",
            [OVER] = "EsoUI/Art/Buttons/tree_closed_over.dds",
            [PRESSED] = "EsoUI/Art/Buttons/tree_closed_down.dds",
            [DISABLED] = "EsoUI/Art/Buttons/tree_closed_disabled.dds",
        },
    },
    [TOGGLE_BUTTON_TYPE_MIN_MAX] =
    {
        [TOGGLE_BUTTON_OPEN] =
        {
            [NORMAL] = "EsoUI/Art/Buttons/minimize_normal.dds",
            [OVER] = "EsoUI/Art/Buttons/minmax_mouseOver.dds",
            [PRESSED] = "EsoUI/Art/Buttons/minimize_mouseDown.dds",
        },
        [TOGGLE_BUTTON_CLOSED] =
        {
            [NORMAL] = "EsoUI/Art/Buttons/maximize_normal.dds",
            [OVER] = "EsoUI/Art/Buttons/minmax_mouseOver.dds",
            [PRESSED] = "EsoUI/Art/Buttons/maximize_mouseDown.dds",
        },
    },
    [TOGGLE_BUTTON_TYPE_LEFT_RIGHT] =
    {
        [TOGGLE_BUTTON_OPEN] =
        {
            [NORMAL] = "EsoUI/Art/Buttons/right_normal.dds",
            [OVER] = "EsoUI/Art/Buttons/minmax_mouseOver.dds",
            [PRESSED] = "EsoUI/Art/Buttons/right_mouseDown.dds",
        },
        [TOGGLE_BUTTON_CLOSED] =
        {
            [NORMAL] = "EsoUI/Art/Buttons/left_normal.dds",
            [OVER] = "EsoUI/Art/Buttons/minmax_mouseOver.dds",
            [PRESSED] = "EsoUI/Art/Buttons/left_mouseDown.dds",
        },
    },
    [TOGGLE_BUTTON_TYPE_MINIMAP] =
    {
        [TOGGLE_BUTTON_OPEN] =
        {
            [NORMAL] = "EsoUI/Art/Minimap/minimap_minimize_up.dds",
            [OVER] = "EsoUI/Art/Buttons/minmax_mouseOver.dds",
            [PRESSED] = "EsoUI/Art/Minimap/minimap_minimize_down.dds",
        },
        [TOGGLE_BUTTON_CLOSED] =
        {
            [NORMAL] = "EsoUI/Art/Minimap/minimap_maximize_up.dds",
            [OVER] = "EsoUI/Art/Buttons/minmax_mouseOver.dds",
            [PRESSED] = "EsoUI/Art/Minimap/minimap_maximize_down.dds",
        },
    },
    [TOGGLE_BUTTON_TYPE_PADLOCK] =
    {
        [TOGGLE_BUTTON_OPEN] =
        {
            [NORMAL] = "EsoUI/Art/Miscellaneous/unlocked_up.dds",
            [OVER] = "EsoUI/Art/Miscellaneous/unlocked_over.dds",
            [PRESSED] = "EsoUI/Art/Miscellaneous/unlocked_down.dds",
        },
        [TOGGLE_BUTTON_CLOSED] =
        {
            [NORMAL] = "EsoUI/Art/Miscellaneous/locked_up.dds",
            [OVER] = "EsoUI/Art/Miscellaneous/locked_over.dds",
            [PRESSED] = "EsoUI/Art/Miscellaneous/locked_down.dds",
        },
    },
    [TOGGLE_BUTTON_TYPE_PADLOCK_GAMEPAD] =
    {
        [TOGGLE_BUTTON_OPEN] =
        {
            -- Show nothing
        },
        [TOGGLE_BUTTON_CLOSED] =
        {
            [NORMAL] = "EsoUI/Art/Miscellaneous/Gamepad/gp_icon_locked32.dds",
        },
    },
}

local function ZO_ToggleButton_UpdateTextures(toggleButton)
    local type = toggleButton.type
    local textureTable = TOGGLE_BUTTON_TEXTURES[type][toggleButton.state]

    if textureTable[NORMAL]  then
        toggleButton:SetNormalTexture(textureTable[NORMAL])
        toggleButton:SetHidden(false)
    else
        toggleButton:SetHidden(true)
    end
    if textureTable[OVER] then
        toggleButton:SetMouseOverTexture(textureTable[OVER])
    end
    if textureTable[PRESSED] then
        toggleButton:SetPressedTexture(textureTable[PRESSED])
    end
    if textureTable[DISABLED] then
        toggleButton:SetDisabledTexture(textureTable[DISABLED])
    end
end

function ZO_ToggleButton_Initialize(toggleButton, type, initialState)
    if initialState == nil then
        initialState = TOGGLE_BUTTON_OPEN
    end

    toggleButton.type = type
    toggleButton.state = initialState
    ZO_ToggleButton_UpdateTextures(toggleButton)
end

function ZO_ToggleButton_Toggle(toggleButton)
    toggleButton.state = not toggleButton.state
    ZO_ToggleButton_UpdateTextures(toggleButton)
end

function ZO_ToggleButton_SetState(toggleButton, state)
    toggleButton.state = state
    ZO_ToggleButton_UpdateTextures(toggleButton)
end

function ZO_ToggleButton_GetState(toggleButton)
    return toggleButton.state
end

------------------------
-- ZO_CheckButton
------------------------

function ZO_CheckButtonLabel_SetDefaultColors(label, defaultNormalColor, defaultHighlightColor, defaultDisabledColor)
    label.defaultNormalColor = defaultNormalColor
    label.defaultHighlightColor = defaultHighlightColor
    label.defaultDisabledColor = defaultDisabledColor
end

function ZO_CheckButtonLabel_ColorText(label, over)
    local button = label:GetParent()
    if button and ZO_CheckButton_IsEnabled(button) then
        local normalColor = label.defaultNormalColor or ZO_NORMAL_TEXT
        local highlightColor = label.defaultHighlightColor or ZO_HIGHLIGHT_TEXT

        if over then
            label:SetColor(highlightColor:UnpackRGBA())
        else
            label:SetColor(normalColor:UnpackRGBA())
        end
    else
        local disabledColor = label.defaultDisabledColor or ZO_DISABLED_TEXT
        label:SetColor(disabledColor:UnpackRGBA())
    end
end

function ZO_CheckButtonLabel_SetTextColor(button, r, g, b)
    local label = button:GetNamedChild("Label")
    label:SetColor(r, g, b)
end

function ZO_CheckButton_SetLabelText(button, labelText)
    if not button.label then
        local label = CreateControlFromVirtual(button:GetName().."Label", button, "ZO_CheckButtonLabel")
        label:SetAnchor(LEFT, button, RIGHT, 5, 0)

        local function OnMouseEnter()
            if ZO_CheckButton_IsTooltipEnabled(button) and button.tooltipText and button.tooltipText ~= "" then
                local anchorControl = button.tooltipAnchorControl or button
                local anchorDirection = button.tooltipAnchorDirection or LEFT
                ZO_Tooltips_ShowTextTooltip(anchorControl, anchorDirection, button.tooltipText)
            end

            local MOUSED_OVER = true
            ZO_CheckButtonLabel_ColorText(label, MOUSED_OVER)
            button:SetShowingHighlight(MOUSED_OVER)
        end

        local function OnMouseExit()
            ZO_Tooltips_HideTextTooltip()

            local NOT_MOUSED_OVER = false
            ZO_CheckButtonLabel_ColorText(label, NOT_MOUSED_OVER)
            button:SetShowingHighlight(NOT_MOUSED_OVER)
        end

        ZO_PreHookHandler(button, "OnMouseEnter", OnMouseEnter)
        ZO_PreHookHandler(button, "OnMouseExit", OnMouseExit)
        ZO_PreHookHandler(label, "OnMouseEnter", function() button:GetHandler("OnMouseEnter")(button) end)
        ZO_PreHookHandler(label, "OnMouseExit", function() button:GetHandler("OnMouseExit")(button) end)

        button.label = label
    end

    if button.label then
        button.label:SetText(labelText)
    end
end

function ZO_CheckButton_SetLabelWrapMode(button, wrapMode, labelWidth)
    if button.label then
        button.label:SetHeight(button.label:GetFontHeight())
        button.label:SetWidth(labelWidth)
        button.label:SetWrapMode(wrapMode)
    end
end

function ZO_CheckButton_SetLabelWidth(button, labelWidth)
    if button.label then
        button.label:SetWidth(labelWidth)
    end
end

function ZO_CheckButton_OnClicked(buttonControl)
    if ZO_CheckButton_IsEnabled(buttonControl) then
        PlaySound(SOUNDS.DEFAULT_CLICK)

        local bState = buttonControl:GetState()
        local callToggleFunc = true
        local checked = true

        if bState == BSTATE_NORMAL then
            ZO_CheckButton_SetChecked(buttonControl)
        elseif bState == BSTATE_PRESSED then
            ZO_CheckButton_SetUnchecked(buttonControl)
            checked = false
        else
            callToggleFunc = false
        end

        if (buttonControl.toggleFunction ~= nil) and callToggleFunc then
            buttonControl:toggleFunction(checked)
        end
    end
end

function ZO_CheckButton_IsEnabled(buttonControl)
    local currentState = buttonControl:GetState()
    return currentState ~= BSTATE_DISABLED and currentState ~= BSTATE_DISABLED_PRESSED
end

function ZO_CheckButton_IsTooltipEnabled(buttonControl)
    return buttonControl.tooltipEnabled == nil or buttonControl.tooltipEnabled
end

function ZO_CheckButton_SetEnableState(buttonControl, enabled)
    if enabled then
        ZO_CheckButton_Enable(buttonControl)
    else
        ZO_CheckButton_Disable(buttonControl)
    end
end

function ZO_CheckButton_Disable(buttonControl)
    local currentState = buttonControl:GetState()
    if currentState == BSTATE_PRESSED then
        buttonControl:SetState(BSTATE_DISABLED_PRESSED, true)
    elseif currentState == BSTATE_NORMAL then
        buttonControl:SetState(BSTATE_DISABLED, true)
    end

    local tooltipEnabled = ZO_CheckButton_IsTooltipEnabled(buttonControl)

    buttonControl:SetMouseEnabled(tooltipEnabled)

    if buttonControl.label then
        buttonControl.label:SetMouseEnabled(tooltipEnabled)
        buttonControl.label:SetColor(ZO_DISABLED_TEXT:UnpackRGBA())
    end
end

function ZO_CheckButton_Enable(buttonControl)
    local currentState = buttonControl:GetState()
    if currentState == BSTATE_DISABLED_PRESSED then
        ZO_CheckButton_SetChecked(buttonControl)
    elseif currentState == BSTATE_DISABLED then
        ZO_CheckButton_SetUnchecked(buttonControl)
    end

    buttonControl:SetMouseEnabled(true)

    if buttonControl.label then
        buttonControl.label:SetMouseEnabled(true)
        ZO_CheckButtonLabel_ColorText(buttonControl.label, MouseIsOver(buttonControl.label))
    end
end

function ZO_CheckButton_SetTooltipEnabledState(buttonControl, enabled)
    buttonControl.tooltipEnabled = enabled
end

function ZO_CheckButton_SetTooltipAnchor(buttonControl, anchorDirection, anchorControl)
    buttonControl.tooltipAnchorControl = anchorControl
    buttonControl.tooltipAnchorDirection = anchorDirection
end

function ZO_CheckButton_SetTooltipText(buttonControl, text)
    if type(text) == "function" then
        text = text()
    end

    buttonControl.tooltipText = text
end

function ZO_CheckButton_SetChecked(buttonControl)
    buttonControl:SetState(BSTATE_PRESSED, true)
    if buttonControl.checkedText then
        buttonControl:SetText(buttonControl.checkedText)
    end
end

function ZO_CheckButton_SetUnchecked(buttonControl)
    buttonControl:SetState(BSTATE_NORMAL, false)
    if buttonControl.uncheckedText then
        buttonControl:SetText(buttonControl.uncheckedText)
    end
end

function ZO_CheckButton_IsChecked(buttonControl)
    local currentState = buttonControl:GetState()
    return currentState == BSTATE_PRESSED or currentState == BSTATE_DISABLED_PRESSED
end

function ZO_CheckButton_SetCheckState(buttonControl, checkState)
    local checkStateType = type(checkState)
    local isChecked = false
    
    if checkStateType == "boolean" then
        isChecked = checkState
    elseif checkStateType == "string" then
        isChecked = (checkState == "true") or (checkState == "t") or (checkState == "1") or (checkState == "y")
    elseif checkStateType == "number" then
        isChecked = checkState > 0
    end

    if isChecked then
        ZO_CheckButton_SetChecked(buttonControl)
    else
        ZO_CheckButton_SetUnchecked(buttonControl)
    end
end

function ZO_CheckButton_SetToggleFunction(checkButtonControl, toggleFunction)
    checkButtonControl.toggleFunction = toggleFunction
end

TRISTATE_CHECK_BUTTON_CHECKED = 1
TRISTATE_CHECK_BUTTON_UNCHECKED = 2
TRISTATE_CHECK_BUTTON_INDETERMINATE = 3

function ZO_TriStateCheckButton_SetState(buttonControl, checkState, callStateChangeFunction)
    if checkState == TRISTATE_CHECK_BUTTON_CHECKED then
        buttonControl:SetPressedTexture("EsoUI/Art/Buttons/checkbox_checked.dds")
        ZO_CheckButton_SetChecked(buttonControl)
    elseif checkState == TRISTATE_CHECK_BUTTON_UNCHECKED then
        ZO_CheckButton_SetUnchecked(buttonControl)
    elseif checkState == TRISTATE_CHECK_BUTTON_INDETERMINATE then
        buttonControl:SetPressedTexture("EsoUI/Art/Buttons/checkbox_indeterminate.dds")
        ZO_CheckButton_SetChecked(buttonControl)
    end

    buttonControl.checkState = checkState

    if callStateChangeFunction and type(buttonControl.stateChangeFunction) == "function" then
        buttonControl.stateChangeFunction(buttonControl, checkState)
    end
end

function ZO_TriStateCheckButton_GetState(buttonControl)
    return buttonControl.checkState
end

local CALL_STATE_CHANGE_FUNCTION = true

function ZO_TriStateCheckButton_OnClicked(buttonControl, mouseButton)
    local checkState = buttonControl.checkState

    if checkState == TRISTATE_CHECK_BUTTON_CHECKED then
        ZO_TriStateCheckButton_SetState(buttonControl, TRISTATE_CHECK_BUTTON_UNCHECKED, CALL_STATE_CHANGE_FUNCTION)
    elseif checkState == TRISTATE_CHECK_BUTTON_UNCHECKED then
        ZO_TriStateCheckButton_SetState(buttonControl, TRISTATE_CHECK_BUTTON_CHECKED, CALL_STATE_CHANGE_FUNCTION)
    elseif checkState == TRISTATE_CHECK_BUTTON_INDETERMINATE then
        ZO_TriStateCheckButton_SetState(buttonControl, TRISTATE_CHECK_BUTTON_CHECKED, CALL_STATE_CHANGE_FUNCTION)
    end
end

function ZO_TriStateCheckButton_SetStateChangeFunction(buttonControl, stateChangeFunction)
    buttonControl.stateChangeFunction = stateChangeFunction
end

function ZO_MenuDropDownTextButton_SetSelectedState(buttonControl, selected)
    if selected then
        if buttonControl.selectedFont then
            buttonControl:SetFont(buttonControl.selectedFont)
        end
        buttonControl:SetNormalFontColor(ZO_SELECTED_TEXT:UnpackRGBA())
    else
        if buttonControl.unselectedFont then
            buttonControl:SetFont(buttonControl.unselectedFont)
        end
        buttonControl:SetNormalFontColor(ZO_NORMAL_TEXT:UnpackRGBA())
    end
end

local function UpdateWeaponSwapButton(self)
    if self.unearned or self.externallyLocked then
        self.lockIcon:SetHidden(false)
        self:SetText("")
        self:SetEnabled(false)
    elseif self.activeWeaponPair > ACTIVE_WEAPON_PAIR_NONE then
        self.lockIcon:SetHidden(true)
        self:SetText(zo_strformat(SI_ACTIVE_WEAPON_PAIR, self.activeWeaponPair))
        self:SetEnabled(not self.disabled)
    end

    if self.hideWhenUnearned then
        self:SetHidden(self.unearned or self.permanentlyHidden)
    else
        self:SetHidden(self.permanentlyHidden)
    end
end

function ZO_WeaponSwap_OnInitialized(self, hideWhenUnearned)
    self.hideWhenUnearned = hideWhenUnearned
    
    local function OnUnitCreated(_, unitTag)
        if(unitTag == "player") then
            self.unearned = GetUnitLevel("player") < GetWeaponSwapUnlockedLevel()
            UpdateWeaponSwapButton(self)
        end
    end
    self:RegisterForEvent(EVENT_UNIT_CREATED, OnUnitCreated)

    local function OnActiveWeaponPairChanged(event, activeWeaponPair, disabled)
        self.activeWeaponPair = activeWeaponPair
        self.disabled = disabled
        UpdateWeaponSwapButton(self)
    end

    local function OnWeaponPairLockChanged(event, disabled)
        self.disabled = disabled
        UpdateWeaponSwapButton(self)
    end

    self:RegisterForEvent(EVENT_ACTIVE_WEAPON_PAIR_CHANGED, OnActiveWeaponPairChanged)
    self:RegisterForEvent(EVENT_WEAPON_PAIR_LOCK_CHANGED, OnWeaponPairLockChanged)

    local function OnLevelUpdate(_, unitTag, level)
        if(unitTag == "player") then
            self.unearned = level < GetWeaponSwapUnlockedLevel()
            UpdateWeaponSwapButton(self)
        end
    end
    self:RegisterForEvent(EVENT_LEVEL_UPDATE, OnLevelUpdate)

    local function OnPlayerActivated()
        self.unearned = GetUnitLevel("player") < GetWeaponSwapUnlockedLevel()
        self.activeWeaponPair, self.disabled = GetActiveWeaponPairInfo()
        UpdateWeaponSwapButton(self)
    end
    self:RegisterForEvent(EVENT_PLAYER_ACTIVATED, OnPlayerActivated)

    self.lockIcon = GetControl(self, "Lock")

    --Initialize these here since platform style depends on it
    self.unearned = GetUnitLevel("player") < GetWeaponSwapUnlockedLevel()
    self.activeWeaponPair, self.disabled = GetActiveWeaponPairInfo()
end

function ZO_WeaponSwap_OnMouseEnter(self, anchorPoint, xOffset, yOffset)
    anchorPoint = anchorPoint or LEFT
    xOffset = xOffset or 5
    yOffset = yOffset or 0

    InitializeTooltip(InformationTooltip, self, anchorPoint, xOffset, yOffset)

    if not self.externallyLocked and self.unearned then
        local unlockLevel = GetWeaponSwapUnlockedLevel()
        InformationTooltip:AddLine(GetString(SI_WEAPON_SWAP_TOOLTIP), "", ZO_TOOLTIP_DEFAULT_COLOR:UnpackRGB())
        InformationTooltip:AddLine(zo_strformat(SI_WEAPON_SWAP_UNEARNED_TOOLTIP, unlockLevel), "", ZO_ERROR_COLOR:UnpackRGB())
    elseif self.externallyLocked or self.disabled then
        InformationTooltip:AddLine(GetString(SI_WEAPON_SWAP_TOOLTIP), "", ZO_TOOLTIP_DEFAULT_COLOR:UnpackRGB())
        InformationTooltip:AddLine(GetString(SI_WEAPON_SWAP_DISABLED_TOOLTIP), "", ZO_ERROR_COLOR:UnpackRGB())
    else
        SetTooltipText(InformationTooltip, GetString(SI_WEAPON_SWAP_TOOLTIP))
    end
end

function ZO_WeaponSwap_OnMouseExit(self)
    ClearTooltip(InformationTooltip)
end

function ZO_WeaponSwap_SetExternallyLocked(self, locked)
    if self.externallyLocked ~= locked then
        self.externallyLocked = locked
        UpdateWeaponSwapButton(self)
        if InformationTooltip:GetOwner() == self then
            zo_callHandler(self, "OnMouseEnter")
        end
    end
end

function ZO_WeaponSwap_SetPermanentlyHidden(self, hidden)
    if self.permanentlyHidden ~= hidden then
        self.permanentlyHidden = hidden
        UpdateWeaponSwapButton(self)
    end
end
