-----------------
-- Guild Ranks --
-----------------

ZO_GUILD_RANK_PERMISSON_HEADER_TEMPLATE_GAMEPAD_HEIGHT = 43

local GUILD_RENAME_RANK_GAMEPAD_DIALOG = "GAMEPAD_RENAME_RANK_DIALOG"
local GUILD_DELETE_RANK_GAMEPAD_DIALOG = "GAMEPAD_DELETE_RANK_DIALOG"
local GUILD_DELETE_RANK_GAMEPAD_WARNING_DIALOG = "GUILD_REMOVE_RANK_WARNING"

local GUILDMASTER_INDEX = 1

local REFRESH_SCREEN = true
local DONT_REFRESH_SCREEN = false

local ADD_RANK_DIALOG_NAME = "GUILD_ADD_RANK_GAMEPAD"

local GAMEPAD_GUILD_RANKS_MENU_ENTRY_TEMPLATE = "ZO_GamepadMenuEntryTemplate"

local LIST_DISPLAY_MODES =
{
    RANKS = 1,
    OPTIONS = 2,
    SELECT_ICON = 3,
    CHANGE_PERMISSIONS = 4,
}

local function SetupRequestEntry(control, data, selected, reselectingDuringRebuild, enabled, active)
    local isValid = enabled
    if data.validInput then
        isValid = data.validInput()
        data.disabled = not isValid
        data:SetEnabled(isValid)
    end

    ZO_SharedGamepadEntry_OnSetup(control, data, selected, reselectingDuringRebuild, isValid, active)
end

local ZO_GuildRanks_Gamepad = ZO_GuildRanks_Shared:Subclass()

function ZO_GuildRanks_Gamepad:New(...)
    local guildRanks = ZO_GuildRanks_Shared.New(self, ...)
    guildRanks:Initialize(...)
    return guildRanks
end

function ZO_GuildRanks_Gamepad:SetMainList(list)
    self.rankList = list
end

function ZO_GuildRanks_Gamepad:SetOptionsList(optionsList)
    self.optionsList = optionsList
end

function ZO_GuildRanks_Gamepad:SetOwningScreen(owningScreen)
    self.owningScreen = owningScreen
end

function ZO_GuildRanks_Gamepad:Initialize(control)
    ZO_GuildRanks_Shared.Initialize(self, control)

    -- Initialize grid list object
    local ALWAYS_ANIMATE = true
    self.permissionsGridListControl = self.control:GetNamedChild("PermissionsPanel")
    GUILD_RANKS_PERMISSION_PANEL_FRAGMENT = ZO_FadeSceneFragment:New(self.permissionsGridListControl, ALWAYS_ANIMATE)

    self.rankIconPickerGridListControl = self.control:GetNamedChild("RankIconPicker")
    GUILD_RANK_ICON_PICKER_FRAGMENT = ZO_FadeSceneFragment:New(self.rankIconPickerGridListControl, ALWAYS_ANIMATE)

    self.templateData =
    {
        gridListClass = ZO_GridScrollList_Gamepad,
        entryTemplate = "ZO_CheckboxTile_Gamepad_Control",
        entryWidth = ZO_CHECKBOX_TILE_GAMEPAD_WIDTH,
        entryHeight = ZO_CHECKBOX_TILE_GAMEPAD_HEIGHT,
        headerTemplate = "ZO_GuildRanks_Permission_Gamepad_Header_Template",
        headerHeight = ZO_GUILD_RANK_PERMISSON_HEADER_TEMPLATE_GAMEPAD_HEIGHT,
        highlightTemplate = "ZO_GuildRanks_Permission_Gamepad_Highlight_Template",
    }

    self:InitializePermissionsGridList()

    self.rankIconPicker = ZO_GuildRankIconPicker_Gamepad:New(self.rankIconPickerGridListControl)
    self.rankIconPicker:SetGetSelectedRankFunction(function(...) return self:GetSelectedRank() end)
    self.rankIconPicker:SetRankIconPickedCallback(function(...) self.selectedRank:SetIconIndex(...) end)

    GUILD_RANKS_GAMEPAD_FRAGMENT = ZO_FadeSceneFragment:New(self.control, ALWAYS_ANIMATE)
    GUILD_RANKS_GAMEPAD_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            self:ResetRankSelection()

            self:PerformDeferredInitialization()

            self:ReloadAndRefreshScreen()

            self:OnTargetChanged(self.rankList, self.rankList:GetTargetData())

            self.owningScreen:SetListsUseTriggerKeybinds(true)

            KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)

            local OnRefresh = function()
                self:ReloadAndRefreshScreen()
            end

            local OnRefreshMatchGuildId = function(_, guildId)
                if self:MatchesGuild(guildId) then
                    self:RefreshScreen()
                end
            end

            self.control:RegisterForEvent(EVENT_GUILD_DATA_LOADED, OnRefresh)
            self.control:RegisterForEvent(EVENT_GUILD_RANKS_CHANGED, OnRefreshMatchGuildId)
            self.control:RegisterForEvent(EVENT_GUILD_RANK_CHANGED, OnRefreshMatchGuildId)
            self.control:RegisterForEvent(EVENT_SAVE_GUILD_RANKS_RESPONSE, OnRefreshMatchGuildId)
        elseif newState == SCENE_HIDING then
            self:RemoveUnusedFragments()
            self:SetChangePermissionsEnabled(false)

            self.rankIconPicker:Deactivate()
            GAMEPAD_NAV_QUADRANT_1_BACKGROUND_FRAGMENT:TakeFocus()

            if self.currentDropdown then
                self.currentDropdown:Deactivate(true)
            end

            self.owningScreen:SetListsUseTriggerKeybinds(false)

            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)

            self.control:UnregisterForEvent(EVENT_GUILD_DATA_LOADED)
            self.control:UnregisterForEvent(EVENT_GUILD_RANKS_CHANGED)
            self.control:UnregisterForEvent(EVENT_GUILD_RANK_CHANGED)
            self.control:UnregisterForEvent(EVENT_SAVE_GUILD_RANKS_RESPONSE)

            if self:NeedsSave() then
                PlaySound(SOUNDS.GUILD_RANK_SAVED)
                self:Save()
            end
        end
    end)
