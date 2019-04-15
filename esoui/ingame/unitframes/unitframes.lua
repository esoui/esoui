local BARS_PADDING_X = 8
local BAR1_TOP_PADDING_Y = 16
local BAR2_BOTTOM_PADDING_Y = -2

local FULL_ALPHA_VALUE = 1
local FADED_ALPHA_VALUE = 0.4

local HIDE_BAR_TEXT = 0
local SHOW_BAR_TEXT_MOUSE_OVER = 1
local SHOW_BAR_TEXT = 2

local FORCE_INIT = true

local GROUP_UNIT_FRAME = "ZO_GroupUnitFrame"
local RAID_UNIT_FRAME = "ZO_RaidUnitFrame"
local TARGET_UNIT_FRAME = "ZO_TargetUnitFrame"

local untrackedBarTypes =
{

}

local NUM_SUBGROUPS = GROUP_SIZE_MAX / SMALL_GROUP_SIZE_THRESHOLD

ZO_KEYBOARD_GROUP_FRAME_WIDTH = 288
ZO_KEYBOARD_GROUP_FRAME_HEIGHT = 80
ZO_KEYBOARD_RAID_FRAME_WIDTH = 96
ZO_KEYBOARD_RAID_FRAME_HEIGHT = 40

local KEYBOARD_CONSTANTS =
{
    GROUP_LEADER_ICON = "EsoUI/Art/UnitFrames/groupIcon_leader.dds",

    GROUP_FRAMES_PER_COLUMN = SMALL_GROUP_SIZE_THRESHOLD,
    NUM_COLUMNS = NUM_SUBGROUPS,

    GROUP_STRIDE = NUM_SUBGROUPS,

    GROUP_FRAME_BASE_OFFSET_X = 28,
    GROUP_FRAME_BASE_OFFSET_Y = 100,

    RAID_FRAME_BASE_OFFSET_X = 28,
    RAID_FRAME_BASE_OFFSET_Y = 100,

    GROUP_FRAME_SIZE_X = ZO_KEYBOARD_GROUP_FRAME_WIDTH,
    GROUP_FRAME_SIZE_Y = ZO_KEYBOARD_GROUP_FRAME_HEIGHT,

    GROUP_FRAME_PAD_X = 2,
    GROUP_FRAME_PAD_Y = 0,

    RAID_FRAME_SIZE_X = ZO_KEYBOARD_RAID_FRAME_WIDTH,
    RAID_FRAME_SIZE_Y = ZO_KEYBOARD_RAID_FRAME_HEIGHT,

    RAID_FRAME_PAD_X = 2,
    RAID_FRAME_PAD_Y = 2,

    GROUP_BAR_FONT = "ZoFontGameOutline",
    RAID_BAR_FONT = "ZoFontGameOutline",

    SHOW_GROUP_LABELS = true,
}

ZO_GAMEPAD_GROUP_FRAME_WIDTH = 160
ZO_GAMEPAD_GROUP_FRAME_HEIGHT = 70
ZO_GAMEPAD_RAID_FRAME_WIDTH = 175
ZO_GAMEPAD_RAID_FRAME_HEIGHT = 40

local GAMEPAD_CONSTANTS =
{
    GROUP_LEADER_ICON = "EsoUI/Art/UnitFrames/Gamepad/gp_Group_Leader.dds",

    GROUP_FRAMES_PER_COLUMN = 12,
    NUM_COLUMNS = GROUP_SIZE_MAX / 12,

    GROUP_STRIDE = 3,

    GROUP_FRAME_BASE_OFFSET_X = 70,
    GROUP_FRAME_BASE_OFFSET_Y = 55,

    RAID_FRAME_BASE_OFFSET_X = 100,
    RAID_FRAME_BASE_OFFSET_Y = 50,

    GROUP_FRAME_SIZE_X = ZO_GAMEPAD_GROUP_FRAME_WIDTH,
    GROUP_FRAME_SIZE_Y = ZO_GAMEPAD_GROUP_FRAME_HEIGHT,

    GROUP_FRAME_PAD_X = 2,
    GROUP_FRAME_PAD_Y = 9,

    RAID_FRAME_SIZE_X = ZO_GAMEPAD_RAID_FRAME_WIDTH,
    RAID_FRAME_SIZE_Y = ZO_GAMEPAD_RAID_FRAME_HEIGHT,

    RAID_FRAME_PAD_X = 4,
    RAID_FRAME_PAD_Y = 2,

    GROUP_BAR_FONT = "ZoFontGamepad34",
    RAID_BAR_FONT = "ZoFontGamepad18",

    SHOW_GROUP_LABELS = false,
}

local function GetPlatformConstants()
    return IsInGamepadPreferredMode() and GAMEPAD_CONSTANTS or KEYBOARD_CONSTANTS
end

local function CalculateDynamicPlatformConstants()
    local allConstants = {KEYBOARD_CONSTANTS, GAMEPAD_CONSTANTS}

    for _, constants in ipairs(allConstants) do
        constants.GROUP_FRAME_OFFSET_X = constants.GROUP_FRAME_SIZE_X + constants.GROUP_FRAME_PAD_X
        constants.GROUP_FRAME_OFFSET_Y = constants.GROUP_FRAME_SIZE_Y + constants.GROUP_FRAME_PAD_Y

        constants.RAID_FRAME_OFFSET_X = constants.RAID_FRAME_SIZE_X + constants.RAID_FRAME_PAD_X
        constants.RAID_FRAME_OFFSET_Y = constants.RAID_FRAME_SIZE_Y + constants.RAID_FRAME_PAD_Y

        constants.RAID_FRAME_ANCHOR_CONTAINER_WIDTH = constants.RAID_FRAME_SIZE_X
        constants.RAID_FRAME_ANCHOR_CONTAINER_HEIGHT = (constants.RAID_FRAME_SIZE_Y + constants.RAID_FRAME_PAD_Y) * constants.GROUP_FRAMES_PER_COLUMN
    end
end

local function GetPlatformBarFont()
    local groupSize = GetGroupSize()
    local constants = GetPlatformConstants()
    if groupSize > SMALL_GROUP_SIZE_THRESHOLD then
        return constants.RAID_BAR_FONT
    else
        return constants.GROUP_BAR_FONT
    end
end

local UNIT_CHANGED = true

local groupFrameAnchor = ZO_Anchor:New(TOPLEFT, GuiRoot, TOPLEFT, 0, 0)

local function GetGroupFrameAnchor(groupIndex, groupSize)
    local constants = GetPlatformConstants()

    groupSize = groupSize or GetGroupSize()
    local column = zo_floor((groupIndex - 1) / constants.GROUP_FRAMES_PER_COLUMN)
    local row = zo_mod(groupIndex - 1, constants.GROUP_FRAMES_PER_COLUMN)

    if(groupSize > SMALL_GROUP_SIZE_THRESHOLD) then
        if IsInGamepadPreferredMode() then
            column = zo_mod(groupIndex - 1, constants.NUM_COLUMNS)
            row = zo_floor((groupIndex - 1) / 2)
        end
        groupFrameAnchor:SetTarget(GetControl("ZO_LargeGroupAnchorFrame"..(column + 1)))
        groupFrameAnchor:SetOffsets(0, row * constants.RAID_FRAME_OFFSET_Y)
        return groupFrameAnchor
    else
        groupFrameAnchor:SetTarget(ZO_SmallGroupAnchorFrame)
        groupFrameAnchor:SetOffsets(0, row * constants.GROUP_FRAME_OFFSET_Y)
        return groupFrameAnchor
    end
end

local function GetGroupAnchorFrameOffsets(subgroupIndex, groupStride, constants)
    groupStride = groupStride or NUM_SUBGROUPS
    local zeroBasedIndex = subgroupIndex - 1
    local row = zo_floor(zeroBasedIndex / groupStride)
    local column = zeroBasedIndex - (row * groupStride)

    return (constants.RAID_FRAME_BASE_OFFSET_X + (column * constants.RAID_FRAME_OFFSET_X)), (constants.RAID_FRAME_BASE_OFFSET_Y + (row * constants.RAID_FRAME_ANCHOR_CONTAINER_HEIGHT))
end

--[[
    Global object declarations
--]]

UNIT_FRAMES = nil

ZO_MostRecentPowerUpdateHandler = ZO_MostRecentEventHandler:Subclass()

do
    local function PowerUpdateEqualityFunction(existingEventInfo, unitTag, powerPoolIndex, powerType, powerPool, powerPoolMax)
        local existingUnitTag = existingEventInfo[1]
        local existingPowerType = existingEventInfo[3]
        return existingUnitTag == unitTag and existingPowerType == powerType
    end

    function ZO_MostRecentPowerUpdateHandler:New(namespace, handlerFunction)
        return ZO_MostRecentEventHandler.New(self, namespace, EVENT_POWER_UPDATE, PowerUpdateEqualityFunction, handlerFunction)
    end
end

--[[
    Local object declarations
--]]

local UnitFrames, UnitFramesManager, UnitFrame, UnitFrameBar

--[[
    UnitFrames container object.  Used to manage the UnitFrame objects according to UnitTags ("group1", "group4pet", etc...)
--]]

UnitFramesManager = ZO_Object:Subclass()

function UnitFramesManager:New()
    local unitFrames = ZO_Object.New(self)

    unitFrames.groupFrames = {}
    unitFrames.raidFrames = {}
    unitFrames.staticFrames = {}
    unitFrames.groupSize = GetGroupSize()
    unitFrames.targetOfTargetEnabled = true
    unitFrames.groupAndRaidHiddenReasons = ZO_HiddenReasons:New()
    unitFrames.firstDirtyGroupIndex = nil

    return unitFrames
end

local function ApplyVisualStyleToAllFrames(frames)
    for _, unitFrame in pairs(frames) do
        unitFrame:ApplyVisualStyle()
    end
end

function UnitFramesManager:ApplyVisualStyle()
    ApplyVisualStyleToAllFrames(self.staticFrames)
    ApplyVisualStyleToAllFrames(self.groupFrames)
    ApplyVisualStyleToAllFrames(self.raidFrames)
end

function UnitFramesManager:GetUnitFrameLookupTable(unitTag)
    if unitTag then
        local isGroupTag = ZO_Group_IsGroupUnitTag(unitTag)

        if isGroupTag then
            if self.groupSize <= SMALL_GROUP_SIZE_THRESHOLD then
                return self.groupFrames
            else
                return self.raidFrames
            end
        end
    end

    return self.staticFrames
end

function UnitFramesManager:GetFrame(unitTag)
    local unitFrameTable = self:GetUnitFrameLookupTable(unitTag)

    if unitFrameTable then
        return unitFrameTable[unitTag]
    end
end

function UnitFramesManager:CreateFrame(unitTag, anchors, showBarText, style)
    local unitFrame = self:GetFrame(unitTag)
    if unitFrame == nil then
        local unitFrameTable = self:GetUnitFrameLookupTable(unitTag)
        unitFrame = UnitFrame:New(unitTag, anchors, showBarText, style)

        if unitFrameTable then
             unitFrameTable[unitTag] = unitFrame
        end
    else
        -- Frame already existed, but may need to be reanchored.
        unitFrame:SetAnchor(anchors)
    end

    return unitFrame
