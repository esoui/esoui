ZO_GENERIC_SELECTOR_GRID_LIST_OFFSET_X = ZO_SCROLL_BAR_WIDTH
ZO_GENERIC_SELECTOR_GRID_LIST_OFFSET_Y = 15

local DEFAULT_HIGHLIGHT = "EsoUI/Art/GenericSelector/genericSelectorChoiceDefaultHighlight.dds"

ZO_GenericSelectorItem_Shared = ZO_Object:Subclass()

function ZO_GenericSelectorItem_Shared.OnControlInitialized(control)
    zo_mixin(control, ZO_GenericSelectorItem_Shared)

    control.highlightTexture = control:GetNamedChild("Highlight")
    control.iconTexture = control:GetNamedChild("Icon")
    control.nameLabel = control:GetNamedChild("Name")
    control.selectedIconTexture = control:GetNamedChild("SelectedIcon")
end

function ZO_GenericSelectorItem_Shared:Layout(data)
    -- Setup item instance.
    self.iconTexture:SetTexture(data.icon)
    self.nameLabel:SetText(ZO_CachedStrFormat(SI_ABILITY_NAME, data.name))
    self.highlightTexture:SetTexture(data.highlightTexture)
    self:SetSelected(data.selected)
end

function ZO_GenericSelectorItem_Shared:Reset()

end

function ZO_GenericSelectorItem_Shared:SetHighlightHidden(hidden)
    self.highlightTexture:SetHidden(hidden)
end

function ZO_GenericSelectorItem_Shared:SetSelected(selected)
    if self.dataEntry.data and SetGenericSelectorChoiceSelectedAtIndex(self.dataEntry.data.index, selected) then
        self.selected = selected
        self.selectedIconTexture:SetHidden(not selected)
        self:SetHighlightHidden(not selected)
    end
end

function ZO_GenericSelectorItem_Shared:IsSelected()
    return self.selected
end

local INTERACTION =
{
    type = "GenericSelector",
    interactTypes = { INTERACTION_GENERIC_SELECTION_PROMPT },
}

ZO_GenericSelector_Shared = ZO_DeferredInitializingObject:Subclass()

function ZO_GenericSelector_Shared:Initialize(control)
    self.control = control
    control.object = self

    local scene = ZO_InteractScene:New(self:GetSceneName(), SCENE_MANAGER, INTERACTION)
    ZO_DeferredInitializingObject.Initialize(self, scene)

    self.fragment = ZO_FadeSceneFragment:New(control)
    scene:AddFragment(self.fragment)

    self:RegisterForEvents()
end

function ZO_GenericSelector_Shared:OnDeferredInitialize()
    self:InitializeControls()
    self:InitializeGridList()
    self:InitializeKeybindStripDescriptor()
end

function ZO_GenericSelector_Shared:InitializeControls()
    local control = self.control
    self.titleLabel = control:GetNamedChild("Title")

    self.gridListControl = control:GetNamedChild("List")
end

function ZO_GenericSelector_Shared:InitializeKeybindStripDescriptor()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,
        {
            name = function()
                local selected = self.focusGridEntry and self.focusGridEntry:IsSelected()
                local keybindString = selected and SI_GAMEPAD_DESELECT_OPTION or SI_GAMEPAD_SELECT_OPTION
                return GetString(keybindString)
            end,
            keybind = "UI_SHORTCUT_PRIMARY",
            clickSound = SOUNDS.GENERIC_SELECTOR_CHOICE_SELECTED,
            callback = function()
                self:ToggleItemSelected(self.focusGridEntry)
            end,
            visible = function()
                return self.focusGridEntry ~= nil
            end,
            enabled = function()
                if IsViewGenericSelectionMenuAvailable() then
                    return false
                end
                local selected = self.focusGridEntry and self.focusGridEntry:IsSelected()
                if selected then
                    return true
                end
                local numCurrentSelections = GetNumGenericSelectorSelectedChoices()
                return numCurrentSelections == 0 or (numCurrentSelections >= GetMinGenericSelectorChoices() and numCurrentSelections <= GetMaxGenericSelectorChoices())
            end,
        },
        {
            name = function()
                local numCurrentSelections = GetNumGenericSelectorSelectedChoices()
                local minSelections = GetMinGenericSelectorChoices()
                local maxSelections = GetMaxGenericSelectorChoices()
                if IsViewGenericSelectionMenuAvailable() or (minSelections == maxSelections and (numCurrentSelections ~= 0 and numCurrentSelections ~= minSelections)) then
                    return GetString(SI_DIALOG_CLOSE)
                else
                    return GetString(SI_GENERIC_SELECTOR_SAVE_CLOSE)
                end
            end,
            keybind = "UI_SHORTCUT_NEGATIVE",
            clickSound = SOUNDS.GENERIC_SELECTOR_SUBMIT_CHOICES,
            callback = function()
                ConfirmGenericSelectionPrompt()
                GENERIC_SELECTOR_HUD_TRACKER:Update()
            end,
        }
    }
