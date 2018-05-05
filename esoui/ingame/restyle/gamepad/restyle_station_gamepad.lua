local ACTION_NONE = 0
local ACTION_STYLES = 1
local ACTION_DYES = 2

local OUTFIT_SWATCH_SLOT_ANCHOR_PADDING = 2

ZO_Restyle_Station_Gamepad = ZO_Gamepad_MultiFocus_ParametricList_Screen:Subclass()

function ZO_Restyle_Station_Gamepad:New(...)
    return ZO_Gamepad_MultiFocus_ParametricList_Screen.New(self, ...)
end

function ZO_Restyle_Station_Gamepad:Initialize(control)
    self.pendingLoopAnimationPool = ZO_MetaPool:New(ZO_Pending_Outfit_LoopAnimation_Pool)
    self.actionMode = ACTION_NONE
	
    GAMEPAD_RESTYLE_STATION_SCENE = ZO_InteractScene:New("gamepad_restyle_station", SCENE_MANAGER, ZO_DYEING_STATION_INTERACTION)
    SYSTEMS:RegisterGamepadRootScene("restyle_station", GAMEPAD_RESTYLE_STATION_SCENE)
    ZO_Gamepad_MultiFocus_ParametricList_Screen.Initialize(self, control, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE, nil, GAMEPAD_RESTYLE_STATION_SCENE)

    self:InitializeOptionsDialog()
    self:InitializeConfirmationDialog()

    local activeWeaponPair
    activeWeaponPair, self.weaponSwapDisabled = GetActiveWeaponPairInfo()

    GAMEPAD_RESTYLE_STATION_FRAGMENT = ZO_FadeSceneFragment:New(control)
    GAMEPAD_RESTYLE_STATION_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
            self:OnFragmentShowing()
        elseif newState == SCENE_FRAGMENT_HIDDEN then
            self:OnFragmentHidden()
        end
    end)

    local function OnOutfitPendingDataChanged(outfitIndex, slotIndex) 
        if not slotIndex and GAMEPAD_RESTYLE_STATION_SCENE:IsShowing() then
            self:Update()
        else
            self.dirty = true
        end
    end

    local function OnWeaponPairLockedChanged(event, disabled)
        self.weaponSwapDisabled = disabled
    end

    ZO_OUTFIT_MANAGER:RegisterCallback("PendingDataChanged", OnOutfitPendingDataChanged)
    control:RegisterForEvent(EVENT_CURRENCY_UPDATE, function(eventId, ...) self:OnCurrencyChanged(...) end)
    control:RegisterForEvent(EVENT_WEAPON_PAIR_LOCK_CHANGED, OnWeaponPairLockedChanged)
	
	control:SetHandler("OnUpdate", function(_, currentFrameTimeSeconds) self:OnUpdate(currentFrameTimeSeconds) end)
end

do
	local NEXT_WEAPON_STATE_EVALUATE_TIME_S = .25
	function ZO_Restyle_Station_Gamepad:OnUpdate(currentFrameTimeSeconds)
        local targetData = self.outfitSlotList:GetTargetData()
        if targetData then
            local outfitSlot = targetData.outfitSlot
            local areWeaponsSheathed = ArePlayerWeaponsSheathed()

            if ZO_OUTFIT_MANAGER:IsOutfitSlotWeapon(outfitSlot) then
                if not ZO_OUTFIT_MANAGER:IsWeaponOutfitSlotActive(outfitSlot) then
                    if not self.weaponSwapDisabled and GetUnitLevel("player") >= GetWeaponSwapUnlockedLevel() then
                        OnWeaponSwap()
                        -- Weapon swapping automatically unsheathes
                        return
                    end
                end

                if areWeaponsSheathed then
                    TogglePlayerWield()
                end
            else
                if not areWeaponsSheathed then
                    TogglePlayerWield()
                end
            end
        end

        -- We do this on an update loop because sometimes when changing target you aren't in a state where you're allowed to swap or unsheath
        -- So you could get yourself stuck into the wrong state
        self.nextWeaponStateEvaluateTimeS = GetFrameTimeSeconds() + NEXT_WEAPON_STATE_EVALUATE_TIME_S
    end
end

function ZO_Restyle_Station_Gamepad:OnShowing()
    self:UpdateCurrentOutfitIndex()
    KEYBIND_STRIP:RemoveDefaultExit()

    -- Always start on the list
    if not self:IsCurrentFocusArea(self.parametricListArea) then
        self.currentFocalArea = self.parametricListArea
    end

    ZO_Gamepad_MultiFocus_ParametricList_Screen.OnShowing(self)
end

function ZO_Restyle_Station_Gamepad:OnHide()
    ZO_Gamepad_MultiFocus_ParametricList_Screen.OnHide(self)

    local selectedControl = self.outfitSlotList:GetSelectedControl()
    if selectedControl then
        selectedControl.dyeSelectorFocus:Deactivate()
    end

    self.dyeAllFocus:Deactivate()

    self.outfitSlotList:Deactivate()

    local currentPanel = self:GetActionPanel(self.actionMode)
    if currentPanel:IsActive() then
        currentPanel:Deactivate()
    end

    self:SwitchToAction(ACTION_NONE)
end

function ZO_Restyle_Station_Gamepad:OnFragmentShowing()
    self:UpdateOutfitPreview()

    if self.currentOutfitManipulator then
        if self.currentOutfitManipulator:IsMarkedForPreservation() then
            self.currentOutfitManipulator:RestorePreservedDyeData()
            self.currentOutfitManipulator:UpdatePreviews()
        else
            self.currentOutfitManipulator:ClearPendingChanges()
        end
    end

    ZO_GamepadGenericHeader_Activate(self.header)

    self.outfitsPanel:OnShowing()
    self.dyeingPanel:OnShowing()

    self:RefreshHeader()
    self:RefreshFooter()

	if self.actionMode == ACTION_STYLES then
        self:UpdateOutfitsPanel()
    end
end

function ZO_Restyle_Station_Gamepad:OnFragmentHidden()
    self.outfitsPanel:OnHide()
    self.dyeingPanel:OnHide()

    ZO_GamepadGenericHeader_Deactivate(self.header)

    if self.currentOutfitManipulator then
        self.currentOutfitManipulator:ClearPendingChanges()
    end

    KEYBIND_STRIP:RestoreDefaultExit()
    if not ArePlayerWeaponsSheathed() then
        TogglePlayerWield()
    end
end

function ZO_Restyle_Station_Gamepad:OnDeferredInitialize()
    ZO_Gamepad_MultiFocus_ParametricList_Screen.OnDeferredInitialize(self)

    self:InitializeOutfitsPanel()
    self:InitializeDyesPanel()
    self:InitializeColorPresetControls()
    self:InitializeFoci()
    self:InitializeChangedDyeControlPool()

    ZO_GamepadGenericHeader_Initialize(self.header, ZO_GAMEPAD_HEADER_TABBAR_CREATE)

    local function UpdateCarriedCurrencyControl(control)
        ZO_CurrencyControl_SetSimpleCurrency(control, CURT_MONEY, GetCurrencyAmount(CURT_MONEY, CURRENCY_LOCATION_CHARACTER), ZO_GAMEPAD_CURRENCY_OPTIONS_LONG_FORMAT)
        return true
    end

    local stylesHeaderData = 
	{
		text = GetString(SI_GAMEPAD_DYEING_EQUIPMENT_ACTION_STYLES),
		callback = function() self:SwitchToAction(ACTION_STYLES) end,
        canSelect = true
	}

    local dyesHeaderData =
    {
		text = GetString(SI_GAMEPAD_DYEING_EQUIPMENT_ACTION_DYES),
		callback = function() self:SwitchToAction(ACTION_DYES) end,
        canSelect = true
	}

    self.outfitHeaderData = 
    {	
		tabBarEntries =
		{
			stylesHeaderData,
            dyesHeaderData
		}
    }

    self.defaultHeaderData =
    {
        tabBarEntries =
		{
            dyesHeaderData
        }
    }

    local function UpdateCarriedCurrencyControl(control)
        ZO_CurrencyControl_SetSimpleCurrency(control, CURT_MONEY, GetCurrencyAmount(CURT_MONEY, CURRENCY_LOCATION_CHARACTER), ZO_GAMEPAD_CURRENCY_OPTIONS_LONG_FORMAT)
        return true
    end

    local IS_PLURAL = false
    local IS_UPPER = false
    self.footerData =
    {
        data1HeaderText = GetCurrencyName(CURT_MONEY, IS_PLURAL, IS_UPPER),
        data1Text = UpdateCarriedCurrencyControl,
    }

    self:UpdateCurrentOutfitIndex()
end

function ZO_Restyle_Station_Gamepad:CreateApplyKeybind(multiFocusArea)
    return
    {
		name = function()
                    if self.currentOutfitManipulator then
						local slotsCost, flatCost = self.currentOutfitManipulator:GetAllCostsForPendingChanges()
                        if slotsCost > 0 then
						    local IS_GAMEPAD = true
						    local USE_SHORT_FORMAT = false
						    local formattedSlotsCurrency = ZO_CurrencyControl_FormatCurrencyAndAppendIcon(slotsCost, USE_SHORT_FORMAT, CURT_MONEY, IS_GAMEPAD)
						    local formattedFlatCurrency = ZO_CurrencyControl_FormatCurrencyAndAppendIcon(flatCost, USE_SHORT_FORMAT, CURT_STYLE_STONES, IS_GAMEPAD)
						    return zo_strformat(SI_OUTFIT_COMMIT_SELECTION, formattedSlotsCurrency, formattedFlatCurrency)
                        end
                    end

                    return GetString(SI_DYEING_COMMIT)
				end,
		keybind = "UI_SHORTCUT_SECONDARY",
		callback = function() 
                      self:CommitSelection()
                      multiFocusArea:UpdateActiveFocusKeybinds()
                   end,
		visible = function() return self:DoesHaveChanges() end,
        enabled = function() return self:CanApplyChanges() end,
	}
