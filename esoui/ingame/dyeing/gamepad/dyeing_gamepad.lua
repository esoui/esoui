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
local SELECTION_EQUIP = "Equip"                             -- Selecting equipment to apply a dye or saved set to, or to retrieve a dye to select.
local SELECTION_EQUIP_COLOR = "Equip Color"                 -- Selecting a color slot on equipment to apply a dye to, or to retrieve a dye to select.
local SELECTION_EQUIP_MULTICOLOR = "Equip Multiple Color"   -- Selecting a color slot on all equipment to apply a dye to, or to retrieve a dye to select.
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

    local function OnBlockingSceneActivated()
        self:AttemptExit()
    end

    GAMEPAD_DYEING_SCENE = ZO_InteractScene:New("dyeing_gamepad", SCENE_MANAGER, ZO_DYEING_STATION_INTERACTION)
    SYSTEMS:RegisterGamepadRootScene("dyeing", GAMEPAD_DYEING_SCENE)
    GAMEPAD_DYEING_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            MAIN_MENU_MANAGER:SetBlockingScene("dyeing_gamepad", OnBlockingSceneActivated)
            self:PerformDeferredInitialization()
            ZO_Dyeing_CopyExistingDyesToPending()
            self.equipmentMenu:Show()
            self.visibleRadialMenu = self.equipmentMenu
            self:SwitchToTab(DYE_TAB_INDEX)
            self:SwitchToTool(self.dyeTool)
            ZO_GamepadGenericHeader_Activate(self.header)
            self:RefreshSavedSets()
            KEYBIND_STRIP:RemoveDefaultExit()
            KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
            DIRECTIONAL_INPUT:Activate(self, self.control)
            TriggerTutorial(TUTORIAL_TRIGGER_DYEING_OPENED)
        elseif newState == SCENE_HIDDEN then
            local RETAIN_BACKGROUND_FOCUS = true
            self:ResetScreen(nil, RETAIN_BACKGROUND_FOCUS)
            self.equipmentMenu:ResetToDefaultPositon()
            ZO_GamepadGenericHeader_Deactivate(self.header)
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
            KEYBIND_STRIP:RestoreDefaultExit()
            DIRECTIONAL_INPUT:Deactivate(self)
            if self.isSpinning then
                -- TODO: Make this work with gamepad right-stick.
                EndInteractCameraSpin()
                self.isSpinning = false
            end
            MAIN_MENU_MANAGER:ClearBlockingScene(OnBlockingSceneActivated)

            ZO_SavePlayerConsoleProfile()
        end
    end)

    local ALWAYS_ANIMATE = true
    GAMEPAD_DYEING_CONVEYOR_FRAGMENT = ZO_ConveyorSceneFragment:New(ZO_DyeingGamepadLeftPaneDyeContainer, ALWAYS_ANIMATE)
    GAMEPAD_DYEING_SET_PRESET_CONVEYOR_FRAGMENT = ZO_ConveyorSceneFragment:New(ZO_DyeingGamepadLeftPanePresetContainer, ALWAYS_ANIMATE)
    GAMEPAD_DYEING_RIGHT_RADIAL_FRAGMENT = ZO_FadeSceneFragment:New(ZO_DyeingGamepadRightPaneRadialContainer, ALWAYS_ANIMATE)
    GAMEPAD_DYEING_RIGHT_SWATCHES_FRAGMENT = ZO_FadeSceneFragment:New(ZO_DyeingGamepadRightPanePresetDyesContainer, ALWAYS_ANIMATE)
end

