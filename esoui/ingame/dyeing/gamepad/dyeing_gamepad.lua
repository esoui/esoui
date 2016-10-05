-- Icons
local CHECKED_ICON = "EsoUI/Art/Inventory/Gamepad/gp_inventory_icon_equipped.dds"
local UNCHECKED_ICON = nil

local SWAP_EQUIPMENT_ICON = "EsoUI/Art/Inventory/GamePad/gp_inventory_icon_apparel.dds"
local SWAP_SAVED_ICON = "EsoUI/Art/Dye/GamePad/Dye_set_icon.dds"

local MONO_COLOR_CENTER_SWATCH = "EsoUI/Art/Dye/Gamepad/gp_colorSelector_monoPoint.dds"
local NO_COLOR_CENTER_SWATCH = "EsoUI/Art/Dye/Gamepad/gp_colorSelector_monoCopy.dds"
local MONO_COLOR_CENTER_SWATCH_NO_POINT = "EsoUI/Art/Dye/Gamepad/gp_colorSelector_monoRound.dds"

local PRIMARY_COLOR_SWATCH_POINT = "EsoUI/Art/Dye/Gamepad/gp_colorSelector_triPoint.dds"
local PRIMARY_COLOR_SWATCH_NO_POINT = "EsoUI/Art/Dye/Gamepad/gp_colorSelector_triTop.dds"

-- Modes
local SELECTION_DYE = "Dye"                                 -- Selecting a dye swatch.
local SELECTION_SAVED = "Saved"                             -- Selecting a saved set to apply.
local SELECTION_SLOT = "Slot"                               -- Selecting a dyeable slot to apply a dye or saved set to, or to retrieve a dye to select.
local SELECTION_SLOT_COLOR = "Slot Color"                   -- Selecting a color slot on a dyeable slot to apply a dye to, or to retrieve a dye to select.
local SELECTION_SLOT_MULTICOLOR = "Slot Multiple Color"     -- Selecting a color slot on all dyeable slots to apply a dye to, or to retrieve a dye to select.
local SELECTION_SAVED_LIST = "Saved List"                   -- A seperate list of Presets you can select and choose colors from, and set while in Saved Swatch mode.
local SELECTION_SAVED_SWATCH = "Saved Swatch"               -- A swatch of dyes you can select to put into the preset slot you just selected in Saved List mode.
-- Tabs
local DYE_TAB_INDEX = 1
local FILL_SET_TAB_INDEX = 2
local FILL_TAB_INDEX = 3
local ERASE_TAB_INDEX = 4
local SAMPLE_TAB_INDEX = 5

-- General variables
local RETAIN_SELECTIONS = true
local CHECK_SLOT = true
local CHECK_CHANNEL = true

-- Interact Scenes
local GAMEPAD_DYEING_ROOT_SCENE_NAME = "gamepad_dyeing_root"
local GAMEPAD_DYEING_ITEMS_SCENE_NAME = "gamepad_dyeing_items"

local MODE_TO_SCENE_NAME =
{
    [DYE_MODE_SELECTION] = GAMEPAD_DYEING_ROOT_SCENE_NAME,
    [DYE_MODE_EQUIPMENT] = GAMEPAD_DYEING_ITEMS_SCENE_NAME,
    [DYE_MODE_COLLECTIBLE] = GAMEPAD_DYEING_ITEMS_SCENE_NAME,
}

-- Tool Tip Styles
local ZO_Dyeing_Gamepad_Tooltip_Styles = ZO_ShallowTableCopy(ZO_TOOLTIP_STYLES)

ZO_Dyeing_Gamepad_Tooltip_Styles.tooltip = ZO_ShallowTableCopy(ZO_Dyeing_Gamepad_Tooltip_Styles.tooltip)
ZO_Dyeing_Gamepad_Tooltip_Styles.tooltip.width = 789

ZO_Dyeing_Gamepad_Tooltip_Styles.title = ZO_ShallowTableCopy(ZO_Dyeing_Gamepad_Tooltip_Styles.title)
ZO_Dyeing_Gamepad_Tooltip_Styles.title.horizontalAlignment = TEXT_ALIGN_CENTER

ZO_Dyeing_Gamepad_Tooltip_Styles.baseStatsSection = ZO_ShallowTableCopy(ZO_Dyeing_Gamepad_Tooltip_Styles.baseStatsSection)
ZO_Dyeing_Gamepad_Tooltip_Styles.baseStatsSection.layoutPrimaryDirectionCentered = true
ZO_Dyeing_Gamepad_Tooltip_Styles.baseStatsSection.paddingTop = 20
ZO_Dyeing_Gamepad_Tooltip_Styles.baseStatsSection.childSpacing = 35
ZO_Dyeing_Gamepad_Tooltip_Styles.baseStatsSection.customSpacing = nil

ZO_Dyeing_Gamepad_Tooltip_Styles.conditionOrChargeBarSection = ZO_ShallowTableCopy(ZO_Dyeing_Gamepad_Tooltip_Styles.conditionOrChargeBarSection)
ZO_Dyeing_Gamepad_Tooltip_Styles.conditionOrChargeBarSection.layoutPrimaryDirectionCentered = true
ZO_Dyeing_Gamepad_Tooltip_Styles.conditionOrChargeBarSection.paddingTop = 10
ZO_Dyeing_Gamepad_Tooltip_Styles.conditionOrChargeBarSection.customSpacing = nil
ZO_Dyeing_Gamepad_Tooltip_Styles.conditionOrChargeBarSection.widthPercent = 100

-- The main class.
local ZO_Dyeing_Gamepad = ZO_Object:Subclass()

function ZO_Dyeing_Gamepad:New(...)
    local dyeing = ZO_Object.New(self)
    dyeing:Initialize(...)
    return dyeing
end

function ZO_Dyeing_Gamepad:Initialize(control)
    self.control = control
    self.header = control:GetNamedChild("HeaderContainer"):GetNamedChild("Header")

    GAMEPAD_DYEING_ROOT_SCENE = ZO_InteractScene:New(GAMEPAD_DYEING_ROOT_SCENE_NAME, SCENE_MANAGER, ZO_DYEING_STATION_INTERACTION)
    GAMEPAD_DYEING_ITEMS_SCENE = ZO_InteractScene:New(GAMEPAD_DYEING_ITEMS_SCENE_NAME, SCENE_MANAGER, ZO_DYEING_STATION_INTERACTION)

    self:InitializeModeList()
    self:InitializeKeybindStripDescriptorsRoot()

    local function OnBlockingSceneActivated()
        self:AttemptExit()
    end

    SYSTEMS:RegisterGamepadRootScene("dyeing", GAMEPAD_DYEING_ROOT_SCENE)

    self.dyeItemsPanel = ZO_Dyeing_Slots_Panel_Gamepad:New(self.control:GetNamedChild("DyeItems"), self, GAMEPAD_DYEING_ITEMS_SCENE)

    ZO_GamepadGenericHeader_Initialize(self.header, ZO_GAMEPAD_HEADER_TABBAR_CREATE)

    self.headerData =
    {  
        titleText = GetString(SI_GAMEPAD_DYEING_ROOT_TITLE)
    }

    GAMEPAD_DYEING_ROOT_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            self:SetMode(DYE_MODE_SELECTION)
            self.modeList:Activate()
            local currentlySelectedData = self.modeList:GetTargetData()
            self:UpdateOptionLeftTooltip(currentlySelectedData.mode)
            MAIN_MENU_MANAGER:SetBlockingScene(GAMEPAD_DYEING_ROOT_SCENE_NAME, OnBlockingSceneActivated)
            KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptorRoot)
            ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)
            TriggerTutorial(TUTORIAL_TRIGGER_DYEING_OPENED)
        elseif newState == SCENE_HIDDEN then
            self.modeList:Deactivate()
            ZO_GamepadGenericHeader_Deactivate(self.header)
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptorRoot)
            MAIN_MENU_MANAGER:ClearBlockingScene(OnBlockingSceneActivated)
        end
    end)
end

function ZO_Dyeing_Gamepad:SetMode(mode)
    if self.mode ~= mode then
        self.mode = mode
        InitializePendingDyes(mode)
        SCENE_MANAGER:Push(MODE_TO_SCENE_NAME[mode])
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptorRoot)
    end
end

function ZO_Dyeing_Gamepad:GetMode()
    return self.mode
end

