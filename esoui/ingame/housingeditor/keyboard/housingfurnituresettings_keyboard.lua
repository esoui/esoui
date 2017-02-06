ZO_KEYBOARD_HOUSING_SETTINGS_DISPLAY_NAME_WIDTH = 300
ZO_KEYBOARD_HOUSING_SETTINGS_PERMISSIONS_WIDTH = 290

ZO_HousingFurnitureSettings_Keyboard = ZO_Object.MultiSubclass(ZO_HousingFurnitureSettings_Base, ZO_HousingBrowserList)

function ZO_HousingFurnitureSettings_Keyboard:New(...)
    return ZO_HousingFurnitureSettings_Base.New(self, ...)
end

function ZO_HousingFurnitureSettings_Keyboard:Initialize(...)
    ZO_HousingFurnitureSettings_Base.Initialize(self, ...)
    ZO_HousingBrowserList.Initialize(self, ...)

    self.settingsTreeData = ZO_FurnitureCategory:New()
        
    for name,topLevelSetting in pairs(ZO_FURNITURE_SETTINGS) do
        local subsettingsTreeData = ZO_FurnitureCategory:New(self.settingsTreeData, name)
        self.settingsTreeData:AddSubcategory(name, subsettingsTreeData)
        for _,i in pairs(topLevelSetting) do
            subsettingsTreeData:AddSubcategory(i, ZO_FurnitureCategory:New(subsettingsTreeData, i))
        end
    end

    self:InitializeSettingsPanels()

    SYSTEMS:RegisterKeyboardObject("furniture_settings", self)
end

function ZO_HousingFurnitureSettings_Keyboard:InitializeSettingsPanels()
    self.categoryIndexToPanel = {}
    self.generalOptionsPanel = self.contents:GetNamedChild("General")
    self.categoryIndexToPanel[HOUSE_PERMISSION_OPTIONS_CATEGORIES_GENERAL] = self.generalOptionsPanel
    self.activePanel = self.generalOptionsPanel

    self.generalOptionsScrollList = self.generalOptionsPanel:GetNamedChild("Settings")
    local generalOptionsScrollChild = GetControl(self.generalOptionsScrollList, "ScrollChild")

    local function OnPrimaryResidenceClicked(button)
        if self.currentHouse ~= self.primaryResidence then
            local collectibleId = GetCollectibleIdForHouse(self.currentHouse)
            local name = GetCollectibleName(collectibleId)
            local nickname = GetCollectibleNickname(collectibleId)
            ZO_Dialogs_ShowDialog("CONFIRM_PRIMARY_RESIDENCE", { currentHouse = self.currentHouse}, { mainTextParams = { name, nickname} })
        end
    end

    self.primaryResidenceSetting = self.generalOptionsPanel:GetNamedChild("PrimaryResidence")
    self.primaryResidenceSetting:SetParent(generalOptionsScrollChild)
    self.primaryResidenceButton = self.primaryResidenceSetting:GetNamedChild("Button")
    self.primaryResidenceButton:SetHandler("OnClicked", OnPrimaryResidenceClicked)

    self.defaultAccessSetting = self.generalOptionsPanel:GetNamedChild("DefaultAccess")
    self.defaultAccessSetting:SetParent(generalOptionsScrollChild)
    self.defaultAccessDropDown = self.defaultAccessSetting:GetNamedChild("DropDown")
    self:BuildDefaultAccessSettings(self.defaultAccessSetting)

    self.visitorsOptionsPanel = self.contents:GetNamedChild("Visitors")
    self.visitorsSocialList = ZO_HousingSettingsVisitorList_Keyboard:New(self.visitorsOptionsPanel, self, ZO_SETTINGS_VISITOR_DATA_TYPE, "ZO_HousingSettings_WhiteList_Row")
    self.visitorsOptionsPanel.list = self.visitorsSocialList
    self.categoryIndexToPanel[HOUSE_PERMISSION_OPTIONS_CATEGORIES_VISITORS] = self.visitorsOptionsPanel

    self.banListOptionsPanel = self.contents:GetNamedChild("BanList")
    self.banListSocialList = ZO_HousingSettingsBanList_Keyboard:New(self.banListOptionsPanel, self, ZO_SETTINGS_BANLIST_DATA_TYPE, "ZO_HousingSettings_BanList_Row")
    self.banListOptionsPanel.list = self.banListSocialList
    self.categoryIndexToPanel[HOUSE_PERMISSION_OPTIONS_CATEGORIES_BANLIST] = self.banListOptionsPanel

    self.guildVisitorsOptionsPanel = self.contents:GetNamedChild("GuildVisitors")
    self.guildVisitorsSocialList = ZO_HousingSettingsGuildVisitorList_Keyboard:New(self.guildVisitorsOptionsPanel, self, ZO_SETTINGS_GUILD_VISITOR_DATA_TYPE, "ZO_HousingSettings_WhiteList_Row")
    self.guildVisitorsOptionsPanel.list = self.guildVisitorsSocialList
    self.categoryIndexToPanel[HOUSE_PERMISSION_OPTIONS_CATEGORIES_GUILD_VISITORS] = self.guildVisitorsOptionsPanel

    self.guildBanListOptionsPanel = self.contents:GetNamedChild("GuildBanList")
    self.guildBanListSocialList = ZO_HousingSettingsGuildBanList_Keyboard:New(self.guildBanListOptionsPanel, self, ZO_SETTINGS_GUILD_BANLIST_DATA_TYPE, "ZO_HousingSettings_BanList_Row")
    self.guildBanListOptionsPanel.list = self.guildBanListSocialList 
    self.categoryIndexToPanel[HOUSE_PERMISSION_OPTIONS_CATEGORIES_GUILD_BANLIST] = self.guildBanListOptionsPanel
