-----------------
-- Ignore List
-----------------

local IgnoreList_Gamepad = ZO_GamepadSocialListPanel:Subclass()

function IgnoreList_Gamepad:New(...)
    return ZO_GamepadSocialListPanel.New(self, ...)
end

function IgnoreList_Gamepad:Initialize(control)
    ZO_GamepadSocialListPanel.Initialize(self, control, IGNORE_LIST_MANAGER, "ZO_GamepadIgnoreListRow")
    self:SetTitle(GetString(SI_GAMEPAD_CONTACTS_IGNORED_LIST_TITLE))
    self:SetEmptyText(GetString(SI_GAMEPAD_CONTACTS_IGNORE_LIST_NO_ENTRIES_MESSAGE));
    self:SetupSort(IGNORE_LIST_ENTRY_SORT_KEYS, "displayName", ZO_SORT_ORDER_UP)

    GAMEPAD_IGNORED_LIST_SCENE = ZO_Scene:New("gamepad_ignored", SCENE_MANAGER)
    GAMEPAD_IGNORED_LIST_SCENE:AddFragment(self:GetListFragment())
end

function IgnoreList_Gamepad:GetAddKeybind()
    local keybind  =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        name = GetString(SI_GAMEPAD_CONTACTS_ADD_IGNORE_BUTTON_LABEL),

        keybind = "UI_SHORTCUT_SECONDARY",

        callback = function()
            ZO_Dialogs_ShowGamepadDialog("GAMEPAD_SOCIAL_ADD_IGNORE_DIALOG", nil)
        end,
    }
    return keybind
end

function IgnoreList_Gamepad:OnShowing()
    IGNORE_LIST_MANAGER:RefreshData()
    self:Activate()
    ZO_GamepadSocialListPanel.OnShowing(self)
end

function IgnoreList_Gamepad:BuildOptionsList()
    local groupId = self:AddOptionTemplateGroup(ZO_SocialOptionsDialogGamepad.GetDefaultHeader)
    self:AddOptionTemplate(groupId, ZO_SocialOptionsDialogGamepad.BuildRemoveIgnoreOption)
    self:AddOptionTemplate(groupId, ZO_SocialOptionsDialogGamepad.BuildGamerCardOption, IsConsoleUI)
end

function IgnoreList_Gamepad:RefreshTooltip()
    --overridden to do nothing
end

function ZO_IgnoreList_Gamepad_OnInitialized(self)
    ZO_IGNORE_LIST_GAMEPAD = IgnoreList_Gamepad:New(self)
end