end

function ZO_GuildRanks_Gamepad:InitializePermissionsGridList()
    ZO_GuildRanks_Shared.InitializePermissionsGridList(self)

    self.permissionsGridList:SetOnSelectedDataChangedCallback(function(...) self:OnPermissionsGridSelectionChanged(...) end)
end

function ZO_GuildRanks_Gamepad:OnPermissionsGridSelectionChanged(oldSelectedData, selectedData)
    -- Deselect previous tile
    if oldSelectedData and oldSelectedData.dataEntry then
        oldSelectedData.dataSource.isSelected = false
    end

    -- Select newly selected tile.
    if selectedData and selectedData.dataEntry then
        selectedData.dataSource.isSelected = true
    end

    self.permissionsGridList:RefreshGridList()

    local currentSelectedData = self.permissionsGridList:GetSelectedData()
    if currentSelectedData then
        local permission = currentSelectedData.dataSource.value
        local permissionInfo = ZO_GuildRanks_Shared.GetToolTipInfoForPermission(permission)
        GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
        if permissionInfo then
            GAMEPAD_TOOLTIPS:LayoutTextBlockTooltip(GAMEPAD_RIGHT_TOOLTIP, permissionInfo)
        end
    end
end

function ZO_GuildRanks_Gamepad:OnPermissionGridListEntryToggle(...)
    self.selectedRank:SetPermission(...)
    self.permissionsGridList:RefreshGridList()
end

function ZO_GuildRanks_Gamepad:GetSelectedRank()
    return self.selectedRank
end

function ZO_GuildRanks_Gamepad:ResetRankSelection()
    self.selectedRank = nil
    self:ActivateRankList(DONT_REFRESH_SCREEN)
end

function ZO_GuildRanks_Gamepad:ActivateRankList(refreshScreen)
    self.listDisplayMode = LIST_DISPLAY_MODES.RANKS
    if refreshScreen then
        self:RefreshScreen()
    end
    self.owningScreen:SetCurrentList(self.rankList)
end

function ZO_GuildRanks_Gamepad:ActivateOptionsList(refreshScreen)
    if self.selectedRank == nil then
        return
    end

    self.listDisplayMode = LIST_DISPLAY_MODES.OPTIONS
    if refreshScreen then
        self:RefreshScreen()
    end

    GAMEPAD_NAV_QUADRANT_1_BACKGROUND_FRAGMENT:TakeFocus()
    self.owningScreen:SetCurrentList(self.optionsList)
end

function ZO_GuildRanks_Gamepad:DeactivateOptionsList()
    self.optionsList:Deactivate()
    GAMEPAD_NAV_QUADRANT_1_BACKGROUND_FRAGMENT:ClearFocus()
end

function ZO_GuildRanks_Gamepad:PerformDeferredInitialization()
    if self.deferredInitialized then
        return
    end

    self.deferredInitialized = true

    self:InitializeKeybindStrip()
    self:InitializeDeleteRankDialog()
    self:InitializeRenameRankDialog()
    self:InitializeAddRankDialog()
end

function ZO_GuildRanks_Gamepad:ReloadAndRefreshScreen()
    self:PopulateRanks()
    self:RefreshScreen()
end

