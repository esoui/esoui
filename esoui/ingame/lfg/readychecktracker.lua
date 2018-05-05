local KEYBOARD_STYLE =
{
    FONT_COUNT = "ZoFontGameShadow",
    TOP_LEVEL_PRIMARY_ANCHOR_OFFSET_Y = 10,
}

local GAMEPAD_STYLE =
{
    FONT_COUNT = "ZoFontGamepad34",
    TOP_LEVEL_PRIMARY_ANCHOR_OFFSET_Y = 20,
}

local MAX_ICON_COUNT = 4

------------------
--Initialization--
------------------

ZO_ReadyCheckTracker = ZO_Object:Subclass()

function ZO_ReadyCheckTracker:New(...)
    local tracker = ZO_Object.New(self)
    tracker:Initialize(...)
    return tracker
end

function ZO_ReadyCheckTracker:Initialize(control)
    self.control = control
    control.owner = self

    self.container = control:GetNamedChild("Container")
    self.iconsContainer = self.container:GetNamedChild("Icons")

    self.iconControls = {}
    for i = 1, MAX_ICON_COUNT do
        table.insert(self.iconControls, self.iconsContainer:GetNamedChild("Icon" .. i))
    end

    self.countLabel = self.container:GetNamedChild("Count")

    local allConstants = { KEYBOARD_STYLE, GAMEPAD_STYLE }
    for _, constants in ipairs(allConstants) do
        constants.TOP_LEVEL_PRIMARY_ANCHOR = ZO_Anchor:New(TOPRIGHT, ZO_ActivityTracker, BOTTOMRIGHT, 0, constants.TOP_LEVEL_PRIMARY_ANCHOR_OFFSET_Y)
        constants.CONTAINER_PRIMARY_ANCHOR = ZO_Anchor:New(TOPRIGHT)
        constants.COUNT_PRIMARY_ANCHOR = ZO_Anchor:New(TOPRIGHT)
    end

    KEYBOARD_STYLE.TOP_LEVEL_SECONDARY_ANCHOR = ZO_Anchor:New(TOPLEFT, ZO_ActivityTracker, BOTTOMLEFT, 0, KEYBOARD_STYLE.TOP_LEVEL_PRIMARY_ANCHOR_OFFSET_Y)
    KEYBOARD_STYLE.CONTAINER_SECONDARY_ANCHOR = ZO_Anchor:New(TOPLEFT)
    KEYBOARD_STYLE.COUNT_SECONDARY_ANCHOR = ZO_Anchor:New(TOPLEFT)

    KEYBOARD_STYLE.ICONS_PRIMARY_ANCHOR = ZO_Anchor:New(TOPLEFT)
    GAMEPAD_STYLE.ICONS_PRIMARY_ANCHOR = ZO_Anchor:New(TOPRIGHT)

    ZO_PlatformStyle:New(function(style) self:ApplyPlatformStyle(style) end, KEYBOARD_STYLE, GAMEPAD_STYLE)

    READY_CHECK_TRACKER_FRAGMENT = ZO_HUDFadeSceneFragment:New(self.container)

    self:RegisterEvents()
end

function ZO_ReadyCheckTracker:RegisterEvents()
    local function Update()
        self:Update()
    end

    self.control:RegisterForEvent(EVENT_PLAYER_ACTIVATED, Update)
    self.control:RegisterForEvent(EVENT_GROUPING_TOOLS_READY_CHECK_UPDATED, Update)
    self.control:RegisterForEvent(EVENT_GROUPING_TOOLS_READY_CHECK_CANCELLED, Update)
end