end

function ZO_HousingFurnitureSettings_Keyboard:InitializeKeybindStrip()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,

        -- Add Player
        {
            name = function()
                        if self.activePanel == self.visitorsOptionsPanel or self.activePanel == self.banListOptionsPanel then
                            return GetString(SI_HOUSING_FURNITURE_SETTINGS_ADD_PLAYER_KEYBIND)
                        elseif self.activePanel == self.guildVisitorsOptionsPanel or self.activePanel == self.guildBanListOptionsPanel then
                            return GetString(SI_HOUSING_FURNITURE_SETTINGS_ADD_GUILD_KEYBIND)
                        end
                   end,
            keybind = "UI_SHORTCUT_SECONDARY",
        
            callback = function()
                local data = { activePanel = self.activePanel.list, currentHouse = self.currentHouse }
                if self.activePanel == self.visitorsOptionsPanel then
                    ZO_Dialogs_ShowDialog("REQUEST_ADD_INDIVIDUAL_PERMISSION", data)
                elseif self.activePanel == self.banListOptionsPanel then
                    ZO_Dialogs_ShowDialog("REQUEST_BAN_INDIVIDUAL_PERMISSION", data)
                elseif self.activePanel == self.guildVisitorsOptionsPanel then
                    ZO_Dialogs_ShowDialog("REQUEST_ADD_GUILD_PERMISSION", data)
                elseif self.activePanel == self.guildBanListOptionsPanel then
                    ZO_Dialogs_ShowDialog("REQUEST_BAN_GUILD_PERMISSION", data)
                end
            end,

            visible = function()
                return self.activePanel ~= self.generalOptionsPanel
            end
        },

        -- Load Permissions
        {
            name = GetString(SI_HOUSING_FURNITURE_SETTINGS_LOAD_PERMISSIONS_KEYBIND),
            keybind = "UI_SHORTCUT_TERTIARY",
        
            callback = function()
                self:TryShowCopyDialog()
            end,
        },
    }
end

function ZO_HousingFurnitureSettings_Keyboard:ShowCopyDialog(data)
    ZO_Dialogs_ShowDialog("COPY_HOUSING_PERMISSIONS", data)
