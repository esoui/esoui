local GenericFooter = ZO_Object:Subclass()

ZO_GAMEPAD_FOOTER_CONTROLS =
{
    DATA1               = 1,
    DATA1HEADER         = 2,
    DATA1LOADINGICON    = 3,
    DATA2               = 4,
    DATA2HEADER         = 5,
    DATA2LOADINGICON    = 6,
    DATA3               = 7,
    DATA3HEADER         = 8,
    DATA3LOADINGICON    = 9,
}

local EMPTY_TABLE       = {}

-- Alias the control names to make the code less verbose and more readable.
local DATA1             = ZO_GAMEPAD_FOOTER_CONTROLS.DATA1
local DATA1HEADER       = ZO_GAMEPAD_FOOTER_CONTROLS.DATA1HEADER
local DATA1LOADINGICON  = ZO_GAMEPAD_FOOTER_CONTROLS.DATA1LOADINGICON
local DATA2             = ZO_GAMEPAD_FOOTER_CONTROLS.DATA2
local DATA2HEADER       = ZO_GAMEPAD_FOOTER_CONTROLS.DATA2HEADER
local DATA2LOADINGICON  = ZO_GAMEPAD_FOOTER_CONTROLS.DATA2LOADINGICON
local DATA3             = ZO_GAMEPAD_FOOTER_CONTROLS.DATA3
local DATA3HEADER       = ZO_GAMEPAD_FOOTER_CONTROLS.DATA3HEADER
local DATA3LOADINGICON  = ZO_GAMEPAD_FOOTER_CONTROLS.DATA3LOADINGICON

function GenericFooter:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function GenericFooter:Initialize(control)
    self.control = control

    self.controls =
    {
        [DATA1]             = control:GetNamedChild("Data1"),
        [DATA1HEADER]       = control:GetNamedChild("Data1Header"),
        [DATA1LOADINGICON]  = control:GetNamedChild("Data1LoadingIcon"),
        [DATA2]             = control:GetNamedChild("Data2"),
        [DATA2HEADER]       = control:GetNamedChild("Data2Header"),
        [DATA2LOADINGICON]  = control:GetNamedChild("Data2LoadingIcon"),
        [DATA3]             = control:GetNamedChild("Data3"),
        [DATA3HEADER]       = control:GetNamedChild("Data3Header"),
        [DATA3LOADINGICON]  = control:GetNamedChild("Data3LoadingIcon"),
    }

    control.OnHidden = function()
        self:Refresh(EMPTY_TABLE)
    end
end

local function ProcessData(control, textData, anchorToBaselineControl, anchorToBaselineOffsetX, overrideColor)
    if control == nil then
        return false
    end

    if type(textData) == "function" then
        textData = textData(control)
    end

    if type(textData) == "string" or type(textData) == "number" then
        if overrideColor then
            textData = overrideColor:Colorize(textData)
        end
        control:SetText(textData)
    end

    control:SetHidden(not textData)

    if anchorToBaselineControl then
        control:ClearAnchorToBaseline(anchorToBaselineControl)
        if textData then
            control:AnchorToBaseline(anchorToBaselineControl, anchorToBaselineOffsetX, LEFT)
        else
            -- This is to make sure there is no gap when a control is missing.
            control:AnchorToBaseline(anchorToBaselineControl, 0, LEFT)
        end
    end

    control:SetHidden(not textData)
    return textData ~= nil
end

local function GetProcessedNarrationText(control, data)
    if control == nil or data == nil then
        return ""
    end

    if type(data) == "function" then
        data = data(control)
    end

    if type(data) == "string" then
        return data
    elseif type(data) == "number" then
        return tostring(data)
    else
        internalassert(false, "Unsupported data type. A custom narration function will need to be set for this control that returns a string or number.")
    end

    return ""
end

function GenericFooter:Refresh(data)
    local controls = self.controls

    local loadingIcon1Offset = data.data1ShowLoading and ZO_GAMEPAD_LOADING_ICON_FOOTER_SIZE or 0
    controls[DATA1LOADINGICON]:SetHidden(not data.data1ShowLoading)
    local loadingIcon2Offset = data.data2ShowLoading and ZO_GAMEPAD_LOADING_ICON_FOOTER_SIZE or 0
    controls[DATA2LOADINGICON]:SetHidden(not data.data2ShowLoading)
    local loadingIcon3Offset = data.data3ShowLoading and ZO_GAMEPAD_LOADING_ICON_FOOTER_SIZE or 0
    controls[DATA3LOADINGICON]:SetHidden(not data.data3ShowLoading)

    ProcessData(controls[DATA1], data.data1Text, nil, nil, data.data1Color)
    ProcessData(controls[DATA1HEADER], data.data1HeaderText, controls[DATA1], -ZO_GAMEPAD_DEFAULT_HEADER_DATA_PADDING - loadingIcon1Offset, data.data1HeaderColor)
    ProcessData(controls[DATA2], data.data2Text, controls[DATA1HEADER], -ZO_GAMEPAD_CONTENT_INSET_X, data.data2Color)
    ProcessData(controls[DATA2HEADER], data.data2HeaderText, controls[DATA2], -ZO_GAMEPAD_DEFAULT_HEADER_DATA_PADDING - loadingIcon2Offset, data.data2HeaderColor)
    ProcessData(controls[DATA3], data.data3Text, controls[DATA2HEADER], -ZO_GAMEPAD_CONTENT_INSET_X, data.data3Color)
    ProcessData(controls[DATA3HEADER], data.data3HeaderText, controls[DATA3], -ZO_GAMEPAD_DEFAULT_HEADER_DATA_PADDING - loadingIcon3Offset, data.data3HeaderColor)
end

function GenericFooter:GetChildControl(index)
    if self.controls then
        return self.controls[index]
    end

    return nil
end

function GenericFooter:GetNarrationText(data)
    local narration = SCREEN_NARRATION_MANAGER:CreateNarratableObject()
    local controls = self.controls

    -- We narrate these in reverse numerical order because they're laid out from right to left
    narration:AddNarrationText(GetProcessedNarrationText(controls[DATA3HEADER], data.data3HeaderTextNarration or data.data3HeaderText))
    narration:AddNarrationText(GetProcessedNarrationText(controls[DATA3], data.data3TextNarration or data.data3Text))
    narration:AddNarrationText(GetProcessedNarrationText(controls[DATA2HEADER], data.data2HeaderTextNarration or data.data2HeaderText))
    narration:AddNarrationText(GetProcessedNarrationText(controls[DATA2], data.data2TextNarration or data.data2Text))
    narration:AddNarrationText(GetProcessedNarrationText(controls[DATA1HEADER], data.data1HeaderTextNarration or data.data1HeaderText))
    narration:AddNarrationText(GetProcessedNarrationText(controls[DATA1], data.data1TextNarration or data.data1Text))

    return narration
end

function ZO_GenericFooter_Gamepad_OnInitialized(self)
    GAMEPAD_GENERIC_FOOTER = GenericFooter:New(self)
end

function ZO_GenericFooter_Gamepad_OnHidden(self)
    self.OnHidden()
end