function ZO_Dyeing_Gamepad:InitializeKeybindDescriptors()
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
            visible = function() return self:CanActivateCurrentSelection() end,
        },

        -- Apply
        {
            name = GetString(SI_DYEING_COMMIT),
            keybind = "UI_SHORTCUT_SECONDARY",
            callback = function() self:CommitSelection() end,
            visible = ZO_Dyeing_AreTherePendingDyes,
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
                            ZO_Dyeing_UniformRandomize(function() return self.dyesList:GetRandomUnlockedDyeIndex() end)
                            self:OnPendingDyesChanged()
                            self:SetupRandomizeSwatch()
                        end,
            visible = function()
                            return (self.visibleRadialMenu == self.equipmentMenu) and ((self.selectionMode == SELECTION_DYE) or (self.selectionMode == SELECTION_SAVED)) and (self.dyesList:GetNumUnlockedDyes() > 0)
                      end,
        },

        -- Clear
        {
            name = GetString(SI_DYEING_UNDO),
            keybind = "UI_SHORTCUT_LEFT_STICK",
            callback = function()
                            ZO_Dyeing_CopyExistingDyesToPending()
                            self:OnPendingDyesChanged()
                            PlaySound(SOUNDS.DYEING_UNDO_CHANGES)
                        end,
            visible = function()
                            return (self.visibleRadialMenu == self.equipmentMenu) and ZO_Dyeing_AreTherePendingDyes()
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

function ZO_Dyeing_Gamepad:InitializeOptionsDialog()
    local sortRarityEntry = ZO_GamepadEntryData:New(GetString(SI_DYEING_SORT_BY_RARITY), (self.savedVars.sortStyle == ZO_DYEING_SORT_STYLE_RARITY) and CHECKED_ICON or UNCHECKED_ICON)
    local sortHueEntry = ZO_GamepadEntryData:New(GetString(SI_DYEING_SORT_BY_HUE), (self.savedVars.sortStyle == ZO_DYEING_SORT_STYLE_HUE) and CHECKED_ICON or UNCHECKED_ICON)
    local showLockedEntry = ZO_GamepadEntryData:New(GetString(SI_DYEING_SHOW_LOCKED), self.savedVars.showLocked and CHECKED_ICON or UNCHECKED_ICON)

    sortRarityEntry.setup = ZO_SharedGamepadEntry_OnSetup
    sortRarityEntry.callback = function()
            self.savedVars.sortStyle = ZO_DYEING_SORT_STYLE_RARITY
            sortRarityEntry:ClearIcons()
            sortHueEntry:ClearIcons()
            sortRarityEntry:AddIcon(CHECKED_ICON)
            self.dyesList:RefreshDyeLayout()
            self.rightPaneDyesList:RefreshDyeLayout()
        end

    sortHueEntry.setup = ZO_SharedGamepadEntry_OnSetup
    sortHueEntry.callback = function()
            self.savedVars.sortStyle = ZO_DYEING_SORT_STYLE_HUE
            sortRarityEntry:ClearIcons()
            sortHueEntry:ClearIcons()
            sortHueEntry:AddIcon(CHECKED_ICON)
            self.dyesList:RefreshDyeLayout()
            self.rightPaneDyesList:RefreshDyeLayout()
        end

    showLockedEntry.setup = ZO_SharedGamepadEntry_OnSetup
    showLockedEntry.callback = function()
            local showLocked = not self.savedVars.showLocked
            self.savedVars.showLocked = showLocked
            showLockedEntry:ClearIcons()
            if showLocked then
                showLockedEntry:AddIcon(CHECKED_ICON)
            end
            self.dyesList:RefreshDyeLayout()
            self.rightPaneDyesList:RefreshDyeLayout()
        end

    ZO_Dialogs_RegisterCustomDialog("DYEING_OPTIONS_GAMEPAD",
    {
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
        },

        setup = function()
            local dialog = ZO_GenericGamepadDialog_GetControl(GAMEPAD_DIALOGS.PARAMETRIC)
            dialog.setupFunc(dialog)
        end,

        title =
        {
            text = GetString(SI_GAMEPAD_DYEING_OPTIONS_TITLE),
        },
        parametricList =
        {
            {
                template = "ZO_GamepadMenuEntryTemplate",
                templateData = sortRarityEntry,
            },
            {
                template = "ZO_GamepadMenuEntryTemplate",
                templateData = sortHueEntry,
            },
            {
                template = "ZO_GamepadMenuEntryTemplate",
                templateData = showLockedEntry,
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
                        data.callback()
                    end
                end,
                clickSound = SOUNDS.DIALOG_ACCEPT,
            },
            {
                keybind = "DIALOG_NEGATIVE",
                text = SI_DIALOG_CANCEL,
            },
        }
    })
end

function ZO_Dyeing_Gamepad:RefreshSavedSet(dyeSetIndex)
    local selectedSavedSet = self:GetSelectedSavedSetIndex()

    local savedSetSwatch = self.savedSets[dyeSetIndex]
    for dyeChannel, dyeControl in ipairs(savedSetSwatch.dyeControls) do
        local currentDyeIndex = select(dyeChannel, GetSavedDyeSetDyes(dyeSetIndex))
        ZO_DyeingUtils_SetSlotDyeSwatchDyeIndex(dyeChannel, dyeControl, currentDyeIndex)
    end

    if selectedSavedSet == dyeSetIndex then
        self:SetupCenterSwatch()
    end