end

function UnitFramesManager:SetFrameHiddenForReason(unitTag, reason, hidden)
    local unitFrame = self:GetFrame(unitTag)

    if unitFrame then
        unitFrame:SetHiddenForReason(reason, hidden)
    end
end

function UnitFramesManager:SetGroupSize(groupSize)
    self.groupSize = groupSize or GetGroupSize()
end

function UnitFramesManager:GetFirstDirtyGroupIndex()
    return self.firstDirtyGroupIndex
end

function UnitFramesManager:GetIsDirty()
    return self.firstDirtyGroupIndex ~= nil
end

function UnitFramesManager:SetGroupIndexDirty(groupIndex)
    -- The update we call will update all unit frames after and including the one being modified
    -- So we really just need to know what is the smallest groupIndex that is being changed 
    if not self.firstDirtyGroupIndex or groupIndex < self.firstDirtyGroupIndex then
        self.firstDirtyGroupIndex = groupIndex
    end
end

function UnitFramesManager:ClearDirty()
    self.firstDirtyGroupIndex = nil
end

function UnitFramesManager:DisableGroupAndRaidFrames()
    -- Disable the raid frames
    for unitTag, unitFrame in pairs(self.raidFrames) do
        unitFrame:SetHiddenForReason("disabled", true)
    end

    -- Disable the group frames
    for unitTag, unitFrame in pairs(self.groupFrames) do
        unitFrame:SetHiddenForReason("disabled", true)
    end
end

function UnitFramesManager:SetGroupAndRaidFramesHiddenForReason(reason, hidden)
    UNIT_FRAMES_FRAGMENT:SetHiddenForReason(reason, hidden)
    self.groupAndRaidHiddenReasons:SetHiddenForReason(reason, hidden)
end

function UnitFramesManager:UpdateGroupAnchorFrames()
    -- Only the raid frame anchors need updates for now and it's only for whether or not the group name labels are showing and which one is highlighted
    if(self.groupSize <= SMALL_GROUP_SIZE_THRESHOLD or self.groupAndRaidHiddenReasons:IsHidden()) then
        -- Small groups never show the raid frame anchors
        for subgroupIndex = 1, NUM_SUBGROUPS do
            GetControl("ZO_LargeGroupAnchorFrame"..subgroupIndex):SetHidden(true)
        end
    else
        for subgroupIndex = 1, NUM_SUBGROUPS do
            local frameIsHidden = true -- Label starts out hidden...
            local isLocalPlayerInSubgroup = false
            for groupMemberIndex = 1, SMALL_GROUP_SIZE_THRESHOLD do
                local unitTag = GetGroupUnitTagByIndex(((subgroupIndex - 1) * SMALL_GROUP_SIZE_THRESHOLD) + groupMemberIndex)
                if unitTag then
                    frameIsHidden = false
                    if AreUnitsEqual("player", unitTag) then
                        isLocalPlayerInSubgroup = true
                        break -- Found a reason to show the label, and determined if this is the local player's subgroup, so bail out
                    end
                end
            end

            local anchorFrame = GetControl("ZO_LargeGroupAnchorFrame"..subgroupIndex)
            anchorFrame:SetHidden(frameIsHidden)
        end
    end
end

function UnitFramesManager:IsTargetOfTargetEnabled()
    return self.targetOfTargetEnabled
end

function UnitFramesManager:SetEnableTargetOfTarget(enableFlag)
    if(enableFlag ~= self.targetOfTargetEnabled) then
        self.targetOfTargetEnabled = enableFlag
        CALLBACK_MANAGER:FireCallbacks("TargetOfTargetEnabledChanged", enableFlag)
    end
end

--[[
    UnitFrameBar class...defines one bar in the unit frame, including background/glass textures, statusbar and text
--]]

local ANY_POWER_TYPE = true -- A special flag that essentially acts like a wild card, accepting any mechanic

local UNITFRAME_BAR_STYLES =
{
    [TARGET_UNIT_FRAME] =
    {
        [POWERTYPE_HEALTH] =
        {
            textAnchors =
            {
                ZO_Anchor:New(TOP, nil, BOTTOM, 0, -22),
            },
            centered = true,
        },
    },    

    [GROUP_UNIT_FRAME] =
    {
        [POWERTYPE_HEALTH] =
        {
            keyboard =
            {
                template = "ZO_GroupUnitFrameStatus",
                barHeight = 9,
                barWidth = 170,
                barAnchors = { ZO_Anchor:New(TOPLEFT, nil, TOPLEFT, 36, 42) },
            },

            gamepad =
            {
                template = "ZO_GroupUnitFrameStatus",
                barHeight = 8,
                barWidth = ZO_GAMEPAD_GROUP_FRAME_WIDTH,
                barAnchors = { ZO_Anchor:New(TOPLEFT, nil, TOPLEFT, 0, 45) },
                hideBgIfOffline = true,
            },
        },
    },

    [RAID_UNIT_FRAME] =
    {
        [POWERTYPE_HEALTH] =
        {
            keyboard =
            {
                template = "ZO_UnitFrameStatus",
                barHeight = 34,
                barWidth = 90,
                barAnchors = { ZO_Anchor:New(TOPLEFT, nil, TOPLEFT, 2, 2) },
            },

            gamepad =
            {
                template = "ZO_UnitFrameStatus",
                barHeight = ZO_GAMEPAD_RAID_FRAME_HEIGHT - 2,
                barWidth = ZO_GAMEPAD_RAID_FRAME_WIDTH - 2,
                barAnchors = { ZO_Anchor:New(TOPLEFT, nil, TOPLEFT, 1, 1) },
            },
        },
    },
}

local function GetPlatformBarStyle(style, powerType)
    local styleData = UNITFRAME_BAR_STYLES[style] or UNITFRAME_BAR_STYLES.default
    local barData = styleData[powerType] or styleData[ANY_POWER_TYPE]

    if barData then
        -- Note: It is assumed that either all platforms are defined, or no platforms are defined.
        local platformKey = IsInGamepadPreferredMode() and "gamepad" or "keyboard"
        return barData[platformKey] or barData
    end
end

local function IsValidBarStyle(style, powerType)
    local styleData = UNITFRAME_BAR_STYLES[style] or UNITFRAME_BAR_STYLES.default
    return styleData and (styleData[powerType] ~= nil or styleData[ANY_POWER_TYPE] ~= nil)
end

local function CreateBarStatusControl(baseBarName, parent, style, mechanic, showBarText)
    local barData = GetPlatformBarStyle(style, mechanic)
    if barData then
        if barData.template then
            local barAnchor1, barAnchor2 = barData.barAnchors[1], barData.barAnchors[2]

            if barData.centered then
                local leftBar = CreateControlFromVirtual(baseBarName.."Left", parent, barData.template)
                local rightBar = CreateControlFromVirtual(baseBarName.."Right", parent, barData.template)

                if barAnchor1 then
                    barAnchor1:Set(leftBar)
                end

                if barAnchor2 then
                    barAnchor2:Set(rightBar)
                end

                leftBar:SetBarAlignment(BAR_ALIGNMENT_REVERSE)
                local gloss = leftBar:GetNamedChild("Gloss")
                if gloss then
                    gloss:SetBarAlignment(BAR_ALIGNMENT_REVERSE)
                end

                if barData.barWidth then
                    leftBar:SetWidth(barData.barWidth / 2)
                    rightBar:SetWidth(barData.barWidth / 2)
                end

                if barData.barHeight then
                    leftBar:SetHeight(barData.barHeight)
                    rightBar:SetHeight(barData.barHeight)
                end

                rightBar:SetAnchor(TOPLEFT, leftBar, TOPRIGHT, 0, 0)

                return { leftBar, rightBar }
            else
                local statusBar = CreateControlFromVirtual(baseBarName, parent, barData.template)
                if barData.barWidth then
                    statusBar:SetWidth(barData.barWidth)
                end

                if barData.barHeight then
                    statusBar:SetHeight(barData.barHeight)
                end

                if barAnchor1 then
                    barAnchor1:Set(statusBar)
                end

                if barAnchor2 then
                    barAnchor2:AddToControl(statusBar)
                end

                return { statusBar }
            end
        else
            -- attempt to find the controls from XML
            local bar = parent:GetNamedChild("Bar")
            if bar then
                return { bar }
            end
            local barLeft = parent:GetNamedChild("BarLeft")
            local barRight = parent:GetNamedChild("BarRight")
            if barLeft and barRight then
                return { barLeft, barRight }
            end
        end
    end
    return nil
end

local function CreateBarTextControls(baseBarName, parent, style, mechanic)
    local barData = GetPlatformBarStyle(style, mechanic)
    local textAnchor1, textAnchor2 = barData.textAnchors[1], barData.textAnchors[2]

    local text1, text2
    local textTemplate = barData.textTemplate or "ZO_UnitFrameBarText"

    if textAnchor1 then
        text1 = CreateControlFromVirtual(baseBarName.."Text1", parent, textTemplate)
        text1:SetFont(GetPlatformBarFont())
        textAnchor1:Set(text1)
    end

    if textAnchor2 then
        text2 = CreateControlFromVirtual(baseBarName.."Text2", parent, textTemplate)
        text2:SetFont(GetPlatformBarFont())
        textAnchor2:Set(text2)
    end

    return text1, text2
end

UnitFrameBar = ZO_Object:Subclass()

function UnitFrameBar:New(baseBarName, parent, showFrameBarText, style, mechanic)
    local barControls = CreateBarStatusControl(baseBarName, parent, style, mechanic, showFrameBarText)

    if barControls then
        local newFrameBar = ZO_Object.New(self)
        newFrameBar.barControls = barControls
        newFrameBar.showBarText = showFrameBarText
        newFrameBar.style = style
        newFrameBar.mechanic = mechanic
        newFrameBar.resourceNumbersLabel = parent:GetNamedChild("ResourceNumbers")

        if showFrameBarText ~= HIDE_BAR_TEXT then
            newFrameBar.leftText, newFrameBar.rightText = CreateBarTextControls(baseBarName, parent, style, mechanic)
        end
        return newFrameBar
    end
end

function UnitFrameBar:Update(barType, cur, max, forceInit)
    local barCur = cur
    local barMax = max

    if #self.barControls == 2 then
        barCur = cur / 2
        barMax = max / 2
    end

    for i = 1, #self.barControls do
        ZO_StatusBar_SmoothTransition(self.barControls[i], barCur, barMax, forceInit)
    end

    local updateBarType = false
    local updateValue = cur ~= self.currentValue or self.maxValue ~= max
    self.currentValue = cur
    self.maxValue = max

    if barType ~= self.barType then
        updateBarType = true
        self.barType = barType
        self.barTypeName = GetString("SI_COMBATMECHANICTYPE", self.barType)
    end

    self:UpdateText(updateBarType, updateValue)
end

