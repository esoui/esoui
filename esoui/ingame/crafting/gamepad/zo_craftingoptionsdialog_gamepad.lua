-----------------------------------
-- CraftingOptionsDialog Gamepad --
-----------------------------------

ZO_CraftingOptionsDialogGamepad = ZO_InitializingObject:Subclass()

function ZO_CraftingOptionsDialogGamepad:Initialize()
    self.optionTemplateGroups = {}
    self.dialogData = {}
    self.filterControls = {}
end

function ZO_CraftingOptionsDialogGamepad:ShowOptionsDialog(dialogData)
    self.dialogData = dialogData
    ZO_ClearTable(self.optionTemplateGroups)
    
    self:BuildOptionsList()
    local parametricList = {}
    self:PopulateOptionsList(parametricList)

    local data = 
    {
        parametricList = parametricList,
        finishedCallback = self.dialogData.finishedCallback,
    }
    ZO_Dialogs_ShowGamepadDialog("GAMEPAD_CRAFTING_OPTIONS_DIALOG", data)
end

function ZO_CraftingOptionsDialogGamepad:BuildOptionsList()
    local filters = self.dialogData.filters
    if filters then
        local numFilters = #filters
        if numFilters > 0 then
            local filterGroupId = self:AddOptionTemplateGroup(GetString(SI_GAMEPAD_CRAFTING_OPTIONS_FILTERS))
            for filterIndex = 1, numFilters do
                local factoryFunction
                local filterData = filters[filterIndex]
                if filterData.multiSelection then
                    factoryFunction = ZO_CraftingOptionsDialogGamepad.BuildMultiSelectionFilter
                else
                    factoryFunction = ZO_CraftingOptionsDialogGamepad.BuildFilter
                end
                self:AddOptionTemplate(filterGroupId, factoryFunction, filterIndex)
            end
        end
    end

    local globalActions = self.dialogData.globalActions
    local itemActions = self.dialogData.itemActions
    if globalActions or itemActions then
        local slotActionController = itemActions and itemActions:GetSlotActions() or nil
        local numItemActions = slotActionController and slotActionController:GetNumSlotActions() or 0
        local numGlobalActions = globalActions and #globalActions or 0
        if numItemActions > 0 or numGlobalActions > 0 then
            local actionGroupId = self:AddOptionTemplateGroup(GetString(SI_GAMEPAD_INVENTORY_ACTION_LIST_KEYBIND))

            if numItemActions > 0 then
                for itemActionIndex = 1, numItemActions do
                    self:AddOptionTemplate(actionGroupId, ZO_CraftingOptionsDialogGamepad.BuildItemAction, itemActionIndex)
                end
            end

            if numGlobalActions > 0 then
                for globalActionIndex = 1, numGlobalActions do
                    self:AddOptionTemplate(actionGroupId, ZO_CraftingOptionsDialogGamepad.BuildGlobalAction, globalActionIndex)
                end
            end
        end
    end
end

function ZO_CraftingOptionsDialogGamepad:PopulateOptionsList(list)
    for groupId, group in pairs(self.optionTemplateGroups) do
        self.currentGroupHeader = group.header
        for index, optionTemplate in pairs(group.options) do
            local option = optionTemplate.buildFunction(self, optionTemplate.optionIndex)
            if option ~= nil then
                table.insert(list, option)
                self.currentGroupHeader = nil
            end
        end
    end
end

function ZO_CraftingOptionsDialogGamepad:AddOptionTemplateGroup(header)
    local id = #self.optionTemplateGroups + 1
    local group =
    {
        header = header,
        options = {},
    }
    self.optionTemplateGroups[id] = group
    return id
end

function ZO_CraftingOptionsDialogGamepad:AddOptionTemplate(groupId, buildFunction, optionIndex)
    local group = self.optionTemplateGroups[groupId]
    assert(group ~= nil, "You must get a valid id from AddOptionTemplateGroup before adding options")
    table.insert(group.options, { buildFunction = buildFunction, optionIndex = optionIndex })
end