end

function ZO_Restyle_Station_Gamepad:CreateUndoKeybind(multiFocusArea)
    return
    {
		name = GetString(SI_DYEING_UNDO),
		keybind = "UI_SHORTCUT_LEFT_STICK",
		visible = function() return self:DoesHaveChanges() end,
		callback = function() 
                       self:ShowUndoPendingChangesDialog()
                       multiFocusArea:UpdateActiveFocusKeybinds()
                   end,
	}
end

function ZO_Restyle_Station_Gamepad:CreateRandomizeKeybind(multiFocusArea)
    return
    {
        name = function()
            if self.actionMode == ACTION_STYLES then
                return GetString(SI_OUTFIT_STYLES_RANDOMIZE)
            else
                return GetString(SI_DYEING_RANDOMIZE)
            end
        end,
        keybind = "UI_SHORTCUT_RIGHT_STICK",
        visible = function() return not (self.actionMode == ACTION_STYLES and RESTYLE_GAMEPAD:GetMode() == RESTYLE_MODE_EQUIPMENT) end,
        callback = function() 
                       self:RandomizeSelection() 
                       multiFocusArea:UpdateActiveFocusKeybinds()
                   end,
    }
end

function ZO_Restyle_Station_Gamepad:CreateOptionsKeybind()
    return
    {
		name = GetString(SI_GAMEPAD_DYEING_OPTIONS),
		keybind = "UI_SHORTCUT_TERTIARY",
        visible = function() return not (self.actionMode == ACTION_STYLES and RESTYLE_GAMEPAD:GetMode() == RESTYLE_MODE_EQUIPMENT) end,
		callback = function() ZO_Dialogs_ShowGamepadDialog("GAMEPAD_RESTYLE_STATION_OPTIONS", self:CreateOptionsDialogActions()) end,
	}
end

function ZO_Restyle_Station_Gamepad:CreateSpecialExitKeybind()
    return
    {
        --Ethereal binds show no text, the name field is used to help identify the keybind when debugging. This text does not have to be localized.
        name = "Gamepad Restyle Exit",
        keybind = "UI_SHORTCUT_EXIT",
        ethereal = true,
        callback = function() self:AttemptExit() end,
    }
end

function ZO_Restyle_Station_Gamepad:InitializeKeybindStripDescriptors()
    local function MultiFocusBack()
        if self.actionMode == ACTION_DYES then
            self:ActivateCurrentSelection()
        else
            self:AttemptExit()
        end
    end

    -- Apply
    local apply = self:CreateApplyKeybind(self)

    local specialExit = self:CreateSpecialExitKeybind()

    -- Main list
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        -- Back
        KEYBIND_STRIP:GenerateGamepadBackButtonDescriptor(MultiFocusBack),

        -- Select
        {
            name = function()
                        if self.actionMode == ACTION_DYES then
                            local activeTool = self.dyeingPanel:GetActiveDyeTool()
                            return GetString(activeTool:GetToolActionString())
                        else
                            return GetString(SI_GAMEPAD_SELECT_OPTION)
                        end
                  end,
            keybind = "UI_SHORTCUT_PRIMARY",
            visible = function() return not (self.actionMode == ACTION_STYLES and RESTYLE_GAMEPAD:GetMode() == RESTYLE_MODE_EQUIPMENT) end,
            callback = function()
                            self:HandleSelectAction()
                       end,
        },
		
		apply,

		-- Options
		self:CreateOptionsKeybind(),

		-- Undo All
		self:CreateUndoKeybind(self),

        -- Randomize
        self:CreateRandomizeKeybind(self),

        -- Special exit button
        specialExit,
    }

    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.keybindStripDescriptor, self.outfitSlotList)

    self.outfitKeybindDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        -- Back
        KEYBIND_STRIP:GenerateGamepadBackButtonDescriptor(MultiFocusBack),

        -- Select
        {
            name = GetString(SI_GAMEPAD_SELECT_OPTION),
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                            self:ShowOutfitSelection()
                       end
        },

        apply,

        -- Special exit button
        specialExit,
    }

    self.savedSetsKeybindDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        -- Back
        KEYBIND_STRIP:GenerateGamepadBackButtonDescriptor(MultiFocusBack),

        -- Select
        {
            name = function()
                        if self.actionMode == ACTION_DYES then
                            if self:ShouldShowSelectedDyeSet() then
                                return GetString(SI_GAMEPAD_DYEING_USE_SAVED_SET)
                            else
                                local activeTool = self.dyeingPanel:GetActiveDyeTool()
                                return GetString(activeTool:GetToolActionString())
                            end
                        else
                            return GetString(SI_GAMEPAD_SELECT_OPTION)
                        end
                  end,
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                            self:HandleSelectSavedSetAction()
                       end
        },

        -- Use Set
		{
			name = GetString(SI_GAMEPAD_DYEING_USE_SAVED_SET),
			keybind = "UI_SHORTCUT_TERTIARY",
			callback = function() 
                            self:HandleUseSetAction()
                       end,
            visible = function() return not self:ShouldShowAllDyeFoci() and not self:ShouldShowSelectedDyeSet() end,
		},

        -- Special exit button
        specialExit,
    }
end

function ZO_Restyle_Station_Gamepad:InitializeOutfitsPanel()
    self.outfitsPanel = ZO_OUTFITS_PANEL_GAMEPAD
    self.outfitsPanelFragmentGroup = { GAMEPAD_OUTFITS_GRID_LIST_PANEL_FRAGMENT, GAMEPAD_OUTFITS_GRID_LIST_FRAGMENT, GAMEPAD_NAV_QUADRANT_2_3_BACKGROUND_FRAGMENT }
    self.outfitsPanel:RegisterCallback("PanelSelectionEnd", function(...) self:OnPanelSelectionEnd(...) end)
end

function ZO_Restyle_Station_Gamepad:InitializeDyesPanel()
    self.dyeingPanel = ZO_DYEING_PANEL_GAMEPAD
    self.dyeingPanelFragmentGroup = { GAMEPAD_DYEING_SLOTS_PANEL_FRAGMENT, GAMEPAD_DYES_GRID_LIST_FRAGMENT, GAMEPAD_DYE_TOOLS_GRID_LIST_FRAGMENT, GAMEPAD_NAV_QUADRANT_2_3_BACKGROUND_FRAGMENT }
    self.dyeingPanel:RegisterCallback("PanelSelectionEnd", function(...) self:OnPanelSelectionEnd(...) end)
    self.dyeingPanel:RegisterCallback("DyeSelected", function(...) self:OnDyeSelected(...) end)
    self.dyeingPanel:RegisterCallback("ToolSelected", function(...) self:OnDyeToolSelected(...) end)
    self.dyeingPanel:RegisterCallback("PendingDyesChanged", function(...) self:OnPendingDyesChanged(...) end)
    self.dyeingPanel:RegisterCallback("SavedSetSlotChanged", function(...) self:OnSavedSetSlotChanged(...) end)

    local function HighlightAllSlots(entry)
        if entry then
            self:HighlightAllFociByChannel(entry.dyeChannel)
        else
            self:ResetHighlightAllFoci()
        end
    end

    self.dyeAllFocus = ZO_GamepadFocus:New(self.control, nil, MOVEMENT_CONTROLLER_DIRECTION_HORIZONTAL)
    self.dyeAllFocus:SetFocusChangedCallback(HighlightAllSlots)
    for i = 1, 3 do 
        local entry = { dyeChannel = i }
        self.dyeAllFocus:AddEntry(entry)
    end
end

function ZO_Restyle_Station_Gamepad:InitializeColorPresetControls()
    self.savedPresetsControl = self.header:GetNamedChild("SavedPresets")
    self.savedPresetsControl.highlight = self.savedPresetsControl:GetNamedChild("SharedHighlight")
    self.savedSets = {}
    self.savedSetFocus = ZO_GamepadFocus:New(self.control, nil, MOVEMENT_CONTROLLER_DIRECTION_HORIZONTAL)
    self.savedSetChannelFocus = ZO_GamepadFocus:New(self.control, nil, MOVEMENT_CONTROLLER_DIRECTION_HORIZONTAL)
    self.savedSetDyeAllChannelFocus = ZO_GamepadFocus:New(self.control, nil, MOVEMENT_CONTROLLER_DIRECTION_HORIZONTAL)

    local numSavedSets = GetNumSavedDyeSets()
    local padding
    for i = 1, numSavedSets do
        local newControl = CreateControlFromVirtual("$(parent)Preset", self.savedPresetsControl, "ZO_DyeingSwatchPreset_Gamepad", i)
        local controlWidth = newControl:GetDimensions()
        if not padding then
            local availableWidth = ZO_GAMEPAD_CONTENT_WIDTH - (controlWidth * numSavedSets)
            padding = availableWidth / (numSavedSets + 1) -- We want padding on left and right.
        end

        newControl:SetAnchor(TOPLEFT, self.savedPresetsControl, TOPLEFT, (padding + controlWidth) * (i - 1), 0)
        newControl.savedSetIndex = i
        table.insert(self.savedSets, newControl)

        self:RefreshSavedSet(i)
        local entry = 
        {
            control = newControl,
            highlight = newControl:GetNamedChild("Highlight"),
        }
        self.savedSetFocus:AddEntry(entry)

        for _, dyeChannelControl in ipairs(newControl.dyeControls) do
            dyeChannelControl.channelHighlight = dyeChannelControl:GetNamedChild("Highlight")
            local entry = 
            {
                control = dyeChannelControl,
                highlight = dyeChannelControl.channelHighlight,
            }
            self.savedSetChannelFocus:AddEntry(entry)
        end
    end

    for i = 1, 3 do
        local dyeControlsForChannel = {}
        for j = 1, numSavedSets do
            local dyeChannelControl = self.savedSets[j].dyeControls[i]
            table.insert(dyeControlsForChannel, dyeChannelControl)
        end

        local entry = 
        {
            data = dyeControlsForChannel,
            activate = function(control, data)
                            for _, dyeChannelControl in ipairs(data) do
                                dyeChannelControl.channelHighlight:SetAlpha(1)
                            end
                       end,
            deactivate = function(control, data)
                            for _, dyeChannelControl in ipairs(data) do
                                dyeChannelControl.channelHighlight:SetAlpha(0)
                            end
                       end,
        }

        self.savedSetDyeAllChannelFocus:AddEntry(entry)
    end