function ZO_GuildRanks_Gamepad:RefreshScreen()
    self:RefreshLists()
    self:RefreshContent()
    self.owningScreen:RefreshHeader()
end

function ZO_GuildRanks_Gamepad:RefreshLists()
    if self:IsDisplayingRankList() then
        self:RefreshRankList()
    elseif self:IsDisplayingOptionsList() then
        self:RefreshOptionsList()
    end
end

function ZO_GuildRanks_Gamepad:RefreshContent()
    if self:IsDisplayingRankList() then
        self:ActivateFragment(GUILD_RANKS_PERMISSION_PANEL_FRAGMENT)
        self.permissionsGridList:RefreshGridList()
    elseif self:IsDisplayingOptionsList() then
        self:ActivateFragment(GUILD_RANKS_PERMISSION_PANEL_FRAGMENT)
        self.permissionsGridList:RefreshGridList()
    elseif self:IsDisplayingRankIconPicker() then
        self:ActivateFragment(GUILD_RANK_ICON_PICKER_FRAGMENT)
        self.rankIconPicker:RefreshGridList()
        self.owningScreen:SetListsUseTriggerKeybinds(false)
    elseif self:IsDisplayingChangePermissions() then
        self:ActivateFragment(GUILD_RANKS_PERMISSION_PANEL_FRAGMENT)
        self.owningScreen:SetListsUseTriggerKeybinds(false)
    end

    self:SetChangePermissionsEnabled(self:IsDisplayingChangePermissions())
    self:SetChangeRankIconPickerEnabled(self:IsDisplayingRankIconPicker())

    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

-----------------
-- Dropdowns --
-----------------

function ZO_GuildRanks_Gamepad:SetCurrentDropdown(dropdown)
    self.currentDropdown = dropdown
end

------------------
-- Rank Dialogs --
------------------

function ZO_GuildRanks_Gamepad:InitializeAddRankDialog()
    local dialogName = ADD_RANK_DIALOG_NAME
    local parametricDialog = ZO_GenericGamepadDialog_GetControl(GAMEPAD_DIALOGS.PARAMETRIC)

    local function UpdateSelectedName(name)
        if self.selectedName ~= name then
            self.selectedName = name
            self.noViolations = self.selectedName ~= "" and self.selectedName ~= nil
        end
    end

    local function UpdateSelectedRankIndex(rank)
        if self.selectedRankIndex ~= rank then
            self.selectedRankIndex = rank
        end
    end

    local function ReleaseDialog()
        ZO_Dialogs_ReleaseDialogOnButtonPress(dialogName)
    end 

    ZO_Dialogs_RegisterCustomDialog(dialogName,
    {
        gamepadInfo = {
            dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
        },

        setup = function(dialog)
            self.noViolations = nil
            self.selectedRankIndex = nil
            self.selectedName = nil
            UpdateSelectedName("")
            dialog:setupFunc()
        end,

        blockDialogReleaseOnPress = true, -- We'll handle Dialog Releases ourselves since we don't want DIALOG_PRIMARY to release the dialog on press.

        title =
        {
            text = SI_GUILD_RANKS_ADD_RANK,
        },
        parametricList =
        {
            -- guild name edit box
            {
                template = "ZO_Gamepad_GenericDialog_Parametric_TextFieldItem",
                templateData = {
                    nameField = true,
                    textChangedCallback = function(control)
                        local newName = control:GetText()
                        if self.selectedName ~= newName then
                            UpdateSelectedName(newName)
                            ZO_GenericParametricListGamepadDialogTemplate_RefreshVisibleEntries(parametricDialog)
                        end
                    end,
                    
                    setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                        control.highlight:SetHidden(not selected)

                        control.editBoxControl.textChangedCallback = data.textChangedCallback

                        if self.selectedName == "" then
                            ZO_EditDefaultText_Initialize(control.editBoxControl, GetString(SI_GAMEPAD_GUILD_RANK_DIALOG_DEFAULT_TEXT))
                        end
                        control.editBoxControl:SetMaxInputChars(MAX_GUILD_RANK_NAME_LENGTH)
                        control.editBoxControl:SetText(self.selectedName)
                        
                        KEYBIND_STRIP:UpdateCurrentKeybindButtonGroups()
                    end,
                },
            },

            -- rank to copy entry
            {
                header = GetString(SI_GUILD_RANKS_COPY_HEADER),
                template = "ZO_GamepadDropdownItem",

                templateData = {
                    rankSelector = true,
                    setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                        control.dropdown:SetSortsItems(false)
                        self:SetCurrentDropdown(control.dropdown)

                        control.dropdown:ClearItems()

                        local function UpdateDropdownSelection()
                            if(self.selectedRankIndex) then
                                control.dropdown:SetSelectedItemText(self.ranks[self.selectedRankIndex].name)
                            else
                                control.dropdown:SetSelectedItemText(GetString(SI_GUILD_RANKS_COPY_NONE))
                            end
                        end

                        local function OnRankSelected(comboBox, entryText, entry)
                            UpdateSelectedRankIndex(entry.rankIndex)
                        end

                        local noneEntry = control.dropdown:CreateItemEntry(GetString(SI_GUILD_RANKS_COPY_NONE), OnRankSelected)
                        control.dropdown:AddItem(noneEntry)
                        --Skip Guild Master
                        for i = 2, #self.ranks do
                            local entry = control.dropdown:CreateItemEntry(self.ranks[i].name, OnRankSelected)
                            entry.rankIndex = i
                            control.dropdown:AddItem(entry)
                        end

                        control.dropdown:UpdateItems()

                        UpdateDropdownSelection()
                    end,
                },
            },

            -- create
            {
                template = "ZO_GamepadTextFieldSubmitItem",
                templateData = {
                    finishedSelector = true,
                    text = GetString(SI_DIALOG_ACCEPT),
                    setup = SetupRequestEntry,
                    validInput = function()
                        return self.noViolations
                    end,
                },
                icon = ZO_GAMEPAD_SUBMIT_ENTRY_ICON,
            },
        },
       
        buttons =
        {
            -- Cancel Button
            {
                keybind = "DIALOG_NEGATIVE",
                text = GetString(SI_DIALOG_CANCEL),
                callback = function()
                    ReleaseDialog()
                end,
            },

            -- Select Button (used for entering name)
            {
                keybind = "DIALOG_PRIMARY",
                text = GetString(SI_GAMEPAD_SELECT_OPTION),
                callback = function(dialog)
                    local targetData = dialog.entryList:GetTargetData()
                    local targetControl = dialog.entryList:GetTargetControl()
                    if targetData.nameField and targetControl then
                        targetControl.editBoxControl:TakeFocus()
                    elseif targetData.rankSelector then
                        self.currentDropdown:Activate()
                        local highlightIndex = 1
                        if self.selectedRankIndex ~= nil then
                            highlightIndex = self.selectedRankIndex
                        end
                        self.currentDropdown:SetHighlightedItem(highlightIndex)
                    elseif targetData.finishedSelector then
                        if self.noViolations then
                            self:AddRank(self.selectedName, self.selectedRankIndex)
                            self:RefreshScreen()
                        end

                        ReleaseDialog()
                    end
                end,
                enabled = function()
                    local targetData = parametricDialog.entryList:GetTargetData()
                    local enabled = true

                    if targetData.finishedSelector then
                        enabled = self.noViolations
                    end

                    return enabled
                end,
            },
        },

        noChoiceCallback = function(dialog)
            ReleaseDialog()
        end,
    })
