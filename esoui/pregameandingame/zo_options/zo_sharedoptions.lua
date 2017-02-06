-- this table stores everything needed to setup every setting control
-- each OptionsPanel_Whatever.lua file creates a table and adds itself to this one.
ZO_SharedOptions_SettingsData  = {} 
SETTING_TYPE_CUSTOM = 5000 --this must be bigger than EsoGameDataEnums::cSettingSystemTypeSize, currently 16

ZO_SharedOptions = ZO_Object:Subclass()

function ZO_SharedOptions:New(control)
    local sharedOptions = ZO_Object.New(self)
    sharedOptions:Initialize(control)
    return sharedOptions
end

function ZO_SharedOptions:Initialize(control)  
    self.controlTable = {}
    self.panelNames = {}
    self.isGamepadOptions = false
end

function ZO_SharedOptions:IsGamepadOptions()
    return self.isGamepadOptions
end

function ZO_SharedOptions:SaveCachedSettings()
    -- We only care about saving cached setting messages ingame
    if SendAllCachedSettingMessages then
        SendAllCachedSettingMessages()
    end
end

function ZO_SharedOptions:GetControlTypeFromControl(control)
    local data = control.data
    if data.controlType == OPTIONS_FINITE_LIST then
        if self:IsGamepadOptions() then
            return OPTIONS_HORIZONTAL_SCROLL_LIST
        else
            return OPTIONS_DROPDOWN
        end
    end

    return data.controlType
end

function ZO_SharedOptions:GetControlType(controlType)
    if controlType == OPTIONS_FINITE_LIST then
        if self:IsGamepadOptions() then
            return OPTIONS_HORIZONTAL_SCROLL_LIST
        else
            return OPTIONS_DROPDOWN
        end
    end

    return controlType
end

function ZO_SharedOptions:InitializeControl(control, selected, isKeyboardControl)
    local data = control.data
    local text = nil

    if type(data.text) == "string" then
        text = data.text
    else
        text = GetString(data.text)
    end

    local controlType = self:GetControlTypeFromControl(control)
    control.optionsManager = self

    if controlType == OPTIONS_SECTION_TITLE then
        GetControl(control, "Label"):SetText(text)
    elseif controlType == OPTIONS_DROPDOWN then
        GetControl(control, "Name"):SetText(text)
        ZO_Options_SetupDropdown(control)
    elseif controlType == OPTIONS_HORIZONTAL_SCROLL_LIST then
        GetControl(control, "Name"):SetText(text)
        ZO_Options_SetupScrollList(control, selected)
    elseif controlType == OPTIONS_CHECKBOX then
        GetControl(control, "Name"):SetText(text)
        ZO_Options_SetupCheckBox(control)
    elseif controlType == OPTIONS_SLIDER then
        GetControl(control, "Name"):SetText(text)
        ZO_Options_SetupSlider(control, selected)
    elseif controlType == OPTIONS_INVOKE_CALLBACK  then
        GetControl(control, "Name"):SetText(text)
    elseif controlType == OPTIONS_CUSTOM then
        if data.customSetupFunction then
            data.customSetupFunction(control, selected)
        end
    end

    if data.onInitializeFunction then
        data.onInitializeFunction(control, isKeyboardControl)
    end
end

function ZO_SharedOptions:IsControlTypeAnOption(data)
	local controlType = self:GetControlType(data.controlType)
    return controlType == OPTIONS_DROPDOWN
			or controlType == OPTIONS_CHECKBOX
			or controlType == OPTIONS_SLIDER
			or controlType == OPTIONS_HORIZONTAL_SCROLL_LIST
end

function ZO_SharedOptions:LoadDefaults(control, data) 
    if self:IsControlTypeAnOption(data) then
        if(not data.excludeFromResetToDefault) then
            ResetSettingToDefault(data.system, data.settingId)
        end
    elseif data.customResetToDefaultsFunction then
        data.customResetToDefaultsFunction(control)
    end
end

function ZO_SharedOptions:GetSettingsData(panel, system, settingId)
    return ZO_SharedOptions_SettingsData[panel][system][settingId]
end

function ZO_SharedOptions:AddTableToPanel(panel, table)
    for key, entry in pairs(table) do
        if(ZO_SharedOptions_SettingsData[panel] == nil) then
            ZO_SharedOptions_SettingsData[panel] = {}
        end
        ZO_SharedOptions_SettingsData[panel][key] = entry
    end
end

function ZO_SharedOptions:AddTableToSystem(panel, system, table)
    for key, entry in pairs(table) do
        if(ZO_SharedOptions_SettingsData[panel] == nil) then
            ZO_SharedOptions_SettingsData[panel] = {}
        end
        if(ZO_SharedOptions_SettingsData[panel][system] == nil) then
            ZO_SharedOptions_SettingsData[panel][system] = {}
        end
        ZO_SharedOptions_SettingsData[panel][system][key] = entry
    end
end