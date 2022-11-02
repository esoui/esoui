--------------
--Focus Grid--
--------------
ZO_TributePatronSelection_Gamepad_FocusArea_Grid = ZO_GamepadMultiFocusArea_Base:Subclass()

function ZO_TributePatronSelection_Gamepad_FocusArea_Grid:HandleMovement(horizontalResult, verticalResult)
    --Pipe directional input through to the grid list
    self.gridList:HandleMoveInDirection(horizontalResult, verticalResult)
    return true
end

function ZO_TributePatronSelection_Gamepad_FocusArea_Grid:CanBeSelected()
    return self.gridList:HasEntries()
end

function ZO_TributePatronSelection_Gamepad_FocusArea_Grid:HandleMovePrevious()
    local consumed = false
    return consumed
end

function ZO_TributePatronSelection_Gamepad_FocusArea_Grid:HandleMoveNext()
    local consumed = false
    return consumed
end

------------------
--Focus Drafted --
------------------
ZO_TributePatronSelection_Gamepad_FocusArea_Drafted = ZO_GamepadMultiFocusArea_Base:Subclass()

local PATRON_DRAFT_ID_ORDER =
{
    TRIBUTE_PATRON_DRAFT_ID_FIRST_PLAYER_FIRST_PICK,
    TRIBUTE_PATRON_DRAFT_ID_SECOND_PLAYER_FIRST_PICK,
    TRIBUTE_PATRON_DRAFT_ID_NEUTRAL,
    TRIBUTE_PATRON_DRAFT_ID_SECOND_PLAYER_SECOND_PICK,
    TRIBUTE_PATRON_DRAFT_ID_FIRST_PLAYER_SECOND_PICK,
}

function ZO_TributePatronSelection_Gamepad_FocusArea_Drafted:HandleMovement(horizontalResult, verticalResult)
    local newDraftId = self.currentDraftId
    local patronStalls = TRIBUTE:GetPatronStalls()
    local currentDraftIndex = ZO_IndexOfElementInNumericallyIndexedTable(PATRON_DRAFT_ID_ORDER, self.currentDraftId)

    if verticalResult == MOVEMENT_CONTROLLER_MOVE_NEXT then
        --Find the first patron stall with data following the currently selected stall
        for i = currentDraftIndex, #PATRON_DRAFT_ID_ORDER do
            if i > currentDraftIndex then
                local draftId = PATRON_DRAFT_ID_ORDER[i]
                local stall = patronStalls[draftId]
                if stall and stall:GetDataSource() then
                    newDraftId = draftId
                    break
                end
            end
        end
    elseif verticalResult == MOVEMENT_CONTROLLER_MOVE_PREVIOUS then
        --Find the first patron stall with data before the currently selected stall
        for i = currentDraftIndex, 1, -1 do
            if i < currentDraftIndex then
                local draftId = PATRON_DRAFT_ID_ORDER[i]
                local stall = patronStalls[draftId]
                if stall and stall:GetDataSource() then
                    newDraftId = draftId
                    break
                end
            end
        end
    end

    local HIGHLIGHT_PATRON = true
    self:SetDraftId(newDraftId, HIGHLIGHT_PATRON)
    return true
end

function ZO_TributePatronSelection_Gamepad_FocusArea_Drafted:CanBeSelected()
    --If any stalls have data we can select this focus area
    for _, patronStall in pairs(TRIBUTE:GetPatronStalls()) do
        if patronStall:GetDataSource() then
            return true
        end
    end
    return false
end

function ZO_TributePatronSelection_Gamepad_FocusArea_Drafted:HandleMovePrevious()
    local consumed = false
    return consumed
end

function ZO_TributePatronSelection_Gamepad_FocusArea_Drafted:HandleMoveNext()
    local consumed = false
    return consumed
end

function ZO_TributePatronSelection_Gamepad_FocusArea_Drafted:SetDraftId(draftId, doHighlight)
    if draftId ~= self.currentDraftId then
        self.currentDraftId = draftId
        if doHighlight then
            SetHighlightedTributePatron(self.currentDraftId)
        end
    end
end

function ZO_TributePatronSelection_Gamepad_FocusArea_Drafted:RefreshTooltips()
    local patronStalls = TRIBUTE:GetPatronStalls()
    if ZO_TRIBUTE_PATRON_SELECTION_MANAGER:ShouldShowGamepadTooltips() then
        patronStalls[self.currentDraftId]:ShowTooltip()
    else
        patronStalls[self.currentDraftId]:HideTooltip()
    end
end

