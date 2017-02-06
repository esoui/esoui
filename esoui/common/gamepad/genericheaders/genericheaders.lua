ZO_GAMEPAD_HEADER_TABBAR_CREATE = true
ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE = false

ZO_GAMEPAD_HEADER_LAYOUTS =
{
--[[
    The key/value pairs are arranged beneath the title row as follows:

    Screen Header (left pane):
        data1Header             data1
        data2Header             data2
        data3Header             data3
        data4Header             data4

    Content Header (right pane):
        data1Header             data1   data3Header             data3
        data2Header             data2   data4Header             data4
--]]
    DATA_PAIRS_SEPARATE = 1,

--[[
    The key/value pairs are arranged beneath the title row as follows:

    Screen Header (left pane):
        data1Header data1       data2Header data2
        data3Header data3       data4Header data4

    Content Header (right pane):
        data1Header data1       data2Header data2   data3Header data3       data4Header data4
--]]
    DATA_PAIRS_TOGETHER = 2,

--[[
    The key/value pairs are arranged beneath the title row as follows:

    Screen Header (left pane):
        Not defined.  Don't use this - it's a special case for the content header.

    Content Header (right pane):
        data1Header data1 data2Header data2 data3Header data3 data4Header data4

        If a data section is not provided, it will be disregarded when it comes to anchoring (data1 will anchor to data3 if there's no data2, etc.)
--]]
    CONTENT_HEADER_DATA_PAIRS_LINKED = 3,
}

ZO_GAMEPAD_HEADER_CONTROLS =
{
    TABBAR          = 1,
    TITLE           = 2,
    CENTER_BASELINE = 3,
    TITLE_BASELINE  = 4,
    DIVIDER_SIMPLE  = 5,
    DIVIDER_PIPPED  = 6,
    DATA1           = 7,
    DATA1HEADER     = 8,
    DATA2           = 9,
    DATA2HEADER     = 10,
    DATA3           = 11,
    DATA3HEADER     = 12,
    DATA4           = 13,
    DATA4HEADER     = 14,
    MESSAGE         = 15,
}

-- Alias the control names to make the code less verbose and more readable.
local TABBAR            = ZO_GAMEPAD_HEADER_CONTROLS.TABBAR
local TITLE             = ZO_GAMEPAD_HEADER_CONTROLS.TITLE
local CENTER_BASELINE   = ZO_GAMEPAD_HEADER_CONTROLS.CENTER_BASELINE
local TITLE_BASELINE    = ZO_GAMEPAD_HEADER_CONTROLS.TITLE_BASELINE
local DIVIDER_SIMPLE    = ZO_GAMEPAD_HEADER_CONTROLS.DIVIDER_SIMPLE
local DIVIDER_PIPPED    = ZO_GAMEPAD_HEADER_CONTROLS.DIVIDER_PIPPED
local DATA1             = ZO_GAMEPAD_HEADER_CONTROLS.DATA1
local DATA1HEADER       = ZO_GAMEPAD_HEADER_CONTROLS.DATA1HEADER
local DATA2             = ZO_GAMEPAD_HEADER_CONTROLS.DATA2
local DATA2HEADER       = ZO_GAMEPAD_HEADER_CONTROLS.DATA2HEADER
local DATA3             = ZO_GAMEPAD_HEADER_CONTROLS.DATA3
local DATA3HEADER       = ZO_GAMEPAD_HEADER_CONTROLS.DATA3HEADER
local DATA4             = ZO_GAMEPAD_HEADER_CONTROLS.DATA4
local DATA4HEADER       = ZO_GAMEPAD_HEADER_CONTROLS.DATA4HEADER
local MESSAGE           = ZO_GAMEPAD_HEADER_CONTROLS.MESSAGE

local DEFAULT_LAYOUT        = ZO_GAMEPAD_HEADER_LAYOUTS.DATA_PAIRS_SEPARATE
local FIRST_DATA_CONTROL    = DATA1
local LAST_DATA_CONTROL     = MESSAGE

-- Because these consts are created before the xml is loaded, we don't have an effecient way to track the anticipated height of the info labels
-- We need to track the disparity to line up the bottoms, so we just grabbed these numbers ahead of time
-- TODO: Revisit this and come up with a better way to anchor dynamically
local GENERIC_HEADER_INFO_LABEL_HEIGHT = 33
local GENERIC_HEADER_INFO_DATA_HEIGHT = 50
local GENERIC_HEADER_INFO_FONT_HEIGHT_DISPARITY = 4 -- This is used to align the baselines of the headers and their texts; will need to update if fonts change
local ROW_OFFSET_Y = GENERIC_HEADER_INFO_LABEL_HEIGHT + 10
local DATA_OFFSET_X = 5
local HEADER_OFFSET_X = 29

ZO_GAMEPAD_CONTENT_HEADER_DIVIDER_INFO_BOTTOM_PADDING_Y = ZO_GAMEPAD_CONTENT_DIVIDER_INFO_PADDING_Y + GENERIC_HEADER_INFO_LABEL_HEIGHT

-- The Anchor class simply wraps a ZO_Anchor object with a target id, which we can later resolve into an actual control.
-- This allows us to specify all anchor data at file scope and resolve the target controls only when needed.
local Anchor = ZO_Object:Subclass()

function Anchor:New(pointOnMe, targetId, pointOnTarget, offsetX, offsetY)
    local object = ZO_Object.New(self)
    object.targetId = targetId
    object.anchor = ZO_Anchor:New(pointOnMe, nil, pointOnTarget, offsetX, offsetY)
    return object
end

local SCREEN_HEADER_ANCHORS =
{
    [ZO_GAMEPAD_HEADER_LAYOUTS.DATA_PAIRS_SEPARATE] =
    {
        [DATA1HEADER]   = {Anchor:New(BOTTOMLEFT, DIVIDER_SIMPLE, BOTTOMLEFT, 0, ZO_GAMEPAD_CONTENT_HEADER_DIVIDER_INFO_BOTTOM_PADDING_Y),     Anchor:New(BOTTOMRIGHT, DIVIDER_SIMPLE, BOTTOMRIGHT, 0, ZO_GAMEPAD_CONTENT_HEADER_DIVIDER_INFO_BOTTOM_PADDING_Y)},
        [DATA1]         = {Anchor:New(BOTTOMRIGHT, DATA1HEADER, BOTTOMRIGHT, 0, GENERIC_HEADER_INFO_FONT_HEIGHT_DISPARITY)},

        [DATA2HEADER]   = {Anchor:New(BOTTOMLEFT, DATA1HEADER, BOTTOMLEFT, 0, ROW_OFFSET_Y),    Anchor:New(BOTTOMRIGHT, DATA1HEADER, BOTTOMRIGHT, 0, ROW_OFFSET_Y)},
        [DATA2]         = {Anchor:New(BOTTOMRIGHT, DATA2HEADER, BOTTOMRIGHT, 0, GENERIC_HEADER_INFO_FONT_HEIGHT_DISPARITY)},

        [DATA3HEADER]   = {Anchor:New(BOTTOMLEFT, DATA2HEADER, BOTTOMLEFT, 0, ROW_OFFSET_Y),    Anchor:New(BOTTOMRIGHT, DATA2HEADER, BOTTOMRIGHT, 0, ROW_OFFSET_Y)},
        [DATA3]         = {Anchor:New(BOTTOMRIGHT, DATA3HEADER, BOTTOMRIGHT, 0, GENERIC_HEADER_INFO_FONT_HEIGHT_DISPARITY)},

        [DATA4HEADER]   = {Anchor:New(BOTTOMLEFT, DATA3HEADER, BOTTOMLEFT, 0, ROW_OFFSET_Y),    Anchor:New(BOTTOMRIGHT, DATA3HEADER, BOTTOMRIGHT, 0, ROW_OFFSET_Y)},
        [DATA4]         = {Anchor:New(BOTTOMRIGHT, DATA4HEADER, BOTTOMRIGHT, 0, GENERIC_HEADER_INFO_FONT_HEIGHT_DISPARITY)},

        [MESSAGE]       = {Anchor:New(TOPLEFT, DIVIDER_SIMPLE, BOTTOMLEFT, 0, ZO_GAMEPAD_CONTENT_DIVIDER_INFO_PADDING_Y),    Anchor:New(TOPRIGHT, DIVIDER_SIMPLE, BOTTOMRIGHT, 0, ZO_GAMEPAD_CONTENT_HEADER_DIVIDER_INFO_BOTTOM_PADDING_Y)},
    },

    [ZO_GAMEPAD_HEADER_LAYOUTS.DATA_PAIRS_TOGETHER] =
    {
        [DATA1HEADER]   = {Anchor:New(BOTTOMLEFT, DIVIDER_SIMPLE, BOTTOMLEFT, 0, ZO_GAMEPAD_CONTENT_HEADER_DIVIDER_INFO_BOTTOM_PADDING_Y)},
        [DATA1]         = {Anchor:New(BOTTOMLEFT, DATA1HEADER, BOTTOMRIGHT, DATA_OFFSET_X, GENERIC_HEADER_INFO_FONT_HEIGHT_DISPARITY)},

        [DATA2]         = {Anchor:New(BOTTOMRIGHT, DIVIDER_SIMPLE, BOTTOMRIGHT, 0, ZO_GAMEPAD_CONTENT_HEADER_DIVIDER_INFO_BOTTOM_PADDING_Y + GENERIC_HEADER_INFO_FONT_HEIGHT_DISPARITY)},
        [DATA2HEADER]   = {Anchor:New(BOTTOMRIGHT, DATA2, BOTTOMLEFT, -DATA_OFFSET_X, -GENERIC_HEADER_INFO_FONT_HEIGHT_DISPARITY)},

        [DATA3HEADER]   = {Anchor:New(BOTTOMLEFT, DATA1HEADER, BOTTOMLEFT, 0, ROW_OFFSET_Y)},
        [DATA3]         = {Anchor:New(BOTTOMLEFT, DATA3HEADER, BOTTOMRIGHT, DATA_OFFSET_X, GENERIC_HEADER_INFO_FONT_HEIGHT_DISPARITY)},

        [DATA4]         = {Anchor:New(BOTTOMRIGHT, DATA2, BOTTOMRIGHT, 0, ROW_OFFSET_Y + GENERIC_HEADER_INFO_FONT_HEIGHT_DISPARITY)},
        [DATA4HEADER]   = {Anchor:New(BOTTOMRIGHT, DATA4, BOTTOMLEFT, -DATA_OFFSET_X, -GENERIC_HEADER_INFO_FONT_HEIGHT_DISPARITY)},

        [MESSAGE]       = {Anchor:New(TOPLEFT, DIVIDER_SIMPLE, BOTTOMLEFT, 0, ZO_GAMEPAD_CONTENT_DIVIDER_INFO_PADDING_Y),    Anchor:New(TOPRIGHT, DIVIDER_SIMPLE, BOTTOMRIGHT, 0, ZO_GAMEPAD_CONTENT_DIVIDER_INFO_PADDING_Y)},
    },
}

-- The overlap anchors are used instead of the normal anchors in cases where the data label's text overlaps its corresponding header label.
local DATA_OVERLAP_ROW_OFFSET_Y = 40
local HEADER_OVERLAP_ROW_OFFSET_Y = 31

local SCREEN_HEADER_OVERLAP_ANCHORS = 
{
    -- Anchors header content as
    -- DATA[N]HEADER
    -- DATA[N]
    -- DATA[N+1]HEADER...
    -- if DATA[N]HEADER and DATA[N] overlap each other
    
    [ZO_GAMEPAD_HEADER_LAYOUTS.DATA_PAIRS_SEPARATE] =
    {
        [DATA1]         = {Anchor:New(BOTTOMLEFT, DATA1HEADER, BOTTOMLEFT, 0, DATA_OVERLAP_ROW_OFFSET_Y), Anchor:New(BOTTOMRIGHT, DATA1HEADER, BOTTOMRIGHT, 0, DATA_OVERLAP_ROW_OFFSET_Y)},

        [DATA2HEADER]   = {Anchor:New(BOTTOMLEFT, DATA1, BOTTOMLEFT, 0, HEADER_OVERLAP_ROW_OFFSET_Y),    Anchor:New(BOTTOMRIGHT, DATA1, BOTTOMRIGHT, 0, HEADER_OVERLAP_ROW_OFFSET_Y)},
        [DATA2]         = {Anchor:New(BOTTOMLEFT, DATA2HEADER, BOTTOMLEFT, 0, DATA_OVERLAP_ROW_OFFSET_Y), Anchor:New(BOTTOMRIGHT, DATA2HEADER, BOTTOMRIGHT, 0, DATA_OVERLAP_ROW_OFFSET_Y)},

        [DATA3HEADER]   = {Anchor:New(BOTTOMLEFT, DATA2, BOTTOMLEFT, 0, HEADER_OVERLAP_ROW_OFFSET_Y),    Anchor:New(BOTTOMRIGHT, DATA2, BOTTOMRIGHT, 0, HEADER_OVERLAP_ROW_OFFSET_Y)},
        [DATA3]         = {Anchor:New(BOTTOMLEFT, DATA3HEADER, BOTTOMLEFT, 0, DATA_OVERLAP_ROW_OFFSET_Y), Anchor:New(BOTTOMRIGHT, DATA3HEADER, BOTTOMRIGHT, 0, DATA_OVERLAP_ROW_OFFSET_Y)},

        [DATA4HEADER]   = {Anchor:New(BOTTOMLEFT, DATA3, BOTTOMLEFT, 0, HEADER_OVERLAP_ROW_OFFSET_Y),    Anchor:New(BOTTOMRIGHT, DATA3, BOTTOMRIGHT, 0, HEADER_OVERLAP_ROW_OFFSET_Y)},
        [DATA4]         = {Anchor:New(BOTTOMLEFT, DATA4HEADER, BOTTOMLEFT, 0, DATA_OVERLAP_ROW_OFFSET_Y), Anchor:New(BOTTOMRIGHT, DATA4HEADER, BOTTOMRIGHT, 0, DATA_OVERLAP_ROW_OFFSET_Y)},
    },
}

local CONTENT_HEADER_ANCHORS =
{
    [ZO_GAMEPAD_HEADER_LAYOUTS.DATA_PAIRS_SEPARATE] =
    {
        [DATA1HEADER]   = {Anchor:New(BOTTOMLEFT, DIVIDER_SIMPLE, BOTTOMLEFT, 0, ZO_GAMEPAD_CONTENT_HEADER_DIVIDER_INFO_BOTTOM_PADDING_Y),   Anchor:New(BOTTOMRIGHT, CENTER_BASELINE, BOTTOMLEFT)},
        [DATA1]         = {Anchor:New(BOTTOMRIGHT, DATA1HEADER, BOTTOMRIGHT, 0, GENERIC_HEADER_INFO_FONT_HEIGHT_DISPARITY)},

        [DATA2HEADER]   = {Anchor:New(BOTTOMLEFT, DATA1HEADER, BOTTOMLEFT, 0, ROW_OFFSET_Y),       Anchor:New(BOTTOMRIGHT, DATA1HEADER, BOTTOMRIGHT, 0, ROW_OFFSET_Y)},
        [DATA2]         = {Anchor:New(BOTTOMRIGHT, DATA2HEADER, BOTTOMRIGHT, 0, GENERIC_HEADER_INFO_FONT_HEIGHT_DISPARITY)},

        [DATA3HEADER]   = {Anchor:New(BOTTOMLEFT, CENTER_BASELINE, BOTTOMRIGHT),                Anchor:New(BOTTOMRIGHT, DIVIDER_SIMPLE, BOTTOMRIGHT, 0, ZO_GAMEPAD_CONTENT_HEADER_DIVIDER_INFO_BOTTOM_PADDING_Y)},
        [DATA3]         = {Anchor:New(BOTTOMRIGHT, DATA3HEADER, BOTTOMRIGHT, 0, GENERIC_HEADER_INFO_FONT_HEIGHT_DISPARITY)},

        [DATA4HEADER]   = {Anchor:New(BOTTOMLEFT, DATA3HEADER, BOTTOMLEFT, 0, ROW_OFFSET_Y),       Anchor:New(BOTTOMRIGHT, DATA3HEADER, BOTTOMRIGHT, 0, ROW_OFFSET_Y)},
        [DATA4]         = {Anchor:New(BOTTOMRIGHT, DATA4HEADER, BOTTOMRIGHT, 0, GENERIC_HEADER_INFO_FONT_HEIGHT_DISPARITY)},
    },

    [ZO_GAMEPAD_HEADER_LAYOUTS.DATA_PAIRS_TOGETHER] =
    {
        [DATA1HEADER]   = {Anchor:New(BOTTOMLEFT, DIVIDER_SIMPLE, BOTTOMLEFT, 0, ZO_GAMEPAD_CONTENT_HEADER_DIVIDER_INFO_BOTTOM_PADDING_Y)},
        [DATA1]         = {Anchor:New(BOTTOMLEFT, DATA1HEADER, BOTTOMRIGHT, DATA_OFFSET_X, GENERIC_HEADER_INFO_FONT_HEIGHT_DISPARITY)},

        [DATA2]         = {Anchor:New(BOTTOMRIGHT, CENTER_BASELINE, BOTTOMLEFT, GENERIC_HEADER_INFO_FONT_HEIGHT_DISPARITY)},
        [DATA2HEADER]   = {Anchor:New(BOTTOMRIGHT, DATA2, BOTTOMLEFT, -DATA_OFFSET_X, -GENERIC_HEADER_INFO_FONT_HEIGHT_DISPARITY)},

        [DATA3HEADER]   = {Anchor:New(BOTTOMLEFT, CENTER_BASELINE, BOTTOMRIGHT)},
        [DATA3]         = {Anchor:New(BOTTOMLEFT, DATA3HEADER, BOTTOMRIGHT, DATA_OFFSET_X, GENERIC_HEADER_INFO_FONT_HEIGHT_DISPARITY)},

        [DATA4]         = {Anchor:New(BOTTOMRIGHT, DIVIDER_SIMPLE, BOTTOMRIGHT, 0, ZO_GAMEPAD_CONTENT_HEADER_DIVIDER_INFO_BOTTOM_PADDING_Y + GENERIC_HEADER_INFO_FONT_HEIGHT_DISPARITY)},
        [DATA4HEADER]   = {Anchor:New(BOTTOMRIGHT, DATA4, BOTTOMLEFT, -DATA_OFFSET_X, -GENERIC_HEADER_INFO_FONT_HEIGHT_DISPARITY)},
    },

    [ZO_GAMEPAD_HEADER_LAYOUTS.CONTENT_HEADER_DATA_PAIRS_LINKED] =
    {
        [DATA1HEADER]   = {Anchor:New(BOTTOMLEFT, DIVIDER_SIMPLE, BOTTOMLEFT, 0, ZO_GAMEPAD_CONTENT_HEADER_DIVIDER_INFO_BOTTOM_PADDING_Y)},
        [DATA1]         = {Anchor:New(BOTTOMLEFT, DATA1HEADER, BOTTOMRIGHT, DATA_OFFSET_X, GENERIC_HEADER_INFO_FONT_HEIGHT_DISPARITY)},

        [DATA2HEADER]   = {Anchor:New(BOTTOMLEFT, DATA1, BOTTOMRIGHT, HEADER_OFFSET_X, -GENERIC_HEADER_INFO_FONT_HEIGHT_DISPARITY)},
        [DATA2]         = {Anchor:New(BOTTOMLEFT, DATA2HEADER, BOTTOMRIGHT, DATA_OFFSET_X, GENERIC_HEADER_INFO_FONT_HEIGHT_DISPARITY)},

        [DATA3HEADER]   = {Anchor:New(BOTTOMLEFT, DATA2, BOTTOMRIGHT, HEADER_OFFSET_X, -GENERIC_HEADER_INFO_FONT_HEIGHT_DISPARITY)},
        [DATA3]         = {Anchor:New(BOTTOMLEFT, DATA3HEADER, BOTTOMRIGHT, DATA_OFFSET_X, GENERIC_HEADER_INFO_FONT_HEIGHT_DISPARITY)},

        [DATA4HEADER]   = {Anchor:New(BOTTOMLEFT, DATA3, BOTTOMRIGHT, HEADER_OFFSET_X, -GENERIC_HEADER_INFO_FONT_HEIGHT_DISPARITY)},
        [DATA4]         = {Anchor:New(BOTTOMLEFT, DATA4HEADER, BOTTOMRIGHT, DATA_OFFSET_X, GENERIC_HEADER_INFO_FONT_HEIGHT_DISPARITY)},
    },
}

-- These targets are only applicable for the SCREEN header.
local MESSAGE_ANCHOR_TARGETS =
{
    [ZO_GAMEPAD_HEADER_LAYOUTS.DATA_PAIRS_SEPARATE] =
    {
        {DATA1HEADER, DATA1},
        {DATA2HEADER, DATA2},
        {DATA3HEADER, DATA3},
        {DATA4HEADER, DATA4},
    },

    [ZO_GAMEPAD_HEADER_LAYOUTS.DATA_PAIRS_TOGETHER] =
    {
        {DATA1HEADER, DATA1, DATA2HEADER, DATA2},
        {DATA3HEADER, DATA3, DATA4HEADER, DATA4},
    }
}

local function TabBar_Setup(control, data, selected, selectedDuringRebuild, enabled, activated)
    -- TODO: Switch the following code over to use ZO_SharedGamepadEntry_OnSetup.
    if data.canSelect == nil then
        data.canSelect = true
    end
    ZO_GamepadMenuHeaderTemplate_Setup(control, data, selected, selectedDuringRebuild, enabled, activated)
    SetDefaultColorOnLabel(control.text, selected)
end

function ZO_GamepadGenericHeader_Initialize(control, createTabBar, layout)
    control.controls =
    {
        [TABBAR]            = control:GetNamedChild("TabBar"),
        [TITLE]             = control:GetNamedChild("TitleContainer"):GetNamedChild("Title"),
        [CENTER_BASELINE]   = control:GetNamedChild("CenterAnchor"),
        [TITLE_BASELINE]    = control:GetNamedChild("TitleContainer"),
        [DIVIDER_SIMPLE]    = control:GetNamedChild("DividerSimple"),
        [DIVIDER_PIPPED]    = control:GetNamedChild("DividerPipped"),
        [DATA1]             = control:GetNamedChild("Data1"),
        [DATA1HEADER]       = control:GetNamedChild("Data1Header"),
        [DATA2]             = control:GetNamedChild("Data2"),
        [DATA2HEADER]       = control:GetNamedChild("Data2Header"),
        [DATA3]             = control:GetNamedChild("Data3"),
        [DATA3HEADER]       = control:GetNamedChild("Data3Header"),
        [DATA4]             = control:GetNamedChild("Data4"),
        [DATA4HEADER]       = control:GetNamedChild("Data4Header"),
        [MESSAGE]           = control:GetNamedChild("Message"),
    }

    if createTabBar == ZO_GAMEPAD_HEADER_TABBAR_CREATE then
        local tabBarControl = control.controls[TABBAR]
        local dividerSimpleControl = control.controls[DIVIDER_SIMPLE]
        local dividerPippedControl = control.controls[DIVIDER_PIPPED]

        tabBarControl:SetHidden(false)
        dividerPippedControl:SetHidden(false)
        dividerSimpleControl:SetHidden(true)

        control.tabBar = ZO_GamepadTabBarScrollList:New(tabBarControl, dividerPippedControl:GetNamedChild("LeftIcon"), dividerPippedControl:GetNamedChild("RightIcon"))
        control.tabBar:AddDataTemplate("ZO_GamepadTabBarTemplate", TabBar_Setup, ZO_GamepadMenuEntryTemplateParametricListFunction, MenuEntryTemplateEquality)
    end

    ZO_GamepadGenericHeader_SetDataLayout(control, layout or DEFAULT_LAYOUT)
end

function ZO_GamepadGenericHeader_GetChildControl(control, controlId)
    return control.controls[controlId]
end

local function ApplyAnchorToControl(control, anchor, targets)
    local target = anchor.targetId and targets[anchor.targetId] or nil
    anchor.anchor:SetTarget(target)
    anchor.anchor:AddToControl(control)
end

local function IsScreenHeader(controls)
    return not controls[CENTER_BASELINE]
end

local function ApplyAnchorSetToControl(dataControl, anchorSet, controls)
    dataControl:ClearAnchors()
    ApplyAnchorToControl(dataControl, anchorSet[1], controls)
    if anchorSet[2] then
        ApplyAnchorToControl(dataControl, anchorSet[2], controls)
    end
end

-- Note: ZO_GamepadGenericHeader_RefreshData must be called after changing the layout.
function ZO_GamepadGenericHeader_SetDataLayout(control, layout)
    if control.layout == layout then
        return
    end

    local controls = control.controls

    local anchorSets = IsScreenHeader(controls) and SCREEN_HEADER_ANCHORS[layout] or CONTENT_HEADER_ANCHORS[layout]
    assert(anchorSets ~= nil)

    for k, anchors in pairs(anchorSets) do
        local dataControl = controls[k]
        ApplyAnchorSetToControl(dataControl, anchors, controls)
    end

    control.layout = layout
end

local g_useHeaderOverlapAnchors = false

local function ReflowScreenHeaderDataPairSeparateIfNecessary(parentControl, dataControlIndex, dataHeaderControlIndex)
    local overlapAnchors = SCREEN_HEADER_OVERLAP_ANCHORS[parentControl.layout]

    if not overlapAnchors then
        return
    end

    local controls = parentControl.controls

    local dataControl = controls[dataControlIndex]
    local dataHeaderControl = controls[dataHeaderControlIndex]

    if g_useHeaderOverlapAnchors then
        if dataHeaderControl then
            local anchorSet = overlapAnchors[dataHeaderControlIndex]

            if anchorSet then
                ApplyAnchorSetToControl(dataHeaderControl, anchorSet, controls)
            end
        end
        g_useHeaderOverlapAnchors = false
    end

    if dataControl and dataHeaderControl then
        if dataControl:GetLeft() < dataHeaderControl:GetLeft() + dataHeaderControl:GetTextWidth() then
            local anchorSet = overlapAnchors[dataControlIndex]
            if anchorSet then
                ApplyAnchorSetToControl(dataControl, anchorSet, controls)
                g_useHeaderOverlapAnchors = true
            end
        end
    end
end

local function ScreenHeaderDataPairsSeparateReflow(control)
    control.layout = nil
    ZO_GamepadGenericHeader_SetDataLayout(control, ZO_GAMEPAD_HEADER_LAYOUTS.DATA_PAIRS_SEPARATE)
    g_useHeaderOverlapAnchors = false

    ReflowScreenHeaderDataPairSeparateIfNecessary(control, DATA1, DATA1HEADER)
    ReflowScreenHeaderDataPairSeparateIfNecessary(control, DATA2, DATA2HEADER)
    ReflowScreenHeaderDataPairSeparateIfNecessary(control, DATA3, DATA3HEADER)
    ReflowScreenHeaderDataPairSeparateIfNecessary(control, DATA4, DATA4HEADER)
end

local g_currentBottomLeftHeader = DATA1HEADER

local function ReflowContentHeaderDataPairIfNecessary(parentControl, dataControlIndex, dataHeaderControlIndex)
    local controls = parentControl.controls

    local dataControl = controls[dataControlIndex]
    if dataControl and dataControl:GetRight() > parentControl:GetRight() then
        local dataHeaderControl = controls[dataHeaderControlIndex]
        dataHeaderControl:ClearAnchors()
        dataHeaderControl:SetAnchor(BOTTOMLEFT, controls[g_currentBottomLeftHeader], BOTTOMLEFT, 0, ROW_OFFSET_Y)
        g_currentBottomLeftHeader = dataHeaderControlIndex
    end
end

local function ContentHeaderDataPairsLinkedReflow(control)
    control.layout = nil
    ZO_GamepadGenericHeader_SetDataLayout(control, ZO_GAMEPAD_HEADER_LAYOUTS.CONTENT_HEADER_DATA_PAIRS_LINKED)
    g_currentBottomLeftHeader = DATA1HEADER    -- Reset the bottom left header value

    ReflowContentHeaderDataPairIfNecessary(control, DATA2, DATA2HEADER)
    ReflowContentHeaderDataPairIfNecessary(control, DATA3, DATA3HEADER)
    ReflowContentHeaderDataPairIfNecessary(control, DATA4, DATA4HEADER)
end

local SCREEN_HEADER_REFLOW_FUNCS = 
{
    [ZO_GAMEPAD_HEADER_LAYOUTS.DATA_PAIRS_SEPARATE] = ScreenHeaderDataPairsSeparateReflow,
}

local CONTENT_HEADER_REFLOW_FUNCS =
{
    [ZO_GAMEPAD_HEADER_LAYOUTS.CONTENT_HEADER_DATA_PAIRS_LINKED] = ContentHeaderDataPairsLinkedReflow,
}

local function ReflowLayout(control)
    local reflowFunc = IsScreenHeader(control.controls) and SCREEN_HEADER_REFLOW_FUNCS[control.layout] or CONTENT_HEADER_REFLOW_FUNCS[control.layout]
    if reflowFunc then
        reflowFunc(control)
    end
end

local function ProcessData(control, data)
    if(control == nil) then
        return false
    end

    if type(data) == "function" then
        data = data(control)
    end

    if type(data) == "string" or type(data) == "number" then
        control:SetText(data)
    end

    control:SetHidden(not data)
    return data ~= nil
end

local function SetAnchorOffsetY(control, index, offsetY)
    local isValid, point, relTo, relPoint, offsetX = control:GetAnchor(index)
    if isValid then
        control:SetAnchor(point, relTo, relPoint, offsetX, offsetY)
    end
end

local function SetAnchorTarget(control, index, target)
    local isValid, point, _, relPoint, offsetX, offsetY = control:GetAnchor(index)
    if isValid then
        control:SetAnchor(point, target, relPoint, offsetX, offsetY)
    end
end

local function AdjustMessageAnchors(control, refreshResults)
    if refreshResults[MESSAGE] then
        -- Test each anchor target set to see if any one of the controls in that set is in use.  If so, then increase the running offset by a set amount.
        -- The idea here is to anchor the message control to the last label/data row that is in use.
        local additionalOffsetY = 0
        local anchorTargetSets = MESSAGE_ANCHOR_TARGETS[control.layout]
        for _, anchorTargets in ipairs(anchorTargetSets) do
            for _, target in ipairs(anchorTargets) do
                if (refreshResults[target] ~= false) then
                    additionalOffsetY = additionalOffsetY + ROW_OFFSET_Y
                    break
                end
            end
        end

        -- Apply the offset calculated above to the message control's anchors.
        local message = control.controls[MESSAGE]
        for i = 0, MAX_ANCHORS - 1 do
            SetAnchorOffsetY(message, i, ZO_GAMEPAD_CONTENT_DIVIDER_INFO_PADDING_Y + additionalOffsetY)
        end
    end
end

local g_refreshResults = {}

local function SetAlignment(control, alignment, defaultAlignment)
    if(control == nil) then
        return
    end

    if(alignment == nil) then
        alignment = defaultAlignment
    end

    control:SetHorizontalAlignment(alignment)
end

function ZO_GamepadGenericHeader_RefreshData(control, data)
    local controls = control.controls

    ProcessData(controls[TITLE], data.titleText)
    SetAlignment(controls[TITLE], data.titleTextAlignment, IsScreenHeader(control.controls) and TEXT_ALIGN_CENTER or TEXT_ALIGN_LEFT)

    g_refreshResults[DATA1HEADER]   = ProcessData(controls[DATA1HEADER], data.data1HeaderText)
    g_refreshResults[DATA1]         = ProcessData(controls[DATA1], data.data1Text)
    g_refreshResults[DATA2HEADER]   = ProcessData(controls[DATA2HEADER], data.data2HeaderText)
    g_refreshResults[DATA2]         = ProcessData(controls[DATA2], data.data2Text)
    g_refreshResults[DATA3HEADER]   = ProcessData(controls[DATA3HEADER], data.data3HeaderText)
    g_refreshResults[DATA3]         = ProcessData(controls[DATA3], data.data3Text)
    g_refreshResults[DATA4HEADER]   = ProcessData(controls[DATA4HEADER], data.data4HeaderText)
    g_refreshResults[DATA4]         = ProcessData(controls[DATA4], data.data4Text)
    g_refreshResults[MESSAGE]       = ProcessData(controls[MESSAGE], data.messageText)
    SetAlignment(controls[MESSAGE], data.messageTextAlignment, TEXT_ALIGN_CENTER)

    ReflowLayout(control)
    AdjustMessageAnchors(control, g_refreshResults)
end

local function TabBar_OnDataChanged(control, newData, oldData, reselectingDuringRebuild)
    if newData.callback then
        newData.callback()
    end
end

function ZO_GamepadGenericHeader_Refresh(control, data, blockTabBarCallbacks)
    ZO_GamepadGenericHeader_RefreshData(control, data)

    if control.tabBar then
        if(blockTabBarCallbacks) then
            control.tabBar:RemoveOnSelectedDataChangedCallback(TabBar_OnDataChanged)
        else
            control.tabBar:SetOnSelectedDataChangedCallback(TabBar_OnDataChanged)
        end

        if data.activatedCallback then
            control.tabBar:SetOnActivatedChangedFunction(data.activatedCallback)
        end

        local pipsEnabled = false
        local tabBarControl = control.controls[TABBAR]
        local dividerSimpleControl = control.controls[DIVIDER_SIMPLE]
        local dividerPippedControl = control.controls[DIVIDER_PIPPED]
        local pipsControl = nil
        local numEntries = 0

        control.tabBar:Clear()
        if data.tabBarEntries then
            for i, tabData in ipairs(data.tabBarEntries) do
                if (tabData.visible == nil) or tabData.visible() then
                    control.tabBar:AddEntry("ZO_GamepadTabBarTemplate", tabData)
                    numEntries = numEntries + 1
                end
            end
            control.tabBar:Commit()

            pipsEnabled = numEntries > 1
            pipsControl = dividerPippedControl:GetNamedChild("Pips")
        end

        tabBarControl:SetHidden(numEntries == 0)
        dividerPippedControl:SetHidden(not pipsEnabled)
        dividerSimpleControl:SetHidden(pipsEnabled)
        control.tabBar:SetPipsEnabled(pipsEnabled, pipsControl)

        if(blockTabBarCallbacks) then
            control.tabBar:SetOnSelectedDataChangedCallback(TabBar_OnDataChanged)
        end
    end
end

function ZO_GamepadGenericHeader_Activate(control)
    if(control.tabBar) then
        control.tabBar:Activate()
    end
end

function ZO_GamepadGenericHeader_Deactivate(control)
    if(control.tabBar) then
        control.tabBar:Deactivate()
    end
end

function ZO_GamepadGenericHeader_SetActiveTabIndex(control, tabIndex, allowEvenIfDisabled)
    if(control.tabBar) then
        control.tabBar:SetSelectedIndex(tabIndex, allowEvenIfDisabled)
    end
end

function ZO_GamepadGenericHeader_SetTabBarPlaySoundFunction(control, fn)
    if(control.tabBar) then
        control.tabBar:SetPlaySoundFunction(fn)
    end
end

function ZO_GamepadGenericHeader_SetPipsEnabled(control, enabled)
    if(control.tabBar) then
        control.tabBar:SetPipsEnabled(enabled)
    end
end