local function ZO_DyeingGamepadRootEntry_OnSetup(control, data, selected, selectedDuringRebuild, enabled, activated)
    ZO_SharedGamepadEntry_OnSetup(control, data, selected, selectedDuringRebuild, enabled, activated)
    if data.mode == DYE_MODE_COLLECTIBLE and not CanUseCollectibleDyeing() then
        if selected then
            control.label:SetColor(ZO_NORMAL_TEXT:UnpackRGBA())
        else
            control.label:SetColor(ZO_GAMEPAD_DISABLED_UNSELECTED_COLOR:UnpackRGBA())
        end
    end
end

function ZO_Dyeing_Gamepad:InitializeModeList()
    self.modeList = ZO_GamepadVerticalItemParametricScrollList:New(self.control:GetNamedChild("Mask"):GetNamedChild("Container"):GetNamedChild("RootList"))
    self.modeList:SetAlignToScreenCenter(true)
    self.modeList:AddDataTemplate("ZO_GamepadItemEntryTemplate", ZO_DyeingGamepadRootEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)

    local function AddEntry(name, mode, icon)
        local data = ZO_GamepadEntryData:New(GetString(name), icon)
        data:SetIconTintOnSelection(true)
        data.mode = mode
        self.modeList:AddEntry("ZO_GamepadItemEntryTemplate", data)
    end

    self.modeList:SetOnSelectedDataChangedCallback(
        function(list, selectedData)
            self.currentlySelectedOptionData = selectedData
            self:UpdateOptionLeftTooltip(selectedData.mode)
            KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptorRoot)
        end
    )

    self.modeList:Clear()
    AddEntry(SI_DYEING_DYE_EQUIPMENT_TAB, DYE_MODE_EQUIPMENT, "EsoUI/Art/Dye/Gamepad/dye_tabIcon_EQUIPMENTDye.dds")
    AddEntry(SI_DYEING_DYE_COLLECTIBLE_TAB, DYE_MODE_COLLECTIBLE, "EsoUI/Art/Dye/Gamepad/dye_tabIcon_costumeDye.dds")
    self.modeList:Commit()
end

function ZO_Dyeing_Gamepad:UpdateOptionLeftTooltip(mode)
    if mode == DYE_MODE_EQUIPMENT then
        GAMEPAD_TOOLTIPS:LayoutTitleAndDescriptionTooltip(GAMEPAD_LEFT_TOOLTIP, GetString(SI_DYEING_DYE_EQUIPMENT_TAB), GetString(SI_GAMEPAD_DYEING_EQUIPMENT_DESCRIPTION))
    elseif mode == DYE_MODE_COLLECTIBLE then
        local descriptionOne
        local descriptionTwo
        if CanUseCollectibleDyeing() then
            descriptionOne = ZO_DEFAULT_ENABLED_COLOR:Colorize(GetString(SI_ESO_PLUS_STATUS_UNLOCKED))
            descriptionTwo = GetString(SI_DYEING_COLLECTIBLE_TAB_DESCRIPTION_UNLOCKED)
        else
            descriptionOne = ZO_DEFAULT_ENABLED_COLOR:Colorize(GetString(SI_ESO_PLUS_STATUS_LOCKED))
            descriptionTwo = GetString(SI_DYEING_COLLECTIBLE_TAB_DESCRIPTION_LOCKED)
        end
        GAMEPAD_TOOLTIPS:LayoutTitleAndMultiSectionDescriptionTooltip(GAMEPAD_LEFT_TOOLTIP, GetString(SI_DYEING_DYE_COLLECTIBLE_TAB), descriptionOne, descriptionTwo)
    end
end

function ZO_Dyeing_Gamepad:InitializeKeybindStripDescriptorsRoot()
    self.keybindStripDescriptorRoot =
    {
        -- Select mode.
        {
            keybind = "UI_SHORTCUT_PRIMARY",
            alignment = KEYBIND_STRIP_ALIGN_LEFT,

            name = function()
                return GetString(SI_GAMEPAD_SELECT_OPTION)
            end,
        
            callback = function()
                local targetData = self.modeList:GetTargetData()
                self:SetMode(targetData.mode)
            end,
            visible = function()
                local targetData = self.modeList:GetTargetData()
                if targetData.mode == DYE_MODE_COLLECTIBLE then
                    return CanUseCollectibleDyeing()
                end
                return true
            end
        },
    }

    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.keybindStripDescriptorRoot, GAME_NAVIGATION_TYPE_BUTTON)
    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.keybindStripDescriptorRoot, self.modeList)
end

function ZO_Dyeing_Gamepad:CancelExit()
    MAIN_MENU_MANAGER:CancelBlockingSceneNextScene()
end

function ZO_Dyeing_Gamepad:ExitWithoutSave()
    SCENE_MANAGER:HideCurrentScene()
end

function ZO_Dyeing_Gamepad:UndoPendingChanges()
    InitializePendingDyes(self.mode)
    PlaySound(SOUNDS.DYEING_UNDO_CHANGES)
end

function ZO_Dyeing_Gamepad:AttemptExit()
    self:ExitWithoutSave()
end

function ZO_Dyeing_Gamepad:ConfirmCommitSelection()
    self.dyeItemsPanel:ConfirmCommitSelection()
end

--[[ ZO_Dyeing_Slots_Panel_Gamepad ]]--

ZO_Dyeing_Slots_Panel_Gamepad = ZO_Object:Subclass()

function ZO_Dyeing_Slots_Panel_Gamepad:New(...)
    local dyeItems = ZO_Object.New(self)
    dyeItems:Initialize(...)
    return dyeItems
end

function ZO_Dyeing_Slots_Panel_Gamepad:Initialize(control, owner, scene)
    self.control = control
    self.owner = owner
    self.scene = scene

    scene:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            self.mode = self.owner:GetMode()
            self:PerformDeferredInitialization()
            self:ActivateDyeItemsHeader()
            self.dyeableSlotsMenu:SetMode(self.mode)
            self.dyeableSlotsMenu:Show()
            self.visibleRadialMenu = self.dyeableSlotsMenu
            self:SwitchToTab(DYE_TAB_INDEX)
            self:SwitchToTool(self.dyeTool)
            self:RefreshSavedSets()
            KEYBIND_STRIP:RemoveDefaultExit()
            KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
            DIRECTIONAL_INPUT:Activate(self, self.control)
        elseif newState == SCENE_HIDDEN then
            local RETAIN_BACKGROUND_FOCUS = true
            self:ResetScreen(nil, RETAIN_BACKGROUND_FOCUS)
            self.dyeableSlotsMenu:ResetToDefaultPositon()
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
            KEYBIND_STRIP:RestoreDefaultExit()
            DIRECTIONAL_INPUT:Deactivate(self)
            if self.isSpinning then
                EndInteractCameraSpin()
                self.isSpinning = false
            end
            ZO_SavePlayerConsoleProfile()
        end
    end)

    local ALWAYS_ANIMATE = true
    GAMEPAD_DYEING_CONVEYOR_FRAGMENT = ZO_ConveyorSceneFragment:New(control:GetNamedChild("LeftPaneDyeContainer"), ALWAYS_ANIMATE)
    GAMEPAD_DYEING_SET_PRESET_CONVEYOR_FRAGMENT = ZO_ConveyorSceneFragment:New(control:GetNamedChild("LeftPanePresetContainer"), ALWAYS_ANIMATE)
    GAMEPAD_DYEING_RIGHT_RADIAL_FRAGMENT = ZO_FadeSceneFragment:New(control:GetNamedChild("RightPaneRadialContainer"), ALWAYS_ANIMATE)
    GAMEPAD_DYEING_RIGHT_SWATCHES_FRAGMENT = ZO_FadeSceneFragment:New(control:GetNamedChild("RightPanePresetDyesContainer"), ALWAYS_ANIMATE)
end