end

function ZO_GuildRanks_Gamepad:InitializeRenameRankDialog()
    local dialogName = GUILD_RENAME_RANK_GAMEPAD_DIALOG
    local parametricDialog = ZO_GenericGamepadDialog_GetControl(GAMEPAD_DIALOGS.PARAMETRIC)

    local function UpdateSelectedName(name)
        if self.selectedName ~= name then
            self.selectedName = name
            self.noViolations = self.selectedName ~= "" and self.selectedName ~= nil
        end
    end

    local function ReleaseDialog()
        ZO_Dialogs_ReleaseDialogOnButtonPress(dialogName)
    end 

    ZO_Dialogs_RegisterCustomDialog(dialogName,
    {
        gamepadInfo = {
            dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
        },

        setup = function(dialog)
            self.noViolations = nil
            self.selectedName = nil
            UpdateSelectedName(self.selectedRank:GetName())
            dialog:setupFunc()
        end,

        blockDialogReleaseOnPress = true, -- We'll handle Dialog Releases ourselves since we don't want DIALOG_PRIMARY to release the dialog on press.

        title =
        {
            text = SI_GAMEPAD_GUILD_RANK_RENAME,
        },
        parametricList =
        {
            -- guild name edit box
            {
                template = "ZO_Gamepad_GenericDialog_Parametric_TextFieldItem",
                templateData = {
                    nameField = true,
                    textChangedCallback = function(control) 
                        local newName = control:GetText()
                        if self.selectedName ~= newName then
                            UpdateSelectedName(newName)
                            ZO_GenericParametricListGamepadDialogTemplate_RefreshVisibleEntries(parametricDialog)
                        end
                    end,
                    
                    setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                        control.highlight:SetHidden(not selected)

                        control.editBoxControl.textChangedCallback = data.textChangedCallback

                        if self.selectedName == "" then
                            ZO_EditDefaultText_Initialize(control.editBoxControl, GetString(SI_GAMEPAD_GUILD_RANK_DIALOG_DEFAULT_TEXT))
                        end
                        control.editBoxControl:SetMaxInputChars(MAX_GUILD_RANK_NAME_LENGTH)
                        control.editBoxControl:SetText(self.selectedName)
                        
                        KEYBIND_STRIP:UpdateCurrentKeybindButtonGroups()
                    end,
                },
            },

            -- confirm rename
            {
                template = "ZO_GamepadTextFieldSubmitItem",
                templateData = {
                    finishedSelector = true,
                    text = GetString(SI_DIALOG_ACCEPT),
                    setup = SetupRequestEntry,
                    validInput = function()
                        return self.noViolations
                    end,
                },
                icon = ZO_GAMEPAD_SUBMIT_ENTRY_ICON,
            },
        },
       
        buttons =
        {
            -- Cancel Button
            {
                keybind = "DIALOG_NEGATIVE",
                text = GetString(SI_DIALOG_CANCEL),
                callback = function()
                    ReleaseDialog()
                end,
            },

            -- Select Button (used for entering name)
            {
                keybind = "DIALOG_PRIMARY",
                text = GetString(SI_GAMEPAD_SELECT_OPTION),
                callback = function(dialog)
                    local targetData = dialog.entryList:GetTargetData()
                    local targetControl = dialog.entryList:GetTargetControl()
                    if targetData.nameField and targetControl then
                        targetControl.editBoxControl:TakeFocus()
                    elseif targetData.finishedSelector then
                        if self.noViolations then
                            self.selectedRank:SetName(self.selectedName)
                            self:RefreshScreen()
                        end

                        ReleaseDialog()
                    end
                end,
                enabled = function()
                    local targetData = parametricDialog.entryList:GetTargetData()
                    local enabled = true

                    if targetData.finishedSelector then
                        enabled = self.noViolations
                    end

                    return enabled
                end,
            },
        },

        noChoiceCallback = function(dialog)
            ReleaseDialog()
        end,
    })
