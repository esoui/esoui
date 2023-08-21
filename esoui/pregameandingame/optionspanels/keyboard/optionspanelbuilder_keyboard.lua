-- Helper object for dynamically creating keyboard panels. This object does not store the panel itself, and can safely be garbage collected after a panel is created.
ZO_KeyboardOptionsPanelBuilder = ZO_Object:Subclass()

function ZO_KeyboardOptionsPanelBuilder:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_KeyboardOptionsPanelBuilder:Initialize(panel)
    self.panel = panel
    self.lastIndentLevel = 0
    self.lastHeader = nil
    self.lastControl = nil
    self.headerControlIndex = 1
end

do
    -- TODO: Bake these offsets into the control templates themselves
    local Y_OFFSET_FOR_CONTROL_TEMPLATE = 
    {
        ["ZO_Options_Dropdown"] = 10,
        ["ZO_Options_Video_Dropdown_IncludeApplyScreenWarning"] = 10,
        ["ZO_Options_Dropdown_DynamicWarning"] = 10,
        ["ZO_Options_Slider"] = 4,
        ["ZO_Options_Video_Slider_IncludeMaxParticleSystemsWarning"] = 4,
        ["ZO_Options_Slider_VerticalLabel"] = 4,
        ["ZO_Options_Checkbox"] = 6,
        ["ZO_Options_Video_Checkbox_IncludeRestartWarning"] = 6,
        ["ZO_Options_Checkbox_DynamicWarning"] = 6,
        ["ZO_Options_InvokeCallback"] = 4,
        ["ZO_Options_InvokeCallback_Wide"] = 4,
        ["ZO_Options_Account_InvokeCallback_WithEmail"] = 4,
        ["ZO_Options_Color"] = 4,
        ["ZO_Options_Social_ChatColor"] = 8,
        ["ZO_Options_Social_GuildLabel"] = 30,
        ["ZO_Options_Video_Checkbox_IncludeApplyScreenWarning"] = 6,
    }
    local INDENT_X_OFFSET = 20
    local HEADER_Y_OFFSET = 15
    function ZO_KeyboardOptionsPanelBuilder:AddSetting(settingTemplate)
        -- add headers if necessary
        local settingData = KEYBOARD_OPTIONS:GetSettingsData(self.panel, settingTemplate.settingType, settingTemplate.settingId)

        if KEYBOARD_OPTIONS:DoesSettingExist(settingData) then
            if settingTemplate.header ~= self.lastHeader then
                local headerControl
                local controlName = string.format("OptionsPanel%dHeader%d", self.panel, self.headerControlIndex)
                if self.lastControl == nil then
                    headerControl = CreateControlFromVirtual(controlName, ZO_OptionsWindowSettingsScrollChild, "ZO_Options_SectionTitle_PanelHeader")
                else
                    headerControl = CreateControlFromVirtual(controlName, ZO_OptionsWindowSettingsScrollChild, "ZO_Options_SectionTitle_WithDivider")
                    headerControl:SetAnchor(TOPLEFT, self.lastControl, BOTTOMLEFT, (self.lastIndentLevel * -INDENT_X_OFFSET), HEADER_Y_OFFSET)
                    self.lastIndentLevel = 0
                end
                internalassert(settingTemplate.header, "All settings need a header")
                KEYBOARD_OPTIONS:SetSectionTitleData(headerControl, settingData.panel, settingTemplate.header)
                ZO_OptionsWindow_InitializeControl(headerControl)

                self.lastControl = headerControl
                self.headerControlIndex = self.headerControlIndex + 1
            end

            local template = settingTemplate.template
            if not template then
                -- Use default template for control type
                local controlType = KEYBOARD_OPTIONS:GetControlType(settingData.controlType)
                if controlType == OPTIONS_DROPDOWN then
                    template = "ZO_Options_Dropdown"
                elseif controlType == OPTIONS_CHECKBOX then
                    template = "ZO_Options_Checkbox"
                elseif controlType == OPTIONS_SLIDER then
                    template = "ZO_Options_Slider"
                elseif controlType == OPTIONS_INVOKE_CALLBACK then
                    template = "ZO_Options_InvokeCallback"
                elseif controlType == OPTIONS_COLOR then
                    template = "ZO_Options_Color"
                elseif controlType == OPTIONS_CHAT_COLOR then
                    template = "ZO_Options_Social_ChatColor"
                else
                    internalassert(false, string.format("No control template for control type: %s", tostring(controlType)))
                end
            end

            local settingControl = CreateControlFromVirtual(settingTemplate.controlName, ZO_OptionsWindowSettingsScrollChild, template)
            local yOffset = internalassert(Y_OFFSET_FOR_CONTROL_TEMPLATE[template], "Missing Y offset for control") or 0
            local indentLevel = settingTemplate.indentLevel or 0
            local indentDifference = indentLevel - self.lastIndentLevel

            settingControl:SetAnchor(TOPLEFT, self.lastControl, BOTTOMLEFT, indentDifference * INDENT_X_OFFSET, yOffset)
            settingControl:SetWidth(settingControl:GetWidth() - (indentLevel * INDENT_X_OFFSET))

            settingControl.data = settingData

            local initializeControlFunction = settingTemplate.initializeControlFunction or ZO_OptionsWindow_InitializeControl
            initializeControlFunction(settingControl)

            self.lastControl = settingControl
            self.lastHeader = settingTemplate.header
            self.lastIndentLevel = indentLevel
        end
    end
end