local PATRON_TILE_GRID_PADDING_X = 12
-- 5 is the number of card slots in a row and 4 is the number of padded spaces between those cards
ZO_TRIBUTE_PATRON_SELECTION_GAMEPAD_HEADER_WIDTH = (ZO_TRIBUTE_PATRON_SELECTION_TILE_WIDTH_GAMEPAD * 5) + (PATRON_TILE_GRID_PADDING_X * 4)
ZO_TRIBUTE_PATRON_SELECTION_GAMEPAD_GRID_WIDTH = ZO_TRIBUTE_PATRON_SELECTION_GAMEPAD_HEADER_WIDTH + ZO_SCROLL_BAR_WIDTH

--TODO Tribute: Determine how much of this logic can be moved to shared
ZO_TributePatronSelection_Gamepad = ZO_Object.MultiSubclass(ZO_GamepadMultiFocusArea_Manager, ZO_TributePatronSelection_Shared)

function ZO_TributePatronSelection_Gamepad:Initialize(control)
    local TEMPLATE_DATA =
    {
        gridListClass = ZO_GridScrollList_Gamepad,
        patronEntryData =
        {
            entryTemplate = "ZO_TributePatronSelectionTile_Gamepad_Control",
            width = ZO_TRIBUTE_PATRON_SELECTION_TILE_WIDTH_GAMEPAD,
            height = ZO_TRIBUTE_PATRON_SELECTION_TILE_HEIGHT_GAMEPAD,
            gridPaddingX = PATRON_TILE_GRID_PADDING_X,
            gridPaddingY = 10,
        },
    }
    ZO_TributePatronSelection_Shared.Initialize(self, control, TEMPLATE_DATA)
    ZO_GamepadMultiFocusArea_Manager.Initialize(self)
    TRIBUTE_PATRON_SELECTION_GAMEPAD_FRAGMENT = ZO_FadeSceneFragment:New(control)
    TRIBUTE_PATRON_SELECTION_GAMEPAD_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWN then
            CALLBACK_MANAGER:RegisterCallback("AllDialogsHidden", self.OnGamepadDialogHidden)
            CALLBACK_MANAGER:RegisterCallback("OnGamepadDialogShowing", self.OnGamepadDialogShowing)
            --TODO Tribute: Switch this to neutral once neutral patrons become a thing
            local DONT_HIGHLIGHT = false
            self.draftArea:SetDraftId(TRIBUTE_PATRON_DRAFT_ID_FIRST_PLAYER_FIRST_PICK, DONT_HIGHLIGHT)
            --Always start off with the grid focused
            self:SelectFocusArea(self.gridArea)
            --If there is a dialog showing, don't activate the focus yet
            if not ZO_Dialogs_IsShowingDialog() then
                self:ActivateCurrentFocus()
            end
            DIRECTIONAL_INPUT:Activate(self, self.control)
            KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
        elseif newState == SCENE_FRAGMENT_HIDING then
            CALLBACK_MANAGER:UnregisterCallback("AllDialogsHidden", self.OnGamepadDialogHidden)
            CALLBACK_MANAGER:UnregisterCallback("OnGamepadDialogShowing", self.OnGamepadDialogShowing)
            self:DeactivateCurrentFocus()
            DIRECTIONAL_INPUT:Deactivate(self)
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
        end
    end)

    self:InitializeMultiFocusAreas()
    self.OnGamepadDialogHidden = function()
        self:ActivateCurrentFocus()
    end

    self.OnGamepadDialogShowing = function()
        self:DeactivateCurrentFocus()
    end
end

function ZO_TributePatronSelection_Gamepad:InitializeMultiFocusAreas()
    --Directional input is managed in this class instead of in the grid list
    local FOREGO_DIRECTIONAL_INPUT = true

    local function GridActivateCallback()
        self.gridList:Activate(FOREGO_DIRECTIONAL_INPUT)
    end

    local function GridDeactivateCallback()
        self.gridList:Deactivate(FOREGO_DIRECTIONAL_INPUT)
    end
    self.gridArea = ZO_TributePatronSelection_Gamepad_FocusArea_Grid:New(self, GridActivateCallback, GridDeactivateCallback)
    self.gridArea.gridList = self.gridList

    local function DraftedActivateCallback()
        SetHighlightedTributePatron(self.draftArea.currentDraftId)
    end

    local function DraftedDeactivateCallback()
        local draftId = self.draftArea.currentDraftId
        local patronStalls = TRIBUTE:GetPatronStalls()
        --We need to manually hide the tooltip, as waiting for the state change event to come back will cause a race condition with the grid list tooltip
        patronStalls[draftId]:HideTooltip()
        SetHighlightedTributePatron(nil)
    end
    self.draftArea = ZO_TributePatronSelection_Gamepad_FocusArea_Drafted:New(self, DraftedActivateCallback, DraftedDeactivateCallback)
    self.draftArea:SetKeybindDescriptor(self.draftedSectionKeybindStripDescriptor)

    self:AddNextFocusArea(self.gridArea)
    self:AddNextFocusArea(self.draftArea)
    self:SelectFocusArea(self.gridArea)