end

function ZO_HousingFurnitureSettings_Keyboard:UpdateGeneralSettings()
    self.primaryResidence = GetHousingPrimaryHouse()

    self:UpdateButtonSettings(self.primaryResidenceSetting)
    self.primaryResidenceButton:SetEnabled(self.primaryResidence ~= self.currentHouse)

    local defaultAccess = HOUSE_SETTINGS_MANAGER:GetDefaultHousingPermission(self.currentHouse)
    self.comboBox:SetSelectedItemText(GetString("SI_HOUSEPERMISSIONDEFAULTACCESSSETTING", defaultAccess))
end

function ZO_HousingFurnitureSettings_Keyboard:UpdateSingleVisitorSettings()
    self.visitorsSocialList:RefreshData()
    self.banListSocialList:RefreshData()
end

function ZO_HousingFurnitureSettings_Keyboard:UpdateGuildVisitorSettings()
    self.guildVisitorsSocialList:RefreshData()
    self.guildBanListSocialList:RefreshData()
end

do
    local CAN_ACCESS = true

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

    function ZO_HousingFurnitureSettings_Keyboard:UpdateButtonSettings(control)
        local data = control.data
        local buttonControl = GetControl(control, "Button")
        local nameControl = GetControl(control, "Name")

        local buttonText = GetStringFromData(data.buttonText)
        buttonControl:SetText(buttonText)

        local labelText = GetStringFromData(data.text)
        nameControl:SetText(labelText)
    end

    function ZO_HousingFurnitureSettings_Keyboard:BuildDefaultAccessSettings(control)
        local data = control.data
        local dropDownControl = GetControl(control, "DropDown")
        local nameControl = GetControl(control, "Name")

        local labelText = GetStringFromData(data.text)
        nameControl:SetText(labelText)

        local comboBox = ZO_ComboBox_ObjectFromContainer(dropDownControl)
        self.comboBox = comboBox
        comboBox:SetSortsItems(false)

        local function OnPresetSelected(_, entryText, entry)
            comboBox:SetSelectedItemText(entry.name)
            local canAccess, preset = HOUSE_SETTINGS_MANAGER:GetHousingPermissionsFromDefaultAccess(entry.defaultAccess)
            AddHousingPermission(self.currentHouse, HOUSE_PERMISSION_USER_GROUP_GENERAL, canAccess, preset, false)
        end

        local allDefaultAccessSettings = HOUSE_SETTINGS_MANAGER:GetAllDefaultAccessSettings()
        for i = HOUSE_PERMISSION_DEFAULT_ACCESS_SETTING_MIN_VALUE, HOUSE_PERMISSION_DEFAULT_ACCESS_SETTING_MAX_VALUE do
            local entry = comboBox:CreateItemEntry(allDefaultAccessSettings[i], OnPresetSelected)
            entry.defaultAccess = i
            comboBox:AddItem(entry)
        end
    end
end

function ZO_HousingFurnitureSettings_Keyboard:GetCategoryTreeData()
    return self.settingsTreeData
end

function ZO_HousingFurnitureSettings_Keyboard:OnCategorySelected(data)
    local categoryPanel = self.categoryIndexToPanel[data.categoryId]
    if categoryPanel then
        self:SetActivePanel(categoryPanel)
    end
end

do
    local IS_HIDDEN = true
    function ZO_HousingFurnitureSettings_Keyboard:SetActivePanel(panel)
        if self.activePanel ~= panel then
            self.activePanel:SetHidden(IS_HIDDEN)

            self.activePanel = panel

            panel:SetHidden(not IS_HIDDEN)

            KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
        end
    end
end

