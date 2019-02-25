KEYBIND_STRIP = nil

function ZO_KeybindStrip_HandleKeybindDown(keybind)
    return KEYBIND_STRIP:TryHandlingKeybindDown(keybind)
end

function ZO_KeybindStrip_HandleKeybindUp(keybind)
    return KEYBIND_STRIP:TryHandlingKeybindUp(keybind)
end

ZO_KEYBIND_STRIP_KEYBOARD_VISUAL_HEIGHT = 85
KEYBIND_STRIP_STANDARD_STYLE = {
    nameFont = "ZoFontKeybindStripDescription",
    nameFontColor = ZO_NORMAL_TEXT,
    keyFont = "ZoFontKeybindStripKey",
    modifyTextType = MODIFY_TEXT_TYPE_NONE,
    alwaysPreferGamepadMode = false,
    resizeToFitPadding = 40,
    leftAnchorOffset = 10,
    centerAnchorOffset = 0,
    rightAnchorOffset = -10,
    drawTier = DT_MEDIUM,
    drawLevel = 1,
    backgroundDrawTier = DT_MEDIUM,
    backgroundDrawLevel = 0,
}

--Same as the standard keyboard setup but on a higher tier to show over the champion screen
KEYBIND_STRIP_CHAMPION_KEYBOARD_STYLE = ZO_ShallowTableCopy(KEYBIND_STRIP_STANDARD_STYLE)
KEYBIND_STRIP_CHAMPION_KEYBOARD_STYLE.drawTier = DT_HIGH
KEYBIND_STRIP_CHAMPION_KEYBOARD_STYLE.drawLevel = ZO_HIGH_TIER_GAMEPAD_KEYBIND_STRIP
KEYBIND_STRIP_CHAMPION_KEYBOARD_STYLE.backgroundDrawTier = DT_HIGH
KEYBIND_STRIP_CHAMPION_KEYBOARD_STYLE.backgroundDrawLevel = ZO_HIGH_TIER_GAMEPAD_KEYBIND_STRIP_BG

ZO_KEYBIND_STRIP_GAMEPAD_VISUAL_HEIGHT = 125
KEYBIND_STRIP_GAMEPAD_STYLE = {
    nameFont = "ZoFontGamepad34",
    nameFontColor = ZO_SELECTED_TEXT,
    keyFont = "ZoFontGamepad22",
    modifyTextType = MODIFY_TEXT_TYPE_UPPERCASE,
    alwaysPreferGamepadMode = true,
    resizeToFitPadding = 15,
    leftAnchorOffset = 96,
    centerAnchorOffset = 0,
    rightAnchorOffset = -96,
    yAnchorOffset = -53,
    drawTier = DT_HIGH,
    drawLevel = ZO_HIGH_TIER_GAMEPAD_KEYBIND_STRIP,
    backgroundDrawTier = DT_HIGH,
    backgroundDrawLevel = ZO_HIGH_TIER_GAMEPAD_KEYBIND_STRIP_BG,
}