function ZO_Dyeing_Slots_Panel_Gamepad:InitializeKeybindDescriptors()
    -- Main list.
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        -- Back
        KEYBIND_STRIP:GenerateGamepadBackButtonDescriptor(function() self:NavigateBack() end),

        -- Select
        {
            name = GetString(SI_GAMEPAD_SELECT_OPTION),
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function() self:ActivateCurrentSelection() end,
            visible = function() return self:CanViewCurrentSelection() end,
            enabled = function() return self:CanActivateCurrentSelection() end,
        },

        -- Apply
        {
            name = GetString(SI_DYEING_COMMIT),
            keybind = "UI_SHORTCUT_SECONDARY",
            callback = function() self:CommitSelection() end,
            visible = function() return ZO_Dyeing_AreTherePendingDyes(self.mode) end,
        },

        -- Options
        {
            name = GetString(SI_GAMEPAD_DYEING_OPTIONS),
            keybind = "UI_SHORTCUT_TERTIARY",
            callback = function() ZO_Dialogs_ShowGamepadDialog("DYEING_OPTIONS_GAMEPAD") end,
            visible = function() return (self.selectionMode == SELECTION_DYE) or (self.selectionMode == SELECTION_SAVED) end,
        },

        -- Randomize
        {
            name = GetString(SI_DYEING_RANDOMIZE),
            keybind = "UI_SHORTCUT_RIGHT_STICK",
            callback = function()
                            ZO_Dyeing_UniformRandomize(self.mode, function() return self.dyesList:GetRandomUnlockedDyeId() end)
                            self:OnPendingDyesChanged()
                            self:SetupRandomizeSwatch()
                        end,
            visible = function()
                            return (self.visibleRadialMenu == self.dyeableSlotsMenu) and ((self.selectionMode == SELECTION_DYE) or (self.selectionMode == SELECTION_SAVED)) and (self.dyesList:GetNumUnlockedDyes() > 0)
                      end,
        },

        -- Clear
        {
            name = GetString(SI_DYEING_UNDO),
            keybind = "UI_SHORTCUT_LEFT_STICK",
            callback = function()
                            InitializePendingDyes(self.mode)
                            self:OnPendingDyesChanged()
                            PlaySound(SOUNDS.DYEING_UNDO_CHANGES)
                        end,
            visible = function()
                            return (self.visibleRadialMenu == self.dyeableSlotsMenu) and ZO_Dyeing_AreTherePendingDyes(self.mode)
                      end,
        },

        -- Special exit button
        {
            name = GetString(SI_EXIT_BUTTON),
            keybind = "UI_SHORTCUT_EXIT",
            ethereal = true,
            callback = function() self:AttemptExit() end,
        },
    }
end

function ZO_GamepadDyeingSortRow_Setup(control, data, selected, selectedDuringRebuild, enabled, activated)
    ZO_SharedGamepadEntry_OnSetup(control, data, selected, selectedDuringRebuild, enabled, activated)
    control.dropdown:SetSortsItems(false)

    data.parentObject.currentDropdown = control.dropdown
    data.parentObject:UpdateDyeSortingDropdownOptions(control.dropdown)
end

function ZO_Dyeing_Slots_Panel_Gamepad:OnDropdownDeactivated()
    self:ActivateMainList()
end


function ZO_Dyeing_Slots_Panel_Gamepad:UpdateDyeSortingDropdownOptions(dropdown)
    dropdown:ClearItems()

    local function SelectNewSort(style)
        self.savedVars.sortStyle = style
        ZO_DYEING_MANAGER:UpdateAllDyeLists()
        self.rightPaneDyesList:RefreshDyeLayout()
    end

    dropdown:AddItem(ZO_ComboBox:CreateItemEntry(GetString(SI_DYEING_SORT_BY_RARITY), function() SelectNewSort(ZO_DYEING_SORT_STYLE_RARITY) end), ZO_COMBOBOX_SUPRESS_UPDATE)
    dropdown:AddItem(ZO_ComboBox:CreateItemEntry(GetString(SI_DYEING_SORT_BY_HUE), function() SelectNewSort(ZO_DYEING_SORT_STYLE_HUE) end), ZO_COMBOBOX_SUPRESS_UPDATE)

    dropdown:UpdateItems()

    self:UpdateDyeSortingDropdownSelection(dropdown)
end

function ZO_Dyeing_Slots_Panel_Gamepad:UpdateDyeSortingDropdownSelection(dropdown)
    local currentSortingStyle = self.savedVars.sortStyle
    if currentSortingStyle == ZO_DYEING_SORT_STYLE_RARITY then
        dropdown:SetSelectedItemText(GetString(SI_DYEING_SORT_BY_RARITY))
    elseif currentSortingStyle == ZO_DYEING_SORT_STYLE_HUE then
        dropdown:SetSelectedItemText(GetString(SI_DYEING_SORT_BY_HUE))
    end
end

function ZO_Dyeing_Slots_Panel_Gamepad:InitializeOptionsDialog()
    local showLockedEntry = ZO_GamepadEntryData:New(GetString(SI_DYEING_SHOW_LOCKED))
    local sortListEntry = ZO_GamepadEntryData:New("")

    local function ActivateDropdown()
        if(self.currentDropdown ~= nil) then
            self.currentDropdown:Activate()

            local currentSortingStyleIndex = self.savedVars.sortStyle
            self.currentDropdown:SetHighlightedItem(currentSortingStyleIndex)
        end
    end

    local function ReleaseDialog()
        ZO_Dialogs_ReleaseDialogOnButtonPress("DYEING_OPTIONS_GAMEPAD")
    end 

    sortListEntry.parentObject = self
    sortListEntry.setup = ZO_GamepadDyeingSortRow_Setup
    sortListEntry.callback = function() ActivateDropdown(sortListEntry.parentObject) end

    showLockedEntry.setup = ZO_GamepadCheckBoxTemplate_Setup
    showLockedEntry.checked = self.savedVars.showLocked
    showLockedEntry.callback = function(dialog)
            local targetControl = dialog.entryList:GetTargetControl()
            ZO_GamepadCheckBoxTemplate_OnClicked(targetControl)
            local showLocked = not self.savedVars.showLocked
            self.savedVars.showLocked = showLocked
            showLockedEntry.checked = self.savedVars.showLocked
            ZO_DYEING_MANAGER:UpdateAllDyeLists()
            self.rightPaneDyesList:RefreshDyeLayout()
        end

    ZO_Dialogs_RegisterCustomDialog("DYEING_OPTIONS_GAMEPAD",
    {
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
        },

        blockDialogReleaseOnPress = true,
        setup = function(dialog)
            showLockedEntry.checked = self.savedVars.showLocked
            dialog:setupFunc()
        end,

        title =
        {
            text = GetString(SI_GAMEPAD_DYEING_OPTIONS_TITLE),
        },
        parametricList =
        {
            {
                template = "ZO_Gamepad_Dropdown_Item_Indented",
                entryData = sortListEntry,
                header = GetString(SI_GAMEPAD_DYEING_SORT_OPTION_HEADER),
            },
            {
                template = "ZO_CheckBoxTemplate_Gamepad",
                entryData = showLockedEntry,
            },
        },
        buttons =
        {
            {
                keybind = "DIALOG_PRIMARY",
                text = SI_GAMEPAD_SELECT_OPTION,
                callback =  function(dialog)
                    local data = dialog.entryList:GetTargetData()
                    if data.callback then
                        data.callback(dialog)
                    end
                end,
                clickSound = SOUNDS.DIALOG_ACCEPT,
            },
            {
                keybind = "DIALOG_NEGATIVE",
                text = SI_DIALOG_CANCEL,
                callback = ReleaseDialog,
            },
        }
    })
end

function ZO_Dyeing_Slots_Panel_Gamepad:RefreshSavedSet(dyeSetIndex)
    local selectedSavedSet = self:GetSelectedSavedSetIndex()

    local savedSetSwatch = self.savedSets[dyeSetIndex]
    for dyeChannel, dyeControl in ipairs(savedSetSwatch.dyeControls) do
        local currentDyeId = select(dyeChannel, GetSavedDyeSetDyes(dyeSetIndex))
        ZO_DyeingUtils_SetSlotDyeSwatchDyeId(dyeChannel, dyeControl, currentDyeId)
    end

    if selectedSavedSet == dyeSetIndex then
        self:SetupCenterSwatch()
    end
end

function ZO_Dyeing_Slots_Panel_Gamepad:RefreshSavedSets()
    local selectedSavedSet = self:GetSelectedSavedSetIndex()

    for dyeSetIndex=1, GetNumSavedDyeSets() do
        self:RefreshSavedSet(dyeSetIndex)
    end

    if selectedSavedSet then
        self:SetupCenterSwatch()
    end
end

function ZO_Dyeing_Slots_Panel_Gamepad:SetupColorPresetControls(parent)
    local previous = parent:GetNamedChild("BaseAnchor")
    self.savedSets = {}
    self.savedSetFocusList = ZO_GamepadFocus:New(self.control, nil, MOVEMENT_CONTROLLER_DIRECTION_HORIZONTAL)
    self.savedSetFocusList:SetFocusChangedCallback(function(...) self:SavedSetSelected(...) end)

    local numSavedSets = GetNumSavedDyeSets()
    local padding
    for i=1, numSavedSets do
        local newControl = CreateControlFromVirtual("$(parent)Preset", parent, "ZO_DyeingSwatchPreset_Gamepad", i)
        if not padding then
            local controlWidth = newControl:GetDimensions()
            local parentWidth = parent:GetDimensions()
            local availableWidth = parentWidth - (controlWidth * numSavedSets)
            padding = availableWidth / (numSavedSets + 1) -- We want padding on left and right.
        end

        newControl:SetAnchor(TOPLEFT, previous, TOPRIGHT, padding, 0)
        self.savedSets[i] = newControl
        newControl.savedSetIndex = i
        previous = newControl

        self:RefreshSavedSet(i)
        local entry = {
                        control = newControl,
                        highlight = newControl:GetNamedChild("Highlight"),
                    }
        self.savedSetFocusList:AddEntry(entry)
    end
