local MAX_ICON_COUNT = 4

------------------
--Initialization--
------------------

ZO_ReadyCheckTracker = ZO_HUDTracker_Base:Subclass()

function ZO_ReadyCheckTracker:Initialize(control)
    ZO_HUDTracker_Base.Initialize(self, control)

    self.iconsContainer = self.container:GetNamedChild("Icons")

    self.iconControls = {}
    for i = 1, MAX_ICON_COUNT do
        table.insert(self.iconControls, self.iconsContainer:GetNamedChild("Icon" .. i))
    end

    READY_CHECK_TRACKER_FRAGMENT = self:GetFragment()
end

function ZO_ReadyCheckTracker:InitializeStyles()
    self.styles =
    {
        gamepad =
        {
            FONT_HEADER = "ZoFontGamepad34",
        }
    }
    ZO_HUDTracker_Base.InitializeStyles(self)
end

function ZO_ReadyCheckTracker:GetHUDElementInfo()
    local DISPLAY_NAME = nil -- Will be controlled via ActivityTracker
    return DISPLAY_NAME
end

function ZO_ReadyCheckTracker:GetHUDElementOptionKeys()
    local KEY = nil -- Will be controlled via ActivityTracker
    return KEY
end

function ZO_ReadyCheckTracker:GetParentTracker()
    return ACTIVITY_TRACKER
end

function ZO_ReadyCheckTracker:RegisterEvents()
    ZO_HUDTracker_Base.RegisterEvents(self)

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
        local inReadyCheckState = GetActivityFinderStatus() == ACTIVITY_FINDER_STATUS_READY_CHECK

        if inReadyCheckState and ZO_Dialogs_IsShowing("LFG_LEAVE_QUEUE_CONFIRMATION") then
            ZO_Dialogs_ReleaseDialog("LFG_LEAVE_QUEUE_CONFIRMATION")
        end

        if inReadyCheckState and HasAcceptedLFGReadyCheck() then
            local tanksAccepted, tanksPending, healersAccepted, healersPending, dpsAccepted, dpsPending = GetLFGReadyCheckCounts()
            local pendingTotal = tanksPending + healersPending + dpsPending
            local total = pendingTotal + tanksAccepted + healersAccepted + dpsAccepted 
            local activityType = GetLFGReadyCheckActivityType()

            if ZO_IsActivityTypeDungeon(activityType) and pendingTotal <= MAX_ICON_COUNT then
                self.headerLabel:SetHidden(true)
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
                self.headerLabel:SetText(zo_strformat(SI_READY_CHECK_TRACKER_COUNT_FORMAT, pendingTotal))
                self.headerLabel:SetHidden(false)
                self.iconsContainer:SetHidden(true)
            end
            self:GetFragment():SetHiddenForReason("Inactive", false, DEFAULT_HUD_DURATION, DEFAULT_HUD_DURATION)
        else
            self.iconsContainer:SetHidden(true)
            self.headerLabel:SetHidden(true)
            self:GetFragment():SetHiddenForReason("Inactive", true, DEFAULT_HUD_DURATION, DEFAULT_HUD_DURATION)
        end

        ZO_HUDTracker_Base.Update(self)
    end
end

function ZO_ReadyCheckTracker:GetPriority()
    return ZO_HUD_TRACKER_PRIORITY.READY_CHECK
end

function ZO_ReadyCheckTracker_OnInitialized(control)
    READY_CHECK_TRACKER = ZO_ReadyCheckTracker:New(control)
end

HUD_TRACKER_MANAGER:RegisterTracker("ZO_ReadyCheckTracker_Template", "ZO_ReadyCheckTrackerTopLevel")