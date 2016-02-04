local HUDRaidLifeManager = ZO_Object:Subclass()

function HUDRaidLifeManager:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function HUDRaidLifeManager:Initialize(control)
    self.control = control
    self.displayObject = control:GetNamedChild("Reservoir").object
    self.displayObject:SetAnimatedShowHide(true)

    self:RefreshMode()

    ZO_PlatformStyle:New(function() self:ApplyPlatformStyle() end)

    EVENT_MANAGER:RegisterForEvent("HUDRaidLifeManager", EVENT_INTERFACE_SETTING_CHANGED, function(_, settingType, settingId)
        if(settingType == SETTING_TYPE_UI and settingId == UI_SETTING_SHOW_RAID_LIVES) then
            self:RefreshMode()
        end
    end)

    local function RaidCounterChanged(eventId, ...)
        self:ProcessRaidCounterChanged()
    end

    EVENT_MANAGER:RegisterForEvent("HUDRaidLifeManager", EVENT_RAID_REVIVE_COUNTER_UPDATE, RaidCounterChanged)

    EVENT_MANAGER:RegisterForUpdate("HUDRaidLifeManager", 100, function(...) self:OnUpdate(...) end)

end

local TIMER_DURATION_MS = 2500
function HUDRaidLifeManager:ProcessRaidCounterChanged()
    local currentInfo = self.announcementsInfo
    local currentScore = GetCurrentRaidLifeScoreBonus()
    if currentInfo == nil then
        currentInfo = 
        {
            currentScore = currentScore,
        }
        self.announcementsInfo = currentInfo
    else
        currentInfo.currentScore = currentScore
    end
    currentInfo.endTimeMS = GetGameTimeMilliseconds() + TIMER_DURATION_MS
end

function HUDRaidLifeManager:ShowCapacityAnnouncement(score)
    local maxCount = GetCurrentRaidStartingReviveCounters()
    local currentCount = GetRaidReviveCountersRemaining()
    if currentCount ~= maxCount then
        local scoreText = zo_strformat(SI_REVIVE_COUNTER_UPDATED_SMALL, score)
        CENTER_SCREEN_ANNOUNCE:AddMessage(EVENT_RAID_REVIVE_COUNTER_UPDATE, CSA_EVENT_LARGE_TEXT, SOUNDS.RAID_TRIAL_COUNTER_UPDATE, zo_strformat(SI_REVIVE_COUNTER_UPDATED_LARGE, "EsoUI/Art/Trials/VitalityDepletion.dds"))
    end
end

function HUDRaidLifeManager:OnUpdate(timeMS)
    if self.announcementsInfo and timeMS > self.announcementsInfo.endTimeMS then
        self:ShowCapacityAnnouncement(self.announcementsInfo.currentScore)
        self.announcementsInfo = nil
    end
end

function HUDRaidLifeManager:RefreshMode()
    local visibilitySetting = tonumber(GetSetting(SETTING_TYPE_UI, UI_SETTING_SHOW_RAID_LIVES))

    local showInSpecificSituations
    if(visibilitySetting == RAID_LIFE_VISIBILITY_CHOICE_OFF) then
        self.displayObject:SetHiddenForReason("disabled", true)
        showInSpecificSituations = false
    elseif(visibilitySetting == RAID_LIFE_VISIBILITY_CHOICE_AUTOMATIC) then
        self.displayObject:SetHiddenForReason("disabled", false)
        showInSpecificSituations = true
    elseif(visibilitySetting == RAID_LIFE_VISIBILITY_CHOICE_ON) then
        self.displayObject:SetHiddenForReason("disabled", false)
        showInSpecificSituations = false
    end

    self.displayObject:SetShowOnChange(showInSpecificSituations)
end

function HUDRaidLifeManager:SetHiddenForReason(reason, hidden)
    self.displayObject:SetHiddenForReason(reason, hidden)
end

function HUDRaidLifeManager:ApplyPlatformStyle()
    ApplyTemplateToControl(self.control, ZO_GetPlatformTemplate("ZO_HUDRaidLife"))
end

function ZO_HUDRaidLife_OnInitialized(self)
    HUD_RAID_LIFE = HUDRaidLifeManager:New(self)
end