end

function ZO_Dyeing_Slots_Panel_Gamepad:SavedSetSelected(control)
    self:RefreshKeybindStrip()
    if control then
        self.leftTipTitle:SetText(GetString(SI_GAMEPAD_DYEING_SETS_TITLE))
        self.leftTipBody:SetText(GetString(SI_GAMEPAD_DYEING_SETS_TOOLTIP))
    elseif self.selectionMode == SELECTION_SAVED then
        self.leftTipTitle:SetText("")
        self.leftTipBody:SetText(GetString(SI_DYEING_NO_MATCHING_DYES))
    end
end

function ZO_Dyeing_Slots_Panel_Gamepad:PerformDeferredInitialization()
    if self.initialized then return end
    self.initialized = true

    -- Saved Variables
    self.savedVars = ZO_SavedVars:New("ZO_Ingame_SavedVariables", 1, "Dyeing", ZO_DYEING_SAVED_VARIABLES_DEFAULTS)

    -- Misc.
    self:InitializeKeybindDescriptors()
    self:InitializeOptionsDialog()
    self.isSpinning = false

    self.savedSetsMovementOutController = ZO_MovementController:New(MOVEMENT_CONTROLLER_DIRECTION_VERTICAL)

    -- Basic controls
    local leftPane = self.control:GetNamedChild("LeftPane")
    self.leftPaneControl = leftPane
    local rightPane = self.control:GetNamedChild("RightPane")
    self.rightPaneControl = rightPane
    self.rightRadialContainer = rightPane:GetNamedChild("RadialContainer")
    local dyesControl = leftPane:GetNamedChild("DyeContainer"):GetNamedChild("Dyes")

    -- Color Presets
    self:SetupColorPresetControls(dyesControl:GetNamedChild("SavedSets"))

    -- Left tooltip
    local leftToolTip = dyesControl:GetNamedChild("Tooltip")
    self.leftTipTitle = leftToolTip:GetNamedChild("Title")
    self.leftTipBody = leftToolTip:GetNamedChild("Body")

    -- Right tooltip
    local rightToolTip = self.rightRadialContainer:GetNamedChild("Tooltip")
    self.rightTipImage = rightToolTip:GetNamedChild("Image")
    self.rightTipSwap = rightToolTip:GetNamedChild("Arrow")
    self.rightTipContents = rightToolTip:GetNamedChild("Contents")
    ZO_Tooltip:Initialize(self.rightTipContents, ZO_Dyeing_Gamepad_Tooltip_Styles)

    -- Tools
    self.dyeTool = ZO_DyeingToolDye:New(self)
    self.fillTool = ZO_DyeingToolFill:New(self)
    self.eraseTool = ZO_DyeingToolErase:New(self)
    self.sampleTool = ZO_DyeingToolSample:New(self)
    self.setFillTool = ZO_DyeingToolSetFill:New(self)

    local _, keyCode = ZO_Keybindings_GetHighestPriorityBindingStringFromAction("UI_SHORTCUT_PRIMARY", nil, nil, true)
    local keybindIcon = GetGamepadIconPathForKeyCode(keyCode)

    -- Dyeable Slots Sheet    
    self.centerSwatch = self.rightRadialContainer:GetNamedChild("CenterSwatch")  
    self.centerSwatch:GetNamedChild("Keybind"):SetTexture(keybindIcon)
    local dyeableSlotsSheet = self.rightRadialContainer:GetNamedChild("DyeableSlotsSheet")    
    self.dyeableSlotsMenu = ZO_Dyeing_Slots_Gamepad:New(dyeableSlotsSheet, radialSharedHighlight)
    self.dyeableSlotsMenu:SetSelectionChangedCallback(function() self:RefreshKeybindStrip() end)
    self.dyeableSlotsMenu:SetOnSelectionChangedCallback(function(...) self:RadialMenuSelectionChanged(...) end)

    local function UpdateRotation(rotation)
        if (self.activeTool == self.dyeTool) or (self.activeTool == self.fillTool) 
            or (self.activeTool == self.eraseTool) or (self.activeTool == self.sampleTool) then
            self.centerSwatch:SetTextureRotation(rotation)
        elseif self.activeTool == self.setFillTool then
            local dyeControls = self.centerSwatchSaved.dyeControls
            for i=1, #dyeControls do
                dyeControls[i]:SetTextureRotation(rotation)
            end
        end
    end

    self.dyeableSlotsMenu:SetOnUpdateRotationFunction(UpdateRotation)
    self.visibleRadialMenu = self.dyeableSlotsMenu

    -- Saved Slots Sheet
    self.centerSwatchSaved = self.rightRadialContainer:GetNamedChild("CenterSwatchSaved")  
    self.centerSwatchSaved:GetNamedChild("Keybind"):SetTexture(keybindIcon) 

    -- Dyeable Slots/Saved Slot Multi-Select
    local function HighlightAllSlots(entry)
        local slotIndex = entry and entry.slotIndex
        self.visibleRadialMenu:HighlightAll(slotIndex)
    end
    self.channelMultiFocus = ZO_GamepadFocus:New(self.control, nil, MOVEMENT_CONTROLLER_DIRECTION_HORIZONTAL)
    self.channelMultiFocus:SetFocusChangedCallback(HighlightAllSlots)
    for i = 1, 3 do
        local entry = {slotIndex = i}
        self.channelMultiFocus:AddEntry(entry)
    end

    -- Dye Layout
    self.swatchesContainer = dyesControl:GetNamedChild("Scroll"):GetNamedChild("Container"):GetNamedChild("List")
    local dyesSharedHighlight = dyesControl:GetNamedChild("SharedHighlight")
    self.dyesList = ZO_Dyeing_Swatches_Gamepad:New(self, self.swatchesContainer, dyesSharedHighlight, self.savedVars, function(...) self:OnDyeSelectionChanged(...) end, function(...) self:OnDyeListMoveOut(...) end, self.savedSetsMovementOutController)
    self.control:RegisterForEvent(EVENT_UNLOCKED_DYES_UPDATED, function() self:UpdateUnlockedDyes() end)
    ZO_DYEING_MANAGER:RegisterForDyeListUpdates(function() self.dyesList:RefreshDyeLayout() end)

    --Preset stuff
    self.rightPaneSwatches = self.control:GetNamedChild("RightPane"):GetNamedChild("PresetDyesContainer")
    local presetSwatchesContainer = self.rightPaneSwatches:GetNamedChild("Scroll"):GetNamedChild("Container"):GetNamedChild("List")
    local presetSwatchesSharedHighlight = self.rightPaneSwatches:GetNamedChild("SharedHighlight")
    self.rightPaneDyesList = ZO_Dyeing_Swatches_Gamepad:New(self, presetSwatchesContainer, presetSwatchesSharedHighlight, self.savedVars, function() self:RefreshKeybindStrip() end)
    
    local leftPanePresetsList = leftPane:GetNamedChild("PresetContainer"):GetNamedChild("SetPresets"):GetNamedChild("List")
    self.setPresestList = ZO_GamepadVerticalItemParametricScrollList:New(leftPanePresetsList)
    self.setPresestList:SetAlignToScreenCenter(true)
    self.setPresestList:SetFixedCenterOffset(-25)

    local function PresetListSetupFunction(control, data, selected, reselectingDuringRebuild, enabled, active)       
        control.multiFocusControl.label:SetText(data.name)
        self:RefreshPresetListEntry(control, data.dyeSetIndex)

        SetDefaultColorOnLabel(control.multiFocusControl.label, selected)
        if selected then
            if self.lastSelectedControl then
                self.lastSelectedControl:Deactivate()
            end
            control:Activate()
            self.lastSelectedControl = control
        end
    end

    self.setPresestList:AddDataTemplate("ZO_DyeSavedPresetEntry", PresetListSetupFunction, ZO_GamepadMenuEntryTemplateParametricListFunction) --TODO scale function

    for dyeSetIndex=1, GetNumSavedDyeSets() do
        local data = { name = GetString(_G["SI_GAMEPAD_DYEING_PRESET_"..tostring(dyeSetIndex)]), dyeSetIndex = dyeSetIndex, }
        self.setPresestList:AddEntry("ZO_DyeSavedPresetEntry", data)
    end
    
    self.setPresestList:Commit()
    
    -- Header
    self.header = self.owner.header
    self.headerData =   {
                            tabBarEntries = {
                                {
                                    text = GetString(SI_DYEING_TOOL_DYE_TOOLTIP),
                                    callback = function() self:SwitchToTool(self.dyeTool) end,
                                    canSelect = true,
                                },
                                {
                                    text = GetString(SI_DYEING_TOOL_SET_FILL),
                                    callback = function() self:SwitchToTool(self.setFillTool) end,
                                    canSelect = false,
                                },
                                {
                                    text = GetString(SI_DYEING_TOOL_DYE_ALL_TOOLTIP),
                                    callback = function()
                                            self:SwitchToTool(self.fillTool)
                                            self:ShowRadialMenu(self.dyeableSlotsMenu)
                                        end,
                                },
                                {
                                    text = GetString(SI_DYEING_TOOL_ERASE_TOOLTIP),
                                    callback = function() self:SwitchToTool(self.eraseTool) end,
                                },
                                {
                                    text = GetString(SI_DYEING_TOOL_SAMPLE_TOOLTIP),
                                    callback = function() self:SwitchToTool(self.sampleTool) end,
                                },
                                {
                                    text = GetString(SI_GAMEPAD_DYEING_PRESET_TITLE),
                                    callback = function()
                                            self:SwitchToTool(self.dyeTool)
                                            self:SwitchToSetPresetList()
                                            self.setPresestList:RefreshVisible()
                                        end,
                                },
                            },
                        }