function ZO_CraftingOptionsDialogGamepad:BuildGlobalAction(globalActionIndex)
    local currentGlobalAction = self.dialogData.globalActions[globalActionIndex]
    local label = currentGlobalAction.actionName
    local entryData = ZO_GamepadEntryData:New(label)
    entryData.text = label
    entryData.setup = ZO_SharedGamepadEntry_OnSetup

    local function OnGlobalActionCallback()
        if currentGlobalAction.callback then
            currentGlobalAction.callback()
        end
        ZO_Dialogs_ReleaseDialogOnButtonPress("GAMEPAD_CRAFTING_OPTIONS_DIALOG")
    end
    entryData.callback = OnGlobalActionCallback

    local function OnGlobalActionSelected()
        if not self.dialogData.ignoreTooltips then
            GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
        end
    end
    entryData.onSelected = OnGlobalActionSelected

    local entry = 
    {
        template = "ZO_GamepadItemEntryTemplate",
        header = self.currentGroupHeader,
        entryData = entryData,
    }
    return entry
end

function ZO_CraftingOptionsDialogGamepad:BuildItemAction(itemActionIndex)
    local action = self.dialogData.itemActions:GetSlotActionAtIndex(itemActionIndex)
    local actionLabel = action[1]
    if not (actionLabel == GetString(SI_ITEM_ACTION_MARK_AS_LOCKED) or 
            actionLabel == GetString(SI_ITEM_ACTION_UNMARK_AS_LOCKED) or 
            actionLabel == GetString(SI_ITEM_ACTION_LINK_TO_CHAT)) then
        return
    end

    local entryData = ZO_GamepadEntryData:New(actionLabel)
    entryData.text = actionLabel
    entryData.setup = ZO_SharedGamepadEntry_OnSetup
    entryData.action = action

    local function OnItemActionCallback()
       self.dialogData.itemActions:SetSelectedAction(entryData and entryData.action)
       self.dialogData.itemActions:DoSelectedAction()
       ZO_Dialogs_ReleaseDialogOnButtonPress("GAMEPAD_CRAFTING_OPTIONS_DIALOG")
    end
    entryData.callback = OnItemActionCallback

    local function OnItemActionSelected()
        local targetData = self.dialogData.targetData
        assert(targetData, "The calling menu should provide targetData when passing the dialogData to this dialog")
        if not self.dialogData.ignoreTooltips then
            GAMEPAD_TOOLTIPS:LayoutBagItem(GAMEPAD_LEFT_TOOLTIP, targetData.bagId, targetData.slotIndex, SHOW_COMBINED_COUNT)
        end
    end
    entryData.onSelected = OnItemActionSelected
    
    local entry = 
    {
        template = "ZO_GamepadItemEntryTemplate",
        header = self.currentGroupHeader,
        entryData = entryData,
    }
    return entry
end

function ZO_CraftingOptionsDialogGamepad:BuildFilter(filterIndex)
    local currentFilter = self.dialogData.filters[filterIndex]
    local header = self.currentGroupHeader
    local label = currentFilter.filterName

    local function OnCraftingFilterToggled()
        if self.filterControls ~= nil then
            local targetControl = self.filterControls[filterIndex]
            ZO_GamepadCheckBoxTemplate_OnClicked(targetControl)
            currentFilter.checked = ZO_CheckButton_IsChecked(targetControl.checkBox)
            local parametricDialog = ZO_GenericGamepadDialog_GetControl(GAMEPAD_DIALOGS.PARAMETRIC)
            SCREEN_NARRATION_MANAGER:QueueDialog(parametricDialog)
        end
    end

    local function OnCraftingFilterSelected()
        if not self.dialogData.ignoreTooltips then
            GAMEPAD_TOOLTIPS:LayoutTitleAndDescriptionTooltip(GAMEPAD_LEFT_TOOLTIP, currentFilter.filterName, currentFilter.filterTooltip)
        end
    end

    local function CraftingFilterCheckboxEntrySetup(control, data, selected, reselectingDuringRebuild, enabled, active)
        data.callback = OnCraftingFilterToggled
        data.onSelected = OnCraftingFilterSelected
        ZO_GamepadCheckBoxTemplate_Setup(control, data, selected, reselectingDuringRebuild, enabled, active)
        if currentFilter.checked then
            ZO_CheckButton_SetChecked(control.checkBox)
        else
            ZO_CheckButton_SetUnchecked(control.checkBox)
        end
        self.filterControls[filterIndex] = control
    end

    local function CraftingFilterCheckboxEntryNarrationText(entryData, entryControl)
        local isChecked = currentFilter.checked
        return ZO_FormatToggleNarrationText(entryData.text, isChecked)
    end

    return self:BuildCheckboxEntry(header, label, CraftingFilterCheckboxEntrySetup, Callback, CraftingFilterCheckboxEntryNarrationText, GAMEPAD_LEFT_TOOLTIP)