end

local g_deleteRankOnFinished = false
function ZO_GuildRanks_Gamepad:InitializeDeleteRankDialog()
    ZO_Dialogs_RegisterCustomDialog(GUILD_DELETE_RANK_GAMEPAD_DIALOG,
    {
        gamepadInfo = {
            dialogType = GAMEPAD_DIALOGS.BASIC,
        },

        title =
        {
            text = function()
                return zo_strformat(SI_GAMEPAD_GUILD_RANK_DELETE_TITLE, self.selectedRank:GetName())
            end, 
        },

        mainText = 
        {
            text = function()
                return zo_strformat(SI_GUILD_RANK_DELETE_WARNING, self.selectedRank:GetName())
            end, 
        },

        setup = function()
            g_deleteRankOnFinished = false
        end,

        finishedCallback = function(dialog)
            if g_deleteRankOnFinished then
                self:DeleteSelectedRank()
            end
        end,
       
        buttons =
        {
            {
                keybind = "DIALOG_PRIMARY",
                text = SI_GAMEPAD_DIALOG_YES_BUTTON,
                callback = function()
                    g_deleteRankOnFinished = true
                end,
            },

            {
                keybind = "DIALOG_NEGATIVE",
                text = SI_GAMEPAD_DIALOG_NO_BUTTON,
                callback = function()
                    self:RefreshScreen()
                end,
            },
        }
    })
end

------------------
-- Screen Stats --
------------------

function ZO_GuildRanks_Gamepad:IsDisplayingRankList()
    return self.listDisplayMode == LIST_DISPLAY_MODES.RANKS
end

function ZO_GuildRanks_Gamepad:IsDisplayingOptionsList()
    return self.listDisplayMode == LIST_DISPLAY_MODES.OPTIONS
end

function ZO_GuildRanks_Gamepad:IsDisplayingRankIconPicker()
    return self.listDisplayMode == LIST_DISPLAY_MODES.SELECT_ICON
end

function ZO_GuildRanks_Gamepad:IsDisplayingChangePermissions()
    return self.listDisplayMode == LIST_DISPLAY_MODES.CHANGE_PERMISSIONS
end

-------------------------
-- Fragment Management --
-------------------------

function ZO_GuildRanks_Gamepad:RemoveUnusedFragments(fragmentBeingAdded)
    local fragments =
    {
        GUILD_RANKS_PERMISSION_PANEL_FRAGMENT,
        GUILD_RANK_ICON_PICKER_FRAGMENT,
    }

    for i, fragment in ipairs(fragments) do
        if fragmentBeingAdded ~= fragment then
            GAMEPAD_GUILD_HOME_SCENE:RemoveFragment(fragment)
        end
    end
end

function ZO_GuildRanks_Gamepad:ActivateFragment(fragment)
    self:RemoveUnusedFragments(fragment)

    GAMEPAD_GUILD_HOME_SCENE:AddFragment(fragment)