end

function ZO_Dyeing_Slots_Panel_Gamepad:ActivateDyeItemsHeader()
    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)
end

local DYEING_PANE_FOCUS_ACTIVATE = true
local DYEING_PANE_FOCUS_DEACTIVATE = false

function ZO_Dyeing_Slots_Panel_Gamepad:OnDyeingPaneFocusChanged(control, activated)
    if not control.focusedChangedAnimation then
        control.focusedChangedAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_GamepadDyeingFocusAnimation", control)
    end
    
    if activated then
        control.focusedChangedAnimation:PlayForward()
    else
        control.focusedChangedAnimation:PlayBackward()
    end
end

function ZO_Dyeing_Slots_Panel_Gamepad:ResetScreen(retainSelections, retainBackgroundFocus)
    -- Clear the selection mode first as it is used in callbacks
    --  made by some of the other calls to determine what to display.
    self.selectionMode = nil

    self.dyeableSlotsMenu:Deactivate(retainSelections)
    self.dyeableSlotsMenu:DefocusAll()
    self.dyesList:Deactivate()
    self.savedSetFocusList:Deactivate()
    self.channelMultiFocus:Deactivate(retainSelections)
    
    self.rightPaneDyesList:Deactivate()
    self.setPresestList:Deactivate()
    if self.lastSelectedControl then
        self.lastSelectedControl:Deactivate()
    end

    if self.activeSlotControl then
        self.activeSlotControl:Deactivate(retainSelections)
        if not retainSelections then
            self.activeSlotControl = nil
        end
    end

    if not retainBackgroundFocus then
        self:OnDyeingPaneFocusChanged(self.leftPaneControl, DYEING_PANE_FOCUS_ACTIVATE)
    end

    if not retainSelections then
        self.visibleRadialMenu:HighlightAll(nil) -- Remove all highlights.
        self:ClearCenterSwatch()
    end

    ZO_GamepadGenericHeader_Activate(self.header)

    self:RadialMenuSelectionChanged(nil)
end


function ZO_Dyeing_Slots_Panel_Gamepad:RefreshPresetListEntry(control, dyeSetIndex)
    for dyeChannel, dyeControl in ipairs(control.dyeControls) do
        local currentDyeId = select(dyeChannel, GetSavedDyeSetDyes(dyeSetIndex))
        ZO_DyeingUtils_SetSlotDyeSwatchDyeId(dyeChannel, dyeControl, currentDyeId)
    end
end

function ZO_Dyeing_Slots_Panel_Gamepad:SwitchToSetPresetList()
    self:ResetScreen()
    
    self.selectionMode = SELECTION_SAVED_LIST

    local selectedControl = self.setPresestList:GetSelectedControl()
    local RETAIN_FOCUS = true
    selectedControl:Activate(RETAIN_FOCUS)
    self.lastSelectedControl = selectedControl

    self.setPresestList:Activate()

    SCENE_MANAGER:AddFragment(GAMEPAD_DYEING_RIGHT_SWATCHES_FRAGMENT)
    SCENE_MANAGER:AddFragment(GAMEPAD_DYEING_SET_PRESET_CONVEYOR_FRAGMENT)
    SCENE_MANAGER:RemoveFragment(GAMEPAD_DYEING_CONVEYOR_FRAGMENT)
    SCENE_MANAGER:RemoveFragment(GAMEPAD_DYEING_RIGHT_RADIAL_FRAGMENT)

    self:RefreshKeybindStrip()

    self:OnDyeingPaneFocusChanged(self.leftPaneControl, DYEING_PANE_FOCUS_ACTIVATE)
end

function ZO_Dyeing_Slots_Panel_Gamepad:SwitchToSetPresetSwatch()
    self.selectionMode = SELECTION_SAVED_SWATCH

    local RETAIN_FOCUS = true
    self.lastSelectedControl:Deactivate(RETAIN_FOCUS)

    self.rightPaneDyesList:Activate()
    self.setPresestList:DeactivateWithoutChangedCallback()

    self:RefreshKeybindStrip()

    self:OnDyeingPaneFocusChanged(self.leftPaneControl, DYEING_PANE_FOCUS_DEACTIVATE)
end



function ZO_Dyeing_Slots_Panel_Gamepad:SwitchToSavedSelection()
    self:ResetScreen()
    self.selectionMode = SELECTION_SAVED
    self.savedSetFocusList:Activate()
    self:RefreshKeybindStrip()

    self:OnDyeingPaneFocusChanged(self.leftPaneControl, DYEING_PANE_FOCUS_ACTIVATE)
end

function ZO_Dyeing_Slots_Panel_Gamepad:SwitchToDyeSelection()
    self:ResetScreen()
    self.selectionMode = SELECTION_DYE
    self.dyesList:Activate()
    self:RefreshKeybindStrip()

   self:OnDyeingPaneFocusChanged(self.leftPaneControl, DYEING_PANE_FOCUS_ACTIVATE)
end

function ZO_Dyeing_Slots_Panel_Gamepad:ShowRadialMenu(menu)
    if self.visibleRadialMenu == menu then return end

    if self.visibleRadialMenu then
        self.visibleRadialMenu:HighlightAll(nil)
        self.visibleRadialMenu:Deactivate()
    end

    self.visibleRadialMenu = menu
    menu:Show()

    local selectedChannelData = self.channelMultiFocus:GetFocusItem()
    local selectedChannel = selectedChannelData and selectedChannelData.slotIndex
    if selectedChannel then
        menu:HighlightAll(selectedChannel)
    end
end

function ZO_Dyeing_Slots_Panel_Gamepad:SwitchToRadialMenu(retainSelections, menu, mode, suppressSound)
    self:ResetScreen(retainSelections)
    self.selectionMode = mode
    menu:Show(suppressSound)
    menu:Activate()
    self.visibleRadialMenu = menu
    self:RefreshKeybindStrip()

    self:OnDyeingPaneFocusChanged(self.leftPaneControl, DYEING_PANE_FOCUS_DEACTIVATE)
end

function ZO_Dyeing_Slots_Panel_Gamepad:SwitchToDyeableSlotsSelection(retainSelections, suppressSound)
    self:SwitchToRadialMenu(retainSelections, self.dyeableSlotsMenu, SELECTION_SLOT, suppressSound)
end

function ZO_Dyeing_Slots_Panel_Gamepad:SwitchToActiveRadialMenuMode(...)
    if self.visibleRadialMenu == self.dyeableSlotsMenu then
        self:SwitchToDyeableSlotsSelection(...)
    else
        -- This case is invalid, and more cases should be
        --  added if additional modes become available.
        assert(false)
    end
end

function ZO_Dyeing_Slots_Panel_Gamepad:SwitchToDyeableSlotDyeSelection(selectedControl)
    local selectedControl = selectedControl or self.dyeableSlotsMenu.selectedControl
    if not selectedControl then return end

    self:ResetScreen(RETAIN_SELECTIONS)

    self.selectionMode = SELECTION_SLOT_COLOR
    selectedControl:Activate()
    self.activeSlotControl = selectedControl

    self:RefreshVisibleRadialMenuSelection()

    self:RefreshKeybindStrip()

    self:OnDyeingPaneFocusChanged(self.leftPaneControl, DYEING_PANE_FOCUS_DEACTIVATE)
