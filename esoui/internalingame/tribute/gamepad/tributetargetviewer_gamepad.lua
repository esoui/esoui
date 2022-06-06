ZO_TributeTargetViewer_Gamepad = ZO_TributeTargetViewer_Shared:Subclass()

function ZO_TributeTargetViewer_Gamepad:Initialize(control)
    local TEMPLATE_DATA =
    {
        gridListClass = ZO_GridScrollList_Gamepad,
        cardEntryData =
        {
            entryTemplate = "ZO_TributeTargetViewerCardTile_Gamepad_Control",
            width = ZO_TRIBUTE_TILE_WIDTH_GAMEPAD,
            height = ZO_TRIBUTE_TILE_HEIGHT_GAMEPAD,
            gridPaddingX = 5,
            gridPaddingY = 10,
        },
    }
    ZO_TributeTargetViewer_Shared.Initialize(self, control, TEMPLATE_DATA)

    TRIBUTE_TARGET_VIEWER_GAMEPAD_FRAGMENT = ZO_FadeSceneFragment:New(control)
    TRIBUTE_TARGET_VIEWER_GAMEPAD_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
            self:RefreshInstruction()
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
    self.fragment = TRIBUTE_TARGET_VIEWER_GAMEPAD_FRAGMENT
end

function ZO_TributeTargetViewer_Gamepad:OnGridSelectionChanged(oldSelectedData, selectedData)
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

--------------------------------------
-- Functions Overridden From Base
--------------------------------------

function ZO_TributeTargetViewer_Gamepad:InitializeControls()
    self.header = self.control:GetNamedChild("HeaderContainerHeader")
    ZO_GamepadGenericHeader_Initialize(self.header, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE)
end

function ZO_TributeTargetViewer_Gamepad:InitializeGridList()
    ZO_TributeTargetViewer_Shared.InitializeGridList(self)
    self.gridList:SetScrollToExtent(true)
    self.gridList:SetOnSelectedDataChangedCallback(function(...) self:OnGridSelectionChanged(...) end)
end

function ZO_TributeTargetViewer_Gamepad:SetInstruction(instructionText)
    local headerData =
    {
        titleText = instructionText,
    }
    ZO_GamepadGenericHeader_Refresh(self.header, headerData)
end


function ZO_TributeTargetViewer_Gamepad:CanShow()
    return IsInGamepadPreferredMode()
end

function ZO_TributeTargetViewer_Gamepad:Show()
    SCENE_MANAGER:AddFragmentGroup(ZO_GAMEPAD_TRIBUTE_TARGET_VIEWER_FRAGMENT_GROUP)
end

function ZO_TributeTargetViewer_Gamepad:Hide()
    ZO_TributeTargetViewer_Shared.Hide(self)
    SCENE_MANAGER:RemoveFragmentGroup(ZO_GAMEPAD_TRIBUTE_TARGET_VIEWER_FRAGMENT_GROUP)
end

-------------------------
-- Global XML Functions
-------------------------

function ZO_TributeTargetViewer_Gamepad_OnInitialized(control)
    TRIBUTE_TARGET_VIEWER_GAMEPAD = ZO_TributeTargetViewer_Gamepad:New(control)
end