function ZO_KeybindStrip_OnInitialized(control)

    KEYBIND_STRIP = ZO_KeybindStrip:New(control, "ZO_KeybindStripButtonTemplate", KEYBIND_STRIP_STANDARD_STYLE)

    local defaultExit = {
        name = GetString(SI_EXIT_BUTTON),
        keybind = "UI_SHORTCUT_EXIT",
        order = -10000,
        callback = function()
            SCENE_MANAGER:RequestShowLeaderBaseScene()
        end,
    }

    local defaultGamepadExit = {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        keybind = "UI_SHORTCUT_EXIT",
        order = -10000,
        ethereal = true,
        callback = function()
            SCENE_MANAGER:RequestShowLeaderBaseScene()
        end,
        --Ethereal binds show no text, the name field is used to help identify the keybind when debugging. This text does not have to be localized.
        name = "Default Gamepad Exit",
    }

    function KEYBIND_STRIP:HasDefaultExit(stateIndex)
        local state = self:GetKeybindState(stateIndex)
        if state then
            return state.allowDefaultExit
        else
            return self.allowDefaultExit
        end

    end

    function KEYBIND_STRIP:RemoveDefaultExit(stateIndex)
        local state = self:GetKeybindState(stateIndex)
        if state then
            state.allowDefaultExit = false
        else
            self.allowDefaultExit = false
        end

        self:RefreshDefaultExits(stateIndex)
    end

    function KEYBIND_STRIP:RestoreDefaultExit(stateIndex)
        local state = self:GetKeybindState(stateIndex)
        if state then
            state.allowDefaultExit = true
        else
            self.allowDefaultExit = true
        end

        self:RefreshDefaultExits(stateIndex)
    end

    function KEYBIND_STRIP:RefreshDefaultExits(stateIndex)
        self:RemoveKeybindButton(defaultExit, stateIndex)
        self:RemoveKeybindButton(defaultGamepadExit, stateIndex)
        if self:HasDefaultExit(stateIndex) then
            local styleInfo = self:GetStyle()
            if styleInfo.alwaysPreferGamepadMode then
                self:AddKeybindButton(defaultGamepadExit, stateIndex)
            else
                self:AddKeybindButton(defaultExit, stateIndex)
            end
        end
    end

    --The KEYBIND_STRIP operates with the assumption that when a scene starts to work with the keybind strip, it will have
    --the default exit on it.
    function KEYBIND_STRIP:PushKeybindGroupState()
        local stateIndex = ZO_KeybindStrip.PushKeybindGroupState(self)
        self:RestoreDefaultExit(stateIndex)
        return stateIndex
    end

    function KEYBIND_STRIP:ClearKeybindGroupStateStack(stateIndex)
       ZO_KeybindStrip.ClearKeybindGroupStateStack(self, stateIndex)
       self:RefreshDefaultExits(stateIndex)
    end

    function KEYBIND_STRIP:GenerateGamepadBackButtonDescriptor(callback, keybind, sound)
        keybind = keybind or "UI_SHORTCUT_NEGATIVE"
        return {
            alignment = KEYBIND_STRIP_ALIGN_LEFT,
            name = GetString(SI_GAMEPAD_BACK_OPTION),
            keybind = keybind,
            order = -1000,
            callback = callback,
            sound = sound,
        }
    end

    -- This is meant to be a private method and should not be called directly outside of this class.
    function KEYBIND_STRIP:GenerateGamepadStickButtonDescriptor_Internal(text, visibleFunc, icon, controlName, buttonTemplate, keybindControl)
        if keybindControl == nil then
            keybindControl = CreateControlFromVirtual(controlName, control, buttonTemplate)
            keybindControl:SetCustomKeyIcon(icon)
            keybindControl:SetKeybindEnabledInEdit(true)
            keybindControl:SetMouseOverEnabled(false)

            local styleInfo = ZO_ShallowTableCopy(KEYBIND_STRIP_GAMEPAD_STYLE)
            styleInfo.resizeToFitPadding = 0
            keybindControl:SetupStyle(styleInfo)
            keybindControl:AdjustBindingAnchors(false)
            keybindControl.nameLabel:SetAnchor(RIGHT, keybindControl, RIGHT, 0)

            keybindControl:SetParent(nil)
            keybindControl:SetHidden(true)
        end

        local keybind = {
            customKeybindControl = keybindControl,
            keybind = "",
            name = text,
            gamepadOrder = 1,
        }

        if visibleFunc then
            keybind.visible = visibleFunc
        end

        return keybind, keybindControl
    end

    function KEYBIND_STRIP:GenerateGamepadRightScrollButtonDescriptor(text, visibleFunc)
        local rightScrollIcon = (GetUIPlatform() == UI_PLATFORM_PS4) and "EsoUI/Art/Buttons/Gamepad/PS4/Nav_Ps4_RS_Scroll.dds" or 
                                "EsoUI/Art/Buttons/Gamepad/Xbox/Nav_XBone_RS_Scroll.dds"

        local keybind, keybindControl = self:GenerateGamepadStickButtonDescriptor_Internal(text, visibleFunc, rightScrollIcon, 
                                                "$(parent)RightStickControl", "ZO_KeybindStripRightScrollKeybind", self.rightScrollKeybind)

        if self.rightScrollKeybind == nil then
            self.rightScrollKeybind = keybindControl
        end

        return keybind
    end

    function KEYBIND_STRIP:GenerateGamepadLeftSlideButtonDescriptor(text, visibleFunc) 
        local leftSlideIcon = (GetUIPlatform() == UI_PLATFORM_PS4) and "EsoUI/Art/Buttons/Gamepad/PS4/Nav_Ps4_LS_Slide.dds" or 
                             "EsoUI/Art/Buttons/Gamepad/Xbox/Nav_XBone_LS_Slide.dds"
        
        local keybind, keybindControl = self:GenerateGamepadStickButtonDescriptor_Internal(text, visibleFunc, leftSlideIcon, 
                                                "$(parent)LeftStickSlide","ZO_KeybindStripLeftSlideKeybind", self.leftSlideKeybind)

        if self.leftSlideKeybind == nil then
            self.leftSlideKeybind = keybindControl
        end

        return keybind
    end

    local defaultGamepadBack = KEYBIND_STRIP:GenerateGamepadBackButtonDescriptor(function() SCENE_MANAGER:HideCurrentScene() end)
    function KEYBIND_STRIP:GetDefaultGamepadBackButtonDescriptor()
        return defaultGamepadBack
    end

    KEYBIND_STRIP:SetOnStyleChangedCallback(function()
        KEYBIND_STRIP:RefreshDefaultExits()
    end)

    KEYBIND_STRIP:RestoreDefaultExit()
end