end

function ZO_Dyeing_Slots_Panel_Gamepad:SwitchToDyeableSlotDyeMultiSelection(retainPosition)
    self:ResetScreen(RETAIN_SELECTIONS)

    self.centerSwatch:SetTexture(MONO_COLOR_CENTER_SWATCH_NO_POINT)
    self.dyeableSlotsMenu:FocusAll()

    self.selectionMode = SELECTION_SLOT_MULTICOLOR
    if not retainPosition then
        self.channelMultiFocus:SetFocusToFirstEntry()
    end
    self.channelMultiFocus:Activate()
    self.activeSlotControl = self.channelMultiFocus

    self:RefreshVisibleRadialMenuSelection()

    self:RefreshKeybindStrip()

    self:OnDyeingPaneFocusChanged(self.leftPaneControl, DYEING_PANE_FOCUS_DEACTIVATE)
    PlaySound(SOUNDS.RADIAL_MENU_OPEN)
end

function ZO_Dyeing_Slots_Panel_Gamepad:RefreshKeybindStrip()
    if self.keybindStripDescriptor then
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    end
end

function ZO_Dyeing_Slots_Panel_Gamepad:UpdateUnlockedDyes()
    self:RefreshKeybindStrip()
    self.dyesList:RefreshDyeLayout()
    self.rightPaneDyesList:RefreshDyeLayout()
end

function ZO_Dyeing_Slots_Panel_Gamepad:GetSelectedSavedSetIndex()
    local INCLUDE_SAVED_FOCUS = true
    local selectedSavedSet = self.savedSetFocusList:GetFocusItem(INCLUDE_SAVED_FOCUS)
    return selectedSavedSet and selectedSavedSet.control.savedSetIndex
end

function ZO_Dyeing_Slots_Panel_Gamepad:GetSelectedDyeId()
    if self.selectionMode == SELECTION_SAVED_SWATCH then
        return self.rightPaneDyesList:GetSelectedDyeId()
    else
        return self.dyesList:GetSelectedDyeId()
    end
end

function ZO_Dyeing_Slots_Panel_Gamepad:SwitchToDyeingWithDyeId(...)
    self.dyesList:SwitchToDyeingWithDyeId(...)
    self:SwitchToTab(DYE_TAB_INDEX)
    self:SwitchToActiveRadialMenuMode(RETAIN_SELECTIONS)
    self:SetupCenterSwatch()
end

function ZO_Dyeing_Slots_Panel_Gamepad:DoesDyeIdExistInPlayerDyes(dyeId)
    return self.dyesList:DoesDyeIdExistInPlayerDyes(dyeId)
end

function ZO_Dyeing_Slots_Panel_Gamepad:SetSelectedSavedSetIndex(dyeSetIndex)
    -- Unlike PC, this callback will copy the saved set to another saved set, rather than
    -- select the saved set.
    SetSavedDyeSetDyes(dyeSetIndex, GetSavedDyeSetDyes(self:GetSelectedSavedSetIndex()))
    self:RefreshSavedSet(dyeSetIndex)
    PlaySound(SOUNDS.DYEING_TOOL_SET_FILL_USED)
end

function ZO_Dyeing_Slots_Panel_Gamepad:DefaultBack()
    if (self.activeTool == self.dyeTool) or (self.activeTool == self.fillTool) or (self.activeTool == self.setFillTool) then
        self:AttemptExit()
    else
        self:SwitchToTab(DYE_TAB_INDEX)
    end
end

function ZO_Dyeing_Slots_Panel_Gamepad:NavigateBack()
    self.suppressToolSounds = false
    if (self.selectionMode == SELECTION_DYE) or (self.selectionMode == SELECTION_SAVED) then
        self:DefaultBack()

    elseif (self.selectionMode == SELECTION_SLOT) then
        if self.activeTool:HasSwatchSelection() then
            self:SwitchToDyeSelection(RETAIN_SELECTIONS)
            PlaySound(SOUNDS.DYEING_TOOL_DYE_SELECTED)
        elseif self.activeTool:HasSavedSetSelection() then
            self:SwitchToSavedSelection(RETAIN_SELECTIONS)
            PlaySound(SOUNDS.DYEING_TOOL_SET_FILL_SELECTED)
        else
            self:DefaultBack()
        end

    elseif self.selectionMode == SELECTION_SLOT_COLOR then
        if self.activeSlotControl then
            self.activeSlotControl:Deactivate(retainSelections)
            self.activeSlotControl = nil
        end
        self:SwitchToDyeableSlotsSelection(RETAIN_SELECTIONS)

    elseif self.selectionMode == SELECTION_SLOT_MULTICOLOR then
        if self.activeSlotControl then
            self.activeSlotControl:Deactivate(retainSelections)
            self.activeSlotControl = nil
        end
        self:SwitchToDyeSelection()
        PlaySound(SOUNDS.DYEING_TOOL_DYE_SELECTED)
    elseif self.selectionMode == SELECTION_SAVED_LIST then
        self:DefaultBack()
    elseif self.selectionMode == SELECTION_SAVED_SWATCH then
        self:SwitchToSetPresetList()
    else
        -- This should never be hit, as all cases should be handled above.
        assert(false)

    end
end

function ZO_Dyeing_Slots_Panel_Gamepad:ActivateCurrentSelection()
    if (self.selectionMode == SELECTION_DYE) or (self.selectionMode == SELECTION_SAVED) then
        self:SetupCenterSwatch()

        local highlightSlot, highlightDyeChannel = self.activeTool:GetHighlightRules(CHECK_SLOT, CHECK_CHANNEL)
        if (not highlightSlot) and highlightDyeChannel then
            -- Tool selects all dyeable slots at once, but only a single channel. This is currently
            --  only supported for dyeable slots selection.
            self:SwitchToDyeableSlotDyeMultiSelection()

        elseif highlightSlot or highlightDyeChannel then
            -- Tool wants a specific slot or a specific channel or both.
            self:SwitchToActiveRadialMenuMode(RETAIN_SELECTIONS)

        else
            -- Tool selects all dyeable slots and channels at once.
            -- TODO: Implement if this becomes a valid option.
            assert(false)
        end

    elseif self.selectionMode == SELECTION_SLOT then
        local selectedEntry = self.dyeableSlotsMenu.selectedEntry
        if not selectedEntry then
            -- It should be impossible to get to this state as CanViewCurrentSelection should
            --  return false in this case.
            assert(false)
        else
            local dyeableSlot = selectedEntry.data.dyeableSlot
            if dyeableSlot and IsDyeableSlotDyeable(dyeableSlot) then
                local highlightSlot, highlightDyeChannel = self.activeTool:GetHighlightRules(dyeableSlot, CHECK_CHANNEL)
                if highlightSlot and highlightDyeChannel then
                    -- Tool wants a specific dyeable slot and channel selection,
                    --  so move on to selecting a channel.
                    self:SwitchToDyeableSlotDyeSelection()
                elseif highlightSlot then
                    -- Tool selects all channels at once, so just activate the tool.
                    self.activeTool:OnLeftClicked(dyeableSlot, nil)
                elseif highlightDyeChannel then
                    -- Tool selects all dyeable slots at once, but only a single channel.
                    self:SwitchToDyeableSlotDyeMultiSelection()
                else
                    -- Tool selects all dyeable slots and channels at once.
                    -- TODO: Implement if this becomes a valid option.
                    assert(false)
                end
            end
        end

    elseif self.selectionMode == SELECTION_SLOT_COLOR then
        local selectedEntry = self.dyeableSlotsMenu.selectedEntry
        local selectedDyeableSlot = selectedEntry and selectedEntry.data.dyeableSlot

        local selectedChannelData = self.activeSlotControl.dyeSelector:GetFocusItem()
        local selectedChannel = selectedChannelData.slotIndex

        self.activeTool:OnLeftClicked(selectedDyeableSlot, selectedChannel)

    elseif self.selectionMode == SELECTION_SLOT_MULTICOLOR then
        local selectedChannelData = self.channelMultiFocus:GetFocusItem()
        local selectedChannel = selectedChannelData.slotIndex

        self.activeTool:OnLeftClicked(nil, selectedChannel)
    elseif self.selectionMode == SELECTION_SAVED_LIST then
        self:SwitchToSetPresetSwatch()
    elseif self.selectionMode == SELECTION_SAVED_SWATCH then
        local presetSelectedControl = self.setPresestList:GetSelectedControl()
        local presetSelectedData = self.setPresestList:GetSelectedData()

        local savedSlotIndex = presetSelectedData.dyeSetIndex

        local selectedChannelData = presetSelectedControl.dyeSelector:GetFocusItem(true)
        local selectedChannel = selectedChannelData.slotIndex

        self.activeTool:OnSavedSetLeftClicked(savedSlotIndex, selectedChannel)
        self:RefreshPresetListEntry(presetSelectedControl, savedSlotIndex)
    else
        -- All selection modes should be handled above.
        assert(false)

    end