local function GetVisibility(self)
    if self.showBarText == SHOW_BAR_TEXT_MOUSE_OVER then
        return self.isMouseInside
    end
    return true
end

function UnitFrameBar:UpdateText(updateBarType, updateValue)
    if self.showBarText == SHOW_BAR_TEXT or self.showBarText == SHOW_BAR_TEXT_MOUSE_OVER then
        local visible = GetVisibility(self)
        if self.leftText and self.rightText then
            self.leftText:SetHidden(not visible)
            self.rightText:SetHidden(not visible)
            if visible then
                if updateBarType then
                    self.leftText:SetText(zo_strformat(SI_UNIT_FRAME_BARTYPE, self.barTypeName))
                end
                if updateValue then
                    self.rightText:SetText(zo_strformat(SI_UNIT_FRAME_BARVALUE, self.currentValue, self.maxValue))
                end
            end
        elseif self.leftText then
            if visible then
                self.leftText:SetHidden(false)
                if updateValue then
                    self.leftText:SetText(zo_strformat(SI_UNIT_FRAME_BARVALUE, self.currentValue, self.maxValue))
                end
            else
                self.leftText:SetHidden(true)
            end
        end
    end

    if self.resourceNumbersLabel then
        self.resourceNumbersLabel:SetText(ZO_FormatResourceBarCurrentAndMax(self.currentValue, self.maxValue))
    end
end

function UnitFrameBar:SetMouseInside(inside)
    self.isMouseInside = inside

    if(self.showBarText == SHOW_BAR_TEXT_MOUSE_OVER) then
        local UPDATE_BAR_TYPE, UPDATE_VALUE = true, true
        self:UpdateText(UPDATE_BAR_TYPE, UPDATE_VALUE)
    end
end

function UnitFrameBar:SetColor(barType)
    local gradient = ZO_POWER_BAR_GRADIENT_COLORS[barType]

    for i = 1, #self.barControls do
        ZO_StatusBar_SetGradientColor(self.barControls[i], gradient)
        self.barControls[i]:SetFadeOutLossColor(GetInterfaceColor(INTERFACE_COLOR_TYPE_POWER_FADE_OUT, barType))
        self.barControls[i]:SetFadeOutGainColor(GetInterfaceColor(INTERFACE_COLOR_TYPE_POWER_FADE_IN, barType))
    end
end

function UnitFrameBar:Hide(hidden)
    for i = 1, #self.barControls do
        self.barControls[i]:SetHidden(hidden)
    end
end

function UnitFrameBar:SetAlpha(alpha)
    for i = 1, #self.barControls do
        self.barControls[i]:SetAlpha(alpha)
    end

    if(self.leftText) then
        self.leftText:SetAlpha(alpha)
    end

    if(self.rightText) then
        self.rightText:SetAlpha(alpha)
    end
end

function UnitFrameBar:GetBarControls()
    return self.barControls
end

function UnitFrameBar:SetBarTextMode(alwaysShow)
    self.showBarText = alwaysShow
    local UPDATE_BAR_TYPE, UPDATE_VALUE = true, true
    self:UpdateText(UPDATE_BAR_TYPE, UPDATE_VALUE)
end

--[[
    UnitFrame main class and update functions
--]]

local UNITFRAME_LAYOUT_DATA =
{
    [GROUP_UNIT_FRAME] =
    {
        keyboard =
        {
            nameAnchor = ZO_Anchor:New(TOPLEFT, nil, TOPLEFT, 35, 19),
            nameWidth = 215,
            nameWrapMode = TEXT_WRAP_MODE_ELLIPSIS,

            statusData = { anchor1 = ZO_Anchor:New(TOPLEFT, nil, TOPLEFT, 36, 42), anchor2 = ZO_Anchor:New(TOPRIGHT, nil, TOPRIGHT, -140, 42), height = 0, },

            leaderIconData = {width = 16, height = 16, offsetX = 5, offsetY = 5}
        },

        gamepad =
        {
            nameAnchor = ZO_Anchor:New(TOPLEFT, nil, TOPLEFT, 0, 1),
            nameWidth = 306,
            nameWrapMode = TEXT_WRAP_MODE_ELLIPSIS,

            indentedNameAnchor = ZO_Anchor:New(TOPLEFT, nil, TOPLEFT, 25, 3),

            statusData = { anchor1 = ZO_Anchor:New(TOPLEFT, nil, TOPLEFT, 0, 0), anchor2 = ZO_Anchor:New(TOPRIGHT, nil, TOPRIGHT, 0, 35), height = 0, },
            hideHealthBgIfOffline = true,

            leaderIconData = {width = 25, height = 25, offsetX = 0, offsetY = 12}
        },
    },

    [RAID_UNIT_FRAME] =
    {
        keyboard =
        {
            highPriorityBuffHighlight =
            {
                left = { texture = "EsoUI/Art/UnitFrames/unitframe_raid_outline_left.dds", width = 64, height = 64, },
                right = { texture = "EsoUI/Art/UnitFrames/unitframe_raid_outline_right.dds", width = 32, height = 64, },
                icon = { width = 14, height = 14, customAnchor = ZO_Anchor:New(TOPLEFT, nil, TOPLEFT, 76, 15) },
            },

            nameAnchor = ZO_Anchor:New(TOPLEFT, nil, TOPLEFT, 5, 4),
            nameWidth = 86,

            indentedNameAnchor = ZO_Anchor:New(TOPLEFT, nil, TOPLEFT, 19, 4),
            indentedNameWidth = 75,

            statusData = { anchor1 = ZO_Anchor:New(TOPLEFT, nil, TOPLEFT, 5, 20), anchor2 = ZO_Anchor:New(TOPRIGHT, nil, TOPRIGHT, -4, 20), height = 15, },

            leaderIconData = {width = 16, height = 16, offsetX = 5, offsetY = 5}
        },

        gamepad =
        {
            highPriorityBuffHighlight =
            {
                left = { texture = "EsoUI/Art/UnitFrames/unitframe_raid_outline_left.dds", width = 54, height = 44, },
                right = { texture = "EsoUI/Art/UnitFrames/unitframe_raid_outline_right.dds", width = 32, height = 44, },
                icon = { width = 14, height = 14, customAnchor = ZO_Anchor:New(TOPLEFT, nil, TOPLEFT, 66, 7) },
            },

            nameAnchor = ZO_Anchor:New(TOPLEFT, nil, TOPLEFT, 6, 2),
            nameWidth = ZO_GAMEPAD_RAID_FRAME_WIDTH - 6,
            indentedNameAnchor = ZO_Anchor:New(TOPLEFT, nil, TOPLEFT, 20, 3),
            indentedNameWidth = ZO_GAMEPAD_RAID_FRAME_WIDTH - 20 - 2,

            leaderIconData = {width = 18, height = 18, offsetX = 2, offsetY = 7}
        },
    },

    [TARGET_UNIT_FRAME] =
    {
        neverHideStatusBar = true,
        showStatusInName = true,
        captionControlName = "Caption",
    },    
}

local function GetPlatformLayoutData(style)
    local layoutData = UNITFRAME_LAYOUT_DATA[style]
    if layoutData then
        -- Note: It is assumed that either all platforms are defined, or no platforms are defined.
        local platformKey = IsInGamepadPreferredMode() and "gamepad" or "keyboard"
        return layoutData[platformKey] or layoutData
    end
end

local FORCE_SHOW = true
local PREVENT_SHOW = false

local function SetUnitFrameTexture(frame, styleData, showOption)
    if(frame and styleData) then
        frame:SetTexture(styleData.texture)
        frame:SetDimensions(styleData.width, styleData.height)

        if(styleData.customAnchor) then
            styleData.customAnchor:Set(frame)
        end

        if(showOption == FORCE_SHOW) then
            frame:SetHidden(false) -- never toggles, this is the only chance this frame has of being shown
        end
    end
end

local function LayoutUnitFrameStatus(statusLabel, statusData, showStatus)
    if(statusLabel) then
        if(statusData) then
            statusData.anchor1:Set(statusLabel)
            statusData.anchor2:AddToControl(statusLabel)
            statusLabel:SetHeight(statusData.height)
        end
        statusLabel:SetHidden(not statusData)
    end
end

local function LayoutUnitFrameName(nameLabel, layoutData, indented)
    if(nameLabel and layoutData) then
        if(layoutData.nameAnchor and not indented) then
            layoutData.nameAnchor:Set(nameLabel)
        elseif(layoutData.indentedNameAnchor and indented) then
            layoutData.indentedNameAnchor:Set(nameLabel)
        end

        nameLabel:SetWrapMode(layoutData.nameWrapMode or TEXT_WRAP_MODE_TRUNCATE)

        local nameWidth = layoutData.nameWidth or 0

        if(indented) then
            nameLabel:SetWidth(layoutData.indentedNameWidth or nameWidth)
        else
            nameLabel:SetWidth(nameWidth)
        end
    end
end

local function DoUnitFrameLayout(unitFrame, style)
    local layoutData = GetPlatformLayoutData(style)
    if(layoutData) then
        unitFrame.neverHideStatusBar = layoutData.neverHideStatusBar

        if(layoutData.highPriorityBuffHighlight) then
            SetUnitFrameTexture(GetControl(unitFrame.frame, "HighPriorityBuffHighlight"), layoutData.highPriorityBuffHighlight.left, PREVENT_SHOW)
            SetUnitFrameTexture(GetControl(unitFrame.frame, "HighPriorityBuffHighlightRight"), layoutData.highPriorityBuffHighlight.right, PREVENT_SHOW)
            SetUnitFrameTexture(GetControl(unitFrame.frame, "HighPriorityBuffHighlightIcon"), layoutData.highPriorityBuffHighlight.icon, PREVENT_SHOW)

            -- These can't be created in XML because the OnInitialized handler doesn't run until the next frame, just initialize the animations here.
            ZO_AlphaAnimation:New(GetControl(unitFrame.frame, "HighPriorityBuffHighlight"))
            ZO_AlphaAnimation:New(GetControl(unitFrame.frame, "HighPriorityBuffHighlightIcon"))
        end

        LayoutUnitFrameName(unitFrame.nameLabel, layoutData)
        LayoutUnitFrameStatus(unitFrame.statusLabel, layoutData.statusData)

        -- NOTE: Level label is always custom and doesn't need to be managed with this anchoring system
    end
end

UnitFrame = ZO_Object:Subclass()