end

function ZO_Dyeing_Gamepad:RefreshSavedSets()
    local selectedSavedSet = self:GetSelectedSavedSetIndex()

    for dyeSetIndex=1, GetNumSavedDyeSets() do
        self:RefreshSavedSet(dyeSetIndex)
    end

    if selectedSavedSet then
        self:SetupCenterSwatch()
    end
end

function ZO_Dyeing_Gamepad:SetupColorPresetControls(parent)
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

function ZO_Dyeing_Gamepad:SavedSetSelected(control)
    self:RefreshKeybindStrip()
    if control then
        self.leftTipTitle:SetText(GetString(SI_GAMEPAD_DYEING_SETS_TITLE))
        self.leftTipBody:SetText(GetString(SI_GAMEPAD_DYEING_SETS_TOOLTIP))
    elseif self.selectionMode == SELECTION_SAVED then
        self.leftTipTitle:SetText("")
        self.leftTipBody:SetText(GetString(SI_DYEING_NO_MATCHING_DYES))
    end
end

function ZO_Dyeing_Gamepad:PerformDeferredInitialization()
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
    local rightPane = self.control:GetNamedChild("RightPane")
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

    -- Equipment Sheet    
    self.centerSwatch = self.rightRadialContainer:GetNamedChild("CenterSwatch")  
    self.centerSwatch:GetNamedChild("Keybind"):SetTexture(keybindIcon)
    local equipmentSheet = self.rightRadialContainer:GetNamedChild("EquipmentSheet")    
    self.equipmentMenu = ZO_Dyeing_Equipment_Gamepad:New(equipmentSheet, radialSharedHighlight)
    self.equipmentMenu:SetOnSelectionChangedCallback(function(...) self:RadialMenuSelectionChanged(...) end)

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

    self.equipmentMenu:SetOnUpdateRotationFunction(UpdateRotation)
    self.visibleRadialMenu = self.equipmentMenu

    -- Saved Slots Sheet
    self.centerSwatchSaved = self.rightRadialContainer:GetNamedChild("CenterSwatchSaved")  
    self.centerSwatchSaved:GetNamedChild("Keybind"):SetTexture(keybindIcon) 

    -- Equipment/Saved Slot Multi-Select
    local function HighlightAllSlots(entry)
        local slotIndex = entry and entry.slotIndex
        self.visibleRadialMenu:HighlightAll(slotIndex)
    end
    self.channelMultiFocus = ZO_GamepadFocus:New(self.control, nil, MOVEMENT_CONTROLLER_DIRECTION_HORIZONTAL)
    self.channelMultiFocus:SetFocusChangedCallback(HighlightAllSlots)
    for i=1, 3 do
        local entry = {slotIndex = i}
        self.channelMultiFocus:AddEntry(entry)
    end

    -- Dye Layout
    self.swatchesContainer = dyesControl:GetNamedChild("Scroll"):GetNamedChild("Container"):GetNamedChild("List")
    local dyesSharedHighlight = dyesControl:GetNamedChild("SharedHighlight")
    self.dyesList = ZO_Dyeing_Swatches_Gamepad:New(self, self.swatchesContainer, dyesSharedHighlight, self.savedVars, function(...) self:OnDyeSelectionChanged(...) end, function(...) self:OnDyeListMoveOut(...) end, self.savedSetsMovementOutController)
    self.control:RegisterForEvent(EVENT_UNLOCKED_DYES_UPDATED, function() self:UpdateUnlockedDyes() end)

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

    self.setPresestList:AddDataTemplate("ZO_DyeingSavedPresetListEntry_Gamepad", PresetListSetupFunction, ZO_GamepadMenuEntryTemplateParametricListFunction) --TODO scale function

    for dyeSetIndex=1, GetNumSavedDyeSets() do
        local data = { name = GetString(_G["SI_GAMEPAD_DYEING_PRESET_"..tostring(dyeSetIndex)]), dyeSetIndex = dyeSetIndex, }
        self.setPresestList:AddEntry("ZO_DyeingSavedPresetListEntry_Gamepad", data)
    end
    
    self.setPresestList:Commit()
    -- Header
    local headerContainer = leftPane:GetNamedChild("HeaderContainer")
    self.header = headerContainer:GetNamedChild("Header")
    ZO_GamepadGenericHeader_Initialize(self.header, ZO_GAMEPAD_HEADER_TABBAR_CREATE)
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
                                            self:ShowRadialMenu(self.equipmentMenu)
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
    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)