end

function ZO_GuildRanks_Gamepad:GetMessageText()
    if self:IsEditingRank() then
        return self.selectedRank:GetName()
    end

    return nil
end

function ZO_GuildRanks_Gamepad:IsEditingRank()
    return not self:IsDisplayingRankList() and self.selectedRank ~= nil
end

------------------------
-- Change Permissions --
------------------------

function ZO_GuildRanks_Gamepad:SetChangePermissionsEnabled(state)
    if self.changePermissionsEnabled ~= state then
        if state then
            self:DeactivateOptionsList()
            self.permissionsGridList:Activate()
        elseif self.changePermissionsEnabled then
            self.permissionsGridList:Deactivate()
            self:ActivateOptionsList()
        end

        self.changePermissionsEnabled = state
    end
end

function ZO_GuildRanks_Gamepad:SetChangeRankIconPickerEnabled(state)
    if self.changeRankIconPickerEnabled ~= state then
        if state then
            self:DeactivateOptionsList()
            self.rankIconPicker:Activate()
        elseif self.changeRankIconPickerEnabled then
            self.rankIconPicker:Deactivate()
            self:ActivateOptionsList()
        end

        self.changeRankIconPickerEnabled = state
    end
end

------------------
-- Reorder Rank --
------------------

function ZO_GuildRanks_Gamepad:GetSelectedRankIndex()
    return self:GetRankIndexById(self.selectedRank:GetRankId())
end

function ZO_GuildRanks_Gamepad:IsGuildMasterSelected()
    if self.selectedRank ~= nil and self.selectedRank.index ~= nil then
        return IsGuildRankGuildMaster(self.guildId, self.selectedRank.index)
    end

    return false
end

function ZO_GuildRanks_Gamepad:IsLastRankSelected()
    return self:GetSelectedRankIndex() >= #self.ranks
end

function ZO_GuildRanks_Gamepad:InSecondRankSelected()
    return self:GetSelectedRankIndex() <= GUILDMASTER_INDEX + 1
end