end

function ZO_CraftingOptionsDialogGamepad:BuildCheckboxEntry(header, label, setupFunction, callback, narrationText, narrationTooltip)
    local entry = 
    {
        template = "ZO_CheckBoxTemplate_WithPadding_Gamepad",
        header = header,
        templateData = 
        {
            text = label,
            setup = setupFunction,
            callback = callback,
            narrationText = narrationText,
            narrationTooltip = narrationTooltip,
        },
    }
    return entry
end

function ZO_CraftingOptionsDialogGamepad:BuildMultiSelectionFilter(filterIndex)
    local currentFilter = self.dialogData.filters[filterIndex]
    local dropdownData = currentFilter.dropdownData

    local OnCraftingFilterComboBoxSelectionChanged = nil
    if currentFilter.onSelectionChanged then
        OnCraftingFilterComboBoxSelectionChanged = function()
            currentFilter.onSelectionChanged(dropdownData)
        end
    end

    local header = self.currentGroupHeader
    local label = currentFilter.filterName
    local tooltip = currentFilter.filterTooltip
    local sorted = currentFilter.sorted
    local normalColor = currentFilter.normalColor or ZO_GAMEPAD_COMPONENT_COLORS.UNSELECTED_INACTIVE
    local highlightColor = currentFilter.highlightColor or ZO_GAMEPAD_COMPONENT_COLORS.SELECTED_ACTIVE
    local noSelectionText = currentFilter.noSelectionText
    local multiSelectionTextFormatter = currentFilter.multiSelectionTextFormatter
    local entry =
    {
        template = "ZO_GamepadMultiSelectionDropdownItem_Indented",
        text = label,
        header = header,
        templateData = 
        {
            setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                local dropdowns = data.dialog.dropdowns
                if not dropdowns then
                    dropdowns = {}
                    data.dialog.dropdowns = dropdowns
                end
                local dropdown = control.dropdown
                table.insert(dropdowns, dropdown)

                dropdown:SetNormalColor(normalColor:UnpackRGB())
                dropdown:SetHighlightedColor(highlightColor:UnpackRGB())
                dropdown:SetSelectedItemTextColor(selected)
                dropdown:SetSortsItems(sorted)
                dropdown:SetNoSelectionText(noSelectionText)
                dropdown:SetMultiSelectionTextFormatter(multiSelectionTextFormatter)
                dropdown:RegisterCallback("OnHideDropdown", OnCraftingFilterComboBoxSelectionChanged)
                dropdown:LoadData(dropdownData)
                SCREEN_NARRATION_MANAGER:RegisterDialogDropdown(data.dialog, dropdown)
            end,

            callback = function(dialog)
                local targetData = dialog.entryList:GetTargetData()
                local targetControl = dialog.entryList:GetTargetControl()
                targetControl.dropdown:Activate()
            end,

            onSelected = function()
                if tooltip and not self.dialogData.ignoreTooltips then
                    GAMEPAD_TOOLTIPS:LayoutTitleAndDescriptionTooltip(GAMEPAD_LEFT_TOOLTIP, label, tooltip)
                end
            end,
            narrationText = function(entryData, entryControl)
                return entryControl.dropdown:GetNarrationText()
            end,
            narrationTooltip = GAMEPAD_LEFT_TOOLTIP,
        },
    }
    return entry
end