end

function ZO_Dyeing_Gamepad:ResetScreen(retainSelections, retainBackgroundFocus)
    -- Clear the selection mode first as it is used in callbacks
    --  made by some of the other calls to determine what to display.
    self.selectionMode = nil

    self.equipmentMenu:Deactivate(retainSelections)
    self.equipmentMenu:DefocusAll()
    self.dyesList:Deactivate()
    self.savedSetFocusList:Deactivate()
    self.channelMultiFocus:Deactivate(retainSelections)
    
    self.rightPaneDyesList:Deactivate()
    self.setPresestList:Deactivate()
    if self.lastSelectedControl then
        self.lastSelectedControl:Deactivate()
    end

    if not retainSelections then
        self.savedSetFocusList:ClearFocus()
    end
    if self.activeSlotControl then
        self.activeSlotControl:Deactivate(retainSelections)
        if not retainSelections then
            self.activeSlotControl = nil
        end
    end

    if not retainBackgroundFocus then
        GAMEPAD_NAV_QUADRANT_1_BACKGROUND_FRAGMENT:ClearFocus()
        GAMEPAD_NAV_QUADRANT_2_3_BACKGROUND_FRAGMENT:ClearFocus()
    end

    if not retainSelections then
        self.visibleRadialMenu:HighlightAll(nil) -- Remove all highlights.
        self:ClearCenterSwatch()
    end

    ZO_GamepadGenericHeader_Activate(self.header)

    self:RadialMenuSelectionChanged(nil)
end

function ZO_Dyeing_Gamepad:RefreshPresetListEntry(control, dyeSetIndex)
    for dyeChannel, dyeControl in ipairs(control.dyeControls) do
        local currentDyeIndex = select(dyeChannel, GetSavedDyeSetDyes(dyeSetIndex))
        ZO_DyeingUtils_SetSlotDyeSwatchDyeIndex(dyeChannel, dyeControl, currentDyeIndex)
    end
end

function ZO_Dyeing_Gamepad:SwitchToSetPresetList()
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

    GAMEPAD_NAV_QUADRANT_1_BACKGROUND_FRAGMENT:TakeFocus()
    GAMEPAD_NAV_QUADRANT_2_3_BACKGROUND_FRAGMENT:ClearFocus()
end

function ZO_Dyeing_Gamepad:SwitchToSetPresetSwatch()
    self.selectionMode = SELECTION_SAVED_SWATCH

    local RETAIN_FOCUS = true
    self.lastSelectedControl:Deactivate(RETAIN_FOCUS)

    self.rightPaneDyesList:Activate()
    self.setPresestList:DeactivateWithoutChangedCallback()

    self:RefreshKeybindStrip()

    GAMEPAD_NAV_QUADRANT_1_BACKGROUND_FRAGMENT:ClearFocus()
    GAMEPAD_NAV_QUADRANT_2_3_BACKGROUND_FRAGMENT:TakeFocus()
end



function ZO_Dyeing_Gamepad:SwitchToSavedSelection()
    self:ResetScreen()
    self.selectionMode = SELECTION_SAVED
    self.savedSetFocusList:Activate()
    self:RefreshKeybindStrip()

    GAMEPAD_NAV_QUADRANT_1_BACKGROUND_FRAGMENT:TakeFocus()
end

function ZO_Dyeing_Gamepad:SwitchToDyeSelection()
    self:ResetScreen()
    self.selectionMode = SELECTION_DYE
    self.dyesList:Activate()
    self:RefreshKeybindStrip()

    GAMEPAD_NAV_QUADRANT_1_BACKGROUND_FRAGMENT:TakeFocus()
end

function ZO_Dyeing_Gamepad:ShowRadialMenu(menu)
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

function ZO_Dyeing_Gamepad:SwitchToRadialMenu(retainSelections, menu, mode, suppressSound)
    self:ResetScreen(retainSelections)
    self.selectionMode = mode
    menu:Show(suppressSound)
    menu:Activate()
    self.visibleRadialMenu = menu
    self:RefreshKeybindStrip()

    GAMEPAD_NAV_QUADRANT_2_3_BACKGROUND_FRAGMENT:TakeFocus()
end

function ZO_Dyeing_Gamepad:SwitchToEquipmentSelection(retainSelections, suppressSound)
    self:SwitchToRadialMenu(retainSelections, self.equipmentMenu, SELECTION_EQUIP, suppressSound)
