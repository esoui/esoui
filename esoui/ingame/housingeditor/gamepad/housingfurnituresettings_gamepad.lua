ZO_GAMEPAD_HOUSING_SETTINGS_DISPLAY_NAME_WIDTH = 310 - ZO_GAMEPAD_INTERACTIVE_FILTER_LIST_HEADER_DOUBLE_PADDING_X
ZO_GAMEPAD_HOUSING_SETTINGS_PERMISSIONS_WIDTH = 437 - ZO_GAMEPAD_INTERACTIVE_FILTER_LIST_HEADER_DOUBLE_PADDING_X

ZO_HousingFurnitureSettings_Gamepad = ZO_HousingFurnitureSettings_Base:Subclass()

function ZO_HousingFurnitureSettings_Gamepad:New(...)
    return ZO_HousingFurnitureSettings_Base.New(self, ...)
end

function ZO_HousingFurnitureSettings_Gamepad:Initialize(owner)
    ZO_HousingFurnitureSettings_Base.Initialize(self, owner.control, owner)

    SYSTEMS:RegisterGamepadObject("furniture_settings", self)

    self:InitializePermissionLists()
    self:InitializeKeybindStripDescriptors()
    self:BuildMainList()

    self:InitializeAddIndividualDialog()
    self:InitializeAddGuildDialog()
    self:InitializeBanIndividualDialog()
    self:InitializeBanGuildDialog()
    self:InitializeRemoveUserGroupDialog()
    self:InitializeChangeUserGroupDialog()
    self:InitializeCopyPermissionsDialog()
end

function ZO_HousingFurnitureSettings_Gamepad:InitializePermissionLists()
    self.visitorList = ZO_HousingSettingsVisitorList_Gamepad:New(self.owner.visitorPermissionsControl, self, ZO_SETTINGS_VISITOR_DATA_TYPE)
    self.banList = ZO_HousingSettingsBanList_Gamepad:New(self.owner.banListPermissionsControl, self, ZO_SETTINGS_BANLIST_DATA_TYPE)
    self.guildVisitorList = ZO_HousingSettingsGuildVisitorList_Gamepad:New(self.owner.guildVisitorPermissionsControl, self, ZO_SETTINGS_GUILD_VISITOR_DATA_TYPE)
    self.guildBanList = ZO_HousingSettingsGuildBanList_Gamepad:New(self.owner.guildBanListPermissionsControl, self, ZO_SETTINGS_GUILD_BANLIST_DATA_TYPE)
end

local function GetStringFromData(data)
    local dataType = type(data)
    if dataType == "function" then
        return data()
    elseif dataType == "number" then
        return GetString(data)
    else
        return data
    end
end