end

local GamepadMultiFocusArea_SavedSets = ZO_GamepadMultiFocusArea_Base:Subclass()

function GamepadMultiFocusArea_SavedSets:CanBeSelected()
    return self.manager.actionMode == ACTION_DYES
end

local GamepadMultiFocusArea_OutfitSelector = ZO_GamepadMultiFocusArea_Base:Subclass()

function GamepadMultiFocusArea_OutfitSelector:CanBeSelected()
    return RESTYLE_GAMEPAD:GetMode() ~= RESTYLE_MODE_COLLECTIBLE
end

function ZO_Restyle_Station_Gamepad:InitializeFoci()
    local function SetActivateCallback()
        if self:ShouldShowAllDyeFoci() then
            self.activeSavedSetsFocus = self.savedSetDyeAllChannelFocus
        elseif self:ShouldShowSelectedDyeSet() then
            self.activeSavedSetsFocus = self.savedSetFocus
        else
            self.activeSavedSetsFocus = self.savedSetChannelFocus
        end
        self.activeSavedSetsFocus:Activate()
    end

    local function SetDeactivateCallback()
        if self.activeSavedSetsFocus then
            self.activeSavedSetsFocus:Deactivate()
            self.activeSavedSetsFocus = nil
        end
    end

    self.savedSetsHeaderFocus = GamepadMultiFocusArea_SavedSets:New(self, SetActivateCallback, SetDeactivateCallback)
    self.savedSetsHeaderFocus:SetKeybindDescriptor(self.savedSetsKeybindDescriptor)
    self:AddPreviousFocusArea(self.savedSetsHeaderFocus)
    self.savedPresetsControl:SetHidden(true)

    self.outfitSelectorControl = self.header:GetNamedChild("OutfitSelector")
    self.outfitSelectorNameLabel = self.outfitSelectorControl:GetNamedChild("OutfitName")

    local function OutfitActivateCallback()
        GAMEPAD_TOOLTIPS:ClearLines(GAMEPAD_LEFT_TOOLTIP)
        self.outfitSelectorNameLabel:SetColor(ZO_SELECTED_TEXT:UnpackRGBA())
    end

    local function OutfitDeactivateCallback()
        self.outfitSelectorNameLabel:SetColor(ZO_DISABLED_TEXT:UnpackRGBA())
    end

    self.outfitSelectorHeaderFocus = GamepadMultiFocusArea_OutfitSelector:New(self, OutfitActivateCallback, OutfitDeactivateCallback)
    self.outfitSelectorHeaderFocus:SetKeybindDescriptor(self.outfitKeybindDescriptor)
    self:AddPreviousFocusArea(self.outfitSelectorHeaderFocus)
    self.outfitSelectorNameLabel:SetColor(ZO_DISABLED_TEXT:UnpackRGBA())
end

function ZO_Restyle_Station_Gamepad:InitializeChangedDyeControlPool()
    self.dyeChangedControlPool = ZO_ControlPool:New("ZO_DyeingChangedHighlight_Gamepad", GuiRoot, "DyeSlotChanged_Gamepad")

    local function CustomResetFunction(control)
        control:SetColor(ZO_DEFAULT_ENABLED_COLOR:UnpackRGB())
    end

    self.dyeChangedControlPool:SetCustomResetBehavior(CustomResetFunction)
end

function ZO_Restyle_Station_Gamepad:UpdateDyeSlotChangedOnControl(control, hasChanged)
    if control.dyeChangedControlKey and not hasChanged then
        self.dyeChangedControlPool:ReleaseObject(control.dyeChangedControlKey)
        control.dyeChangedControlKey = nil
        control.dyeChangedControl = nil
    elseif not control.dyeChangedControlKey and hasChanged then
        local dyeChangedControl, key = self.dyeChangedControlPool:AcquireObject()
        dyeChangedControl:SetAnchor(TOPLEFT, control, TOPLEFT, -OUTFIT_SWATCH_SLOT_ANCHOR_PADDING, -OUTFIT_SWATCH_SLOT_ANCHOR_PADDING)
        dyeChangedControl:SetAnchor(BOTTOMRIGHT, control, BOTTOMRIGHT, OUTFIT_SWATCH_SLOT_ANCHOR_PADDING, OUTFIT_SWATCH_SLOT_ANCHOR_PADDING)
        dyeChangedControl:SetParent(control)
        dyeChangedControl:SetHidden(false)
        dyeChangedControl:SetColor(ZO_DYEING_OUTFIT_SWATCH_CHANGED_COLOR:UnpackRGB())
        control.dyeChangedControlKey = key
        control.dyeChangedControl = dyeChangedControl
    end
end

function ZO_Restyle_Station_Gamepad:SetupList(list)
    self.outfitSlotList = list

    local function SetupSlotEntry(control, data, selected, reselectingDuringRebuild, enabled, active)
        ZO_SharedGamepadEntry_OnSetup(control, data, selected, reselectingDuringRebuild, enabled, active)

        local isDyeable = IsRestyleSlotTypeDyeable(RESTYLE_GAMEPAD:GetMode(), data.restyleIndex)
        local showSlots = (selected and isDyeable) or self:ShouldShowAllDyeFoci()
        local changedDyeChannels = data.restyleSlotData:GetDyeChannelChangedStates()
        control.slotDyes:SetHidden(not showSlots)
        if showSlots then
            ZO_Dyeing_RefreshDyeableSlotControlDyes(control.dyeControls, data.restyleSlotData)
        end

        for i, hasChanged in ipairs(changedDyeChannels) do
            self:UpdateDyeSlotChangedOnControl(control.dyeControls[i], hasChanged and showSlots) -- if we are not showing Slots, hide all active dyeChangedControls
        end


        if data.restyleSlotData:IsDataDyeable() then
            if self:ShouldShowAllDyeFoci() then
                local dyeChannel = self.dyeAllFocus:GetFocus()
                if dyeChannel then
                    ZO_Dyeing_Gamepad_OutfitSwatchSlot_Highlight_Only(control, dyeChannel)
                end
            elseif self:ShouldShowSelectedDyeSet() then
                if selected then
                    ZO_Dyeing_Gamepad_OutfitSwatchSlot_Highlight_All(control)
                end
            else
                local dyeChannel = control.dyeSelectorFocus:GetFocus()
                if dyeChannel then
                    ZO_Dyeing_Gamepad_OutfitSwatchSlot_Highlight_Only(control, dyeChannel)
                end
            end
        end
    end

    local function SetupOutfitSlotEntry(control, data, selected, reselectingDuringRebuild, enabled, active)
        local slotManipulator = data.slotManipulator
        data:ClearIcons()
        data:AddIcon(slotManipulator:GetSlotAppropriateIcon())

        SetupSlotEntry(control, data, selected, reselectingDuringRebuild, enabled, active)

        if slotManipulator:IsAnyChangePending() then
            local individualCost = slotManipulator:GetPendingChangeCost()
            ZO_CurrencyControl_SetSimpleCurrency(control.priceLabel, CURT_MONEY, individualCost, ZO_GAMEPAD_CURRENCY_OPTIONS)
        else
            control.priceLabel:SetText("")
        end

        local appropriateCollectibleId = slotManipulator:GetPendingCollectibleId()
        if appropriateCollectibleId > 0 then
            local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(appropriateCollectibleId)
            ZO_Restyle_Station_Gamepad_SetOutfitEntryBorder(control, collectibleData, slotManipulator, self.pendingLoopAnimationPool)
            control.borderBackground:SetHidden(false)
        else
            ZO_Restyle_Station_Gamepad_CleanupAnimationOnControl(control, self.pendingLoopAnimationPool)
            control.borderBackground:SetHidden(true)
        end
    end

    local function ResetSlotEntry(control)
        control.dyeSelectorFocus:Deactivate()
        ZO_Dyeing_Gamepad_OutfitSwatchSlot_Reset_Highlight(control)
    end

    local function ResetOutfitSlotEntry(control)
        ResetSlotEntry(control)
        ZO_Restyle_Station_Gamepad_CleanupAnimationOnControl(control, self.pendingLoopAnimationPool)
    end

    list:SetAlignToScreenCenter(true)
    local EQUALITY_FUNCTION = nil
    local CONTROL_POOL_PREFIX = nil
    list:AddDataTemplate("ZO_RestyleSlot_EntryTemplate_Gamepad", SetupSlotEntry, ZO_GamepadMenuEntryTemplateParametricListFunction, EQUALITY_FUNCTION, CONTROL_POOL_PREFIX, ResetSlotEntry)
    list:AddDataTemplate("ZO_OutfitSlot_EntryTemplate_Gamepad", SetupOutfitSlotEntry, ZO_GamepadMenuEntryTemplateParametricListFunction, EQUALITY_FUNCTION, CONTROL_POOL_PREFIX, ResetOutfitSlotEntry)
    list:AddDataTemplateWithHeader("ZO_OutfitSlot_EntryTemplate_Gamepad", SetupOutfitSlotEntry, ZO_GamepadMenuEntryTemplateParametricListFunction, EQUALITY_FUNCTION, "ZO_GamepadMenuEntryHeaderTemplate", HEADER_SETUP_FUNCTION, CONTROL_POOL_PREFIX, ResetOutfitSlotEntry)
    list:SetOnSelectedDataChangedCallback(function(list, selectedData, oldData) self:OnSlotChanged(oldData, selectedData) end)
