--[[Basic screen]]--
ZO_HelpTutorialsGamepad = ZO_Gamepad_ParametricList_Screen:Subclass()

function ZO_HelpTutorialsGamepad:New(...)
    return ZO_Gamepad_ParametricList_Screen.New(self, ...)
end

function ZO_HelpTutorialsGamepad:Initialize(control, activateOnShow)
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE, activateOnShow)
    self.itemList = ZO_Gamepad_ParametricList_Screen.GetMainList(self)

    self.headerData = {
	        titleText = GetString(SI_HELP_TUTORIALS),
        }
    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)

    self:InitializeEvents()
end

function ZO_HelpTutorialsGamepad:InitializeEvents()
    local function UpdateHelp()
        self:Update()
    end

    self.control:RegisterForEvent(EVENT_HELP_INITIALIZED, UpdateHelp)
end

function ZO_HelpTutorialsGamepad:SetupSearchHeaderData(searchString, headerData)
    if searchString and searchString ~= "" then
        headerData.data1HeaderText = GetString(SI_GAMEPAD_HELP_SEARCH)
        headerData.data1Text = searchString
    else
        headerData.data1HeaderText = nil
        headerData.data1Text = nil
    end
end