end

function ZO_Dyeing_Gamepad:SwitchToActiveRadialMenuMode(...)
    if self.visibleRadialMenu == self.equipmentMenu then
        self:SwitchToEquipmentSelection(...)
    else
        -- This case is invalid, and more cases should be
        --  added if additional modes become available.
        assert(false)
    end
end

function ZO_Dyeing_Gamepad:SwitchToEquipmentDyeSelection(selectedControl)
    local selectedControl = selectedControl or self.equipmentMenu.selectedControl
    if not selectedControl then return end

    self:ResetScreen(RETAIN_SELECTIONS)

    self.selectionMode = SELECTION_EQUIP_COLOR
    selectedControl:Activate()
    self.activeSlotControl = selectedControl

    self:RefreshVisibleRadialMenuSelection()

    self:RefreshKeybindStrip()

    GAMEPAD_NAV_QUADRANT_2_3_BACKGROUND_FRAGMENT:TakeFocus()
end

function ZO_Dyeing_Gamepad:SwitchToEquipmentDyeMultiSelection(retainPosition)
    self:ResetScreen(RETAIN_SELECTIONS)

    self.centerSwatch:SetTexture(MONO_COLOR_CENTER_SWATCH_NO_POINT)
    self.equipmentMenu:FocusAll()

    self.selectionMode = SELECTION_EQUIP_MULTICOLOR
    if not retainPosition then
        self.channelMultiFocus:SetFocusToFirstEntry()
    end
    self.channelMultiFocus:Activate()
    self.activeSlotControl = self.channelMultiFocus

    self:RefreshVisibleRadialMenuSelection()

    self:RefreshKeybindStrip()

    GAMEPAD_NAV_QUADRANT_2_3_BACKGROUND_FRAGMENT:TakeFocus()
    PlaySound(SOUNDS.RADIAL_MENU_OPEN)
end

function ZO_Dyeing_Gamepad:RefreshKeybindStrip()
    if self.keybindStripDescriptor then
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    end
end

function ZO_Dyeing_Gamepad:UpdateUnlockedDyes()
    self:RefreshKeybindStrip()
    self.dyesList:RefreshDyeLayout()
    self.rightPaneDyesList:RefreshDyeLayout()
end

function ZO_Dyeing_Gamepad:GetSelectedSavedSetIndex()
    local INCLUDE_SAVED_FOCUS = true
    local selectedSavedSet = self.savedSetFocusList:GetFocusItem(INCLUDE_SAVED_FOCUS)
    return selectedSavedSet and selectedSavedSet.control.savedSetIndex
end

function ZO_Dyeing_Gamepad:GetSelectedDyeIndex()
    if self.selectionMode == SELECTION_SAVED_SWATCH then
        return self.rightPaneDyesList:GetSelectedDyeIndex()
    else
        return self.dyesList:GetSelectedDyeIndex()
    end
end

function ZO_Dyeing_Gamepad:SwitchToDyeingWithDyeIndex(...)
    self.dyesList:SwitchToDyeingWithDyeIndex(...)
    self:SwitchToTab(DYE_TAB_INDEX)
    self:SwitchToActiveRadialMenuMode(RETAIN_SELECTIONS)
    self:SetupCenterSwatch()
end

function ZO_Dyeing_Gamepad:SetSelectedSavedSetIndex(dyeSetIndex)
    -- Unlike PC, this callback will copy the saved set to another saved set, rather than
    --  select the saved set.
    SetSavedDyeSetDyes(dyeSetIndex, GetSavedDyeSetDyes(self:GetSelectedSavedSetIndex()))
    self:RefreshSavedSet(dyeSetIndex)
    PlaySound(SOUNDS.DYEING_TOOL_SET_FILL_USED)
end

function ZO_Dyeing_Gamepad:DefaultBack()
    if (self.activeTool == self.dyeTool) or (self.activeTool == self.fillTool) or (self.activeTool == self.setFillTool) then
        self:AttemptExit()
    else
        self:SwitchToTab(DYE_TAB_INDEX)
    end
end