end

function ZO_Restyle_Station_Gamepad:InitializeOptionsDialog()
    ZO_Dialogs_RegisterCustomDialog("GAMEPAD_RESTYLE_STATION_OPTIONS",
    {
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
        },
        title =
        {
            text = SI_GAMEPAD_OUTFITS_OPTIONS_HEADER
        },
        setup = function(dialog, allActions)
            local parametricList = dialog.info.parametricList
            ZO_ClearNumericallyIndexedTable(parametricList)

            for i, action in ipairs(allActions) do
                local entryData = ZO_GamepadEntryData:New(action.text)
                entryData.action = action
                entryData.setup = action.setup or ZO_SharedGamepadEntry_OnSetup
                entryData.callback = action.callback

                local listItem =
                {
                    template = action.template or "ZO_GamepadItemEntryTemplate",
                    entryData = entryData,
                    header = action.header,
                }

                table.insert(parametricList, listItem)
            end

            dialog:setupFunc()
        end,
        parametricList = {}, -- Generated Dynamically
        
        blockDialogReleaseOnPress = true,
        buttons = 
        {
            {
                keybind = "DIALOG_PRIMARY",
                text = SI_GAMEPAD_SELECT_OPTION,
                callback = function(dialog)
                    local targetData = dialog.entryList:GetTargetData()
                    if targetData and targetData.callback then
                        targetData.callback(dialog)
                    end
                end,
            },
            {
                keybind = "DIALOG_NEGATIVE",
                text = SI_GAMEPAD_BACK_OPTION,
                callback =  function(dialog)
                    ZO_Dialogs_ReleaseDialogOnButtonPress("GAMEPAD_RESTYLE_STATION_OPTIONS")
                end,
            },     
        },
        noChoiceCallback = function(dialog)
            local parametricList = dialog.info.parametricList
            for i, entry in ipairs(parametricList) do
                if entry.entryData.action.isDropdown then
                    local control = dialog.entryList:GetControlFromData(entry.entryData)
                    control.dropdown:Deactivate()
                end
            end
        end
    })
end

function ZO_Restyle_Station_Gamepad:CreateOptionActionDataClear(slotManipulator)
    return
    {
        template = "ZO_GamepadItemEntryTemplate",
        text = GetString(SI_OUTFIT_SLOT_CLEAR_ACTION),
        callback = function(dialog)
            slotManipulator:Clear()
            self:GetMainList():RefreshVisible()
            self:UpdateOutfitsPanel()
            ZO_Dialogs_ReleaseDialogOnButtonPress("GAMEPAD_RESTYLE_STATION_OPTIONS")
        end,
    }
end

function ZO_Restyle_Station_Gamepad:CreateOptionActionDataUndo(slotManipulator)
    return
    {
        template = "ZO_GamepadItemEntryTemplate",
        text = GetString(SI_OUTFIT_SLOT_UNDO_ACTION),
        callback = function(dialog)
            slotManipulator:ClearPendingChanges()
            self:GetMainList():RefreshVisible()
            self:UpdateOutfitsPanel()
            ZO_Dialogs_ReleaseDialogOnButtonPress("GAMEPAD_RESTYLE_STATION_OPTIONS")
        end,
    }
end

function ZO_Restyle_Station_Gamepad:CreateOptionActionDataHide(slotManipulator, hiddenCollectibleId)
    return
    {
        template = "ZO_GamepadItemEntryTemplate",
        text = GetString(SI_OUTFIT_SLOT_HIDE_ACTION),
        callback = function(dialog)
            slotManipulator:SetPendingCollectibleIdAndItemMaterialIndex(hiddenCollectibleId, ZO_OUTFIT_STYLE_DEFAULT_ITEM_MATERIAL_INDEX)
            self:GetMainList():RefreshVisible()
            self:UpdateOutfitsPanel()
            ZO_Dialogs_ReleaseDialogOnButtonPress("GAMEPAD_RESTYLE_STATION_OPTIONS")
        end,
    }
end

function ZO_Restyle_Station_Gamepad:CreateOptionActionDataChangeMaterial(slotManipulator, collectibleData)
    return
    {
        template = "ZO_GamepadItemEntryTemplate",
        text = GetString(SI_OUTFIT_SLOT_CHANGE_MATERIAL_ACTION),
        callback = function(dialog)
            ZO_Dialogs_ReleaseDialogOnButtonPress("GAMEPAD_RESTYLE_STATION_OPTIONS")
            ZO_Dialogs_ShowGamepadDialog("GAMEPAD_OUTFIT_ITEM_MATERIAL_OPTIONS", { slotManipulator = slotManipulator, selectedData = collectibleData })
        end,
    }
end

do
    local DYE_SORTING_DROPDOWN_ACTION_DATA
    function ZO_Restyle_Station_Gamepad:CreateOptionActionDataDyeSortingDropdown()
        if not DYE_SORTING_DROPDOWN_ACTION_DATA then
            DYE_SORTING_DROPDOWN_ACTION_DATA = 
            {
                template = "ZO_Gamepad_Dropdown_Item_Indented",
                header = GetString(SI_GAMEPAD_DYEING_SORT_OPTION_HEADER),
                setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                    ZO_SharedGamepadEntry_OnSetup(control, data, selected, selectedDuringRebuild, enabled, activated)
                    control.dropdown:SetSortsItems(false)
                    self:UpdateDyeSortingDropdownOptions(control.dropdown)
                end,
                callback = function(dialog)
                    local targetControl = dialog.entryList:GetTargetControl()
                    targetControl.dropdown:Activate()
                end,
                isDropdown = true,
            }
        end

        return DYE_SORTING_DROPDOWN_ACTION_DATA
    end
end

function ZO_Restyle_Station_Gamepad:UpdateDyeSortingDropdownOptions(dropdown)
    dropdown:ClearItems()

    local function SelectNewSort(style)
        ZO_DYEING_MANAGER:SetSortStyle(style)
    end

    dropdown:AddItem(ZO_ComboBox:CreateItemEntry(GetString(SI_DYEING_SORT_BY_RARITY), function() SelectNewSort(ZO_DYEING_SORT_STYLE_RARITY) end), ZO_COMBOBOX_SUPRESS_UPDATE)
    dropdown:AddItem(ZO_ComboBox:CreateItemEntry(GetString(SI_DYEING_SORT_BY_HUE), function() SelectNewSort(ZO_DYEING_SORT_STYLE_HUE) end), ZO_COMBOBOX_SUPRESS_UPDATE)

    dropdown:UpdateItems()

    local currentSortingStyle = ZO_DYEING_MANAGER:GetSortStyle()
    if currentSortingStyle == ZO_DYEING_SORT_STYLE_RARITY then
        dropdown:SetSelectedItemText(GetString(SI_DYEING_SORT_BY_RARITY))
    elseif currentSortingStyle == ZO_DYEING_SORT_STYLE_HUE then
        dropdown:SetSelectedItemText(GetString(SI_DYEING_SORT_BY_HUE))
    end
end


function ZO_Restyle_Station_Gamepad:CreateOptionActionDataDyeingShowLocked(optionalCallback)
    return
    {
        template = "ZO_CheckBoxTemplate_Gamepad",
        text = GetString(SI_RESTYLE_SHOW_LOCKED),
        setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
            ZO_GamepadCheckBoxTemplate_Setup(control, data, selected, reselectingDuringRebuild, enabled, active)
            if ZO_DYEING_MANAGER:GetShowLocked() then
                ZO_CheckButton_SetChecked(control.checkBox)
            else
                ZO_CheckButton_SetUnchecked(control.checkBox)
            end
        end,
        callback = function(dialog)
            local targetControl = dialog.entryList:GetTargetControl()
            ZO_GamepadCheckBoxTemplate_OnClicked(targetControl)
            ZO_DYEING_MANAGER:SetShowLocked(ZO_GamepadCheckBoxTemplate_IsChecked(targetControl))
            if optionalCallback then
                optionalCallback(dialog)
            end
        end,
    }
end

function ZO_Restyle_Station_Gamepad:CreateOptionActionDataOutfitStylesShowLocked(optionalCallback)
    return
    {
        template = "ZO_CheckBoxTemplate_Gamepad",
        text = GetString(SI_RESTYLE_SHOW_LOCKED),
        setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
            ZO_GamepadCheckBoxTemplate_Setup(control, data, selected, reselectingDuringRebuild, enabled, active)
            if ZO_OUTFIT_MANAGER:GetShowLocked() then
                ZO_CheckButton_SetChecked(control.checkBox)
            else
                ZO_CheckButton_SetUnchecked(control.checkBox)
            end
        end,
        callback = function(dialog)
            local targetControl = dialog.entryList:GetTargetControl()
            ZO_GamepadCheckBoxTemplate_OnClicked(targetControl)
            ZO_OUTFIT_MANAGER:SetShowLocked(ZO_GamepadCheckBoxTemplate_IsChecked(targetControl))
            if optionalCallback then
                optionalCallback(dialog)
            end
        end,
    }
end

