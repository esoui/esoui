----
-- ZO_CharacterSelect_EventBanner_Keyboard
----

local ZO_CharacterSelect_EventBanner_Keyboard = ZO_CharacterSelect_EventBanner_Shared:Subclass()

function ZO_CharacterSelect_EventBanner_Keyboard:New(...)
    return ZO_CharacterSelect_EventBanner_Shared.New(self, ...)
end

function ZO_CharacterSelect_EventBanner_Keyboard:Initialize(control, conditionFunction)
    ZO_CharacterSelect_EventBanner_Shared.Initialize(self, control, conditionFunction)

    self.carousel = ZO_Carousel_Shared:New(self.carouselControl, "ZO_CharacterSelect_EventTile_Keyboard_Control")
    self.carousel:SetSelectionIndicatorPipStateImages("EsoUI/Art/Buttons/RadioButtonDown.dds", "EsoUI/Art/Buttons/RadioButtonUp.dds", "EsoUI/Art/Buttons/RadioButtonHighlight.dds")
end

function ZO_CharacterSelect_EventBanner_Keyboard:OnShowing()
    local miniEventBanner = CHARACTER_SELECT_FRAGMENT and CHARACTER_SELECT_FRAGMENT:GetControl() and CHARACTER_SELECT_FRAGMENT:GetControl().carousel
    if miniEventBanner then
        self.autoSelectIndex = miniEventBanner:GetSelectedIndex()
    end

    ZO_CharacterSelect_EventBanner_Shared.OnShowing(self)

    self.autoSelectIndex = false
end

function ZO_CharacterSelect_EventBanner_Keyboard:OnCloseClicked()
    self.closeButton:OnClicked()
end

-------------------------
-- Global XML Functions
-------------------------

function ZO_CharacterSelect_EventBanner_Keyboard_OnInitialized(control)
    CHARACTER_SELECT_EVENT_BANNER_KEYBOARD = ZO_CharacterSelect_EventBanner_Keyboard:New(control)
end