end

function ZO_TributePatronSelection_Gamepad:OnGridSelectionChanged(oldSelectedData, selectedData)
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
        ZO_TributePatronTooltip_Gamepad_Hide()
    end
end

----------------------------------
-- Functions Overridden From Base
----------------------------------
function ZO_TributePatronSelection_Gamepad:InitializeGridList()
    ZO_TributePatronSelection_Shared.InitializeGridList(self)
    self.gridList:SetScrollToExtent(true)
    self.gridList:SetOnSelectedDataChangedCallback(function(...) self:OnGridSelectionChanged(...) end)
end

function ZO_TributePatronSelection_Gamepad:InitializeControls()
    self.selectionText = self.control:GetNamedChild("SubHeaderText")
    self.divider = self.control:GetNamedChild("Divider")
    self.matchInfo = self.control:GetNamedChild("HeaderMatchInfo")
    self.timerContainer = self.control:GetNamedChild("HeaderTimer")
    self.timerText = self.timerContainer:GetNamedChild("Text")
end

function ZO_TributePatronSelection_Gamepad:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,
        {
            name = GetString(SI_TRIBUTE_DECK_SELECTION_CONFIRM_ACTION),
            order = 2,
            keybind = "UI_SHORTCUT_SECONDARY",
            callback = function() 
                ZO_TRIBUTE_PATRON_SELECTION_MANAGER:ConfirmSelection() 
            end,
            enabled = function()
                return ZO_TRIBUTE_PATRON_SELECTION_MANAGER:GetSelectedPatron() ~= nil
            end,
            visible = function()
                return self:ShouldShowConfirm()
            end,
        },
        {
            name= function()
                if self:IsCurrentFocusArea(self.gridArea) then
                    return GetString(SI_TRIBUTE_DECK_SELECTION_GAMEPAD_VIEW_DRAFTED_PATRONS_ACTION)
                else
                    return GetString(SI_TRIBUTE_DECK_SELECTION_GAMEPAD_DRAFT_PATRONS_ACTION)
                end
            end,
            order = 4,
            keybind = "UI_SHORTCUT_QUATERNARY",
            callback = function()
                if self:IsCurrentFocusArea(self.gridArea) then
                    self:ActivateFocusArea(self.draftArea)
                else
                    self:ActivateFocusArea(self.gridArea)
                end
                KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
            end,
            visible = function()
                return self.draftArea:CanBeSelected()
            end,
        },
        {
            keybind = "UI_SHORTCUT_NEGATIVE",
            ethereal = true,
            callback = function()
              local NO_EVENT = nil
              local NOT_INTERCEPTING_CLOSE_ACTION = false
              TRIBUTE:RequestExitTribute(NO_EVENT, NOT_INTERCEPTING_CLOSE_ACTION)
            end,
        },
    }

    self.draftedSectionKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,
        {
            name = GetString(SI_TRIBUTE_DECK_SELECTION_GAMEPAD_TOGGLE_TOOLTIPS_ACTION),
            order = 3,
            keybind = "UI_SHORTCUT_TERTIARY",
            callback = function()
                ZO_TRIBUTE_PATRON_SELECTION_MANAGER:ToggleShowGamepadTooltips()
                self.draftArea:RefreshTooltips()
            end,
        },
    }
end

function ZO_TributePatronSelection_Gamepad:CanShow()
    return IsInGamepadPreferredMode()
end

function ZO_TributePatronSelection_Gamepad:Show()
    local RESET_TO_TOP = true
    local DONT_RESELECT_DATA = false
    local ANIMATE_INSTANTLY = true
    self:RefreshGridList(RESET_TO_TOP, DONT_RESELECT_DATA, ANIMATE_INSTANTLY)
    SCENE_MANAGER:AddFragmentGroup(ZO_GAMEPAD_TRIBUTE_PATRON_SELECTION_FRAGMENT_GROUP)
end

function ZO_TributePatronSelection_Gamepad:Hide()
    SCENE_MANAGER:RemoveFragmentGroup(ZO_GAMEPAD_TRIBUTE_PATRON_SELECTION_FRAGMENT_GROUP)
end

-------------------------
-- Global XML Functions
-------------------------

function ZO_TributePatronSelection_Gamepad_OnInitialized(control)
    TRIBUTE_PATRON_SELECTION_GAMEPAD = ZO_TributePatronSelection_Gamepad:New(control)
end