function ZO_HousingFurnitureSettings_Keyboard:ShowDefaultAccessTooltip(control)
    local defaultAccess = HOUSE_SETTINGS_MANAGER:GetDefaultHousingPermission(self.currentHouse)
    InitializeTooltip(InformationTooltip, control, BOTTOMLEFT, 0, -2, TOPLEFT)
    local r,g,b = ZO_NORMAL_TEXT:UnpackRGB()
    InformationTooltip:AddLine(GetString(SI_HOUSING_FURNITURE_SETTINGS_GENERAL_DEFAULT_ACCESS_TOOLTIP_TEXT), "", r, g, b)

    local selectionTitle = GetString("SI_HOUSEPERMISSIONDEFAULTACCESSSETTING",  defaultAccess)
    local selectionDescription = GetString("SI_HOUSING_PERMISSIONS_DEFAULT_ACCESS_DESCRIPTION", defaultAccess)

    InformationTooltip:AddLine(selectionTitle)
    InformationTooltip:AddLine(selectionDescription, "", r, g, b)
end

function ZO_HousingFurnitureSettings_Keyboard:ShowPrimaryResidenceTooltip(control)
    InitializeTooltip(InformationTooltip, control, BOTTOMLEFT, 0, -2, TOPLEFT)
    SetTooltipText(InformationTooltip, GetString(SI_HOUSING_FURNITURE_SETTINGS_GENERAL_PRIMARY_RESIDENCE_TOOLTIP_TEXT))
end

function ZO_HousingFurnitureSettings_Keyboard:ShowHomeShowTooltip(control)
    InitializeTooltip(InformationTooltip, control, BOTTOMLEFT, 0, -2, TOPLEFT)
    SetTooltipText(InformationTooltip, GetString(SI_HOUSING_FURNITURE_SETTINGS_GENERAL_HOMESHOW_TOOLTIP_TEXT))
end

-- XML Functions
-------------------
function ZO_HousingSettingsRow_OnMouseEnter(control)
    control.panel:EnterRow(control)
end

function ZO_HousingSettingsRow_OnMouseExit(control)
    control.panel:ExitRow(control)
end

function ZO_HousingSettingsRow_OnMouseUp(control, button, upInside)
    if button == MOUSE_BUTTON_INDEX_RIGHT and upInside then
        ClearMenu()

        local data = ZO_ScrollList_GetData(control)
        if data.dataEntry.typeId == ZO_SETTINGS_VISITOR_DATA_TYPE or data.dataEntry.typeId == ZO_SETTINGS_GUILD_VISITOR_DATA_TYPE then
            AddMenuItem(GetString(SI_HOUSING_PERMISSIONS_OPTIONS_CHANGE_PERMISSIONS), function() ZO_Dialogs_ShowDialog("CHANGE_HOUSING_PERMISSIONS", data) end)

            local headerText
            local titleText
            if data.dataEntry.typeId == ZO_SETTINGS_VISITOR_DATA_TYPE  then
                 headerText = zo_strformat(SI_DIALOG_TEXT_REMOVE_INDIVIDUAL_PERMISSION, data.displayName)
                 titleText = GetString(SI_DIALOG_TITLE_REMOVE_INDIVIDUAL_PERMISSION)
            elseif data.dataEntry.typeId == ZO_SETTINGS_GUILD_VISITOR_DATA_TYPE then
                headerText = zo_strformat(SI_DIALOG_TEXT_REMOVE_GUILD_PERMISSION, data.displayName)
                titleText = GetString(SI_DIALOG_TITLE_REMOVE_GUILD_PERMISSION)
            end

            AddMenuItem(GetString(SI_HOUSING_PERMISSIONS_OPTIONS_REMOVE), function() ZO_Dialogs_ShowDialog("CONFIRM_REMOVE_PERMISSIONS", { titleText = titleText, headerText = headerText, currentHouse = data.currentHouse, userGroup = data.userGroup, index = data.index }) end)
            control.panel:ShowMenu(control)
        end
    end
end

