ZO_TributeConfinementViewer_Keyboard = ZO_TributeConfinementViewer_Shared:Subclass()

function ZO_TributeConfinementViewer_Keyboard:Initialize(control)
    local TEMPLATE_DATA =
    {
        gridListClass = ZO_GridScrollList_Keyboard,
        cardEntryData =
        {
            entryTemplate = "ZO_TributeConfinementViewerCardTile_Keyboard_Control",
            width = ZO_TRIBUTE_CARD_TILE_WIDTH_KEYBOARD,
            height = ZO_TRIBUTE_CARD_TILE_TALL_HEIGHT_KEYBOARD,
            gridPaddingX = 20,
            --Allow tiles to overlap to accommodate size of card highlight without excessive spacing between cards
            gridPaddingY = -15,
        },
    }
    ZO_TributeConfinementViewer_Shared.Initialize(self, control, TEMPLATE_DATA)
    TRIBUTE_CONFINEMENT_VIEWER_KEYBOARD_FRAGMENT = ZO_FadeSceneFragment:New(control)
    TRIBUTE_CONFINEMENT_VIEWER_KEYBOARD_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
            self:RefreshTitle()
        end
    end)
    self.fragment = TRIBUTE_CONFINEMENT_VIEWER_KEYBOARD_FRAGMENT
end

----------------------------------
-- Functions Overridden From Base
----------------------------------

function ZO_TributeConfinementViewer_Keyboard:InitializeControls()
    self.headerContainer = self.control:GetNamedChild("Header")
    self.title = self.headerContainer:GetNamedChild("Title")
end

function ZO_TributeConfinementViewer_Keyboard:SetTitle(titleText)
    self.title:SetText(titleText)
end

function ZO_TributeConfinementViewer_Keyboard:CanShow()
    return not IsInGamepadPreferredMode()
end

function ZO_TributeConfinementViewer_Keyboard:Show()
    SCENE_MANAGER:AddFragmentGroup(ZO_KEYBOARD_TRIBUTE_CONFINEMENT_VIEWER_FRAGMENT_GROUP)
end

function ZO_TributeConfinementViewer_Keyboard:Hide()
    ZO_TributeConfinementViewer_Shared.Hide(self)
    SCENE_MANAGER:RemoveFragmentGroup(ZO_KEYBOARD_TRIBUTE_CONFINEMENT_VIEWER_FRAGMENT_GROUP)
end

-------------------------
-- Global XML Functions
-------------------------

function ZO_TributeConfinementViewer_Keyboard_OnInitialized(control)
    TRIBUTE_CONFINEMENT_VIEWER_KEYBOARD = ZO_TributeConfinementViewer_Keyboard:New(control)
end