function UnitFrame:New(unitTag, anchors, showBarText, style)
    local newFrame = ZO_Object.New(self)
    local baseWindowName = style..unitTag
    local parent = ZO_UnitFrames

    if ZO_Group_IsGroupUnitTag(unitTag) then
        parent = ZO_UnitFramesGroups
    end

    local layoutData = GetPlatformLayoutData(style)
    if(not layoutData) then
        return
    end

    newFrame.frame = CreateControlFromVirtual(baseWindowName, parent, style)
    newFrame.style = style
    newFrame.hasTarget = false
    newFrame.unitTag = unitTag
    newFrame.dirty = true
    newFrame.animateShowHide = false
    newFrame.fadeComponents = {}
    newFrame.hiddenReasons = ZO_HiddenReasons:New()

    local nameControlName = layoutData.nameControlName or "Name"
    newFrame.nameLabel = newFrame:AddFadeComponent(nameControlName)

    newFrame.levelLabel = newFrame:AddFadeComponent("Level")

    if layoutData.captionControlName then
        newFrame.captionLabel = newFrame:AddFadeComponent(layoutData.captionControlName)
    end

    local statusControlName = layoutData.statusControlName or "Status"
    newFrame.statusLabel = newFrame:AddFadeComponent(statusControlName)

    local DONT_COLOR_RANK_ICON = false
    newFrame.rankIcon = newFrame:AddFadeComponent("RankIcon", DONT_COLOR_RANK_ICON)
    newFrame.assignmentIcon = newFrame:AddFadeComponent("AssignmentIcon", DONT_COLOR_RANK_ICON)
    newFrame.championIcon = newFrame:AddFadeComponent("ChampionIcon")
    newFrame.leftBracket = newFrame:AddFadeComponent("LeftBracket")
    newFrame.leftBracketGlow = GetControl(newFrame.frame, "LeftBracketGlow")
    newFrame.leftBracketUnderlay = GetControl(newFrame.frame, "LeftBracketUnderlay")
    newFrame.rightBracket = newFrame:AddFadeComponent("RightBracket")
    newFrame.rightBracketGlow = GetControl(newFrame.frame, "RightBracketGlow")
    newFrame.rightBracketUnderlay = GetControl(newFrame.frame, "RightBracketUnderlay")
    
    newFrame.showBarText = showBarText

    newFrame.healthBar = UnitFrameBar:New(baseWindowName.."Hp", newFrame.frame, showBarText, style, POWERTYPE_HEALTH)
    newFrame.healthBar:SetColor(POWERTYPE_HEALTH)

    newFrame.resourceBars = {}
    newFrame.resourceBars[POWERTYPE_HEALTH] = newFrame.healthBar

    newFrame.powerBars = {}
    newFrame.lastPowerType = 0
    newFrame.frame.m_unitTag = unitTag

    newFrame:SetAnchor(anchors)
    newFrame:ApplyVisualStyle()
    newFrame:RefreshVisible()

    return newFrame
end

function UnitFrame:ApplyVisualStyle()
    DoUnitFrameLayout(self, self.style)
    local frameTemplate = ZO_GetPlatformTemplate(self.style)
    ApplyTemplateToControl(self.frame, frameTemplate)

    local isLeader = IsUnitGroupLeader(self.unitTag)
    local isOnline = IsUnitOnline(self.unitTag)
    self:DoAlphaUpdate(IsUnitInGroupSupportRange(self.unitTag), isOnline, isLeader)
    self:UpdateDifficulty()

    local healthBar = self.healthBar
    local barData = GetPlatformBarStyle(healthBar.style, healthBar.mechanic)
    if barData.template then
        local barWidth = barData.centered and barData.barWidth/2 or barData.barWidth
        for i, control in ipairs(healthBar.barControls) do
            if self.style ~= TARGET_UNIT_FRAME then
                ApplyTemplateToControl(control, ZO_GetPlatformTemplate(barData.template))
            end

            barData.barAnchors[i]:Set(control)
            control:SetWidth(barWidth)
            control:SetHeight(barData.barHeight)
        end

        if #healthBar.barControls == 1 then
            local barAnchor2 = barData.barAnchors[2]
            if barAnchor2 then
                barAnchor2:AddToControl(healthBar.barControls[1])
            end
        end
    end
    local statusBackground = GetControl(self.frame, "Background1")
    if statusBackground then
        statusBackground:SetHidden(not isOnline and barData.hideBgIfOffline)
    end

    local font = GetPlatformBarFont()
    if healthBar.leftText then
        healthBar.leftText:SetFont(font)
    end
    if healthBar.rightText then
        healthBar.rightText:SetFont(font)
    end

    if self.attributeVisualizer then
        self.attributeVisualizer:ApplyPlatformStyle()
    end

    self:RefreshControls()
end

function UnitFrame:SetAnimateShowHide(animate)
    self.animateShowHide = animate
end

function UnitFrame:AddFadeComponent(name, setColor)
    local control = GetControl(self.frame, name)
    if control then
        control.setColor = setColor ~= false
        table.insert(self.fadeComponents, control)
    end
    return control
end

function UnitFrame:SetTextIndented(isIndented)
    local layoutData = GetPlatformLayoutData(self.style)
    if layoutData then
        LayoutUnitFrameName(self.nameLabel, layoutData, isIndented)
        LayoutUnitFrameStatus(self.statusLabel, layoutData.statusData, isIndented)
    end
end

