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
    local narrationInfo =
    {
        canNarrate = function()
            return self:GetFragment():IsShowing()
        end,
        selectedNarrationFunction = function()
            local narrations = {}
            local data = self.carousel:GetSelectedData()
            if data then
                --Generate the narration for the remaining time
                local remainingTime = CHARACTER_SELECT_MANAGER:GetEventAnnouncementRemainingTimeByIndex(data.index)
                local countdownText = ZO_FormatTime(remainingTime, TIME_FORMAT_STYLE_SHOW_LARGEST_TWO_UNITS, TIME_FORMAT_PRECISION_TWENTY_FOUR_HOUR)
                ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(zo_strformat(SI_EVENT_ANNOUNCEMENT_TIME, countdownText)))
                --Generate the narration for the name and description
                ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(data.name))
                ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(data.description))
            end
            return narrations
        end,
        additionalInputNarrationFunction = function()
            --Only narrate the directional input if there is more than one option
            if self.carousel:CanScroll() then
                return ZO_GetHorizontalDirectionalInputNarrationData(GetString(SI_SCREEN_NARRATION_TABBAR_PREVIOUS_KEYBIND), GetString(SI_SCREEN_NARRATION_TABBAR_NEXT_KEYBIND))
            else
                return {}
            end
        end,
    }
    SCREEN_NARRATION_MANAGER:RegisterCustomObject("CharacterSelectEventBanner", narrationInfo)
end

function ZO_CharacterSelect_EventBanner_Gamepad:InitializeKeybinds()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
    }
    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, function() self:OnEventBannerCloseKeybind() end, GetString(SI_DIALOG_CLOSE))
end

function ZO_CharacterSelect_EventBanner_Gamepad:SetSelectedIndex(selectedIndex)
    self.autoSelectIndex = selectedIndex and (1 - selectedIndex) or 0
end

function ZO_CharacterSelect_EventBanner_Gamepad:OnShowing()
    ZO_CharacterSelect_EventBanner_Shared.OnShowing(self)

    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
    SCREEN_NARRATION_MANAGER:QueueCustomEntry("CharacterSelectEventBanner")
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

--Overridden from base
function ZO_CharacterSelect_EventBanner_Gamepad:OnSelectionChanged(index)
    ZO_CharacterSelect_EventBanner_Shared.OnSelectionChanged(self, index)
    --Re-narrate when the selection changes
    SCREEN_NARRATION_MANAGER:QueueCustomEntry("CharacterSelectEventBanner")
end

-------------------------
-- Global XML Functions
-------------------------

function ZO_CharacterSelect_EventBanner_Gamepad_OnInitialized(control)
    CHARACTER_SELECT_EVENT_BANNER_GAMEPAD = ZO_CharacterSelect_EventBanner_Gamepad:New(control)
end