function ZO_GuildRanks_Gamepad:ReorderSelectedRank(up)
    if self.selectedRank ~= nil then
        local oldIndex = self:GetSelectedRankIndex()
        local newIndex = oldIndex
        if up then
            newIndex = newIndex - 1
        else
            newIndex = newIndex + 1
        end

        newIndex = zo_clamp(newIndex, GUILDMASTER_INDEX + 1, #self.ranks)

        if newIndex ~= oldIndex then
            local tmp = self.ranks[oldIndex]
            self.ranks[oldIndex] = self.ranks[newIndex]
            self.ranks[newIndex] = tmp

            PlaySound(SOUNDS.GUILD_RANK_REORDERED)

            self:ActivateRankList(REFRESH_SCREEN)
            self.rankList:SetSelectedIndexWithoutAnimation(newIndex)
        end
    end
end

------------------------
-- Delete Rank Dialog --
------------------------

function ZO_GuildRanks_Gamepad:DeleteSelectedRank()
    local index = self:GetSelectedRankIndex()
    table.remove(self.ranks, index)
    self:ResetRankSelection()

    PlaySound(SOUNDS.GUILD_RANK_DELETED)
    self:ActivateRankList(REFRESH_SCREEN)
    self.rankList:SetSelectedIndexWithoutAnimation(1)
end

--------------------
-- Key Bind Strip --
--------------------

function ZO_GuildRanks_Gamepad:InitializeKeybindStrip()
    self.keybindStripDescriptor = {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        -- select
        {
            name = function()
                return GetString(SI_GAMEPAD_SELECT_OPTION)
            end,

            keybind = "UI_SHORTCUT_PRIMARY",

            callback = function()
                if self:IsDisplayingOptionsList() then
                    local selectedOptionsData = self.optionsList:GetTargetData()
                    if selectedOptionsData ~= nil and selectedOptionsData.callback ~= nil then
                        selectedOptionsData.callback()
                    end
                elseif self:IsDisplayingRankList() then
                    local selectedRankData = self.rankList:GetTargetData()
                    if selectedRankData.addRank then
                        selectedRankData.callback()
                    else
                        PlaySound(SOUNDS.GAMEPAD_MENU_FORWARD)
                        self:ActivateOptionsList(REFRESH_SCREEN)
                    end
                elseif self:IsDisplayingRankIconPicker() then
                    self.rankIconPicker:OnRankIconPickerSelectedGridListEntryClicked()
                    self:ActivateOptionsList(REFRESH_SCREEN)
                elseif self:IsDisplayingChangePermissions() then
                    local selectedData = self.permissionsGridList:GetSelectedData()
                    if selectedData then
                        selectedData.dataEntry.control.object:OnCheckboxToggle()
                    end
                end
            end,

            visible = function()
                return DoesPlayerHaveGuildPermission(self.guildId, GUILD_PERMISSION_PERMISSION_EDIT) and #self.ranks > 0
            end,
        },

        -- back
        {
            name = GetString(SI_GAMEPAD_BACK_OPTION),
            keybind = "UI_SHORTCUT_NEGATIVE",

            callback = function()
                if self:IsDisplayingRankList() then
                    GAMEPAD_GUILD_HUB:SetEnterInSingleGuildList(true)
                    SCENE_MANAGER:Hide(GAMEPAD_GUILD_HOME_SCENE_NAME)
                elseif self:IsDisplayingRankIconPicker() or self:IsDisplayingChangePermissions() then
                    if self:NeedsSave() then
                        PlaySound(SOUNDS.GUILD_RANK_SAVED)
                        self:Save()
                    end
                    self.permissionsGridList:Deactivate()
                    self.owningScreen:SetListsUseTriggerKeybinds(true)

                    self:ActivateOptionsList(REFRESH_SCREEN)
                    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
                    PlaySound(SOUNDS.GAMEPAD_MENU_BACK)
                else
                    PlaySound(SOUNDS.GAMEPAD_MENU_BACK)
                    self:ActivateRankList(REFRESH_SCREEN)
                end
            end,
        },
    }
end

-------------
-- Options --
-------------
do
    local ICON_PERMISSIONS = "EsoUI/Art/Guild/Gamepad/gp_guild_options_permissions.dds"
    local ICON_RENAME = "EsoUI/Art/Guild/Gamepad/gp_guild_options_rename.dds"
    local ICON_DELETE = "EsoUI/Art/Guild/Gamepad/gp_guild_options_delete.dds"
    local ICON_CHANGE_ICON = "EsoUI/Art/Guild/Gamepad/gp_guild_options_changeIcon.dds"
    local ICON_REORDER_UP = "EsoUI/Art/Guild/Gamepad/gp_guild_options_reorder_up.dds"
    local ICON_REORDER_DOWN = "EsoUI/Art/Guild/Gamepad/gp_guild_options_reorder_down.dds"

    function ZO_GuildRanks_Gamepad:RefreshOptionsList()
        if self.selectedRank ~= nil then
            local isGuildmasterRankSelected = self:IsGuildMasterSelected()
            self.optionsList:Clear()

            local data = nil
            local firstEntry = true
            local function AddEntry(data)
                data:SetIconTintOnSelection(true)
                if firstEntry then
                    data:SetHeader(GetString(SI_GAMEPAD_GUILD_RANK_OPTIONS)) 
                    self.optionsList:AddEntryWithHeader(GAMEPAD_GUILD_RANKS_MENU_ENTRY_TEMPLATE, data)
                    firstEntry = false
                else
                    self.optionsList:AddEntry(GAMEPAD_GUILD_RANKS_MENU_ENTRY_TEMPLATE, data)
                end
            end

            local canChangePermissions = DoesPlayerHaveGuildPermission(self.guildId, GUILD_PERMISSION_PERMISSION_EDIT) and #self.ranks > 0 and (not self:IsGuildMasterSelected())
            if canChangePermissions then
                data = ZO_GamepadEntryData:New(GetString(SI_GAMEPAD_GUILD_RANK_CHANGE_PERMISSIONS), ICON_PERMISSIONS)
                data.callback = function()
                    PlaySound(SOUNDS.GAMEPAD_MENU_FORWARD)
                    self.listDisplayMode = LIST_DISPLAY_MODES.CHANGE_PERMISSIONS
                    self:RefreshScreen()
                end
                AddEntry(data)
            end

            data = ZO_GamepadEntryData:New(GetString(SI_GAMEPAD_GUILD_RANK_RENAME_ENTRY), ICON_RENAME)
            data.callback = function()
                ZO_Dialogs_ShowGamepadDialog(GUILD_RENAME_RANK_GAMEPAD_DIALOG)
            end
            AddEntry(data)

            if not isGuildmasterRankSelected then
                data = ZO_GamepadEntryData:New(GetString(SI_GAMEPAD_GUILD_RANK_DELETE_ENTRY), ICON_DELETE)
                data.callback = function()
                    if self:IsRankOccupied(self.selectedRank) then
                        ZO_Dialogs_ShowGamepadDialog(GUILD_DELETE_RANK_GAMEPAD_WARNING_DIALOG, nil, { buttonKeybindOverrides = { "DIALOG_PRIMARY" }})
                    else
                        ZO_Dialogs_ShowGamepadDialog(GUILD_DELETE_RANK_GAMEPAD_DIALOG)
                    end
                end
                AddEntry(data)
            end

            data = ZO_GamepadEntryData:New(GetString(SI_GAMEPAD_GUILD_RANK_CHANGE_ICON), ICON_CHANGE_ICON)
            data.callback = function()
                PlaySound(SOUNDS.GAMEPAD_MENU_FORWARD)
                self.listDisplayMode = LIST_DISPLAY_MODES.SELECT_ICON
                self:RefreshScreen()
            end
            AddEntry(data)

            if not isGuildmasterRankSelected then
                if not self:InSecondRankSelected() then
                    data = ZO_GamepadEntryData:New(GetString(SI_GAMEPAD_GUILD_RANK_REORDER_UP), ICON_REORDER_UP)
                    data.unfadeRankList = true
                    data.callback = function()
                        self:ReorderSelectedRank(true)
                    end
                    AddEntry(data)
                end

                if not self:IsLastRankSelected() then
                    data = ZO_GamepadEntryData:New(GetString(SI_GAMEPAD_GUILD_RANK_REORDER_DOWN), ICON_REORDER_DOWN)
                    data.unfadeRankList= true
                    data.callback = function()
                        self:ReorderSelectedRank(false)
                    end
                    AddEntry(data)
                end
            end

            self.optionsList:Commit()
        end
    end
end

---------------
-- Add Rank --
---------------

function ZO_GuildRanks_Gamepad:AddRank(rankName, copyPermissionsFromRankIndex)
    local rank = ZO_GuildRank_Shared:New(GUILD_RANKS_GAMEPAD, self.guildId, nil, rankName)

    local newRankIndex = self:InsertRank(rank, copyPermissionsFromRankIndex)

    self:RefreshScreen()

    self.rankList:SetSelectedIndexWithoutAnimation(newRankIndex)
end

---------------
-- Rank List --
---------------

function ZO_GuildRanks_Gamepad:OnTargetChanged(list, selectedData, oldSelectedData)
    if selectedData ~= nil then
        if selectedData.addRank then
            self:RemoveUnusedFragments()

            self.selectedRank = nil
        elseif selectedData.rankObject ~= nil and self.selectedRank ~= selectedData.rankObject then
            self.selectedRank = selectedData.rankObject
            self:RefreshContent()
        end
    end

    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_GuildRanks_Gamepad:CancelDialog()
    self:RefreshScreen()
end

function ZO_GuildRanks_Gamepad:PopulateRanks()
    self:ResetRankSelection(false)

    self.ranks = {}

    if self.guildId then
        for i = 1, GetNumGuildRanks(self.guildId) do
            local rankObject = ZO_GuildRank_Shared:New(GUILD_RANKS_GAMEPAD, self.guildId, i)
            self.ranks[i] = rankObject
        end
    end
end

function ZO_GuildRanks_Gamepad:RefreshRankList()
    self.rankList:Clear()

    local rankPermission = DoesPlayerHaveGuildPermission(self.guildId, GUILD_PERMISSION_PERMISSION_EDIT)

    for i = 1, #self.ranks do
        local rankObject = self.ranks[i]

        local data = ZO_GamepadEntryData:New(rankObject:GetName(), rankObject:GetLargeIcon())
        data:SetIconTintOnSelection(true)
        data.rankObject = rankObject

        if i == 1 then
            local headerText = GetString(SI_WINDOW_TITLE_GUILD_RANKS)
            if rankPermission then
                headerText = GetString(SI_GAMEPAD_GUILD_RANK_EDIT)
            end
            data:SetHeader(headerText)
            self.rankList:AddEntryWithHeader(GAMEPAD_GUILD_RANKS_MENU_ENTRY_TEMPLATE, data)
        else
            self.rankList:AddEntry(GAMEPAD_GUILD_RANKS_MENU_ENTRY_TEMPLATE, data)
        end
    end

    local addRankEnabled = #self.ranks < MAX_GUILD_RANKS and rankPermission
    if addRankEnabled then
        local data = ZO_GamepadEntryData:New(GetString(SI_GAMEPAD_GUILD_RANK_ADD), "EsoUI/Art/Buttons/Gamepad/gp_plus_large.dds")
        data:SetIconTintOnSelection(true)
        data.addRank = true
        data.callback = function()
            ZO_Dialogs_ShowGamepadDialog(ADD_RANK_DIALOG_NAME)
        end
        data:SetHeader(GetString(SI_GAMEPAD_GUILD_RANK_NEW_HEADER)) 
        self.rankList:AddEntryWithHeader(GAMEPAD_GUILD_RANKS_MENU_ENTRY_TEMPLATE, data)
    end

    self.rankList:Commit()
end

-- XML functions
----------------

function ZO_GuildRanks_Gamepad_Initialize(control)
    GUILD_RANKS_GAMEPAD = ZO_GuildRanks_Gamepad:New(control)
end