function UnitFrame:SetAnchor(anchors)
    self.frame:ClearAnchors()

    if(type(anchors) == "table" and #anchors >= 2) then
        anchors[1]:Set(self.frame)
        anchors[2]:AddToControl(self.frame)
    else
        anchors:Set(self.frame)
    end
end

function UnitFrame:SetBuffTracker(buffTracker)
    self.buffTracker = buffTracker
end

function UnitFrame:SetHiddenForReason(reason, hidden)
    if(self.hiddenReasons:SetHiddenForReason(reason, hidden)) then
        local INSTANT = true
        self:RefreshVisible(INSTANT)
    end
end

function UnitFrame:SetHasTarget(hasTarget)
    self.hasTarget = hasTarget
    local ANIMATED = false
    self:RefreshVisible(ANIMATED)
end

function UnitFrame:ComputeHidden()
    if not self.hasTarget then
        return true
    end

    return self.hiddenReasons:IsHidden()
end

function UnitFrame:RefreshVisible(instant)
    local hidden = self:ComputeHidden()
    if hidden ~= self.hidden then
        self.hidden = hidden
        if not hidden and self.dirty then
            self.dirty = nil
            self:RefreshControls()
        end

        if self.animateShowHide and not instant then
            if not self.showHideTimeline then
                self.showHideTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_UnitFrameFadeAnimation", self.frame)
            end
            if hidden then
                if self.showHideTimeline:IsPlaying() then
                    self.showHideTimeline:PlayBackward()
                else
                    self.showHideTimeline:PlayFromEnd()
                end
            else
                if self.showHideTimeline:IsPlaying() then
                    self.showHideTimeline:PlayForward()
                else
                    self.showHideTimeline:PlayFromStart()
                end
            end
        else
            if self.showHideTimeline then
                self.showHideTimeline:Stop()
            end
            self.frame:SetHidden(hidden)
        end

        if self.buffTracker then
            self.buffTracker:SetDisabled(hidden)
        end
    end
end

function UnitFrame:RefreshControls()
    if self.hidden then
        self.dirty = true
    else
        if self.hasTarget then
            self:UpdateName()
            self:UpdateUnitReaction()
            self:UpdateLevel()
            self:UpdateCaption()

            local health, maxHealth = GetUnitPower(self.unitTag, POWERTYPE_HEALTH)
            self.healthBar:Update(POWERTYPE_HEALTH, health, maxHealth, FORCE_INIT)

            for i = 1, NUM_POWER_POOLS do
                local powerType, cur, max = GetUnitPowerInfo(self.unitTag, i)
                self:UpdatePowerBar(i, powerType, cur, max, FORCE_INIT)
            end

            self:UpdateStatus(IsUnitDead(self.unitTag), IsUnitOnline(self.unitTag))
            self:UpdateRank()
            self:UpdateAssignment()
            self:UpdateDifficulty()
            self:DoAlphaUpdate(IsUnitInGroupSupportRange(self.unitTag), IsUnitOnline(self.unitTag), IsUnitGroupLeader(self.unitTag))
        end
    end
end

function UnitFrame:RefreshUnit(unitChanged)
    local validTarget = DoesUnitExist(self.unitTag)
    if validTarget then
        if(self.unitTag == "reticleovertarget") then
            local localPlayerIsTarget = AreUnitsEqual("player", "reticleover")
            validTarget = UnitFrames:IsTargetOfTargetEnabled() and not localPlayerIsTarget
        end
    end

    if unitChanged or self.hasTarget ~= validTarget then
        MenuOwnerClosed(self.frame)

        if self.castBar then
            self.castBar:UpdateAfterUnitChange()
        end
    end

    self:SetHasTarget(validTarget)
end

function UnitFrame:SetBarsHidden(hidden)
    self.healthBar:Hide(hidden)
end

function UnitFrame:IsHidden()
    return self.hidden
end

function UnitFrame:GetUnitTag()
    return self.frame.m_unitTag
end

function UnitFrame:GetPrimaryControl()
    return self.frame
end

function UnitFrame:DoAlphaUpdate(isNearby, isOnline, isLeader)
    -- Don't fade out just the frame, because that needs to appear correctly (along with BG, etc...)
    -- Just make the status bars and any text on the frame fade out.
    local color
    if self.unitTag == "reticleover" then
        color = ZO_SELECTED_TEXT
    else
        if isLeader then
            color = ZO_HIGHLIGHT_TEXT
        else
            color = ZO_NORMAL_TEXT
        end
    end

    local alphaValue = isNearby and FULL_ALPHA_VALUE or FADED_ALPHA_VALUE
    self.healthBar:SetAlpha(alphaValue)

    for i = 1, #self.fadeComponents do
        local fadeComponent = self.fadeComponents[i]
        if fadeComponent.setColor then
            fadeComponent:SetColor(color:UnpackRGBA())
        end
        fadeComponent:SetAlpha(alphaValue)
    end
end

function UnitFrame:GetBuffTracker()
    return self.buffTracker
end

function UnitFrame:UpdatePowerBar(index, powerType, cur, max, forceInit)
    -- Should this bar type ever be displayed?
    if(untrackedBarTypes[powerType] ~= nil or not IsValidBarStyle(self.style, powerType)) then
        return
    end

    local currentBar = self.powerBars[index]

    if(currentBar == nil) then
        self.powerBars[index] = UnitFrameBar:New(self.frame:GetName().."PowerBar"..index, self.frame, self.showBarText, self.style, powerType)
        currentBar = self.powerBars[index]
        currentBar:SetColor(powerType)
        self.resourceBars[powerType] = currentBar
    end

    if(currentBar ~= nil) then
        currentBar:Update(powerType, cur, max, forceInit)

        currentBar:Hide(powerType == POWERTYPE_INVALID)
    end
end

-- Global to allow for outside manipulation
ZO_UNIT_FRAMES_SHOW_LEVEL_REACTIONS =
{
    [UNIT_REACTION_PLAYER_ALLY] = true,
}

local HIDE_LEVEL_TYPES =
{
    [UNIT_TYPE_SIEGEWEAPON] = true,
    [UNIT_TYPE_INTERACTFIXTURE] = true,
    [UNIT_TYPE_INTERACTOBJ] = true,
    [UNIT_TYPE_SIMPLEINTERACTFIXTURE] = true,
    [UNIT_TYPE_SIMPLEINTERACTOBJ] = true,
}

function UnitFrame:ShouldShowLevel()
    --show level for players and non-friendly NPCs
    local unitTag = self:GetUnitTag()
    if IsUnitPlayer(unitTag) then
        return true
    elseif IsUnitInvulnerableGuard(unitTag) then
        return false
    else
        local unitType = GetUnitType(unitTag)
        if HIDE_LEVEL_TYPES[unitType] then
            return false
        else
            local unitReaction = GetUnitReaction(unitTag)
            if ZO_UNIT_FRAMES_SHOW_LEVEL_REACTIONS[unitReaction] then
                return true
            end
        end
    end
end

function UnitFrame:UpdateLevel()
    local showLevel = self:ShouldShowLevel()
    local unitLevel
    local isChampion = IsUnitChampion(self:GetUnitTag())
    if isChampion then
        unitLevel = GetUnitEffectiveChampionPoints(self:GetUnitTag())
    else
        unitLevel = GetUnitLevel(self:GetUnitTag())
    end

    if(self.levelLabel) then
        if(showLevel and unitLevel > 0) then
            self.levelLabel:SetHidden(false)
            self.levelLabel:SetText(tostring(unitLevel))
            self.nameLabel:SetAnchor(TOPLEFT, self.levelLabel, TOPRIGHT, 10, 0)
        else
            self.levelLabel:SetHidden(true)
            self.nameLabel:SetAnchor(TOPLEFT)
        end
    end

    if(self.championIcon) then
        if showLevel and isChampion then
            self.championIcon:SetHidden(false)
        else
            self.championIcon:SetHidden(true)
        end
    end
end

function UnitFrame:UpdateRank()
    if(self.rankIcon) then
        local unitTag = self:GetUnitTag()
        local rank, subRank = GetUnitAvARank(unitTag)

        local showRank = rank ~= 0 or IsUnitPlayer(unitTag)
        if showRank then
            local rankIconFile = GetAvARankIcon(rank)
            self.rankIcon:SetTexture(rankIconFile)

            local alliance = GetUnitAlliance(unitTag)
            self.rankIcon:SetColor(GetAllianceColor(alliance):UnpackRGBA())
        end
        self.rankIcon:SetHidden(not showRank)
    end
end

function UnitFrame:UpdateAssignment()
    if self.assignmentIcon then
        local unitTag = self:GetUnitTag()
        local assignmentTexture = nil
        if IsActiveWorldBattleground() then
            local battlegroundAlliance = GetUnitBattlegroundAlliance(unitTag)
            if battlegroundAlliance ~= BATTLEGROUND_ALLIANCE_NONE then
                assignmentTexture = GetBattlegroundTeamIcon(battlegroundAlliance)
            end
        else
            local selectedRole = GetGroupMemberSelectedRole(unitTag)
            if selectedRole ~= LFG_ROLE_INVALID then
                assignmentTexture = GetRoleIcon(selectedRole)
            end
        end

        if assignmentTexture then
            self.assignmentIcon:SetTexture(assignmentTexture)
        end
        self.assignmentIcon:SetHidden(assignmentTexture == nil)
    end
end

local DIFFICULTY_BRACKET_LEFT_TEXTURE =
{
    [MONSTER_DIFFICULTY_NORMAL] = "EsoUI/Art/UnitFrames/targetUnitFrame_bracket_level2_left.dds",
    [MONSTER_DIFFICULTY_HARD] = "EsoUI/Art/UnitFrames/targetUnitFrame_bracket_level3_left.dds",
    [MONSTER_DIFFICULTY_DEADLY] = "EsoUI/Art/UnitFrames/targetUnitFrame_bracket_level4_left.dds",
}

local DIFFICULTY_BRACKET_RIGHT_TEXTURE =
{
    [MONSTER_DIFFICULTY_NORMAL] = "EsoUI/Art/UnitFrames/targetUnitFrame_bracket_level2_right.dds",
    [MONSTER_DIFFICULTY_HARD] = "EsoUI/Art/UnitFrames/targetUnitFrame_bracket_level3_right.dds",
    [MONSTER_DIFFICULTY_DEADLY] = "EsoUI/Art/UnitFrames/targetUnitFrame_bracket_level4_right.dds",
}

local DIFFICULTY_BRACKET_GLOW_LEFT_TEXTURE =
{
    [MONSTER_DIFFICULTY_NORMAL] = "EsoUI/Art/UnitFrames/targetUnitFrame_glowOverlay_level2_left.dds",
    [MONSTER_DIFFICULTY_HARD] = "EsoUI/Art/UnitFrames/targetUnitFrame_glowOverlay_level3_left.dds",
    [MONSTER_DIFFICULTY_DEADLY] = "EsoUI/Art/UnitFrames/targetUnitFrame_glowOverlay_level4_left.dds",    
}

local DIFFICULTY_BRACKET_GLOW_RIGHT_TEXTURE =
{
    [MONSTER_DIFFICULTY_NORMAL] = "EsoUI/Art/UnitFrames/targetUnitFrame_glowOverlay_level2_right.dds",
    [MONSTER_DIFFICULTY_HARD] = "EsoUI/Art/UnitFrames/targetUnitFrame_glowOverlay_level3_right.dds",
    [MONSTER_DIFFICULTY_DEADLY] = "EsoUI/Art/UnitFrames/targetUnitFrame_glowOverlay_level4_right.dds",    
}

local GAMEPAD_DIFFICULTY_BRACKET_TEXTURE =
{
    [MONSTER_DIFFICULTY_NORMAL] = "EsoUI/Art/UnitFrames/Gamepad/gp_targetUnitFrame_bracket_level2.dds",
    [MONSTER_DIFFICULTY_HARD] = "EsoUI/Art/UnitFrames/Gamepad/gp_targetUnitFrame_bracket_level3.dds",
    [MONSTER_DIFFICULTY_DEADLY] = "EsoUI/Art/UnitFrames/Gamepad/gp_targetUnitFrame_bracket_level4.dds",
}

function UnitFrame:SetPlatformDifficultyTextures(difficulty)
    if IsInGamepadPreferredMode() then
        local texture = GAMEPAD_DIFFICULTY_BRACKET_TEXTURE[difficulty]
        self.leftBracket:SetTexture(texture)
        self.rightBracket:SetTexture(texture)
        self.leftBracketGlow:SetHidden(true)
        self.rightBracketGlow:SetHidden(true)
    else
        self.leftBracket:SetTexture(DIFFICULTY_BRACKET_LEFT_TEXTURE[difficulty])
        self.rightBracket:SetTexture(DIFFICULTY_BRACKET_RIGHT_TEXTURE[difficulty])
        self.leftBracketGlow:SetTexture(DIFFICULTY_BRACKET_GLOW_LEFT_TEXTURE[difficulty])
        self.rightBracketGlow:SetTexture(DIFFICULTY_BRACKET_GLOW_RIGHT_TEXTURE[difficulty])
        self.leftBracketGlow:SetHidden(false)
        self.rightBracketGlow:SetHidden(false)
    end
end

function UnitFrame:UpdateDifficulty()
    if self.leftBracket then
        local difficulty = GetUnitDifficulty(self:GetUnitTag())

        --show difficulty for neutral and hostile NPCs
        local unitReaction = GetUnitReaction(self:GetUnitTag())
        local showsDifficulty = (difficulty > MONSTER_DIFFICULTY_EASY) and (unitReaction == UNIT_REACTION_NEUTRAL or unitReaction == UNIT_REACTION_HOSTILE)

        self.leftBracket:SetHidden(not showsDifficulty)
        self.rightBracket:SetHidden(not showsDifficulty)
        self.leftBracketUnderlay:SetHidden(true)
        self.rightBracketUnderlay:SetHidden(true)

        if showsDifficulty then
            self:SetPlatformDifficultyTextures(difficulty)

            if difficulty == MONSTER_DIFFICULTY_DEADLY and not IsInGamepadPreferredMode() then
                self.leftBracketUnderlay:SetHidden(false)
                self.rightBracketUnderlay:SetHidden(false)
            end

            if unitReaction == UNIT_REACTION_HOSTILE then
                TriggerTutorial(TUTORIAL_TRIGGER_COMBAT_MONSTER_DIFFICULTY)
            end
        end
    end
end

function UnitFrame:UpdateUnitReaction()
    local unitTag = self:GetUnitTag()

    if self.nameLabel then
        if ZO_Group_IsGroupUnitTag(unitTag) then
            local currentNameAlpha = self.nameLabel:GetControlAlpha()
            local r, g, b = GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_HIGHLIGHT)
            self.nameLabel:SetColor(r, g, b, currentNameAlpha)
        end
    end
end

function UnitFrame:UpdateName()
    if self.nameLabel then
        local name
        local tag = self.unitTag
        if IsUnitPlayer(tag) then
            name = ZO_GetPrimaryPlayerNameFromUnitTag(tag)
        else
            name = GetUnitName(tag)
        end
        self.nameLabel:SetText(name)
    end
end

function UnitFrame:UpdateCaption()
    local captionLabel = self.captionLabel
    if captionLabel then
        local caption = ""
        local unitTag = self:GetUnitTag()
        if IsUnitPlayer(unitTag) then
            caption = ZO_GetSecondaryPlayerNameWithTitleFromUnitTag(unitTag)
        else
            local unitCaption = GetUnitCaption(unitTag)
            if unitCaption then
                caption = zo_strformat(SI_TOOLTIP_UNIT_CAPTION, unitCaption)
            end
        end

        local hideCaption = caption == ""
        captionLabel:SetHidden(hideCaption)
        captionLabel:SetText(caption) -- still set the caption text when empty so we collapse the label for anything anchoring off the bottom of it
    end
end

function UnitFrame:UpdateStatus(isDead, isOnline)
    local statusLabel = self.statusLabel
    if(statusLabel) then
        local hideBars = (isOnline == false) or (isDead == true)
        self:SetBarsHidden(hideBars and not self.neverHideStatusBar)
        local layoutData = GetPlatformLayoutData(self.style)
        statusLabel:SetHidden(not hideBars or not layoutData.statusData)

        local statusBackground = GetControl(self.frame, "Background1")
        if statusBackground then
            statusBackground:SetHidden(not isOnline and layoutData.hideHealthBgIfOffline)
        end

        if(layoutData and layoutData.showStatusInName) then
            if(not isOnline) then
                statusLabel:SetText("("..GetString(SI_UNIT_FRAME_STATUS_OFFLINE)..")")
            elseif(isDead) then
                statusLabel:SetText("("..GetString(SI_UNIT_FRAME_STATUS_DEAD)..")")
            else
                statusLabel:SetText("")
            end
        else
            if(not isOnline) then
                statusLabel:SetText(GetString(SI_UNIT_FRAME_STATUS_OFFLINE))
            elseif(isDead) then
                statusLabel:SetText(GetString(SI_UNIT_FRAME_STATUS_DEAD))
            else
                statusLabel:SetText("")
            end
        end
    end
end

function UnitFrame:SetBarMouseInside(inside)
    self.healthBar:SetMouseInside(inside)
    for powerIndex, powerBar in pairs(self.powerBars) do
        powerBar:SetMouseInside(inside)
    end
end

function UnitFrame:HandleMouseEnter()
    self:SetBarMouseInside(true)
