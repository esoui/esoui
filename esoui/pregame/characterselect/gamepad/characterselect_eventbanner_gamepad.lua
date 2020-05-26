----
-- ZO_CharacterSelect_EventBanner_Gamepad
----

ZO_CharacterSelect_EventBanner_Gamepad = ZO_CharacterSelect_EventBanner_Shared:Subclass()

function ZO_CharacterSelect_EventBanner_Gamepad:New(...)
    return ZO_CharacterSelect_EventBanner_Shared.New(self, ...)
end

function ZO_CharacterSelect_EventBanner_Gamepad:Initialize(control, conditionFunction)
    ZO_CharacterSelect_EventBanner_Shared.Initialize(self, control, conditionFunction)

    self.carousel = ZO_Carousel_Shared:New(self.carouselControl, "ZO_CharacterSelect_EventTile_Gamepad_Control")
    self.carousel:SetSelectionIndicatorPipStateImages("EsoUI/Art/Miscellaneous/Gamepad/pip_active.dds", "EsoUI/Art/Miscellaneous/Gamepad/pip_inactive.dds")
    self.carousel:SetSelectionIndicatorPipDimensions(32, 32)
end

function ZO_CharacterSelect_EventBanner_Gamepad:InitializeKeybinds()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
    }
    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, function() self:OnEventBannerCloseKeybind() end)
end

function ZO_CharacterSelect_EventBanner_Gamepad:SetSelectedIndex(selectedIndex)
    self.autoSelectIndex = selectedIndex and (1 - selectedIndex) or 0
end

function ZO_CharacterSelect_EventBanner_Gamepad:OnShowing()
    ZO_CharacterSelect_EventBanner_Shared.OnShowing(self)

    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_CharacterSelect_EventBanner_Gamepad:OnHiding()
    ZO_CharacterSelect_EventBanner_Shared.OnHiding(self)

    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_CharacterSelect_EventBanner_Gamepad:SetOnCloseCallback(onCloseCallback)
    self.onCloseCallback = onCloseCallback
end

function ZO_CharacterSelect_EventBanner_Gamepad:OnEventBannerCloseKeybind()
    ZO_CharacterSelect_EventBanner_Shared.OnEventBannerCloseKeybind(self)

    if self.onCloseCallback then
        self.onCloseCallback()
    end
end

-------------------------
-- Global XML Functions
-------------------------

function ZO_CharacterSelect_EventBanner_Gamepad_OnInitialized(control)
    CHARACTER_SELECT_EVENT_BANNER_GAMEPAD = ZO_CharacterSelect_EventBanner_Gamepad:New(control)
end