function ZO_Dyeing_Gamepad:NavigateBack()
    self.suppressToolSounds = false
    if (self.selectionMode == SELECTION_DYE) or (self.selectionMode == SELECTION_SAVED) then
        self:DefaultBack()

    elseif (self.selectionMode == SELECTION_EQUIP) then
        if self.activeTool:HasSwatchSelection() then
            self:SwitchToDyeSelection(RETAIN_SELECTIONS)
            PlaySound(SOUNDS.DYEING_TOOL_DYE_SELECTED)
        elseif self.activeTool:HasSavedSetSelection() then
            self:SwitchToSavedSelection(RETAIN_SELECTIONS)
            PlaySound(SOUNDS.DYEING_TOOL_SET_FILL_SELECTED)
        else
            self:DefaultBack()
        end

    elseif self.selectionMode == SELECTION_EQUIP_COLOR then
        if self.activeSlotControl then
            self.activeSlotControl:Deactivate(retainSelections)
            self.activeSlotControl = nil
        end
        self:SwitchToEquipmentSelection(RETAIN_SELECTIONS)

    elseif self.selectionMode == SELECTION_EQUIP_MULTICOLOR then
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

function ZO_Dyeing_Gamepad:ActivateCurrentSelection()
    if (self.selectionMode == SELECTION_DYE) or (self.selectionMode == SELECTION_SAVED) then
        self:SetupCenterSwatch()

        local highlightSlot, highlightDyeChannel = self.activeTool:GetHighlightRules(CHECK_SLOT, CHECK_CHANNEL)
        if (not highlightSlot) and highlightDyeChannel then
            -- Tool selects all equip slots at once, but only a single channel. This is currently
            --  only supported for equipment selection.
            self:SwitchToEquipmentDyeMultiSelection()

        elseif highlightSlot or highlightDyeChannel then
            -- Tool wants a specific slot or a specific channel or both.
            self:SwitchToActiveRadialMenuMode(RETAIN_SELECTIONS)

        else
            -- Tool selects all equip slots and channels at once.
            -- TODO: Implement if this becomes a valid option.
            assert(false)
        end

    elseif self.selectionMode == SELECTION_EQUIP then
        local selectedEntry = self.equipmentMenu.selectedEntry
        if not selectedEntry then
            -- It should be impossible to get to this state as CanActivateCurrentSelection should
            --  return false in this case.
            assert(false)
        else
            local equipSlot = selectedEntry.data.equipSlot
            if equipSlot and IsItemDyeable(BAG_WORN, equipSlot) then
                local highlightSlot, highlightDyeChannel = self.activeTool:GetHighlightRules(equipSlot, CHECK_CHANNEL)
                if highlightSlot and highlightDyeChannel then
                    -- Tool wants a specific equipment slot and channel selection,
                    --  so move on to selecting a channel.
                    self:SwitchToEquipmentDyeSelection()
                elseif highlightSlot then
                    -- Tool selects all channels at once, so just activate the tool.
                    self.activeTool:OnEquipSlotLeftClicked(equipSlot, nil)
                elseif highlightDyeChannel then
                    -- Tool selects all equip slots at once, but only a single channel.
                    self:SwitchToEquipmentDyeMultiSelection()
                else
                    -- Tool selects all equip slots and channels at once.
                    -- TODO: Implement if this becomes a valid option.
                    assert(false)
                end
            end
        end

    elseif self.selectionMode == SELECTION_EQUIP_COLOR then
        local selectedEntry = self.equipmentMenu.selectedEntry
        local selectedEquipSlot = selectedEntry and selectedEntry.data.equipSlot

        local selectedChannelData = self.activeSlotControl.dyeSelector:GetFocusItem()
        local selectedChannel = selectedChannelData.slotIndex

        self.activeTool:OnEquipSlotLeftClicked(selectedEquipSlot, selectedChannel)

    elseif self.selectionMode == SELECTION_EQUIP_MULTICOLOR then
        local selectedChannelData = self.channelMultiFocus:GetFocusItem()
        local selectedChannel = selectedChannelData.slotIndex

        self.activeTool:OnEquipSlotLeftClicked(nil, selectedChannel)
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

