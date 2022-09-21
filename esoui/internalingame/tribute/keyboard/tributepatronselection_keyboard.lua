local PATRON_TILE_GRID_PADDING_X = 8
ZO_TRIBUTE_PATRON_SELECTION_KEYBOARD_HEADER_WIDTH = (ZO_TRIBUTE_PATRON_SELECTION_TILE_WIDTH_KEYBOARD * 5) + (PATRON_TILE_GRID_PADDING_X * 4)
ZO_TRIBUTE_PATRON_SELECTION_KEYBOARD_GRID_WIDTH = ZO_TRIBUTE_PATRON_SELECTION_KEYBOARD_HEADER_WIDTH + ZO_SCROLL_BAR_WIDTH

ZO_TributePatronSelection_Keyboard = ZO_TributePatronSelection_Shared:Subclass()

function ZO_TributePatronSelection_Keyboard:Initialize(control)
    local TEMPLATE_DATA =
    {
        gridListClass = ZO_GridScrollList_Keyboard,
        patronEntryData =
        {
            entryTemplate = "ZO_TributePatronSelectionTile_Keyboard_Control",
            width = ZO_TRIBUTE_PATRON_SELECTION_TILE_WIDTH_KEYBOARD,
            height = ZO_TRIBUTE_PATRON_SELECTION_TILE_HEIGHT_KEYBOARD,
            gridPaddingX = PATRON_TILE_GRID_PADDING_X,
            gridPaddingY = 10,
        },
    }
    ZO_TributePatronSelection_Shared.Initialize(self, control, TEMPLATE_DATA)
    TRIBUTE_PATRON_SELECTION_KEYBOARD_FRAGMENT = ZO_FadeSceneFragment:New(control)
    TRIBUTE_PATRON_SELECTION_KEYBOARD_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWN then
            KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
        elseif newState == SCENE_FRAGMENT_HIDING then
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
        end
    end)
end

----------------------------------
-- Functions Overridden From Base
----------------------------------

function ZO_TributePatronSelection_Keyboard:InitializeControls()
    self.headerContainer = self.control:GetNamedChild("Header")
    self.selectionText = self.control:GetNamedChild("SubHeaderText")
    self.divider = self.control:GetNamedChild("Divider")
    self.matchInfo = self.headerContainer:GetNamedChild("MatchInfo")
    self.timerContainer = self.headerContainer:GetNamedChild("Timer")
    self.timerText = self.timerContainer:GetNamedChild("Text")
end

function ZO_TributePatronSelection_Keyboard:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,
        {
            name = GetString(SI_TRIBUTE_DECK_SELECTION_CONFIRM_ACTION),
            order = 2,
            keybind = "UI_SHORTCUT_SECONDARY",
            callback = function() ZO_TRIBUTE_PATRON_SELECTION_MANAGER:ConfirmSelection() end,
            enabled = function()
                return ZO_TRIBUTE_PATRON_SELECTION_MANAGER:GetSelectedPatron() ~= nil
            end,
            visible = function()
                return self:ShouldShowConfirm()
            end,
        },
    }
end

function ZO_TributePatronSelection_Keyboard:CanShow()
    return not IsInGamepadPreferredMode()
end

function ZO_TributePatronSelection_Keyboard:Show()
    local RESET_TO_TOP = true
    local DONT_RESELECT_DATA = false
    local ANIMATE_INSTANTLY = true
    self:RefreshGridList(RESET_TO_TOP, DONT_RESELECT_DATA, ANIMATE_INSTANTLY)
    SCENE_MANAGER:AddFragmentGroup(ZO_KEYBOARD_TRIBUTE_PATRON_SELECTION_FRAGMENT_GROUP)
end

function ZO_TributePatronSelection_Keyboard:Hide()
    SCENE_MANAGER:RemoveFragmentGroup(ZO_KEYBOARD_TRIBUTE_PATRON_SELECTION_FRAGMENT_GROUP)
end

-------------------------
-- Global XML Functions
-------------------------

function ZO_TributePatronSelection_Keyboard_OnInitialized(control)
    TRIBUTE_PATRON_SELECTION_KEYBOARD = ZO_TributePatronSelection_Keyboard:New(control)
end