function ZO_Restyle_Station_Gamepad:CreateOptionsDialogActions()
    local actionsTable = {}

    if self.actionMode == ACTION_STYLES then
        -- Show Locked Styles
        table.insert(actionsTable, self:CreateOptionActionDataOutfitStylesShowLocked())
    elseif self.actionMode == ACTION_DYES then
        -- Dye Sorting Options
        table.insert(actionsTable, self:CreateOptionActionDataDyeSortingDropdown())

        -- Show Locked Dyes
        table.insert(actionsTable, self:CreateOptionActionDataDyeingShowLocked())
    end
    local numBaseActions = #actionsTable

    if self:HasActiveFocus() then
        local currentlySelectedData = self.outfitSlotList:GetTargetData()
        local slotManipulator = currentlySelectedData.slotManipulator

        if slotManipulator then
            -- Undo
            if slotManipulator:IsSlotDataChangePending() then 
                table.insert(actionsTable, self:CreateOptionActionDataUndo(slotManipulator))
            end


            if slotManipulator:GetPendingCollectibleId() > 0 then
                -- Clear
                table.insert(actionsTable, self:CreateOptionActionDataClear(slotManipulator))
            end

            -- Hide
            local hiddenCollectibleId = GetOutfitSlotDataHiddenOutfitStyleCollectibleId(slotManipulator:GetOutfitSlotIndex())
            if hiddenCollectibleId > 0 and slotManipulator:GetPendingCollectibleId() ~= hiddenCollectibleId then
                local hiddenCollectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(hiddenCollectibleId)
                if hiddenCollectibleData:IsUnlocked() then
                    table.insert(actionsTable, self:CreateOptionActionDataHide(slotManipulator, hiddenCollectibleId))
                end
            end
        end
    end

    if #actionsTable > numBaseActions then
        actionsTable[numBaseActions + 1].header = GetString(SI_GAMEPAD_OUTFITS_SLOT_OPTIONS)
    end

    return actionsTable
end

function ZO_Restyle_Station_Gamepad:UpdateOutfitsPanel()
    local currentlySelectedData = self.outfitSlotList:GetTargetData()
    if currentlySelectedData then
        local slotManipulator = currentlySelectedData.slotManipulator
        if slotManipulator then
            self.outfitsPanel:SetSlotManipulator(slotManipulator)
        else
            GAMEPAD_TOOLTIPS:LayoutTitleAndDescriptionTooltip(GAMEPAD_LEFT_TOOLTIP, GetString(SI_GAMEPAD_OUTFITS_NO_OUTFIT_EQUIPPED_TITLE), GetString(SI_GAMEPAD_OUTFITS_NO_OUTFIT_EQUIPPED_DESCRIPTION))
        end
    else
        self.outfitsPanel:SetSlotManipulator(nil)
    end
end

function ZO_Restyle_Station_Gamepad:UpdateCurrentActionFragmentGroup()
    if self.actionMode == ACTION_STYLES and (self:IsCurrentFocusArea(self.outfitSelectorHeaderFocus) or RESTYLE_GAMEPAD:GetMode() == RESTYLE_MODE_EQUIPMENT) then
        SCENE_MANAGER:RemoveFragmentGroup(self:GetActionFragmentGroup(self.actionMode))
    else
        SCENE_MANAGER:AddFragmentGroup(self:GetActionFragmentGroup(self.actionMode))
    end
end

function ZO_Restyle_Station_Gamepad:PerformUpdate()
    self.outfitSlotList:Clear()

	local restyleMode = RESTYLE_GAMEPAD:GetMode()
	
    if restyleMode == RESTYLE_MODE_OUTFIT then
        local foundMainWeapons = false
        local foundBackupWeapons = false
        local mainHandOutfitSlot, offHandOutfitSlot, backupMainHandOutfitSlot, backupOffHandOutfitSlot = GetOutfitSlotsForEquippedWeapons()
        for outfitSlotIndex = OUTFIT_SLOT_ITERATION_BEGIN, OUTFIT_SLOT_ITERATION_END do
            local isArmor = ZO_OUTFIT_MANAGER:IsOutfitSlotArmor(outfitSlotIndex)
            local isEquippedWeapon = not isArmor and (mainHandOutfitSlot == outfitSlotIndex
                                     or offHandOutfitSlot == outfitSlotIndex
                                     or backupMainHandOutfitSlot == outfitSlotIndex
                                     or backupOffHandOutfitSlot == outfitSlotIndex)

            if isArmor or isEquippedWeapon then
                local slotManipulator = self.currentOutfitManipulator:GetSlotManipulator(outfitSlotIndex)
                local appropriateCollectibleId = slotManipulator:GetPendingCollectibleId()
                local isWeaponSlotMain = ZO_OUTFIT_MANAGER:IsWeaponOutfitSlotMain(outfitSlotIndex)
                local isWeaponSlotBackup = ZO_OUTFIT_MANAGER:IsWeaponOutfitSlotBackup(outfitSlotIndex)

                local name = zo_strformat(SI_CHARACTER_EQUIP_SLOT_FORMAT, GetString("SI_OUTFITSLOT", outfitSlotIndex))
                
                local icon = slotManipulator:GetSlotAppropriateIcon()

                local data = ZO_GamepadEntryData:New(name, icon)
                data.collectibleId = appropriateCollectibleId
                data.outfitSlot = outfitSlotIndex
                data.slotManipulator = slotManipulator
                data.restyleIndex = slotManipulator:GetOutfitSlotIndex()
                data.restyleSlotData = slotManipulator:GetRestyleSlotData()
                if isWeaponSlotMain and not foundMainWeapons then
                    data:SetHeader(GetString(SI_RESTYLE_SHEET_EQUIPMENT_WEAPONS_SET_1))
                    foundMainWeapons = true
                    self.outfitSlotList:AddEntryWithHeader("ZO_OutfitSlot_EntryTemplate_Gamepad", data)
                elseif isWeaponSlotBackup and not foundBackupWeapons then
                    data:SetHeader(GetString(SI_RESTYLE_SHEET_EQUIPMENT_WEAPONS_SET_2))
                    foundBackupWeapons = true
                    self.outfitSlotList:AddEntryWithHeader("ZO_OutfitSlot_EntryTemplate_Gamepad", data)
                else
                    self.outfitSlotList:AddEntry("ZO_OutfitSlot_EntryTemplate_Gamepad", data)
                end
            end
        end
    else
        local slotsByMode = ZO_Dyeing_GetSlotsForRestyleSet(restyleMode, ZO_RESTYLE_DEFAULT_SET_INDEX)
        for _, dyeableSlotData in ipairs(slotsByMode) do
            if not dyeableSlotData:ShouldBeHidden() then
                local name = zo_strformat(SI_CHARACTER_EQUIP_SLOT_FORMAT, dyeableSlotData:GetDefaultDescriptor())
                local data = ZO_GamepadEntryData:New(name, dyeableSlotData:GetIcon())
                data.restyleIndex = dyeableSlotData:GetRestyleSlotType()
                data.restyleSlotData = ZO_RestyleSlotData:Copy(dyeableSlotData)
                self.outfitSlotList:AddEntry("ZO_RestyleSlot_EntryTemplate_Gamepad", data)
            end
        end
    end

    self.outfitSlotList:Commit()

    self.dirty = false
end

function ZO_Restyle_Station_Gamepad:UpdateCurrentOutfitIndex()
    if RESTYLE_GAMEPAD:GetMode() == RESTYLE_MODE_COLLECTIBLE then
        self.currentOutfitManipulator = nil
        return
    end

    local currentEditingIndex = ZO_OUTFITS_SELECTOR_GAMEPAD:GetCurrentOutfitIndex()
    if not currentEditingIndex then
        self:SetOutfitManipulator(nil)
    else
        self:SetOutfitManipulator(ZO_OUTFIT_MANAGER:GetOutfitManipulator(currentEditingIndex))
    end
end

function ZO_Restyle_Station_Gamepad:UpdateOutfitPreview()
    if RESTYLE_GAMEPAD:GetMode() == RESTYLE_MODE_COLLECTIBLE then
        return
    end

    if self.currentOutfitManipulator then
        ITEM_PREVIEW_GAMEPAD:PreviewOutfit(self.currentOutfitManipulator:GetOutfitIndex())
    else
        ITEM_PREVIEW_GAMEPAD:PreviewUnequipOutfit()
    end
end

function ZO_Restyle_Station_Gamepad:RefreshHeader()
    if RESTYLE_GAMEPAD:GetMode() ~= RESTYLE_MODE_COLLECTIBLE then
        ZO_GamepadGenericHeader_Refresh(self.header, self.outfitHeaderData)
    else
        ZO_GamepadGenericHeader_Refresh(self.header, self.defaultHeaderData)
    end

    self.outfitSelectorControl:SetHidden(RESTYLE_GAMEPAD:GetMode() == RESTYLE_MODE_COLLECTIBLE)

    if self.currentOutfitManipulator then
        self.outfitSelectorNameLabel:SetText(self.currentOutfitManipulator:GetOutfitName())
    else
        self.outfitSelectorNameLabel:SetText(GetString(SI_NO_OUTFIT_EQUIP_ENTRY))
    end
end

function ZO_Restyle_Station_Gamepad:RefreshFooter()
    if RESTYLE_GAMEPAD:GetMode() == RESTYLE_MODE_OUTFIT then
        GAMEPAD_GENERIC_FOOTER:Refresh(self.footerData)
    else
        GAMEPAD_GENERIC_FOOTER:Refresh({})
    end
end

function ZO_Restyle_Station_Gamepad:RefreshSavedSet(dyeSetIndex)
    local savedSetSwatch = self.savedSets[dyeSetIndex]
    local savedSetDyes = { GetSavedDyeSetDyes(dyeSetIndex) }
    for dyeChannel, dyeControl in ipairs(savedSetSwatch.dyeControls) do
        local currentDyeId = savedSetDyes[dyeChannel]
        ZO_DyeingUtils_SetSlotDyeSwatchDyeId(dyeControl, currentDyeId)
    end
end

function ZO_Restyle_Station_Gamepad:RefreshSavedSets()
    for dyeSetIndex = 1, GetNumSavedDyeSets() do
        self:RefreshSavedSet(dyeSetIndex)
    end
end

function ZO_Restyle_Station_Gamepad:RefreshSavedSetHighlight()
    if self:ShouldShowSelectedDyeSet() then
        ZO_Dyeing_Gamepad_SavedSet_Highlight(self.savedPresetsControl, self.savedSets[self.dyeingPanel:GetSelectedSavedSetIndex()])
    else
        ZO_Dyeing_Gamepad_SavedSet_Highlight(self.savedPresetsControl, nil)
    end