function ZO_Dyeing_Gamepad:CanActivateCurrentSelection()
    if self.selectionMode == SELECTION_DYE then
        local selectedSwatch = self.dyesList:GetSelectedSwatch()
        return selectedSwatch and (not selectedSwatch.locked)

    elseif self.selectionMode == SELECTION_SAVED then
        local selectedSet = self.savedSetFocusList:GetFocusItem()
        return selectedSet ~= nil

    elseif self.selectionMode == SELECTION_EQUIP then
        local selectedEntry = self.equipmentMenu.selectedEntry
        if not selectedEntry then
            return false
        end

        local equipSlot = selectedEntry.data.equipSlot
        if not equipSlot then
            return true
        end

        if not IsItemDyeable(BAG_WORN, equipSlot) then
            return false
        end

        local stackCount = select(2, GetItemInfo(BAG_WORN, equipSlot))
        return stackCount ~= 0
    elseif (self.selectionMode == SELECTION_EQUIP_COLOR) then
        if not self.activeSlotControl then
            return false
        end
        local selectedChannelData = self.activeSlotControl.dyeSelector:GetFocusItem()
        local selectedChannel = selectedChannelData and selectedChannelData.slotIndex
        return (selectedChannel ~= nil)

    elseif self.selectionMode == SELECTION_EQUIP_MULTICOLOR then
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

function ZO_Dyeing_Gamepad:UpdateDirectionalInput()
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

function ZO_Dyeing_Gamepad:CommitSelection()
    if ZO_Dyeing_AreAllItemsBound() then
        self:ConfirmCommitSelection()
        PlaySound(SOUNDS.DYEING_APPLY_CHANGES)
    else
        ZO_Dialogs_ShowGamepadDialog("CONFIRM_APPLY_DYE")
    end
end

function ZO_Dyeing_Gamepad:ConfirmCommitSelection()
    ApplyPendingDyes()
    ZO_Dyeing_CopyExistingDyesToPending()
    self:OnPendingDyesChanged()
    self:SwitchToTab(DYE_TAB_INDEX)
    self:SwitchToDyeSelection()
end

function ZO_Dyeing_Gamepad:SwitchToTab(tabIndex)
    self.suppressToolSounds = false
    ZO_GamepadGenericHeader_SetActiveTabIndex(self.header, tabIndex)
end

function ZO_Dyeing_Gamepad:SwitchToTool(newTool)
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

    function ZO_Dyeing_Gamepad:OnDyeListMoveOut(direction, rowIndex, colIndex)
        if direction == ZO_DYEING_SWATCHES_MOVE_OUT_DIRECTION_UP then
            local presetToSelect = zo_floor((colIndex - 1) / PRESET_SWATCH_WIDTH_RATIO) + 1
            presetToSelect = zo_clamp(presetToSelect, 1, GetNumSavedDyeSets())
            self.savedSetFocusList:SetFocusByIndex(presetToSelect)
            self:SwitchToTab(FILL_SET_TAB_INDEX)
        end
    end

    function ZO_Dyeing_Gamepad:OnSavedSetListMoveOut()
        local colIndex = self.savedSetFocusList:GetFocus()
        if colIndex then
            self.dyesList:SetSelectedDyeColumn(zo_ceil((colIndex - 1) * PRESET_SWATCH_WIDTH_RATIO) + 1)
        end
        self:SwitchToTab(DYE_TAB_INDEX)
    end
end

function ZO_Dyeing_Gamepad:OnDyeSelectionChanged(previousSwatch, newSwatch)
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

function ZO_Dyeing_Gamepad:CancelExit()
    MAIN_MENU_MANAGER:CancelBlockingSceneNextScene()
end

function ZO_Dyeing_Gamepad:AttemptExit()
    if ZO_Dyeing_AreTherePendingDyes() then
        ZO_Dialogs_ShowGamepadDialog("EXIT_DYE_UI_DISCARD_GAMEPAD")
    else
        self:ExitWithoutSave()
    end
end

function ZO_Dyeing_Gamepad:ExitWithoutSave()
    SCENE_MANAGER:ShowBaseScene()
end

function ZO_Dyeing_Gamepad:OnPendingDyesChanged(equipSlot)
    self.equipmentMenu:PerformLayout()

    if SCENE_MANAGER:IsShowing("dyeing_gamepad") then
        self:RefreshKeybindStrip()
    end
end

function ZO_Dyeing_Gamepad:OnSavedSetSlotChanged(dyeSetIndex)
    if dyeSetIndex then
        self:RefreshSavedSet(dyeSetIndex)
    else
        self:RefreshSavedSets()
    end
    self:RefreshKeybindStrip()
end

local function GetDyeColor(dyeIndex)
    if dyeIndex then
        local _, _, _, _, _, r, g, b, _ = GetDyeInfo(dyeIndex)
        return r, g, b, 1
    else
        return 0, 0, 0, 1
    end
end