function ZO_HousingSettings_BanList_Row_OnClick(control)
    local headerText
    local titleText
    local data = ZO_ScrollList_GetData(control)
    if data.dataEntry.typeId == ZO_SETTINGS_BANLIST_DATA_TYPE or data.dataEntry.typeId == ZO_SETTINGS_GUILD_BANLIST_DATA_TYPE then
        if data.dataEntry.typeId == ZO_SETTINGS_BANLIST_DATA_TYPE then
            headerText = zo_strformat(SI_DIALOG_TEXT_REMOVE_BANLIST_INDIVIDUAL_PERMISSION, data.displayName)
            titleText = GetString(SI_DIALOG_TITLE_REMOVE_BANLIST_INDIVIDUAL_PERMISSION)
        elseif data.dataEntry.typeId == ZO_SETTINGS_GUILD_BANLIST_DATA_TYPE then
            headerText = zo_strformat(SI_DIALOG_TEXT_REMOVE_BANLIST_GUILD_PERMISSION, data.displayName)
            titleText = GetString(SI_DIALOG_TITLE_REMOVE_BANLIST_GUILD_PERMISSION)
        end
        ZO_Dialogs_ShowDialog("CONFIRM_REMOVE_PERMISSIONS", { titleText = titleText, headerText = headerText, currentHouse = data.currentHouse, userGroup = data.userGroup, index = data.index })
    end
end


-- Setting Dialogs --
---------------------

function ZO_HousingSettings_TogglePermission(control, state)
    control.parentDialog.changedData[control.permissionSetting] = state
end