end

function ZO_Restyle_Station_Gamepad:GetSelectedSavedSetIndex()
    local INCLUDE_SAVED_FOCUS = true
    local selectedSavedSet = self.savedSetFocus:GetFocusItem(INCLUDE_SAVED_FOCUS)
    return selectedSavedSet and selectedSavedSet.control.savedSetIndex
end

function ZO_Restyle_Station_Gamepad:SwitchToAction(action)
    if self.actionMode ~= action then
        local previousActionPanel = self:GetActionPanel(self.actionMode)
        if self.actionMode ~= ACTION_NONE then
            local previousActionFragmentGroup = self:GetActionFragmentGroup(self.actionMode)

            SCENE_MANAGER:RemoveFragmentGroup(previousActionFragmentGroup)
            if previousActionPanel:IsActive() then
                self:DeactivateCurrentSelection()
            end

            GAMEPAD_TOOLTIPS:ClearLines(GAMEPAD_LEFT_TOOLTIP)

            if self.actionMode == ACTION_DYES then
                self:DeactivateRelevantDyeFoci()
                self:ResetHighlightAllFoci()
            end
        end

        self.actionMode = action

        if action ~= ACTION_NONE then
            local nextActionPanel = self:GetActionPanel(action)
            self:UpdateCurrentActionFragmentGroup()

            self:GetMainList():RefreshVisible()

            if action == ACTION_DYES then
                self:RefreshSavedSets()
                self:ActivateCurrentSelection()
            elseif action == ACTION_STYLES then
                self:UpdateOutfitsPanel()
                if self:IsCurrentFocusArea(self.savedSetsHeaderFocus) then
                    self.savedSetsHeaderFocus:HandleMoveNext()
                end
                self:UpdateActiveFocusKeybinds()
                TriggerTutorial(TUTORIAL_TRIGGER_OUTFIT_STYLES_SHOWN)
            end
        end

        self.savedPresetsControl:SetHidden(action ~= ACTION_DYES)
    end
end

function ZO_Restyle_Station_Gamepad:GetActionPanel(action)
    if action == ACTION_STYLES then
        return self.outfitsPanel
    elseif action == ACTION_DYES then
        return self.dyeingPanel
    end
end

function ZO_Restyle_Station_Gamepad:GetActionFragmentGroup(action)
    if action == ACTION_STYLES then
        return self.outfitsPanelFragmentGroup
    elseif action == ACTION_DYES then
        return self.dyeingPanelFragmentGroup
    end
end

function ZO_Restyle_Station_Gamepad:HandleSelectAction()
    if self.actionMode == ACTION_DYES then
        local selectedControl = self.outfitSlotList:GetSelectedControl()
        local dyeChannelIndex
        if self:ShouldShowAllDyeFoci() then
            dyeChannelIndex = self.dyeAllFocus:GetFocus()
        else
            dyeChannelIndex = selectedControl.dyeSelectorFocus:GetFocus()
        end
        local activeTool = self.dyeingPanel:GetActiveDyeTool()
        local targetData = self.outfitSlotList:GetTargetData()
        local restyleSlotData = targetData.restyleSlotData
        local isChannelDyeableTable = {restyleSlotData:AreDyeChannelsDyeable()}
        if isChannelDyeableTable[dyeChannelIndex] or self:ShouldShowAllDyeFoci() or self:CanApplySelectedDyeSet() then
            activeTool:OnLeftClicked(restyleSlotData, dyeChannelIndex)
            self:GetMainList():RefreshVisible()
            self:RefreshKeybinds()
        else
            ZO_Alert(ALERT, nil, zo_strformat(SI_GAMEPAD_DYEING_UNDYEABLE_CHANNEL))
        end
    else
        self:ActivateCurrentSelection()
        PlaySound(SOUNDS.OUTFIT_GAMEPAD_MENU_ENTER)
    end
end

do
    local function GetTrueSetIndex(index)
        return zo_floor((index - 1) / 3) + 1
    end

    function ZO_Restyle_Station_Gamepad:HandleSelectSavedSetAction()
        if self:ShouldShowSelectedDyeSet() then
            self.dyeingPanel:SetSelectedSavedSetIndex(self.savedSetFocus:GetFocus(true))
            self:RefreshSavedSetHighlight()
            self.savedSetsHeaderFocus:HandleMoveNext()
        else
            local activeTool = self.dyeingPanel:GetActiveDyeTool()
            local savedSetChannelIndex = self.activeSavedSetsFocus:GetFocus(true)
            local trueSetIndex = GetTrueSetIndex(savedSetChannelIndex)
            local trueChannelIndex = zo_mod(savedSetChannelIndex - 1, 3) + 1
            activeTool:OnSavedSetLeftClicked(trueSetIndex, trueChannelIndex)
        end
    end

    function ZO_Restyle_Station_Gamepad:HandleUseSetAction()
        local savedSetChannelIndex = self.activeSavedSetsFocus:GetFocus(true)
        local trueSetIndex = GetTrueSetIndex(savedSetChannelIndex)

        self.dyeingPanel:SwitchToSavedSet(trueSetIndex)
        self:RefreshSavedSetHighlight()
        self.savedSetsHeaderFocus:HandleMoveNext()
    end
end

function ZO_Restyle_Station_Gamepad:OnSlotChanged(oldData, selectedData)
    if self.actionMode == ACTION_STYLES then
	    self:UpdateOutfitsPanel()
    elseif self.actionMode == ACTION_DYES then
        local oldControl = self.outfitSlotList:GetControlFromData(oldData)
        local newControl = self.outfitSlotList:GetControlFromData(selectedData)
        if self:HasActiveFocus() then
            if self:ShouldShowAllDyeFoci() then
                self:HighlightAllFociByChannel(self.dyeAllFocus:GetFocus())
            elseif self:ShouldShowSelectedDyeSet() then
                if newControl and selectedData.restyleSlotData:IsDataDyeable() then
                    ZO_Dyeing_Gamepad_OutfitSwatchSlot_Highlight_All(newControl)
                end

                if oldControl and oldData.restyleSlotData:IsDataDyeable() then
                    ZO_Dyeing_Gamepad_OutfitSwatchSlot_Reset_Highlight(oldControl)
                end
            else
                local oldIndex = 1
                if oldControl then
                    oldIndex = oldControl.dyeSelectorFocus:GetFocus(true)
                    oldControl.dyeSelectorFocus:Deactivate()
                end

                newControl.dyeSelectorFocus:SetFocusByIndex(oldIndex)

                if selectedData.restyleSlotData:IsDataDyeable() then
                    newControl.dyeSelectorFocus:Activate()
                end
            end
        end
    end
end

function ZO_Restyle_Station_Gamepad:OnListAreaDeactivate()
    if self.actionMode == ACTION_STYLES then
        self:UpdateOutfitsPanel()
    elseif self.actionMode == ACTION_DYES then
        self:DeactivateRelevantDyeFoci()
        if self:ShouldShowSelectedDyeSet() then
            local selectedControl = self.outfitSlotList:GetSelectedControl()
            ZO_Dyeing_Gamepad_OutfitSwatchSlot_Reset_Highlight(selectedControl)
        end
    end
end

function ZO_Restyle_Station_Gamepad:OnListAreaActivate()
    if self.actionMode == ACTION_STYLES then
        self:UpdateOutfitsPanel()
    elseif self.actionMode == ACTION_DYES then
        self:ActivateRelevantDyeFoci()
        if self:CanApplySelectedDyeSet() then
            local selectedControl = self.outfitSlotList:GetSelectedControl()
            ZO_Dyeing_Gamepad_OutfitSwatchSlot_Highlight_All(selectedControl)
        end
    end
end

function ZO_Restyle_Station_Gamepad:OnFocusChanged()
    self:UpdateCurrentActionFragmentGroup()
end

function ZO_Restyle_Station_Gamepad:OnPanelSelectionEnd(helperPanel)
    if self.actionMode == ACTION_DYES then
        if RESTYLE_GAMEPAD:GetMode() ~= RESTYLE_MODE_COLLECTIBLE then
            self.header.tabBar:MovePrevious()
        else
            self:AttemptExit()
        end
    else
        self:DeactivateCurrentSelection()
        self:GetMainList():RefreshVisible()
    end
end

function ZO_Restyle_Station_Gamepad:OnDyeToolSelected()
    local activeTool = self.dyeingPanel:GetActiveDyeTool()
    self:GetMainList():RefreshVisible()
    if not activeTool:HasSwatchSelection() then
        self:DeactivateCurrentSelection()
    end

    self:RefreshSavedSetHighlight()
end

function ZO_Restyle_Station_Gamepad:OnPendingDyesChanged(restyleSlotData)
    if restyleSlotData then
        local slotManipulator = ZO_OUTFIT_MANAGER:GetOutfitSlotManipulatorFromRestyleSlotData(restyleSlotData)
        slotManipulator:UpdatePreview()
    else
        if self.currentOutfitManipulator then
            self.currentOutfitManipulator:UpdatePreviews()
        end
    end
    self:GetMainList():RefreshVisible()
    self:UpdateActiveFocusKeybinds()
end

function ZO_Restyle_Station_Gamepad:OnDyeSelected()
    self:DeactivateCurrentSelection()
    self:UpdateActiveFocusKeybinds()
end

function ZO_Restyle_Station_Gamepad:OnSavedSetSlotChanged(dyeSetIndex)
    if dyeSetIndex then
        self:RefreshSavedSet(dyeSetIndex)
    else
        self:RefreshSavedSets()
    end
end

function ZO_Restyle_Station_Gamepad:ActivateRelevantDyeFoci()
    if self:ShouldShowAllDyeFoci() then
        self.dyeAllFocus:Activate()
    elseif not self:ShouldShowSelectedDyeSet() then
        local selectedControl = self.outfitSlotList:GetSelectedControl()
        local data = self.outfitSlotList:GetDataForDataIndex(selectedControl.dataIndex)
        if data.restyleSlotData:IsDataDyeable() then
            selectedControl.dyeSelectorFocus:Activate()
        end
    end