function ZO_HousingFurnitureSettings_Gamepad:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        -- Primary
        {
            name =  function()
                        local targetData = self.mainList:GetTargetData()
                        if targetData.permissionOption == HOUSE_PERMISSION_OPTIONS_CATEGORIES_GENERAL then
                            return GetStringFromData(targetData.generalInfo.buttonText)
                        else
                            return GetString(SI_GAMEPAD_HOUSING_PERMISSIONS_SELECT)
                        end
                    end,
            keybind = "UI_SHORTCUT_PRIMARY",
            callback =  function() 
                            local targetData = self.mainList:GetTargetData()
                            if targetData.permissionOption == HOUSE_PERMISSION_OPTIONS_CATEGORIES_GENERAL then
                                if targetData.generalInfo == ZO_HOUSING_SETTINGS_CONTROL_DATA[ZO_HOUSING_SETTINGS_CONTROL_DATA_PRIMARY_RESIDENCE] then
                                    if self.currentHouse ~= self.primaryResidence then
                                        local collectibleId = GetCollectibleIdForHouse(self.currentHouse)
                                        local name = GetCollectibleName(collectibleId)
                                        local nickname = GetCollectibleNickname(collectibleId)
                                        ZO_Dialogs_ShowGamepadDialog("CONFIRM_PRIMARY_RESIDENCE", { currentHouse = self.currentHouse}, { mainTextParams = { name, nickname} })
                                    end
                                end
                            elseif self.activePanel then
                                self.owner:DeactivateCurrentList()
                                KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
                                self.activePanel:ActivateList()
                            end
                        end,
            enabled = function()
                            local targetData = self.mainList:GetTargetData()
                            if targetData.permissionOption == HOUSE_PERMISSION_OPTIONS_CATEGORIES_GENERAL then
                                if targetData.generalInfo == ZO_HOUSING_SETTINGS_CONTROL_DATA[ZO_HOUSING_SETTINGS_CONTROL_DATA_PRIMARY_RESIDENCE] then
                                    return self.primaryResidence ~= self.currentHouse
                                end
                            elseif self.activePanel then
                                return self.activePanel:GetNumPossibleEntries() > 0
                            end

                            return true
                      end,
            visible = function()
                            local targetData = self.mainList:GetTargetData()
                            if targetData.permissionOption == HOUSE_PERMISSION_OPTIONS_CATEGORIES_GENERAL then
                                return targetData.generalInfo ~= ZO_HOUSING_SETTINGS_CONTROL_DATA[ZO_HOUSING_SETTINGS_CONTROL_DATA_DEFAULT_ACCESS]
                            end
                            return true
                      end,
        },
        -- Secondary
        {
            keybind = "UI_SHORTCUT_SECONDARY",
            name =  function()
                        if self.activePanel == self.visitorList or self.activePanel == self.banList then
                            return GetString(SI_HOUSING_FURNITURE_SETTINGS_ADD_PLAYER_KEYBIND)
                        elseif self.activePanel == self.guildVisitorList or self.activePanel == self.guildBanList then
                            return GetString(SI_HOUSING_FURNITURE_SETTINGS_ADD_GUILD_KEYBIND)
                        end
                    end,
            visible = function()
                          return self.activePanel ~= nil
                      end,
            callback = function()
                local data = { activePanel = self.activePanel, currentHouse = self.currentHouse }
                if self.activePanel == self.visitorList then
                    ZO_Dialogs_ShowGamepadDialog("GAMEPAD_REQUEST_ADD_INDIVIDUAL_PERMISSION", data)
                elseif self.activePanel == self.guildVisitorList then
                    ZO_Dialogs_ShowGamepadDialog("GAMEPAD_REQUEST_ADD_GUILD_PERMISSION", data)
                elseif self.activePanel == self.banList then
                    ZO_Dialogs_ShowGamepadDialog("GAMEPAD_REQUEST_BAN_INDIVIDUAL_PERMISSION", data)
                elseif self.activePanel == self.guildBanList then
                    ZO_Dialogs_ShowGamepadDialog("GAMEPAD_REQUEST_BAN_GUILD_PERMISSION", data)
                end
            end,
        },
        -- Tertiary
        {
            keybind = "UI_SHORTCUT_TERTIARY",
            name =  GetString(SI_HOUSING_FURNITURE_SETTINGS_LOAD_PERMISSIONS_KEYBIND),
            callback = function()
                            self:TryShowCopyDialog()
                       end
        }
    }

    local function OnMainListBack()
        self:DefaultBackKeybindCallback()
    end

    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, OnMainListBack)
end

function ZO_HousingFurnitureSettings_Gamepad:ShowCopyDialog(data)
    ZO_Dialogs_ShowGamepadDialog("GAMEPAD_COPY_HOUSE_PERMISSIONS", data)
end

