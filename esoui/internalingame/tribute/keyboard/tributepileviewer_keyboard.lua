ZO_TributePileViewer_Keyboard = ZO_TributePileViewer_Shared:Subclass()

function ZO_TributePileViewer_Keyboard:Initialize(control)
    local TEMPLATE_DATA =
    {
        gridListClass = ZO_GridScrollList_Keyboard,
        cardEntryData =
        {
            entryTemplate = "ZO_TributePileViewerCardTile_Keyboard_Control",
            width = ZO_TRIBUTE_CARD_TILE_WIDTH_KEYBOARD,
            height = ZO_TRIBUTE_CARD_TILE_TALL_HEIGHT_KEYBOARD,
            gridPaddingX = 20,
            --Allow tiles to overlap to accommodate size of card highlight without excessive spacing between cards
            gridPaddingY = -15,
        },
    }
    ZO_TributePileViewer_Shared.Initialize(self, control, TEMPLATE_DATA)
    TRIBUTE_PILE_VIEWER_KEYBOARD_FRAGMENT = ZO_FadeSceneFragment:New(control)
    TRIBUTE_PILE_VIEWER_KEYBOARD_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWN then
            KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
        elseif newState == SCENE_FRAGMENT_HIDING then
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
        end
    end)
end

function ZO_TributePileViewer_Keyboard:RefreshTabs()
    self.pileTabControlPool:ReleaseAllObjects()
    local family = self.currentPileData:GetFamilyInfo()
    local previousControl = nil
    for _, boardLocation in ipairs(family) do
        local pileData = ZO_TRIBUTE_PILE_VIEWER_MANAGER:GetViewerPileData(boardLocation)
        if pileData then
            local control = self.pileTabControlPool:AcquireObject()
            control:SetText(pileData:GetName())
            control.boardLocation = boardLocation
            if previousControl then
                control:SetAnchor(LEFT, previousControl, RIGHT, 50, 0)
            else
                control:SetAnchor(LEFT, nil, LEFT, 0, 0)
            end
            previousControl = control
            control:SetSelected(pileData:GetBoardLocation() == self.currentPileData:GetBoardLocation())
        end
    end
end

----------------------------------
-- Functions Overridden From Base
----------------------------------

function ZO_TributePileViewer_Keyboard:InitializeControls()
    self.headerContainer = self.control:GetNamedChild("Header")
    local tabsContainer = self.headerContainer:GetNamedChild("Tabs")
    self.pileTabControlPool = ZO_ControlPool:New("ZO_TributePileName_Keyboard", tabsContainer)
end

function ZO_TributePileViewer_Keyboard:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor =
    {
        {
            name = GetString(SI_DIALOG_CLOSE),
            keybind = "UI_SHORTCUT_NEGATIVE",
            callback = function()
                ZO_TRIBUTE_PILE_VIEWER_MANAGER:SetViewingPile(nil)
            end,
        },
        {
            keybind = "UI_SHORTCUT_EXIT",
            ethereal = true,
            callback = function()
                ZO_TRIBUTE_PILE_VIEWER_MANAGER:SetViewingPile(nil)
            end,
        },
    }
end

function ZO_TributePileViewer_Keyboard:RefreshPile()
    local DONT_RESET_TO_TOP = false
    self:RefreshGridList(DONT_RESET_TO_TOP)
end

function ZO_TributePileViewer_Keyboard:CanShow()
    return not IsInGamepadPreferredMode()
end

function ZO_TributePileViewer_Keyboard:Show()
    self:RefreshTabs()
    SCENE_MANAGER:AddFragmentGroup(ZO_KEYBOARD_TRIBUTE_PILE_VIEWER_FRAGMENT_GROUP)
end

function ZO_TributePileViewer_Keyboard:Hide()
    ZO_TributePileViewer_Shared.Hide(self)
    SCENE_MANAGER:RemoveFragmentGroup(ZO_KEYBOARD_TRIBUTE_PILE_VIEWER_FRAGMENT_GROUP)
end

-------------------------
-- Global XML Functions
-------------------------

function ZO_TributePileViewer_Keyboard_OnInitialized(control)
    TRIBUTE_PILE_VIEWER_KEYBOARD = ZO_TributePileViewer_Keyboard:New(control)
end

function ZO_TributePileName_Keyboard_OnMouseUp(control, upInside)
    if upInside then
        ZO_TRIBUTE_PILE_VIEWER_MANAGER:SetViewingPile(control.boardLocation)
        TRIBUTE_PILE_VIEWER_KEYBOARD:RefreshTabs()
    end
end

function ZO_TributePileViewerUnderlay_Keyboard_OnMouseUp(control, upInside)
    if upInside then
        ZO_TRIBUTE_PILE_VIEWER_MANAGER:SetViewingPile(nil)
    end
end