end

function ZO_Restyle_Station_Gamepad:DeactivateRelevantDyeFoci()
    if self:ShouldShowAllDyeFoci() then
        self.dyeAllFocus:Deactivate()
    elseif not self:ShouldShowSelectedDyeSet() then
        local selectedControl = self.outfitSlotList:GetSelectedControl()
        selectedControl.dyeSelectorFocus:Deactivate()
    end
end

function ZO_Restyle_Station_Gamepad:ShouldShowAllDyeFoci()
    local activeTool = self.dyeingPanel:GetActiveDyeTool()
    return activeTool:GetCursorType() == MOUSE_CURSOR_FILL and self.actionMode == ACTION_DYES
end

function ZO_Restyle_Station_Gamepad:ShouldShowSelectedDyeSet()
    local activeTool = self.dyeingPanel:GetActiveDyeTool()
    return activeTool:GetCursorType() == MOUSE_CURSOR_FILL_MULTIPLE and self.actionMode == ACTION_DYES
end

function ZO_Restyle_Station_Gamepad:CanApplySelectedDyeSet()
    if not self:ShouldShowSelectedDyeSet() then
        return false
    end
    local selectedControl = self.outfitSlotList:GetSelectedControl()
    local data = self.outfitSlotList:GetDataForDataIndex(selectedControl.dataIndex)
    local isPrimaryChannelDyeable, isSecondaryChannelDyeable, isAccentChannelDyeable = data.restyleSlotData:AreDyeChannelsDyeable()

    return isPrimaryChannelDyeable or isSecondaryChannelDyeable or isAccentChannelDyeable
end

function ZO_Restyle_Station_Gamepad:HighlightAllFociByChannel(dyeChannel)
    for control, visible in pairs(self.outfitSlotList:GetAllVisibleControls()) do
        local data = self.outfitSlotList:GetDataForDataIndex(control.dataIndex)
        if data.restyleSlotData:IsDataDyeable() then
            ZO_Dyeing_Gamepad_OutfitSwatchSlot_Highlight_Only(control, dyeChannel)
        end
    end
end

function ZO_Restyle_Station_Gamepad:ResetHighlightAllFoci()
    for control, visible in pairs(self.outfitSlotList:GetAllVisibleControls()) do
        ZO_Dyeing_Gamepad_OutfitSwatchSlot_Reset_Highlight(control)
    end
end

function ZO_Restyle_Station_Gamepad:OnCurrencyChanged(currencyType, currencyLocation, newAmount, oldAmount, reason)
    if currencyType == CURT_STYLE_STONES or currencyType == CURT_MONEY then
        if SCENE_MANAGER:IsShowing(self.scene.name) then
            self:RefreshFooter()
        else
            self.dirty = true
        end
    end
end

function ZO_Restyle_Station_Gamepad:SetOutfitManipulator(newManipulator)
    if self.currentOutfitManipulator ~= newManipulator then
        self.currentOutfitManipulator = newManipulator

        if newManipulator then
            RESTYLE_GAMEPAD:SetMode(RESTYLE_MODE_OUTFIT)
        else
            RESTYLE_GAMEPAD:SetMode(RESTYLE_MODE_EQUIPMENT)
        end

        self:PerformUpdate()
    end
end

function ZO_Restyle_Station_Gamepad:AttemptExit()
    local currentMode = RESTYLE_GAMEPAD:GetMode()
    local setIndex = ZO_RESTYLE_DEFAULT_SET_INDEX
    if self.currentOutfitManipulator then
        setIndex = self.currentOutfitManipulator:GetOutfitIndex()
    end

    if self:DoesCurrentOutfitHaveChanges() then
        ZO_Dialogs_ShowGamepadDialog("CONFIRM_REVERT_RESTYLE_CHANGES", { confirmCallback = function()
                                                                                                ZO_OUTFIT_MANAGER:EquipOutfit(self.currentOutfitManipulator:GetOutfitIndex()) 
                                                                                                SCENE_MANAGER:HideCurrentScene()
                                                                                                self.currentOutfitManipulator:ClearPendingChanges() 
                                                                                            end})
        return
    end

    if ZO_Dyeing_AreTherePendingDyes(currentMode, setIndex) then
        ZO_Dialogs_ShowGamepadDialog("EXIT_DYE_UI_DISCARD_GAMEPAD")
        return
    end


    self:ExitWithoutSave()
end

function ZO_Restyle_Station_Gamepad:ExitWithoutSave()
    if RESTYLE_GAMEPAD:GetMode() ~= RESTYLE_MODE_COLLECTIBLE then
        if self.currentOutfitManipulator then
            ZO_OUTFIT_MANAGER:EquipOutfit(self.currentOutfitManipulator:GetOutfitIndex())
        else
            UnequipOutfit()
        end
    end
    SCENE_MANAGER:HideCurrentScene()
end

function ZO_Restyle_Station_Gamepad:ActivateCurrentSelection()
    local selectedControl = self.outfitSlotList:GetSelectedControl()
    if selectedControl then
        selectedControl.dyeSelectorFocus:Deactivate()
    end
    ZO_GamepadOnDefaultActivatedChanged(self.savedPresetsControl, false)
    self:DeactivateCurrentFocus()
    self:ResetHighlightAllFoci()
    local currentPanel = self:GetActionPanel(self.actionMode)
    currentPanel:Activate()
end

function ZO_Restyle_Station_Gamepad:DeactivateCurrentSelection()
    local currentPanel = self:GetActionPanel(self.actionMode)
    currentPanel:Deactivate()
    ZO_GamepadOnDefaultActivatedChanged(self.savedPresetsControl, true)
    self:ActivateCurrentFocus()
    ZO_GamepadGenericHeader_Activate(self.header)
end

do
    local IS_GAMEPAD = true
    local USE_SHORT_FORMAT = false

    function ZO_Restyle_Station_Gamepad:CommitSelection()
        local currentMode = RESTYLE_GAMEPAD:GetMode()
        if currentMode == RESTYLE_MODE_OUTFIT then
            local slotCosts = self.currentOutfitManipulator:GetTotalSlotCostsForPendingChanges()
            local currentAmount = GetCurrencyAmount(CURT_MONEY, CURRENCY_LOCATION_CHARACTER)
            if slotCosts > 0 then
                ZO_Dialogs_ShowGamepadDialog("GAMEPAD_RESTYLE_STATION_CONFIRM_APPLY", { outfitManipulator = self.currentOutfitManipulator })
            else
                ZO_Dialogs_ShowGamepadDialog("CONFIRM_APPLY_OUTFIT_STYLE", { outfitManipulator = self.currentOutfitManipulator })
            end
        else
            if ZO_Dyeing_AreAllItemsBound(currentMode, ZO_RESTYLE_DEFAULT_SET_INDEX) then
                self:CompleteDyeChanges()
            else
                ZO_Dialogs_ShowGamepadDialog("CONFIRM_APPLY_DYE")
            end
        end
    end
end

function ZO_Restyle_Station_Gamepad:CompleteDyeChanges()
    ApplyPendingDyes()
    InitializePendingDyes()
    self:OnPendingDyesChanged()
end

function ZO_Restyle_Station_Gamepad:DoesHaveChanges()
    local currentMode = RESTYLE_GAMEPAD:GetMode()
    if currentMode == RESTYLE_MODE_OUTFIT then
        return self:DoesCurrentOutfitHaveChanges()
    else
        return ZO_Dyeing_AreTherePendingDyes(RESTYLE_GAMEPAD:GetMode(), ZO_RESTYLE_DEFAULT_SET_INDEX)
    end
end

function ZO_Restyle_Station_Gamepad:CanApplyChanges()
    local currentMode = RESTYLE_GAMEPAD:GetMode()
    if currentMode == RESTYLE_MODE_OUTFIT then
        return self:CanCurrentOutfitApplyChanges()
    else
        return true
    end
end

function ZO_Restyle_Station_Gamepad:DoesCurrentOutfitHaveChanges()
    return self.currentOutfitManipulator and self.currentOutfitManipulator:IsAnyChangePending()
end

function ZO_Restyle_Station_Gamepad:CanCurrentOutfitApplyChanges()
    return self.currentOutfitManipulator and self.currentOutfitManipulator:CanApplyChanges()
end

function ZO_Restyle_Station_Gamepad:ShowUndoPendingChangesDialog()
    ZO_Dialogs_ShowGamepadDialog("CONFIRM_REVERT_OUTFIT_CHANGES", { confirmCallback = function() self:UndoPendingChanges() end})
end

function ZO_Restyle_Station_Gamepad:UndoPendingChanges()
    InitializePendingDyes()
    if self.currentOutfitManipulator then
        self.currentOutfitManipulator:ClearPendingChanges()
        self.currentOutfitManipulator:UpdatePreviews()
        if self.outfitsPanel:IsActive() then
            self:UpdateOutfitsPanel()
        end
        PlaySound(SOUNDS.OUTFIT_GAMEPAD_UNDO_CHANGES)
    else
        PlaySound(SOUNDS.DYEING_UNDO_CHANGES)
    end
    self:OnPendingDyesChanged()
end

function ZO_Restyle_Station_Gamepad:RandomizeSelection()
    if self.actionMode == ACTION_STYLES then
        if self.currentOutfitManipulator then
            self.currentOutfitManipulator:RandomizeStyleData()
        end
    elseif self.actionMode == ACTION_DYES then
        local currentMode = RESTYLE_GAMEPAD:GetMode()
        local setIndex = ZO_RESTYLE_DEFAULT_SET_INDEX
        if self.currentOutfitManipulator then
            setIndex = self.currentOutfitManipulator:GetOutfitIndex()
        end
        ZO_Dyeing_UniformRandomize(currentMode, setIndex, function() return ZO_DYEING_MANAGER:GetRandomUnlockedDyeId() end)
        self:OnPendingDyesChanged()
    end