do
    local ALLOW_EVEN_IF_DISABLED = true
    local NO_ANIMATION = true

    local function HorizontalScrollListSelectionChanged(selectedData, oldData, reselectingDuringRebuild)
        if oldData ~= nil and reselectingDuringRebuild ~= true then
            local canAccess, preset = HOUSE_SETTINGS_MANAGER:GetHousingPermissionsFromDefaultAccess(selectedData.defaultAccess)
            AddHousingPermission(selectedData.currentHouse, HOUSE_PERMISSION_USER_GROUP_GENERAL, canAccess, preset, false)
            selectedData.updateToolTipFunction()
        end
    end

    function ZO_HousingFurnitureSettings_Gamepad:BuildMainList()
        self.mainList = self.owner:RequestNewList()

        local function SetupDefaultAccessControl(control, data, selected, reselectingDuringRebuild, enabled, active)
            GetControl(control, "Name"):SetText(GetString(data.generalInfo.text))

            control.horizontalListObject:Clear()
            local horizontalList = control.horizontalListObject
            local currentHouse = self.currentHouse

            local updateTooltipFunction = function()
                                                local targetData = self.mainList:GetTargetData()
                                                if targetData.index == ZO_HOUSING_SETTINGS_CONTROL_DATA_DEFAULT_ACCESS then
                                                    self:ShowDefaultAccessTooltip() 
                                                end
                                            end

            local allDefaultAccessSettings = HOUSE_SETTINGS_MANAGER:GetAllDefaultAccessSettings()
            for i = HOUSE_PERMISSION_DEFAULT_ACCESS_SETTING_MIN_VALUE, HOUSE_PERMISSION_DEFAULT_ACCESS_SETTING_MAX_VALUE do
                local entryData = 
                {
                    text = allDefaultAccessSettings[i],
                    defaultAccess = i,
                    currentHouse = currentHouse,
                    updateToolTipFunction = updateTooltipFunction,
                    parentControl = control
                }
                horizontalList:AddEntry(entryData)
            end
        
            local color = selected and ZO_SELECTED_TEXT or ZO_DISABLED_TEXT
            local r,g,b,a = color:UnpackRGBA()
            local label = GetControl(control, "Name")
            label:SetColor(r, g, b, 1)

            horizontalList:SetOnSelectedDataChangedCallback(nil) -- don't set the callback til after we update the menu's selected index 
            horizontalList:SetSelectedFromParent(selected)
            horizontalList:Commit()
            horizontalList:SetActive(selected)

            local defaultAccess = HOUSE_SETTINGS_MANAGER:GetDefaultHousingPermission(self.currentHouse)

            horizontalList:SetSelectedDataIndex(defaultAccess + 1, ALLOW_EVEN_IF_DISABLED, NO_ANIMATION) -- plus 1 is for lua index offset
            horizontalList:SetOnSelectedDataChangedCallback(HorizontalScrollListSelectionChanged)
            self.defaultAccessList = horizontalList
        end

        self.mainList:AddDataTemplate("ZO_HousingPermissionsSettingsRow_Gamepad", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
        self.mainList:AddDataTemplate("ZO_GamepadHorizontalListRow", SetupDefaultAccessControl, ZO_GamepadMenuEntryTemplateParametricListFunction)    
    
        for name,toplevelSetting in pairs(ZO_FURNITURE_SETTINGS) do
            for subName,i in pairs(toplevelSetting) do
                if subName == HOUSE_PERMISSION_OPTIONS_CATEGORIES_GENERAL then
                    -- expand out the options under general here
                    for j,info in ipairs(ZO_HOUSING_SETTINGS_CONTROL_DATA) do
                        local entry = ZO_GamepadEntryData:New(GetString(info.text))
                        entry.permissionOption = subName
                        entry.generalInfo = info
                        entry.index = j
                        self.mainList:AddEntry(info.gamepadTemplate, entry)
                    end
                else
                    local entry = ZO_GamepadEntryData:New(self:GetCategoryInfo(subName))
                    entry.permissionOption = subName
                    self.mainList:AddEntry("ZO_HousingPermissionsSettingsRow_Gamepad", entry)
                end
            end
        end

        self.mainList:Commit()
        self.mainList:SetOnTargetDataChangedCallback(function(...) self:OnSettingsTargetChanged(...) end)
    end
end

function ZO_HousingFurnitureSettings_Gamepad:UpdateInfoFromTargetData()
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
    local targetData = self.mainList:GetTargetData()

    self:HideActivePanel()

    if targetData.permissionOption == HOUSE_PERMISSION_OPTIONS_CATEGORIES_VISITORS then
        self.activePanel = self.visitorList
    elseif targetData.permissionOption == HOUSE_PERMISSION_OPTIONS_CATEGORIES_BANLIST then
        self.activePanel = self.banList
    elseif targetData.permissionOption == HOUSE_PERMISSION_OPTIONS_CATEGORIES_GUILD_VISITORS then
        self.activePanel = self.guildVisitorList
    elseif targetData.permissionOption == HOUSE_PERMISSION_OPTIONS_CATEGORIES_GUILD_BANLIST then
        self.activePanel = self.guildBanList
    elseif targetData.permissionOption == HOUSE_PERMISSION_OPTIONS_CATEGORIES_GENERAL then
        local tooltipFunction = targetData.generalInfo.tooltipFunction
        tooltipFunction()
    end

    if self.activePanel then
        self.activePanel:ShowList()
    end

    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_HousingFurnitureSettings_Gamepad:DefaultBackKeybindCallback()
    self:HideActivePanel()
    SCENE_MANAGER:HideCurrentScene()
end

function ZO_HousingFurnitureSettings_Gamepad:OnShowing()
    self.owner:SetCurrentList(self.mainList)
    self.mainList:RefreshVisible()
    self:UpdateInfoFromTargetData()
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
    SCENE_MANAGER:AddFragment(HOUSE_INFORMATION_FRAGMENT_GAMEPAD)
    SCENE_MANAGER:AddFragment(GAMEPAD_NAV_QUADRANT_4_BACKGROUND_FRAGMENT)
end

function ZO_HousingFurnitureSettings_Gamepad:OnHiding()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
    self:DeactivateSelectedControl()
    self:HideActivePanel()
    self.owner:DisableCurrentList()
end

function ZO_HousingFurnitureSettings_Gamepad:HideActivePanel()
    if self.activePanel then
        self.activePanel:HideList()
        self.activePanel = nil
    end
end

function ZO_HousingFurnitureSettings_Gamepad:DeactivateSelectedControl()
    local selectedControl = self.mainList:GetSelectedControl()
    if selectedControl and selectedControl.horizontalListObject then
        selectedControl.horizontalListObject:Deactivate()
    end
end

function ZO_HousingFurnitureSettings_Gamepad:SelectMainMenuList()
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
    self.owner:ActivateCurrentList()
end

function ZO_HousingFurnitureSettings_Gamepad:OnSettingsTargetChanged(list, targetData, oldTargetData)
    self:UpdateInfoFromTargetData()
end

function ZO_HousingFurnitureSettings_Gamepad:UpdateSingleVisitorSettings()
    self.visitorList:RefreshData()
    self.banList:RefreshData()
end

function ZO_HousingFurnitureSettings_Gamepad:UpdateGuildVisitorSettings()
    self.guildVisitorList:RefreshData()
    self.guildBanList:RefreshData()
end

function ZO_HousingFurnitureSettings_Gamepad:UpdateGeneralSettings()
    self.primaryResidence = GetHousingPrimaryHouse()
    local defaultAccess = HOUSE_SETTINGS_MANAGER:GetDefaultHousingPermission(self.currentHouse)

    local ALLOW_EVEN_IF_DISABLED = true
    local NO_ANIMATION = true
    self.defaultAccessList:SetSelectedDataIndex(defaultAccess + 1, ALLOW_EVEN_IF_DISABLED, NO_ANIMATION) -- plus 1 is for lua index offset
    
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_HousingFurnitureSettings_Gamepad:BuildCategories()
    -- only need to build once in BuildMainList
end

function ZO_HousingFurnitureSettings_Gamepad:ShowDefaultAccessTooltip()
    local defaultAccess = HOUSE_SETTINGS_MANAGER:GetDefaultHousingPermission(self.currentHouse)
    GAMEPAD_TOOLTIPS:LayoutDefaultAccessTooltip(GAMEPAD_LEFT_TOOLTIP, defaultAccess)
end

function ZO_HousingFurnitureSettings_Gamepad:ShowPrimaryResidenceTooltip()
    local title = GetStringFromData(SI_HOUSING_FURNITURE_SETTINGS_GENERAL_PRIMARY_RESIDENCE_TEXT)
    local body = GetString(SI_HOUSING_FURNITURE_SETTINGS_GENERAL_PRIMARY_RESIDENCE_TOOLTIP_TEXT)
    GAMEPAD_TOOLTIPS:LayoutTitleAndDescriptionTooltip(GAMEPAD_LEFT_TOOLTIP, title, body)
end

function ZO_HousingFurnitureSettings_Gamepad:ShowHomeShowTooltip()
    local title = GetStringFromData(SI_HOUSING_FURNITURE_SETTINGS_GENERAL_HOMESHOW_TEXT)
    local body = GetString(SI_HOUSING_FURNITURE_SETTINGS_GENERAL_HOMESHOW_TOOLTIP_TEXT)
    GAMEPAD_TOOLTIPS:LayoutTitleAndDescriptionTooltip(GAMEPAD_LEFT_TOOLTIP, title, body)
end

-----------------------------
-- Gamepad Setting Dialogs --
-----------------------------

do
    local INVALID_HOUSE_ID = -1
    local INVALID_COMBOBOX_INDEX = -1

    local function SetActiveEdit(dialog)
        local data = dialog.entryList:GetTargetData()
        local edit = data.control.editBoxControl

        edit:TakeFocus()
    end

    local function SetupRequestEntry(control, data, selected, reselectingDuringRebuild, enabled, active)
        local isValid = enabled
        if data.validInput then
            isValid = data.validInput(data.dialog)
            data.disabled = not isValid
            data:SetEnabled(isValid)
        end

        ZO_SharedGamepadEntry_OnSetup(control, data, selected, reselectingDuringRebuild, isValid, active)
    end

    local function IsValidInput(inputString)
        return inputString and inputString ~= ""
    end

    local function SetupAddOrBanDialog(dialog, dialogName)
        dialog.dialogName = dialogName
        dialog.applyToAllHouses = HOUSE_SETTINGS_MANAGER:GetApplyToAllHousesFlag()
        dialog.selectedPresetIndex = HOUSE_SETTINGS_MANAGER:GetDefaultPreset()
        dialog.selectedGuildIndex = 1
        dialog.selectedGuildId = GetGuildId(1)
        dialog.nameText = ""
        local dialogTitle = dialog.data.activePanel:GetAddUserGroupDialogTitle()
        ZO_GenericGamepadDialog_RefreshText(dialog, dialogTitle)
        dialog:setupFunc()
    end

    local function SetupRemoveDialog(dialog, dialogName)
        dialog.dialogName = dialogName
        dialog.applyToAllHouses = HOUSE_SETTINGS_MANAGER:GetApplyToAllHousesFlag()
        local dialogTitle = dialog.data.titleText
        local dialogText = dialog.data.headerText
        ZO_GenericGamepadDialog_RefreshText(dialog, dialogTitle, dialogText)
        dialog:setupFunc()
    end

    local function SetupChangeDialog(dialog, dialogName)
        dialog.dialogName = dialogName
        dialog.selectedPresetIndex = HOUSE_SETTINGS_MANAGER:GetDefaultPreset()
        dialog.applyToAllHouses = HOUSE_SETTINGS_MANAGER:GetApplyToAllHousesFlag()
        local dialogText = zo_strformat(SI_DIALOG_TEXT_CHANGE_HOUSING_PERMISSION, dialog.data.displayName)
        ZO_GenericGamepadDialog_RefreshText(dialog, GetString(SI_DIALOG_TITLE_CHANGE_HOUSING_PERMISSION), dialogText)
        dialog:setupFunc()
    end

    local function SetupCopyDialog(dialog, dialogName)
        dialog.dialogName = dialogName
        dialog.selectedHouseId = INVALID_HOUSE_ID
        dialog.selectedHouseIndex = INVALID_COMBOBOX_INDEX
        ZO_GenericGamepadDialog_RefreshText(dialog, GetString(SI_DIALOG_COPY_HOUSING_PERMISSION_TITLE))
        dialog:setupFunc()
    end

    local function NoChoiceCallback(dialog)
        -- cleanup all dropdowns
        if dialog.presetSelectorDropdown then
            dialog.presetSelectorDropdown:Deactivate()
            dialog.presetSelectorDropdown = nil
        end

        if dialog.guildSelectorDropdown then
            dialog.guildSelectorDropdown:Deactivate()
            dialog.guildSelectorDropdown = nil
        end

        if dialog.houseSelectorDropdown then
            dialog.houseSelectorDropdown:Deactivate()
            dialog.houseSelectorDropdown = nil
        end

    end

    -- user name
    local userNameData =
    {
        template = "ZO_Gamepad_GenericDialog_Parametric_TextFieldItem",
        templateData = 
        {
            setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                control.highlight:SetHidden(not selected)
                local dialog = data.dialog

                control.editBoxControl.textChangedCallback = function(control)
                                                                dialog.nameText = control:GetText()
                                                             end
                data.control = control

                if dialog.nameText == "" then
                    local activePanel = dialog.data.activePanel
                    local defaultEditString
                    if activePanel:GetUserGroup() == HOUSE_PERMISSION_USER_GROUP_INDIVIDUAL then
                        defaultEditString = ZO_GetInviteInstructions()
                    elseif activePanel:GetUserGroup() == HOUSE_PERMISSION_USER_GROUP_GUILD then
                        defaultEditString = GetString(SI_REQUEST_GUILD_INSTRUCTIONS)
                    end
                    ZO_EditDefaultText_Initialize(control.editBoxControl, defaultEditString)

                    control.resetFunction = function()
                        control.editBoxControl.textChangedCallback = nil
                        control.editBoxControl:SetText("")
                    end
                else
                    control.editBoxControl:SetText(dialog.nameText)
                end
            end,
            visible = function(dialog)
                local activePanel = dialog.data.activePanel
                if activePanel:GetUserGroup() == HOUSE_PERMISSION_USER_GROUP_GUILD then
                    return dialog.selectedGuildIndex > GetNumGuilds()
                end
                return true
            end,
            callback = function(dialog)
                SetActiveEdit(dialog)
            end,
        },
    }

    -- All Houses
    local allHousesData = 
    {
        template = "ZO_CheckBoxTemplate_WithoutIndent_Gamepad",
        text = GetString(SI_DIALOG_OPTION_VISITOR_PERMISSION_AFFECTS_ALL_HOUSES),

        templateData = 
        {
            setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                ZO_GamepadCheckBoxTemplate_Setup(control, data, selected, reselectingDuringRebuild, enabled, active)
                if data.dialog.applyToAllHouses then
                    ZO_CheckButton_SetChecked(control.checkBox)
                else
                    ZO_CheckButton_SetUnchecked(control.checkBox)
                end
            end,
            callback = function(dialog)
                local targetData = dialog.entryList:GetTargetData()
                local targetControl = dialog.entryList:GetTargetControl()
                ZO_GamepadCheckBoxTemplate_OnClicked(targetControl)
                dialog.applyToAllHouses = ZO_GamepadCheckBoxTemplate_IsChecked(targetControl)
                HOUSE_SETTINGS_MANAGER:SetApplyToAllHousesFlag(dialog.applyToAllHouses)
            end,
        },
    }

    -- Preset Selector
    local presetSelectorData =
    {
        header = GetString(SI_GAMEPAD_HOUSING_PERMISSIONS_PRESET_HEADER),
        template = "ZO_GamepadDropdownItem",

        templateData = 
        {
            setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                local dropdown = control.dropdown
                data.dialog.presetSelectorDropdown = dropdown
                dropdown:SetSortsItems(false)
                dropdown:ClearItems()

                local function OnPresetSelected(dropdown, entryText, entry)
                    data.dialog.selectedPresetIndex = entry.presetIndex
                end

                local allPermissionPresets = HOUSE_SETTINGS_MANAGER:GetAllPermissionPresets()
                for i, presetName in pairs(allPermissionPresets) do
                    if i ~= HOUSE_PERMISSION_PRESET_SETTING_INVALID then
                        local newEntry = control.dropdown:CreateItemEntry(presetName, OnPresetSelected)
                        newEntry.presetIndex = i

                        control.dropdown:AddItem(newEntry)
                    end
                end

                dropdown:UpdateItems()

                control.dropdown:SelectItemByIndex(data.dialog.selectedPresetIndex)
            end,
            callback = function(dialog)
                local targetData = dialog.entryList:GetTargetData()
                local targetControl = dialog.entryList:GetTargetControl()
                targetControl.dropdown:Activate()
            end,
        },
    }

    -- Guild Selector
    local guildSelectorData =
    {
        header = GetString(SI_GAMEPAD_HOUSING_PERMISSIONS_GUILD_HEADER),
        template = "ZO_GamepadDropdownItem",

        templateData = 
        {
            setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                local dropdown = control.dropdown
                data.dialog.guildSelectorDropdown = dropdown
                dropdown:SetSortsItems(false)
                dropdown:ClearItems()

                local function OnGuildSelected(dropdown, entryText, entry)
                    data.dialog.selectedGuildIndex = entry.guildIndex
                    data.dialog.selectedGuildId = entry.guildId
                    data.dialog:setupFunc()
                end

                local numGuilds = GetNumGuilds()
                for i = 1, numGuilds do
                    local guildId = GetGuildId(i)
                    local guildName = GetGuildName(guildId)

                    local newEntry = control.dropdown:CreateItemEntry(guildName, OnGuildSelected)
                    newEntry.guildId = guildId
                    newEntry.guildIndex = i
                    control.dropdown:AddItem(newEntry)
                end

                local newEntry = control.dropdown:CreateItemEntry(GetString(SI_GAMEPAD_HOUSING_PERMISSIONS_GUILD_OTHER), OnGuildSelected)
                newEntry.guildId = 0
                newEntry.guildIndex = numGuilds + 1

                control.dropdown:AddItem(newEntry)

                dropdown:UpdateItems()

                local IGNORE_CALLBACK = true
                control.dropdown:SelectItemByIndex(data.dialog.selectedGuildIndex, IGNORE_CALLBACK)
            end,
            callback = function(dialog)
                local targetData = dialog.entryList:GetTargetData()
                local targetControl = dialog.entryList:GetTargetControl()
                targetControl.dropdown:Activate()
            end,
        },
    }

    -- House Selector
    local houseSelectorData =
    {
        header = GetString(SI_GAMEPAD_HOUSING_PERMISSIONS_HOUSE_HEADER),
        template = "ZO_GamepadDropdownItem",

        templateData = 
        {
            setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                local dropdown = control.dropdown
                data.dialog.houseSelectorDropdown = dropdown
                dropdown:SetSortsItems(false)
                dropdown:ClearItems()

                local function OnHouseSelected(_, entryText, entry)
                    data.dialog.selectedHouseId = entry.houseId
                    data.dialog.selectedHouseIndex = entry.houseIndex
                    data.dialog:setupFunc()
                end

                HOUSE_SETTINGS_MANAGER:SetupCopyPermissionsCombobox(dropdown, data.dialog.data.currentHouse, OnHouseSelected)

                dropdown:UpdateItems()

                local IGNORE_CALLBACK = true
                if data.dialog.selectedHouseIndex > INVALID_COMBOBOX_INDEX then
                    control.dropdown:SelectItemByIndex(data.dialog.selectedHouseIndex, IGNORE_CALLBACK)
                end
            end,
            callback = function(dialog)
                local targetData = dialog.entryList:GetTargetData()
                local targetControl = dialog.entryList:GetTargetControl()
                targetControl.dropdown:Activate()
            end,
        },
    }

    -- Dialog Button Data
    local buttonsData =
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
            enabled = function(control)
                local targetData = control.dialog.entryList:GetTargetData()
                if targetData.validInput then
                    return targetData.validInput(control.dialog)
                end

                return true
            end,
        },

        {
            keybind = "DIALOG_NEGATIVE",
            text = SI_DIALOG_CANCEL,
            callback =  function(dialog)
                ZO_Dialogs_ReleaseDialogOnButtonPress(dialog.dialogName)
            end,
        },
    }

    function ZO_HousingFurnitureSettings_Gamepad:InitializeAddIndividualDialog()
        local dialogName = "GAMEPAD_REQUEST_ADD_INDIVIDUAL_PERMISSION"

        ZO_Dialogs_RegisterCustomDialog(dialogName,
        {
            gamepadInfo =
            {
                dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
            },
            setup = function(dialog)
                SetupAddOrBanDialog(dialog, dialogName)
            end,
            parametricList =
            {
                -- user name
                userNameData,

                -- Preset Selector
                presetSelectorData,

                -- All Houses
                allHousesData,

                -- Confirm
                {
                    template = "ZO_GamepadTextFieldSubmitItem",
                    templateData = 
                    {
                        text = GetString(SI_DIALOG_CONFIRM),
                        setup = SetupRequestEntry,
                        callback = function(dialog)
                            local nameText = ZO_FormatManualNameEntry(dialog.nameText)

                            if IsValidInput(nameText) then
                                local ALLOW_ACCESS = true

                                local data = dialog.data
                                local activePanel = data.activePanel
                                local userGroup = activePanel:GetUserGroup()

                                AddHousingPermission(data.currentHouse, userGroup, ALLOW_ACCESS, dialog.selectedPresetIndex, dialog.applyToAllHouses, nameText)
                                ZO_Dialogs_ReleaseDialogOnButtonPress(dialogName)
                            end
                        end,
                        validInput = function(dialog)
                            return IsValidInput(dialog.nameText)
                        end,
                    }
                },
            },
            blockDialogReleaseOnPress = true,
            buttons = buttonsData,
            noChoiceCallback = NoChoiceCallback,
        })
    end

    function ZO_HousingFurnitureSettings_Gamepad:InitializeAddGuildDialog()
        local dialogName = "GAMEPAD_REQUEST_ADD_GUILD_PERMISSION"

        ZO_Dialogs_RegisterCustomDialog(dialogName,
        {
            gamepadInfo =
            {
                dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
            },
            setup = function(dialog)
                SetupAddOrBanDialog(dialog, dialogName)
            end,
            parametricList =
            {
                -- Guild Selector
                guildSelectorData,

                -- user name
                userNameData,

                -- Preset Selector
                presetSelectorData,

                -- All Houses
                allHousesData,

                -- Confirm
                {
                    template = "ZO_GamepadTextFieldSubmitItem",
                    templateData = 
                    {
                        text = GetString(SI_DIALOG_CONFIRM),
                        setup = SetupRequestEntry,
                        callback = function(dialog)
                            local nameText 
                            if dialog.selectedGuildIndex > GetNumGuilds() then
                                nameText = dialog.nameText
                            else
                                nameText = GetGuildName(dialog.selectedGuildId)
                            end

                            if IsValidInput(nameText) then
                                local ALLOW_ACCESS = true
                                local data = dialog.data
                                local activePanel = data.activePanel
                                local userGroup = activePanel:GetUserGroup()
                                AddHousingPermission(data.currentHouse, userGroup, ALLOW_ACCESS, dialog.selectedPresetIndex, dialog.applyToAllHouses, nameText)
                                ZO_Dialogs_ReleaseDialogOnButtonPress(dialogName)
                            end
                        end,
                        validInput = function(dialog)
                            return IsValidInput(dialog.nameText) or dialog.selectedGuildIndex <= GetNumGuilds()
                        end,
                    }
                },
            },
            blockDialogReleaseOnPress = true,
            buttons = buttonsData,
            noChoiceCallback = NoChoiceCallback,
        })
    end

    function ZO_HousingFurnitureSettings_Gamepad:InitializeBanIndividualDialog()
        local dialogName = "GAMEPAD_REQUEST_BAN_INDIVIDUAL_PERMISSION"

        ZO_Dialogs_RegisterCustomDialog(dialogName,
        {
            gamepadInfo =
            {
                dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
            },
            setup = function(dialog)
                SetupAddOrBanDialog(dialog, dialogName)
            end,
            parametricList =
            {
                -- user name
                userNameData,

                -- All Houses
                allHousesData,

                -- Confirm
                {
                    template = "ZO_GamepadTextFieldSubmitItem",
                    templateData = 
                    {
                        text = GetString(SI_DIALOG_CONFIRM),
                        setup = SetupRequestEntry,
                        callback = function(dialog)
                            local nameText = ZO_FormatManualNameEntry(dialog.nameText)

                            if IsValidInput(nameText) then
                                local DISALLOW_ACCESS = false
                                local CANNOT_EDIT = false

                                local data = dialog.data
                                local activePanel = data.activePanel
                                local userGroup = activePanel:GetUserGroup()

                                AddHousingPermission(data.currentHouse, userGroup, DISALLOW_ACCESS, HOUSE_PERMISSION_PRESET_SETTING_INVALID, dialog.applyToAllHouses, nameText)
                                ZO_Dialogs_ReleaseDialogOnButtonPress(dialogName)
                            end
                        end,
                        validInput = function(dialog)
                            return IsValidInput(dialog.nameText)
                        end,
                    }
                },
            },
            blockDialogReleaseOnPress = true,
            buttons = buttonsData,
        })
    end

    function ZO_HousingFurnitureSettings_Gamepad:InitializeBanGuildDialog()
        local dialogName = "GAMEPAD_REQUEST_BAN_GUILD_PERMISSION"

        ZO_Dialogs_RegisterCustomDialog(dialogName,
        {
            gamepadInfo =
            {
                dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
            },
            setup = function(dialog)
                SetupAddOrBanDialog(dialog, dialogName)
            end,
            parametricList =
            {
                -- Guild Selector
                guildSelectorData,

                -- user name
                userNameData,

                -- All Houses
                allHousesData,

                -- Confirm
                {
                    template = "ZO_GamepadTextFieldSubmitItem",
                    templateData = 
                    {
                        text = GetString(SI_DIALOG_CONFIRM),
                        setup = SetupRequestEntry,
                        callback = function(dialog)
                            local nameText 
                            if dialog.selectedGuildIndex > GetNumGuilds() then
                                nameText = dialog.nameText
                            else
                                nameText = GetGuildName(dialog.selectedGuildId)
                            end

                            if IsValidInput(nameText) then
                                local DISALLOW_ACCESS = false
                                local CANNOT_EDIT = false

                                local data = dialog.data
                                local activePanel = data.activePanel
                                local userGroup = activePanel:GetUserGroup()

                                AddHousingPermission(data.currentHouse, userGroup, DISALLOW_ACCESS, HOUSE_PERMISSION_PRESET_SETTING_INVALID, dialog.applyToAllHouses, nameText)
                                ZO_Dialogs_ReleaseDialogOnButtonPress(dialogName)
                            end
                        end,
                        validInput = function(dialog)
                            return IsValidInput(dialog.nameText) or dialog.selectedGuildIndex <= GetNumGuilds()
                        end,
                    }
                },
            },
            blockDialogReleaseOnPress = true,
            buttons = buttonsData,
            noChoiceCallback = NoChoiceCallback,
        })
    end

    function ZO_HousingFurnitureSettings_Gamepad:InitializeRemoveUserGroupDialog()
        local dialogName = "GAMEPAD_CONFIRM_REMOVE_PERMISSIONS"

        ZO_Dialogs_RegisterCustomDialog(dialogName,
        {
            gamepadInfo =
            {
                dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
            },
            canQueue = true,
            setup = function(dialog)
                SetupRemoveDialog(dialog, dialogName)
            end,
            parametricList =
            {
                -- All Houses
                allHousesData,

                -- Confirm
                {
                    template = "ZO_GamepadTextFieldSubmitItem",
                    templateData = 
                    {
                        text = GetString(SI_DIALOG_CONFIRM),
                        setup = SetupRequestEntry,
                        callback = function(dialog)
                            local data = dialog.data

                            RemoveHousingPermission(data.currentHouse, data.userGroup, data.index, dialog.applyToAllHouses)
                            ZO_Dialogs_ReleaseDialogOnButtonPress(dialogName)
                        end,
                    }
                },
            },
            blockDialogReleaseOnPress = true,
            buttons = buttonsData,
        })
    end

    function ZO_HousingFurnitureSettings_Gamepad:InitializeChangeUserGroupDialog()
        local dialogName = "GAMEPAD_CHANGE_HOUSING_PERMISSIONS"

        ZO_Dialogs_RegisterCustomDialog(dialogName,
        {
            gamepadInfo =
            {
                dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
            },
            canQueue = true,
            setup = function(dialog)
                SetupChangeDialog(dialog, dialogName)
            end,
            parametricList =
            {
                -- Preset Selector
                presetSelectorData,

                -- All Houses
                allHousesData,

                -- Confirm
                {
                    template = "ZO_GamepadTextFieldSubmitItem",
                    templateData = 
                    {
                        text = GetString(SI_DIALOG_CONFIRM),
                        setup = SetupRequestEntry,
                        callback = function(dialog)
                            local data = dialog.data

                            SetHousingPermissionPreset(data.currentHouse, data.userGroup, data.index, dialog.selectedPresetIndex, dialog.applyToAllHouses)
                            ZO_Dialogs_ReleaseDialogOnButtonPress(dialogName)
                        end,
                    }
                },
            },
            blockDialogReleaseOnPress = true,
            buttons = buttonsData,
            noChoiceCallback = NoChoiceCallback,
        })
    end

    function ZO_HousingFurnitureSettings_Gamepad:InitializeCopyPermissionsDialog()
        local dialogName = "GAMEPAD_COPY_HOUSE_PERMISSIONS"

        ZO_Dialogs_RegisterCustomDialog(dialogName,
        {
            gamepadInfo =
            {
                dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
            },
            setup = function(dialog)
                SetupCopyDialog(dialog, dialogName)
            end,
            parametricList =
            {
                -- House Selector
                houseSelectorData,

                -- Confirm
                {
                    template = "ZO_GamepadTextFieldSubmitItem",
                    templateData = 
                    {
                        text = GetString(SI_DIALOG_CONFIRM),
                        setup = SetupRequestEntry,
                        callback = function(dialog)
                            local data = dialog.data
                            CopyHousePermissions(dialog.selectedHouseId, data.currentHouse)
                            ZO_Dialogs_ReleaseDialogOnButtonPress(dialogName)
                        end,
                         validInput = function(dialog)
                            return dialog.selectedHouseId > INVALID_HOUSE_ID
                        end,
                    },
                },
            },
            blockDialogReleaseOnPress = true,
            buttons = buttonsData,
            noChoiceCallback = NoChoiceCallback,
        })
    end
end