function ZO_Dyeing_Gamepad:ClearCenterSwatch()
    self.centerSwatch:SetColor(1, 1, 1, 1)
    self.centerSwatch:SetTexture(NO_COLOR_CENTER_SWATCH)
    self.centerSwatch:SetHidden(false)
    self.centerSwatchSaved:SetHidden(true)
end

function ZO_Dyeing_Gamepad:SetupCenterSwatch()
    if (self.activeTool == self.dyeTool) or (self.activeTool == self.fillTool) then
        local dyeIndex = self.dyesList:GetSelectedDyeIndex()
        if dyeIndex then
            local r, g, b, a = GetDyeColor(dyeIndex)
            self.centerSwatch:SetColor(r, g, b, a)
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
                local dyeIndex = select(i, GetSavedDyeSetDyes(selectedSavedSetIndex))
                local r, g, b, a = GetDyeColor(dyeIndex)
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

function ZO_Dyeing_Gamepad:SetupRandomizeSwatch()
    self.centerSwatchSaved:GetNamedChild("Primary"):SetTexture(PRIMARY_COLOR_SWATCH_NO_POINT)
    self.centerSwatchSaved:GetNamedChild("Keybind"):SetHidden(true)
    local dyeInfo = {GetPendingEquippedItemDye(EQUIP_SLOT_HEAD)}
    for i=1, #self.centerSwatchSaved.dyeControls do
        local dyeIndex = dyeInfo[i]
        local r, g, b, a = GetDyeColor(dyeIndex)
        local control = self.centerSwatchSaved.dyeControls[i]
        control:SetColor(r, g, b, a)
    end

    self.centerSwatch:SetHidden(true)
    self.centerSwatchSaved:SetHidden(false)
end

function ZO_Dyeing_Gamepad:RefreshVisibleRadialMenuSelection()
    if self.visibleRadialMenu then
        self:RadialMenuSelectionChanged(self.visibleRadialMenu.selectedEntry)
    else
        self:RadialMenuSelectionChanged(nil)
    end
end

function ZO_Dyeing_Gamepad:RadialMenuSelectionChanged(selectedEntry)
    if (self.equipMenuSelectedEntry == selectedEntry) and (self.lastUpdateMode == self.selectionMode) then return end
    self.equipMenuSelectedEntry = selectedEntry
    self.lastUpdateMode = self.selectionMode

    self:RefreshKeybindStrip()
    self.rightTipContents:ClearLines()

    if (self.selectionMode == SELECTION_EQUIP) or (self.selectionMode == SELECTION_EQUIP_COLOR) then
        if selectedEntry and selectedEntry.data.equipSlot then
            -- User has an equipment slot selected.
            local data = selectedEntry.data
            local equipSlot = data.equipSlot

            local itemLink = GetItemLink(BAG_WORN, equipSlot)
            local icon, stackCount, sellPrice, meetsUsageRequirement, locked, equipType, itemStyle, quality = GetItemInfo(BAG_WORN, equipSlot)
            if stackCount == 0 then
                -- No item is equipped in the slot.
                icon = ZO_Character_GetEmptyEquipSlotTexture(equipSlot)
                local slotName = zo_strformat(SI_CHARACTER_EQUIP_SLOT_FORMAT, GetString("SI_EQUIPSLOT", equipSlot))
                self.rightTipContents:AddItemTitle(itemLink, slotName)
            else
                -- An item is equipped in the slot.
                self.rightTipContents:AddItemTitle(itemLink)
                self.rightTipContents:AddBaseStats(itemLink)
                self.rightTipContents:AddConditionBar(itemLink)
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
            -- User has no selection on the equipment selection pane.
            self.rightTipImage:SetHidden(true)
            self.rightTipSwap:SetHidden(true)

        end
    elseif self.selectionMode == SELECTION_EQUIP_MULTICOLOR then
        -- TODO: What tooltip in this case?
        self.rightTipImage:SetHidden(true)
        self.rightTipSwap:SetHidden(true)

    else
        self.rightTipImage:SetHidden(true)
        self.rightTipSwap:SetHidden(true)
    end
end

function ZO_Dyeing_Gamepad:RefreshEquipSlotDyes(equipSlot)
    ZO_Dyeing_RefreshEquipControlDyes(slotControl, equipSlot)
end

function ZO_Dyeing_Gamepad_OnInitialized(control)
    DYEING_GAMEPAD = ZO_Dyeing_Gamepad:New(control)
    SYSTEMS:RegisterGamepadObject("dyeing", DYEING_GAMEPAD)
end