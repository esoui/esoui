local GenericFooter = ZO_Object:Subclass()

ZO_GAMEPAD_FOOTER_CONTROLS =
{
    DATA1           = 1,
    DATA1HEADER     = 2,
    DATA2           = 3,
    DATA2HEADER     = 4,
    DATA3           = 5,
    DATA3HEADER     = 6,
    LOADINGICON     = 7,
}

local EMPTY_TABLE       = {}

-- Alias the control names to make the code less verbose and more readable.
local DATA1             = ZO_GAMEPAD_FOOTER_CONTROLS.DATA1
local DATA1HEADER       = ZO_GAMEPAD_FOOTER_CONTROLS.DATA1HEADER
local DATA2             = ZO_GAMEPAD_FOOTER_CONTROLS.DATA2
local DATA2HEADER       = ZO_GAMEPAD_FOOTER_CONTROLS.DATA2HEADER
local DATA3             = ZO_GAMEPAD_FOOTER_CONTROLS.DATA3
local DATA3HEADER       = ZO_GAMEPAD_FOOTER_CONTROLS.DATA3HEADER
local LOADINGICON       = ZO_GAMEPAD_FOOTER_CONTROLS.LOADINGICON

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
        [DATA2]             = control:GetNamedChild("Data2"),
        [DATA2HEADER]       = control:GetNamedChild("Data2Header"),
        [DATA3]             = control:GetNamedChild("Data3"),
        [DATA3HEADER]       = control:GetNamedChild("Data3Header"),
        [LOADINGICON]       = control:GetNamedChild("LoadingIcon"),
    }

    control.OnHidden = function()
        self:Refresh(EMPTY_TABLE)
    end
end

local function ProcessData(control, data, anchorToBaselineControl, anchorToBaselineOffsetX)
    if(control == nil) then
        return false
    end

    if type(data) == "function" then
        data = data(control)
    end

    if type(data) == "string" or type(data) == "number" then
        control:SetText(data)
    else
        control:SetText("")
    end

    if anchorToBaselineControl then
        control:ClearAnchorToBaseline(anchorToBaselineControl)
        if data then
            control:AnchorToBaseline(anchorToBaselineControl, anchorToBaselineOffsetX, LEFT)
        else
            -- This is to make sure there is no gap when a control is missing.
            control:AnchorToBaseline(anchorToBaselineControl, 0, LEFT)
        end
    end

    control:SetHidden(not data)
    return data ~= nil
end

function GenericFooter:Refresh(data)
    local controls = self.controls

    ProcessData(controls[DATA1], data.data1Text)
    ProcessData(controls[DATA1HEADER], data.data1HeaderText, controls[DATA1], -ZO_GAMEPAD_DEFAULT_HEADER_DATA_PADDING)
    ProcessData(controls[DATA2], data.data2Text, controls[DATA1HEADER], -ZO_GAMEPAD_CONTENT_INSET_X)
    ProcessData(controls[DATA2HEADER], data.data2HeaderText, controls[DATA2], -ZO_GAMEPAD_DEFAULT_HEADER_DATA_PADDING)
    ProcessData(controls[DATA3], data.data3Text, controls[DATA2HEADER], -ZO_GAMEPAD_CONTENT_INSET_X)
    ProcessData(controls[DATA3HEADER], data.data3HeaderText, controls[DATA3], -ZO_GAMEPAD_DEFAULT_HEADER_DATA_PADDING)

    controls[DATA3HEADER]:ClearAnchors()
    local target = data.showLoading and controls[LOADINGICON] or controls[DATA3]
    controls[DATA3HEADER]:SetAnchor(BOTTOMRIGHT, target, BOTTOMLEFT, -ZO_GAMEPAD_DEFAULT_HEADER_DATA_PADDING, -1)
    controls[LOADINGICON]:SetHidden(not data.showLoading)
end

function ZO_GenericFooter_Gamepad_OnInitialized(self)
    GAMEPAD_GENERIC_FOOTER = GenericFooter:New(self)
end

function ZO_GenericFooter_Gamepad_OnHidden(self)
    self.OnHidden()
end