do
    local TANKS_ACCEPTED_PATH = "EsoUI/Art/LFG/LFG_tank_down_no_glow_64.dds"
    local TANKS_PENDING_PATH = "EsoUI/Art/LFG/LFG_tank_disabled_64.dds"
    local HEALERS_ACCEPTED_PATH = "EsoUI/Art/LFG/LFG_healer_down_no_glow_64.dds"
    local HEALERS_PENDING_PATH = "EsoUI/Art/LFG/LFG_healer_disabled_64.dds"
    local DPS_ACCEPTED_PATH = "EsoUI/Art/LFG/LFG_dps_down_no_glow_64.dds"
    local DPS_PENDING_PATH = "EsoUI/Art/LFG/LFG_dps_disabled_64.dds"

    local function SetIcons(iconControls, path, startingIndex, numToSet)
        for i = 1, numToSet do
            local control = iconControls[startingIndex]
            control:SetTexture(path)
            control:SetHidden(false)
            startingIndex = startingIndex + 1
        end
        return startingIndex
    end

    function ZO_ReadyCheckTracker:Update()
        if GetActivityFinderStatus() == ACTIVITY_FINDER_STATUS_READY_CHECK and HasAcceptedLFGReadyCheck() then
            local tanksAccepted, tanksPending, healersAccepted, healersPending, dpsAccepted, dpsPending = GetLFGReadyCheckCounts()
            local pendingTotal = tanksPending + healersPending + dpsPending
            local total = pendingTotal + tanksAccepted + healersAccepted + dpsAccepted 
            local activityType = GetLFGReadyCheckActivityType()

            if ZO_IsActivityTypeDungeon(activityType) and pendingTotal <= MAX_ICON_COUNT then
                self.countLabel:SetHidden(true)
                self.iconsContainer:SetHidden(false)

                local currentIndex = 1
                local iconControls = self.iconControls
                currentIndex = SetIcons(iconControls, TANKS_ACCEPTED_PATH, currentIndex, tanksAccepted)
                currentIndex = SetIcons(iconControls, TANKS_PENDING_PATH, currentIndex, tanksPending)
                currentIndex = SetIcons(iconControls, HEALERS_ACCEPTED_PATH, currentIndex, healersAccepted)
                currentIndex = SetIcons(iconControls, HEALERS_PENDING_PATH, currentIndex, healersPending)
                currentIndex = SetIcons(iconControls, DPS_ACCEPTED_PATH, currentIndex, dpsAccepted)
                currentIndex = SetIcons(iconControls, DPS_PENDING_PATH, currentIndex, dpsPending)
            
                for unusedIndex = currentIndex, MAX_ICON_COUNT do
                    iconControls[unusedIndex]:SetHidden(true)
                end
            else
                self.countLabel:SetText(zo_strformat(SI_READY_CHECK_TRACKER_COUNT_FORMAT, pendingTotal))
                self.countLabel:SetHidden(false)
                self.iconsContainer:SetHidden(true)
            end
        else
            self.iconsContainer:SetHidden(true)
            self.countLabel:SetHidden(true)
        end
    end
end

function ZO_ReadyCheckTracker:ApplyPlatformStyle(style)
    self.countLabel:SetFont(style.FONT_COUNT)

    self.control:ClearAnchors()
    style.TOP_LEVEL_PRIMARY_ANCHOR:AddToControl(self.control)
    if style.TOP_LEVEL_SECONDARY_ANCHOR then
        style.TOP_LEVEL_SECONDARY_ANCHOR:AddToControl(self.control)
    end

    self.container:ClearAnchors()
    style.CONTAINER_PRIMARY_ANCHOR:AddToControl(self.container)
    if style.CONTAINER_SECONDARY_ANCHOR then
        style.CONTAINER_SECONDARY_ANCHOR:AddToControl(self.container)
    end

    self.iconsContainer:ClearAnchors()
    style.ICONS_PRIMARY_ANCHOR:AddToControl(self.iconsContainer)

    self.countLabel:ClearAnchors()
    style.COUNT_PRIMARY_ANCHOR:AddToControl(self.countLabel)
    if style.COUNT_SECONDARY_ANCHOR then
        style.COUNT_SECONDARY_ANCHOR:AddToControl(self.countLabel)
    end
end

function ZO_ReadyCheckTracker_OnInitialized(control)
    READY_CHECK_TRACKER = ZO_ReadyCheckTracker:New(control)
end