end

function UnitFrame:HandleMouseExit()
    self:SetBarMouseInside(false)
end

function UnitFrame:SetBarTextMode(alwaysShow)
    self.healthBar:SetBarTextMode(alwaysShow)
    for powerIndex, powerBar in pairs(self.powerBars) do
        powerBar:SetBarTextMode(alwaysShow)
    end
end

function UnitFrame:CreateAttributeVisualizer(soundTable)
    if not self.attributeVisualizer then
        self.frame.barControls = self.healthBar:GetBarControls()
        self.attributeVisualizer = ZO_UnitAttributeVisualizer:New(self:GetUnitTag(), soundTable, self.frame)
    end
    return self.attributeVisualizer
end

--[[
    UnitFrame Utility functions
--]]

function ZO_UnitFrames_UpdateWindow(unitTag, unitChanged)
    local unitFrame = UnitFrames:GetFrame(unitTag)
    if unitFrame then
        unitFrame:RefreshUnit(unitChanged)
        unitFrame:RefreshControls()
    end
end

local function CreateGroupAnchorFrames()
    local constants = GetPlatformConstants()

    -- Create small group anchor frame
    local smallFrame = CreateControlFromVirtual("ZO_SmallGroupAnchorFrame", ZO_UnitFramesGroups, "ZO_GroupFrameAnchor")
    smallFrame:SetDimensions(constants.GROUP_FRAME_SIZE_X, (constants.GROUP_FRAME_SIZE_Y + constants.GROUP_FRAME_PAD_Y) * SMALL_GROUP_SIZE_THRESHOLD)
    smallFrame:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, constants.GROUP_FRAME_BASE_OFFSET_X, constants.GROUP_FRAME_BASE_OFFSET_Y)

    -- Create raid group anchor frames, these are positioned at the default locations
    for i = 1, NUM_SUBGROUPS
    do
        local raidFrame = CreateControlFromVirtual("ZO_LargeGroupAnchorFrame"..i, ZO_UnitFramesGroups, "ZO_RaidFrameAnchor")
        raidFrame:SetDimensions(constants.RAID_FRAME_ANCHOR_CONTAINER_WIDTH, constants.RAID_FRAME_ANCHOR_CONTAINER_HEIGHT)

        GetControl(raidFrame, "GroupName"):SetText(zo_strformat(SI_GROUP_SUBGROUP_LABEL, i))

        local x, y = GetGroupAnchorFrameOffsets(i, constants.GROUP_STRIDE, constants)
        raidFrame:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, x, y)
    end
end

local function UpdateLeaderIndicator()
    ZO_UnitFrames_Leader:SetHidden(true)

    for i = 1, GROUP_SIZE_MAX do
        local unitTag = GetGroupUnitTagByIndex(i)
        local unitFrame = unitTag and UnitFrames:GetFrame(unitTag)

        if unitFrame then
            if IsUnitGroupLeader(unitTag) then
                ZO_UnitFrames_Leader:ClearAnchors()
                local layoutData = GetPlatformLayoutData(unitFrame.style)
                if layoutData.leaderIconData then
                    local data = layoutData.leaderIconData
                    ZO_UnitFrames_Leader:SetDimensions(data.width, data.height)
                    ZO_UnitFrames_Leader:SetAnchor(TOPLEFT, unitFrame.frame, TOPLEFT, data.offsetX, data.offsetY)
                    unitFrame:SetTextIndented(true)
                else
                    unitFrame:SetTextIndented(false)
                end

                ZO_UnitFrames_Leader:SetParent(unitFrame.frame)
                ZO_UnitFrames_Leader:SetHidden(not layoutData.leaderIconData)
            else
                unitFrame:SetTextIndented(false)
            end

            unitFrame:UpdateUnitReaction()
        end
    end
end

local function DoGroupUpdate(eventCode)
    UpdateLeaderIndicator()
    UnitFrames:UpdateGroupAnchorFrames()
end

local function GetCastBar(unitTag)
    local frame = UnitFrames:GetFrame(unitTag)
    return frame and frame.castBar or nil
end

local unitTypesWhoUseCastInfo =
{
    [UNIT_REACTION_HOSTILE] = true,
    [UNIT_REACTION_NEUTRAL] = true,
}

local TARGET_ATTRIBUTE_VISUALIZER_SOUNDS = 
{
    [STAT_HEALTH_MAX] = 
    {
        [ATTRIBUTE_BAR_STATE_NORMAL]    = SOUNDS.UAV_MAX_HEALTH_NORMAL_TARGET,
        [ATTRIBUTE_BAR_STATE_EXPANDED]  = SOUNDS.UAV_MAX_HEALTH_INCREASED_TARGET,
        [ATTRIBUTE_BAR_STATE_SHRUNK]    = SOUNDS.UAV_MAX_HEALTH_DECREASED_TARGET,
    },
    [STAT_MAGICKA_MAX] = 
    {
        [ATTRIBUTE_BAR_STATE_NORMAL]    = SOUNDS.UAV_MAX_MAGICKA_NORMAL_TARGET,
        [ATTRIBUTE_BAR_STATE_EXPANDED]  = SOUNDS.UAV_MAX_MAGICKA_INCREASED_TARGET,
        [ATTRIBUTE_BAR_STATE_SHRUNK]    = SOUNDS.UAV_MAX_MAGICKA_DECREASED_TARGET,
    },
    [STAT_STAMINA_MAX] = 
    {
        [ATTRIBUTE_BAR_STATE_NORMAL]    = SOUNDS.UAV_MAX_STAMINA_NORMAL_TARGET,
        [ATTRIBUTE_BAR_STATE_EXPANDED]  = SOUNDS.UAV_MAX_STAMINA_INCREASED_TARGET,
        [ATTRIBUTE_BAR_STATE_SHRUNK]    = SOUNDS.UAV_MAX_STAMINA_DECREASED_TARGET,
    },
    [STAT_HEALTH_REGEN_COMBAT] = 
    {
        [STAT_STATE_INCREASE_GAINED]    = SOUNDS.UAV_INCREASED_HEALTH_REGEN_ADDED_TARGET,
        [STAT_STATE_INCREASE_LOST]      = SOUNDS.UAV_INCREASED_HEALTH_REGEN_LOST_TARGET,
        [STAT_STATE_DECREASE_GAINED]    = SOUNDS.UAV_DECREASED_HEALTH_REGEN_ADDED_TARGET,
        [STAT_STATE_DECREASE_LOST]      = SOUNDS.UAV_DECREASED_HEALTH_REGEN_LOST_TARGET,
    },
    [STAT_MAGICKA_REGEN_COMBAT] = 
    {
        [STAT_STATE_INCREASE_GAINED]    = SOUNDS.UAV_INCREASED_MAGICKA_REGEN_ADDED_TARGET,
        [STAT_STATE_INCREASE_LOST]      = SOUNDS.UAV_INCREASED_MAGICKA_REGEN_LOST_TARGET,
        [STAT_STATE_DECREASE_GAINED]    = SOUNDS.UAV_DECREASED_MAGICKA_REGEN_ADDED_TARGET,
        [STAT_STATE_DECREASE_LOST]      = SOUNDS.UAV_DECREASED_MAGICKA_REGEN_LOST_TARGET,
    },
    [STAT_STAMINA_REGEN_COMBAT] = 
    {
        [STAT_STATE_INCREASE_GAINED]    = SOUNDS.UAV_INCREASED_STAMINA_REGEN_ADDED_TARGET,
        [STAT_STATE_INCREASE_LOST]      = SOUNDS.UAV_INCREASED_STAMINA_REGEN_LOST_TARGET,
        [STAT_STATE_DECREASE_GAINED]    = SOUNDS.UAV_DECREASED_STAMINA_REGEN_ADDED_TARGET,
        [STAT_STATE_DECREASE_LOST]      = SOUNDS.UAV_DECREASED_STAMINA_REGEN_LOST_TARGET,
    },
    [STAT_ARMOR_RATING] = 
    {
        [STAT_STATE_INCREASE_GAINED]    = SOUNDS.UAV_INCREASED_ARMOR_ADDED_TARGET,
        [STAT_STATE_INCREASE_LOST]      = SOUNDS.UAV_INCREASED_ARMOR_LOST_TARGET,
        [STAT_STATE_DECREASE_GAINED]    = SOUNDS.UAV_DECREASED_ARMOR_ADDED_TARGET,
        [STAT_STATE_DECREASE_LOST]      = SOUNDS.UAV_DECREASED_ARMOR_LOST_TARGET,
    },
    [STAT_POWER] = 
    {
        [STAT_STATE_INCREASE_GAINED]    = SOUNDS.UAV_INCREASED_POWER_ADDED_TARGET,
        [STAT_STATE_INCREASE_LOST]      = SOUNDS.UAV_INCREASED_POWER_LOST_TARGET,
        [STAT_STATE_DECREASE_GAINED]    = SOUNDS.UAV_DECREASED_POWER_ADDED_TARGET,
        [STAT_STATE_DECREASE_LOST]      = SOUNDS.UAV_DECREASED_POWER_LOST_TARGET,
    },
    [STAT_MITIGATION] =
    {
        [STAT_STATE_IMMUNITY_GAINED]    = SOUNDS.UAV_IMMUNITY_ADDED_TARGET,
        [STAT_STATE_IMMUNITY_LOST]      = SOUNDS.UAV_IMMUNITY_LOST_TARGET,
        [STAT_STATE_SHIELD_GAINED]      = SOUNDS.UAV_DAMAGE_SHIELD_ADDED_TARGET,
        [STAT_STATE_SHIELD_LOST]        = SOUNDS.UAV_DAMAGE_SHIELD_LOST_TARGET,
        [STAT_STATE_POSSESSION_APPLIED] = SOUNDS.UAV_POSSESSION_APPLIED_TARGET,
        [STAT_STATE_POSSESSION_REMOVED] = SOUNDS.UAV_POSSESSION_REMOVED_TARGET,
        [STAT_STATE_TRAUMA_GAINED]      = SOUNDS.UAV_TRAUMA_ADDED_TARGET,
        [STAT_STATE_TRAUMA_LOST]        = SOUNDS.UAV_TRAUMA_LOST_TARGET,
    },
}