end

function ZO_Dyeing_Slots_Panel_Gamepad:CanViewCurrentSelection()
    if self.selectionMode == SELECTION_DYE then
        local selectedSwatch = self.dyesList:GetSelectedSwatch()
        return selectedSwatch and (not selectedSwatch.locked)

    elseif self.selectionMode == SELECTION_SAVED then
        local selectedSet = self.savedSetFocusList:GetFocusItem()
        return selectedSet ~= nil

    elseif self.selectionMode == SELECTION_SLOT then
        local selectedEntry = self.dyeableSlotsMenu.selectedEntry
        if not selectedEntry then
            return false
        end

        local dyeableSlot = selectedEntry.data.dyeableSlot
        if not dyeableSlot then
            return true
        end

        if not IsDyeableSlotDyeable(dyeableSlot) then
            return false
        end

        local icon = GetDyeableSlotIcon(dyeableSlot)
        return icon ~= ZO_NO_TEXTURE_FILE
    elseif self.selectionMode == SELECTION_SLOT_COLOR then
        if not self.activeSlotControl then
            return false
        end
        local selectedChannelData = self.activeSlotControl.dyeSelector:GetFocusItem()
        local selectedChannel = selectedChannelData and selectedChannelData.slotIndex
        return (selectedChannel ~= nil)

    elseif self.selectionMode == SELECTION_SLOT_MULTICOLOR then
        local selectedChannelData = self.channelMultiFocus:GetFocusItem()
        local selectedChannel = selectedChannelData and selectedChannelData.slotIndex
        return (selectedChannel ~= nil)
    elseif self.selectionMode == SELECTION_SAVED_LIST then
        local selectedControl = self.setPresestList:GetSelectedControl()
        return selectedControl ~= nil
    elseif self.selectionMode == SELECTION_SAVED_SWATCH then
        local selectedSwatch = self.rightPaneDyesList:GetSelectedSwatch()
        return selectedSwatch and (not selectedSwatch.locked)
    end

    return false
end

function ZO_Dyeing_Slots_Panel_Gamepad:CanActivateCurrentSelection()
	if self.selectionMode == SELECTION_SLOT_COLOR then
		if not self.activeSlotControl then
            return false
        end
		local selectedEntry = self.dyeableSlotsMenu.selectedEntry
        if not selectedEntry then
            return false
        end

		local dyeableSlot = selectedEntry.data.dyeableSlot
        local selectedChannelData = self.activeSlotControl.dyeSelector:GetFocusItem()
        local selectedChannel = selectedChannelData and selectedChannelData.slotIndex
		local isChannelDyeableTable = {AreDyeableSlotDyeChannelsDyeable(dyeableSlot)}
		if selectedChannel ~= nil then
			return isChannelDyeableTable[selectedChannel]
		end

		return false
	end

	return true
end

function ZO_Dyeing_Slots_Panel_Gamepad:UpdateDirectionalInput()
    -- Camera Spin.
    local x = DIRECTIONAL_INPUT:GetX(ZO_DI_RIGHT_STICK)
    if x ~= 0 then
        -- TODO: Make this work with gamepad right-stick.
        BeginInteractCameraSpin()
        self.isSpinning = true
    else
        if self.isSpinning then
            -- TODO: Make this work with gamepad right-stick.
            EndInteractCameraSpin()
            self.isSpinning = false
        end
    end

    -- Move out of Saved Sets.
    if self.selectionMode == SELECTION_SAVED then
        local result = self.savedSetsMovementOutController:CheckMovement()
        if result == MOVEMENT_CONTROLLER_MOVE_NEXT then
            self:OnSavedSetListMoveOut()
        end
    end
end

function ZO_Dyeing_Slots_Panel_Gamepad:CommitSelection()
    if ZO_Dyeing_AreAllItemsBound(self.mode) then
        self:ConfirmCommitSelection()
        PlaySound(SOUNDS.DYEING_APPLY_CHANGES)
    else
        ZO_Dialogs_ShowGamepadDialog("CONFIRM_APPLY_DYE")
    end
end

function ZO_Dyeing_Slots_Panel_Gamepad:ConfirmCommitSelection()
    ApplyPendingDyes()
    InitializePendingDyes(self.mode)
    self:OnPendingDyesChanged()
    self:SwitchToTab(DYE_TAB_INDEX)
    self:SwitchToDyeSelection()
end

function ZO_Dyeing_Slots_Panel_Gamepad:SwitchToTab(tabIndex)
    self.suppressToolSounds = false
    ZO_GamepadGenericHeader_SetActiveTabIndex(self.header, tabIndex)
end

function ZO_Dyeing_Slots_Panel_Gamepad:SwitchToTool(newTool)
    local lastTool = self.activeTool
    if lastTool then
        lastTool:Deactivate()
    end

    self.activeTool = newTool
    if newTool then
        self.activeTool:Activate(lastTool, self.suppressToolSounds)

        if newTool:HasSwatchSelection() then
            self:SwitchToDyeSelection()
        elseif newTool:HasSavedSetSelection() then
            self:SwitchToSavedSelection()
        else
            self:SwitchToActiveRadialMenuMode(nil, self.suppressToolSounds)
        end
        self.suppressToolSounds = true
    end

    if newTool == self.setFillTool then
        self.headerData.tabBarEntries[DYE_TAB_INDEX].canSelect = false
        self.headerData.tabBarEntries[FILL_SET_TAB_INDEX].canSelect = true
    else
        self.headerData.tabBarEntries[DYE_TAB_INDEX].canSelect = true
        self.headerData.tabBarEntries[FILL_SET_TAB_INDEX].canSelect = false
    end
    
    SCENE_MANAGER:RemoveFragment(GAMEPAD_DYEING_RIGHT_SWATCHES_FRAGMENT)
    SCENE_MANAGER:RemoveFragment(GAMEPAD_DYEING_SET_PRESET_CONVEYOR_FRAGMENT)
    SCENE_MANAGER:AddFragment(GAMEPAD_DYEING_CONVEYOR_FRAGMENT)
    SCENE_MANAGER:AddFragment(GAMEPAD_DYEING_RIGHT_RADIAL_FRAGMENT)
end

do
    local PRESET_CONTROL_WIDTH = 90
    local PRESET_CONTROL_PADDING = 20
    local SWATCH_CONTROL_WIDTH = 32
    local SWATCH_CONTROL_PADDING = 10
    local PRESET_SWATCH_WIDTH_RATIO = (PRESET_CONTROL_WIDTH + PRESET_CONTROL_PADDING) / (SWATCH_CONTROL_WIDTH + SWATCH_CONTROL_PADDING)

    function ZO_Dyeing_Slots_Panel_Gamepad:OnDyeListMoveOut(direction, rowIndex, colIndex)
        if direction == ZO_DYEING_SWATCHES_MOVE_OUT_DIRECTION_UP then
            local presetToSelect = zo_floor((colIndex - 1) / PRESET_SWATCH_WIDTH_RATIO) + 1
            presetToSelect = zo_clamp(presetToSelect, 1, GetNumSavedDyeSets())
            self.savedSetFocusList:SetFocusByIndex(presetToSelect)
            self:SwitchToTab(FILL_SET_TAB_INDEX)
        end
    end

    function ZO_Dyeing_Slots_Panel_Gamepad:OnSavedSetListMoveOut()
        local colIndex = self.savedSetFocusList:GetFocus()
        if colIndex then
            self.dyesList:SetSelectedDyeColumn(zo_ceil((colIndex - 1) * PRESET_SWATCH_WIDTH_RATIO) + 1)
        end
        self:SwitchToTab(DYE_TAB_INDEX)
    end
end

function ZO_Dyeing_Slots_Panel_Gamepad:OnDyeSelectionChanged(previousSwatch, newSwatch)
    self:RefreshKeybindStrip()

    if newSwatch then
        local dyeName = newSwatch.dyeName
        local achievementId = newSwatch.achievementId
        local known = newSwatch.known

        self.leftTipTitle:SetText(zo_strformat(SI_DYEING_SWATCH_TOOLTIP_TITLE, dyeName))

        local achievementName = GetAchievementInfo(achievementId)
        local leftTipBody = ZO_Dyeing_GetAchivementText(known, achievementId)
        self.leftTipBody:SetText(leftTipBody)

    elseif self.selectionMode == SELECTION_DYE then
        self.leftTipTitle:SetText("")
        self.leftTipBody:SetText(GetString(SI_DYEING_NO_MATCHING_DYES))
    end
