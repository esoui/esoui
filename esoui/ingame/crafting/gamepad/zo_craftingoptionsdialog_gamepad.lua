--------------------------------------------
-- CraftingOptionsDialog Gamepad
--------------------------------------------

ZO_CraftingOptionsDialogGamepad = ZO_Object:Subclass()

function ZO_CraftingOptionsDialogGamepad:New(...)
    local object = ZO_Object:New(self)
    object:Initialize(...)
    return object
end

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
        finishedCallback = self.dialogData.finishedCallback
    }
    ZO_Dialogs_ShowGamepadDialog("GAMEPAD_CRAFTING_OPTIONS_DIALOG", data)
end

function ZO_CraftingOptionsDialogGamepad:BuildOptionsList()
    if self.dialogData.filters then
        local numFilters = #self.dialogData.filters
        if numFilters > 0 then
            local filterGroupId = self:AddOptionTemplateGroup(GetString(SI_GAMEPAD_CRAFTING_OPTIONS_FILTERS))
            for filterIndex = 1, numFilters do
                self:AddOptionTemplate(filterGroupId, ZO_CraftingOptionsDialogGamepad.BuildFilter, filterIndex)
            end
        end
    end

    local globalActions = self.dialogData.globalActions
    local itemActions = self.dialogData.itemActions
    if globalActions or itemActions then
        local actionGroupId = self:AddOptionTemplateGroup(GetString(SI_GAMEPAD_INVENTORY_ACTION_LIST_KEYBIND))

        if itemActions then
            local slotActionController = itemActions:GetSlotActions()
            for itemActionIndex = 1, slotActionController:GetNumSlotActions() do
                self:AddOptionTemplate(actionGroupId, ZO_CraftingOptionsDialogGamepad.BuildItemAction, itemActionIndex)
            end
        end

        if globalActions then
            for globalActionIndex = 1, #globalActions do
                self:AddOptionTemplate(actionGroupId, ZO_CraftingOptionsDialogGamepad.BuildGlobalAction, globalActionIndex)
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

    local function OnSelected()
        if not self.dialogData.ignoreTooltips then
            GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
        end
    end
    local label = currentGlobalAction.actionName
    local entryData = ZO_GamepadEntryData:New(label)
    entryData.text = label
    entryData.setup = ZO_SharedGamepadEntry_OnSetup
    entryData.callback = function()
        if currentGlobalAction.callback then
            currentGlobalAction.callback()
        end
        ZO_Dialogs_ReleaseDialogOnButtonPress("GAMEPAD_CRAFTING_OPTIONS_DIALOG")
    end
    entryData.onSelected = function()
        GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
    end
    
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
    local function OnSelected()
        local targetData = self.dialogData.targetData
        assert(targetData, "The calling menu should provide targetData when passing the dialogData to this dialog")
        if not self.dialogData.ignoreTooltips then
            GAMEPAD_TOOLTIPS:LayoutBagItem(GAMEPAD_LEFT_TOOLTIP, targetData.bagId, targetData.slotIndex, SHOW_COMBINED_COUNT)
        end
    end
    entryData.text = actionLabel
    entryData.setup = ZO_SharedGamepadEntry_OnSetup
    entryData.action = action
    entryData.callback = function()
       self.dialogData.itemActions:SetSelectedAction(entryData and entryData.action)
       self.dialogData.itemActions:DoSelectedAction()
       ZO_Dialogs_ReleaseDialogOnButtonPress("GAMEPAD_CRAFTING_OPTIONS_DIALOG")
    end
    entryData.onSelected = OnSelected
    
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
    local function ToggleFunction()
        if self.filterControls ~= nil then
            local targetControl = self.filterControls[filterIndex]
            ZO_GamepadCheckBoxTemplate_OnClicked(targetControl)
            currentFilter.checked = ZO_CheckButton_IsChecked(targetControl.checkBox)
        end
    end
    local function OnSelected()
        if not self.dialogData.ignoreTooltips then
            GAMEPAD_TOOLTIPS:LayoutTitleAndDescriptionTooltip(GAMEPAD_LEFT_TOOLTIP, currentFilter.filterName, currentFilter.filterTooltip)
        end
    end
    local function CheckboxEntrySetup(control, data, selected, reselectingDuringRebuild, enabled, active)
        data.callback = ToggleFunction
        data.onSelected = OnSelected
        ZO_GamepadCheckBoxTemplate_Setup(control, data, selected, reselectingDuringRebuild, enabled, active)

        if currentFilter.checked then
            ZO_CheckButton_SetChecked(control.checkBox)
        else
            ZO_CheckButton_SetUnchecked(control.checkBox)
        end
        self.filterControls[filterIndex] = control
    end
    return self:BuildCheckboxEntry(header, label, CheckboxEntrySetup, Callback)
end

function ZO_CraftingOptionsDialogGamepad:BuildCheckboxEntry(header, label, setupFunction, callback)
    local entry = 
    {
        template = "ZO_CheckBoxTemplate_WithPadding_Gamepad",
        header = header,
        templateData = 
        {
            text = label,
            setup = setupFunction,
            callback = callback,
        },
    }
    return entry
end