do
    local ALLOW_ACCESS = true
    local CANNOT_EDIT = false

    local function SetupPresetComboBox(dialog)
        local presetsComboBoxControl = GetControl(dialog, "Presets")
        dialog.presetsComboBox = ZO_ComboBox_ObjectFromContainer(presetsComboBoxControl)
        dialog.presetsComboBox:SetSortsItems(false)


        local function OnPresetSelected(_, entryText, entry)
            dialog.selectedPreset = entry.presetIndex
            dialog.presetsComboBox:SetSelectedItemText(entry.name)
        end
       
        local allPermissionPresets = HOUSE_SETTINGS_MANAGER:GetAllPermissionPresets()
        for i, presetName in pairs(allPermissionPresets) do
            if i ~= HOUSE_PERMISSION_PRESET_SETTING_INVALID then
                local entry = dialog.presetsComboBox:CreateItemEntry(presetName, OnPresetSelected)
                entry.presetIndex = i
                dialog.presetsComboBox:AddItem(entry)
            end
        end
    end

    local function SetupHousesComboBox(dialog)
        local housesComboBoxControl = GetControl(dialog, "HousesComboBox")
        dialog.housesComboBox = ZO_ComboBox_ObjectFromContainer(housesComboBoxControl)
        dialog.housesComboBox:SetSortsItems(false)
    end

    local function SetupChangePermissionsDialog(dialog)
        dialog:GetNamedChild("Header"):SetText(zo_strformat(SI_DIALOG_TEXT_CHANGE_HOUSING_PERMISSION, dialog.data.displayName))

        local data = dialog.data

        if dialog.presetsComboBox then
            dialog.presetsComboBox:SetSelectedItemText(data.permissionPresetName)
            dialog.selectedPreset = HOUSE_SETTINGS_MANAGER:GetHousingPresetIndex(data.permissionPresetName)
        end

        local allHousesCheckBoxControl = dialog:GetNamedChild("AllHouses")
        ZO_CheckButton_SetCheckState(allHousesCheckBoxControl, HOUSE_SETTINGS_MANAGER:GetApplyToAllHousesFlag())
    end

    local function SetupCopyPermissionsDialog(dialog)
        local data = dialog.data

        dialog.confirmButton:SetState(BSTATE_DISABLED, false)

        if dialog.housesComboBox then
            local INVALID_HOUSE_ID = -1
            dialog.housesComboBox:ClearItems()
            dialog.selectedHouseId = INVALID_HOUSE_ID

            local function OnHouseSelected(_, entryText, entry)
                dialog.selectedHouseId = entry.houseId
                dialog.housesComboBox:SetSelectedItemText(entry.name)
                dialog.confirmButton:SetState(BSTATE_NORMAL, true)
            end
            
            HOUSE_SETTINGS_MANAGER:SetupCopyPermissionsCombobox(dialog.housesComboBox, dialog.data.currentHouse, OnHouseSelected)
        end
    end

    function ZO_ChangeHousingPermissionsDialog_OnInitialized(self)
        ZO_Dialogs_RegisterCustomDialog("CHANGE_HOUSING_PERMISSIONS",
        {
            customControl = self,
            setup = SetupChangePermissionsDialog,
            canQueue = true,
            title =
            {
                text = SI_DIALOG_TITLE_CHANGE_HOUSING_PERMISSION,
            },
            buttons =
            {
                {
                    keybind = "DIALOG_PRIMARY",
                    control = self:GetNamedChild("Confirm"),
                    text = SI_DIALOG_BUTTON_CHANGE_HOUSING_PERMISSION,
                    callback = function(dialog)
                        local editCheckBoxControl = dialog:GetNamedChild("AllHouses")
                        local isAllHousesChecked = ZO_CheckButton_IsChecked(editCheckBoxControl)
                        HOUSE_SETTINGS_MANAGER:SetApplyToAllHousesFlag(isAllHousesChecked)

                        local data = dialog.data
                        SetHousingPermissionPreset(data.currentHouse, data.userGroup, data.index, dialog.selectedPreset, isAllHousesChecked)
                    end
                },
                {
                    control = self:GetNamedChild("Cancel"),
                    text = SI_DIALOG_CANCEL,
                },
            },
        })

        SetupPresetComboBox(self)
    end

    local function SetupRemovePermissionsDialog(dialog)
        dialog:GetNamedChild("Title"):SetText(dialog.data.titleText)
        dialog:GetNamedChild("Header"):SetText(dialog.data.headerText)

        local editCheckBoxControl = dialog:GetNamedChild("AllHouses")
        ZO_CheckButton_SetCheckState(editCheckBoxControl, HOUSE_SETTINGS_MANAGER:GetApplyToAllHousesFlag())
    end

    function ZO_RemoveHousingPermissionsDialog_OnInitialized(self)
        ZO_Dialogs_RegisterCustomDialog("CONFIRM_REMOVE_PERMISSIONS",
        {
            customControl = self,
            setup = SetupRemovePermissionsDialog,
            buttons =
            {
                {
                    control = self:GetNamedChild("Confirm"),
                    text = SI_DIALOG_CONFIRM,
                    callback =  function(dialog)
                                    local data = dialog.data
                                    local editCheckBoxControl = dialog:GetNamedChild("AllHouses")
                                    local isAllHousesChecked = ZO_CheckButton_IsChecked(editCheckBoxControl)
                                    HOUSE_SETTINGS_MANAGER:SetApplyToAllHousesFlag(isAllHousesChecked)
                                    RemoveHousingPermission(data.currentHouse, data.userGroup, data.index, isAllHousesChecked)
                                end
                },
                {
                    control = self:GetNamedChild("Cancel"),
                    text = SI_DIALOG_CANCEL,
                },
            },
        })
    end

    local function SetupAddOrBanUserGroupDialog(dialog)
        local data = dialog.data
        local activePanel = data.activePanel
        local dialogTitle = activePanel:GetAddUserGroupDialogTitle()

        dialog:GetNamedChild("Title"):SetText(dialogTitle)
        GetControl(dialog, "NameEdit"):SetText("")

        local editCheckBoxControl = dialog:GetNamedChild("AllHouses")
        ZO_CheckButton_SetCheckState(editCheckBoxControl, HOUSE_SETTINGS_MANAGER:GetApplyToAllHousesFlag())

        if dialog.presetsComboBox then
            local defaultPreset = HOUSE_SETTINGS_MANAGER:GetDefaultPreset()
            local allPermissionPresets = HOUSE_SETTINGS_MANAGER:GetAllPermissionPresets()
            dialog.presetsComboBox:SetSelectedItemText(allPermissionPresets[defaultPreset])
            dialog.selectedPreset = defaultPreset
        end
    end

    function ZO_RequestAddUserGroupDialog_OnInitialized(self, dialogName)
        ZO_Dialogs_RegisterCustomDialog(dialogName,
        {
            customControl = self,
            setup = SetupAddOrBanUserGroupDialog,
            buttons =
            {
                {
                    control = self:GetNamedChild("Confirm"),
                    text = SI_DIALOG_CONFIRM,
                    callback =  function(dialog)
                                    local data = dialog.data
                                    local activePanel = data.activePanel
                                    local userGroup = activePanel:GetUserGroup()
                                    local editCheckBoxControl = dialog:GetNamedChild("AllHouses")
                                    local isAllHousesChecked = ZO_CheckButton_IsChecked(editCheckBoxControl)
                                    HOUSE_SETTINGS_MANAGER:SetApplyToAllHousesFlag(isAllHousesChecked)
                                    local name = GetControl(dialog, "NameEdit"):GetText()

                                    AddHousingPermission(data.currentHouse, userGroup, ALLOW_ACCESS, dialog.selectedPreset, isAllHousesChecked, name)
                                end
                },
                {
                    control = self:GetNamedChild("Cancel"),
                    text = SI_DIALOG_CANCEL,
                },
            },
        })

        SetupPresetComboBox(self)

        local addUserGroupFields = ZO_RequiredTextFields:New()
        addUserGroupFields:AddButton(GetControl(self, "Confirm"))
        addUserGroupFields:AddTextField(GetControl(self, "NameEdit"))
    end

    function ZO_RequestBanUserGroupDialog_OnInitialized(self, dialogName)
        ZO_Dialogs_RegisterCustomDialog(dialogName,
        {
            customControl = self,
            setup = SetupAddOrBanUserGroupDialog,
            buttons =
            {
                {
                    control = self:GetNamedChild("Confirm"),
                    text = SI_DIALOG_CONFIRM,
                    callback =  function(dialog)
                                    local data = dialog.data
                                    local activePanel = data.activePanel
                                    local userGroup = activePanel:GetUserGroup()
                                    local editCheckBoxControl = dialog:GetNamedChild("AllHouses")
                                    local isAllHousesChecked = ZO_CheckButton_IsChecked(editCheckBoxControl)
                                    HOUSE_SETTINGS_MANAGER:SetApplyToAllHousesFlag(isAllHousesChecked)
                                    local name = GetControl(dialog, "NameEdit"):GetText()

                                    AddHousingPermission(data.currentHouse, userGroup, not ALLOW_ACCESS, HOUSE_PERMISSION_PRESET_SETTING_INVALID, isAllHousesChecked, name)
                                end
                },
                {
                    control = self:GetNamedChild("Cancel"),
                    text = SI_DIALOG_CANCEL,
                },
            },
        })

        local banUserGroupFields = ZO_RequiredTextFields:New()
        banUserGroupFields:AddButton(GetControl(self, "Confirm"))
        banUserGroupFields:AddTextField(GetControl(self, "NameEdit"))
    end

    function ZO_CopyHousingPermissionsDialog_OnInitialized(self)
        self.confirmButton = self:GetNamedChild("Confirm")

        ZO_Dialogs_RegisterCustomDialog("COPY_HOUSING_PERMISSIONS",
        {
            customControl = self,
            setup = SetupCopyPermissionsDialog,
            canQueue = true,
            title =
            {
                text = SI_DIALOG_COPY_HOUSING_PERMISSION_TITLE,
            },
            buttons =
            {
                {
                    keybind = "DIALOG_PRIMARY",
                    control = self.confirmButton,
                    text = SI_DIALOG_CONFIRM,
                    callback = function(dialog)
                        local data = dialog.data
                        CopyHousePermissions(dialog.selectedHouseId, data.currentHouse)
                    end
                },
                {
                    control = self:GetNamedChild("Cancel"),
                    text = SI_DIALOG_CANCEL,
                },
            },
        })
        SetupHousesComboBox(self)
    end
end