end

function ZO_Dyeing_Slots_Panel_Gamepad:AttemptExit()
    if ZO_Dyeing_AreTherePendingDyes(self.mode) then
        ZO_Dialogs_ShowGamepadDialog("EXIT_DYE_UI_DISCARD_GAMEPAD")
    else
        self:ExitWithoutSave()
    end
end

function ZO_Dyeing_Slots_Panel_Gamepad:ExitWithoutSave()
    self:UndoPendingChanges()
    SCENE_MANAGER:HideCurrentScene()
end

function ZO_Dyeing_Slots_Panel_Gamepad:UndoPendingChanges()
    InitializePendingDyes(self.mode)
    PlaySound(SOUNDS.DYEING_UNDO_CHANGES)
end

function ZO_Dyeing_Slots_Panel_Gamepad:OnPendingDyesChanged()
    self.dyeableSlotsMenu:PerformLayout()

    if SCENE_MANAGER:IsShowing(GAMEPAD_DYEING_ITEMS_SCENE_NAME) then
        self:RefreshKeybindStrip()
    end
end

function ZO_Dyeing_Slots_Panel_Gamepad:OnSavedSetSlotChanged(dyeSetIndex)
    if dyeSetIndex then
        self:RefreshSavedSet(dyeSetIndex)
    else
        self:RefreshSavedSets()
    end
    self:RefreshKeybindStrip()
end

local function GetDyeColor(dyeId)
    if dyeId then
        local r, g, b = GetDyeColorsById(dyeId)
        return r, g, b, 1
    else
        return 0, 0, 0, 1
    end
end

function ZO_Dyeing_Slots_Panel_Gamepad:ClearCenterSwatch()
    self.centerSwatch:SetColor(1, 1, 1, 1)
    self.centerSwatch:SetTexture(NO_COLOR_CENTER_SWATCH)
    self.centerSwatch:SetHidden(false)
    self.centerSwatchSaved:SetHidden(true)
end

function ZO_Dyeing_Slots_Panel_Gamepad:SetupCenterSwatch()
    if (self.activeTool == self.dyeTool) or (self.activeTool == self.fillTool) then
        local dyeId = self.dyesList:GetSelectedDyeId()
        if dyeId then
            local r, g, b = GetDyeColor(dyeId)
            self.centerSwatch:SetColor(r, g, b)
            self.centerSwatch:SetTexture(MONO_COLOR_CENTER_SWATCH)
        else
            self.centerSwatch:SetTexture(NO_COLOR_CENTER_SWATCH)
        end
        self.centerSwatch:SetHidden(false)
        self.centerSwatchSaved:SetHidden(true)

    elseif self.activeTool == self.setFillTool then
        self.centerSwatchSaved:GetNamedChild("Primary"):SetTexture(PRIMARY_COLOR_SWATCH_POINT)
        self.centerSwatchSaved:GetNamedChild("Keybind"):SetHidden(false)
        local selectedSavedSetIndex = self:GetSelectedSavedSetIndex()
        if selectedSavedSetIndex then
            for i=1, #self.centerSwatchSaved.dyeControls do
                local dyeId = select(i, GetSavedDyeSetDyes(selectedSavedSetIndex))
                local r, g, b, a = GetDyeColor(dyeId)
                local control = self.centerSwatchSaved.dyeControls[i]
                control:SetColor(r, g, b, a)
            end

            self.centerSwatch:SetHidden(true)
            self.centerSwatchSaved:SetHidden(false)
        else
            self:ClearCenterSwatch()
        end

    else
        self:ClearCenterSwatch()
    end
end

function ZO_Dyeing_Slots_Panel_Gamepad:SetupRandomizeSwatch()
    self.centerSwatchSaved:GetNamedChild("Primary"):SetTexture(PRIMARY_COLOR_SWATCH_NO_POINT)
    self.centerSwatchSaved:GetNamedChild("Keybind"):SetHidden(true)
    local modeSlotData = ZO_Dyeing_GetSlotsForMode(self.mode)
    local dyeInfo = {GetPendingSlotDyes(modeSlotData[1].dyeableSlot)}
    for i = 1, #self.centerSwatchSaved.dyeControls do
        local dyeId = dyeInfo[i]
        local r, g, b, a = GetDyeColor(dyeId)
        local control = self.centerSwatchSaved.dyeControls[i]
        control:SetColor(r, g, b, a)
    end

    self.centerSwatch:SetHidden(true)
    self.centerSwatchSaved:SetHidden(false)
end

function ZO_Dyeing_Slots_Panel_Gamepad:RefreshVisibleRadialMenuSelection()
    if self.visibleRadialMenu then
        self:RadialMenuSelectionChanged(self.visibleRadialMenu.selectedEntry)
    else
        self:RadialMenuSelectionChanged(nil)
    end
end

function ZO_Dyeing_Slots_Panel_Gamepad:RadialMenuSelectionChanged(selectedEntry)
    if self.dyeableSlotsMenuSelectedEntry == selectedEntry and self.lastUpdateMode == self.selectionMode then return end
    self.dyeableSlotsMenuSelectedEntry = selectedEntry
    self.lastUpdateMode = self.selectionMode

    self:RefreshKeybindStrip()
    self.rightTipContents:ClearLines()

    if (self.selectionMode == SELECTION_SLOT) or (self.selectionMode == SELECTION_SLOT_COLOR) then
        if selectedEntry and selectedEntry.data.dyeableSlot then
            -- User has an dyeable slot selected.
            local data = selectedEntry.data
            local dyeableSlot = data.dyeableSlot

            local equipSlot = GetEquipSlotFromDyeableSlot(dyeableSlot)
            local layoutEquipment = equipSlot ~= EQUIP_SLOT_NONE
            local itemLink
            local icon = GetDyeableSlotIcon(dyeableSlot)
            if icon == ZO_NO_TEXTURE_FILE then
                -- Nothing is in the slot.
                icon = ZO_Character_GetEmptyDyeableSlotTexture(dyeableSlot)
                local slotName = zo_strformat(SI_CHARACTER_EQUIP_SLOT_FORMAT, GetString("SI_DYEABLESLOT", dyeableSlot))
                self.rightTipContents:AddItemTitle(itemLink, slotName)
            else
                if layoutEquipment then
                    -- An item is equipped in the slot.
                    itemLink = GetItemLink(BAG_WORN, equipSlot)
                    self.rightTipContents:AddItemTitle(itemLink)
                    self.rightTipContents:AddBaseStats(itemLink)
                    self.rightTipContents:AddConditionBar(itemLink)
                else
                    local collectibleName = GetCollectibleInfo(GetDyeableSlotId(dyeableSlot))
                    self.rightTipContents:AddLine(collectibleName, nil, self.rightTipContents:GetStyle("title"))
                end
            end
            self.rightTipImage:SetTexture(icon)
            self.rightTipImage:SetHidden(false)
            self.rightTipSwap:SetHidden(true)

        elseif selectedEntry then
            -- User has the "switch to saved set" option selected.
            self.rightTipImage:SetTexture(SWAP_SAVED_ICON)
            self.rightTipImage:SetHidden(false)
            self.rightTipSwap:SetHidden(false)
            self.rightTipContents:AddLine(GetString(SI_GAMEPAD_DYEING_SETS_SWITCH), self.rightTipContents:GetStyle("title"))

        else
            -- User has no selection on the dyeable slots menu.
            self.rightTipImage:SetHidden(true)
            self.rightTipSwap:SetHidden(true)

        end
    elseif self.selectionMode == SELECTION_SLOT_MULTICOLOR then
        -- TODO: What tooltip in this case?
        self.rightTipImage:SetHidden(true)
        self.rightTipSwap:SetHidden(true)

    else
        self.rightTipImage:SetHidden(true)
        self.rightTipSwap:SetHidden(true)
    end
end

function ZO_Dyeing_Slots_Panel_Gamepad:RefreshDyeableSlotDyes(dyeableSlot)
    ZO_Dyeing_RefreshDyeableSlotControlDyes(slotControl, dyeableSlot)
end

function ZO_Dyeing_Slots_Panel_Gamepad:GetMode()
    return self.mode
end


function ZO_Dyeing_Gamepad_OnInitialized(control)
    DYEING_GAMEPAD = ZO_Dyeing_Gamepad:New(control)
    SYSTEMS:RegisterGamepadObject("dyeing", DYEING_GAMEPAD)
end