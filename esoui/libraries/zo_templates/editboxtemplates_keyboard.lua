ZO_SINGLE_LINE_EDIT_CONTAINER_PADDING_TOP = 3
ZO_SINGLE_LINE_EDIT_CONTAINER_PADDING_BOTTOM = 3
ZO_SINGLE_LINE_EDIT_CONTAINER_PADDING_LEFT = 8
ZO_SINGLE_LINE_EDIT_CONTAINER_PADDING_RIGHT = 6
ZO_SINGLE_LINE_TOGGLE_PASSWORD_EDIT_CONTAINER_PADDING_RIGHT = ZO_SINGLE_LINE_EDIT_CONTAINER_PADDING_RIGHT + 32

local EditContainerSizer_Keyboard = ZO_EditContainerSizer:New(ZO_SINGLE_LINE_EDIT_CONTAINER_PADDING_TOP, ZO_SINGLE_LINE_EDIT_CONTAINER_PADDING_BOTTOM)

function ZO_SingleLineEditContainerSize_Keyboard_OnInitialized(self)
    EditContainerSizer_Keyboard:Add(self)
end

ZO_SINGLE_LINE_EDIT_CONTAINER_DARK_PADDING_TOP = 5
ZO_SINGLE_LINE_EDIT_CONTAINER_DARK_PADDING_BOTTOM = 8
ZO_SINGLE_LINE_EDIT_CONTAINER_DARK_PADDING_LEFT = 8
ZO_SINGLE_LINE_EDIT_CONTAINER_DARK_PADDING_RIGHT = 6

local EditContainerDarkSizer_Keyboard = ZO_EditContainerSizer:New(ZO_SINGLE_LINE_EDIT_CONTAINER_DARK_PADDING_TOP, ZO_SINGLE_LINE_EDIT_CONTAINER_DARK_PADDING_BOTTOM)

function ZO_SingleLineEditContainerDarkSize_Keyboard_OnInitialized(self)
    EditContainerDarkSizer_Keyboard:Add(self)
end

ZO_MULTI_LINE_EDIT_CONTAINER_PADDING_TOP = 5
ZO_MULTI_LINE_EDIT_CONTAINER_PADDING_BOTTOM = 7
ZO_MULTI_LINE_EDIT_CONTAINER_PADDING_LEFT = 6
ZO_MULTI_LINE_EDIT_CONTAINER_PADDING_RIGHT = 7

function ZO_EditBoxKeyboard_SetAsPassword(editBoxControl, isPassword, passwordButtonControl)
    editBoxControl:SetAsPassword(isPassword)
    if passwordButtonControl then
        if isPassword then
            passwordButtonControl:SetNormalTexture("EsoUI/Art/Miscellaneous/Keyboard/hidden_up.dds")
            passwordButtonControl:SetMouseOverTexture("EsoUI/Art/Miscellaneous/Keyboard/hidden_over.dds")
            passwordButtonControl:SetPressedTexture("EsoUI/Art/Miscellaneous/Keyboard/hidden_down.dds")
        else
            passwordButtonControl:SetNormalTexture("EsoUI/Art/Miscellaneous/Keyboard/visible_up.dds")
            passwordButtonControl:SetMouseOverTexture("EsoUI/Art/Miscellaneous/Keyboard/visible_over.dds")
            passwordButtonControl:SetPressedTexture("EsoUI/Art/Miscellaneous/Keyboard/visible_down.dds")
        end
    end
end

function ZO_EditBoxKeyboard_TogglePassword(editBoxControl, passwordButtonControl)
    local wasPassword = editBoxControl:IsPassword()
    ZO_EditBoxKeyboard_SetAsPassword(editBoxControl, not wasPassword, passwordButtonControl)
end