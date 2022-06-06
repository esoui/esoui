ZO_TributeTargetViewer_Keyboard = ZO_TributeTargetViewer_Shared:Subclass()

function ZO_TributeTargetViewer_Keyboard:Initialize(control)
    local TEMPLATE_DATA =
    {
        gridListClass = ZO_GridScrollList_Keyboard,
        cardEntryData =
        {
            entryTemplate = "ZO_TributeTargetViewerCardTile_Keyboard_Control",
            width = ZO_TRIBUTE_CARD_TILE_WIDTH_KEYBOARD,
            height = ZO_TRIBUTE_CARD_TILE_TALL_HEIGHT_KEYBOARD,
            gridPaddingX = 20,
            --Allow tiles to overlap to accommodate size of card highlight without excessive spacing between cards
            gridPaddingY = -15,
        },
    }
    ZO_TributeTargetViewer_Shared.Initialize(self, control, TEMPLATE_DATA)
    TRIBUTE_TARGET_VIEWER_KEYBOARD_FRAGMENT = ZO_FadeSceneFragment:New(control)
    TRIBUTE_TARGET_VIEWER_KEYBOARD_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
            self:RefreshInstruction()
        elseif newState == SCENE_FRAGMENT_SHOWN then
            KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
        elseif newState == SCENE_FRAGMENT_HIDING then
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
        end
    end)
    self.fragment = TRIBUTE_TARGET_VIEWER_KEYBOARD_FRAGMENT
end

----------------------------------
-- Functions Overridden From Base
----------------------------------

function ZO_TributeTargetViewer_Keyboard:InitializeControls()
    self.headerContainer = self.control:GetNamedChild("Header")
    self.instructionText = self.headerContainer:GetNamedChild("Instruction")
end

function ZO_TributeTargetViewer_Keyboard:SetInstruction(instructionText)
    self.instructionText:SetText(instructionText)
end

function ZO_TributeTargetViewer_Keyboard:CanShow()
    return not IsInGamepadPreferredMode()
end

function ZO_TributeTargetViewer_Keyboard:Show()
    SCENE_MANAGER:AddFragmentGroup(ZO_KEYBOARD_TRIBUTE_TARGET_VIEWER_FRAGMENT_GROUP)
end

function ZO_TributeTargetViewer_Keyboard:Hide()
    ZO_TributeTargetViewer_Shared.Hide(self)
    SCENE_MANAGER:RemoveFragmentGroup(ZO_KEYBOARD_TRIBUTE_TARGET_VIEWER_FRAGMENT_GROUP)
end

-------------------------
-- Global XML Functions
-------------------------

function ZO_TributeTargetViewer_Keyboard_OnInitialized(control)
    TRIBUTE_TARGET_VIEWER_KEYBOARD = ZO_TributeTargetViewer_Keyboard:New(control)
end