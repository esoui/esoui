ZO_TributePileViewer_Gamepad = ZO_TributePileViewer_Shared:Subclass()

function ZO_TributePileViewer_Gamepad:Initialize(control)
    local TEMPLATE_DATA =
    {
        gridListClass = ZO_GridScrollList_Gamepad,
        cardEntryData =
        {
            entryTemplate = "ZO_TributePileViewerCardTile_Gamepad_Control",
            width = ZO_TRIBUTE_TILE_WIDTH_GAMEPAD,
            height = ZO_TRIBUTE_TILE_HEIGHT_GAMEPAD,
            gridPaddingX = 5,
            gridPaddingY = 10,
        },
    }
    ZO_TributePileViewer_Shared.Initialize(self, control, TEMPLATE_DATA)

    TRIBUTE_PILE_VIEWER_GAMEPAD_FRAGMENT = ZO_FadeSceneFragment:New(control)
    TRIBUTE_PILE_VIEWER_GAMEPAD_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
            self:RefreshHeader()
        elseif newState == SCENE_FRAGMENT_SHOWN then
            self.gridList:Activate()
            ZO_GamepadGenericHeader_Activate(self.header)
            KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
        elseif newState == SCENE_FRAGMENT_HIDING then
            if self.gridList:IsActive() then
                self.gridList:Deactivate()
            end
            ZO_GamepadGenericHeader_Deactivate(self.header)
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
        end
    end)
end

function ZO_TributePileViewer_Gamepad:OnGridSelectionChanged(oldSelectedData, selectedData)
    -- Deselect previous tile
    if oldSelectedData and oldSelectedData.dataEntry then
        if oldSelectedData.dataEntry.control then
            oldSelectedData.dataEntry.control.object:SetSelected(false)
        end
        oldSelectedData.isSelected = false
    end

    -- Select newly selected tile.
    if selectedData and selectedData.dataEntry then
        if selectedData.dataEntry.control then
            selectedData.dataEntry.control.object:SetSelected(true)
        end
        selectedData.isSelected = true
    else
        GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
    end
end

function ZO_TributePileViewer_Gamepad:RefreshHeader()
    local family = self.currentPileData:GetFamilyInfo()
    local tabBarEntries = {}
    local selectedIndex = 1
    for index, boardLocation in ipairs(family) do
        local pileData = ZO_TRIBUTE_PILE_VIEWER_MANAGER:GetViewerPileData(boardLocation)
        local tabData =
        {
            text = pileData:GetName(),
            callback = function() 
                ZO_TRIBUTE_PILE_VIEWER_MANAGER:SetViewingPile(boardLocation) 
            end,
            --We need to override the normal tab template to make the control wider than it is by default
            template = "ZO_TributePileViewerTabBar_Gamepad_Template",
        }
        table.insert(tabBarEntries, tabData)

        if pileData:GetBoardLocation() == self.currentPileData:GetBoardLocation() then
            selectedIndex = index
        end
    end

    local headerData =
    {
        tabBarEntries = tabBarEntries,
    }
    ZO_GamepadGenericHeader_Refresh(self.header, headerData)
    ZO_GamepadGenericHeader_SetActiveTabIndex(self.header, selectedIndex)
end

--------------------------------------
-- Functions Overridden From Base
--------------------------------------

function ZO_TributePileViewer_Gamepad:InitializeControls()
    self.header = self.control:GetNamedChild("HeaderContainerHeader")
    ZO_GamepadGenericHeader_Initialize(self.header, ZO_GAMEPAD_HEADER_TABBAR_CREATE)
    ZO_GamepadGenericHeader_AddTabBarTemplate(self.header, "ZO_TributePileViewerTabBar_Gamepad_Template")
end

function ZO_TributePileViewer_Gamepad:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            keybind = "UI_SHORTCUT_NEGATIVE",
            name = function()
                return GetString(SI_GAMEPAD_BACK_OPTION)
            end,
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

function ZO_TributePileViewer_Gamepad:InitializeGridList()
    ZO_TributePileViewer_Shared.InitializeGridList(self)
    self.gridList:SetScrollToExtent(true)
    self.gridList:SetOnSelectedDataChangedCallback(function(...) self:OnGridSelectionChanged(...) end)
end

function ZO_TributePileViewer_Gamepad:RefreshPile()
    local ANIMATE_INSTANTLY = true
    local SCROLL_INTO_VIEW = true
    local DONT_RESET_TO_TOP = false
    local RESELECT_DATA = true
    self:RefreshGridList(DONT_RESET_TO_TOP, RESELECT_DATA)
    self.gridList:RefreshSelection(ANIMATE_INSTANTLY, SCROLL_INTO_VIEW)
end

function ZO_TributePileViewer_Gamepad:CanShow()
    return IsInGamepadPreferredMode()
end

function ZO_TributePileViewer_Gamepad:Show()
    SCENE_MANAGER:AddFragmentGroup(ZO_GAMEPAD_TRIBUTE_PILE_VIEWER_FRAGMENT_GROUP)
end

function ZO_TributePileViewer_Gamepad:Hide()
    ZO_TributePileViewer_Shared.Hide(self)
    SCENE_MANAGER:RemoveFragmentGroup(ZO_GAMEPAD_TRIBUTE_PILE_VIEWER_FRAGMENT_GROUP)
end

-------------------------
-- Global XML Functions
-------------------------

function ZO_TributePileViewer_Gamepad_OnInitialized(control)
    TRIBUTE_PILE_VIEWER_GAMEPAD = ZO_TributePileViewer_Gamepad:New(control)
end