end

function ZO_Restyle_Station_Gamepad:ShowOutfitSelection()
    if self:DoesCurrentOutfitHaveChanges() then
        ZO_Dialogs_ShowGamepadDialog("CONFIRM_REVERT_OUTFIT_ON_CHANGE", { confirmCallback = function() self.currentOutfitManipulator:ClearPendingChanges() SCENE_MANAGER:Push("gamepad_outfits_selection") end})
    else
        SCENE_MANAGER:Push("gamepad_outfits_selection")
    end
end

-- Confimation Dialog --
function ZO_Restyle_Station_Gamepad:InitializeConfirmationDialog()
    local IS_SINGULAR = true
    local IS_UPPER = true
    local NORMAL_FONT_SELECTED = "ZoFontGamepad42"
    local NORMAL_FONT_UNSELECTED = "ZoFontGamepad34"

    local function SetupOutfitApplyOption(control, data, selected, selectedDuringRebuild, enabled, activated)
        ZO_SharedGamepadEntry_OnSetup(control, data, selected, selectedDuringRebuild, enabled, activated)

        local currentCurrency = GetCurrencyAmount(data.currencyType, data.currencyLocation)
        local slotCosts, flatCost = self.currentOutfitManipulator:GetAllCostsForPendingChanges()
        local costToUse = data.currencyType == CURT_MONEY and slotCosts or flatCost

        local priceControl = control:GetNamedChild("Price")
        ZO_CurrencyControl_SetSimpleCurrency(priceControl, data.currencyType, data.value, ZO_GAMEPAD_CURRENCY_OPTIONS, CURRENCY_SHOW_ALL, costToUse > currentCurrency)
        priceControl:SetFont(selected and NORMAL_FONT_SELECTED or NORMAL_FONT_UNSELECTED)
        if selected then
            priceControl:SetAlpha(1)
        else
            priceControl:SetAlpha(0.5)
        end
    end 

    ZO_Dialogs_RegisterCustomDialog("GAMEPAD_RESTYLE_STATION_CONFIRM_APPLY",
    {
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
        },
        title =
        {
            text = SI_OUTFIT_CONFIRM_COMMIT_TITLE
        },
        setup = function(dialog, allActions)
            local parametricList = dialog.info.parametricList
            ZO_ClearNumericallyIndexedTable(parametricList)

            local slotCosts, flatCost = self.currentOutfitManipulator:GetAllCostsForPendingChanges()

            -- gold
            if slotCosts > 0 then
                local entryData = ZO_GamepadEntryData:New(GetCurrencyName(CURT_MONEY, IS_SINGULAR, IS_UPPER))
                entryData.currencyType = CURT_MONEY
                entryData.setup = SetupOutfitApplyOption
                entryData.currencyLocation = CURRENCY_LOCATION_CHARACTER
                entryData.value = slotCosts
                entryData.useFlatCurrency = false

                local listItem =
                {
                    template = "ZO_Restyle_ApplyChanges_EntryTemplate_Gamepad",
                    entryData = entryData,
                    header = GetString(SI_GAMEPAD_OUTFITS_APPLY_CHANGES_LIST_HEADER),
                    headerTemplate = "ZO_GamepadMenuEntryFullWidthHeaderTemplate",
                }
                table.insert(parametricList, listItem)
            end

            -- outfit scraps
            if flatCost > 0 then
                local entryData = ZO_GamepadEntryData:New(GetCurrencyName(CURT_STYLE_STONES, IS_SINGULAR, IS_UPPER))
                entryData.currencyType = CURT_STYLE_STONES
                entryData.currencyLocation = CURRENCY_LOCATION_ACCOUNT
                entryData.setup = SetupOutfitApplyOption
                entryData.value = flatCost
                entryData.useFlatCurrency = true

                local listItem =
                {
                    template = "ZO_Restyle_ApplyChanges_EntryTemplate_Gamepad",
                    entryData = entryData,
                }
                table.insert(parametricList, listItem)
            end

            dialog:setupFunc()
        end,
        parametricList = {}, -- Added Dynamically
        parametricListOnSelectionChangedCallback = function(dialog, list, newSelectedData, oldSelectedData)
                                                        if newSelectedData then
                                                            local slotCosts, flatCost = self.currentOutfitManipulator:GetAllCostsForPendingChanges()
                                                            local costToShow = newSelectedData.currencyType == CURT_MONEY and slotCosts or flatCost
                                                            local IS_GAMEPAD = true
						                                    local USE_SHORT_FORMAT = false
                                                            balanceData =
                                                            {
                                                                data1 = { header = GetString(SI_GAMEPAD_OUTFITS_APPLY_CHANGES_BALANCE), 
                                                                value = ZO_CurrencyControl_FormatCurrencyAndAppendIcon(GetCurrencyAmount(newSelectedData.currencyType, newSelectedData.currencyLocation), USE_SHORT_FORMAT, newSelectedData.currencyType, IS_GAMEPAD) },
                                                            }
                                                            ZO_GenericGamepadDialog_RefreshHeaderData(dialog, balanceData)
                                                        end
                                                    end,
        blockDialogReleaseOnPress = true,
        buttons = 
        {
            {
                onShowCooldown = 2000,
                keybind = "DIALOG_PRIMARY",
                text = SI_GAMEPAD_SELECT_OPTION,
                callback = function(dialog)
                    local targetData = dialog.entryList:GetTargetData()
                    if targetData then
                        self.currentOutfitManipulator:SendOutfitChangeRequest(targetData.useFlatCurrency)
                    end
                    ZO_Dialogs_ReleaseDialogOnButtonPress("GAMEPAD_RESTYLE_STATION_CONFIRM_APPLY")
                end,
                enabled = function(dialog)
                                local targetData = dialog.entryList:GetTargetData()
                                if targetData then
                                    local slotCosts, flatCost = self.currentOutfitManipulator:GetAllCostsForPendingChanges()
                                    local costToUse = targetData.currencyType == CURT_MONEY and slotCosts or flatCost
                                    return costToUse <= GetCurrencyAmount(targetData.currencyType, targetData.currencyLocation)
                                end
                                return false
                            end,
            },
            {
                keybind = "DIALOG_NEGATIVE",
                text = SI_GAMEPAD_BACK_OPTION,
                callback =  function(dialog)
                    ZO_Dialogs_ReleaseDialogOnButtonPress("GAMEPAD_RESTYLE_STATION_CONFIRM_APPLY")
                end,
            },     
            {
                keybind = "DIALOG_SECONDARY",
                text = zo_strformat(SI_BUY_CURRENCY, GetCurrencyName(CURT_STYLE_STONES, IS_SINGULAR, IS_UPPER)),
                callback =  function(dialog)
                    ZO_Dialogs_ReleaseDialogOnButtonPress("GAMEPAD_RESTYLE_STATION_CONFIRM_APPLY")
                    self.currentOutfitManipulator:SetMarkedForPreservation(true)
                    ShowMarketAndSearch("", MARKET_OPEN_OPERATION_OUTFIT_CURRENCY)
                end,
            },     
        } 
    })
end

-- XML Functions --

function ZO_Restyle_Station_OnInitialize(control)
    ZO_RESTYLE_STATION_GAMEPAD = ZO_Restyle_Station_Gamepad:New(control)
    SYSTEMS:RegisterGamepadObject("restyle_station", ZO_RESTYLE_STATION_GAMEPAD)
end

function ZO_RestyleSlot_EntryTemplate_Gamepad_OnInitialize(control)
    ZO_SharedGamepadEntry_OnInitialized(control)
    -- Height of these controls needs to account for the dye slots underneath the text
    control.GetHeight = function(control)
        local height = control.label:GetTextHeight()
        if not control.slotDyes:IsHidden() then
            height = height + control.slotDyes:GetHeight()
        end

        return height
    end

    control.sharedHighlight = control:GetNamedChild("SharedHighlight")
    control.slotDyes = control:GetNamedChild("Dyes")
    control.dyeControls = control.slotDyes.dyeControls
    control.dyeHighlightControls = control.slotDyes.dyeHighlightControls
    control.dyeSelectorFocus = ZO_GamepadFocus:New(control.slotDyes, ZO_MovementController:New(MOVEMENT_CONTROLLER_DIRECTION_HORIZONTAL))

    for i, dyeControl in ipairs(control.dyeControls) do
        local entry = {
                        control = dyeControl,
                        dyeChannel = i,
                        iconScaleAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_DyeingSlot_Gamepad_FocusScaleAnimation", dyeControl),
                    }
        control.dyeSelectorFocus:AddEntry(entry)
    end

    control.Activate = function(control, ...)
                control.dyeSelectorFocus:SetFocusByIndex(1)
                control.dyeSelectorFocus:Activate(...)
            end

    control.Deactivate = function(control, ...)
                control.dyeSelectorFocus:Deactivate(...)
            end
    
    local function OnSelectionChanged(entry)
        if entry then
            ZO_Dyeing_Gamepad_OutfitSwatchSlot_Highlight_Only(control, entry.dyeChannel)
        else
            ZO_Dyeing_Gamepad_OutfitSwatchSlot_Reset_Highlight(control)
        end

        if control.onSelectionChangedCallback then
            control.onSelectionChangedCallback()
        end
    end

    control.dyeSelectorFocus:SetFocusChangedCallback(OnSelectionChanged)
end

function ZO_OutfitSlot_EntryTemplate_Gamepad_OnInitialize(control)
    ZO_RestyleSlot_EntryTemplate_Gamepad_OnInitialize(control)

    control.borderBackground = control:GetNamedChild("BorderedBackground")
    control.priceLabel = control:GetNamedChild("Price")
end