local function CreateTargetFrame()
    local targetFrameAnchor = ZO_Anchor:New(TOP, GuiRoot, TOP, 0, 88)
    local targetFrame = UnitFrames:CreateFrame("reticleover", targetFrameAnchor, HIDE_BAR_TEXT, "ZO_TargetUnitFrame")
    targetFrame:SetAnimateShowHide(true)
    local visualizer = targetFrame:CreateAttributeVisualizer(TARGET_ATTRIBUTE_VISUALIZER_SOUNDS)

    visualizer:AddModule(ZO_UnitVisualizer_ArrowRegenerationModule:New())

    VISUALIZER_ANGLE_NORMAL_WIDTH = 281
    VISUALIZER_ANGLE_EXPANDED_WIDTH = 362
    VISUALIZER_ANGLE_SHRUNK_WIDTH = 180
    visualizer:AddModule(ZO_UnitVisualizer_ShrinkExpandModule:New(VISUALIZER_ANGLE_NORMAL_WIDTH, VISUALIZER_ANGLE_EXPANDED_WIDTH, VISUALIZER_ANGLE_SHRUNK_WIDTH))

    VISUALIZER_ANGLE_ARMOR_DAMAGE_LAYOUT_DATA =
    {
        type = "Angle",
        increasedArmorBgContainerTemplate = "ZO_IncreasedArmorBgContainerAngle",
        increasedArmorFrameContainerTemplate = "ZO_IncreasedArmorFrameContainerAngle",
        decreasedArmorOverlayContainerTemplate = "ZO_DecreasedArmorOverlayContainerAngle",
        increasedPowerGlowTemplate = "ZO_IncreasedPowerGlowAngle",
        increasedArmorOffsets = 
        {
            keyboard = 
            {
                top = -7,
                bottom = 8,
                left = -15,
                right = 15,
            },
            gamepad = 
            {
                top = -8,
                bottom = 9,
                left = -12,
                right = 12, 
            }
        }
    }

    visualizer:AddModule(ZO_UnitVisualizer_ArmorDamage:New(VISUALIZER_ANGLE_ARMOR_DAMAGE_LAYOUT_DATA))

    VISUALIZER_ANGLE_UNWAVERING_LAYOUT_DATA =
    {
        overlayContainerTemplate = "ZO_UnwaveringOverlayContainerAngle",
        overlayOffsets = 
        {
            keyboard = 
            {
                top = 2,
                bottom = -3,
                left = 6,
                right = -7,
            },
            gamepad = 
            {
                top = 4,
                bottom = -2,
                left = 8,
                right = -8, 
            }
        }

    }
    visualizer:AddModule(ZO_UnitVisualizer_UnwaveringModule:New(VISUALIZER_ANGLE_UNWAVERING_LAYOUT_DATA))

    VISUALIZER_ANGLE_POSSESSION_LAYOUT_DATA =
    {
        type = "Angle",
        overlayContainerTemplate = "ZO_PossessionOverlayContainerAngle",
        possessionHaloGlowTemplate   = "ZO_PossessionHaloGlowAngle",
        overlayLeftOffset = 8,
        overlayTopOffset = 3,
        overlayRightOffset = -8,
        overlayBottomOffset = -3,
    }
    visualizer:AddModule(ZO_UnitVisualizer_PossessionModule:New(VISUALIZER_ANGLE_POSSESSION_LAYOUT_DATA))

    VISUALIZER_ANGLE_POWER_SHIELD_LAYOUT_DATA =
    {
        barLeftOverlayTemplate = "ZO_PowerShieldBarLeftOverlayAngle",
        barRightOverlayTemplate = "ZO_PowerShieldBarRightOverlayAngle",
    }
    visualizer:AddModule(ZO_UnitVisualizer_PowerShieldModule:New(VISUALIZER_ANGLE_POWER_SHIELD_LAYOUT_DATA))

    ZO_UnitFrames_UpdateWindow("reticleover", UNIT_CHANGED)

    CALLBACK_MANAGER:FireCallbacks("TargetFrameCreated", targetFrame)
end

local function CreateGroupMember(frameIndex, unitTag, groupSize)
    if(frameIndex == nil) then return end

    local frameStyle = "ZO_GroupUnitFrame"
    if(groupSize > SMALL_GROUP_SIZE_THRESHOLD) then
        frameStyle = "ZO_RaidUnitFrame"
    end

    local anchor = GetGroupFrameAnchor(frameIndex, groupSize)
    local frame = UnitFrames:CreateFrame(unitTag, anchor, HIDE_BAR_TEXT, frameStyle)
    frame:SetHiddenForReason("disabled", false)

    ZO_UnitFrames_UpdateWindow(unitTag, UNIT_CHANGED)
end

local function CreateGroupsAfter(startIndex)
    local groupSize = GetGroupSize()

    for i = startIndex, GROUP_SIZE_MAX do
        local unitTag = GetGroupUnitTagByIndex(i)

        if unitTag then
            CreateGroupMember(i, unitTag, groupSize)
        end
    end

    DoGroupUpdate()
end

local function CreateGroups()
    CreateGroupsAfter(1)
end

-- Utility to update the style of the current group frames creating a new frame for the unitTag if necessary,
-- hiding frames that are no longer applicable, and creating new frames of the correct style if the group size
-- goes above or below the "small group" or "raid group" thresholds.
local function UpdateGroupFrameStyle(groupIndex)
    local groupSize = GetGroupSize()
    local oldGroupSize = UnitFrames.groupSize

    local oldLargeGroup = (oldGroupSize ~= nil) and (oldGroupSize > SMALL_GROUP_SIZE_THRESHOLD);
    local newLargeGroup = groupSize > SMALL_GROUP_SIZE_THRESHOLD;

    UnitFrames:SetGroupSize(groupSize)

    -- In cases where no UI has been setup, the group changes between large and small group sizes, or when
    --  members are removed, we need to run a full update of the UI. These could also be optimized to only
    --  run partial updates if more performance is needed.
    if (oldGroupSize == nil) or (oldLargeGroup ~= newLargeGroup) or (oldGroupSize > groupSize) then
        -- Create all the appropriate frames for the new group member, or in the case of a unit_destroyed
        -- create the small group versions.
        UnitFrames:DisableGroupAndRaidFrames()
        CreateGroups()
    else
        -- Only update the frames of the unit being changed, and those after it in the list for performance
        --  reasons.
        CreateGroupsAfter(groupIndex)
    end
end

local function RefreshUnitFrames()
    if UnitFrames:GetIsDirty() then
        UpdateGroupFrameStyle(UnitFrames:GetFirstDirtyGroupIndex())
        UnitFrames:ClearDirty()
    end
end

local function ReportUnitChanged(unitTag)
    local groupIndex = GetGroupIndexByUnitTag(unitTag)
    UnitFrames:SetGroupIndexDirty(groupIndex)
end

local function SetAnchorOffsets(control, offsetX, offsetY)
    local isValid, point, target, relPoint = control:GetAnchor(0)
    if isValid then
        control:SetAnchor(point, target, relPoint, offsetX, offsetY)
    end
end

local function UpdateGroupFramesVisualStyle()
    local constants = GetPlatformConstants()

    -- Note: Small group anchor frame is currently the same for all platforms.
    local groupFrame = ZO_SmallGroupAnchorFrame
    groupFrame:SetDimensions(constants.GROUP_FRAME_SIZE_X, (constants.GROUP_FRAME_SIZE_Y + constants.GROUP_FRAME_PAD_Y) * SMALL_GROUP_SIZE_THRESHOLD)
    SetAnchorOffsets(groupFrame, constants.GROUP_FRAME_BASE_OFFSET_X, constants.GROUP_FRAME_BASE_OFFSET_Y)

    -- Raid group anchor frames.
    local raidTemplate = ZO_GetPlatformTemplate("ZO_RaidFrameAnchor")
    for i = 1, NUM_SUBGROUPS do
        local raidFrame = GetControl("ZO_LargeGroupAnchorFrame"..i)
        ApplyTemplateToControl(raidFrame, raidTemplate)

        -- For some reason, the ModifyTextType attribute on the template isn't being applied to the existing text on the label.
        -- Clearing and setting the text again seems to reapply the ModifyTextType attribute.
        local groupNameControl = GetControl(raidFrame, "GroupName")
        groupNameControl:SetText("")
        
        if constants.SHOW_GROUP_LABELS then
            groupNameControl:SetText(zo_strformat(SI_GROUP_SUBGROUP_LABEL, i))
        end

        raidFrame:SetDimensions(constants.RAID_FRAME_ANCHOR_CONTAINER_WIDTH, constants.RAID_FRAME_ANCHOR_CONTAINER_HEIGHT)
        local x, y = GetGroupAnchorFrameOffsets(i, constants.GROUP_STRIDE, constants)
        SetAnchorOffsets(raidFrame, x, y)
    end

    -- Update all UnitFrame anchors.
    local groupSize = GetGroupSize()
    for i = 1, GROUP_SIZE_MAX do
        local unitTag = GetGroupUnitTagByIndex(i)
        if unitTag then
            local unitFrame = UnitFrames:GetFrame(unitTag)
            local anchor = GetGroupFrameAnchor(i, groupSize)
            unitFrame:SetAnchor(anchor)
        end
    end

    -- Update the Group Leader Icon Texture
    ZO_UnitFrames_LeaderIcon:SetTexture(constants.GROUP_LEADER_ICON)
end

function UnitFrame_HandleMouseReceiveDrag(frame)
    if GetCursorContentType() ~= MOUSE_CONTENT_EMPTY then
        PlaceInUnitFrame(frame.m_unitTag)
    end
end

function UnitFrame_HandleMouseUp(frame, button, upInside)
    local unitTag = frame.m_unitTag

    if GetCursorContentType() ~= MOUSE_CONTENT_EMPTY then
        --dropped something with left click
        if button == MOUSE_BUTTON_INDEX_LEFT then
            PlaceInUnitFrame(unitTag)
        else
            ClearCursor()
        end

        -- Same deal here...no unitFrame related clicks like targeting or context menus should take place at this point
        return
    end
end

function UnitFrame_HandleMouseEnter(frame)
    local unitFrame = UnitFrames:GetFrame(frame.m_unitTag)
    if unitFrame then
        unitFrame:HandleMouseEnter()
    end
end

function UnitFrame_HandleMouseExit(frame)
    local unitFrame = UnitFrames:GetFrame(frame.m_unitTag)
    if unitFrame then
        unitFrame:HandleMouseExit()
    end
end

local function RefreshGroups(eventCode)
    DoGroupUpdate(eventCode)

    for i = 1, GROUP_SIZE_MAX do
        ZO_UnitFrames_UpdateWindow(ZO_Group_GetUnitTagForGroupIndex(i))
    end
end

local function UpdateStatus(unitTag, isDead, isOnline)
    local unitFrame = UnitFrames:GetFrame(unitTag)
    if(unitFrame) then
        unitFrame:UpdateStatus(isDead, isOnline)
        unitFrame:DoAlphaUpdate(IsUnitInGroupSupportRange(unitTag), isOnline, IsUnitGroupLeader(unitTag))
    end

    if(AreUnitsEqual(unitTag, "reticleover")) then
        unitFrame = UnitFrames:GetFrame("reticleover")
        if(unitFrame) then
            unitFrame:UpdateStatus(isDead, isOnline)
        end
    end
end

function ZO_UnitFrames_GetUnitFrame(unitTag)
    return UnitFrames:GetFrame(unitTag)
end

function ZO_UnitFrames_SetEnableTargetOfTarget(enabled)
    UnitFrames:SetEnableTargetOfTarget(enabled)
end

function ZO_UnitFrames_IsTargetOfTargetEnabled()
    return UnitFrames:IsTargetOfTargetEnabled()
end