end

function ZO_GenericSelector_Shared:RegisterForEvents()
    local function OnGenericSelectionPromptShow()
        SYSTEMS:ShowScene("genericSelector")
    end

    local function OnGenericSelectionPromptHide()
        SYSTEMS:HideScene("genericSelector")
    end

    EVENT_MANAGER:RegisterForEvent("GenericSelector", EVENT_GENERIC_SELECTION_PROMPT_SHOW, ZO_GetEventForwardingFunction(self, OnGenericSelectionPromptShow))
    EVENT_MANAGER:RegisterForEvent("GenericSelector", EVENT_GENERIC_SELECTION_PROMPT_HIDE, ZO_GetEventForwardingFunction(self, OnGenericSelectionPromptHide))
end

function ZO_GenericSelector_Shared:OnShowing()
    self:RefreshItems()
    self:RefreshTitle()
    KEYBIND_STRIP:RemoveDefaultExit()
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_GenericSelector_Shared:OnHiding()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
    KEYBIND_STRIP:RestoreDefaultExit()
end

function ZO_GenericSelector_Shared:SetupGridEntry(control, data)
    control.owner = self
    control:Layout(data)
end

function ZO_GenericSelector_Shared:ResetGridEntry(control)
    ZO_ObjectPool_DefaultResetControl(control)
    control:Reset()
end

function ZO_GenericSelector_Shared:RefreshItems()
    local gridList = self.gridList
    gridList:ClearGridList()
    self.entryDataObjectPool:ReleaseAllObjects()
    local gridEntryTemplateName = self.gridEntryTemplateName
    local numGenericSelectorItems = GetNumGenericSelectorChoices()
    for itemIndex = 1, numGenericSelectorItems do
        local selected = IsGenericSelectorChoiceSelectedAtIndex(itemIndex)

        local highlightTexture = DEFAULT_HIGHLIGHT

        if HasGenericSelectorChoiceSelectionHighlightOverrideAtIndex(itemIndex) then
            highlightTexture = GetGenericSelectorChoiceSelectionHighlightOverrideAtIndex(itemIndex)
        end

        local itemData =
        {
            index = itemIndex,
            name = GetGenericSelectorChoiceNameAtIndex(itemIndex),
            icon = GetGenericSelectorChoiceIconAtIndex(itemIndex),
            highlightTexture = highlightTexture,
            selected = selected,
        }
        local entryData = ZO_GridSquareEntryData_Shared:New(itemData)
        local itemEntry = self.entryDataObjectPool:AcquireObject()
        itemEntry:SetDataSource(entryData)
        gridList:AddEntry(itemEntry, gridEntryTemplateName)
    end
    gridList:CommitGridList()
end

function ZO_GenericSelector_Shared:RefreshTitle()
    local minSelections = GetMinGenericSelectorChoices()
    local maxSelections = GetMaxGenericSelectorChoices()
    internalassert(maxSelections > minSelections, "Maximum number of generic selector choices must be greater than the minimum.")
    local titleText
    if minSelections == maxSelections then
        titleText = zo_strformat(SI_GENERIC_SELECTOR_CHOOSE_X, maxSelections)
    elseif minSelections == 0 then
        titleText = zo_strformat(SI_GENERIC_SELECTOR_CHOOSE_UP_TO_X, maxSelections)
    else
        titleText = zo_strformat(SI_GENERIC_SELECTOR_CHOOSE_AT_LEAST_X, minSelections)
    end
    self.titleLabel:SetText(titleText)
end

function ZO_GenericSelector_Shared:RefreshKeybinds()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_GenericSelector_Shared:ToggleItemSelected(itemControl)
    itemControl:SetSelected(not itemControl:IsSelected())
    self:RefreshKeybinds()
end

function ZO_GenericSelector_Shared:SetGridEntryFocus(control, isFocus)
    if not isFocus then
        self.focusGridEntry = nil
    end

    if control then
        if isFocus then
            self.focusGridEntry = control
        end
    end
end

function ZO_GenericSelector_Shared:OnGenericSelectorChoicesReceived()
    SYSTEMS:ShowScene("genericSelector")
end

ZO_GenericSelector_Shared:MUST_IMPLEMENT("GetSceneName")
ZO_GenericSelector_Shared:MUST_IMPLEMENT("InitializeGridList")