local function RegisterForEvents()
    local function OnTargetChanged(evt, unitTag)
        ZO_UnitFrames_UpdateWindow("reticleovertarget", UNIT_CHANGED)
    end
    
    local function OnUnitCharacterNameChanged(evt, unitTag)
        ZO_UnitFrames_UpdateWindow(unitTag)
    end

    local function OnReticleTargetChanged(evt)
        ZO_UnitFrames_UpdateWindow("reticleover", UNIT_CHANGED)
        ZO_UnitFrames_UpdateWindow("reticleovertarget", UNIT_CHANGED)
    end

    local function PowerUpdateHandlerFunction(unitTag, powerPoolIndex, powerType, powerPool, powerPoolMax)
        local unitFrame = UnitFrames:GetFrame(unitTag)
        if unitFrame then
            if powerType == POWERTYPE_HEALTH then
                local oldHealth = unitFrame.healthBar.currentValue    
                unitFrame.healthBar:Update(POWERTYPE_HEALTH, powerPool, powerPoolMax)
    
                if oldHealth ~= nil and oldHealth == 0 then
                    -- Unit went from dead to non dead...update reaction
                    unitFrame:UpdateUnitReaction()
                end
            else
                unitFrame:UpdatePowerBar(powerPoolIndex, powerType, powerPool, powerPoolMax)
            end
        end
    end
    ZO_MostRecentPowerUpdateHandler:New("UnitFrames", PowerUpdateHandlerFunction)

    local function OnUnitCreated(evt, unitTag)
        if(ZO_Group_IsGroupUnitTag(unitTag)) then
            ReportUnitChanged(unitTag)
        else
            ZO_UnitFrames_UpdateWindow(unitTag, UNIT_CHANGED)
        end
    end

    local function OnUnitDestroyed(evt, unitTag)
        if(ZO_Group_IsGroupUnitTag(unitTag)) then
            ReportUnitChanged(unitTag)
        else
            ZO_UnitFrames_UpdateWindow(unitTag)
        end
    end

    local function OnLevelUpdate(eventCode, unitTag, level)
        local unitFrame = UnitFrames:GetFrame(unitTag)
    
        if(unitFrame) then
            unitFrame:UpdateLevel()
        end
    end

    local function OnLeaderUpdate()
        UpdateLeaderIndicator()
    end

    local function OnDispositionUpdate(eventCode, unitTag)
        local unitFrame = UnitFrames:GetFrame(unitTag)
    
        if(unitFrame) then
            unitFrame:UpdateUnitReaction()
        end
    end

    local function OnGroupSupportRangeUpdate(evt, unitTag, isNearby)
        local unitFrame = UnitFrames:GetFrame(unitTag)
    
        if(unitFrame) then
            local isOnline = IsUnitOnline(unitTag)
            local isLeader = IsUnitGroupLeader(unitTag)
            unitFrame:DoAlphaUpdate(isNearby, isOnline, isLeader)
            if(AreUnitsEqual(unitTag, "reticleover")) then
                UnitFrames:GetFrame("reticleover"):DoAlphaUpdate(isNearby, isOnline, isLeader)
            end
    
            if(AreUnitsEqual(unitTag, "reticleovertarget")) then
                local targetOfTarget = UnitFrames:GetFrame("reticleovertarget")
                if(targetOfTarget) then
                    targetOfTarget:DoAlphaUpdate(isNearby, isOnline, isLeader)
                end
            end
        end
    end

    local function OnGroupUpdate(eventCode)
        --Pretty much anything can happen on a full group update so refresh everything
        UnitFrames:SetGroupSize(GetGroupSize())
        UnitFrames:DisableGroupAndRaidFrames()
        CreateGroups()
        UnitFrames:ClearDirty()
    end

    local function OnGroupMemberLeft(eventCode, characterName, reason, wasLocalPlayer, amLeader)
        if(wasLocalPlayer) then
            RefreshGroups(eventCode)
        end
    end

    local function OnGroupMemberConnectedStateChanged(event, unitTag, isOnline)
        UpdateStatus(unitTag, IsUnitDead(unitTag), isOnline)
    end
    
    local function OnGroupMemberRoleChanged(event, unitTag, role)
        local unitFrame = UnitFrames:GetFrame(unitTag)    
        if unitFrame then
            unitFrame:UpdateAssignment()
        end
    end

    local function OnUnitDeathStateChanged(event, unitTag, isDead)
        UpdateStatus(unitTag, isDead, IsUnitOnline(unitTag))
    end

    local function OnRankPointUpdate(eventCode, unitTag)
        local unitFrame = UnitFrames:GetFrame(unitTag)
    
        if(unitFrame) then
            unitFrame:UpdateRank()
        end
    end

    local function OnChampionPointsUpdate(eventCode, unitTag)
        local unitFrame = UnitFrames:GetFrame(unitTag)
    
        if(unitFrame) then
            unitFrame:UpdateLevel()
        end    
    end

    local function OnTitleUpdated(eventCode, unitTag)
        local unitFrame = UnitFrames:GetFrame(unitTag)
    
        if(unitFrame) then
            unitFrame:UpdateCaption()
        end    
    end

    local function OnPlayerActivated(eventCode)
        ZO_UnitFrames_UpdateWindow("reticleover", UNIT_CHANGED)
        ZO_UnitFrames_UpdateWindow("reticleovertarget", UNIT_CHANGED)
    
        -- do a full update because we probably missed events while loading
        UnitFrames:SetGroupSize()
        UnitFrames:DisableGroupAndRaidFrames()
        CreateGroups()
    end

    local function OnTargetOfTargetEnabledChanged(enabled)
        ZO_UnitFrames_UpdateWindow("reticleovertarget", UNIT_CHANGED)
    end

    local function OnInterfaceSettingChanged(eventCode)
        -- Groups do not update every frame (they wait for events), so refresh if the primary name option may have changed
        RefreshGroups(eventCode)
    end

    local function OnGuildNameAvailable()
        --only reticle over can show a guild name in a caption
        local unitFrame = UnitFrames:GetFrame("reticleover")
        if unitFrame then
            unitFrame:UpdateCaption()
        end
    end

    local function OnGuildIdChanged()
        --this is filtered to only fire on reticle over unit tag
        local unitFrame = UnitFrames:GetFrame("reticleover")
        if unitFrame then
            unitFrame:UpdateCaption()
        end
    end

    ZO_UnitFrames:RegisterForEvent(EVENT_TARGET_CHANGED, OnTargetChanged)
    ZO_UnitFrames:AddFilterForEvent(EVENT_TARGET_CHANGED, REGISTER_FILTER_UNIT_TAG, "reticleover")
    ZO_UnitFrames:RegisterForEvent(EVENT_UNIT_CHARACTER_NAME_CHANGED, OnUnitCharacterNameChanged)
    ZO_UnitFrames:AddFilterForEvent(EVENT_UNIT_CHARACTER_NAME_CHANGED, REGISTER_FILTER_UNIT_TAG, "reticleover")
    ZO_UnitFrames:RegisterForEvent(EVENT_RETICLE_TARGET_CHANGED, OnReticleTargetChanged)
    ZO_UnitFrames:RegisterForEvent(EVENT_UNIT_CREATED, OnUnitCreated)
    ZO_UnitFrames:RegisterForEvent(EVENT_UNIT_DESTROYED, OnUnitDestroyed)
    ZO_UnitFrames:RegisterForEvent(EVENT_LEVEL_UPDATE, OnLevelUpdate)
    ZO_UnitFrames:RegisterForEvent(EVENT_LEADER_UPDATE, OnLeaderUpdate)
    ZO_UnitFrames:RegisterForEvent(EVENT_DISPOSITION_UPDATE, OnDispositionUpdate)
    ZO_UnitFrames:RegisterForEvent(EVENT_GROUP_SUPPORT_RANGE_UPDATE, OnGroupSupportRangeUpdate)
    ZO_UnitFrames:RegisterForEvent(EVENT_GROUP_UPDATE, OnGroupUpdate)
    ZO_UnitFrames:RegisterForEvent(EVENT_GROUP_MEMBER_LEFT, OnGroupMemberLeft)
    ZO_UnitFrames:RegisterForEvent(EVENT_GROUP_MEMBER_CONNECTED_STATUS, OnGroupMemberConnectedStateChanged)
    ZO_UnitFrames:RegisterForEvent(EVENT_GROUP_MEMBER_ROLE_CHANGED, OnGroupMemberRoleChanged)
    ZO_UnitFrames:RegisterForEvent(EVENT_UNIT_DEATH_STATE_CHANGED, OnUnitDeathStateChanged)
    ZO_UnitFrames:RegisterForEvent(EVENT_RANK_POINT_UPDATE, OnRankPointUpdate)
    ZO_UnitFrames:RegisterForEvent(EVENT_CHAMPION_POINT_UPDATE, OnChampionPointsUpdate)
    ZO_UnitFrames:RegisterForEvent(EVENT_TITLE_UPDATE, OnTitleUpdated)
    ZO_UnitFrames:RegisterForEvent(EVENT_PLAYER_ACTIVATED, OnPlayerActivated)
    ZO_UnitFrames:RegisterForEvent(EVENT_INTERFACE_SETTING_CHANGED, OnInterfaceSettingChanged)
    ZO_UnitFrames:RegisterForEvent(EVENT_GUILD_NAME_AVAILABLE, OnGuildNameAvailable)
    ZO_UnitFrames:RegisterForEvent(EVENT_GUILD_ID_CHANGED, OnGuildIdChanged)
    ZO_UnitFrames:AddFilterForEvent(EVENT_GUILD_ID_CHANGED, REGISTER_FILTER_UNIT_TAG, "reticleover")

    CALLBACK_MANAGER:RegisterCallback("TargetOfTargetEnabledChanged", OnTargetOfTargetEnabledChanged)
end

function ZO_UnitFrames_Initialize()
    local function OnAddOnLoaded(event, name)
        if name == "ZO_Ingame" then
            CalculateDynamicPlatformConstants()
            RegisterForEvents()
            CreateGroupAnchorFrames()

            UnitFrames = UnitFramesManager:New()

            CreateTargetFrame()
            CreateGroups()

            local function OnGamepadPreferredModeChanged()
                UnitFrames:ApplyVisualStyle()
                UpdateGroupFramesVisualStyle()
                UpdateLeaderIndicator()
            end
            ZO_PlatformStyle:New(OnGamepadPreferredModeChanged)

            UNIT_FRAMES = UnitFrames

            CALLBACK_MANAGER:FireCallbacks("UnitFramesCreated")
            EVENT_MANAGER:UnregisterForEvent("UnitFrames_OnAddOnLoaded", EVENT_ADD_ON_LOADED)
        end
    end

    EVENT_MANAGER:RegisterForEvent("UnitFrames_OnAddOnLoaded", EVENT_ADD_ON_LOADED, OnAddOnLoaded)
    UNIT_FRAMES_FRAGMENT = ZO_HUDFadeSceneFragment:New(ZO_UnitFrames)
end

function ZO_UnitFrames_OnUpdate()
    if UnitFrames and UnitFrames:GetIsDirty() then
        RefreshUnitFrames()
    end
end
